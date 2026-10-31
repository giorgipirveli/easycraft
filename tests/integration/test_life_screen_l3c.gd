extends GutTest
## Owner #112, #118 (Life L3c): the Life screen knows Online City, Find Your Way and Home Helper. Life online, Getting
## around and Home and everyday show their units on every track within the School's frame; the grown-ups' page names L3c's
## authorities and says nothing is asked for or kept; walking up to a third-row place in Life Town opens its unit (TRY
## IT); Online City and Find Your Way end with the calm debrief, Home Helper (chores) goes straight to its name-it card.

const DAY := 20_000

var profile: ProfileData
var screen: LifeScreen
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	measure_path = "user://life_measure_l3c_%d.json" % OS.get_process_id()


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


func _finished() -> Dictionary:
	return {"finished": true, "stamps": LifeData.DONE | LifeData.SELF, "hints": 0, "seconds": 300.0, "mistakes": 0,
		"log": [{"id": "end", "kind": "info", "seconds": 4.0, "hinted": false, "mistakes": 0}] as Array[Dictionary]}


func test_the_three_areas_fit_the_frame_on_every_track() -> void:
	for track in LifeData.TRACKS:
		await _open(track)
		for pair: Array in [["online", "online_city"], ["around", "find_way"], ["home", "home_helper"]]:
			screen.show_area(str(pair[0]), track)
			await wait_process_frames(2)
			var u := LifeCatalog.experience_unit(str(pair[1]), track)
			assert_not_null(screen.find_child("Unit_" + u.replace(".", "_"), true, false), "%s %s: %s" % [pair[0], track, u])
			var size := screen.get_combined_minimum_size()
			assert_lte(size.x, SchoolUi.FRAME.x, "%s %s: %s" % [pair[0], track, size])
			assert_lte(size.y, SchoolUi.FRAME.y, "%s %s: %s" % [pair[0], track, size])
		screen.queue_free()
		await wait_process_frames(1)


func test_the_grown_ups_page_names_l3cs_authorities() -> void:
	await _open("middle")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	for w: String in ["Childnet", "UK Safer Internet Centre", "RSPCA", "GINETEX", "never asks for an address"]:
		assert_string_contains(_labels(), w)


func test_a_third_row_place_in_life_town_opens_its_unit() -> void:
	for exp_id: String in ["online_city", "find_way", "home_helper"]:
		await _open("big", exp_id)
		assert_eq(screen.page, LifeScreen.UNIT, exp_id + ": its unit")
		assert_eq(screen.unit_id, LifeCatalog.experience_unit(exp_id, "big"), exp_id)
		assert_not_null(screen.find_child("TryIt", true, false), exp_id + ": TRY IT")
		screen.queue_free()
		await wait_process_frames(1)


func test_online_city_and_find_your_way_end_with_the_calm_debrief_home_helper_does_not() -> void:
	for pair: Array in [["online_city", LifeScreen.DEBRIEF], ["find_way", LifeScreen.DEBRIEF], ["home_helper", LifeScreen.CARD]]:
		var exp_id := str(pair[0])
		profile = ProfileData.new()
		profile.life.set_skill(exp_id + ".middle", {"b": 1, "q": 4})
		await _open("middle")
		screen.start_experience(exp_id, "middle", false)
		await wait_process_frames(2)
		screen.host.finished.emit(_finished())
		await wait_process_frames(2)
		assert_eq(screen.page, pair[1], exp_id)
		if pair[1] == LifeScreen.DEBRIEF:
			assert_string_contains(_labels(), "grown-ups help too")
		screen.queue_free()
		await wait_process_frames(1)
