extends GutTest
## Owner #78 (spec §24), the second tour: a secret at each of the New Seven Wonders (WondersSecretRules), each find
## ending with a real fact: the Great Wall's watchtower store room, treasure by Petra's urn, the tunnels under the
## Colosseum's arena, the pyramid inside El Castillo with its red jaguar throne, the cave under Machu Picchu's Temple of
## the Sun, treasure at the top of the Taj Mahal's minaret, the room in Christ the Redeemer's pedestal. Round the second
## tour only these; the first tour's secrets keep their ids.

const Walker := preload("res://tests/fakes/wonder_walker.gd")
const Y := WonderTour.BASE_Y
const ROOMS: Array[StringName] = [&"great_wall", &"colosseum", &"chichen_itza", &"machu_picchu", &"christ_redeemer"]
const CHESTS: Array[StringName] = [&"petra", &"taj_mahal"]

var rules: WondersSecretRules
var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(99)
	rules = WondersSecretRules.new(99, shape)


func test_one_secret_at_each_new_wonder_with_its_real_fact() -> void:
	for id: StringName in WonderFacts.tour_ids(&"new"):
		var s := rules.secret_of(id)
		assert_false(s.is_empty(), "%s has a secret" % id)
		assert_eq(str(s.words), str(WonderFacts.of(id).secret), "%s's find says its fact" % id)
		assert_eq(s.kind, SecretRules.ROOM if ROOMS.has(id) else SecretRules.TREASURE, str(id))
		assert_eq(rules.find(s.id), s, "found again by its id (%s)" % s.id)
	assert_true(str(rules.secret_of(&"pyramid").id).ends_with("_%d" % WondersSecretRules.FIRST_ATTEMPT),
		"the first tour's secrets keep their ids")
	assert_true(str(rules.secret_of(&"great_wall").id).ends_with("_%d" % (WondersSecretRules.FIRST_ATTEMPT + 7)))


func test_only_the_wonders_secrets_in_the_second_tours_areas() -> void:
	var a := WondersSecretRules.NEW_TOUR_AREAS
	for az in range(a.position.y, a.end.y):
		for ax in range(a.position.x, a.end.x):
			var area := Vector2i(ax, az)
			assert_true(WondersSecretRules.in_tour(area))
			for s: Dictionary in rules.secrets_in_area(area):
				assert_true(s.has("wonder"), "only a wonder's secret in area %s (%s)" % [area, s.id])
			assert_eq(rules.tiny_in_area(area), [], "no mouse village on the tour")
	for id: StringName in WonderFacts.tour_ids(&"new"):
		var at: Vector3i = rules.secret_of(id).anchor
		assert_true(WondersSecretRules.in_tour(SecretRules.area_of(at.x, at.z)), "%s's secret is in the tour's areas" % id)


func test_the_fake_doors_look_like_their_wall_and_open_onto_a_room_a_child_walks_into() -> void:
	var closed := Walker.new(shape, rules, false)
	var opened := Walker.new(shape, rules, true)
	for id: StringName in ROOMS:
		var s := rules.secret_of(id)
		for c: Vector3i in s.fake_wall:
			assert_true(SecretRules.is_fake_wall(rules.block_at(c)), "%s's fake door at %s" % [id, c])
		var door: Vector3i = s.fake_wall[0]
		var outside := door + (s.dir as Vector3i)
		assert_true(opened.stands(outside), "%s: room to stand before its door (%s)" % [id, outside])
		var lo: Vector3i = s.inside[0]
		var hi: Vector3i = s.inside[1]
		var goal := Walker.inside(lo, hi - Vector3i.ONE)
		var within := Walker.around(id)
		assert_false(closed.walks(outside, goal, within), "%s: shut until the knock" % id)
		assert_true(opened.walks(outside, goal, within), "%s: through the door into the room" % id)
		var chest: Vector3i = s.chest
		assert_true(opened.stands(chest), "%s's chest stands on the room's floor (%s)" % [id, chest])
		assert_eq(s.chest_kind, &"room")


func test_the_chests_up_petras_rock_and_the_taj_mahals_minaret() -> void:
	var walker := Walker.new(shape, rules, false)
	for id: StringName in CHESTS:
		var s := rules.secret_of(id)
		assert_eq(s.chest_kind, &"sky", "%s: a golden chest, found when it is opened" % id)
		var chest: Vector3i = s.chest
		assert_true(walker.stands(chest), "%s's chest stands on a floor (%s)" % [id, chest])
		var gate := WonderTour.gate(id)
		assert_true(walker.walks(Vector3i(gate.x, Y, gate.y), func(p: Vector3i) -> bool: return p == chest,
			Walker.around(id)), "%s: a child climbs to it" % id)
	var petra := rules.secret_of(&"petra")
	var urn := Walker.at(&"petra", 0, WonderBuildsNew.PETRA_LEDGE, WonderBuildsNew.PETRA_FACE)
	assert_lte(Vector3(petra.chest).distance_to(Vector3(urn)), 2.0, "by the Treasury's urn")


func test_the_pyramid_inside_the_pyramid_has_the_red_jaguar_throne() -> void:
	var s := rules.secret_of(&"chichen_itza")
	var lo: Vector3i = s.inside[0]
	var hi: Vector3i = s.inside[1]
	var thrones := 0
	for x in range(lo.x, hi.x):
		for z in range(lo.z, hi.z):
			if rules.block_at(Vector3i(x, lo.y, z)) == BlockIds.JAGUAR_THRONE:
				thrones += 1
	assert_gt(thrones, 0, "the red jaguar throne inside")
	assert_gt(lo.y, Y + 4, "up inside the pyramid, not under it")
	assert_true(WonderBuilds.block_at(Vector3i((lo.x + hi.x) / 2, hi.y + 2, (lo.z + hi.z) / 2)) == BlockIds.MAYA_STONE,
		"stone over it: the outer pyramid round the inner one")


func test_the_colosseums_tunnels_lie_under_the_tiers() -> void:
	var s := rules.secret_of(&"colosseum")
	var lo: Vector3i = s.inside[0]
	assert_lt(lo.y, Y - 2, "under the arena's floor")
	var door: Vector3i = s.fake_wall[0]
	var arena := door + (s.dir as Vector3i)
	assert_eq(WonderBuilds.block_at(arena + Vector3i.DOWN), BlockIds.SAND, "its door opens off the arena's sand")
