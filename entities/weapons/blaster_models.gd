class_name BlasterModels
extends RefCounted
## The blasters' looks (M3 Task 14b, spec §13.4): chunky toy blasters in bright colours, every one with an
## orange tip (a toy's sign, never a real-world gun), and their shots. Each is ONE merged, vertex-coloured
## mesh built once with WeaponModels' shared material (no new shader), like every held item. A blaster's
## rarity shows as rarity + 1 light bands along its top (colour is never the only sign, like the tiers).
## Held models have their grip at the origin and point along -Z; shots have their front at the origin and
## trail along +Z (the arrow's way). The bubble shot and the bubbles around trapped monsters are see-through:
## they share the invisibility potion's material (Player.ghost_material), so nothing new is compiled.
## The paint mark over a painted monster shines through fog and darkness: one cached unshaded material with
## fog off (mark_material), compiled once when the world appears (BlasterDirector.prewarm).

const ORANGE := Color("ff7a1a")
const BAND := WeaponModels.TIER_MARK
const PAINT := Color("ff2fa0")
const SNOW := Color("f4fbff")
const CONFETTI: Array[Color] = [Color("ef5350"), Color("ffee58"), Color("66bb6a"), Color("42a5f5"), Color("ab47bc")]

## Shot looks (BlasterDirector's pool).
const DART := &"dart"
const SNOWBALL := &"snowball"
const PAINT_BLOB := &"paint"
const BUBBLE := &"bubble"
const ROCKET := &"rocket"
const GOBLIN_ARROW := &"goblin_arrow"   # the goblin archers' slow arrows

static var _cache := {}
static var _mark_material: StandardMaterial3D


## The held model of a blaster, or null.
static func mesh_for(id: int) -> Mesh:
	if not BlasterRules.is_blaster(id):
		return null
	if not _cache.has(id):
		var parts := _parts(id)
		parts.append_array(bands(id))
		_cache[id] = WeaponModels.build(parts)
	return _cache[id]


## rarity + 1 light bands across the top of the body, from the back.
static func bands(id: int) -> Array:
	var out: Array = []
	var top := _top(id)
	for i in BlasterRules.rarity(id) + 1:
		out.append([Vector3(0, top, -0.02 - i * 0.055), Vector3(0.1, 0.022, 0.028), BAND])
	return out


## The height of the body's top (where the bands sit).
static func _top(id: int) -> float:
	match id:
		ItemIds.SNOWBALL_LAUNCHER:
			return 0.125
		ItemIds.BUBBLE_CANNON:
			return 0.13
		ItemIds.CONFETTI_ROCKET:
			return 0.14
	return 0.115


static func _parts(id: int) -> Array:
	var dark := Color("2b3140")
	match id:
		ItemIds.FOAM_BLASTER:
			var yellow := Color("ffd23f")
			var blue := Color("2f86f0")
			return [
				[Vector3(0, -0.1, 0.05), Vector3(0.075, 0.2, 0.1), blue.darkened(0.3)],     # grip
				[Vector3(0, 0.04, -0.12), Vector3(0.12, 0.14, 0.46), yellow],             # body
				[Vector3(0, -0.02, -0.16), Vector3(0.15, 0.1, 0.13), blue],               # dart drum
				[Vector3(0, 0.05, -0.41), Vector3(0.08, 0.08, 0.14), blue],               # barrel
				[Vector3(0, 0.05, -0.5), Vector3(0.1, 0.1, 0.05), ORANGE],                # the orange tip
				[Vector3(0, -0.07, -0.02), Vector3(0.03, 0.06, 0.03), dark],              # trigger
			]
		ItemIds.SNOWBALL_LAUNCHER:
			var ice := Color("8fd3ff")
			return [
				[Vector3(0, -0.1, 0.05), Vector3(0.075, 0.2, 0.1), Color("3f6fa8")],      # grip
				[Vector3(0, 0.04, -0.14), Vector3(0.14, 0.16, 0.5), ice],                 # body
				[Vector3(0, 0.17, -0.1), Vector3(0.16, 0.1, 0.16), SNOW],                 # hopper of snowballs
				[Vector3(0.03, 0.23, -0.1), Vector3(0.08, 0.06, 0.08), SNOW],
				[Vector3(0, 0.05, -0.43), Vector3(0.12, 0.12, 0.1), ice.darkened(0.15)],  # wide barrel
				[Vector3(0, 0.05, -0.5), Vector3(0.13, 0.13, 0.05), ORANGE],              # the orange tip
				[Vector3(0, -0.07, -0.02), Vector3(0.03, 0.06, 0.03), dark],
			]
		ItemIds.PAINT_SPLATTER:
			var pink := Color("ff9ad5")
			return [
				[Vector3(0, -0.1, 0.05), Vector3(0.075, 0.2, 0.1), Color("7b2f8f")],      # grip
				[Vector3(0, 0.03, -0.12), Vector3(0.1, 0.12, 0.44), Color("7b2f8f")],     # body
				[Vector3(0, 0.15, -0.05), Vector3(0.14, 0.14, 0.18), pink],               # paint tank
				[Vector3(0, 0.15, -0.05), Vector3(0.1, 0.16, 0.1), PAINT],
				[Vector3(0, 0.04, -0.4), Vector3(0.07, 0.07, 0.14), PAINT],               # nozzle
				[Vector3(0, 0.04, -0.49), Vector3(0.09, 0.09, 0.05), ORANGE],             # the orange tip
				[Vector3(0.05, -0.03, -0.3), Vector3(0.02, 0.05, 0.02), PAINT],           # a drip
				[Vector3(0, -0.07, -0.02), Vector3(0.03, 0.06, 0.03), dark],
			]
		ItemIds.BUBBLE_CANNON:
			var aqua := Color("3fd2c7")
			return [
				[Vector3(0, -0.1, 0.05), Vector3(0.075, 0.2, 0.1), aqua.darkened(0.4)],   # grip
				[Vector3(0, 0.04, -0.12), Vector3(0.15, 0.16, 0.42), aqua],               # body
				[Vector3(0, 0.05, -0.38), Vector3(0.18, 0.18, 0.1), Color("bff6ff")],     # bell
				[Vector3(0, 0.05, -0.45), Vector3(0.2, 0.2, 0.05), ORANGE],               # the orange tip
				[Vector3(0, 0.17, -0.02), Vector3(0.09, 0.09, 0.09), Color("dffbff")],    # a soap bubble on top
				[Vector3(0, -0.07, -0.02), Vector3(0.03, 0.06, 0.03), dark],
			]
		ItemIds.CONFETTI_ROCKET:
			var red := Color("e8403a")
			var out: Array = [
				[Vector3(0, -0.1, 0.1), Vector3(0.075, 0.2, 0.1), dark],                  # grip
				[Vector3(0, 0.05, -0.1), Vector3(0.16, 0.16, 0.66), red],                 # tube on the shoulder
				[Vector3(0, 0.05, 0.25), Vector3(0.18, 0.18, 0.06), Color("ffd23f")],     # back ring
				[Vector3(0, 0.05, -0.45), Vector3(0.19, 0.19, 0.06), ORANGE],             # the orange tip
				[Vector3(0, -0.07, 0.05), Vector3(0.03, 0.06, 0.03), dark],
			]
			for i in CONFETTI.size():                                                    # rainbow stripes
				out.append([Vector3(0, -0.035, -0.32 + i * 0.07), Vector3(0.165, 0.02, 0.04), CONFETTI[i]])
			return out
	return []


# --- Shots ---

## The mesh of a shot look (DART, SNOWBALL, PAINT_BLOB, BUBBLE, ROCKET, GOBLIN_ARROW).
static func shot_mesh(look: StringName) -> Mesh:
	if not _cache.has(look):
		_cache[look] = _make_shot(look)
	return _cache[look]


## The look of a blaster's shots.
static func shot_look(blaster: int) -> StringName:
	match blaster:
		ItemIds.SNOWBALL_LAUNCHER:
			return SNOWBALL
		ItemIds.PAINT_SPLATTER:
			return PAINT_BLOB
		ItemIds.BUBBLE_CANNON:
			return BUBBLE
		ItemIds.CONFETTI_ROCKET:
			return ROCKET
	return DART


static func _make_shot(look: StringName) -> Mesh:
	match look:
		SNOWBALL:
			return WeaponModels.build([[Vector3(0, 0, 0.12), Vector3(0.26, 0.26, 0.26), SNOW],
				[Vector3(0.05, 0.06, 0.06), Vector3(0.14, 0.14, 0.14), Color("dcecff")]])
		PAINT_BLOB:
			return WeaponModels.build([[Vector3(0, 0, 0.1), Vector3(0.2, 0.2, 0.2), PAINT],
				[Vector3(0, 0, 0.24), Vector3(0.1, 0.1, 0.12), PAINT.lightened(0.3)]])
		BUBBLE:
			var s := SphereMesh.new()
			s.radius = 0.22
			s.height = 0.44
			s.radial_segments = 12
			s.rings = 6
			s.material = Player.ghost_material()
			return s
		ROCKET:
			var parts: Array = [
				[Vector3(0, 0, 0.18), Vector3(0.11, 0.11, 0.3), Color("e8403a")],         # body
				[Vector3(0, 0, 0.02), Vector3(0.07, 0.07, 0.06), Color("ffd23f")],        # nose
				[Vector3(0, 0, 0.33), Vector3(0.22, 0.03, 0.08), Color("42a5f5")],        # fins
				[Vector3(0, 0, 0.33), Vector3(0.03, 0.22, 0.08), Color("66bb6a")],
				[Vector3(0, 0, 0.4), Vector3(0.08, 0.08, 0.06), ORANGE],                  # flame
			]
			return WeaponModels.build(parts)
		GOBLIN_ARROW:
			var red := Color("ff3b30")
			return WeaponModels.build([
				[Vector3(0, 0, 0.06), Vector3(0.12, 0.12, 0.14), Color("fff6b0")],         # a big bright head
				[Vector3(0, 0, 0.45), Vector3(0.06, 0.06, 0.7), Color("8a5a2e")],          # shaft
				[Vector3(0, 0, 0.78), Vector3(0.26, 0.03, 0.18), red],                     # fletching
				[Vector3(0, 0, 0.78), Vector3(0.03, 0.26, 0.18), red],
			])
	# DART: a foam dart with an orange suction tip
	return WeaponModels.build([[Vector3(0, 0, 0.03), Vector3(0.07, 0.07, 0.06), ORANGE],
		[Vector3(0, 0, 0.17), Vector3(0.05, 0.05, 0.22), Color("2f86f0")],
		[Vector3(0, 0, 0.3), Vector3(0.06, 0.06, 0.04), Color("ffd23f")]])


# --- Marks on monsters ---

## A see-through soap bubble (radius 1: scaled to the monster).
static func bubble_mesh() -> Mesh:
	if not _cache.has(&"bubble_big"):
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 16
		s.rings = 8
		s.material = Player.ghost_material()
		_cache[&"bubble_big"] = s
	return _cache[&"bubble_big"]


## A paint splat over a painted monster's head (faces +Z, turned to the camera by BlasterDirector).
static func paint_mark_mesh() -> Mesh:
	if not _cache.has(&"paint_mark"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(mark_material())
		for b: Array in [[Vector3.ZERO, Vector2(0.34, 0.26)], [Vector3(0.12, 0.1, 0), Vector2(0.14, 0.14)],
				[Vector3(-0.15, -0.08, 0), Vector2(0.12, 0.12)], [Vector3(0.05, -0.2, 0), Vector2(0.06, 0.14)],
				[Vector3(-0.2, 0.12, 0), Vector2(0.07, 0.07)]]:
			_flat(st, b[0], b[1], PAINT)
		_cache[&"paint_mark"] = st.commit()
	return _cache[&"paint_mark"]


## The paint mark's material: unshaded (bright at night), fog off (seen through storms and caves' fog).
static func mark_material() -> StandardMaterial3D:
	if _mark_material == null:
		_mark_material = StandardMaterial3D.new()
		_mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mark_material.vertex_color_use_as_albedo = true
		_mark_material.disable_fog = true
		_mark_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mark_material


static func _flat(st: SurfaceTool, c: Vector3, s: Vector2, color: Color) -> void:
	var h := s * 0.5
	var p := [c + Vector3(-h.x, -h.y, 0), c + Vector3(h.x, -h.y, 0), c + Vector3(h.x, h.y, 0), c + Vector3(-h.x, h.y, 0)]
	st.set_color(color)
	st.set_normal(Vector3.BACK)
	for i: int in [0, 2, 1, 0, 3, 2]:
		st.add_vertex(p[i])
