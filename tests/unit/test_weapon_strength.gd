extends GutTest
## Owner feedback #53 (2026-09-25): "based on how difficult the weapon is to get, based on their strength. For
## example the blaster: it's hard to get but doesn't really deal much damage." How hard a weapon is to get is its
## rarity (the colour it shows everywhere; Tilly's price follows it). Its strength is the damage it does per second
## to one monster over a whole fight (a blaster's reloads and a boomerang's round trip counted). Every fighting
## weapon's strength sits in its rarity's band, and the bands never overlap: a rarer weapon always hits harder.
## A weapon's style (reach, area, range, a slow or a bubble) is the difference inside a band. Tools (pickaxe, axe,
## hammer) are for blocks and hit weaker than the weapons of their rarity.

const S := preload("res://core/rules/weapon_strength.gd")


func _name(id: int) -> String:
	return "%s (%s)" % [ItemIds.display_name(id), ItemRarity.label(S.rarity(id))]


func test_every_fighting_weapon_has_a_rarity() -> void:
	var list: Array[int] = S.fighting_weapons()
	assert_gte(list.size(), 26, "4 tier lines of 5, the boomerang and 5 blasters")
	for b in ItemIds.BLASTERS:
		assert_true(list.has(b), ItemIds.display_name(b))
	for id in list:
		assert_between(S.rarity(id), ItemRarity.COMMON, ItemRarity.LEGENDARY, ItemIds.display_name(id))


func test_every_weapon_is_as_strong_as_its_rarity() -> void:
	for id in S.fighting_weapons():
		var r := S.rarity(id)
		var dps := S.dps(id)
		assert_true(dps >= S.BANDS[r] and dps < S.BANDS[r + 1],
			"%s: %.1f damage a second, its band is %.0f to %.0f" % [_name(id), dps, S.BANDS[r], S.BANDS[r + 1]])


func test_a_rarer_weapon_always_hits_harder() -> void:
	var list: Array[int] = S.fighting_weapons()
	for a in list:
		for b in list:
			if S.rarity(a) > S.rarity(b):
				assert_gt(S.dps(a), S.dps(b), "%s beats %s" % [_name(a), _name(b)])


## The owner's example: the blasters are hard to get, so they hit like the swords of their rarity.
func test_blasters_hit_as_hard_as_they_are_hard_to_get() -> void:
	assert_gt(S.dps(ItemIds.CONFETTI_ROCKET), S.dps(ItemIds.SWORD_CRYSTAL), "legendary beats epic")
	assert_gt(S.dps(ItemIds.BUBBLE_CANNON), S.dps(ItemIds.SWORD_IRON), "epic beats rare")
	assert_gt(S.dps(ItemIds.FOAM_BLASTER), S.dps(WeaponRules.FISTS), "even the foam blaster beats bare hands")
	for b in ItemIds.BLASTERS:
		var sword: int = WeaponRules.TIERS[ItemIds.SWORD][BlasterRules.rarity(b)]
		assert_gte(S.dps(b), S.dps(sword) * 0.6, "%s is near the %s" % [_name(b), ItemIds.display_name(sword)])


func test_in_each_family_a_rarer_one_hits_harder_every_time() -> void:
	var families: Array = [ItemIds.BLASTERS]
	for kind: int in [ItemIds.SWORD, ItemIds.BOW, ItemIds.SPEAR, ItemIds.MACE]:
		families.append(WeaponRules.TIERS[kind])
	for family: Array in families:
		for i in range(1, family.size()):
			assert_gt(S.hit(family[i]), S.hit(family[i - 1]), "%s hits harder than %s" % [
				_name(family[i]), _name(family[i - 1])])


## Harder to get: a rarer weapon never costs less at Tilly's than a commoner one.
func test_a_rarer_weapon_never_costs_less() -> void:
	var list: Array[int] = S.fighting_weapons()
	for a in list:
		for b in list:
			if S.rarity(a) > S.rarity(b):
				assert_gt(ShopRules.price(a), ShopRules.price(b), "%s costs more than %s" % [_name(a), _name(b)])


func test_tools_hit_weaker_than_the_weapons_of_their_rarity() -> void:
	for kind: int in [ItemIds.PICKAXE, ItemIds.AXE]:
		for id: int in WeaponRules.TIERS[kind]:
			assert_lt(S.dps(id), S.BANDS[S.rarity(id)], _name(id))
	assert_lt(S.dps(ItemIds.HAMMER), S.BANDS[S.rarity(ItemIds.HAMMER)], _name(ItemIds.HAMMER))
	assert_lt(S.dps(WeaponRules.FISTS), S.BANDS[ItemRarity.COMMON], "bare hands")


func test_how_strength_is_measured() -> void:
	assert_almost_eq(S.dps(ItemIds.SWORD), 4.0 / 0.35, 0.01, "a melee weapon: a hit every cooldown")
	var f := ItemIds.FOAM_BLASTER
	var cycle := (BlasterRules.magazine(f) - 1) * BlasterRules.interval(f) + BlasterRules.reload_time(f)
	assert_almost_eq(S.dps(f), BlasterRules.magazine(f) * BlasterRules.damage(f) / cycle, 0.01,
		"a blaster: a magazine, then its reload")
	var trip := WeaponRules.boomerang_round_trip()
	assert_almost_eq(trip, 14.0 / 16.0 + 14.0 / (16.0 * 1.15), 0.01)
	assert_almost_eq(S.dps(ItemIds.BOOMERANG), WeaponRules.stats(ItemIds.BOOMERANG).damage / trip, 0.01,
		"a boomerang: one hit a throw, thrown again when it is back")
