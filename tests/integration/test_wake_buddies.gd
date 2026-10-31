extends GutTest
## M3 Task 21c: woken cacti, pumpkins and snowmen have a personality of their own on every game (the kind comes
## from the synced blocks): a cactus's flower pops out when it cheers, a jack-o-lantern glows orange, a pumpkin rocks
## and rolls as it lands, a snowman puffs snowflakes. Their looks are shared (never a mesh or a material per buddy).


func _buddy(ids: Array, buddy_name: String = "Bo") -> Buddy:
	var blocks := {}
	for i in ids.size():
		blocks[Vector3i(0, i, 0)] = ids[i]
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": buddy_name, "owner": 1, "pos": Vector3(3, 40, 5), "yaw": 0.0, "id": "Buddy%d" % ids.size()})
	add_child_autofree(b)
	return b


func test_the_kind_comes_from_the_blocks() -> void:
	assert_eq(_buddy([BlockIds.CACTUS, BlockIds.CACTUS]).wake_kind, WakeKinds.CACTUS)
	assert_eq(_buddy([BlockIds.PUMPKIN]).wake_kind, WakeKinds.PUMPKIN)
	assert_eq(_buddy([BlockIds.PACKED_SNOW, BlockIds.SNOWMAN_HEAD]).wake_kind, WakeKinds.SNOWMAN)
	assert_eq(_buddy([BlockIds.RED, BlockIds.BLUE]).wake_kind, WakeKinds.NONE)


func test_a_cactus_flower_pops_out_when_it_cheers() -> void:
	var b := _buddy([BlockIds.CACTUS, BlockIds.CACTUS, BlockIds.CACTUS])
	var flower := b.flower()
	assert_not_null(flower)
	if flower == null:
		return
	assert_false(flower.visible, "hidden until it cheers")
	b.cheer()
	assert_true(flower.visible)
	var other := _buddy([BlockIds.CACTUS, BlockIds.CACTUS])
	assert_same(other.flower().mesh, flower.mesh, "one shared flower mesh")
	assert_null(_buddy([BlockIds.RED]).flower(), "only cacti flower")


func test_a_jack_o_lantern_glows_orange() -> void:
	var jack := _buddy([BlockIds.JACK_O_LANTERN])
	var lights := jack.find_children("*", "OmniLight3D", true, false)
	assert_eq(lights.size(), 1)
	if lights.size() == 1:
		assert_eq((lights[0] as OmniLight3D).light_color, WakeKinds.GLOW_COLOR)
	assert_eq(_buddy([BlockIds.PUMPKIN]).find_children("*", "OmniLight3D", true, false).size(), 0)


func test_a_pumpkin_rocks_when_it_lands_and_a_snowman_puffs_snow() -> void:
	var p := _buddy([BlockIds.PUMPKIN])
	p.wake_kind_landed()
	assert_true(p.is_rolling(), "a pumpkin rolls as it lands")
	var s := _buddy([BlockIds.SNOWMAN_HEAD])
	s.wake_kind_landed()
	s.wake_kind_landed()
	assert_eq(s.snow_puffs, 1, "at most one puff a second")
	var r := _buddy([BlockIds.RED])
	r.wake_kind_landed()
	assert_false(r.is_rolling())
	assert_eq(r.snow_puffs, 0)
