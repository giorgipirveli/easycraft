extends GutTest
## Owner #81, #82 (brief 2026-09-30 item 2): postcards at proud moments, offered once. In the School, a unit mastered (or
## a grade's whole subject) offers MAKE A POSTCARD on the round's end, once; its postcard is a drawn picture, the words
## ("I mastered Big numbers!"), the invite code and link, with SAVE PICTURE, SHARE, COPY and CLOSE, and the grown-ups'
## line. The moment goes to friends to cheer. In a world, PostcardOffer's small card asks once ("What a moment! Make a
## postcard?"); POSTCARD takes the world's picture and shows the postcard over the game; NO THANKS goes away. Every page
## fits the frame.

const UNIT := "g4.maths.big_numbers"
const CONTENT := {"id": UNIT, "lesson": [{"text": "A digit's place tells what it is worth."}, {"text": "Ten times."}],
	"exercises": [{"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens.", "level": 1},
		{"type": "truefalse", "prompt": "In 347, the 3 is worth 30.", "answer": false, "hint": "Hundreds.", "level": 2},
		{"type": "truefalse", "prompt": "In 520, the 2 is worth 20.", "answer": true, "hint": "Tens.", "level": 3}]}

var profile: ProfileData
var screen: SchoolScreen
var copied: Array[String] = []
var captured := 0


func before_each() -> void:
	Curriculum.clear_cache()
	Curriculum.put_content(UNIT, CONTENT)
	profile = ProfileData.new()
	profile.school.grade = 4
	profile.invite.code = "BLUE-OTTER-42"
	copied.clear()
	captured = 0


func after_each() -> void:
	Curriculum.clear_cache()


func after_all() -> void:
	Audio.stop_all()


func _school() -> SchoolScreen:
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	screen.today = func() -> int: return 20_000
	screen.daily_today = func() -> int: return 20_726
	screen.next_seed = func() -> int: return 7
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(root: Node, text_or_name: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if ((b as Button).text == text_or_name or b.name == text_or_name) and (b as Button).is_visible_in_tree():
			return b
	return null


func _labels(root: Node) -> Array[String]:
	var out: Array[String] = []
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return out


func _master_the_unit() -> void:
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in screen.round.size():
		screen.exercise_panel.answered.emit(true)
		await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.ROUND_END)


func test_a_unit_mastered_offers_a_postcard_once_and_tells_friends() -> void:
	await _school()
	await _master_the_unit()
	var make := _button(screen, "MakePostcard")
	assert_not_null(make, "MAKE A POSTCARD on the round's end")
	assert_false(PostcardRules.due(profile, PostcardRules.unit(UNIT, "Big numbers")), "offered: never again")
	assert_eq(profile.social.moments.size(), 1, "friends will hear it")
	assert_eq(str(profile.social.moments[0].kind), "unit")
	assert_eq(profile.social.units, [UNIT] as Array[String], "the crew's week hears the unit")
	make.pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.POSTCARD)
	var labels := _labels(screen)
	assert_has(labels, "I mastered Big numbers!")
	assert_has(labels, PostcardRules.GROWN_UPS_LINE)
	assert_true(" ".join(labels).contains("BLUE-OTTER-42"), "the invite code on the postcard")
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "the postcard page is %s" % size)
	assert_lte(size.y, SchoolUi.FRAME.y, "the postcard page is %s" % size)
	screen.postcard.copy_text = func(t: String) -> void: copied.append(t)
	_button(screen, "Copy").pressed.emit()
	assert_eq(copied, [PostcardRules.share_text("I mastered Big numbers!", "BLUE-OTTER-42")] as Array[String])
	_button(screen, "Close").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.UNIT, "back to the unit")
	# Mastered again later: no second offer.
	await _master_the_unit()
	assert_null(_button(screen, "MakePostcard"))


func test_the_last_unit_of_a_subject_is_the_grades_moment() -> void:
	Curriculum.put_grade(4, {"grade": 4, "ages": "9-10", "subjects": [
		{"id": "maths", "title": "Maths", "units": [{"id": UNIT, "title": "Big numbers", "standards": ["4.NBT.1"],
			"goals": ["Read big numbers"], "file": "g4/maths/big_numbers.json"}]},
		{"id": "science", "title": "Science", "units": []}, {"id": "english", "title": "English", "units": []}]})
	Curriculum.put_content(UNIT, CONTENT)
	await _school()
	await _master_the_unit()
	assert_eq(screen.moment, PostcardRules.grade(4, "maths"))
	_button(screen, "MakePostcard").pressed.emit()
	await wait_process_frames(2)
	assert_has(_labels(screen), "I mastered grade 4 maths!")


func test_a_world_moment_offers_its_postcard_once_and_goes_away_kindly() -> void:
	var layer := Control.new()
	layer.size = Vector2(1280, 720)
	add_child_autofree(layer)
	var m := PostcardRules.landed("moon")
	var offer := PostcardOffer.offer(layer, m, profile)
	assert_not_null(offer)
	assert_null(PostcardOffer.offer(layer, m, profile), "once per moment")
	await wait_process_frames(2)
	assert_has(_labels(offer), "I landed on the Moon!")
	assert_has(_labels(offer), PostcardRules.OFFER_WORDS)
	assert_eq(profile.social.moments.size(), 1, "friends hear it")
	_button(offer, "NoThanks").pressed.emit()
	await wait_process_frames(2)
	assert_false(is_instance_valid(offer), "NO THANKS: gone, never asked again")
	var mars := PostcardOffer.offer(layer, PostcardRules.landed("mars"), profile)
	mars.capture = func() -> Image:
		captured += 1
		return Image.create_empty(320, 180, false, Image.FORMAT_RGB8)
	await wait_process_frames(1)
	_button(mars, "MakePostcard").pressed.emit()
	await wait_process_frames(3)
	assert_eq(captured, 1, "the world's picture")
	assert_not_null(mars.page)
	assert_not_null(mars.page.photo, "the postcard shows the photo")
	assert_has(_labels(mars), "I landed on Mars!")
	var size := mars.page.get_combined_minimum_size()
	assert_lte(size.y, SchoolUi.FRAME.y + 40.0, "the postcard fits over the game: %s" % size)
	_button(mars, "Close").pressed.emit()
	await wait_process_frames(2)
	assert_false(is_instance_valid(mars))


func test_postcard_words_are_calm_and_carry_only_the_invite() -> void:
	var p := PostcardPage.new(PostcardRules.deposit("gold"))
	p.profile = profile
	add_child_autofree(p)
	await wait_process_frames(2)
	assert_eq(p.share_text(), PostcardRules.share_text("I found gold!", "BLUE-OTTER-42"))
	for w in _labels(p):
		for bad in ["hurry", "lose", "must", "or else", "last chance"]:
			assert_false(w.to_lower().contains(bad), "calm: %s" % w)
