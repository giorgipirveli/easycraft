class_name UniverseArt
extends RefCounted
## Every universe's own little scene (M5 Task 2, spec §15.2), drawn from its own block tiles and colours in owner
## #43's look: a sky from its colours with its sun, soft hills far away, then a row of its blocks in front (a
## ROWS x COLUMNS layout: Green Meadows' grass hill and tree, the desert's pyramid and cacti, Frostpeak's igloo and
## pine, the Candy Kingdom's candy canes, gumdrops and lollipop by a chocolate river, the Dragon Realm's floating
## island with golden spires over a sea of clouds at sunrise) and the brand's orange buddy exploring it.
## The universe cards (UniverseCard) and a universe's own menu screens (UniverseBackdrop) draw it; nothing is
## loaded but the block pages the icons already use, and it is drawn only when a card or a panel redraws.

const ROWS := 8
const COLUMNS := 12
const TOP := 0
const SIDE := 1
const BUDDY := Color("f28c28")        # the brand's buddy (tools/make_brand_art.py)
const BUDDY_DARK := Color("c96a12")
const EYE := Color.WHITE
const PUPIL := Color("1d1a24")

## The scenes, top row first ('.' is sky; letters are blocks of the universe's legend; 'b' is where the buddy
## stands; 'd' a dark doorway; 's' a lollipop's white stick).
const _LAYOUTS := {
	1: ["............",
		"........LLL.",
		".......LLLLL",
		"........LTL.",
		".........T..",
		"GGG..b...T..",
		"DDDGGGGGGGGG",
		"DDDDDDDDDDDD"],
	2: ["............",
		"............",
		"......p.....",
		".....ppp....",
		".C..ppppp..C",
		".C.ppppppp.C",
		"SSSSSSSSSSSS",
		"rrrrrrrrrrrr"],
	3: ["............",
		".........N..",
		"........NNN.",
		".......NNNNN",
		"..BBB....L..",
		".BBdBB.b.L..",
		"WWWWWWWWWWWW",
		"KKKKKKKKKKKK"],
	4: ["............",
		"..........o.",
		".........ooo",
		"..c.......s.",
		"..c..g....s.",
		"..c.ggg.b.s.",
		"FFFFFF~~FFFF",
		"KKKKKKCCKKKK"],
	5: ["............",
		"........y...",
		"..y.....y...",
		"..y..GGGGGG.",
		".GGGGffffff.",
		"..ffffffff..",
		"cc..DDDD..cc",
		"ccccc.cccccc"],
	6: ["WWWWWWWWWWWW",    # universe 6: the Glow Caves: a glow-worm ceiling, stalactites, a giant blue glowshroom, a rose
		".t..t....t..",    # one, a selenite crystal, the buddy on glow moss by a cave pool's pebbles
		"........BBB.",
		".RRR.....s..",
		"..s..Y...s..",
		"..s.YY.b.s..",
		"MMMMMMMLLMMM",
		"CCCCCCCCCCCC"],
	16: ["............",   # owner #55: the Moon: the Moon Base's dome on silvery dust, a crater, a crystal
		"............",
		"............",
		".......PPP..",
		"......PPOPP.",
		"..y..bPPPPP.",
		"MMM.MMMMMMMM",
		"RRRMRRRRRRRR"],
	17: ["............",   # Planet Boing: a spring mushroom, the Boing Tower's pads, a jelly pool in the moss
		"........BBB.",
		"..CCC....S..",
		"...S...CCS..",
		"...S.....SCC",
		"...S.b...S..",
		"MMMMMMJJMMMM",
		"LLLLLLLLLLLL"],
	18: ["............",   # Rainbow Planet: the Rainbow Arch on striped terraces, a prism spire
		"...rrrrrr...",
		"..rooooooor.",
		".royy..yyor.",
		".roy....yor.",
		"Gro.b....orG",
		"OOGGGGGGGGOO",
		"YYYYYYYYYYYY"],
	19: ["............",   # cosmos: Mars: the rover on red dust (its mast and eyes), the buddy, a gypsum crystal
		"............",
		"........PL..",
		"........P...",
		"....SSSSSS..",
		"..b.PPPPPP..",
		"MMMMWMMWMWMM",
		"RRRRRRRRRRRR"],
	20: ["............",   # cosmos: Europa: the Ice Lander on white ice by a reddish crack, the buddy; Jupiter is drawn
		"............",
		"............",
		"......L.....",
		".....PPPPP..",
		"..b..m...m..",
		"EEEERREEEEEE",
		"DDDDDDDDDDDD"],
	21: ["............",   # cosmos: Io: the Volcano Lander on yellow sulphur by a glowing lava pool, the buddy; Jupiter
		"............",    # and a volcano's plume are drawn
		"............",
		"......C.....",
		".....TTTT...",
		"..b..L..L...",
		"SSOSBHHBSSFS",
		"RRRRRRRRRRRR"],
	22: ["............",   # cosmos: Titan: the Landing Probe on orange soil, its parachute behind it, a methane lake, the
		"............",    # buddy; Saturn with its rings in the orange haze is drawn
		"............",
		"............",
		"........L...",
		".......PPPP.",
		"..b.CC..PP.K",
		"mmSSSSKSSSSS"],
	23: ["............",   # cosmos: Mercury: the Sunshade Lander (its white sunshade, its body, legs and lamp) on grey dust
		"............",    # by a bright young crater, the thermometer with its red bulb, the buddy; the huge white Sun
		"......W.....",    # is drawn
		"......W..L..",
		"......WHHHH.",
		".T....WH..H.",
		".Bb....H..H.",
		"DDRRDDDDKDDD"],
	24: ["............",   # cosmos: Venus's cloud city: the Research Blimp (white, a teal stripe, its fins) over its gondola,
		".SSSSSSSS...",    # lamps on a deck over a float hull, the buddy; the hazy Sun and the yellow clouds far below
		"FSSTTTTSSSL.",    # are drawn
		".SSSSSSSS...",
		"....GGG.....",
		".L.b....L...",
		"..DDDDDDDD..",
		"...HHHHHH..."],
	25: ["............",   # cosmos: Saturn's rings: frosty ice chunks floating over space, a pebble and a rock, the buddy
		"............",    # on a chunk by the Ring Station (its window and its dish); huge banded Saturn with its rings
		"..........I.",    # edge-on and the small far Sun are drawn
		"........DDD.",
		"..b.....SWS.",
		".FFFF..FFFFF",
		"..III...III.",
		"...I.....R.."],
	26: ["............",   # cosmos: Pluto: the Balloon Lander (its white deck, gold foil body and legs) on the heart's
		"............",    # pale nitrogen ice with its cells' edges, its silvery drag balloon behind it, blocks of the
		"............",    # ice mountains with snow on top, the buddy; the star-like Sun, big grey Charon with its red cap
		".........SS.",    # and the blue haze along the horizon are drawn
		"...PPPP..WWS",
		"...FFFF.WWWW",
		".b.T..TDDDWW",
		"NNNENNNNNENN"],
	27: ["............",   # cosmos: Triton: the Hopper Lander (its white tank, white deck, gold foil body and legs) on the
		"............",    # band's frost, the pink polar cap with a dark streak and a geyser's vent, the buddy; the
		"............",    # star-like Sun, huge blue Neptune with its dark spot and the geyser's dark plume drifting
		"....KK......",    # away on the wind are drawn
		"...PPPP.....",
		"...FFFF.....",
		".b.T..T.....",
		"RRRRRRIIDDVI"],
	28: ["............",   # cosmos: Ganymede: the Solar Wing Lander (its giant solar wings, white deck, gold foil body and
		"............",    # legs) on the bright grooved ice, the old dark terrain to the left, a bright ray of fresh ice,
		"............",    # the buddy; the small Sun, Jupiter big and banded with Io and Europa beside it and the
		"............",    # auroras' green and pink belts are drawn
		".WWWPPPPWWW.",
		"....FFFF....",
		".b..T..T....",
		"DDDDGGGGRGGG"],
	41: ["............",   # owner #78: Wonders of the World: the Great Pyramid on Giza's sand, a marble column, the buddy
		"............",
		"........L...",
		".......LLL..",
		".K....LLLLL.",
		".C...LLLLLLL",
		".Cb.LLLLLLLL",
		"PPPPSSSSSSSS"],
}
## Which block each letter is, per universe (the letters mean the same only within a universe).
const _LEGENDS := {
	1: {"G": BlockIds.GRASS, "D": BlockIds.DIRT, "L": BlockIds.LEAVES, "T": BlockIds.LOG, "b": 0},
	2: {"S": BlockIds.SAND, "r": BlockIds.SANDSTONE, "p": BlockIds.CUT_SANDSTONE, "C": BlockIds.CACTUS, "b": 0},
	3: {"W": BlockIds.SNOW, "K": BlockIds.PACKED_SNOW, "B": BlockIds.SNOW_BRICK, "N": BlockIds.PINE_NEEDLES,
		"L": BlockIds.PINE_LOG, "d": 0, "b": 0},
	4: {"F": BlockIds.FROSTING, "K": BlockIds.CAKE, "C": BlockIds.CHOCOLATE, "~": BlockIds.CHOCOLATE,
		"c": BlockIds.CANDY_CANE, "g": BlockIds.GUMDROP, "o": BlockIds.LOLLIPOP, "s": 0, "b": 0},
	5: {"G": BlockIds.SKY_GRASS, "f": BlockIds.FLOATSTONE, "D": BlockIds.DEEP_FLOATSTONE,
		"y": BlockIds.CRYSTAL_SPIRE, "c": BlockIds.CLOUD},
	6: {"W": BlockIds.GLOW_WORMS, "t": BlockIds.STALACTITE, "B": BlockIds.BLUE_SHROOM, "R": BlockIds.ROSE_SHROOM,
		"s": BlockIds.SHROOM_STEM, "Y": BlockIds.SELENITE, "M": BlockIds.GLOW_MOSS, "L": BlockIds.LAKE_STONE,
		"C": BlockIds.CAVE_STONE, "b": 0},
	16: {"M": BlockIds.MOON_DUST, "R": BlockIds.MOON_ROCK, "P": BlockIds.BASE_PANEL, "O": BlockIds.PORTHOLE,
		"y": BlockIds.MOON_CRYSTAL, "b": 0},
	17: {"M": BlockIds.BOING_MOSS, "L": BlockIds.BOING_SOIL, "J": BlockIds.JELLY, "C": BlockIds.SPRING_CAP,
		"S": BlockIds.SPRING_STEM, "B": BlockIds.BOING_BRICK, "b": 0},
	18: {"G": BlockIds.PRISM_GRASS, "r": BlockIds.RAINBOW_RED, "o": BlockIds.RAINBOW_ORANGE, "y": BlockIds.RAINBOW_YELLOW,
		"O": BlockIds.RAINBOW_GREEN, "Y": BlockIds.RAINBOW_BLUE, "b": 0},
	19: {"M": BlockIds.MARS_DUST, "R": BlockIds.MARS_REGOLITH, "P": BlockIds.ROVER_PANEL, "S": BlockIds.SOLAR_PANEL,
		"W": BlockIds.ROVER_WHEEL, "L": BlockIds.ROVER_LIGHT, "b": 0},
	20: {"E": BlockIds.EUROPA_ICE, "R": BlockIds.LINEA_ICE, "D": BlockIds.DEEP_ICE, "P": BlockIds.PROBE_PANEL,
		"m": BlockIds.MELT_PROBE, "L": BlockIds.PROBE_LIGHT, "b": 0},
	21: {"S": BlockIds.SULPHUR, "O": BlockIds.ORANGE_SULPHUR, "F": BlockIds.SULPHUR_FROST, "B": BlockIds.BLACK_LAVA,
		"H": BlockIds.HOT_LAVA, "R": BlockIds.IO_ROCK, "T": BlockIds.HEAT_TILE, "L": BlockIds.LANDER_LEG,
		"C": BlockIds.HEAT_CAMERA, "b": 0},
	22: {"S": BlockIds.TITAN_SOIL, "K": BlockIds.ICE_PEBBLES, "P": BlockIds.PROBE_SHELL, "L": BlockIds.PROBE_LAMP,
		"C": BlockIds.PARACHUTE, "b": 0},
	23: {"D": BlockIds.MERCURY_DUST, "R": BlockIds.RAY_DUST, "K": BlockIds.DARK_DUST, "W": BlockIds.SUNSHADE,
		"H": BlockIds.HEAT_BLANKET, "L": BlockIds.EXPLORER_LAMP, "T": BlockIds.THERMOMETER, "B": BlockIds.THERMO_BULB,
		"b": 0},
	24: {"S": BlockIds.BLIMP_SKIN, "T": BlockIds.BLIMP_STRIPE, "F": BlockIds.BLIMP_STRIPE, "G": BlockIds.GONDOLA,
		"L": BlockIds.CLOUD_LAMP, "D": BlockIds.CLOUD_DECK, "H": BlockIds.FLOAT_HULL, "b": 0},
	25: {"F": BlockIds.RING_FROST, "I": BlockIds.RING_ICE, "R": BlockIds.RING_ROCK, "S": BlockIds.STATION_PANEL,
		"W": BlockIds.STATION_WINDOW, "D": BlockIds.RADIO_DISH, "b": 0},
	26: {"N": BlockIds.NITROGEN_ICE, "E": BlockIds.CELL_EDGE, "W": BlockIds.WATER_ICE, "S": BlockIds.METHANE_SNOW,
		"D": BlockIds.DRAG_BALLOON, "F": BlockIds.LANDER_FOIL, "P": BlockIds.STATION_PANEL, "T": BlockIds.TRUSS, "b": 0},
	27: {"R": BlockIds.TRITON_FROST, "I": BlockIds.PINK_ICE, "D": BlockIds.GEYSER_DUST, "V": BlockIds.NITROGEN_GEYSER,
		"K": BlockIds.NITROGEN_TANK, "P": BlockIds.STATION_PANEL, "F": BlockIds.LANDER_FOIL, "T": BlockIds.TRUSS, "b": 0},
	28: {"W": BlockIds.SOLAR_PANEL, "P": BlockIds.STATION_PANEL, "F": BlockIds.LANDER_FOIL, "T": BlockIds.TRUSS,
		"D": BlockIds.DARK_ICE, "G": BlockIds.GROOVED_ICE, "R": BlockIds.RAY_ICE, "b": 0},
	41: {"L": BlockIds.LIMESTONE, "S": BlockIds.SAND, "P": BlockIds.PAVING, "C": BlockIds.MARBLE_COLUMN,
		"K": BlockIds.CAPITAL, "b": 0},
}
## The far hills' colour and height (of the picture), per universe.
const _HILLS := {1: [Color("8fd18a"), 0.42], 2: [Color("f3cf8b"), 0.5], 3: [Color("dfe9f5"), 0.28],
	4: [Color("ffc1dc"), 0.45], 5: [Color("fff3ea"), 0.22],   # the Dragon Realm: its sea of clouds
	6: [Color("4b3f8f"), 0.3],   # universe 6: the Glow Caves: far cave walls in the violet dark
	16: [Color("8e93a6"), 0.26],   # owner #55: the Moon's grey hills
	17: [Color("b98ee8"), 0.4], 18: [Color("f7c6e4"), 0.46],
	19: [Color("b5603a"), 0.3],   # cosmos: Mars's rusty far hills
	20: [Color("dfe6f0"), 0.2],   # cosmos: Europa's pale ice far away
	21: [Color("e0a83a"), 0.26],   # cosmos: Io's sulphur hills far away
	22: [Color("8a5a36"), 0.3],   # cosmos: Titan's dark dunes far away
	23: [Color("8f8b86"), 0.22],   # cosmos: Mercury's grey crater rims far away
	24: [Color("f4df8e"), 0.2],   # cosmos: Venus's yellow clouds far below
	25: [Color("8d95ad"), 0.18],   # cosmos: Saturn's rings: far chunks of ice fading into the dark
	26: [Color("c9b6a0"), 0.22],   # cosmos: Pluto's peach-tan uplands far away, in the blue haze
	27: [Color("e7c7c1"), 0.2],   # cosmos: Triton's pink polar cap far away
	28: [Color("cfd3da"), 0.2],   # cosmos: Ganymede's bright grooved ice far away
	41: [Color("9fd18a"), 0.3]}   # owner #78: Earth's green hills far away

static var _tiles := {}


## Universe u's scene (Green Meadows' for an unknown one).
static func layout(u: int) -> Array:
	return _LAYOUTS.get(u, _LAYOUTS[1])


## What each letter of universe u's scene is (a block id; 0: drawn by hand).
static func legend(u: int) -> Dictionary:
	return _LEGENDS.get(u, _LEGENDS[1])


## One tile of a block's own page (face TOP or SIDE), made once. Pages may change their tile size (M5 Task 3): the
## tile is measured from the page itself.
static func tile(id: int, face: int) -> Texture2D:
	var key := id * 2 + face
	if _tiles.has(key):
		return _tiles[key]
	var tiles := BlockLibrary.tiles_of(id)
	if tiles.is_empty():
		return null
	var page := BlockLibrary.pixel_atlas_of(id)
	var size := page.get_width() / BlockLibrary.ATLAS_TILES.x
	var at: Vector2i = tiles[TOP if face == TOP else SIDE]
	var t := AtlasTexture.new()
	t.atlas = page
	t.region = Rect2(at.x * size, at.y * size, size, size)
	t.filter_clip = true
	_tiles[key] = t
	return t


## Draws universe u's scene into `rect` of `ci` (a Control's _draw); locked: greyed with a question mark. Returns
## how many blocks it drew. The blocks stand at the bottom, square: as tall as the rect allows (`block` 0), or
## `block` pixels (a whole screen: more sky), repeated sideways when the rect is wider than the scene.
static func draw(ci: CanvasItem, rect: Rect2, u: int, locked: bool = false, block: float = 0.0) -> int:
	var colors := UniverseRegistry.card_colors(u)
	var top: Color = colors.top
	var bottom: Color = colors.bottom
	var p := rect.position
	var s := rect.size
	ci.draw_polygon(PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	_sun(ci, rect, u)
	var hills: Array = _HILLS.get(u, _HILLS[1])
	var hill_top := p.y + s.y * (1.0 - float(hills[1]))
	var ridge := PackedVector2Array([p + Vector2(0, s.y)])
	for i in 9:
		var x := p.x + s.x * i / 8.0
		ridge.append(Vector2(x, hill_top + s.y * 0.08 * (1.0 + sin(i * 1.7 + u))))
	ridge.append(p + s)
	ci.draw_colored_polygon(ridge, hills[0])
	if block <= 0.0:
		block = floorf(s.y / ROWS)
	var rows := layout(u)
	var lg := legend(u)
	var width := COLUMNS * block
	var left := p.x + (s.x - width) * 0.5              # the scene in the middle ...
	left -= ceilf((left - p.x) / width) * width        # ... and copies of it to both sides when there is room
	var drawn := 0
	var x0 := left
	while x0 < p.x + s.x:
		for r in ROWS:
			var y := p.y + s.y - (ROWS - r) * block
			var row: String = rows[r]
			for c in COLUMNS:
				var ch := row[c]
				if ch == ".":
					continue
				var at := Rect2(x0 + c * block, y, block, block)
				if at.end.x <= p.x or at.position.x >= p.x + s.x:
					continue
				var id: int = lg.get(ch, 0)
				if id > 0:
					if _block(ci, tile(id, SIDE) as AtlasTexture, at, rect):
						drawn += 1
				elif at.position.x >= p.x and at.end.x <= p.x + s.x:
					_hand_drawn(ci, ch, at, block)
		x0 += width
	if locked:
		ci.draw_rect(rect, Color(0.32, 0.34, 0.4, 0.82))
		var font := ThemeDB.fallback_font
		ci.draw_string(font, p + Vector2(0, s.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, s.x, int(s.y * 0.5), Color.WHITE)
	return drawn


## One block's tile at `at`, cut to `clip` at the picture's sides (the tile's region cut the same, never squashed).
static func _block(ci: CanvasItem, t: AtlasTexture, at: Rect2, clip: Rect2) -> bool:
	if t == null:
		return false
	var shown := at.intersection(clip)
	if shown.size.x <= 0.0 or shown.size.y <= 0.0:
		return false
	var src := t.region
	var k := src.size.x / at.size.x
	var from := Rect2(src.position + (shown.position - at.position) * k, shown.size * k)
	ci.draw_texture_rect_region(t.atlas, shown, from)
	return true


static func _sun(ci: CanvasItem, rect: Rect2, u: int) -> void:
	var p := rect.position
	var s := rect.size
	match u:
		17:   # owner #55: Planet Boing: a golden ringed planet
			var c := p + Vector2(s.x * 0.2, s.y * 0.24)
			ci.draw_circle(c, s.y * 0.11, Color("ffb347"))
			ci.draw_line(c - Vector2(s.y * 0.2, -s.y * 0.04), c + Vector2(s.y * 0.2, -s.y * 0.04), Color("fff0c2"),
				maxf(2.0, s.y * 0.025))
		18:   # owner #55: Rainbow Planet: a pink planet and a little moon
			ci.draw_circle(p + Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.1, Color("ff9fcf"))
			ci.draw_circle(p + Vector2(s.x * 0.32, s.y * 0.12), s.y * 0.04, Color("fff0f8"))
		20:   # cosmos: Europa: stars and giant Jupiter with its cloud bands and Great Red Spot, little Io beside it
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.3, 1.0), s.y * fmod(i * 0.211, 0.55)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var c := p + Vector2(s.x * 0.26, s.y * 0.3)
			var r := s.y * 0.2
			ci.draw_circle(c, r, Color("e3cfa8"))
			for k: float in [-0.62, -0.25, 0.12, 0.5]:
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("b0714a"), maxf(2.0, r * 0.15))
			ci.draw_circle(c + Vector2(r * 0.3, r * 0.32), r * 0.13, Color("c4553a"))
			ci.draw_circle(p + Vector2(s.x * 0.44, s.y * 0.14), s.y * 0.035, Color("e8d04a"))
		21:   # cosmos: Io: stars, giant Jupiter (bigger than over Europa), little Europa, a volcano's plume far away
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.3, 1.0), s.y * fmod(i * 0.211, 0.55)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var c := p + Vector2(s.x * 0.24, s.y * 0.3)
			var r := s.y * 0.25
			ci.draw_circle(c, r, Color("e3cfa8"))
			for k: float in [-0.62, -0.25, 0.12, 0.5]:
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("b0714a"), maxf(2.0, r * 0.15))
			ci.draw_circle(c + Vector2(r * 0.3, r * 0.32), r * 0.13, Color("c4553a"))
			ci.draw_circle(p + Vector2(s.x * 0.46, s.y * 0.12), s.y * 0.03, Color("eae3d2"))
			var vent := p + Vector2(s.x * 0.84, s.y * 0.72)   # an umbrella of sulphur over a far volcano
			ci.draw_line(vent, vent - Vector2(0, s.y * 0.26), Color(1.0, 0.93, 0.6, 0.8), maxf(2.0, s.y * 0.02))
			ci.draw_arc(vent - Vector2(0, s.y * 0.2), s.y * 0.1, PI, TAU, 16, Color(1.0, 0.9, 0.55, 0.8), maxf(2.0, s.y * 0.02))
		22:   # cosmos: Titan: Saturn, pale and banded, with its rings, soft in the orange haze
			var c := p + Vector2(s.x * 0.24, s.y * 0.26)
			var r := s.y * 0.14
			var ring := Color(1.0, 0.93, 0.76, 0.85)
			ci.draw_arc(c, r * 1.9, PI * 1.05, PI * 1.95, 24, ring, maxf(2.0, s.y * 0.02))   # the ring behind it
			ci.draw_circle(c, r, Color("ecd3a1"))
			for k: float in [-0.5, -0.1, 0.35]:
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("cfa86a"), maxf(1.5, r * 0.14))
			ci.draw_line(c + Vector2(-r * 1.9, r * 0.1), c + Vector2(r * 1.9, -r * 0.1), ring, maxf(2.0, s.y * 0.025))
			ci.draw_rect(Rect2(p, s), Color(0.95, 0.72, 0.42, 0.18))   # the haze over everything far away
		23:   # cosmos: Mercury: stars and the huge white Sun in the black sky (three times as big as at home), its glow
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.5, 1.0), s.y * fmod(i * 0.211, 0.55)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var c := p + Vector2(s.x * 0.24, s.y * 0.3)
			for k in 4:
				ci.draw_circle(c, s.y * (0.34 - k * 0.025), Color(1.0, 0.98, 0.9, 0.08 + k * 0.05))
			ci.draw_circle(c, s.y * 0.24, Color(1.0, 0.99, 0.95))
		24:   # cosmos: Venus: the Sun a soft big glow in the hazy golden sky, a flash of lightning deep in the clouds
			var c := p + Vector2(s.x * 0.8, s.y * 0.24)
			for k in 4:
				ci.draw_circle(c, s.y * (0.26 - k * 0.04), Color(1.0, 0.97, 0.82, 0.12 + k * 0.08))
			ci.draw_circle(c, s.y * 0.1, Color(1.0, 0.99, 0.92))
			var bolt := PackedVector2Array([p + Vector2(s.x * 0.9, s.y * 0.8), p + Vector2(s.x * 0.87, s.y * 0.88),
				p + Vector2(s.x * 0.9, s.y * 0.89), p + Vector2(s.x * 0.86, s.y * 0.98)])
			ci.draw_polyline(bolt, Color(1.0, 1.0, 0.96, 0.9), maxf(1.5, s.y * 0.012))
		25:   # cosmos: Saturn's rings: stars, the small far Sun, huge Saturn over the horizon with its bands, the rings edge-on
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.4, 1.0), s.y * fmod(i * 0.211, 0.5)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			ci.draw_circle(p + Vector2(s.x * 0.86, s.y * 0.12), s.y * 0.03, Color(1.0, 0.98, 0.9, 0.35))
			ci.draw_circle(p + Vector2(s.x * 0.86, s.y * 0.12), s.y * 0.015, Color(1.0, 0.99, 0.95))
			var c := p + Vector2(s.x * 0.3, s.y * 0.6)
			var r := s.y * 0.42
			ci.draw_circle(c, r, Color("ead7a4"))
			for k: float in [-0.75, -0.45, -0.2, 0.28, 0.55, 0.8]:
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("c9a46a"), maxf(2.0, r * 0.07))
			var shade := r * sqrt(1.0 - 0.1 * 0.1)
			ci.draw_line(c + Vector2(-shade, r * 0.1), c + Vector2(shade, r * 0.1), Color(0.35, 0.3, 0.25, 0.7),
				maxf(2.0, r * 0.06))   # the rings' shadow on its clouds
			ci.draw_line(Vector2(p.x, c.y), Vector2(p.x + s.x, c.y), Color(1.0, 0.96, 0.86), maxf(1.5, s.y * 0.012))
		27:   # cosmos: Triton: stars, the Sun a tiny bright star, huge deep blue Neptune (its bands, its dark spot, white
			for i in 14:   # clouds) up in the north-east, and a geyser's dark plume rising from its vent, drifting on the wind
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.2, 1.0), s.y * fmod(i * 0.211, 0.5)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var sun := p + Vector2(s.x * 0.12, s.y * 0.12)
			ci.draw_circle(sun, s.y * 0.026, Color(1.0, 0.98, 0.9, 0.3))
			ci.draw_circle(sun, s.y * 0.011, Color(1.0, 1.0, 0.97))
			var c := p + Vector2(s.x * 0.66, s.y * 0.28)
			var r := s.y * 0.22
			ci.draw_circle(c, r, Color("3f63e0"))
			for k: float in [-0.55, -0.15, 0.3, 0.65]:   # its faint bands
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("5b7ff0"), maxf(1.5, r * 0.08))
			ci.draw_circle(c + Vector2(-r * 0.25, r * 0.18), r * 0.15, Color("1d2a6e"))   # its dark spot
			ci.draw_line(c + Vector2(-r * 0.35, r * 0.42), c + Vector2(r * 0.05, r * 0.42), Color("e6ecff"),
				maxf(1.5, r * 0.05))   # white clouds by it
			var vent := p + Vector2(s.x * 10.5 / COLUMNS, s.y * 7.0 / ROWS)
			for k in 8:   # the plume: up, then carried off downwind
				var q := vent + Vector2(s.x * 0.0012 * k * k, -s.y * 0.055 * k)
				ci.draw_circle(q, s.y * (0.012 + 0.005 * k), Color(0.52, 0.49, 0.55, 0.6 - 0.06 * k))
		28:   # cosmos: Ganymede: stars, a small Sun, Jupiter big and banded (its Great Red Spot) with Io and Europa beside it,
			for i in 14:   # and the auroras: wavy belts of green light, pink at their tops
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.2, 1.0), s.y * fmod(i * 0.211, 0.5)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var sun := p + Vector2(s.x * 0.1, s.y * 0.1)
			ci.draw_circle(sun, s.y * 0.045, Color(1.0, 0.97, 0.85, 0.3))
			ci.draw_circle(sun, s.y * 0.022, Color(1.0, 0.99, 0.92))
			for band in 3:   # the auroras' belts
				var pts := PackedVector2Array()
				for k in 25:
					var t := k / 24.0
					pts.append(p + Vector2(s.x * (0.04 + 0.5 * t), s.y * (0.3 + 0.05 * band + 0.035 * sin(t * 9.0 + band * 1.7))))
				ci.draw_polyline(pts, Color(0.45, 1.0, 0.62, 0.55 - 0.12 * band), maxf(2.0, s.y * 0.03))
				for k in pts.size():
					pts[k] -= Vector2(0, s.y * 0.035)
				ci.draw_polyline(pts, Color(1.0, 0.55, 0.8, 0.35 - 0.08 * band), maxf(1.5, s.y * 0.02))
			var c := p + Vector2(s.x * 0.74, s.y * 0.26)
			var r := s.y * 0.17
			ci.draw_circle(c, r, Color("e3cfa8"))
			for k: float in [-0.62, -0.25, 0.12, 0.5]:
				var half := r * sqrt(maxf(1.0 - k * k, 0.0))
				ci.draw_line(c + Vector2(-half, k * r), c + Vector2(half, k * r), Color("b0714a"), maxf(2.0, r * 0.15))
			ci.draw_circle(c + Vector2(r * 0.3, r * 0.32), r * 0.13, Color("c4553a"))
			ci.draw_circle(c + Vector2(-r * 1.6, r * 0.4), s.y * 0.016, Color("e8d04a"))   # Io ...
			ci.draw_circle(c + Vector2(r * 2.1, -r * 0.3), s.y * 0.02, Color("eae3d2"))   # ... and Europa
		26:   # cosmos: Pluto: stars, the Sun a tiny bright star, big grey Charon with its red cap low in the west, the blue haze
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377 + 0.2, 1.0), s.y * fmod(i * 0.211, 0.5)),
					maxf(1.0, s.y * 0.008), Color(1, 1, 1, 0.85))
			var sun := p + Vector2(s.x * 0.84, s.y * 0.14)
			ci.draw_circle(sun, s.y * 0.028, Color(1.0, 0.98, 0.9, 0.3))
			ci.draw_circle(sun, s.y * 0.012, Color(1.0, 1.0, 0.97))
			var c := p + Vector2(s.x * 0.18, s.y * 0.34)
			var r := s.y * 0.15
			ci.draw_circle(c, r, Color("a8a39d"))
			for k in 4:   # its red cap across the top
				var y := -r + r * 0.1 * k
				var half := r * sqrt(maxf(1.0 - (y / r) * (y / r), 0.0))
				ci.draw_line(c + Vector2(-half, y), c + Vector2(half, y), Color("8e4a33"), maxf(1.5, r * 0.12))
			ci.draw_circle(c + Vector2(r * 0.3, r * 0.25), r * 0.12, Color("8f8a84"))
			ci.draw_circle(c + Vector2(-r * 0.35, r * 0.35), r * 0.09, Color("8f8a84"))
			for k in 3:   # the blue haze along the horizon, in layers
				var band := p.y + s.y * (0.5 + 0.06 * k)
				ci.draw_rect(Rect2(p.x, band, s.x, s.y * 0.03), Color(0.45, 0.65, 1.0, 0.16 + 0.06 * k))
		19:   # cosmos: Mars: its two small moons in the butterscotch sky, Phobos and the smaller Deimos
			ci.draw_circle(p + Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.06, Color("8a7d72"))
			ci.draw_circle(p + Vector2(s.x * 0.36, s.y * 0.12), s.y * 0.03, Color("a39584"))
		16:   # owner #55: the Moon: stars and the home planet, blue with green land
			for i in 14:
				ci.draw_circle(p + Vector2(s.x * fmod(i * 0.377, 1.0), s.y * fmod(i * 0.211, 0.55)), maxf(1.0, s.y * 0.008),
					Color(1, 1, 1, 0.85))
			var c := p + Vector2(s.x * 0.22, s.y * 0.26)
			ci.draw_circle(c, s.y * 0.14, Color("3f8fe0"))
			ci.draw_circle(c + Vector2(-s.y * 0.04, -s.y * 0.03), s.y * 0.05, Color("5cb85c"))
			ci.draw_circle(c + Vector2(s.y * 0.05, s.y * 0.04), s.y * 0.04, Color("5cb85c"))
		6:   # the Glow Caves: no sun under the rock: glow-worms' little blue lights and a few hanging threads
			for i in 14:
				var g := p + Vector2(s.x * fmod(0.07 + i * 0.137, 1.0), s.y * (0.16 + 0.1 * fmod(i * 0.61, 1.0)))
				ci.draw_line(g - Vector2(0, s.y * 0.06), g, Color(0.5, 0.62, 0.9, 0.35), maxf(1.0, s.y * 0.006))
				ci.draw_circle(g, maxf(1.5, s.y * 0.012), Color("bff4ff"))
		5:   # the Dragon Realm: a golden morning sun over the sea of clouds, with rays
			var c := p + Vector2(s.x * 0.16, s.y * 0.3)
			for i in 12:
				var a := TAU * (i + 0.5) / 12.0
				ci.draw_line(c, c + Vector2(cos(a), sin(a)) * s.y * 0.24, Color(1.0, 0.86, 0.5, 0.6), maxf(2.0, s.y * 0.02))
			ci.draw_circle(c, s.y * 0.13, Color("ffd36b"))
		3:   # Frostpeak: a small pale winter sun
			ci.draw_circle(p + Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.08, Color(1.0, 0.98, 0.9))
		4:   # the Candy Kingdom: a pink-white sun with a candy ring
			var c := p + Vector2(s.x * 0.22, s.y * 0.22)
			ci.draw_circle(c, s.y * 0.13, Color("ff9ccf"))
			ci.draw_circle(c, s.y * 0.1, Color(1.0, 0.96, 0.98))
		2:   # the desert: a big hot sun
			ci.draw_circle(p + Vector2(s.x * 0.8, s.y * 0.22), s.y * 0.15, Color(1.0, 0.93, 0.6))
		_:
			ci.draw_circle(p + Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.11, Color(1.0, 0.95, 0.7))
			for cloud: Vector2 in [Vector2(0.52, 0.16), Vector2(0.62, 0.2)]:
				ci.draw_circle(p + s * cloud, s.y * 0.07, Color(1, 1, 1, 0.9))


## The cells a layout draws by hand: the buddy, a doorway, a lollipop's stick.
static func _hand_drawn(ci: CanvasItem, ch: String, at: Rect2, block: float) -> void:
	match ch:
		"b":
			buddy(ci, at.position + Vector2(block * 0.1, block * 0.1), block * 0.8)
		"d":
			ci.draw_rect(Rect2(at.position + Vector2(block * 0.15, block * 0.2), Vector2(block * 0.7, block * 0.8)), Color("23324a"))
		"s":
			ci.draw_rect(Rect2(at.position + Vector2(block * 0.42, 0), Vector2(block * 0.16, block)), Color(0.98, 0.97, 0.95))
		"m":   # cosmos: Titan's liquid methane: amber and glassy, a glint on top
			ci.draw_rect(at, TitanRules.METHANE_COLOR)
			ci.draw_rect(Rect2(at.position + Vector2(block * 0.15, block * 0.12), Vector2(block * 0.5, block * 0.08)),
				Color(1.0, 0.9, 0.7, 0.8))


## The brand's buddy: an orange block with a darker bottom and two googly eyes looking to the side (size: its width).
static func buddy(ci: CanvasItem, at: Vector2, size: float) -> void:
	ci.draw_rect(Rect2(at, Vector2(size, size)), BUDDY)
	ci.draw_rect(Rect2(at + Vector2(0, size * 0.78), Vector2(size, size * 0.22)), BUDDY_DARK)
	for side in [0.3, 0.7]:
		var c := at + Vector2(size * side, size * 0.36)
		ci.draw_circle(c, size * 0.17, EYE)
		ci.draw_circle(c + Vector2(size * 0.05, size * 0.03), size * 0.08, PUPIL)
