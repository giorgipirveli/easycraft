extends GutTest
## Owner #99 (spec §5.13 "As built (owner #99)"; module 0.2.20): the same name on a new device, with proof and never by
## the name alone, through the game's own OnlineService on two devices against the fake server. The computer asks for
## Anna's account and gets a 6-digit code; Anna's phone hears the ask (the card's list) and a grown-up types the code
## there; the computer gets a one-time key and signs in to the account: the name, progress, looks and gold come. The
## phone stays signed in and hears "Your game is on a computer now too." Wrong codes, NOT ME and time end an ask, and the
## computer is never told what the phone did.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_device_move_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func before_all() -> void:
	DeviceMoveRules.enabled = true   # the move by code ships off (the quick-ship round); these tests are for its return


func after_all() -> void:
	DeviceMoveRules.enabled = false
	DirAccess.remove_absolute(DIR)


func _service(device: String, profile: ProfileData) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.device_id_path = DIR + device + "_device_id.json"
	s.profile = profile
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + "wallet_" + device + ".json"
	s.gift_book_path = DIR + "gifts_" + device + ".json"
	s.ghost_book_path = DIR + "ghosts_" + device + ".json"
	s.clock = func() -> int: return now
	s.prefs.safe_card_seen = now
	s.move_card = false
	add_child_autofree(s)
	return s


func _profile(username: String) -> ProfileData:
	var p := ProfileData.new()
	p.username = username
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = now
	return p


## Anna's phone, signed in: played, backed up, gold on the server.
func _phone() -> OnlineService:
	server.make_account("phone-1", "Anna_7")
	var played := _profile("Anna_7")
	played.universe_unlocked = 3
	played.avatar.hat = &"party"
	played.cosmetics.append("hat.party")
	var phone := _service("phone-1", played)
	assert_eq(await phone.sign_in(), "")
	await phone.profile_sync.sync()
	server.wallets[phone.backend.user_id()] = 4321
	return phone


## A computer's first start: the first-launch screens gave it "Anna_7" too, nothing played.
func _computer() -> OnlineService:
	var c := _service("computer-1", _profile("Anna_7"))
	assert_eq(await c.sign_in(), "")
	return c


func test_the_code_typed_on_the_phone_moves_the_game_to_the_computer() -> void:
	var phone := await _phone()
	var child_id: String = phone.backend.user_id()
	var news: Array[String] = []
	phone.move_news.connect(func(t: String) -> void: news.append(t))
	var computer := await _computer()
	assert_eq(await computer.claim_username("Anna_7"), OnlineRules.message("taken"), "the name is taken")
	var asked: Dictionary = await computer.move_start("anna_7", "computer")
	assert_eq(asked.text, "")
	assert_eq(DeviceMoveRules.normalize_code(asked.code), asked.code, "six digits")
	await wait_process_frames(2)
	assert_eq(phone.move_asks.size(), 1, "the phone heard the ask (notification 110)")
	assert_eq(phone.move_asks[0].kind, "computer")
	assert_false(JSON.stringify(phone.move_asks).contains(asked.code), "the phone never sees the code")
	var wrong := "000000" if asked.code != "000000" else "111111"
	var w: Dictionary = await phone.move_approve(phone.move_asks[0].id, wrong)
	assert_eq(w.text, DeviceMoveRules.wrong_text(2))
	assert_false(w.done)
	var waiting: Dictionary = await computer.move_status(asked.id)
	assert_eq(waiting.state, "waiting", "the computer is not told what the phone did")
	var ok: Dictionary = await phone.move_approve(phone.move_asks[0].id, DeviceMoveRules.pretty_code(asked.code))
	assert_true(ok.done)
	assert_eq(ok.text, DeviceMoveRules.APPROVED_HERE)
	assert_eq(phone.move_asks.size(), 0, "the card's ask is done")
	var st: Dictionary = await computer.move_status(asked.id)
	assert_eq(st.state, "approved")
	assert_eq(st.username, "Anna_7")
	assert_eq(await computer.move_sign_in(st.username, st.key), "")
	assert_eq(computer.backend.user_id(), child_id, "the same account")
	assert_true(computer.claimed())
	assert_eq(computer.profile.universe_unlocked, 3, "progress came")
	assert_eq(computer.profile.avatar.hat, &"party", "the look came")
	assert_eq(computer.profile.survivor_gold, 4321, "the gold came")
	assert_false(phone.backend.is_signed_in(), "one device at a time (owner #105): the phone is logged out")
	await wait_process_frames(2)
	assert_eq(news, [DeviceMoveRules.moved_text("computer")] as Array[String])
	assert_eq(news[0], "Your game is on a computer now too.")


func test_the_one_time_key_works_once() -> void:
	var phone := await _phone()
	var computer := await _computer()
	var asked: Dictionary = await computer.move_start("Anna_7", "tablet")
	await wait_process_frames(2)
	await phone.move_approve(phone.move_asks[0].id, asked.code)
	var key: String = (await computer.move_status(asked.id)).key
	var stranger := _service("stranger-1", _profile("Mallory"))
	assert_eq(await stranger.sign_in(), "")
	assert_eq(await stranger.move_sign_in("Anna_7", key), OnlineRules.message("wrong_key"), "only for the computer")
	assert_eq(await computer.move_sign_in("Anna_7", key), "")


func test_an_old_device_that_comes_online_later_sees_the_ask() -> void:
	server.make_account("phone-1", "Anna_7")
	var computer := await _computer()
	var asked: Dictionary = await computer.move_start("Anna_7", "computer")
	assert_eq(asked.text, "")
	var phone := _service("phone-1", _profile("Anna_7"))
	assert_eq(phone.move_asks.size(), 0)
	assert_eq(await phone.sign_in(), "")
	assert_eq(phone.move_asks.size(), 1, "read at the sign-in")
	server.clock_ms += FakeServer.MOVE_CODE_MS
	assert_eq(await phone.refresh_move_asks(), "")
	assert_eq(phone.move_asks.size(), 0, "its code is over")


func test_not_me_ends_the_ask_quietly_for_the_asker_and_the_code_runs_out() -> void:
	var phone := await _phone()
	var computer := await _computer()
	var asked: Dictionary = await computer.move_start("Anna_7", "phone")
	await wait_process_frames(2)
	assert_eq(await phone.move_decline(phone.move_asks[0].id), "")
	assert_eq(phone.move_asks.size(), 0)
	assert_eq((await computer.move_status(asked.id)).state, "waiting")
	server.clock_ms += FakeServer.MOVE_CODE_MS
	var st: Dictionary = await computer.move_status(asked.id)
	assert_eq(st.state, "ended")
	assert_eq(DeviceMoveRules.ended_text(st.why), DeviceMoveRules.ENDED_WORDS.expired)


func test_three_wrong_codes_end_the_ask_on_the_phone() -> void:
	var phone := await _phone()
	var computer := await _computer()
	var asked: Dictionary = await computer.move_start("Anna_7", "phone")
	await wait_process_frames(2)
	var id: String = phone.move_asks[0].id
	var wrong := "000000" if asked.code != "000000" else "111111"
	await phone.move_approve(id, wrong)
	await phone.move_approve(id, wrong)
	var last: Dictionary = await phone.move_approve(id, wrong)
	assert_true(last.over)
	assert_eq(last.text, DeviceMoveRules.ENDED_HERE)
	assert_eq(phone.move_asks.size(), 0)
	assert_eq((await computer.move_status(asked.id)).state, "waiting", "not told")


func test_back_on_the_new_device_takes_the_card_away() -> void:
	var phone := await _phone()
	var computer := await _computer()
	var asked: Dictionary = await computer.move_start("Anna_7", "phone")
	await computer.move_cancel(asked.id)
	assert_eq(await phone.refresh_move_asks(), "")
	assert_eq(phone.move_asks.size(), 0)


func test_unknown_names_and_ones_own_name() -> void:
	var phone := await _phone()
	var computer := await _computer()
	assert_eq((await computer.move_start("Nobody_1")).text, OnlineRules.message("no_such_player"))
	assert_eq((await phone.move_start("Anna_7")).text, DeviceMoveRules.SELF)


func test_offline_the_move_says_so() -> void:
	server.down = true
	var computer := _service("computer-1", _profile("Anna_7"))
	var r: Dictionary = await computer.move_start("Anna_7")
	assert_ne(r.text, "")
	assert_false(r.has("code"))


func test_the_card_comes_over_every_scene_with_the_first_ask() -> void:
	var phone := await _phone()
	phone.move_card = true
	var computer := await _computer()
	await computer.move_start("Anna_7", "computer")
	await wait_process_frames(2)
	var layer := phone.get_node_or_null("MoveAskLayer") as CanvasLayer
	assert_not_null(layer, "the card's layer")
	if layer == null:
		return
	var card := layer.get_child(0) as MoveAskCard
	assert_true(card.visible)
	assert_eq(card.text_label.text, "Someone wants to play as Anna_7 on a computer.")
