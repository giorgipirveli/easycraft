class_name PostcardView
extends PanelContainer
## Owner #81, #82 (brief 2026-09-30 item 2): a picture postcard of a proud moment. A photo of the world (photo mode's
## camera: PhotoMode.capture) or, in the School, a drawn one (Professor Hoot and gold stars), a stamp-edged frame, the
## words in big letters ("I landed on the Moon!"), "Play and learn with me!", the invite code and the link. The same view
## is shown on the page and rendered into a picture for SAVE and SHARE (CardPicture).

const SIZE := Vector2(600, 380)
const PAPER := Color("fdf6e3")
const INK := Color("1f2a4a")
const EDGE := Color("d9463b")

var words := ""
var code := ""
var photo: Texture2D


func _init(p_words: String = "", p_code: String = "", p_photo: Texture2D = null) -> void:
	words = p_words
	code = p_code
	photo = p_photo
	name = "Postcard"
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := UiKit.box(PAPER, 10, 16)
	look.set_border_width_all(8)
	look.border_color = EDGE
	add_theme_stylebox_override("panel", look)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var picture := Control.new()
	picture.name = "Picture"
	picture.custom_minimum_size = Vector2(SIZE.x - 32.0, 196)
	picture.clip_contents = true
	if photo != null:
		var t := TextureRect.new()
		t.texture = photo
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.add_child(t)
	else:
		var scene := DrawnScene.new()
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.add_child(scene)
		var owl := SchoolUi.teacher(150.0)
		owl.anchor_left = 0.5
		owl.anchor_right = 0.5
		owl.anchor_top = 0.5
		owl.anchor_bottom = 0.5
		owl.offset_left = -75.0
		owl.offset_right = 75.0
		owl.offset_top = -85.0
		owl.offset_bottom = 65.0
		picture.add_child(owl)
	v.add_child(picture)
	v.add_child(_line(words, 32, INK, "Words"))
	v.add_child(_line(PostcardRules.PLAY_WORDS + ("  " + code if code != "" else ""), 22, Color("c9901a"), "Invite"))
	v.add_child(_line(DailyMission.link(code), 14, INK.lightened(0.3), "Link"))


func _line(text: String, font_size: int, color: Color, node_name: String) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = SIZE.x - 32.0
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)   # ink on paper
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	return l


## The School's postcard picture: a teal sky of gold stars (Professor Hoot stands in it).
class DrawnScene:
	extends Control

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("139e9b"))
		draw_rect(Rect2(Vector2(0, size.y * 0.78), Vector2(size.x, size.y * 0.22)), Color("2fae4e"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 14:
			var c := Vector2(rng.randf_range(20.0, size.x - 20.0), rng.randf_range(16.0, size.y * 0.6))
			if absf(c.x - size.x * 0.5) < 90.0:
				continue
			draw_colored_polygon(SchoolUi.star_points(c, rng.randf_range(8.0, 18.0)), SchoolUi.GOLD)
