class_name SpaceGeysers
extends Node
## Europa's water plumes, Io's volcanoes and Triton's nitrogen geysers (cosmos, spec §21b.2; real: space telescopes have
## seen plumes of water vapour rise from Europa; Io's volcanoes throw plumes of sulphur up to about 400 km; Triton's
## geysers blow nitrogen gas and dark dust about 8 km up, and the thin wind carries the dust ~150 km downwind). The vents
## are the terrain's (SpaceShape.vents_near: Europa's in mounds of salt, Io's in cones of black lava, Triton's in rings of
## dark dust on its pink cap; a vent block throws a child up, PadRules). The sandbox adds one ("Geysers") in a world whose
## shape has vents, for this game's own player: every vent within RANGE of the player erupts now and then, each on its
## own beat (erupting(): ERUPT seconds of every PERIOD), a column of white vapour (Europa), yellow sulphur (Io) or dark
## dust and frost drifting north-east on the wind (Triton: plume_color, plume_wind) puffing up from it (`plume`: Fx
## bursts and a soft whoosh as it starts). Cheap on a phone:
## it looks for the vents near the player once a second and puffs a few times a second; Fx skips bursts far from the
## camera anyway.

const PERIOD := 9.0
const ERUPT := 3.0
const PUFF := 0.3                 # seconds between puffs of an erupting plume
const RANGE := 64.0               # plumes this near the player blow (Fx draws bursts within 48 of the camera)
const LOOK := 1.0                 # seconds between looks for the vents near the player
const VAPOUR := Color(0.92, 0.97, 1.0)
const SULPHUR := Color(1.0, 0.9, 0.45)   # cosmos: an Io volcano's plume
const DUST := Color(0.36, 0.33, 0.38)    # cosmos: a Triton geyser's dark dust ...
const FROST := Color(0.93, 0.93, 0.97)   # ... and its nitrogen frost
const DRIFT := 3.0                       # cosmos: Triton's puffs drift downwind (PadRules.WIND) at this, m/s²

var shape: SpaceShape
## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable
## (top: Vector3) -> void: one puff of a plume at its vent's top (the default: a burst of vapour); tests catch it.
var plume: Callable
## Off in tests (they call tick()).
var auto_tick := true
var time := 0.0

var _puff_t := 0.0
var _look_t := 0.0
var _near: Array[Vector2i] = []
var _blowing := {}                # vent -> it was erupting at the last puff (a whoosh when one starts)


## The colour of a world's plumes: yellow sulphur on Io, dark dust on Triton, white vapour elsewhere (Europa).
static func plume_color(s: SpaceShape) -> Color:
	if s != null and s.triton != null:
		return DUST
	return SULPHUR if s != null and s.io != null else VAPOUR


## Where a world's puffs drift: north-east on Triton's thin wind (the way its geysers' dust was carried), nowhere
## elsewhere (straight up).
static func plume_wind(s: SpaceShape) -> Vector3:
	return PadRules.WIND * DRIFT if s != null and s.triton != null else Vector3.ZERO


## A vent's plume is erupting at time t (seconds): ERUPT of every PERIOD, on the vent's own beat.
static func erupting(t: float, vent: Vector2i) -> bool:
	var phase := float(absi(vent.x * 73856093 ^ vent.y * 19349663) % 1000) / 1000.0 * PERIOD
	return fposmod(t + phase, PERIOD) < ERUPT


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func tick(delta: float) -> void:
	time += delta
	if shape == null or not shape.has_vents() or not player_position.is_valid():
		return
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK
		var at: Vector3 = player_position.call()
		_near = shape.vents_near(floori(at.x), floori(at.z), RANGE) if at.is_finite() else ([] as Array[Vector2i])
	_puff_t -= delta
	if _puff_t > 0.0:
		return
	_puff_t = PUFF
	for v in _near:
		var on := erupting(time, v)
		if on:
			var top := Vector3(v.x + 0.5, shape.height_at(v.x, v.y) + 0.2, v.y + 0.5)
			if plume.is_valid():
				plume.call(top)
			else:
				_puff(top, not bool(_blowing.get(v, false)))
		_blowing[v] = on


## One puff rising from a vent, in the world's plume colour (and a soft whoosh when the plume starts). Triton: a gentler
## puff of dark dust and a little frost, lasting longer, drifting north-east as it rises.
func _puff(top: Vector3, starts: bool) -> void:
	if not is_inside_tree():
		return
	if starts:
		Audio.play(&"whoosh", top, -8.0, 0.8)
	var wind := plume_wind(shape)
	if wind == Vector3.ZERO:
		Fx.burst(get_tree().root, top, plume_color(shape), 10, 14.0, 0.3, 2.0, 2.0, 8.0)
		return
	var dust := Fx.burst(get_tree().root, top, plume_color(shape), 8, 10.0, 0.32, 3.0, 0.6, 10.0)
	dust.gravity += wind
	var frost := Fx.burst(get_tree().root, top, FROST, 4, 9.0, 0.24, 3.0, 0.6, 10.0)
	frost.gravity += wind
