class_name BlockLibrary
extends RefCounted
## Builds the voxel model library from BlockIds. Model index == block id.

const ATLAS := preload("res://data/blocks/atlas.png")
const ATLAS_TILES := Vector2i(8, 8)
## The REALISTIC style: same tile layout, CC0 photo textures (tools/make_realistic_atlas.py).
## Loaded only when that style is chosen (they are big).
const REALISTIC_ALBEDO := "res://data/blocks/realistic_albedo.png"
const REALISTIC_NORMAL := "res://data/blocks/realistic_normal.png"
const WATER_WAVES := preload("res://data/blocks/water_waves.png")
const WATER_SHADER := preload("res://shaders/water.gdshader")
## The visuals brief (docs/devlog/parts/visuals.md): leaves and plants move in the wind (set_sway, sway_material).
const SWAY_SHADER := preload("res://world/look/sway.gdshader")

## Per block: [top, side, bottom] tile coordinates in the atlas.
const TILES := {
	BlockIds.GRASS: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	BlockIds.DIRT: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0)],
	BlockIds.STONE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0)],
	BlockIds.SAND: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0)],
	BlockIds.LOG: [Vector2i(6, 0), Vector2i(5, 0), Vector2i(6, 0)],
	BlockIds.PLANKS: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0)],
	BlockIds.LEAVES: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1)],
	BlockIds.GLASS: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
	BlockIds.BRICK: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1)],
	BlockIds.LIGHT: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1)],
	BlockIds.WATER: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1)],
	BlockIds.RED: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1)],
	BlockIds.YELLOW: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1)],
	BlockIds.GREEN: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1)],
	BlockIds.BLUE: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2)],
	BlockIds.PURPLE: [Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2)],
	BlockIds.DEEPSTONE: [Vector2i(2, 2), Vector2i(2, 2), Vector2i(2, 2)],
	BlockIds.BEDROCK: [Vector2i(3, 2), Vector2i(3, 2), Vector2i(3, 2)],
	BlockIds.COAL: [Vector2i(4, 2), Vector2i(4, 2), Vector2i(4, 2)],
	BlockIds.IRON: [Vector2i(5, 2), Vector2i(5, 2), Vector2i(5, 2)],
	BlockIds.GOLD: [Vector2i(6, 2), Vector2i(6, 2), Vector2i(6, 2)],
	BlockIds.DIAMOND: [Vector2i(7, 2), Vector2i(7, 2), Vector2i(7, 2)],
	BlockIds.CRYSTAL: [Vector2i(6, 3), Vector2i(6, 3), Vector2i(6, 3)],
	BlockIds.BED: [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)],
	# M2 Task 8: doors (planks on top and below), the open door's frame (cut out), the spike trap, the
	# lantern (glows).
	BlockIds.DOOR: [Vector2i(7, 0), Vector2i(3, 4), Vector2i(7, 0)],
	BlockIds.DOOR_OPEN: [Vector2i(5, 4), Vector2i(5, 4), Vector2i(5, 4)],
	BlockIds.SPIKE_TRAP: [Vector2i(6, 4), Vector2i(7, 4), Vector2i(6, 4)],
	BlockIds.LANTERN: [Vector2i(4, 4), Vector2i(7, 3), Vector2i(4, 4)],
	# Hiding spots (M2 Task 5): a round shrub with berries, a hooped barrel, a wardrobe with air slits.
	BlockIds.BUSH: [Vector2i(1, 6), Vector2i(0, 6), Vector2i(1, 6)],
	BlockIds.BARREL: [Vector2i(3, 6), Vector2i(2, 6), Vector2i(3, 6)],
	BlockIds.CLOSET: [Vector2i(5, 6), Vector2i(4, 6), Vector2i(5, 6)],
	# Secrets and treasures (M2 Task 16).
	BlockIds.FAKE_WALL: [Vector2i(6, 6), Vector2i(6, 6), Vector2i(6, 6)],
	BlockIds.PRESSURE_PLATE: [Vector2i(7, 6), Vector2i(0, 7), Vector2i(3, 0)],
	BlockIds.TROPHY: [Vector2i(2, 7), Vector2i(1, 7), Vector2i(2, 7)],
	BlockIds.GOLD_LAMP: [Vector2i(3, 7), Vector2i(3, 7), Vector2i(3, 7)],
	# M3 Task 6 placeholders until M3 Task 1's pages draw a spring top and an arrow top: glowing
	# two-tone blocks, green on purple (jump) and yellow on blue (speed), stone underneath.
	BlockIds.JUMP_PAD: [Vector2i(7, 1), Vector2i(1, 2), Vector2i(3, 0)],
	BlockIds.SPEED_PAD: [Vector2i(6, 1), Vector2i(0, 2), Vector2i(3, 0)],
}
## A pressure plate's height (the player stands on it; its side face shows the tile's bottom 2 rows).
const PLATE_HEIGHT := 0.125

## Different transparency indices keep faces between see-through blocks visible.
const TRANSPARENCY := {BlockIds.LEAVES: 1, BlockIds.GLASS: 2, BlockIds.WATER: 3}


# --- Block atlas pages (M3 Task 1) ---
# Page 0 is the atlas above (every id below FIRST_PAGED_ID). Each later range of IDS_PER_PAGE ids
# (desert 64-79, frost 80-95; items own 100-175, so candy 176-191, smart and game blocks 192-207,
# portals/pads/lab 208-223, the Dragon Realm 224-239 (owner 39), paint 240-255) gets its own 8 x 8 page — a pixel
# atlas and its realistic twin — and its own shared, long-lived materials: a chunk draws one call per page it uses. Pages are registered by the
# universes and systems that own them (register_page), so worlds made before pages look the same.

const PAGE_0_FILES := ["res://data/blocks/atlas.png", REALISTIC_ALBEDO, REALISTIC_NORMAL]
const FIRST_PAGED_ID := 64
const IDS_PER_PAGE := 16

## page -> {"files": [pixel, realistic albedo, realistic normal], "tiles": {id: [top, side, bottom, kind?, extras?]}}
## (kind: &"opaque" by default, or &"cutout" / &"glow"; &"pass" is a cut-out block you walk through, M3 Task 7;
## extras (M3 Task 2): {"walk_through": true} for a block bodies pass through, {"transparency": n} for
## see-through blocks whose faces show next to others; owner #45b: {"cross": true} two crossed pictures,
## {"height": h} a lower cube; spec §21c: {"culls": true} a cut-out hiding the faces between two of it, like glass;
## the Glow Caves: {"still": true} crossed pictures that never sway (stone), {"hang": true} pictures that reach the cell's
## top instead of standing on its floor: a stalactite hangs from the block above).
static var _pages := {}
static var _page_materials := {}   # page (>= 1) -> {"opaque", "cutout", "glow"}


## The pages of the universes and systems that own them, registered as this class loads (M3 Task 2:
## the desert's page 1; M3 Task 3: Frostpeak's page 2), so every library, icon and break particle has them.
static func _static_init() -> void:
	DesertBlocks.register()
	FrostBlocks.register()
	CandyBlocks.register()   # M3 Task 4: the Candy Kingdom's page 8
	DragonBlocks.register()   # owner 39: the Dragon Realm's page 11
	PortalPage.register()   # page 10 (portals, the crafting table and the furnace): icons before any world
	PaintPage.register()   # M3 Task 8: page 12, the painted blocks
	MeadowsBlocks.register()   # owner #45b: the wild meadows' page 13 (a child carries its blocks anywhere)
	TinyPage.register()   # M3 Task 21c: page 14, the pumpkin, the jack-o-lantern, the snowman's head, the cheese
	MoonBlocks.register()   # owner #55: the Moon's page 15
	BoingBlocks.register()   # owner #55: Planet Boing's page 16
	RainbowBlocks.register()   # owner #55: Rainbow Planet's page 17
	MarsBlocks.register()   # cosmos (spec §21b.2): Mars's page 18
	LabPage.register()   # spec §23: the Science Lab's page 19 (the lab bench)
	EuropaBlocks.register()   # cosmos (spec §21b.2): Europa's page 20
	IoBlocks.register()   # cosmos (spec §21b.2): Io's page 21
	TitanBlocks.register()   # cosmos (spec §21b.2): Titan's page 29 (past the items' ids 400-511)
	MercuryBlocks.register()   # cosmos (spec §21b.2): Mercury's page 30
	VenusBlocks.register()   # cosmos (spec §21b.2): Venus's cloud city's page 38
	RingsBlocks.register()   # cosmos (spec §21b.2): Saturn's rings' page 40 (39 is the riches of the Moon and Mars)
	PlutoBlocks.register()   # cosmos (spec §21b.2): Pluto's page 41
	TritonBlocks.register()   # cosmos (spec §21b.2): Triton's page 42
	GanymedeBlocks.register()   # cosmos (spec §21b.2): Ganymede's page 43
	MusicPage.register()   # owner #110 (VR round 4): the music blocks' page 44 (the xylophone, the bongos)
	GlowBlocks.register()   # universe 6: the Glow Caves' page 45
	RocketPage.register()   # spec §21d (missions): the rocket parts and the launch pad, page 32 (31 is the domes')
	ProspectPage.register()   # spec §26 (prospecting): the riches of the Earth, page 35
	ProspectSpacePage.register()   # spec §26.5 (prospecting): the riches of the Moon and Mars, page 39
	ColonyBlocks.register()   # spec §21c: the colonies under domes on the Moon and Mars, page 31
	WondersBlocks.register()   # owner #78 (spec §24): the world's wonders, pages 33-34


static func page_of(id: int) -> int:
	return 0 if id < FIRST_PAGED_ID else 1 + (id - FIRST_PAGED_ID) / IDS_PER_PAGE


static func register_page(page: int, files: Array, tiles: Dictionary) -> void:
	_pages[page] = {"files": files, "tiles": tiles}
	_page_materials.erase(page)
	_forget_twins(page)


static func unregister_page(page: int) -> void:
	_pages.erase(page)
	_page_materials.erase(page)
	_forget_twins(page)


## M7: the realistic twins (albedo, normal) of page 0 and every registered page: only the REALISTIC style loads them
## (in a browser they come later, RealisticPack).
static func realistic_files() -> Array[String]:
	var out: Array[String] = [PAGE_0_FILES[1], PAGE_0_FILES[2]]
	for page: int in _pages:
		out.append_array([_pages[page].files[1], _pages[page].files[2]])
	return out


## The shared material of `kind` (&"opaque", &"cutout", &"glow") for blocks on `page`.
static func page_material(page: int, kind: StringName) -> BaseMaterial3D:
	if _materials.is_empty():
		_create_materials()
	if page == 0:
		return _materials[String(kind)]
	if not _page_materials.has(page):
		var files: Array = _pages[page].files
		var opaque := _material(load(files[0]))
		var cutout := _material(load(files[0]))
		cutout.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		cutout.alpha_scissor_threshold = 0.5
		cutout.cull_mode = BaseMaterial3D.CULL_DISABLED
		var glow := _material(load(files[0]))
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_page_materials[page] = {"opaque": opaque, "cutout": cutout, "glow": glow, "sway": _sway_material(false),
			"sway_rooted": _sway_material(true)}
		_style_page(page)
	return _page_materials[page][String(kind)]


## The visuals brief: the sway material of `page`: its leaves (whole blocks move), or `rooted` its crossed plants
## (flowers, wheat: the tops move, the feet stay).
static func sway_material(page: int, rooted: bool) -> ShaderMaterial:
	if _materials.is_empty():
		_create_materials()
	var key := "sway_rooted" if rooted else "sway"
	if page == 0:
		return _materials[key]
	page_material(page, &"opaque")   # makes the page's materials
	return _page_materials[page][key]


## The material of a page's block from its tile entry [top, side, bottom, kind?, extras?]: its kind's (a walked-through
## cut-out, &"pass", is a cut-out), or (the visuals brief) while they sway (set_sway: HIGH) the sway material: plants
## (extras "cross") sway at the top, leaves (extras "sway") move whole.
static func block_material(page: int, t: Array) -> Material:
	var extras: Dictionary = t[4] if t.size() > 4 and t[4] is Dictionary else {}
	if _sway_on and extras.get("cross", false) and not extras.get("still", false):
		return sway_material(page, true)
	if _sway_on and extras.get("sway", false):
		return sway_material(page, false)
	var kind: StringName = t[3] if t.size() > 3 else &"opaque"
	return page_material(page, &"cutout" if kind == &"pass" else kind)


## A block's [top, side, bottom] tiles on its page ([] for a block without any).
static func tiles_of(id: int) -> Array:
	var page := page_of(id)
	if page == 0:
		return TILES.get(id, [])
	return (_pages[page].tiles.get(id, []) as Array).slice(0, 3) if _pages.has(page) else []


## The pixel atlas of the page a block is on (its icon and break particles come from it).
static func pixel_atlas_of(id: int) -> Texture2D:
	var page := page_of(id)
	return ATLAS if page == 0 or not _pages.has(page) else load(_pages[page].files[0])


## A registered page's blocks, each with its page's material.
static func _page_models(models: Array) -> void:
	for page: int in _pages:
		var tiles: Dictionary = _pages[page].tiles
		for id: int in tiles:
			var t: Array = tiles[id]
			var extras: Dictionary = t[4] if t.size() > 4 and t[4] is Dictionary else {}
			var m: VoxelBlockyModel = _cross_model(t[1], extras.get("hang", false)) if extras.get("cross", false) \
				else _cube_model(t, extras)
			var kind: StringName = t[3] if t.size() > 3 else &"opaque"
			m.set_material_override(0, block_material(page, t))
			if kind == &"cutout" or kind == &"pass":
				m.culls_neighbors = bool(extras.get("culls", false))   # spec §21c: the domes' glass is one sheet
			m.transparency_index = int(extras.get("transparency", 0))
			# walked through like the bush: an open powered door or a coin (M3 Task 7), a desert block (M3 Task 2)
			if kind == &"pass" or extras.get("walk_through", false):
				m.collision_aabbs = []
				m.set_mesh_collision_enabled(0, false)
			m.resource_name = BlockIds.display_name(id)
			if id >= models.size():
				models.resize(id + 1)
			models[id] = m


## A page block's cube: [top, side, bottom] tiles; extras "height" (owner #45b: the lily pad) makes it lower.
static func _cube_model(t: Array, extras: Dictionary) -> VoxelBlockyModelCube:
	var m := VoxelBlockyModelCube.new()
	m.atlas_size_in_tiles = ATLAS_TILES
	m.set_tile(VoxelBlockyModel.SIDE_POSITIVE_Y, t[0])
	m.set_tile(VoxelBlockyModel.SIDE_NEGATIVE_Y, t[2])
	for side in [VoxelBlockyModel.SIDE_POSITIVE_X, VoxelBlockyModel.SIDE_NEGATIVE_X,
			VoxelBlockyModel.SIDE_POSITIVE_Z, VoxelBlockyModel.SIDE_NEGATIVE_Z]:
		m.set_tile(side, t[1])
	if extras.has("height"):
		m.height = clampf(float(extras.height), 0.0625, 1.0)
	return m


static var _cross_meshes := {}   # [tile, hang] -> ArrayMesh, shared by every library


## Owner #45b: two pictures crossed along the cell's diagonals (flowers, wheat), from `tile` of the block's
## page. Drawn from both sides (the page's cut-out material draws both faces), never solid. `hang` (the Glow Caves'
## stalactites): the pictures reach the cell's top, not its floor.
static func _cross_model(tile: Vector2i, hang: bool = false) -> VoxelBlockyModelMesh:
	var key := [tile, hang]
	if not _cross_meshes.has(key):
		var uv0 := Vector2(tile) / Vector2(ATLAS_TILES)
		var uv1 := Vector2(tile + Vector2i.ONE) / Vector2(ATLAS_TILES)
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		var inset := 0.1
		for diag: Array in [[Vector3(inset, 0, inset), Vector3(1 - inset, 0, 1 - inset)],
				[Vector3(1 - inset, 0, inset), Vector3(inset, 0, 1 - inset)]]:
			var a: Vector3 = diag[0] + (Vector3.UP * 0.1 if hang else Vector3.ZERO)
			var b: Vector3 = diag[1] + (Vector3.UP * 0.1 if hang else Vector3.ZERO)
			var n := (b - a).cross(Vector3.UP).normalized()
			var base := verts.size()
			verts.append_array([a, b, b + Vector3.UP * 0.9, a + Vector3.UP * 0.9])
			uvs.append_array([Vector2(uv0.x, uv1.y), Vector2(uv1.x, uv1.y), Vector2(uv1.x, uv0.y), uv0])
			for i in 4:
				normals.append(n)
			indices.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_cross_meshes[key] = mesh
	var m := VoxelBlockyModelMesh.new()
	m.mesh = _cross_meshes[key]
	m.collision_aabbs = []
	m.set_mesh_collision_enabled(0, false)
	return m


## The current graphics style (GraphicsPreset.STYLES).
static var style := "blocky"
## The block materials, created once and shared by every library, block mesh and living buddy, so
## set_style() restyles everything at once without remeshing.
static var _materials := {}


static func build() -> VoxelBlockyLibrary:
	PortalPage.register()   # M3 Task 5: page 10 (portal frame and core), in every world
	SmartPage.register()    # M3 Task 7: page 9 (smart blocks and Game Blocks), in every world
	PaintPage.register()    # M3 Task 8: page 12 (the painted blocks), in every world
	if _materials.is_empty():
		_create_materials()
	var opaque: StandardMaterial3D = _materials.opaque
	var cutout: StandardMaterial3D = _materials.cutout
	var water: ShaderMaterial = _materials.water
	var glow: StandardMaterial3D = _materials.glow

	var models: Array = []
	models.resize(BlockIds.COUNT)
	_page_models(models)   # M3 Task 1: blocks on later pages
	models[BlockIds.AIR] = VoxelBlockyModelEmpty.new()
	for id: int in TILES:
		var m := VoxelBlockyModelCube.new()
		m.atlas_size_in_tiles = ATLAS_TILES
		var tiles: Array = TILES[id]
		m.set_tile(VoxelBlockyModel.SIDE_POSITIVE_Y, tiles[0])
		m.set_tile(VoxelBlockyModel.SIDE_NEGATIVE_Y, tiles[2])
		for side in [VoxelBlockyModel.SIDE_POSITIVE_X, VoxelBlockyModel.SIDE_NEGATIVE_X,
				VoxelBlockyModel.SIDE_POSITIVE_Z, VoxelBlockyModel.SIDE_NEGATIVE_Z]:
			m.set_tile(side, tiles[1])
		m.transparency_index = TRANSPARENCY.get(id, 0)
		if id == BlockIds.BED:
			m.height = BedRules.TOP   # half height; collision follows
		elif id == BlockIds.PRESSURE_PLATE:
			m.height = PLATE_HEIGHT
		match id:
			BlockIds.LEAVES:
				m.set_material_override(0, _materials.sway if _sway_on else cutout)   # the visuals brief: HIGH sways
				m.culls_neighbors = false
			BlockIds.GLASS:
				m.set_material_override(0, cutout)
			BlockIds.WATER:
				m.set_material_override(0, water)
				m.collision_aabbs = []
				m.set_mesh_collision_enabled(0, false)   # no physics surface: bodies swim in it (like open doors)
			BlockIds.DOOR_OPEN, BlockIds.BUSH:
				# an open door is a frame (M2 Task 8); a bush is leafy (it sways like leaves)
				m.set_material_override(0, _materials.sway if id == BlockIds.BUSH and _sway_on else cutout)
				m.collision_aabbs = []   # walk-through (BlockIds.NON_SOLID) for Voxel Tools' own box queries
				m.set_mesh_collision_enabled(0, false)   # ... and for the terrain's physics (M2 Task 8)
				m.culls_neighbors = false
			BlockIds.LIGHT, BlockIds.CRYSTAL, BlockIds.GOLD_LAMP, BlockIds.JUMP_PAD, BlockIds.SPEED_PAD, BlockIds.LANTERN:
				m.set_material_override(0, glow)
			_:
				m.set_material_override(0, opaque)
		m.resource_name = BlockIds.display_name(id)
		models[id] = m
	for id in models.size():   # ids no block owns yet (BlockIds.is_valid refuses them)
		if models[id] == null:
			models[id] = VoxelBlockyModelEmpty.new()
	var lib := VoxelBlockyLibrary.new()
	lib.models = models
	lib.bake()
	return lib


static var _colors := {}


## Average color of a block (opaque), used for break particles. Grass uses its green top tile;
## every other block its side tile.
static func average_color(id: int) -> Color:
	if _colors.has(id):
		return _colors[id]
	var page := page_of(id)
	var tiles: Array = TILES.get(id, []) if page == 0 else (_pages[page].tiles.get(id, []) if _pages.has(page) else [])
	if tiles.is_empty():
		return Color.WHITE
	var tile: Vector2i = tiles[0] if id == BlockIds.GRASS else tiles[1]
	var img := ATLAS.get_image() if page == 0 else (load(_pages[page].files[0]) as Texture2D).get_image()
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in 16:
		for x in 16:
			var c := img.get_pixel(tile.x * 16 + x, tile.y * 16 + y)
			if c.a > 0.1:
				sum += c
				n += 1
	var avg := Color(sum.r / n, sum.g / n, sum.b / n, 1.0) if n > 0 else Color.WHITE
	_colors[id] = avg
	return avg


## Switches every block between the pixel-art atlas and the realistic textures (instant). M7: REALISTIC before its
## pictures are in (a browser before the realistic pack, RealisticPack) keeps the pixel pictures: `style` says what the
## blocks show; the saved choice stays, and the worlds that want REALISTIC call this again when the pack lands.
static func set_style(new_style: String) -> void:
	style = new_style if GraphicsPreset.STYLES.has(new_style) else "blocky"
	if style == "realistic" and not RealisticPack.present():
		style = "blocky"
	if _materials.is_empty():
		_create_materials()
	var realistic := style == "realistic"
	var albedo: Texture2D = load(REALISTIC_ALBEDO) if realistic else ATLAS
	var normal: Texture2D = load(REALISTIC_NORMAL) if realistic else null
	for key: String in ["opaque", "cutout", "glow"]:
		_look(_materials[key], key, realistic, albedo, normal)
	for key: String in ["sway", "sway_rooted"]:
		_look_sway(_materials[key], realistic, ATLAS, albedo, normal)
	(_materials.water as ShaderMaterial).set_shader_parameter("realistic", realistic)
	for page: int in _page_materials:
		_style_page(page)


## A page's materials in the current style: its pixel atlas, or its realistic albedo and normal map.
static func _style_page(page: int) -> void:
	var files: Array = _pages[page].files
	var realistic := style == "realistic" and RealisticPack.file_present(files[1]) and RealisticPack.file_present(files[2])
	var albedo: Texture2D = load(files[1] if realistic else files[0])
	for key: String in ["opaque", "cutout", "glow"]:
		_look(_page_materials[page][key], key, realistic, albedo, load(files[2]) if realistic and key != "glow" else null)
	for key: String in ["sway", "sway_rooted"]:
		_look_sway(_page_materials[page][key], realistic, load(files[0]), albedo, load(files[2]) if realistic else null)


## One block material of `kind` ("opaque", "cutout", "glow") in a style: its picture and what the style changes.
static func _look(m: StandardMaterial3D, kind: String, realistic: bool, albedo: Texture2D, normal: Texture2D) -> void:
	m.albedo_texture = albedo
	m.uv1_scale = page_uv_scale(albedo) if realistic else Vector3.ONE
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if realistic \
		else BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.normal_enabled = realistic and kind != "glow"
	m.normal_texture = normal if kind != "glow" else null
	m.roughness = 0.85 if realistic else 1.0

# --- The visuals brief: leaves and plants that sway (world/look/sway.gdshader) -----------------------------------

## Whether libraries built from now on give leaves and plants the sway material (GraphicsPreset.sways: HIGH, not with
## Reduce motion). Only HIGH: on Vulkan's Mobile renderer any custom cut-out shader drew the leaves about twice as dear
## as StandardMaterial3D's cut-out (measured in a cave under a forest: +9-10 ms of this PC's GPU; the sway's own vertex
## work was nothing), so MEDIUM and LOW keep the plain cut-out. A library is built once (WorldService.library()): the
## world after a change shows it (WorldService.apply_graphics drops the old library).
static var _sway_on := false
static var _sway := 1.0   # the shader's knob: 0 holds them still without a new library


## Returns whether it changed (a new library is then needed for it to show).
static func set_sway(on: bool) -> bool:
	var changed := on != _sway_on
	_sway_on = on
	_sway = 1.0 if on else 0.0
	if _materials.is_empty():
		_create_materials()
	for key: String in ["sway", "sway_rooted"]:
		(_materials[key] as ShaderMaterial).set_shader_parameter("sway", _sway)
		for page: int in _page_materials:
			(_page_materials[page][key] as ShaderMaterial).set_shader_parameter("sway", _sway)
	return changed


static func sways() -> bool:
	return _sway_on


static func _sway_material(rooted: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SWAY_SHADER
	m.set_shader_parameter("rooted", 1.0 if rooted else 0.0)
	m.set_shader_parameter("sway", _sway)
	return m


## A sway material in a style: the pixel page, or its realistic picture and normal map (the page's rows: page_uv_scale).
static func _look_sway(m: ShaderMaterial, realistic: bool, pixel: Texture2D, albedo: Texture2D, normal: Texture2D) -> void:
	m.set_shader_parameter("pixel_tex", pixel)
	m.set_shader_parameter("photo_tex", albedo if realistic else pixel)
	m.set_shader_parameter("photo_normal", normal)
	m.set_shader_parameter("realistic", realistic)
	var s := page_uv_scale(albedo) if realistic else Vector3.ONE
	m.set_shader_parameter("uv_scale", Vector2(s.x, s.y))


## The warm-up's keeper of the sway shader in `for_style` (one: every page's sway materials are that one shader).
static func _sway_twin(for_style: String) -> ShaderMaterial:
	var k := "%s|0|sway" % for_style
	if not _twins.has(k):
		var twin := _sway_material(false)
		var realistic := for_style == "realistic"
		var albedo: Texture2D = ATLAS
		var normal: Texture2D = null
		if realistic:
			if RealisticPack.file_present(REALISTIC_ALBEDO):
				albedo = load(REALISTIC_ALBEDO)
			normal = load(REALISTIC_NORMAL) if RealisticPack.file_present(REALISTIC_NORMAL) else albedo
		_look_sway(twin, realistic, ATLAS, albedo, normal)
		_twins[k] = twin
	return _twins[k]

# --- M7: the shader warm-up (ShaderWarmup) ---------------------------------------------------------------------

static var _twins := {}   # "<style>|<page>|<kind>" -> a block material set up for a style the blocks do not show


## Every block material of `for_style` (page 0, every registered page, the water), as twins of the shared ones set up
## in that style. ShaderWarmup draws them once before the menu, and the twins stay: they keep that style's shaders
## compiled (a shader nobody uses is freed) whichever style the shared materials show, for the moment the child switches
## styles or the realistic pictures land. Before those pictures are in, a twin shows the pixel page: the same shader.
static func warmup_materials(for_style: String) -> Array[Material]:
	if _materials.is_empty():
		_create_materials()
	var out: Array[Material] = [_materials.water]
	var pages: Array = [0] + _pages.keys()
	for page: int in pages:
		for kind: StringName in [&"opaque", &"cutout", &"glow"]:
			out.append(_twin(for_style, page, kind, page_material(page, kind)))
	if _sway_on:
		out.append(_sway_twin(for_style))   # the visuals brief: the leaves' and plants' one shader (HIGH)
	return out


static func _forget_twins(page: int) -> void:
	for k: String in _twins.keys():
		if k.get_slice("|", 1) == str(page):
			_twins.erase(k)


static func _twin(for_style: String, page: int, kind: StringName, live: BaseMaterial3D) -> StandardMaterial3D:
	var k := "%s|%d|%s" % [for_style, page, kind]
	if not _twins.has(k):
		var twin := live.duplicate() as StandardMaterial3D
		var files: Array = PAGE_0_FILES if page == 0 else _pages[page].files
		var realistic := for_style == "realistic"
		var albedo: Texture2D = ATLAS if page == 0 else load(files[0])
		var normal: Texture2D = null
		if realistic:
			if RealisticPack.file_present(files[1]):
				albedo = load(files[1])
			normal = load(files[2]) if RealisticPack.file_present(files[2]) else albedo
		_look(twin, kind, realistic, albedo, normal)
		_twins[k] = twin
	return _twins[k]


## How many of the page's 8 rows of tiles a page texture holds (M5 Task 3, the APK size pass): the realistic page
## tools crop the empty rows under a page's last drawn tile (the desert's twin is 2048 x 768), so a texture is as tall
## as the rows it draws. The pixel pages keep all 8.
static func texture_rows(tex: Texture2D) -> int:
	return clampi(roundi(tex.get_height() * float(ATLAS_TILES.x) / tex.get_width()), 1, ATLAS_TILES.y)


## The UV scale that stretches the 8 x 8 page's UVs (the meshes, the tile coordinates) over the rows `tex` keeps:
## a uniform of the one shared material, so no mesh changes and no new shader.
static func page_uv_scale(tex: Texture2D) -> Vector3:
	return Vector3(1.0, float(ATLAS_TILES.y) / texture_rows(tex), 1.0)


static func _create_materials() -> void:
	var opaque := _material()
	var cutout := _material()
	cutout.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	cutout.alpha_scissor_threshold = 0.5
	cutout.cull_mode = BaseMaterial3D.CULL_DISABLED
	var water := ShaderMaterial.new()
	water.shader = WATER_SHADER
	water.set_shader_parameter("atlas", ATLAS)
	water.set_shader_parameter("waves", WATER_WAVES)
	var glow := _material()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials = {"opaque": opaque, "cutout": cutout, "water": water, "glow": glow, "sway": _sway_material(false),
		"sway_rooted": _sway_material(true)}
	set_style(style)


static func _material(atlas: Texture2D = ATLAS) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = atlas
	# Every renderer decodes the atlas's sRGB itself (Godot 4.7's OpenGL too: a forced second decode made the colours
	# dark and loud there; the visuals brief, docs/devlog/parts/visuals.md).
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	return mat

# --- M3 Task 4: the Candy Kingdom's chocolate --------------------------------------------------------------

## How this world's water looks: &"chocolate" in the Candy Kingdom (the same WATER blocks, so its rivers flow
## and swim like water), &"methane" on Titan (cosmos: TitanRules), plain water otherwise. A uniform on the one shared
## water material: no new shader.
static func set_liquid(kind: StringName) -> void:
	if _materials.is_empty():
		_create_materials()
	(_materials.water as ShaderMaterial).set_shader_parameter("chocolate", 1.0 if kind == &"chocolate" else 0.0)
	(_materials.water as ShaderMaterial).set_shader_parameter("methane", 1.0 if kind == TitanRules.METHANE else 0.0)


## M5 Task 3: the LOW preset's simpler water: one uniform of the one shared water material (no second shader).
static func set_simple_water(on: bool) -> void:
	if _materials.is_empty():
		_create_materials()
	(_materials.water as ShaderMaterial).set_shader_parameter("simple", on)


## 1.0 while the water looks like chocolate (tests).
static func liquid_chocolate() -> float:
	if _materials.is_empty():
		return 0.0
	return float((_materials.water as ShaderMaterial).get_shader_parameter("chocolate"))


## 1.0 while the water looks like Titan's liquid methane (tests).
static func liquid_methane() -> float:
	if _materials.is_empty():
		return 0.0
	return float((_materials.water as ShaderMaterial).get_shader_parameter("methane"))
