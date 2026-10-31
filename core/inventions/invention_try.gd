class_name InventionTry
extends RefCounted
## Owner #78 (spec §21e): the "try it" moments, a small challenge for each invention that shows its science, pure. The
## director feeds what the child's body does (`feed`, a sample: pos, craft (FlightCrafts), flying, gliding, on_floor,
## facing, wind) and pays when it is done (once per invention: InventionRules.try_gold):
## - the kite: your back to the wind with the kite up, for KITE_SECONDS in all (the kite flies downwind of you);
## - the balloon: rise BALLOON_BLOCKS above where it first flew (hot air rises);
## - the glider: one glide of GLIDE_BLOCKS across the ground (from higher up you glide farther);
## - the plane: PLANE_SECONDS in the air in one flight (the first powered flight lasted 12 seconds);
## - the jet: JET_BLOCKS in one jet flight (the fastest);
## - the rocket: a bottle rocket in the book (launch_bottle): more air pumped in pushes the water out harder, and it
##   flies higher; BOTTLE_GOAL metres.

const KITE_SECONDS := 5.0
const BALLOON_BLOCKS := 15.0
const GLIDE_BLOCKS := 25.0
const PLANE_SECONDS := 12.0
const JET_BLOCKS := 300.0
const BOTTLE_GOAL := 30.0
const BOTTLE_METRES_PER_PUMP := 5.5
const BOTTLE_MAX_PUMPS := 8

var id: StringName = &""
var progress := 0.0
var done := false

var _time := 0.0
var _dist := 0.0
var _start_y := NAN
var _last := Vector3.INF
var _hint := ""


func start(p_id: StringName) -> void:
	id = p_id if InventionLine.has(p_id) else &""
	progress = 0.0
	done = false
	_time = 0.0
	_dist = 0.0
	_start_y = NAN
	_last = Vector3.INF
	_hint = ""


func stop() -> void:
	start(&"")


func active() -> bool:
	return id != &"" and not done


## What to do (the challenge in words).
func goal() -> String:
	return str(InventionLine.entry(id).get("try", ""))


## What the child should do now to go on ("" when it is going well).
func hint() -> String:
	return _hint


## One look at the child's body; returns the progress (0 … 1).
func feed(s: Dictionary, delta: float) -> float:
	if not active() or not is_finite(delta) or delta <= 0.0:
		return progress
	var pos: Vector3 = s.get("pos", Vector3.INF)
	if not pos.is_finite():
		return progress
	var craft := int(s.get("craft", FlightCrafts.Craft.NONE))
	var flying := bool(s.get("flying", false))
	_hint = ""
	match id:
		InventionLine.KITE:
			if craft != FlightCrafts.Craft.KITE:
				_hint = "Put your kite up: TRY IT in the book."
			elif not FlightCrafts.downwind(s.get("facing", Vector3.ZERO), s.get("wind", Vector3.ZERO)):
				_hint = "Turn your back to the wind: the kite flies out in front of you."
			else:
				_time += delta
			progress = _time / KITE_SECONDS
		InventionLine.BALLOON:
			if craft != FlightCrafts.Craft.BALLOON or not flying:
				_hint = "Fly your balloon: FLY with the balloon."
			else:
				if is_nan(_start_y):
					_start_y = pos.y
				progress = maxf(progress, (pos.y - _start_y) / BALLOON_BLOCKS)
		InventionLine.GLIDER:
			if not bool(s.get("gliding", false)):
				_dist = 0.0
				_last = Vector3.INF
				_hint = "Climb up high, jump off and GLIDE."
			else:
				_along(pos)
			progress = _dist / GLIDE_BLOCKS
		InventionLine.PLANE:
			if craft != FlightCrafts.Craft.PLANE or not flying or bool(s.get("on_floor", false)):
				_time = 0.0
				_hint = "Take off in your plane and stay up!"
			else:
				_time += delta
			progress = _time / PLANE_SECONDS
		InventionLine.JET:
			if craft != FlightCrafts.Craft.JET or not flying:
				_dist = 0.0
				_last = Vector3.INF
				_hint = "Fly your jet: FLY with the jet."
			else:
				_along(pos)
			progress = _dist / JET_BLOCKS
	progress = clampf(progress, 0.0, 1.0)
	if progress >= 1.0:
		done = true
	return progress


func _along(pos: Vector3) -> void:
	if _last.is_finite():
		_dist += Vector2(pos.x - _last.x, pos.z - _last.z).length()
	_last = pos


## The rocket's try: a bottle rocket launched with `pumps` of air; its height (m). Done at BOTTLE_GOAL.
func launch_bottle(pumps: int) -> float:
	var h := bottle_height(pumps)
	if id == InventionLine.ROCKET and not done:
		progress = clampf(h / BOTTLE_GOAL, 0.0, 1.0)
		done = h >= BOTTLE_GOAL
	return h


## How high a bottle rocket a third full of water flies with `pumps` of air (only as much as is safe).
static func bottle_height(pumps: int) -> float:
	return clampi(pumps, 0, BOTTLE_MAX_PUMPS) * BOTTLE_METRES_PER_PUMP
