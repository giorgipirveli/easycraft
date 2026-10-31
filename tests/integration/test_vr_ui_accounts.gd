extends GutTest
## Owner #101 with #104 / #105 (VR on the Meta Quest): the account screens work in a headset like every other screen.
## The overlay AccountsFlow opens on (LOG IN, LOG OUT, PASSWORD) and the logged-out card are drawn in the VR canvas and
## come to the eye panel; the name and the password are typed with the VR keyboard; a password stays secret there (dots on
## the keyboard's own line, never read aloud, never in any words on the canvas) and SHOW / HIDE works from the keyboard;
## the main menu's account button and every word on these screens are 24 px or more. Against the fake server.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const SECRET := "otter-moon-42"

var ROOT := "user://test_vr_ui_accounts_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var profile: ProfileData
var pad: PadFocus
var _old_pad: PadFocus
var _voice: ReadAloud.Voice
var heard: Array[String] = []


class Spy:
	extends ReadAloud.Voice
	var heard: Array[String]

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		heard.append(text)


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	server = FakeServer.new()
	profile = ProfileData.new()
	_old_pad = PadFocus.instance
	pad = PadFocus.new()
	add_child_autofree(pad)
	_voice = ReadAloud.voice
	var spy := Spy.new()
	heard = []
	spy.heard = heard
	ReadAloud.voice = spy
	Profile.data.settings.read_to_me = true
	Vr.simulate(true)


func after_each() -> void:
	Vr.simulate(false)
	get_tree().paused = false
	PadFocus.instance = _old_pad
	ReadAloud.voice = _voice
	Profile.data.settings.read_to_me = false
	for f in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(f))


func _service() -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id_path = ROOT + "device_id.json"
	s.prefs_path = ROOT + "online.json"
	s.wallet_path = ROOT + "wallet_sync.json"
	s.gift_book_path = ROOT + "gifts.json"
	s.ghost_book_path = ROOT + "ghosts.json"
	s.profile = profile
	s.save_profile = func() -> void: JsonStore.write_atomic(ROOT + "profile.json", profile.to_json())
	s.clock = func() -> int: return now
	s.move_card = false
	s.logged_out_card = true
	add_child_autofree(s)
	s.prefs.safe_card_seen = now
	return s


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _kb() -> VrKeyboard:
	return VrUi.instance.keyboard


func _type(word: String) -> void:
	for ch in word:
		if ch != ch.to_lower():
			_kb().key(VrKeyboard.SHIFT).pressed.emit()
		var k := _kb().key(ch)
		assert_not_null(k, "a key for %s" % ch)
		if k:
			k.pressed.emit()
	await _frames(2)


## The words shown on the canvas now (labels, buttons, rich text): a password must never be among them.
func _words_on_canvas() -> String:
	var out := []
	for n in Vr.ui_viewport().find_children("*", "Control", true, false):
		var c := n as Control
		if c.is_visible_in_tree() and (c is Label or c is Button or c is RichTextLabel):
			out.append(str(c.get("text")))
	return "\n".join(out)


func _log_in_overlay() -> AccountsOverlay:
	var s := _service()
	var b := AccountsOverlay.start_log_in_button(s)
	add_child_autofree(b)
	b.pressed.emit()
	await _frames(8)
	var found := Vr.ui_viewport().find_children("*", "CanvasLayer", false, false).filter(func(n: Node) -> bool:
		return n is AccountsOverlay)
	assert_eq(found.size(), 1, "the account overlay is drawn in the VR canvas")
	return found[0] as AccountsOverlay if found.size() == 1 else null


func test_log_in_comes_to_the_eye_panel_in_the_canvas() -> void:
	var o := await _log_in_overlay()
	if o == null:
		return
	assert_eq(o.flow.view, AccountsFlow.VIEW_LOG_IN)
	assert_eq(VrUi.instance.panel.place, VrPanelRules.EYE, "in front of the child")
	assert_eq(VrReadability.too_small(o), [] as Array[String], "every word 24 px or more")
	o.queue_free()


func test_the_name_and_a_secret_password_are_typed_with_the_vr_keyboard() -> void:
	var o := await _log_in_overlay()
	if o == null:
		return
	var page := o.flow.page as LogInPage
	assert_not_null(page)
	if page == null:
		return
	page.name_edit.grab_focus()
	await _frames(2)
	assert_eq(_kb().target, page.name_edit)
	await _type("Anna_7")
	assert_eq(page.name_edit.text, "Anna_7")
	page.password.edit.grab_focus()
	await _frames(2)
	assert_eq(_kb().target, page.password.edit, "the password box gets the keyboard too")
	await _type(SECRET)
	assert_eq(page.password.text, SECRET)
	assert_eq(_kb().shown_text(), "•".repeat(SECRET.length()), "dots on the keyboard's own line")
	assert_false(_words_on_canvas().contains(SECRET), "never in any words on the canvas")
	for line in heard:
		assert_false(line.contains(SECRET), "never read aloud")
	var show := _kb().key(VrKeyboard.SHOW)
	assert_not_null(show, "SHOW on the keyboard for a secret box")
	if show:
		assert_true(show.is_visible_in_tree())
		show.pressed.emit()
		await _frames(1)
		assert_false(page.password.edit.secret, "SHOW shows it")
		assert_eq(page.password.show_button.text, PasswordRules.HIDE, "the field's own SHOW follows")
		assert_eq(_kb().shown_text(), SECRET, "the child chose to see it")
		assert_eq(show.text, PasswordRules.HIDE)
		show.pressed.emit()
		await _frames(1)
		assert_true(page.password.edit.secret, "HIDE hides it again")
	page.name_edit.grab_focus()
	await _frames(2)
	assert_false(_kb().key(VrKeyboard.SHOW).is_visible_in_tree(), "no SHOW for a name")
	o.queue_free()


func test_the_logged_out_card_comes_to_the_eye_panel() -> void:
	var s := _service()
	s._lo_show_card()
	await _frames(3)
	var card := Vr.ui_viewport().find_children("*", "LoggedOutCard", true, false)
	assert_eq(card.size(), 1, "the card is drawn in the VR canvas")
	if card.size() != 1:
		return
	var c := card[0] as LoggedOutCard
	assert_true(c.is_visible_in_tree())
	assert_eq(VrUi.instance.panel.place, VrPanelRules.EYE, "in front of the child, whatever they were doing")
	assert_eq(VrReadability.too_small(c), [] as Array[String], "every word 24 px or more")
	s._lo_hide_card()
	await _frames(2)
	assert_ne(VrUi.instance.panel.place, VrPanelRules.EYE, "LATER: back to playing")


func test_the_main_menus_account_button_is_on_the_panel_and_readable() -> void:
	var b := AccountsOverlay.menu_button(_service())
	var o := Node.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var holder := Control.new()
	holder.size = Vector2(VrPanelRules.CANVAS)
	holder.theme = UiKit.theme()
	holder.add_child(b)
	layer.add_child(holder)
	UiLayers.route(layer, o)
	await _frames(3)
	assert_eq(b.get_viewport(), Vr.ui_viewport())
	assert_gte(VrReadability.drawn_px(b), float(VrReadability.MIN_PX), "LOG IN / LOG OUT at 24 px or more")
	assert_true(Rect2(Vector2.ZERO, Vector2(VrPanelRules.CANVAS)).encloses(b.get_global_rect()), "on the panel")
