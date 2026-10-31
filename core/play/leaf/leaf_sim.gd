class_name LeafSim
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.4-3.5b, §4.3): the leaf, whose rules are the science (the
## honesty table, §9). Its doors (stomata) let air in and water out, faster in the heat; the vein refills the cells from
## watered soil; the green workshops (chloroplasts) build sugar from the air with the light, slower when the leaf is too
## dry; the leaf droops when its cells lose water; sugar carried to the gold pipe climbs to the bud only while the leaf
## stands. Two plants' ways (the voyage's `sim.model`):
## - C3 (the sunflower): air goes straight to the workshops (the phase A model voyage_5_1_model.py, step for step);
## - CAM (the cactus): at night the air that comes in is kept in jars (the cells' vacuoles), and by day the workshops
##   build from the jars behind shut doors (desert_night_model.py, step for step).
## Pure and deterministic: `step(dt, weather)` with the weather's {heat, light, night, refill, floor}; the numbers are
## the voyage's data (LeafVoyages: `sim`).

const C3 := "c3"
const CAM := "cam"
## The defaults: voyage 5.1's numbers (the data gives every voyage its own).
const DEFAULTS := {"model": C3, "doors": 6, "water": 0.95, "doors_open": false, "r_in": 0.035, "k_out": 0.006,
	"cuticle": 0.0006, "k_air": 0.22, "air_use": 4.0, "k_sugar": 0.35, "droop": 0.55, "dry": 0.35, "dry_work": 0.3,
	"jar_cap": 0.0, "k_jar": 0.0, "bud": 12, "bud_rate": 1.0}
## The air a workshop needs to build at full speed (min(air / AIR_FULL, 1)).
const AIR_FULL := 0.5
## The vein brings water towards this (the models' 1.05: a full leaf still drinks a little).
const VEIN_FULL := 1.05
## Air comes in this much faster than one door's share a second (the models' x 4).
const AIR_RATE := 4.0
## Water lost through open doors grows with heat from this (the models' 0.10 + heat).
const STILL_AIR := 0.10

var params := {}
var model := C3
## Each door: open (true) or shut.
var doors: Array[bool] = []
## The leaf's water, 0-1 (below `droop` the leaf sags; below `dry` the workshops slow and Hoot steps in).
var water := 0.95
## Air inside (CO2), 0-1.
var air := 0.0
## The cactus's jars: air kept for the day, in sugars' worth.
var jars := 0.0
## Sugar built (hexagons, a fraction while the next one forms), picked up, put in the gold pipe, arrived in the bud.
var made := 0.0
var taken := 0
var delivered := 0
var bud := 0.0
## The weather of the last step.
var heat := 0.0
var light := 0.0
var night := false
## How hard the workshops built in the last step, 0-1 (the place's glow).
var _work := 0.0
var _cam := false
var _r_in := 0.0
var _k_out := 0.0
var _cuticle := 0.0
var _k_air := 0.0
var _air_use := 0.0
var _k_sugar := 0.0
var _droop := 0.55
var _dry := 0.35
var _dry_work := 0.3
var _jar_cap := 0.0
var _k_jar := 0.0
var _bud_rate := 1.0
var _bud_need := 12.0


static func make(sim_params: Dictionary) -> LeafSim:
	var s := LeafSim.new()
	s.params = DEFAULTS.duplicate()
	s.params.merge(sim_params, true)
	s.model = str(s.params.model)
	s.water = float(s.params.water)
	for i in int(s.params.doors):
		s.doors.append(bool(s.params.doors_open))
	s._cache()
	return s


## The numbers as typed fields (the step runs thousands of times a second in the cheat test's bots).
func _cache() -> void:
	_cam = model == CAM
	_r_in = float(params.r_in)
	_k_out = float(params.k_out)
	_cuticle = float(params.cuticle)
	_k_air = float(params.k_air)
	_air_use = float(params.air_use)
	_k_sugar = float(params.k_sugar)
	_droop = float(params.droop)
	_dry = float(params.dry)
	_dry_work = float(params.dry_work)
	_jar_cap = float(params.jar_cap)
	_k_jar = float(params.k_jar)
	_bud_rate = float(params.bud_rate)
	_bud_need = float(params.bud)


func step(dt: float, weather: Dictionary) -> void:
	heat = weather.get("heat", 0.0)
	light = weather.get("light", 0.0)
	night = weather.get("night", false)
	var n := doors.count(true)
	var inflow: float = _r_in * float(weather.get("refill", 1.0)) * (VEIN_FULL - water)
	var out := n * _k_out * (STILL_AIR + heat) + _cuticle
	water = clampf(water + (inflow - out) * dt, 0.0, 1.0)
	water = maxf(water, float(weather.get("floor", 0.0)))
	var wet := 1.0 if water > _dry else _dry_work
	var before := made
	if _cam:
		_step_cam(dt, n, wet)
	else:
		_step_c3(dt, n, wet)
	var full_rate := _k_sugar * dt
	_work = clampf((made - before) / full_rate, 0.0, 1.0) if full_rate > 0.0 else 0.0
	if water >= _droop:
		bud = minf(bud + _bud_rate * dt, float(delivered))


## The sunflower: air in through the open doors, used by the workshops as they build.
func _step_c3(dt: float, n: int, wet: float) -> void:
	var share := float(n) / doors.size() if not doors.is_empty() else 0.0
	var use := minf(air, light * minf(air / AIR_FULL, 1.0) * _k_sugar * dt * _air_use)
	air = clampf(air + _k_air * share * (1.0 - air) * dt * AIR_RATE - use, 0.0, 1.0)
	made += _k_sugar * light * minf(air / AIR_FULL, 1.0) * wet * dt


## The cactus: at night the open doors fill the jars; by day the jars feed the workshops first, the day's air after.
func _step_cam(dt: float, n: int, wet: float) -> void:
	var share := float(n) / doors.size() if not doors.is_empty() else 0.0
	if night:
		jars = minf(_jar_cap, jars + _k_jar * n * dt)
	else:
		air = minf(1.0, air + _k_air * share * (1.0 - air) * dt * AIR_RATE)
	if light <= 0.0:
		return
	var from_jars := minf(jars, _k_sugar * light * wet * dt) if jars > 0.0 else 0.0
	var from_air := 0.0
	if from_jars <= 0.0:
		from_air = _k_sugar * light * minf(air / AIR_FULL, 1.0) * wet * dt
	jars -= from_jars
	air = maxf(0.0, air - from_air * _air_use)
	made += from_jars + from_air


## Opens a shut door or shuts an open one; its new state (false for a door that isn't there).
func toggle(door: int) -> bool:
	if door < 0 or door >= doors.size():
		return false
	doors[door] = not doors[door]
	return doors[door]


func set_door(door: int, open: bool) -> void:
	if door >= 0 and door < doors.size():
		doors[door] = open


func open_count() -> int:
	return doors.count(true)


func open_share() -> float:
	return float(open_count()) / doors.size() if not doors.is_empty() else 0.0


## The leaf stands (its cells full enough): seen inside and outside.
func standing() -> bool:
	return water >= _droop


## Too dry: the workshops slow and Hoot steps in (L27).
func too_dry() -> bool:
	return water < _dry


## Whole hexagons waiting at the workshops to be picked up.
func waiting() -> int:
	return maxi(int(floor(made)) - taken, 0)


## Picks up a waiting hexagon (false when none waits).
func take() -> bool:
	if waiting() <= 0:
		return false
	taken += 1
	return true


## Puts up to `n` carried hexagons into the gold pipe; how many went in (only what was carried).
func deliver(n: int = 1) -> int:
	var carried := taken - delivered
	var gone := clampi(n, 0, carried)
	delivered += gone
	return gone


func bud_full() -> bool:
	return bud >= _bud_need - 0.0001


## How hard the workshops built in the last step, 0 (dim) to 1 (lit).
func work() -> float:
	return _work
