class_name HubPanel
extends Control
## The portal hub (M3 Task 5, spec §14.1), opened by walking into the stone circle by a Survivor world's
## spawn: a picture card for every unlocked universe (UniverseCard; GO!, "You are here", "Coming soon!").
## A tap on GO! asks to travel there (travel_requested); why not (UniverseRules.travel_message) shows
## under the cards. Closes on its X or when the player walks out of the circle. Per device, never sent.

signal travel_requested(universe: int)
signal opened
signal closed

const TITLE := "Where to?"
const HINT_ONE := "Beat the boss to open a new universe!"

var close_button: Button
var cards: Array[UniverseCard] = []

var _panel := PanelContainer.new()
var _row := HBoxContainer.new()
var _hint := Label.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.17), 26, 22))
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	var title := UiKit.title(TITLE, 40)
	title.add_theme_color_override("font_color", Color("c9a6ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 84))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)
	column.add_child(header)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 16)
	column.add_child(_row)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color("ffe14d"))
	column.add_child(_hint)


## Shows `entries` (UniverseRules.hub_entries: {universe, open}); `here` is this world's universe.
func open(entries: Array[Dictionary], here: int) -> void:
	for c in cards:
		_row.remove_child(c)
		c.free()
	cards.clear()
	for e: Dictionary in entries:
		var card := UniverseCard.new(int(e.universe), bool(e.open), int(e.universe) == here)
		card.pressed.connect(func() -> void: travel_requested.emit(card.universe))
		_row.add_child(card)
		cards.append(card)
	_row.add_theme_constant_override("separation", 16 if entries.size() <= 4 else 6)   # owner 39: five fit 1280
	_hint.text = HINT_ONE if entries.size() <= 1 else ""
	if cards.any(func(c: UniverseCard) -> bool: return c.plus_locked) and ShopWords.plus_once_due(Profile.data):
		_hint.text = Session.shop_travel_refusal(_first_plus_card())   # Owner 35: said once, then never
	visible = true
	if PlatformRules.captures_mouse(PlatformRules.current()):   # M7: a phone browser has no mouse to free
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _first_plus_card() -> int:
	for c in cards:
		if c.plus_locked:
			return c.universe
	return 0


## Why a travel can't happen, under the cards.
func say(text: String) -> void:
	_hint.text = text


func hint() -> String:
	return _hint.text


func card_for(u: int) -> UniverseCard:
	for c in cards:
		if c.universe == u:
			return c
	return null


## What must not build or break under the panel (LookBuildArea reads touches first).
func blockers() -> Array[Control]:
	return [self]
