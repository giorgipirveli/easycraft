extends GutTest
## Secret buddy shapes on the buddy itself (M3 Task 20b, spec §14.21): a buddy whose blocks match a recipe is a
## special buddy on every game (worked out from its blocks, so a save or a guest needs nothing more): its name tag
## in the recipe's colour, the recipe's traits (a fairy floats, a lighthouse glows bright), and now and then its
## own thing (snowflakes, a tune, growing...). Tricks: a buddy learns an emote its child does three times near it
## and does its own version afterwards; learned tricks are saved with the world's buddies.

const W := BlockIds.PAINTED_WHITE


func after_all() -> void:
	Audio.stop_all()


func _snowman() -> Dictionary:
	return {Vector3i(0, 0, 0): W, Vector3i(0, 1, 0): W, Vector3i(0, 2, 0): W, Vector3i(1, 2, 0): BlockIds.PAINTED_ORANGE}


func _buddy(blocks: Dictionary, id := "Buddy1") -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": "Frosty", "owner": 1, "pos": Vector3(0, 40, 0), "yaw": 0.0, "id": id})
	add_child_autofree(b)
	b.set_physics_process(false)
	b.set_process(false)
	return b


func _recipe_blocks(id: StringName) -> Dictionary:
	var out := {}
	var lo := Vector3i(99, 99, 99)
	for c: Array in BuddyRecipes.recipe(id).cells:
		lo = Vector3i(mini(lo.x, c[0].x), mini(lo.y, c[0].y), mini(lo.z, c[0].z))
	for c: Array in BuddyRecipes.recipe(id).cells:
		out[(c[0] as Vector3i) - lo] = BuddyRecipes.block_of(c[1])
	return out


func test_a_secret_shape_is_a_special_buddy() -> void:
	var b := _buddy(_snowman())
	assert_eq(b.recipe, &"snowman")
	assert_eq(b._tag.modulate, BuddyRecipes.recipe(&"snowman").color, "its name in its own colour")
	var plain := _buddy({Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.PLANKS}, "Buddy2")
	assert_eq(plain.recipe, &"", "a plain buddy")


func test_a_special_buddy_takes_its_recipes_traits() -> void:
	var fairy := _buddy(_recipe_blocks(&"fairy"))
	assert_eq(fairy.recipe, &"fairy")
	assert_true(fairy.traits.floaty, "a fairy floats (only one of its four blocks is glass)")
	var lighthouse := _buddy(_recipe_blocks(&"lighthouse"), "Buddy2")
	assert_true(lighthouse.traits.glow)
	assert_eq(lighthouse.find_children("*", "OmniLight3D", true, false).size(), 1, "its light")
	var robot := _buddy(_recipe_blocks(&"robot"), "Buddy3")
	assert_true(robot.traits.glow, "its lamp head glows, a lantern too")


func test_a_special_buddy_does_its_thing_now_and_then() -> void:
	var b := _buddy(_snowman())
	var every: float = BuddyRecipes.recipe(&"snowman").every
	var played: int = Audio.played + Audio.dropped
	b._process(every + 0.01)
	b._process(every + 0.01)
	assert_gte(b.acts, 1, "at least once in two of its spells")
	assert_gt(Audio.played + Audio.dropped, played, "with its own sound")
	var plain := _buddy({Vector3i(0, 0, 0): BlockIds.PLANKS}, "Buddy2")
	plain._process(60.0)
	assert_eq(plain.acts, 0, "a plain buddy does nothing extra")


func test_the_flower_pot_grows_but_its_box_stays() -> void:
	var b := _buddy(_recipe_blocks(&"flower_pot"))
	var box := (b.find_children("*", "CollisionShape3D", true, false)[0] as CollisionShape3D).shape as BoxShape3D
	var size := box.size
	for i in 40:
		b._process(float(BuddyRecipes.recipe(&"flower_pot").every) + 0.01)
	assert_gt(b.grown, 1.0, "it grew")
	assert_lte(b.grown, Buddy.GROW_MAX)
	assert_almost_eq(b._body.scale.y, b.grown, 0.001)
	assert_eq(box.size, size, "the collision box never grows (owner feedback #9)")
	b._squash()
	await get_tree().create_timer(0.4).timeout
	assert_almost_eq(b._body.scale.y, b.grown, 0.001, "a landing's squash comes back to its grown size")


func test_a_buddy_learns_a_dance_after_three_times_and_saves_it() -> void:
	var b := _buddy(_snowman())
	assert_eq(b.learn(&"dance_hop"), TrickRules.PRACTICE)
	assert_eq(b.learn(&"dance_hop"), TrickRules.PRACTICE)
	assert_eq(b.learn(&"dance_hop"), TrickRules.LEARNED)
	assert_eq(b.learn(&"dance_hop"), TrickRules.KNOWN)
	var m := WorldMeta.new_random()
	m.buddies = [b.to_save()]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.buddies[0].get("tricks"), ["dance_hop"], "saved with the world's buddies")
	var again := _buddy(_snowman(), "Buddy2")
	again.load_tricks(back.buddies[0])
	assert_eq(again.learn(&"dance_hop"), TrickRules.KNOWN, "never forgotten")


func test_every_trick_move_plays() -> void:
	var b := _buddy(_snowman())
	for move: StringName in TrickRules.MOVES:
		b.do_trick(move)
		assert_true(b._anim != null and b._anim.is_valid(), str(move))
