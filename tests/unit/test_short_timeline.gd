extends GutTest
## Owner #94 (spec §5.12b): a Short is a timeline. Every actor's look at any moment is a pure function of the time
## (ShortTimeline.actor_state), so the player can seek, the feed can snap to any frame and a test can check a frame.


func _actor(moves: Array, extra: Dictionary = {}) -> Dictionary:
	var a := {"kind": "words", "text": "Hi", "at": [100, 200], "moves": moves}
	a.merge(extra, true)
	return a


func _short(seconds: Array) -> Dictionary:
	var scenes: Array = []
	for s: float in seconds:
		scenes.append({"seconds": s, "background": "sky", "caption": "A", "say": "A", "actors": []})
	return {"id": "t", "title": "T", "topic": "science", "scenes": scenes}


# --- Easing ---------------------------------------------------------------------------------------------------------

func test_every_ease_starts_at_0_and_ends_at_1() -> void:
	for e: String in ShortTimeline.EASES:
		assert_almost_eq(ShortTimeline.ease_value(e, 0.0), 0.0, 0.001, e)
		assert_almost_eq(ShortTimeline.ease_value(e, 1.0), 1.0, 0.001, e)


func test_back_overshoots_and_bounce_lands_bouncing() -> void:
	var peak := 0.0
	for i in 101:
		peak = maxf(peak, ShortTimeline.ease_value("back", i / 100.0))
	assert_gt(peak, 1.05, "a pop overshoots: it grows a little too big, then settles")
	# out-bounce touches 1 before the end (the first landing), then leaves it again (the bounce)
	assert_almost_eq(ShortTimeline.ease_value("bounce", 1.0 / 2.75), 1.0, 0.01)
	assert_lt(ShortTimeline.ease_value("bounce", 0.6), 0.99)


func test_an_unknown_ease_is_smooth() -> void:
	assert_eq(ShortTimeline.ease_value("zigzag", 0.3), ShortTimeline.ease_value("smooth", 0.3))


# --- Entrances ------------------------------------------------------------------------------------------------------

func test_an_actor_without_an_entrance_is_there_from_the_start() -> void:
	var s := ShortTimeline.actor_state(_actor([]), 0.0)
	assert_true(s.visible)
	assert_eq(s.pos, Vector2(100, 200))
	assert_almost_eq(float(s.scale), 1.0, 0.0001)
	assert_almost_eq(float(s.alpha), 1.0, 0.0001)


func test_a_pop_hides_it_until_then_overshoots_and_settles() -> void:
	var a := _actor([{"do": "pop", "at": 1.0}])
	assert_false(ShortTimeline.actor_state(a, 0.99).visible, "hidden before its pop")
	var biggest := 0.0
	for i in 46:
		biggest = maxf(biggest, float(ShortTimeline.actor_state(a, 1.0 + i * 0.01).scale))
	assert_gt(biggest, 1.05, "it pops a little too big")
	var settled := ShortTimeline.actor_state(a, 2.0)
	assert_true(settled.visible)
	assert_almost_eq(float(settled.scale), 1.0, 0.0001, "then settles")
	assert_almost_eq(float(settled.alpha), 1.0, 0.0001)


func test_a_drop_falls_from_above_and_bounces_on_arrival() -> void:
	var a := _actor([{"do": "drop", "at": 0.0, "dur": 1.0, "height": 300}])
	assert_almost_eq((ShortTimeline.actor_state(a, 0.0).pos as Vector2).y, -100.0, 0.5, "300 above its place")
	var ys: Array[float] = []
	for i in 101:
		ys.append((ShortTimeline.actor_state(a, i / 100.0).pos as Vector2).y)
	var landed := -1
	for i in ys.size():
		if ys[i] > 190.0:
			landed = i
			break
	assert_true(landed > 0 and landed < 60, "it lands long before the end (%d)..." % landed)
	var after: Array[float] = ys.slice(landed, landed + 30)
	assert_lt(after.min(), ys[landed] - 20.0, "...and bounces up again")
	assert_almost_eq(ys[100], 200.0, 0.01, "then rests in its place")


func test_draw_on_goes_from_nothing_to_the_whole_line() -> void:
	var a := {"kind": "arrow", "from": [0, 0], "to": [100, 0], "at": [50, 0], "moves": [{"do": "draw", "at": 0.5, "dur": 1.0}]}
	assert_false(ShortTimeline.actor_state(a, 0.4).visible)
	assert_almost_eq(float(ShortTimeline.actor_state(a, 0.5).draw), 0.0, 0.0001)
	var mid := float(ShortTimeline.actor_state(a, 1.0).draw)
	assert_true(mid > 0.3 and mid < 1.0, "half-way it is partly drawn: %s" % mid)
	assert_almost_eq(float(ShortTimeline.actor_state(a, 1.6).draw), 1.0, 0.0001)


func test_a_slide_comes_in_from_its_side() -> void:
	var a := _actor([{"do": "slide", "at": 0.0, "dur": 0.6, "from": [-100, 200]}])
	assert_almost_eq((ShortTimeline.actor_state(a, 0.0).pos as Vector2).x, -100.0, 0.01)
	assert_eq(ShortTimeline.actor_state(a, 0.6).pos, Vector2(100, 200))


# --- Moves ----------------------------------------------------------------------------------------------------------

func test_moves_chain_one_after_another() -> void:
	var a := _actor([{"do": "move", "at": 0.0, "dur": 1.0, "to": [200, 200]}, {"do": "move", "at": 1.0, "dur": 1.0, "to": [200, 400]}])
	assert_eq(ShortTimeline.actor_state(a, 1.0).pos, Vector2(200, 200))
	assert_eq(ShortTimeline.actor_state(a, 3.0).pos, Vector2(200, 400))
	var half := ShortTimeline.actor_state(a, 1.5).pos as Vector2
	assert_eq(half.x, 200.0)
	assert_true(half.y > 200.0 and half.y < 400.0)


func test_grow_spin_fade_and_value() -> void:
	var a := _actor([{"do": "grow", "at": 0.0, "to": 2.0}, {"do": "spin", "at": 0.0, "dur": 1.0, "turns": 0.5},
		{"do": "fade", "at": 1.0, "to": 0.0}, {"do": "value", "at": 0.0, "dur": 1.0, "to": 250}], {"value": 0})
	var end := ShortTimeline.actor_state(a, 2.0)
	assert_almost_eq(float(end.scale), 2.0, 0.0001)
	assert_almost_eq(float(end.rot), PI, 0.0001)
	assert_almost_eq(float(end.alpha), 0.0, 0.0001)
	assert_almost_eq(float(end.value), 250.0, 0.0001)


func test_an_orbit_goes_round_at_its_period() -> void:
	var a := _actor([{"do": "orbit", "at": 0.0, "dur": 20.0, "around": [100, 100], "period": 4.0}], {"at": [200, 100]})
	assert_eq(ShortTimeline.actor_state(a, 0.0).pos, Vector2(200, 100))
	var quarter := ShortTimeline.actor_state(a, 1.0).pos as Vector2
	assert_almost_eq(quarter.x, 100.0, 0.01, "a quarter turn in a quarter of the period")
	assert_almost_eq(quarter.distance_to(Vector2(100, 100)), 100.0, 0.01, "on its circle")
	var round := ShortTimeline.actor_state(a, 4.0).pos as Vector2
	assert_almost_eq(round.x, 200.0, 0.01, "one whole turn in one period")
	assert_almost_eq(round.y, 100.0, 0.01)


func test_an_orbit_can_be_a_tilted_ellipse() -> void:
	var a := _actor([{"do": "orbit", "at": 0.0, "dur": 20.0, "around": [100, 100], "period": 4.0, "squash": 0.5}],
		{"at": [200, 100]})
	var quarter := ShortTimeline.actor_state(a, 1.0).pos as Vector2
	assert_almost_eq(absf(quarter.y - 100.0), 50.0, 0.01, "half as tall as wide")


func test_bounce_pulse_and_shake_come_back_to_rest() -> void:
	var a := _actor([{"do": "bounce", "at": 0.0, "dur": 1.0, "height": 40}, {"do": "pulse", "at": 1.0},
		{"do": "shake", "at": 2.0}])
	assert_lt((ShortTimeline.actor_state(a, 0.25).pos as Vector2).y, 195.0, "it hops up")
	assert_gt(float(ShortTimeline.actor_state(a, 1.3).scale), 1.05, "it throbs")
	var rest := ShortTimeline.actor_state(a, 3.0)
	assert_eq(rest.pos, Vector2(100, 200))
	assert_almost_eq(float(rest.scale), 1.0, 0.0001)


func test_out_pops_it_away() -> void:
	var a := _actor([{"do": "pop", "at": 0.0}, {"do": "out", "at": 2.0}])
	assert_true(ShortTimeline.actor_state(a, 1.9).visible)
	assert_false(ShortTimeline.actor_state(a, 2.5).visible, "gone after its out")


# --- Reduce motion (research A2) --------------------------------------------------------------------------------------

func test_reduce_motion_keeps_the_meaning_but_not_the_bounce() -> void:
	var a := _actor([{"do": "pop", "at": 0.0}, {"do": "bounce", "at": 1.0}, {"do": "shake", "at": 2.0},
		{"do": "move", "at": 3.0, "to": [300, 200], "ease": "bounce"}])
	for i in 60:
		var s := ShortTimeline.actor_state(a, i * 0.05, true)
		assert_lte(float(s.scale), 1.0001, "no overshoot at %.2f" % (i * 0.05))
		assert_almost_eq((s.pos as Vector2).y, 200.0, 0.0001, "no hop or shake at %.2f" % (i * 0.05))
	assert_eq(ShortTimeline.actor_state(a, 4.0, true).pos, Vector2(300, 200), "the move still happens")


# --- Scenes and seeking ---------------------------------------------------------------------------------------------

func test_the_length_is_the_sum_of_the_scenes() -> void:
	assert_almost_eq(ShortTimeline.length(_short([5.0, 7.5, 10.0])), 22.5, 0.0001)


func test_a_moment_falls_in_its_scene() -> void:
	var s := _short([5.0, 7.5, 10.0])
	assert_eq(ShortTimeline.at(s, 0.0), {"scene": 0, "local": 0.0})
	assert_eq(ShortTimeline.at(s, 5.0), {"scene": 1, "local": 0.0})
	var late := ShortTimeline.at(s, 13.0)
	assert_eq(late.scene, 2)
	assert_almost_eq(float(late.local), 0.5, 0.0001)
	assert_eq(ShortTimeline.at(s, 99.0).scene, 2, "past the end: the last scene")
	assert_almost_eq(float(ShortTimeline.at(s, 99.0).local), 10.0, 0.0001)


func test_a_count_starts_at_its_from() -> void:
	var a := {"kind": "count", "from": 3, "to": 1, "at": [100, 100], "moves": [{"do": "value", "at": 1.0, "dur": 1.0, "to": 1}]}
	assert_almost_eq(float(ShortTimeline.actor_state(a, 0.5).value), 3.0, 0.0001, "3 before it counts (its sheet showed 0)")
	assert_almost_eq(float(ShortTimeline.actor_state(a, 2.0).value), 1.0, 0.0001)


func test_the_same_moment_gives_the_same_look_however_you_get_there() -> void:
	var a := _actor([{"do": "pop", "at": 0.2}, {"do": "move", "at": 1.0, "to": [300, 50], "ease": "back"},
		{"do": "spin", "at": 1.5, "turns": 2}, {"do": "bounce", "at": 3.0}])
	var direct := ShortTimeline.actor_state(a, 3.3)
	var t := 0.0
	var stepped := {}
	while t < 3.3 - 0.0001:
		t = minf(t + 1.0 / 60.0, 3.3)
		stepped = ShortTimeline.actor_state(a, t)
	assert_eq(stepped, direct)
