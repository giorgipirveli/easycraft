extends GutTest
## M3 Task 14b (spec §13.4): the cartoon blasters as pure rules. One blaster per rarity, each with its own
## ammo; damage, fire rate, magazine and reload; the host's checks (a rate with slack for network jitter);
## what each hit does (the bubble's level cap and time, the paint's slow and mark, the snowball's small push,
## the confetti rocket's area push); Survivor ammo; Tilly's prices.

const F := ItemIds.FOAM_BLASTER
const S := ItemIds.SNOWBALL_LAUNCHER
const P := ItemIds.PAINT_SPLATTER
const B := ItemIds.BUBBLE_CANNON
const C := ItemIds.CONFETTI_ROCKET


func test_the_blaster_and_ammo_ids_are_the_tasks_own() -> void:
	assert_eq(ItemIds.BLASTERS, [415, 416, 417, 418, 419] as Array[int])
	assert_eq(ItemIds.AMMO, [420, 421, 422, 423, 424] as Array[int])
	for id in ItemIds.BLASTERS + ItemIds.AMMO:
		assert_true(ItemIds.is_item(id), str(id))
		assert_true(ItemIds.is_hotbar_valid(id), str(id))
		assert_ne(ItemIds.display_name(id), "", str(id))
		assert_false(BlockIds.is_valid(id), "never a block id: %d" % id)
	for id in range(425, 430):
		assert_false(ItemIds.is_item(id), "%d stays free" % id)


func test_every_blaster_has_its_own_ammo_and_one_rarity() -> void:
	var rarities := {}
	for i in ItemIds.BLASTERS.size():
		var b: int = ItemIds.BLASTERS[i]
		assert_true(BlasterRules.is_blaster(b))
		assert_false(BlasterRules.is_ammo(b))
		assert_eq(BlasterRules.ammo_of(b), ItemIds.AMMO[i], ItemIds.display_name(b))
		assert_eq(BlasterRules.blaster_of(ItemIds.AMMO[i]), b)
		assert_true(BlasterRules.is_ammo(ItemIds.AMMO[i]))
		rarities[BlasterRules.rarity(b)] = true
		assert_eq(BlasterRules.rarity(ItemIds.AMMO[i]), BlasterRules.rarity(b), "ammo wears its blaster's colour")
	assert_eq(rarities.keys().size(), 5, "common, uncommon, rare, epic, legendary")
	assert_eq(BlasterRules.rarity(F), ItemRarity.COMMON)
	assert_eq(BlasterRules.rarity(C), ItemRarity.LEGENDARY)
	assert_false(BlasterRules.is_blaster(ItemIds.SWORD))
	assert_false(BlasterRules.is_blaster(ItemIds.BOW))
	assert_eq(BlasterRules.rarity(ItemIds.SWORD), -1)


## Owner #53: the weakest hit of the blasters, but as strong a second as a common weapon (test_weapon_strength.gd).
func test_the_foam_blaster_is_quick_and_weak() -> void:
	for b in ItemIds.BLASTERS:
		assert_gt(BlasterRules.damage(b), 0)
		if b != F:
			assert_lt(BlasterRules.interval(F), BlasterRules.interval(b), "quick darts")
			assert_lte(BlasterRules.damage(F), BlasterRules.damage(b), "low damage")
	assert_eq(BlasterRules.damage(F), 3)
	assert_gte(BlasterRules.magazine(F), 6, "plenty of darts before a reload")


func test_the_confetti_rocket_has_three_rockets_and_the_slowest_reload() -> void:
	assert_eq(BlasterRules.magazine(C), 3, "owner #53: three rockets, then the slow reload")
	for b in ItemIds.BLASTERS:
		if b != C:
			assert_gt(BlasterRules.reload_time(C), BlasterRules.reload_time(b), "slow reload")
	assert_eq(BlasterRules.effect(C), BlasterRules.CONFETTI)
	assert_eq(BlasterRules.area_radius(C), 4.0, "area knockback 4 blocks")
	assert_eq(BlasterRules.area_radius(F), 0.0)


func test_each_blasters_effect() -> void:
	assert_eq(BlasterRules.effect(F), BlasterRules.NONE)
	assert_eq(BlasterRules.effect(S), BlasterRules.SNOW)
	assert_eq(BlasterRules.effect(P), BlasterRules.PAINT)
	assert_eq(BlasterRules.effect(B), BlasterRules.BUBBLE)


func test_the_snowball_arcs_and_foam_flies_straight() -> void:
	assert_gt(BlasterRules.gravity(S), BlasterRules.gravity(F) * 3.0, "the snowball arcs")
	var v := BlasterRules.velocity(F, Vector3.FORWARD)
	assert_almost_eq(v.length(), BlasterRules.speed(F), 0.001)
	var pos := Vector3.ZERO
	var vel := BlasterRules.velocity(S, Vector3.FORWARD)
	var none := func(_c: Vector3i) -> bool: return false
	for i in 30:
		var s := WeaponRules.arrow_step(pos, vel, 1.0 / 30.0, none, BlasterRules.gravity(S))
		pos = s.pos
		vel = s.vel
	assert_lt(pos.y, -1.0, "a snowball drops over a second")


func test_a_shot_never_passes_a_wall() -> void:
	var wall := func(c: Vector3i) -> bool: return c.z == -5
	var pos := Vector3(0.5, 0.5, 0.5)
	var vel := BlasterRules.velocity(F, Vector3.FORWARD)
	for i in 60:
		var s := WeaponRules.arrow_step(pos, vel, 1.0 / 60.0, wall, BlasterRules.gravity(F))
		pos = s.pos
		vel = s.vel
		if s.stuck:
			break
	assert_gt(pos.z, -4.01, "stopped at the wall's face")


func test_a_shot_flies_no_further_than_its_range() -> void:
	for b in ItemIds.BLASTERS:
		var r := BlasterRules.speed(b) * BlasterRules.life(b)
		assert_between(r, 12.0, 45.0, "%s reaches %.1f m" % [ItemIds.display_name(b), r])


# --- The magazine: rate and reload ---

func test_the_foam_blaster_fires_a_magazine_then_reloads() -> void:
	var m := BlasterRules.Magazine.new(F)
	var t := 1000
	var iv := int(BlasterRules.interval(F) * 1000.0)
	for i in BlasterRules.magazine(F):
		assert_true(m.fire(t), "dart %d" % i)
		assert_false(m.fire(t + 1), "never faster than its rate")
		t += iv
	assert_eq(m.left, 0)
	assert_true(m.reloading(t))
	assert_false(m.fire(t), "reloading")
	t += int(BlasterRules.reload_time(F) * 1000.0) - iv
	assert_false(m.fire(t - 50), "still reloading")
	assert_true(m.fire(t + 1), "full again")
	assert_eq(m.left, BlasterRules.magazine(F) - 1)


func test_the_rocket_reloads_after_its_three_rockets() -> void:
	var m := BlasterRules.Magazine.new(C)
	var iv := int(BlasterRules.interval(C) * 1000.0)
	for i in 3:
		assert_true(m.fire(i * iv), "rocket %d" % (i + 1))
	var empty := 2 * iv
	assert_false(m.fire(empty + int(BlasterRules.reload_time(C) * 1000.0) - 10), "still reloading")
	assert_true(m.fire(empty + int(BlasterRules.reload_time(C) * 1000.0) + 10))


func test_a_rest_fills_a_half_empty_magazine() -> void:
	var m := BlasterRules.Magazine.new(F)
	m.fire(0)
	m.fire(200)
	assert_eq(m.left, BlasterRules.magazine(F) - 2)
	m.refresh(200 + int(BlasterRules.reload_time(F) * 1000.0) + 1)
	assert_eq(m.left, BlasterRules.magazine(F), "resting reloads it")


func test_the_host_allows_network_jitter() -> void:
	var host := BlasterRules.Magazine.new(P, BlasterRules.HOST_SLACK)
	var iv := int(BlasterRules.interval(P) * 1000.0)
	assert_true(host.fire(0))
	assert_true(host.fire(int(iv * 0.85)), "a shot that arrived a little early")
	assert_false(host.fire(int(iv * 0.85) + int(iv * 0.5)), "twice as fast is refused")


func test_reload_left_counts_down() -> void:
	var m := BlasterRules.Magazine.new(C)
	var iv := int(BlasterRules.interval(C) * 1000.0)
	for i in 3:
		m.fire(i * iv)
	assert_almost_eq(m.reload_left(2 * iv + 500), BlasterRules.reload_time(C) - 0.5, 0.01)
	assert_eq(m.reload_left(100000), 0.0)


# --- What a hit does ---

func test_the_bubble_traps_small_monsters_for_4_seconds() -> void:
	for level in [1, 2]:
		assert_true(BlasterRules.bubble_traps(level), "level %d" % level)
	for level in [3, 4, 5]:
		assert_false(BlasterRules.bubble_traps(level), "level %d is too big" % level)
	assert_eq(BlasterRules.BUBBLE_TIME, 4.0)
	assert_lt(BlasterRules.BUBBLE_SLOW, 1.0, "bigger ones are slowed")
	assert_gt(BlasterRules.BUBBLE_SLOW, 0.0)


func test_paint_slows_30_percent_for_5_seconds() -> void:
	assert_almost_eq(BlasterRules.PAINT_SLOW, 0.7, 0.001)
	assert_eq(BlasterRules.PAINT_TIME, 5.0)


func test_the_snowball_pushes_a_little() -> void:
	var push := BlasterRules.push(S, Vector3.FORWARD)
	assert_gt(push.dot(Vector3.FORWARD), 1.0, "along the throw")
	assert_gt(push.y, 0.0, "and up a little")
	var sword := WeaponRules.knockback(Vector3.ZERO, Vector3.FORWARD, ItemIds.SWORD)
	assert_lte(Vector2(push.x, push.z).length(), Vector2(sword.x, sword.z).length(), "no more than a sword's")
	assert_eq(BlasterRules.push(B, Vector3.FORWARD), Vector3.ZERO, "a bubble never pushes")


func test_the_rocket_pushes_everything_within_4_blocks_away_from_the_blast() -> void:
	var things := [{"pos": Vector3(2, 0, 0), "radius": 0.5}, {"pos": Vector3(0, 0, 4.3), "radius": 0.5},
		{"pos": Vector3(6, 0, 0), "radius": 0.5}, {"pos": Vector3(0, 1, 0), "radius": 0.4}]
	assert_eq(BlasterRules.area_hits(Vector3.ZERO, things, 4.0), [0, 1, 3], "the far one stays")
	var push := BlasterRules.area_push(Vector3.ZERO, Vector3(2, 0, 0))
	assert_gt(push.x, 3.0, "away from the blast")
	assert_gt(push.y, 0.0)
	var under := BlasterRules.area_push(Vector3.ZERO, Vector3.ZERO)
	assert_true(under.is_finite(), "right at the blast: still a sane push")


# --- Survivor ammo ---

func test_survivor_needs_ammo_and_sandbox_never_does() -> void:
	assert_eq(BlasterRules.ammo_refusal(F, true, 0), "", "Sandbox: unlimited")
	assert_eq(BlasterRules.ammo_refusal(F, false, 3), "")
	var why := BlasterRules.ammo_refusal(F, false, 0)
	assert_string_contains(why, "Foam Darts")
	assert_string_contains(why, "Tilly")
	assert_eq(BlasterRules.ammo_refusal(ItemIds.SWORD, false, 0), "?", "not a blaster")


func test_tilly_sells_blasters_by_rarity_and_ammo_in_packs() -> void:
	var last := 0
	for b in ItemIds.BLASTERS:
		assert_gt(BlasterRules.shop_price(b), last, "rarer costs more")
		last = BlasterRules.shop_price(b)
		assert_eq(BlasterRules.pack(b), 1)
	for a in ItemIds.AMMO:
		assert_gt(BlasterRules.shop_price(a), 0)
		assert_gt(BlasterRules.pack(a), 1, "a pack")
	assert_lt(BlasterRules.shop_price(ItemIds.FOAM_DARTS) / float(BlasterRules.pack(ItemIds.FOAM_DARTS)), 1.0,
		"a foam dart is cheap")
	assert_eq(BlasterRules.shop_price(ItemIds.SWORD), 0)


func test_aims_are_checked() -> void:
	assert_true(BlasterRules.aim_ok(Vector3(0, 0, -1)))
	assert_false(BlasterRules.aim_ok(Vector3.ZERO))
	assert_false(BlasterRules.aim_ok(Vector3(NAN, 0, 0)))
	assert_false(BlasterRules.aim_ok(Vector3(INF, 0, 1)))
