extends GutTest
## Owner #112 (docs/design/life-skills.md §3, §7, §11): Life's part of the profile (ProfileData.life): the child's track,
## a grown-up's lock, the region, the careful topics' switches (all off), each Life unit's progress (the School's short
## keys) and each skill's Passport stamps, runs, before-and-after numbers and spaced repeats. Parsed field by field (a bad
## field falls back on its own), limited in size (the server backup's limits), merged without losing a stamp.

const DAY := 20_000


func test_a_new_profile_has_no_life_progress_and_every_careful_topic_off() -> void:
	var d := LifeData.new()
	assert_true(d.is_empty())
	assert_eq(d.track, "")
	assert_eq(d.region, "")
	for topic: String in LifeData.CAREFUL_TOPICS:
		assert_false(d.careful_on(topic), topic)


func test_the_three_tracks() -> void:
	assert_eq(LifeData.TRACKS, ["little", "middle", "big"] as Array[String])
	assert_true(LifeData.valid_track("middle"))
	assert_false(LifeData.valid_track("huge"))


func test_it_round_trips_through_a_dictionary() -> void:
	var d := LifeData.new()
	d.track = "big"
	d.track_locked = true
	d.region = "uk"
	d.set_careful("body_safety", true)
	d.set_unit("life.safe.call_for_help", {"l": true, "s": 2, "r": 1, "p": true})
	d.set_skill("little_lifesaver.little", {"s": LifeData.DONE | LifeData.SELF, "r": 2, "b": 1, "q": 5, "a": 5, "l": 4,
		"t": DAY, "w": 540})
	var e := LifeData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(e.track, "big")
	assert_true(e.track_locked)
	assert_eq(e.region, "uk")
	assert_true(e.careful_on("body_safety"))
	assert_eq(int(e.unit("life.safe.call_for_help").s), 2)
	assert_true(bool(e.unit("life.safe.call_for_help").p))
	var k := e.skill("little_lifesaver.little")
	assert_eq(int(k.s), LifeData.DONE | LifeData.SELF)
	assert_eq(int(k.b), 1)
	assert_eq(int(k.a), 5)
	assert_eq(int(k.w), 540)


func test_bad_fields_fall_back_on_their_own() -> void:
	var e := LifeData.from_dict({"track": "giant", "locked": "yes", "region": 7, "careful": {"nope": true, "puberty": 1},
		"units": {"g4.maths.x": {"s": 3}, "life.safe.ok": {"s": 9, "r": -4}, "LIFE.bad": {}},
		"skills": {"fire_escape.huge": {"s": 1}, "fire_escape.big": {"s": 99, "r": "lots", "b": 50}}})
	assert_eq(e.track, "")
	assert_false(e.track_locked)
	assert_eq(e.region, "")
	assert_false(e.careful_on("puberty"), "only true turns a topic on")
	assert_false(e.careful.has("nope"), "unknown topics are dropped")
	assert_false(e.units.has("g4.maths.x"), "School ids live in the School's progress")
	assert_eq(int(e.unit("life.safe.ok").s), 3, "stars at most 3")
	assert_eq(int(e.unit("life.safe.ok").r), 0)
	assert_false(e.skills.has("fire_escape.huge"))
	assert_eq(int(e.skill("fire_escape.big").s), LifeData.DONE | LifeData.SELF | LifeData.EXPERT, "only the three stamps")
	assert_eq(int(e.skill("fire_escape.big").r), 0)
	assert_eq(int(e.skill("fire_escape.big").b), LifeData.MAX_QUESTIONS)


func test_only_known_regions_are_kept() -> void:
	var d := LifeData.from_dict({"region": "jp"})
	assert_eq(d.region, "jp")
	assert_eq(LifeData.from_dict({"region": "mars"}).region, "")


func test_ids() -> void:
	assert_true(LifeData.valid_unit_id("life.safe.call_for_help"))
	assert_false(LifeData.valid_unit_id("g3.health_pe.getting_help"))
	assert_false(LifeData.valid_unit_id("life.safe"))
	assert_true(LifeData.valid_skill_id("money_stall.middle"))
	assert_false(LifeData.valid_skill_id("money_stall.tiny"))
	assert_false(LifeData.valid_skill_id("Money.big"))


func test_a_skills_defaults_say_never_checked() -> void:
	var k := LifeData.new().skill("fire_escape.little")
	assert_eq(int(k.s), 0)
	assert_eq(int(k.b), -1, "no before-check yet")
	assert_eq(int(k.a), -1, "no after-check yet")


func test_the_stamps() -> void:
	var d := LifeData.new()
	assert_false(d.has_stamp("fire_escape.big", LifeData.DONE))
	d.set_skill("fire_escape.big", {"s": LifeData.DONE | LifeData.EXPERT})
	assert_true(d.has_stamp("fire_escape.big", LifeData.DONE))
	assert_false(d.has_stamp("fire_escape.big", LifeData.SELF))
	assert_true(d.has_stamp("fire_escape.big", LifeData.EXPERT))


func test_the_size_is_limited_for_the_backup() -> void:
	var d := LifeData.new()
	for i in LifeData.MAX_UNITS + 5:
		d.set_unit("life.safe.u%d" % i, {"s": 1})
	assert_eq(d.units.size(), LifeData.MAX_UNITS)
	for i in LifeData.MAX_SKILLS + 5:
		d.set_skill("s%s.little" % "abcdefghijklmnopqrstuvwxyz".substr(i % 26, 1).repeat(1 + i / 26), {"r": 1})
	assert_lte(d.skills.size(), LifeData.MAX_SKILLS)


func test_merge_never_loses_a_stamp_a_star_or_a_paid_reward() -> void:
	var a := LifeData.new()
	a.set_unit("life.safe.call_for_help", {"s": 1, "r": 3})
	a.set_skill("fire_escape.little", {"s": LifeData.DONE, "r": 1, "b": 2, "q": 5, "a": 3, "l": 3, "t": DAY, "w": 600})
	var b := LifeData.new()
	b.track = "middle"
	b.region = "uk"
	b.set_unit("life.safe.call_for_help", {"s": 2, "r": 1, "p": true})
	b.set_skill("fire_escape.little", {"s": LifeData.SELF, "r": 4, "b": 1, "q": 5, "a": 5, "l": 4, "t": DAY + 3, "g": true,
		"x": 2, "d": DAY + 10})
	a.merge_from(b)
	assert_eq(a.track, "middle", "a copy with no track takes the other's")
	assert_eq(a.region, "uk")
	var u := a.unit("life.safe.call_for_help")
	assert_eq(int(u.s), 2)
	assert_eq(int(u.r), 3)
	assert_true(bool(u.p))
	var k := a.skill("fire_escape.little")
	assert_eq(int(k.s), LifeData.DONE | LifeData.SELF)
	assert_eq(int(k.r), 4)
	assert_eq(int(k.b), 1, "the first before-check: the lower one")
	assert_eq(int(k.a), 5, "the best after-check")
	assert_eq(int(k.l), 4, "the latest after-check: from the copy that played last")
	assert_eq(int(k.t), DAY + 3)
	assert_true(bool(k.g))
	assert_eq(int(k.x), 2)
	assert_eq(int(k.d), DAY + 10)
	assert_eq(int(k.w), 600, "the first run's time stays")


func test_a_grown_ups_lock_survives_a_merge() -> void:
	var a := LifeData.new()
	var b := LifeData.new()
	b.track_locked = true
	a.merge_from(b)
	assert_true(a.track_locked)


## ProfileBackup.merge merges into the newer copy: its careful topics' switches are the grown-up's latest choice and
## stay as they are (an older copy never turns one on or off).
func test_the_careful_switches_stay_the_newer_copys() -> void:
	var newer := LifeData.new()
	var older := LifeData.new()
	older.set_careful("body_safety", true)
	newer.merge_from(older)
	assert_false(newer.careful_on("body_safety"))
	var on := LifeData.new()
	on.set_careful("body_safety", true)
	on.merge_from(LifeData.new())
	assert_true(on.careful_on("body_safety"))
