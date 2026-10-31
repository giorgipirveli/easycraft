extends GutTest
## Owner #94 (the animations brief §3): one shared motion helper for the menus and the HUD (UiMotion, ui/fx/), so every
## panel feels the same: cards and panels pop in with easing, buttons squash when pressed, gold and stars fly to their
## counter, a right answer bursts a few stars, a level-up glows. Reduce motion calms all of it (a fade, no squash, fewer
## and slower pieces). The flying pieces are drawn by one pooled node per screen that sleeps when nothing flies.

var _reduce := false


func before_each() -> void:
	_reduce = bool(Profile.data.settings.get("reduce_motion", false))
	Profile.data.settings.reduce_motion = false


func after_each() -> void:
	Profile.data.settings.reduce_motion = _reduce


func _box(at: Vector2 = Vector2(100, 100), px: Vector2 = Vector2(200, 120)) -> Control:
	var c := Control.new()
	c.position = at
	c.size = px
	add_child_autofree(c)
	return c


func test_a_panel_pops_in_with_easing() -> void:
	var c := _box()
	UiMotion.pop_in(c)
	assert_lt(c.scale.x, 1.0, "it starts small")
	assert_lt(c.modulate.a, 1.0, "and faint")
	assert_eq(c.pivot_offset, c.size * 0.5, "it grows from its middle")
	await wait_seconds(UiMotion.POP_TIME + 0.15)
	assert_eq(c.scale, Vector2.ONE, "then it is exactly its size")
	assert_eq(c.modulate.a, 1.0)


func test_a_pop_twice_is_one_pop() -> void:
	var c := _box()
	UiMotion.pop_in(c)
	await wait_seconds(0.05)
	UiMotion.pop_in(c)
	await wait_seconds(UiMotion.POP_TIME + 0.15)
	assert_eq(c.scale, Vector2.ONE)
	assert_eq(c.modulate.a, 1.0)


func test_with_reduce_motion_a_panel_only_fades_in() -> void:
	Profile.data.settings.reduce_motion = true
	var c := _box()
	UiMotion.pop_in(c)
	assert_eq(c.scale, Vector2.ONE, "no growing")
	await wait_seconds(UiMotion.POP_TIME + 0.15)
	assert_eq(c.modulate.a, 1.0)


func test_a_button_squashes_when_pressed_and_springs_back() -> void:
	var b := Button.new()
	b.size = Vector2(200, 80)
	add_child_autofree(b)
	UiMotion.squash_on_press(b)
	b.button_down.emit()
	await wait_seconds(0.3)   # it holds squashed while pressed (a busy PC's slow frames still get there)
	assert_lt(b.scale.y, 0.97, "squashed")
	assert_eq(b.pivot_offset, b.size * 0.5)
	b.button_up.emit()
	await wait_seconds(0.4)
	assert_almost_eq(b.scale.x, 1.0, 0.001, "back")
	assert_almost_eq(b.scale.y, 1.0, 0.001)
	Profile.data.settings.reduce_motion = true
	b.button_down.emit()
	await wait_seconds(0.3)
	assert_eq(b.scale, Vector2.ONE, "no squash with Reduce motion")


func test_every_big_button_squashes() -> void:
	var b := UiKit.big_button("GO")
	add_child_autofree(b)
	assert_true(UiMotion.squashes(b), "UiKit's buttons all squash")
	UiMotion.squash_on_press(b)
	assert_eq(b.button_down.get_connections().size(), 1, "once, however often it is asked")


func test_coins_fly_to_their_counter_and_bump_it() -> void:
	var counter := _box(Vector2(900, 20), Vector2(120, 40))
	var host := _box(Vector2.ZERO, Vector2(1280, 720))
	var landed := []
	var flyers := UiMotion.fly(host, Vector2(640, 400), counter, 5, UiFlyers.COIN)
	flyers.arrived.connect(func(kind: StringName) -> void: landed.append(kind))
	assert_eq(flyers.alive(), 5, "five coins in the air")
	assert_true(flyers.is_processing())
	await wait_seconds(UiFlyers.FLIGHT + UiFlyers.STAGGER * 5 + 0.2)
	assert_eq(landed.size(), 5, "every coin lands")
	assert_eq(flyers.alive(), 0)
	assert_false(flyers.is_processing(), "it sleeps when nothing flies: no per-frame cost")
	assert_same(UiMotion.fly(host, Vector2.ZERO, counter, 1, UiFlyers.STAR), flyers, "one pooled node per screen")


func test_a_right_answer_bursts_a_few_stars() -> void:
	var host := _box(Vector2.ZERO, Vector2(1280, 720))
	var flyers := UiMotion.burst(host, Vector2(300, 300), 8)
	assert_eq(flyers.alive(), 8)
	await wait_seconds(UiFlyers.BURST_LIFE + 0.2)
	assert_eq(flyers.alive(), 0, "gone after a moment")
	Profile.data.settings.reduce_motion = true
	UiMotion.burst(host, Vector2(300, 300), 8)
	assert_eq(flyers.alive(), 4, "half with Reduce motion")


func test_never_more_than_a_handful_in_the_air() -> void:
	var host := _box(Vector2.ZERO, Vector2(1280, 720))
	var counter := _box(Vector2(900, 20), Vector2(120, 40))
	for i in 10:
		UiMotion.fly(host, Vector2(640, 400), counter, 8, UiFlyers.COIN)
	assert_lte(UiMotion.flyers(host).alive(), UiFlyers.MAX, "the oldest make room")


func test_a_level_up_glows_then_is_itself_again() -> void:
	var c := _box()
	var tw := UiMotion.glow(c)
	var brightest := 0.0
	while tw.is_running():   # every frame of it, however slow the PC's frames are
		brightest = maxf(brightest, c.modulate.r)
		await wait_process_frames(1)
	assert_gt(brightest, 1.0, "brighter than itself")
	assert_eq(c.modulate, Color.WHITE, "exactly itself after")


func test_flying_pieces_are_cheap() -> void:
	var host := _box(Vector2.ZERO, Vector2(1280, 720))
	var counter := _box(Vector2(900, 20), Vector2(120, 40))
	var flyers := UiMotion.fly(host, Vector2(640, 400), counter, 8, UiFlyers.COIN)
	UiMotion.burst(host, Vector2(300, 300), 8)
	var t0 := Time.get_ticks_usec()
	for i in 60:
		flyers.step(1.0 / 120.0)
	var per := (Time.get_ticks_usec() - t0) / 60.0
	gut.p("MEASURE ui flyers step %.1f us (16 pieces)" % per)
	assert_lt(per, 300.0, "well under a millisecond a frame")


# --- Where the game uses it -----------------------------------------------------------------------------------------

func test_gold_earned_flies_to_the_counter() -> void:
	assert_eq(GoldCounter.coins_for(1), 1, "a coin for a little")
	assert_eq(GoldCounter.coins_for(50), 4)
	assert_eq(GoldCounter.coins_for(100000), 8, "never a swarm")
	var gc := GoldCounter.new()
	gc.size = Vector2(200, 50)
	add_child_autofree(gc)
	gc._infinite = false
	gc._balance = 0
	gc._on_gold_changed(50)
	assert_eq(UiMotion.flyers(gc).alive(), 4, "four coins on their way")
	gc._on_gold_changed(40)
	assert_eq(UiMotion.flyers(gc).alive(), 4, "spending sends none")


func test_a_right_answer_in_the_school_bursts_stars() -> void:
	var p := ExercisePanel.new({"type": "choice", "prompt": "3 x 4 = ?", "choices": ["12", "7", "34"], "answer": 0,
		"hint": "Rows.", "level": 1}, 0)
	add_child_autofree(p)
	await wait_process_frames(1)
	p.answer_widget.choose(0)
	assert_eq(p.state, ExercisePanel.RIGHT)
	assert_eq(UiMotion.flyers(p).alive(), 8, "stars burst from the answer")


func test_the_hud_s_panels_pop_in() -> void:
	var more := MorePanel.new()
	add_child_autofree(more)
	await wait_process_frames(1)
	more.open()
	assert_lt(more.scale.x, 1.0, "the MORE panel grows in")
	await wait_seconds(UiMotion.POP_TIME + 0.15)
	assert_eq(more.scale, Vector2.ONE)
