class_name GuestbookPage
extends VBoxContainer
## MY SHOWCASE in PLAY ONLINE's friends page (M4 Wave 3, agent I; spec §17.5, research T3): the stickers
## friends left on this child's showcase while visiting (who, which picture), each deletable, each with
## REPORT; and TAKE IT DOWN for the showcase itself. Putting a showcase up happens in a world (MORE,
## SHARE, MY SHOWCASE: the area around where the child stands).

const LIST_HEIGHT := 210.0

var service: OnlineService
var message: Label
var list := VBoxContainer.new()
var has_showcase := false

var _busy := false
var _down: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_down = OnlineUi.button("TAKE IT DOWN", UiKit.RED, Vector2(260, 76))
	_down.name = "TakeDown"
	_down.add_theme_font_size_override("font_size", 22)
	_down.visible = false
	_down.pressed.connect(_take_down)
	add_child(OnlineUi.row([UiKit.title("My showcase", 40), _down], 24))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	add_child(scroll)
	message = OnlineUi.words("One moment...", 24, 900)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	load_book()


func load_book() -> void:
	var r: Dictionary = await service.my_showcase()
	if not is_inside_tree():
		return
	has_showcase = not (r.showcase as Dictionary).is_empty()
	_down.visible = has_showcase
	message.text = r.text
	show_stickers(r.guestbook)


func show_stickers(book: Array) -> void:
	OnlineUi.clear(list)
	if not has_showcase:
		list.add_child(OnlineUi.words("No showcase yet. In your world, tap MORE, then SHARE, then MY SHOWCASE.", 28, 880))
		return
	if book.is_empty():
		list.add_child(OnlineUi.words("No stickers yet. When friends visit, their stickers wait here!", 28, 880))
	for e: Dictionary in book:
		var row := HBoxContainer.new()
		row.name = "Sticker_" + str(e.id)
		row.add_theme_constant_override("separation", 12)
		var pic := StickerPicture.new(str(e.sticker))
		pic.custom_minimum_size = Vector2(64, 64)
		row.add_child(pic)
		var l := Label.new()
		l.text = tr("%s from %s") % [GiftRules.sticker_word(e.sticker), e.from]
		l.add_theme_font_size_override("font_size", 26)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(_small("DELETE", UiKit.RED, _act.bind(e.id)))
		row.add_child(_small("REPORT", UiKit.ORANGE, _report.bind(str(e.from_id), str(e.id))))
		list.add_child(row)


func _small(text: String, color: Color, action: Callable) -> Button:
	var b := OnlineUi.button(text, color, Vector2(170, 70))
	b.name = text.capitalize()
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(action)
	return b


func _act(entry_id: String) -> void:
	if _busy:
		return
	_busy = true
	var r: Dictionary = await service.remove_sticker(entry_id)
	_busy = false
	if not is_inside_tree():
		return
	message.text = r.text if r.text != "" else "Gone!"
	if r.text == "":
		show_stickers(r.guestbook)


## A sticker is a preset picture: reporting it tells a person about the visitor; the sticker goes.
func _report(user_id: String, entry_id: String) -> void:
	if _busy:
		return
	_busy = true
	var err: String = await service.report(user_id, OnlineService.REPORT_OTHER)
	var r: Dictionary = await service.remove_sticker(entry_id)
	_busy = false
	if not is_inside_tree():
		return
	message.text = err if err != "" else "Thank you for telling us. A grown-up will look at it."
	if r.text == "":
		show_stickers(r.guestbook)


func _take_down() -> void:
	if _busy:
		return
	_busy = true
	var err: String = await service.remove_showcase()
	_busy = false
	if not is_inside_tree():
		return
	has_showcase = err != "" and has_showcase
	_down.visible = has_showcase
	message.text = err if err != "" else "Your showcase is down. Friends can't visit it now."
	show_stickers([])
