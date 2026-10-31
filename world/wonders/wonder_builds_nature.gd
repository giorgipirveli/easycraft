class_name WonderBuildsNature
extends RefCounted
## The blocks of the third tour in world 41, the Seven Natural Wonders (owner #78, spec §24), as pure rules: what people
## built at nature's wonders, or what a child needs to see them safely, each in its wonder's own frame
## (WonderBuilds.Frame: its front toward -z, y up from the tour's ground) and turned into the world by WonderBuilds. The
## wonders themselves are the ground (NatureGround: the canyon, the volcano, the mountains, the falls, the bay, the reef,
## the snowy valley); these are the paths, stairs, lookouts and camps on them, and the water of the falls.
##   Grand Canyon: a lookout with a low wall on the west rim, a glass walk out over the canyon, a granary's stone front
##     with its doors in the cliff beside the trail down the gully (the trail itself is the ground's).
##   Great Barrier Reef: a jetty out from the beach to the coral cay, a stair down a glass tube into an underwater room
##     on the reef flat (corals at its windows), a ship's cannon on the reef.
##   Harbour of Rio de Janeiro: a promenade along the bay's shore, a paved lookout with a low wall on the Sugarloaf's top
##     (the steps up the ridge from the beach over Urca are the ground's).
##   Mount Everest: base camp's tents and prayer flags, stair 1 up to the South Col (packed snow), Camp IV's tents, stair 2
##     up the ridge to the summit, prayer flags strung on the summit and the ridge.
##   Northern Lights: a dirt path with ice lanterns into the snowy valley, a log cabin, a viewing deck with benches by
##     the frozen lake (the lights are NatureSky's, at night).
##   Parícutin: the farm track through the cornfield, a stair cut up the cone to its rim, a pool of glowing lava in the
##     crater behind a ring of rock (the game's lava never hurts) and a stair out of it, the church of San Juan's tower
##     and front wall rising out of the lava field.
##   Victoria Falls: the curtain of water from the lip to the pool (a rock buttress and Livingstone Island split it), the
##     rainforest path along the chasm's far lip with a hedge, a path to it, a stair down the chasm to the pool.

const AIR := BlockIds.AIR
const W := WonderBuilds.Y   # (frame y 0 is the tour's ground level)

## Where trees never grow round each wonder (frame rects): its builds and paths (WondersShape adds them to its clearings).
const CLEAR := {
	&"grand_canyon": [Rect2i(-18, -54, 9, 20), Rect2i(12, -32, 13, 14), Rect2i(-9, -36, 19, 8)],
	&"barrier_reef": [Rect2i(-4, -36, 9, 8)],
	&"rio_harbour": [Rect2i(-32, -32, 33, 33), Rect2i(-24, 18, 6, 9)],
	&"everest": [Rect2i(14, -82, 30, 22)],
	&"northern_lights": [Rect2i(-3, -44, 7, 42), Rect2i(-18, -28, 10, 10), Rect2i(-6, -8, 13, 7), Rect2i(9, 17, 19, 19)],
	&"paricutin": [Rect2i(-3, -56, 7, 22)],
	&"victoria_falls": [Rect2i(-32, -9, 65, 6), Rect2i(-3, -34, 7, 27), Rect2i(3, 3, 9, 10)],
}


# --- The Grand Canyon (face west: frame +x north, +z east) ---

const GLASS_X := Vector2i(16, 22)       # the glass walk's railings (frame x); it reaches GLASS_OUT over the canyon
const GLASS_OUT := 8
const LOOKOUT_X := 6                    # the lookout's wall along the rim, frame x ±LOOKOUT_X
## The granary in the gully's south wall beside the trail: its room (frame x, z), its floor's height (feet).
const GRANARY := Rect2i(-20, -24, 4, 5)
const GRANARY_DOOR_Z := -22


## The trail down the gully: the feet's height (frame y) at frame z (NatureGround's gully).
static func trail_feet(fz: int) -> int:
	return 0 if fz <= NatureGround.TRAIL_TOP else -(fz - NatureGround.TRAIL_TOP)


static func grand_canyon(b: WonderBuilds.Frame) -> void:
	var top := NatureGround.PLATEAU_TOP - W   # the plateau's feet (frame y)
	for fx in range(-LOOKOUT_X, LOOKOUT_X + 1):   # the lookout's low wall along the rim
		b.cell(Vector3i(fx, top, NatureGround.canyon_rim_west(fx)), BlockIds.KAIBAB_LIMESTONE)
	var rim := NatureGround.canyon_rim_west((GLASS_X.x + GLASS_X.y) / 2)
	b.box(Vector3i(GLASS_X.x, top - 1, rim), Vector3i(GLASS_X.y, top - 1, rim + GLASS_OUT), BlockIds.GLASS)   # its floor
	b.box(Vector3i(GLASS_X.x + 1, top, rim - 1), Vector3i(GLASS_X.y - 1, top + 2, rim + GLASS_OUT - 1), AIR)
	b.box(Vector3i(GLASS_X.x, top, rim), Vector3i(GLASS_X.x, top, rim + GLASS_OUT), BlockIds.GLASS)   # its railings
	b.box(Vector3i(GLASS_X.y, top, rim), Vector3i(GLASS_X.y, top, rim + GLASS_OUT), BlockIds.GLASS)
	b.box(Vector3i(GLASS_X.x, top, rim + GLASS_OUT), Vector3i(GLASS_X.y, top, rim + GLASS_OUT), BlockIds.GLASS)
	# the granary: a front of stacked stone in the gully's south wall, three small doors, a room behind
	var g := GRANARY
	var feet := trail_feet(GRANARY_DOOR_Z)
	b.box(Vector3i(g.position.x, feet - 1, g.position.y), Vector3i(g.end.x - 1, feet - 1, g.end.y - 1), BlockIds.SUPAI_REDBED)
	b.box(Vector3i(g.position.x, feet, g.position.y), Vector3i(g.end.x - 1, feet + 2, g.end.y - 1), AIR)
	var wall_x := g.end.x
	b.box(Vector3i(wall_x, feet - 1, g.position.y - 1), Vector3i(wall_x, feet + 3, g.end.y), BlockIds.COCONINO_SANDSTONE)
	b.box(Vector3i(wall_x, feet, GRANARY_DOOR_Z), Vector3i(wall_x, feet + 1, GRANARY_DOOR_Z), AIR)   # the door in
	for z: int in [g.position.y, g.end.y - 1]:   # two small doors, high up (granaries were sealed against mice)
		b.cell(Vector3i(wall_x, feet + 2, z), AIR)


# --- The Great Barrier Reef (face north: frame = world - its centre) ---

const JETTY_FROM := -30                 # the jetty's deck from the beach (frame z) ...
const JETTY_TO := -7                    # ... to the cay
const DECK := NatureGround.CAY_TOP - 1  # its planks (absolute y; feet one higher)
## The underwater room on the reef flat: its air (frame x, z) and its floor's height (absolute, glass).
const ROOM := Rect2i(3, -16, 5, 7)
const ROOM_FLOOR := NatureGround.REEF_FLOOR
const TUBE_X := Vector2i(3, 5)
## The ship's cannon on the reef (frame x from-to, z), on the reef's floor.
const CANNON := Vector3i(10, 12, -12)


static func barrier_reef(b: WonderBuilds.Frame) -> void:
	var deck := DECK - W
	b.box(Vector3i(-1, deck, JETTY_FROM), Vector3i(1, deck, JETTY_TO), BlockIds.PLANKS)
	for z in range(JETTY_FROM, JETTY_TO + 1, 6):   # its posts, down to the sea floor
		for x: int in [-1, 1]:
			b.box(Vector3i(x, NatureGround.SEA_DEEP - W, z), Vector3i(x, deck - 1, z), BlockIds.LOG)
	for x: int in [-2, 2]:   # low rails, with a gap to the landing
		b.box(Vector3i(x, deck + 1, JETTY_FROM + 2), Vector3i(x, deck + 1, JETTY_TO - 1), BlockIds.LOG)
	b.box(Vector3i(2, deck + 1, -26), Vector3i(2, deck + 1, -24), AIR)
	b.box(Vector3i(2, deck, -26), Vector3i(TUBE_X.y, deck, -24), BlockIds.PLANKS)   # the landing over the tube
	# the glass tube: down a step a block from the landing into the room on the reef flat
	var floor_y := ROOM_FLOOR - W
	var room := ROOM
	b.box(Vector3i(room.position.x - 1, floor_y, room.position.y - 1), Vector3i(room.end.x, floor_y + 4, room.end.y),
		BlockIds.GLASS)
	b.box(Vector3i(room.position.x, floor_y + 1, room.position.y), Vector3i(room.end.x - 1, floor_y + 3, room.end.y - 1), AIR)
	var steps := (deck + 1) - (floor_y + 1)
	for j in range(1, steps + 1):
		var z := -24 + j
		var feet := deck + 1 - j
		b.box(Vector3i(TUBE_X.x - 1, feet - 1, z), Vector3i(TUBE_X.y + 1, feet + 3, z), BlockIds.GLASS)
		b.box(Vector3i(TUBE_X.x, feet, z), Vector3i(TUBE_X.y, feet + 2, z), AIR)
		b.box(Vector3i(TUBE_X.x, feet - 1, z), Vector3i(TUBE_X.y, feet - 1, z), BlockIds.PLANKS)
	b.box(Vector3i(TUBE_X.x, deck + 1, -24), Vector3i(TUBE_X.y, deck + 3, -24), AIR)   # the way in from the landing
	# the cannon on the reef, coral growing on it
	var c := CANNON
	b.box(Vector3i(c.x, floor_y, c.z), Vector3i(c.y, floor_y, c.z), BlockIds.DEEPSTONE)
	b.cell(Vector3i(c.y, floor_y + 1, c.z), BlockIds.STAGHORN_CORAL)
	# the cay: a signpost by the jetty's end
	b.box(Vector3i(2, NatureGround.CAY_TOP - W, -5), Vector3i(2, NatureGround.CAY_TOP - W + 1, -5), BlockIds.LOG)
	b.cell(Vector3i(2, NatureGround.CAY_TOP - W + 2, -5), BlockIds.PLANKS)


# --- The Harbour of Rio de Janeiro (face north: frame = world - its centre) ---

const PROMENADE := Vector2(27.5, 29.5)  # the promenade's ring (frame radii) round the bay's north-west
const LOOKOUT_R := 3.5                  # the Sugarloaf's lookout round its top


static func rio_harbour(b: WonderBuilds.Frame) -> void:
	var r1 := ceili(PROMENADE.y)
	for fz in range(-r1, 1):   # the promenade: paving on the bay's north-west shore
		var run := []
		for fx in range(-r1, 1):
			var r := Vector2(fx, fz).length()
			if r >= PROMENADE.x and r <= PROMENADE.y:
				run.append(fx)
		if not run.is_empty():
			b.box(Vector3i(int(run.min()), -1, fz), Vector3i(int(run.max()), -1, fz), BlockIds.PAVING)
	# the lookout on the Sugarloaf's top: a paved floor and a low wall, open where the steps arrive
	var sl := NatureGround.SUGARLOAF
	var top := NatureGround.SEA + NatureGround.SUGARLOAF_TOP - W
	var c := Vector2i(int(sl.x), int(sl.y))
	var lr := ceili(LOOKOUT_R + 1)
	for dz in range(-lr, lr + 1):
		for dx in range(-lr, lr + 1):
			var r := Vector2(dx, dz).length()
			var steps := dx < 0 and absi(c.y + dz - NatureGround.STEPS_Z) <= 1   # where the steps come up into it
			if r <= LOOKOUT_R and not steps:
				b.cell(Vector3i(c.x + dx, top - 1, c.y + dz), BlockIds.PAVING)
				b.box(Vector3i(c.x + dx, top, c.y + dz), Vector3i(c.x + dx, top + 2, c.y + dz), AIR)
			elif r > LOOKOUT_R and r <= LOOKOUT_R + 1.0 and not steps:
				b.cell(Vector3i(c.x + dx, top, c.y + dz), BlockIds.WHITE_BRICK)
	# a signpost at the steps' foot
	var foot := NatureGround.STEPS_FROM - 2
	b.box(Vector3i(foot, NatureGround.STEPS_FOOT - W, NatureGround.STEPS_Z - 2),
		Vector3i(foot, NatureGround.STEPS_FOOT - W + 1, NatureGround.STEPS_Z - 2), BlockIds.LOG)
	b.cell(Vector3i(foot, NatureGround.STEPS_FOOT - W + 2, NatureGround.STEPS_Z - 2), BlockIds.PLANKS)


# --- Mount Everest (face east: frame +x south, +z west) ---

## Base camp's tents (frame x, z of a corner; each 3 by 3) and their colours.
const CAMP_TENTS: Array[Vector3i] = [Vector3i(17, -75, BlockIds.YELLOW), Vector3i(21, -75, BlockIds.RED),
	Vector3i(31, -75, BlockIds.YELLOW), Vector3i(35, -75, BlockIds.BLUE), Vector3i(17, -69, BlockIds.RED),
	Vector3i(35, -69, BlockIds.YELLOW), Vector3i(39, -69, BlockIds.RED)]
const COL_TENTS: Array[Vector3i] = [Vector3i(30, -3, BlockIds.YELLOW), Vector3i(30, 1, BlockIds.RED)]
const FLAGS_Z := -71                    # base camp's string of flags (frame z), from frame x 15 to 41


static func everest(b: WonderBuilds.Frame) -> void:
	var foot := NatureGround.ROUTE_FOOT
	for fz in range(foot + 1, 1):   # stair 1: packed snow steps up to the col
		var feet := fz - foot
		b.box(Vector3i(NatureGround.STAIR1_X - 1, feet - 1, fz), Vector3i(NatureGround.STAIR1_X + 1, feet - 1, fz),
			BlockIds.PACKED_SNOW)
		b.box(Vector3i(NatureGround.STAIR1_X - 1, feet, fz), Vector3i(NatureGround.STAIR1_X + 1, feet + 2, fz), AIR)
	for fx in range(1, NatureGround.COL_X):   # stair 2: up the ridge from the col to the summit
		var feet := NatureGround.EVEREST_TOP - fx
		b.box(Vector3i(fx, feet - 1, -1), Vector3i(fx, feet - 1, 1), BlockIds.PACKED_SNOW)
		b.box(Vector3i(fx, feet, -1), Vector3i(fx, feet + 2, 1), AIR)
	for t: Vector3i in CAMP_TENTS:
		_tent(b, t.x, 0, t.y, t.z)
	for t: Vector3i in COL_TENTS:
		_tent(b, t.x, NatureGround.COL_TOP, t.y, t.z)
	b.box(Vector3i(15, 0, FLAGS_Z), Vector3i(15, 2, FLAGS_Z), BlockIds.LOG)   # base camp's prayer flags
	b.box(Vector3i(41, 0, FLAGS_Z), Vector3i(41, 2, FLAGS_Z), BlockIds.LOG)
	b.box(Vector3i(16, 3, FLAGS_Z), Vector3i(40, 3, FLAGS_Z), BlockIds.PRAYER_FLAGS)
	var top := NatureGround.EVEREST_TOP
	b.box(Vector3i(-1, top, -2), Vector3i(1, top + 2, 2), AIR)   # room on the summit
	b.box(Vector3i(-2, top, -2), Vector3i(-2, top + 1, -2), BlockIds.LOG)   # flags strung on the summit
	b.box(Vector3i(-2, top, 2), Vector3i(-2, top + 1, 2), BlockIds.LOG)
	b.box(Vector3i(-2, top + 1, -1), Vector3i(-2, top + 1, 1), BlockIds.PRAYER_FLAGS)
	b.cell(Vector3i(-1, top - 1, 1), BlockIds.SEA_FOSSIL)   # the summit's rock: limestone with sea fossils
	b.cell(Vector3i(0, top - 1, -1), BlockIds.SEA_FOSSIL)


## A small tent: a 3 by 3 base two high and a ridge on top (frame corner x, y, z).
static func _tent(b: WonderBuilds.Frame, x: int, y: int, z: int, colour: int) -> void:
	b.box(Vector3i(x, y, z), Vector3i(x + 2, y + 1, z + 2), colour)
	b.box(Vector3i(x + 1, y + 2, z), Vector3i(x + 1, y + 2, z + 2), colour)


# --- The Northern Lights (face east: frame +x south, +z west) ---

const CABIN := Rect2i(-16, -26, 7, 7)   # its walls (frame x, z)
const DECK_RECT := Rect2i(-4, -6, 9, 4)
const LANTERN_ZS: Array[int] = [-38, -30, -22, -14]


static func northern_lights(b: WonderBuilds.Frame) -> void:
	b.box(Vector3i(-1, -1, -44), Vector3i(1, -1, -7), BlockIds.DIRT)   # the path in from the gate
	for z: int in LANTERN_ZS:   # ice lanterns on posts along it
		b.box(Vector3i(2, 0, z), Vector3i(2, 1, z), BlockIds.LOG)
		b.cell(Vector3i(2, 2, z), BlockIds.ICE_LANTERN)
	var d := DECK_RECT   # the viewing deck by the frozen lake, benches facing it
	b.box(Vector3i(d.position.x, 0, d.position.y), Vector3i(d.end.x - 1, 0, d.end.y - 1), BlockIds.PLANKS)
	for x: int in [d.position.x, d.end.x - 1]:
		for z: int in [d.position.y, d.end.y - 1]:
			b.box(Vector3i(x, 1, z), Vector3i(x, 2, z), BlockIds.LOG)
	for x in range(d.position.x + 1, d.end.x - 1, 2):
		b.cell(Vector3i(x, 1, d.end.y - 2), BlockIds.PLANKS)
	var c := CABIN   # a log cabin: its door toward the path, windows east and toward the lake, a lantern inside
	var x0 := c.position.x
	var x1 := c.end.x - 1
	var z0 := c.position.y
	var z1 := c.end.y - 1
	b.box(Vector3i(x0, -1, z0), Vector3i(x1, -1, z1), BlockIds.PLANKS)
	b.box(Vector3i(x0, 0, z0), Vector3i(x1, 3, z1), BlockIds.LOG)
	b.box(Vector3i(x0 + 1, 0, z0 + 1), Vector3i(x1 - 1, 3, z1 - 1), AIR)
	b.box(Vector3i(x1, 0, (z0 + z1) / 2), Vector3i(x1, 1, (z0 + z1) / 2), AIR)   # the door (south, toward the path)
	b.cell(Vector3i((x0 + x1) / 2, 1, z0), BlockIds.GLASS)
	b.cell(Vector3i((x0 + x1) / 2, 1, z1), BlockIds.GLASS)
	b.cell(Vector3i(x0 + 1, 2, z0 + 1), BlockIds.LANTERN)
	for j in 3:   # a roof of planks, a step in each time
		b.box(Vector3i(x0 - 1 + j, 4 + j, z0 - 1), Vector3i(x1 + 1 - j, 4 + j, z1 + 1), BlockIds.PLANKS)


# --- Parícutin (face south: frame +x west, +z north) ---

const STAIR_FOOT := -35                 # the stair up the cone: from here (frame z, feet at 0) to the rim
const CRATER_STAIR_X := Vector2i(4, 6)  # the stair out of the crater (frame x), from its floor (z -4) to the rim
## The church of San Juan in the lava field: the tower (frame x, z of its corner, 4 by 4), the front wall's x span.
const TOWER := Vector2i(14, 52)
const TOWER_TOP := 13
const FRONT := Vector2i(6, 13)


static func paricutin(b: WonderBuilds.Frame) -> void:
	b.box(Vector3i(-1, -1, -54), Vector3i(1, -1, STAIR_FOOT - 1), BlockIds.DIRT)   # the farm track
	var rim := NatureGround.CONE_TOP
	for fz in range(STAIR_FOOT, -int(NatureGround.CRATER_R) - 1):   # the stair cut up the cone
		var feet := fz - STAIR_FOOT
		b.box(Vector3i(-1, feet - 1, fz), Vector3i(1, feet - 1, fz), BlockIds.CINDER)
		b.box(Vector3i(-1, feet, fz), Vector3i(1, feet + 2, fz), AIR)
	# the crater's lava pool behind a ring of rock, and a stair out of the crater
	var floor_y := NatureGround.CRATER_FLOOR
	for dz in range(-5, 6):
		for dx in range(-5, 6):
			var r := Vector2(dx, dz).length()
			if r <= 3.2:
				b.cell(Vector3i(dx, floor_y - 1, dz), BlockIds.HOT_LAVA)
			elif r <= 4.6:
				b.cell(Vector3i(dx, floor_y, dz), BlockIds.BLACK_LAVA)
	for fz in range(-4, 6):
		var feet := floor_y + (fz + 4)
		var x0 := CRATER_STAIR_X.x
		var x1 := CRATER_STAIR_X.y
		if feet - 1 >= floor_y:
			b.box(Vector3i(x0, floor_y, fz), Vector3i(x1, feet - 1, fz), BlockIds.CINDER)
		b.box(Vector3i(x0, feet, fz), Vector3i(x1, feet + 2, fz), AIR)
	b.box(Vector3i(CRATER_STAIR_X.x, rim, 6), Vector3i(CRATER_STAIR_X.y, rim + 2, 6), AIR)
	# the church of San Juan: its tower and front wall rising out of the lava
	var t := TOWER
	b.box(Vector3i(t.x, 0, t.y), Vector3i(t.x + 3, TOWER_TOP - 1, t.y + 3), BlockIds.WALL_BRICK)
	var bell := TOWER_TOP - 3   # the belfry: hollow, an opening in the middle of each side
	b.box(Vector3i(t.x + 1, bell - 1, t.y + 1), Vector3i(t.x + 2, TOWER_TOP - 1, t.y + 2), AIR)
	b.box(Vector3i(t.x + 1, bell, t.y), Vector3i(t.x + 2, bell + 1, t.y + 3), AIR)
	b.box(Vector3i(t.x, bell, t.y + 1), Vector3i(t.x + 3, bell + 1, t.y + 2), AIR)
	b.box(Vector3i(t.x, TOWER_TOP, t.y), Vector3i(t.x + 3, TOWER_TOP, t.y + 3), BlockIds.WALL_BRICK)
	b.box(Vector3i(t.x + 1, TOWER_TOP + 1, t.y + 1), Vector3i(t.x + 2, TOWER_TOP + 1, t.y + 2), BlockIds.WALL_BRICK)
	b.box(Vector3i(FRONT.x, 0, t.y), Vector3i(FRONT.y, 6, t.y), BlockIds.WALL_BRICK)   # the front wall and its gable
	b.box(Vector3i(FRONT.x + 2, 7, t.y), Vector3i(FRONT.y - 2, 7, t.y), BlockIds.WALL_BRICK)
	b.box(Vector3i(FRONT.x + 3, 8, t.y), Vector3i(FRONT.y - 3, 8, t.y), BlockIds.WALL_BRICK)
	b.box(Vector3i(FRONT.x + 3, 3, t.y), Vector3i(FRONT.y - 3, 5, t.y), AIR)   # its doorway, half filled with lava
	b.box(Vector3i(FRONT.x + 3, 3, t.y + 1), Vector3i(FRONT.y - 3, 3, t.y + 1), BlockIds.BLACK_LAVA)


# --- Victoria Falls (face north: frame = world - its centre) ---

## The water curtain over the chasm's south row (frame x spans), split by a rock buttress and Livingstone Island.
const CURTAINS: Array[Vector2i] = [Vector2i(-22, -11), Vector2i(-8, 3), Vector2i(11, 22)]
const PATH_Z := Vector2i(-7, -5)        # the rainforest path along the north lip
const HEDGE_Z := -4
const STAIR_DOWN := Vector2i(-27, -3)   # the stair down the chasm's north side: from frame x -27 (feet a block under
                                        # the lip) east to -3 (feet just over the pool)


static func victoria_falls(b: WonderBuilds.Frame) -> void:
	var lip := NatureGround.RIVER_TOP - 1 - W     # the river's surface (frame y)
	var pool := NatureGround.POOL_TOP - W         # the first cell over the pool
	var south := NatureGround.CHASM_Z.y
	for c: Vector2i in CURTAINS:   # the falling water
		b.box(Vector3i(c.x, pool, south), Vector3i(c.y, lip, south), BlockIds.WATER)
	for c: Vector2i in [Vector2i(-10, -9), Vector2i(4, 10)]:   # the rock between: a buttress, Livingstone Island's face
		b.box(Vector3i(c.x, pool, south), Vector3i(c.y, 0, south), BlockIds.BLACK_LAVA)
	var half := NatureGround.CHASM_HALF + 2
	b.box(Vector3i(-half, -1, PATH_Z.x), Vector3i(half, -1, PATH_Z.y), BlockIds.DIRT)   # the rainforest path
	b.box(Vector3i(-1, -1, -34), Vector3i(1, -1, PATH_Z.x - 1), BlockIds.DIRT)   # the path to it from the gate
	for x0 in range(-NatureGround.CHASM_HALF + 4, NatureGround.CHASM_HALF + 1, 9):   # the hedge on the lip, with gaps
		b.box(Vector3i(x0, 0, HEDGE_Z), Vector3i(mini(x0 + 6, NatureGround.CHASM_HALF), 0, HEDGE_Z), BlockIds.LEAVES)
	var s := STAIR_DOWN   # the stair down to the pool (the Boiling Pot's path), along the chasm's north side
	for fx in range(s.x, s.y + 1):
		var feet := -1 - (fx - s.x)
		b.box(Vector3i(fx, NatureGround.POOL_BED - W, NatureGround.CHASM_Z.x), Vector3i(fx, feet - 1, -1),
			BlockIds.BLACK_LAVA)
		b.box(Vector3i(fx, feet, NatureGround.CHASM_Z.x), Vector3i(fx, feet + 2, -1), AIR)
