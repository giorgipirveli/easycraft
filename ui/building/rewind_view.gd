class_name RewindView
extends Control
## Build Rewind's time-lapse (M3 Task 8; spec §14.5, §3a): a full-screen view that plays a RewindLog in at most
## 20 s on a stage of its own (RewindPreview in its own World3D, in a SubViewport), seen through a camera orbiting
## the build (PhotoOrbit, M3 Task 16). It never touches the game's world; while it shows, the game's own 3D view
## is not drawn (Viewport.disable_3d) and solo play pauses (PhotoRules, like photo mode). AGAIN plays it from the
## start, NEW forgets the recording (the next REWIND tap starts one), CLOSE goes back to the game.
## M5: a video export through the share sheet goes behind SHARE (hidden until VIDEO_EXPORT; export_video()).

signal restart_requested
signal closed

## The HUD under the view (the sandbox's): hidden while the view shows, as photo mode does (a HUD button's touch
## is read before any GUI control, so a tap on AGAIN would also press the hotbar under it; DEVELOPMENT.md §8).
var hud: Control
var _hud_was_visible := true

const END_PAUSE := 1.5          # the finished build stays a moment before the replay stops
const ORBIT_SPEED := 0.45       # radians a second
const PITCH := -0.5
const VIDEO_EXPORT := false     # M5 turns it on with export_video()
const NOTHING_YET := "Nothing built here yet! Build near the spot, then tap with REWIND again."
const SKY := Color("9fd3ff")

var viewport := SubViewport.new()
var camera := Camera3D.new()
var preview := RewindPreview.new()
var orbit := PhotoOrbit.new()
var playing := false
var share_button := UiKit.big_button("SHARE", UiKit.ORANGE, Vector2(200, 96))

var _record: RewindLog
var _t := 0.0
var _centre := Vector3.ZERO
var _paused_by_me := false
var _3d_hidden := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # the whole screen: nothing behind it takes a tap
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.12, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 24
	frame.offset_top = 84
	frame.offset_right = -24
	frame.offset_bottom = -132
	viewport.own_world_3d = true   # the stage's own world: the game's world is never in it
	viewport.handle_input_locally = false
	frame.add_child(viewport)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.7
	env.environment = e
	viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 0.9
	viewport.add_child(sun)
	camera.current = true
	viewport.add_child(camera)
	viewport.add_child(preview)
	var title := Label.new()
	title.text = "BUILD REWIND"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffd23f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 18
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
	var again_button := UiKit.big_button("AGAIN", UiKit.GREEN, Vector2(220, 96))
	again_button.name = "Again"
	again_button.pressed.connect(again)
	var new_button := UiKit.big_button("NEW", UiKit.ORANGE, Vector2(200, 96))
	new_button.name = "New"
	new_button.pressed.connect(new_recording)
	var close_button := UiKit.big_button("CLOSE", UiKit.BLUE, Vector2(220, 96))
	close_button.name = "Close"
	close_button.pressed.connect(close)
	share_button.name = "Share"
	share_button.visible = VIDEO_EXPORT
	share_button.pressed.connect(export_video)
	var row := OnlineUi.row([again_button, new_button, share_button, close_button], 24)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -116
	row.offset_bottom = -16
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(row)


## Plays `r` from the start (false, and nothing shows, when nothing is recorded yet).
func open(r: RewindLog) -> bool:
	if r == null or r.size() == 0:
		return false
	_record = r
	preview.setup(r)
	var b := preview.bounds()
	_centre = b.get_center()
	orbit.pitch = PITCH
	orbit.yaw = 0.6
	orbit.distance = maxf(b.size.length() * 1.1, 6.0)
	again()
	visible = true
	_paused_by_me = PhotoRules.pauses_world(Game.net_mode) and is_inside_tree() and not get_tree().paused
	if _paused_by_me:
		get_tree().paused = true
	if is_inside_tree() and not get_viewport().disable_3d:
		get_viewport().disable_3d = true   # the game's world is hidden behind the view: don't draw it
		_3d_hidden = true
	if is_instance_valid(hud):
		_hud_was_visible = hud.visible
		hud.propagate_notification(NOTIFICATION_PAUSED)   # let go of every finger, as pausing does
		hud.visible = false
	step(0.0)
	return true


func again() -> void:
	_t = 0.0
	preview.seek(0)
	playing = true


func _process(delta: float) -> void:
	if visible:
		step(delta)


## Moves the replay and the camera on by `delta` seconds.
func step(delta: float) -> void:
	if _record == null:
		return
	if playing:
		_t += delta
		preview.seek(_record.shown_at(_t))
		if _t >= _record.duration() + END_PAUSE:
			playing = false
	orbit.yaw = wrapf(orbit.yaw + delta * ORBIT_SPEED, -PI, PI)
	camera.transform = orbit.place(_centre, func(_c: Vector3i) -> bool: return false)


func close() -> void:
	if not visible:
		return
	visible = false
	playing = false
	_restore()
	closed.emit()


## NEW: forget this recording; the next REWIND tap starts a new one.
func new_recording() -> void:
	close()
	restart_requested.emit()


## M5: a video of the time-lapse through the share sheet. Not built yet.
func export_video() -> bool:
	return false


## The view's controls, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [self]


func _restore() -> void:
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false
	_paused_by_me = false
	if _3d_hidden and is_inside_tree():
		get_viewport().disable_3d = false
	_3d_hidden = false
	if is_instance_valid(hud) and not hud.visible:
		hud.visible = _hud_was_visible


func _exit_tree() -> void:
	_restore()   # leaving the world with the view open must not leave the game paused or blind
