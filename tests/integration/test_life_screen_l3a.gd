extends GutTest
## Owner #118 (docs/design/life-skills.md §6, §14; Life L3a): after every emergency Experience a calm debrief ("You did
## it. In real life, grown-ups help too."), before the name-it card, and in the calm page after STOP FOR NOW; the room
## gets the grown-up's intensity (only on the Big track) and the skill's runs (the danger moments' time); the grown-ups'
## page sets the intensity (gentle by default) and says what "more real" changes; Staying safe's many units show in two
## rows inside the School's frame; the Passport and the map know L3a's skills.

const DAY := 20_000

var profile: ProfileData
var saves := 0
var screen: LifeScreen
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	saves = 0
	measure_path = "user://life_measure_l3a_%d.json" % OS.get_process_id()


func after_each() -> void:
	if is_instance_valid(screen) and is_instance_valid(screen.host):
		screen.host.close()
	if FileAccess.file_exists(measure_path):
		DirAccess.remove_absolute(measure_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String) -> LifeScreen:
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


func _labels() -> String:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append((b as Button).text)
	return "\n".join(out)


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _finish_room() -> void:
	var o := {"finished": true, "stamps": LifeData.DONE | LifeData.SELF, "hints": 0, "seconds": 300.0, "mistakes": 1,
		"log": [{"id": "rip", "kind": "go", "seconds": 4.0, "hinted": false, "mistakes": 1}] as Array[Dictionary]}
	screen.host.finished.emit(o)
	await wait_process_frames(2)


func test_an_emergency_experience_ends_with_the_calm_debrief() -> void:
	profile.life.set_skill("water_safety.middle", {"b": 1, "q": 5})
	await _open("middle")
	screen.start_experience("water_safety", "middle", false)
	await wait_process_frames(1)
	await _finish_room()
	assert_eq(screen.page, LifeScreen.DEBRIEF, "the debrief first")
	var words := _labels()
	assert_string_contains(words, LifeScreen.DEBRIEF_WORDS)
	assert_string_contains(words, "112", "the region's number, for a real emergency")
	assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "read aloud")
	_button("NEXT").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.CARD, "then the name-it card")
	assert_eq(screen.measure.step("water_safety.middle", "rip").m, 1, "the wrong way tried, measured on the device")


func test_a_try_that_isnt_an_emergency_has_no_debrief() -> void:
	profile.life.set_skill("kitchen.middle", {"b": 1, "q": 5})
	await _open("middle")
	screen.start_experience("kitchen", "middle", false)
	await wait_process_frames(1)
	await _finish_room()
	assert_eq(screen.page, LifeScreen.CARD)


func test_stop_for_now_in_an_emergency_says_grown_ups_help_too() -> void:
	profile.life.set_skill("earth_weather.little", {"b": 1, "q": 4})
	await _open("little")
	screen.start_experience("earth_weather", "little", false)
	await wait_process_frames(1)
	screen.host.stopped.emit({"finished": false, "stamps": 0, "hints": 0, "seconds": 20.0, "log": [] as Array[Dictionary]})
	await wait_process_frames(2)
	assert_eq(screen.page, LifeScreen.CALM)
	assert_string_contains(_labels(), "grown-ups help too")


func test_the_room_gets_the_intensity_on_the_big_track_and_the_runs() -> void:
	profile.life.intensity = LifeData.REAL
	profile.life.set_skill("water_safety.big", {"b": 1, "q": 5, "r": 3, "s": LifeData.DONE})
	await _open("big")
	screen.start_experience("water_safety", "big", false)
	await wait_process_frames(1)
	assert_eq(screen.host.intensity, LifeData.REAL)
	assert_eq(screen.host.tries, 3)
	assert_almost_eq(screen.host.danger_scale, 1.0, 0.001, "more real: real time")
	screen.host.close()
	profile.life.set_skill("water_safety.middle", {"b": 1, "q": 5})
	screen.start_experience("water_safety", "middle", false)
	await wait_process_frames(1)
	assert_eq(screen.host.intensity, LifeData.GENTLE, "never more real below the Big track")
	assert_almost_eq(screen.host.danger_scale, LifeRun.SLOW_FIRST, 0.001, "the first try: slow")


func test_the_grown_ups_page_sets_the_intensity() -> void:
	await _open("big")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	screen.grown_ups.show_safety()
	await wait_process_frames(1)
	assert_string_contains(_labels(), "GENTLE")
	assert_string_contains(_labels(), "MORE REAL")
	assert_eq(profile.life.intensity, LifeData.GENTLE, "gentle by default")
	screen.grown_ups.set_intensity(LifeData.REAL)
	assert_eq(profile.life.intensity, LifeData.REAL)
	assert_gt(saves, 0)
	assert_string_contains(_labels(), "Big track", "what it changes, and where")
	assert_string_contains(_labels(), "safe mistake", "and what a safe mistake is")
	var size := screen.get_combined_minimum_size()
	assert_lte(size.y, SchoolUi.FRAME.y, "the SAFETY tab fits: %s" % size)
	assert_lte(size.x, SchoolUi.FRAME.x, "the SAFETY tab fits: %s" % size)
	screen.grown_ups.show_settings()
	await wait_process_frames(1)
	assert_lte(screen.get_combined_minimum_size().y, SchoolUi.FRAME.y, "the settings still fit")


func test_staying_safe_shows_its_many_units_inside_the_frame() -> void:
	await _open("middle")
	screen.show_area("safe")
	await wait_process_frames(2)
	var found := 0
	for exp_id: String in ["water_safety", "poisons_cupboard", "earth_weather"]:
		var u := LifeCatalog.experience_unit(exp_id, "middle")
		assert_ne(u, "", exp_id)
		if screen.find_child("Unit_" + u.replace(".", "_"), true, false) != null:
			found += 1
	assert_eq(found, 3, "L3a's three units on the area page")
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s" % size)
	assert_lte(size.y, SchoolUi.FRAME.y, "%s" % size)


func test_the_grown_ups_page_names_l3as_authorities() -> void:
	await _open("middle")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	assert_string_contains(_labels(), "RNLI")
	assert_string_contains(_labels(), "ShakeOut")
