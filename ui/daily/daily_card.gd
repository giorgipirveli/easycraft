class_name DailyCard
extends PanelContainer
## Owner #85 (Wordle's lesson; brief 2026-09-30 item 1): the Daily Mission's result card, drawn by the game (the font has
## no stars: they are drawn). The date, the grade, the stars as a row of pictures, "Today's Mission: 4 of 5!", and the
## invite: "Play and learn with me!", the code big and the link. Never a question or an answer. The same card is shown
## on the page and rendered into a picture for SAVE and SHARE (CardPicture).

const SIZE := Vector2(560, 380)
const INK := Color("1f2a4a")
const PAPER := Color("fdf6e3")
const TEAL := Color("139e9b")

var day := 0
var grade := 0
var stars := ""
var code := ""


func _init(p_day: int = 0, p_grade: int = 0, p_stars: String = "", p_code: String = "") -> void:
	day = p_day
	grade = p_grade
	stars = p_stars
	code = p_code
	name = "DailyCard"
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := UiKit.box(PAPER, 22, 18)
	look.set_border_width_all(6)
	look.border_color = TEAL
	add_theme_stylebox_override("panel", look)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)
	v.add_child(_line("EASYCRAFT DAILY MISSION", 24, TEAL, "Head"))
	v.add_child(_line("%s  -  Grade %d" % [DailyMission.date_words(day), grade], 22, INK, "Date"))
	var row := StarLine.new()
	row.name = "Stars"
	row.stars = stars
	row.custom_minimum_size = Vector2(SIZE.x - 60.0, 74)
	v.add_child(row)
	v.add_child(_line(DailyMission.score_words(DailyMission.stars_in(stars)), 34, INK, "Score"))
	v.add_child(_line(PostcardRules.PLAY_WORDS, 20, INK.lightened(0.25), "Play"))
	if code != "":
		v.add_child(_line(code, 30, Color("c9901a"), "Code"))
	v.add_child(_line(DailyMission.link(code), 15, INK.lightened(0.3), "Link"))


func _line(text: String, font_size: int, color: Color, node_name: String) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = SIZE.x - 60.0
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)   # ink on paper
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	return l


## The day's answers as drawn pictures: a gold star for each right the first time, a soft circle for the others.
class StarLine:
	extends Control
	var stars := "":
		set(v):
			stars = v
			queue_redraw()

	func _draw() -> void:
		var n := DailyMission.SIZE
		var h := minf(size.y, size.x / (n * 1.25))
		var r := h * 0.46
		var step := h * 1.25
		var left := (size.x - step * (n - 1)) * 0.5
		for i in n:
			var c := Vector2(left + i * step, size.y * 0.5)
			var got := i < stars.length() and stars[i] == "1"
			if got:
				draw_colored_polygon(SchoolUi.star_points(c, r), SchoolUi.GOLD)
				var loop := SchoolUi.star_points(c, r)
				loop.append(loop[0])
				draw_polyline(loop, Color("c9901a"), 2.5, true)
			else:
				draw_circle(c, r * 0.62, Color(0.12, 0.16, 0.29, 0.14))
				draw_arc(c, r * 0.62, 0.0, TAU, 32, Color(0.12, 0.16, 0.29, 0.45), 2.5, true)
