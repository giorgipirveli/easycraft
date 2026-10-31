extends GutTest
## M3 Task 21b (research C3): the trophy shelf — a block (217) whose open shelves show the world owner's badges
## as small 3D trophies: a few on each shelf, more shelves show more, in the order the badges came.


func test_badges_fill_the_shelves_in_order() -> void:
	var shelves: Array[Vector3i] = [Vector3i(5, 10, 0), Vector3i(4, 11, 0), Vector3i(4, 10, 0)]
	var badges: Array[String] = ["first_buddy", "first_pet", "first_secret", "golem", "builder", "say_cheese"]
	var got := TrophyRules.layout(shelves, badges)
	assert_eq(got.size(), 3)
	assert_eq(got[Vector3i(4, 11, 0)], ["first_buddy", "first_pet", "first_secret", "golem"], "the top shelf first")
	assert_eq(got[Vector3i(4, 10, 0)], ["builder", "say_cheese"], "then the row below, left to right")
	assert_eq(got[Vector3i(5, 10, 0)], [], "an empty shelf stays empty")
	assert_eq(TrophyRules.PER_SHELF, 4)


func test_the_order_is_the_same_on_every_game() -> void:
	var a: Array[Vector3i] = [Vector3i(1, 5, 2), Vector3i(0, 5, 3), Vector3i(0, 6, 9), Vector3i(0, 5, 2)]
	var b: Array[Vector3i] = [Vector3i(0, 5, 2), Vector3i(0, 6, 9), Vector3i(1, 5, 2), Vector3i(0, 5, 3)]
	assert_eq(TrophyRules.order(a), TrophyRules.order(b))
	assert_eq(TrophyRules.order(a)[0], Vector3i(0, 6, 9))


func test_unknown_badges_never_stand_on_a_shelf() -> void:
	var shelves: Array[Vector3i] = [Vector3i.ZERO]
	var got := TrophyRules.layout(shelves, ["nonsense", "golem"] as Array[String])
	assert_eq(got[Vector3i.ZERO], ["golem"])


func test_every_badge_has_a_trophy_look() -> void:
	for b: Dictionary in AchievementRules.BADGES:
		var look := TrophyRules.look_of(String(b.id))
		assert_true(TrophyRules.SHAPES.has(look.shape), String(b.id))
		assert_true(look.color is Color)


func test_a_shelf_is_one_mesh_of_boxes_inside_its_block() -> void:
	var boxes := TrophyRules.boxes(["first_buddy", "golem", "level_5", "crystal_cave"] as Array[String])
	assert_gt(boxes.size(), 4, "the middle shelf and four trophies")
	for box: Array in boxes:
		var c: Vector3 = box[0]
		var s: Vector3 = box[1]
		for axis in 3:
			assert_gte(c[axis] - s[axis] * 0.5, 0.0, "inside the block: %s" % [box])
			assert_lte(c[axis] + s[axis] * 0.5, 1.0, "inside the block: %s" % [box])
	assert_eq(TrophyRules.key(["golem", "builder"] as Array[String]), "golem,builder")
	assert_ne(TrophyRules.key(["golem"] as Array[String]), TrophyRules.key(["builder"] as Array[String]))
