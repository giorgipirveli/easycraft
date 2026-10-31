extends SceneTree
## Generates data/minds/thoughts.png (M2 Task 18): 8 × 1 tiles of 32 px, the pictures of creatures'
## thought bubbles (ids: core/mind/thought.gd) — a white cloud with a picture inside: a heart, a
## question mark, zzz, a drumstick, a sweat drop, a light bulb. Original pixel art, no randomness.
## Run: godot --headless --path . --script res://tools/make_thought_pictures.gd

const TILE := 32
const COLUMNS := 8
const OUT := "res://data/minds/thoughts.png"
const OUTLINE := Color("2a2230")
const CLOUD := Color("fbfbff")

var img: Image


func _init() -> void:
	img = Image.create(TILE * COLUMNS, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var draw := [_heart, _question, _zzz, _drumstick, _sweat, _bulb]
	for i in draw.size():
		var t := Vector2i(i, 0)
		_cloud(t)
		(draw[i] as Callable).call(t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("THOUGHTS saved err=", err)
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _disc(t: Vector2i, cx: float, cy: float, r: float, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_px(t, x, y, c)


func _poly(t: Vector2i, points: PackedVector2Array, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_px(t, x, y, c)


func _line(t: Vector2i, a: Vector2, b: Vector2, width: float, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= width * 0.5:
				_px(t, x, y, c)


## The white thought cloud (three puffs and two little bubbles below), outlined.
func _cloud(t: Vector2i) -> void:
	var shape := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	shape.fill(Color(0, 0, 0, 0))
	var puffs := [[16.0, 13.0, 11.0], [8.5, 15.0, 6.5], [23.5, 15.0, 6.5], [16.0, 18.0, 8.0],
		[6.0, 27.0, 2.6], [3.0, 30.5, 1.4]]
	for y in TILE:
		for x in TILE:
			for p: Array in puffs:
				if Vector2(x + 0.5 - p[0], y + 0.5 - p[1]).length() <= p[2]:
					shape.set_pixel(x, y, CLOUD)
	for y in TILE:
		for x in TILE:
			if shape.get_pixel(x, y).a > 0.5:
				_px(t, x, y, CLOUD)
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < TILE and n.y < TILE and shape.get_pixel(n.x, n.y).a > 0.5:
					_px(t, x, y, OUTLINE)
					break


func _heart(t: Vector2i) -> void:
	var red := Color("ff4f7b")
	_disc(t, 12.5, 12.0, 4.2, red)
	_disc(t, 19.5, 12.0, 4.2, red)
	_poly(t, PackedVector2Array([Vector2(8.4, 13.5), Vector2(23.6, 13.5), Vector2(16, 22.5)]), red)
	_disc(t, 11.5, 11.0, 1.3, Color("ffc2d1"))


func _question(t: Vector2i) -> void:
	var blue := Color("2f7fe0")
	_line(t, Vector2(11.5, 10.5), Vector2(13.5, 7.5), 3.0, blue)
	_line(t, Vector2(13.5, 7.5), Vector2(18.5, 7.5), 3.0, blue)
	_line(t, Vector2(18.5, 7.5), Vector2(20.5, 10.5), 3.0, blue)
	_line(t, Vector2(20.5, 10.5), Vector2(16.0, 15.0), 3.0, blue)
	_line(t, Vector2(16.0, 15.0), Vector2(16.0, 17.0), 3.0, blue)
	_disc(t, 16.0, 21.5, 1.9, blue)


func _zzz(t: Vector2i) -> void:
	var purple := Color("7b5be0")
	_z(t, Vector2(8, 15), 5.0, purple)
	_z(t, Vector2(15, 10), 6.0, purple)
	_z(t, Vector2(19, 17), 4.0, purple)


func _z(t: Vector2i, at: Vector2, s: float, c: Color) -> void:
	_line(t, at, at + Vector2(s, 0), 2.0, c)
	_line(t, at + Vector2(s, 0), at + Vector2(0, s), 2.0, c)
	_line(t, at + Vector2(0, s), at + Vector2(s, s), 2.0, c)


func _drumstick(t: Vector2i) -> void:
	var bone := Color("f3efe6")
	_line(t, Vector2(17, 15), Vector2(23, 21), 3.0, bone)
	_disc(t, 23.5, 20.0, 1.8, bone)
	_disc(t, 21.5, 22.5, 1.8, bone)
	_disc(t, 13.0, 11.5, 6.0, Color("b8612e"))
	_disc(t, 11.5, 10.0, 2.2, Color("dd8a4f"))


func _sweat(t: Vector2i) -> void:
	var drop := Color("5ec8f2")
	_disc(t, 16.0, 16.5, 5.0, drop)
	_poly(t, PackedVector2Array([Vector2(11.3, 15.0), Vector2(20.7, 15.0), Vector2(16.0, 6.0)]), drop)
	_disc(t, 14.0, 17.0, 1.4, Color("d9f4ff"))


func _bulb(t: Vector2i) -> void:
	var glass := Color("ffd23f")
	_disc(t, 16.0, 12.5, 5.5, glass)
	_line(t, Vector2(14, 17), Vector2(18, 17), 3.0, glass)
	_line(t, Vector2(14, 19.5), Vector2(18, 19.5), 2.0, Color("8a8f99"))
	_line(t, Vector2(14.5, 21.5), Vector2(17.5, 21.5), 2.0, Color("8a8f99"))
	_disc(t, 14.2, 10.5, 1.5, Color("fff6c8"))
	for a in [PI * 1.0, PI * 1.25, PI * 1.5, PI * 1.75, 0.0]:
		var d := Vector2(cos(a), sin(a))
		_line(t, Vector2(16, 12.5) + d * 7.5, Vector2(16, 12.5) + d * 9.0, 1.5, Color("f0a020"))
