class_name SchoolUi
extends RefCounted
## Owner #68 (spec §22): the School's look on top of UiKit and OnlineUi: the frame every page fits (inside the menu's
## panel on a 1280 × 720 screen and every wider phone), colours, drawn stars (the font has none), the teacher, words.

## Every School page fits this (the menu's panel adds 28 px each side: 1236 × 692 on a 720 px screen).
const FRAME := Vector2(1180, 636)
const TEAL := Color("139e9b")         # the brand's teal: the School's own colour
const PAPER := Color("fdf6e3")        # picture cards
const INK := Color("1f2a4a")          # lines and words on paper
const GOLD := Color("ffd23f")
const HINT := Color("ffd166")         # "Not yet" and hints: warm, never red
const GOOD := Color("8dff8a")
const SUBJECT_COLORS := {"maths": Color("3a7be8"), "science": Color("2fae4e"), "english": Color("f08a1c"),
	"history": Color("a8642a"), "geography": Color("128fa6"), "citizenship": Color("7b5cd6"), "computing": Color("3f51b5"),
	"art": Color("d9437a"), "music": Color("b03cc0"), "health_pe": Color("d6475a"), "design_tech": Color("6d8a1f"),
	"projects": Color("c49a12")}
const SUBJECT_WORDS := {"maths": "MATHS", "science": "SCIENCE", "english": "ENGLISH", "history": "HISTORY",
	"geography": "GEOGRAPHY", "citizenship": "CITIZENSHIP", "computing": "COMPUTING", "art": "ART", "music": "MUSIC",
	"health_pe": "HEALTH & PE", "design_tech": "DESIGN & TECH", "projects": "PROJECTS"}


static func button(text: String, color: Color = Color(), min_size: Vector2 = Vector2(240, 76)) -> Button:
	return OnlineUi.button(text, color, min_size)


static func words(text: String, font_size: int = 28, width: float = 600.0) -> Label:
	return OnlineUi.words(text, font_size, width)


## Professor Hoot: the game's own owl (AnimalPortrait) in a teacher's square cap.
static func teacher(px: float = 96.0) -> Control:
	return Teacher.new(px)


## A title that fits `max_width` (the font steps down from `start` to `least`; the default font, as the UiKit theme has).
static func fit_title(text: String, max_width: float, start: int = 36, least: int = 22) -> Label:
	var fs := start
	var font := ThemeDB.fallback_font
	while fs > least and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_width:
		fs -= 2
	var l := UiKit.title(text, fs)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if fs <= least else TextServer.OVERRUN_NO_TRIMMING
	return l


class Teacher:
	extends Control
	var owl: AnimalPortrait

	func _init(px: float) -> void:
		name = "Teacher"
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		owl = AnimalPortrait.new(&"owl", px * 0.84)
		owl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		owl.offset_top = px * 0.16
		owl.show_behind_parent = true   # the cap is drawn over the owl's head

	func _ready() -> void:
		UiMotion.bounce(self, 0.15)   # owner #94: Professor Hoot bounces hello
		add_child(owl)

	func _draw() -> void:   # the square cap and its gold tassel, over the owl's head
		var u := minf(size.x, size.y)
		var c := Vector2(size.x * 0.5, u * 0.2)
		var board := PackedVector2Array([c + Vector2(-0.34, 0.0) * u, c + Vector2(0.0, -0.12) * u, c + Vector2(0.34, 0.0) * u,
			c + Vector2(0.0, 0.12) * u])
		draw_rect(Rect2(c + Vector2(-0.16, 0.02) * u, Vector2(0.32, 0.12) * u), Color("22283b"))
		draw_colored_polygon(board, Color("2d3550"))
		draw_polyline(PackedVector2Array([board[0], board[1], board[2], board[3], board[0]]), Color("171b29"), maxf(1.0, u * 0.015))
		draw_line(c, c + Vector2(0.3, 0.08) * u, SchoolUi.GOLD, maxf(1.5, u * 0.025))
		draw_line(c + Vector2(0.3, 0.08) * u, c + Vector2(0.3, 0.24) * u, SchoolUi.GOLD, maxf(1.5, u * 0.025))
		draw_circle(c + Vector2(0.3, 0.26) * u, u * 0.035, SchoolUi.GOLD)


## A row of three stars, `count` of them gold.
static func stars(count: int, side: float = 28.0) -> Control:
	var s := StarRow.new()
	s.count = count
	s.custom_minimum_size = Vector2(side * 3.3, side)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## The points of a five-pointed star centred on `c`.
static func star_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts


class StarRow:
	extends Control
	var count := 0:
		set(v):
			count = v
			queue_redraw()

	func _draw() -> void:
		var h := minf(size.y, size.x / 3.3)
		var r := h * 0.5
		var top := (size.y - h) * 0.5
		for i in 3:
			var c := Vector2(r + i * h * 1.15, top + r)
			var pts := SchoolUi.star_points(c, r)
			if i < count:
				draw_colored_polygon(pts, SchoolUi.GOLD)
			var loop := pts.duplicate()
			loop.append(pts[0])
			draw_polyline(loop, SchoolUi.GOLD if i < count else Color(1, 1, 1, 0.45), 2.0, true)


## LISTEN: a big button that plays `sound` (SchoolSound data) on the sound effects' bus, from the start at every tap;
## `played` is told each time. Its player is its child and its meta "player".
static func listen_button(sound: Dictionary, played: Callable = Callable()) -> Button:
	var b := button("LISTEN", Color("9b59d0"), Vector2(260, 72))
	b.name = "Listen"
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var player := AudioStreamPlayer.new()
	player.bus = Audio.BUS
	player.stream = SchoolSound.stream(sound)
	b.add_child(player)
	b.set_meta(&"player", player)
	b.pressed.connect(func() -> void:
		player.stop()
		player.play()
		if played.is_valid():
			played.call())
	return b

