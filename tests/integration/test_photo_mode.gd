extends GutTest
## Photo mode (M3 Task 16, spec §14.14): the HUD hides, a free camera looks at the player, filters
## share one material, frames are drawn by the UI, the shutter saves a PNG of the screen without the
## buttons, and closing restores the camera and the HUD exactly. Solo play pauses the world; LAN never
## does, and a hit there drops the player out of photo mode. Runs in its own 1280x720 SubViewport.

const SCREEN := Vector2i(1280, 720)
const MIDDLE := Vector2(560, 300)   # clear of every photo-mode button
const F := PhotoFilters.Filter
const T := {"year": 2026, "month": 9, "day": 24, "hour": 12, "minute": 0, "second": 1}

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_photos_%d/" % OS.get_process_id()

var view: SubViewport
var game_cam: Camera3D
var target: Node3D
var hud: Control
var hud_part: Control
var photo: PhotoMode
var _net_mode: StringName


static func _ground(cell: Vector3i) -> bool:
	return cell.y < 10


func before_each() -> void:
	_net_mode = Game.net_mode
	Game.net_mode = &"host"   # nothing pauses unless a test says solo (a paused tree stops GUT's awaits)
	view = SubViewport.new()
	view.size = SCREEN
	add_child_autofree(view)
	target = Node3D.new()
	view.add_child(target)
	target.position = Vector3(0.5, 10.0, 0.5)
	game_cam = Camera3D.new()
	view.add_child(game_cam)
	var b := Basis.from_euler(Vector3(-0.35, 0.6, 0.0))
	game_cam.global_transform = Transform3D(b, target.position + Vector3(0, PhotoMode.HEAD_HEIGHT, 0) + b * Vector3(0, 0, 4.5))
	game_cam.make_current()
	hud = Control.new()
	view.add_child(hud)
	hud_part = Control.new()
	hud_part.visible = false
	hud.add_child(hud_part)
	photo = PhotoMode.new()
	view.add_child(photo)
	photo.setup(target, hud, _ground)
	photo.folders = PackedStringArray([DIR])


func after_each() -> void:
	get_tree().paused = false
	Game.net_mode = _net_mode
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		DirAccess.remove_absolute(DIR)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	view.push_input(t, true)


func _drag(index: int, from: Vector2, to: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = to
	d.relative = to - from
	view.push_input(d, true)


func _action(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	view.push_input(e)


func _shoot() -> String:
	photo.take_photo()
	await wait_for_signal(photo.photo_saved, 10, "the photo is saved")
	return photo.last_path


func test_opening_hides_the_hud_and_looks_through_the_photo_camera() -> void:
	photo.open()
	assert_true(photo.is_open())
	assert_true(photo.visible)
	assert_false(hud.visible)
	assert_same(view.get_camera_3d(), photo.camera)
	photo.close()


func test_the_photo_camera_starts_where_the_game_camera_was() -> void:
	photo.open()
	assert_almost_eq(photo.camera.global_position.distance_to(game_cam.global_position), 0.0, 0.01)
	photo.close()


func test_closing_restores_the_camera_and_the_hud_exactly() -> void:
	var cam_before := game_cam.global_transform
	photo.open()
	photo.orbit.orbit(Vector2(300, 80))
	photo.orbit.zoom(0.5)
	photo.orbit.pan_by(Vector2(40, 0))
	photo.set_filter(F.COMIC)
	photo.set_frame(PhotoFrames.Frame.FILM)
	photo.close()
	assert_false(photo.is_open())
	assert_false(photo.visible)
	assert_true(hud.visible)
	assert_false(hud_part.visible, "the HUD's own hidden parts stay hidden")
	assert_same(view.get_camera_3d(), game_cam)
	assert_eq(game_cam.global_transform, cam_before)


func test_a_hidden_hud_stays_hidden() -> void:
	hud.visible = false
	photo.open()
	photo.close()
	assert_false(hud.visible)


func test_solo_play_pauses_the_world_while_open() -> void:
	Game.net_mode = &"solo"
	photo.open()
	assert_true(get_tree().paused)
	assert_eq(photo.process_mode, Node.PROCESS_MODE_ALWAYS, "photo mode itself keeps running")
	photo.close()
	assert_false(get_tree().paused)


func test_lan_play_never_pauses() -> void:
	photo.open()
	assert_false(get_tree().paused)
	photo.close()


func test_a_game_paused_before_stays_paused() -> void:
	Game.net_mode = &"solo"
	get_tree().paused = true
	photo.open()
	photo.close()
	assert_true(get_tree().paused)


func test_filters_share_one_material() -> void:
	photo.open()
	var mat := photo.filter_rect.material as ShaderMaterial
	assert_not_null(mat)
	for f: int in PhotoFilters.ORDER:
		photo.set_filter(f)
		assert_same(photo.filter_rect.material, mat, "filter %d" % f)
	photo.set_filter(F.WARM)
	assert_eq(mat.get_shader_parameter("tint"), PhotoFilters.params(F.WARM).tint)
	assert_eq(mat.get_shader_parameter("saturation"), PhotoFilters.params(F.WARM).saturation)
	await wait_process_frames(PhotoMode.PREWARM_FRAMES + 1)
	assert_true(photo.filter_rect.visible)
	photo.set_filter(F.NORMAL)
	assert_false(photo.filter_rect.visible, "the normal picture costs no extra pass")
	photo.close()


func test_the_filter_shader_is_drawn_once_as_photo_mode_opens() -> void:
	photo.open()
	assert_true(photo.filter_rect.visible, "compiled while the HUD hides, not on the first filter tap")
	await wait_process_frames(PhotoMode.PREWARM_FRAMES + 1)
	assert_false(photo.filter_rect.visible)
	photo.close()


func test_frames_are_drawn_over_the_picture() -> void:
	photo.open()
	photo.set_frame(PhotoFrames.Frame.FILM)
	assert_eq(photo.frame_overlay.frame, PhotoFrames.Frame.FILM)
	assert_true(photo.frame_overlay.visible)
	photo.set_frame(PhotoFrames.Frame.NONE)
	assert_false(photo.frame_overlay.visible)
	photo.close()


func test_a_photo_is_saved_with_the_size_of_the_screen() -> void:
	photo.open()
	var path: String = await _shoot()
	assert_true(path.begins_with(DIR), path)
	assert_true(FileAccess.file_exists(path))
	var img := Image.load_from_file(path)
	assert_not_null(img)
	if img:
		assert_eq(img.get_size(), SCREEN)
	photo.close()


func test_two_photos_in_one_second_never_overwrite() -> void:
	photo.clock = func() -> Dictionary: return T
	photo.open()
	var first: String = await _shoot()
	var second: String = await _shoot()
	assert_ne(first, second)
	assert_true(FileAccess.file_exists(first))
	assert_true(FileAccess.file_exists(second))
	assert_string_contains(first, "EasyCraft_20260924_120001")
	photo.close()


func test_the_buttons_are_left_out_of_the_photo_but_the_frame_is_in() -> void:
	var seen: Array[bool] = []
	photo.shutter.connect(func() -> void: seen.append_array([photo.controls.visible, photo.frame_overlay.visible]))
	photo.open()
	photo.set_frame(PhotoFrames.Frame.STARS)
	await _shoot()
	assert_eq(seen, [false, true] as Array[bool])
	assert_true(photo.controls.visible, "the buttons come back")
	photo.close()


func test_a_hit_on_lan_drops_out_of_photo_mode() -> void:
	photo.peer_id = 42
	photo.open()
	Session.player_hurt.emit(42, 9, Vector3.ZERO)   # hearts come in: nothing lost yet
	Session.player_hurt.emit(7, 1, Vector3.ZERO)    # someone else was hit
	assert_true(photo.is_open())
	Session.player_hurt.emit(42, 7, Vector3.ZERO)
	assert_false(photo.is_open())
	assert_true(hud.visible)


func test_one_finger_turns_and_two_fingers_zoom() -> void:
	photo.open()
	var yaw := photo.orbit.yaw
	_touch(0, MIDDLE, true)
	_drag(0, MIDDLE, MIDDLE + Vector2(60, 0))
	_touch(0, MIDDLE + Vector2(60, 0), false)
	assert_ne(photo.orbit.yaw, yaw, "one finger orbits")
	var distance := photo.orbit.distance
	_touch(1, MIDDLE, true)
	_touch(2, MIDDLE + Vector2(50, 0), true)
	_drag(2, MIDDLE + Vector2(50, 0), MIDDLE + Vector2(100, 0))
	assert_lt(photo.orbit.distance, distance, "spreading two fingers comes closer")
	_touch(1, MIDDLE, false)
	_touch(2, MIDDLE + Vector2(100, 0), false)
	photo.close()


func test_the_mouse_wheel_zooms_on_desktop() -> void:
	photo.open()
	var distance := photo.orbit.distance
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = MIDDLE
	view.push_input(wheel, true)
	assert_lt(photo.orbit.distance, distance)
	photo.close()


func test_escape_leaves_photo_mode() -> void:
	photo.open()
	_action(&"pause")
	assert_false(photo.is_open())
	assert_true(hud.visible)


func test_the_photo_key_opens_and_closes_photo_mode() -> void:
	assert_true(InputMap.has_action(&"photo"), "P on desktop")
	_action(&"photo")
	assert_true(photo.is_open())
	_action(&"photo")
	assert_false(photo.is_open())


func test_the_player_is_in_the_picture_even_from_first_person() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"   # this device's own player
	add_child_autofree(p)
	p.toggle_camera()   # first person hides your own body
	p._process(0.016)
	assert_false(p.avatar.visible)
	p.photo_mode = true
	p._process(0.016)
	assert_true(p.avatar.visible)
