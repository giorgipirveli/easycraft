extends GutTest
## M3 Task 4 (spec §14.1, §5.2): the Candy Kingdom's monsters as pure rules. The gummy bear is a jumper that
## bounces off walls (a pure bounce rule); the candy sneaker is the new "sneaker": invisible in the dark, a
## shimmer shows it within 6 blocks, and it always shimmers and jingles before it attacks (fair).


func test_the_kingdoms_monsters() -> void:
	assert_true(MonsterRules.KINDS.has(MonsterRules.GUMMY))
	assert_true(MonsterRules.KINDS.has(MonsterRules.SNEAKER))
	assert_eq(MonsterRules.CANDY_KINDS, [MonsterRules.GUMMY, MonsterRules.SNEAKER] as Array[StringName])
	assert_eq(MonsterRules.behaviour(MonsterRules.GUMMY), MonsterRules.JUMPER)
	assert_eq(MonsterRules.behaviour(MonsterRules.SNEAKER), MonsterRules.SNEAKS)
	assert_eq(MonsterRules.pick_kind(0.1, MonsterRules.CANDY_KINDS), MonsterRules.GUMMY, "gummies are 3 in 5")
	assert_eq(MonsterRules.pick_kind(0.9, MonsterRules.CANDY_KINDS), MonsterRules.SNEAKER)
	assert_false(MonsterRules.splits(MonsterRules.GUMMY, 5), "a gummy bear never splits")
	assert_false(MonsterRules.splits(MonsterRules.SNEAKER, 5))


func test_stats_by_level_and_universe() -> void:
	assert_eq(MonsterRules.hp(MonsterRules.GUMMY, 1), 5)
	assert_eq(MonsterRules.hp(MonsterRules.GUMMY, 5), 17)
	assert_eq(MonsterRules.hp(MonsterRules.SNEAKER, 1), 6)
	assert_eq(MonsterRules.hp(MonsterRules.SNEAKER, 3), 12)
	assert_eq(MonsterRules.hp(MonsterRules.GUMMY, 1, 4), 40, "× 8 in universe 4 (§5.1)")
	assert_eq(MonsterRules.hit(MonsterRules.GUMMY, 1), 1, "a gummy bear nips like a slime")
	assert_eq(MonsterRules.hit(MonsterRules.GUMMY, 4), 3)
	assert_eq(MonsterRules.hit(MonsterRules.SNEAKER, 1), 2, "a sneaker's lollipop hits like a goblin's club")
	assert_eq(MonsterRules.hit(MonsterRules.SNEAKER, 3, 4), 32)
	assert_eq(MonsterRules.gold(MonsterRules.GUMMY, 2), 4)
	assert_eq(MonsterRules.gold(MonsterRules.SNEAKER, 2), 8, "harder to spot, worth more")
	for kind: StringName in MonsterRules.CANDY_KINDS:
		for l in range(1, 6):
			assert_lt(MonsterRules.speed(kind, l), 6.0, "%s %d is slower than a walking child" % [kind, l])
		assert_gt(MonsterRules.size_of(kind, 1).y, 0.4, String(kind))


## A sneaker's attack is signalled longer than a goblin's (it is hard to see); a gummy bear just bumps.
func test_wind_ups() -> void:
	assert_gt(MonsterRules.windup(MonsterRules.SNEAKER), MonsterRules.windup(MonsterRules.GOBLIN))
	assert_true(MonsterRules.winds_up(MonsterRules.SNEAKER))
	assert_false(MonsterRules.winds_up(MonsterRules.GUMMY))
	assert_gt(MonsterRules.hop_up(MonsterRules.GUMMY), MonsterRules.hop_up(MonsterRules.SLIME), "gummy bears hop higher")


## The bounce: flying into a wall, a gummy bear comes back off it — the part of its speed into the wall
## turns round (BOUNCE_KEEP of it), the part along the wall stays, and it gets a little hop up.
func test_a_gummy_bear_bounces_off_a_wall() -> void:
	var into := Vector3(-4.0, -1.0, 0.0)
	var back := MonsterRules.wall_bounce(into, Vector3(1, 0, 0))
	assert_almost_eq(back.x, 4.0 * MonsterRules.BOUNCE_KEEP, 0.001, "straight back")
	assert_almost_eq(back.z, 0.0, 0.001)
	assert_gte(back.y, MonsterRules.BOUNCE_UP, "a little hop up")
	var glancing := MonsterRules.wall_bounce(Vector3(2.0, 3.0, 3.0), Vector3(0, 0, -1))
	assert_almost_eq(glancing.x, 2.0, 0.001, "along the wall: kept")
	assert_almost_eq(glancing.z, -3.0 * MonsterRules.BOUNCE_KEEP, 0.001, "into the wall: turned round")
	assert_almost_eq(glancing.y, 3.0, 0.001, "already going up faster: kept")
	var wall := Vector3(-1, 0, 1).normalized()
	var slanted := MonsterRules.wall_bounce(Vector3(3.0, 0.0, 0.0), wall)
	assert_gt(Vector3(slanted.x, 0.0, slanted.z).dot(wall), 0.0, "off a slanted wall too: away from it")
	assert_gt(slanted.z, 0.0)


func test_no_bounce_off_floors_or_walls_it_moves_away_from() -> void:
	var v := Vector3(3.0, -5.0, 1.0)
	assert_eq(MonsterRules.wall_bounce(v, Vector3.UP), v, "a floor is not a wall")
	assert_eq(MonsterRules.wall_bounce(v, Vector3(0.1, 0.99, 0.0).normalized()), v, "a slope under it is not a wall")
	assert_eq(MonsterRules.wall_bounce(v, Vector3(1, 0, 0)), v, "moving away from the wall already")
	assert_eq(MonsterRules.wall_bounce(Vector3.ZERO, Vector3(1, 0, 0)), Vector3.ZERO)
	var fast := MonsterRules.wall_bounce(Vector3(-40.0, 0.0, 0.0), Vector3(1, 0, 0))
	assert_lte(Vector2(fast.x, fast.z).length(), MonsterRules.BOUNCE_MAX + 0.001, "never flung faster than BOUNCE_MAX")


## The sneaker: dark where the light is low (night, caves), plain to see in the light; in the dark a shimmer
## shows it within SHIMMER_NEAR of a player, and it always shimmers while it winds up (the fair signal).
func test_a_candy_sneaker_hides_in_the_dark_and_shimmers_when_close() -> void:
	assert_true(MonsterRules.sneaker_dark(StealthRules.NIGHT), "night outdoors is dark")
	assert_true(MonsterRules.sneaker_dark(StealthRules.DARK_CAVE), "a cave is dark")
	assert_false(MonsterRules.sneaker_dark(StealthRules.DAYLIGHT), "daylight")
	assert_false(MonsterRules.sneaker_dark(StealthRules.NEAR_LIGHT), "a lantern shows it")
	assert_eq(MonsterRules.SHIMMER_NEAR, 6.0, "the brief: within 6 blocks")
	assert_eq(MonsterRules.sneaker_look(false, false, 30.0), MonsterRules.SEEN, "in the light it is seen like any monster")
	assert_eq(MonsterRules.sneaker_look(true, false, 12.0), MonsterRules.HIDDEN, "dark and far: invisible")
	assert_eq(MonsterRules.sneaker_look(true, false, 5.5), MonsterRules.SHIMMER, "dark and close: a shimmer")
	assert_eq(MonsterRules.sneaker_look(true, true, 40.0), MonsterRules.SHIMMER, "always a shimmer before it attacks")
	assert_eq(MonsterRules.sneaker_look(true, true, 1.0), MonsterRules.SHIMMER)


func test_summon_names() -> void:
	assert_true(ChatCommands.MONSTERS.has("gummy"))
	assert_true(ChatCommands.MONSTERS.has("sneaker"))
	assert_eq(ChatCommands.parse("/summon gummy 2").get("monster"), MonsterRules.GUMMY)
	assert_eq(ChatCommands.parse("/summon sneaker").get("monster"), MonsterRules.SNEAKER)
	assert_true(ChatCommands.BOSSES.has("cake"))
	assert_eq(ChatCommands.parse("/summon cake").get("boss"), &"cake")
