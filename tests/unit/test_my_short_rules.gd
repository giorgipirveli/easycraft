extends GutTest
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the maker's rules. A child's own Short is a small recipe kept in
## the profile on this device; its typed words go through the game's word filter for children (ChatRules.filter_code)
## and a names rule (no real child's name); the quick phrases need no typing; English letters only; no rewards.


func test_ids_are_mine_and_never_a_hand_made_one() -> void:
	assert_eq(MyShortRules.id_for(3), "mine:3")
	assert_true(MyShortRules.is_mine_id("mine:3"))
	assert_true(MyShortRules.is_mine_id("mine:120"))
	for bad: String in ["mine:", "mine:x", "rocket_parts", "lesson:g4.science.circuits", "mine:3:4", "Mine:3", "mine:-1"]:
		assert_false(MyShortRules.is_mine_id(bad), bad)
	assert_true(ShortsData.valid_id(MyShortRules.id_for(20)), "hearts and seen marks take it")


func test_the_three_templates_teach_or_show() -> void:
	assert_eq(MyShortRules.TEMPLATES, [MyShortRules.BUILT, MyShortRules.FACTS, MyShortRules.STEPS] as Array[String])
	for t: String in MyShortRules.TEMPLATES:
		var w: Dictionary = MyShortRules.TEMPLATE_WORDS[t]
		assert_true(str(w.title) != "" and str(w.line) != "", t)


func test_a_quick_phrase_passes_the_words_check() -> void:
	var all: Array[String] = []
	for list: Array in [MyShortRules.TITLES[MyShortRules.BUILT], MyShortRules.PHOTO_PHRASES, MyShortRules.STEP_PHRASES]:
		for p: String in list:
			all.append(p)
	for t: String in MyShortRules.TEMPLATES:
		for p: String in MyShortRules.ENDINGS[t]:
			all.append(p)
	for f: String in MyShortRules.STEP_TITLES:
		all.append(f % "a house")
	assert_gt(all.size(), 30)
	for p in all:
		var r := MyShortRules.check_words(p, MyShortRules.MAX_CAPTION)
		assert_eq(r.get("text", ""), p, "%s: %s" % [p, r])


func test_every_ending_asks_a_question() -> void:
	for t: String in MyShortRules.TEMPLATES:
		assert_gte((MyShortRules.ENDINGS[t] as Array).size(), 3, t)
		for p: String in MyShortRules.ENDINGS[t]:
			assert_true(p.ends_with("?"), p)


func test_typed_words_go_through_the_game_s_filter() -> void:
	assert_eq(MyShortRules.check_words("  I built  a big castle! ", 80), {"text": "I built a big castle!"})
	assert_eq(MyShortRules.check_words("", 80).get("error"), "empty")
	assert_eq(MyShortRules.check_words("    ", 80).get("error"), "empty")
	assert_eq(MyShortRules.check_words("x".repeat(81), 80).get("error"), "too_long")
	assert_eq(MyShortRules.check_words("this is shit", 80).get("error"), "blocked_word")
	assert_eq(MyShortRules.check_words("call me 555 123 4567", 80).get("error"), "personal_info")
	assert_eq(MyShortRules.check_words("visit www.example.com", 80).get("error"), "personal_info")
	assert_eq(MyShortRules.check_words("my email is a@b.co", 80).get("error"), "personal_info")
	assert_eq(MyShortRules.check_words("I go to my school", 80).get("error"), "personal_info")


func test_english_letters_only() -> void:
	assert_eq(MyShortRules.check_words("Привет мир", 80).get("error"), "letters")
	assert_eq(MyShortRules.check_words("გამარჯობა", 80).get("error"), "letters")
	assert_eq(MyShortRules.check_words("Hi <b>bold</b>", 80).get("error"), "letters")
	assert_eq(MyShortRules.check_words("It's 3 blocks high, isn't it?", 80).get("text"), "It's 3 blocks high, isn't it?")


func test_no_names_of_real_children() -> void:
	assert_eq(MyShortRules.check_words("My name is Sam", 80).get("error"), "name")
	assert_eq(MyShortRules.check_words("I am called Sam", 80).get("error"), "name")
	assert_eq(MyShortRules.check_words("I'm called Sam", 80).get("error"), "name")
	assert_eq(MyShortRules.check_words("Made by BlueFox42", 80, ["BlueFox42"]).get("error"), "name", "the child's username")
	assert_eq(MyShortRules.check_words("built with bluefox42!", 80, ["BlueFox42"]).get("error"), "name", "any case")
	assert_eq(MyShortRules.check_words("A blue fox", 80, ["BlueFox42"]).get("text"), "A blue fox", "not a name")
	assert_eq(MyShortRules.check_words("Thanks Max", 80, ["", "Al", "MaxRocket"]).get("text"), "Thanks Max",
		"short or other names don't match inside words")


func test_every_refusal_has_kind_words() -> void:
	for code: String in ["empty", "too_long", "letters", "personal_info", "blocked_word", "name"]:
		var w := MyShortRules.message(code)
		assert_ne(w, "", code)
		assert_false(w.to_lower().contains("bad"), "never scolds: " + w)


func test_backdrops_and_music_are_the_game_s_own() -> void:
	for b: String in MyShortRules.BACKDROPS:
		assert_true(ShortRules.BACKGROUNDS.has(b), b)
	assert_eq(MyShortRules.MUSIC[0], "", "the first choice is no music")
	for m: String in MyShortRules.MUSIC:
		if m != "":
			assert_true(MusicPieces.has(StringName(m)), m)
			assert_false(MusicPieces.is_own(StringName(m)), "a piece every world plays")
	for k: String in MyShortRules.BLUEPRINTS:
		assert_false(Blueprints.local(int(MyShortRules.BLUEPRINTS[k])).is_empty(), k)
		assert_ne(MyShortRules.blueprint_name(k), "", k)


func _built() -> Dictionary:
	return {"template": "built", "title": "How I built my castle", "photos": ["p_1.jpg", "p_2.jpg", "p_3.jpg"],
		"captions": ["First, I picked my blocks.", "Then I built the walls.", "Here it is, all done!"],
		"ending": "What will you build next?", "backdrop": "sky", "music": "spring", "voice": true}


func test_a_recipe_is_cleaned() -> void:
	var r := MyShortRules.clean_recipe(_built())
	assert_eq(r.template, "built")
	assert_eq(r.photos, ["p_1.jpg", "p_2.jpg", "p_3.jpg"])
	assert_eq(r.captions.size(), 3)
	assert_eq(r.backdrop, "sky")
	assert_eq(r.music, "spring")
	assert_true(r.voice)


func test_a_broken_recipe_is_left_out_or_mended() -> void:
	assert_eq(MyShortRules.clean_recipe({}), {})
	assert_eq(MyShortRules.clean_recipe({"template": "video"}), {})
	assert_eq(MyShortRules.clean_recipe("text"), {})
	var one_photo := _built()
	one_photo.photos = ["p_1.jpg"]
	assert_eq(MyShortRules.clean_recipe(one_photo), {}, "How I built it needs 2-4 photos")
	var paths := _built()
	paths.photos = ["../profile.json", "p_2.jpg", "p_3.jpg"]
	assert_eq(MyShortRules.clean_recipe(paths), {}, "a photo is a plain file name in the album, never a path")
	var odd := _built()
	odd.backdrop = "lava"
	odd.music = "a_song_from_the_internet"
	odd.voice = "loud"
	odd.ending = "Bye!"
	odd.title = "My name is Sam"
	odd.captions = ["shit", 7]
	var r := MyShortRules.clean_recipe(odd)
	assert_eq(r.backdrop, MyShortRules.BACKDROPS[0])
	assert_eq(r.music, "")
	assert_true(r.voice)
	assert_eq(r.ending, MyShortRules.ENDINGS["built"][0], "an ending is one of the questions")
	assert_eq(r.title, "", "words that fail the check are dropped (the maker says its own)")
	assert_eq(r.captions, ["", ""])


func test_a_facts_recipe_names_a_real_subject() -> void:
	var r := MyShortRules.clean_recipe({"template": "facts", "subject": {"kind": "planet", "id": "mars"}, "facts": [0, 1, 2]})
	assert_eq(r.subject, {"kind": "planet", "id": "mars"})
	assert_eq(r.facts, [0, 1, 2])
	assert_eq(MyShortRules.clean_recipe({"template": "facts", "subject": {"kind": "planet", "id": "vulcan"}}), {})
	var few := MyShortRules.clean_recipe({"template": "facts", "subject": {"kind": "wonder", "id": "pyramid"}, "facts": [1, 1, 99]})
	assert_eq(few.facts.size(), MyShortRules.FACT_COUNT, "always three different facts")
	assert_eq(few.facts[0], 1)


func test_a_steps_recipe_names_a_build() -> void:
	var r := MyShortRules.clean_recipe({"template": "steps", "build": {"kind": "blueprint", "id": "house"}})
	assert_eq(r.build.id, "house")
	assert_eq(MyShortRules.clean_recipe({"template": "steps", "build": {"kind": "blueprint", "id": "rocket"}}), {})
	var stamp := MyShortRules.clean_recipe({"template": "steps", "build": {"kind": "stamp", "file": "b_4.txt", "layers": 6}})
	assert_eq(stamp.build, {"kind": "stamp", "file": "b_4.txt", "layers": 6})
	assert_eq(MyShortRules.clean_recipe({"template": "steps", "build": {"kind": "stamp", "file": "b_4.txt", "layers": 1}}), {},
		"one layer is not steps")
