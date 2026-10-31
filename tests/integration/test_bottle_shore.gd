extends GutTest
## Friends' bottles (M4 Wave 3, agent I; research D5): when the child plays, every bottle waiting on the
## server floats up on the water nearest to them (else the beach, else the ground); a tap opens it (the
## secret things' tap: whatever is in the hand); the card shows who sent it and what it says, a tiny
## build becomes a gift stamp; REPORT keeps it for the reviewer. Only this child's game has them.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_bottle_shore_%d/" % OS.get_process_id()
var server: RefCounted
var me: OnlineService
var pip: OnlineService
var world: WaterWorld
var body: Node3D
var shore: BottleShore


## A sea west of x = -3 (the water's top at y 9), sand beside it, grass east; all loaded.
class WaterWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		if pos.y > 9:
			return BlockIds.AIR
		if pos.x < -3:
			return BlockIds.WATER if pos.y == 9 else BlockIds.SAND
		return BlockIds.SAND if pos.x < 0 and pos.y == 9 else BlockIds.GRASS

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
	me = await _player("dev-me", "Hopper")
	pip = await _player("dev-pip", "Pip_7")
	server.befriend(me.backend.user_id(), pip.backend.user_id())
	world = WaterWorld.new()
	add_child_autofree(world)
	body = Node3D.new()   # where the child stands
	add_child_autofree(body)
	body.global_position = Vector3(2.5, 10.0, 0.5)
	shore = BottleShore.new()
	shore.world = world
	shore.player = body
	shore.service = me
	add_child_autofree(shore)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _player(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.gift_book = GiftStampBook.new()
	s.gift_book_path = DIR + device + "_gifts.json"
	add_child_autofree(s)
	s.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await s.sign_in(), "")
	return s


func _tiny() -> String:
	return BuildCodec.encode({Vector3i.ZERO: BlockIds.BLUE, Vector3i(0, 1, 0): BlockIds.YELLOW})


func test_waiting_bottles_float_up_on_the_nearest_water_apart() -> void:
	await pip.send_bottle(me.backend.user_id(), "Hi!")
	await pip.send_bottle(me.backend.user_id(), "Look!", _tiny())
	await shore.start()
	var bottles := shore.bottles()
	assert_eq(bottles.size(), 2)
	for b in bottles:
		assert_true(b.floating, "on the water")
		var cell := Vector3i(b.position.floor())
		assert_eq(world.get_block(cell), BlockIds.WATER, "in the water's top cell")
		assert_eq(world.get_block(cell + Vector3i.UP), BlockIds.AIR, "open to the sky")
		assert_eq(b.collision_layer, SecretThing.LAYER, "tap rays only")
		assert_eq(b.from, "Pip_7")
	assert_gte(bottles[0].position.distance_to(bottles[1].position), BottleSpot.SPREAD)


func test_a_tap_opens_it_the_card_says_what_and_a_tiny_build_becomes_a_stamp() -> void:
	await pip.send_bottle(me.backend.user_id(), "Nice build!", _tiny())
	await shore.start()
	var card := BottleCard.new()
	card.service = me
	add_child_autofree(card)
	shore.opened.connect(card.show_result)
	var bottle: GiftBottle = shore.bottles()[0]
	assert_true(SecretTaps.use(bottle, get_tree()), "a tap on a secret thing opens it, whatever is in the hand")
	await wait_until(func() -> bool: return card.visible, 5.0)
	var words := " ".join(card.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text))
	assert_string_contains(words, "A bottle from Pip_7!")
	assert_string_contains(words, "Nice build!")
	assert_string_contains(words, "GIFTS page")
	assert_eq(me.gift_book.slots().size(), 1)
	assert_eq(me.gift_book.stamp(me.gift_book.slots()[0]).kind, GiftStampBook.KIND_BOTTLE)
	await wait_process_frames(2)
	assert_eq(shore.bottles().size(), 0, "opened: gone from the water")
	(card.find_child("Report", true, false) as Button).pressed.emit()
	await wait_until(func() -> bool: return server.build_reports.size() == 1, 5.0)
	assert_eq(server.build_reports[0].what, "bottle")
	assert_eq(me.gift_book.slots(), [] as Array[int], "the reported tiny build goes")
	(card.find_child("Ok", true, false) as Button).pressed.emit()
	assert_false(card.visible)


func test_a_bottle_that_arrives_while_playing_floats_up_too() -> void:
	await shore.start()
	assert_eq(shore.bottles().size(), 0)
	await pip.send_bottle(me.backend.user_id(), "Wow!")
	await wait_until(func() -> bool: return shore.bottles().size() == 1, 5.0)
	assert_eq(shore.bottles()[0].from, "Pip_7")


func test_no_water_near_the_beach_or_the_ground() -> void:
	body.global_position = Vector3(60.5, 10.0, 0.5)   # 60 blocks from the sea
	await pip.send_bottle(me.backend.user_id(), "Bye!")
	await shore.start()
	var b: GiftBottle = shore.bottles()[0]
	assert_false(b.floating, "on the ground")
	assert_lt(b.position.distance_to(body.global_position), 12.0, "a few steps away")
