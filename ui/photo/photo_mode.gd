class_name PhotoMode
extends Control
## Photo mode (M3 Task 16, spec §14.14). The HUD hides and a free camera (PhotoOrbit) looks at the
## player: one finger turns it, two fingers pinch to zoom and drag to pan (mouse drag, right-drag and
## the wheel on desktop). Filters are one full-screen shader pass on one long-lived material; frames
## are drawn by PhotoFrameOverlay. The shutter hides the buttons for one frame, reads the screen back,
## flashes, clicks, encodes the PNG on a worker thread and saves it (PhotoFiles); SHARE opens the
## Android share sheet (PhotoShare), only where a grown-up's switch allows it (M5 store readiness F1,
## PhotoRules.may_share; otherwise the shutter only saves). M7 (spec §20.3): in a browser (save_way PHOTO_DOWNLOAD) the
## shutter keeps the photo in the game, no file, and that chip is DOWNLOAD (the same switch). Closing puts the game
## camera, the HUD, the pause state and the mouse back exactly as they were. Solo play pauses the world while open;
## LAN never does, and a hit there closes photo mode (PhotoRules). Runs while the tree is paused (PROCESS_MODE_ALWAYS).

signal opened
signal closed
## The moment the picture is taken: the buttons are hidden, the filter and the frame are shown.
signal shutter
signal photo_saved(path: String)
signal photo_failed

const HEAD_HEIGHT := CameraRig.HEAD_HEIGHT
## The filter shader is drawn for these frames after opening, so it compiles while the HUD hides and
## not on the first filter tap (a new shader stalled the emulator's GL renderer for 100+ ms; see Fx).
const PREWARM_FRAMES := 2
const WHEEL_ZOOM := 0.9
const FLASH_SECONDS := 0.35
const HINT_SECONDS := 4.0
const HINT_TOUCH := "Drag: turn     Pinch: zoom     Two fingers: move"
const HINT_DESKTOP := "Drag: turn     Right-drag: move     Wheel: zoom     Esc: back"

var target: Node3D
var hud: CanvasItem
var is_solid: Callable = func(_cell: Vector3i) -> bool: return false
var peer_id := 1
## M7: where the shutter's photo goes (PlatformRules.photo_save: the gallery, a download, the folder).
var save_way: StringName = PlatformRules.photo_save(PlatformRules.current())
var folders := PhotoFiles.folders(save_way == PlatformRules.PHOTO_GALLERY, _pictures_dir())
var clock: Callable = func() -> Dictionary: return Time.get_datetime_dict_from_system()
## M5 store readiness F1 (spec §5.14): whether SHARE may show, read at every open (a grown-up's switch in the
## profile; tests set one). Where it may not, photo mode only saves to the gallery.
var share_allowed: Callable = func() -> bool: return PhotoRules.may_share(Profile.data.age_band, Profile.data.photo_share)
## Opens the share sheet with (png, saved path) and says what happened (PhotoShare.share; tests record it).
var sharer: Callable = func(png: PackedByteArray, path: String) -> StringName: return PhotoShare.share(png, path, save_way)

var orbit := PhotoOrbit.new()
var camera := Camera3D.new()
var filter_rect := ColorRect.new()
var frame_overlay := PhotoFrameOverlay.new()
var controls := Control.new()
var filter: int = PhotoFilters.Filter.NORMAL
var frame: int = PhotoFrames.Frame.NONE
var last_path := ""

var _open := false
var _busy := false
var _gestures := PhotoGestures.new()
var _material := ShaderMaterial.new()
var _previous_camera: Camera3D
var _hud_was_visible := true
var _paused_by_me := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _hp := -1
var _prewarm_left := 0
var _last_png := PackedByteArray()
var _hidden_helpers := {}         # the player's build helpers hidden while open -> were visible
var _interactor: Node
var _interactor_mode := Node.PROCESS_MODE_INHERIT
var _flash := ColorRect.new()
var _hint := Label.new()
var _message := Label.new()
var _message_tween: Tween
var _hint_tween: Tween
var _filter_chips := {}
var _frame_chips := {}
var _close_button := PhotoChip.new()
var _shutter_button := PhotoChip.new()
var _share_button := PhotoChip.new()
## Owner #101 (VR on the Meta Quest, P3): in a headset PHOTO is a camera held in the pointing hand (VrPhotoCamera); the
## trigger takes the picture from it. Null off VR.
var _held: VrPhotoCamera
var _held_trigger := false
var _held_moved := {}        # filter_rect / frame_overlay -> [parent, index] while they draw in the held camera


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	visible = false
	_material.shader = load(PhotoFilters.SHADER_PATH)
	filter_rect.material = _material
	_full_screen(filter_rect)
	filter_rect.visible = false
	add_child(frame_overlay)
	_full_screen(controls)
	_build_controls()
	_flash.color = Color(1, 1, 1, 0)
	_full_screen(_flash)
	camera.name = "PhotoCamera"
	add_child(camera)   # a Node3D under a Control: its transform is its global transform
	Session.player_hurt.connect(_on_player_hurt)


## The player to photograph (a Player, or any Node3D), the HUD to hide, and which cells are solid.
func setup(p_target: Node3D, p_hud: CanvasItem, p_is_solid: Callable) -> void:
	target = p_target
	hud = p_hud
	is_solid = p_is_solid
	if target is Player:
		peer_id = (target as Player).peer_id


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or not is_instance_valid(target):
		return
	_open = true
	_previous_camera = get_viewport().get_camera_3d()
	var head := head_position()
	var start := Transform3D(Basis(), head + Vector3(0, 0, PhotoOrbit.DEFAULT_DISTANCE))
	if _previous_camera:
		start = _previous_camera.global_transform
		camera.fov = _previous_camera.fov
		camera.far = _previous_camera.far
	camera.near = 0.05
	orbit = PhotoOrbit.from_camera(start, head, _size_scale())
	_place_camera()
	camera.make_current()
	if is_instance_valid(hud):
		_hud_was_visible = hud.visible
		hud.propagate_notification(NOTIFICATION_PAUSED)   # let go of every finger, as pausing does
		hud.visible = false
	_hide_build_helpers()
	_paused_by_me = PhotoRules.pauses_world(Game.net_mode) and not get_tree().paused
	if _paused_by_me:
		get_tree().paused = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hp = _target_hp()
	_gestures.cancel()
	_prewarm_left = PREWARM_FRAMES
	_apply_filter()
	frame_overlay.frame = frame
	_share_button.visible = bool(share_allowed.call())   # M5 F1: a grown-up's switch
	controls.visible = true
	_message.visible = false
	_show_hint()
	visible = true
	if Vr.active():
		_vr_open()
	opened.emit()


func close() -> void:
	if not _open:
		return
	_open = false
	_fixed = false   # M4 H
	_vr_close()
	_gestures.cancel()
	visible = false
	filter_rect.visible = false
	camera.clear_current(false)
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	_previous_camera = null
	if is_instance_valid(hud):
		hud.visible = _hud_was_visible
	_restore_build_helpers()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	Input.mouse_mode = _mouse_before
	closed.emit()


func set_filter(f: int) -> void:
	filter = f if PhotoFilters.ORDER.has(f) else PhotoFilters.Filter.NORMAL
	_apply_filter()


func set_frame(f: int) -> void:
	frame = f if PhotoFrames.ORDER.has(f) else PhotoFrames.Frame.NONE
	frame_overlay.frame = frame
	for id: int in _frame_chips:
		(_frame_chips[id] as PhotoChip).selected = id == frame


func head_position() -> Vector3:
	if target.has_method(&"eye_position"):
		return target.call(&"eye_position")
	return target.global_position + Vector3(0, HEAD_HEIGHT, 0)


# --- Taking, saving and sharing ----------------------------------------------------------------

## Hides the buttons for one drawn frame, reads the screen back (filter and frame included), flashes,
## clicks, then encodes and saves the PNG without stalling the game.
func take_photo() -> void:
	if _busy or not _open:
		return
	_busy = true
	controls.visible = false
	await _frame_drawn()
	if not _open:
		controls.visible = true
		_busy = false
		return
	shutter.emit()
	var image := capture(_held.viewport if _held else get_viewport())
	controls.visible = true
	_flash_screen()
	Audio.play(&"shutter")
	await _save(image)


## The viewport's picture. Headless runs draw nothing: a blank picture of the same size stands in.
static func capture(viewport: Viewport) -> Image:
	var tex := viewport.get_texture()
	var size := Vector2i(tex.get_size())
	if DisplayServer.get_name() != "headless":
		var img := tex.get_image()
		if img and not img.is_empty():
			return img
	return Image.create_empty(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGB8)


func share() -> void:
	if _busy or not _share_button.visible:   # M5 F1: only where a grown-up's switch allows it
		return
	if _last_png.is_empty():
		_say("Take a photo first!")
		return
	match sharer.call(_last_png, last_path):
		&"sheet":
			pass
		&"viewer":
			_say("Tap Share on your photo!")
		&"folder":
			_say("Your photos folder is open")
		&"download":
			_say("Your photo is downloading!")   # M7: a browser
		_:
			_say("Sharing doesn't work here yet. Your photo is saved!")


func _frame_drawn() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


## PNG encoding of a full phone screen takes a few hundred ms on a phone: it runs on a worker thread,
## and only the file write (MediaStore on Android) happens here.
func _save(image: Image) -> void:
	var result: Array[PackedByteArray] = [PackedByteArray()]
	var task := WorkerThreadPool.add_task(func() -> void:
		if image.get_format() != Image.FORMAT_RGB8:
			image.convert(Image.FORMAT_RGB8)
		result[0] = image.save_png_to_buffer())
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	var png := result[0]
	var path := ""
	if not png.is_empty():
		var t: Dictionary = clock.call()
		if save_way == PlatformRules.PHOTO_DOWNLOAD:
			path = PhotoFiles.download_name(t)   # M7: kept in the game (a browser's user:// holds the worlds); DOWNLOAD
		else:
			path = PhotoFiles.write_png(png, folders, t)
	_busy = false
	if path == "":
		_say("Oops! The photo could not be saved.")
		photo_failed.emit()
		return
	last_path = path
	_last_png = png
	if save_way == PlatformRules.PHOTO_DOWNLOAD:
		_say(PhotoFiles.kept_message(_share_button.visible))
	else:
		_say(PhotoFiles.where_message(path, _pictures_dir(), save_way == PlatformRules.PHOTO_GALLERY))
	photo_saved.emit(path)


static func _pictures_dir() -> String:
	var gallery := PlatformRules.photo_save(PlatformRules.current()) == PlatformRules.PHOTO_GALLERY
	return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) if gallery else ""


# --- Input -------------------------------------------------------------------------------------

## While open, photo mode takes every event: its own buttons see theirs first (children get _input
## before their parent), everything else steers the camera, and nothing builds or looks behind it.
func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"photo"):
		close()
	elif _held:
		pass   # owner #101: the held camera goes where the hand goes (no orbit to steer)
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_gestures.press(t.index, t.position)
		else:
			_gestures.release(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_steer(_gestures.move(d.index, d.position))
	elif event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit.zoom(WHEEL_ZOOM)
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit.zoom(1.0 / WHEEL_ZOOM)
	elif event is InputEventMouseMotion:
		# The left button arrives as an emulated touch (desktop); the right or middle one pans.
		var m := event as InputEventMouseMotion
		if m.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			orbit.pan_by(m.relative)
	get_viewport().set_input_as_handled()


## P on desktop opens photo mode (never over the pause menu).
func _unhandled_input(event: InputEvent) -> void:
	if not _open and event.is_action_pressed(&"photo") and not get_tree().paused and is_instance_valid(target):
		open()
		get_viewport().set_input_as_handled()


func _steer(g: Dictionary) -> void:
	var turn: Vector2 = g.orbit
	var pan: Vector2 = g.pan
	var zoom: float = g.zoom
	if _fixed and (turn != Vector2.ZERO or pan != Vector2.ZERO or zoom != 1.0):
		_free_camera()   # M4 H: the child takes over the team photo's camera
	if turn != Vector2.ZERO:
		orbit.orbit(turn)
	if zoom != 1.0:
		orbit.zoom(zoom)
	if pan != Vector2.ZERO:
		orbit.pan_by(pan)


func _process(_delta: float) -> void:
	if not _open:
		return
	if not is_instance_valid(target):   # a LAN client's own player goes when the host quits
		close()
		return
	if _prewarm_left > 0:
		_prewarm_left -= 1
		if _prewarm_left == 0:
			_apply_filter()
	if _held:
		_vr_step()
		return
	_place_camera()


func _place_camera() -> void:
	if _fixed:
		camera.global_transform = fixed_view   # M4 H: the team photo's camera
		return
	camera.global_transform = orbit.place(head_position(), is_solid)


func _on_player_hurt(pid: int, hp: int, _from: Vector3) -> void:
	if pid != peer_id:
		return
	if _open and PhotoRules.exits_on_hurt(_hp, hp):
		close()
	_hp = hp


## Leaving the world with photo mode open (a LAN host quitting) must not leave the game paused.
func _exit_tree() -> void:
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false
		_paused_by_me = false


# --- The player in the picture ----------------------------------------------------------------

func _size_scale() -> float:
	return target.call(&"size_scale") if target.has_method(&"size_scale") else 1.0


func _target_hp() -> int:
	return (target as Player).health.hp if target is Player else -1


## Your own body is always in the picture (even from first person), and the block highlight, the
## mirror wall and building stay out of it.
func _hide_build_helpers() -> void:
	_hidden_helpers.clear()
	_interactor = null
	if not target is Player:
		return
	var p := target as Player
	p.photo_mode = true
	p.avatar.visible = true   # a paused player doesn't update it
	_interactor = p.get_node_or_null("BlockInteractor")
	if _interactor == null:
		return
	_interactor_mode = _interactor.process_mode
	_interactor.process_mode = Node.PROCESS_MODE_DISABLED
	for helper_name: String in ["TargetHighlight", "MirrorWall"]:
		var helper := _interactor.get_node_or_null(helper_name) as Node3D
		if helper:
			_hidden_helpers[helper] = helper.visible
			helper.visible = false


func _restore_build_helpers() -> void:
	for helper in _hidden_helpers:
		if is_instance_valid(helper):
			(helper as Node3D).visible = _hidden_helpers[helper]
	_hidden_helpers.clear()
	if is_instance_valid(_interactor):
		_interactor.process_mode = _interactor_mode
	_interactor = null
	if is_instance_valid(target) and target is Player:
		(target as Player).photo_mode = false


# --- Look ---------------------------------------------------------------------------------------

func _apply_filter() -> void:
	var params := PhotoFilters.params(filter)
	for key: String in params:
		_material.set_shader_parameter(key, params[key])
	filter_rect.visible = _open and (PhotoFilters.uses_shader(filter) or _prewarm_left > 0)
	for id: int in _filter_chips:
		(_filter_chips[id] as PhotoChip).selected = id == filter


func _flash_screen() -> void:
	_flash.color.a = 0.85
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, FLASH_SECONDS).set_ease(Tween.EASE_OUT)


func _say(text: String, seconds: float = 3.0) -> void:
	_message.text = text
	_message.visible = true
	_message.modulate.a = 1.0
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(seconds)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.4)
	_message_tween.tween_callback(func() -> void: _message.visible = false)


func _show_hint() -> void:
	_hint.text = HINT_TOUCH if PlatformRules.touch_device(PlatformRules.current()) else HINT_DESKTOP
	_hint.visible = true
	_hint.modulate.a = 1.0
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(HINT_SECONDS)
	_hint_tween.tween_property(_hint, "modulate:a", 0.0, 0.6)


# --- Layout (1280 x 720 design space, corner anchors like the HUD) ---------------------------

func _build_controls() -> void:
	_close_button.glyph = PhotoChip.Glyph.CLOSE
	_chip(_close_button, "", Vector2(0, 0), Vector2(18, 18), Vector2(96, 96))
	_close_button.pressed.connect(close)
	_shutter_button.glyph = PhotoChip.Glyph.SHUTTER
	_chip(_shutter_button, "", Vector2(1, 0.5), Vector2(-178, -80), Vector2(150, 150))
	_shutter_button.pressed.connect(take_photo)
	_share_button.round_shape = false
	_share_button.font_size = 24
	_chip(_share_button, PhotoShare.button_label(save_way), Vector2(1, 0.5), Vector2(-178, 90), Vector2(150, 70))
	_share_button.pressed.connect(share)
	for i in PhotoFilters.ORDER.size():
		var id: int = PhotoFilters.ORDER[i]
		var c := PhotoChip.new()
		c.swatch = PhotoFilters.SWATCHES[id]
		_filter_chip(c, PhotoFilters.LABELS[id], Vector2(0, 1), Vector2(18 + i * 114, -88))
		c.pressed.connect(set_filter.bind(id))
		_filter_chips[id] = c
	for i in PhotoFrames.ORDER.size():
		var id: int = PhotoFrames.ORDER[i]
		var c := PhotoChip.new()
		_filter_chip(c, PhotoFrames.LABELS[id], Vector2(1, 1), Vector2(-578 + i * 114, -88))
		c.pressed.connect(set_frame.bind(id))
		_frame_chips[id] = c
	_label(_hint, Vector2(-500, 22), Vector2(1000, 40), 24)
	_label(_message, Vector2(-500, 70), Vector2(1000, 50), 30)
	_message.visible = false
	set_filter(filter)
	set_frame(frame)


func _filter_chip(c: PhotoChip, text: String, anchor: Vector2, offset: Vector2) -> void:
	c.round_shape = false
	c.font_size = 20
	_chip(c, text, anchor, offset, Vector2(104, 70))


func _chip(c: PhotoChip, text: String, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	c.text = text
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y
	controls.add_child(c)


func _label(l: Label, offset: Vector2, size: Vector2, font_size: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = offset.x
	l.offset_top = offset.y
	l.offset_right = offset.x + size.x
	l.offset_bottom = offset.y + size.y
	controls.add_child(l)


func _full_screen(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# --- M4 H: the team photo after a boss ------------------------------------------------------------

## The team photo's camera (GamesDirector's line-up, TeamPhoto.camera_view), in front of the line; it
## holds until the child steers (then the orbit takes over from there) or leaves.
var fixed_view := Transform3D()
var _fixed := false


## Opens photo mode looking at the team from `view` (the stars frame on), takes the picture and stays
## open, so the child can take more or SHARE it (only their own share button ever shares it).
func take_team_photo(view: Transform3D) -> void:
	if not view.origin.is_finite():
		return
	open()
	if not _open:
		return
	fixed_view = view
	_fixed = true
	set_frame(PhotoFrames.Frame.STARS)
	if _held:
		_vr_step()   # owner #101: the held camera at the team photo's place
	else:
		_place_camera()
	await take_photo()


func _free_camera() -> void:
	_fixed = false
	orbit = PhotoOrbit.from_camera(camera.global_transform, head_position(), _size_scale())

# --- M3 Task 21b: the Memory Book keeps a small copy of a photo taken soon after a big moment ---

## The last saved photo's PNG (empty before one): read when photo_saved fires.
func last_png() -> PackedByteArray:
	return _last_png

# --- Owner #101: PHOTO in a headset, a camera held in the hand (P3; docs/devlog/parts/vr-rig.md) ---------------------

## The headset's PHOTO: a camera in the pointing hand over the same world (its little screen above the hand), the filter
## and the frame drawn into its picture, the child's own avatar seen by it alone (a selfie; never from inside the head).
func _vr_open() -> void:
	_held = VrPhotoCamera.new()
	target.add_child(_held)
	_held.use_world(target.get_world_3d())
	for c: Control in [filter_rect, frame_overlay]:
		_held_moved[c] = [c.get_parent(), c.get_index()]
		c.reparent(_held.viewport, false)
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_held_trigger = Vr.trigger(Vr.pointing_hand()) >= VrRules.TRIGGER_ON   # a squeeze that opened it never shoots
	_vr_selfie(true)
	_vr_step()


func _vr_close() -> void:
	if _held == null:
		return
	_vr_selfie(false)
	for c: Control in _held_moved:
		if is_instance_valid(c):
			var back: Array = _held_moved[c]
			c.reparent(back[0], false)
			(back[0] as Node).move_child(c, mini(int(back[1]), (back[0] as Node).get_child_count() - 1))
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_held_moved.clear()
	if is_instance_valid(_held):
		_held.queue_free()
	_held = null


## Every frame: the lens on the pointing hand (a team photo's fixed view instead), the screen to the eyes; a squeeze of
## the pointing trigger takes the picture.
func _vr_step() -> void:
	var lens := camera.global_transform
	var ray := Vr.pointer_ray()
	if _fixed:
		lens = fixed_view   # M4 H: the team photo's camera
	elif not ray.is_empty():
		var ahead: Vector3 = ray[1]
		lens = Transform3D(Basis.looking_at(ahead, Vector3.UP if absf(ahead.y) < 0.99 else Vector3.BACK), ray[0])
	_held.place(lens, Vr.head_transform().origin)
	var down := VrRules.trigger_down(Vr.trigger(Vr.pointing_hand()), _held_trigger)
	if down and not _held_trigger:
		take_photo()
	_held_trigger = down


## The avatar's meshes on their own layer (VrPhotoCamera.SELF_LAYER) while PHOTO is open: the held camera sees it, the
## head does not.
func _vr_selfie(on: bool) -> void:
	if target is Player and target == Vr.local_player():
		Vr.show_self(on, &"photo")   # P4: one place for the photo's selfie and the mirror


## The held camera (tests; null off VR or closed).
func held_camera() -> VrPhotoCamera:
	return _held
