class_name GanymedeSky
extends Node3D
## Ganymede's sky shows (cosmos, spec §21b.2), for this game's own player. The sandbox adds one ("GanymedeSky") in a world
## whose shape is Ganymede's.
## - The auroras: Ganymede is the only moon with its own magnetic field, so it has auroras, glowing belts round both its
##   poles (a space telescope watched them; their gentle rocking showed a salty ocean under the ice). Here: a belt of
##   curtains over each pole's frost (the north one BELT_IN inside the north frost's line, the south one inside the
##   south's), BELT_Y high, running east and west round the pole over the child; green low down and pink higher up
##   (Ganymede's visible auroras glow red and green from oxygen); shown at night only (faded in and out with the night sky's
##   stars: DayCycle.look), each curtain swaying and brightening slowly, the belts rocking ROCK to and fro every
##   ROCK_PERIOD. From the pad the north belt hangs low over the northern horizon and the south belt over the southern
##   one; from the frost under it, overhead. A belt farther than BELT_FAR is drawn at BELT_FAR in its direction (inside
##   the camera's far plane, 300). The curtains look like NatureSky's (owner #78's northern lights), with ends that
##   dissolve (belt_mesh): vertex colours with the night sky's star material settings (NatureSky.star_material,
##   SkyCycle._night_material), so no new shader.
## - Io and Europa go round Jupiter inside Ganymede's orbit (Io 4 times and Europa twice for each of Ganymede's: the
##   orbital resonance): seen from Ganymede they swing back and forth past Jupiter like pendulums (a circle seen edge-on),
##   out to IO_SWING and EUROPA_SWING from it (asin of their orbits' radii over Ganymede's), in front of it half the time
##   and behind it the other half (hidden behind its disc). This moves SkyCycle's two small moons (the descriptor's
##   sky_planet.moons: Io first, then Europa) along Jupiter's equator's circle through the east and the west.
## Cheap: two belts of three curtains (a few hundred triangles each), a look ten times a second, two moved billboards.

const UPDATE := 0.1                     # seconds between looks
const NIGHT_MIN := 0.04                 # fainter than this, no aurora is drawn
const BELT_IN := 60.0                   # a belt hangs this far inside its frost's line ...
const BELT_Y := 150.0                   # ... this high
const BELT_FAR := 200.0                 # ... drawn at most this far from the viewer
const ROCK := 8.0                       # the belts rock this far north and south ...
const ROCK_PERIOD := 150.0              # ... every this many seconds
## Each belt's curtains: [offset from the belt's middle, width, height, waves' phase]; a curtain's last END_FADE of its
## width at both ends dissolves (belt_mesh), SEGMENTS pieces along it.
const CURTAINS := [[Vector3(0, 0, 0), 420.0, 60.0, 0.0], [Vector3(-40, 12, -18), 340.0, 48.0, 2.1],
	[Vector3(50, -8, 16), 300.0, 40.0, 4.3]]
const END_FADE := 0.3
const SEGMENTS := 64
## Io and Europa seen from Ganymede: the farthest each gets from Jupiter (degrees: asin(421,700 ÷ 1,070,400) and
## asin(671,100 ÷ 1,070,400)) and the seconds of a swing there and back (2.35 and 7.05 Earth days, as Ganymede's own day
## of 7.155 Earth days is the game's day of DayCycle.LENGTH seconds).
const IO_SWING := 23.2
const EUROPA_SWING := 38.8
const IO_PERIOD := 394.0
const EUROPA_PERIOD := 1182.0
const BEHIND := 9.9                     # degrees: Jupiter's picture's half width (80 across at SkyCycle.MOON_RADIUS)
const NEAR := 6.0                       # a moon in front of Jupiter is drawn this much nearer, one behind it farther

var shape: SpaceShape
var sky: SkyCycle
## () -> Vector3: where this game's player looks from (the camera; INF when there is none).
var viewer_position: Callable
## () -> float: the time of day (DayCycle).
var sky_time: Callable = func() -> float: return DayCycle.NOON
## Off in tests (they call tick()).
var auto_tick := true

var north: Node3D
var south: Node3D
var _curtains: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _t := 0.0
var _look := 0.0
var _night := 0.0


func _ready() -> void:
	if not viewer_position.is_valid():
		viewer_position = _camera_position
	north = _belt("AuroraNorth", 0.0)
	south = _belt("AuroraSouth", 1.3)
	tick(0.0)


func _belt(belt_name: String, phase: float) -> Node3D:
	var b := Node3D.new()
	b.name = belt_name
	b.visible = false
	add_child(b)
	for i in CURTAINS.size():
		var c: Array = CURTAINS[i]
		var m := MeshInstance3D.new()
		m.name = "Curtain%d" % i
		m.position = c[0]
		var mat := NatureSky.star_material()
		_materials.append(mat)
		m.mesh = belt_mesh(c[1], c[2], float(c[3]) + phase, mat)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.add_child(m)
		_curtains.append(m)
	return b


## Both belts' curtains (tests).
func curtains() -> Array[MeshInstance3D]:
	return _curtains


func _camera_position() -> Vector3:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position if cam != null else Vector3.INF


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


## One step: a look every UPDATE seconds (night or day, how bright, the moons), the belts placed for the viewer and the
## curtains' slow sway every frame they show.
func tick(delta: float) -> void:
	_t += delta
	_look -= delta
	if _look <= 0.0:
		_look = UPDATE
		look()
	var at: Vector3 = viewer_position.call() if viewer_position.is_valid() else Vector3.INF
	if north == null or not at.is_finite() or _night <= NIGHT_MIN:
		return
	_place(north, true, at)
	_place(south, false, at)
	for i in _curtains.size():
		var c := _curtains[i]
		var k := i % CURTAINS.size()
		c.rotation.y = 0.05 * sin(_t * 0.11 + i * 1.7)
		c.scale.y = 1.0 + 0.12 * sin(_t * 0.27 + i * 2.3)
		c.position.x = (CURTAINS[k][0] as Vector3).x + 6.0 * sin(_t * 0.05 + i)


## What shows now: the belts at night, how bright; Io and Europa where their swings are.
func look() -> void:
	_night = NatureSky.night_amount(float(sky_time.call()))
	if north != null:
		var shown := _night > NIGHT_MIN and shape != null and shape.ganymede != null
		north.visible = shown
		south.visible = shown
		if shown:
			for i in _materials.size():
				_materials[i].albedo_color.a = _night * (0.7 + 0.3 * sin(_t * 0.45 + i * 1.9))
	_move_moons()


## The middle line of a belt (its z: north is -z) now, rocking to and fro.
func belt_z(is_north: bool) -> float:
	if shape == null or shape.ganymede == null:
		return 0.0
	var at: Vector3 = viewer_position.call() if viewer_position.is_valid() else Vector3.ZERO
	var x := at.x if at.is_finite() else 0.0
	var rock := ROCK * sin(TAU * _t / ROCK_PERIOD)
	if is_north:
		return shape.ganymede.north_edge(x) - BELT_IN + rock
	return shape.ganymede.south_edge(x) + BELT_IN + rock


## A belt over the viewer's east-west place, at its line and height; farther than BELT_FAR, drawn at BELT_FAR toward it.
func _place(belt: Node3D, is_north: bool, at: Vector3) -> void:
	var d := Vector3(0.0, BELT_Y - at.y, belt_z(is_north) - at.z)
	var length := d.length()
	if length > BELT_FAR:
		d *= BELT_FAR / length
	belt.global_position = at + d


## A belt's curtain of light: a wavy ribbon `width` wide and `height` tall (NatureSky's northern lights' look: a bright
## green foot fading up into pink and violet), dissolving at both ends over END_FADE of its width so a long belt never
## ends in a hard edge.
static func belt_mesh(width: float, height: float, phase: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [[0.0, Color(NatureSky.GREEN, 0.0)], [0.12, Color(NatureSky.GREEN, 0.95)], [0.45, Color(NatureSky.GREEN, 0.55)],
		[0.75, Color(NatureSky.PINK, 0.3)], [1.0, Color(NatureSky.VIOLET, 0.0)]]
	var pts := PackedVector3Array()
	var fade := PackedFloat32Array()
	for i in SEGMENTS + 1:
		var u := float(i) / SEGMENTS
		pts.append(Vector3((u - 0.5) * width, 0.0, 14.0 * sin(u * 5.0 + phase) + 6.0 * sin(u * 13.0 + phase * 2.0)))
		fade.append(smoothstep(0.0, END_FADE, u) * smoothstep(1.0, 1.0 - END_FADE, u))
	for i in SEGMENTS:
		for r in rows.size() - 1:
			var y0: float = rows[r][0] * height
			var y1: float = rows[r + 1][0] * height
			var c0: Color = rows[r][1]
			var c1: Color = rows[r + 1][1]
			for v: Array in [[i, y0, c0], [i + 1, y0, c0], [i + 1, y1, c1], [i, y0, c0], [i + 1, y1, c1], [i, y1, c1]]:
				var k: int = v[0]
				var c: Color = v[2]
				st.set_color(Color(c, c.a * fade[k]))
				st.add_vertex(pts[k] + Vector3(0, v[1], 0))
	st.set_material(mat)
	return st.commit()


## A swing at time t (seconds) of `period`, out to `max_deg` from Jupiter: (its angle from Jupiter in degrees, in front
## of Jupiter when > 0).
static func swing(t: float, period: float, max_deg: float, phase: float) -> Vector2:
	var a := TAU * t / period + phase
	return Vector2(max_deg * sin(a), cos(a))


## The direction of a body `deg` degrees from Jupiter (at `jupiter`) along Jupiter's equator's circle, which passes
## through the east and the west (positive: toward the west).
static func along_circle(jupiter: Vector3, deg: float) -> Vector3:
	var j := jupiter.normalized()
	var west := Vector3.LEFT - j * j.dot(Vector3.LEFT)
	var t := west.normalized() if west.length() > 0.001 else Vector3.UP
	return (j * cos(deg_to_rad(deg)) + t * sin(deg_to_rad(deg))).normalized()


func _move_moons() -> void:
	if sky == null or sky.planet() == null:
		return
	var moons := sky.moons()
	if moons.size() < 2:
		return
	var j := sky.planet().position.normalized()
	for e: Array in [[moons[0], IO_PERIOD, IO_SWING, 0.7], [moons[1], EUROPA_PERIOD, EUROPA_SWING, 2.6]]:
		var m: MeshInstance3D = e[0]
		var s := swing(_t, float(e[1]), float(e[2]), float(e[3]))
		var dir := along_circle(j, s.x)
		m.position = dir * (SkyCycle.MOON_RADIUS + (-NEAR if s.y > 0.0 else NEAR))
		m.visible = dir.y > 0.02 and not (s.y <= 0.0 and absf(s.x) < BEHIND)
