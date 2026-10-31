class_name SavingPage
extends VBoxContainer
## The saving list in the book (M3 Task 21b; research R3): each gold thing the child chose to save up for — a
## tool at Tilly's or an avatar item — with its picture, its name, where it is found and a have/need bar of the
## child's Survivor gold (Tilly's price where the child is). X takes it off. Nothing here buys or nags.

const ROW := Vector2(900, 66)
const ICON := 58.0

## The book's data, the gold and where the child is (tests use their own).
var profile: Callable = func() -> ProfileData: return Profile.data
var universe: Callable = func() -> int: return Game.universe
var game: Callable = func() -> StringName: return Game.survivor_game

var title := BookKit.label(SavingRules.TITLE, 34, BookKit.TITLE_INK)
var gold_label := BookKit.label("", 24, BookKit.SOFT_INK)
var empty_label := BookKit.label(SavingRules.EMPTY_WORDS, 26, BookKit.SOFT_INK)

var _rows := VBoxContainer.new()


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0))   # M3 Task 21a's speaker
	head.add_child(CoinIcon.new(34))
	gold_label.custom_minimum_size.x = 110
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(gold_label)
	add_child(head)
	_rows.add_theme_constant_override("separation", 8)
	_rows.custom_minimum_size = Vector2(ROW.x, ROW.y * SavingRules.MAX + 8 * (SavingRules.MAX - 1))
	add_child(_rows)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.custom_minimum_size = Vector2(700, 0)
	add_child(empty_label)
	refresh()


func refresh() -> void:
	var p: ProfileData = profile.call()
	SavingRules.tidy(p.wonder, p)
	gold_label.text = GoldFormat.short(p.survivor_gold)
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	for e in p.wonder.saving:
		_rows.add_child(_row(e, p))
	empty_label.visible = p.wonder.saving.is_empty()
	_rows.visible = not empty_label.visible


func _row(e: Dictionary, p: ProfileData) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = ROW
	box.add_theme_stylebox_override("panel", BookKit.card_box(BookKit.CARD, 4))
	box.set_meta(&"entry", e)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	row.add_child(_icon(e))
	var words := VBoxContainer.new()
	words.custom_minimum_size.x = 300
	var name_label := BookKit.label(SavingRules.name_of(e), 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(name_label)
	var where := BookKit.label(SavingRules.where_words(e), 17, BookKit.SOFT_INK)
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(where)
	row.add_child(words)
	var bar := SavingBar.new(Vector2(360, 34))
	bar.name = "Bar"
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.set_have_need(SavingRules.have_need(e, p.survivor_gold, int(universe.call()), game.call()))
	row.add_child(bar)
	var x := BookKit.button("X", Vector2(64, 58), 28)
	x.name = "Remove"
	x.pressed.connect(remove.bind(e))
	row.add_child(x)
	return box


func _icon(e: Dictionary) -> Control:
	if e.kind == SavingRules.LOOK:
		var id := str(e.id)
		var t := AvatarTile.new(AvatarCatalog.slot_of(id), AvatarCatalog.name_of(id), Vector2(ICON, ICON))
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var r := TextureRect.new()
	r.texture = ShopCard.icon_for(str(e.id).to_int())
	r.self_modulate = ShopCard.tint_for(str(e.id).to_int())
	r.custom_minimum_size = Vector2(ICON, ICON)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r


## X: off the list (the child's choice, no questions asked).
func remove(e: Dictionary) -> void:
	var p: ProfileData = profile.call()
	SavingRules.remove(p.wonder, e.kind, e.id)
	Audio.play(&"ui_click")
	refresh()


## The rows showing now (tests): [{entry, words (the bar's)}].
func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _rows.get_children():
		if not c.is_queued_for_deletion():
			out.append({"entry": c.get_meta(&"entry"), "bar": (c.find_child("Bar", true, false) as SavingBar).words(),
				"remove": c.find_child("Remove", true, false)})
	return out
