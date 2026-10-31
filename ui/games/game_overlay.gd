class_name GameOverlay
extends Control
## The co-op games' screens over the world (M4 Wave 3, agent H), under the HUD's buttons: the seeker's
## friendly counting screen (the view covered while the others hide: a big number counting down from 30,
## kind words, a sleepy face; nothing flashes) and the end card (the round's words and everyone's sticker,
## a few seconds). Never takes a tap. It asks its GamesDirector what to show.

const SKY := Color("7cc6f2")
const INK := Color(0.1, 0.13, 0.22)
const CARD := Color(0.08, 0.1, 0.17, 0.92)
const STICKER := Color("ffd23f")
const END_SECONDS := GameRules.OVER_TIME

var director: GamesDirector

var counting := Control.new()
var number := Label.new()
var end_card := PanelContainer.new()
var end_text := Label.new()
var sticker_text := Label.new()
var _end_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	_build_counting()
	_build_end_card()
	if director:
		director.ended.connect(show_end)
		director.sticker_received.connect(show_sticker)


func _build_counting() -> void:
	counting.name = "Counting"
	counting.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(counting)
	counting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sky := ColorRect.new()
	sky.color = SKY
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counting.add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var face := SleepyFace.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counting.add_child(face)
	face.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	face.offset_left = -70
	face.offset_right = 70
	face.offset_top = 70
	face.offset_bottom = 190
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	counting.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 150
	number.name = "Number"
	number.add_theme_font_size_override("font_size", 150)
	number.add_theme_color_override("font_color", Color.WHITE)
	number.add_theme_color_override("font_outline_color", INK)
	number.add_theme_constant_override("outline_size", 16)
	for l: Label in [number, _line(GameWords.YOU_SEEK, 34), _line("Everyone is hiding. No peeking!", 28)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	counting.visible = false


func _line(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	return l


func _build_end_card() -> void:
	end_card.name = "EndCard"
	end_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_theme_stylebox_override("panel", UiKit.box(CARD, 22, 24))
	add_child(end_card)
	end_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	end_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	end_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_child(v)
	var star := StarPicture.new()
	star.custom_minimum_size = Vector2(96, 96)
	star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(star)
	for l: Label in [end_text, sticker_text]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	end_text.add_theme_font_size_override("font_size", 34)
	sticker_text.add_theme_font_size_override("font_size", 26)
	sticker_text.add_theme_color_override("font_color", STICKER)
	end_card.visible = false


## The round ended: its words (the sticker's line comes with sticker_received).
func show_end(text: String) -> void:
	end_text.text = text
	sticker_text.text = ""
	end_card.visible = true
	_end_t = END_SECONDS


func show_sticker(text: String) -> void:
	sticker_text.text = text
	end_card.visible = true
	_end_t = maxf(_end_t, END_SECONDS)


func _process(delta: float) -> void:
	var count := director != null and director.counting_here()
	if counting.visible != count:
		counting.visible = count
	if count:
		number.text = str(maxi(ceili(director.hide.time_left()), 0))
	if _end_t > 0.0:
		_end_t -= delta
		if _end_t <= 0.0:
			end_card.visible = false


## A sleepy face with closed eyes (the seeker counting), drawn in code.
class SleepyFace:
	extends Control

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.45
		draw_circle(c, r, Color("ffd9a8"))
		draw_arc(c + Vector2(-r * 0.38, -r * 0.1), r * 0.2, 0.2, PI - 0.2, 12, GameOverlay.INK, 5.0)
		draw_arc(c + Vector2(r * 0.38, -r * 0.1), r * 0.2, 0.2, PI - 0.2, 12, GameOverlay.INK, 5.0)
		draw_arc(c + Vector2(0, r * 0.3), r * 0.25, 0.3, PI - 0.3, 12, GameOverlay.INK, 5.0)


## The round's sticker: a gold star with a smile, drawn in code.
class StarPicture:
	extends Control

	func _draw() -> void:
		var c := size * 0.5
		var pts := PackedVector2Array()
		for i in 10:
			var r := minf(size.x, size.y) * (0.48 if i % 2 == 0 else 0.22)
			var a := -PI * 0.5 + float(i) * TAU / 10.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, GameOverlay.STICKER)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 3.0)
		draw_arc(c + Vector2(0, 2), size.x * 0.1, 0.3, PI - 0.3, 10, GameOverlay.INK, 3.0)
