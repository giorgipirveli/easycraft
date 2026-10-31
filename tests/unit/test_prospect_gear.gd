extends GutTest
## The Gold Shop's prospecting gear (spec §25.5, §26): the Metal Detector on WEAPONS & TOOLS, bought once with the child's
## gold and theirs for good; it hears the metal deposits (gold, copper, iron: never oil or salt) within its range.


func after_each() -> void:
	SpendRules.clear_extra()


func test_the_detector_hangs_on_the_gear_shelf_and_is_bought_once() -> void:
	ProspectGear.register_shelf()
	ProspectGear.register_shelf()
	var ids: Array = SpendRules.items(SpendRules.GEAR, ProfileData.new()).map(func(it: Dictionary) -> String: return it.id)
	assert_eq(ids.count(ProspectGear.DETECTOR), 1, "on the shelf once")
	var p := ProfileData.new()
	p.survivor_gold = 100
	assert_eq(SpendRules.buy(p, ProspectGear.DETECTOR), SpendRules.NOT_ENOUGH)
	assert_false(ProspectGear.has_detector(p))
	p.survivor_gold = 400
	assert_eq(SpendRules.buy(p, ProspectGear.DETECTOR), SpendRules.OK)
	assert_eq(p.survivor_gold, 400 - ProspectGear.DETECTOR_PRICE)
	assert_true(ProspectGear.has_detector(p))
	assert_eq(SpendRules.buy(p, ProspectGear.DETECTOR), SpendRules.OWNED, "nobody needs two")
	assert_true(ProspectGear.has_detector(ProfileData.from_json(p.to_json())), "kept by the profile")
	assert_false(ProspectGear.has_detector(null))


func test_it_hears_metal_not_oil_or_salt() -> void:
	var desert := DepositRules.for_world(12345, DesertShape.new(12345))
	var copper := desert.nearest(DepositKinds.COPPER, Vector3.ZERO)
	var c: Vector3i = copper.signs[0][0]
	var near := ProspectGear.nearest_metal(desert, Vector3(c) + Vector3(10, 0, 0))
	assert_false(near.is_empty(), "copper is metal")
	assert_lte(float(near.distance), 10.9)
	var oil := desert.nearest(DepositKinds.OIL, Vector3.ZERO)
	var o: Vector3i = oil.signs[0][0]
	var at_oil := ProspectGear.nearest_metal(desert, Vector3(o) + Vector3(1, 0, 0))
	assert_true(at_oil.is_empty() or float(at_oil.distance) > 30.0, "oil is not metal")
	assert_true(ProspectGear.nearest_metal(null, Vector3.ZERO).is_empty())
	assert_true(ProspectGear.nearest_metal(desert, Vector3.INF).is_empty())


## Spec §26.5: the detector hears the Moon's and Mars's iron meteorites too; the Ice Finder (a neutron counter: ice's
## hydrogen slows the ground's neutrons) hears the ice of both, never the metal.
func test_the_detector_hears_meteorites_and_the_ice_finder_hears_ice() -> void:
	ProspectGear.register_shelf()
	ProspectGear.register_shelf()
	var ids: Array = SpendRules.items(SpendRules.GEAR, ProfileData.new()).map(func(it: Dictionary) -> String: return it.id)
	assert_eq(ids.count(ProspectGear.ICE_FINDER), 1, "the Ice Finder on the shelf once")
	var p := ProfileData.new()
	p.survivor_gold = 400
	assert_false(ProspectGear.has_ice_finder(p))
	assert_eq(SpendRules.buy(p, ProspectGear.ICE_FINDER), SpendRules.OK)
	assert_eq(p.survivor_gold, 400 - ProspectGear.ICE_FINDER_PRICE)
	assert_true(ProspectGear.has_ice_finder(p))
	for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
		var shape := SpaceShape.new(12345, planet)
		var rules := DepositRules.for_world(12345, shape, SpaceSecretRules.new(12345, shape))
		var sp := Vector3(rules.spawn.x, 0, rules.spawn.y)
		var met := rules.nearest(DepositKinds.MOON_METEORITE if planet == SpaceShape.MOON else DepositKinds.MARS_METEORITE,
			sp, [], 3)
		var m: Vector3i = met.signs[(met.signs as Array).size() - 1][0]
		var heard := ProspectGear.nearest_metal(rules, Vector3(m) + Vector3(8, 0, 0))
		assert_false(heard.is_empty(), "%s: an iron meteorite is metal" % planet)
		assert_true(ProspectGear.nearest_ice(rules, Vector3(m) + Vector3(8, 0, 0)).is_empty()
			or float(ProspectGear.nearest_ice(rules, Vector3(m) + Vector3(8, 0, 0)).distance) > 20.0, "no ice there")
		var ice := rules.nearest(DepositKinds.MOON_ICE if planet == SpaceShape.MOON else DepositKinds.MARS_ICE, sp, [], 3)
		var i: Vector3i = ice.signs[1][0]
		var found := ProspectGear.nearest_ice(rules, Vector3(i) + Vector3(6, 2, 0))
		assert_false(found.is_empty(), "%s: the Ice Finder hears the ice" % planet)
		assert_lte(float(found.distance), 7.0)
