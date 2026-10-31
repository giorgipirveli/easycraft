extends GutTest
## Owner #122 (docs/design/learning-is-play.md §6; spec §22.0): DISCOVER. The map shows each subject's units as places to
## play, each with its game's picture; a unit's page offers PLAY first and the Book (today's cards, read aloud) as a small
## choice, never LESSON then PRACTICE. PLAY opens the place (PlayHost); its end is recorded exactly as a round was
## (MasteryRules: stars, reviews, the gold once; EarnRules per answer) and offers the unit's world task as a quest card
## to take along (MY QUESTS). Stopping records nothing. Every page fits the frame and can be read aloud.
## Owner #134 (docs/design/future-lessons.md §6): a unit without enough to play without reading stays in the School as
## it was (LESSON, then PRACTICE; no game picture on the map), never dressed as a game.

const UNIT := "g4.maths.big_numbers"
const DAY := 20_000
const CONTENT := {"id": UNIT, "lesson": [
		{"text": "Quick memory: what is 3 × 4?"},
		{"text": "A digit's place tells what it is worth.", "picture": {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}},
		{"text": "Try it in the world: build a tower of 347 blocks. Next: tables."}],
	"exercises": [
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 1},
		{"type": "number", "prompt": "200 + 5 = ?", "answer": "205", "hint": "No tens.", "level": 2},
		{"type": "order", "prompt": "Smallest to biggest.", "items": ["120", "99", "347"], "answer": [1, 0, 2],
			"hint": "Look at the hundreds.", "level": 2},
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3}]}
## A unit whose questions all need reading (written choices and claims).
const READING := {"lesson": [{"text": "Rome was built on seven hills."}, {"text": "Its people voted in the Forum."}],
	"exercises": [
		{"type": "choice", "prompt": "Where did Rome's people vote?", "choices": ["the Forum", "the baths"], "answer": 0,
			"hint": "The square.", "level": 1},
		{"type": "truefalse", "prompt": "Rome was built on seven hills.", "answer": true, "hint": "Seven.", "level": 2},
		{"type": "choice", "prompt": "What did the Romans build to carry water?", "choices": ["aqueducts", "castles"],
			"answer": 0, "hint": "Water.", "level": 3}]}

var profile: ProfileData
var saves := 0
var screen: SchoolScreen
var quests := ""


func before_each() -> void:
	ParentGate.reset_tries()
	Curriculum.clear_cache()
	Curriculum.put_content(UNIT, CONTENT)
	profile = ProfileData.new()
	saves = 0
	quests = "user://test_play_screen_quests_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(quests):
		DirAccess.remove_absolute(quests)


func after_each() -> void:
	if is_instance_valid(screen) and is_instance_valid(screen.play_host) and not screen.play_host.closed:
		screen.play_host.close()
	Curriculum.clear_cache()
	if FileAccess.file_exists(quests):
		DirAccess.remove_absolute(quests)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(grade: int = 4) -> SchoolScreen:
	profile.school.grade = grade
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.quests_path = quests
	layer.add_child(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _labels() -> Array[String]:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return out


## The place's round ends with `right_first` of 6 right the first time.
func _play_through(right_first: int) -> void:
	screen.show_play(UNIT)
	await wait_process_frames(2)
	var host := screen.play_host
	host.finished.emit({"right_first": right_first, "total": 6, "world_task": host.loop.world_task})
	host.close()
	await wait_process_frames(2)


func test_a_unit_offers_play_first_and_the_book_as_a_small_choice() -> void:
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	var play := _button(SchoolScreen.PLAY_WORDS)
	var book := _button(SchoolScreen.BOOK_WORDS)
	assert_not_null(play, "PLAY")
	assert_not_null(book, "the Book")
	assert_gt(play.custom_minimum_size.y, book.custom_minimum_size.y, "PLAY is the big one")
	assert_null(_button("LESSON"), "no lesson first")
	assert_null(_button("PRACTICE"), "no practice round")
	assert_true(_labels().any(func(t: String) -> bool: return t.contains(PlayMechanics.name_of("make"))),
		"the page says what you play")


class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []
	func has_voice(_language: String) -> bool:
		return true
	func speak(text: String, _language: String) -> void:
		said.append(text)
	func is_speaking() -> bool:
		return false


## The lead on the emulator (2026-10-18, owner #133 "consider no one will start reading"): a playing unit's page put a
## grown-up's text above PLAY ("You will learn to:", its goals, "Common Core: 4.NBT…", an 18-word tip). Now its games are
## big pictures, Hoot says what to do as it opens, PLAY is the big button, and the goals and standards are a small
## "For grown-ups" note.
func test_a_playing_units_page_is_pictures_and_hoots_voice() -> void:
	var voice := FakeVoice.new()
	var old_voice := ReadAloud.voice
	var old_queue := ReadAloud.queue
	var old_read := bool(Profile.data.settings.read_to_me)
	ReadAloud.voice = voice
	ReadAloud.queue = SpeechQueue.new()
	Profile.data.settings.read_to_me = true
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	ReadAloud.pump(1000.0)
	ReadAloud.voice = old_voice
	ReadAloud.queue = old_queue
	Profile.data.settings.read_to_me = old_read
	assert_true(voice.said.any(func(t: String) -> bool: return t.contains("PLAY")), "Hoot says what to do: %s" % [voice.said])
	var icons := screen.find_children("PlayIcon", "PlayIcon", true, false)
	assert_false(icons.is_empty())
	for i: Control in icons:
		assert_gte(i.custom_minimum_size.x, 72.0, "the games are big pictures")
	for l in screen.find_children("*", "Label", true, false):
		var label := l as Label
		if label.is_visible_in_tree() and (label.text.contains("You will learn") or label.text.contains("Common Core")):
			assert_lte(label.get_theme_font_size("font_size"), 18, "a small note, not the page: " + label.text)
	assert_true(_labels().any(func(t: String) -> bool: return t.begins_with(SchoolScreen.GROWN_UPS_NOTE)),
		"the goals are for grown-ups")


## The outline's second maths unit of grade 4, its content all reading.
func _reading_unit() -> String:
	var id := str(Curriculum.units(4, "maths")[1].id)
	var c := READING.duplicate(true)
	c.id = id
	Curriculum.put_content(id, c)
	return id


func test_a_unit_that_needs_reading_stays_in_the_school_as_it_was() -> void:
	var id := _reading_unit()
	await _open()
	screen.show_unit(id)
	await wait_process_frames(1)
	assert_null(_button(SchoolScreen.PLAY_WORDS), "a written quiz is not dressed as a game")
	assert_not_null(_button("LESSON"))
	assert_not_null(_button("PRACTICE"))
	_button("PRACTICE").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.ROUND, "the School's own round")
	screen.show_lesson(id, 1)
	await wait_process_frames(1)
	assert_not_null(_button(SchoolScreen.PRACTISE_WORDS), "its Book ends in practice")
	assert_null(_button(SchoolScreen.BOOK_PLAY_WORDS))
	screen.show_map("maths")
	await wait_process_frames(1)
	for s in screen.stops:
		if s.unit_id == id:
			assert_eq(s.find_children("PlayIcon", "PlayIcon", true, false).size(), 0, "no game picture on its stop")


func test_play_opens_the_place_and_hides_the_school() -> void:
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	_button(SchoolScreen.PLAY_WORDS).pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.PLAY)
	assert_not_null(screen.play_host)
	assert_false((screen.get_parent() as CanvasLayer).visible, "the place shows instead")
	assert_eq(screen.play_host.unit_id, UNIT)


func test_the_end_of_play_counts_like_a_round_with_the_gold_once() -> void:
	var gold := profile.survivor_gold
	await _open()
	await _play_through(5)
	assert_eq(screen.page, SchoolScreen.ROUND_END)
	assert_has(_labels(), "5 of 6 right the first time!")
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 2, "mastered")
	assert_eq(profile.survivor_gold, gold + MasteryRules.UNIT_GOLD, "the unit's gold (answers' gold is the host's)")
	assert_gt(saves, 0)
	assert_true((screen.get_parent() as CanvasLayer).visible, "the School is back")
	_button(SchoolScreen.PLAY_AGAIN_WORDS).pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.PLAY, "come back: the same game, new challenges")
	var host2 := screen.play_host
	host2.finished.emit({"right_first": 6, "total": 6, "world_task": ""})
	host2.close()
	await wait_process_frames(2)
	assert_eq(profile.survivor_gold, gold + MasteryRules.UNIT_GOLD, "paid once")


func test_a_weaker_play_gives_the_first_star() -> void:
	await _open()
	await _play_through(3)
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 1)
	assert_has(_labels(), "3 of 6 right the first time.")


func test_stopping_the_play_records_nothing() -> void:
	await _open()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	screen.play_host.stop_for_now()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.UNIT)
	assert_eq(profile.school.progress(UNIT), SchoolData.new().progress(UNIT))


func test_the_end_offers_the_world_task_as_a_quest_card_to_take() -> void:
	await _open()
	await _play_through(5)
	assert_has(_labels(), "Build a tower of 347 blocks.")
	_button(SchoolScreen.TAKE_WORDS).pressed.emit()
	await wait_process_frames(1)
	assert_true(PlayQuests.open_at(quests).has(UNIT), "kept on the device")
	screen.show_quests()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.QUESTS)
	assert_has(_labels(), "Build a tower of 347 blocks.")
	_button(SchoolScreen.DONE_WORDS).pressed.emit()
	await wait_process_frames(1)
	assert_eq(PlayQuests.open_at(quests).open_cards().size(), 0, "ticked")


func test_the_book_is_the_cards_and_ends_in_play() -> void:
	await _open()
	screen.show_lesson(UNIT)
	await wait_process_frames(1)
	assert_true(_labels().any(func(t: String) -> bool: return t.begins_with(SchoolScreen.BOOK_TITLE)), "the Book")
	assert_has(_labels(), "Quick memory: what is 3 × 4?", "today's cards, as they are")
	_button("NEXT").pressed.emit()
	_button("NEXT").pressed.emit()
	await wait_process_frames(1)
	_button(SchoolScreen.BOOK_PLAY_WORDS).pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.PLAY)


func test_a_review_due_says_play_again_review() -> void:
	profile.school.set_progress(UNIT, MasteryRules.after_round(profile.school.progress(UNIT), 6, 6, DAY - 3).progress)
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	assert_not_null(_button(SchoolScreen.REVIEW_WORDS))


func test_the_map_shows_places_to_play_each_with_its_game() -> void:
	await _open()
	screen.show_map("maths")
	await wait_process_frames(1)
	var stop: UnitStop = null
	for s in screen.stops:
		if s.unit_id == UNIT:
			stop = s
	assert_not_null(stop)
	var icons := stop.find_children("PlayIcon", "PlayIcon", true, false)
	assert_eq(icons.size(), 1, "its game's picture")
	assert_eq((icons[0] as PlayIcon).mechanic, PlayMechanics.main_of(Curriculum.content(UNIT)))
	assert_true(_labels().any(func(t: String) -> bool: return t.contains(SchoolScreen.PLACES_WORDS)), "places to play")


func test_the_welcome_says_discover() -> void:
	profile.school.grade = 0
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	screen.today = func() -> int: return DAY
	add_child_autofree(screen)
	await wait_process_frames(2)
	assert_true(_labels().any(func(t: String) -> bool: return t.contains("DISCOVER")))
	assert_false(_labels().any(func(t: String) -> bool: return t.to_lower().contains("welcome to school")))


func test_the_new_pages_fit_the_frame_and_have_a_speaker() -> void:
	await _open()
	var pages := {
		"unit": func() -> void: screen.show_unit(UNIT),
		"book": func() -> void: screen.show_lesson(UNIT),
		"quests": func() -> void: screen.show_quests(),
	}
	for name: String in pages:
		(pages[name] as Callable).call()
		await wait_process_frames(2)
		var size := screen.get_combined_minimum_size()
		assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [name, size])
		assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [name, size])
		assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % name)
	await _play_through(5)
	var end := screen.get_combined_minimum_size()
	assert_lte(end.x, SchoolUi.FRAME.x, "the play's end is %s" % end)
	assert_lte(end.y, SchoolUi.FRAME.y, "the play's end is %s" % end)


func test_the_grown_ups_page_shows_each_unit_s_play_level() -> void:
	await _open()
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	var page: SchoolGrownUpsPage = screen.find_children("*", "SchoolGrownUpsPage", true, false)[0]
	var levels := page.find_children("PlayLevel", "Label", true, false)
	assert_eq(levels.size(), page.rows.size(), "every unit's play level")
	assert_eq((levels[0] as Label).text, PlayMechanics.P0)
	assert_true(_labels().any(func(t: String) -> bool: return t.contains("P0") and t.contains("P1")), "what they mean")
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "still fits: %s" % size)
