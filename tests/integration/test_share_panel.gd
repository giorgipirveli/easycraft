extends GutTest
## SHARE in a world (M4 Wave 3, agent I; spec §17.5): GIFT A BUILD (a tap picks the connected build, it
## glows, SEND TO A FRIEND) and MY SHOWCASE (the golden frame around the child, SHOW IT), through the
## real OnlineService against the fake server; a stand-in world of cells; the panel lets go of the world's
## taps when it closes. SHARE is offered only in the child's own world, signed in with friends allowed.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_share_panel_%d/" % OS.get_process_id()
var server: RefCounted
var service: OnlineService
var panel: SharePanel
var world: CellWorld
var spot: Node3D
var interactor: BlockInteractor
var toasts: Array = []


## Stands in for the terrain: flat grass under y 10, and the test's cells; one bulk copy like the real one.
class CellWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for x in size.x:
			for y in size.y:
				for z in size.z:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	var me: String = server.make_account("dev-me", "Hopper")
	var mia: String = server.make_account("dev-mia", "Mia_2")
	server.befriend(me, mia)
	service = OnlineService.new()
	service.backend = FakeBackend.new(server)
	service.device_id = "dev-me"
	service.profile = ProfileData.new()
	service.profile.username = "Hopper"
	service.save_profile = func() -> void: pass
	service.prefs_path = DIR + "me.json"
	service.gift_book = GiftStampBook.new()
	service.gift_book_path = DIR + "gifts.json"
	add_child_autofree(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await service.sign_in(), "")
	world = CellWorld.new()
	add_child_autofree(world)
	spot = Node3D.new()
	add_child_autofree(spot)
	spot.global_position = Vector3(0.5, 10.0, 0.5)
	interactor = BlockInteractor.new()
	autofree(interactor)
	panel = SharePanel.new()
	panel.service = service
	panel.world = world
	panel.player = spot
	panel.interactor = interactor
	panel.outline = BuildOutline.new()
	add_child_autofree(panel.outline)
	panel.player_toast = func(t: String) -> void: toasts.append(t)
	add_child_autofree(panel)
	toasts.clear()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _tower(at: Vector3i, height: int) -> void:
	for y in height:
		world.cells[at + Vector3i(0, y, 0)] = BlockIds.PLANKS


func _press(name_pattern: String) -> void:
	var b := panel.find_child(name_pattern, true, false) as Button
	assert_not_null(b, name_pattern)
	if b:
		b.pressed.emit()


func test_gift_a_build_picks_it_glows_and_goes_to_the_friend() -> void:
	_tower(Vector3i(3, 10, 3), 3)
	panel.open()
	assert_eq(panel.step, SharePanel.CHOOSE)
	_press("GiftABuild")
	assert_eq(panel.step, SharePanel.PICK)
	assert_true(interactor.tap_override.is_valid(), "the next tap on the world picks")
	panel.pick_cell(Vector3i(3, 11, 3))
	assert_eq(panel.step, SharePanel.PICKED)
	assert_eq((panel.picked.blocks as Dictionary).size(), 3)
	assert_not_null(panel.outline.mesh, "the build glows")
	assert_eq(panel.outline.material_override, BuildOutline.material(), "one shared material")
	_press("SendToAFriend")
	assert_false(interactor.tap_override.is_valid(), "choosing a friend: the world's taps are its own again")
	_press("Friend_Mia_2")
	await wait_until(func() -> bool: return not panel.visible, 5.0)
	var got: Array = server.gifts.get(server.id_of("Mia_2"), [])
	assert_eq(got.size(), 1)
	assert_eq(BuildCodec.count_of(got[0].build), 3)
	assert_eq(toasts, ["Your present is on its way to Mia_2!"])
	assert_null(panel.outline.mesh, "the glow goes when the panel closes")


func test_the_ground_or_a_too_big_build_says_so_and_keeps_picking() -> void:
	panel.open()
	panel.start_pick()
	panel.pick_cell(Vector3i(0, 9, 0))
	assert_eq(panel.message.text, BuildPicker.message("not_a_build"))
	_tower(Vector3i(5, 10, 5), 9)
	panel.pick_cell(Vector3i(5, 10, 5))
	assert_eq(panel.message.text, BuildPicker.message("too_big"))
	assert_eq(panel.step, SharePanel.PICK, "still picking")
	panel.close()
	assert_false(interactor.tap_override.is_valid())


func test_my_showcase_frames_the_area_and_puts_it_up_with_my_buddy() -> void:
	_tower(Vector3i(2, 10, -2), 4)
	var buddy_blocks := {Vector3i(0, 0, 0): BlockIds.CRYSTAL}
	panel.own_buddies = func() -> Array: return [{"blocks": buddy_blocks, "pos": Vector3(4.5, 10.0, 4.5)}]
	panel.open()
	_press("MyShowcase")
	assert_eq(panel.step, SharePanel.AREA)
	assert_eq(panel.area.size, Vector3i(32, 32, 32))
	assert_not_null(panel.outline.mesh, "the golden frame")
	_press("ShowIt")
	await wait_until(func() -> bool: return not panel.visible, 10.0)
	var up: Dictionary = server.showcases.get(server.id_of("Hopper"), {})
	assert_false(up.is_empty(), "the showcase is on the server")
	var blocks := BuildCodec.decode(up.build, BuildCodec.SHOWCASE)
	var b := ShowcaseArea.BELOW
	assert_eq(blocks.get(Vector3i(2 + 16, b, -2 + 16)), BlockIds.PLANKS, "the tower is in it (the area starts 16 west and north, 8 down)")
	assert_eq(up.buddy.at, [4 + 16, b, 4 + 16], "my buddy waits in it")
	assert_eq(toasts, ["Your showcase is up! Friends can visit it now."])


## M4 Task 10 review: CANCEL while "One moment..." (the area's copy is read on a worker for a few frames) put the
## showcase up anyway, and with a buddy nearby read the cleared area (a SCRIPT ERROR). A cancelled share
## shares nothing.
func test_cancel_while_the_area_is_read_shares_nothing() -> void:
	_tower(Vector3i(2, 10, -2), 4)
	panel.own_buddies = func() -> Array: return [{"blocks": {Vector3i(0, 0, 0): BlockIds.CRYSTAL}, "pos": Vector3(4.5, 10.0, 4.5)}]
	panel.open()
	_press("MyShowcase")
	_press("ShowIt")   # the snapshot starts ...
	_press("Cancel")   # ... and the child changes their mind before it is read
	assert_false(panel.visible)
	await wait_frames(10)
	assert_false(server.showcases.has(server.id_of("Hopper")), "nothing went up")
	assert_false(server.calls.has("publish_showcase"))
	assert_eq(toasts, [], "no 'Your showcase is up!'")
	panel.open()
	_press("MyShowcase")
	_press("ShowIt")
	await wait_until(func() -> bool: return not panel.visible, 10.0)
	assert_true(server.showcases.has(server.id_of("Hopper")), "SHOW IT works again afterwards")


func test_share_is_offered_only_in_my_own_world_with_friends_allowed() -> void:
	assert_true(SharePanel.offered(service, false))
	assert_false(SharePanel.offered(service, true), "a guest in a friend's world")
	assert_false(SharePanel.offered(null, false), "never online")
	service.sign_out()
	assert_false(SharePanel.offered(service, false), "signed out")
	assert_true(HudIcons.knows(&"gift"), "SHARE's picture")


func test_the_picking_bar_stays_clear_of_the_hud_buttons() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	_tower(Vector3i(3, 10, 3), 3)
	await wait_process_frames(2)
	panel.open()
	for step: Callable in [panel.start_pick, panel.pick_cell.bind(Vector3i(3, 10, 3)), panel.start_area]:
		step.call()
		await wait_process_frames(2)
		var bar: Control = panel.blockers()[0]
		for b: Control in hud.find_children("*", "TouchButton", true, false):
			if b.visible and b.get_parent() == hud:
				assert_false(bar.get_global_rect().intersects(b.get_global_rect()), "%s: the bar and %s: %s %s" % [panel.step,
					b.name, bar.get_global_rect(), b.get_global_rect()])
