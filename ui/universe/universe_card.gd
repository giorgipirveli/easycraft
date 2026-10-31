class_name UniverseCard
extends Button
## One universe in the portal hub (M3 Task 5): a picture of it (its sky, a sun and its ground, drawn,
## no image files), its name and one short word: GO!, "You are here" or "Coming soon!" (a greyed
## picture with a question mark). Used by the main menu's SURVIVOR hub and the stone circle's panel.

const SIZE := Vector2(236, 250)
const PICTURE := Vector2(204, 140)
## Universe 6 (the Glow Caves): a row of every universe of the ladder still fits the 1280 px screen (the menu's rows put
## GAP between cards and keep MARGIN at each side): a card is narrower when the ladder is longer (195 px for six).
const SCREEN := 1280.0
const GAP := 18.0
const MARGIN := 24.0

var universe := 1
var open := true
var here := false
## Owner 35 (spec §18.3): unlocked by its boss but it comes with EasyCraft Plus, which this profile doesn't
## have: a calm card that can't be pressed ("EasyCraft Plus"; no price, nothing to tap).
var plus_locked := false
var picture := UniversePicture.new()
var name_label := Label.new()
var state_label := Label.new()
## Universe 6 (brief, owner #72): a locked universe with a free peek (UniverseRegistry.peek) has PEEK in place of its
## word; the card itself stays unpressable (no trip), the button opens UniversePeek. null otherwise.
var peek_button: Button = null


func _init(u: int = 1, is_open: bool = true, is_here: bool = false) -> void:
	universe = u
	open = is_open
	here = is_here
	plus_locked = open and not Entitlements.universe_open(u, Profile.data.purchases, Session.shop().store_open())   # Owner 35
	var w := width_for(UniverseRegistry.size())
	custom_minimum_size = Vector2(w, SIZE.y)
	focus_mode = Control.FOCUS_NONE
	disabled = not open or here or plus_locked
	pressed.connect(Audio.play.bind(&"ui_click"))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_right = -12
	column.offset_top = 10
	column.offset_bottom = -8
	add_child(column)
	picture.universe = u   # M5 Task 2: its own scene (UniverseArt)
	picture.locked = not open
	picture.plus = plus_locked
	picture.custom_minimum_size = Vector2(PICTURE.x - (SIZE.x - w), PICTURE.y)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	name_label.text = UniverseRegistry.display_name(u)
	_label(name_label, 24 if w >= SIZE.x else 20, Color.WHITE)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(name_label)
	state_label.text = word()
	_label(state_label, 22, Color("ffe14d") if open and not here and not plus_locked else Color(0.8, 0.82, 0.88))
	column.add_child(state_label)
	if not open and UniverseRegistry.exists(u) and not UniverseRegistry.peek(u).is_empty():
		state_label.visible = false
		peek_button = UiKit.big_button("PEEK", UiKit.BLUE, Vector2(minf(w - 40.0, 150.0), 46))
		peek_button.add_theme_font_size_override("font_size", 24)
		peek_button.focus_mode = Control.FOCUS_NONE
		peek_button.mouse_filter = Control.MOUSE_FILTER_STOP
		peek_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		peek_button.pressed.connect(func() -> void: UniversePeek.show_for(universe, self))
		column.add_child(peek_button)
	var color := UiKit.GREEN if open and not here and not plus_locked else Color(0.22, 0.24, 0.32)
	add_theme_stylebox_override("normal", UiKit.box(color, 20, 8))
	add_theme_stylebox_override("hover", UiKit.box(color.lightened(0.12), 20, 8))
	add_theme_stylebox_override("pressed", UiKit.box(color.darkened(0.15), 20, 8))
	add_theme_stylebox_override("disabled", UiKit.box(color.darkened(0.1), 20, 8))


## A card's width when `count` cards stand in a row: SIZE.x, or narrower so the row fits the screen.
static func width_for(count: int) -> float:
	var n := maxi(count, 1)
	return minf(SIZE.x, floorf((SCREEN - 2.0 * MARGIN - GAP * (n - 1)) / n))


## Owner #55 (spec §21): the way home from space — never locked (nobody is left on a planet): HOME, green, pressable.
func as_home() -> void:
	open = true
	plus_locked = false
	picture.locked = false
	picture.plus = false
	disabled = false
	state_label.text = SpaceRules.HOME_WORD
	state_label.add_theme_color_override("font_color", Color("ffe14d"))
	for st: String in ["normal", "hover", "pressed", "disabled"]:
		var c := UiKit.GREEN.lightened(0.12) if st == "hover" else (UiKit.GREEN.darkened(0.15) if st == "pressed" else UiKit.GREEN)
		add_theme_stylebox_override(st, UiKit.box(c, 20, 8))


## The card's one word.
func word() -> String:
	if not open:
		return "Coming soon!"
	if plus_locked:
		return ShopWords.PLUS_CARD
	return "You are here" if here else "GO!"


func _label(l: Label, size: int, color: Color) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## The picture: the universe's own little scene (M5 Task 2, UniverseArt: its sky, sun, far hills, its own blocks and the
## brand's buddy); locked: greyed with a question mark; EasyCraft Plus: a soft veil and a star (its colours stay).
class UniversePicture extends Control:
	var universe := 1
	var locked := false
	var plus := false   # Owner 35: comes with EasyCraft Plus (a soft veil and a star; its colours stay)
	var drawn := 0      # blocks drawn the last time (tests)

	func _draw() -> void:
		var s := size
		drawn = UniverseArt.draw(self, Rect2(Vector2.ZERO, s), universe, locked)
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.5), false, 3.0)
		if plus:
			draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.1, 0.18, 0.45))
			var c := Vector2(s.x * 0.5, s.y * 0.45)
			var r := s.y * 0.2
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + TAU * i / 10.0
				star.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
			draw_colored_polygon(star, Color("ffe082"))
