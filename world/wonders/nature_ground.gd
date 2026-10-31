class_name NatureGround
extends RefCounted
## The ground of world 41's third region (owner #78, spec §24), round the Seven Natural Wonders' square (WonderTour
## NATURE_SQUARE, out to NATURE_R), as pure rules, the same in every world (seed-free): flat park land at the tour's
## ground level (WonderTour.BASE_Y), snowy in the west, a round sea in the south-east (a sandy beach, a shelf), and
## nature's wonders shaped into it, each in its wonder's own frame (WonderTour.WONDERS: the centres and facings here are
## copies, checked by test_wonders_nature_ground):
##   the Grand Canyon: a plateau with a long canyon cut into it, its walls in layers of rock (strata: the generator
##     colours them by height, the oldest at the bottom), the Colorado River in its bottom, a side gully a trail goes down;
##   Parícutin: a cinder cone with a crater, its cornfield round it, a black lava field behind it;
##   the northern lights' valley: snowy flat land, a frozen lake, a snow mound;
##   Mount Everest with Lhotse and the South Col between them, the climbing route's shoulder from base camp up to the col
##     and the ridge from the col to the summit (both stairs: a block a step);
##   Victoria Falls: a river on the plateau flowing north from a lake, falling into a narrow chasm of basalt, a zigzag
##     gorge, Livingstone Island on the lip, basalt under the land round it;
##   the Harbour of Rio de Janeiro: a round bay opening to the sea, islands in it, Urca and the Sugarloaf rising from the
##     water on its south side, joined by a rocky ridge of steps up to the Sugarloaf's top;
##   the Great Barrier Reef: a coral cay off the coast in a shallow reef flat (coral heads on it: coral_at).
## sample(x, z) gives a column's height (the first air over the ground) and its kind (what the generator writes:
## WondersGenerator._write_nature_column); the trees, corn, corals and spray are decisions made here too. Cheap: a few
## box tests, then one feature's sums.

const Y := WonderTour.BASE_Y
const SEA := MeadowsShape.SEA_LEVEL      # water fills a sea column below this (to SEA - 1)

## What a column is made of (WondersGenerator writes it).
const LAND := 0           # grass on dirt
const SNOW := 1           # snowy grass (the snowy west, the mountains' feet)
const BEACH := 2          # sand (dry, or under shallow water)
const SEA_FLOOR := 3      # sand under the sea
const CANYON := 4         # bare layered rock (strata by height); the river's water in its bottom
const PLATEAU := 5        # the canyon's plateau: grass on its layered rock
const CINDER := 6         # Parícutin's cinder cone
const LAVA := 7           # the black lava field
const MOUNTAIN := 8       # Everest's rock, snow over the snow line
const RIVER := 9          # the falls' river and its lake: water over a basalt bed (up to RIVER_TOP)
const CHASM := 10         # the falls' chasm and gorge: basalt, a pool at the bottom (up to POOL_TOP)
const FARM := 11          # Parícutin's cornfield
const REEF := 12          # the reef flat: sand under shallow water, coral heads
const ROCK := 13          # the Sugarloaf, Urca and the ridge between them: bare granite
const LAKE_ICE := 14      # the frozen lake: ice over water
const BASALT_LAND := 15   # grass on basalt (round the falls)

# --- The sea: a round sea (centre SEA_O, radius SEA_R) south-east of the square; coast(x, z) > 0 is seaward ---
const SEA_O := Vector2(400, 600)
const SEA_R := 200.0
const BEACH_IN := 8.0
const SHELF := 12.0
const SEA_DEEP := 14
## Snow: west of a wavy line (x + SNOW_WAVE sin(z SNOW_FREQ) < SNOW_X).
const SNOW_X := 98.0
const SNOW_WAVE := 10.0
const SNOW_FREQ := 0.045

# --- The Grand Canyon (face west: frame x = CANYON_C.y - z (north), frame z = x - CANYON_C.x (east)) ---
const CANYON_C := Vector2i(288, 330)
const CANYON_HALF := Vector2i(60, 48)    # the plateau's ramp ends here
const PLATEAU_FLAT := Vector2i(44, 34)   # ... and it is flat to here
const PLATEAU_TOP := 44                  # the first air over the plateau (the rim)
const CANYON_LEN := 48.0                 # the canyon closes at frame x ±48
const RIM := 28.0                        # the canyon's half width at the rim (where it is widest)
const MEANDER := 4.0
const RIVER_BED := 2                     # the river's bed (first air): its water from here to CANYON_WATER_TOP - 1
const CANYON_WATER_TOP := 5
## The trail down a side gully: frame x TRAIL_X ± 1, level with the park (Y) from the plateau's edge to TRAIL_TOP, then
## down a block a step to the river's bank at TRAIL_END.
const TRAIL_X := -14
const TRAIL_END := -9
const TRAIL_TOP := TRAIL_END - (Y - 5)
## Buttes in the canyon: frame x, how far from the canyon's middle (frame z), radius (away from the river, the trail and
## the glass walk).
const BUTTES: Array[Vector3] = [Vector3(-22, 15, 8.5), Vector3(6, 16, 8.5), Vector3(30, -15, 7.5)]
static var _butte_at: Array[Vector3] = _butte_centres()   # their middles (frame x, z) and radii, worked out once


static func _butte_centres() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for b: Vector3 in BUTTES:
		out.append(Vector3(b.x, canyon_middle(int(b.x)) + b.y, b.z))
	return out
## The rock layers, bottom up (each from its y to the next one's): the Vishnu Schist, the Bright Angel Shale, the Redwall
## Limestone, the Supai red beds, the Coconino Sandstone, the Kaibab Limestone at the rim.
const STRATA: Array[Vector2i] = [Vector2i(-64, BlockIds.VISHNU_SCHIST), Vector2i(13, BlockIds.CANYON_SHALE),
	Vector2i(16, BlockIds.REDWALL_LIMESTONE), Vector2i(25, BlockIds.SUPAI_REDBED), Vector2i(33, BlockIds.COCONINO_SANDSTONE),
	Vector2i(39, BlockIds.KAIBAB_LIMESTONE)]

# --- Parícutin (face south: frame x = PARICUTIN_C.x - x, frame z = PARICUTIN_C.y - z) ---
const PARICUTIN_C := Vector2i(170, 272)
const CONE_R := 40.0
const CONE_TOP := 26                     # the rim, over the tour's ground
const CRATER_R := 7.0
const CRATER_FLOOR := 16
const POOL_R := 4.0                      # the crater's floor is flat out to here (the lava pool and its rock ring)
const FARM_R := 54.0
const LAVA_FIELD := Vector4(8, 50, 22, 18)   # the lava field's ellipse: frame centre (x, z), radii (x, z)
const TRACK_HALF := 2                    # the farm track to the cone's stair (frame x)

# --- The northern lights' valley (face east: frame x = z - AURORA_C.y (south), frame z = AURORA_C.x - x (west)) ---
const AURORA_C := Vector2i(55, 348)
const VALLEY_R := 50.0
const LAKE := Vector4(0, 12, 16, 10)     # the frozen lake's ellipse: frame centre, radii
const MOUND := Vector3(18, 26, 8)        # the snow mound (the ice cave): frame centre, radius
const MOUND_TOP := 8

# --- Mount Everest (face east: frame x = z - EVEREST_C.y (south), frame z = EVEREST_C.x - x (west)) ---
const EVEREST_C := Vector2i(0, 470)
const EVEREST_TOP := 88
const EVEREST_R := 56.0
const LHOTSE := Vector2i(40, 0)          # frame
const LHOTSE_TOP := 78
const LHOTSE_R := 40.0
const COL_X := 26                        # the South Col's flat, from here (frame x) to COL_X + 6, between the peaks
const COL_TOP := 62
const STAIR1_X := 28                     # stair 1 runs along frame x STAIR1_X ± 1 from ROUTE_FOOT (feet at Y) up to the col
const ROUTE_FOOT := -COL_TOP
const SNOW_LINE := 34                    # over the tour's ground: snow on the mountains' tops from here up
const RIDGE_FALL := 2.2                  # the ridge's sides fall this many blocks a block

# --- Victoria Falls (face north: frame = world - FALLS_C) ---
const FALLS_C := Vector2i(140, 528)
const CHASM_HALF := 28
const CHASM_Z := Vector2i(-3, 3)
const POOL_BED := 4                      # the chasm's pool: water from y 4 to POOL_TOP - 1
const POOL_TOP := 7
const FALLS_RIVER := Vector4i(-22, 4, 22, 62)   # the river: frame x from, z from, x to, z to
const RIVER_BED_Y := 29                  # water from here to RIVER_TOP - 1
const RIVER_TOP := 32
const SOURCE := Vector3(0, 74, 20)       # the lake the river flows from: frame centre, radius
const ISLAND := Vector4i(4, 4, 10, 11)   # Livingstone Island on the lip: frame x from, z from, x to, z to
const GORGE_W := Vector4i(-44, -3, -29, 3)
const GORGE_S := Vector4i(-44, 4, -38, 34)
const FALLS_BOX := Vector4i(-50, -36, 50, 96)

# --- The Harbour of Rio de Janeiro (face north: frame = world - RIO_C) ---
const RIO_C := Vector2i(236, 486)
const BAY_R := 20.0
const BAY_SHORE := 26.0
const BAY_FLOOR := 16
const SUGARLOAF := Vector4(11, 22, 12, 9)   # frame centre, radii (x, z)
const SUGARLOAF_TOP := 36                # over the sea level: its top's feet at y 60
const URCA := Vector4(-7, 22, 10, 8)
const URCA_TOP := 18
const STEPS_Z := 22                      # the ridge of steps along frame z 21-23 ...
const STEPS_FROM := -19                  # ... from frame x -19 (on the beach) ...
const STEPS_TO := 11                     # ... to the Sugarloaf's top
const STEPS_FOOT := SEA + SUGARLOAF_TOP - (STEPS_TO - STEPS_FROM)
const BAY_ISLANDS: Array[Vector3] = [Vector3(-8, -6, 3), Vector3(6, -10, 2)]

# --- The Great Barrier Reef (face north: frame = world - REEF_C) ---
const REEF_C := Vector2i(318, 445)
const CAY_R := 5.0
const CAY_TOP := 26
const REEF_R := 24.0
const REEF_FLOOR := 18
const REEF_EDGE := 30.0


## (height, kind) of column (x, z) in the region: the height is the first air over the ground.
static func sample(x: int, z: int) -> Vector2i:
	if x >= 226 and x <= 350 and z >= 268 and z <= 392:
		var c := _canyon(x, z)
		if c.x >= 0:
			return c
	if x >= 114 and x <= 226 and z >= 200 and z <= 328:
		var p := _paricutin(x, z)
		if p.x >= 0:
			return p
	if x >= 0 and x <= 110 and z >= 296 and z <= 400:
		var a := _aurora(x, z)
		if a.x >= 0:
			return a
	if x >= -62 and x <= 84 and z >= 408 and z <= 556:
		var e := _everest(x, z)
		if e.x >= 0:
			return e
	if x >= FALLS_C.x + FALLS_BOX.x and x <= FALLS_C.x + FALLS_BOX.z and z >= FALLS_C.y + FALLS_BOX.y \
			and z <= FALLS_C.y + FALLS_BOX.w:
		return _falls(x, z)
	var cst := coast(x, z)
	if x >= 204 and x <= 268 and z >= 454 and z <= 524:
		var r := _rio(x, z, cst)
		if r.x >= 0:
			return r
	if x >= 286 and x <= 350 and z >= 413 and z <= 477:
		var f := _reef(x, z, cst)
		if f.x >= 0:
			return f
	return _plain(x, z, cst)


static func height(x: int, z: int) -> int:
	return sample(x, z).x


## How far (x, z) is out to sea from the coast (< 0 inland).
static func coast(x: int, z: int) -> float:
	return SEA_R - Vector2(x - SEA_O.x, z - SEA_O.y).length()


## The ground's height (absolute) at `c` from the coast: the park, the beach sloping down, the shelf, the sea floor.
static func coast_height(c: float) -> int:
	if c <= -BEACH_IN:
		return Y
	if c <= 0.0:
		return Y - roundi(c + BEACH_IN)
	if c <= SHELF:
		return SEA - roundi(c * (SEA - SEA_DEEP) / SHELF)
	return SEA_DEEP


## The snowy west (the northern valley, Everest's feet).
static func snowy(x: int, z: int) -> bool:
	return x + SNOW_WAVE * sin(z * SNOW_FREQ) < SNOW_X


static func _plain(x: int, z: int, c: float) -> Vector2i:
	var h := coast_height(c)
	if c > 0.0:
		return Vector2i(h, SEA_FLOOR if h < SEA - 1 else BEACH)
	if c > -BEACH_IN - 2.0:
		return Vector2i(h, BEACH)
	return Vector2i(h, SNOW if snowy(x, z) else LAND)


# --- The Grand Canyon ---

static func _canyon(x: int, z: int) -> Vector2i:
	var fx := CANYON_C.y - z
	var fz := x - CANYON_C.x
	if absi(fx) > CANYON_HALF.x or absi(fz) > CANYON_HALF.y:
		return Vector2i(-1, 0)
	var qx := float(absi(fx) - PLATEAU_FLAT.x) / (CANYON_HALF.x - PLATEAU_FLAT.x)
	var qz := float(absi(fz) - PLATEAU_FLAT.y) / (CANYON_HALF.y - PLATEAU_FLAT.y)
	var q := clampf(maxf(qx, qz), 0.0, 1.0)
	var h := PLATEAU_TOP - roundi(q * (PLATEAU_TOP - Y))
	var k := PLATEAU
	var d := canyon_d(fx, fz)
	if d < RIM:
		h = maxi(canyon_profile(d), _butte(fx, fz))
		k = CANYON
	if absi(fx - TRAIL_X) <= 1 and fz <= TRAIL_END:
		var t := Y if fz <= TRAIL_TOP else Y - (fz - TRAIL_TOP)
		if t < h:
			h = t
			k = CANYON
	return Vector2i(h, k)


## The meander of the canyon's middle (frame z) at frame x.
static func canyon_middle(fx: int) -> float:
	return MEANDER * sin(fx * 0.07)


## How far (frame x, z) is from the canyon's middle, stretched where the canyon narrows toward its ends (RIM and more
## past them: the plateau).
static func canyon_d(fx: int, fz: int) -> float:
	if absf(fx) >= CANYON_LEN:
		return 1e6
	var w := sqrt(1.0 - (fx / CANYON_LEN) * (fx / CANYON_LEN))
	return absf(fz - canyon_middle(fx)) / maxf(w, 0.02)


## The ground's height (absolute) at distance d from the canyon's middle: the river, its banks, the Inner Gorge's cliffs
## of schist, the Tonto Platform, the Redwall's cliff, the Supai's ledges, the Coconino's cliff, the slope, the Kaibab
## at the rim.
static func canyon_profile(d: float) -> int:
	if d < 3.5:
		return RIVER_BED
	if d < 5.5:
		return 5
	if d < 7.5:
		return roundi(5.0 + (d - 5.5) * 4.0)
	if d < 13.5:
		return roundi(13.0 + (d - 7.5) / 6.0)
	if d < 15.5:
		return roundi(14.0 + (d - 13.5) * 4.5)
	if d < 21.5:
		return 23 + floori((d - 15.5) * 10.0 / 6.0 / 2.0) * 2
	if d < 23.5:
		return roundi(33.0 + (d - 21.5) * 2.5)
	if d < 26.0:
		return roundi(38.0 + (d - 23.5) * 2.0 / 2.5)
	return mini(roundi(40.0 + (d - 26.0) * 2.0), PLATEAU_TOP)


## A butte standing in the canyon (frame x, z): a tower of the canyon's own layers left behind as the river and the rain
## wore the land round it away (the real canyon's "temples"), stepped like the walls; -1 off them.
static func _butte(fx: int, fz: int) -> int:
	for b: Vector3 in _butte_at:
		if absf(fx - b.x) >= b.z:
			continue
		var r := Vector2(fx - b.x, fz - b.y).length()
		if r < b.z:
			if r < b.z * 0.3:
				return 41
			if r < b.z * 0.55:
				return 34
			if r < b.z * 0.8:
				return 25
			return 16
	return -1


## The canyon's rim on its west side (frame z of the last plateau column) at frame x.
static func canyon_rim_west(fx: int) -> int:
	var w := sqrt(maxf(1.0 - (fx / CANYON_LEN) * (fx / CANYON_LEN), 0.0))
	return floori(canyon_middle(fx) - RIM * w)


## The rock layer at height y in the canyon's walls.
static func stratum(y: int) -> int:
	var id: int = STRATA[0].y
	for s: Vector2i in STRATA:
		if y >= s.x:
			id = s.y
	return id


# --- Parícutin ---

static func _paricutin(x: int, z: int) -> Vector2i:
	var fx := PARICUTIN_C.x - x
	var fz := PARICUTIN_C.y - z
	var r := sqrt(float(fx * fx + fz * fz))
	var cone := -1
	if r < CONE_R:
		cone = Y + cone_height(r)
	var ex := (fx - LAVA_FIELD.x) / LAVA_FIELD.z
	var ez := (fz - LAVA_FIELD.y) / LAVA_FIELD.w
	if ex * ex + ez * ez <= 1.0:
		var lava := Y + 2 + absi(_h(x, z)) % 2
		if lava >= cone:
			return Vector2i(lava, LAVA)
	if cone >= 0:
		return Vector2i(cone, CINDER)
	if r < FARM_R:
		return Vector2i(Y, FARM)
	return Vector2i(-1, 0)


## The cone's height over the tour's ground at radius r: the crater's flat floor, its bowl, the rim, the slope.
static func cone_height(r: float) -> int:
	if r < POOL_R:
		return CRATER_FLOOR
	if r < CRATER_R:
		var t := (r - POOL_R) / (CRATER_R - POOL_R)
		return CRATER_FLOOR + roundi((CONE_TOP - CRATER_FLOOR) * t * t)
	if r < CRATER_R + 2.0:
		return CONE_TOP
	return roundi(CONE_TOP * (CONE_R - r) / (CONE_R - CRATER_R - 2.0))


## Corn grows here (Parícutin's cornfield: rows along z, every other x, a few gaps; never on the track to the stair).
static func corn_at(x: int, z: int) -> bool:
	if posmod(x, 2) != 0 or absi(_h(z, x)) % 13 == 0:
		return false
	var fx := PARICUTIN_C.x - x
	var fz := PARICUTIN_C.y - z
	if absi(fx) <= TRACK_HALF and fz < 0:
		return false
	var r2 := float(fx * fx + fz * fz)
	if r2 < CONE_R * CONE_R or r2 >= FARM_R * FARM_R:
		return false
	var ex := (fx - LAVA_FIELD.x) / LAVA_FIELD.z
	var ez := (fz - LAVA_FIELD.y) / LAVA_FIELD.w
	return ex * ex + ez * ez > 1.0   # (the field's own sums: sample's FARM, without the other wonders' boxes)


# --- The northern lights' valley ---

static func _aurora(x: int, z: int) -> Vector2i:
	var fx := z - AURORA_C.y
	var fz := AURORA_C.x - x
	if fx * fx + fz * fz > VALLEY_R * VALLEY_R:
		return Vector2i(-1, 0)
	var lx := (fx - LAKE.x) / LAKE.z
	var lz := (fz - LAKE.y) / LAKE.w
	if lx * lx + lz * lz <= 1.0:
		return Vector2i(Y, LAKE_ICE)
	var m := Vector2(fx - MOUND.x, fz - MOUND.y).length()
	if m < MOUND.z:
		return Vector2i(Y + roundi(MOUND_TOP * (1.0 - (m / MOUND.z) * (m / MOUND.z))), SNOW)
	return Vector2i(Y, SNOW)


# --- Mount Everest, Lhotse and the South Col ---

static func _everest(x: int, z: int) -> Vector2i:
	var h := everest_height(z - EVEREST_C.y, EVEREST_C.x - x)
	if h < 0:
		return Vector2i(-1, 0)
	return Vector2i(Y + h, MOUNTAIN if h > 0 else SNOW)


## The massif's height over the tour's ground at (frame x, z), -1 off it.
static func everest_height(fx: int, fz: int) -> int:
	if absi(fx - STAIR1_X) <= 1 and fz >= ROUTE_FOOT and fz <= 0:   # stair 1: from base camp up to the col
		return fz - ROUTE_FOOT
	if absi(fz) <= 1 and fx >= 0 and fx < COL_X:   # stair 2: the ridge from the col up to the summit
		return EVEREST_TOP - fx
	if fx < -EVEREST_R or fx > LHOTSE.x + LHOTSE_R or absf(fz) > EVEREST_R:
		return -1
	var h := 0.0
	var re := sqrt(float(fx * fx + fz * fz))
	if re < EVEREST_R:
		h = EVEREST_TOP * pow(1.0 - re / EVEREST_R, 1.6)
		if re <= 1.5:
			h = EVEREST_TOP
	var rl := Vector2(fx - LHOTSE.x, fz - LHOTSE.y).length()
	if rl < LHOTSE_R:
		h = maxf(h, LHOTSE_TOP * pow(1.0 - rl / LHOTSE_R, 1.6))
	# the ridge from the summit down to the col and up to Lhotse: its crest along the line between the peaks, steep sides
	var t := clampi(fx, 0, LHOTSE.x)
	var crest := float(EVEREST_TOP - t) if t <= COL_X \
		else COL_TOP + (t - COL_X) * float(LHOTSE_TOP - COL_TOP) / (LHOTSE.x - COL_X)
	h = maxf(h, crest - RIDGE_FALL * Vector2(fx - t, fz).length())
	if fx >= COL_X and fx <= COL_X + 6 and absi(fz) <= 3:   # the col's flat (Camp IV)
		h = maxf(h, COL_TOP)
	if absi(fx - STAIR1_X) <= 6 and fz >= ROUTE_FOOT and fz <= 0:   # the route's shoulder
		h = maxf(h, (fz - ROUTE_FOOT) - 2.0 * (absi(fx - STAIR1_X) - 1))
	return maxi(roundi(h), 0)


# --- Victoria Falls ---

static func _falls(x: int, z: int) -> Vector2i:
	var fx := x - FALLS_C.x
	var fz := z - FALLS_C.y
	if absi(fx) <= CHASM_HALF and fz >= CHASM_Z.x and fz <= CHASM_Z.y:
		return Vector2i(POOL_BED, CHASM)
	if _in(fx, fz, GORGE_W) or _in(fx, fz, GORGE_S):
		return Vector2i(POOL_BED, CHASM)
	if _in(fx, fz, ISLAND):
		return Vector2i(Y + 1, BASALT_LAND)
	if _in(fx, fz, FALLS_RIVER):
		return Vector2i(RIVER_BED_Y, RIVER)
	if Vector2(fx - SOURCE.x, fz - SOURCE.y).length() <= SOURCE.z:
		return Vector2i(RIVER_BED_Y - 1, RIVER)
	return Vector2i(Y, BASALT_LAND)


static func _in(fx: int, fz: int, r: Vector4i) -> bool:
	return fx >= r.x and fx <= r.z and fz >= r.y and fz <= r.w


# --- The Harbour of Rio de Janeiro ---

static func _rio(x: int, z: int, c: float) -> Vector2i:
	var fx := x - RIO_C.x
	var fz := z - RIO_C.y
	var r := sqrt(float(fx * fx + fz * fz))
	var h := coast_height(c)
	var k := -1
	if r < BAY_SHORE + 4.0:
		var bay := BAY_FLOOR if r < BAY_R else roundi(BAY_FLOOR + (r - BAY_R) * (Y - BAY_FLOOR) / (BAY_SHORE - BAY_R))
		h = mini(h, bay)
		k = BEACH
		for isl: Vector3 in BAY_ISLANDS:
			var ri := Vector2(fx - isl.x, fz - isl.y).length()
			if ri <= isl.z:
				h = maxi(h, SEA + 2 + roundi(isl.z - ri))
				k = LAND
	var rock := maxi(_dome(fx, fz, SUGARLOAF, SUGARLOAF_TOP), _dome(fx, fz, URCA, URCA_TOP))
	if fx >= STEPS_FROM and fx <= STEPS_TO:
		var crest := STEPS_FOOT + (fx - STEPS_FROM)
		var off := absi(fz - STEPS_Z)
		if off <= 1:
			return Vector2i(crest, ROCK)
		rock = maxi(rock, crest - 2 * (off - 1))
	if rock > h:
		return Vector2i(rock, ROCK)
	if k < 0:
		return Vector2i(-1, 0)
	return Vector2i(h, k if h >= SEA else SEA_FLOOR)


## A rock dome rising from the sea: its height (absolute) at (frame x, z), or -1 off it.
static func _dome(fx: int, fz: int, d: Vector4, top: int) -> int:
	var qx := (fx - d.x) / d.z
	var qz := (fz - d.y) / d.w
	var q2 := qx * qx + qz * qz
	if q2 >= 1.0:
		return -1
	return SEA + roundi(top * sqrt(1.0 - q2))


# --- The Great Barrier Reef ---

static func _reef(x: int, z: int, c: float) -> Vector2i:
	var fx := x - REEF_C.x
	var fz := z - REEF_C.y
	var r := sqrt(float(fx * fx + fz * fz))
	if r > REEF_EDGE:
		return Vector2i(-1, 0)
	if r <= CAY_R:
		return Vector2i(CAY_TOP, BEACH)
	if r <= CAY_R + 2.0:
		return Vector2i(CAY_TOP - roundi(r - CAY_R), BEACH)
	var h := REEF_FLOOR
	var k := REEF
	if r > REEF_R:
		h = REEF_FLOOR - roundi((r - REEF_R) * (REEF_FLOOR - SEA_DEEP) / (REEF_EDGE - REEF_R))
		k = SEA_FLOOR
	var shore := coast_height(c)
	if shore > h:
		return _plain(x, z, c)
	return Vector2i(h, k)


## A coral head on the reef flat at (x, z): [block, how many tall] ([] for none): heads of two by two cells, one to
## three tall, brain coral, staghorn coral or a sea fan.
static func coral_at(x: int, z: int) -> Array:
	var cell := absi(_h(floori(x / 2.0) * 7 + 3, floori(z / 2.0) * 5 - 1))
	if cell % 5 != 0:
		return []
	if _reef(x, z, coast(x, z)).y != REEF:   # (sample's REEF: the reef's own sums)
		return []
	var block: int = [BlockIds.BRAIN_CORAL, BlockIds.STAGHORN_CORAL, BlockIds.SEA_FAN][(cell / 5) % 3]
	return [block, 1 + (cell / 15) % 3]


# --- Victoria Falls' spray ---

const SPRAY_LOW := Y + 2                 # the spray's plume over the chasm (over a child's eyes on the path) ...
const SPRAY_HIGH := Y + 16               # ... up to here


## The spray (the "smoke" over the falls, and mist over the pool) at cell (x, y, z): fewer cells higher up.
static func spray_at(x: int, y: int, z: int) -> bool:
	var fx := x - FALLS_C.x
	var fz := z - FALLS_C.y
	if fz < CHASM_Z.x + 1 or fz > CHASM_Z.y - 1 or absi(fx) > 24:
		return false
	var chance := 0
	if y >= SPRAY_LOW and y <= SPRAY_HIGH:
		chance = 26 - (y - SPRAY_LOW) * 3 / 2
	elif y >= POOL_TOP and y < POOL_TOP + 3:
		chance = 22
	if chance <= 0:
		return false
	return absi(_h(x * 13 + y * 7, z * 11 - y * 3)) % 100 < chance


# --- Trees ---

## The most trees in a thousand columns anywhere here (the rainforest), and anywhere but the rainforest: a column whose
## roll is over it has none.
const TREES_MOST := 60
const TREES_OUTSIDE_FOREST := 14
const RAINFOREST := Vector4i(-40, -32, 40, -9)   # (frame x from, z from, x to, z to of the falls)


## The rainforest the falls' spray waters, on their north lip.
static func in_rainforest(x: int, z: int) -> bool:
	return _in(x - FALLS_C.x, z - FALLS_C.y, RAINFOREST)


## How many trees in a thousand columns grow at (x, z) of kind `k` (its height h): pines on the snowy land and the
## plateau, a dense rainforest facing the falls, oaks on the park land.
static func tree_per_mille(x: int, z: int, h: int, k: int) -> int:
	match k:
		SNOW:
			return 14 if h == Y else 0
		PLATEAU:
			return 8 if h == PLATEAU_TOP and canyon_d(CANYON_C.y - z, x - CANYON_C.x) > RIM + 4.0 else 0
		BASALT_LAND:
			if h == Y and in_rainforest(x, z):
				return TREES_MOST   # the rainforest the spray waters
			return 7 if h == Y else 0
		LAND:
			return 7 if h == Y else 0
	return 0


## The tree growing on kind `k`: pines in the snow and on the plateau, oaks elsewhere.
static func tree_kind(k: int) -> StringName:
	return &"pine" if k == SNOW or k == PLATEAU else &"oak"


## A seed-free hash of (x, z).
static func _h(x: int, z: int) -> int:
	var h := x * 374761393 + z * 668265263 + 1234567
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
