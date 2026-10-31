class_name UnitStop
extends Button
## Owner #68 (spec §22.1): a unit's stop on the School's map: its number, its title, its stars; a badge once it is
## mastered; a green leaf when a review would help; grey with "Coming soon" when its lessons are not written yet.

const SIZE := Vector2(180, 128)
const BODY_TOP := 24.0   # the title starts under the corner row (the number, the leaf, the medal)

var unit_id := ""
var stars := 0
var review := false
var written := true
var color := UiKit.BLUE
var number := 0


func _init(unit: Dictionary, progress: Dictionary, today: int, subject_color: Color) -> void:
	unit_id = str(unit.get("id", ""))
	name = "Stop_" + unit_id
	written = Curriculum.has_content(unit_id)
	stars = MasteryRules.stars(progress)
	review = written and MasteryRules.review_due(progress, today)
	color = subject_color if written else Color(0.36, 0.38, 0.45)
	custom_minimum_size = SIZE
	text = ""
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var c := color.lightened(0.12) if state == "hover" else (color.darkened(0.15) if state == "pressed" else color)
		add_theme_stylebox_override(state, UiKit.box(c, 16, 8))
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 8
	col.offset_right = -8
	col.offset_top = BODY_TOP
	col.offset_bottom = -6
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number = int(unit.get("number", 0))
	var title := Label.new()
	title.name = "Title"
	title.text = str(unit.get("title", ""))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(SIZE.x - 16, 0)
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var n := title.text.length()
	title.add_theme_font_size_override("font_size", 19 if n <= 22 else (16 if n <= 28 else 15))
	if Vr.active():   # owner #101: in a headset its words are 24 px (VrReadability): two lines, then "…" (the unit has all)
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	if written:
		var row := SchoolUi.stars(stars, 20.0)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(row)
	else:
		var soon := Label.new()
		soon.text = SchoolWords.COMING_SOON
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		soon.add_theme_font_size_override("font_size", 15)
		soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(soon)
	add_child(col)


func body_top() -> float:
	return BODY_TOP


func _draw() -> void:
	var font := get_theme_default_font()
	draw_string(font, Vector2(10, 24), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	if stars >= MasteryRules.MASTERED:   # the unit's badge: a gold medal in the top-right corner
		var c := Vector2(size.x - 18, 16)
		draw_circle(c, 12.0, SchoolUi.GOLD)
		draw_arc(c, 12.0, 0, TAU, 24, Color("b8860b"), 2.5, true)
		draw_colored_polygon(SchoolUi.star_points(c, 7.0), Color("fff4b0"))
	if review:   # a review would help: a green leaf in the top-left corner, beside the number
		var c := Vector2(48, 16)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 6), c + Vector2(-2, -10), c + Vector2(12, -8),
			c + Vector2(6, 6)]), Color("8dff8a"))
		draw_line(c + Vector2(-10, 6), c + Vector2(8, -6), Color("2e7d32"), 2.0)
