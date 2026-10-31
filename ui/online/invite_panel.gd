class_name InvitePanel
extends VBoxContainer
## The pause menu's INVITE page for the host of an online world (M4 Wave 1, Agent C; spec §17.3):
## the friends online now, each with INVITE, and how many players the world has (4 at most). The
## server checks friendship, consent and the cap again and lets only invited players join.

signal closed

const LIST_HEIGHT := 250.0

var service: OnlineService
var match_id := ""
var world_name := ""
## () -> int: players in this world now (the host too).
var players := func() -> int: return 1

var players_label: Label
var message: Label
var list := VBoxContainer.new()
var back_button: Button

var _invited: Array[String] = []
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	add_child(UiKit.title("Invite friends"))
	players_label = OnlineUi.words("", 26, 560)
	add_child(players_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	add_child(scroll)
	message = OnlineUi.words("", 24, 560)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(300, 80))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(back_button)
	service.friends_changed.connect(_fill)
	_fill()
	_refresh()


func _refresh() -> void:
	await service.refresh_friends()


func _fill() -> void:
	if not is_inside_tree():
		return
	var n := int(players.call())
	players_label.text = tr("Players: %d of %d") % [n, OnlineRules.MAX_PLAYERS]
	OnlineUi.clear(list)
	var online := service.friends_online()
	if online.is_empty():
		list.add_child(OnlineUi.words("No friends online right now.", 26, 600))
	for f in online:
		var row := HBoxContainer.new()
		row.name = "Friend_" + str(f.username)
		row.add_theme_constant_override("separation", 14)
		var dot := OnlineDot.new(true)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var name_label := Label.new()
		name_label.text = str(f.username)
		name_label.add_theme_font_size_override("font_size", 30)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var done := _invited.has(f.id)
		var b := OnlineUi.button("INVITED" if done else "INVITE", OnlineUi.PURPLE, Vector2(200, 72))
		b.name = "Invite"
		b.disabled = done or not OnlineRules.can_invite(n)
		b.pressed.connect(_invite.bind(f))
		row.add_child(b)
		list.add_child(row)
	if not OnlineRules.can_invite(n):
		message.text = OnlineRules.message("full")


func _invite(f: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.invite(f.id, match_id, world_name)
	_busy = false
	if not is_inside_tree():
		return
	if err == "":
		_invited.append(f.id)
	_fill()
	message.text = tr("Invited %s!") % f.username if err == "" else err
