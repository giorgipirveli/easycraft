class_name PasswordField
extends HBoxContainer
## Owner #105: a password typed in secret, with SHOW / HIDE beside it (a child checks what they typed). Used by the
## password pages, LOG IN and DELETE.

signal submitted

var edit := LineEdit.new()
var show_button: Button
var label: Label


static func make(title: String, width: float = 420.0, label_width: float = 170.0, show_width: float = 150.0,
		height: float = 72.0) -> PasswordField:
	var f := PasswordField.new()
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 14)
	f.label = Label.new()
	f.label.text = title
	f.label.custom_minimum_size = Vector2(label_width, 0)
	f.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	f.label.add_theme_font_size_override("font_size", 26)
	f.add_child(f.label)
	f.edit.secret = true
	f.edit.max_length = PasswordRules.MAX_LEN
	f.edit.custom_minimum_size = Vector2(width, height)
	f.edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.edit.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	f.edit.text_submitted.connect(func(_t: String) -> void: f.submitted.emit())
	f.add_child(f.edit)
	f.show_button = OnlineUi.button(PasswordRules.SHOW, Color(), Vector2(show_width, height))
	f.show_button.add_theme_font_size_override("font_size", 22)
	f.show_button.pressed.connect(f.toggle)
	f.add_child(f.show_button)
	return f


func toggle() -> void:
	edit.secret = not edit.secret
	show_button.text = PasswordRules.SHOW if edit.secret else PasswordRules.HIDE


var text: String:
	get:
		return edit.text
	set(v):
		edit.text = v
