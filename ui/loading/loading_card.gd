class_name LoadingCard
extends Control
## While a world loads (M5 Task 2, spec §15.2): the universe's own scene (UniverseBackdrop) fills the screen and a
## card shows one picture hint at a time (LoadingHints, HINT_TIME each, never the same twice in a row), read aloud
## with "Read to me". cover() puts it over the HUD until this device's player stands in the world, then it fades.
## One label and one icon; nothing is made per frame (a hint changes a texture and a text every HINT_TIME).

const HINT_TIME := 5.0
const FADE_TIME := 0.35
const LAYER := 88                 # over the HUD and the tutorial's card, under Feel's flash (90) and the net overlay
const ICON := Vector2(96, 96)
const FONT := 30
## M7: while a card is up a world is loading; the web build's background downloads wait (WebContent.world_loading).
const GROUP := &"world_loading"
## M7: while a node is in this group the card stays after the child stands in the world (in a browser, ShaderWarmup
## drawing what a first world shows: the child never meets those compiling), at most `hold_max` seconds.
const HOLD_GROUP := &"holds_loading_card"
const HOLD_MAX := 30.0

var backdrop: UniverseBackdrop
var icon := TextureRect.new()
var label := Label.new()
var hint := -1
## The child stands in the world and the card waits for what holds it (HOLD_GROUP).
var holding := false
var hold_max := HOLD_MAX
var _held := 0.0

var _mode: StringName = ModeRules.SANDBOX
var _universe := 1
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _leaving := false


## Over `parent` until `player` (anything with a `spawned` signal) stands in the world: a CanvasLayer holding the card.
static func cover(parent: Node, player: Node, mode: StringName, u: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "LoadingLayer"
	layer.layer = LAYER
	var card := LoadingCard.new()
	card.setup(mode, u)
	layer.add_child(card)
	UiLayers.route(layer, parent)   # owner #101: in VR on the eye panel, in the loading room (VrUi)
	player.connect(&"spawned", card.finish, CONNECT_ONE_SHOT)
	return layer


func setup(mode: StringName, u: int) -> void:
	_mode = mode
	_universe = u


## The world that loads under this card (ShaderWarmup.world_part draws what it shows round its landing first).
func universe() -> int:
	return _universe


func _ready() -> void:
	name = "LoadingCard"
	add_to_group(GROUP)
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop = UniverseBackdrop.new(_universe)
	backdrop.veil = Color(0.08, 0.1, 0.17, 0.18)
	backdrop.rows_high = 13.0                      # a whole screen: the scene below, sky above
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.9), 22, 22))
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)
	icon.custom_minimum_size = ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	label.add_theme_font_size_override("font_size", FONT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 420
	row.add_child(label)
	_rng.randomize()
	_next()


func _process(delta: float) -> void:
	if holding:
		_held += delta
		if not _held_by_something() or _held >= hold_max:
			holding = false
			finish()
	step(delta)


func _held_by_something() -> bool:
	return is_inside_tree() and get_tree().get_first_node_in_group(HOLD_GROUP) != null


## M5 Task 6 review: the pause menu (Android Back during a load) lives on the world's layer, under this one; a paused
## game never spawns the player, so the card steps aside while paused and comes back on RESUME.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		visible = false
	elif what == NOTIFICATION_UNPAUSED and not _leaving:
		visible = true


## `delta` seconds of the card (tests step it): the next hint every HINT_TIME.
func step(delta: float) -> void:
	if _leaving:
		return
	_t += delta
	if _t >= HINT_TIME:
		_t = 0.0
		_next()


func _next() -> void:
	hint = LoadingHints.pick(_mode, _universe, hint, _rng)
	if hint < 0:
		return
	var h: Dictionary = LoadingHints.HINTS[hint]
	label.text = str(h.text)
	icon.texture = LoadingHints.picture(h)
	ReadAloud.auto(label.text)


## The player stands in the world: the card fades and its layer goes (after what holds it, HOLD_GROUP).
func finish() -> void:
	if _leaving or holding:
		return
	if _held < hold_max and _held_by_something():
		holding = true
		return
	_leaving = true
	var owner_node: Node = get_parent() if get_parent() is CanvasLayer else self
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	t.tween_callback(owner_node.queue_free)
