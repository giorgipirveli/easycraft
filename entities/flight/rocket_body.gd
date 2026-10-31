class_name RocketBody
extends Node3D
## The rocket the child built, flying (owner #79, spec §25.3): one mesh per stage from its blocks (RocketMesh: the
## blocks' own look, a draw call per material), its origin the rocket's axis at its bottom. It burns (the flame: little
## glowing blocks pouring from the lowest stage's bottom, as big and fast as the fire), trails smoke in the air, lets its
## stages go (each falls away and fades), puts its landing legs out, opens its parachute and lets it go, and glows at its
## heat shield. Everything on RocketFlight.ROCKET_LAYER (the inside camera does not see its own rocket). Its looks are
## the game's shared ones (the blocks' pages, Fx's particles, the golem's glow): no new shader.

const FLAME_COLORS: Array[Color] = [Color(1.0, 0.98, 0.78), Color(1.0, 0.78, 0.3), Color(1.0, 0.45, 0.12), Color(0.75, 0.18, 0.08)]
const LEG_COLOR := Color(0.6, 0.62, 0.66)
const CHUTE_COLORS: Array[Color] = [Color("f08a1c"), Color("fff6e8")]
const FALL_SECONDS := 4.0

var rocket := {}
var pivot := Vector3.ZERO
var stages: Array[MeshInstance3D] = []
var dropped := 0
var flame: CPUParticles3D
var trail: CPUParticles3D
var plasma: CPUParticles3D
var legs: Array[Node3D] = []
var chute: Node3D
var heat_shield: MeshInstance3D
var layer_mask := 1

var _height := 1.0
var _bottom := 0.0
var _width := 1.0
var _fire := 0.0
var _legs := 0.0
var _chute := 0.0
var _chute_gone := false
var _chute_fly := 0.0
var _falling: Array = []   # [node, seconds, spin axis, drift]


func setup(r: Dictionary, layer: int) -> void:
	rocket = r
	layer_mask = layer
	pivot = RocketStages.pivot(r.cells)
	var all := RocketStages.bounds(r.cells)
	_width = maxf(maxf(all.size.x, all.size.z), 1.0)
	_measure()
	for i in RocketStages.stage_count(r):
		var m := MeshInstance3D.new()
		m.name = "Stage%d" % i
		m.mesh = RocketMesh.build(RocketStages.stage_cells(r, i), pivot)
		m.layers = layer
		add_child(m)
		stages.append(m)
	_add_flame()
	_add_trail()
	_place_flame()


## The parts needed later (the legs, the parachute, the heat shield): RocketFlight builds them a frame after the rest,
## so a flight's first frame stays short.
func finish_setup() -> void:
	if heat_shield != null:
		return
	_add_legs()
	_add_chute()
	_add_heat()
	_place_flame()


## How tall the rocket that still flies is (m), and its width.
func height() -> float:
	return _height


func width() -> float:
	return _width


## The bottom of what still flies, over the rocket's origin.
func bottom() -> float:
	return _bottom


func _measure() -> void:
	var b := RocketStages.bounds(RocketStages.flying_after(rocket, dropped))
	_height = maxf(b.end.y - pivot.y, 1.0)
	_bottom = b.position.y - pivot.y


## Where the child sits, in this node's space.
func seat() -> Vector3:
	return RocketStages.seat(rocket) - pivot


func set_fire(f: float) -> void:
	_fire = clampf(f, 0.0, 1.0)
	var on := _fire > 0.02
	if flame.emitting != on:
		flame.emitting = on
	flame.speed_scale = 0.7 + 0.6 * _fire
	flame.scale_amount_min = 0.45 + 0.5 * _fire
	flame.scale_amount_max = 0.8 + 0.9 * _fire


## Smoke behind it (only in air).
func set_trail(on: bool) -> void:
	if trail.emitting != on:
		trail.emitting = on


func set_legs(v: float) -> void:
	_legs = clampf(v, 0.0, 1.0)


func set_chute(v: float) -> void:
	if v > 0.0 and _chute_gone:
		return
	if v <= 0.0 and _chute > 0.3 and not _chute_gone:
		_chute_gone = true   # let go: it flies away
	_chute = clampf(v, 0.0, 1.0) if not _chute_gone else _chute


func set_heat(v: float) -> void:
	if heat_shield == null:
		return
	heat_shield.visible = v > 0.02
	heat_shield.scale = Vector3.ONE * lerpf(0.7, 1.15, v)
	var on := v > 0.15
	if plasma.emitting != on:
		plasma.emitting = on


## Lets the lowest stage still attached go: it falls away from the rocket (in `into`, keeping where it is) with a puff.
func drop_next(into: Node3D) -> void:
	if dropped >= stages.size() - 1:
		return
	var m := stages[dropped]
	dropped += 1
	_measure()
	var xf := m.global_transform
	m.get_parent().remove_child(m)
	into.add_child(m)
	m.global_transform = xf
	var down := -global_basis.y.normalized()
	_falling.append([m, 0.0, Vector3(0.3, 0.1, 1.0).normalized(), down * 6.0 + global_basis.x * 1.5])
	var puff := Fx.burst(into, global_position + global_basis.y * (bottom() + 0.1), Color(0.95, 0.95, 0.97), 30, 5.0,
		0.3, 1.0, 0.0, 90.0)
	puff.layers = layer_mask
	_place_flame()


func _process(delta: float) -> void:
	_animate(delta)


func _animate(delta: float) -> void:
	for f: Array in _falling.duplicate():
		var m: MeshInstance3D = f[0]
		f[1] = float(f[1]) + delta
		if not is_instance_valid(m) or float(f[1]) >= FALL_SECONDS:
			if is_instance_valid(m):
				m.queue_free()
			_falling.erase(f)
			continue
		m.global_position += (f[3] as Vector3) * delta * (1.0 + float(f[1]))
		m.rotate(f[2], delta * 0.6)
		m.scale = Vector3.ONE * lerpf(1.0, 0.4, float(f[1]) / FALL_SECONDS)
	var w := width()
	for i in legs.size():
		var leg := legs[i]
		leg.rotation.z = 0.0
		leg.rotation.x = -deg_to_rad(lerpf(160.0, 32.0, _legs))
	if chute:
		if not _chute_gone:
			chute.position = Vector3(0, height() + 7.0, 0)
		if _chute_gone:
			_chute_fly += delta
			chute.position += Vector3(2.0, 9.0, 3.0) * delta
			chute.visible = _chute_fly < 2.0
		else:
			chute.visible = _chute > 0.01
			chute.scale = Vector3(lerpf(0.15, 1.0, _chute), lerpf(0.4, 1.0, _chute), lerpf(0.15, 1.0, _chute)) * maxf(w / 3.0, 1.0)


func _place_flame() -> void:
	var cells := RocketStages.stage_cells(rocket, dropped)
	var nozzles := RocketStages.nozzles(rocket, dropped)
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for c: Vector3i in nozzles:
		lo = lo.min(Vector3(c))
		hi = hi.max(Vector3(c) + Vector3.ONE)
	if nozzles.is_empty():
		var b := RocketStages.bounds(cells)
		lo = b.position
		hi = b.end
	var mid := (lo + hi) * 0.5 - pivot
	flame.position = Vector3(mid.x, lo.y - pivot.y - 0.1, mid.z)
	flame.emission_box_extents = Vector3(maxf((hi.x - lo.x) * 0.35, 0.3), 0.1, maxf((hi.z - lo.z) * 0.35, 0.3))
	trail.position = flame.position + Vector3(0, -1.5, 0)
	if heat_shield:
		heat_shield.position = Vector3(mid.x, bottom() - 0.05, mid.z)
		plasma.position = heat_shield.position


func _add_flame() -> void:
	flame = CPUParticles3D.new()
	flame.name = "Flame"
	flame.layers = layer_mask
	flame.amount = Fx.scaled(48)
	flame.lifetime = 0.35
	flame.local_coords = true
	flame.emitting = false
	flame.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flame.direction = Vector3.DOWN
	flame.spread = 9.0
	flame.initial_velocity_min = 13.0
	flame.initial_velocity_max = 21.0
	flame.gravity = Vector3.ZERO
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.42
	box.material = GolemModels.glow_material()
	flame.mesh = box
	flame.color_ramp = _ramp(FLAME_COLORS)
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.25))
	flame.scale_amount_curve = shrink
	add_child(flame)


func _add_trail() -> void:
	trail = CPUParticles3D.new()
	trail.name = "Trail"
	trail.layers = layer_mask
	trail.amount = Fx.scaled(36)
	trail.lifetime = 2.2
	trail.local_coords = false
	trail.emitting = false
	trail.direction = Vector3.DOWN
	trail.spread = 25.0
	trail.initial_velocity_min = 2.0
	trail.initial_velocity_max = 4.0
	trail.gravity = Vector3(0, 0.6, 0)
	trail.damping_min = 1.0
	trail.damping_max = 2.0
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.9
	box.material = Fx.material()
	trail.mesh = box
	trail.color = Color(0.9, 0.9, 0.92)
	var grow := Curve.new()
	grow.max_value = 3.0
	grow.add_point(Vector2(0.0, 0.6))
	grow.add_point(Vector2(1.0, 2.6))
	trail.scale_amount_curve = grow
	add_child(trail)


## Four struts at the lander's corners: folded up along its sides, then swung out and down to stand on.
func _add_legs() -> void:
	var lander := RocketStages.lander(rocket)
	var b := RocketStages.bounds(lander)
	var hw := maxf(b.size.x, b.size.z) * 0.5
	var y := b.position.y - pivot.y + 1.2
	var strut := BoxMesh.new()
	strut.size = Vector3(0.22, 1.6, 0.22)
	strut.material = Fx.material()
	var foot := BoxMesh.new()
	foot.size = Vector3(0.6, 0.12, 0.6)
	foot.material = Fx.material()
	for corner: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var hinge := Node3D.new()
		hinge.name = "Leg"
		hinge.position = Vector3(corner.x * hw * 0.8, y, corner.y * hw * 0.8)
		hinge.basis = Basis(Vector3.UP, atan2(corner.x, corner.y))   # swings out away from the middle (its +z)
		var arm := Node3D.new()
		hinge.add_child(arm)
		legs.append(arm)
		var s := MeshInstance3D.new()
		s.mesh = strut
		s.position = Vector3(0, -0.8, 0)
		s.layers = layer_mask
		arm.add_child(s)
		var f := MeshInstance3D.new()
		f.mesh = foot
		f.position = Vector3(0, -1.6, 0)
		f.layers = layer_mask
		arm.add_child(f)
		_tint(s, LEG_COLOR)
		_tint(f, LEG_COLOR.darkened(0.2))
		add_child(hinge)


## A striped canopy (both sides drawn) over the lander on four lines.
func _add_chute() -> void:
	chute = Node3D.new()
	chute.name = "Chute"
	chute.visible = false
	var top := height() + 7.0
	chute.position = Vector3(0, top, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gores := 12
	var rings := 4
	for g in gores:
		var col := CHUTE_COLORS[g % 2]
		for r in rings:
			var a0 := TAU * g / gores
			var a1 := TAU * (g + 1) / gores
			var p0 := PI * 0.5 * r / rings
			var p1 := PI * 0.5 * (r + 1) / rings
			var quad: Array[Vector3] = [_dome(a0, p0), _dome(a1, p0), _dome(a1, p1), _dome(a0, p1)]
			var out: Vector3 = ((quad[0] + quad[2]) * 0.5 - Vector3(0, -3.0, 0)).normalized()
			var cw := (quad[1] - quad[0]).cross(quad[2] - quad[0]).dot(out) < 0.0   # clockwise seen from outside
			for side in [1.0, -1.0]:
				st.set_color(col)
				st.set_normal(out * side)
				var order := [0, 1, 2, 0, 2, 3] if (cw == (side > 0.0)) else [0, 2, 1, 0, 3, 2]
				for i: int in order:
					st.add_vertex(quad[i])
	st.set_material(Fx.material())
	var canopy := MeshInstance3D.new()
	canopy.mesh = st.commit()
	canopy.layers = layer_mask
	chute.add_child(canopy)
	var line := BoxMesh.new()
	line.size = Vector3(0.06, 1.0, 0.06)
	line.material = Fx.material()
	for a in 4:
		var rim := _dome(TAU * a / 4.0 + 0.4, PI * 0.5)
		var l := MeshInstance3D.new()
		l.mesh = line
		l.layers = layer_mask
		var from := rim
		var to := Vector3(0, -top + height(), 0)
		l.position = (from + to) * 0.5
		l.scale = Vector3(1, from.distance_to(to), 1)
		l.basis = Basis(Quaternion(Vector3.UP, (from - to).normalized())).scaled(Vector3(1, from.distance_to(to), 1))
		chute.add_child(l)
	add_child(chute)


## A point of the canopy (radius 5, 3 high) at angle `a` round and `p` down from its top.
static func _dome(a: float, p: float) -> Vector3:
	return Vector3(sin(p) * cos(a) * 5.0, cos(p) * 3.0 - 3.0, sin(p) * sin(a) * 5.0)


## The heat shield's glow: a shallow dome under the lander, white-hot in the middle and red at the rim, and plasma
## streaming back past it.
func _add_heat() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := maxf(width() * 0.55, 1.2)
	var n := 16
	var centre := Vector3(0, -r * 0.35, 0)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		st.set_normal(Vector3.DOWN)
		st.set_color(Color(1.0, 0.95, 0.75))
		st.add_vertex(centre)
		st.set_color(Color(1.0, 0.35, 0.1))
		st.add_vertex(p1)
		st.add_vertex(p0)
	st.set_material(GolemModels.glow_material())
	heat_shield = MeshInstance3D.new()
	heat_shield.name = "HeatShield"
	heat_shield.mesh = st.commit()
	heat_shield.layers = layer_mask
	heat_shield.visible = false
	add_child(heat_shield)
	plasma = CPUParticles3D.new()
	plasma.name = "Plasma"
	plasma.layers = layer_mask
	plasma.amount = Fx.scaled(40)
	plasma.lifetime = 0.45
	plasma.local_coords = true
	plasma.emitting = false
	plasma.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	plasma.emission_ring_axis = Vector3.UP
	plasma.emission_ring_radius = r
	plasma.emission_ring_inner_radius = r * 0.7
	plasma.emission_ring_height = 0.1
	plasma.direction = Vector3.UP
	plasma.spread = 6.0
	plasma.initial_velocity_min = 16.0
	plasma.initial_velocity_max = 26.0
	plasma.gravity = Vector3.ZERO
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.3
	box.material = GolemModels.glow_material()
	plasma.mesh = box
	plasma.color_ramp = _ramp([Color(1.0, 0.9, 0.6), Color(1.0, 0.5, 0.15), Color(0.9, 0.25, 0.1)])
	add_child(plasma)


static func _ramp(colors: Array[Color]) -> Gradient:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / maxf(colors.size() - 1, 1))
		cols.append(colors[i])
	g.offsets = offsets
	g.colors = cols
	return g


## A box in one colour: Fx's material takes its colour from the mesh's vertex colours, so the box is copied with them
## (a material per colour would be a new shader setting).
func _tint(m: MeshInstance3D, c: Color) -> void:
	var src := m.mesh as BoxMesh
	var arrays := src.get_mesh_arrays()
	var n: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var cols := PackedColorArray()
	cols.resize(n)
	cols.fill(c)
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, Fx.material())
	m.mesh = mesh
