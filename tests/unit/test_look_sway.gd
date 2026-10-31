extends GutTest
## Leaves and plants that move in the wind (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md): on HIGH the leaf
## blocks of every page that has them and the crossed plants (flowers, wheat) draw with the sway material (one shader,
## world/look/sway.gdshader); plants keep their feet (rooted), leaves move whole. MEDIUM and LOW keep the plain cut-out
## (on a phone's Vulkan the custom cut-out shader costs too much), and so does Reduce motion.

var lib: VoxelBlockyLibrary


func before_all() -> void:
	BlockLibrary.set_sway(true)
	lib = BlockLibrary.build()


func after_all() -> void:
	BlockLibrary.set_sway(false)
	BlockLibrary._twins.clear()   # the REALISTIC twins hold the photo textures (see test_look_colours.gd)


func after_each() -> void:
	BlockLibrary.set_style("blocky")
	BlockLibrary.set_sway(true)


func _material(id: int) -> Material:
	return (lib.models[id] as VoxelBlockyModel).get_material_override(0)


func _sways(id: int) -> bool:
	var m := _material(id)
	return m is ShaderMaterial and (m as ShaderMaterial).shader == BlockLibrary.SWAY_SHADER


func test_leaves_of_every_page_sway_whole() -> void:
	for id in [BlockIds.LEAVES, BlockIds.BUSH, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES, BlockIds.PALM_LEAVES,
			BlockIds.OLIVE_LEAVES]:
		assert_true(_sways(id), BlockIds.display_name(id))
		if _sways(id):
			assert_eq(float((_material(id) as ShaderMaterial).get_shader_parameter("rooted")), 0.0,
				"%s moves whole" % BlockIds.display_name(id))


func test_plants_sway_at_the_top_and_keep_their_feet() -> void:
	for id in [BlockIds.FLOWERS, BlockIds.WHEAT]:
		assert_true(_sways(id), BlockIds.display_name(id))
		if _sways(id):
			assert_eq(float((_material(id) as ShaderMaterial).get_shader_parameter("rooted")), 1.0, BlockIds.display_name(id))


func test_glass_doors_and_solid_blocks_stay_still() -> void:
	for id in [BlockIds.GLASS, BlockIds.DOOR_OPEN, BlockIds.GRASS, BlockIds.STONE, BlockIds.LOG, BlockIds.WATER]:
		assert_false(_sways(id), BlockIds.display_name(id))


## A leaf block still sees through its holes, is walked through or not as before, and hides no neighbour.
func test_swaying_leaves_keep_their_block_rules() -> void:
	var leaves := lib.models[BlockIds.LEAVES] as VoxelBlockyModel
	assert_false(leaves.culls_neighbors)
	assert_gt(leaves.transparency_index, 0)
	assert_false(leaves.collision_aabbs.is_empty(), "leaves are solid")
	assert_true((lib.models[BlockIds.BUSH] as VoxelBlockyModel).collision_aabbs.is_empty(), "a bush is walked through")
	assert_true((lib.models[BlockIds.FLOWERS] as VoxelBlockyModel).collision_aabbs.is_empty(), "flowers too")


func test_the_style_switches_the_swaying_pictures() -> void:
	var m := _material(BlockIds.LEAVES) as ShaderMaterial
	assert_false(bool(m.get_shader_parameter("realistic")))
	assert_eq(m.get_shader_parameter("pixel_tex"), BlockLibrary.ATLAS)
	BlockLibrary.set_style("realistic")
	if BlockLibrary.style == "realistic":
		assert_true(bool(m.get_shader_parameter("realistic")))
		assert_not_null(m.get_shader_parameter("photo_tex"))
		assert_not_null(m.get_shader_parameter("photo_normal"))
	BlockLibrary.set_style("blocky")
	assert_false(bool(m.get_shader_parameter("realistic")))


func test_a_cropped_realistic_page_keeps_its_rows() -> void:
	BlockLibrary.set_style("realistic")
	if BlockLibrary.style != "realistic":
		pass_test("no realistic pictures here")
		return
	var m := _material(BlockIds.PALM_LEAVES) as ShaderMaterial
	var photo: Texture2D = m.get_shader_parameter("photo_tex")
	var scale: Vector2 = m.get_shader_parameter("uv_scale")
	var want := BlockLibrary.page_uv_scale(photo)
	assert_almost_eq(scale.y, want.y, 0.0001)


func test_only_high_sways_and_never_with_reduce_motion() -> void:
	assert_false(bool(GraphicsPreset.params("low").sway), "LOW")
	assert_false(bool(GraphicsPreset.params("medium").sway), "MEDIUM: a phone's default")
	assert_true(bool(GraphicsPreset.params("high").sway))
	assert_true(GraphicsPreset.sways({"graphics": "high"}))
	assert_false(GraphicsPreset.sways({"graphics": "medium"}))
	assert_false(GraphicsPreset.sways({"graphics": "low"}))
	assert_false(GraphicsPreset.sways({"graphics": "high", "reduce_motion": true}), "Reduce motion")


## The choice is made as a library is built (a world's terrain keeps its library): off, a new library's leaves and
## plants are the plain cut-outs of their pages, with no sway shader to compile; set_sway says when it changed.
func test_off_a_new_library_keeps_the_plain_cut_out() -> void:
	assert_false(BlockLibrary.set_sway(true), "no change")
	assert_true(BlockLibrary.set_sway(false), "a change: a new library shows it")
	assert_false(BlockLibrary.sways())
	var plain := BlockLibrary.build()
	var leaves := (plain.models[BlockIds.LEAVES] as VoxelBlockyModel).get_material_override(0)
	assert_same(leaves, BlockLibrary.page_material(0, &"cutout"))
	var flowers := (plain.models[BlockIds.FLOWERS] as VoxelBlockyModel).get_material_override(0)
	assert_same(flowers, BlockLibrary.page_material(MeadowsBlocks.PAGE, &"cutout"))
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		assert_false(m is ShaderMaterial and (m as ShaderMaterial).shader == BlockLibrary.SWAY_SHADER, "no sway to warm")
	assert_true(BlockLibrary.set_sway(true))
	var m := _material(BlockIds.FLOWERS) as ShaderMaterial
	assert_eq(float(m.get_shader_parameter("sway")), 1.0)


## The shader warm-up draws the block pages' materials (BlockLibrary.warmup_materials): the sway shader is among them in
## both styles, so its first sight never compiles in play.
func test_the_warm_up_draws_the_sway_shader_in_both_styles() -> void:
	for style: String in ["blocky", "realistic"]:
		var found := false
		for m: Material in BlockLibrary.warmup_materials(style):
			if m is ShaderMaterial and (m as ShaderMaterial).shader == BlockLibrary.SWAY_SHADER:
				found = true
				assert_eq(bool((m as ShaderMaterial).get_shader_parameter("realistic")), style == "realistic", style)
		assert_true(found, style)
