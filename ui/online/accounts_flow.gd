class_name AccountsFlow
extends VBoxContainer
## Owner #99, #104, #105 (spec §5.13 "As built"; the final review's simple model): LOG OUT and LOG IN, one page at a time,
## from the main menu's own button, SETTINGS, PLAY ONLINE's account card, the start screen and the logged-out card.
## One player on a device: there are no kept player slots.
## - LOG OUT: one tap and one YES / NO (never a grown-up's step). The game is saved to the account first (offline: "Connect
##   to the internet first, so your game is saved."); an account with no password makes one first ("Make a password
##   first, so you can log back in."); then this device is unlinked on the server and forgets the account and the player
##   (OnlineService.log_out): the main menu opens on the start screen (PLAY for a new player, or LOG IN).
## - LOG IN: the name and the password (OnlineService.log_in), or a grown-up's key (the parent gate, then
##   KeySignInPage); every other device of the account is logged out, and the main menu opens for the account.

signal closed     # BACK or NO: nothing changed
signal switched   # logged out or in: the main menu opens again (unless open_menu is false)

const VIEW_CONFIRM := &"confirm"   # "Log out, Anna?" YES, LOG OUT / NO
const VIEW_LOG_OUT := &"log_out"
const VIEW_PASSWORD := &"password"   # make a password first, then log out
const VIEW_LOG_IN := &"log_in"
const VIEW_GATE := &"gate"
const VIEW_KEY := &"key"

var service: OnlineService
var start_at := VIEW_LOG_OUT
var open_menu := true         # tests: false (switched still says it)
var view := &""
var page: Control
var message: Label
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	if start_at == VIEW_LOG_IN:   # the main menu's LOG IN, the start screen, a logged-out device
		show_log_in(service.prefs.account_name if service.logged_out else "",
			PasswordRules.LOGGED_OUT if service.logged_out else "")
	else:
		show_confirm()


func button(text: String) -> Button:
	for b in find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and (b as Button).is_visible_in_tree():
			return b
	return null


## LOG OUT, asked once: "Log out, Anna?" YES, LOG OUT / NO. Never a grown-up's step.
func show_confirm() -> void:
	var name := str(service.account.get("username", service.prefs.account_name))
	var v := _page(VIEW_CONFIRM, DeviceMoveRules.LOG_OUT_TITLE)
	var ask := OnlineUi.words(DeviceMoveRules.LOG_OUT_ASK % name if name != "" else DeviceMoveRules.LOG_OUT_TITLE + "?", 34)
	ask.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # it has the name in it
	v.add_child(ask)
	v.add_child(OnlineUi.words(DeviceMoveRules.LOG_OUT_SAVED_FIRST, 26, 1000))
	var yes := OnlineUi.button(DeviceMoveRules.YES_LOG_OUT, UiKit.GREEN, Vector2(320, 90))
	yes.pressed.connect(show_log_out)
	var no := OnlineUi.button(DeviceMoveRules.NO, UiKit.BLUE, Vector2(220, 90))
	no.pressed.connect(func() -> void: closed.emit())
	v.add_child(OnlineUi.row([no, yes], 28))
	ReadAloud.auto(ask.text)


## LOG OUT: saving first, then this device leaves the account (OnlineService.log_out).
func show_log_out() -> void:
	var v := _page(VIEW_LOG_OUT, DeviceMoveRules.LOG_OUT_TITLE)
	message.text = DeviceMoveRules.SAVING
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(240, 84))
	back.pressed.connect(func() -> void: closed.emit())
	v.add_child(OnlineUi.row([back], 24))
	_busy = true
	var err: String = await service.log_out()
	_busy = false
	if not is_inside_tree() or view != VIEW_LOG_OUT:
		return
	if err == "":
		_done()
		return
	if err == OnlineService.LOG_OUT_NEEDS_PASSWORD:
		show_password_first()
		return
	message.text = err
	var again := OnlineUi.button("TRY AGAIN", UiKit.GREEN, Vector2(280, 84))
	again.pressed.connect(show_log_out)
	(back.get_parent() as HBoxContainer).add_child(again)
	ReadAloud.auto(err)


## An account with no password makes one before it logs out (so the player can log back in), then LOG OUT goes on.
func show_password_first() -> void:
	var pp := PasswordPage.new()
	pp.service = service
	pp.mode = PasswordPage.Mode.MAKE
	pp.note = DeviceMoveRules.MAKE_FIRST
	pp.later_allowed = true   # BACK: no log out
	pp.done.connect(show_log_out)
	pp.closed.connect(func() -> void: closed.emit())
	_set_page(VIEW_PASSWORD, pp)


## LOG IN: the online name and the password (owner #105), or a grown-up's key.
func show_log_in(username: String = "", note: String = "") -> void:
	var p := LogInPage.new()
	p.username = username
	p.note = note
	p.goes = service.progress_goes   # the final review's 2: a guest's progress never goes without asking
	p.log_in.connect(_log_in.bind(p))
	p.key_wanted.connect(show_key_gate)
	p.closed.connect(func() -> void: closed.emit())
	_set_page(VIEW_LOG_IN, p)
	service.prepare_log_in()   # the device's asking account, early (a brand-new one waits a moment)


func _log_in(username: String, password: String, p: LogInPage) -> void:
	if _busy:
		return
	_busy = true
	p.busy = true
	var err: String = await service.log_in(username, password)
	_busy = false
	if not is_inside_tree() or page != p:
		return
	p.busy = false
	if err != "":
		p.message.text = err
		return
	_done()


func show_key_gate(username: String) -> void:
	var gate := GrownUpGate.new()
	gate.passed.connect(show_key.bind(username))
	gate.cancelled.connect(show_log_in.bind(username))
	_set_page(VIEW_GATE, gate)


func show_key(username: String) -> void:
	var k := KeySignInPage.new()
	k.service = service
	k.username = username
	k.goes = service.progress_goes
	k.done.connect(_done)
	k.closed.connect(show_log_in.bind(username))
	_set_page(VIEW_KEY, k)


func _done() -> void:
	switched.emit()
	if open_menu:
		AccountsOverlay.to_menu()


func _page(id: StringName, title: String) -> VBoxContainer:
	var v := OnlineUi.column(18)
	v.add_child(ReadAloud.with_speaker(UiKit.title(title), v))
	message = OnlineUi.words("", 26, 1000)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	v.add_child(message)
	_set_page(id, v)
	return v


func _set_page(id: StringName, control: Control) -> void:
	OnlineUi.clear(self)
	view = id
	page = control
	add_child(control)
