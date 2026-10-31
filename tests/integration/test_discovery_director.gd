extends GutTest
## Owner #132 (W1), stage 1: DISCOVER inside the world and Professor Hoot's invitation. MORE's DISCOVER (a picture: a
## magnifying glass, its word spoken when pointed at) opens the School over the world (DiscoverPanel, as Life Town opens
## Life) and BACK gives the world back; while it shows the avatar is held and kept safe. The first time in a home world
## (and a world seen before at most once a day) Hoot comes after the child has stood in it a while: his line spoken by
## itself (owner #133: no child has to read), on screen Hoot, one big DISCOVER picture and a few words; it never blocks
## play, waits quietly and fades. In a headset his line goes on the toast strip.

class RecordingVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


const DAY := 20380

var voice: RecordingVoice
var _old_voice: ReadAloud.Voice
var ui: Control
var profile: ProfileData
var held: Array = []
var safe := 0
var toasts: Array = []
var ready_now := true
var covered := false
var day := DAY


func before_each() -> void:
	_old_voice = ReadAloud.voice
	voice = RecordingVoice.new()
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(ui)
	profile = ProfileData.new()
	profile.school.grade = 4
	held = []
	safe = 0
	toasts = []
	ready_now = true
	covered = false
	day = DAY


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	if Vr.active():
		Vr.simulate(false)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _director(key := "sandbox_1:7", hoot := true, log := DiscoveryLog.new("")) -> DiscoveryDirector:
	var d := DiscoveryDirector.new()
	d.profile = profile
	d.save_profile = func() -> void: pass
	d.today = func() -> int: return day
	d.player_ready = func() -> bool: return ready_now
	d.overlay_open = func() -> bool: return covered
	d.take_over = func(on: bool) -> void: held.append(on)
	d.keep_safe = func() -> void: safe += 1
	d.toast = func(text: String, seconds: float) -> void: toasts.append([text, seconds])
	d.log = log
	add_child_autofree(d)
	d.setup(ui, key, hoot)
	return d


## Seconds of the director's time, in steps (no real waiting).
func _run(d: DiscoveryDirector, seconds: float, step := 0.5) -> void:
	var t := 0.0
	while t < seconds:
		d.step(step)
		t += step


# --- DISCOVER in MORE --------------------------------------------------------------------------------------------

func test_mores_discover_is_a_picture_button() -> void:
	var d := _director()
	var b := d.more_button()
	add_child_autofree(b)
	assert_eq(b.symbol, &"discover")
	assert_true(HudIcons.knows(&"discover"), "the HUD knows how to draw it")
	assert_eq(b.text, "DISCOVER")
	assert_ne(b.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a pointer over it is heard")


func test_pointing_at_discover_speaks_its_word() -> void:
	var d := _director()
	var b := d.more_button()
	add_child_autofree(b)
	b.mouse_entered.emit()
	assert_eq(voice.said.back(), DiscoveryRules.DISCOVER_WORD)


## The lead on the emulator (2026-10-18, owner #133 "no one will start reading"): DISCOVER opened a grid of written
## lesson titles. Pressed with no subject it starts play at once, Hoot's pick (DiscoveryPlays.pick: a review due, else
## the next unit that plays without reading), spoken; no written map.
func test_discover_starts_hoots_pick_at_once() -> void:
	var d := _director()
	var b := d.more_button()
	add_child_autofree(b)
	b.pressed.emit()
	assert_not_null(d.place, "a game, not a list of lessons")
	assert_false(d.panel.is_open(), "no grid of written titles")
	assert_true(voice.said.has(DiscoveryRules.PICK_LINE), "Hoot says what it is")


func test_discover_opens_the_map_only_when_nothing_plays() -> void:
	var d := _director()
	d.unit_plays = func(_unit: String) -> bool: return false
	d.open_discover()
	assert_true(d.panel.is_open())
	assert_true(d.panel.screen is SchoolScreen)
	assert_eq((d.panel.screen as SchoolScreen).page, SchoolScreen.MAP, "the child's grade's map")
	assert_true(voice.said.has(DiscoveryRules.OPEN_LINE), "Hoot says it as it opens")


func test_the_schools_back_gives_the_world_back() -> void:
	var d := _director()
	d.open_discover("maths")
	d.step(0.1)
	assert_eq(held, [true], "the avatar is held while it shows")
	(d.panel.screen as SchoolScreen).closed.emit()
	assert_false(d.panel.is_open())
	d.step(0.1)
	assert_eq(held, [true, false], "and let go after")


func test_the_avatar_is_kept_safe_while_learning() -> void:
	var d := _director()
	d.open_discover("maths")
	_run(d, 3.2)
	assert_gte(safe, 3, "about once a second")


func test_android_back_closes_it() -> void:
	var d := _director()
	assert_false(d.close_if_open(), "nothing open: Back goes on")
	d.open_discover("maths")
	assert_true(d.close_if_open())
	assert_false(d.panel.is_open())


func test_a_subject_opens_on_its_map() -> void:
	var d := _director()
	d.open_discover("science")
	assert_eq((d.panel.screen as SchoolScreen).subject, "science")
	assert_eq((d.panel.screen as SchoolScreen).page, SchoolScreen.MAP)


# --- Professor Hoot's invitation ---------------------------------------------------------------------------------

func test_hoot_comes_after_the_child_has_stood_a_while_and_speaks() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER - 1.0)
	assert_false(d.hoot.visible, "not at once")
	_run(d, 1.5)
	assert_true(d.hoot.visible)
	assert_true(voice.said.has(DiscoveryRules.HOOT_LINE), "his line is spoken by itself")


func test_hoots_card_shows_a_picture_and_few_words() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_true(d.hoot.discover is DiscoverButton, "one big DISCOVER picture")
	assert_lte(DiscoveryRules.word_count(ReadAloud.words_of(d.hoot)), DiscoveryRules.MAX_SCREEN_WORDS)
	assert_eq(d.hoot.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never covers the world's touches")
	assert_true(d.blockers().has(d.hoot.card), "only the card itself takes a touch")


func test_hoots_discover_starts_play() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	d.hoot.discover.pressed.emit()
	assert_false(d.hoot.visible)
	assert_not_null(d.place, "Hoot's pick: a game at once")


func test_not_now_puts_hoot_away_and_nothing_is_lost() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	d.hoot.not_now.pressed.emit()
	assert_false(d.hoot.visible)
	assert_false(d.panel.is_open())


func test_hoot_waits_quietly_then_fades() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	await wait_seconds(0.1)
	d.hoot.stays = 0.2
	d.hoot.restart_wait()
	await wait_until(func() -> bool: return not d.hoot.visible, 3.0)
	assert_false(d.hoot.visible, "gone by itself")


func test_hoot_waits_while_a_menu_covers_the_screen_or_the_child_is_not_in_the_world() -> void:
	var d := _director()
	covered = true
	_run(d, DiscoveryRules.HOOT_AFTER + 5.0)
	assert_false(d.hoot.visible, "never over a menu")
	covered = false
	ready_now = false
	_run(d, DiscoveryRules.HOOT_AFTER + 5.0)
	assert_false(d.hoot.visible, "not before the child stands in the world")
	ready_now = true
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_true(d.hoot.visible)


func test_hoot_comes_once_a_day_to_a_world() -> void:
	var log := DiscoveryLog.new("")
	var d := _director("sandbox_1:7", true, log)
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_true(d.hoot.visible)
	var again := _director("sandbox_1:7", true, log)   # the same world, later the same day
	_run(again, DiscoveryRules.HOOT_AFTER + 5.0)
	assert_false(again.hoot.visible)
	day += 1
	var tomorrow := _director("sandbox_1:7", true, log)
	_run(tomorrow, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_true(tomorrow.hoot.visible, "the next day he comes again")


func test_hoot_comes_to_a_new_world_the_same_day() -> void:
	var log := DiscoveryLog.new("")
	_run(_director("sandbox_1:7", true, log), DiscoveryRules.HOOT_AFTER + 1.0)
	var other := _director("survivor_2:9", true, log)
	_run(other, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_true(other.hoot.visible, "every world's first visit")


func test_no_hoot_where_he_does_not_come() -> void:
	var d := _director("wave_1:3", false)
	_run(d, DiscoveryRules.HOOT_AFTER + 5.0)
	assert_false(d.hoot.visible)
	assert_true(voice.said.is_empty())


func test_hoots_memory_is_kept_on_the_device() -> void:
	var path := "user://test_discovery_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var d := _director("sandbox_1:7", true, DiscoveryLog.new(path))
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	var back := DiscoveryLog.new(path)
	assert_false(DiscoveryRules.hoot_due(back.state, "sandbox_1:7", DAY), "the file remembers today's visit")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_in_a_headset_hoots_line_goes_on_the_toast_strip() -> void:
	Vr.simulate(true)
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_false(d.hoot.visible, "no card in the headset: the HUD hides while playing (owner #127)")
	assert_eq(toasts.size(), 1)
	assert_eq(str(toasts[0][0]), DiscoveryRules.HOOT_LINE_VR)
	assert_true(voice.said.has(DiscoveryRules.HOOT_LINE_VR), "and spoken")


func test_a_child_who_found_discover_needs_no_invitation_today() -> void:
	var log := DiscoveryLog.new("")
	var d := _director("sandbox_1:7", true, log)
	d.open_discover()
	d.panel.close()
	_run(d, DiscoveryRules.HOOT_AFTER + 5.0)
	assert_false(d.hoot.visible)
	assert_false(DiscoveryRules.hoot_due(log.state, "sandbox_1:7", DAY), "remembered as today's visit")


func test_opening_discover_puts_hoots_card_away() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	d.open_discover()
	assert_false(d.hoot.visible)
