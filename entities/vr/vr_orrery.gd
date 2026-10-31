class_name VrOrrery
extends Node3D
## Owner #110 (VR round 4, VR-WONDER, idea 1 "hold a planet"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3): in a headset the Star Map's solar system is also a moving orrery within
## reach, made by SpacePanel (its VR branch) under Vr while the map is open (the 2D map stays on the eye panel for the
## cards and the buttons). OrreryRules has the sums.
##
## - Under the eye panel, a little more than a metre across: the Sun in the middle, the planets on their orbits where they
##   really are today (the flat map's StarMap.longitude), going round (an Earth year in 40 seconds), their moons round
##   them. A hand near a planet (or holding one) holds time still: a planet waits for a child's hand.
## - Every body but the Sun is a VrGrabbable of kind &"two_hand" (VR-HANDS' grabber: near, or the laser's far pull).
##   Taken, it grows to its true size against Earth (Earth 4 cm, Jupiter 45 cm), sits in front of the palm, its bands
##   turning, and its card opens on the panel (body_taken: the Space Book). Two hands stretch it. A planet in each hand:
##   the words over the orrery compare them ("Jupiter is 11 times as wide as Earth!").
## - Let go, it glides back to its orbit. Let go in the gold landing ring (beside the orrery on the pointing hand's
##   side): dropped_in_ring, and the panel does what its card's LAND (or HOME) does, or says why not.
## - TRUE SIZE (the panel's button): the planets glide into a row in their true sizes before a Sun 109 Earths across.
## - Cheap: one MultiMesh of every body but the Sun (per-instance colours and bands, lit from the orrery's Sun: one
##   draw), the Sun, Saturn's ring, the orbits, the landing ring and two labels: 7 draws at most while open.
## Nothing moves the child (the objects move, never the world); the Sun's light is steady (no flashes).

signal body_taken(id: StringName)
signal dropped_in_ring(id: StringName)

## A glide home (let go, TRUE SIZE on or off) takes this long (s).
const GLIDE_TIME := 0.6
## A planet in one hand grows towards its hand size at this rate (1/s).
const GROW_RATE := 12.0
## A held planet sits this many of its radii ahead of the palm.
const HOLD_AHEAD := 0.8
## A planet's bands turn once in this many seconds.
const SPIN_SECONDS := 8.0
## Axial tilts (degrees): Uranus spins on its side, as its card says.
const TILT := {&"earth": 23.4, &"mars": 25.2, &"jupiter": 3.1, &"saturn": 26.7, &"uranus": 97.8, &"neptune": 28.3,
	&"pluto": 57.0}
## Bands (1) or patches (0) on each body's sphere: the giants are banded, the rocky ones patchy.
const BANDS := {&"jupiter": 1.0, &"saturn": 1.0, &"uranus": 0.35, &"neptune": 0.45}
const SUN_COLOR := Color("ffcf3a")
const RING_COLOR := Color(0.89, 0.79, 0.56, 0.75)
const LAND_COLOR := Color("ffd23f")
const ORBIT_COLOR := Color(1.0, 1.0, 1.0, 0.22)

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

uniform vec3 sun_at = vec3(0.0);

varying vec3 local_n;
varying vec3 world_n;
varying vec3 world_p;
varying vec4 second;

void vertex() {
	local_n = normalize(VERTEX);
	second = INSTANCE_CUSTOM;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float stripe = smoothstep(0.35, 0.65, 0.5 + 0.5 * sin(local_n.y * 18.0 + sin(local_n.y * 7.0) * 1.5));
	float blot = smoothstep(0.55, 0.8, 0.5 + 0.5 * sin(local_n.x * 5.0 + local_n.z * 3.0) * cos(local_n.y * 4.0 - local_n.z * 2.0));
	float m = mix(blot, stripe, second.a);
	vec3 base = mix(COLOR.rgb, second.rgb, m * 0.85);
	float day = clamp(dot(normalize(world_n), normalize(sun_at - world_p)), 0.0, 1.0);
	ALBEDO = base * (0.28 + 0.72 * day);
}
"""

static var _shader: Shader

## The Star Map's days since 2000 the orrery shows, and its moons' clock (s).
var days := 0.0
var moon_t := 0.0
## TRUE SIZE: the planets in a row in their true sizes.
var true_size := false
## The hand that points (the landing ring's side).
var pointing: StringName = VrRules.RIGHT

var _bodies := {}                    # id -> Body
var _order: Array[StringName] = []   # the MultiMesh's instances (every body but the Sun)
var _mm := MultiMeshInstance3D.new()
var _material := ShaderMaterial.new()
var _orbits := MeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _ring_label := Label3D.new()
var _compare := Label3D.new()
var _local := Transform3D()          # the orrery's place relative to the rig (it moves with the child's body)


## One body: a Node3D whose scale is its radius (the sphere drawn by the MultiMesh is a unit one) with its grabbable.
class Body:
	extends Node3D
	var id: StringName
	var grabbable := VrGrabbable.new()
	var spin := 0.0
	var tilt := 0.0
	var glide := 1.0          # of a glide home (1: home)
	var from := Transform3D()
	var grows := true         # one hand: it grows to its hand size (after two hands stretched it: as stretched)
	var hovers := 0

	func _init(body_id: StringName) -> void:
		id = body_id
		name = "Body_" + String(body_id)
		grabbable.name = "Grabbable"
		grabbable.kind = &"two_hand"
		grabbable.throwable = false
		grabbable.far_pull = true
		grabbable.enabled = OrreryRules.takeable(body_id)
		add_child(grabbable)


func _init() -> void:
	name = "VrOrrery"
	process_mode = Node.PROCESS_MODE_ALWAYS   # the Star Map holds a game played alone still: the orrery goes on


## Builds the orrery for the Star Map's `start_days`, in front of the head (VR's own place: under the eye panel).
func open(start_days: float, pointing_hand: StringName) -> void:
	days = start_days
	moon_t = 0.0
	pointing = pointing_hand
	_build()
	var head := Vr.head_transform()
	var s := Vr.world_scale()
	var fwd := -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP) * s,
		head.origin + (fwd * OrreryRules.ORRERY_AHEAD + Vector3.DOWN * OrreryRules.ORRERY_DROP) * s)
	_local = Vr.rig.global_transform.affine_inverse() * global_transform if Vr.rig != null else global_transform
	if not Vr.ended.is_connected(queue_free):
		Vr.ended.connect(queue_free)
	step(0.0)


func close() -> void:
	if Vr.ended.is_connected(queue_free):
		Vr.ended.disconnect(queue_free)
	for b: Body in _bodies.values():
		b.grabbable.enabled = false   # no hand takes a planet of a closed orrery in the frame before it goes
	queue_free()


func _exit_tree() -> void:
	if Vr.ended.is_connected(queue_free):
		Vr.ended.disconnect(queue_free)


func _process(delta: float) -> void:
	step(delta)


## The node of body `id` (null for none).
func body(id: StringName) -> Node3D:
	return _bodies.get(id) as Node3D


func body_grabbable(id: StringName) -> VrGrabbable:
	var b := _bodies.get(id) as Body
	return b.grabbable if b else null


## The landing ring's middle in the world.
func ring_position() -> Vector3:
	return global_transform * OrreryRules.ring_at(pointing)


## The words comparing the two planets in the hands ("" unless there are two).
func compare_text() -> String:
	return _compare.text


## TRUE SIZE on or off: every body glides to its new place and size.
func set_true_size(on: bool) -> void:
	if on == true_size:
		return
	true_size = on
	for b: Body in _bodies.values():
		if not _busy(b):
			_glide_from_here(b)
	_orbits.visible = not on


# --- Every frame ---

func step(delta: float) -> void:
	if Vr.rig != null and is_inside_tree():
		global_transform = Vr.rig.global_transform * _local   # with the child's body (the map holds it still alone)
	if not _still():
		days += delta * OrreryRules.days_per_second()
		moon_t += delta
	var held: Array[Body] = []
	for b: Body in _bodies.values():
		b.spin = fposmod(b.spin + delta * TAU / SPIN_SECONDS, TAU)
		if _busy(b):
			_step_held(b, delta)
			if b.grabbable.held_by() == VrRules.LEFT or b.grabbable.held_by() == VrRules.RIGHT:
				held.append(b)
		else:
			_step_home(b, delta)
		b.grabbable.radius = b.global_transform.basis.get_scale().x
	_draw_bodies()
	var words := ""
	if held.size() == 2 and held[0] != held[1]:
		words = OrreryRules.compare_words(held[0].id, held[1].id)
	if _compare.text != words:
		_compare.text = words
	_compare.visible = words != ""


## A hand near a body, or holding, locking or pulling one: time waits.
func _still() -> bool:
	for b: Body in _bodies.values():
		if b.hovers > 0 or _busy(b):
			return true
	return false


## A hand holds, locks or pulls it (VR-HANDS' grabber moves it then).
func _busy(b: Body) -> bool:
	if b.grabbable.held_by() != &"":
		return true
	if Vr.grabber == null:
		return false
	return Vr.grabber.held(VrRules.LEFT) == b.grabbable or Vr.grabber.held(VrRules.RIGHT) == b.grabbable


## Held in one hand: it grows towards its true size against Earth and sits ahead of the palm.
func _step_held(b: Body, delta: float) -> void:
	var by := b.grabbable.held_by()
	if by != VrRules.LEFT and by != VrRules.RIGHT:
		return   # locked, pulled or in both hands: the grabber's (two hands stretch it)
	var r := b.global_transform.basis.get_scale().x
	if b.grows and b.top_level:
		var want := OrreryRules.hand_radius(b.id) * Vr.world_scale()
		r = lerpf(r, want, 1.0 - exp(-GROW_RATE * delta)) if absf(r - want) > 0.0002 else want
		b.scale = Vector3.ONE * r
	b.grabbable.hold_offset = Transform3D(Basis(), Vector3(0.0, 0.0, -HOLD_AHEAD * r))


## Not held: on its orbit (or in the TRUE SIZE row), gliding there first when it was let go.
func _step_home(b: Body, delta: float) -> void:
	var target := Transform3D(Basis.from_scale(Vector3.ONE * OrreryRules.radius(b.id, true_size)),
		OrreryRules.place(b.id, days, moon_t, true_size))
	if b.glide < 1.0:
		b.glide = minf(b.glide + delta / GLIDE_TIME, 1.0)
		var e := b.glide * b.glide * (3.0 - 2.0 * b.glide)
		b.transform = b.from.interpolate_with(target, e)
	else:
		b.transform = target


func _glide_from_here(b: Body) -> void:
	b.from = b.transform
	b.glide = 0.0


func _draw_bodies() -> void:
	var mm := _mm.multimesh
	if mm == null:
		return
	var inv := _mm.global_transform.affine_inverse()
	for i in _order.size():
		var b := _bodies[_order[i]] as Body
		var turn := Basis(Vector3.BACK, deg_to_rad(b.tilt)) * Basis(Vector3.UP, b.spin)
		mm.set_instance_transform(i, inv * b.global_transform * Transform3D(turn, Vector3.ZERO))
	var sun := _bodies.get(&"sun") as Body
	if sun:
		_material.set_shader_parameter(&"sun_at", sun.global_position)


# --- The hands (the grabbables' signals) ---

func _on_hovered(_side: StringName, on: bool, b: Body) -> void:
	b.hovers = maxi(b.hovers + (1 if on else -1), 0)


func _on_grabbed(side: StringName, b: Body) -> void:
	if not b.top_level:
		b.top_level = true   # in the hand it is the hand's: the orrery's place never drags it
	if b.grabbable.held_by() == &"both":
		b.grows = false   # two hands: the grabber stretches it
		return
	b.grows = true
	if b.grabbable.held_by() == side:
		body_taken.emit(b.id)


func _on_released(side: StringName, _velocity: Vector3, b: Body) -> void:
	if b.grabbable.held_by() != &"":
		return   # the other hand keeps it
	var inv := global_transform.affine_inverse()
	var ring := OrreryRules.ring_at(pointing)
	var landed := OrreryRules.in_ring(inv * b.global_position, ring) \
		or OrreryRules.in_ring(inv * Vr.hand_grip(side).origin, ring)
	b.top_level = false
	b.grows = true
	b.grabbable.hold_offset = Transform3D.IDENTITY
	_glide_from_here(b)
	if landed:
		dropped_in_ring.emit(b.id)

# --- Building ---

func _build() -> void:
	if not _bodies.is_empty():
		return
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_material.shader = _shader
	for d: Dictionary in StarMap.SOLAR:
		var b := Body.new(d.id)
		b.tilt = float(TILT.get(d.id, 0.0))
		add_child(b)
		_bodies[d.id] = b
		b.grabbable.hovered.connect(_on_hovered.bind(b))
		b.grabbable.grabbed.connect(_on_grabbed.bind(b))
		b.grabbable.released.connect(_on_released.bind(b))
		if d.id == &"sun":
			b.add_child(_sun_mesh())
		else:
			_order.append(d.id)
		if d.id == &"saturn":
			b.add_child(_saturn_ring(deg_to_rad(b.tilt)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mm.mesh = sphere
	mm.instance_count = _order.size()
	for i in _order.size():
		var d := StarMap.body(_order[i])
		var c2: Color = d.get("color2", d.color)
		mm.set_instance_color(i, d.color)
		mm.set_instance_custom_data(i, Color(c2.r, c2.g, c2.b, float(BANDS.get(_order[i], 0.0))))
	_mm.name = "Bodies"
	_mm.multimesh = mm
	_mm.material_override = _material
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm.custom_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))   # a planet in the hand is still drawn
	add_child(_mm)
	_orbits.name = "Orbits"
	_orbits.mesh = _orbit_lines()
	_orbits.material_override = _plain(ORBIT_COLOR, true)
	_orbits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_orbits)
	var torus := TorusMesh.new()
	torus.inner_radius = OrreryRules.RING_RADIUS - 0.012
	torus.outer_radius = OrreryRules.RING_RADIUS + 0.008
	torus.rings = 24
	torus.ring_segments = 8
	_ring.name = "LandingRing"
	_ring.mesh = torus
	_ring.material_override = _plain(LAND_COLOR, false)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = OrreryRules.ring_at(pointing)
	add_child(_ring)
	_label(_ring_label, "LAND", 44)
	_ring_label.name = "LandWords"
	_ring_label.position = OrreryRules.ring_at(pointing) + Vector3(0.0, -0.06, 0.0)
	add_child(_ring_label)
	_label(_compare, "", 40)
	_compare.name = "Compare"
	_compare.position = Vector3(0.0, 0.26, 0.1)
	_compare.width = 900.0
	_compare.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compare.visible = false
	add_child(_compare)


func _sun_mesh() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "Sun"
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 32
	s.rings = 16
	m.mesh = s
	m.material_override = _plain(SUN_COLOR, false)   # steady: no glow, no flicker
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## Saturn's rings: a flat band from RING_INNER to RING_OUTER of its radius, tilted with it.
func _saturn_ring(tilt: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 48
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p := [Vector3(cos(a0), 0, sin(a0)), Vector3(cos(a1), 0, sin(a1))]
		var i0: Vector3 = p[0] * OrreryRules.RING_INNER
		var i1: Vector3 = p[1] * OrreryRules.RING_INNER
		var o0: Vector3 = p[0] * OrreryRules.RING_OUTER
		var o1: Vector3 = p[1] * OrreryRules.RING_OUTER
		for v: Vector3 in [i0, o0, o1, i0, o1, i1]:
			st.add_vertex(v)
	var m := MeshInstance3D.new()
	m.name = "SaturnRing"
	m.mesh = st.commit()
	var mat := _plain(RING_COLOR, true)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.rotation = Vector3(0.0, 0.0, tilt)
	return m


## Every planet's orbit as a faint circle (one mesh of lines).
static func _orbit_lines() -> ArrayMesh:
	var pts := PackedVector3Array()
	var n := 64
	for id: StringName in OrreryRules.ORBIT:
		var r := float(OrreryRules.ORBIT[id])
		for i in n:
			pts.append(Vector3(cos(TAU * i / n) * r, 0.0, sin(TAU * i / n) * r))
			pts.append(Vector3(cos(TAU * (i + 1) / n) * r, 0.0, sin(TAU * (i + 1) / n) * r))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func _plain(color: Color, alpha: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.disable_receive_shadows = true
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func _label(l: Label3D, text: String, size: int) -> void:
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0008
	l.outline_size = 10
	l.modulate = Color("fff3b0")
	l.outline_modulate = Color(0.05, 0.05, 0.12)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
