class_name DailyWeek
extends Control
## Owner #85 (brief 2026-09-30 item 1: "a calm streak that forgives"): the last 7 days of the Daily Mission, oldest
## first, each a small gold star (a mission day) or a sleeping moon (a rest day), with its weekday's letter; today has a
## ring. Never "missed", never a count that falls (DailyData.week).

const LETTERS: Array[String] = ["S", "M", "T", "W", "T", "F", "S"]   # Time's weekday: 0 is Sunday

var row: Array[int] = []
var today := 0


func _init(p_row: Array[int] = [], p_today: int = 0) -> void:
	row = p_row
	today = p_today
	name = "DailyWeek"
	custom_minimum_size = Vector2(420, 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := get_theme_default_font()
	var step := size.x / 7.0
	var r := minf(step * 0.34, size.y * 0.3)
	for i in 7:
		var c := Vector2(step * (i + 0.5), r + 4.0)
		var done := i < row.size() and row[i] == 1
		if done:
			draw_colored_polygon(SchoolUi.star_points(c, r), SchoolUi.GOLD)
		else:   # a rest day: a quiet crescent moon
			draw_circle(c, r * 0.62, Color(0.8, 0.84, 1.0, 0.55))
			draw_circle(c + Vector2(r * 0.3, -r * 0.18), r * 0.55, Color(0.08, 0.1, 0.17, 0.9))
		if i == 6:
			draw_arc(c, r * 1.08, 0.0, TAU, 36, Color(1, 1, 1, 0.85), 2.0, true)
		var wd := int(Time.get_date_dict_from_unix_time((today - 6 + i) * DailyMission.DAY_SECONDS).weekday)
		var letter := LETTERS[clampi(wd, 0, 6)]
		if font:
			var fs := 18
			var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(c.x - w * 0.5, size.y - 4.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(1, 1, 1, 0.75))
