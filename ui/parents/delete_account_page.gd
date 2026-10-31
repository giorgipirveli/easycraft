class_name DeleteAccountPage
extends VBoxContainer
## DELETE MY ONLINE ACCOUNT, a page of the grown-up area behind the parent gate (M4 Task 8b, agent G;
## spec §5.14, §17.2; Google Play's account-deletion rule, COPPA parents' rights). Plain adult words
## on what goes (on our server) and what stays (on this device), then a button held for 3 seconds.
## The server takes two calls: the page asks for a confirmation when it opens and deletes with it
## when the hold ends. Afterwards the game forgets its online link (OnlineService.forget_online) and
## offline play goes on. Not while this game plays in an online world (the account's session is
## that world's connection): leave it first.
## Owner #99, #105 (the owner, 2026-10-15 23:06: "when i delete my account it is not deleting"): DELETE now deletes the
## online account AND this player on this device (its name, progress, gold and looks: OnlineService.forget_player),
## so nothing signs in again by itself and nothing makes the account again from what was left; the worlds on this device
## stay (said on the done screen); the game starts again for a new player. It needs the password once there is one. When
## it can't be done (offline, not signed in) it says so plainly: nothing was deleted.

signal closed   # BACK, or OK after deleting
signal deleted

const RED := Color("d64545")

var service: OnlineService
## Whether this game plays in an online world now (default Session.is_online(); tests set one).
var in_online_world := Callable()
## Owner #99: after the server deleted the account, this player goes from this device (default: the game's own player,
## OnlineService.forget_player; tests set their own) and the main menu opens again (default AccountsOverlay.to_menu).
var forget_player := Callable()
var open_menu := Callable()
var password: PasswordField

var hold: HoldButton
var back_button: Button
var message: Label

var _confirm := ""
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	if in_world():
		add_child(_line("Leave the online world first (SAVE & QUIT), then come back here to delete the online account."))
		_buttons([])
		return
	if service == null or not service.has_online_link():
		add_child(_line(NO_ACCOUNT))
		_buttons([])
		return
	if service.status != OnlineService.ONLINE:
		var waiting := _line("One moment...")
		add_child(waiting)
		var err: String = await service.sign_in()   # owner #99: never seem to work while not signed in
		if not is_inside_tree():
			return
		remove_child(waiting)
		waiting.queue_free()
		if err != "" or service.status != OnlineService.ONLINE:
			add_child(_line(CANT_NOW))
			add_child(_line(err))
			_buttons([])
			return
	var name := str(service.account.get("username", ""))
	add_child(_line((tr("Deletes %s's online account on our server") % name if name != "" else "Deletes the online account on our server")
		+ ": the online name, the password, friends, chat history, the online backup, the sign-in key and gold. Reports your child sent stay, without the name, to keep other children safe.", 22))
	add_child(_line(stays_words(PlatformRules.lan_available(PlatformRules.current())), 22))
	if service.has_password != 0:   # owner #105: the server needs it once there is one (beside the hold: it fits)
		password = PasswordField.make(PasswordRules.PASSWORD, 200.0, 130.0, 110.0)
	hold = HoldButton.new()
	hold.text = "HOLD TO DELETE"
	hold.add_theme_font_size_override("font_size", 28)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		hold.add_theme_stylebox_override(state, UiKit.box(RED.darkened(0.15) if state == "pressed" else RED))
	hold.disabled = true   # until the server's confirmation is here
	hold.held.connect(_delete)
	_buttons([password, hold] if password != null else [hold])
	_prepare()


func in_world() -> bool:
	return bool(in_online_world.call()) if in_online_world.is_valid() else Session.is_online()


func _buttons(extra: Array) -> void:
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 90))
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(OnlineUi.row([back_button] + extra, 28))
	message = OnlineUi.words("", 24, 1000)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)


## What goes from this device and what stays; `lan`: this device has home Wi-Fi play (M7: a browser has none, spec §20.3).
## Owner #99: this player goes from this device too (else PLAY ONLINE made the same name again from what was left).
static func stays_words(lan: bool) -> String:
	var plays := "Sandbox, Survivor, bot friends and home Wi-Fi play" if lan else "Sandbox, Survivor and bot friends"
	return "On this device this player goes too: the name, progress, gold, looks and books. Worlds on this device stay, and %s keep working for a new player. This can't be undone." % plays


const NO_ACCOUNT := "This player has no online account on this device: there is nothing to delete online."
const CANT_NOW := "Can't delete now: this device is not connected to the game's server. Connect to the internet and try again. Nothing was deleted."
const DONE_WORDS := "The online account is deleted, and this player is gone from this device: the name, progress, gold, looks and books. Worlds on this device stay. The game starts again for a new player."


func _line(text: String, font_size: int = 24) -> Label:
	return OnlineUi.words(text, font_size, 1100)


## The server's first call: a confirmation for the hold (nothing is deleted yet).
func _prepare() -> void:
	_busy = true
	message.text = "One moment..."
	var r: Dictionary = await service.delete_account_start()
	_busy = false
	if not is_inside_tree():
		return
	_confirm = str(r.get("confirm", ""))
	if r.text != "":
		message.text = r.text
		return
	hold.disabled = false
	message.text = "Hold the red button for 3 seconds to delete."


func _delete() -> void:
	if _busy or _confirm == "":
		return
	if password != null and password.text == "":   # owner #105: asked before the server is
		message.text = PasswordRules.DELETE_PASSWORD
		return
	_busy = true
	hold.disabled = true
	message.text = "Deleting..."
	var err: String = await service.delete_account(_confirm, password.text if password != null else "")
	_busy = false
	if not is_inside_tree():
		return
	if err == "":
		_done()
		return
	message.text = err + " Nothing was deleted."   # owner #99: never seem to work
	if err == OnlineRules.message("confirm_expired"):
		var said := err
		await _prepare()   # a new confirmation for the next hold
		if is_inside_tree() and _confirm != "":
			message.text = said
	else:
		hold.disabled = false


func _done() -> void:
	# Owner #99: this player goes from this device too (nothing signs in again or makes the name again by itself)
	if forget_player.is_valid():
		forget_player.call()
	elif service.profile == Profile.data:   # the game's own player (tests give their own profile and forget_player)
		service.forget_player()   # the account files and the player go from this device (the worlds stay)
	OnlineUi.clear(self)
	hold = null
	password = null
	add_child(OnlineUi.words(DONE_WORDS, 28, 1000))
	var done := OnlineUi.button("OK", UiKit.BLUE, Vector2(220, 90))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void:
		closed.emit()
		if open_menu.is_valid():
			open_menu.call()
		elif service.profile == Profile.data:
			AccountsOverlay.to_menu())   # the start screen, for a new player
	add_child(done)
	deleted.emit()
