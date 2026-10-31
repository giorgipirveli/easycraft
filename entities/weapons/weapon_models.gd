class_name WeaponModels
extends RefCounted
## Cheap models for the weapons, tools, arrows and practice targets (M1b Task 11): each is ONE
## merged, vertex-coloured mesh (one draw call, one shared material), built from boxes and discs
## once and cached. Held items have their grip at the origin and point along -Z (forward);
## targets stand on the origin and face -Z; the arrow's tip is at the origin, its shaft along +Z.
## M2 Task 6: the spear, mace and shield, and the tiers. A tier item is its kind's model plus 1-5
## light bands (studs on a shield) that count the tier, one mesh per item, built once; its colour
## comes from one shared material per tier (tier_material), never a material per item.

const BULLSEYE_CENTER := Vector3(0, 1.15, 0)   # middle of the bullseye face, from the target's feet
const DUMMY_CENTER := Vector3(0, 1.15, 0)      # the dummy's chest
const _SEGMENTS := 24

const TIER_MARK := Color("fff4d6")              # the bands that count a tier

static var _cache := {}
static var _material: StandardMaterial3D
static var _tier_materials := {}


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.6
	return _material


## The model of a weapon, tool, shield or target item, or null. A tier item: its kind's model with
## tier + 1 bands.
static func mesh_for(id: int) -> Mesh:
	if BlasterRules.is_blaster(id):
		return BlasterModels.mesh_for(id)   # M3 Task 14b
	if GadgetRules.is_gadget(id):
		return GadgetModels.held(id)   # M3 Task 14a
	if not _cache.has(id):
		var base := WeaponRules.base_of(id)
		var parts := _parts(base)
		var tier := WeaponRules.tier_of(id)
		if not parts.is_empty() and tier >= 0:
			parts.append_array(tier_marks(base, tier))
		_cache[id] = null if parts.is_empty() else build(parts)
	return _cache[id]


## The material of a tier's held models: the M1b one for wood, else a copy in the tier's rarity
## tint (the same shader: only its colour uniforms differ, so nothing new is compiled). One per tier.
static func tier_material(tier: int) -> Material:
	if tier <= WeaponRules.TIER_WOOD:
		return material()
	if not _tier_materials.has(tier):
		var m := material().duplicate() as StandardMaterial3D
		m.albedo_color = ItemRarity.model_tint(ItemRarity.of_tier(tier))
		if tier >= WeaponRules.TIER_CRYSTAL:
			m.metallic = 0.25
			m.roughness = 0.35
		_tier_materials[tier] = m
	return _tier_materials[tier]


## tier + 1 light bands around the handle (studs along the bottom of a shield's face), so the tier
## can be counted without its colour.
static func tier_marks(kind: int, tier: int) -> Array:
	var parts: Array = []
	for i in tier + 1:
		match kind:
			ItemIds.SWORD:          # on the blade, just above the guard
				parts.append([Vector3(0, 0, -0.16 - i * 0.05), Vector3(0.13, 0.05, 0.018), TIER_MARK])
			ItemIds.BOW:            # on the lower limb, next to the grip
				var z := 0.1 + i * 0.04
				var s := -z / 0.5
				parts.append([Vector3(0, -0.16 * (1.0 - s * s) + 0.16, z), Vector3(0.075, 0.075, 0.016), TIER_MARK])
			ItemIds.SHIELD_WOOD:    # studs across the face, below the boss
				parts.append([Vector3((i - tier * 0.5) * 0.06, -0.13, -0.16), Vector3(0.035, 0.035, 0.02), TIER_MARK])
			_:                      # on the handle, between the hand and the head
				parts.append([Vector3(0, 0, -0.12 - i * 0.045), Vector3(0.082, 0.082, 0.018), TIER_MARK])
	return parts


static func arrow() -> Mesh:
	if not _cache.has(&"arrow"):
		var red := Color("e8403a")
		_cache[&"arrow"] = build([
			[Vector3(0, 0, 0.07), Vector3(0.07, 0.07, 0.14), Color("d9dee4")],
			[Vector3(0, 0, 0.42), Vector3(0.04, 0.04, 0.62), Color("c8b28a")],
			[Vector3(0, 0, 0.68), Vector3(0.16, 0.02, 0.14), red],
			[Vector3(0, 0, 0.68), Vector3(0.02, 0.16, 0.14), red],
		])
	return _cache[&"arrow"]


## parts: boxes [center, size, color] or [center, size, color, basis], and discs
## {"center", "rings": [[r_in, r_out, color], ...], "thickness", "back": color} facing -Z.
static func build(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material())
	for p: Variant in parts:
		if p is Dictionary:
			_disc(st, p)
		else:
			var b: Array = p
			_box(st, b[0], b[1], b[2], b[3] if b.size() > 3 else Basis.IDENTITY)
	return st.commit()


static func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color, basis: Basis) -> void:
	var h := size * 0.5
	for axis in 3:
		for s: float in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = s
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := n * h[axis]
			_quad(st, [c - u - v, c + u - v, c + u + v, c - u + v], n, color, center, basis)


## Corners (3 or 4) in order around the face. Godot draws clockwise-wound triangles as front faces.
static func _quad(st: SurfaceTool, corners: Array, n: Vector3, color: Color, offset: Vector3 = Vector3.ZERO, basis: Basis = Basis.IDENTITY) -> void:
	var p: Array[Vector3] = []
	for c: Vector3 in corners:
		p.append(offset + basis * c)
	var normal := (basis * n).normalized()
	var flip := (p[1] - p[0]).cross(p[2] - p[0]).dot(normal) > 0.0
	var order := [0, 1, 2, 0, 2, 3] if p.size() == 4 else [0, 1, 2]
	if flip:
		order = [0, 2, 1, 0, 3, 2] if p.size() == 4 else [0, 2, 1]
	st.set_color(color)
	st.set_normal(normal)
	for i: int in order:
		st.add_vertex(p[i])


static func _disc(st: SurfaceTool, d: Dictionary) -> void:
	var c: Vector3 = d.center
	var half := float(d.thickness) * 0.5
	var outer := 0.0
	for ring: Array in d.rings:
		outer = maxf(outer, ring[1])
		for k in _SEGMENTS:
			var a0 := TAU * k / _SEGMENTS
			var a1 := TAU * (k + 1) / _SEGMENTS
			var r0: float = ring[0]
			var r1: float = ring[1]
			var q := [Vector3(cos(a0) * r0, sin(a0) * r0, -half), Vector3(cos(a0) * r1, sin(a0) * r1, -half),
				Vector3(cos(a1) * r1, sin(a1) * r1, -half), Vector3(cos(a1) * r0, sin(a1) * r0, -half)]
			_quad(st, q, Vector3.FORWARD, ring[2], c)
	for k in _SEGMENTS:
		var a0 := TAU * k / _SEGMENTS
		var a1 := TAU * (k + 1) / _SEGMENTS
		var e0 := Vector3(cos(a0), sin(a0), 0.0) * outer
		var e1 := Vector3(cos(a1), sin(a1), 0.0) * outer
		_quad(st, [Vector3(0, 0, half), e0 + Vector3(0, 0, half), e1 + Vector3(0, 0, half)], Vector3.BACK, d.back, c)
		_quad(st, [e0 + Vector3(0, 0, -half), e1 + Vector3(0, 0, -half), e1 + Vector3(0, 0, half), e0 + Vector3(0, 0, half)],
			Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0.0), d.back, c)


static func _parts(id: int) -> Array:
	var wood := Color("8a5a2e")
	var steel := Color("9aa6b2")
	var bright := Color("e9eef3")
	var gold := Color("f2b632")
	match id:
		ItemIds.SWORD:
			return [
				[Vector3(0, 0, 0.06), Vector3(0.07, 0.07, 0.2), Color("7a4a24")],       # grip
				[Vector3(0, 0, 0.18), Vector3(0.1, 0.1, 0.06), gold],                   # pommel
				[Vector3(0, 0, -0.07), Vector3(0.3, 0.07, 0.07), gold],                 # guard
				[Vector3(0, 0, -0.5), Vector3(0.11, 0.035, 0.8), bright],               # blade
				[Vector3(0, 0.02, -0.46), Vector3(0.03, 0.01, 0.62), steel],            # fuller
				[Vector3(0, 0, -0.94), Vector3(0.06, 0.03, 0.08), Color.WHITE],         # tip
			]
		ItemIds.HAMMER:
			return [
				[Vector3(0, 0, -0.2), Vector3(0.07, 0.07, 0.8), wood],                  # handle
				[Vector3(0, 0, -0.44), Vector3(0.09, 0.09, 0.05), gold],                # band
				[Vector3(0, 0, -0.64), Vector3(0.28, 0.46, 0.3), Color("7d848c")],      # head (strikes with -Y)
				[Vector3(0, -0.24, -0.64), Vector3(0.3, 0.04, 0.32), Color("4c5157")],
				[Vector3(0, 0.24, -0.64), Vector3(0.3, 0.04, 0.32), Color("4c5157")],
			]
		ItemIds.AXE:
			return [
				[Vector3(0, 0, -0.2), Vector3(0.06, 0.06, 0.76), wood],                 # handle
				[Vector3(0, -0.13, -0.5), Vector3(0.04, 0.26, 0.24), Color("8e949b")],  # blade (cuts with -Y)
				[Vector3(0, -0.27, -0.5), Vector3(0.05, 0.05, 0.32), bright],           # edge
				[Vector3(0, 0.05, -0.5), Vector3(0.08, 0.1, 0.12), Color("5f6770")],    # back
			]
		ItemIds.PICKAXE:
			return [
				[Vector3(0, 0, -0.2), Vector3(0.06, 0.06, 0.76), wood],                 # handle
				[Vector3(0, 0.17, -0.56), Vector3(0.07, 0.36, 0.08), steel, Basis(Vector3.RIGHT, 0.3)],
				[Vector3(0, -0.17, -0.56), Vector3(0.07, 0.36, 0.08), steel, Basis(Vector3.RIGHT, -0.3)],
				[Vector3(0, 0, -0.58), Vector3(0.1, 0.1, 0.1), Color("5f6770")],
			]
		ItemIds.BOW:
			return _bow_parts()
		ItemIds.SPEAR:
			return [
				[Vector3(0, 0, -0.35), Vector3(0.05, 0.05, 1.3), wood],                 # shaft (+0.3 .. -1.0)
				[Vector3(0, 0, 0.02), Vector3(0.065, 0.065, 0.2), Color("5a3a1e")],     # grip
				[Vector3(0, 0, -1.02), Vector3(0.075, 0.075, 0.08), Color("5f6770")],   # socket
				[Vector3(0, 0, -1.15), Vector3(0.13, 0.03, 0.2), steel],                # blade
				[Vector3(0, 0.017, -1.15), Vector3(0.06, 0.01, 0.18), bright],          # ridge
				[Vector3(0, 0, -1.29), Vector3(0.07, 0.025, 0.1), bright],              # tip
			]
		ItemIds.MACE:
			var head := Color("7d848c")
			var c := Vector3(0, 0, -0.68)
			return [
				[Vector3(0, 0, -0.24), Vector3(0.06, 0.06, 0.62), wood],                # handle
				[Vector3(0, 0, 0.0), Vector3(0.075, 0.075, 0.16), Color("5a3a1e")],     # grip
				[Vector3(0, 0, -0.5), Vector3(0.085, 0.085, 0.05), gold],               # collar
				[c, Vector3(0.24, 0.24, 0.24), head],                                   # head
				[c, Vector3(0.2, 0.2, 0.28), head.lightened(0.1), Basis(Vector3.FORWARD, PI / 4.0)],
				[c + Vector3(0.15, 0, 0), Vector3(0.1, 0.05, 0.05), bright],            # spikes
				[c + Vector3(-0.15, 0, 0), Vector3(0.1, 0.05, 0.05), bright],
				[c + Vector3(0, 0.15, 0), Vector3(0.05, 0.1, 0.05), bright],
				[c + Vector3(0, -0.15, 0), Vector3(0.05, 0.1, 0.05), bright],
				[c + Vector3(0, 0, -0.15), Vector3(0.05, 0.05, 0.1), bright],
			]
		ItemIds.SHIELD_WOOD:
			return [
				{"center": Vector3(0, 0.05, -0.12), "thickness": 0.05, "back": Color("6e4522"), "rings": [
					[0.0, 0.075, bright], [0.075, 0.26, wood], [0.26, 0.32, steel]]},
				[Vector3(0, 0.05, -0.155), Vector3(0.09, 0.09, 0.03), steel],            # boss
				[Vector3(0, 0.05, -0.08), Vector3(0.05, 0.3, 0.03), Color("5a3a1e")],    # arm strap
			]
		ItemIds.BOOMERANG:
			var orange := Color("f08a1c")
			return [
				[Vector3(0.08, 0, -0.14), Vector3(0.1, 0.04, 0.36), orange, Basis(Vector3.UP, 0.55)],
				[Vector3(0.08, 0, 0.14), Vector3(0.1, 0.04, 0.36), orange, Basis(Vector3.UP, -0.55)],
				[Vector3(0.08, 0.025, -0.14), Vector3(0.04, 0.01, 0.2), Color("3a7be8"), Basis(Vector3.UP, 0.55)],
				[Vector3(0.08, 0.025, 0.14), Vector3(0.04, 0.01, 0.2), Color("3a7be8"), Basis(Vector3.UP, -0.55)],
			]
		ItemIds.DUMMY:
			var straw := Color("e0c38c")
			return [
				[Vector3(0, 0.04, 0), Vector3(0.5, 0.08, 0.5), Color("5a3a1e")],        # foot
				[Vector3(0, 0.45, 0), Vector3(0.12, 0.9, 0.12), Color("6e4522")],       # post
				[DUMMY_CENTER, Vector3(0.5, 0.62, 0.34), straw],                        # sack body
				[Vector3(0, 0.9, 0), Vector3(0.52, 0.06, 0.36), Color("a0622d")],       # rope belt
				[Vector3(0, 1.32, 0), Vector3(1.0, 0.12, 0.12), Color("c8924e")],       # arms
				[Vector3(0, 1.68, 0), Vector3(0.34, 0.34, 0.3), Color("f0dcae")],       # head
				[Vector3(-0.07, 1.72, -0.155), Vector3(0.06, 0.06, 0.02), Color("3b2f2a")],
				[Vector3(0.07, 1.72, -0.155), Vector3(0.06, 0.06, 0.02), Color("3b2f2a")],
				[DUMMY_CENTER + Vector3(0, 0, -0.175), Vector3(0.22, 0.22, 0.02), Color("e8403a")],
				[DUMMY_CENTER + Vector3(0, 0, -0.19), Vector3(0.09, 0.09, 0.02), Color.WHITE],
			]
		ItemIds.BULLSEYE:
			var r := WeaponRules.BULLSEYE_RADIUS
			return [
				[Vector3(-0.38, 0.55, 0.1), Vector3(0.08, 1.1, 0.08), Color("6e4522")],  # legs
				[Vector3(0.38, 0.55, 0.1), Vector3(0.08, 1.1, 0.08), Color("6e4522")],
				[Vector3(0, 0.55, 0.32), Vector3(0.08, 1.15, 0.08), Color("6e4522"), Basis(Vector3.RIGHT, -0.35)],
				{"center": BULLSEYE_CENTER, "thickness": 0.12, "back": Color("e0c38c"), "rings": [
					[0.0, r * 0.2, Color("f7d23e")], [r * 0.2, r * 0.4, Color("e8403a")],
					[r * 0.4, r * 0.6, Color("3a7be8")], [r * 0.6, r * 0.8, Color("2b2f36")],
					[r * 0.8, r, Color("f7f5ef")]]},
			]
	return []


## A bow along Z (vertical when drawn), bulging towards -Y, string on +Y; the grip in the middle.
static func _bow_parts() -> Array:
	var parts: Array = []
	var half := 0.5
	var bulge := 0.16
	var points: Array[Vector3] = []
	for k in 9:
		var s := lerpf(-1.0, 1.0, k / 8.0)
		points.append(Vector3(0, -bulge * (1.0 - s * s) + bulge, -half * s))
	for k in 8:
		var a := points[k]
		var b := points[k + 1]
		parts.append([(a + b) * 0.5, Vector3(0.05, 0.05, a.distance_to(b) + 0.02), Color("a0622d"),
			Basis.looking_at(b - a, Vector3.RIGHT)])
	parts.append([Vector3(0, bulge, 0), Vector3(0.015, 0.015, half * 2.0), Color("f3efe6")])   # string
	parts.append([Vector3.ZERO, Vector3(0.07, 0.07, 0.14), Color("5a3a1e")])                    # grip
	return parts
