class_name ShortBackdrop
extends Control
## A Short's background (owner #94, spec §5.12b), drawn on the whole stage with a little life of its own that follows
## the time (so a seek shows the same frame): sky (drifting clouds), space (twinkling stars), paper (an exercise book),
## grass, sea (a moving wave), night, sunset, chalk (a board), lab, or tint (the scene's own colour, soft lights
## floating up). The game's bright palette; 2D draw calls only. Owner #96's review: a backdrop never draws a Sun or a
## Moon of its own (a Short's own showed twice), and its ground is above the caption's band.

const STARS := 70
const STAR_SEED := 9404

var kind := "sky"
var tint := Color("7b4bd6")
var time := 0.0
var _stars: PackedVector3Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = ShortRules.STAGE
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for i in STARS:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.0, TAU)))


func show_scene(scene: Dictionary, t: float) -> void:
	var k := str(scene.get("background", "sky"))
	var c := ShortRules.colour(scene.get("tint"), tint)
	if k != kind or c != tint or t != time:
		kind = k
		tint = c
		time = t
		queue_redraw()


func _draw() -> void:
	var s := ShortRules.STAGE
	match kind:
		"sky":
			_gradient(Color("4f9fe8"), Color("c4e6ff"))
			_clouds(Color(1, 1, 1, 0.9))
		"space":
			_gradient(Color("070a1f"), Color("1d1f52"))
			_twinkle(1.0)
		"paper":
			draw_rect(Rect2(Vector2.ZERO, s), Color("fdf6e3"))
			for i in 24:
				draw_line(Vector2(0, 40 + i * 28), Vector2(s.x, 40 + i * 28), Color(0.4, 0.6, 0.85, 0.25), 1.5)
			draw_line(Vector2(44, 0), Vector2(44, s.y), Color(0.9, 0.3, 0.3, 0.35), 2.0)
		"grass":
			_gradient(Color("5aa9f0"), Color("d6efff"))
			_clouds(Color(1, 1, 1, 0.85))
			_hill(Color("5cb85c"), 0.62, 0.0)   # the ground shows above the caption: things stand on it
			_hill(Color("3f9a47"), 0.7, 1.7)
		"sea":
			_gradient(Color("5aa9f0"), Color("d6efff"))
			_clouds(Color(1, 1, 1, 0.8))
			var pts := PackedVector2Array([Vector2(s.x, s.y), Vector2(0, s.y)])
			for i in 37:
				var x := s.x * i / 36.0
				pts.append(Vector2(x, s.y * 0.62 + sin(x * 0.04 + time * 1.6) * 8.0))
			draw_colored_polygon(pts, Color("2a7fd4"))
		"night":
			_gradient(Color("0c1233"), Color("2c3a78"))
			_twinkle(0.6)
		"sunset":
			_gradient(Color("5b3fa6"), Color("ff9f45"))
		"chalk":
			draw_rect(Rect2(Vector2.ZERO, s), Color("7a4a24"))
			draw_rect(Rect2(Vector2(10, 10), s - Vector2(20, 20)), Color("2f5d46"))
			for i in 6:
				draw_line(Vector2(30 + i * 60, 60 + i * 70), Vector2(80 + i * 50, 58 + i * 70), Color(1, 1, 1, 0.06), 6.0)
		"lab":
			_gradient(Color("d8f3f0"), Color("9fd9d2"))
			for y in range(0, int(s.y), 40):
				draw_line(Vector2(0, y), Vector2(s.x, y), Color(1, 1, 1, 0.35), 1.0)
			for x in range(0, int(s.x), 40):
				draw_line(Vector2(x, 0), Vector2(x, s.y), Color(1, 1, 1, 0.35), 1.0)
		_:
			_gradient(tint.lightened(0.18), tint.darkened(0.3))
			for i in 9:   # soft lights floating up
				var x := fposmod(i * 97.0 + sin(time * 0.5 + i) * 14.0, s.x)
				var y := fposmod(s.y - (i * 83.0 + time * (14.0 + i * 3.0)), s.y + 60.0) - 30.0
				draw_circle(Vector2(x, y), 10.0 + (i % 3) * 7.0, Color(1, 1, 1, 0.08))


func _gradient(top: Color, bottom: Color) -> void:
	var s := ShortRules.STAGE
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _twinkle(strength: float) -> void:
	var s := ShortRules.STAGE
	for st in _stars:
		var a := (0.55 + 0.45 * sin(time * 2.2 + st.z)) * strength
		draw_circle(Vector2(st.x * s.x, st.y * s.y), 1.3 + fposmod(st.z, 1.2), Color(1, 1, 0.95, a))


func _clouds(col: Color) -> void:
	var s := ShortRules.STAGE
	for i in 3:
		var x := fposmod(i * 150.0 + time * (8.0 + i * 4.0), s.x + 160.0) - 80.0
		var y := 60.0 + i * 55.0
		for k: Vector3 in [Vector3(-26, 4, 22), Vector3(0, -6, 30), Vector3(28, 4, 22)]:
			draw_circle(Vector2(x + k.x, y + k.y), k.z, col)


func _hill(col: Color, top: float, phase: float) -> void:
	var s := ShortRules.STAGE
	var pts := PackedVector2Array([Vector2(s.x, s.y), Vector2(0, s.y)])
	for i in 25:
		var x := s.x * i / 24.0
		pts.append(Vector2(x, s.y * top + sin(x * 0.012 + phase) * 16.0))
	draw_colored_polygon(pts, col)
