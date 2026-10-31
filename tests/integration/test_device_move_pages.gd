extends GutTest
## Owner #99 (spec §5.13 "As built (owner #99)"): the pages of the move, as a child sees them, against the fake server.
## On the computer, PLAY ONLINE's name claim: a taken name asks "Someone already has the name Anna_7. Is it you, from
## another phone, tablet or computer?"; YES, IT'S ME opens MOVE YOUR GAME HERE with a big 6-digit code. On Anna's phone
## the card "Someone wants to play as Anna_7 on a computer." warns "Never type a code someone tells you."; TYPE THE CODE
## is a grown-up's step (the parent gate), then a number pad. The right code: the computer says "Welcome back, Anna_7!"
## and plays as her account. Every page fits the menu's panel at 1280 x 720 with big buttons.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_device_move_pages_%d/" % OS.get_process_id()
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


func _service(device: String, username: String) -> OnlineService:
	var p := ProfileData.new()
	p.username = username
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = now
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.device_id_path = DIR + device + "_device_id.json"
	s.profile = p
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + "wallet_" + device + ".json"
	s.gift_book_path = DIR + "gifts_" + device + ".json"
	s.ghost_book_path = DIR + "ghosts_" + device + ".json"
	s.clock = func() -> int: return now
	s.move_card = false
	add_child_autofree(s)
	s.prefs.safe_card_seen = now
	return s


func _phone() -> OnlineService:
	server.make_account("phone-1", "Anna_7")
	var phone := _service("phone-1", "Anna_7")
	phone.profile.universe_unlocked = 3
	assert_eq(await phone.sign_in(), "")
	await phone.profile_sync.sync()
	return phone


func _screen(s: OnlineService) -> PlayOnlineScreen:
	var screen := PlayOnlineScreen.new()
	screen.service = s
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	box.add_child(screen)
	add_child_autofree(box)
	await wait_process_frames(8)
	return screen


func _card(phone: OnlineService) -> MoveAskCard:
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var card := MoveAskCard.new()
	card.service = phone
	layer.add_child(card)
	await wait_process_frames(2)
	return card


func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append(b)
	return out


func _has(root: Node, text: String) -> bool:
	return _buttons(root).any(func(b: Button) -> bool: return b.text == text)


func _press(root: Node, prefix: String) -> void:
	var b: Button = null
	for x in _buttons(root):
		if x.text.begins_with(prefix):
			b = x
			break
	assert_not_null(b, "a %s button" % prefix)
	if b:
		b.pressed.emit()
	await wait_process_frames(6)


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _fits(root: Control, what: String, room: Vector2 = PANEL_CONTENT) -> void:
	await wait_process_frames(2)
	var size := root.get_combined_minimum_size()
	assert_lte(size.y, room.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, room.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(root):
		if not (b is ReadAloud.ReadAloudSpeaker):
			assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
			assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


func _pass_gate(gate: GrownUpGate) -> void:
	assert_not_null(gate, "the parent gate first")
	if gate == null:
		return
	for key in str(gate.question.answer):
		gate.press(key)
	gate.press("OK")
	await wait_process_frames(3)


func _type(card: MoveAskCard, code: String) -> void:
	for c in code:
		card.press(c)
	card.press("OK")
	await wait_process_frames(6)


## The computer at the claim, the name taken, YES: MOVE YOUR GAME HERE with its code.
func _to_move_page(computer: OnlineService) -> PlayOnlineScreen:
	var screen := await _screen(computer)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _press(screen, "OK")
	var claim := screen.page as UsernameClaim
	assert_true(claim.taken_box.visible, "a taken name asks")
	await _press(screen, DeviceMoveRules.YES_ME)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_MOVE)
	return screen


func test_a_taken_name_asks_and_the_question_fits() -> void:
	await _phone()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _screen(computer)
	await _press(screen, "OK")
	assert_string_contains(_words(screen),
		"Someone already has the name Anna_7. Is it you, from another phone, tablet or computer?")
	assert_true(_has(screen, DeviceMoveRules.YES_ME))
	assert_true(_has(screen, DeviceMoveRules.NO_OTHER))
	assert_false(_has(screen, "RANDOM"), "the question only")
	await _fits(screen, "the taken name's question")


func test_the_code_typed_on_the_phone_moves_the_game_and_the_computer_says_welcome_back() -> void:
	var phone := await _phone()
	var child_id: String = phone.backend.user_id()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _to_move_page(computer)
	var move := screen.page as MoveGamePage
	move.auto_poll = false
	assert_eq(move.state, MoveGamePage.WAITING)
	assert_eq(move.code_label.text, DeviceMoveRules.pretty_code(move.code), "the code, big, in two threes")
	var words := _words(screen)
	assert_string_contains(words, DeviceMoveRules.TYPE_THERE)
	assert_string_contains(words, DeviceMoveRules.WAITING)
	assert_false(words.contains("online"), "nothing about the other device")
	await _fits(screen, "MOVE YOUR GAME HERE")
	var card := await _card(phone)
	assert_true(card.visible, "the phone's card")
	var card_words := _words(card)
	assert_string_contains(card_words, "Someone wants to play as Anna_7 on a computer.")
	assert_string_contains(card_words, DeviceMoveRules.ASK_IF)
	assert_string_contains(card_words, "Never type a code someone tells you.")
	await _fits(card, "the phone's card", Vector2(1280, 720))
	await _press(card, DeviceMoveRules.TYPE_CODE)
	assert_eq(card.view, MoveAskCard.GATE, "a grown-up's step first")
	await _pass_gate(card.gate)
	assert_eq(card.view, MoveAskCard.PAD)
	await _fits(card, "the code pad", Vector2(1280, 720))
	var wrong := "000000" if move.code != "000000" else "111111"
	await _type(card, wrong)
	assert_string_contains(_words(card), DeviceMoveRules.wrong_text(2))
	assert_eq(card.view, MoveAskCard.PAD, "try again")
	await _type(card, move.code)
	assert_string_contains(_words(card), DeviceMoveRules.APPROVED_HERE)
	await wait_process_frames(6)   # notification 110: the computer looks at once
	assert_eq(move.state, MoveGamePage.WELCOME)
	assert_string_contains(_words(screen), "Welcome back, Anna_7! Your name, progress, looks and gold are here.")
	assert_eq(computer.backend.user_id(), child_id)
	assert_eq(computer.profile.universe_unlocked, 3)
	await _press(screen, "OK")
	assert_eq(screen.view, OnlineRules.SCREEN_HOME, "her own PLAY ONLINE")


func test_not_me_on_the_phone_and_the_computer_just_waits() -> void:
	var phone := await _phone()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _to_move_page(computer)
	var move := screen.page as MoveGamePage
	move.auto_poll = false
	var card := await _card(phone)
	await _press(card, DeviceMoveRules.NOT_ME)
	assert_string_contains(_words(card), DeviceMoveRules.DECLINED_HERE)
	assert_eq(phone.move_asks.size(), 0)
	await move.poll()
	assert_eq(move.state, MoveGamePage.WAITING, "the computer is not told")
	server.clock_ms += FakeServer.MOVE_CODE_MS
	await move.poll()
	assert_eq(move.state, MoveGamePage.ENDED)
	assert_string_contains(_words(screen), DeviceMoveRules.ENDED_WORDS.expired)
	assert_true(_has(screen, DeviceMoveRules.NEW_CODE))
	await _press(screen, DeviceMoveRules.NEW_CODE)
	assert_eq(move.state, MoveGamePage.WAITING, "a new code")


func test_back_on_the_computer_takes_the_phones_card_away() -> void:
	var phone := await _phone()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _to_move_page(computer)
	assert_eq(phone.move_asks.size(), 1)
	await _press(screen, "BACK")
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	assert_eq(await phone.refresh_move_asks(), "")
	assert_eq(phone.move_asks.size(), 0)


func test_use_a_key_is_a_grown_ups_step_with_the_name_typed() -> void:
	await _phone()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _to_move_page(computer)
	await _press(screen, DeviceMoveRules.USE_KEY)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GATE)
	await _pass_gate(screen.page as GrownUpGate)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_KEY)
	assert_eq((screen.page as KeySignInPage).name_edit.text, "Anna_7")


func test_the_phone_hears_that_its_game_is_on_a_computer_now_too() -> void:
	var phone := await _phone()
	var card := await _card(phone)
	phone.move_news.emit(DeviceMoveRules.moved_text("computer"))
	await wait_process_frames(2)
	assert_eq(card.view, MoveAskCard.NEWS)
	assert_string_contains(_words(card), "Your game is on a computer now too.")
	await _press(card, "OK")
	assert_false(card.visible)


func test_three_wrong_codes_end_it_on_the_card() -> void:
	var phone := await _phone()
	var computer := _service("computer-1", "Anna_7")
	var screen := await _to_move_page(computer)
	var move := screen.page as MoveGamePage
	var card := await _card(phone)
	await _press(card, DeviceMoveRules.TYPE_CODE)
	await _pass_gate(card.gate)
	var wrong := "000000" if move.code != "000000" else "111111"
	for i in 3:
		await _type(card, wrong)
	assert_eq(card.view, MoveAskCard.BYE)
	assert_string_contains(_words(card), DeviceMoveRules.ENDED_HERE)
