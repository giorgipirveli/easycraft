extends GutTest
## Owner #118, #115 (Life L3b): the Life screen knows L3b's three Experiences and Life Town's second row. Staying safe's
## units (now ten on the Middle track) and Our world's (Safe with Animals) fit the School's frame on every track; the
## grown-ups' page names L3b's authorities; walking up to a Success place in Life Town opens its unit on the child's
## track (TRY IT), like every other place; an L3b Experience ends with the calm debrief.

const DAY := 20_000

var profile: ProfileData
var screen: LifeScreen
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	measure_path = "user://life_measure_l3b_%d.json" % OS.get_process_id()


func after_each() -> void:
	if is_instance_valid(screen) and is_instance_valid(screen.host):
		screen.host.close()
	if FileAccess.file_exists(measure_path):
		DirAccess.remove_absolute(measure_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String, town := "") -> LifeScreen:
	profile.life.track = track
	screen = LifeScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.locale = "ka_GE"
	screen.measure = LifeMeasure.new(measure_path)
	screen.town_experience = town
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


func test_staying_safe_and_our_world_fit_the_frame_on_every_track() -> void:
	for track in LifeData.TRACKS:
		await _open(track)
		for area: String in ["safe", "world"]:
			screen.show_area(area, track)
			await wait_process_frames(2)
			for exp_id: String in (["electricity", "medical"] if area == "safe" else ["animals"]):
				var u := LifeCatalog.experience_unit(exp_id, track)
				assert_not_null(screen.find_child("Unit_" + u.replace(".", "_"), true, false), "%s %s: %s" % [area, track, u])
			var size := screen.get_combined_minimum_size()
			assert_lte(size.x, SchoolUi.FRAME.x, "%s %s: %s" % [area, track, size])
			assert_lte(size.y, SchoolUi.FRAME.y, "%s %s: %s" % [area, track, size])
		screen.queue_free()
		await wait_process_frames(1)


func test_the_grown_ups_page_names_l3bs_authorities() -> void:
	await _open("middle")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	for w: String in ["Electrical Safety First", "Dogs Trust", "Epilepsy Action", "Asthma + Lung UK"]:
		assert_string_contains(_labels(), w)


func test_a_success_place_in_life_town_opens_its_unit() -> void:
	for exp_id: String in SuccessExperiences.IDS:
		await _open("middle", exp_id)
		assert_eq(screen.page, LifeScreen.UNIT, exp_id + ": its unit")
		assert_eq(screen.unit_id, LifeCatalog.experience_unit(exp_id, "middle"), exp_id)
		assert_not_null(screen.find_child("TryIt", true, false), exp_id + ": TRY IT")
		screen.queue_free()
		await wait_process_frames(1)


func test_an_l3b_experience_ends_with_the_calm_debrief() -> void:
	profile.life.set_skill("animals.middle", {"b": 1, "q": 5})
	await _open("middle")
	screen.start_experience("animals", "middle", false)
	await wait_process_frames(2)
	var o := {"finished": true, "stamps": LifeData.DONE | LifeData.SELF, "hints": 0, "seconds": 300.0, "mistakes": 1,
		"log": [{"id": "tree", "kind": "action", "seconds": 4.0, "hinted": false, "mistakes": 1}] as Array[Dictionary]}
	screen.host.finished.emit(o)
	await wait_process_frames(2)
	assert_eq(screen.page, LifeScreen.DEBRIEF, "the calm debrief first")
	assert_string_contains(_labels(), "grown-ups help too")
