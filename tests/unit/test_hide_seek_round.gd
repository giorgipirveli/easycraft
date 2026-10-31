extends GutTest
## Hide-and-seek as pure rules (M4 Wave 3, agent H; spec §17.5, research T6): one seeker (chosen, or
## random) counts 30 s while the others hide; then seekers find hiders by seeing them (the monsters' sight
## rules: a 120° view, a clear line, never through walls) within 3 blocks, or in the hiding spot they tap;
## a found hider joins the seekers (nobody sits out); hints after 2 minutes; the round ends when everyone
## is found or after 3 minutes of seeking.

const R := preload("res://core/games/hide_seek_round.gd")

const MIA := "p1"
const MAX := "p7"
const PIP := "bPip"


func _round(seeker: String = MIA) -> HideSeekRound:
	var r := R.new()
	assert_true(r.start([MIA, MAX, PIP] as Array[String], seeker, Vector3(10, 64, 10)))
	return r


func _seek(r: HideSeekRound) -> void:
	r.advance(R.COUNT_TIME + 0.01)
	assert_eq(r.phase, R.Phase.SEEKING)


func _air(_cell: Vector3i) -> bool:
	return false


# --- Starting ---

func test_the_seeker_is_the_one_chosen_or_a_random_one() -> void:
	var all: Array[String] = [MIA, MAX, PIP]
	assert_eq(R.pick_seeker(all, MAX, 0), MAX, "the child picked Max")
	assert_eq(R.pick_seeker(all, PIP, 5), PIP, "a bot friend can seek too")
	assert_eq(R.pick_seeker(all, "", 4), all[4 % 3], "random: the roll picks")
	assert_eq(R.pick_seeker(all, "p99", 2), all[2], "someone who isn't playing: random")
	assert_eq(R.pick_seeker([] as Array[String], "", 1), "", "nobody to pick")


func test_a_round_needs_two_and_starts_with_the_counting() -> void:
	var r := R.new()
	assert_false(r.start([MIA] as Array[String], MIA, Vector3.ZERO), "alone: no hide-and-seek")
	assert_eq(r.phase, R.Phase.IDLE)
	r = _round()
	assert_eq(r.phase, R.Phase.COUNTING)
	assert_eq(r.seekers, [MIA] as Array[String])
	assert_eq(r.hiders_left(), [MAX, PIP] as Array[String])
	assert_true(r.is_seeker(MIA))
	assert_true(r.is_hiding(PIP))
	assert_false(r.is_hiding(MIA))
	assert_eq(r.base, Vector3(10, 64, 10), "where the seeker counts")
	assert_false(R.new().start([MIA, MAX] as Array[String], "p42", Vector3.ZERO), "the seeker must be playing")


func test_counting_lasts_thirty_seconds_then_the_seeking_starts() -> void:
	var r := _round()
	assert_eq(R.COUNT_TIME, 30.0)
	assert_eq(r.advance(29.9), [] as Array[StringName])
	assert_eq(r.phase, R.Phase.COUNTING)
	assert_almost_eq(r.time_left(), 0.1, 0.001)
	assert_eq(r.advance(0.2), [R.SEEK] as Array[StringName], "ready or not")
	assert_eq(r.phase, R.Phase.SEEKING)
	assert_almost_eq(r.time_left(), R.SEEK_TIME - 0.1, 0.001, "the extra time counts")


# --- Finding ---

func test_a_seeker_finds_a_hider_who_then_joins_the_seekers() -> void:
	var r := _round()
	assert_false(r.find(MIA, MAX), "not while counting")
	_seek(r)
	assert_false(r.find(MAX, PIP), "a hider can't find anyone")
	assert_false(r.find(MIA, MIA), "not yourself")
	assert_false(r.find(MIA, "p99"), "not someone who isn't playing")
	assert_true(r.find(MIA, MAX))
	assert_true(r.is_seeker(MAX), "found: Max seeks now, nobody sits out")
	assert_false(r.is_hiding(MAX))
	assert_eq(r.found, [MAX] as Array[String])
	assert_eq(r.found_by[MAX], MIA)
	assert_false(r.find(MIA, MAX), "found once")
	assert_eq(r.phase, R.Phase.SEEKING, "Pip is still hiding")
	assert_true(r.find(MAX, PIP), "a found hider finds others too")
	assert_eq(r.phase, R.Phase.OVER)
	assert_eq(r.result, R.ALL_FOUND)


func test_time_is_up_after_three_minutes_of_seeking() -> void:
	var r := _round()
	_seek(r)
	assert_eq(R.SEEK_TIME, 180.0)
	var events := r.advance(R.SEEK_TIME)
	assert_has(events, R.TIME_UP)
	assert_eq(r.phase, R.Phase.OVER)
	assert_eq(r.result, R.TIME_UP)
	assert_eq(r.advance(5.0), [] as Array[StringName], "over is over")
	assert_false(r.find(MIA, MAX))


func test_hints_come_after_two_minutes_then_every_twenty_seconds() -> void:
	var r := _round()
	_seek(r)
	var hints := 0
	for i in int(R.SEEK_TIME) - 1:
		if r.advance(1.0).has(R.HINT):
			hints += 1
			if hints == 1:
				assert_almost_eq(r.seek_elapsed(), R.HINT_AFTER, 1.01, "the first hint after two minutes")
	assert_eq(hints, 3, "at 120, 140 and 160 s")


func test_a_player_who_leaves_or_joins() -> void:
	var r := _round()
	r.join("p9")
	assert_true(r.is_hiding("p9"), "joining while counting: hide too")
	_seek(r)
	r.join("p11")
	assert_true(r.is_seeker("p11"), "joining while seeking: help seek")
	r.leave(MAX)
	r.leave("p9")
	assert_eq(r.hiders_left(), [PIP] as Array[String])
	r.leave(PIP)
	assert_eq(r.phase, R.Phase.OVER, "nobody left to find")
	var s := _round()
	s.leave(MIA)
	assert_eq(s.phase, R.Phase.OVER, "the only seeker went: the round ends")
	assert_eq(s.result, R.ENDED)


func test_the_state_goes_to_every_game() -> void:
	var r := _round(PIP)
	r.names = {MIA: "Mia", MAX: "Max", PIP: "Pip (bot)"}
	_seek(r)
	r.find(PIP, MIA)
	r.advance(12.5)
	var copy := R.from_state(r.to_state())
	assert_eq(copy.phase, R.Phase.SEEKING)
	assert_eq(copy.seekers, [PIP, MIA] as Array[String])
	assert_eq(copy.hiders_left(), [MAX] as Array[String])
	assert_eq(copy.found, [MIA] as Array[String])
	assert_eq(copy.base, r.base)
	assert_almost_eq(copy.time_left(), r.time_left(), 0.001)
	assert_eq(copy.names[PIP], "Pip (bot)")
	var broken := R.from_state({"phase": "nope", "seekers": 5, "base": "x"})
	assert_eq(broken.phase, R.Phase.IDLE, "a broken state is no round")


# --- Seeing and hiding spots (the stealth rules, M2 Task 5) ---

func test_seeing_a_hider_means_close_in_view_and_a_clear_line() -> void:
	var eye := Vector3(0.5, 65.6, 0.5)
	var ahead := Vector3.FORWARD
	assert_true(R.can_see(eye, ahead, eye + Vector3(0, 0, -2.5), 1.0, _air), "2.5 blocks ahead")
	assert_false(R.can_see(eye, ahead, eye + Vector3(0, 0, -3.5), 1.0, _air), "further than 3 blocks")
	assert_true(R.can_see(eye, ahead, eye + Vector3(0, 0, -3.5), 1.0, _air, R.FIND_SLACK), "the host's slack")
	assert_false(R.can_see(eye, ahead, eye + Vector3(0, 0, 2.0), 1.0, _air), "behind the seeker")
	var wall := func(cell: Vector3i) -> bool: return cell == Vector3i(0, 65, -1)
	assert_false(R.can_see(eye, ahead, eye + Vector3(0, 0, -2.5), 1.0, wall), "never through a wall")
	assert_false(R.can_see(eye, ahead, eye + Vector3(0, 0, -1.0), 0.0, _air), "hidden: in a barrel or a bush")
	var dark_crouch := StealthRules.visibility(StealthRules.DARK_CAVE, true, false, false)
	assert_false(R.can_see(eye, ahead, eye + Vector3(0, 0, -2.8), dark_crouch, _air), "crouching in a dark cave")
	assert_true(R.can_see(eye, ahead, eye + Vector3(0, 0, -2.0), dark_crouch, _air), "... but not right next to you")


func test_a_tapped_spot_holds_whoever_is_inside_or_crouching_in_it() -> void:
	var barrel := Vector3i(4, 64, 4)
	assert_true(R.in_spot(barrel, barrel, Vector3(4.5, 64, 4.5)), "inside the barrel")
	var bush := Vector3i(8, 64, 2)
	assert_true(R.in_spot(bush, Player.NO_SPOT, Vector3(8.4, 64.0, 2.6)), "feet in the bush")
	assert_true(R.in_spot(bush, Player.NO_SPOT, Vector3(8.4, 63.0, 2.6)), "the bush at head height")
	assert_false(R.in_spot(bush, Player.NO_SPOT, Vector3(9.4, 64.0, 2.6)), "next to it is not in it")
	assert_true(R.spot_in_reach(Vector3(4.5, 65.6, 7.5), barrel), "3 blocks away")
	assert_false(R.spot_in_reach(Vector3(4.5, 65.6, 12.5), barrel), "too far to look inside")


func test_hiders_stay_near_the_counting_spot() -> void:
	var base := Vector3(0, 64, 0)
	assert_eq(R.AREA_RADIUS, 40.0)
	assert_eq(R.area_push(Vector3(30, 64, 0), base), Vector3.ZERO, "inside the play area")
	var push := R.area_push(Vector3(45, 70, 0), base)
	assert_lt(push.x, 0.0, "back towards the counting spot")
	assert_eq(push.y, 0.0)
