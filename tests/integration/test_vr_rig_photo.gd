extends GutTest
## Owner #101 (VR on the Meta Quest), P3: PHOTO in a headset is a camera held in the pointing hand (VrPhotoCamera): its
## lens on the hand's aim, its little screen above the hand facing the eyes, the head still the view (no orbit), the
## trigger takes the picture from the held camera (its size, its filter and frame), the child's own avatar seen by the
## held camera alone (a selfie, never from inside the head), and everything put back when PHOTO closes.

const T := {"year": 2026, "month": 10, "day": 15, "hour": 12, "minute": 0, "second": 1}

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


var DIR := "user://test_vr_photos_%d/" % OS.get_process_id()
var p: Player
var photo: PhotoMode
var hud: Control
var _net_mode: StringName


func before_each() -> void:
	_net_mode = Game.net_mode
	Game.net_mode = &"host"   # nothing pauses (a paused tree stops GUT's awaits)
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true
	p.global_position = Vector3(0.5, 80, 0.5)
	hud = Control.new()
	add_child_autofree(hud)
	photo = PhotoMode.new()
	add_child_autofree(photo)
	photo.setup(p, hud, func(c: Vector3i) -> bool: return c.y < 80)
	photo.folders = PackedStringArray([DIR])
	photo.clock = func() -> Dictionary: return T
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	Vr.step_physics()
	Vr.step(0.016)
	# the right hand held out ahead, pointing a little to the left
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.2, 1.2, -0.35)))


func after_each() -> void:
	photo.close()
	Vr.simulate(false)
	Vr.anchor(null)
	Game.net_mode = _net_mode
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))
		DirAccess.remove_absolute(DIR)


func test_photo_is_a_camera_held_in_the_hand_and_the_head_stays_the_view() -> void:
	photo.open()
	var held := photo.held_camera()
	assert_not_null(held, "a camera in the hand")
	Vr.step(0.016)
	assert_eq(get_viewport().get_camera_3d(), Vr.camera, "the head is still the view: no orbit round the player")
	var ray := Vr.pointer_ray()
	assert_almost_eq(held.camera.global_position.distance_to(ray[0]), 0.0, 0.001, "the lens on the hand")
	assert_almost_eq((-held.camera.global_basis.z).angle_to(ray[1]), 0.0, 0.001, "looking where the hand points")
	var to_eyes := Vr.head_transform().origin - held.screen.global_position
	assert_gt(held.screen.global_basis.z.dot(to_eyes.normalized()), 0.9, "its little screen faces the eyes")
	assert_eq(held.viewport.world_3d, p.get_world_3d(), "it sees the same world")


func test_the_held_camera_follows_the_hand() -> void:
	photo.open()
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(Vector3.UP, -0.8), Vector3(-0.1, 1.0, -0.3)))
	photo._process(0.016)
	var ray := Vr.pointer_ray()
	assert_almost_eq(photo.held_camera().camera.global_position.distance_to(ray[0]), 0.0, 0.001)


func test_the_trigger_takes_the_picture_from_the_held_camera() -> void:
	photo.open()
	watch_signals(photo)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	photo._process(0.016)
	await wait_for_signal(photo.photo_saved, 5.0)
	assert_signal_emitted(photo, "photo_saved")
	var img := Image.load_from_file(ProjectSettings.globalize_path(photo.last_path))
	assert_not_null(img)
	assert_eq(img.get_size(), VrPhotoCamera.SIZE, "the held camera's picture, not the headset's view")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)


func test_a_squeeze_held_when_photo_opens_never_shoots() -> void:
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	photo.open()
	watch_signals(photo)
	photo._process(0.016)
	assert_signal_not_emitted(photo, "shutter", "only a new squeeze takes a picture")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)


func test_the_filter_and_frame_draw_into_the_held_picture_and_come_back() -> void:
	var filter_parent := photo.filter_rect.get_parent()
	photo.open()
	var held := photo.held_camera()
	assert_eq(photo.filter_rect.get_parent(), held.viewport, "the filter is in its picture")
	assert_eq(photo.frame_overlay.get_parent(), held.viewport, "the frame too")
	photo.close()
	assert_eq(photo.filter_rect.get_parent(), filter_parent, "back where they were")
	assert_eq(photo.frame_overlay.get_parent(), filter_parent)
	assert_null(photo.held_camera(), "the held camera is gone")


func test_only_the_held_camera_sees_the_childs_own_avatar() -> void:
	photo.open()
	var meshes := p.avatar.find_children("*", "VisualInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	for m: Node in meshes:
		assert_eq((m as VisualInstance3D).layers, VrPhotoCamera.SELF_LAYER, "%s: the selfie's layer" % m.name)
	assert_eq(Vr.camera.cull_mask & VrPhotoCamera.SELF_LAYER, 0, "never seen from inside the head")
	photo.close()
	for m: Node in meshes:
		assert_ne((m as VisualInstance3D).layers, VrPhotoCamera.SELF_LAYER, "%s: its own layers again" % m.name)
	assert_ne(Vr.camera.cull_mask & 1, 0)


func test_off_vr_photo_is_the_orbit_as_before() -> void:
	Vr.simulate(false)
	photo.open()
	assert_null(photo.held_camera())
	assert_eq(get_viewport().get_camera_3d(), photo.camera, "the photo's own orbit camera")
