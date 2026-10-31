extends GutTest
## The core loop (owner #79, #83): the Gold Shop's ROCKET PARTS shelf sells the missions' parts (RocketParts: the same
## prices as the Launch Site's PARTS page) into the profile's rocket parts; a part is bought again and again (a rocket
## needs three legs and many tanks), never "owned" once.

var _profile: ProfileData


func before_each() -> void:
	SpendRules.clear_extra()
	RocketParts.register_shelf()
	_profile = ProfileData.new()


func after_each() -> void:
	SpendRules.clear_extra()


func test_the_rocket_shelf_has_every_part_at_its_price() -> void:
	var ids: Array = SpendRules.items(SpendRules.ROCKET, _profile).map(func(it: Dictionary) -> String: return str(it.id))
	for part: int in RocketParts.ORDER:
		assert_has(ids, "part:%d" % part)
		assert_eq(SpendRules.price("part:%d" % part, _profile), RocketParts.price(part))


func test_a_part_is_bought_again_and_again_into_the_rocket_parts() -> void:
	var leg := BlockIds.LANDING_LEGS
	var id := "part:%d" % leg
	_profile.survivor_gold = RocketParts.price(leg) * 3
	for i in 3:
		assert_eq(SpendRules.buy(_profile, id), SpendRules.OK, "leg %d" % (i + 1))
	assert_eq(int(_profile.missions.parts.get(leg, 0)), 3, "three legs")
	assert_eq(_profile.survivor_gold, 0)
	assert_false(SpendRules.owned(_profile, id), "never owned once and for all")
	assert_eq(SpendRules.buy(_profile, id), SpendRules.NOT_ENOUGH)
