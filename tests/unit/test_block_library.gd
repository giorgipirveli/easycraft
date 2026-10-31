extends GutTest

var lib: VoxelBlockyLibrary


func before_all() -> void:
	lib = BlockLibrary.build()


func test_one_model_per_block_id() -> void:
	assert_eq(lib.models.size(), BlockIds.COUNT)


func test_air_is_empty() -> void:
	assert_true(lib.models[BlockIds.AIR] is VoxelBlockyModelEmpty)


func test_water_has_no_collision() -> void:
	assert_true((lib.models[BlockIds.WATER] as VoxelBlockyModel).collision_aabbs.is_empty())


func test_solid_blocks_have_collision() -> void:
	for id in BlockIds.PLACEABLE:
		if BlockIds.is_solid(id):
			assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))


func test_see_through_blocks_do_not_hide_neighbours() -> void:
	for id in [BlockIds.GLASS, BlockIds.LEAVES, BlockIds.WATER]:
		assert_gt((lib.models[id] as VoxelBlockyModel).transparency_index, 0, BlockIds.display_name(id))


func test_grass_top_differs_from_side() -> void:
	var grass := lib.models[BlockIds.GRASS] as VoxelBlockyModelCube
	assert_ne(grass.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), grass.get_tile(VoxelBlockyModel.SIDE_POSITIVE_X))


func test_every_block_has_a_textured_cube() -> void:
	for id in range(1, BlockIds.COUNT):
		if BlockIds.display_name(id) == "":
			assert_true(lib.models[id] is VoxelBlockyModelEmpty, "unowned id %d stays empty" % id)
			continue
		if _crossed(id):
			assert_true(lib.models[id] is VoxelBlockyModelMesh, "block %d" % id)
			continue
		assert_true(lib.models[id] is VoxelBlockyModelCube, "block %d" % id)


## Two crossed pictures: page 0's flowers and wheat (owner #45b, test_meadows_blocks.gd) and a page's block marked
## "cross" (owner #78: the natural wonders' corn, test_wonders_nature_blocks.gd).
func _crossed(id: int) -> bool:
	if id in [BlockIds.FLOWERS, BlockIds.WHEAT]:
		return true
	var page := BlockLibrary.page_of(id)
	if page == 0 or not BlockLibrary._pages.has(page):
		return false
	var t: Array = BlockLibrary._pages[page].tiles.get(id, [])
	return t.size() > 4 and t[4] is Dictionary and bool((t[4] as Dictionary).get("cross", false))


func test_crystal_glows() -> void:
	var mat := (lib.models[BlockIds.CRYSTAL] as VoxelBlockyModel).get_material_override(0) as BaseMaterial3D
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)


func test_ores_look_different_from_stone() -> void:
	var stone := (lib.models[BlockIds.DEEPSTONE] as VoxelBlockyModelCube).get_tile(VoxelBlockyModel.SIDE_POSITIVE_X)
	for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.BEDROCK]:
		assert_ne((lib.models[id] as VoxelBlockyModelCube).get_tile(VoxelBlockyModel.SIDE_POSITIVE_X), stone, BlockIds.display_name(id))


# --- Graphics styles (M1b Task 8) ---

func _tile_has_pixels(img: Image, tile: Vector2i) -> bool:
	var s := img.get_width() / BlockLibrary.ATLAS_TILES.x
	for y in range(0, s, maxi(s / 16, 1)):
		for x in range(0, s, maxi(s / 16, 1)):
			if img.get_pixel(tile.x * s + x, tile.y * s + y).a > 0.1:
				return true
	return false


func test_both_styles_share_the_tile_layout() -> void:
	var blocky := BlockLibrary.ATLAS.get_image()
	var realistic := (load(BlockLibrary.REALISTIC_ALBEDO) as Texture2D).get_image()
	if realistic.is_compressed():
		realistic.decompress()
	assert_eq(realistic.get_width(), 2048)
	for id: int in BlockLibrary.TILES:
		for tile: Vector2i in BlockLibrary.TILES[id]:
			assert_true(_tile_has_pixels(blocky, tile), "blocky %s" % BlockIds.display_name(id))
			assert_true(_tile_has_pixels(realistic, tile), "realistic %s" % BlockIds.display_name(id))


func test_set_style_swaps_textures_on_the_shared_materials() -> void:
	var opaque := lib.models[BlockIds.STONE].get_material_override(0) as StandardMaterial3D
	var water := lib.models[BlockIds.WATER].get_material_override(0) as ShaderMaterial
	BlockLibrary.set_style("realistic")
	assert_eq(opaque.albedo_texture.resource_path, BlockLibrary.REALISTIC_ALBEDO)
	assert_true(opaque.normal_enabled)
	assert_eq(water.get_shader_parameter("realistic"), true)
	BlockLibrary.set_style("blocky")
	assert_eq(opaque.albedo_texture, BlockLibrary.ATLAS)
	assert_false(opaque.normal_enabled)
	assert_eq(water.get_shader_parameter("realistic"), false)


# --- Beds (M1b Task 10) ---

func test_bed_is_a_half_height_block_with_matching_collision() -> void:
	var bed := lib.models[BlockIds.BED] as VoxelBlockyModelCube
	assert_almost_eq(bed.height, BedRules.TOP, 0.0001)
	assert_eq(bed.collision_aabbs.size(), 1)
	assert_eq(bed.collision_aabbs[0], AABB(Vector3.ZERO, Vector3(1.0, BedRules.TOP, 1.0)))
	assert_ne(bed.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), bed.get_tile(VoxelBlockyModel.SIDE_POSITIVE_X),
		"blanket and pillow on top, the frame on the sides")


## A half-height bed must not hide the face of the block next to it (it would leave a hole above).
func test_a_bed_does_not_hide_the_face_next_to_it() -> void:
	var mesher := VoxelMesherBlocky.new()
	mesher.library = lib
	var buffer := VoxelBuffer.new()
	buffer.create(4, 3, 3)                       # 1 voxel of padding: mesh coords = buffer coords - 1
	buffer.set_voxel(BlockIds.BED, 1, 1, 1, VoxelBuffer.CHANNEL_TYPE)
	buffer.set_voxel(BlockIds.STONE, 2, 1, 1, VoxelBuffer.CHANNEL_TYPE)
	var mesh := mesher.build_mesh(buffer, [])
	var top := -1.0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in verts.size():
			if is_equal_approx(verts[i].x, 1.0) and normals[i].x < -0.9:
				top = maxf(top, verts[i].y)
	assert_almost_eq(top, 1.0, 0.001, "the stone's side facing the bed is drawn up to its top")


# --- Secrets and treasures (M2 Task 16) ---

func test_pressure_plate_is_a_low_plate_you_stand_on() -> void:
	var plate := lib.models[BlockIds.PRESSURE_PLATE] as VoxelBlockyModelCube
	assert_almost_eq(plate.height, 0.125, 0.0001)
	assert_eq(plate.collision_aabbs, [AABB(Vector3.ZERO, Vector3(1.0, 0.125, 1.0))])


func test_the_golden_lamp_glows() -> void:
	var mat := (lib.models[BlockIds.GOLD_LAMP] as VoxelBlockyModel).get_material_override(0) as BaseMaterial3D
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)


## A fake wall hides in stone: its own tile (a faint crack for sharp eyes), but nearly the same colour.
func test_a_fake_wall_looks_almost_like_stone() -> void:
	var fake := (lib.models[BlockIds.FAKE_WALL] as VoxelBlockyModelCube).get_tile(VoxelBlockyModel.SIDE_POSITIVE_X)
	var stone := (lib.models[BlockIds.STONE] as VoxelBlockyModelCube).get_tile(VoxelBlockyModel.SIDE_POSITIVE_X)
	assert_ne(fake, stone)
	var a := BlockLibrary.average_color(BlockIds.FAKE_WALL)
	var b := BlockLibrary.average_color(BlockIds.STONE)
	assert_lt(absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b), 0.1, "fake %s vs stone %s" % [a, b])


func test_secret_blocks_use_their_allocated_tiles() -> void:
	var allowed := [Vector2i(6, 6), Vector2i(7, 6), Vector2i(3, 0)]
	for x in 8:
		allowed.append(Vector2i(x, 7))
	for id in [BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE, BlockIds.TROPHY, BlockIds.GOLD_LAMP]:
		for tile: Vector2i in BlockLibrary.TILES[id]:
			assert_true(allowed.has(tile), "%s uses %s" % [BlockIds.display_name(id), tile])

# --- Jump and speed pads (M3 Task 6) ---

## Placeholder looks from the existing atlas until M3 Task 1's pages: a two-tone glowing block, a
## different top and side, so a pad stands out from the plain toy blocks.
func test_pads_are_glowing_two_tone_blocks() -> void:
	for id in [BlockIds.JUMP_PAD, BlockIds.SPEED_PAD]:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_ne(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_X),
			BlockIds.display_name(id))
		var mat := m.get_material_override(0) as BaseMaterial3D
		assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, BlockIds.display_name(id))
		assert_false(m.collision_aabbs.is_empty(), "you stand on it")
	var jump := lib.models[BlockIds.JUMP_PAD] as VoxelBlockyModelCube
	var speed := lib.models[BlockIds.SPEED_PAD] as VoxelBlockyModelCube
	assert_ne(jump.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), speed.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y))

# --- Hiding spots (M2 Task 5) ---

func test_hiding_spots_have_their_own_tiles_in_row_6() -> void:
	var tiles := {BlockIds.BUSH: [Vector2i(1, 6), Vector2i(0, 6), Vector2i(1, 6)],
		BlockIds.BARREL: [Vector2i(3, 6), Vector2i(2, 6), Vector2i(3, 6)],
		BlockIds.CLOSET: [Vector2i(5, 6), Vector2i(4, 6), Vector2i(5, 6)]}
	for id: int in tiles:
		assert_eq(BlockLibrary.TILES[id], tiles[id], BlockIds.display_name(id))
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_eq(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), tiles[id][0])
		assert_eq(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_X), tiles[id][1])


func test_a_bush_is_leafy_and_walk_through_and_barrels_and_closets_are_solid() -> void:
	var bush := lib.models[BlockIds.BUSH] as VoxelBlockyModel
	assert_true(bush.collision_aabbs.is_empty(), "walk into it")
	assert_same(bush.get_material_override(0), lib.models[BlockIds.LEAVES].get_material_override(0), "leafy gaps, like leaves")
	for id in [BlockIds.BARREL, BlockIds.CLOSET]:
		assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))

# --- Defenses (M2 Task 8) ---

const DEFENSE_TILES := {
	BlockIds.DOOR: [Vector2i(7, 0), Vector2i(3, 4), Vector2i(7, 0)],          # planks on top and below
	BlockIds.DOOR_OPEN: [Vector2i(5, 4), Vector2i(5, 4), Vector2i(5, 4)],
	BlockIds.SPIKE_TRAP: [Vector2i(6, 4), Vector2i(7, 4), Vector2i(6, 4)],
	BlockIds.LANTERN: [Vector2i(4, 4), Vector2i(7, 3), Vector2i(4, 4)],
}


func _realistic_image() -> Image:
	var img := (load(BlockLibrary.REALISTIC_ALBEDO) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	return img


## The pixel at (fx, fy) (0..1 across the tile) of `tile` in an atlas image of either style.
func _pixel(img: Image, tile: Vector2i, fx: float, fy: float) -> Color:
	var s := img.get_width() / BlockLibrary.ATLAS_TILES.x
	var pad := 0 if s == 16 else 8                  # realistic tiles: a 240 px texture in an 8 px border
	var inner := s - 2 * pad
	return img.get_pixel(tile.x * s + pad + int(fx * (inner - 1)), tile.y * s + pad + int(fy * (inner - 1)))


func test_defense_blocks_have_their_own_tiles() -> void:
	for id: int in DEFENSE_TILES:
		assert_eq(BlockLibrary.TILES[id], DEFENSE_TILES[id], BlockIds.display_name(id))
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_eq(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), DEFENSE_TILES[id][0], BlockIds.display_name(id))
		assert_eq(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_X), DEFENSE_TILES[id][1], BlockIds.display_name(id))


func test_a_lantern_glows() -> void:
	var mat := (lib.models[BlockIds.LANTERN] as VoxelBlockyModel).get_material_override(0) as BaseMaterial3D
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	for img: Image in [BlockLibrary.ATLAS.get_image(), _realistic_image()]:
		var glass := _pixel(img, Vector2i(7, 3), 0.5, 0.5)
		assert_gt(glass.get_luminance(), 0.7, "warm glass in the middle (%d px)" % img.get_width())


func test_an_open_door_is_a_see_through_frame_you_walk_through() -> void:
	var open := lib.models[BlockIds.DOOR_OPEN] as VoxelBlockyModel
	var closed := lib.models[BlockIds.DOOR] as VoxelBlockyModel
	assert_true(open.collision_aabbs.is_empty(), "walk through")
	assert_false(closed.collision_aabbs.is_empty())
	# The terrain's physics is built from mesh surfaces with collision on; collision_aabbs only serve
	# Voxel Tools' own box queries (found by the defense smoke run: monsters pressed on an open door).
	assert_false(open.is_mesh_collision_enabled(0), "no physics surface for an open door")
	assert_true(closed.is_mesh_collision_enabled(0))
	assert_eq((open.get_material_override(0) as BaseMaterial3D).transparency, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
		"cut out")
	assert_eq((closed.get_material_override(0) as BaseMaterial3D).transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
	for img: Image in [BlockLibrary.ATLAS.get_image(), _realistic_image()]:
		assert_lt(_pixel(img, Vector2i(5, 4), 0.6, 0.5).a, 0.1, "the middle is open (%d px)" % img.get_width())
		assert_gt(_pixel(img, Vector2i(5, 4), 0.0, 0.5).a, 0.9, "the frame is there")
		for f in [0.1, 0.5, 0.9]:
			assert_gt(_pixel(img, Vector2i(3, 4), f, f).a, 0.9, "a closed door is solid wood")


func test_the_spike_trap_wears_warning_stripes_in_both_styles() -> void:
	for img: Image in [BlockLibrary.ATLAS.get_image(), _realistic_image()]:
		var yellow := 0
		for i in 16:
			var c := _pixel(img, Vector2i(6, 4), i / 15.0, 0.02)
			if c.r > 0.8 and c.g > 0.6 and c.b < 0.4:
				yellow += 1
		assert_gt(yellow, 3, "yellow and black border (%d px)" % img.get_width())


## Found by Task 8's smoke run: the terrain's physics is built from mesh surfaces with collision on, so
## water with only collision_aabbs = [] was still a solid surface for bodies and physics rays on real
## terrain. Water has no physics surface; swimming (SwimRules) reads the blocks.
func test_water_has_no_physics_surface() -> void:
	var water := lib.models[BlockIds.WATER] as VoxelBlockyModel
	assert_true(water.collision_aabbs.is_empty())
	assert_false(water.is_mesh_collision_enabled(0), "bodies and rays pass through water")

