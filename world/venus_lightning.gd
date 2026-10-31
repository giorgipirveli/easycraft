class_name VenusLightning
extends Node
## Lightning far below Venus's cloud city (cosmos, spec §21b.2: "lightning far below"; real: spacecraft picked up radio
## signals that may come from lightning in Venus's clouds). The sandbox adds one ("Lightning") in a world whose shape is
## Venus's, for this game's own player: every EVERY seconds or so a soft, silent flash deep in the yellow clouds, NEAR to
## FAR blocks away sideways and never over a deck: a bright zig-zag bolt with a faint glow round it, shown for a moment,
## a flicker, once more, gone. Friendly (spec §3c): no thunder, never near the child, never over the city, never a
## danger (the clouds are a fact to learn). Cheap: one small mesh at a time, drawn with the night sky's own material
## settings (the stars': unshaded vertex colours, no fog), so no new shader.

const EVERY := Vector2(5.0, 11.0)       # seconds between two flashes
const FIRST := 3.0                      # the first one after landing
const NEAR := 26.0                      # blocks sideways from the child ...
const FAR := 70.0                       # ... at most
const DEPTH := Vector2i(1, 5)           # the bolt starts this far under the clouds' top
const LENGTH := Vector2(10.0, 18.0)     # its length
const SEGMENTS := 7
const WIDTH := 0.7                      # the bolt's core ...
const GLOW_WIDTH := 2.6                 # ... and its faint glow
const SHOW := 0.12                      # seconds shown, dark, shown again
const DARK := 0.08
const AGAIN := 0.1
const CORE := Color(1.0, 0.98, 1.0, 1.0)
const GLOW := Color(0.86, 0.8, 1.0, 0.35)
const TRIES := 8                        # spots tried for a flash (never over a deck)

var shape: SpaceShape
## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable
## Off in tests (they call tick()).
var auto_tick := true
var rng := RandomNumberGenerator.new()

var _wait := FIRST
var _t := -1.0                          # seconds into the flash showing now (-1: none)
var _bolt: MeshInstance3D

static var _material: StandardMaterial3D


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


## One step: waits, then flashes (shown, dark, shown again, gone).
func tick(delta: float) -> void:
	if _t >= 0.0:
		_t += delta
		if _bolt:
			_bolt.visible = _t < SHOW or (_t >= SHOW + DARK and _t < SHOW + DARK + AGAIN)
		if _t >= SHOW + DARK + AGAIN:
			_end()
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = rng.randf_range(EVERY.x, EVERY.y)
	if shape == null or shape.venus == null or not player_position.is_valid():
		return
	var at: Vector3 = player_position.call()
	if not at.is_finite():
		return
	var from := spot(shape, at, rng)
	if not from.is_finite():
		return
	flash(from)


## Shows a bolt from `from` now.
func flash(from: Vector3) -> void:
	_end()
	var points := bolt_points(from, rng.randf_range(LENGTH.x, LENGTH.y), rng.randf() * TAU, rng)
	_bolt = MeshInstance3D.new()
	_bolt.name = "Bolt"
	_bolt.mesh = bolt_mesh(points)
	_bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bolt)
	_t = 0.0


## The bolt showing now (null between flashes).
func bolt() -> MeshInstance3D:
	return _bolt


func _end() -> void:
	if _bolt:
		_bolt.queue_free()
		_bolt = null
	_t = -1.0


## Where a flash starts near the child at `child`: NEAR to FAR sideways, a little under the clouds' top there, never
## under a deck or a bridge (INF when no spot was clear).
static func spot(s: SpaceShape, child: Vector3, r: RandomNumberGenerator) -> Vector3:
	for i in TRIES:
		var a := r.randf() * TAU
		var d := r.randf_range(NEAR, FAR)
		var x := floori(child.x + cos(a) * d)
		var z := floori(child.z + sin(a) * d)
		if s.venus.kind_at(x, z) != VenusTerrain.CLOUD:
			continue
		var top := s.venus.cloud_top(x, z)
		return Vector3(x + 0.5, top - r.randi_range(DEPTH.x, DEPTH.y), z + 0.5)
	return Vector3.INF


## A zig-zag of SEGMENTS + 1 points from `from`, `length` long, heading `heading` (radians) sideways and a little down,
## each joint kicked sideways and up or down.
static func bolt_points(from: Vector3, length: float, heading: float, r: RandomNumberGenerator) -> PackedVector3Array:
	var out := PackedVector3Array([from])
	var way := Vector3(cos(heading), -0.35, sin(heading)).normalized()
	var side := Vector3(-way.z, 0.0, way.x)
	var step := length / SEGMENTS
	var at := from
	for i in SEGMENTS:
		at += way * step + side * r.randf_range(-1.2, 1.2) + Vector3(0, r.randf_range(-0.8, 0.5), 0)
		out.append(at)
	return out


## The bolt's mesh: each segment two crossed ribbons (seen from any side), a bright core in a faint glow.
static func bolt_mesh(points: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer: Array in [[GLOW_WIDTH, GLOW], [WIDTH, CORE]]:
		var w: float = layer[0]
		var c: Color = layer[1]
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var along := (b - a).normalized()
			var flat := along.cross(Vector3.UP).normalized()   # a bolt runs mostly sideways: never straight up
			for across: Vector3 in [flat, along.cross(flat).normalized()]:
				var o := across * (w * 0.5)
				for v: Vector3 in [a - o, b - o, b + o, a - o, b + o, a + o]:
					st.set_color(c)
					st.add_vertex(v)
	st.set_material(material())
	return st.commit()


## The night sky's star material settings (SkyCycle: unshaded, see-through vertex colours, never fogged, both sides):
## a shader the warm-up already has.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		SkyCycle._night_material(_material)
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
	return _material
