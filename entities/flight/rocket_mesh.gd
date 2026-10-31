class_name RocketMesh
extends RefCounted
## The rocket the child built, as a mesh (owner #79, spec §25.3): its blocks with the blocks' own atlas look, drawn with
## BlockLibrary's shared materials (page_material: one surface, one draw call, per material; the world's set_style
## restyles it with every block, both styles, no new shader). Only faces that show are made: a face against an opaque
## neighbour goes, a see-through block (glass) shows what is behind it, glass against the same glass goes. A block id no
## page draws yet (the missions' parts, page 32, ids 560-575, before their page is merged; or any id beyond the pages)
## is drawn in a stand-in look: the painted-white tile tinted by a colour of its id, so parts are still told apart.
## Front faces wind clockwise seen from outside (Godot's rule).

## The stand-in tints (a colour per id, round the list): white, silver, red, orange, sky blue, gold.
const TINTS: Array[Color] = [Color("f4f4f0"), Color("b8c0cc"), Color("e0463c"), Color("f08a1c"), Color("78b8f0"),
	Color("f2c438")]
const _CUTOUT_0: Array[int] = [BlockIds.LEAVES, BlockIds.GLASS, BlockIds.WATER, BlockIds.DOOR_OPEN, BlockIds.BUSH]
const _GLOW_0: Array[int] = [BlockIds.LIGHT, BlockIds.CRYSTAL, BlockIds.GOLD_LAMP, BlockIds.JUMP_PAD, BlockIds.SPEED_PAD,
	BlockIds.LANTERN]
## The six faces: normal, and the "up" of its picture (sides: the sky; the top: north; the bottom: south).
const _FACES: Array = [[Vector3i(1, 0, 0), Vector3.UP], [Vector3i(-1, 0, 0), Vector3.UP], [Vector3i(0, 0, 1), Vector3.UP],
	[Vector3i(0, 0, -1), Vector3.UP], [Vector3i(0, 1, 0), Vector3.FORWARD], [Vector3i(0, -1, 0), Vector3.BACK]]


## How block `id` is drawn: {"page", "kind" (&"opaque", &"cutout", &"glow"), "tiles" [top, side, bottom], "tint"}.
static func look(id: int) -> Dictionary:
	var page := BlockLibrary.page_of(id)
	if page == 0 and BlockLibrary.TILES.has(id):
		var kind := &"cutout" if _CUTOUT_0.has(id) else (&"glow" if _GLOW_0.has(id) else &"opaque")
		return {"page": 0, "kind": kind, "tiles": BlockLibrary.TILES[id], "tint": Color.WHITE}
	var pages: Dictionary = BlockLibrary._pages   # the registered pages (their tiles and kinds)
	if page > 0 and pages.has(page) and (pages[page].tiles as Dictionary).has(id):
		var t: Array = pages[page].tiles[id]
		var kind: StringName = t[3] if t.size() > 3 else &"opaque"
		if kind == &"pass":
			kind = &"cutout"
		return {"page": page, "kind": kind, "tiles": t.slice(0, 3), "tint": Color.WHITE}
	var white := BlockIds.PAINTED_WHITE
	var tiles := BlockLibrary.tiles_of(white)
	if tiles.size() < 3:   # the paint page always registers; the stone tile if it ever does not
		return {"page": 0, "kind": &"opaque", "tiles": BlockLibrary.TILES[BlockIds.STONE],
			"tint": TINTS[absi(id) % TINTS.size()]}
	return {"page": BlockLibrary.page_of(white), "kind": &"opaque", "tiles": tiles, "tint": TINTS[absi(id) % TINTS.size()]}


## True when no page draws block `id` (the stand-in look).
static func stand_in(id: int) -> bool:
	var page := BlockLibrary.page_of(id)
	if page == 0:
		return not BlockLibrary.TILES.has(id)
	var pages: Dictionary = BlockLibrary._pages
	return not (pages.has(page) and (pages[page].tiles as Dictionary).has(id))


## The mesh of `cells` ({Vector3i: block id}), moved so `origin` (a point in cell space, e.g. RocketStages.pivot) is its
## (0, 0, 0). No blocks: a mesh with no surfaces.
static func build(cells: Dictionary, origin: Vector3 = Vector3.ZERO) -> ArrayMesh:
	var looks := {}
	for c: Vector3i in cells:
		var id: int = cells[c]
		if not looks.has(id):
			looks[id] = look(id)
	var groups := {}   # material -> {"v", "n", "uv", "col", "idx"} (plain Arrays: packed arrays are copied on append)
	for c: Vector3i in cells:
		var id: int = cells[c]
		var lk: Dictionary = looks[id]
		for f: Array in _FACES:
			var dir: Vector3i = f[0]
			var nb := c + dir
			if cells.has(nb) and _hides(lk, id, looks[cells[nb]], cells[nb]):
				continue
			var mat := BlockLibrary.page_material(lk.page, lk.kind)
			if not groups.has(mat):
				groups[mat] = {"v": [], "n": [], "uv": [], "col": [], "idx": []}
			var tiles: Array = lk.tiles
			var tile: Vector2i = tiles[0] if dir.y > 0 else (tiles[2] if dir.y < 0 else tiles[1])
			_face(groups[mat], Vector3(c) - origin, Vector3(dir), f[1], tile, lk.tint)
	var mesh := ArrayMesh.new()
	for mat: Material in groups:
		var g: Dictionary = groups[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(g.v)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(g.n)
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(g.uv)
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(g.col)
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(g.idx)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	return mesh


## A face between a block and its neighbour is hidden when the neighbour is solid (opaque or glowing), or when both
## are the same see-through block.
static func _hides(lk: Dictionary, id: int, nb_look: Dictionary, nb_id: int) -> bool:
	if nb_look.kind != &"cutout":
		return true
	return lk.kind == &"cutout" and id == nb_id


## One square face of the cell at `at` (its low corner) facing `n`, its picture `tile` upright along `up`.
static func _face(g: Dictionary, at: Vector3, n: Vector3, up: Vector3, tile: Vector2i, tint: Color) -> void:
	var right := (-n).cross(up)
	var centre := at + Vector3(0.5, 0.5, 0.5) + n * 0.5
	var r := right * 0.5
	var u := up * 0.5
	var base: int = (g.v as Array).size()
	(g.v as Array).append_array([centre - r + u, centre + r + u, centre + r - u, centre - r - u])   # TL TR BR BL
	var uv0 := Vector2(tile) / Vector2(BlockLibrary.ATLAS_TILES)
	var uv1 := Vector2(tile + Vector2i.ONE) / Vector2(BlockLibrary.ATLAS_TILES)
	(g.uv as Array).append_array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)])
	for i in 4:
		(g.n as Array).append(n)
		(g.col as Array).append(tint)
	(g.idx as Array).append_array([base, base + 1, base + 2, base, base + 2, base + 3])
