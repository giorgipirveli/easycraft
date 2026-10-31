extends GutTest
## Owner #81, #82 (brief 2026-09-30 item 2; the world game plan §1 "Pride and showing"): postcards at proud moments. A
## first landing on a planet, a mission complete, a unit or a grade mastered, a wonder's stamp, a deposit found: a
## picture postcard with the words ("I landed on the Moon!") and the invite link, offered once at the moment (the
## profile remembers: never nagging), shared by grown-ups.

const PRESSURE: Array[String] = ["hurry", "or else", "last chance", "lose", "only today", "don't miss", "must", "streak"]

var profile: ProfileData


func before_each() -> void:
	profile = ProfileData.new()


func after_all() -> void:
	Curriculum.clear_cache()


func test_each_proud_moment_has_its_words_and_its_own_key() -> void:
	var landed := PostcardRules.landed("moon")
	assert_eq(landed, {"kind": "landed", "place": "moon", "key": "landed:moon", "words": "I landed on the Moon!"})
	assert_eq(PostcardRules.landed("mars").words, "I landed on Mars!")
	assert_eq(PostcardRules.mission("moon").words, "Mission complete: the Moon!")
	assert_eq(PostcardRules.unit("g4.maths.equal_fractions", "Equal fractions").words, "I mastered Equal fractions!")
	assert_eq(PostcardRules.unit("g4.maths.equal_fractions", "Equal fractions").key, "unit:g4.maths.equal_fractions")
	assert_eq(PostcardRules.grade(4, "maths"), {"kind": "grade", "place": "g4.maths", "key": "grade:g4.maths",
		"words": "I mastered grade 4 maths!"})
	assert_eq(PostcardRules.grade(5, "health_pe").words, "I mastered grade 5 health & PE!")
	assert_eq(PostcardRules.stamp("great_pyramid", "the Great Pyramid").words, "I visited the Great Pyramid!")
	assert_eq(PostcardRules.deposit("gold").words, "I found gold!")
	for m: Dictionary in [landed, PostcardRules.deposit("oil"), PostcardRules.grade(3, "art")]:
		assert_true(PostcardRules.KINDS.has(m.kind))
		assert_true(PostcardRules.PLACE_RE.search(m.place) != null, "a place is an id the server takes: %s" % m.place)


func test_a_postcard_is_offered_once_never_again() -> void:
	var m := PostcardRules.landed("moon")
	assert_true(PostcardRules.due(profile, m))
	assert_true(PostcardRules.note_offered(profile, m))
	assert_false(PostcardRules.due(profile, m), "offered once")
	assert_false(PostcardRules.note_offered(profile, m))
	assert_true(PostcardRules.due(profile, PostcardRules.landed("mars")), "another moment is its own")
	var back := ProfileData.from_json(profile.to_json())
	assert_false(PostcardRules.due(back, m), "remembered across a save")
	var other := ProfileData.new()
	other.social.merge_from(back.social)
	assert_false(PostcardRules.due(other, m), "and across the account's devices")


func test_the_share_text_carries_the_words_and_the_invite_only() -> void:
	var t := PostcardRules.share_text("I landed on the Moon!", "BLUE-OTTER-42")
	assert_string_contains(t, "I landed on the Moon!")
	assert_string_contains(t, InviteRules.link("BLUE-OTTER-42"))
	assert_string_contains(PostcardRules.share_text("I found gold!", ""), InviteRules.PLAY_URL)


func test_place_names_read_well() -> void:
	assert_eq(PostcardRules.place_name("landed", "moon"), "the Moon")
	assert_eq(PostcardRules.place_name("landed", "europa"), "Europa")
	assert_eq(PostcardRules.place_name("deposit", "natural_gas"), "natural gas")
	assert_eq(PostcardRules.place_name("grade", "g6.english"), "grade 6 English")
	assert_eq(PostcardRules.place_name("unit", "g4.science.no_such_unit"), "a new unit", "an unknown unit says so kindly")


func test_the_words_are_proud_and_calm() -> void:
	for w: String in [PostcardRules.OFFER_WORDS, PostcardRules.GROWN_UPS_LINE, PostcardRules.SAVED_WORDS]:
		for p in PRESSURE:
			assert_false(w.to_lower().contains(p), "no pressure (%s): %s" % [p, w])


## The lead's wiring (owner #85, the flight merged): landing on a planet offers its postcard once, a mission's own
## ("Mission complete: the Moon!") or a plain landing's ("I landed on Mercury!").
func test_a_landing_offers_its_postcard() -> void:
	var m := PostcardRules.for_landing(SpaceRules.MOON, true)
	assert_eq(m.kind, "mission")
	assert_eq(m.place, "moon")
	var l := PostcardRules.for_landing(SpaceRules.MERCURY, false)
	assert_eq(l.kind, "landed")
	assert_string_contains(str(l.words), "Mercury")
	assert_eq(PostcardRules.for_landing(1, false), {}, "home is no landing")
