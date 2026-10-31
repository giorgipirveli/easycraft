class_name TreasureModels
extends RefCounted
## Shared models of the treasure pack's things (owner feedback #42): a friendly ghost, a pot of gold, a
## loot cart's wheels, a well's bucket and the rainbow's arch. Made once (box-built, vertex-coloured, like
## InteractableModels) and used by every instance: nothing is made per event.

const GHOST := Color("f4f7ff")
const GHOST_SHADE := Color("d6def7")
const INK := Color("2a2230")
const CHEEK := Color("ff9fc2")
const POT := Color("2b2b33")
const POT_RIM := Color("45454f")
## The rainbow's bands, outside in (red to violet).
const BANDS: Array[Color] = [Color("ff4b4b"), Color("ff9a3c"), Color("ffe14a"), Color("5fd35b"), Color("4aa3ff"),
	Color("9b6bff")]
const BAND_WIDTH := 0.9
const ARCH_SEGMENTS := 48

static var _meshes := {}
static var _ghost_material: StandardMaterial3D
static var _rainbow_material: StandardMaterial3D


## A friendly ghost: a round white body with a wavy hem, two little arms, big eyes, pink cheeks and a smile
## (faces -Z). Drawn a little see-through.
static func ghost() -> ArrayMesh:
	if not _meshes.has("ghost"):
		_meshes["ghost"] = InteractableModels._build([
			[Vector3(0, 0.75, 0), Vector3(0.62, 0.7, 0.55), GHOST],
			[Vector3(0, 1.15, 0), Vector3(0.5, 0.2, 0.46), GHOST],
			[Vector3(0, 1.28, 0), Vector3(0.34, 0.1, 0.32), GHOST],
			[Vector3(-0.2, 0.36, 0), Vector3(0.18, 0.14, 0.5), GHOST_SHADE],    # a wavy hem
			[Vector3(0.02, 0.33, 0), Vector3(0.16, 0.12, 0.5), GHOST_SHADE],
			[Vector3(0.22, 0.37, 0), Vector3(0.16, 0.14, 0.5), GHOST_SHADE],
			[Vector3(-0.38, 0.8, -0.04), Vector3(0.14, 0.12, 0.14), GHOST],      # little arms
			[Vector3(0.38, 0.86, -0.04), Vector3(0.14, 0.12, 0.14), GHOST],
			[Vector3(-0.12, 0.98, -0.28), Vector3(0.12, 0.16, 0.02), INK],        # eyes
			[Vector3(0.12, 0.98, -0.28), Vector3(0.12, 0.16, 0.02), INK],
			[Vector3(-0.1, 1.02, -0.29), Vector3(0.04, 0.05, 0.01), Color.WHITE],
			[Vector3(0.14, 1.02, -0.29), Vector3(0.04, 0.05, 0.01), Color.WHITE],
			[Vector3(-0.22, 0.86, -0.28), Vector3(0.08, 0.05, 0.02), CHEEK],      # cheeks
			[Vector3(0.22, 0.86, -0.28), Vector3(0.08, 0.05, 0.02), CHEEK],
			[Vector3(0, 0.82, -0.285), Vector3(0.14, 0.04, 0.01), INK],           # a smile
			[Vector3(-0.07, 0.84, -0.285), Vector3(0.03, 0.04, 0.01), INK],
			[Vector3(0.07, 0.84, -0.285), Vector3(0.03, 0.04, 0.01), INK],
		], ghost_material())
	return _meshes["ghost"]


static func ghost_material() -> StandardMaterial3D:
	if _ghost_material == null:
		_ghost_material = StandardMaterial3D.new()
		_ghost_material.vertex_color_use_as_albedo = true
		_ghost_material.vertex_color_is_srgb = true
		_ghost_material.albedo_color = Color(1, 1, 1, 0.82)
		_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _ghost_material


## A pot of gold: a round black pot heaped with gold coins.
static func pot() -> ArrayMesh:
	if not _meshes.has("pot"):
		var g := InteractableModels.GOLD
		var gl := InteractableModels.GOLD_LIGHT
		_meshes["pot"] = InteractableModels._build([
			[Vector3(0, 0.3, 0), Vector3(0.7, 0.5, 0.7), POT],
			[Vector3(0, 0.3, 0), Vector3(0.8, 0.36, 0.56), POT],
			[Vector3(0, 0.3, 0), Vector3(0.56, 0.36, 0.8), POT],
			[Vector3(0, 0.58, 0), Vector3(0.66, 0.08, 0.66), POT_RIM],
			[Vector3(0, 0.66, 0), Vector3(0.56, 0.12, 0.56), g],                  # the heap of gold
			[Vector3(0, 0.76, 0), Vector3(0.36, 0.1, 0.36), gl],
			[Vector3(0.08, 0.84, -0.04), Vector3(0.16, 0.06, 0.16), g],
			[Vector3(0.3, 0.62, -0.32), Vector3(0.12, 0.12, 0.03), gl],           # coins spilling out
			[Vector3(-0.42, 0.04, -0.2), Vector3(0.14, 0.03, 0.14), g],
			[Vector3(0.4, 0.04, 0.26), Vector3(0.14, 0.03, 0.14), gl],
			[Vector3(-0.22, 0.02, 0.34), Vector3(0.1, 0.03, 0.1), g],
		])
	return _meshes["pot"]


## A loot cart's wheels and frame, under a chest (its front faces -Z).
static func cart() -> ArrayMesh:
	if not _meshes.has("cart"):
		var iron := Color("5c5f66")
		var dark := Color("2f3136")
		_meshes["cart"] = InteractableModels._build([
			[Vector3(0, 0.03, 0), Vector3(0.9, 0.06, 0.6), iron],                  # the frame
			[Vector3(-0.47, 0.0, -0.22), Vector3(0.06, 0.26, 0.26), dark],         # four wheels
			[Vector3(0.47, 0.0, -0.22), Vector3(0.06, 0.26, 0.26), dark],
			[Vector3(-0.47, 0.0, 0.22), Vector3(0.06, 0.26, 0.26), dark],
			[Vector3(0.47, 0.0, 0.22), Vector3(0.06, 0.26, 0.26), dark],
			[Vector3(-0.5, 0.0, -0.22), Vector3(0.02, 0.08, 0.08), iron],          # hubs
			[Vector3(0.5, 0.0, -0.22), Vector3(0.02, 0.08, 0.08), iron],
			[Vector3(-0.5, 0.0, 0.22), Vector3(0.02, 0.08, 0.08), iron],
			[Vector3(0.5, 0.0, 0.22), Vector3(0.02, 0.08, 0.08), iron],
		])
	return _meshes["cart"]


## A wooden bucket on a rope (hangs under a wishing well's roof).
static func bucket() -> ArrayMesh:
	if not _meshes.has("bucket"):
		_meshes["bucket"] = InteractableModels._build([
			[Vector3(0, 0, 0), Vector3(0.36, 0.3, 0.36), InteractableModels.WOOD],
			[Vector3(0, 0.1, 0), Vector3(0.4, 0.05, 0.4), Color("5c5f66")],
			[Vector3(0, 0.45, 0), Vector3(0.03, 0.6, 0.03), Color("d8c49a")],
		])
	return _meshes["bucket"]


## The rainbow: six bands in a half circle from its foot at (0, 0, 0) to its other foot at (span, 0, 0),
## in the XY plane, seen from both sides.
static func rainbow(span: float) -> ArrayMesh:
	var key := "rainbow_%d" % roundi(span)
	if not _meshes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var r0 := span * 0.5
		var c := Vector3(r0, 0, 0)
		for b in BANDS.size():
			var outer := r0 + BAND_WIDTH * (BANDS.size() * 0.5 - b)
			var inner := outer - BAND_WIDTH
			for i in ARCH_SEGMENTS:
				var a0 := PI * i / ARCH_SEGMENTS
				var a1 := PI * (i + 1) / ARCH_SEGMENTS
				var p := [c + Vector3(cos(a0), sin(a0), 0) * outer, c + Vector3(cos(a1), sin(a1), 0) * outer,
					c + Vector3(cos(a1), sin(a1), 0) * inner, c + Vector3(cos(a0), sin(a0), 0) * inner]
				for k in [0, 1, 2, 0, 2, 3]:
					st.set_color(BANDS[b])
					st.set_normal(Vector3.BACK)
					st.add_vertex(p[k])
		st.set_material(rainbow_material())
		_meshes[key] = st.commit()
	return _meshes[key]


static func rainbow_material() -> StandardMaterial3D:
	if _rainbow_material == null:
		_rainbow_material = StandardMaterial3D.new()
		_rainbow_material.vertex_color_use_as_albedo = true
		_rainbow_material.vertex_color_is_srgb = true
		_rainbow_material.albedo_color = Color(1, 1, 1, 0.55)
		_rainbow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_rainbow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_rainbow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _rainbow_material


## A picture tile standing upright (the pictures over a vault's levers); material: Pictures.material(id).
static func picture_sign() -> QuadMesh:
	if not _meshes.has("sign"):
		var q := QuadMesh.new()
		q.size = Vector2(0.8, 0.8)
		_meshes["sign"] = q
	return _meshes["sign"]


## Extra parts a chest of the pack wears: a loot cart's wheels.
static func dress(chest: Node3D, chest_kind: StringName) -> void:
	if chest_kind == &"cart":
		var wheels := MeshInstance3D.new()
		wheels.mesh = cart()
		wheels.position = Vector3(0, 0.1, 0)
		chest.add_child(wheels)
