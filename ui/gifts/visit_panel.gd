class_name VisitPanel
extends Control
## The visit's own buttons (M4 Wave 3, agent I; spec §17.5, research T3): a bar at the top of a
## friend's showcase with their name, STICKER (the eight preset stickers: one tap leaves it in their
## guestbook), REPORT (what was wrong: a person looks, with a copy of the build) and LEAVE (back to the
## menu). Big buttons, pictures first.

signal leave_requested

const BAR_TOP := 12.0

var service: OnlineService
var showcase: Dictionary = {}     # GiftRules.showcase
var message: Label

var _bar := PanelContainer.new()
var _sheet := PanelContainer.new()
var _sheet_box := VBoxContainer.new()
var _busy := false
var _signed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.9), 20, 12))
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bar)
	_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_bar.offset_top = BAR_TOP
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_bar.add_child(row)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("%s's showcase") % showcase.get("owner", "")
	title.add_theme_font_size_override("font_size", 30)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	for spec: Array in [["STICKER", UiKit.GREEN, _show_stickers, &"heart"], ["REPORT", UiKit.ORANGE, _show_reasons, &"flag"],
			["LEAVE", UiKit.BLUE, func() -> void: leave_requested.emit(), &"house"]]:
		var b := OnlineUi.button(spec[0], spec[1], Vector2(190, 96), spec[3])
		b.name = String(spec[0]).capitalize()
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(spec[2])
		row.add_child(b)
	message = OnlineUi.words("", 24, 700)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	_sheet.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 18))
	_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	_sheet.visible = false
	add_child(_sheet)
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sheet.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sheet_box.add_theme_constant_override("separation", 14)
	_sheet.add_child(_sheet_box)


## The bar and the sheet, for the HUD's look area (their taps never reach the world).
func blockers() -> Array[Control]:
	return [_bar, _sheet]


func sheet_open() -> bool:
	return _sheet.visible


func close_sheet() -> void:
	_sheet.visible = false


func _open_sheet(title: String) -> void:
	if message.get_parent():
		message.get_parent().remove_child(message)
	OnlineUi.clear(_sheet_box)
	_sheet_box.add_child(OnlineUi.words(title, 32, 720))
	_sheet.visible = true


func _show_stickers() -> void:
	_open_sheet(tr("Leave %s a sticker!") % showcase.get("owner", ""))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for s in GiftRules.STICKERS:
		var b := Button.new()
		b.name = "Sticker_" + s
		b.custom_minimum_size = Vector2(150, 150)
		b.tooltip_text = GiftRules.sticker_word(s)
		var pic := StickerPicture.new(s)
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.offset_left = 18
		pic.offset_top = 18
		pic.offset_right = -18
		pic.offset_bottom = -18
		b.add_child(pic)
		b.pressed.connect(_sign.bind(s))
		grid.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	_sheet_box.add_child(centre)
	_sheet_box.add_child(message)
	_sheet_box.add_child(OnlineUi.row([_back()]))


func _sign(sticker: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.sign_guestbook(str(showcase.owner_id), sticker)
	_busy = false
	if not is_inside_tree():
		return
	if err == "":
		_signed = true
		close_sheet()
		_toast.call("%s will see your sticker!" % showcase.get("owner", ""))
	else:
		message.text = err


func _show_reasons() -> void:
	_open_sheet("What was wrong with it?")
	var buttons: Array = []
	for reason: String in ["bad_build", "scary", "other"]:
		var words: String = {"bad_build": "NOT NICE", "scary": "SCARY", "other": "SOMETHING\nELSE"}[reason]
		var b := OnlineUi.button(words, UiKit.ORANGE, Vector2(220, 96))
		b.name = "Reason_" + reason
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_report.bind(reason))
		buttons.append(b)
	_sheet_box.add_child(OnlineUi.row(buttons))
	_sheet_box.add_child(message)
	_sheet_box.add_child(OnlineUi.row([_back()]))


func _report(reason: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.report_build(str(showcase.owner_id), "showcase", str(showcase.build), -1, reason)
	_busy = false
	if not is_inside_tree():
		return
	message.text = err if err != "" else "Thank you for telling us. A grown-up will look at it."


func _back() -> Button:
	var b := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 86))
	b.name = "Back"
	b.pressed.connect(close_sheet)
	return b


## Words over the world for a moment (the visit has no HUD toast of its own here).
var _toast := func(_text: String) -> void: pass


func set_toast(show_words: Callable) -> void:
	_toast = show_words


func _exit_tree() -> void:
	if message and message.get_parent() == null:
		message.free()
