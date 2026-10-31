extends GutTest
## M3 Task 21b (research R1): the Hub Tree by the portal hub's stone circle grows a leafy crown for every
## universe explored, a glowing fruit for every boss beaten and a golden star for every Secret Book page
## done: a picture of progress. It only grows; it never withers.


func _data(universes: Array[int], bosses: Array[String], pages: Array[String]) -> Array:
	var w := WonderData.new()
	for u in universes:
		w.explore(u)
	w.pages.assign(pages)
	var d := ProgressData.new()
	for b in bosses:
		d.record(StringName("boss_beaten/" + b))
	return [w, d]


func test_the_state_follows_what_the_child_did() -> void:
	var x := _data([2, 1], ["golem", "serpent"], [BookPages.SECRETS])
	var s := HubTreeRules.state(x[0], x[1])
	assert_eq(s.u, [1, 2])
	assert_eq(s.b, ["golem", "serpent"])
	assert_eq(s.p, [BookPages.SECRETS])
	assert_eq(HubTreeRules.things(s), 5)
	assert_eq(HubTreeRules.things(HubTreeRules.state(WonderData.new(), ProgressData.new())), 0)


func test_it_only_ever_grows() -> void:
	var small := HubTreeRules.state(_data([1], ["golem"], [])[0], _data([1], ["golem"], [])[1])
	var x := _data([1, 2], ["golem", "cake"], [BookPages.TREASURE])
	var big := HubTreeRules.state(x[0], x[1])
	assert_true(HubTreeRules.grows(small, big))
	assert_false(HubTreeRules.grows(big, small), "nothing is taken away")
	assert_gt(HubTreeRules.trunk_height(big), HubTreeRules.trunk_height(small))
	assert_gt(HubTreeRules.boxes(big).lit.size() + HubTreeRules.boxes(big).glow.size(),
		HubTreeRules.boxes(small).lit.size() + HubTreeRules.boxes(small).glow.size())
	assert_lte(HubTreeRules.trunk_height(HubTreeRules.clean({"u": range(1, 21), "b": ["a", "b", "c", "d", "e", "f"],
		"p": BookPages.ids()})), HubTreeRules.MAX_TRUNK)


func test_a_fruit_for_each_boss_and_a_star_for_each_page() -> void:
	var x := _data([1, 2, 3], ["golem", "serpent", "giant"], [BookPages.SECRETS, BookPages.KEEPSAKES])
	var b := HubTreeRules.boxes(HubTreeRules.state(x[0], x[1]))
	assert_eq(b.glow.size(), 3 + 2 * HubTreeRules.STAR_BOXES, "3 fruits glow, 2 stars")
	assert_eq(HubTreeRules.crowns(HubTreeRules.state(x[0], x[1])), 3, "a leafy crown per universe")


func test_the_state_from_the_network_is_cleaned() -> void:
	var s := HubTreeRules.clean({"u": [3, 3, 0, "x", 99, 2.0], "b": ["golem", 5, "a b", "golem", "x".repeat(40)],
		"p": ["secrets", "nope"]})
	assert_eq(s.u, [2, 3])
	assert_eq(s.b, ["golem"])
	assert_eq(s.p, ["secrets"])
	assert_eq(HubTreeRules.clean("junk"), HubTreeRules.clean({}))
	assert_eq(HubTreeRules.key(s), HubTreeRules.key(HubTreeRules.clean(s)), "the same tree, the same mesh")


func test_the_tree_stands_on_dry_open_ground_beside_the_circle() -> void:
	var center := Vector3(10.5, 20, 10.5)
	var flat := func(_x: int, _z: int) -> int: return 20
	var yes := func(_x: int, _z: int) -> bool: return true
	var no_trees := func(_x: int, _z: int) -> bool: return false
	var at := HubTreeRules.spot(center, 0.0, flat, yes, no_trees)
	assert_true(at.is_finite())
	var d := Vector2(at.x - center.x, at.z - center.z).length()
	assert_between(d, HubRules.STONE_RING + 1.2, HubRules.LEAVE + 4.0, "outside the stones, close to them")
	assert_eq(at.y, 20.0, "on the ground (height_at is the first empty y)")
	var wet := func(_x: int, _z: int) -> bool: return false
	assert_false(HubTreeRules.spot(center, 0.0, flat, wet, no_trees).is_finite(), "never in water: no tree then")
	var trees := func(x: int, _z: int) -> bool: return x >= 10
	var west := HubTreeRules.spot(center, 0.0, flat, yes, trees)
	assert_true(west.is_finite() and west.x < 10.0, "clear of the world's own trees")
