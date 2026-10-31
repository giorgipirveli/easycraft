class_name PlayOnlineScreen
extends VBoxContainer
## PLAY ONLINE, from the main menu (M4 Wave 1, Agent C; spec §17.1-17.3). It signs in, then shows
## what this player needs next (OnlineRules.screen): "Ask a grown-up" for under-13 without consent
## (the parent gate, then the grown-up's page that starts the consent flow), the stay-safe card, the
## username claim, and then HOME: HOST MY WORLD (a Sandbox or Survivor world) and FRIENDS.
## Pictures first, short words, big buttons.

signal closed
signal host_requested(world_mode: StringName)
signal join_requested(match_id: String)

const VIEW_SOON := &"soon"                 # this build has no server address yet
const VIEW_CONNECTING := &"connecting"
const VIEW_FAILED := &"failed"
const VIEW_GATE := &"gate"
const VIEW_GROWNUPS := &"grownups"
const VIEW_HOST := &"host"
const VIEW_FRIENDS := &"friends"

var service: OnlineService
var view: StringName = &""
## The page on screen (StaySafeCard, UsernameClaim, GrownUpGate, GrownUpsPanel, OnlineFriendsPanel,
## or a VBoxContainer of this screen's own).
var page: Control
var message: Label

var _busy := false
var _friends_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 20)
	service.account_changed.connect(_on_account_changed)
	service.status_changed.connect(_on_status_changed)
	service.friends_changed.connect(_update_news)
	service.invite_received.connect(_on_invite_received)
	service.account_deleted.connect(_on_account_deleted)   # M4 G
	open()


## Signs in (once) and shows the right page.
func open() -> void:
	if not service.has_server():
		var v := _page(VIEW_SOON, "Play online", &"globe")
		v.add_child(OnlineUi.words(OnlineRules.message("no_server"), 30))
		v.add_child(_back_row([]))
		return
	_show_connecting()
	var err: String = await service.sign_in()
	if not is_inside_tree():
		return
	if service.logged_out:   # owner #105: another device logged in to this account: LOG IN to play here
		_show_log_in(service.prefs.account_name, PasswordRules.LOGGED_OUT)
	elif err != "":
		_show_failed(err)
	else:
		route()


## The page for where this player is now.
func route() -> void:
	match service.screen():
		OnlineRules.SCREEN_ASK_GROWNUP:
			_show_ask()
		OnlineRules.SCREEN_WAIT_GROWNUP:
			_show_wait()
		OnlineRules.SCREEN_PARENT_OFF:
			_show_parent_off()
		OnlineRules.SCREEN_SAFE_CARD:
			_show_card()
		OnlineRules.SCREEN_CLAIM:
			_show_claim()
		_:
			if service.needs_password():   # owner #105: an account with a name and no password is asked once
				_show_password(PasswordPage.Mode.MAKE, true)
			else:
				_show_home()


func button(text: String) -> Button:
	for b in find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and (b as Button).is_visible_in_tree():
			return b
	return null


# --- Pages ---

func _show_connecting() -> void:
	var v := _page(VIEW_CONNECTING, "Play online", &"globe")
	v.add_child(OnlineUi.words("Connecting...", 30))
	v.add_child(_back_row([]))


func _show_failed(text: String) -> void:
	var v := _page(VIEW_FAILED, "Play online", &"globe")
	v.add_child(OnlineUi.words(text, 30))
	var alone := OnlineUi.play_alone(text)   # owner #93: what works without the internet
	if alone != null:
		v.add_child(alone)
	var again := OnlineUi.button("TRY AGAIN", UiKit.GREEN, Vector2(300, 90))
	again.pressed.connect(open)
	v.add_child(_back_row([again] + _gh_races_button()))   # M4 ghost races: friends' races kept on this device


func _show_ask() -> void:
	var v := _page(OnlineRules.SCREEN_ASK_GROWNUP, "Ask a grown-up", &"grownup")
	v.add_child(OnlineUi.words("Playing online with friends needs a grown-up's OK.", 30))
	var here := OnlineUi.button("GROWN-UP HERE", UiKit.ORANGE, Vector2(400, 96), &"grownup")
	here.pressed.connect(_show_gate)
	v.add_child(_back_row([here]))


func _show_wait() -> void:
	var v := _page(OnlineRules.SCREEN_WAIT_GROWNUP, "Ask a grown-up", &"grownup")
	v.add_child(OnlineUi.words("A grown-up is saying yes. When they are done, tap CHECK.", 30))
	var check := OnlineUi.button("CHECK", UiKit.GREEN, Vector2(260, 90))
	check.pressed.connect(_check_consent)
	var grownups := OnlineUi.button("GROWN-UPS", UiKit.ORANGE, Vector2(300, 90), &"grownup")
	grownups.pressed.connect(_show_gate)
	v.add_child(_back_row([check, grownups]))


func _show_parent_off() -> void:
	var v := _page(OnlineRules.SCREEN_PARENT_OFF, "Play online", &"grownup")
	v.add_child(OnlineUi.words(OnlineRules.message("online_off"), 30))
	var grownups := OnlineUi.button("GROWN-UPS", UiKit.ORANGE, Vector2(300, 90), &"grownup")
	grownups.pressed.connect(_show_gate)
	v.add_child(_back_row([grownups]))


func _show_gate() -> void:
	var gate := GrownUpGate.new()
	gate.passed.connect(_show_grownups)
	gate.cancelled.connect(route)
	_set_page(VIEW_GATE, gate)


func _show_grownups() -> void:
	var panel := GrownUpsPanel.new()
	panel.service = service
	panel.closed.connect(_on_grownups_closed)
	_set_page(VIEW_GROWNUPS, panel)


func _show_card() -> void:
	var card := StaySafeCard.new()
	card.done.connect(func() -> void:
		service.mark_card_seen()
		route())
	_set_page(OnlineRules.SCREEN_SAFE_CARD, card)


func _show_claim() -> void:
	var claim := UsernameClaim.new()
	claim.service = service
	claim.done.connect(_after_claim)   # owner #105: a password right after the name
	claim.have_account.connect(_show_log_in)   # owner #67; owner #99, #105: LOG IN (the name and the password)
	claim.move_asked.connect(_show_move)   # owner #99: a taken name, and YES, IT'S ME
	_set_page(OnlineRules.SCREEN_CLAIM, claim)


# --- Owner #67: I HAVE AN ACCOUNT (the account on every device) ---
# The parent gate, then KeySignInPage: the child's name and the sign-in key sign this device in to that account.
# Owner #99: I HAVE AN ACCOUNT opens LOG IN (the name), then MOVE YOUR GAME HERE (the code from the other device), whose
# USE A KEY leads here with the name typed.

const VIEW_KEY := &"key"


func _show_key_gate(username: String = "") -> void:
	var gate := GrownUpGate.new()
	gate.passed.connect(_show_key.bind(username))
	gate.cancelled.connect(route)
	_set_page(VIEW_GATE, gate)


func _show_key(username: String = "") -> void:
	var key_page := KeySignInPage.new()
	key_page.service = service
	key_page.username = username
	key_page.goes = service.progress_goes
	key_page.done.connect(route)
	key_page.closed.connect(route)
	_set_page(VIEW_KEY, key_page)

# --- Owner #99, #105: LOG IN and LOG OUT ---
# A taken name asks (UsernameClaim); YES, IT'S ME and I HAVE AN ACCOUNT open LOG IN (the name and the password, or a
# grown-up's key); this device then plays as that account. The home page's account card has PASSWORD and LOG OUT
# (AccountsFlow: saved first, then this device leaves the account and the start screen opens).

const VIEW_LOG_IN := &"log_in"
const VIEW_MOVE := &"move"
const VIEW_ACCOUNTS := &"accounts"
const VIEW_PASSWORD := &"password"


## Owner #105: LOG IN with the name and the password (I HAVE AN ACCOUNT, a taken name's YES, a device logged out by
## another one); this device plays as that account and its other devices are logged out (OnlineService.log_in).
func _show_log_in(username: String = "", note: String = "") -> void:
	var p := LogInPage.new()
	p.username = username
	p.note = note
	p.goes = service.progress_goes   # the final review's 2: a guest's progress never goes without asking
	p.log_in.connect(_log_in.bind(p))
	p.key_wanted.connect(func(n: String) -> void: _show_key_gate(n))
	p.closed.connect(route)
	_set_page(VIEW_LOG_IN, p)
	service.prepare_log_in()   # the device's asking account, early (a brand-new one waits a moment)


func _log_in(username: String, password: String, p: LogInPage) -> void:
	p.busy = true
	# Another account than this device's own starts from a fresh player, so nothing of this device's player merges into
	# it and gold can't double (OnlineService._become); the same account (logged out elsewhere) keeps what was played.
	# The page asked first when this device's player had progress (LogInPage.goes).
	var err: String = await service.log_in(username, password)
	if not is_inside_tree() or page != p:
		return
	p.busy = false
	if err != "":
		p.message.text = err
		return
	route()


## Owner #105: right after the name is claimed, the account's password (when it has none yet: it never has on a real
## server, the claim makes none).
func _after_claim() -> void:
	var r: Dictionary = await service.password_state()
	if not is_inside_tree():
		return
	if r.get("has_password", false):
		route()
	else:
		_show_password(PasswordPage.Mode.MAKE, false)


## Owner #105: MAKE a password (right after the claim, `asked` once of an account without one, with LATER) or CHANGE it.
func _show_password(mode: PasswordPage.Mode, asked: bool = false) -> void:
	var pp := PasswordPage.new()
	pp.service = service
	pp.mode = mode
	pp.asked = asked
	pp.later_allowed = asked or mode != PasswordPage.Mode.MAKE
	if asked:
		service.mark_password_asked()
	pp.done.connect(route)
	pp.closed.connect(_show_home if asked else route)
	_set_page(VIEW_PASSWORD, pp)


func _show_move(username: String) -> void:
	if not DeviceMoveRules.enabled:   # the move by code is off: LOG IN with the name and the password (owner #105)
		_show_log_in(username)
		return
	var m := MoveGamePage.new()
	m.service = service
	m.username = username
	m.done.connect(route)
	m.closed.connect(route)
	m.key_wanted.connect(_show_key_gate)
	_set_page(VIEW_MOVE, m)


func _show_accounts(start_at: StringName = AccountsFlow.VIEW_LOG_OUT) -> void:
	var flow := AccountsFlow.new()
	flow.service = service
	flow.start_at = start_at
	flow.closed.connect(route)
	_set_page(VIEW_ACCOUNTS, flow)


## "You are Anna" and LOG OUT.
func _account_card() -> Control:
	var you := Label.new()
	you.text = tr("You are %s") % service.profile.username
	you.add_theme_font_size_override("font_size", 30)
	you.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var log_out := OnlineUi.button(DeviceMoveRules.LOG_OUT, Color(), Vector2(200, 64))
	log_out.add_theme_font_size_override("font_size", 22)
	log_out.pressed.connect(_show_accounts)
	var password := OnlineUi.button(PasswordRules.PASSWORD, Color(), Vector2(220, 64))   # owner #105
	password.add_theme_font_size_override("font_size", 22)
	password.pressed.connect(func() -> void:
		_show_password(PasswordPage.Mode.MAKE if service.has_password == 0 else PasswordPage.Mode.CHANGE))
	return OnlineUi.row([you, password, log_out], 20)


func _show_home() -> void:
	var v := _page(OnlineRules.SCREEN_HOME, "Play online", &"")
	v.add_child(_account_card())   # owner #99: LOG OUT
	var host := OnlineUi.button("HOST MY\nWORLD", UiKit.GREEN, Vector2(400, 170), &"house")
	host.pressed.connect(_show_host)
	_friends_button = OnlineUi.button("FRIENDS", UiKit.BLUE, Vector2(400, 170), &"friends")
	_friends_button.pressed.connect(_show_friends)
	_update_news()
	v.add_child(OnlineUi.row([host, _friends_button], 28))
	var grownups := OnlineUi.button("GROWN-UPS", Color(), Vector2(260, 80), &"grownup")
	grownups.add_theme_font_size_override("font_size", 24)
	grownups.pressed.connect(_show_gate)
	v.add_child(_back_row([grownups]))
	service.refresh_friends()   # new requests show on the button (friends_changed)


func _update_news() -> void:
	if view == OnlineRules.SCREEN_HOME and is_instance_valid(_friends_button):
		var news := _news()
		_friends_button.text = "FRIENDS" + (tr("\n%d new") % news if news > 0 else "")


## Friend requests and open invites: the number on the FRIENDS button.
func _news() -> int:
	var n := service.pending_invites().size()
	for f in service.friends:
		if f.state == OnlineRules.RECEIVED:
			n += 1
	return n


func _show_host() -> void:
	var v := _page(VIEW_HOST, "Which world?", &"")
	var sandbox := OnlineUi.button("SANDBOX", UiKit.GREEN, Vector2(360, 150))
	sandbox.pressed.connect(func() -> void: host_requested.emit(ModeRules.SANDBOX))
	var survivor := OnlineUi.button("SURVIVOR", UiKit.RED, Vector2(360, 150))
	survivor.pressed.connect(func() -> void: host_requested.emit(ModeRules.SURVIVOR))
	v.add_child(OnlineUi.row([sandbox, survivor], 28))
	v.add_child(OnlineUi.words("Then invite friends from the pause menu.", 26))
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(300, 80))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_home)
	v.add_child(back)


func _show_friends() -> void:
	var panel := OnlineFriendsPanel.new()
	panel.service = service
	panel.closed.connect(_show_home)
	panel.join_requested.connect(func(match_id: String) -> void: join_requested.emit(match_id))
	_set_page(VIEW_FRIENDS, panel)


# --- Helpers ---

func _check_consent() -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.check_consent()
	_busy = false
	if not is_inside_tree():
		return
	if err != "":
		message.text = err
	elif service.screen() == OnlineRules.SCREEN_WAIT_GROWNUP:
		message.text = "Not yet. A grown-up can tap GROWN-UPS."
	else:
		route()


## A page of this screen's own: a title with a picture, then its words and buttons.
func _page(id: StringName, title: String, icon: StringName) -> VBoxContainer:
	var v := OnlineUi.column(20)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 16)
	if icon != &"":
		var pic := OnlineIcon.new(icon)
		pic.custom_minimum_size = Vector2(72, 72)
		head.add_child(pic)
	head.add_child(UiKit.title(title))
	v.add_child(head)
	_set_page(id, v)
	message = OnlineUi.words("", 24)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	v.add_child(message)
	return v


func _back_row(others: Array) -> HBoxContainer:
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(260, 90))
	back.pressed.connect(func() -> void: closed.emit())
	return OnlineUi.row(others + [back], 24)


func _set_page(id: StringName, control: Control) -> void:
	OnlineUi.clear(self)
	view = id
	page = control
	add_child(control)


func _on_account_changed() -> void:
	# A grown-up's approval (notification 103) moves a waiting child on by itself.
	if view == OnlineRules.SCREEN_WAIT_GROWNUP and not _busy and service.screen() != view:
		route()


func _on_invite_received(_invite: Dictionary) -> void:
	_update_news()


func _on_status_changed(status: StringName) -> void:
	if view in [VIEW_GROWNUPS, VIEW_KEY, VIEW_MOVE, VIEW_ACCOUNTS, VIEW_LOG_IN, VIEW_PASSWORD]:
		return   # M4 G: the grown-up area says so itself; decided when it closes (_on_grownups_closed). Owner #67:
		# signing in with a key signs out and in again, and its page says what went wrong. Owner #99: so do a move,
		# LOG OUT (it signs in to save) and a switch of players
	if status == OnlineService.OFFLINE and view not in [VIEW_CONNECTING, VIEW_FAILED, &""]:
		_show_failed(OnlineRules.message("network"))

# --- M4 Task 8b, agent G: the grown-up area deleted the online account ---
# The grown-up keeps seeing the area (it says it worked; deleting signs out, which is not a network
# failure); when it closes, PLAY ONLINE closes too: its pages belonged to the deleted account, and
# signing in again would make a new one.

var _deleted := false


func _on_account_deleted() -> void:
	_deleted = true


func _on_grownups_closed() -> void:
	if _deleted:
		closed.emit()
	elif service.status != OnlineService.ONLINE:
		_show_failed(OnlineRules.message("network"))
	else:
		route()

# --- M4 ghost races: friends' races on this device, offline (spec §17.5) ---
# When PLAY ONLINE can't reach the game, FRIENDS' RACES lists the friends' showcases kept on this device
# (GhostBook: a visit brought them) and a tap visits one to race its ghosts without the server.

## A kept showcase is about to be visited (tests listen; the game goes there when visit_starts).
signal visit_requested(showcase: Dictionary)

const VIEW_RACES := &"races"
const RACES_SHOWN := 6

var visit_starts := true


func _gh_races_button() -> Array:
	if service.kept_showcases().is_empty():
		return []
	var b := OnlineUi.button("FRIENDS'\nRACES", UiKit.ORANGE, Vector2(300, 90), &"visit")
	b.name = "FriendsRaces"
	b.pressed.connect(show_kept_races)
	return [b]


func show_kept_races() -> void:
	var v := _page(VIEW_RACES, "Friends' races", &"visit")
	v.add_child(OnlineUi.words("Race your friends' ghosts, even without the internet!", 26))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	var names := service.ghost_names_shown()
	for s: Dictionary in service.kept_showcases().slice(0, RACES_SHOWN):
		var who := str(s.owner) if names else "A FRIEND"
		var b := OnlineUi.button(who, UiKit.GREEN, Vector2(300, 80))
		b.name = "Races_" + str(s.owner_id)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_gh_race.bind(str(s.owner_id)))
		grid.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	v.add_child(centre)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(260, 90))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: _show_failed(OnlineRules.message("network")))
	v.add_child(back)


func _gh_race(owner_id: String) -> void:
	var showcase := service.kept_showcase(owner_id)
	if showcase.is_empty():
		return
	visit_requested.emit(showcase)
	if visit_starts:
		Session.start_visit(showcase)
