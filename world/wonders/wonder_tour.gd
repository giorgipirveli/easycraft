class_name WonderTour
extends RefCounted
## Where the wonders stand in world 41, Wonders of the World (owner #78, spec §24), as pure rules, a tour at a time: the
## first tour, the Seven Wonders of the Ancient World, round the landing spot; the second, the New Seven Wonders (chosen
## in 2007), round their own square (NEW_SQUARE) at the end of the Wonders Road, which runs west from the landing square
## (a paved road with speed pads across it; NewSevenGround shapes that region's ground: the Great Wall's ridge,
## Corcovado, Huayna Picchu). The same in every world (never the seed's): a flat park
## at the tour's ground level (BASE_Y) out to FLAT_R, a sea to the north-east (the Mediterranean: its coast is the line
## x - z = COAST, a sandy beach before it), the Lighthouse on its island at the end of a raised causeway, the Colossus on
## the harbour's shore, the pyramid on the sand of Giza, the Hanging Gardens by a river. Each wonder stands at its own
## centre facing the landing spot (or where the real one faced: the Temple of Artemis west, the Temple of Zeus east),
## at a size a child walks round in half a minute (the real sizes are in its facts). Paved paths run straight from the
## landing square to each wonder's gate, where its plaque stands; a signpost on the square points each way.
## WonderBuilds turns this into blocks; WondersShape into ground; WondersSecretRules into the wonders' secrets. Each
## wonder's tour is WonderFacts.tour_of; its paths and signposts start on its tour's square.

const BASE_Y := 32                 # the tour's ground: the first air above it (the top block is at BASE_Y - 1)
const FLAT_R := 190                # flat park (and the sea) out to here ...
const BLEND_R := 260               # ... then Green Meadows' own land (MeadowsShape) from here on
const PLAZA_R := 10                # the landing square (paving) round the spawn
const PATH_HALF := 1               # paths are 3 wide
const SIGN_R := 8                  # the signposts stand this far from the spawn, toward each wonder
## The sea: north-east of the line x - z = COAST; the beach runs from BEACH_IN (inland) to the water.
const COAST := 155.0
const BEACH_IN := 12.0             # blocks inland of the coast line where the sand begins
const SEA_FLOOR := 18
## The Lighthouse's island, and the causeway (the Heptastadion) that joins it to the shore.
const ISLAND := Vector2i(145, -40)
const ISLAND_R := 13
const ISLAND_RIM := 4              # its rocky slope down to the sea floor
const CAUSEWAY := Rect2i(96, -42, 42, 5)    # x 96..137, z -42..-38: flat at BASE_Y
## Giza's sand round the pyramid.
const DESERT := Rect2i(-44, 68, 76, 72)
## The river Euphrates by the Hanging Gardens (water in a channel).
const RIVER := Rect2i(122, 28, 5, 88)

## North, east, south, west: the way a wonder's front faces.
const N := Vector2i(0, -1)
const E := Vector2i(1, 0)
const S := Vector2i(0, 1)
const W := Vector2i(-1, 0)

## The tours, the first tour in the old lists' order. centre: its middle (x, z); face: where its front looks; half: its
## footprint's half size in its own frame (x across, z along); gate: where its path ends (its own frame, in front of it
## or beside it); plaque: beside the gate (its own frame); reach (optional): a frame rect (x, z) its build also covers
## past its footprint (a stair up a mountain).
const WONDERS := {
	&"pyramid": {"centre": Vector2i(-8, 105), "face": N, "half": Vector2i(22, 23), "gate": Vector2i(0, -32),
		"plaque": Vector2i(3, -32)},
	&"gardens": {"centre": Vector2i(100, 70), "face": W, "half": Vector2i(16, 20), "gate": Vector2i(0, -26),
		"plaque": Vector2i(3, -26)},
	&"artemis": {"centre": Vector2i(-95, -55), "face": W, "half": Vector2i(13, 27), "gate": Vector2i(0, 32),
		"plaque": Vector2i(3, 32)},
	&"zeus": {"centre": Vector2i(-100, 45), "face": E, "half": Vector2i(12, 27), "gate": Vector2i(0, -32),
		"plaque": Vector2i(3, -32)},
	&"mausoleum": {"centre": Vector2i(-12, -105), "face": S, "half": Vector2i(9, 20), "gate": Vector2i(0, -26),
		"plaque": Vector2i(3, -26)},
	&"colossus": {"centre": Vector2i(42, -75), "face": S, "half": Vector2i(7, 12), "gate": Vector2i(0, -17),
		"plaque": Vector2i(3, -17)},
	&"lighthouse": {"centre": ISLAND, "face": W, "half": Vector2i(ISLAND_R, ISLAND_R), "gate": Vector2i(0, -50),
		"plaque": Vector2i(3, -9)},
	# the second tour, round NEW_SQUARE (-350, 0): the Great Wall on its ridge to the north (its battlements face north),
	# the Taj Mahal with its garden to the south and the river behind it to the north (as the real one), Petra's cliff,
	# Christ the Redeemer on Corcovado facing the square, Machu Picchu's terraces with Huayna Picchu behind them,
	# Chichen Itza's pyramid (its serpent stairs to the north, as the real one), the Colosseum (its long way east-west,
	# its broken outer ring on the south, as the real one).
	&"great_wall": {"centre": Vector2i(-400, -122), "face": S, "half": Vector2i(57, 5), "gate": Vector2i(0, -28),
		"plaque": Vector2i(3, -28), "reach": Rect2i(-57, -17, 115, 22)},
	&"petra": {"centre": Vector2i(-250, 50), "face": W, "half": Vector2i(25, 26), "gate": Vector2i(0, -31),
		"plaque": Vector2i(3, -31)},
	&"colosseum": {"centre": Vector2i(-455, -55), "face": E, "half": Vector2i(24, 29), "gate": Vector2i(0, -34),
		"plaque": Vector2i(3, -34)},
	&"chichen_itza": {"centre": Vector2i(-480, 28), "face": N, "half": Vector2i(26, 26), "gate": Vector2i(31, 0),
		"plaque": Vector2i(31, -3)},
	&"machu_picchu": {"centre": Vector2i(-430, 90), "face": N, "half": Vector2i(30, 22), "gate": Vector2i(0, -29),
		"plaque": Vector2i(3, -29)},
	&"taj_mahal": {"centre": Vector2i(-300, -88), "face": S, "half": Vector2i(23, 45), "gate": Vector2i(0, -48),
		"plaque": Vector2i(3, -48)},
	&"christ_redeemer": {"centre": Vector2i(-325, 115), "face": N, "half": Vector2i(12, 9), "gate": Vector2i(0, -51),
		"plaque": Vector2i(3, -51), "reach": Rect2i(-12, -47, 25, 57)},
	# the third tour, round NATURE_SQUARE (165, 410), its ground NatureGround's: Parícutin in its cornfield to the north,
	# the northern lights' snowy valley to the north-west, Mount Everest with Lhotse to the south-west (its base camp
	# toward the square), Victoria Falls to the south (its river flowing north into the chasm, the rainforest facing it),
	# the Harbour of Rio de Janeiro's bay on the coast to the south-east (Urca and the Sugarloaf on its south side), the
	# Great Barrier Reef off the coast to the east (a jetty out from the beach), the Grand Canyon on its plateau to the
	# north-east (its long way north-south, the river in its bottom).
	&"grand_canyon": {"centre": Vector2i(288, 330), "face": W, "half": Vector2i(60, 48), "gate": Vector2i(0, -54),
		"plaque": Vector2i(3, -54)},
	&"barrier_reef": {"centre": Vector2i(318, 445), "face": N, "half": Vector2i(8, 30), "gate": Vector2i(0, -44),
		"plaque": Vector2i(3, -44)},
	&"rio_harbour": {"centre": Vector2i(236, 486), "face": N, "half": Vector2i(24, 24), "gate": Vector2i(-22, -28),
		"plaque": Vector2i(-19, -28), "reach": Rect2i(-20, 12, 45, 21)},
	&"everest": {"centre": Vector2i(0, 470), "face": E, "half": Vector2i(56, 56), "gate": Vector2i(28, -80),
		"plaque": Vector2i(31, -80), "reach": Rect2i(-56, -80, 137, 137)},
	&"northern_lights": {"centre": Vector2i(55, 348), "face": E, "half": Vector2i(20, 30), "gate": Vector2i(0, -44),
		"plaque": Vector2i(3, -44)},
	&"paricutin": {"centre": Vector2i(170, 272), "face": S, "half": Vector2i(40, 40), "gate": Vector2i(0, -54),
		"plaque": Vector2i(3, -54), "reach": Rect2i(-14, 30, 44, 40)},
	&"victoria_falls": {"centre": Vector2i(140, 528), "face": N, "half": Vector2i(30, 12), "gate": Vector2i(0, -34),
		"plaque": Vector2i(3, -34), "reach": Rect2i(-46, -12, 77, 108)},
}

# --- The second tour's region: its square, the Wonders Road to it ---
## The New Seven Wonders' square (the end of the Wonders Road) and the radius round it where the ground is the tour's own
## (NewSevenGround: flat, with the Great Wall's ridge, Corcovado and Huayna Picchu); it blends into Green Meadows' land
## over BLEND past it, like the first tour's park.
const NEW_SQUARE := Vector2i(-350, 0)
const NEW_R := 180
const BLEND := BLEND_R - FLAT_R
## The third tour's region: the Seven Natural Wonders' square (the end of the Nature Trail, south of the landing
## square) and the radius round it where the ground is NatureGround's (the canyon's plateau, the volcano, the mountains,
## the falls, the bay, the sea and the reef); past it, over BLEND, Green Meadows' land. Its nearest edge (442 - 230 =
## 212 blocks out) is past the landing spot's farthest view (GraphicsPreset.MAX_VIEW_DISTANCE 192).
const NATURE_SQUARE := Vector2i(165, 410)
const NATURE_R := 230
const SQUARES := {&"ancient": Vector2i.ZERO, &"new": NEW_SQUARE, &"nature": NATURE_SQUARE}
## The Nature Trail's surface and the third tour's paths: dirt, a block of the ground's own page (no material added to
## the chunks they cross). Speed pads across it every TRAIL_PAD_EVERY blocks from TRAIL_PAD_FIRST blocks out (out of the
## landing spot's view, like the Wonders Road's).
const TRAIL_BLOCK := BlockIds.DIRT
const NATURE_PATH_BLOCK := BlockIds.DIRT
const TRAIL_PAD_FIRST := 198
const TRAIL_PAD_EVERY := 24
## Speed pads across the Wonders Road (PadRules: a burst along the way the child goes), every ROAD_PAD_EVERY blocks from
## ROAD_PAD_FIRST on: past the first park and out of the landing spot's view (GraphicsPreset.MAX_VIEW_DISTANCE 192; a
## pad's glowing material would be one more draw in each chunk it is in).
const ROAD_PAD_EVERY := 24
const ROAD_PAD_FIRST := -198
## The road's surface: sand, a block of the ground's own page (paving would add a material to every chunk it crosses
## in the landing spot's view).
const ROAD_BLOCK := BlockIds.SAND


static func ids() -> Array[StringName]:
	return WonderFacts.ORDER.duplicate()


## The square wonder `id`'s tour stands round (its paths and signposts start there).
static func square_of(id: StringName) -> Vector2i:
	return square(WonderFacts.tour_of(id))


static func square(tour: StringName) -> Vector2i:
	return SQUARES.get(tour, Vector2i.ZERO)


## The Wonders Road's two ends (x, z): from the landing square's edge west to the New Seven's square's edge, 3 wide.
static func road() -> Array[Vector2i]:
	return [Vector2i(-(PLAZA_R - 1), 0), Vector2i(NEW_SQUARE.x + PLAZA_R - 1, 0)]


## The x of each row of speed pads across the Wonders Road.
static func road_pads() -> Array[int]:
	var out: Array[int] = []
	var x := ROAD_PAD_FIRST
	while x >= NEW_SQUARE.x + PLAZA_R + 10:
		out.append(x)
		x -= ROAD_PAD_EVERY
	return out


## The Wonders Road's signpost on tour `tour`'s square, pointing along the road to the other tour.
static func road_signpost(tour: StringName) -> Vector2i:
	var c := square(tour)
	var dir := Vector2(-1, 0) if tour == &"ancient" else Vector2(1, 0)
	var side := Vector2(-dir.y, dir.x)
	return c + Vector2i((dir * SIGN_R + side * 2.5).round())


## The Nature Trail's two ends (x, z): from the landing square's edge south to the nature square's edge, 3 wide.
static func trail() -> Array[Vector2i]:
	var dir := Vector2(NATURE_SQUARE).normalized() * (PLAZA_R - 1)
	return [Vector2i(dir.round()), NATURE_SQUARE - Vector2i(dir.round())]


## The middle cell of each row of speed pads across the Nature Trail (a row covers it, 3 wide): from TRAIL_PAD_FIRST
## blocks out, every TRAIL_PAD_EVERY, short of the nature square.
static func trail_pads() -> Array[Vector2i]:
	var ends := trail()
	var cells := line_cells(ends[0], ends[1])
	var out: Array[Vector2i] = []
	var want := float(TRAIL_PAD_FIRST)
	var last := Vector2(NATURE_SQUARE).length() - PLAZA_R - 10.0
	for c in cells:
		if want > last:
			break
		if Vector2(c).length() >= want:
			out.append(c)
			want += TRAIL_PAD_EVERY
	return out


## The Nature Trail's signpost on tour `end`'s square (&"ancient" or &"nature"), pointing along the trail to the other.
static func trail_signpost(end: StringName) -> Vector2i:
	var c := square(end)
	var dir := Vector2(NATURE_SQUARE).normalized() * (1.0 if end == &"ancient" else -1.0)
	var side := Vector2(-dir.y, dir.x)
	return c + Vector2i((dir * SIGN_R + side * 2.5).round())


## The middle cells of a straight path from a to b, a step along its longer way at a time (WonderBuilds lays a path's
## rows on them, 3 wide across).
static func line_cells(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var d := b - a
	var n := maxi(absi(d.x), absi(d.y))
	var out: Array[Vector2i] = []
	for i in n + 1:
		out.append(Vector2i((Vector2(a) + Vector2(d) * (float(i) / maxf(n, 1))).round()))
	return out


## The distance from (x, z) to the nature square.
static func nature_distance(x: float, z: float) -> float:
	return Vector2(x - NATURE_SQUARE.x, z - NATURE_SQUARE.y).length()


## True where the ground is the third tour's region's own (NatureGround).
static func in_nature_region(x: float, z: float) -> bool:
	return nature_distance(x, z) <= NATURE_R and x * x + z * z > FLAT_R * FLAT_R


## The distance from (x, z) to the New Seven's square.
static func new_distance(x: float, z: float) -> float:
	return Vector2(x - NEW_SQUARE.x, z - NEW_SQUARE.y).length()


## True where the ground is the New Seven's region's own (NewSevenGround), not the first tour's park or the meadows.
static func in_new_region(x: float, z: float) -> bool:
	return new_distance(x, z) <= NEW_R and x * x + z * z > FLAT_R * FLAT_R


static func has(id: StringName) -> bool:
	return WONDERS.has(id)


## A point of wonder `id`'s own frame (x across it, z from its front (-z) to its back) in the world.
static func to_world(id: StringName, local: Vector2i) -> Vector2i:
	var w: Dictionary = WONDERS[id]
	return (w.centre as Vector2i) + turn(local, w.face)


## A world point (x, z) in wonder `id`'s own frame (the inverse of to_world).
static func to_frame(id: StringName, world: Vector2i) -> Vector2i:
	var w: Dictionary = WONDERS[id]
	var v := world - (w.centre as Vector2i)
	match w.face:
		S:
			return Vector2i(-v.x, -v.y)
		E:
			return Vector2i(v.y, -v.x)
		W:
			return Vector2i(-v.y, v.x)
	return v


## A vector of a wonder's own frame (its front at -z) turned to face `face`.
static func turn(v: Vector2i, face: Vector2i) -> Vector2i:
	match face:
		S:
			return Vector2i(-v.x, -v.y)
		E:
			return Vector2i(-v.y, v.x)
		W:
			return Vector2i(v.y, -v.x)
	return v


## The world cells [lo, hi] (inclusive) of a box given in wonder `id`'s own frame (y as given).
static func box_to_world(id: StringName, a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var p := to_world(id, Vector2i(a.x, a.z))
	var q := to_world(id, Vector2i(b.x, b.z))
	return [Vector3i(mini(p.x, q.x), mini(a.y, b.y), mini(p.y, q.y)), Vector3i(maxi(p.x, q.x), maxi(a.y, b.y), maxi(p.y, q.y))]


static func centre(id: StringName) -> Vector3:
	var c: Vector2i = WONDERS[id].centre
	return Vector3(c.x + 0.5, BASE_Y, c.y + 0.5)


## Where a wonder's path ends (x, z).
static func gate(id: StringName) -> Vector2i:
	return to_world(id, WONDERS[id].gate)


## The plaque's cell (a tap opens the wonder's card).
static func plaque(id: StringName) -> Vector3i:
	var p := to_world(id, WONDERS[id].plaque)
	return Vector3i(p.x, BASE_Y, p.y)


## A tour's own plaque on its square (its card: the tour, its facts, the guide): the landing square's (&"ancient"), the
## New Seven's square's (&"new") and the nature square's (&"nature").
static func tour_plaque(tour: StringName = &"ancient") -> Vector3i:
	var c := square(tour)
	return Vector3i(c.x, BASE_Y, c.y + 4)


## The wonder whose plaque is at `cell` (a tour's plaque id for a square's: &"tour", &"tour_new", &"tour_nature"; &""
## for none).
static func plaque_at(cell: Vector3i) -> StringName:
	for t: StringName in WonderFacts.TOUR_IDS:
		if cell == tour_plaque(t):
			return WonderFacts.tour_info(t).plaque
	for id: StringName in WONDERS:
		if plaque(id) == cell:
			return id
	return &""


## A path's two ends: from its tour's square's edge toward the wonder's gate, to the gate. The Lighthouse's path ends
## where its causeway begins.
static func path(id: StringName) -> Array[Vector2i]:
	var to := gate(id)
	if id == &"lighthouse":
		to = Vector2i(CAUSEWAY.position.x, CAUSEWAY.position.y + CAUSEWAY.size.y / 2)
	var c := square_of(id)
	var dir := Vector2(to - c).normalized()
	var from := c + Vector2i((dir * (PLAZA_R - 1)).round())
	return [from, to]


## The signpost on its tour's square that points to wonder `id` (x, z).
static func signpost(id: StringName) -> Vector2i:
	var ends := path(id)
	var dir := Vector2(ends[1] - ends[0]).normalized()
	var side := Vector2(-dir.y, dir.x)
	return square_of(id) + Vector2i((dir * SIGN_R + side * 2.5).round())


## The perpendicular distance of (x, z) from the coast line: > 0 out at sea, < 0 inland.
static func coast_distance(x: float, z: float) -> float:
	return (x - z - COAST) * 0.70710678


## The distance from (x, z) to the segment a-b.
static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Wonder `id`'s footprint in the world (x, z, inclusive rect as Rect2i with size = extent + 1), from its half size.
static func footprint(id: StringName) -> Rect2i:
	var w: Dictionary = WONDERS[id]
	var h: Vector2i = w.half
	return _frame_rect(id, Vector2i(-h.x, -h.y), Vector2i(h.x, h.y))


## Everything wonder `id`'s build covers (x, z): its footprint and its reach (a stair up a mountain), as one rect.
static func reach(id: StringName) -> Rect2i:
	var f := footprint(id)
	var w: Dictionary = WONDERS[id]
	if not w.has("reach"):
		return f
	var r: Rect2i = w.reach
	return f.merge(_frame_rect(id, r.position, r.end - Vector2i.ONE))


## The world rect (inclusive corners a, b of wonder `id`'s frame).
static func _frame_rect(id: StringName, a: Vector2i, b: Vector2i) -> Rect2i:
	var p := to_world(id, a)
	var q := to_world(id, b)
	var lo := Vector2i(mini(p.x, q.x), mini(p.y, q.y))
	var hi := Vector2i(maxi(p.x, q.x), maxi(p.y, q.y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


## Phidias's workshop west of the Temple of Zeus (the Statue of Zeus's secret): its world rect.
const WORKSHOP := Rect2i(-146, 40, 11, 9)
## Petra's desert: sand round its cliff (no trees there).
const PETRA_SAND := Rect2i(-286, 17, 73, 67)
