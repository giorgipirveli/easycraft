class_name PasswordPage
extends VBoxContainer
## Owner #105 (spec §5.13 "As built (owner #99, #105)"): the account's password. MAKE: right after the name is claimed, or
## asked once of an account that has none ("Make a password so you can play on your other devices.", with LATER), or
## from SETTINGS. CHANGE: the old one and a new one (SETTINGS). GROWN_UP: GROWN-UPS → CHANGE PASSWORD on a device still
## logged in; the old one, or empty: a key made on this device proves it (FORGOT PASSWORD). Typed twice, in secret with
## SHOW; "Never tell anyone your password. Not even a friend."

signal done     # made or changed
signal closed   # LATER or BACK

enum Mode { MAKE, CHANGE, GROWN_UP }

var service: OnlineService
var mode := Mode.MAKE
var asked := false        # MAKE asked once of an account with no password: the why, and LATER
var later_allowed := true
var note := ""           # a line above the fields (LOG OUT: "Make a password first, so you can log back in.")
## The grown-up area's room under its tabs is small: a smaller title, NEW and AGAIN side by side, no child's line, and
## the words in the area's own line (the host sets `message` before adding the page).
var compact := false

var old_field: PasswordField
var new_field: PasswordField
var again_field: PasswordField
var message: Label
var ok_button: Button
var back_button: Button
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 8 if compact else 10)
	var title := PasswordRules.MAKE_TITLE if mode == Mode.MAKE else PasswordRules.CHANGE_TITLE
	if compact:
		add_child(OnlineUi.words(title, 26, 1100))
	else:
		add_child(ReadAloud.with_speaker(UiKit.title(title), self))
	if note != "":
		add_child(OnlineUi.words(note, 26, 1000))
	elif mode == Mode.MAKE and asked:
		add_child(OnlineUi.words(PasswordRules.MAKE_WHY, 26, 1000))
	if mode == Mode.MAKE:   # how to make a good one, before the first try (CHANGE has no room: its words say it)
		var idea := OnlineUi.words(PasswordRules.IDEA, 24, 1000)
		idea.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
		add_child(idea)
	if mode == Mode.GROWN_UP:
		add_child(OnlineUi.words(PasswordRules.GROWN_UP_KEY, 22, 1100))
	var w := 260.0 if compact else 420.0
	var label_w := 110.0 if compact else 170.0
	var show_w := 110.0 if compact else 150.0
	var field_h := OnlineUi.MIN_HEIGHT if compact else 72.0
	if mode != Mode.MAKE:
		old_field = PasswordField.make(PasswordRules.OLD, w, label_w, show_w, field_h)
		add_child(old_field)
	new_field = PasswordField.make(PasswordRules.PASSWORD, w, label_w, show_w, field_h)
	again_field = PasswordField.make(PasswordRules.AGAIN, w, label_w, show_w, field_h)
	again_field.submitted.connect(_go)
	if compact:
		add_child(OnlineUi.row([new_field, again_field], 24))
	else:
		add_child(new_field)
		add_child(again_field)
		var never := OnlineUi.words(PasswordRules.NEVER_TELL, 24, 1000)
		never.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
		add_child(never)
	if message == null:
		message = OnlineUi.words("", 24, 1000)
		message.add_theme_color_override("font_color", Color("ff8a80"))
		add_child(message)
	var button_h := OnlineUi.MIN_HEIGHT if compact else 84.0
	ok_button = OnlineUi.button(PasswordRules.MAKE if mode == Mode.MAKE else PasswordRules.CHANGE, UiKit.GREEN, Vector2(260, button_h))
	ok_button.pressed.connect(_go)
	var back_words := PasswordRules.LATER if mode == Mode.MAKE else "BACK"
	back_button = OnlineUi.button(back_words, UiKit.BLUE, Vector2(220, button_h))
	back_button.pressed.connect(func() -> void: closed.emit())
	back_button.visible = mode != Mode.MAKE or later_allowed
	add_child(OnlineUi.row([back_button, ok_button], 28))
	if not compact:
		ReadAloud.auto(PasswordRules.NEVER_TELL)


func _go() -> void:
	if _busy:
		return
	_busy = true
	ok_button.disabled = true
	message.text = "One moment..."
	var err: String
	var new_key := ""
	match mode:
		Mode.MAKE:
			err = await service.make_password(new_field.text, again_field.text)
		Mode.CHANGE:
			var cr: Dictionary = await service.change_password(new_field.text, again_field.text, old_field.text)
			err = str(cr.get("text", ""))
		Mode.GROWN_UP:
			var gr: Dictionary = await service.change_password(new_field.text, again_field.text, old_field.text, old_field.text == "")
			err = str(gr.get("text", ""))
			new_key = str(gr.get("new_key", ""))
	_busy = false
	if not is_inside_tree():
		return
	ok_button.disabled = false
	if err != "":
		message.text = err
		return
	message.text = ""   # (the area's line, when compact)
	OnlineUi.clear(self)
	add_child(OnlineUi.words(PasswordRules.SAVED if mode == Mode.MAKE else PasswordRules.CHANGED, 32, 1000))
	if new_key != "":   # owner #105: a new key was made to prove it: show it, so the old written-down one is never lost silently
		add_child(OnlineUi.words(PasswordRules.NEW_KEY_MADE, 24, 1000))
		var key_label := OnlineUi.words(new_key, 34, 1000)
		key_label.add_theme_color_override("font_color", UiKit.GREEN)
		key_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		add_child(key_label)
	add_child(OnlineUi.words(PasswordRules.NEVER_TELL, 26, 1000))
	var ok := OnlineUi.button("OK", UiKit.GREEN, Vector2(220, 84))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void: done.emit())
	add_child(ok)
	ReadAloud.auto(PasswordRules.SAVED)
