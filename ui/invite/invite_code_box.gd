class_name InviteCodeBox
extends VBoxContainer
## Owner #79 (spec §25.2): "Did a friend give you an invite code?" A new player types a friend's (or a class or family)
## code at the start (after the name) or once in SETTINGS; the web page's ?invite= fills it in. OK signs in (a code needs
## the server), claims the child's own name when it is free (the friend is told their guide's name), and uses the code:
## the welcome words, or kind words about a code that didn't work. Without the internet the code waits in the profile
## and goes up at the next sign-in. NO CODE (at the start) or BACK (in SETTINGS) goes on: nothing is ever required.

signal done(result: Dictionary)   # use_invite's answer, or {"skipped": true}

const PLACEHOLDER := "BLUE-OTTER-42"
const HOW := "It looks like BLUE-OTTER-42. A code is all it needs: no names, no numbers."

var service: OnlineService
var prefill := ""
## At the start (NO CODE) or in SETTINGS (BACK).
var at_start := true
var edit := LineEdit.new()
var message: Label
var ok_button: Button
var skip_button: Button
var continue_button: Button
var _busy := false
var _result := {}


func _ready() -> void:
	name = "InviteCodeBox"
	add_theme_constant_override("separation", 18)
	add_child(ReadAloud.with_speaker(UiKit.title(InviteRules.TYPE_CODE_WORDS, 40), self))
	add_child(OnlineUi.words(HOW, 24, 900))
	edit.name = "CodeEdit"
	edit.max_length = InviteRules.MAX_TYPED
	edit.placeholder_text = PLACEHOLDER
	edit.custom_minimum_size = Vector2(560, 84)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	edit.text = prefill
	edit.text_changed.connect(func(_t: String) -> void: _refresh())
	edit.text_submitted.connect(func(_t: String) -> void: if not ok_button.disabled: check())
	add_child(edit)
	message = OnlineUi.words("", 26, 900)
	message.name = "Message"
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	skip_button = OnlineUi.button("NO CODE" if at_start else "BACK", UiKit.BLUE, Vector2(260, 84))
	skip_button.pressed.connect(func() -> void: done.emit({"skipped": true}))
	ok_button = OnlineUi.button("OK", UiKit.GREEN, Vector2(240, 84))
	ok_button.pressed.connect(check)
	continue_button = OnlineUi.button("CONTINUE", UiKit.GREEN, Vector2(300, 84))
	continue_button.visible = false
	continue_button.pressed.connect(func() -> void: done.emit(_result))
	add_child(OnlineUi.row([skip_button, ok_button, continue_button]))
	_refresh()
	if PlatformRules.keyboard_first(PlatformRules.current()):   # owner #84: a PC types at once
		edit.grab_focus.call_deferred()


func _refresh() -> void:
	ok_button.disabled = _busy or not InviteRules.looks_like_code(edit.text)


## OK: signs in when it can, claims the child's own name when it is free, and uses the code.
func check() -> void:
	if _busy or not InviteRules.looks_like_code(edit.text):
		return
	_busy = true
	_refresh()
	message.text = "Checking the code..."
	if service.status != OnlineService.ONLINE and service.has_server():
		await service.sign_in()   # a failure keeps the code waiting (use_invite)
	if service.status == OnlineService.ONLINE and not service.claimed() \
			and UsernameRules.validate(service.profile.username) == "":
		await service.claim_username(service.profile.username)   # taken: the friend sees "a new friend" until one is claimed
	var r := await service.use_invite(edit.text)
	_busy = false
	if not is_inside_tree():
		return
	message.text = str(r.get("text", ""))
	if r.get("ok", false) or r.get("waiting", false):
		_result = r
		message.add_theme_color_override("font_color", SchoolUi.GOLD if r.get("ok", false) else OnlineUi.HINT_COLOR)
		edit.editable = false
		ok_button.visible = false
		skip_button.visible = false
		continue_button.visible = true
		Audio.play(&"jingle_badge" if r.get("ok", false) else &"ui_click")
		ReadAloud.auto(message.text)
	_refresh()
