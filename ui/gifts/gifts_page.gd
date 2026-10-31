class_name GiftsPage
extends VBoxContainer
## PRESENTS in PLAY ONLINE's friends page (M4 Wave 3, agent I; spec §17.5): the presents friends sent
## (OPEN turns one into a stamp in the palette's GIFTS page; DELETE throws it away unopened) and the
## gift stamps on this device (DELETE). REPORT on each one: a person looks at the build, the sender is
## muted here and the thing goes away. Every received thing can be deleted by the child.

const LIST_HEIGHT := 220.0

var service: OnlineService
var message: Label
var list := VBoxContainer.new()
var picked: Dictionary = {}       # the thing whose REPORT reasons show ({} on the list)

var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var head := OnlineUi.row([_icon(&"gift"), UiKit.title("Presents", 40)], 14)
	add_child(head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1000, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	add_child(scroll)
	message = OnlineUi.words("", 24, 960)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	service.gifts_changed.connect(_on_changed)
	fill()
	_refresh()


func fill() -> void:
	picked = {}
	OnlineUi.clear(list)
	for g: Dictionary in service.gifts:
		list.add_child(_row(tr("From %s\n%s") % [g.from, Lang.blocks(int(g.count))] + (tr(" and a race!") if g.get("ghost", false) else ""), [
			_small("OPEN", UiKit.GREEN, _open.bind(g.id)),
			_small("DELETE", UiKit.RED, _act.bind(service.discard_gift.bind(g.id), "Gone!")),
			_small("REPORT", UiKit.ORANGE, _report.bind(g.from_id, "gift", "", -1))], "Present_" + g.id))
	var book := service._i_book()
	for slot in book.slots():
		var s := book.stamp(slot)
		list.add_child(_row(tr("Gift stamp from %s") % s.from, [
			_small("DELETE", UiKit.RED, _delete_stamp.bind(slot)),
			_small("REPORT", UiKit.ORANGE, _report.bind(s.from_id, str(s.kind), str(s.build), slot))], "Stamp_%d" % slot))
	if list.get_child_count() == 0:
		list.add_child(OnlineUi.words("No presents yet. When a friend sends you one, it waits here!", 26, 960))


func _row(words: String, buttons: Array, row_name: String) -> Control:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 12)
	row.add_child(_icon(&"gift"))
	var l := Label.new()
	l.text = words
	l.add_theme_font_size_override("font_size", 26)
	l.custom_minimum_size = Vector2(360, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	for b: Button in buttons:
		row.add_child(b)
	return row


func _small(text: String, color: Color, action: Callable) -> Button:
	var b := OnlineUi.button(text, color, Vector2(170, 70))
	b.name = text.capitalize()
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(action)
	return b


func _icon(kind: StringName) -> Control:
	var pic := OnlineIcon.new(kind)
	pic.custom_minimum_size = Vector2(56, 56)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return pic


func _open(gift_id: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var r: Dictionary = await service.open_gift(gift_id)
	_busy = false
	if not is_inside_tree():
		return
	fill()
	message.text = r.text if r.text != "" else "It's a stamp now! Find it in your blocks, on the GIFTS page." + \
		(" Stamp it and step on START to race!" if service.ghost_race_in_slot(int(r.get("slot", -1))) else "")   # M4 ghost races


func _delete_stamp(slot: int) -> void:
	service.delete_stamp(slot)
	fill()
	message.text = "Gone!"


## REPORT's reasons, as on a friend's page; the report keeps a copy of the build for the reviewer.
func _report(user_id: String, what: String, build: String, slot: int) -> void:
	picked = {"user_id": user_id}
	OnlineUi.clear(list)
	list.add_child(OnlineUi.words("What was wrong with it?", 30, 960))
	var buttons: Array = []
	for reason: String in ["bad_build", "scary", "other"]:
		var words: String = {"bad_build": "NOT NICE", "scary": "SCARY", "other": "SOMETHING\nELSE"}[reason]
		var b := OnlineUi.button(words, UiKit.ORANGE, Vector2(220, 96))
		b.name = "Reason_" + reason
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_act.bind(service.report_build.bind(user_id, what, build, slot, reason),
			"Thank you for telling us. A grown-up will look at it."))
		buttons.append(b)
	list.add_child(OnlineUi.row(buttons))


func _act(action: Callable, thanks: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await action.call()
	_busy = false
	if not is_inside_tree():
		return
	fill()
	message.text = err if err != "" else thanks


func _refresh() -> void:
	if not _busy:
		await service.refresh_gifts()


func _on_changed() -> void:
	if picked.is_empty() and is_inside_tree() and not _busy:
		fill()


## The friends page's BACK: out of REPORT's reasons first (true), else the page closes (false).
func back() -> bool:
	if picked.is_empty():
		return false
	fill()
	return true
