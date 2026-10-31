extends GutTest
## Owner #132 (W1), stage 2, with #133 and #134: the discovery crystal in a world. After a few minutes of play (not
## while busy or under a menu; home worlds; a grown-up can turn them off) a glowing crystal rises a few metres from the
## child with a chime and a spoken line. Walking up to it, tapping it or (in a headset) touching it with a hand starts
## its play: the challenge is spoken and shown with numbers only; the child takes gems (a tap, a hand); the world
## answers (a gem flies in, or bounces off). Three challenges, answer gold for each solved with no miss (the School's
## daily cap), then it goes with a burst. Untouched, it fades; walking away or the cross ends the play quietly; nothing
## is lost. It is this device's own (no network), and what it played is kept on the device (a unit with no real play
## yet is recorded as play debt).

class RecordingVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


## A flat meadow: grass below y 70.
class Meadow:
	func block(p: Vector3i) -> int:
		return BlockIds.GRASS if p.y < 70 else BlockIds.AIR


const DAY := 20380

var voice: RecordingVoice
var _old_voice: ReadAloud.Voice
var ui: Control
var world: Node3D
var meadow := Meadow.new()
var profile: ProfileData
var feet := Vector3(0.5, 70.0, 0.5)
var busy_now := false
var covered := false
var hands: Array[Vector3] = []
var log: DiscoveryLog


func before_each() -> void:
	_old_voice = ReadAloud.voice
	voice = RecordingVoice.new()
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(ui)
	world = Node3D.new()
	add_child_autofree(world)
	profile = ProfileData.new()
	profile.school.grade = 4
	profile.survivor_gold = 0
	feet = Vector3(0.5, 70.0, 0.5)
	busy_now = false
	covered = false
	hands = []
	log = DiscoveryLog.new("")
	log.state = DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)   # Hoot has been: the crystal is the subject here


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _director(hoot := true) -> DiscoveryDirector:
	var d := DiscoveryDirector.new()
	d.profile = profile
	d.save_profile = func() -> void: pass
	d.today = func() -> int: return DAY
	d.player_ready = func() -> bool: return true
	d.overlay_open = func() -> bool: return covered
	d.take_over = func(_on: bool) -> void: pass
	d.keep_safe = func() -> void: pass
	d.toast = func(_text: String, _seconds: float) -> void: pass
	d.in_vr = func() -> bool: return false
	d.log = log
	d.world_parent = world
	d.block_at = meadow.block
	d.player_feet = func() -> Vector3: return feet
	d.player_yaw = func() -> float: return 0.0
	d.busy = func() -> bool: return busy_now
	d.hand_points = func() -> Array[Vector3]: return hands
	d.next_seed = func() -> int: return 11
	d.unit_plays = func(_id: String) -> bool: return false   # the crystal's own number play (G0's place: test_discovery_play_place)
	add_child_autofree(d)
	d.setup(ui, "sandbox_1:7", hoot)
	return d


func _run(d: DiscoveryDirector, seconds: float, step := 0.5) -> void:
	var t := 0.0
	while t < seconds:
		d.step(step)
		t += step


func _with_crystal() -> DiscoveryDirector:
	var d := _director()
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS + 2.0)
	return d


func _ray_to(p: Vector3) -> Array:
	var eye := feet + Vector3(0, 1.6, 4.0)
	return [eye, (p - eye).normalized()]


func _tap_at(d: DiscoveryDirector, p: Vector3) -> bool:
	var r := _ray_to(p)
	return d.tap(r[0], r[1])


## Plays the current challenge by its hints, tapping each gem.
func _solve_one(d: DiscoveryDirector) -> void:
	var guard := 0
	while d.challenge.state() != DiscoveryChallenge.DONE and guard < 40:
		_tap_at(d, d.crystal.gem_position(d.challenge.hint()))
		guard += 1


# --- When and where it comes ---------------------------------------------------------------------------------------

func test_a_crystal_rises_after_a_few_minutes_of_play() -> void:
	var d := _director()
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS - 5.0)
	assert_null(d.crystal)
	_run(d, 7.0)
	assert_not_null(d.crystal)
	assert_true(d.crystal.get_parent() == world, "in the world, this device's own")
	var p := d.crystal.global_position
	assert_between(Vector2(p.x - feet.x, p.z - feet.z).length(), DiscoveryCrystalRules.NEAR,
		DiscoveryCrystalRules.FAR + 0.8)
	assert_true(voice.said.has(DiscoveryCrystalRules.HOOT_CRYSTAL_LINE), "the first one ever: Hoot says what to do")


func test_never_while_busy_or_under_a_menu() -> void:
	var d := _director()
	busy_now = true
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS + 60.0)
	assert_null(d.crystal, "not in a fight, a race, a round, riding or flying")
	busy_now = false
	covered = true
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS + 60.0)
	assert_null(d.crystal, "not under a menu")


func test_never_when_a_grown_up_turned_them_off() -> void:
	profile.settings[DiscoveryCrystalRules.SETTING] = false
	var d := _director()
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS + 60.0)
	assert_null(d.crystal)


func test_never_where_hoot_does_not_come() -> void:
	var d := _director(false)   # Monster Wave's arena, a space world
	_run(d, DiscoveryCrystalRules.FIRST_SECONDS + 60.0)
	assert_null(d.crystal)


func test_an_untouched_crystal_fades_and_the_next_comes_later() -> void:
	var d := _with_crystal()
	var first := d.crystal
	_run(d, DiscoveryCrystalRules.WAIT_SECONDS + 1.0)
	assert_true(d.crystal == null or d.crystal != first, "it faded")
	_run(d, DiscoveryCrystalRules.EVERY_SECONDS - 20.0)
	assert_null(d.crystal, "a while before the next")
	_run(d, 30.0)
	assert_not_null(d.crystal)
	assert_true(voice.said.has(DiscoveryCrystalRules.ARRIVE_LINE), "the next one says it came")


# --- Starting it ---------------------------------------------------------------------------------------------------

func test_walking_up_to_it_starts_the_play() -> void:
	var d := _with_crystal()
	feet = d.crystal.global_position + Vector3(0.6, 0, 0)
	d.step(0.1)
	assert_true(d.playing())
	var c := d.challenge.current()
	assert_eq(voice.said.back(), SchoolSpeech.spoken(str(c.say)), "the challenge is spoken")
	assert_eq(d.crystal.gem_count(), (c.labels as Array).size())


func test_a_tap_on_it_starts_the_play_and_a_tap_elsewhere_is_the_worlds() -> void:
	var d := _with_crystal()
	assert_false(_tap_at(d, d.crystal.global_position + Vector3(0, 9, 0)), "the sky: the world's tap")
	assert_false(d.playing())
	assert_true(_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0)))
	assert_true(d.playing())


func test_in_a_headset_the_hand_touches_it() -> void:
	var d := _with_crystal()
	hands = [d.crystal.global_position + Vector3(0, 0.9, 0)]
	d.step(0.1)
	assert_true(d.playing())


func test_the_play_shows_numbers_and_signs_only() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	assert_true(d.strip.visible)
	assert_lte(DiscoveryRules.word_count(ReadAloud.words_of(d.strip)), DiscoveryRules.MAX_SCREEN_WORDS)
	assert_eq(DiscoveryRules.word_count(d.crystal.words()), 0, "the crystal and its gems: numbers and signs")


# --- Playing it ----------------------------------------------------------------------------------------------------

func test_taps_take_gems_and_never_build_while_playing() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	var before := d.challenge.total if str(d.challenge.current().kind) == "make" else d.challenge.taken.size()
	assert_true(_tap_at(d, d.crystal.gem_position(d.challenge.hint())), "a gem")
	var after := d.challenge.total if str(d.challenge.current().kind) == "make" else d.challenge.taken.size()
	assert_ne(after, before, "it flew in")
	assert_true(_tap_at(d, feet + Vector3(0, -5, 0)), "the ground: still the play's, nothing built")


func test_three_challenges_solved_pay_answer_gold_and_it_goes() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	watch_signals(d)
	var crystal := d.crystal
	for n in DiscoveryPlays.PER_CRYSTAL:
		_solve_one(d)
		_run(d, DiscoveryDirector.NEXT_PAUSE + 0.1, 0.1)
	assert_signal_emitted(d, "crystal_finished")
	var result: Dictionary = get_signal_parameters(d, "crystal_finished")[0]
	assert_eq(int(result.first_try), DiscoveryPlays.PER_CRYSTAL)
	assert_eq(profile.survivor_gold, DiscoveryPlays.PER_CRYSTAL * EarnRules.ANSWER_GOLD, "the School's answer gold")
	assert_false(d.playing())
	assert_true(d.crystal == null or d.crystal != crystal, "it went with a burst")
	assert_false(d.strip.visible)
	assert_eq(int(log.state.crystals.played), 1, "kept on the device")


func test_answer_gold_keeps_the_schools_daily_cap() -> void:
	profile.earn_today = {"d": DAY, "g": EarnRules.ANSWER_DAY_CAP}
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	_solve_one(d)
	assert_eq(profile.survivor_gold, 0, "the day's answer gold is full")


## A gem that would bounce off now (taking the helpful ones until there is one); -1 when the challenge ends first.
func _bouncing_gem(d: DiscoveryDirector) -> int:
	for step in 40:
		for i in d.crystal.gem_count():
			var probe := DiscoveryChallenge.new([d.challenge.current()])
			probe.total = d.challenge.total
			probe.taken = d.challenge.taken.duplicate()
			if probe.take(i) == DiscoveryChallenge.BOUNCED:
				return i
		if d.challenge.state() == DiscoveryChallenge.DONE:
			return -1
		_tap_at(d, d.crystal.gem_position(d.challenge.hint()))
	return -1


func test_a_bounce_is_a_calm_miss_and_that_challenge_pays_nothing() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	var wrong := _bouncing_gem(d)
	assert_ne(wrong, -1, "a gem that goes past the number, or is not the smallest")
	var before := d.challenge.total
	_tap_at(d, d.crystal.gem_position(wrong))
	assert_eq(d.challenge.misses, 1)
	assert_eq(d.challenge.total, before, "the number stays")
	_solve_one(d)
	assert_eq(profile.survivor_gold, 0, "not right the first time: no answer gold")


func test_after_two_misses_the_helpful_gem_glows() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	var wrong := _bouncing_gem(d)
	_tap_at(d, d.crystal.gem_position(wrong))
	assert_eq(d.crystal.glowing, -1, "one miss: no help yet")
	_tap_at(d, d.crystal.gem_position(wrong))
	assert_eq(d.challenge.misses, DiscoveryChallenge.HINT_AFTER)
	assert_eq(d.crystal.glowing, d.challenge.hint(), "shown, not told")


func test_in_a_headset_a_hand_takes_a_gem() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	var hint := d.challenge.hint()
	hands = [d.crystal.gem_position(hint)]
	d.step(0.1)
	hands = []
	assert_true(d.challenge.misses == 0 and (d.challenge.total != int(d.challenge.current().get("start", 0))
		or d.challenge.taken.size() == 1), "the touched gem was taken")


# --- Ending it -----------------------------------------------------------------------------------------------------

func test_walking_away_ends_it_quietly() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	feet += Vector3(DiscoveryCrystalRules.LEAVE + 2.0, 0, 0)
	d.step(0.1)
	assert_false(d.playing())
	assert_false(d.strip.visible)
	assert_eq(profile.survivor_gold, 0)


func test_the_cross_ends_it_quietly() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	d.strip.cross.pressed.emit()
	assert_false(d.playing())


func test_a_fight_ends_it_quietly() -> void:
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	busy_now = true
	d.step(0.1)
	assert_false(d.playing())


func test_a_unit_without_real_play_yet_is_recorded() -> void:
	for id: String in ["g4.maths.big_numbers", "g4.maths.compare_round"]:
		profile.school.set_progress(id, {"s": 2, "d": DAY + 10, "m": DAY - 3})
	var d := _with_crystal()
	_tap_at(d, d.crystal.global_position + Vector3(0, 0.9, 0))
	assert_eq(int((log.state.crystals.debt as Dictionary).get("g4.maths.add_subtract", 0)), 1,
		"the next unit had no real play: a grade challenge instead, and the unit noted")
