class_name BossBar
extends Control
## The Stone Golem's health bar (M2 Task 10; HUD top-centre, above the toasts): a little golem face,
## the name ("STONE GOLEM", or "TIRED GOLEM" when honest help made it weaker) and a big bar. The
## health is shown as a bar, never as a number; notches at every quarter help a child see how far the
## team got. While the Golem is dazed a steady "x2" chip says hits count double (nothing blinks).
## After a fight the name line says how it went ("You got it to 20%!" / "You beat the Stone Golem!")
## and the bar stays where the team got it. It never takes a tap. It redraws only when something
## changes (the BossDirector calls set_health every frame with the same numbers).

const SIZE := Vector2(270, 76)
const TITLE := "STONE GOLEM"
const TIRED_TITLE := "TIRED GOLEM"
const BACK := Color(0.08, 0.1, 0.17, 0.88)
const BAR_BACK := Color(0.2, 0.16, 0.2)
const FILL := Color("e8603a")
const FILL_TOP := Color("ff9a6a")
const NOTCH := Color(0.08, 0.06, 0.1, 0.8)
const TEXT := Color.WHITE
const RESULT := Color("ffd84a")
const ICON := Rect2(10, 14, 46, 48)
const BAR := Rect2(64, 42, 194, 22)

var _title := Label.new()
var _double := Label.new()
var _names := [TITLE, TIRED_TITLE]   # M3 Task 2: the fighting boss's name (use_boss)
var _serpent := false
var _giant := false               # M3 Task 3: the Frost Giant's face
var _face := BossRules.GOLEM   # M3 Task 4: whose face the bar shows
var _fraction := 1.0
var _hp := -1
var _max := -1
var _tired := false
var _result := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	_style(_title, 19, TEXT)
	_title.position = Vector2(64, 6)
	_title.size = Vector2(160, 30)
	_title.text = TITLE
	add_child(_title)
	_style(_double, 20, RESULT)
	_double.position = Vector2(222, 6)
	_double.size = Vector2(40, 30)
	_double.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_double.text = "x2"
	_double.visible = false
	add_child(_double)
	visible = false


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## A fight begins: the name, a full bar.
func start(tired: bool) -> void:
	_result = false
	_hp = -1
	_tired = tired
	_set_title(_names[1] if tired else _names[0], TEXT)
	_set_fraction(1.0)
	_double.visible = false
	visible = true


## The Golem's health now (cheap to call every frame: only a change redraws). A result on the bar
## stays until start(): a LAN guest's copy of a beaten Golem can outlive the win message by a frame.
func set_health(hp: int, max_hp: int, tired: bool = false, dazed: bool = false) -> void:
	if _result:
		return
	if not visible:
		visible = true
	if tired != _tired:
		_tired = tired
		_set_title(_names[1] if tired else _names[0], TEXT)
	if _double.visible != dazed:
		_double.visible = dazed
	if hp != _hp or max_hp != _max:
		_hp = hp
		_max = max_hp
		_set_fraction(float(hp) / float(maxi(max_hp, 1)))


## After a fight: how it went, with the bar where the team got it.
func show_result(text: String, fraction_left: float) -> void:
	_result = true
	_double.visible = false
	_set_title(text, RESULT)
	_set_fraction(fraction_left)
	visible = true


func hide_bar() -> void:
	visible = false
	_result = false


func title() -> String:
	return _title.text


func fraction() -> float:
	return _fraction


func shows_double() -> bool:
	return _double.visible


func showing_result() -> bool:
	return _result and visible


func _set_title(text: String, color: Color) -> void:
	_title.text = text
	_title.add_theme_color_override("font_color", color)
	_title.size = Vector2(160 if color == TEXT else 200, 30)


func _set_fraction(f: float) -> void:
	f = clampf(f, 0.0, 1.0)
	if not is_equal_approx(f, _fraction):
		_fraction = f
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BACK, true)
	if _face == BossRules.SPORE_MOTHER:
		_draw_mother_face()   # universe 6
	elif _face == BossRules.SKY_DRAGON:
		_draw_dragon_face()   # owner 39
	elif _face == BossRules.CAKE:
		_draw_cake_face()   # M3 Task 4
	elif _serpent:
		_draw_serpent_face()
	elif _giant:
		_draw_giant_face()
	else:
		_draw_golem_face()
	_draw_bar()


## Universe 6: the Spore Mother's face: her rose cap with glowing teal spots over a pale face, happy closed eyes, cheeks.
func _draw_mother_face() -> void:
	draw_rect(Rect2(ICON.position + Vector2(4, 18), Vector2(ICON.size.x - 8, ICON.size.y - 18)), SporeMotherModels.STEM, true)
	draw_rect(Rect2(ICON.position + Vector2(-3, 2), Vector2(ICON.size.x + 6, 16)), SporeMotherModels.CAP, true)
	draw_rect(Rect2(ICON.position + Vector2(6, -4), Vector2(ICON.size.x - 12, 8)), SporeMotherModels.CAP_LIGHT, true)
	for spot: Vector2 in [Vector2(4, 6), Vector2(20, 2), Vector2(34, 8)]:
		draw_rect(Rect2(ICON.position + spot, Vector2(7, 5)), SporeMotherModels.SPOT, true)
	draw_rect(Rect2(ICON.position + Vector2(9, 26), Vector2(10, 3)), SporeMotherModels.EYE, true)
	draw_rect(Rect2(ICON.position + Vector2(27, 26), Vector2(10, 3)), SporeMotherModels.EYE, true)
	draw_rect(Rect2(ICON.position + Vector2(17, 36), Vector2(12, 3)), SporeMotherModels.EYE, true)
	draw_rect(Rect2(ICON.position + Vector2(5, 31), Vector2(6, 4)), SporeMotherModels.CHEEK, true)
	draw_rect(Rect2(ICON.position + Vector2(35, 31), Vector2(6, 4)), SporeMotherModels.CHEEK, true)


func _draw_golem_face() -> void:
	# The golem's face: grey stone, a heavy brow, glowing eyes, a crack of a mouth.
	draw_rect(ICON, GolemModels.STONE, true)
	draw_rect(Rect2(ICON.position + Vector2(-2, 8), Vector2(ICON.size.x + 4, 9)), GolemModels.STONE_DARK, true)
	draw_rect(Rect2(ICON.position + Vector2(8, 21), Vector2(10, 6)), GolemModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(28, 21), Vector2(10, 6)), GolemModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(15, 36), Vector2(16, 3)), GolemModels.STONE_DARK, true)
	draw_rect(Rect2(ICON.position + Vector2(4, -2), Vector2(18, 4)), GolemModels.MOSS, true)


func _draw_bar() -> void:
	# The bar: dark back, the fill, notches at every quarter, a thin outline.
	draw_rect(BAR, BAR_BACK, true)
	if _fraction > 0.0:
		var fill := Rect2(BAR.position, Vector2(BAR.size.x * _fraction, BAR.size.y))
		draw_rect(fill, FILL, true)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, 5)), FILL_TOP, true)
	for q in [0.25, 0.5, 0.75]:
		var x: float = BAR.position.x + BAR.size.x * q
		draw_line(Vector2(x, BAR.position.y), Vector2(x, BAR.end.y), NOTCH, 2.0)
	draw_rect(BAR, Color(1, 1, 1, 0.7), false, 2.0)


# --- M3 Task 2: each universe's boss -----------------------------------------------------------------

## The boss this bar shows (BossRules.words: its name, and its face on the left).
func use_boss(kind: StringName) -> void:
	var w := BossRules.words(kind)
	_names = [w.title, w.tired_title]
	var serpent := kind == BossRules.SERPENT
	var giant := kind == BossRules.FROST_GIANT
	if serpent != _serpent or giant != _giant or kind != _face:
		_serpent = serpent
		_giant = giant
		_face = kind if kind in [BossRules.SERPENT, BossRules.FROST_GIANT, BossRules.CAKE, BossRules.SKY_DRAGON,
			BossRules.SPORE_MOTHER] else BossRules.GOLEM
		queue_redraw()


func boss_title() -> String:
	return _names[0]


## The Sand Serpent's face: sandy scales, a pale jaw, green eyes, two fangs.
func _draw_serpent_face() -> void:
	draw_rect(ICON, SerpentModels.SCALES, true)
	draw_rect(Rect2(ICON.position + Vector2(0, 30), Vector2(ICON.size.x, 18)), SerpentModels.BELLY, true)
	draw_rect(Rect2(ICON.position + Vector2(20, -2), Vector2(6, 10)), SerpentModels.SCALES_DARK, true)
	draw_rect(Rect2(ICON.position + Vector2(7, 14), Vector2(10, 7)), SerpentModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(29, 14), Vector2(10, 7)), SerpentModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(12, 40), Vector2(4, 7)), SerpentModels.FANG, true)
	draw_rect(Rect2(ICON.position + Vector2(30, 40), Vector2(4, 7)), SerpentModels.FANG, true)


## The Frost Giant's face (M3 Task 3): icy blue skin, a white beard with icicles, glowing eyes, a crown of ice.
func _draw_giant_face() -> void:
	draw_rect(ICON, GiantModels.SKIN, true)
	draw_rect(Rect2(ICON.position + Vector2(-2, 10), Vector2(ICON.size.x + 4, 6)), GiantModels.SKIN_DARK, true)
	draw_rect(Rect2(ICON.position + Vector2(8, 18), Vector2(10, 6)), GiantModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(28, 18), Vector2(10, 6)), GiantModels.EYES, true)
	draw_rect(Rect2(ICON.position + Vector2(4, 30), Vector2(ICON.size.x - 8, 16)), GiantModels.FUR, true)
	for x in [10, 21, 32]:
		draw_rect(Rect2(ICON.position + Vector2(x, 44), Vector2(4, 6)), GiantModels.ICE, true)
	for x in [6, 20, 34]:
		draw_rect(Rect2(ICON.position + Vector2(x, -6), Vector2(6, 8)), GiantModels.ICE, true)

# --- M3 Task 4: the Cake Monster's face ------------------------------------------------------------------

## Whose face the bar shows (BossRules.GOLEM, SERPENT or CAKE).
func face() -> StringName:
	return _face


## The Cake Monster's face: sponge under pink frosting drips, big eyes with pink pupils, a wide grin.
func _draw_cake_face() -> void:
	draw_rect(ICON, CakeModels.SPONGE, true)
	draw_rect(Rect2(ICON.position, Vector2(ICON.size.x, 12)), CakeModels.PINK, true)
	for k in 4:
		draw_rect(Rect2(ICON.position + Vector2(4 + k * 11, 12), Vector2(6, 5 + (k % 2) * 4)), CakeModels.PINK_DARK, true)
	draw_rect(Rect2(ICON.position + Vector2(6, 20), Vector2(13, 11)), CakeModels.EYE_WHITE, true)
	draw_rect(Rect2(ICON.position + Vector2(27, 20), Vector2(13, 11)), CakeModels.EYE_WHITE, true)
	draw_rect(Rect2(ICON.position + Vector2(10, 23), Vector2(6, 6)), Color("ff4fa3"), true)
	draw_rect(Rect2(ICON.position + Vector2(31, 23), Vector2(6, 6)), Color("ff4fa3"), true)
	draw_rect(Rect2(ICON.position + Vector2(9, 36), Vector2(28, 7)), CakeModels.MOUTH, true)
	draw_rect(Rect2(ICON.position + Vector2(13, 36), Vector2(5, 3)), CakeModels.TOOTH, true)
	draw_rect(Rect2(ICON.position + Vector2(27, 36), Vector2(5, 3)), CakeModels.TOOTH, true)

# --- Owner 39: the Sky Dragon's face ----------------------------------------------------------------------------

## The Sky Dragon's face: teal scales, ivory horns, violet frills, golden eyes with dark slits, a pale jaw, nostrils.
func _draw_dragon_face() -> void:
	draw_rect(ICON, SkyDragonModels.SCALES, true)
	for x in [4, 32]:
		draw_rect(Rect2(ICON.position + Vector2(x, -7), Vector2(9, 11)), SkyDragonModels.HORN, true)
	draw_rect(Rect2(ICON.position + Vector2(-3, 16), Vector2(5, 14)), SkyDragonModels.VIOLET, true)
	draw_rect(Rect2(ICON.position + Vector2(ICON.size.x - 2, 16), Vector2(5, 14)), SkyDragonModels.VIOLET, true)
	draw_rect(Rect2(ICON.position + Vector2(0, 32), Vector2(ICON.size.x, 16)), SkyDragonModels.BELLY, true)
	for x in [7, 28]:
		draw_rect(Rect2(ICON.position + Vector2(x, 14), Vector2(11, 8)), SkyDragonModels.EYES, true)
		draw_rect(Rect2(ICON.position + Vector2(x + 4, 14), Vector2(3, 8)), SkyDragonModels.SLIT, true)
	for x in [15, 28]:
		draw_rect(Rect2(ICON.position + Vector2(x, 34), Vector2(4, 3)), SkyDragonModels.NOSTRIL, true)
	for x in [12, 31]:
		draw_rect(Rect2(ICON.position + Vector2(x, 44), Vector2(4, 5)), SkyDragonModels.TOOTH, true)
