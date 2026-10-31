class_name GrownUpsPanel
extends VBoxContainer
## The grown-up area behind the parent gate (M4 Wave 1, Agent C; M4 Wave 2, agent F: spec §5.14,
## §17.2), from PLAY ONLINE's "Ask a grown-up" and from SETTINGS. Three pages and DONE:
## - ONLINE PLAY: the consent state; for an under-13 player without verified consent START asks
##   the server to start verifiable parental consent (the fake provider in developer builds; a real
##   provider's page opens in the browser), then CHECK; with consent (or for 13+): online play ON /
##   OFF and the chat setting (never free text for under-13), saved on the server.
## - FRIEND REQUESTS: an under-13 player's friend requests wait here for a YES or NO (approve_friend).
## - PLAY & PHOTOS (PLAY TIME before M5 store readiness F1): today's play time, counted on this device only
##   (PlayClock), and the photo sharing switch (photo mode's SHARE; PhotoRules.may_share), saved in the profile.
## - DELETE MY ONLINE ACCOUNT (M4 Task 8b, agent G), from ONLINE PLAY: DeleteAccountPage.
## - SHOP (owner #35, spec §18): EasyCraft Plus, the packs, the child's wish list (ShopPage); works offline.
## - PRIVACY (M5 Task 4; Play's User Data policy wants the privacy policy inside the app): the trust promise
##   (docs/store/trust-promise.md) and buttons that open the privacy policy and the deletion page on the game's own
##   server (OnlineConfig.privacy_url); from the title row, on every page; works offline.
## Signs in by itself when opened from SETTINGS, but only on a device that has an online account
## (agent G: never makes one, e.g. right after it was deleted). The words are for grown-ups, so they
## may be longer.

signal closed

const CHAT_WORDS := {OnlineRules.CHAT_OFF: "OFF", OnlineRules.CHAT_QUICK: "QUICK", OnlineRules.CHAT_FILTERED: "TEXT"}
const PAGE_ONLINE := &"online"
const PAGE_FRIENDS := &"friends"
const PAGE_TIME := &"time"
const PAGE_DELETE := &"delete"   # M4 G: from ONLINE PLAY
const PAGE_SHOP := &"shop"       # Owner 35: EasyCraft Plus, packs, the child's wish list (ShopPage)
const PAGE_PRIVACY := &"privacy" # M5 Task 4: the trust promise and the privacy policy
const PAGE_KEY := &"key"         # owner #67: OTHER DEVICES, from ONLINE PLAY (AccountKeyPage)
const PAGE_PASSWORD := &"password"   # owner #105: CHANGE PASSWORD, from ONLINE PLAY (PasswordPage, a grown-up's)
## M5 Task 4: the trust promise (docs/store/trust-promise.md, spec §16), one short line each; every line stays
## true in every release (the whole-game review checks them).
const PROMISE: Array[String] = ["No ads, not now and not later.", "Nothing random for money.",
	"No streaks and no guilt.", "Private by default.", "Your child's data stays small.", "People review every report."]
const MAX_ROWS := 3   # friend requests on the page at once (the next shows after an answer)
## The tabs' height and words (M5 Task 4: 72 px and 26 px before the title row got PRIVACY; the SHOP pages fill the
## panel to the pixel, and a 26 px word makes a 64 px tab taller again).
const TAB_HEIGHT := 64
const TAB_FONT := 22

var service: OnlineService
## Owner 35: the shop the SHOP page uses (default: Session.shop(); tests set one).
var shop: ShopService
## M4 G: whether this game plays in an online world now (DeleteAccountPage; default Session.is_online()).
var in_online_world := Callable()
## Opens the provider's page (OS.shell_open; tests record it instead).
var open_url := func(url: String) -> void: OS.shell_open(url)
## Today's minutes of play on this device (tests set one).
var play_minutes := Callable()

var page: StringName = PAGE_ONLINE
var content: VBoxContainer
var message: Label
var start_button: Button
var check_button: Button
var save_button: Button
var done_button: Button
var online_buttons := {}   # true / false -> Button
var chat_buttons := {}     # chat setting -> Button
var tab_buttons := {}      # page -> Button
var photo_buttons := {}    # M5 F1: photo sharing on (true) / off (false) -> Button

var _online := false
var _chat := OnlineRules.CHAT_OFF
var _busy := false
var _connect_error := ""


func _ready() -> void:
	add_theme_constant_override("separation", 10)   # M5 Task 4: 14 before PRIVACY's title row took 17 px
	_show()


func needs_consent() -> bool:
	var acct := service.account
	return acct.get("age_band") != AgeBand.TEEN_PLUS and acct.get("consent") != OnlineRules.CONSENT_VERIFIED


## Builds the area on the current page.
func _show() -> void:
	OnlineUi.clear(self)
	tab_buttons.clear()
	add_child(_title_row())   # M5 Task 4: the title and PRIVACY
	var tabs: Array = []
	for p: StringName in [PAGE_ONLINE, PAGE_FRIENDS, PAGE_TIME, PAGE_SHOP]:
		var words: String = {PAGE_ONLINE: "ONLINE PLAY", PAGE_FRIENDS: "FRIEND REQUESTS", PAGE_TIME: "PLAY & PHOTOS",
			PAGE_SHOP: "SHOP"}[p]   # M5 F1: PLAY TIME holds the photo sharing switch too
		var b := OnlineUi.button(words, Color(), Vector2({PAGE_FRIENDS: 300, PAGE_SHOP: 170}.get(p, 240), TAB_HEIGHT))
		b.add_theme_font_size_override("font_size", TAB_FONT)
		b.toggle_mode = true
		b.pressed.connect(show_page.bind(p))
		tab_buttons[p] = b
		tabs.append(b)
	done_button = OnlineUi.button("DONE", UiKit.BLUE, Vector2(200, TAB_HEIGHT))
	done_button.add_theme_font_size_override("font_size", TAB_FONT)
	done_button.pressed.connect(func() -> void: closed.emit())
	tabs.append(done_button)
	add_child(OnlineUi.row(tabs, 14))
	content = OnlineUi.column(14)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)
	message = OnlineUi.words("", 24, 1000)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	show_page(page)


func show_page(p: StringName) -> void:
	page = p
	for key: StringName in tab_buttons:
		(tab_buttons[key] as Button).set_pressed_no_signal(key == p)
	OnlineUi.clear(content)
	online_buttons.clear()
	chat_buttons.clear()
	photo_buttons.clear()
	start_button = null
	check_button = null
	save_button = null
	message.text = ""
	if p == PAGE_TIME:
		_time_view()
	elif p == PAGE_PRIVACY:
		_privacy_view()   # M5 Task 4: needs no online account
	elif p == PAGE_SHOP:
		_shop_view()   # Owner 35: needs no online account
	elif _online_ready():
		if p == PAGE_ONLINE:
			content.add_child(_line(_consent_words()))
			if needs_consent():
				_consent_view()
			else:
				_settings_view()
			content.add_child(_account_row())   # M4 G: DELETE; owner #67: OTHER DEVICES
		elif p == PAGE_DELETE:
			_delete_view()
		elif p == PAGE_KEY:
			_key_view()   # owner #67
		elif p == PAGE_PASSWORD:
			_password_view()   # owner #105
		else:
			_friends_view()


# --- Signing in (from SETTINGS the service may not be online yet) ---

## True when signed in; otherwise the page says why not (or signs in, then shows itself again).
func _online_ready() -> bool:
	if not service.has_server():
		content.add_child(_line(OnlineRules.message("no_server")))
		return false
	if service.status == OnlineService.ONLINE:
		return true
	if not service.has_online_link():   # M4 G: signing in would make a new account
		content.add_child(_line("This device has no online account. Online play starts from PLAY ONLINE."))
		return false
	if _connect_error != "":
		content.add_child(_line(_connect_error))
		var again := OnlineUi.button("TRY AGAIN", UiKit.GREEN, Vector2(300, 80))
		again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		again.pressed.connect(func() -> void:
			_connect_error = ""
			show_page(page))
		content.add_child(again)
		return false
	content.add_child(_line("Connecting..."))
	_connect()
	return false


func _connect() -> void:
	if _busy:
		return
	_busy = true
	var err: String = await service.sign_in()
	_busy = false
	if not is_inside_tree():
		return
	_connect_error = err
	show_page(page)


# --- ONLINE PLAY ---

func _consent_words() -> String:
	if service.account.get("age_band") == AgeBand.TEEN_PLUS:
		return "13 or older: no parental consent needed."
	match service.account.get("consent"):
		OnlineRules.CONSENT_VERIFIED:
			return "Parental consent: given."
		OnlineRules.CONSENT_PENDING:
			return "Parental consent: waiting for you."
	return "Parental consent: not asked yet."


func _consent_view() -> void:
	var pending: bool = service.account.get("consent") == OnlineRules.CONSENT_PENDING
	content.add_child(OnlineUi.words("Your child wants to play online with friends. First we check that you are their parent or guardian.", 26, 1000))
	start_button = OnlineUi.button("START", UiKit.GREEN, Vector2(260, 86))
	start_button.pressed.connect(_start)
	check_button = OnlineUi.button("CHECK", UiKit.ORANGE, Vector2(260, 86))
	check_button.pressed.connect(_check)
	check_button.disabled = not pending
	content.add_child(OnlineUi.row([start_button, check_button]))
	if pending:
		message.text = "When you have finished, tap CHECK."
	elif not bool(service.account.get("consent_available", true)):
		start_button.disabled = true   # no verification provider on this server yet (§17.2)
		message.text = OnlineRules.message("no_provider")


func _settings_view() -> void:
	_online = bool(service.account.get("online_allowed", false))
	_chat = str(service.account.get("chat", OnlineRules.CHAT_OFF))
	var online_row: Array = [_row_label("Online play")]
	for on: bool in [true, false]:
		var b := _toggle("ON" if on else "OFF")
		b.pressed.connect(func() -> void:
			_online = on
			_refresh_toggles())
		online_buttons[on] = b
		online_row.append(b)
	content.add_child(OnlineUi.row(online_row))
	var chat_row: Array = [_row_label("Chat")]
	for c: String in OnlineRules.chat_choices(AgeBand.effective(StringName(str(service.account.get("age_band", ""))))):
		var b := _toggle(CHAT_WORDS[c])
		b.pressed.connect(func() -> void:
			_chat = c
			_refresh_toggles())
		chat_buttons[c] = b
		chat_row.append(b)
	save_button = OnlineUi.button("SAVE", UiKit.GREEN, Vector2(200, 76))
	save_button.pressed.connect(_save)
	chat_row.append(save_button)
	content.add_child(OnlineUi.row(chat_row))
	_refresh_toggles()


func _row_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(220, 0)
	l.add_theme_font_size_override("font_size", 28)
	return l


func _line(text: String) -> Label:
	return OnlineUi.words(text, 28, 1000)


func _toggle(text: String) -> Button:
	var b := OnlineUi.button(text, Color(), Vector2(160, 76))
	b.toggle_mode = true
	return b


func _refresh_toggles() -> void:
	for on: bool in online_buttons:
		(online_buttons[on] as Button).set_pressed_no_signal(on == _online)
	for c: String in chat_buttons:
		(chat_buttons[c] as Button).set_pressed_no_signal(c == _chat)


func _start() -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var r: Dictionary = await service.start_consent()
	_busy = false
	if not is_inside_tree():
		return
	if r.text != "":
		message.text = r.text
		return
	if r.url != "":
		open_url.call(r.url)
		message.text = "A page opened. Finish there, then tap CHECK."
	else:
		message.text = "When you have finished, tap CHECK."
	check_button.disabled = false


func _check() -> void:
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
	elif service.account.get("consent") == OnlineRules.CONSENT_NONE:
		check_button.disabled = true   # the provider said no, or the request ran out
		message.text = "Consent was not given. You can START again."
	elif needs_consent():
		message.text = "Not finished yet. Tap CHECK again when you are done."
	else:
		_show()
		message.text = "Thank you! Online play is on." if bool(service.account.get("online_allowed", false)) \
			else "Thank you! You can switch online play on here."


func _save() -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.set_parent_settings(_online, _chat)
	_busy = false
	if is_inside_tree():
		message.text = err if err != "" else "Saved!"


# --- FRIEND REQUESTS (under-13, §17.2) ---

func _friends_view() -> void:
	if service.account.get("age_band") == AgeBand.TEEN_PLUS:
		content.add_child(_line("Players 13 and older add friends themselves."))
		return
	content.add_child(_line("Loading..."))
	_load_requests()


func _load_requests() -> void:
	if _busy:
		return
	_busy = true
	var r: Dictionary = await service.friend_approvals()
	_busy = false
	if not is_inside_tree() or page != PAGE_FRIENDS:
		return
	OnlineUi.clear(content)
	if r.text != "":
		content.add_child(_line(r.text))
		return
	var list: Array = r.requests
	if list.is_empty():
		content.add_child(_line("No friend requests are waiting."))
		return
	content.add_child(_line("Say YES only to friends your child knows."))
	for i in mini(list.size(), MAX_ROWS):
		content.add_child(_request_row(list[i]))
	if list.size() > MAX_ROWS:
		content.add_child(_line(tr("%d more after these.") % (list.size() - MAX_ROWS)))


func _request_row(r: Dictionary) -> HBoxContainer:
	var me := service.profile.username
	var words := tr("%s wants to be friends with %s") % ([r.username, me] if r.direction == "in" else [me, r.username])
	var label := Label.new()
	label.text = words
	label.custom_minimum_size = Vector2(640, 0)
	label.add_theme_font_size_override("font_size", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var yes := OnlineUi.button("YES", UiKit.GREEN, Vector2(160, 70))
	yes.pressed.connect(_answer.bind(r, true))
	var no := OnlineUi.button("NO", UiKit.RED, Vector2(160, 70))
	no.pressed.connect(_answer.bind(r, false))
	var row := OnlineUi.row([label, yes, no])
	row.name = "Request_" + str(r.username)
	return row


func _answer(r: Dictionary, yes: bool) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.approve_friend(r.user_id, yes)
	_busy = false
	if not is_inside_tree():
		return
	var me := service.profile.username
	if err != "":
		message.text = err
	elif not yes:
		message.text = tr("%s's request was declined.") % r.username
	elif r.direction == "in":
		message.text = tr("%s and %s are friends now.") % [me, r.username]
	else:
		message.text = tr("%s gets a friend request now.") % r.username
	var said := message.text
	await _load_requests()
	if is_inside_tree():
		message.text = said


# --- PLAY TIME (§5.14 parent corner) ---

func _time_view() -> void:
	var minutes := int(play_minutes.call()) if play_minutes.is_valid() else Session.play_minutes_today()
	var today := OnlineUi.words(tr("Played today: %s") % PlayTime.words(minutes).to_lower(), 34, 1000)
	if minutes <= 0:
		today.text = "Played today: less than a minute"
	content.add_child(today)
	content.add_child(_line("Counted on this device only, while the game is open. It never leaves the device."))
	_photo_view()   # M5 F1
	_crystals_view()   # owner #132 (W1)


# --- Owner #132 (W1): discovery crystals, a grown-up's switch beside play time and photos ---

var crystal_buttons := {}   # on (true) / off (false) -> Button


## "Discovery crystals" ON / OFF: a glowing crystal with a short number game now and then while the child plays a home
## world (DiscoveryCrystalRules). On unless a grown-up turns it off; saved at once in the profile's settings.
func _crystals_view() -> void:
	crystal_buttons.clear()
	var row: Array = [_row_label("Discovery crystals")]
	for on: bool in [true, false]:
		var b := _toggle("ON" if on else "OFF")
		b.pressed.connect(_set_crystals.bind(on))
		crystal_buttons[on] = b
		row.append(b)
	content.add_child(OnlineUi.row(row))
	_refresh_crystals()


func _set_crystals(on: bool) -> void:
	_photo_profile().settings[DiscoveryCrystalRules.SETTING] = on
	if service.profile != null and service.save_profile.is_valid():
		service.save_profile.call()
	else:
		Profile.save()
	_refresh_crystals()
	message.text = ("Discovery crystals are on: a short number game now and then while playing." if on
		else "Discovery crystals are off.")


func _refresh_crystals() -> void:
	var on := DiscoveryCrystalRules.switched_on(_photo_profile().settings)
	for key: bool in crystal_buttons:
		(crystal_buttons[key] as Button).set_pressed_no_signal(key == on)


# --- M5 store readiness F1: photo sharing (spec §5.14), this phone's switch beside play time ---

## "Photo sharing" ON / OFF: SHARE in photo mode (the phone's share sheet). It shows the switch's effect (from the
## band until a grown-up picks one) and saves a choice at once in the profile; no online account needed.
func _photo_view() -> void:
	var row: Array = [_row_label("Photo sharing")]
	for on: bool in [true, false]:
		var b := _toggle("ON" if on else "OFF")
		b.pressed.connect(_set_photo_share.bind(on))
		photo_buttons[on] = b
		row.append(b)
	content.add_child(OnlineUi.row(row))
	var hint := OnlineUi.words("ON: photo mode can SHARE a photo to other apps. OFF: photos are only saved on this device.",
		24, 1000)
	hint.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	content.add_child(hint)
	_refresh_photo()


func _set_photo_share(on: bool) -> void:
	_photo_profile().photo_share = PhotoRules.SHARE_ON if on else PhotoRules.SHARE_OFF
	if service.profile != null and service.save_profile.is_valid():
		service.save_profile.call()
	else:
		Profile.save()
	_refresh_photo()
	message.text = "Photo sharing is on." if on else "Photo sharing is off. Photos are only saved on this device."


func _refresh_photo() -> void:
	var p := _photo_profile()
	var on := PhotoRules.may_share(p.age_band, p.photo_share)
	for key: bool in photo_buttons:
		(photo_buttons[key] as Button).set_pressed_no_signal(key == on)


## The profile the switch lives in: the service's (the Profile autoload's object in the game; tests give their own),
## or the autoload's while the service has not started.
func _photo_profile() -> ProfileData:
	return service.profile if service.profile != null else Profile.data


# --- M4 Task 8b, agent G: DELETE MY ONLINE ACCOUNT (spec §5.14, §17.2) ---

func _delete_button() -> Button:
	var b := OnlineUi.button("DELETE MY ONLINE ACCOUNT", Color(), Vector2(460, 72))
	b.add_theme_font_size_override("font_size", 22)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(show_page.bind(PAGE_DELETE))
	return b


func _delete_view() -> void:
	var page := DeleteAccountPage.new()
	page.service = service
	page.in_online_world = in_online_world
	page.closed.connect(show_page.bind(PAGE_ONLINE))
	content.add_child(page)


# --- Owner #67: OTHER DEVICES (the account on every device: the sign-in key) ---

## ONLINE PLAY's last row: OTHER DEVICES (a claimed account only: there is a name to sign in to) and DELETE.
func _account_row() -> Control:
	if not service.claimed():
		return _delete_button()
	var b := OnlineUi.button("OTHER DEVICES", UiKit.GREEN, Vector2(260, 72))
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(show_page.bind(PAGE_KEY))
	var pw := OnlineUi.button("CHANGE PASSWORD", UiKit.ORANGE, Vector2(300, 72))   # owner #105: FORGOT PASSWORD's way
	pw.name = "ChangePassword"
	pw.add_theme_font_size_override("font_size", 22)
	pw.pressed.connect(show_page.bind(PAGE_PASSWORD))
	return OnlineUi.row([b, pw, _delete_button()], 18)


## Owner #105: CHANGE PASSWORD (a grown-up's): the old one, or empty: a key made on this device proves it's them.
func _password_view() -> void:
	var page := PasswordPage.new()
	page.service = service
	page.mode = PasswordPage.Mode.MAKE if service.has_password == 0 else PasswordPage.Mode.GROWN_UP
	page.compact = true   # under the area's tabs
	page.message = message   # its words in the area's line below
	page.done.connect(show_page.bind(PAGE_ONLINE))
	page.closed.connect(show_page.bind(PAGE_ONLINE))
	content.add_child(page)


func _key_view() -> void:
	var page := AccountKeyPage.new()
	page.service = service
	page.closed.connect(show_page.bind(PAGE_ONLINE))
	content.add_child(page)


# --- Owner 35: SHOP (spec §18): EasyCraft Plus, the packs, the child's wish list, behind the parent gate ---

func _shop_view() -> void:
	var page := ShopPage.new()
	page.shop = shop if shop else Session.shop()
	content.add_child(page)


# --- M5 Task 4: PRIVACY (Play's User Data policy: the privacy policy inside the app; spec §16's trust promise) ---

## "For grown-ups" with PRIVACY at its right, so the privacy page is one tap from every page (the tab row is full).
func _title_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var title := UiKit.title("For grown-ups", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var b := OnlineUi.button("PRIVACY", Color(), Vector2(190, 64))
	b.add_theme_font_size_override("font_size", 24)
	b.toggle_mode = true
	b.pressed.connect(show_page.bind(PAGE_PRIVACY))
	tab_buttons[PAGE_PRIVACY] = b
	row.add_child(b)
	return row


func _privacy_view() -> void:
	content.add_child(OnlineUi.words("Our promise to kids and parents", 30, 1000))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 6)
	for line: String in PROMISE:
		var l := OnlineUi.words(line, 24, 580)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(l)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	var buttons: Array = []
	for pair: Array in [["PRIVACY POLICY", OnlineConfig.privacy_url()], ["DELETING DATA", OnlineConfig.delete_account_url()]]:
		var url: String = pair[1]
		if url == "":
			continue   # no server yet: nothing to open
		var b := OnlineUi.button(pair[0], UiKit.BLUE, Vector2(300, 72))
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(func() -> void: open_url.call(url))
		buttons.append(b)
	if not buttons.is_empty():
		content.add_child(OnlineUi.row(buttons, 18))
	content.add_child(_line(tr("Questions or requests: %s") % OnlineConfig.SUPPORT_EMAIL))
