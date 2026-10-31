extends GutTest
## Owner #81, #82 (brief 2026-09-30 item 5): the CREW tab against the fake server. MAKE A CREW picks a name from two
## kid-safe word lists and a badge (never typed); the crew page shows the badge and name, each member's avatar and what
## each learned this week (never a ranking), the weekly goal bar; INVITE A FRIEND TO THE CREW sends an invitation the
## friend JOINs (or NO THANKS); LEAVE THE CREW. Every page fits the menu's frame.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_crew_page_%d/" % OS.get_process_id()
var server: RefCounted
var page: FriendsPage


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	Curriculum.clear_cache()
	Audio.stop_all()


func _service(device: String, username: String) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.in_online_world = func() -> bool: return false
	add_child_autofree(s)
	return s


func _open(s: OnlineService) -> FriendsPage:
	page = FriendsPage.new()
	page.service = s
	add_child_autofree(page)
	for i in 30:
		await wait_process_frames(1)
		if page.view == FriendsPage.FRIENDS:
			break
	page.show_crew()
	await wait_process_frames(2)
	return page


func _button(node_name: String) -> Button:
	for b: Button in page.find_children(node_name, "Button", true, false):
		if b.is_visible_in_tree():
			return b
	return null


func _labels() -> String:
	var out: Array[String] = []
	for l in page.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return " | ".join(out)


func _settle() -> void:
	for i in 10:
		await wait_process_frames(1)


func _fits(what: String) -> void:
	await wait_process_frames(2)
	var size := page.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [what, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [what, size])


func test_make_a_crew_from_the_word_lists_and_a_badge() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	await _open(alex)
	assert_eq(page.view, FriendsPage.CREW)
	assert_string_contains(_labels(), CrewRules.ABOUT)
	await _fits("crew, none yet")
	_button("MakeCrew").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, FriendsPage.MAKE_CREW)
	assert_string_contains(_labels(), "Brave Astronauts")
	_button("NextAdjective").pressed.emit()
	_button("NextNoun").pressed.emit()
	_button("PrevNoun").pressed.emit()
	_button("NextNoun").pressed.emit()
	await wait_process_frames(1)
	assert_string_contains(_labels(), "Bright Comets")
	_button("Badge_owl").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.pick_badge, CrewRules.BADGES.find("owl"))
	assert_eq(page.find_children("*", "LineEdit", true, false).size(), 0, "a name is never typed")
	await _fits("make a crew")
	_button("MakeTheCrew").pressed.emit()
	await _settle()
	assert_eq(page.view, FriendsPage.CREW)
	assert_string_contains(_labels(), "Your crew is ready!")
	assert_string_contains(_labels(), "Bright Comets")
	assert_string_contains(_labels(), CrewRules.size_words(1))
	assert_string_contains(_labels(), "Alex_7 (you)")
	assert_string_contains(_labels(), CrewRules.goal_words(0, 6))
	await _fits("the crew page")


func test_invite_a_friend_who_joins_and_what_each_learned_this_week() -> void:
	var a: String = server.make_account("dev-alex", "Alex_7")
	var b: String = server.make_account("dev-sam", "Sam_22")
	server.befriend(a, b)
	var alex := _service("dev-alex", "Alex_7")
	var sam := _service("dev-sam", "Sam_22")
	await _open(alex)
	_button("MakeCrew").pressed.emit()
	await wait_process_frames(1)
	_button("MakeTheCrew").pressed.emit()
	await _settle()
	_button("CrewInvite").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, FriendsPage.PICK_CREWMATE)
	await _fits("pick a crewmate")
	_button("Mate0").pressed.emit()
	await _settle()
	assert_string_contains(_labels(), "Invitation sent!")
	page.queue_free()
	await wait_process_frames(1)
	await _open(sam)
	assert_string_contains(_labels(), "Alex_7 asks you to join the Brave Astronauts (1 of 6)")
	_button("Join").pressed.emit()
	await _settle()
	assert_string_contains(_labels(), "Welcome to the crew!")
	assert_string_contains(_labels(), "Sam_22 (you)")
	assert_string_contains(_labels(), "Alex_7")
	# The week: each member's own learning, never a ranking.
	server.soc[b].week = {"days": 2, "units": ["g4.maths.big_numbers"]}
	await page.refresh(FriendsPage.CREW)
	var t := str(Curriculum.unit("g4.maths.big_numbers").get("title", ""))
	assert_string_contains(_labels(), "2 learning days. Mastered: %s" % t)
	assert_string_contains(_labels(), "Resting this week")
	assert_string_contains(_labels(), CrewRules.goal_words(2, 6))
	for bad in ["1st", "winner", "top learner", "rank"]:
		assert_false(_labels().to_lower().contains(bad), "never a ranking: %s" % bad)
	assert_eq((page.find_children("Members", "", true, false)[0] as Node).get_child_count(), 2, "each member's avatar")
	_button("LeaveCrew").pressed.emit()
	await _settle()
	assert_string_contains(_labels(), "You left the crew.")
	assert_not_null(_button("MakeCrew"))


func test_no_thanks_to_an_invitation() -> void:
	var a: String = server.make_account("dev-alex", "Alex_7")
	var b: String = server.make_account("dev-sam", "Sam_22")
	server.befriend(a, b)
	var alex := _service("dev-alex", "Alex_7")
	assert_eq(await alex.sign_in(), "")
	await alex.crew_action("make", {"adjective": "Kind", "noun": "Owls", "badge": "owl"})
	await alex.crew_action("invite", {"user_id": b})
	await _open(_service("dev-sam", "Sam_22"))
	assert_not_null(_button("Decline"))
	_button("Decline").pressed.emit()
	await _settle()
	assert_null(_button("Decline"), "gone")
	assert_eq(server.soc[b].crew_invites, [])
