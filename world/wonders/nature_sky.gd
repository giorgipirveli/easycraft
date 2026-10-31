class_name NatureSky
extends Node3D
## The nature region's sky in world 41 (owner #78, spec §24, the third tour), for this game's own player: the northern
## lights in the sky north of the snowy valley on dark nights (WonderFacts: they can only be seen when the sky is dark),
## and a rainbow in Victoria Falls' spray by day. Each is drawn as ribbons of vertex colours with the night sky's star
## material settings (SkyCycle._night_material: unshaded, see-through, never fogged, both sides; like Venus's
## lightning), so no new shader. Shown only near them (AURORA_RANGE, RAINBOW_RANGE), faded in and out with the night
## (DayCycle.look's stars), the lights' curtains swaying and brightening slowly. Cheap: a handful of meshes of a few
## hundred triangles, a look ten times a second, nothing at all far away.

const UPDATE := 0.1                     # seconds between looks
const AURORA_RANGE := 300.0             # the lights are drawn while the child is this near the valley (x, z) ...
const RAINBOW_RANGE := 160.0            # ... the rainbow this near the falls
const NIGHT_MIN := 0.04                 # fainter than this, nothing is drawn
## The curtains: their feet's middle (north of the valley, high in the sky), and each curtain's [offset from it,
## width, height, waves' phase].
const AURORA_AT := Vector3(55, 130, 270)
const CURTAINS := [[Vector3(0, 0, 0), 190.0, 46.0, 0.0], [Vector3(-20, 10, -26), 150.0, 38.0, 2.1],
	[Vector3(30, -6, 22), 120.0, 30.0, 4.3]]
const SEGMENTS := 48
const GREEN := Color(0.35, 1.0, 0.55)   # oxygen's green, low down ...
const PINK := Color(0.95, 0.35, 0.75)   # ... red-pink and violet higher up
const VIOLET := Color(0.55, 0.35, 1.0)
## The rainbow over the falls' chasm, facing the rainforest path (north): its middle and radius.
const RAINBOW_AT := Vector3(140, 18, 528)
const RAINBOW_R := 22.0
const RAINBOW_BAND := 0.5
const RAINBOW_ALPHA := 0.4
const RAINBOW_COLOURS: Array[Color] = [Color("ff4040"), Color("ff9a30"), Color("ffe640"), Color("50e060"), Color("40a0ff"),
	Color("5060e0"), Color("a050e0")]

## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable = func() -> Vector3: return Vector3.INF
## () -> float: the time of day (DayCycle).
var sky_time: Callable = func() -> float: return DayCycle.NOON
## Off in tests (they call tick()).
var auto_tick := true

var aurora: Node3D
var curtains: Array[MeshInstance3D] = []
var rainbow: MeshInstance3D
var _materials: Array[StandardMaterial3D] = []
var _rainbow_material: StandardMaterial3D
var _t := 0.0
var _look := 0.0


func _ready() -> void:
	aurora = Node3D.new()
	aurora.name = "Aurora"
	aurora.position = AURORA_AT
	aurora.visible = false
	add_child(aurora)
	for i in CURTAINS.size():
		var c: Array = CURTAINS[i]
		var m := MeshInstance3D.new()
		m.name = "Curtain%d" % i
		m.position = c[0]
		var mat := star_material()
		_materials.append(mat)
		m.mesh = curtain_mesh(c[1], c[2], c[3], mat)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aurora.add_child(m)
		curtains.append(m)
	rainbow = MeshInstance3D.new()
	rainbow.name = "Rainbow"
	rainbow.position = RAINBOW_AT
	_rainbow_material = star_material()
	rainbow.mesh = rainbow_mesh(_rainbow_material)
	rainbow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rainbow.visible = false
	add_child(rainbow)


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


## One step: a look every UPDATE seconds (what shows, how bright), the curtains' slow sway every frame they show.
func tick(delta: float) -> void:
	_t += delta
	_look -= delta
	if _look <= 0.0:
		_look = UPDATE
		look()
	if aurora != null and aurora.visible:
		for i in curtains.size():
			var c := curtains[i]
			c.rotation.y = 0.07 * sin(_t * 0.11 + i * 1.7)
			c.scale.y = 1.0 + 0.12 * sin(_t * 0.27 + i * 2.3)
			c.position.x = (CURTAINS[i][0] as Vector3).x + 6.0 * sin(_t * 0.05 + i)


## What shows now: the lights at night near the valley, the rainbow by day near the falls, and how bright.
func look() -> void:
	if aurora == null:
		return
	var at: Vector3 = player_position.call()
	var night := night_amount(float(sky_time.call()))
	var valley := NatureGround.AURORA_C
	var near_valley := at.is_finite() and Vector2(at.x - valley.x, at.z - valley.y).length() < AURORA_RANGE
	aurora.visible = near_valley and night > NIGHT_MIN
	if aurora.visible:
		for i in _materials.size():
			_materials[i].albedo_color.a = night * (0.7 + 0.3 * sin(_t * 0.45 + i * 1.9))
	var near_falls := at.is_finite() and Vector2(at.x - RAINBOW_AT.x, at.z - RAINBOW_AT.z).length() < RAINBOW_RANGE
	var day := 1.0 - night
	rainbow.visible = near_falls and day > NIGHT_MIN
	_rainbow_material.albedo_color.a = day


## How dark the sky is at time t (0 day, 1 night): the stars' visibility (DayCycle.look).
static func night_amount(t: float) -> float:
	return float(DayCycle.look(t).stars)


## The night sky's star material settings (SkyCycle: unshaded, see-through vertex colours, never fogged, both sides): a
## shader the warm-up already has; one per curtain so each can brighten on its own.
static func star_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	SkyCycle._night_material(m)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	return m


## A curtain of light: a wavy ribbon `width` wide and `height` tall, its foot a thin bright green line, green fading
## up into pink and violet at its top.
static func curtain_mesh(width: float, height: float, phase: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [[0.0, Color(GREEN, 0.0)], [0.12, Color(GREEN, 0.95)], [0.45, Color(GREEN, 0.55)],
		[0.75, Color(PINK, 0.3)], [1.0, Color(VIOLET, 0.0)]]
	var pts := PackedVector3Array()
	for i in SEGMENTS + 1:
		var u := float(i) / SEGMENTS
		var x := (u - 0.5) * width
		var z := 9.0 * sin(u * 7.0 + phase) + 4.0 * sin(u * 17.0 + phase * 2.0)
		pts.append(Vector3(x, 0.0, z))
	for i in SEGMENTS:
		for r in rows.size() - 1:
			var y0: float = rows[r][0] * height
			var y1: float = rows[r + 1][0] * height
			var c0: Color = rows[r][1]
			var c1: Color = rows[r + 1][1]
			var a := pts[i]
			var b := pts[i + 1]
			for v: Array in [[a, y0, c0], [b, y0, c0], [b, y1, c1], [a, y0, c0], [b, y1, c1], [a, y1, c1]]:
				st.set_color(v[2])
				st.add_vertex((v[0] as Vector3) + Vector3(0, v[1], 0))
	st.set_material(mat)
	return st.commit()


## A rainbow: seven bands, red outside to violet inside, in a half circle (standing in the x-y plane).
static func rainbow_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
	for band in RAINBOW_COLOURS.size():
		var r1 := RAINBOW_R - band * RAINBOW_BAND
		var r0 := r1 - RAINBOW_BAND
		var c := Color(RAINBOW_COLOURS[band], RAINBOW_ALPHA)
		for i in n:
			var a0 := PI * i / n
			var a1 := PI * (i + 1) / n
			var p := [Vector3(cos(a0) * r0, sin(a0) * r0, 0), Vector3(cos(a1) * r0, sin(a1) * r0, 0),
				Vector3(cos(a1) * r1, sin(a1) * r1, 0), Vector3(cos(a0) * r1, sin(a0) * r1, 0)]
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_color(c)
				st.add_vertex(p[k])
	st.set_material(mat)
	return st.commit()
