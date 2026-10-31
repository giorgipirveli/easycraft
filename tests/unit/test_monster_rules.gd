extends GutTest
## M2 Task 4: the monsters of Green Meadows as pure rules (spec §12.4, §12.15).

const S := MonsterRules.SLIME
const G := MonsterRules.GOBLIN


# --- Stats (§12.4 table) ---

func test_slime_stats_per_level() -> void:
	# level:            1  2  3   4   5
	var hp := [4, 7, 10, 13, 16]       # 4 + 3(l-1)
	var hit := [1, 2, 2, 3, 3]         # 1 + floor(l/2)
	var gold := [2, 4, 6, 8, 10]       # 2l
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(S, l), hp[l - 1], "slime hp at level %d" % l)
		assert_eq(MonsterRules.hit(S, l), hit[l - 1], "slime hit at level %d" % l)
		assert_eq(MonsterRules.gold(S, l), gold[l - 1], "slime gold at level %d" % l)


func test_goblin_stats_per_level() -> void:
	var hp := [6, 10, 14, 18, 22]      # 6 + 4(l-1)
	var hit := [2, 3, 4, 5, 6]         # 2 + (l-1)
	var gold := [3, 6, 9, 12, 15]      # 3l
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(G, l), hp[l - 1], "goblin hp at level %d" % l)
		assert_eq(MonsterRules.hit(G, l), hit[l - 1], "goblin hit at level %d" % l)
		assert_eq(MonsterRules.gold(G, l), gold[l - 1], "goblin gold at level %d" % l)


func test_universe_scaling_doubles_hp_hits_and_gold_per_universe() -> void:
	assert_eq(MonsterRules.universe_scale(1), 1)
	assert_eq(MonsterRules.universe_scale(2), 2)
	assert_eq(MonsterRules.universe_scale(4), 8)
	assert_eq(MonsterRules.universe_scale(0), 1, "no universe below the first")
	assert_eq(MonsterRules.hp(G, 3, 2), 28)
	assert_eq(MonsterRules.hit(S, 5, 3), 12)
	assert_eq(MonsterRules.gold(G, 2, 3), 24)


func test_levels_are_kept_between_1_and_5() -> void:
	assert_eq(MonsterRules.hp(S, 0), MonsterRules.hp(S, 1))
	assert_eq(MonsterRules.hp(G, 9), MonsterRules.hp(G, 5))


func test_behaviours() -> void:
	assert_eq(MonsterRules.behaviour(S), MonsterRules.JUMPER)
	assert_eq(MonsterRules.behaviour(G), MonsterRules.CHASER)
	assert_eq(MonsterRules.GOBLIN_WINDUP, 0.8, "the club's wind-up (§12.4)")


func test_only_big_slimes_split_into_two_small_ones() -> void:
	for l in range(1, 6):
		assert_eq(MonsterRules.splits(S, l), l >= 3, "slime level %d" % l)
		assert_false(MonsterRules.splits(G, l), "goblins never split")
	assert_eq(MonsterRules.SPLIT_COUNT, 2)
	assert_eq(MonsterRules.SPLIT_LEVEL, 1, "the small ones are level 1 and never split again")


# --- Level looks (shape and colour, colourblind-safe) ---

func test_higher_levels_are_bigger_and_each_level_has_its_own_colour() -> void:
	for l in range(1, 5):
		assert_gt(MonsterRules.size_scale(l + 1), MonsterRules.size_scale(l), "level %d is bigger than %d" % [l + 1, l])
	for a in range(1, 6):
		for b in range(a + 1, 6):
			var ca := MonsterRules.level_color(a)
			var cb := MonsterRules.level_color(b)
			var apart := absf(ca.h - cb.h) > 0.04 or absf(ca.get_luminance() - cb.get_luminance()) > 0.1
			assert_true(apart, "levels %d and %d look different" % [a, b])
	assert_eq(MonsterRules.level_color(1), Color("009e73"), "Okabe-Ito colours (safe for colour blindness)")


# --- When and where monsters come (§12.4 night spawns, §12.15 Sandbox) ---

func test_monsters_come_only_at_night() -> void:
	assert_true(MonsterRules.spawns_now(ModeRules.SURVIVOR, true, DayCycle.MIDNIGHT))
	assert_true(MonsterRules.spawns_now(ModeRules.SURVIVOR, true, DayCycle.NIGHT_START))
	assert_false(MonsterRules.spawns_now(ModeRules.SURVIVOR, true, DayCycle.NOON))
	assert_false(MonsterRules.spawns_now(ModeRules.SURVIVOR, true, DayCycle.START))


func test_the_monsters_setting_turns_sandbox_monsters_off_but_never_survivor_ones() -> void:
	assert_true(MonsterRules.spawns_enabled(ModeRules.SANDBOX, true))
	assert_false(MonsterRules.spawns_enabled(ModeRules.SANDBOX, false), "Sandbox never spawns with Monsters: OFF")
	assert_true(MonsterRules.spawns_enabled(ModeRules.SURVIVOR, false), "Survivor has no such setting")
	assert_false(MonsterRules.spawns_now(ModeRules.SANDBOX, false, DayCycle.MIDNIGHT))


func test_caps_are_20_in_all_and_10_per_player_and_8_in_sandbox() -> void:
	assert_eq(MonsterRules.cap_total(false), 20)
	assert_eq(MonsterRules.cap_per_player(false), 10)
	assert_eq(MonsterRules.cap_total(true), 8)
	assert_eq(MonsterRules.spawn_budget(0, 0, false), 10)
	assert_eq(MonsterRules.spawn_budget(0, 7, false), 3, "a player has 7 near: 3 more")
	assert_eq(MonsterRules.spawn_budget(18, 0, false), 2, "20 in the whole world at most")
	assert_eq(MonsterRules.spawn_budget(20, 0, false), 0)
	assert_eq(MonsterRules.spawn_budget(0, 0, true), 8)
	assert_eq(MonsterRules.spawn_budget(6, 0, true), 2)
	assert_eq(MonsterRules.spawn_budget(25, 12, false), 0, "never negative")


func test_level_grows_with_the_distance_from_the_world_spawn() -> void:
	assert_eq(MonsterRules.level_for(0.0, 0, false), 1)
	assert_eq(MonsterRules.level_for(149.0, 0, false), 1)
	assert_eq(MonsterRules.level_for(150.0, 0, false), 2)
	assert_eq(MonsterRules.level_for(450.0, 0, false), 4)
	assert_eq(MonsterRules.level_for(9000.0, 0, false), 5, "level 5 at most")


func test_level_varies_by_one_at_random_within_1_to_5() -> void:
	assert_eq(MonsterRules.level_for(300.0, 1, false), 4)
	assert_eq(MonsterRules.level_for(300.0, -1, false), 2)
	assert_eq(MonsterRules.level_for(0.0, -1, false), 1)
	assert_eq(MonsterRules.level_for(9000.0, 1, false), 5)
	assert_eq(MonsterRules.level_for(300.0, 7, false), 4, "never more than one step")


func test_sandbox_monsters_are_level_1_or_2() -> void:
	for roll in [-1, 0, 1]:
		assert_between(MonsterRules.level_for(9000.0, roll, true), 1, 2)
	assert_eq(MonsterRules.level_for(0.0, 1, true), 2)


func test_a_spot_is_18_to_40_blocks_from_a_player() -> void:
	var players: Array[Vector3] = [Vector3(0, 30, 0)]
	var none: Array[Vector3i] = []
	assert_eq(MonsterRules.spot_refusal(Vector3(25, 30, 0), players, none, none), &"")
	assert_eq(MonsterRules.spot_refusal(Vector3(10, 30, 0), players, none, none), &"too_close")
	assert_eq(MonsterRules.spot_refusal(Vector3(45, 30, 0), players, none, none), &"too_far")
	players.append(Vector3(30, 30, 0))
	assert_eq(MonsterRules.spot_refusal(Vector3(25, 30, 0), players, none, none), &"too_close", "never next to any player")


func test_ring_spots_lie_between_18_and_40_blocks() -> void:
	var c := Vector3(5, 30, -7)
	for i in 20:
		var p := MonsterRules.ring_spot(c, i * 0.7, i / 19.0)
		var d := Vector2(p.x - c.x, p.y - c.z).length()
		assert_between(d, MonsterRules.SPAWN_MIN, MonsterRules.SPAWN_MAX)


func test_never_within_8_blocks_of_a_lantern_or_a_home_bed() -> void:
	var players: Array[Vector3] = [Vector3(0, 30, 0)]
	var none: Array[Vector3i] = []
	var spot := Vector3(25.5, 30, 0.5)
	var lantern: Array[Vector3i] = [Vector3i(30, 30, 0)]
	assert_eq(MonsterRules.spot_refusal(spot, players, lantern, none), &"light")
	var far_lantern: Array[Vector3i] = [Vector3i(34, 30, 0)]
	assert_eq(MonsterRules.spot_refusal(spot, players, far_lantern, none), &"")
	var bed: Array[Vector3i] = [Vector3i(20, 30, 3)]
	assert_eq(MonsterRules.spot_refusal(spot, players, none, bed), &"home")
	assert_true(MonsterRules.LIGHT_BLOCKS.has(BlockIds.LANTERN))


func test_monsters_stand_on_the_surface_never_in_water_or_on_leaves() -> void:
	var ground := func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 10 else BlockIds.AIR
	assert_eq(MonsterRules.surface_spot(3, -4, 9, ground, 192), Vector3(3.5, 10, -3.5))
	var sea := func(p: Vector3i) -> int: return BlockIds.WATER if p.y < 10 else BlockIds.AIR
	assert_false(MonsterRules.surface_spot(3, -4, 9, sea, 192).is_finite(), "no monsters on the sea")
	var tree := func(p: Vector3i) -> int: return BlockIds.LEAVES if p.y < 14 else BlockIds.AIR
	assert_false(MonsterRules.surface_spot(3, -4, 9, tree, 192).is_finite(), "nor on a tree top")
	var wall := func(_p: Vector3i) -> int: return BlockIds.STONE
	assert_false(MonsterRules.surface_spot(3, -4, 9, wall, 20).is_finite(), "no room anywhere")


func test_a_kind_is_picked_from_a_roll() -> void:
	assert_eq(MonsterRules.pick_kind(0.0), S)
	assert_eq(MonsterRules.pick_kind(0.99), G)


# --- Activity, despawning, the sunrise puff ---

func test_monsters_near_a_player_are_simulated_and_far_ones_rest() -> void:
	var players: Array[Vector3] = [Vector3(0, 30, 0)]
	assert_true(MonsterRules.is_active(Vector3(20, 30, 0), players))
	assert_false(MonsterRules.is_active(Vector3(MonsterRules.ACTIVE_DISTANCE + 5.0, 30, 0), players))
	assert_false(MonsterRules.is_active(Vector3(20, 30, 0), [] as Array[Vector3]))


func test_monsters_far_from_everyone_leave() -> void:
	var players: Array[Vector3] = [Vector3(0, 30, 0)]
	assert_false(MonsterRules.should_despawn(Vector3(40, 30, 0), players))
	assert_true(MonsterRules.should_despawn(Vector3(MonsterRules.DESPAWN_DISTANCE + 1.0, 30, 0), players))


func test_wild_monsters_puff_away_at_sunrise() -> void:
	assert_true(MonsterRules.puffs(DayCycle.SUNRISE, true), "the sun is up")
	assert_true(MonsterRules.puffs(DayCycle.NOON, true))
	assert_false(MonsterRules.puffs(DayCycle.MIDNIGHT, true), "still night")
	assert_false(MonsterRules.puffs(DayCycle.NOON, false), "summoned monsters stay")


# --- Coins ---

func test_coins_add_up_to_the_gold_in_a_few_coins() -> void:
	for gold in [1, 2, 3, 7, 10, 15, 24, 160]:
		var coins := MonsterRules.coin_values(gold)
		var sum := 0
		for c in coins:
			assert_gte(c, 1)
			sum += c
		assert_eq(sum, gold, "coins for %d gold" % gold)
		assert_between(coins.size(), 1, MonsterRules.MAX_COINS_PER_DEFEAT)
	assert_eq(MonsterRules.coin_values(0), [] as Array[int])
	assert_eq(MonsterRules.coin_values(-4), [] as Array[int])
	assert_eq(MonsterRules.coin_values(3).size(), 3, "small gold: one coin per gold")


func test_a_coin_goes_to_the_nearest_player_within_2_blocks() -> void:
	var coin := Vector3(0, 30, 0)
	var players: Array[Vector3] = [Vector3(1.8, 30, 0), Vector3(0.5, 30, 0.5), Vector3(0.1, 30, 5)]
	assert_eq(MonsterRules.collector(coin, players), 1)
	var far: Array[Vector3] = [Vector3(2.5, 30, 0)]
	assert_eq(MonsterRules.collector(coin, far), -1, "nobody close enough")
	assert_eq(MonsterRules.collector(coin, [] as Array[Vector3]), -1)


# --- Perception (a seam: Task 5 stealth replaces it) and movement ---

func _open(_p: Vector3i) -> bool:
	return false


func test_a_monster_sees_a_player_in_front_within_16_blocks() -> void:
	var eye := Vector3(0.5, 31, 0.5)
	assert_true(MonsterRules.can_see(eye, Vector3.FORWARD, Vector3(0.5, 31, -10.5), _open))
	assert_false(MonsterRules.can_see(eye, Vector3.FORWARD, Vector3(0.5, 31, -20.5), _open), "too far")
	assert_false(MonsterRules.can_see(eye, Vector3.FORWARD, Vector3(0.5, 31, 10.5), _open), "behind it")
	assert_true(MonsterRules.can_see(eye, Vector3.FORWARD, Vector3(0.5, 31, 2.5), _open), "right next to it: noticed")


func test_a_wall_hides_the_player() -> void:
	var wall := func(p: Vector3i) -> bool: return p.z == -5
	var eye := Vector3(0.5, 31, 0.5)
	assert_false(MonsterRules.can_see(eye, Vector3.FORWARD, Vector3(0.5, 31, -10.5), wall))


func test_monsters_never_walk_into_water_or_off_a_cliff() -> void:
	var flat := func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 10 else BlockIds.AIR
	assert_true(MonsterRules.can_step(Vector3i(0, 10, 0), flat))
	var water := func(p: Vector3i) -> int: return BlockIds.WATER if p.y < 10 else BlockIds.AIR
	assert_false(MonsterRules.can_step(Vector3i(0, 10, 0), water))
	var cliff := func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 2 else BlockIds.AIR
	assert_false(MonsterRules.can_step(Vector3i(0, 10, 0), cliff))


func test_the_club_lands_only_when_the_player_is_still_close() -> void:
	assert_true(MonsterRules.strike_lands(Vector3(0, 30, 0), Vector3(1.5, 30, 0), MonsterRules.STRIKE_REACH))
	assert_false(MonsterRules.strike_lands(Vector3(0, 30, 0), Vector3(4, 30, 0), MonsterRules.STRIKE_REACH), "stepped away")
	assert_false(MonsterRules.strike_lands(Vector3(0, 30, 0), Vector3(1, 34, 0), MonsterRules.STRIKE_REACH), "jumped up high")


# --- /summon ---

func test_a_summoned_monster_stands_a_few_blocks_from_the_player() -> void:
	var flat := func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 10 else BlockIds.AIR
	var near := Vector3(0.5, 10, 0.5)
	for start in 8:
		var spot := MonsterRules.summon_spot(near, flat, start)
		var d := Vector2(spot.x - near.x, spot.z - near.z).length()
		assert_between(d, float(MonsterRules.SUMMON_DISTANCE) - 0.01, MonsterRules.SUMMON_DISTANCE * 1.5, "start %d" % start)
		assert_eq(spot.y, 10.0, "standing on the ground")
	assert_true(MonsterRules.summon_spot(near, flat, -3).is_finite(), "any start works")
	var pond := func(p: Vector3i) -> int:
		if p.y < 9:
			return BlockIds.STONE
		return BlockIds.WATER if p.y == 9 and (absi(p.x) > 1 or absi(p.z) > 1) else (BlockIds.GRASS if p.y < 10 else BlockIds.AIR)
	var close := MonsterRules.summon_spot(near, pond, 0)
	assert_lt(Vector2(close.x - near.x, close.z - near.z).length(), 2.0, "no dry land out there: right next to the player")


## Found by Task 5's smoke run: while a knocked-out player gets up there is a moment with no spawned
## player, and every summoned monster was sent away. Nobody to be far from means nobody leaves.
func test_no_players_for_a_moment_sends_no_monster_away() -> void:
	assert_false(MonsterRules.should_despawn(Vector3(0, 10, 0), [] as Array[Vector3]))
	assert_true(MonsterRules.should_despawn(Vector3(0, 10, 0), [Vector3(500, 10, 0)] as Array[Vector3]))
