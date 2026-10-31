class_name LeafGarden
extends LeafRoom
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5 steps 1 and 10, §3.11; picture 01-garden-before-after): the
## garden terrace in its own place far above the world (like G0's arena), the child's sunflower in a terracotta pot. The
## hook: the sunflower droops in the heat, its soil cracked and pale, the watering can glowing; it still droops when
## watered (the soil darkens). The answer, after the voyage: in the evening light it stands tall, its bud opens petal by
## petal and a bee lands. Two block scales by the pot (gold blocks for the plant's weight, brown for the soil's) show the
## plant got heavier and the soil didn't (van Helmont, honestly: LeafProgress gives the blocks). Professor Hoot sits on
## the fence. Targets: the can (the hands lift it in VR), the soil (it pours there), the leaf (the dive starts there);
## views: GARDEN (flat, over the child's shoulder) and its VR stand in front of the pot.
## B2: the desert's hook (§3.5b, `plant` "cactus"): Hoot's cactus in a pot of dry sand, no can (no "can" or "soil"
## target: the sand is dry); its green stem is the "leaf" target (cacti build sugar in their stems); its answer is the
## big white night flower (CactusModel). The can pours by itself (`set_pour`, flat) or is lifted and tilted (VR, the
## host moves `can_node()`); the answer opens the flower slowly (`set_bloom`).

const GARDEN := "garden"
const POT_AT := Vector3(0, 0, 0)
const POT_HEIGHT := 0.46
const CAN_AT := Vector3(0.52, 0.34, 0.6)
## The can waits on a low stone by the pot (in VR the hands reach it without kneeling).
const STONE_AT := Vector3(0.52, 0, 0.6)
const SCALES_AT := Vector3(-0.78, 0, 0.36)
const FENCE_Z := -1.5
const GRASS := Color("74c34f")
const GRASS_LIGHT := Color("9ad86a")
const POT := Color("d8743c")
const SOIL_DRY := Color("b49a72")
const SOIL_WET := Color("5a3f2c")
const SAND := Color("e2c48a")
## The can's rose (where the water comes out), in the can's space.
const ROSE := Vector3(0.47, 0.335, 0)
const GOLD_BLOCK := Color("ffc73a")
const SOIL_BLOCK := Color("8a5a33")
const MAX_BLOCKS := 14

var plant_name := "sunflower"
var sunflower: SunflowerModel
var cactus: CactusModel
var key_light: DirectionalLight3D
var stage := LeafProgress.DROOP
var watered := false
var plant_blocks := LeafProgress.START_BLOCKS
var soil_blocks := LeafProgress.SOIL_BLOCKS
var _soil_dry: MeshInstance3D
var _soil_wet: MeshInstance3D
var _blocks: MultiMeshInstance3D
var _bee: MeshInstance3D
var _can: Node3D
var _water: MeshInstance3D
var _hoot: Node3D
var _sky_dome: MeshInstance3D
var _evening := false
var _bee_t := 0.0


func _init(garden_plant: String = "sunflower") -> void:
	super()
	name = "LeafGarden"
	plant_name = garden_plant
	start_view = GARDEN


func build() -> void:
	env = LeafKit.environment(Color("8ccdf5"), Color("e9f2e0"), 0.6)
	key_light = LeafKit.sun(self, -48.0, 32.0, Color("fff2d6"), 1.25)
	_build_sky()
	_build_terrace()
	_build_props()
	if plant_name == "cactus":
		cactus = CactusModel.new()
		cactus.position = POT_AT + Vector3(0, POT_HEIGHT - 0.04, 0)
		add_child(cactus)
	else:
		sunflower = SunflowerModel.new()
		sunflower.position = POT_AT + Vector3(0, POT_HEIGHT - 0.04, 0)
		add_child(sunflower)
	_build_bee()
	_build_hoot()
	_targets_and_views()
	show_stage(stage, false)


## The garden's moment: DROOP (the hook: drooping, the can glowing) or BLOOM (standing, open, the bee, the evening);
## `watered` darkens the soil.
func show_stage(new_stage: String, now_watered: bool) -> void:
	stage = new_stage
	watered = now_watered or new_stage != LeafProgress.DROOP
	if sunflower == null and cactus == null:
		return
	var bloom := new_stage == LeafProgress.BLOOM
	if sunflower:
		sunflower.set_pose(0.0 if new_stage != LeafProgress.DROOP else 1.0, 1.0 if bloom else 0.0)
	else:
		cactus.set_pose(1.0 if bloom else 0.0)
	_soil_dry.visible = not watered or cactus != null
	_soil_wet.visible = watered and cactus == null
	_bee.visible = bloom and sunflower != null
	set_evening(bloom)
	set_blocks(plant_blocks + (LeafProgress.GROWTH if bloom else 0), soil_blocks)
	if has_target("leaf") and sunflower:
		target_node("leaf").position = sunflower.leaf_tip()


## The world's answer, slowly (0-1): the plant stands, then opens (the sunflower's petals; the cactus's white flower).
func set_bloom(p: float) -> void:
	var b := clampf(p, 0.0, 1.0)
	if sunflower:
		sunflower.set_pose(0.0, b)
		_bee.visible = b > 0.85
	elif cactus:
		cactus.set_pose(b)


## The can pours by itself (flat, 0-1): it rises from its stone to over the pot and tips its rose down, the water falls
## on the soil from half way.
func set_pour(p: float) -> void:
	if _can == null:
		return
	var k := clampf(p, 0.0, 1.0)
	var lift := smoothstep(0.0, 0.45, k) * (1.0 - smoothstep(0.85, 1.0, k))
	var over := POT_AT + Vector3(-0.22, POT_HEIGHT + 0.42, 0.18)
	_can.position = CAN_AT.lerp(over, lift)
	_can.rotation = Vector3(0, lerpf(-0.45, -PI * 0.5 - 0.3, lift), lerpf(0.0, -0.75, smoothstep(0.3, 0.6, k) * lift))
	if _water:
		_water.visible = k > 0.45 and k < 0.9
		_water.global_position = _can.to_global(ROSE)


## The can (VR: the hands lift it; the host moves it and says when it pours), or null for a garden without one.
func can_node() -> Node3D:
	return _can


## Puts the can back on its stone.
func can_home() -> void:
	if _can:
		_can.position = CAN_AT
		_can.rotation = Vector3(0, -0.45, 0)
		if _water:
			_water.visible = false


## The can's rose is over the soil and tipped down (VR's pour).
func can_pours_on_soil() -> bool:
	if _can == null:
		return false
	var rose := _can.to_global(ROSE)
	var soil := to_global(POT_AT + Vector3(0, POT_HEIGHT, 0))
	var spout := (_can.global_basis * Vector3(0.6, 0.4, 0)).normalized()   # the spout, tipped down to pour
	return Vector2(rose.x - soil.x, rose.z - soil.z).length() < 0.32 * global_basis.get_scale().x and rose.y > soil.y \
		and spout.y < -0.15


## The scales' blocks: the plant's gold, the soil's brown.
func set_blocks(plant: int, soil: int) -> void:
	for k in MAX_BLOCKS * 2:
		_blocks.multimesh.set_instance_transform(k, LeafKit.hidden())
	for k in mini(plant, MAX_BLOCKS):
		var at := SCALES_AT + Vector3(0, 0.13 + k * 0.075, 0)
		_blocks.multimesh.set_instance_transform(k, Transform3D(Basis(Vector3.UP, 0.04 * sin(k * 2.1)), at))
		_blocks.multimesh.set_instance_color(k, GOLD_BLOCK.lerp(Color("ffe08a"), 0.25 if k >= plant - LeafProgress.GROWTH
			and stage == LeafProgress.BLOOM else 0.0))
	for k in mini(soil, MAX_BLOCKS):
		var at := SCALES_AT + Vector3(0.3, 0.13 + k * 0.075, 0)
		_blocks.multimesh.set_instance_transform(MAX_BLOCKS + k, Transform3D(Basis(Vector3.UP, 0.05 * cos(k * 1.7)), at))
		_blocks.multimesh.set_instance_color(MAX_BLOCKS + k, SOIL_BLOCK)


## The evening light of the bloom (warm, low), or the hot noon of the hook.
func set_evening(on: bool) -> void:
	_evening = on
	key_light.rotation_degrees = Vector3(-24.0 if on else -52.0, 36.0 if on else 30.0, 0)
	key_light.light_color = Color("ffd2a0") if on else Color("fff6e6")
	key_light.light_energy = 1.05 if on else 1.3
	env.ambient_light_color = Color("f2d8c6") if on else Color("e8f2e2")
	env.ambient_light_energy = 0.55 if on else 0.62
	_tint_sky(Color("6f8fd8") if on else Color("5cb4f2"), Color("ffcfa6") if on else Color("e6f6ff"))


func _process(delta: float) -> void:
	super._process(delta)
	if _bee and _bee.visible:
		_bee_t += delta
		var head := sunflower.position + sunflower.head_position() if sunflower else Vector3.ZERO
		_bee.position = head + Vector3(0.12 + 0.04 * sin(_bee_t * 3.1), 0.16 + 0.03 * sin(_bee_t * 5.3), 0.1)


func _build_sky() -> void:
	var m := LeafKit.Mesher.new()
	var first := m.count()
	var seg := 32
	var rings := 12
	for r in rings + 1:
		var phi := PI * 0.62 * r / rings
		for k in seg + 1:
			var th := TAU * k / seg
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			m._add(dir * 40.0, -dir, Color.WHITE)
	m._grid(first, rings + 1, seg + 1, true)
	_sky_dome = LeafKit.mesh(self, "Sky", m.commit(), LeafKit.glow())
	var c := LeafKit.Mesher.new()
	for cloud: Array in [[Vector3(-14, 7, -24), 1.0], [Vector3(16, 9, -26), 0.8], [Vector3(-26, 5, -6), 0.7],
			[Vector3(24, 6, 4), 0.75]]:
		var at: Vector3 = cloud[0]
		var s := float(cloud[1])
		for b: Array in [[0.0, 0.0, 0.0, 3.0], [2.8, -0.3, 0.5, 2.3], [-2.7, -0.4, -0.2, 2.2], [1.0, 1.0, -0.3, 2.0]]:
			c.ball(Transform3D(Basis().scaled(Vector3(1, 0.6, 1)), at + Vector3(b[0], b[1], b[2]) * s), float(b[3]) * s,
				Color.WHITE, Color("e2e9f0"), 12, 7)
	LeafKit.mesh(self, "Clouds", c.commit(), LeafKit.glow())


var _sky_tint := []


func _tint_sky(top: Color, low: Color) -> void:
	if _sky_dome == null or (_sky_tint.size() == 2 and (_sky_tint[0] as Color).is_equal_approx(top)
			and (_sky_tint[1] as Color).is_equal_approx(low)):
		return
	_sky_tint = [top, low]
	var arr := (_sky_dome.mesh as ArrayMesh).surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cols := PackedColorArray()
	cols.resize(verts.size())
	for i in verts.size():
		cols[i] = low.lerp(top, sqrt(clampf(verts[i].y / 40.0, 0.0, 1.0)))
	arr[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_sky_dome.mesh = m


func _build_terrace() -> void:
	var m := LeafKit.Mesher.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# The floating island: a flat lawn, a darker rim, earth layers below tapering to a point, rounded stones at the edge.
	m.disc(Transform3D(Basis(), Vector3(0, 0.0, -0.2)), 4.4, GRASS_LIGHT, GRASS, 48, 0.02)
	for k in 9:   # soft patches in the lawn
		var th := rng.randf_range(0, TAU)
		var r := rng.randf_range(1.0, 3.6)
		m.disc(Transform3D(Basis(), Vector3(cos(th) * r, 0.004, sin(th) * r - 0.2)), rng.randf_range(0.5, 0.9),
			GRASS_LIGHT.lightened(0.06), GRASS_LIGHT, 14, 0.004)
	m.tube(Vector3(0, -0.005, -0.2), Vector3(0, -0.12, -0.2), 4.4, 4.38, GRASS.darkened(0.12), GRASS.darkened(0.2), 48, false)
	m.tube(Vector3(0, -0.12, -0.2), Vector3(0, -0.6, -0.2), 4.38, 4.0, Color("9a7348"), Color("86633d"), 48, false)
	m.tube(Vector3(0, -0.6, -0.2), Vector3(0, -1.7, -0.2), 4.0, 2.2, Color("86633d"), Color("6e5341"), 48, false)
	m.tube(Vector3(0, -1.7, -0.2), Vector3(0, -3.3, -0.2), 2.2, 0.14, Color("6e5341"), Color("5c473a"), 48, false)
	for k in 20:
		var th := TAU * k / 20.0 + rng.randf_range(-0.08, 0.08)
		var at := Vector3(cos(th) * 4.25, -0.02, sin(th) * 4.25 - 0.2)
		var r := rng.randf_range(0.14, 0.26)
		m.ball(Transform3D(Basis().scaled(Vector3(1.2, 0.7, 1.0)), at), r, Color("b9b4a6"), Color("8e897d"), 10, 6, 0.08,
			float(k))
	# A few daisies, away from the pot.
	for k in 7:
		var th := rng.randf_range(0, TAU)
		var r := rng.randf_range(1.3, 3.6)
		var at := Vector3(cos(th) * r, 0.0, sin(th) * r - 0.2)
		if at.distance_to(POT_AT) < 0.9:
			continue
		m.tube(at, at + Vector3(0, 0.11, 0), 0.006, 0.005, GRASS.darkened(0.1), GRASS, 4, false)
		for p in 7:
			var a := TAU * p / 7.0
			m.ball(Transform3D(Basis(), at + Vector3(cos(a) * 0.028, 0.115, sin(a) * 0.028)), 0.017, Color.WHITE,
				Color("e8eef2"), 5, 3)
		m.ball(Transform3D(Basis(), at + Vector3(0, 0.12, 0)), 0.015, Color("ffd84a"), Color("f0b020"), 5, 3)
	LeafKit.mesh(self, "Terrace", m.commit(), LeafKit.lit())


func _build_props() -> void:
	var m := LeafKit.Mesher.new()
	# The terracotta pot: a tapered body, a rim, a dark inside.
	m.tube(POT_AT, POT_AT + Vector3(0, POT_HEIGHT - 0.06, 0), 0.22, 0.3, POT.darkened(0.12), POT, 22, true)
	m.tube(POT_AT + Vector3(0, POT_HEIGHT - 0.08, 0), POT_AT + Vector3(0, POT_HEIGHT, 0), 0.34, 0.34, POT.lightened(0.08),
		POT.lightened(0.12), 22, true)
	if plant_name != "cactus":   # the can's stone (the desert has no can: the sand is dry)
		m.tube(STONE_AT, STONE_AT + Vector3(0, 0.32, 0), 0.2, 0.17, Color("9a958a"), Color("bdb7aa"), 14, true)
	# The scales: a little board with two stone pedestals, each with a plate.
	m.box(Transform3D(Basis(), SCALES_AT + Vector3(0.15, 0.02, 0)), Vector3(0.62, 0.04, 0.3), Color("a58560"), Color("bf9c74"))
	for k in 2:
		var at := SCALES_AT + Vector3(0.3 * k, 0.04, 0)
		m.tube(at, at + Vector3(0, 0.06, 0), 0.08, 0.065, Color("9aa3ad"), Color("b6bfc8"), 12, true)
		m.tube(at + Vector3(0, 0.06, 0), at + Vector3(0, 0.085, 0), 0.11, 0.11, Color("c9d0d6"), Color("dfe5ea"), 14, true)
	# The fence: posts and two rails.
	for k in range(-4, 5):
		var x := k * 0.42
		m.box(Transform3D(Basis(), Vector3(x, 0.38, FENCE_Z)), Vector3(0.08, 0.76, 0.08), Color("b07a45"), Color("c99560"))
		m.box(Transform3D(Basis(), Vector3(x, 0.8, FENCE_Z)), Vector3(0.1, 0.06, 0.1), Color("c99560"), Color("d8a670"))
	for y: float in [0.3, 0.6]:
		m.box(Transform3D(Basis(), Vector3(0, y, FENCE_Z + 0.06)), Vector3(3.5, 0.07, 0.04), Color("a8743f"), Color("bf8b55"))
	LeafKit.mesh(self, "Props", m.commit(), LeafKit.lit())
	var dry := LeafKit.Mesher.new()
	var dry_colour := SAND if plant_name == "cactus" else SOIL_DRY
	dry.disc(Transform3D(Basis(), POT_AT + Vector3(0, POT_HEIGHT - 0.035, 0)), 0.31, dry_colour.lightened(0.06), dry_colour,
		22, 0.02)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for k in 7:   # cracks in the dry soil
		var th := rng.randf_range(0, TAU)
		var a := POT_AT + Vector3(0, POT_HEIGHT - 0.012, 0) + Vector3(cos(th), 0, sin(th)) * 0.05
		var b := a + Vector3(cos(th + rng.randf_range(-0.4, 0.4)), 0, sin(th + rng.randf_range(-0.4, 0.4))) * 0.22
		dry.quad(a, b - a, Vector3(0, 0, 0.012).rotated(Vector3.UP, th), Color("6e5a40"), Color("8a7352"))
	_soil_dry = LeafKit.mesh(self, "SoilDry", dry.commit(), LeafKit.lit())
	var wet := LeafKit.Mesher.new()
	wet.disc(Transform3D(Basis(), POT_AT + Vector3(0, POT_HEIGHT - 0.03, 0)), 0.31, SOIL_WET.lightened(0.08), SOIL_WET, 22,
		0.03)
	_soil_wet = LeafKit.mesh(self, "SoilWet", wet.commit(), LeafKit.lit())
	var block := LeafKit.Mesher.new()
	block.box(Transform3D(), Vector3(0.12, 0.07, 0.12), Color(0.86, 0.86, 0.86), Color.WHITE)
	_blocks = LeafKit.multimesh(self, "Blocks", block.commit(), LeafKit.lit(), MAX_BLOCKS * 2,
		AABB(Vector3(-2, -0.2, -2), Vector3(4, 3, 4)))
	if plant_name == "cactus":
		return
	_can = Node3D.new()
	_can.name = "Can"
	_can.position = CAN_AT
	_can.rotation.y = -0.45
	add_child(_can)
	var c := LeafKit.Mesher.new()
	var tin := Color("4ea7dc")
	var dark := tin.darkened(0.22)
	# The watering can: an oval body, a rim, a long spout rising forward to its rose, the handle arching over the top.
	c.tube(Vector3.ZERO, Vector3(0, 0.26, 0), 0.14, 0.13, dark, tin, 22, true)
	c.tube(Vector3(0, 0.26, 0), Vector3(0, 0.285, 0), 0.105, 0.11, tin.lightened(0.1), tin.lightened(0.2), 22, true)
	c.tube(Vector3(0.0, 0.25, 0), Vector3(0.0, 0.252, 0), 0.08, 0.08, Color("1d3e55"), Color("1d3e55"), 16, true)
	c.tube(Vector3(0.1, 0.05, 0), Vector3(0.42, 0.3, 0), 0.032, 0.022, tin, tin.lightened(0.12), 10, false)
	c.tube(Vector3(0.41, 0.29, 0), Vector3(0.47, 0.335, 0), 0.026, 0.06, tin.lightened(0.1), tin.lightened(0.3), 14, true)
	var arc_from := Vector3(-0.11, 0.24, 0)
	for k in 10:
		var a0 := PI * k / 10.0
		var a1 := PI * (k + 1) / 10.0
		var p0 := Vector3(-cos(a0) * 0.11, 0.26 + sin(a0) * 0.13, 0)
		var p1 := Vector3(-cos(a1) * 0.11, 0.26 + sin(a1) * 0.13, 0)
		c.tube(p0, p1, 0.016, 0.016, tin.darkened(0.08), tin.darkened(0.08), 8, false)
	c.tube(Vector3(-0.14, 0.2, 0), Vector3(-0.21, 0.16, 0), 0.016, 0.016, tin.darkened(0.08), tin.darkened(0.08), 8, false)
	c.tube(Vector3(-0.21, 0.16, 0), Vector3(-0.14, 0.06, 0), 0.016, 0.016, tin.darkened(0.08), tin.darkened(0.08), 8, false)
	LeafKit.mesh(_can, "Body", c.commit(), LeafKit.lit())
	var w := LeafKit.Mesher.new()   # the water from the rose: a few falling drops, one draw
	for k in 7:
		w.ball(Transform3D(Basis(), Vector3(0.02 * sin(k * 2.3), -0.06 - 0.05 * k, 0.02 * cos(k * 1.7))), 0.016 - 0.001 * k,
			Color("bfe8ff"), Color("6cc2f2"), 6, 4)
	_water = LeafKit.mesh(self, "Water", w.commit(), LeafKit.glow())
	_water.visible = false


func _build_bee() -> void:
	var m := LeafKit.Mesher.new()
	var yellow := Color("ffcf2e")
	var black := Color("2a2420")
	m.ball(Transform3D(Basis().scaled(Vector3(0.8, 0.8, 1.15)), Vector3.ZERO), 0.045, yellow, yellow.darkened(0.2), 12, 8)
	for z: float in [-0.012, 0.022]:
		m.tube(Vector3(0, 0, z - 0.008), Vector3(0, 0, z + 0.008), 0.039, 0.038, black, black, 12, false)
	m.ball(Transform3D(Basis(), Vector3(0, 0.005, 0.055)), 0.026, black.lightened(0.1), black, 10, 6)
	for side: float in [-1.0, 1.0]:
		m.ball(Transform3D(Basis(Vector3.FORWARD, side * 0.5).scaled(Vector3(0.45, 0.06, 1.0)),
			Vector3(side * 0.04, 0.035, -0.005)), 0.05, Color("f4fbff"), Color("d8e8f2"), 8, 4)
	_bee = LeafKit.mesh(self, "Bee", m.commit(), LeafKit.lit())
	_bee.visible = false


func _build_hoot() -> void:
	_hoot = LeafKit.hoot(self, Vector3(0.84, 0.83, FENCE_Z + 0.02), -0.3, 0.62)


func _targets_and_views() -> void:
	add_view(GARDEN, Vector3(0.5, 1.55, 2.85), Vector3(-0.08, 0.68, -0.1), Vector3(0.05, 0, 0.82), 0.0)
	if cactus:
		var stem := add_spot_target("leaf", cactus, cactus.stem_point(), 0.2)
		stem.name = "T_leaf"
		add_flat(GARDEN, ["leaf"])
		add_hand("leaf", GARDEN)
		return
	var middle := Node3D.new()
	middle.name = "Middle"
	middle.position = Vector3(0, 0.15, 0)
	_can.add_child(middle)
	add_target("can", middle, 0.26)
	add_spot_target("soil", self, POT_AT + Vector3(0, POT_HEIGHT, 0), 0.3)
	var leaf := add_spot_target("leaf", sunflower, sunflower.leaf_tip(), 0.2)
	leaf.name = "T_leaf"
	add_flat(GARDEN, ["can", "soil", "leaf"])
	add_hand("can", GARDEN)
	add_hand("leaf", GARDEN)
