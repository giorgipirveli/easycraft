extends GutTest
## M2 Task 10: the Stone Golem as pure rules (spec §12.9, research G3 "honest help" and D8 "portal
## peek"): health by team size (players and bot friends), the attack schedule and its wind-ups, the
## slam (grounded targets within 7 only), the rock and the charge, dazed double damage, the gold split,
## honest help after lost fights, and the portal's universe unlock.


func _targets(list: Array) -> Array:
	var out: Array = []
	for e: Array in list:
		out.append({"pos": e[0], "grounded": e[1]})
	return out


# --- Health by team size ---

func test_health_is_300_for_one_and_half_again_for_each_more() -> void:
	assert_eq(BossRules.max_hp(1), 300)
	assert_eq(BossRules.max_hp(2), 450)
	assert_eq(BossRules.max_hp(3), 600)
	assert_eq(BossRules.max_hp(4), 750)


func test_bot_friends_count_like_players() -> void:
	assert_eq(BossRules.max_hp(BotRules.team_size(1, 3)), 750, "one player and three friends: a team of 4")
	assert_eq(BossRules.max_hp(BotRules.team_size(4, 3)), 1200, "four players and three friends")


func test_an_empty_or_broken_team_counts_as_one() -> void:
	assert_eq(BossRules.max_hp(0), 300)
	assert_eq(BossRules.max_hp(-3), 300)


func test_a_tired_golem_has_a_quarter_less_health() -> void:
	assert_eq(BossRules.max_hp(1, true), 225)
	assert_eq(BossRules.max_hp(2, true), 338, "450 x 0.75 = 337.5, rounded")
	assert_eq(BossRules.max_hp(4, true), 563)


# --- The attack schedule and its wind-ups ---

func test_the_attacks_come_in_a_fixed_order_slam_rock_charge() -> void:
	var seen: Array[StringName] = []
	for step in 7:
		seen.append(BossRules.attack_at(step))
	assert_eq(seen, [BossRules.SLAM, BossRules.ROCK, BossRules.CHARGE, BossRules.SLAM, BossRules.ROCK,
		BossRules.CHARGE, BossRules.SLAM] as Array[StringName])
	assert_eq(BossRules.attack_at(-1), BossRules.SLAM, "a broken step starts the order again")


func test_every_attack_is_signalled_by_its_wind_up() -> void:
	assert_eq(BossRules.windup(BossRules.SLAM), 1.2, "raises both fists for 1.2 s")
	assert_eq(BossRules.windup(BossRules.ROCK), 1.0, "holds a glowing rock for 1 s")
	assert_eq(BossRules.windup(BossRules.CHARGE), 1.0, "paws the ground for 1 s")
	assert_eq(BossRules.phase_time(BossRules.Phase.SLAM_WINDUP), 1.2)
	assert_eq(BossRules.phase_time(BossRules.Phase.ROCK_WINDUP), 1.0)
	assert_eq(BossRules.phase_time(BossRules.Phase.CHARGE_WINDUP), 1.0)


func test_the_hits() -> void:
	assert_eq(BossRules.damage(BossRules.SLAM), 4)
	assert_eq(BossRules.damage(BossRules.ROCK), 3)
	assert_eq(BossRules.damage(BossRules.CHARGE), 5)
	assert_eq(BossRules.damage(&"hug"), 0)


func test_the_phases_follow_the_schedule() -> void:
	var P := BossRules.Phase
	assert_eq(BossRules.next_phase(P.RISE, 0), P.WALK, "it rises, then walks")
	assert_eq(BossRules.next_phase(P.WALK, 0), P.SLAM_WINDUP)
	assert_eq(BossRules.next_phase(P.WALK, 1), P.ROCK_WINDUP)
	assert_eq(BossRules.next_phase(P.WALK, 2), P.CHARGE_WINDUP)
	assert_eq(BossRules.next_phase(P.SLAM_WINDUP, 0), P.DAZED, "after a slam it is dazed")
	assert_eq(BossRules.next_phase(P.DAZED, 0), P.WALK)
	assert_eq(BossRules.next_phase(P.ROCK_WINDUP, 1), P.WALK, "the rock flies, then it walks")
	assert_eq(BossRules.next_phase(P.CHARGE_WINDUP, 2), P.CHARGE, "after pawing it runs")
	assert_eq(BossRules.next_phase(P.CHARGE, 2), P.WALK)
	assert_eq(BossRules.next_phase(P.DOWN, 0), P.DOWN, "down stays down")


func test_phase_times() -> void:
	var P := BossRules.Phase
	assert_eq(BossRules.phase_time(P.DAZED), 2.0, "dazed for 2 s")
	assert_eq(BossRules.phase_time(P.WALK), BossRules.REST)
	assert_gt(BossRules.phase_time(P.RISE), 0.0)
	assert_almost_eq(BossRules.phase_time(P.CHARGE), 12.0 / BossRules.CHARGE_SPEED, 0.001, "runs 12 blocks")
	assert_eq(BossRules.phase_time(P.DOWN), INF)
	assert_true(BossRules.is_windup(P.SLAM_WINDUP) and BossRules.is_windup(P.ROCK_WINDUP) and BossRules.is_windup(P.CHARGE_WINDUP))
	assert_false(BossRules.is_windup(P.WALK) or BossRules.is_windup(P.DAZED) or BossRules.is_windup(P.CHARGE))
	assert_eq(BossRules.attack_of(P.SLAM_WINDUP), BossRules.SLAM)
	assert_eq(BossRules.attack_of(P.CHARGE), BossRules.CHARGE)
	assert_eq(BossRules.attack_of(P.WALK), &"")


func test_a_whole_round_is_long_enough_to_react() -> void:
	# From the first wind-up to the next one there is always the walk between attacks.
	assert_gte(BossRules.REST, 1.5)
	assert_lt(BossRules.CHARGE_SPEED, 12.0, "the charge is fast but can be sidestepped")


# --- The slam: grounded targets within 7 only ---

func test_the_slam_hits_everyone_on_the_ground_within_7() -> void:
	var c := Vector3(0, 10, 0)
	var t := _targets([
		[Vector3(0, 10, 3), true],       # 0: close, on the ground
		[Vector3(6.9, 10, 0), true],     # 1: at the edge
		[Vector3(5, 10, 5), true],       # 2: 7.07 away: outside
		[Vector3(0, 11.5, 2), false],    # 3: jumping
		[Vector3(-3, 10, 0), false],     # 4: flying low
		[Vector3(0, 30, 1), true],       # 5: standing on a pillar high above
		[Vector3(0, 9, -6), true],       # 6: a block lower, within 7
	])
	assert_eq(BossRules.slam_hits(c, t), [0, 1, 6] as Array[int])


func test_nobody_in_the_air_is_hit_by_the_slam() -> void:
	var t := _targets([[Vector3(1, 10, 0), false], [Vector3(0, 10, 1), false]])
	assert_eq(BossRules.slam_hits(Vector3(0, 10, 0), t), [] as Array[int])


func test_grounded_means_standing_on_a_block_not_jumping_or_flying() -> void:
	var solid := func(c: Vector3i) -> bool: return c.y < 10
	assert_true(BossRules.is_grounded(Vector3(0.5, 10, 0.5), 0.0, false, solid), "standing")
	assert_true(BossRules.is_grounded(Vector3(0.5, 10.1, 0.5), -0.2, false, solid), "just landed")
	assert_false(BossRules.is_grounded(Vector3(0.5, 11.2, 0.5), 0.0, false, solid), "at the top of a jump")
	assert_false(BossRules.is_grounded(Vector3(0.5, 10.05, 0.5), 8.0, false, solid), "taking off")
	assert_false(BossRules.is_grounded(Vector3(0.5, 10, 0.5), 0.0, true, solid), "flying just above the grass")
	var bed := func(c: Vector3i) -> bool: return c.y < 10 or c == Vector3i(0, 10, 0)
	assert_true(BossRules.is_grounded(Vector3(0.5, 10.5625, 0.5), 0.0, false, bed), "standing on a bed (half high)")
	var water := func(_c: Vector3i) -> bool: return false
	assert_false(BossRules.is_grounded(Vector3(0.5, 10, 0.5), 0.0, false, water), "swimming")


# --- The rock and the charge ---

func test_the_rock_hits_whoever_is_where_it_lands() -> void:
	var t := _targets([[Vector3(10, 10, 0), true], [Vector3(11, 10.8, 0), false], [Vector3(13, 10, 0), true]])
	assert_eq(BossRules.rock_hits(Vector3(10, 10, 0), t), [0, 1] as Array[int], "in the air too; not 3 away")


func test_the_rock_flies_an_arc_from_the_hand_to_the_spot() -> void:
	var from := Vector3(0, 13, 0)
	var to := Vector3(10, 10, 0)
	assert_eq(BossRules.rock_point(from, to, 0.0), from)
	assert_eq(BossRules.rock_point(from, to, 1.0), to)
	var mid := BossRules.rock_point(from, to, 0.5)
	assert_gt(mid.y, (from.y + to.y) * 0.5, "it goes up and comes down")
	assert_between(BossRules.rock_time(from, to), 0.5, 1.6, "a flight a child can step away from")
	assert_gt(BossRules.rock_time(from, Vector3(20, 10, 0)), BossRules.rock_time(from, to))


func test_the_charge_hits_whoever_is_on_its_path() -> void:
	var t := _targets([
		[Vector3(3, 10, 0.5), true],     # 0: on the path
		[Vector3(6, 10, 1.5), false],    # 1: beside it, within reach (jumping does not help)
		[Vector3(4, 10, 4), true],       # 2: well to the side
		[Vector3(-2, 10, 0), true],      # 3: behind the start
		[Vector3(3, 20, 0), true],       # 4: far above
	])
	assert_eq(BossRules.charge_hits(Vector3(0, 10, 0), Vector3(6, 10, 0), t), [0, 1] as Array[int])


func test_the_charge_runs_straight_12_blocks() -> void:
	assert_eq(BossRules.CHARGE_DISTANCE, 12.0)
	var end := BossRules.charge_end(Vector3(1, 10, 1), Vector3(0, 0, -1))
	assert_almost_eq(end.distance_to(Vector3(1, 10, 1)), 12.0, 0.001)
	assert_almost_eq(end.z, -11.0, 0.001)


# --- Dazed double damage ---

func test_dazed_it_takes_double_damage() -> void:
	assert_eq(BossRules.hit_taken(6, false), 6)
	assert_eq(BossRules.hit_taken(6, true), 12)
	assert_eq(BossRules.hit_taken(-4, true), 0, "never healed by a hit")
	assert_eq(BossRules.DAZE_TIME, 2.0)


# --- Gold ---

func test_300_gold_are_split_among_the_players() -> void:
	assert_eq(BossRules.gold_split(1), [300] as Array[int])
	assert_eq(BossRules.gold_split(2), [150, 150] as Array[int])
	assert_eq(BossRules.gold_split(3), [100, 100, 100] as Array[int])
	assert_eq(BossRules.gold_split(4), [75, 75, 75, 75] as Array[int])


func test_the_split_never_loses_or_makes_gold() -> void:
	for n in range(1, 12):
		var shares := BossRules.gold_split(n)
		var sum := 0
		for s in shares:
			sum += s
			assert_between(s, 300 / n, 300 / n + 1, "near-equal shares")
		assert_eq(shares.size(), n)
		assert_eq(sum, 300, "%d players share exactly 300" % n)
	assert_eq(BossRules.gold_split(7), [43, 43, 43, 43, 43, 43, 42] as Array[int], "the first players get the odd coins")
	assert_eq(BossRules.gold_split(0), [] as Array[int])


# --- Honest help (research G3) ---

func test_the_bar_says_how_far_the_team_got() -> void:
	assert_eq(BossRules.percent_left(60, 300), 20)
	assert_eq(BossRules.percent_left(61, 300), 25, "rounded up to fives: never more progress than made")
	assert_eq(BossRules.percent_left(1, 300), 5)
	assert_eq(BossRules.percent_left(300, 300), 100)
	assert_eq(BossRules.percent_left(0, 300), 0)
	assert_eq(BossRules.percent_left(5, 0), 100, "a broken maximum shows no progress")
	assert_eq(BossRules.loss_message(20), "You got it to 20%!")


func test_after_three_lost_fights_the_golem_is_tired_and_says_so() -> void:
	var help := BossRules.new_help()
	assert_false(BossRules.is_tired(help))
	help = BossRules.after_loss(help, 60)
	help = BossRules.after_loss(help, 35)
	assert_false(BossRules.is_tired(help), "two losses: not yet")
	help = BossRules.after_loss(help, 45)
	assert_true(BossRules.is_tired(help), "three lost fights")
	assert_eq(help.losses, 3)
	assert_eq(help.best, 35, "the best try is remembered")
	assert_ne(BossRules.TIRED_MESSAGE, "")
	assert_string_contains(BossRules.TIRED_MESSAGE.to_lower(), "tired", "announced, not hidden")


func test_the_help_resets_after_a_win() -> void:
	var help := BossRules.new_help()
	for i in 4:
		help = BossRules.after_loss(help, 50)
	help = BossRules.after_win(help)
	assert_false(BossRules.is_tired(help))
	assert_eq(help.losses, 0)
	assert_eq(help.best, 100)
	assert_eq(help.wins, 1)


func test_saved_help_is_cleaned() -> void:
	assert_eq(BossRules.clean_help(null), BossRules.new_help())
	assert_eq(BossRules.clean_help("x"), BossRules.new_help())
	var h := BossRules.clean_help({"losses": 2.0, "best": 40, "wins": 1})
	assert_eq(h, {"losses": 2, "best": 40, "wins": 1})
	var bad := BossRules.clean_help({"losses": -5, "best": 900, "wins": "lots"})
	assert_eq(bad, {"losses": 0, "best": 100, "wins": 0})
	assert_eq(BossRules.clean_help({"losses": 1e9}).losses, BossRules.MAX_LOSSES)
	assert_eq(BossRules.clean_help({"losses": NAN}).losses, 0)


# --- A lost fight ---

func test_a_fight_is_lost_when_every_player_is_down_or_everyone_left() -> void:
	assert_false(BossRules.is_lost(1, 0.0, true), "someone is up")
	assert_true(BossRules.is_lost(0, 0.0, true), "all knocked out at once (Survivor)")
	assert_false(BossRules.is_lost(0, 0.0, false), "Sandbox players pop right back up: the fight goes on")
	assert_false(BossRules.is_lost(1, BossRules.LEAVE_TIME - 0.1, true))
	assert_true(BossRules.is_lost(1, BossRules.LEAVE_TIME, false), "nobody near the Golem for a while")


# --- The portal ---

func test_the_portal_unlocks_universe_2_once() -> void:
	assert_eq(BossRules.unlocked_after_win(1), 2)
	assert_eq(BossRules.unlocked_after_win(2), 2, "a second win opens nothing more")
	assert_eq(BossRules.unlocked_after_win(4), 4, "never lowered")
	assert_true(BossRules.unlocks_universe(ModeRules.SURVIVOR))
	assert_false(BossRules.unlocks_universe(ModeRules.SANDBOX), "a summoned Sandbox Golem opens nothing")
	assert_eq(BossRules.PORTAL_MESSAGE, "Sandstorm Desert opens in the next update!")
	for bad in ["tomorrow", "wait", "hours", "days", "countdown"]:
		assert_false(BossRules.PORTAL_MESSAGE.to_lower().contains(bad), "no countdown, no come back later")


func test_they_stand_on_the_ground_nearest_the_totems_height() -> void:
	var hill := func(c: Vector3i) -> int:
		if c.x == 5 and c.y < 14:
			return BlockIds.STONE                     # a little hill in column x = 5
		if c.x == 6 and c.y >= 10 and c.y < 13:
			return BlockIds.LEAVES                    # a bush on the grass
		if c.x == 7 and c.y < 11:
			return BlockIds.WATER if c.y == 10 else BlockIds.SAND
		return BlockIds.GRASS if c.y < 10 else BlockIds.AIR
	assert_eq(BossRules.stand_y(0.5, 0.5, 10.0, hill), 10.0, "on the grass")
	assert_eq(BossRules.stand_y(0.5, 0.5, 12.0, hill), 10.0, "down to the grass")
	assert_eq(BossRules.stand_y(5.5, 0.5, 10.0, hill), 14.0, "up onto the hill")
	assert_eq(BossRules.stand_y(6.5, 0.5, 10.0, hill), 13.0, "never inside a bush (on top of it at worst)")
	assert_eq(BossRules.stand_y(7.5, 0.5, 11.0, hill), 11.0, "no place to stand here: the height it was given")
	var air := func(_c: Vector3i) -> int: return BlockIds.AIR
	assert_eq(BossRules.stand_y(0.5, 0.5, 30.0, air), 30.0)


func test_the_golem_and_the_portal_stand_next_to_the_totem() -> void:
	var totem := Vector3(20.5, 12, 3.5)
	var g := BossRules.golem_spot(totem)
	var p := BossRules.portal_spot(totem)
	assert_between(Vector2(g.x - totem.x, g.z - totem.z).length(), 4.0, 10.0, "a few steps away: a moment to get ready")
	assert_between(Vector2(p.x - totem.x, p.z - totem.z).length(), 2.0, 6.0, "right by the Totem")
	assert_gt(g.distance_to(p), 3.0, "not in the same spot")
