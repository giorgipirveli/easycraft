class_name Fx
extends RefCounted
## One-shot particle bursts made of little cubes (block breaks, jump puffs), and the water effects
## (splashes, ripples, bubbles, drips). Self-freeing.
## Every effect shares one material, kept for the whole game: a material per burst freed its shader
## with the last burst, so the next one compiled it again, a 120-147 ms frame on the emulator in the
## REALISTIC style (in BLOCKY the blocky avatar's materials happened to keep that shader alive).

const WATER_DROP := Color(0.78, 0.9, 1.0)
const BUBBLE := Color(0.88, 0.97, 1.0)
const RING := Color(0.93, 0.98, 1.0)
const RING_FADED := Color(0.32, 0.56, 0.8)    # a spreading ripple fades into the water's blue
const RIPPLE_TIME := 1.0
const DRIP_LIFETIME := 0.5

## M5 Task 3: the share of each effect's particles this phone draws (the graphics preset: LOW draws half;
## Game.apply_settings sets it). Never fewer than one.
static var particle_scale := 1.0
static var _material: StandardMaterial3D
static var _meshes := {}          # cube size -> BoxMesh
static var _ring: TorusMesh
static var _ring_grow: Curve
static var _ring_flat: Curve
static var _ring_fade: Gradient


static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 14, speed: float = 3.5,
		size: float = 0.14, lifetime: float = 0.6, gravity: float = 14.0, spread: float = 180.0) -> CPUParticles3D:
	if _too_far(parent, pos):
		return _stand_in()   # M5 Task 2: nobody sees it; the caller can still set it up
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = scaled(amount)
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.mesh = _mesh(size)
	p.color = color
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -gravity, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	calm(p, amount)   # M5 Task 1
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.emitting = true
	_track(p)
	return p


## `amount` particles as this phone draws them (particle_scale), at least one.
static func scaled(amount: int) -> int:
	return maxi(roundi(amount * particle_scale), 1)


static func break_block(parent: Node, block_pos: Vector3i, block_id: int) -> void:
	burst(parent, Vector3(block_pos) + Vector3(0.5, 0.5, 0.5), BlockLibrary.average_color(block_id), 16, 4.0)
	LifeRules.flutter(parent, block_pos, block_id)   # owner #94: a tree's leaves or a flower's petals flutter down


static func jump_puff(parent: Node, feet: Vector3) -> void:
	burst(parent, feet + Vector3(0, 0.1, 0), Color(1, 1, 1, 0.9), 10, 2.5, 0.12, 0.35, 2.0)


# --- Water (M2 Task 14, owner feedback #17) ------------------------------------------------------

## A body hitting the water at `pos` (on the surface): drops fly up, more, higher and bigger the harder
## it came in (strength 0..1, SwimRules.splash_strength), and a ring spreads on the surface.
## size: the body's SizeMagic scale. Swim strokes throw a few drops without a ring.
static func splash(parent: Node, pos: Vector3, strength: float, size: float = 1.0, ring: bool = true) -> void:
	var s := clampf(strength, 0.0, 1.0)
	var drops := burst(parent, pos, WATER_DROP, int(lerpf(6.0, 34.0, s)), lerpf(2.0, 7.5, s) * sqrt(size),
		0.1, lerpf(0.5, 1.0, s), 16.0, 25.0)
	drops.scale_amount_min = lerpf(0.5, 0.8, s) * size
	drops.scale_amount_max = lerpf(0.9, 1.4, s) * size
	if ring:
		ripple(parent, pos, lerpf(0.9, 2.2, s) * size)


## A ring spreading on the water around a swimmer (pos on the surface). One shared ring mesh and
## curves; the ring fades into the water's colour as it spreads.
static func ripple(parent: Node, pos: Vector3, size: float = 1.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 1
	p.lifetime = RIPPLE_TIME
	p.explosiveness = 1.0
	p.mesh = _ring_mesh()
	p.direction = Vector3.UP
	p.spread = 0.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.gravity = Vector3.ZERO
	p.split_scale = true
	p.scale_curve_x = _ring_grow
	p.scale_curve_y = _ring_flat
	p.scale_curve_z = _ring_grow
	p.scale_amount_min = size
	p.scale_amount_max = size
	p.color_ramp = _ring_fade
	parent.add_child(p)
	p.global_position = pos + Vector3(0, 0.03, 0)
	p.finished.connect(p.queue_free)
	p.emitting = true
	_track(p)


## A few bubbles rising from a diver's head.
static func bubbles(parent: Node, pos: Vector3, size: float = 1.0) -> void:
	var p := burst(parent, pos, BUBBLE, 3, 0.5, 0.07, 1.2, -3.0, 70.0)
	p.scale_amount_min = 0.5 * size
	p.scale_amount_max = 1.2 * size


## Drops falling off a body that climbed out of the water, for `seconds`. The drops stay where they
## fall (world space); the emitter follows the body and frees itself.
static func drips(body: Node3D, seconds: float, size: float = 1.0) -> void:
	var p := CPUParticles3D.new()
	p.amount = 10
	p.lifetime = DRIP_LIFETIME
	p.mesh = _mesh(0.05)
	p.color = WATER_DROP
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.25, 0.6, 0.18) * size
	p.position = Vector3(0, 0.9, 0) * size
	p.direction = Vector3.DOWN
	p.spread = 10.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0, -14.0, 0)
	p.scale_amount_min = 0.6 * size
	p.scale_amount_max = 1.0 * size
	body.add_child(p)
	p.emitting = true
	_track(p)
	var t := p.create_tween()
	t.tween_interval(seconds)
	t.tween_callback(func() -> void: p.emitting = false)
	t.tween_interval(DRIP_LIFETIME + 0.1)
	t.tween_callback(p.queue_free)


## The first burst of a session would still compile the shared shader (one 107-127 ms frame on the
## emulator at the first break or jump). One tiny, short burst in the middle of the camera's view,
## sent as the world appears (the camera must be in place, or nothing is drawn), compiles it through
## the same (instanced) drawing path.
static func prewarm(camera: Camera3D) -> void:
	var at := camera.global_position - camera.global_basis.z * 1.5
	burst(camera.get_parent(), at, Color(1, 1, 1), 1, 0.0, 0.01, 0.1, 0.0)


## The one material every burst uses.
static func material() -> StandardMaterial3D:
	_mesh(0.14)
	return _material


static func _mesh(size: float) -> BoxMesh:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true   # each burst's colour (CPUParticles3D.color)
		_material.vertex_color_is_srgb = true         # same look as the old albedo_color
		_material.roughness = 0.8
	if not _meshes.has(size):
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * size
		mesh.material = _material
		_meshes[size] = mesh
	return _meshes[size]


## A thin, low-poly ring (radius about 0.47) lying flat on the water, with the shared material.
static func _ring_mesh() -> TorusMesh:
	if _ring == null:
		_ring = TorusMesh.new()
		_ring.inner_radius = 0.44
		_ring.outer_radius = 0.5
		_ring.rings = 24
		_ring.ring_segments = 4
		_ring.material = material()
		_ring_grow = Curve.new()
		_ring_grow.max_value = 2.0
		_ring_grow.add_point(Vector2(0.0, 0.35))
		_ring_grow.add_point(Vector2(1.0, 1.6), 0.6, 0.6)
		_ring_flat = Curve.new()
		_ring_flat.add_point(Vector2(0.0, 1.0))
		_ring_flat.add_point(Vector2(1.0, 0.4))
		_ring_fade = Gradient.new()
		_ring_fade.set_color(0, RING)
		_ring_fade.set_color(1, RING_FADED)
	return _ring

# --- Spike traps (M2 Task 8) ---------------------------------------------------------------------------

const SPIKE_COLOR := Color(0.86, 0.89, 0.93)

static var _spike: CylinderMesh


## A spike trap at `cell` stabs: nine little spikes shoot up out of its top and sink back (0.3 s). One
## cached cone mesh with the shared material, like every other burst.
static func spikes(parent: Node, cell: Vector3i) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 9
	p.lifetime = 0.3
	p.explosiveness = 1.0
	p.mesh = spike_mesh()
	p.color = SPIKE_COLOR
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	var points := PackedVector3Array()
	for z in 3:
		for x in 3:
			points.append(Vector3((x - 1) * 0.3, 0.0, (z - 1) * 0.3))
	p.emission_points = points
	p.direction = Vector3.UP
	p.spread = 0.0
	p.initial_velocity_min = 3.4
	p.initial_velocity_max = 3.4
	p.gravity = Vector3(0, -24.0, 0)
	parent.add_child(p)
	p.global_position = Vector3(cell) + Vector3(0.5, 1.0, 0.5)
	p.finished.connect(p.queue_free)
	p.emitting = true
	_track(p)
	return p


## The one spike (a four-sided cone) every trap's burst uses.
static func spike_mesh() -> CylinderMesh:
	if _spike == null:
		_spike = CylinderMesh.new()
		_spike.top_radius = 0.0
		_spike.bottom_radius = 0.07
		_spike.height = 0.34
		_spike.radial_segments = 4
		_spike.rings = 0
		_spike.material = material()
	return _spike

# --- M3 Task 10: the Gold Farm's welcome-back coin shower ----------------------------------------------

const COIN_GOLD := Color("ffd23f")
const COIN_SHOWER_MIN := 12
const COIN_SHOWER_MAX := 48

static var _coin: ArrayMesh


## Gold coins rain down around `feet` (the welcome-back: more gold, more coins, never more than
## COIN_SHOWER_MAX). One cached coin (a standing disc that spins about Y) with the shared material.
static func coin_shower(parent: Node, feet: Vector3, gold: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	var pieces := clampi(COIN_SHOWER_MIN + gold / 10, COIN_SHOWER_MIN, COIN_SHOWER_MAX)
	p.amount = scaled(pieces)
	p.lifetime = 1.4
	p.explosiveness = 0.35
	p.mesh = coin_mesh()
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.8, 0.2, 1.8)
	p.direction = Vector3.DOWN
	p.spread = 12.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.gravity = Vector3(0, -7.0, 0)
	p.particle_flag_rotate_y = true
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2
	calm(p, pieces)   # M5 Task 1 (the unscaled amount: calm scales it)
	parent.add_child(p)
	p.global_position = feet + Vector3(0, 4.0, 0)
	p.finished.connect(p.queue_free)
	p.emitting = true
	_track(p)
	return p


## One gold coin standing on its edge (a rim and a raised middle), with the shared material.
static func coin_mesh() -> ArrayMesh:
	if _coin == null:
		_coin = WeaponModels.build([{"center": Vector3.ZERO, "thickness": 0.04,
			"rings": [[0.0, 0.08, COIN_GOLD], [0.08, 0.14, COIN_GOLD.darkened(0.2)]], "back": COIN_GOLD}])
		_coin.surface_set_material(0, material())
	return _coin


## M5 Task 1 (spec §15.1a): with Reduce motion a burst is calmer: half the pieces, slower, no spin (FeelRules). Pooled
## bursts call it before each restart with their own unscaled `amount`, so a change of the setting reaches them too.
## The phone's particle_scale (M5 Task 3's LOW) applies first: both halve.
static func calm(p: CPUParticles3D, amount: int) -> void:
	var reduce := bool(Profile.data.settings.get("reduce_motion", false))
	var n := FeelRules.burst_amount(scaled(amount), reduce)
	if p.amount != n:
		p.amount = n
	p.speed_scale = FeelRules.burst_speed_scale(reduce)
	if reduce:
		p.angular_velocity_min = 0.0
		p.angular_velocity_max = 0.0

# --- M5 Task 2: the particle pass (spec §15.2) ---------------------------------------------------------------

## Never more than this many effects alive at once: a new one ends the oldest early (a night's worth of defeats, a
## boss's win and its fireworks: dozens of emitters in one second before).
const MAX_LIVE := 32
## Bursts farther than this from this device's camera are never made (nobody sees a 0.1 m cube there).
const FAR := 48.0
const WAKE_GOLD := Color("ffe27a")
const STAR_GOLD := Color("ffd23f")
## A golden portal's sparkles (owner #43: gold and the rainbow, never purple swirls).
const PORTAL_COLORS: Array[Color] = [Color("ffe27a"), Color("ff6b6b"), Color("ffb347"), Color("fff176"),
	Color("7ee06b"), Color("5cc8ff"), Color("b388ff")]

## Effects cut short because too many were alive, and bursts skipped because they were too far (tests, diagnostics).
static var cut := 0
static var skipped := 0
static var _live: Array[int] = []   # instance ids, oldest first (freed ones drop out)
static var _star: ArrayMesh
static var _ramps := {}


## How many effects are alive now.
static func live() -> int:
	_prune()
	return _live.size()


## Tests: forget the counters (the effects themselves are the scene's).
static func reset_budget() -> void:
	_live.clear()
	cut = 0
	skipped = 0


static func _prune() -> void:
	var keep: Array[int] = []
	for id in _live:
		var o := instance_from_id(id)
		if o != null and is_instance_valid(o) and not (o as Node).is_queued_for_deletion():
			keep.append(id)
	_live = keep


## P5 (VR draws): how many effects may be alive at once: MAX_LIVE, or in a headset session the VR preset's `fx_live`
## (each burst is a draw of its own: the headset's budget is about 100 a frame).
static func max_live() -> int:
	return int(GraphicsPreset.params("").get("fx_live", MAX_LIVE)) if GraphicsPreset.vr_session else MAX_LIVE


static func _track(p: CPUParticles3D) -> void:
	_prune()
	var cap := max_live()
	while _live.size() >= cap:
		var old := instance_from_id(_live.pop_front()) as Node
		if old:
			old.queue_free()
			cut += 1
	_live.append(p.get_instance_id())


static func _too_far(parent: Node, pos: Vector3) -> bool:
	if parent == null or not parent.is_inside_tree():
		return false
	var cam := parent.get_viewport().get_camera_3d()
	if cam == null or not cam.is_inside_tree() or cam.global_position.distance_to(pos) <= FAR:
		return false
	skipped += 1
	return true


## What a skipped burst gives back: never in the tree, never drawn, gone at the end of the frame; setting it up
## does nothing.
static func _stand_in() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.queue_free()
	return p


## A buddy waking (the wand's magic): a few gold stars float up where it wakes.
static func wake(parent: Node, at: Vector3, size: float = 1.0) -> CPUParticles3D:
	var p := burst(parent, at, WAKE_GOLD, 8, 2.0, 0.16 * size, 0.8, -2.5, 70.0)
	p.mesh = star_mesh()
	return p


## A portal taking someone or opening: rainbow-gold stars in every direction, floating a little.
static func portal(parent: Node, at: Vector3, size: float = 1.0) -> CPUParticles3D:
	var p := burst(parent, at, Color.WHITE, 20, 4.0, 0.16 * size, 0.9, -1.5)
	p.mesh = star_mesh()
	p.color_initial_ramp = _ramp(PORTAL_COLORS)
	return p


## A level-up: gold stars rising in a ring round the child (the banner and the confetti come with it).
static func level_up(parent: Node, feet: Vector3, size: float = 1.0) -> CPUParticles3D:
	var p := burst(parent, feet + Vector3(0, 0.3 * size, 0), STAR_GOLD, 24, 1.2, 0.18 * size, 1.4, -3.0, 15.0)
	p.mesh = star_mesh()
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.8 * size
	p.emission_ring_inner_radius = 0.6 * size
	p.emission_ring_height = 0.1
	p.explosiveness = 0.6
	p.scale_amount_min = 0.7 * size
	p.scale_amount_max = 1.2 * size
	return p


## Many-coloured confetti in one emitter (each cube one of `colors`), instead of one emitter per colour.
static func confetti(parent: Node, pos: Vector3, colors: Array[Color], amount: int = 32, speed: float = 5.0,
		size: float = 0.1, lifetime: float = 0.9, gravity: float = 7.0) -> CPUParticles3D:
	var p := burst(parent, pos, Color.WHITE, amount, speed, size, lifetime, gravity)
	p.color_initial_ramp = _ramp(colors)
	return p


## A hard-stepped gradient of `colors`, one per list (every particle picks one colour, never a blend).
static func _ramp(colors: Array[Color]) -> Gradient:
	var key := str(colors)
	if not _ramps.has(key):
		var g := Gradient.new()
		g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		var offsets := PackedFloat32Array()
		var cols := PackedColorArray()
		for i in colors.size():
			offsets.append(float(i) / colors.size())
			cols.append(colors[i])
		g.offsets = offsets
		g.colors = cols
		_ramps[key] = g
	return _ramps[key]


## A flat five-pointed star (0.5 across), a face each way so it shows while it spins; the shared material.
static func star_mesh() -> ArrayMesh:
	if _star == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rim := PackedVector3Array()
		for i in 10:
			var a := PI * 0.5 + TAU * i / 10.0
			var r := 0.25 if i % 2 == 0 else 0.11
			rim.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
		for side in [1.0, -1.0]:
			st.set_normal(Vector3(0, 0, side))
			for i in 10:
				var a := rim[i]
				var b := rim[(i + 1) % 10]
				if side > 0.0:
					st.add_vertex(Vector3.ZERO)
					st.add_vertex(b)
					st.add_vertex(a)
				else:
					st.add_vertex(Vector3.ZERO)
					st.add_vertex(a)
					st.add_vertex(b)
		st.set_material(material())
		_star = st.commit()
	return _star
