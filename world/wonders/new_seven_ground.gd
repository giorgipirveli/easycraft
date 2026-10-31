class_name NewSevenGround
extends RefCounted
## The ground of world 41's second region (owner #78, spec §24), round the New Seven Wonders' square (WonderTour
## NEW_SQUARE, out to NEW_R), as pure rules, the same in every world: flat at the tour's ground level (WonderTour.BASE_Y)
## but for three hills the wonders need, each a smooth shape of its own:
##   the Great Wall's ridge: a long hill under the wall, its crest rising and falling with the wall's walkway (the wall
##     stands WALL_ABOVE over it), its sides falling away to the flat ground;
##   Corcovado: the round mountain Christ the Redeemer stands on (its summit CORCOVADO_TOP over the ground);
##   Huayna Picchu: the steep sugarloaf peak behind Machu Picchu's terraces.
## WondersShape asks it for the ground's height there; WonderBuildsNew builds the wall on the ridge and the stair up
## Corcovado from the same numbers.

## The Great Wall runs its frame's x from -WALL_HALF to WALL_HALF, a watchtower at each of WALL_TOWERS; its walkway (the
## feet's height over the tour's ground) is flat through each tower and ramps gently between them (at most a block a
## step): wall_walk.
const WALL_HALF := 56
const WALL_TOWERS: Array[int] = [-42, -21, 0, 21, 42]
const WALL_BASE := 11
const WALL_SWING := 3.0
const TOWER_HALF := 3
const WALL_ABOVE := 5
const RIDGE_FALL := Vector2(4.0, 24.0)    # the ridge's sides fall from here to here (|frame z|)
const RIDGE_END := Vector2(50.0, 66.0)    # ... and it fades out between these (|frame x|)
## Corcovado, round Christ the Redeemer's centre: its summit (the feet's height there) and its radius.
const CORCOVADO_TOP := 40
const CORCOVADO_R := 46.0
## Huayna Picchu, behind Machu Picchu (its frame's +z): where, how high, how wide.
const HUAYNA := Vector2i(0, 44)
const HUAYNA_TOP := 44.0
const HUAYNA_R := 22.0


## Where the hills stand (world x, z), kept here so a column's height is plain arithmetic (the generator asks it for
## every column of the region; test_wonders_new_seven checks they match WonderTour's centres): the Great Wall's centre
## (its frame faces south: frame x = WALL_C.x - x, frame z = WALL_C.y - z), Corcovado's (Christ the Redeemer's centre),
## Huayna Picchu's (Machu Picchu's frame HUAYNA).
const WALL_C := Vector2i(-400, -122)
const CORCOVADO_C := Vector2i(-325, 115)
const HUAYNA_C := Vector2i(-430, 134)


## The ground's height at (x, z): the first air above it (the tour's ground level where no hill is).
static func height(x: int, z: int) -> int:
	var h := 0.0
	var fx := WALL_C.x - x
	var fz := WALL_C.y - z
	if absf(fz) < RIDGE_FALL.y and absf(fx) < RIDGE_END.y:
		h = _ridge_frame(fx, fz)
	var dx := x - CORCOVADO_C.x
	var dz := z - CORCOVADO_C.y
	if absf(dx) < CORCOVADO_R and absf(dz) < CORCOVADO_R:
		h = maxf(h, _corcovado_r(sqrt(float(dx * dx + dz * dz))))
	dx = x - HUAYNA_C.x
	dz = z - HUAYNA_C.y
	if absf(dx) < HUAYNA_R and absf(dz) < HUAYNA_R:
		h = maxf(h, _huayna_r(sqrt(float(dx * dx + dz * dz))))
	return WonderTour.BASE_Y + roundi(h)


## The Great Wall's walkway at its frame's x: the feet's height over the tour's ground.
static func wall_walk(xf: int) -> int:
	var x := clampi(xf, -WALL_HALF, WALL_HALF)
	var towers := WALL_TOWERS
	if x <= towers[0] + TOWER_HALF:
		return _tower_walk(towers[0])
	if x >= towers[-1] - TOWER_HALF:
		return _tower_walk(towers[-1])
	for i in towers.size() - 1:
		var a := towers[i]
		var b := towers[i + 1]
		if x <= b + TOWER_HALF:
			if x <= a + TOWER_HALF:
				return _tower_walk(a)
			if x >= b - TOWER_HALF:
				return _tower_walk(b)
			var t := float(x - (a + TOWER_HALF)) / float((b - TOWER_HALF) - (a + TOWER_HALF))
			return roundi(lerpf(_tower_walk(a), _tower_walk(b), t))
	return WALL_BASE


static func _tower_walk(t: int) -> int:
	return WALL_BASE + roundi(WALL_SWING * sin(t * 0.09))


## The ridge under the Great Wall at (x, z), in blocks over the tour's ground.
static func ridge(x: int, z: int) -> float:
	return _ridge_frame(WALL_C.x - x, WALL_C.y - z)


static func _ridge_frame(fx: int, fz: int) -> float:
	var ax := absf(fx)
	var az := absf(fz)
	if az >= RIDGE_FALL.y or ax >= RIDGE_END.y:
		return 0.0
	var crest := float(wall_walk(fx) - WALL_ABOVE)
	return crest * (1.0 - smoothstep(RIDGE_FALL.x, RIDGE_FALL.y, az)) * (1.0 - smoothstep(RIDGE_END.x, RIDGE_END.y, ax))


## Corcovado under Christ the Redeemer at (x, z): a round mountain, steep near its summit.
static func corcovado(x: int, z: int) -> float:
	return _corcovado_r(Vector2(x - CORCOVADO_C.x, z - CORCOVADO_C.y).length())


static func _corcovado_r(r: float) -> float:
	if r >= CORCOVADO_R:
		return 0.0
	var k := 1.0 - (r / CORCOVADO_R) * (r / CORCOVADO_R)
	return CORCOVADO_TOP * k * k


## Huayna Picchu behind Machu Picchu at (x, z): a steep sugarloaf peak.
static func huayna(x: int, z: int) -> float:
	return _huayna_r(Vector2(x - HUAYNA_C.x, z - HUAYNA_C.y).length())


static func _huayna_r(r: float) -> float:
	if r >= HUAYNA_R:
		return 0.0
	return HUAYNA_TOP * pow(1.0 - r / HUAYNA_R, 1.4)
