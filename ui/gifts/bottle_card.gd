class_name BottleCard
extends Control
## What a friend's bottle says (M4 Wave 3, agent I; research D5): the friend's name, the quick phrase
## big with its picture, and, when a tiny build was inside, where to find it (the palette's GIFTS page).
## OK closes it; REPORT tells a person (the build is kept for them), mutes the friend here and deletes
## the tiny build's stamp. A centred card over the HUD; a tap outside does nothing.

signal closed

var service: OnlineService
var result: Dictionary = {}       # OnlineService.open_bottle's answer
var message: Label

var _box := PanelContainer.new()
var _content := VBoxContainer.new()
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 22))
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_content.add_theme_constant_override("separation", 14)
	_box.add_child(_content)


## Shows an opened bottle (or the words of why it could not open).
func show_result(r: Dictionary) -> void:
	result = r
	OnlineUi.clear(_content)
	var b: Dictionary = r.get("bottle", {})
	if b.is_empty():
		_content.add_child(OnlineUi.words(str(r.get("text", "")), 30, 620))
		_content.add_child(_buttons(false))
	else:
		_content.add_child(OnlineUi.words(tr("A bottle from %s!") % b.from, 32, 620))
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 16)
		var pic := _Phrase.new(OnlineChatRules.PICTURES.get(b.phrase, &""))
		pic.custom_minimum_size = Vector2(96, 96)
		line.add_child(pic)
		var said := Label.new()
		said.text = "\"%s\"" % b.phrase
		said.add_theme_font_size_override("font_size", 46)
		line.add_child(said)
		_content.add_child(line)
		if int(r.get("slot", -1)) >= 0:
			_content.add_child(OnlineUi.words("A tiny build was inside! Find it in your blocks, on the GIFTS page.", 24, 620))
		elif str(b.get("build", "")) != "":
			_content.add_child(OnlineUi.words(GiftRules.message("book_full"), 24, 620))
		_content.add_child(_buttons(true))
	message = OnlineUi.words("", 22, 620)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	_content.add_child(message)
	visible = true


func _buttons(with_report: bool) -> HBoxContainer:
	var ok := OnlineUi.button("OK", UiKit.GREEN, Vector2(220, 90))
	ok.name = "Ok"
	ok.pressed.connect(close)
	var row: Array = [ok]
	if with_report:
		var report := OnlineUi.button("REPORT", UiKit.ORANGE, Vector2(220, 90), &"flag")
		report.name = "Report"
		report.pressed.connect(_report)
		row.append(report)
	return OnlineUi.row(row)


func _report() -> void:
	if _busy or service == null:
		return
	_busy = true
	var b: Dictionary = result.get("bottle", {})
	var err: String = await service.report_build(str(b.get("from_id", "")), "bottle", str(b.get("build", "")),
		int(result.get("slot", -1)))
	_busy = false
	if is_inside_tree():
		message.text = err if err != "" else "Thank you for telling us. A grown-up will look at it."


func close() -> void:
	visible = false
	closed.emit()


## The buttons and the card, for the HUD's look area (a tap on them must not build).
func blockers() -> Array[Control]:
	return [_box]


## The phrase's picture (ChatPictures, the quick-chat wheel's).
class _Phrase extends Control:
	var kind: StringName

	func _init(k: StringName) -> void:
		kind = k
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if kind != &"":
			ChatPictures.draw(self, kind, Rect2(Vector2.ZERO, size), Color.WHITE)
