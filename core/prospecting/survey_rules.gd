class_name SurveyRules
extends RefCounted
## Prospecting (spec §26.2): the maths of finding a deposit, as a real prospector does it. Pure.
## - The echo survey (oil): a thump sends sound down; it bounces off the dome's top and comes back. It went down and up,
##   so depth = speed × time ÷ 2 (ECHO_SPEED: sound in the sandstone and shale over the dome, 2,000 m a second; real
##   sedimentary rock carries it at about 2,000-4,000).
## - The metal detector (gold, iron, copper): its beeps come faster the closer the metal: half the distance, twice the
##   beeps (1 a second at 40 m, as far as it hears: DETECTOR_RANGE).
## - The map: which way (8 compass points; north is -z, MY MAP's up), how far (rounded to a square, as a map is read),
##   which square (letters A-H west to east, numbers 1-8 north to south). A quest's map is MAP_SQUARES squares of
##   SQUARE metres round the camp and the target.
## A block is a metre.

const ECHO_SPEED := 2000
const DETECTOR_RANGE := 48.0
const BEEPS_AT_40 := 1.0
const MAX_BEEPS := 12.0
const SQUARE := 100
const MAP_SQUARES := 8
const POINTS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const POINT_WORDS := {"N": "north", "NE": "north-east", "E": "east", "SE": "south-east", "S": "south",
	"SW": "south-west", "W": "west", "NW": "north-west"}
const LETTERS := "ABCDEFGH"


## Seconds for the echo from a dome `depth_m` metres down to come back up.
static func echo_seconds(depth_m: int, speed: int = ECHO_SPEED) -> float:
	return 2.0 * float(depth_m) / float(speed)


## Metres down to what sent back an echo after `seconds` (there and back again).
static func depth_from_echo(seconds: float, speed: int = ECHO_SPEED) -> int:
	return roundi(float(speed) * seconds / 2.0)


## The detector's beeps a second at `distance` metres from metal (0: too far to hear).
static func beeps(distance: float) -> float:
	if is_nan(distance) or distance > DETECTOR_RANGE:
		return 0.0
	if distance <= 40.0 * BEEPS_AT_40 / MAX_BEEPS:
		return MAX_BEEPS
	return minf(40.0 * BEEPS_AT_40 / distance, MAX_BEEPS)


## The compass point ("N", "NE", …) from `from` towards `to`, sideways.
static func point(from: Vector3, to: Vector3) -> String:
	var deg := rad_to_deg(atan2(to.x - from.x, -(to.z - from.z)))
	var i := posmod(roundi(deg / 45.0), 8)
	return POINTS[i]


static func point_words(p: String) -> String:
	return str(POINT_WORDS.get(p, ""))


## Sideways metres from `from` to `to`, to the nearest square of `square_m` metres (never less than one).
static func map_distance(from: Vector3, to: Vector3, square_m: int = SQUARE) -> int:
	var d := Vector2(to.x - from.x, to.z - from.z).length()
	return maxi(roundi(d / square_m), 1) * square_m


## The square ("C4") a place is in, on a map whose north-west corner is `corner` (x, z); "" off the map.
static func square(pos: Vector3, corner: Vector2, square_m: int = SQUARE) -> String:
	var col := floori((pos.x - corner.x) / square_m)
	var row := floori((pos.z - corner.y) / square_m)
	if col < 0 or row < 0 or col >= MAP_SQUARES or row >= MAP_SQUARES:
		return ""
	return "%s%d" % [LETTERS[col], row + 1]


## The middle of a square ("C4") on a map whose north-west corner is `corner` (x, z); INF for no square.
static func square_middle(sq: String, corner: Vector2, square_m: int = SQUARE) -> Vector2:
	if sq.length() < 2 or not LETTERS.contains(sq[0]) or not sq.substr(1).is_valid_int():
		return Vector2.INF
	return corner + Vector2(LETTERS.find(sq[0]) + 0.5, int(sq.substr(1)) - 0.5) * square_m


## The scales a quest's map may have: a square is 100 m, or 200 m, or 500 m for a target far away.
const SCALES: Array[int] = [100, 200, 500]


## A quest's map round the camp and the target: {corner: Vector2 (the north-west corner, on grid lines), size (metres),
## squares, square (metres a square)}. The smallest scale that fits both a little inside its edge; centred on them.
static func map_frame(camp: Vector3, target: Vector3) -> Dictionary:
	for sq in SCALES:
		var size := MAP_SQUARES * sq
		var mid := Vector2((camp.x + target.x) * 0.5, (camp.z + target.z) * 0.5)
		var corner := Vector2(floorf((mid.x - size * 0.5) / sq) * sq, floorf((mid.y - size * 0.5) / sq) * sq)
		var fits := true
		for p: Vector3 in [camp, target]:   # keep both a little inside the edge
			var lo := Vector2(ceilf((p.x + 20.0 - size) / sq) * sq, ceilf((p.z + 20.0 - size) / sq) * sq)
			var hi := Vector2(floorf((p.x - 20.0) / sq) * sq, floorf((p.z - 20.0) / sq) * sq)
			fits = fits and lo.x <= hi.x and lo.y <= hi.y
			if fits:
				corner = corner.clamp(lo, hi)
		if fits and square(camp, corner, sq) != "" and square(target, corner, sq) != "":
			return {"corner": corner, "size": size, "squares": MAP_SQUARES, "square": sq}
	var far := SCALES[SCALES.size() - 1]
	var c := Vector2(floorf(camp.x / far) * far - far * 3, floorf(camp.z / far) * far - far * 3)
	return {"corner": c, "size": MAP_SQUARES * far, "squares": MAP_SQUARES, "square": far}


# --- Choices for a question (School "choice" exercises) --------------------------------------------------------------

## 4 compass directions in words, the right one among them at a place the roll picks: {choices, answer}.
static func point_choices(right: String, roll: int) -> Dictionary:
	var i := POINTS.find(right)
	var others: Array[String] = []
	for d in [4, 2, 6, 1, 3, 5, 7]:   # the opposite first, then the quarter turns: the mix-ups a child makes
		others.append(POINTS[(i + d) % 8])
	return _mix(point_words(right), [point_words(others[0]), point_words(others[1 + roll % 2]),
		point_words(others[3 + roll % 4])], roll)


## 4 distances in metres ("300 m"), the right one among them: {choices, answer}.
static func number_choices(right: int, step: int, roll: int, unit := " m") -> Dictionary:
	var wrong: Array = []
	for k in [2, -1, 1, 3, -2]:
		var v: int = right + int(k) * step
		if v > 0 and wrong.size() < 3:
			wrong.append("%d%s" % [v, unit])
	return _mix("%d%s" % [right, unit], wrong, roll)


## 4 squares ("C4"), the right one among them (the letter and the number swapped, the neighbours): {choices, answer}.
static func square_choices(right: String, roll: int) -> Dictionary:
	var col := LETTERS.find(right[0])
	var row := int(right.substr(1))
	var wrong: Array = []
	var swap := "%s%d" % [LETTERS[clampi(row - 1, 0, MAP_SQUARES - 1)], col + 1]
	if swap != right:
		wrong.append(swap)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1)]:
		var c := col + d.x
		var r := row + d.y
		if c < 0 or c >= MAP_SQUARES or r < 1 or r > MAP_SQUARES:
			continue
		var sq := "%s%d" % [LETTERS[c], r]
		if sq != right and not wrong.has(sq) and wrong.size() < 3:
			wrong.append(sq)
	return _mix(right, wrong, roll)


## The right answer put in among the wrong ones at the place the roll picks.
static func _mix(right: String, wrong: Array, roll: int) -> Dictionary:
	var out: Array[String] = []
	for w: Variant in wrong:
		if str(w) != right and not out.has(str(w)):
			out.append(str(w))
	var at := absi(roll) % (out.size() + 1)
	out.insert(at, right)
	return {"choices": out, "answer": at}
