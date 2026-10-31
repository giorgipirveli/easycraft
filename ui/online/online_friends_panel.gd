class_name OnlineFriendsPanel
extends VBoxContainer
## PLAY ONLINE's FRIENDS page (M4 Wave 1, Agent C; spec §17.3): add a friend by their exact
## username, friend requests (YES / NO), the friends list with online dots, JOIN for a friend whose
## invite is open, and per friend MUTE (on this device), BLOCK (removes and blocks) and REPORT
## (a person reviews it). Nothing here shows unless the service allows social play.
## M4 Wave 3, agent I: GIFT and VISIT on a friend's row, PRESENTS and MY SHOWCASE beside ADD.

signal closed
signal join_requested(match_id: String)

const REFRESH_SECONDS := 15.0
const LIST_HEIGHT := 220.0
const LIST_WIDTH := 1100.0          # M4 I: a friend's row holds TALK, GIFT, VISIT and MORE (and JOIN)
const ROW_BUTTON := Vector2(135, 70)
## Report reasons in a child's words ("secrets": the stay-safe card's word for name, home, school).
const REASONS := {OnlineService.REPORT_MEAN: "MEAN WORDS", OnlineService.REPORT_SCARY: "SCARY",
	OnlineService.REPORT_SECRETS: "ASKED\nSECRETS", OnlineService.REPORT_OTHER: "SOMETHING\nELSE"}

var service: OnlineService

var name_edit := LineEdit.new()
var add_button: Button
var message: Label
var list := VBoxContainer.new()
var back_button: Button
## The friend whose MUTE / BLOCK / REPORT page is open ({} on the list).
var picked: Dictionary = {}

var _body := VBoxContainer.new()
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(UiKit.title("Friends"))
	add_child(_body)
	_body.add_theme_constant_override("separation", 12)
	message = OnlineUi.words("", 24, 760)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(300, 80))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back)
	add_child(back_button)
	service.friends_changed.connect(_on_friends_changed)
	service.invite_received.connect(_on_invite_received)
	service.gifts_changed.connect(_i_update_mail)   # M4 I
	var timer := Timer.new()
	timer.wait_time = REFRESH_SECONDS
	timer.autostart = true
	timer.timeout.connect(_refresh)
	add_child(timer)
	show_list()
	_refresh()


func show_list() -> void:
	picked = {}
	_clear_body()
	name_edit.max_length = UsernameRules.MAX_LEN
	name_edit.placeholder_text = "Friend's name"
	name_edit.custom_minimum_size = Vector2(380, 80)
	if not name_edit.text_submitted.is_connected(_on_name_submitted):
		name_edit.text_submitted.connect(_on_name_submitted)
	add_button = OnlineUi.button("ADD", UiKit.GREEN, Vector2(220, 80), &"add_friend")
	add_button.pressed.connect(_add)
	_body.add_child(OnlineUi.row([name_edit, add_button] + _i_mail_buttons()))   # M4 I
	_body.add_child(message)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(LIST_WIDTH, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	_body.add_child(scroll)
	_fill_list()


## The rows of the list, from the service.
func _fill_list() -> void:
	OnlineUi.clear(list)
	if service.friends.is_empty():
		list.add_child(OnlineUi.words("No friends yet. Add one by their name!", 26, 760))
	for f: Dictionary in service.friends:
		list.add_child(_row(f))


func _row(f: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "Friend_" + str(f.username)
	row.add_theme_constant_override("separation", 14)
	var dot := OnlineDot.new(bool(f.online))
	dot.name = "Dot"
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var name_label := Label.new()
	name_label.text = str(f.username)
	name_label.custom_minimum_size = Vector2(200, 0)
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	match f.state:
		OnlineRules.RECEIVED:
			row.add_child(_small_words("wants to be friends"))
			row.add_child(_row_button("YES", UiKit.GREEN, _answer.bind(f.id, true)))
			row.add_child(_row_button("NO", UiKit.RED, _answer.bind(f.id, false)))
		OnlineRules.SENT:
			row.add_child(_small_words("asked"))
		OnlineRules.FRIEND:
			var inv := service.invite_from(f.id)
			if not inv.is_empty():
				row.add_child(_row_button("JOIN", UiKit.GREEN, func() -> void: join_requested.emit(inv.match_id)))
			if service.is_muted(f.id):
				row.add_child(_small_words("muted"))
			elif service.chat_level() != OnlineRules.CHAT_OFF:   # M4 E: chat with this friend
				row.add_child(_row_button("TALK", OnlineUi.PURPLE, show_chat.bind(f)))
			row.add_child(_row_button("GIFT", UiKit.ORANGE, show_gift.bind(f)))   # M4 I
			row.add_child(_row_button("VISIT", UiKit.GREEN, visit.bind(f)))       # M4 I
			row.add_child(_row_button("MORE", UiKit.BLUE, show_friend.bind(f)))
	return row


func _small_words(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	return l


func _row_button(text: String, color: Color, action: Callable) -> Button:
	var b := OnlineUi.button(text, color, ROW_BUTTON)
	b.name = text.capitalize()
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(action)
	return b


## M4 E: the chat with one friend (DmPanel); BACK comes back to the list and leaves the chat.
func show_chat(f: Dictionary) -> void:
	picked = f
	_clear_body()
	var dm := DmPanel.new()
	dm.name = "Chat"
	dm.service = service
	dm.friend = f
	_body.add_child(dm)


## MUTE, BLOCK and REPORT for one friend.
func show_friend(f: Dictionary) -> void:
	picked = f
	_clear_body()
	_body.add_child(OnlineUi.words(str(f.username), 36, 760))
	var muted := service.is_muted(f.id)
	var mute := OnlineUi.button("UNMUTE" if muted else "MUTE", Color(), Vector2(220, 86))
	mute.name = "Mute"
	mute.pressed.connect(func() -> void:
		if service.is_muted(f.id):
			service.unmute(f.id)
		else:
			service.mute(f.id)
		show_friend(f))
	var block := OnlineUi.button("BLOCK", UiKit.RED, Vector2(220, 86))
	block.name = "Block"
	block.pressed.connect(_confirm_block.bind(f))
	var report := OnlineUi.button("REPORT", UiKit.ORANGE, Vector2(220, 86), &"flag")
	report.name = "Report"
	report.pressed.connect(_show_reasons.bind(f))
	_body.add_child(OnlineUi.row([mute, block, report]))
	_body.add_child(OnlineUi.words("MUTE: no invites from them. BLOCK: not friends anymore.", 22, 760))
	_body.add_child(message)


func _confirm_block(f: Dictionary) -> void:
	_clear_body()
	_body.add_child(OnlineUi.words(tr("Block %s? You will not be friends anymore.") % f.username, 30, 760))
	var yes := OnlineUi.button("YES, BLOCK", UiKit.RED, Vector2(280, 86))
	yes.name = "YesBlock"
	yes.pressed.connect(_act.bind(service.block.bind(f.id), ""))
	var no := OnlineUi.button("NO", UiKit.BLUE, Vector2(200, 86))
	no.pressed.connect(show_friend.bind(f))
	_body.add_child(OnlineUi.row([yes, no]))
	_body.add_child(message)


func _show_reasons(f: Dictionary) -> void:
	_clear_body()
	_body.add_child(OnlineUi.words("What happened?", 32, 760))
	var buttons: Array = []
	for reason: String in OnlineService.REPORT_REASONS:
		var b := OnlineUi.button(REASONS[reason], UiKit.ORANGE, Vector2(220, 96))
		b.add_theme_font_size_override("font_size", 26)
		b.name = "Reason_" + reason
		b.pressed.connect(_act.bind(service.report.bind(f.id, reason), "Thank you for telling us. A grown-up will look at it."))
		buttons.append(b)
	_body.add_child(OnlineUi.row(buttons))
	_body.add_child(message)


func _answer(id: String, yes: bool) -> void:
	_act(service.accept.bind(id) if yes else service.decline.bind(id), "")


func _exit_tree() -> void:
	for keep: Control in [message, name_edit]:
		if keep and keep.get_parent() == null:
			keep.free()


func _add() -> void:
	if _busy:
		return
	var typed := name_edit.text
	await _act(service.add_friend.bind(typed), "Asked! They will see it next time they play.")
	if message.text.begins_with("Asked"):
		name_edit.text = ""


func _on_name_submitted(_t: String) -> void:
	_add()


## Runs a service action (-> "" or plain words), then goes back to the list with its words.
func _act(action: Callable, thanks: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await action.call()
	_busy = false
	if not is_inside_tree():
		return
	show_list()
	message.text = err if err != "" else thanks


func _refresh() -> void:
	if is_inside_tree() and not _busy:
		await service.refresh_friends()


## The message and the name field live on across pages (the field keeps what was typed).
func _clear_body() -> void:
	for keep: Control in [message, name_edit]:
		if keep.get_parent():
			keep.get_parent().remove_child(keep)
	OnlineUi.clear(_body)


func _on_invite_received(_invite: Dictionary) -> void:
	_on_friends_changed()


func _on_friends_changed() -> void:
	if picked.is_empty() and is_inside_tree() and not _busy:
		_fill_list()


func _on_back() -> void:
	if picked.is_empty():
		closed.emit()
	elif not _i_page_back():   # M4 I: a page of its own steps back inside itself first
		show_list()

# --- M4 I: gifts and visits (M4 Wave 3, agent I; spec §17.5) ---
# GIFT on a friend's row: a build or a bottle (GiftSendPage). VISIT: the friend's showcase, even while
# they are away (Session.start_visit). Beside ADD: PRESENTS (what friends sent: open, delete, report;
# GiftsPage) and MY SHOWCASE (the stickers visitors left; GuestbookPage).

var presents_button: Button
var showcase_button: Button


func _i_mail_buttons() -> Array:
	presents_button = OnlineUi.button("PRESENTS", UiKit.ORANGE, Vector2(220, 72), &"gift")
	presents_button.name = "Presents"
	presents_button.add_theme_font_size_override("font_size", 20)
	presents_button.pressed.connect(show_presents)
	showcase_button = OnlineUi.button("MY SHOWCASE", OnlineUi.PURPLE, Vector2(240, 72), &"visit")
	showcase_button.name = "MyShowcase"
	showcase_button.add_theme_font_size_override("font_size", 20)
	showcase_button.pressed.connect(show_showcase)
	_i_update_mail()
	return [presents_button, showcase_button]


## PRESENTS says how many wait; MY SHOWCASE how many stickers came while online.
func _i_update_mail() -> void:
	if is_instance_valid(presents_button):
		var n := service.gifts.size()
		presents_button.text = "PRESENTS" + (" (%d)" % n if n > 0 else "")
	if is_instance_valid(showcase_button):
		showcase_button.text = "MY SHOWCASE" + (" (%d)" % service.new_stickers if service.new_stickers > 0 else "")


func show_gift(f: Dictionary) -> void:
	picked = f
	_clear_body()
	var page := GiftSendPage.new()
	page.name = "Gift"
	page.service = service
	page.friend = {"id": f.id, "username": f.username}
	_body.add_child(page)


func show_presents() -> void:
	picked = {"page": "presents"}
	_clear_body()
	var page := GiftsPage.new()
	page.name = "Presents"
	page.service = service
	_body.add_child(page)


func show_showcase() -> void:
	picked = {"page": "showcase"}
	_clear_body()
	var page := GuestbookPage.new()
	page.name = "Showcase"
	page.service = service
	_body.add_child(page)


## VISIT: the friend's showcase in a small world of its own (read-only), even while they are away.
func visit(f: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var r: Dictionary = await service.showcase_of(str(f.id))
	_busy = false
	if not is_inside_tree():
		return
	if r.text != "" or (r.showcase as Dictionary).is_empty():
		message.text = r.text if r.text != "" else GiftRules.message("no_showcase")
		return
	message.text = ""
	visit_requested.emit(r.showcase)
	if visit_starts:
		Session.start_visit(r.showcase)


## A visit is about to start (tests listen; the game goes there when visit_starts).
signal visit_requested(showcase: Dictionary)
var visit_starts := true


## BACK on one of this section's pages: true when the page stepped back inside itself.
func _i_page_back() -> bool:
	for c in _body.get_children():
		if c.has_method(&"back"):
			return bool(c.call(&"back"))
	return false
