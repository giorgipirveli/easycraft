extends GutTest
## M3 Task 10: the opt-in "Your farm is full!" note (spec §5.6, §6): off by default, only when the
## player (a grown-up for an under-13 child) turned it on, at the time the barn is full but never
## 20:00-08:00 (it waits for the morning), at most once a day, and no guilt in its words. The
## notifier itself is an interface: a no-op on the desktop and in tests (the Android plugin is M5's).

const DAY := 86400
const H := 3600
const MIDNIGHT := 1_800_057_600   # a UTC midnight (unix seconds; 1_800_057_600 % 86400 == 0)


func test_the_note_is_off_by_default() -> void:
	assert_false(FarmNotifyRules.wanted(ProfileData.new().settings))
	assert_true(FarmNotifyRules.wanted({"farm_note": true}))
	assert_false(FarmNotifyRules.wanted({"farm_note": "yes"}), "only a real switch")


func test_it_rings_when_the_barn_is_full_in_the_daytime() -> void:
	var full := MIDNIGHT + 15 * H
	assert_eq(FarmNotifyRules.fire_at(full, 0, -1), full)


func test_never_at_night_it_waits_for_eight_in_the_morning() -> void:
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 21 * H, 0, -1), MIDNIGHT + DAY + 8 * H, "late evening: next morning")
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 20 * H, 0, -1), MIDNIGHT + DAY + 8 * H, "20:00 is night")
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 3 * H, 0, -1), MIDNIGHT + 8 * H, "after midnight: that morning")
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 8 * H, 0, -1), MIDNIGHT + 8 * H, "08:00 is day")


func test_night_is_the_phones_own_night() -> void:
	var tbilisi := 4 * 60   # UTC+4, minutes
	# 17:00 UTC is 21:00 in Tbilisi: night there, so 08:00 Tbilisi next day (04:00 UTC).
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 17 * H, tbilisi, -1), MIDNIGHT + DAY + 4 * H)
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 10 * H, tbilisi, -1), MIDNIGHT + 10 * H, "14:00 there")


func test_at_most_once_a_day() -> void:
	var today := FarmNotifyRules.local_day(MIDNIGHT + 9 * H, 0)
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 15 * H, 0, today), MIDNIGHT + DAY + 8 * H, "one rang today: tomorrow")
	assert_eq(FarmNotifyRules.fire_at(MIDNIGHT + 15 * H, 0, today - 1), MIDNIGHT + 15 * H)


func test_which_day_last_rang() -> void:
	var now := MIDNIGHT + 12 * H
	assert_eq(FarmNotifyRules.last_rang_day(0, now, 0), -1, "never")
	assert_eq(FarmNotifyRules.last_rang_day(MIDNIGHT + 9 * H, now, 0), FarmNotifyRules.local_day(now, 0), "this morning")
	assert_eq(FarmNotifyRules.last_rang_day(MIDNIGHT + 14 * H, now, 0), -1, "still waiting: it has not rung")


func test_the_words_are_kind() -> void:
	assert_eq(FarmNotifyRules.TITLE, "Your farm is full!")
	for bad in ["hurry", "miss you", "don't go", "last chance", "come back"]:
		assert_false((FarmNotifyRules.TITLE + " " + FarmNotifyRules.TEXT).to_lower().contains(bad), bad)


func test_the_desktop_notifier_does_nothing_and_says_so() -> void:
	var n := FarmNotifier.for_platform()
	assert_false(n.is_available(), "no plugin on the desktop")
	n.schedule(MIDNIGHT + 15 * H, FarmNotifyRules.TITLE, FarmNotifyRules.TEXT)
	assert_eq(n.scheduled_at, MIDNIGHT + 15 * H, "remembers what it was asked (tests read it)")
	n.cancel()
	assert_eq(n.scheduled_at, 0)


func test_the_android_notifier_uses_the_plugin_only_when_it_has_one() -> void:
	var none := AndroidFarmNotifier.new(null)
	assert_false(none.is_available())
	none.schedule(MIDNIGHT, "a", "b")   # no crash without a plugin
	var fake := _FakePlugin.new()
	var n := AndroidFarmNotifier.new(fake)
	assert_true(n.is_available())
	n.schedule(MIDNIGHT + 9 * H, FarmNotifyRules.TITLE, FarmNotifyRules.TEXT)
	assert_eq(fake.calls, [["schedule", AndroidFarmNotifier.NOTE_ID, MIDNIGHT + 9 * H, FarmNotifyRules.TITLE,
		FarmNotifyRules.TEXT]])
	n.cancel()
	assert_eq(fake.calls[1], ["cancel", AndroidFarmNotifier.NOTE_ID])


class _FakePlugin:
	extends RefCounted
	var calls: Array = []

	func scheduleNote(id: int, at_unix: int, title: String, text: String) -> void:
		calls.append(["schedule", id, at_unix, title, text])

	func cancelNote(id: int) -> void:
		calls.append(["cancel", id])
