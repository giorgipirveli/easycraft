extends GutTest
## Spec §23.1-23.2 (owner #74): the Science Lab's screen (LabScreen). A page of big experiment cards; each experiment in
## three steps: 1 PREDICT (a guess, never marked), 2 TRY IT (the small scene, every step a tap; WHAT HAPPENED? opens once
## the child has seen it), 3 WHAT HAPPENED AND WHY (the guess, the result, the why cards read aloud; the Lab Book's
## star). LEARN MORE opens the School's unit. Survivor's supplies come from the bag. Every page fits the School's frame
## (1180 × 636, inside the menu's panel on a 1280 × 720 screen), every button is at least 64 px, every page can be read
## aloud. The screen works on its own profile, save hook and clock (tests never touch the real profile).

const NOW := 2_000_000_000

var profile: ProfileData
var saves := 0
var clock := [NOW]
var screen: LabScreen


func before_each() -> void:
	LabExperiments.clear_cache()
	Curriculum.clear_cache()
	profile = ProfileData.new()
	saves = 0
	clock = [NOW]


func after_all() -> void:
	Audio.stop_all()


func _open() -> LabScreen:
	screen = LabScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.now = func() -> int: return clock[0]
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _labels() -> String:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return "\n".join(out)


## Makes the guess: the right one, or another.
func _guess(right: bool) -> void:
	var p := LabExperiments.predict_of(LabExperiments.experiment(screen.experiment_id))
	var w := screen.predict_answer
	if str(p.type) == "choice":
		w.choose(int(p.answer) if right else (int(p.answer) + 1) % (p.choices as Array).size())
	else:
		for i in (p.items as Array).size():
			var want := int(p.answer[i]) if right else 0
			while w.picked[i] != want:
				w.tap(i)


## Taps the scene's own buttons until the experiment is done (every step reachable by taps).
func _finish_by_taps() -> void:
	var v := screen.view
	match screen.model.kind:
		"tank", "magnet":
			for b: Button in v.thing_buttons:
				b.pressed.emit()
		"heat":
			for i in 9:
				v.warm_button.pressed.emit()
			for i in 7:
				v.cool_button.pressed.emit()
		"colours":
			var pots: Array[Button] = v.paint_buttons   # red, yellow, blue
			for pair: Array in [[0, 1], [1, 2], [0, 1, 2]]:
				v.clean_button.pressed.emit()
				for i: int in pair:
					pots[i].pressed.emit()
			v.light_buttons[0].pressed.emit()
			v.light_buttons[1].pressed.emit()
			v.light_buttons[2].pressed.emit()
		"plants":
			for b: Button in v.pot_buttons:
				b.pressed.emit()
			clock[0] += int(2 * LabPlants.DAY)
			v.look_button.pressed.emit()
		"circuit":
			v.switch_button.pressed.emit()
			v.wire_buttons[0].pressed.emit()
			v.wire_buttons[0].pressed.emit()
			v.bulb_button.pressed.emit()
	await wait_process_frames(1)


# --- The list -------------------------------------------------------------------------------------------------------

func test_the_lab_opens_on_a_card_for_every_experiment() -> void:
	await _open()
	assert_eq(screen.page, LabScreen.LIST)
	assert_eq(screen.cards.size(), LabExperiments.ids().size())
	for c: Button in screen.cards:
		assert_gte(c.custom_minimum_size.x, 300.0, "a big picture card")
		assert_gte(c.custom_minimum_size.y, 200.0)
	screen.cards[1].pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.PREDICT)
	assert_eq(screen.experiment_id, "magnets")


# --- Every experiment, by taps --------------------------------------------------------------------------------------

func test_every_experiment_goes_predict_try_why_by_taps_and_earns_its_star() -> void:
	await _open()
	for id in LabExperiments.ids():
		screen.open(id)
		await wait_process_frames(1)
		assert_eq(screen.page, LabScreen.PREDICT, id)
		var go := _button("TRY IT!")
		assert_not_null(go, id)
		assert_true(go.disabled, "%s: first a guess" % id)
		_guess(id != "magnets")
		assert_false(go.disabled, "%s: a guess made" % id)
		go.pressed.emit()
		await wait_process_frames(1)
		assert_eq(screen.page, LabScreen.TRY, id)
		var what := _button("WHAT HAPPENED?")
		assert_true(what.disabled, "%s: first see it happen" % id)
		await _finish_by_taps()
		assert_true(screen.model.done(), "%s: finished by taps" % id)
		assert_false(what.disabled, id)
		what.pressed.emit()
		await wait_process_frames(1)
		assert_eq(screen.page, LabScreen.WHY, id)
		assert_true(profile.lab.has_star(id), "%s: a star in the Lab Book" % id)
		assert_true(profile.lab.guess(id) != null, "%s: the guess is kept" % id)
		var e := LabExperiments.experiment(id)
		var text := _labels()
		assert_string_contains(text, str(e.result), id)
		assert_string_contains(text, LabExperiments.predict_words(e, profile.lab.guess(id)), id)
		assert_string_contains(text, str(e.why[0]), "%s: the first why card" % id)
	assert_gt(saves, 0)


## Owner #79 (spec §25.1): a new star in the Lab Book pays EarnRules.LAB_STAR_GOLD, once per experiment.
func test_a_new_star_pays_its_gold_once() -> void:
	await _open()
	var gold := profile.survivor_gold
	for run in 2:
		screen.open("melting")
		await wait_process_frames(1)
		_guess(true)
		_button("TRY IT!").pressed.emit()
		await wait_process_frames(1)
		await _finish_by_taps()
		_button("WHAT HAPPENED?").pressed.emit()
		await wait_process_frames(1)
		if run == 0:
			assert_string_contains(_labels(), EarnRules.lab_words())
		else:
			assert_false(_labels().contains(EarnRules.lab_words()), "the second time: no new star, no gold")
	assert_eq(profile.survivor_gold, gold + EarnRules.LAB_STAR_GOLD)


func test_a_guess_that_did_not_match_is_never_marked_wrong() -> void:
	await _open()
	screen.open("melting")
	_guess(false)
	_button("TRY IT!").pressed.emit()
	await _finish_by_taps()
	_button("WHAT HAPPENED?").pressed.emit()
	await wait_process_frames(1)
	var text := _labels()
	assert_string_contains(text, LabScreen.GUESS_AGAIN, "scientists guess wrong all the time")
	assert_false(text.to_lower().contains("incorrect"))
	assert_false(text.contains("Not yet"), "no School-style miss either")
	assert_false(profile.lab.matched("melting"))
	assert_true(profile.lab.has_star("melting"), "a star for doing it, whatever the guess")
	screen.open("melting")
	_guess(true)
	_button("TRY IT!").pressed.emit()
	await _finish_by_taps()
	_button("WHAT HAPPENED?").pressed.emit()
	await wait_process_frames(1)
	assert_string_contains(_labels(), LabScreen.GUESS_MATCHED)
	assert_true(profile.lab.matched("melting"))
	assert_eq(profile.lab.runs("melting"), 2)


func test_a_choice_can_be_changed_before_trying() -> void:
	await _open()
	screen.open("circuit")
	var w := screen.predict_answer
	w.choose(1)
	w.choose(0)
	assert_eq(w.response(), 0)
	for b: Button in w.buttons:
		assert_false(b.disabled, "every guess stays open: none is ever greyed out")


func test_the_why_cards_turn_and_the_speaker_reads_them() -> void:
	await _open()
	screen.open("magnets")
	_guess(true)
	_button("TRY IT!").pressed.emit()
	await _finish_by_taps()
	_button("WHAT HAPPENED?").pressed.emit()
	await wait_process_frames(1)
	var e := LabExperiments.experiment("magnets")
	assert_eq(screen.why_card.text, str(e.why[0]))
	_button("NEXT").pressed.emit()
	assert_eq(screen.why_card.text, str(e.why[1]))
	assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0)


# --- Plants: two game days ------------------------------------------------------------------------------------------

func test_the_plants_keep_growing_while_the_child_is_away() -> void:
	await _open()
	screen.open("plants")
	_guess(true)
	_button("TRY IT!").pressed.emit()
	await wait_process_frames(1)
	for b: Button in screen.view.pot_buttons:
		b.pressed.emit()
	assert_eq(profile.lab.planted_at("plants"), NOW, "the planting is kept in the Lab Book")
	assert_false(screen.model.done())
	screen.show_list()
	clock[0] += int(LabPlants.DAY)
	screen.open("plants")
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.TRY, "planted: straight back to the pots")
	assert_eq((screen.model as LabPlants).days(), 1)
	assert_string_contains(_labels(), "Day 1 of 2")
	clock[0] += int(LabPlants.DAY)
	screen.view.look_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(screen.model.done())
	_button("WHAT HAPPENED?").pressed.emit()
	await wait_process_frames(1)
	assert_true(profile.lab.has_star("plants"))
	assert_eq(profile.lab.planted_at("plants"), 0, "done: the pots are empty for next time")


# --- Survivor's supplies --------------------------------------------------------------------------------------------

func test_survivor_supplies_come_from_the_bag() -> void:
	await _open()
	var asked: Array[String] = []
	var have := [false]
	screen.supplies = func(e: Dictionary) -> String:
		asked.append(str(e.id))
		return "" if have[0] else "The bench needs %s from your bag." % LabExperiments.supplies_words(e)
	screen.open("float_sink")
	_guess(true)
	_button("TRY IT!").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.PREDICT, "not without its supplies")
	assert_string_contains(_labels(), "1 Planks and 1 Stone")
	have[0] = true
	_button("TRY IT!").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.TRY)
	assert_eq(asked, ["float_sink", "float_sink"] as Array[String])


# --- LEARN MORE and the Lab Book ------------------------------------------------------------------------------------

func test_learn_more_opens_the_units_page_for_the_childs_grade() -> void:
	profile.school.grade = 5
	await _open()
	var got: Array[String] = []
	screen.learn_more = func(unit_id: String) -> void: got.append(unit_id)
	screen.open("melting")
	_guess(true)
	_button("TRY IT!").pressed.emit()
	await _finish_by_taps()
	_button("WHAT HAPPENED?").pressed.emit()
	await wait_process_frames(1)
	_button("LEARN MORE").pressed.emit()
	assert_eq(got, ["g5.science.particles"] as Array[String])


func test_learn_more_shows_the_school_inside_the_lab_and_comes_back() -> void:
	profile.school.grade = 3
	await _open()
	screen.open("magnets")
	screen.show_learn("g3.science.magnets")
	await wait_process_frames(2)
	assert_eq(screen.page, LabScreen.LEARN)
	var school := screen.school
	assert_not_null(school)
	assert_eq(school.page, SchoolScreen.UNIT)
	assert_eq(school.unit_id, "g3.science.magnets")
	assert_null(school.find_child("TryInLab", true, false), "no Lab inside the Lab")
	school.closed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.PREDICT, "back to the experiment")


func test_the_lab_book_page_shows_guesses_results_and_stars() -> void:
	profile.lab.set_guess("magnets", [0, 1, 1, 0, 1, 1, 0, 1], false)
	profile.lab.finish("magnets")
	await _open()
	screen.show_book()
	await wait_process_frames(1)
	assert_eq(screen.page, LabScreen.BOOK)
	var book := screen.book
	assert_eq(book.tiles().size(), LabExperiments.ids().size())
	var m := LabExperiments.ids().find("magnets")
	assert_true(book.tile_star(m))
	assert_false(book.tile_star(0), "float or sink not done yet")
	assert_eq(book.count_label.text, "1 of %d experiments done" % LabExperiments.ids().size())
	book.open_card("magnets")
	var e := LabExperiments.experiment("magnets")
	assert_string_contains(book.detail_guess.text, LabExperiments.predict_words(e, profile.lab.guess("magnets")))
	assert_string_contains(book.detail_result.text, str(e.result))
	assert_string_contains(book.detail_note.text, LabScreen.GUESS_AGAIN)
	book.open_card("float_sink")
	assert_string_contains(book.detail_result.text, "Not tried yet")


# --- Fit, touch and read-aloud --------------------------------------------------------------------------------------

func _fits(name: String) -> void:
	await wait_process_frames(2)
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [name, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [name, size])
	assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % name)
	for b in screen.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.is_visible_in_tree():
			var s := btn.get_combined_minimum_size().max(btn.size)
			assert_gte(s.x, 64.0, "%s: %s is wide enough for small fingers" % [name, btn.name])
			assert_gte(s.y, 64.0, "%s: %s is tall enough for small fingers" % [name, btn.name])


func test_every_page_fits_the_frame_with_big_buttons_and_a_speaker() -> void:
	await _open()
	await _fits("list")
	for id in LabExperiments.ids():
		screen.open(id)
		await _fits("%s predict" % id)
		_guess(true)
		_button("TRY IT!").pressed.emit()
		await _fits("%s try" % id)
		await _finish_by_taps()
		await _fits("%s try, done" % id)
		_button("WHAT HAPPENED?").pressed.emit()
		await _fits("%s why" % id)
	screen.show_book()
	await _fits("the Lab Book")
	screen.book.open_card("magnets")
	await _fits("a Lab Book card")
	assert_eq(screen.find_children("*", "Timer", true, false).size(), 0, "no timers anywhere in the Lab")
