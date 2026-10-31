extends GutTest
## M3 Task 12 (spec §5.8, research R4): instead of a daily gift, a tamed pet sometimes brings a small
## present while the child plays: every 15-25 minutes of active play, a choice from a fixed list of small
## gifts. Never paid, never required, nothing for being away.


func test_the_wait_is_15_to_25_minutes_and_never_random() -> void:
	for n in 12:
		var s := PresentRules.interval_s(n)
		assert_between(s, 15.0 * 60.0, 25.0 * 60.0, "present %d" % n)
		assert_eq(PresentRules.interval_s(n), s, "the same every time: no dice")
	assert_eq(PresentRules.interval_s(-5), PresentRules.interval_s(0))


func test_a_present_comes_after_enough_active_play_with_a_pet() -> void:
	var d := ProgressData.new()
	var need := PresentRules.interval_s(0)
	var ready := false
	var seconds := 0
	while not ready and seconds < 3000:
		ready = PresentRules.tick(d, 1.0, true, true)
		seconds += 1
	assert_true(ready)
	assert_eq(seconds, int(ceil(need)))
	assert_true(d.present_waiting)


func test_no_present_without_a_pet_or_while_not_playing() -> void:
	var d := ProgressData.new()
	for i in 3000:
		assert_false(PresentRules.tick(d, 1.0, false, true), "idle, asleep or paused: the clock stands still")
		assert_false(PresentRules.tick(d, 1.0, true, false), "no pet here: nobody brings a present")
	assert_eq(d.present_s, 0.0)
	assert_false(d.present_waiting)


## Nothing for being away: a phone asleep for ten hours (or a clock set a year ahead) comes back as one
## long frame, and a frame counts at most MAX_STEP.
func test_time_away_counts_nothing() -> void:
	var d := ProgressData.new()
	assert_false(PresentRules.tick(d, 10.0 * 3600.0, true, true))
	assert_eq(d.present_s, PresentRules.MAX_STEP)
	assert_false(PresentRules.tick(d, -500.0, true, true), "a clock turned back counts nothing either")
	assert_eq(d.present_s, PresentRules.MAX_STEP)
	assert_false(PresentRules.tick(d, NAN, true, true))
	assert_eq(d.present_s, PresentRules.MAX_STEP)


func test_a_waiting_present_stops_the_clock_until_opened() -> void:
	var d := ProgressData.new()
	d.present_waiting = true
	for i in 5000:
		assert_false(PresentRules.tick(d, 1.0, true, true))
	assert_eq(d.present_s, 0.0, "presents never pile up")


func test_the_child_picks_one_of_three_small_gifts() -> void:
	for survivor in [true, false]:
		var list := PresentRules.gifts(survivor)
		assert_eq(list.size(), 3)
		for id: StringName in list:
			var g := PresentRules.gift(id, survivor)
			assert_eq(g.id, id)
			assert_true(ProgressPictures.knows(g.picture), String(id))
			assert_lte(str(g.words).split(" ").size(), 3, str(g.words))
	assert_eq(int(PresentRules.gift(&"gold", true).gold), 15)
	assert_eq(PresentRules.gift(&"gold", false), {}, "Sandbox gold is endless: stickers there")
	assert_eq(PresentRules.gift(&"gift_flower", true), {}, "each mode its own list")
	assert_eq(int(PresentRules.gift(&"lanterns", true).item), BlockIds.LANTERN)
	assert_eq(int(PresentRules.gift(&"lanterns", true).count), 2)
	assert_eq(str(PresentRules.gift(&"gift_flower", false).sticker), "gift_flower")


func test_opening_a_present_takes_one_gift_and_restarts_the_clock() -> void:
	var d := ProgressData.new()
	assert_eq(PresentRules.open(d, &"gift_star", false), {}, "nothing is waiting")
	d.present_waiting = true
	d.present_s = 12.0
	assert_eq(PresentRules.open(d, &"made_up", false), {}, "not on the list")
	assert_true(d.present_waiting, "a bad choice keeps the present")
	var g := PresentRules.open(d, &"gift_star", false)
	assert_eq(g.id, &"gift_star")
	assert_false(d.present_waiting)
	assert_eq(d.present_s, 0.0)
	assert_eq(d.presents, 1)
	assert_eq(int(d.stickers.get("gift_star", 0)), 1, "a Sandbox gift is a sticker")
	var e := ProgressData.new()
	e.present_waiting = true
	PresentRules.open(e, &"gold", true)
	assert_eq(e.stickers, {}, "Survivor gifts come from the host (gold, blocks)")


func test_the_host_gives_a_player_a_present_at_most_every_few_minutes() -> void:
	assert_true(PresentRules.host_allows(-1, 0))
	assert_false(PresentRules.host_allows(0, PresentRules.CLAIM_GAP_MS - 1))
	assert_true(PresentRules.host_allows(0, PresentRules.CLAIM_GAP_MS))
	assert_lt(PresentRules.CLAIM_GAP_MS, int(PresentRules.interval_s(0) * 1000.0), "a real present is never refused")
