extends GutTest
## Owner #112, #113, #115 (docs/design/life-skills.md §3, §7, §10, §11; spec §27): the School's 13th tab, Life. The
## first visit asks the track with big picture buttons (read aloud); a grown-up can fix it. The map shows the ten areas
## in Life's two strands; an area shows its units on the track (EASIER and HARDER look at the others); a unit has LESSON,
## PRACTICE and, for an Experience, TRY IT with the Passport's stamps. Practice pays gold like any lesson (once per unit;
## a School unit keeps the School's progress). TRY IT runs the before-check the first time, then the practice room; a
## finished try shows the "name it" card, the after-check and the stamps (a surprise on a new Expert stamp), pays the
## Experience's gold once and keeps the device's measurements; STOP FOR NOW comes back calmly. The Passport shows every
## skill; the grown-ups' page (behind the gate) sets the track, the region and the careful switches and shows the
## learning in plain words. Every page fits the School's frame and has a speaker.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


const DAY := 20_000

var profile: ProfileData
var saves := 0
var screen: LifeScreen
var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	saves = 0
	_old_voice = ReadAloud.voice
	voice = FakeVoice.new()
	ReadAloud.voice = voice
	measure_path = "user://life_measure_screen_%d.json" % OS.get_process_id()


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	if is_instance_valid(screen) and is_instance_valid(screen.host):
		screen.host.close()
	Curriculum.clear_cache()
	if FileAccess.file_exists(measure_path):
		DirAccess.remove_absolute(measure_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String = "middle") -> LifeScreen:
	profile.life.track = track
	screen = LifeScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.locale = "ka_GE"
	screen.measure = LifeMeasure.new(measure_path)
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _named(n: String) -> Node:
	var found := screen.find_children(n, "", true, false)
	return found[0] if not found.is_empty() else null


## Every word shown: the labels and the buttons' own words.
func _labels() -> String:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append((b as Button).text)
	return "\n".join(out)


# --- The School's Life tab ---

func test_the_school_map_has_a_life_tab_that_opens_life() -> void:
	profile.school.grade = 4
	var school := SchoolScreen.new()
	school.profile = profile
	school.save_profile = func() -> void: saves += 1
	school.today = func() -> int: return DAY
	add_child_autofree(school)
	await wait_process_frames(2)
	var tab := school.find_children("Tab_life", "Button", true, false)
	assert_eq(tab.size(), 1, "the 13th tab")
	assert_true((tab[0] as Node).find_child("TabIcon", true, false) is LifeIcons, "its own icon")
	(tab[0] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(school.page, SchoolScreen.LIFE)
	assert_not_null(school.life)
	school.life.closed.emit()
	await wait_process_frames(1)
	assert_eq(school.page, SchoolScreen.MAP, "BACK comes back to the School's map")


## In a headset words are 24 px and the map's tabs keep to six columns: LIFE sits in the map's header there.
func test_in_vr_life_is_in_the_school_maps_header() -> void:
	Vr.simulate(true)
	profile.school.grade = 4
	var school := SchoolScreen.new()
	school.profile = profile
	school.save_profile = func() -> void: saves += 1
	school.today = func() -> int: return DAY
	add_child_autofree(school)
	await wait_process_frames(2)
	var tabs := school.find_children("Tab_*", "Button", true, false)
	var life := school.find_children("Tab_life", "Button", true, false)
	assert_eq(life.size(), 1)
	assert_false((life[0] as Node).get_parent() is GridContainer, "not one of the grid's tabs in VR")
	(life[0] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(school.page, SchoolScreen.LIFE)
	assert_gt(tabs.size(), 3)
	Vr.simulate(false)


func test_the_schools_grown_ups_page_links_to_lifes() -> void:
	profile.school.grade = 4
	var school := SchoolScreen.new()
	school.profile = profile
	school.save_profile = func() -> void: saves += 1
	add_child_autofree(school)
	await wait_process_frames(2)
	school.show_grown_ups_page()
	await wait_process_frames(1)
	var life := school.find_children("LifeForGrownUps", "Button", true, false)
	assert_eq(life.size(), 1)
	(life[0] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(school.page, SchoolScreen.LIFE)
	assert_eq(school.life.page, LifeScreen.GROWN_UPS, "already past the gate")


# --- The track ---

func test_the_first_visit_asks_the_track_with_pictures_read_aloud() -> void:
	await _open("")
	assert_eq(screen.page, LifeScreen.TRACK)
	for word: String in ["LITTLE", "MIDDLE", "BIG"]:
		assert_not_null(_button(word), word)
	assert_gt(voice.said.size(), 0, "the question is read aloud")


func test_picking_a_track_saves_it_and_shows_the_map() -> void:
	await _open("")
	_button("MIDDLE").pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.life.track, "middle")
	assert_gt(saves, 0)
	assert_eq(screen.page, LifeScreen.MAP)


func test_a_grown_ups_lock_keeps_the_track() -> void:
	profile.life.track_locked = true
	await _open("little")
	screen.show_track()
	await wait_process_frames(1)
	assert_true(_button("BIG").disabled)
	assert_string_contains(_labels(), "A grown-up chose")


# --- The map and the areas ---

func test_the_map_shows_ten_areas_in_two_strands() -> void:
	await _open()
	assert_eq(screen.page, LifeScreen.MAP)
	assert_eq(screen.find_children("Area_*", "Button", true, false).size(), 14, "with Success S2's four (owner #115)")
	var words := _labels()
	assert_string_contains(words, "LIVING WELL")
	assert_string_contains(words, "SUCCESS")


func test_an_area_shows_its_units_and_easier_and_harder_look_at_the_others() -> void:
	await _open("little")
	screen.show_area("safe")
	await wait_process_frames(1)
	assert_string_contains(_labels(), "Call for help")
	_button("HARDER").pressed.emit()
	await wait_process_frames(1)
	assert_string_contains(_labels(), "Cuts, burns and recovery")
	assert_eq(profile.life.track, "little", "looking at another track never changes the child's own")


# --- A unit, its lesson, its practice ---

func test_an_experience_unit_has_lesson_practice_try_it_and_its_stamps() -> void:
	await _open("middle")
	screen.show_unit("life.safe.fire_escape")
	await wait_process_frames(1)
	for word: String in ["BOOK", "PRACTICE", "TRY IT"]:
		assert_not_null(_button(word), word)
	assert_not_null(_named("Stamps"))
	assert_null(_button("EXPERT TRY"), "the Expert try opens after By myself")
	profile.life.set_skill("fire_escape.middle", {"s": LifeData.DONE | LifeData.SELF})
	screen.show_unit("life.safe.fire_escape")
	await wait_process_frames(1)
	assert_not_null(_button("EXPERT TRY"))


## Owner #122 (learning is play, `docs/design/learning-is-play.md` §3 rule 2: play first, words after): an Experience
## unit offers TRY IT first and PRACTICE next; its cards are the BOOK, last, for a child who wants to read. The tip
## never says to read first.
func test_an_experience_unit_offers_try_it_first_and_the_book_last() -> void:
	await _open("middle")
	screen.show_unit("life.safe.fire_escape")
	await wait_process_frames(1)
	var try_it := _named("TryIt") as Button
	var practice := _button("PRACTICE")
	var book := _button("BOOK")
	assert_not_null(book, "the lesson's cards are the BOOK")
	assert_null(_button("LESSON"))
	assert_eq(try_it.get_parent(), book.get_parent())
	assert_lt(try_it.get_index(), practice.get_index(), "TRY IT before PRACTICE")
	assert_lt(practice.get_index(), book.get_index(), "the BOOK last")
	assert_false(_labels().contains("Read the"), "never 'read first'")
	book.pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.LESSON, "the BOOK opens the cards")


## Owner #122: a unit with no practice room (here a School lesson shown in Life) offers PRACTICE first, the BOOK after.
func test_a_unit_without_a_room_offers_practice_first_and_the_book_after() -> void:
	await _open("middle")
	screen.show_unit("g3.health_pe.germs_hygiene")
	await wait_process_frames(1)
	var practice := _button("PRACTICE")
	var book := _button("BOOK")
	assert_not_null(book)
	assert_lt(practice.get_index(), book.get_index(), "PRACTICE before the BOOK")
	assert_false(_labels().contains("Read the"), "never 'read first'")


## The emulator (2026-10-17): every Experience's card showed the same passport picture. Each has its own now, one
## the Life pictures can draw, and an area's cards show them.
func test_every_experience_card_shows_its_own_picture() -> void:
	var owner := {}
	for u: Dictionary in LifeCatalog.data().units:
		if not u.has("experience"):
			continue
		var exp_id := str(u.experience)
		var icon: String = LifeScreen.experience_icon(exp_id)
		assert_true(LifeIcons.has(icon), "%s: %s is a Life picture" % [exp_id, icon])
		assert_ne(icon, "passport", exp_id + " has its own picture")
		assert_true(str(owner.get(icon, exp_id)) == exp_id, "%s and %s share %s" % [owner.get(icon), exp_id, icon])
		owner[icon] = exp_id
	await _open("middle")
	screen.show_area("safe")
	await wait_process_frames(1)
	var card := _named("Unit_life_safe_fire_escape")
	assert_eq((card.find_child("Picture", false, false) as LifeIcons).icon, LifeScreen.experience_icon("fire_escape"))


## The emulator (2026-10-17): on an area with two rows of cards (Money and business), the stars covered two-line
## titles. On every track, each card's title fits between its picture and its stars or stamps.
func test_every_areas_card_titles_stay_clear_of_their_stars() -> void:
	await _open("middle")
	for t: String in LifeData.TRACKS:
		for a: Dictionary in LifeCatalog.data().areas:
			screen.show_area(str(a.id), t)
			await wait_process_frames(1)
			for node in screen.find_children("Unit_*", "Button", true, false):
				var b := node as Button
				var box := b.get_theme_stylebox("normal")
				var fs := b.get_theme_font_size("font_size")
				var width := b.size.x - box.content_margin_left - box.content_margin_right
				var need := b.get_theme_font("font").get_multiline_string_size(b.text, HORIZONTAL_ALIGNMENT_CENTER,
					width, fs).y
				var room := b.size.y - box.content_margin_top - box.content_margin_bottom
				assert_lte(need, room, "%s %s %s: the title needs %d px, has %d" % [t, a.id, b.text, need, room])
				var badge := b.get_child(b.get_child_count() - 1) as Control
				assert_gte(box.content_margin_bottom, b.size.y - badge.position.y, "%s: the stars under the title" % b.text)


## The emulator (2026-10-17): the before-check's header read "What do you know?: 1 of 4".
func test_the_before_check_header_has_no_stray_colon() -> void:
	await _open("middle")
	screen.start_experience("fire_escape", "middle", false)
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.CHECK)
	assert_string_contains(_labels(), "What do you know? 1 of ")
	assert_false(_labels().contains("?:"))


func test_a_lesson_on_the_little_track_reads_every_card() -> void:
	await _open("little")
	screen.show_lesson("life.safe.call_for_help")
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.LESSON)
	assert_gt(voice.said.size(), 0)
	assert_string_contains(voice.said.back(), "Quick memory")


## Life L2 built every "coming soon" unit; the screen still says it for the next wave's (here a made-up L3 one).
func test_a_coming_soon_unit_says_so() -> void:
	(LifeCatalog.data().units as Array).append({"id": "life.around.find_your_way_little", "area": "around",
		"track": "little", "title": "Find Your Way", "goals": ["learn your address with a grown-up"], "soon": "find_your_way"})
	await _open("little")
	screen.show_unit("life.around.find_your_way_little")
	await wait_process_frames(1)
	assert_string_contains(_labels(), "Coming soon")
	assert_null(_button("PRACTICE"))
	LifeCatalog.clear_cache()


## Answers the current exercise right the first time.
func _answer_right() -> void:
	var p := screen.exercise_panel
	var ex := p.ex
	var w := p.answer_widget
	var a: Variant = ExerciseCheck.answer_of(ex)
	match str(ex.type):
		"choice":
			(w as ChoiceAnswer).choose(int(a))
		"truefalse":
			(w as ChoiceAnswer).choose(0 if a else 1)
		"number":
			var pad := w as NumberAnswerPad
			for ch in str(a):
				pad.press(ch)
		"order":
			for i: int in a:
				(w as OrderAnswer).tap(i)
		"sort":
			for i in (a as Array).size():
				for k in int(a[i]) + 1:   # a tap moves a thing on to the next group, from none
					(w as SortAnswer).tap(i)
		"match":
			for i in (a as Array).size():
				(w as MatchAnswer).tap_left(i)
				(w as MatchAnswer).tap_right(int(a[i]))
	p.check()
	p.next_button.pressed.emit()
	await wait_process_frames(1)


func test_practice_mastered_pays_the_units_gold_once_like_any_lesson() -> void:
	await _open("middle")
	var gold := profile.survivor_gold
	screen.show_round("life.safe.fire_escape")
	await wait_process_frames(1)
	for i in MasteryRules.ROUND_SIZE:
		await _answer_right()
	assert_eq(screen.page, LifeScreen.ROUND_END)
	assert_eq(int(profile.life.unit("life.safe.fire_escape").s), MasteryRules.MASTERED)
	var paid := profile.survivor_gold - gold
	assert_eq(paid, MasteryRules.UNIT_GOLD + MasteryRules.ROUND_SIZE * EarnRules.ANSWER_GOLD)
	screen.show_round("life.safe.fire_escape")
	await wait_process_frames(1)
	for i in MasteryRules.ROUND_SIZE:
		await _answer_right()
	assert_eq(profile.survivor_gold - gold, paid + MasteryRules.ROUND_SIZE * EarnRules.ANSWER_GOLD, "the unit's 100 once")


func test_a_school_lesson_in_life_keeps_the_schools_progress() -> void:
	await _open("little")
	screen.show_round("g3.health_pe.getting_help")
	await wait_process_frames(1)
	for i in MasteryRules.ROUND_SIZE:
		await _answer_right()
	assert_eq(int(profile.school.progress("g3.health_pe.getting_help").r), 1, "one unit, one progress")
	assert_true(profile.life.units.is_empty())


# --- TRY IT: the check, the room, the card, the stamps ---

func _answer_check() -> void:
	while screen.page == LifeScreen.CHECK:
		var q: Dictionary = screen.check_questions[screen.check_index]
		screen.answer_check(int(q.answer))
		await wait_process_frames(1)


func test_try_it_runs_the_before_check_the_first_time_then_the_room() -> void:
	await _open("middle")
	screen.show_unit("life.safe.fire_escape")
	await wait_process_frames(1)
	_button("TRY IT").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.CHECK, "what do you know? first")
	await _answer_check()
	assert_eq(screen.page, LifeScreen.ROOM)
	assert_not_null(screen.host)
	assert_eq(int(profile.life.skill("fire_escape.middle").b), int(profile.life.skill("fire_escape.middle").q))


func test_the_second_try_goes_straight_into_the_room() -> void:
	profile.life.set_skill("fire_escape.middle", {"b": 2, "q": 5})
	await _open("middle")
	screen.start_experience("fire_escape", "middle", false)
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.ROOM)


func _finish_room(stamps: int) -> void:
	var o := {"finished": true, "stamps": stamps, "hints": 0 if stamps & LifeData.SELF else 2, "seconds": 480.0,
		"log": [{"id": "low", "kind": "action", "seconds": 3.0, "hinted": false}] as Array[Dictionary]}
	screen.host.finished.emit(o)
	await wait_process_frames(2)


func test_a_finished_try_shows_the_card_the_after_check_and_the_stamps() -> void:
	profile.life.set_skill("fire_escape.middle", {"b": 1, "q": 5})
	await _open("middle")
	var gold := profile.survivor_gold
	screen.start_experience("fire_escape", "middle", false)
	await wait_process_frames(1)
	await _finish_room(LifeData.DONE | LifeData.SELF)
	assert_eq(screen.page, LifeScreen.DEBRIEF, "an emergency practice: the calm debrief first (owner #118, Life L3a)")
	_button("NEXT").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.CARD, "the name-it card: the authorities' own steps")
	assert_string_contains(_labels(), "Get low")
	assert_string_contains(_labels(), "NFPA")
	_button("NEXT").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.CHECK, "the same check, after")
	await _answer_check()
	assert_eq(screen.page, LifeScreen.RESULT)
	assert_true(profile.life.has_stamp("fire_escape.middle", LifeData.SELF))
	assert_eq(profile.survivor_gold - gold, LifePassport.GOLD, "the Experience's gold, like a lesson")
	assert_string_contains(_labels(), "Try it for real")
	assert_string_contains(_labels(), "1 of 5")
	assert_eq(screen.measure.step("fire_escape.middle", "low").n, 1, "measured on the device")
	assert_true(FileAccess.file_exists(measure_path))


func test_the_gold_is_paid_once_per_skill() -> void:
	profile.life.set_skill("fire_escape.middle", {"b": 1, "q": 5, "r": 1, "s": LifeData.DONE, "g": true})
	await _open("middle")
	var gold := profile.survivor_gold
	screen.start_experience("fire_escape", "middle", false)
	await wait_process_frames(1)
	await _finish_room(LifeData.DONE)
	assert_eq(profile.survivor_gold, gold)


func test_a_new_expert_stamp_is_a_surprise_celebration() -> void:
	profile.life.set_skill("fire_escape.middle", {"b": 1, "q": 5, "s": LifeData.DONE | LifeData.SELF})
	await _open("middle")
	screen.start_experience("fire_escape", "middle", true)
	await wait_process_frames(1)
	await _finish_room(LifeData.DONE | LifeData.SELF | LifeData.EXPERT)
	_button("NEXT").pressed.emit()   # the debrief (owner #118: after an emergency practice)
	await wait_process_frames(1)
	_button("NEXT").pressed.emit()   # the name-it card
	await wait_process_frames(1)
	await _answer_check()
	assert_not_null(_named("ExpertSurprise"))


func test_stop_for_now_comes_back_calmly() -> void:
	profile.life.set_skill("money_stall.little", {"b": 1, "q": 4})
	await _open("little")
	screen.start_experience("money_stall", "little", false)
	await wait_process_frames(1)
	screen.host.stopped.emit({"finished": false, "stamps": 0, "hints": 0, "seconds": 20.0, "log": [] as Array[Dictionary]})
	await wait_process_frames(2)
	assert_eq(screen.page, LifeScreen.CALM)
	assert_string_contains(_labels(), "Well done for practising")
	assert_eq(profile.life.skill("money_stall.little").r, 0, "nothing recorded as done, nothing lost")


# --- The Passport and the grown-ups ---

func test_the_passport_shows_every_skill_and_its_stamps() -> void:
	profile.life.set_skill("little_lifesaver.big", {"s": LifeData.DONE | LifeData.SELF, "r": 1})
	await _open()
	screen.show_passport()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.PASSPORT)
	var shown := screen.find_children("Skill_*", "Button", true, false).size()
	assert_string_contains(_labels(), "Hands-only CPR and choking")
	assert_eq(screen.passport.pages(), ceili(LifeExperience.IDS.size() / float(LifePassportPage.PER_PAGE)),
		"a page per three Experiences: L1's, L2's, then Real Builder's (owner #112, #116)")
	var seen_streets := false
	for i in range(1, screen.passport.pages()):
		screen.passport.show_book(i)
		await wait_process_frames(1)
		shown += screen.find_children("Skill_*", "Button", true, false).size()
		seen_streets = seen_streets or _labels().contains("Stop, look and listen")
	assert_eq(shown, LifePassport.skills().size(), "every skill on one of its pages")
	assert_true(seen_streets, "L2's skills are in the book")


func test_the_grown_ups_page_sets_the_region_the_track_and_the_careful_switches() -> void:
	await _open("little")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.GROWN_UPS)
	var page := screen.grown_ups
	page.show_settings()
	await wait_process_frames(1)
	page.set_region("uk")
	assert_eq(profile.life.region, "uk")
	page.set_track("big")
	assert_eq(profile.life.track, "big")
	page.set_locked(true)
	assert_true(profile.life.track_locked)
	for topic in LifeData.CAREFUL_TOPICS:
		assert_false(profile.life.careful_on(topic), "every careful topic starts off: " + topic)
	page.set_careful("body_safety", true)
	assert_true(profile.life.careful_on("body_safety"))
	assert_gt(saves, 3)


func test_the_grown_ups_page_says_what_the_child_can_now_do() -> void:
	profile.life.set_skill("little_lifesaver.little", {"s": LifeData.DONE | LifeData.SELF, "r": 2, "b": 1, "q": 4,
		"a": 4, "l": 4, "t": DAY, "w": 420})
	profile.life.region = "ge"
	await _open("little")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	var words := _labels()
	assert_string_contains(words, "Your child can now")
	assert_string_contains(words, "call 112")
	assert_string_contains(words, "knew 1 of 4 at the start, now 4 of 4, in 7 minutes")
	assert_string_contains(words, "Try it for real")


func test_every_page_fits_the_frame_and_has_a_speaker() -> void:
	await _open("middle")
	var pages := {
		"track": func() -> void: screen.show_track(),
		"map": func() -> void: screen.show_map(),
		"area safe": func() -> void: screen.show_area("safe"),
		"area money": func() -> void: screen.show_area("money"),
		"unit": func() -> void: screen.show_unit("life.safe.fire_escape"),
		"school unit": func() -> void: screen.show_unit("g4.health_pe.first_aid_basics"),
		"lesson": func() -> void: screen.show_lesson("life.safe.fire_escape"),
		"round": func() -> void: screen.show_round("life.safe.fire_escape"),
		"check": func() -> void: screen.show_check("fire_escape", "middle", false),
		"card": func() -> void: screen.show_card("fire_escape", "middle"),
		"passport": func() -> void: screen.show_passport(),
		"passport page 2": func() -> void:
			screen.show_passport()
			screen.passport.show_book(1),
		"grown-ups": func() -> void: screen.show_grown_ups_page(),
		"grown-ups settings": func() -> void:
			screen.show_grown_ups_page()
			screen.grown_ups.show_settings(),
		"grown-ups safety": func() -> void:   # Life L3a (owner #118)
			screen.show_grown_ups_page()
			screen.grown_ups.show_safety(),
		"debrief": func() -> void: screen.show_debrief("water_safety", "middle"),
		"area safe big": func() -> void: screen.show_area("safe", "big"),
		"unit water": func() -> void: screen.show_unit("life.safe.spot_trouble_and_rips"),
		"calm": func() -> void: screen.show_calm(),
	}
	for name: String in pages:
		(pages[name] as Callable).call()
		await wait_process_frames(2)
		var size := screen.get_combined_minimum_size()
		assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [name, size])
		assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [name, size])
		assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % name)
