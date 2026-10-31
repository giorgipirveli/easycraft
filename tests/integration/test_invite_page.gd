extends GutTest
## Owner #79, #81, #82, #85 (spec §25.2): INVITE A FRIEND and the code box, against the fake server. The page signs in,
## claims the child's own name when the account has none, and shows the code big, the link (COPY LINK, SHARE where the
## browser has a share sheet, a QR code), what both friends get, the friends by their in-game names, the Explorer
## Tree's count and the rank, the grown-ups' line, I HAVE A CODE for a new account, and class and family codes behind
## the parent gate. The code box (at the start and in SETTINGS) uses a friend's code or goes on without one. Every page
## fits the menu's frame.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_invite_page_%d/" % OS.get_process_id()
var server: RefCounted
var copied: Array[String] = []
var shared: Array = []
var page: InvitePage


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	copied.clear()
	shared.clear()
	ParentGate.reset_tries()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
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


func _open(s: OnlineService, sharing: bool = true) -> InvitePage:
	page = InvitePage.new()
	page.service = s
	page.copy_text = func(t: String) -> void: copied.append(t)
	page.can_share = func() -> bool: return sharing
	page.share = func(t: String, u: String) -> bool:
		shared.append([t, u])
		return true
	add_child_autofree(page)
	for i in 20:
		await wait_process_frames(1)
		if page.view in [InvitePage.MAIN, InvitePage.CLAIM, InvitePage.FAILED]:
			break
	return page


func _button(text: String) -> Button:
	for b in page.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _label(n: String) -> Label:
	return page.find_child(n, true, false) as Label


func _texts() -> String:
	var out: Array[String] = []
	for l in page.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return "\n".join(out)


func _fits() -> void:
	await wait_process_frames(2)
	var size := page.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [page.view, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [page.view, size])


func test_the_page_shows_the_code_the_link_and_the_ways_to_pass_it_on() -> void:
	server.make_account("dev-alex", "Alex_7")
	await _open(_service("dev-alex", "Alex_7"))
	assert_eq(page.view, InvitePage.MAIN)
	var code := _label("Code").text
	assert_true(InviteRules.looks_like_code(code), code)
	assert_eq(_label("Link").text, InviteRules.link(code))
	_button("COPY LINK").pressed.emit()
	assert_eq(copied, [InviteRules.share_text(code)] as Array[String], "the words and the link, nothing else")
	_button("SHARE").pressed.emit()
	assert_eq(shared, [[InviteRules.share_text(code), InviteRules.link(code)]])
	assert_string_contains(_label("GrownUpLine").text, "no personal information")
	assert_string_contains(_texts(), InviteRules.WHY)
	assert_string_contains(_texts(), InviteRules.NO_ONE_LINE)
	assert_not_null(_button("I HAVE A CODE"), "a new account may still use a friend's code")
	await _fits()


func test_no_share_sheet_no_share_button() -> void:
	server.make_account("dev-alex", "Alex_7")
	await _open(_service("dev-alex", "Alex_7"), false)
	assert_null(_button("SHARE"))
	assert_not_null(_button("COPY LINK"))


func test_the_qr_code_carries_the_link() -> void:
	server.make_account("dev-alex", "Alex_7")
	await _open(_service("dev-alex", "Alex_7"))
	var code := _label("Code").text
	_button("QR CODE").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, InvitePage.QR)
	var qr := page.find_child("Qr", true, false) as QrView
	assert_not_null(qr)
	assert_eq(qr.text, InviteRules.link(code))
	assert_false(qr.qr.is_empty())
	await _fits()
	_button("BACK").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, InvitePage.MAIN)


func test_an_account_without_a_name_claims_the_child_s_own_name_first() -> void:
	var s := _service("dev-new", "Nova_3")   # a device the server has never seen: a new, unclaimed account
	await _open(s)
	assert_eq(page.view, InvitePage.MAIN)
	assert_true(s.claimed())
	assert_eq(str(server.accounts[s.backend.user_id()].username), "Nova_3")


func test_a_taken_name_asks_for_another() -> void:
	server.make_account("dev-other", "Nova_3")
	await _open(_service("dev-new", "Nova_3"))
	assert_eq(page.view, InvitePage.CLAIM)
	assert_not_null(page.find_children("*", "UsernameClaim", true, false))


func test_friends_by_their_names_the_tree_and_the_rank() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	assert_eq(await alex.sign_in(), "")
	var code: String = (await alex.invite_info()).code
	for n in ["Sam_22", "Bo_9"]:
		server.make_account("dev-" + n, n)
		var f := _service("dev-" + n, n)
		assert_eq(await f.sign_in(), "")
		await f.use_invite(code)
		if n == "Sam_22":
			f.profile.invite.note_learned(20_000)
			await f.send_invite_events()
	await _open(alex)
	var text := _texts()
	assert_string_contains(text, "2 joined, 1 learned a whole unit")
	assert_string_contains(text, "Sam_22  - learned!")
	assert_string_contains(text, "Bo_9  - joined")
	assert_eq(_label("Tree").text, "Your tree: 1 child learning")
	assert_string_contains(text, "Mentor: a Mentor star and a crew badge")
	assert_string_contains(text, "Next: Trail Guide, 2 more friends who learn")
	assert_eq(_label("Earned").text, "Gold from friends so far: 250  (this month 1 of 10 friends)", "the rewards so far")
	await _fits()


func test_i_have_a_code_opens_the_box_and_a_friend_s_code_welcomes() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	await alex.sign_in()
	var code: String = (await alex.invite_info()).code
	server.make_account("dev-sam", "Sam_22")
	await _open(_service("dev-sam", "Sam_22"))
	_button("I HAVE A CODE").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, InvitePage.CODE)
	var box := page.find_child("InviteCodeBox", true, false) as InviteCodeBox
	box.edit.text = code
	box.edit.text_changed.emit(code)
	box.check()
	for i in 10:
		await wait_process_frames(1)
	assert_eq(box.message.text, "Welcome, explorer! Alex_7's code brought you +100 gold.")
	box.continue_button.pressed.emit()
	for i in 10:
		await wait_process_frames(1)
	assert_eq(page.view, InvitePage.MAIN)
	assert_null(_button("I HAVE A CODE"), "once")


func test_class_and_family_codes_are_behind_the_parent_gate() -> void:
	server.make_account("dev-mum", "Mum_1")
	await _open(_service("dev-mum", "Mum_1"))
	_button("GROWN-UPS").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.view, InvitePage.GATE)
	page.show_grown_ups()
	await wait_process_frames(1)
	await _fits()
	(page.find_child("Make_family", true, false) as Button).pressed.emit()
	for i in 10:
		await wait_process_frames(1)
	assert_eq(page.view, InvitePage.GROWN_UPS)
	assert_string_contains(_texts(), "FAMILY-")
	assert_not_null(page.find_child("Remove_family", true, false))
	await _fits()


func test_the_code_box_at_the_start_goes_on_without_a_code() -> void:
	var s := _service("dev-kid", "Kid_1")
	var box := InviteCodeBox.new()
	box.service = s
	box.prefill = "blue otter 42"
	add_child_autofree(box)
	await wait_process_frames(1)
	assert_eq(box.edit.text, "blue otter 42", "the web page's ?invite= fills it in")
	assert_false(box.ok_button.disabled)
	watch_signals(box)
	box.skip_button.pressed.emit()
	assert_signal_emitted_with_parameters(box, "done", [{"skipped": true}])
	box.edit.text = "hello"
	box.edit.text_changed.emit("hello")
	assert_true(box.ok_button.disabled, "not a code yet")


func test_the_code_box_signs_in_claims_and_uses_the_code_at_the_start() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	await alex.sign_in()
	var code: String = (await alex.invite_info()).code
	var kid := _service("dev-kid", "Kid_1")   # never signed in before
	var box := InviteCodeBox.new()
	box.service = kid
	add_child_autofree(box)
	await wait_process_frames(1)
	box.edit.text = code
	box.edit.text_changed.emit(code)
	box.check()
	for i in 12:
		await wait_process_frames(1)
	assert_eq(kid.status, OnlineService.ONLINE)
	assert_true(kid.claimed(), "the name picked at the start is the friend-facing name")
	assert_eq(box.message.text, "Welcome, explorer! Alex_7's code brought you +100 gold.")
	assert_true(box.continue_button.visible)
	assert_true(kid.profile.invite.used)


func test_a_build_without_a_server_and_a_failed_sign_in_say_so_kindly() -> void:
	var s := _service("dev-x", "Kid_1")
	s.server = {"error": "no server"}
	await _open(s)
	assert_eq(page.view, InvitePage.SOON)
	assert_string_contains(_texts(), "Invite codes need the internet")
	assert_not_null(_button("BACK"))
	page._show_failed("The server is resting.")
	await wait_process_frames(1)
	assert_eq(page.view, InvitePage.FAILED)
	assert_not_null(_button("TRY AGAIN"))


## Owner #93: without the internet the page says what still works alone (other troubles need no such line).
func test_no_internet_says_what_works_alone() -> void:
	server.make_account("dev-x", "Kid_1")
	server.set("down", true)
	await _open(_service("dev-x", "Kid_1"))
	assert_eq(page.view, InvitePage.FAILED)
	assert_string_contains(_texts(), OnlineRules.PLAY_ALONE)
	page._show_failed("The server is resting.")
	await wait_process_frames(1)
	assert_false(_texts().contains(OnlineRules.PLAY_ALONE), "other troubles need no hint")


func test_a_friend_who_brought_friends_shows_how_many_never_who() -> void:
	server.make_account("dev-gran", "Gran_5")
	var gran := _service("dev-gran", "Gran_5")
	await gran.sign_in()
	var code: String = (await gran.invite_info()).code
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	await alex.sign_in()
	await alex.use_invite(code)
	var alex_code: String = (await alex.invite_info()).code
	server.make_account("dev-sam", "Sam_22")
	var sam := _service("dev-sam", "Sam_22")
	await sam.sign_in()
	await sam.use_invite(alex_code)
	await _open(gran)
	assert_eq(_label("Friend0").text, "Alex_7  - joined  (brought 1)")
	assert_false(_texts().contains("Sam_22"), "a friend's friend is never named")
