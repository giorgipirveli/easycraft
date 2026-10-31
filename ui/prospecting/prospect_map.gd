class_name ProspectMap
extends Control
## A prospecting quest's map (spec §26.2: "read a map: coordinates, compass directions, the scale"): this world's ground
## round Gemma's camp and the quest's X, seen from above, north (-z) up, on paper: water blue, the land green (the
## desert sand, its mesas red-brown), higher ground darker; a grid of squares (letters A-H across the top, numbers 1-8
## down the side), the camp's tent, the red X, a north arrow and the scale bar. Drawn once into a small picture when the
## map is set (`sampler` gives each spot's colour), then only redrawn.

const MAP_PX := 250.0
const LABEL_PX := 26.0
const SAMPLES := 48
## Spec §26.5: a planet's map is drawn from fewer samples (its colours cost more to work out: the map opens at once).
const SPACE_SAMPLES := 32
const PAPER := Color("f3e2b8")
const INK := Color("5a3d1e")
const X_COLOR := Color("d9302a")

## {camp: Vector3, target: Vector3, frame: {corner: Vector2, size, squares, square}, kind}.
var data: Dictionary = {}
## (x, z) -> Color: the ground's colour there (the director reads the terrain); a plain land colour without it.
var sampler: Callable = func(_x: float, _z: float) -> Color: return Color("9cc27a")
## Samples across the picture (SAMPLES; SPACE_SAMPLES on the planets).
var samples := SAMPLES
var picture: ImageTexture


func _init(map: Dictionary = {}, colour_at: Callable = Callable(), across: int = SAMPLES) -> void:
	samples = clampi(across, 8, SAMPLES)
	custom_minimum_size = Vector2(580, MAP_PX + LABEL_PX + 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if colour_at.is_valid():
		sampler = colour_at
	set_map(map)


func set_map(map: Dictionary) -> void:
	data = map
	picture = null
	if not data.is_empty():
		var img := Image.create(samples, samples, false, Image.FORMAT_RGB8)
		var frame: Dictionary = data.frame
		var corner: Vector2 = frame.corner
		var size := float(frame.size)
		for j in samples:
			for i in samples:
				var c: Color = sampler.call(corner.x + (i + 0.5) * size / samples, corner.y + (j + 0.5) * size / samples)
				img.set_pixel(i, j, c.lerp(PAPER, 0.25))
		picture = ImageTexture.create_from_image(img)
	queue_redraw()


## Where a world position is on the drawn map (the map's square starts at (LABEL_PX, LABEL_PX)).
func to_map(pos: Vector3) -> Vector2:
	var frame: Dictionary = data.frame
	var corner: Vector2 = frame.corner
	var k := MAP_PX / float(frame.size)
	return Vector2(LABEL_PX, LABEL_PX) + (Vector2(pos.x, pos.z) - corner) * k


func _draw() -> void:
	if data.is_empty():
		return
	var frame: Dictionary = data.frame
	var squares := int(frame.squares)
	var sq := int(frame.square)
	var origin := Vector2(LABEL_PX, LABEL_PX)
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_PX + LABEL_PX + 6, MAP_PX + LABEL_PX + 6)), PAPER)
	if picture:
		draw_texture_rect(picture, Rect2(origin, Vector2(MAP_PX, MAP_PX)), false)
	var step := MAP_PX / squares
	for i in squares + 1:
		var w := 2.0 if i == 0 or i == squares else 1.0
		draw_line(origin + Vector2(i * step, 0), origin + Vector2(i * step, MAP_PX), Color(INK, 0.55), w)
		draw_line(origin + Vector2(0, i * step), origin + Vector2(MAP_PX, i * step), Color(INK, 0.55), w)
	for i in squares:
		draw_string(font, Vector2(origin.x + i * step, LABEL_PX - 6), SurveyRules.LETTERS[i], HORIZONTAL_ALIGNMENT_CENTER,
			step, 18, INK)
		draw_string(font, Vector2(0, origin.y + i * step + step * 0.5 + 7), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER,
			LABEL_PX, 18, INK)
	# The camp: a little tent.
	var camp := to_map(data.camp)
	draw_colored_polygon(PackedVector2Array([camp + Vector2(-10, 7), camp + Vector2(10, 7), camp + Vector2(0, -10)]),
		Color("f08a1c"))
	draw_line(camp + Vector2(0, -10), camp + Vector2(0, 7), INK, 1.5)
	# The X.
	var x := to_map(data.target)
	draw_line(x + Vector2(-9, -9), x + Vector2(9, 9), X_COLOR, 5.0)
	draw_line(x + Vector2(9, -9), x + Vector2(-9, 9), X_COLOR, 5.0)
	# The key on the right: north, the scale, what the marks mean.
	var kx := LABEL_PX + MAP_PX + 30.0
	draw_line(Vector2(kx + 20, 70), Vector2(kx + 20, 22), INK, 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(kx + 20, 10), Vector2(kx + 10, 28), Vector2(kx + 30, 28)]), INK)
	draw_string(font, Vector2(kx + 38, 40), "N  north", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	draw_line(Vector2(kx, 110), Vector2(kx + step, 110), INK, 4.0)
	draw_line(Vector2(kx, 102), Vector2(kx, 118), INK, 2.0)
	draw_line(Vector2(kx + step, 102), Vector2(kx + step, 118), INK, 2.0)
	draw_string(font, Vector2(kx + step + 10, 118), "%d m" % sq, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	draw_string(font, Vector2(kx, 142), "one square", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	draw_colored_polygon(PackedVector2Array([Vector2(kx, 190), Vector2(kx + 20, 190), Vector2(kx + 10, 173)]), Color("f08a1c"))
	draw_string(font, Vector2(kx + 30, 190), "our camp", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_line(Vector2(kx + 2, 210), Vector2(kx + 18, 226), X_COLOR, 4.0)
	draw_line(Vector2(kx + 18, 210), Vector2(kx + 2, 226), X_COLOR, 4.0)
	draw_string(font, Vector2(kx + 30, 226), "what we look for", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)


## The ground's colour for a map from a terrain (the director's sampler): water, sand, grass by height, rock and snow
## high up; the desert's dunes, mesas and oases; spec §26.5: the Moon's grey dust, darker in its craters' bowls and
## paler on their rims, and the colony's domes; Mars's red plains, pale river beds, the dark volcano, the canyon and
## the white caps.
static func terrain_colour(shape: MeadowsShape, x: float, z: float, craters: SpaceDepositSites.Cols = null) -> Color:
	var xi := floori(x)
	var zi := floori(z)
	if shape is SpaceShape:
		return _space_colour(shape as SpaceShape, xi, zi, craters)
	if shape is DesertShape:
		var c := (shape as DesertShape).column(xi, zi)
		if c.x < MeadowsShape.SEA_LEVEL:
			return Color("4f8fd6")
		match c.y:
			DesertShape.MESA:
				return Color("b0573a").darkened(clampf((c.x - c.z) / 40.0, 0.0, 0.3))
			DesertShape.OASIS:
				return Color("6fae4e")
		return Color("e3cf94").darkened(clampf((c.x - c.z) / 30.0, 0.0, 0.2))
	var h := shape.height_at(xi, zi)
	if h < MeadowsShape.SEA_LEVEL:
		return Color("4f8fd6") if not shape.is_river(xi, zi) else Color("6aa8e8")
	if h <= MeadowsShape.SEA_LEVEL + 1:
		return Color("e6d59c")
	if h > 90:
		return Color("f4f4f4")
	if h > 70:
		return Color("9a9a9a")
	return Color("8cc26a").darkened(clampf((h - 30) / 60.0, 0.0, 0.45))


## Spec §26.5: a planet's colour at (x, z), cheaply (the map samples 32 × 32 columns as the board opens): the Moon from
## its craters alone (`craters`: their cells drawn once for the whole map), Mars from its region (MarsTerrain.column
## without the craters' relief) and its height.
static func _space_colour(sp: SpaceShape, x: int, z: int, craters: SpaceDepositSites.Cols = null) -> Color:
	if sp.colony != null and sp.colony.covers(x, z, -8):
		return Color("dfe6ee")   # the colony's domes and floors
	if sp.mars != null:
		var c := sp.mars.column(x, z, 0.0)
		var h := c >> 4
		match c & 15:
			MarsTerrain.NORTH_CAP, MarsTerrain.SOUTH_CAP:
				return Color("f2f5f8")
			MarsTerrain.FROST_N, MarsTerrain.FROST_S:
				return Color("e6dcd4")
			MarsTerrain.VOLCANO, MarsTerrain.CALDERA:
				return Color("7a4a38").lightened(clampf((h - MarsTerrain.BASE) / 160.0, 0.0, 0.3))
			MarsTerrain.CANYON:
				return Color("8e4a2c")
			MarsTerrain.VALLEY:
				return Color("d9a57e")
		return Color("c46a3c").darkened(clampf((MarsTerrain.BASE - h) / 30.0, -0.15, 0.2))
	var crater := craters.crater_only(x, z) if craters != null else sp.crater_depth(x, z)
	if crater < -0.5:
		return Color("8e929c").darkened(clampf(-crater / 12.0, 0.0, 0.35))   # a bowl: darker, deeper darker
	if crater > 0.3:
		return Color("d2d5da")   # a raised rim: paler
	return Color("b4b8c0")
