extends GutTest
## Tool tiers, the spear and the mace, shields and rarity colours (M2 Task 6, spec §12.6, §13.1-13.2).

const KINDS := [ItemIds.SWORD, ItemIds.BOW, ItemIds.PICKAXE, ItemIds.AXE, ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]


# --- Ids ---

func test_spear_and_mace_ids_are_allocated() -> void:
	assert_eq([ItemIds.SPEAR, ItemIds.MACE], [118, 119])
	assert_eq([ItemIds.SPEAR_STONE, ItemIds.SPEAR_IRON, ItemIds.SPEAR_CRYSTAL, ItemIds.SPEAR_COSMIC], [161, 162, 163, 164])
	assert_eq([ItemIds.MACE_STONE, ItemIds.MACE_IRON, ItemIds.MACE_CRYSTAL, ItemIds.MACE_COSMIC], [166, 167, 168, 169])
	assert_eq(ItemIds.display_name(ItemIds.SPEAR), "Spear")
	assert_eq(ItemIds.display_name(ItemIds.MACE_COSMIC), "Cosmic Mace")


func test_every_tier_item_and_potion_is_a_usable_item() -> void:
	for kind: int in KINDS:
		for id: int in WeaponRules.TIERS[kind]:
			assert_true(ItemIds.is_item(id), ItemIds.display_name(id))
			assert_true(ItemIds.is_hotbar_valid(id), str(id))
			assert_ne(ItemIds.display_name(id), "", str(id))
	for id in ItemIds.POTIONS:
		assert_true(ItemIds.is_item(id), ItemIds.display_name(id))


# --- Tiers ---

func test_each_kind_has_five_tiers_from_wood_to_cosmic() -> void:
	assert_eq(WeaponRules.TIERS.size(), KINDS.size())
	for kind: int in KINDS:
		var ids: Array = WeaponRules.TIERS[kind]
		assert_eq(ids.size(), 5, ItemIds.display_name(kind))
		assert_eq(ids[0], kind, "the first (wood) is the kind itself")
		for t in 5:
			assert_eq(WeaponRules.tier_of(ids[t]), t, ItemIds.display_name(ids[t]))
			assert_eq(WeaponRules.base_of(ids[t]), kind, ItemIds.display_name(ids[t]))
	assert_eq(WeaponRules.TIERS[ItemIds.SWORD], [ItemIds.SWORD, ItemIds.SWORD_STONE, ItemIds.SWORD_IRON,
		ItemIds.SWORD_CRYSTAL, ItemIds.SWORD_COSMIC])
	assert_eq(WeaponRules.TIERS[ItemIds.SHIELD_WOOD][4], ItemIds.SHIELD_COSMIC)


func test_things_without_tiers() -> void:
	for id in [ItemIds.BOOMERANG, ItemIds.HAMMER, ItemIds.WAND, ItemIds.DUMMY, ItemIds.POTION_JUMP, BlockIds.STONE, 0, 999]:
		assert_eq(WeaponRules.tier_of(id), -1, str(id))
		assert_eq(WeaponRules.base_of(id), id, "untiered: itself")


func test_the_m1b_items_are_the_wood_tier() -> void:
	for id in [ItemIds.SWORD, ItemIds.BOW, ItemIds.PICKAXE, ItemIds.AXE]:
		assert_eq(WeaponRules.tier_of(id), WeaponRules.TIER_WOOD, ItemIds.display_name(id))
		assert_eq(WeaponRules.stats(id), WeaponRules.WEAPONS[id], "unchanged M1b stats")


func test_tier_multipliers_scale_damage() -> void:
	assert_eq(WeaponRules.TIER_MULTIPLIERS, [1.0, 1.5, 2.0, 3.0, 4.5])
	var expected := {ItemIds.SWORD: [4, 6, 8, 12, 18], ItemIds.BOW: [5, 8, 10, 15, 23], ItemIds.PICKAXE: [2, 3, 4, 6, 9],
		ItemIds.AXE: [3, 5, 6, 9, 14], ItemIds.SPEAR: [5, 8, 10, 15, 23], ItemIds.MACE: [8, 12, 16, 24, 36]}   # owner #53
	for kind: int in expected:
		var ids: Array = WeaponRules.TIERS[kind]
		for t in 5:
			assert_eq(int(WeaponRules.stats(ids[t]).damage), expected[kind][t], ItemIds.display_name(ids[t]))
			assert_eq(WeaponRules.damage_to(WeaponRules.DUMMY, ids[t]), expected[kind][t], "hits a dummy: %s" % ItemIds.display_name(ids[t]))


func test_tiers_keep_the_kinds_reach_speed_push_and_power() -> void:
	for kind: int in [ItemIds.SWORD, ItemIds.BOW, ItemIds.PICKAXE, ItemIds.AXE, ItemIds.SPEAR, ItemIds.MACE]:
		var base := WeaponRules.stats(kind)
		for id: int in WeaponRules.TIERS[kind]:
			assert_true(WeaponRules.is_weapon(id), ItemIds.display_name(id))
			var w := WeaponRules.stats(id)
			for key in ["kind", "reach", "cooldown", "knockback", "arc", "max_hits", "power", "sound"]:
				assert_eq(w[key], base[key], "%s: %s" % [ItemIds.display_name(id), key])


func test_tiered_weapons_behave_like_their_kind() -> void:
	var o := Vector3(0, 1, 0)
	var behind: Array[Dictionary] = [{"pos": Vector3(0, 1, 2), "radius": 0.3}]
	var finisher := WeaponRules.COMBO_STEPS - 1
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, behind, ItemIds.SWORD_COSMIC, finisher), [0], "the spin")
	assert_eq(WeaponRules.combo_next(ItemIds.SWORD_IRON, 0, 0.2), 1, "sword combo")
	assert_eq(WeaponRules.combo_bonus(ItemIds.SWORD_IRON, finisher), WeaponRules.FINISHER_BONUS)
	assert_eq(WeaponRules.combo_next(ItemIds.MACE_IRON, 0, 0.2), 0, "no combo")
	assert_eq(WeaponRules.knockback(Vector3.ZERO, Vector3(0, 0, -2), ItemIds.AXE_COSMIC),
		WeaponRules.knockback(Vector3.ZERO, Vector3(0, 0, -2), ItemIds.AXE), "push is the kind's")


func test_dig_power_scales_with_the_tier() -> void:
	assert_eq(WeaponRules.dig_power(ItemIds.PICKAXE), 1.0)
	assert_eq(WeaponRules.dig_power(ItemIds.PICKAXE_IRON), 2.0)
	assert_eq(WeaponRules.dig_power(ItemIds.AXE_COSMIC), 4.5)
	assert_eq(WeaponRules.dig_power(ItemIds.HAMMER), 1.0, "the hammer has one tier")
	assert_eq(WeaponRules.dig_power(ItemIds.SWORD_IRON), 0.0, "no block power")
	assert_eq(WeaponRules.dig_power(BlockIds.STONE), 0.0)
	var wood := WeaponRules.power_cooldown(ItemIds.PICKAXE)
	assert_almost_eq(wood, float(WeaponRules.stats(ItemIds.PICKAXE).cooldown), 0.0001)
	assert_almost_eq(WeaponRules.power_cooldown(ItemIds.PICKAXE_IRON), wood / 2.0, 0.0001, "digs twice as fast")
	assert_almost_eq(WeaponRules.power_cooldown(ItemIds.PICKAXE_COSMIC), wood / 4.5, 0.0001)


# --- Spear and mace (§13.1) ---

func test_spear_thrusts_far_and_narrow() -> void:
	var spear := WeaponRules.stats(ItemIds.SPEAR)
	assert_eq(spear.kind, WeaponRules.MELEE)
	assert_eq(float(spear.reach), 4.5)
	for id in [ItemIds.SWORD, ItemIds.AXE, ItemIds.HAMMER]:
		assert_lt(float(spear.arc), float(WeaponRules.stats(id).arc) + 0.1, "narrower than %s" % ItemIds.display_name(id))
	var o := Vector3(0, 1, 0)
	var targets: Array[Dictionary] = [{"pos": Vector3(0, 1, -4.2), "radius": 0.3}, {"pos": Vector3(2.2, 1, -2.0), "radius": 0.3}]
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.SPEAR), [0], "far ahead yes, to the side no")
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.SWORD), [1], "a sword doesn't reach that far, but sweeps wide")


func test_mace_is_slow_and_pushes_hard() -> void:
	var mace := WeaponRules.stats(ItemIds.MACE)
	assert_eq(mace.kind, WeaponRules.MELEE)
	assert_eq(float(mace.reach), 3.0)
	for id in [ItemIds.SWORD, ItemIds.SPEAR, ItemIds.AXE, ItemIds.PICKAXE, ItemIds.BOW]:
		var w := WeaponRules.stats(id)
		assert_gt(float(mace.cooldown), float(w.cooldown), "slower than %s" % ItemIds.display_name(id))
		assert_gt(float(mace.knockback), float(w.knockback), "pushes harder than %s" % ItemIds.display_name(id))
		assert_gt(int(mace.damage), int(w.damage) - 1, "hits at least as hard as %s" % ItemIds.display_name(id))
	assert_eq(mace.power, &"", "a weapon, not a tool")


func test_mace_shakes_the_ground_in_front_nearby_only() -> void:
	var impact := WeaponRules.mace_impact(Vector3(0, 1, 0), Vector3(0, 0.3, -1))
	assert_almost_eq(impact.y, 0.0, 0.001, "on the ground at the feet")
	assert_lt(impact.z, -1.0, "in front")
	assert_almost_eq(impact.x, 0.0, 0.001)
	assert_almost_eq(WeaponRules.shake_strength(0.0), WeaponRules.MACE_SHAKE, 0.001)
	assert_gt(WeaponRules.shake_strength(2.0), WeaponRules.shake_strength(5.0))
	assert_eq(WeaponRules.shake_strength(WeaponRules.MACE_SHAKE_RADIUS + 0.1), 0.0)


func test_a_far_tap_throws_the_spear_a_near_one_thrusts() -> void:
	var reach := float(WeaponRules.stats(ItemIds.SPEAR).reach)
	assert_false(WeaponRules.wants_throw(ItemIds.SPEAR, reach - 0.5))
	assert_true(WeaponRules.wants_throw(ItemIds.SPEAR_IRON, reach + 2.0))
	assert_true(WeaponRules.wants_throw(ItemIds.SPEAR, WeaponRules.SPEAR_THROW_RANGE - 0.1))
	assert_false(WeaponRules.wants_throw(ItemIds.SPEAR, WeaponRules.SPEAR_THROW_RANGE + 5.0), "too far: a thrust at the air")
	assert_false(WeaponRules.wants_throw(ItemIds.SWORD, reach + 2.0), "only spears fly")


func test_a_thrown_spear_flies_short_and_hits_harder() -> void:
	var v := WeaponRules.spear_throw_velocity(Vector3(0, 0, -2))
	assert_almost_eq(v.length(), WeaponRules.SPEAR_THROW_SPEED, 0.001)
	var pos := Vector3(0, 1.5, 0)
	var vel := WeaponRules.spear_throw_velocity(Vector3(0, 1, -1))   # the farthest throw, 45 degrees
	var ground := func(c: Vector3i) -> bool: return c.y < 0
	var landed := Vector3.INF
	for i in 400:
		var s := WeaponRules.arrow_step(pos, vel, 1.0 / 60.0, ground, WeaponRules.SPEAR_GRAVITY)
		pos = s.pos
		vel = s.vel
		if s.stuck:
			landed = pos
			break
	assert_true(landed.is_finite(), "it comes down")
	assert_between(-landed.z, 12.0, 26.0, "a short throw")
	var thrust := WeaponRules.damage_to(WeaponRules.DUMMY, ItemIds.SPEAR_IRON)
	var thrown := WeaponRules.damage_to(WeaponRules.DUMMY, ItemIds.SPEAR_IRON, WeaponRules.THROW)
	assert_eq(thrown, roundi(thrust * WeaponRules.SPEAR_THROW_BONUS))
	assert_eq(WeaponRules.damage_to(WeaponRules.ANIMAL, ItemIds.SPEAR, WeaponRules.THROW),
		roundi(int(WeaponRules.stats(ItemIds.SPEAR).damage) * WeaponRules.SPEAR_THROW_BONUS),
		"animals are hurt too since owner feedback #26 (they used to be only pushed)")


func test_a_stuck_spear_is_picked_up_by_walking_to_it() -> void:
	var spear := Vector3(5.0, 0.3, 5.0)
	assert_true(WeaponRules.can_pick_up(spear, Vector3(5.5, 0.0, 5.8)))
	assert_false(WeaponRules.can_pick_up(spear, Vector3(8.0, 0.0, 5.0)), "too far")
	assert_false(WeaponRules.can_pick_up(spear, Vector3(5.0, 4.0, 5.0)), "far above")


# --- Shields (§12.6, ruling 5) ---

func test_shield_blocks_its_tiers_share_from_the_front() -> void:
	var facing := Vector3(0, 0, -1)
	var head_on := Vector3(0, 0, 1)         # the blow travels from the front towards the player
	var shares := [0.30, 0.40, 0.55, 0.70, 0.85]
	var shields: Array = WeaponRules.TIERS[ItemIds.SHIELD_WOOD]
	for t in 5:
		assert_almost_eq(WeaponRules.shield_block(shields[t], head_on, facing), shares[t], 0.0001, ItemIds.display_name(shields[t]))


func test_shield_covers_60_degrees_each_side() -> void:
	var facing := Vector3(0, 0, -1)
	var from_dir := func(deg: float) -> Vector3:   # a blow coming from `deg` off the facing
		return -facing.rotated(Vector3.UP, deg_to_rad(deg))
	assert_gt(WeaponRules.shield_block(ItemIds.SHIELD_IRON, from_dir.call(59.0), facing), 0.0)
	assert_gt(WeaponRules.shield_block(ItemIds.SHIELD_IRON, from_dir.call(-59.0), facing), 0.0)
	assert_eq(WeaponRules.shield_block(ItemIds.SHIELD_IRON, from_dir.call(61.0), facing), 0.0, "from the side")
	assert_eq(WeaponRules.shield_block(ItemIds.SHIELD_IRON, from_dir.call(180.0), facing), 0.0, "from behind")
	assert_gt(WeaponRules.shield_block(ItemIds.SHIELD_IRON, Vector3(0, -0.8, 0.5), facing), 0.0, "a blow from above in front")
	assert_eq(WeaponRules.shield_block(ItemIds.SHIELD_IRON, Vector3(0, -1, 0), facing), 0.0, "straight down: no side to block")
	assert_eq(WeaponRules.shield_block(ItemIds.SHIELD_IRON, Vector3.INF, facing), 0.0, "no direction known")
	assert_eq(WeaponRules.shield_block(ItemIds.SHIELD_IRON, Vector3.ZERO, facing), 0.0, "from right where the player stands")
	assert_eq(WeaponRules.shield_block(0, Vector3(0, 0, 1), facing), 0.0, "no shield")
	assert_eq(WeaponRules.shield_block(ItemIds.SWORD, Vector3(0, 0, 1), facing), 0.0, "a sword is no shield")


func test_the_best_shield_owned_counts() -> void:
	assert_eq(WeaponRules.best_shield([BlockIds.DIRT, ItemIds.SHIELD_STONE, ItemIds.SWORD, ItemIds.SHIELD_CRYSTAL, ItemIds.SHIELD_WOOD]),
		ItemIds.SHIELD_CRYSTAL)
	assert_eq(WeaponRules.best_shield([ItemIds.SWORD, BlockIds.DIRT]), 0)
	assert_eq(WeaponRules.best_shield([]), 0)


func test_blocked_damage_adds_up_fairly_over_many_hits() -> void:
	var carry := 0.0
	var taken := 0
	for i in 100:
		var r := WeaponRules.shielded_damage(1, 0.30, carry)
		taken += int(r.damage)
		carry = float(r.carry)
	assert_between(taken, 69, 71, "a 30% shield takes 30 of 100 one-point hits")
	var first := WeaponRules.shielded_damage(1, 0.30, 0.0)
	assert_eq(int(first.damage), 0, "the first small hit is blocked")
	assert_eq(int(WeaponRules.shielded_damage(4, 0.0, 0.0).damage), 4, "no shield: all of it")
	assert_eq(int(WeaponRules.shielded_damage(5, 0.85, 0.0).damage), 0)
	assert_eq(int(WeaponRules.shielded_damage(5, 0.85, 0.5).damage), 1)


# --- Rarity colours (§13.2) ---

func test_each_tier_has_its_rarity_colour() -> void:
	assert_eq(ItemRarity.of_tier(WeaponRules.TIER_WOOD), ItemRarity.COMMON)
	assert_eq(ItemRarity.of_tier(WeaponRules.TIER_COSMIC), ItemRarity.LEGENDARY)
	assert_eq(ItemRarity.of_item(ItemIds.SWORD_STONE), ItemRarity.UNCOMMON)
	assert_eq(ItemRarity.of_item(ItemIds.SHIELD_IRON), ItemRarity.RARE)
	assert_eq(ItemRarity.of_item(ItemIds.MACE_CRYSTAL), ItemRarity.EPIC)
	assert_eq(ItemRarity.of_item(ItemIds.WAND), -1, "no rarity")
	var names := []
	for r in 5:
		names.append(ItemRarity.label(r))
	assert_eq(names, ["Common", "Uncommon", "Rare", "Epic", "Legendary"])


func test_rarity_colours_read_as_grey_green_blue_purple_gold() -> void:
	var grey := ItemRarity.color(ItemRarity.COMMON)
	assert_lt(grey.s, 0.2, "grey")
	assert_almost_eq(ItemRarity.color(ItemRarity.UNCOMMON).h * 360.0, 125.0, 25.0, "green")
	assert_almost_eq(ItemRarity.color(ItemRarity.RARE).h * 360.0, 215.0, 20.0, "blue")
	assert_almost_eq(ItemRarity.color(ItemRarity.EPIC).h * 360.0, 280.0, 20.0, "purple")
	assert_almost_eq(ItemRarity.color(ItemRarity.LEGENDARY).h * 360.0, 42.0, 12.0, "gold")
	for r in range(1, 5):
		assert_gt(ItemRarity.color(r).s, 0.5, "a strong colour: %s" % ItemRarity.label(r))
	assert_eq(ItemRarity.model_tint(ItemRarity.COMMON), Color.WHITE, "common keeps the M1b look")
	assert_eq(ItemRarity.color(-1), Color.WHITE)
