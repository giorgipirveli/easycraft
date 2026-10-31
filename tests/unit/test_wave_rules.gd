extends GutTest
## M2 Task 9 (spec §12.8, §12.15, research G6): Monster Totem waves as pure rules. Wave N brings
## 3 + 2N monsters (at most 20) of levels ⌈N/2⌉ … ⌈N/2⌉+1 (at most 5) from the edge of a 25-block
## circle; it ends when all are defeated (won) or after 3 minutes or when every player was knocked
## out (not won); every player not knocked out during a won wave gets 10 × N gold; a win raises N; the
## boss is offered after wave 5; a lost wave offers "Try again" or "Try an easier wave". Sandbox waves
## are gentle (level ≤ 2, ≤ 8 monsters, no gold). The Totem stands on flat ground 20 blocks from the
## world spawn, placed once from the seed.

const SPAWN := Vector2i(40, -8)


static func _flat(_x: int, _z: int) -> int:
	return 30


static func _dry(_x: int, _z: int) -> bool:
	return true


static func _no_trees(_x: int, _z: int) -> bool:
	return false


static func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.z))


# --- Wave sizes and levels ---

func test_wave_sizes_for_waves_1_to_12() -> void:
	var sizes: Array[int] = []
	for n in range(1, 13):
		sizes.append(WaveRules.size(n, false))
	assert_eq(sizes, [5, 7, 9, 11, 13, 15, 17, 19, 20, 20, 20, 20] as Array[int], "3 + 2N, never more than 20")


func test_wave_levels_for_waves_1_to_12() -> void:
	var levels: Array[Vector2i] = []
	for n in range(1, 13):
		levels.append(WaveRules.levels(n, false))
	assert_eq(levels, [Vector2i(1, 2), Vector2i(1, 2), Vector2i(2, 3), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(3, 4), Vector2i(4, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 5), Vector2i(5, 5),
		Vector2i(5, 5)] as Array[Vector2i], "⌈N/2⌉ … ⌈N/2⌉+1, never above 5")


func test_the_roster_has_the_wave_size_with_both_levels_and_both_kinds() -> void:
	for n in range(1, 13):
		var roster := WaveRules.roster(n, false)
		var lv := WaveRules.levels(n, false)
		assert_eq(roster.size(), WaveRules.size(n, false), "wave %d" % n)
		var levels := {}
		var kinds := {}
		for m: Dictionary in roster:
			assert_between(int(m.level), lv.x, lv.y, "wave %d level" % n)
			assert_true(MonsterRules.KINDS.has(m.kind), "wave %d kind" % n)
			levels[m.level] = true
			kinds[m.kind] = true
		assert_eq(levels.size(), lv.y - lv.x + 1, "wave %d: both levels come" % n)
		assert_eq(kinds.size(), 2, "wave %d: slimes and goblins" % n)


func test_the_same_wave_always_brings_the_same_monsters() -> void:
	assert_eq(WaveRules.roster(4, false), WaveRules.roster(4, false), "children can learn a wave")


func test_a_bad_wave_number_is_wave_1() -> void:
	assert_eq(WaveRules.size(0, false), 5)
	assert_eq(WaveRules.size(-3, false), 5)
	assert_eq(WaveRules.levels(0, false), Vector2i(1, 2))


func test_sandbox_waves_are_gentle_level_2_at_most_and_8_at_most() -> void:
	for n in range(1, 13):
		assert_lte(WaveRules.size(n, true), 8, "wave %d" % n)
		assert_eq(WaveRules.size(n, true), mini(WaveRules.size(n, false), 8))
		var lv := WaveRules.levels(n, true)
		assert_lte(lv.y, 2, "wave %d" % n)
		for m: Dictionary in WaveRules.roster(n, true):
			assert_lte(int(m.level), 2)
	assert_eq(WaveRules.levels(1, true), Vector2i(1, 2))


# --- Rewards ---

func test_a_won_wave_pays_10_gold_per_wave_number_and_nothing_in_sandbox() -> void:
	assert_eq(WaveRules.reward(1, false), 10)
	assert_eq(WaveRules.reward(7, false), 70)
	assert_eq(WaveRules.reward(7, true), 0, "Sandbox gold is ∞: nothing is paid")


func test_only_players_not_knocked_out_are_paid() -> void:
	var players: Array[int] = [1, 7, 9]
	var knocked: Array[int] = [7]
	assert_eq(WaveRules.paid(players, knocked), [1, 9] as Array[int])
	var everyone: Array[int] = [1, 7, 9]
	assert_eq(WaveRules.paid(players, everyone), [] as Array[int])
	var left_the_game: Array[int] = [4]
	assert_eq(WaveRules.paid(players, left_the_game), players, "someone who left doesn't change anything")


# --- How a wave ends ---

func test_a_wave_is_won_when_every_monster_is_defeated() -> void:
	var players: Array[int] = [1]
	var none: Array[int] = []
	assert_eq(WaveRules.outcome(0, 0, 60.0, players, none), WaveRules.WON)
	assert_eq(WaveRules.outcome(1, 0, 60.0, players, none), WaveRules.GOING, "one left")
	assert_eq(WaveRules.outcome(0, 2, 60.0, players, none), WaveRules.GOING, "two still coming")


func test_a_wave_ends_after_3_minutes() -> void:
	var players: Array[int] = [1]
	var none: Array[int] = []
	assert_eq(WaveRules.TIME_LIMIT, 180.0)
	assert_eq(WaveRules.outcome(3, 0, 179.9, players, none), WaveRules.GOING)
	assert_eq(WaveRules.outcome(3, 0, 180.0, players, none), WaveRules.TIME_UP)
	assert_false(WaveRules.is_win(WaveRules.TIME_UP))


func test_a_wave_ends_when_every_player_was_knocked_out() -> void:
	var two: Array[int] = [1, 5]
	var one_down: Array[int] = [5]
	var both_down: Array[int] = [5, 1]
	assert_eq(WaveRules.outcome(4, 0, 30.0, two, one_down), WaveRules.GOING, "someone is still standing")
	assert_eq(WaveRules.outcome(4, 0, 30.0, two, both_down), WaveRules.KNOCKED_OUT)
	var nobody: Array[int] = []
	assert_eq(WaveRules.outcome(4, 0, 30.0, nobody, nobody), WaveRules.GOING, "no players: only the clock ends it")


func test_the_last_monster_falling_as_the_last_player_falls_is_a_win() -> void:
	var one: Array[int] = [1]
	assert_eq(WaveRules.outcome(0, 0, 180.0, one, one), WaveRules.WON, "kind: the child did it")
	assert_true(WaveRules.is_win(WaveRules.WON))


# --- The Totem's N, the easier wave and the boss ---

func test_n_rises_on_a_win_only() -> void:
	assert_eq(WaveRules.next_wave(3, 3, true), 4)
	assert_eq(WaveRules.next_wave(3, 3, false), 3, "a lost wave never lowers or raises N")
	assert_eq(WaveRules.next_wave(4, 3, true), 4, "winning an easier wave keeps N")
	assert_eq(WaveRules.next_wave(WaveRules.MAX_WAVE, WaveRules.MAX_WAVE, true), WaveRules.MAX_WAVE)


func test_after_a_lost_wave_the_totem_offers_it_again_or_one_easier() -> void:
	assert_eq(WaveRules.easier(4), 3)
	assert_true(WaveRules.offers_easier(4))
	assert_false(WaveRules.offers_easier(1), "wave 1 is the easiest")
	assert_eq(WaveRules.easier(1), 1)


func test_the_easier_wave_pays_the_normal_gold() -> void:
	# Research G6 guard: the easier wave is a normal wave N-1, paid like any other.
	assert_eq(WaveRules.reward(WaveRules.easier(4), false), WaveRules.reward(3, false))
	assert_eq(WaveRules.roster(WaveRules.easier(4), false), WaveRules.roster(3, false))


func test_which_waves_the_totem_may_start() -> void:
	assert_true(WaveRules.may_start(4, 4, 0), "the Totem's wave")
	assert_false(WaveRules.may_start(3, 4, 0), "no easier wave before a loss")
	assert_false(WaveRules.may_start(5, 4, 0), "never above N")
	assert_true(WaveRules.may_start(4, 4, 4), "try again")
	assert_true(WaveRules.may_start(3, 4, 4), "try an easier wave")
	assert_false(WaveRules.may_start(2, 4, 4))
	assert_true(WaveRules.may_start(2, 4, 3), "an easier wave lost: try it again or one easier still")
	assert_true(WaveRules.may_start(3, 4, 3))
	assert_false(WaveRules.may_start(0, 1, 1), "never below wave 1")


func test_the_boss_is_offered_after_wave_5_is_won() -> void:
	assert_false(WaveRules.boss_ready(5), "wave 5 not won yet")
	assert_true(WaveRules.boss_ready(6))
	assert_false(WaveRules.offers_boss(4, true))
	assert_true(WaveRules.offers_boss(5, true))
	assert_false(WaveRules.offers_boss(5, false))
	assert_true(WaveRules.offers_boss(8, true), "every won wave from 5 on reminds the child")


# --- Where monsters come from ---

func test_monsters_come_from_the_edge_of_a_25_block_circle_all_around() -> void:
	var center := Vector3(10.5, 30, -4.5)
	var count := 7
	var angles: Array[float] = []
	for i in count:
		var first: Vector2 = WaveRules.spawn_columns(center, i, count, 0.3)[0]
		var d := first - Vector2(center.x, center.z)
		assert_almost_eq(d.length(), WaveRules.RING, 0.01, "monster %d on the edge" % i)
		angles.append(d.angle())
	angles.sort()
	for i in count:
		var gap := wrapf(angles[(i + 1) % count] - angles[i], 0.0, TAU)
		assert_almost_eq(gap, TAU / count, 0.01, "spread evenly around")


func test_spawn_columns_try_near_the_edge_first_and_come_closer_last() -> void:
	var center := Vector3(0.5, 30, 0.5)
	var cols := WaveRules.spawn_columns(center, 0, 5, 0.0)
	assert_gt(cols.size(), 10)
	var first_ring := 0
	for c: Vector2 in cols:
		var r := (c - Vector2(center.x, center.z)).length()
		assert_between(r, 7.0, WaveRules.RING + 3.0)
		if absf(r - WaveRules.RING) <= 3.0:
			first_ring += 1
	assert_gt(first_ring, cols.size() / 2, "mostly near the edge")
	var last: Vector2 = cols.back()
	assert_lt((last - Vector2(center.x, center.z)).length(), 12.0, "an island Totem still gets its wave")


# --- The Totem ---

func test_the_totem_stands_20_blocks_from_the_spawn_on_the_ground_facing_it() -> void:
	var spot := WaveRules.totem_spot(7, SPAWN, _flat, _dry, _no_trees)
	var pos: Vector3 = spot.pos
	var c := _cell(pos)
	assert_almost_eq(Vector2(c).distance_to(Vector2(SPAWN)), 20.0, 0.75)
	assert_eq(pos.y, 30.0, "on the ground")
	assert_eq(Vector2(pos.x, pos.z), Vector2(c) + Vector2(0.5, 0.5))
	var front := Vector3(-sin(spot.yaw), 0, -cos(spot.yaw))
	var to_spawn := (Vector3(SPAWN.x + 0.5, 0, SPAWN.y + 0.5) - Vector3(pos.x, 0, pos.z)).normalized()
	assert_gt(front.dot(to_spawn), 0.99, "the Totem faces the spawn")


func test_the_totem_needs_flat_dry_ground_away_from_trees() -> void:
	var patch := SPAWN + Vector2i(0, 20)
	var bumpy := func(x: int, z: int) -> int:
		if absi(x - patch.x) <= 2 and absi(z - patch.y) <= 2:
			return 30
		return 30 + (x * 7 + z * 13) % 3
	var c := _cell(WaveRules.totem_spot(99, SPAWN, bumpy, _dry, _no_trees).pos)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			assert_eq(int(bumpy.call(c.x + dx, c.y + dz)), 30, "3 x 3 flat")
	var tree := SPAWN + Vector2i(20, 0)
	var trees := func(x: int, z: int) -> bool: return Vector2i(x, z) == tree
	var dry_north := func(_x: int, z: int) -> bool: return z < SPAWN.y
	var c2 := _cell(WaveRules.totem_spot(5, SPAWN, _flat, dry_north, trees).pos)
	assert_lt(c2.y, SPAWN.y - 1, "dry land")
	assert_gt(maxi(absi(c2.x - tree.x), absi(c2.y - tree.y)), WaveRules.CLEAR_RADIUS, "no trunk next to it")


func test_the_totem_keeps_away_from_tillys_stall() -> void:
	for s in 12:
		var free := WaveRules.totem_spot(s * 31, SPAWN, _flat, _dry, _no_trees)
		var stall := Vector3(free.pos.x, 30, free.pos.z)   # Tilly right where the Totem would go
		var moved: Vector3 = WaveRules.totem_spot(s * 31, SPAWN, _flat, _dry, _no_trees, stall).pos
		assert_gte(Vector2(moved.x - stall.x, moved.z - stall.z).length(), WaveRules.TRADER_CLEAR)


func test_the_totem_spot_is_deterministic_and_differs_between_worlds() -> void:
	var a := WaveRules.totem_spot(1234, SPAWN, _flat, _dry, _no_trees)
	assert_eq(WaveRules.totem_spot(1234, SPAWN, _flat, _dry, _no_trees), a)
	var spots := {}
	for s in 8:
		spots[WaveRules.totem_spot(s * 7919, SPAWN, _flat, _dry, _no_trees).pos] = true
	assert_gt(spots.size(), 1)


func test_with_no_good_spot_the_totem_still_comes() -> void:
	var nowhere := func(_x: int, _z: int) -> bool: return false
	var spot := WaveRules.totem_spot(3, SPAWN, _flat, nowhere, _no_trees)
	assert_almost_eq(Vector2(_cell(spot.pos)).distance_to(Vector2(SPAWN)), 20.0, 0.75)


func test_real_worlds_get_a_flat_dry_spot_away_from_tilly() -> void:
	for world_seed: int in [1, 42, 777, 20260924]:
		var shape := MeadowsShape.new(world_seed)
		var spawn := shape.spawn_column()
		var stall: Vector3 = TraderRules.stall_for_world(world_seed, shape, spawn).pos
		var spot := WaveRules.totem_for_world(world_seed, shape, spawn, stall)
		var c := _cell(spot.pos)
		var hs: Array[int] = []
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				hs.append(shape.height_at(c.x + dx, c.y + dz))
		assert_eq(hs.min(), hs.max(), "seed %d: flat" % world_seed)
		assert_gt(hs[0], MeadowsShape.SEA_LEVEL + 1, "seed %d: dry land" % world_seed)
		assert_eq(int(spot.pos.y), hs[0], "seed %d: on the ground" % world_seed)
		assert_gte(Vector2(spot.pos.x - stall.x, spot.pos.z - stall.z).length(), WaveRules.TRADER_CLEAR, "seed %d: clear of Tilly" % world_seed)


func test_every_world_gets_its_totem_once_and_keeps_it() -> void:
	for mode: StringName in [ModeRules.SURVIVOR, ModeRules.SANDBOX]:
		var meta := WorldMeta.new()
		meta.seed = 42
		meta.mode = mode
		var shape := MeadowsShape.new(meta.seed)
		assert_true(WaveRules.place_in(meta, shape, shape.spawn_column()), "%s worlds have a Totem" % mode)
		assert_true(meta.has_totem())
		assert_eq(meta.totem_pos, WaveRules.totem_for_world(meta.seed, shape, shape.spawn_column(), meta.trader_pos).pos)
		meta.totem_pos = Vector3(1.5, 40, 2.5)
		assert_true(WaveRules.place_in(meta, shape, shape.spawn_column()))
		assert_eq(meta.totem_pos, Vector3(1.5, 40, 2.5), "a saved Totem stays where it was saved")


func test_taps_and_reach() -> void:
	var totem := Vector3(10.5, 30, 4.5)
	assert_true(WaveRules.in_reach(Vector3(10.5, 31.6, 0.0), totem, WaveRules.TAP_REACH))
	assert_false(WaveRules.in_reach(Vector3(10.5, 31.6, -8.0), totem, WaveRules.TAP_REACH))
	assert_false(WaveRules.in_reach(Vector3.INF, totem, WaveRules.TAP_REACH))
	var from := Vector3(10.5, 31.6, 0.0)
	assert_almost_eq(WaveRules.ray_hit(from, Vector3(0, 0, 1), totem), 3.6, 0.01, "the face of the pole")
	assert_almost_eq(WaveRules.ray_hit(from + Vector3(0, 1.5, 0), Vector3(0, 0, 1), totem), 3.6, 0.01, "its tall head too")
	assert_eq(WaveRules.ray_hit(from, Vector3(1, 0, 0), totem), -1.0, "a miss")
	assert_eq(WaveRules.ray_hit(from, Vector3(0, 0, -1), totem), -1.0, "behind the eye")


# --- Words (never shame, research G6) ---

func test_the_lines_are_short() -> void:
	assert_eq(WaveRules.line(3, 5), "Wave 3 — 5 left")
	assert_eq(WaveRules.countdown_line(3, 5), "Wave 3 starts in 5…")
	assert_eq(WaveRules.won_message(3, 30), "Wave 3 won! +30 gold")
	assert_eq(WaveRules.won_message(3, 0), "Wave 3 won!")


func test_words_never_shame() -> void:
	var said: Array[String] = [WaveRules.lost_message(WaveRules.TIME_UP), WaveRules.lost_message(WaveRules.KNOCKED_OUT),
		WaveRules.won_message(2, 20), WaveRules.won_message(2, 0), WaveRules.no_gold_message(2),
		WaveRules.TRY_AGAIN, WaveRules.TRY_EASIER, WaveRules.BOSS_WORD]
	for key: StringName in WaveRules.REFUSALS:
		said.append(WaveRules.refusal_message(key))
	var word := RegEx.create_from_string("[a-z']+")
	for text in said:
		var low := text.to_lower()
		var words: Array[String] = []
		for m in word.search_all(low):
			words.append(m.get_string())
		for bad: String in ["baby", "babies", "fail", "failed", "lost", "lose", "loser", "bad", "weak", "died", "noob"]:
			assert_false(words.has(bad), "\"%s\" says \"%s\"" % [text, bad])
		for bad: String in ["easy mode", "too hard for you", "give up", "fault", "should have"]:
			assert_false(low.contains(bad), "\"%s\" says \"%s\"" % [text, bad])
	assert_eq(WaveRules.TRY_EASIER, "Try an easier wave")
	assert_eq(WaveRules.TRY_AGAIN, "Try again")
