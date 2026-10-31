class_name LifeRules
extends RefCounted
## Owner #94 (the animations brief §2): the world's ambient life, its rules and its budget. Over Green Meadows' grass
## and flowers a few fireflies blink at night (Fireflies) and a small flock of birds circles high by day (Birds); a
## broken tree or flower block lets its leaves or petals flutter down (flutter, from Fx.break_block); the Launch Site's
## tower light blinks (Blinker) and a flag waves on Mission Control (WavingFlag). Everything follows this game's player
## (nothing is sent), shares materials the game already draws (no new shader), is pooled (one particle system, one
## multimesh), and is off when nobody would see it (night or day, a cave, another universe, far away).

## Fireflies over the meadow at night (a few, LOW draws half: Fx.scaled).
const FIREFLIES := 14
## Birds in the flock by day (3 instances each: a body and two wings; LOW flies half).
const BIRDS := 6
## How far underground (Ambience.underground, 0..1) the sky's life still shows.
const UNDERGROUND := 0.3
## The flock circles this high over the player's feet, this far round.
const FLOCK_HEIGHT := 16.0
const FLOCK_RADIUS := Vector2(9.0, 20.0)
const BIRD_SPEED := 6.0
## Things of the Launch Site (the tower light, the flag) sleep farther than this from the camera.
const AWAKE_RANGE := 90.0
const LEAF_BITS := 7
const PETAL_BITS := 10
const PETALS: Array[Color] = [Color("ff8fc8"), Color("ffd23f"), Color("ffffff"), Color("ff6b6b"), Color("b388ff")]
const LEAFY: Array[int] = [BlockIds.LEAVES, BlockIds.PALM_LEAVES, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES,
	BlockIds.FRUIT_LEAVES, BlockIds.OLIVE_LEAVES, BlockIds.BUSH]
const FLOWERY: Array[int] = [BlockIds.FLOWERS]


## Fireflies: at night, under the open sky, over the meadow's grass and bushes (InsectRules.FLOWERS).
static func fireflies_on(time_of_day: float, underground: float, ground: int) -> bool:
	return DayCycle.is_night(time_of_day) and underground < UNDERGROUND and InsectRules.FLOWERS.has(ground)


## Birds: by day, under the open sky (anywhere over the meadows: they fly high).
static func birds_on(time_of_day: float, underground: float) -> bool:
	return not DayCycle.is_night(time_of_day) and underground < UNDERGROUND


## Bird `i` of the flock, `t` seconds on, round the flock's middle (local): each flies its own circle at its own height
## (a few the other way round). Separate calls, no allocation (Birds asks every frame).
static func bird_at(i: int, t: float) -> Vector3:
	var k := fposmod(i * 0.618034, 1.0)
	var radius := lerpf(FLOCK_RADIUS.x, FLOCK_RADIUS.y, k)
	var angle := _bird_angle(i, t, radius)
	return Vector3(cos(angle) * radius, (k - 0.5) * 5.0 + sin(t * 0.7 + i) * 0.8, sin(angle) * radius)


## Its heading (yaw: its -Z along its circle).
static func bird_heading(i: int, t: float) -> float:
	var radius := lerpf(FLOCK_RADIUS.x, FLOCK_RADIUS.y, fposmod(i * 0.618034, 1.0))
	var angle := _bird_angle(i, t, radius)
	var way := _bird_way(i)
	return atan2(way * sin(angle), -way * cos(angle))


## Its wings' beat (radians, the tips up): flapping for a while, then gliding with them a little up.
static func bird_flap(i: int, t: float) -> float:
	var beat := fposmod(t * 0.35 + fposmod(i * 0.618034, 1.0), 1.0)
	return 0.12 + (0.65 * sin(t * TAU * 4.5 + i) if beat < 0.45 else 0.0)


## Its lean into the turn (radians).
static func bird_bank(i: int) -> float:
	return _bird_way(i) * 0.3


static func _bird_way(i: int) -> float:
	return 1.0 if i % 3 != 2 else -1.0


static func _bird_angle(i: int, t: float, radius: float) -> float:
	return i * 2.1 + _bird_way(i) * BIRD_SPEED / radius * t


## True for a block whose breaking lets leaves (leafy) or petals flutter down.
static func flutters(block_id: int) -> bool:
	return LEAFY.has(block_id) or FLOWERY.has(block_id)


## Leaves or petals fluttering down from a broken block (on top of Fx's burst of its bits). Fx's material, its budget.
static func flutter(parent: Node, block_pos: Vector3i, block_id: int) -> CPUParticles3D:
	if not flutters(block_id):
		return null
	var at := Vector3(block_pos) + Vector3(0.5, 0.6, 0.5)
	if FLOWERY.has(block_id):
		return Fx.confetti(parent, at, PETALS, PETAL_BITS, 1.6, 0.07, 1.8, 1.0)
	var leaf := BlockLibrary.average_color(block_id)
	var greens: Array[Color] = [leaf, leaf.lightened(0.2), leaf.darkened(0.15)]
	return Fx.confetti(parent, at, greens, LEAF_BITS, 1.4, 0.1, 1.9, 1.1)
