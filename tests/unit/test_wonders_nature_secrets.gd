extends GutTest
## Owner #78 (spec §24), the third tour: a secret at each of the Seven Natural Wonders (WondersSecretRules), each find
## ending with a real fact: a chest in the Grand Canyon's granary, one by Endeavour's cannon on the reef, one on the
## climbers' ledge under the Sugarloaf's lookout, one on Everest's summit by its sea fossil, the northern lights' ice cave
## in the snow mound, the room in Parícutin's church tower, a chest on Livingstone Island. Round the third tour only
## these; the first two tours' secrets keep their ids.

const Walker := preload("res://tests/fakes/wonder_walker.gd")
const Y := WonderTour.BASE_Y
const ROOMS: Array[StringName] = [&"northern_lights", &"paricutin"]

var rules: WondersSecretRules
var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(5150)
	rules = WondersSecretRules.new(5150, shape)


func test_one_secret_at_each_natural_wonder_with_its_real_fact() -> void:
	for id: StringName in WonderFacts.tour_ids(&"nature"):
		var s := rules.secret_of(id)
		assert_false(s.is_empty(), "%s has a secret" % id)
		assert_eq(str(s.words), str(WonderFacts.of(id).secret), "%s's find says its fact" % id)
		assert_eq(s.kind, SecretRules.ROOM if ROOMS.has(id) else SecretRules.TREASURE, str(id))
		assert_eq(rules.find(s.id), s, "found again by its id (%s)" % s.id)
	assert_true(str(rules.secret_of(&"pyramid").id).ends_with("_%d" % WondersSecretRules.FIRST_ATTEMPT),
		"the first tour's secrets keep their ids")
	assert_true(str(rules.secret_of(&"christ_redeemer").id).ends_with("_%d" % (WondersSecretRules.FIRST_ATTEMPT + 13)),
		"and the second tour's")
	assert_true(str(rules.secret_of(&"grand_canyon").id).ends_with("_%d" % (WondersSecretRules.FIRST_ATTEMPT + 14)))


func test_only_the_wonders_secrets_in_the_third_tours_areas_each_inside_its_own_area() -> void:
	var a := WondersSecretRules.NATURE_TOUR_AREAS
	for az in range(a.position.y, a.end.y):
		for ax in range(a.position.x, a.end.x):
			var area := Vector2i(ax, az)
			assert_true(WondersSecretRules.in_tour(area))
			for s: Dictionary in rules.secrets_in_area(area):
				assert_true(s.has("wonder"), "only a wonder's secret in area %s (%s)" % [area, s.id])
			assert_eq(rules.tiny_in_area(area), [], "no mouse village on the tour")
	var region := WonderTour.NATURE_R + WonderTour.BLEND
	var s0 := WonderTour.NATURE_SQUARE
	for corner: Vector2i in [s0 + Vector2i(-region, -region), s0 + Vector2i(region, region)]:
		assert_true(WondersSecretRules.in_tour(SecretRules.area_of(corner.x, corner.y)), "the region's areas %s" % corner)
	for id: StringName in WonderFacts.tour_ids(&"nature"):
		var s := rules.secret_of(id)
		var at: Vector3i = s.anchor
		var area := SecretRules.area_of(at.x, at.z)
		assert_true(WondersSecretRules.in_tour(area), "%s's secret is in the tour's areas" % id)
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi - Vector3i.ONE
		assert_eq(SecretRules.area_of(lo.x, lo.z), area, "%s's secret's boxes stay in its area (the chunks look there)" % id)
		assert_eq(SecretRules.area_of(hi.x, hi.z), area, str(id))


func test_the_ice_cave_and_the_tower_room_open_with_a_knock_onto_rooms_a_child_walks_into() -> void:
	var closed := Walker.new(shape, rules, false)
	var opened := Walker.new(shape, rules, true)
	for id: StringName in ROOMS:
		var s := rules.secret_of(id)
		for c: Vector3i in s.fake_wall:
			assert_true(SecretRules.is_fake_wall(rules.block_at(c)), "%s's fake door at %s" % [id, c])
		var door: Vector3i = s.fake_wall[0]
		var outside := door + (s.dir as Vector3i)
		assert_true(opened.stands(outside) or opened.stands(outside + Vector3i.DOWN),
			"%s: room to stand before its door (%s)" % [id, outside])
		var start := outside if opened.stands(outside) else outside + Vector3i.DOWN
		var lo: Vector3i = s.inside[0]
		var hi: Vector3i = s.inside[1]
		var goal := Walker.inside(lo, hi - Vector3i.ONE)
		var within := Walker.around(id, 16)
		assert_false(closed.walks(start, goal, within), "%s: shut until the knock" % id)
		assert_true(opened.walks(start, goal, within), "%s: through the door into the room" % id)
		assert_true(opened.stands(s.chest), "%s's chest stands on the room's floor (%s)" % [id, s.chest])
	var cave := rules.secret_of(&"northern_lights")
	assert_eq(rules.block_at(cave.fake_wall[0]), BlockIds.FAKE_SNOW, "a snow door into the ice cave")
	var ice := 0
	for b: Array in cave.boxes:
		ice += 1 if b[2] == BlockIds.BLUE_ICE else 0
	assert_gt(ice, 0, "lined with blue ice")
	assert_eq(rules.block_at(rules.secret_of(&"paricutin").fake_wall[0]), BlockIds.FAKE_WALL_BRICK, "a brick in the tower")


func test_the_chests_a_child_reaches_on_foot() -> void:
	var walker := Walker.new(shape, rules, false)
	for id: StringName in [&"grand_canyon", &"rio_harbour", &"everest"]:
		var s := rules.secret_of(id)
		assert_eq(s.chest_kind, &"sky", "%s: a golden chest, found when it is opened" % id)
		var chest: Vector3i = s.chest
		assert_true(walker.stands(chest), "%s's chest stands on a floor (%s)" % [id, chest])
		var g := WonderTour.gate(id)
		var within := Walker.around(id, 24).merge(Rect2i(g - Vector2i(24, 24), Vector2i(49, 49)))
		assert_true(walker.walks(Vector3i(g.x, Y, g.y), func(p: Vector3i) -> bool: return p == chest, within, 1, 400000),
			"%s: a child walks or climbs to it" % id)
	var summit := rules.secret_of(&"everest").chest as Vector3i
	assert_eq(summit.y, Y + NatureGround.EVEREST_TOP, "on the top of the world")


func test_the_reefs_chest_is_dived_to_and_the_islands_is_swum_to() -> void:
	var reef := rules.secret_of(&"barrier_reef")
	var chest: Vector3i = reef.chest
	assert_lt(chest.y, NatureGround.SEA - 1, "under the water, on the reef")
	var near := 0
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			near += 1 if WonderBuilds.block_at(chest + Vector3i(dx, 0, dz)) == BlockIds.DEEPSTONE else 0
	assert_gt(near, 0, "by Endeavour's cannon")
	var island := rules.secret_of(&"victoria_falls")
	var at: Vector3i = island.chest
	var i := NatureGround.ISLAND
	var f := WonderTour.to_frame(&"victoria_falls", Vector2i(at.x, at.z))
	assert_true(f.x >= i.x and f.x <= i.z and f.y >= i.y and f.y <= i.w, "on Livingstone Island")
	assert_eq(at.y, shape.height_at(at.x, at.z), "standing on it, over the river by the lip")
