extends GutTest


func _data() -> Dictionary:
	var blocks := {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(0, 1, 0): BlockIds.LIGHT, Vector3i(1, 0, 0): BlockIds.BLUE}
	return {"flat": Buddy.pack(blocks), "name": "Bobble", "owner": 1, "pos": Vector3(3, 40, 5), "yaw": 0.5, "id": "Buddy1"}


func test_pack_unpack_round_trip() -> void:
	var blocks := {Vector3i(2, 0, 1): BlockIds.GREEN, Vector3i(0, 3, 0): BlockIds.GLASS}
	assert_eq(Buddy.unpack(Buddy.pack(blocks)), blocks)


func test_setup_builds_a_glowing_buddy_with_eyes_and_name() -> void:
	var b := Buddy.new()
	b.setup(_data())
	add_child_autofree(b)
	assert_eq(b.name, "Buddy1")
	assert_eq(b.size_blocks, Vector3i(2, 2, 1))
	assert_true(b.traits.glow)
	assert_eq(b.find_children("*", "Label3D", true, false).size(), 1)
	assert_eq(b.find_children("*", "OmniLight3D", true, false).size(), 1)
	assert_eq(b._pupils.size(), 2)


func test_save_round_trips_through_world_meta() -> void:
	var b := Buddy.new()
	b.setup(_data())
	add_child_autofree(b)
	var m := WorldMeta.new_random()
	m.buddies = [b.to_save()]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.buddies.size(), 1)
	assert_eq((back.buddies[0].blocks as Array).size(), 3)
	assert_eq(back.buddies[0].name, "Bobble")


func test_cheer_does_not_litter_the_buddy_container() -> void:
	var container := Node3D.new()
	add_child_autofree(container)
	var b := Buddy.new()
	b.setup(_data())
	container.add_child(b)
	b.cheer()
	for child in container.get_children():
		assert_true(child is Buddy, "only buddies live in the container, found %s" % child.get_class())


## Owner feedback #9: ten big buddies froze the game at 3 FPS. Each buddy's collision box was as
## wide as the whole build, and physics cost grows with the box's footprint on the voxel terrain.
func test_big_buddy_collides_with_a_compact_footprint() -> void:
	var blocks := {}
	for x in 7:
		for y in 6:
			for z in 7:
				blocks[Vector3i(x, y, z)] = BlockIds.PLANKS
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": "Hulk", "owner": 1, "pos": Vector3(0, 40, 0), "yaw": 0.0, "id": "Buddy9"})
	add_child_autofree(b)
	var shapes := b.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(box.size.x, Buddy.MAX_FOOTPRINT)
	assert_lte(box.size.z, Buddy.MAX_FOOTPRINT)
	assert_gt(box.size.y, 5.0, "keeps its height, so it still bumps into walls")


func test_small_buddy_keeps_its_own_size() -> void:
	var b := Buddy.new()
	b.setup(_data())
	add_child_autofree(b)
	var box := ((b.find_children("*", "CollisionShape3D", false, false)[0]) as CollisionShape3D).shape as BoxShape3D
	assert_almost_eq(box.size.x, 2 * 0.9, 0.001)
	assert_almost_eq(box.size.z, 1 * 0.9, 0.001)


# --- The wake-up ceremony (M2 Task 17, research: signature moments) ---

func _eyes(b: Buddy) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in b._pupils:
		out.append(p.get_parent() as Node3D)   # the eye's white
	return out


func _tag(b: Buddy) -> Label3D:
	return b.find_children("*", "Label3D", true, false)[0] as Label3D


## A buddy the wand just woke: its eyes start closed and blink open, its name pops in, sparkles swirl.
func test_a_new_buddy_wakes_up_eyes_closed_then_open() -> void:
	var data := _data()
	data["fresh"] = true
	var b := Buddy.new()
	b.setup(data)
	add_child_autofree(b)
	await get_tree().process_frame
	for eye in _eyes(b):
		assert_lt(eye.scale.y, 0.2, "eyes closed at first")
	assert_lt(_tag(b).scale.x, 0.2, "the name is not there yet")
	await wait_seconds(Buddy.WAKE_TIME + 0.3)
	for eye in _eyes(b):
		assert_almost_eq(eye.scale.y, 1.0, 0.01, "eyes open")
	assert_almost_eq(_tag(b).scale.x, 1.0, 0.01, "the name popped in")


func test_a_buddy_from_a_save_is_just_there() -> void:
	var b := Buddy.new()
	b.setup(_data())
	add_child_autofree(b)
	await get_tree().process_frame
	for eye in _eyes(b):
		assert_almost_eq(eye.scale.y, 1.0, 0.01)
	assert_almost_eq(_tag(b).scale.x, 1.0, 0.01)


## The owner's camera leans in only on the owner's own game, and never with Reduce motion.
func test_the_camera_leans_in_for_the_owner_unless_reduce_motion() -> void:
	assert_true(Buddy.camera_leans(true, 1, 1, false))
	assert_false(Buddy.camera_leans(true, 1, 2, false), "someone else's buddy")
	assert_false(Buddy.camera_leans(true, 1, 1, true), "Reduce motion")
	assert_false(Buddy.camera_leans(false, 1, 1, false), "a buddy from a save")
