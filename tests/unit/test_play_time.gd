extends GutTest
## Today's play time for the grown-up area (M4 Wave 2, agent F; spec §5.14 parent corner, §17.2 "see
## play time"): seconds per local day, kept on this device only (user://play_time.json, never the
## profile or the server), a few days back, and in plain words for a grown-up.

var DIR := "user://test_play_time_%d/" % OS.get_process_id()


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func test_time_adds_up_per_day() -> void:
	var t := PlayTime.new()
	assert_eq(t.minutes_on("2026-09-24"), 0)
	for i in 150:
		t.add(1.0, "2026-09-24")
	assert_eq(t.seconds_on("2026-09-24"), 150)
	assert_eq(t.minutes_on("2026-09-24"), 2, "whole minutes")
	for i in 6:
		t.add(5.0, "2026-09-25")
	assert_eq(t.seconds_on("2026-09-25"), 30, "a new day starts at 0")
	assert_eq(t.seconds_on("2026-09-24"), 150)


func test_one_step_never_counts_a_long_sleep() -> void:
	var t := PlayTime.new()
	t.add(3600.0, "2026-09-24")   # the phone slept with the game in the background
	t.add(-5.0, "2026-09-24")
	t.add(NAN, "2026-09-24")
	assert_eq(t.seconds_on("2026-09-24"), int(PlayTime.MAX_STEP))


func test_only_the_last_days_are_kept() -> void:
	var t := PlayTime.new()
	for d in range(1, 13):
		t.add(2.0, "2026-09-%02d" % d)
	assert_eq(t.days.size(), PlayTime.KEEP_DAYS)
	assert_true(t.days.has("2026-09-12"))
	assert_false(t.days.has("2026-09-01"))


func test_saved_and_read_back_safely() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR + "play_time.json"
	var t := PlayTime.new()
	t.add(5.0, "2026-09-24")
	assert_eq(t.save_to(path), OK)
	assert_eq(PlayTime.load_from(path).seconds_on("2026-09-24"), 5)
	assert_eq(PlayTime.load_from(DIR + "missing.json").days, {})
	for bad in ["", "nope", "[]", '{"days": 5}', '{"days": {"2026-09-24": "lots", "yesterday": 5, "2026-09-23": -3}}']:
		assert_eq(PlayTime.from_json(bad).days, {}, "bad file: %s" % bad)


func test_plain_words_for_a_grown_up() -> void:
	assert_eq(PlayTime.words(0), "Less than a minute")
	assert_eq(PlayTime.words(1), "1 minute")
	assert_eq(PlayTime.words(42), "42 minutes")
	assert_eq(PlayTime.words(60), "1 hour")
	assert_eq(PlayTime.words(125), "2 hours 5 minutes")


func test_today_is_the_local_date() -> void:
	assert_true(PlayTime.today().length() == 10 and PlayTime.today()[4] == "-", PlayTime.today())
