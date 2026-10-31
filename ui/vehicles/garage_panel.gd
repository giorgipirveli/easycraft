class_name GaragePanel
extends Control
## Owner #109 (spec §3b "Cars"): the garage, from MORE → CARS (VehicleDirector opens it over the game, which goes on
## under it). Left: the eight cars as tiles (their pictures drawn from their own models; FREE in the Sandbox, the price
## or YOURS in Survivor) and the picked car's card (DID YOU KNOW?, its checked facts, its numbers: CarCard). Right: its
## picture in the picked colour, its name (read aloud with a speaker), its line, its numbers, four colours and one big
## button: GET IT (the Sandbox), BUY <price> (Survivor, not yet the child's), CALL MY CAR (owned), CALL IT (out
## already); PUT AWAY sends one that is out back. The button asks the host (VehicleDirector) and the garage closes, so the
## child sees the car come. CLOSE, a tap outside, Back and Esc close it; it hears every touch on it first (the HUD's
## buttons under it never do); a game controller has it while it shows (PadFocus).

signal closed

const BOX_SIZE := Vector2(1200, 640)
const TILE := Vector2(150, 120)

var director: VehicleDirector
var kind: StringName = CarKinds.GO_KART
var colour := 0
var box := PanelContainer.new()
var tiles := {}                 # kind -> Button
var tags := {}                  # kind -> Label
var picture := CarPicture.new(CarKinds.GO_KART, 0, Vector2(480, 150))
var title_label := UiKit.title("", 36)
var about_label := Label.new()
var numbers_label := Label.new()
var gold_label := Label.new()
var swatches: Array[Button] = []
var card := CarCard.new()
var main_button: Button
var away_button: Button
var close_button: Button


func _init(d: VehicleDirector) -> void:
	director = d
	name = "Garage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # a click outside the box closes it (and never reaches the world)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.97), 24, 18))
	box.custom_minimum_size = BOX_SIZE
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(_header())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	v.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	row.add_child(left)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in CarKinds.ORDER:
		grid.add_child(_tile(k))
	left.add_child(grid)
	left.add_child(card)
	row.add_child(_detail())


func _ready() -> void:
	Session.gold_changed.connect(_on_gold)
	pick(kind)
	UiMotion.pop_in(box)
	PadFocus.take(self, tiles[kind])


func _exit_tree() -> void:
	if Session.gold_changed.is_connected(_on_gold):
		Session.gold_changed.disconnect(_on_gold)


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var title := UiKit.title("GARAGE", 36)
	row.add_child(ReadAloud.with_speaker(title, self, func() -> String: return "Garage. Pick a car!"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	gold_label.add_theme_font_size_override("font_size", 26)
	gold_label.add_theme_color_override("font_color", Color("ffd23f"))
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(gold_label)
	close_button = UiKit.big_button("CLOSE", UiKit.BLUE, Vector2(170, 64))
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _tile(k: StringName) -> Button:
	var b := Button.new()
	b.name = "Tile_" + String(k)
	b.custom_minimum_size = TILE
	b.add_theme_stylebox_override("normal", UiKit.box(Color(0.16, 0.2, 0.3), 16, 6))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(0.2, 0.25, 0.38), 16, 6))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(0.12, 0.15, 0.24), 16, 6))
	b.pressed.connect(pick.bind(k))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var pic := CarPicture.new(k, 0, Vector2(140, 60))
	v.add_child(pic)
	var label := Label.new()
	label.text = CarKinds.display_name(k)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(label)
	var tag := Label.new()
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 17)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tag)
	tags[k] = tag
	tiles[k] = b
	return b


func _detail() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size.x = 480
	v.add_child(picture)
	v.add_child(ReadAloud.with_speaker(title_label, self, card.words))
	for l: Label in [about_label, numbers_label]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 480
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 21)
		v.add_child(l)
	numbers_label.add_theme_color_override("font_color", Color("9ad7ff"))
	var colours := HBoxContainer.new()
	colours.alignment = BoxContainer.ALIGNMENT_CENTER
	colours.add_theme_constant_override("separation", 14)
	for i in CarKinds.COLOURS:
		var s := Button.new()
		s.name = "Colour%d" % i
		s.custom_minimum_size = Vector2(66, 66)
		s.pressed.connect(_pick_colour.bind(i))
		colours.add_child(s)
		swatches.append(s)
	v.add_child(colours)
	main_button = UiKit.big_button("GET IT", UiKit.GREEN, Vector2(360, 80))
	main_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_button.pressed.connect(_main)
	v.add_child(main_button)
	away_button = UiKit.big_button("PUT AWAY", UiKit.ORANGE, Vector2(240, 64))
	away_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	away_button.pressed.connect(_put_away)
	v.add_child(away_button)
	return v


## Shows car `k` (its picture, words, colours, card and button).
func pick(k: StringName) -> void:
	if not CarKinds.exists(k):
		return
	kind = k
	var mine := _mine()
	colour = mine.colour if mine else colour
	picture.kind = k
	picture.colour = colour
	title_label.text = CarKinds.display_name(k)
	about_label.text = CarKinds.about(k)
	numbers_label.text = CarKinds.numbers_words(k)
	card.set_kind(k)
	for i in swatches.size():
		var c := CarKinds.colour_of(k, i)
		var on := i == colour
		var style := UiKit.box(c, 36, 4)
		style.border_color = Color.WHITE if on else c.darkened(0.4)
		style.set_border_width_all(6 if on else 3)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			swatches[i].add_theme_stylebox_override(state, style)
		swatches[i].tooltip_text = str(CarKinds.colour_names(k)[i])
	refresh()


func _pick_colour(i: int) -> void:
	colour = CarKinds.colour_index(i)
	pick(kind)


## The tiles' tags, the gold and the button's word, as things are now.
func refresh() -> void:
	for k: StringName in tags:
		(tags[k] as Label).text = tag_of(k)
		(tags[k] as Label).add_theme_color_override("font_color",
			Color("7cfc6b") if tag_of(k) in ["FREE", "YOURS"] else Color("ffd23f"))
		(tiles[k] as Button).modulate = Color.WHITE if k == kind else Color(1, 1, 1, 0.82)
	gold_label.visible = not _free()
	gold_label.text = "Gold: %s" % GoldFormat.short(Profile.data.survivor_gold) if gold_label.visible else ""
	main_button.text = main_word()
	away_button.visible = _mine() != null


## A tile's tag: FREE (the Sandbox), YOURS (owned) or the price.
func tag_of(k: StringName) -> String:
	if _free():
		return "FREE"
	if _owns(k):
		return "YOURS"
	return str(CarKinds.price(k))


## The big button's word for the picked car.
func main_word() -> String:
	if _mine() != null:
		return "CALL IT"
	if _free():
		return "GET IT"
	if _owns(kind):
		return "CALL MY CAR"
	return "BUY %d" % CarKinds.price(kind)


func _free() -> bool:
	return Game.allows(ModeRules.INFINITE_GOLD)


func _owns(k: StringName) -> bool:
	return VehicleRules.owned_kinds(Profile.data.bought).has(k)


## This game's child's car of the picked kind in the world, or null.
func _mine() -> Vehicle:
	if director == null:
		return null
	return director.car_of(director.name_of(multiplayer.get_unique_id()), kind)


func _main() -> void:
	if director == null:
		return
	if _free() or _owns(kind) or _mine() != null:
		director.request_car(kind, colour)
	else:
		director.request_buy(kind, colour)
	close()


func _put_away() -> void:
	if director:
		director.request_put_away(kind)
	close()


func _on_gold(_balance: int) -> void:
	refresh()


func close() -> void:
	closed.emit()


## Every new finger: on the box it stays there (its buttons hear it as a click); anywhere else it closes the garage.
## Either way the HUD's buttons and the world behind never hear it.
func _input(event: InputEvent) -> void:
	var t := event as InputEventScreenTouch
	if t == null or not t.pressed or not is_visible_in_tree():
		return
	if not box.get_global_rect().has_point(t.position):
		close()
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var m := event as InputEventMouseButton
	if m and m.pressed and not box.get_global_rect().has_point(m.position):
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		close()
		get_viewport().set_input_as_handled()
