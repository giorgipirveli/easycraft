extends GutTest
## The HUD's game clock (spec §12.18): one label, never a button. Build to Survive: a moon and "Night in 1:20"
## by day, a sun and "Morning in 0:45" at night, the score under it; near and during the night the shelter's
## words instead, with a house when safe. Monster Wave: a sword, "3:24 · Wave 5" and the best, and a defeat's
## kill bonus popping up for a moment. Game time only; kind words.


func _clock() -> GameClock:
	var c := GameClock.new()
	add_child_autofree(c)
	return c


func test_it_is_a_label_that_never_takes_a_tap() -> void:
	var c := _clock()
	assert_eq(c.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var o: Object = c
	assert_false(o is BaseButton)
	assert_eq(c.size, GameClock.SIZE)


func test_by_day_the_night_clock_and_the_score() -> void:
	var c := _clock()
	c.show_build(BuildRules.START_TIME, 3, 5, ShelterRules.OPEN)
	assert_eq(c.symbol(), &"moon")
	assert_eq(c.line(), "Night in 3:00")
	assert_eq(c.small_line(), "Nights 3 · Best 5")


func test_close_to_night_and_at_night_the_shelter_speaks() -> void:
	var c := _clock()
	var t := DayCycle.SUNSET - 50.0 * BuildRules.DAY_SPEED / DayCycle.LENGTH   # 50 s before the night
	c.show_build(t, 0, 0, ShelterRules.NO_ROOF)
	assert_eq(c.line(), "Night in 0:50")
	assert_eq(c.small_line(), "Add a roof!")
	c.show_build(DayCycle.MIDNIGHT, 0, 0, ShelterRules.GAP)
	assert_eq(c.symbol(), &"wake", "a sun: counting to the morning")
	assert_eq(c.line(), "Morning in 1:30")
	assert_eq(c.small_line(), "Close the gap!")
	c.show_build(DayCycle.MIDNIGHT, 0, 0, ShelterRules.SAFE)
	assert_eq(c.symbol(), &"home")
	assert_eq(c.small_line(), "Safe inside!")


## Monster Wave (spec §12.20): a sword, the time survived and the wave, the best under it; a defeat's kill
## bonus pops up there for a moment.
func test_monster_wave_shows_the_time_the_wave_and_the_best() -> void:
	var c := _clock()
	c.show_arena(204.0, 5, {"best_time": 190.0, "best_wave": 5})
	assert_eq(c.symbol(), &"attack")
	assert_eq(c.line(), "3:24 · Wave 5")
	assert_eq(c.small_line(), "Best 3:10 · Wave 5")
	c.show_arena(12.0, 1, ArenaRules.new_record())
	assert_eq(c.small_line(), "Your first run!")


func test_the_kill_bonus_pops_up_for_a_moment() -> void:
	var c := _clock()
	c.show_arena(30.0, 1, ArenaRules.new_record())
	c.show_paid(4, 2)
	assert_eq(c.small_line(), "+4 × 2!")
	c.show_arena(31.0, 1, ArenaRules.new_record())
	assert_eq(c.small_line(), "+4 × 2!", "it stays a moment")
	c.pop_left = 0.0
	c.show_arena(32.0, 1, ArenaRules.new_record())
	assert_eq(c.small_line(), "Your first run!")


func test_every_symbol_is_a_hud_picture_and_every_line_is_kind() -> void:
	var c := _clock()
	var lines: Array[String] = []
	for state: StringName in [ShelterRules.SAFE, ShelterRules.NO_ROOF, ShelterRules.GAP, ShelterRules.OPEN]:
		for t in [0.0, 0.5, 0.84, 0.9]:
			c.show_build(t, 1, 2, state)
			assert_true(HudIcons.knows(c.symbol()), str(c.symbol()))
			lines.append(c.line())
			lines.append(c.small_line())
	c.show_arena(70.0, 3, ArenaRules.new_record())
	assert_true(HudIcons.knows(c.symbol()))
	for line in lines:
		for word in ["hurry", "die", "dead", "last chance", "quick!"]:
			assert_false(line.to_lower().contains(word), "%s: '%s'" % [line, word])
