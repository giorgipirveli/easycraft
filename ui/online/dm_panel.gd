class_name DmPanel
extends VBoxContainer
## A chat with one friend (M4 Wave 2, Agent E; spec §5.13, §17.4), opened by TALK on the friends
## page. The messages (a 13+ player's last 30 days come back; nothing is kept with an under-13 player
## in the chat), then the ways to talk: 13+ with text chat type (SEND) or use the QUICK wheel and
## EMOTES; everyone else has QUICK CHAT (the picture wheel) and EMOTES only. A friend's message is a
## button: MUTE (on this device) or REPORT (a person reviews it; they are muted too). Leaving the
## page leaves the chat.

const LIST_HEIGHT := 176.0
const ROW_HEIGHT := 64.0
const THANKS := "Thank you for telling us. A grown-up will look at it."

var service: OnlineService
var friend: Dictionary = {}
var channel_id := ""

var list := VBoxContainer.new()
var message: Label
var field: LineEdit                      # 13+ with text chat only
var wheel := QuickChatWheel.new()
var emotes := EmoteWheel.new()

var _bottom := HBoxContainer.new()
var _layer := CanvasLayer.new()
var _picked: Dictionary = {}             # the message whose MUTE / REPORT shows
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var title := OnlineUi.words(tr("Chat with %s") % str(friend.get("username", "")), 28, 760)
	add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "Messages"
	scroll.custom_minimum_size = Vector2(780, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	add_child(scroll)
	message = OnlineUi.words("", 22, 760)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom.add_theme_constant_override("separation", 14)
	add_child(_bottom)
	_layer.layer = 92   # the wheels over the menu
	add_child(_layer)
	_layer.add_child(wheel)
	_layer.add_child(emotes)
	wheel.chosen.connect(_send_phrase)
	emotes.chosen.connect(_send_emote)
	service.chat_message.connect(_on_message)
	_show_talk()
	_open()


func _open() -> void:
	message.text = "One moment..."
	_set_enabled(false)
	var r: Dictionary = await service.open_dm(str(friend.get("id", "")))
	if not is_inside_tree():
		if r.has("channel_id"):
			service.close_chat(r.channel_id)
		return
	if r.has("error"):
		message.text = r.error
		return
	channel_id = r.channel_id
	message.text = ""
	_set_enabled(true)
	_fill()


func _exit_tree() -> void:
	if channel_id != "" and service:
		service.close_chat(channel_id)
		channel_id = ""


## The messages shown, as lines ("Pip: Hi!").
func lines() -> Array[String]:
	var out: Array[String] = []
	for m in service.messages(channel_id):
		out.append(OnlineChatRules.line(m))
	return out


func _fill() -> void:
	OnlineUi.clear(list)
	var msgs := service.messages(channel_id)
	if msgs.is_empty():
		var hint := "Type a message, or tap QUICK." if field else "Tap QUICK CHAT to say hi!"
		list.add_child(OnlineUi.words(hint, 24, 760))
	for m in msgs:
		list.add_child(_row(m))


func _row(msg: Dictionary) -> Button:
	var b := UiKit.big_button(OnlineChatRules.line(msg), Color(0.2, 0.26, 0.4) if msg.mine else Color(), Vector2(760, ROW_HEIGHT))
	b.add_theme_font_size_override("font_size", 24)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.disabled = not service.can_report(msg)
	b.pressed.connect(_show_message.bind(msg))
	return b


func _on_message(msg: Dictionary) -> void:
	if msg.get("channel_id", "") == channel_id and channel_id != "" and is_inside_tree():
		_fill()


# --- Talking ---

func _show_talk() -> void:
	_picked = {}
	OnlineUi.clear(_bottom)
	field = null
	if service.can_type():
		field = LineEdit.new()
		field.max_length = ChatRules.MAX_LENGTH
		field.placeholder_text = "Say something"
		field.custom_minimum_size = Vector2(330, 80)
		field.add_theme_font_size_override("font_size", 26)
		field.text_submitted.connect(func(_t: String) -> void: _send_typed())
		_bottom.add_child(field)
		_bottom.add_child(_button("SEND", UiKit.GREEN, Vector2(150, 80), _send_typed))
		_bottom.add_child(_button("QUICK", OnlineUi.PURPLE, Vector2(150, 80), wheel.open))
	else:
		_bottom.add_child(_button("QUICK CHAT", OnlineUi.PURPLE, Vector2(330, 86), wheel.open, &"talk"))
	_bottom.add_child(_button("EMOTES", UiKit.BLUE, Vector2(180, 80 if field else 86), _open_emotes))
	_set_enabled(channel_id != "")


func _open_emotes() -> void:
	emotes.open(Profile.data.avatar.emotes)


func _send_typed() -> void:
	if field == null or _busy:
		return
	var text := field.text
	var err := await _act(service.send_text.bind(channel_id, text))
	if err == "" and field:
		field.text = ""


func _send_phrase(phrase: String) -> void:
	await _act(service.send_phrase.bind(channel_id, phrase))


func _send_emote(emote: StringName) -> void:
	await _act(service.send_emote.bind(channel_id, emote))


## Runs a send; its words (or nothing) under the messages.
func _act(action: Callable) -> String:
	_busy = true
	var err: String = await action.call()
	_busy = false
	if is_inside_tree():
		message.text = err
	return err


# --- MUTE and REPORT from a message ---

func _show_message(msg: Dictionary) -> void:
	if not service.can_report(msg):
		return
	_picked = msg
	OnlineUi.clear(_bottom)
	var what := OnlineUi.words(OnlineChatRules.line(msg), 24, 300)
	what.clip_text = true
	_bottom.add_child(what)
	_bottom.add_child(_button("MUTE", Color(), Vector2(150, 80), _mute))
	_bottom.add_child(_button("REPORT", UiKit.ORANGE, Vector2(170, 80), _show_reasons, &"flag"))
	_bottom.add_child(_button("OK", UiKit.BLUE, Vector2(150, 80), _show_talk))


func _show_reasons() -> void:
	OnlineUi.clear(_bottom)
	for reason: String in OnlineService.REPORT_REASONS:
		var b := _button(OnlineFriendsPanel.REASONS[reason], UiKit.ORANGE, Vector2(190, 96), _report.bind(reason))
		b.add_theme_font_size_override("font_size", 24)
		_bottom.add_child(b)
	message.text = "What happened?"


func _mute() -> void:
	service.mute_sender(_picked)
	_show_talk()
	_fill()


func _report(reason: String) -> void:
	var msg := _picked
	_show_talk()
	message.text = "One moment..."
	var err: String = await service.report_message(msg, reason)
	if not is_inside_tree():
		return
	message.text = err if err != "" else THANKS
	_fill()


func _button(text: String, color: Color, min_size: Vector2, action: Callable, icon: StringName = &"") -> Button:
	var b := OnlineUi.button(text, color, min_size, icon)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(action)
	return b


func _set_enabled(on: bool) -> void:
	for b in _bottom.find_children("*", "Button", true, false):
		(b as Button).disabled = not on
	if field:
		field.editable = on
