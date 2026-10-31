extends GutTest
## Owner #78 (spec §24): a secret at each wonder of world 41 (WondersSecretRules), each find ending with a real fact:
## the pyramid's hidden room over the Grand Gallery (up a secret stair behind a fake block), the gardens' cool room, the
## Temple of Artemis's treasury (its plates, note and golden door), Phidias's workshop, the Mausoleum's hidden tomb
## room, buried treasure by the Colossus, a golden chest by the Lighthouse's fire. Round the tour only these; out past it
## Green Meadows' own.

const Y := WonderTour.BASE_Y

var rules: WondersSecretRules
var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(99)
	rules = WondersSecretRules.new(99, shape)


func test_one_secret_at_each_wonder_with_its_real_fact() -> void:
	var list := rules.wonder_secrets()
	assert_eq(list.size(), 21, "one at each wonder of every tour")
	var kinds := {}
	for id in WonderTour.ids():
		var s := rules.secret_of(id)
		assert_false(s.is_empty(), "%s has a secret" % id)
		assert_eq(str(s.words), str(WonderFacts.of(id).secret), "%s's find says its fact" % id)
		assert_true(str(s.words).begins_with("You found"), str(s.words))
		assert_true(SecretRules.is_kind(s.kind))
		kinds[id] = s.kind
		assert_eq(rules.find(s.id), s, "found again by its id (%s)" % s.id)
	assert_eq(kinds[&"pyramid"], SecretRules.ROOM, "the pyramid's hidden room")
	assert_eq(kinds[&"artemis"], SecretRules.TEMPLE, "the temple's treasury puzzle")
	assert_eq(kinds[&"colossus"], SecretRules.TREASURE, "buried treasure")
	assert_eq(kinds[&"lighthouse"], SecretRules.TREASURE)
	var split := SecretDirector.split_words(str(rules.secret_of(&"pyramid").words))
	assert_eq(split[0], "You found a hidden room!", "the banner says the find")
	assert_true(split[1].begins_with("In 2017"), "the toast says the fact")


func test_each_secret_stays_in_its_own_area() -> void:
	for s: Dictionary in rules.wonder_secrets():
		var a0: Vector2i = s.area * SecretRules.AREA
		for b: Array in s.boxes:
			var lo: Vector3i = b[0]
			var hi: Vector3i = b[1]
			assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA,
				"%s's box %s..%s in area %s" % [s.id, lo, hi, s.area])
		assert_eq(SecretRules.area_of(s.anchor.x, s.anchor.z), s.area)


func test_only_the_wonders_secrets_round_the_tour() -> void:
	for az in range(WondersSecretRules.TOUR_AREAS.x, WondersSecretRules.TOUR_AREAS.y + 1):
		for ax in range(WondersSecretRules.TOUR_AREAS.x, WondersSecretRules.TOUR_AREAS.y + 1):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				assert_true(s.has("wonder"), "only a wonder's secret in area %s (%s)" % [Vector2i(ax, az), s.id])
			assert_eq(rules.tiny_in_area(Vector2i(ax, az)), [], "no mouse village on the tour")
	var far := 0
	for az in range(6, 9):
		for ax in range(6, 9):
			far += rules.secrets_in_area(Vector2i(ax, az)).size()
	assert_gt(far, 0, "Green Meadows' own secrets far out")


func _block(p: Vector3i, open: bool) -> int:
	var sb := rules.block_at(p)
	if sb >= 0:
		return BlockIds.AIR if open and SecretRules.is_fake_wall(sb) else sb
	var b := WonderBuilds.block_at(p)
	if b >= 0:
		return b
	return BlockIds.STONE if p.y < shape.height_at(p.x, p.z) else BlockIds.AIR


func test_the_fake_doors_look_like_their_wall_and_open_onto_the_room() -> void:
	for id: StringName in [&"pyramid", &"gardens", &"zeus", &"mausoleum"]:
		var s := rules.secret_of(id)
		assert_eq(s.kind, SecretRules.ROOM)
		for c: Vector3i in s.fake_wall:
			assert_true(SecretRules.is_fake_wall(rules.block_at(c)), "%s's fake door at %s" % [id, c])
		var outside: Vector3i = (s.fake_wall[0] as Vector3i) + (s.dir as Vector3i)
		assert_false(BlockIds.is_solid(_block(outside, false)), "%s: room to stand before its door (%s)" % [id, outside])
		var inside: Array = s.inside
		var lo: Vector3i = inside[0]
		var hi: Vector3i = inside[1]
		var free := 0
		var all := 0
		for x in range(lo.x, hi.x):
			for z in range(lo.z, hi.z):
				all += 1
				if not BlockIds.is_solid(_block(Vector3i(x, lo.y, z), true)):
					free += 1
		assert_gt(free * 2, all, "%s's room has room to walk (%d of %d)" % [id, free, all])
		var chest: Vector3i = s.chest
		assert_false(BlockIds.is_solid(_block(chest, true)), "%s's chest stands free" % id)
		assert_eq(s.chest_kind, &"room")


func test_the_pyramids_hidden_room_is_inside_the_pyramid_over_the_gallery() -> void:
	var s := rules.secret_of(&"pyramid")
	var lo: Vector3i = s.inside[0]
	var hi: Vector3i = s.inside[1]
	for x in range(lo.x - 1, hi.x + 1):
		for z in range(lo.z - 1, hi.z + 1):
			var room := x >= lo.x and x < hi.x and z >= lo.z and z < hi.z
			if room:
				assert_true(BlockIds.is_solid(_block(Vector3i(x, hi.y, z), true)), "a roof over the hidden room at %d, %d" % [x, z])
			else:
				for y in range(lo.y, hi.y):
					var b := _block(Vector3i(x, y, z), true)
					assert_true(BlockIds.is_solid(b) or x == hi.x, "walls round the hidden room at %d, %d, %d" % [x, y, z])
	var gallery: Array = WonderBuilds.PYRAMID_ROOMS["grand_gallery"]
	assert_gt(lo.y, Y + (gallery[1] as Vector3i).y + 2, "over the Grand Gallery (as scientists found it)")


func test_the_temple_of_artemis_treasury_is_a_plate_puzzle_with_a_golden_door() -> void:
	var s := rules.secret_of(&"artemis")
	assert_eq((s.plates as Array).size(), 3)
	for p: Vector3i in s.plates:
		assert_eq(rules.block_at(p), BlockIds.PRESSURE_PLATE)
		assert_eq(WonderBuilds.block_at(p - Vector3i.UP), BlockIds.MARBLE, "plates on the marble floor")
	for v: Vector3i in s.vault:
		assert_eq(rules.block_at(v), BlockIds.YELLOW, "the golden door")
	assert_true(bool(s.locked))
	assert_eq((s.order as Array).size(), 3)
	assert_eq(s.note.text, Riddles.TEMPLE_TEXT)


func test_the_treasures_by_the_colossus_and_up_the_lighthouse() -> void:
	var t := rules.secret_of(&"colossus")
	assert_eq(t.chest_kind, &"buried")
	var c: Vector3i = t.chest
	assert_eq(rules.block_at(Vector3i(c.x, Y - 1, c.z)), BlockIds.SAND, "the X over it")
	assert_lt(c.y, Y - 1, "buried under the grass")
	var l := rules.secret_of(&"lighthouse")
	assert_eq(l.chest_kind, &"sky", "a golden chest")
	assert_eq((l.chest as Vector3i).y, Y + WonderBuilds.LIGHTHOUSE_TOP, "in the lantern by the fire")
	var feet: Vector3i = l.chest
	assert_true(BlockIds.is_solid(WonderBuilds.block_at(feet - Vector3i.UP)), "it stands on the lantern's floor")
