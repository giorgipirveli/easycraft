extends GutTest
## The colours on OpenGL (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md): every renderer decodes a
## colour picture once, so every material takes its picture as it is.

const GAME_ROOTS := ["res://autoloads", "res://core", "res://entities", "res://scenes", "res://ui", "res://world",
	"res://shaders"]


func after_each() -> void:
	BlockLibrary.set_style("blocky")


## The warm-up's REALISTIC twins hold every page's photo textures for as long as they are cached: a later test that
## decompresses a texture's image to read its pixels would then leave it decompressed for test_page_sizes (89.7 MB
## instead of 63.8 in the full suite). Drop them: the warm-up makes them again when it needs them.
func after_all() -> void:
	BlockLibrary._twins.clear()


func _files_under(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd") or f.ends_with(".gdshader"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_files_under(dir.path_join(d), out)


## Godot 4.7's OpenGL renderer decodes a colour picture (a `source_color` sampler, every material's albedo) itself, as
## Vulkan does: measured on this PC's OpenGL, the emulator's app and the web build in the emulator's Chrome (the grass
## red/green 0.23-0.27 there, 0.43 on Vulkan, the tile's own 0.47). A second decode (albedo_texture_force_srgb, a
## to_linear in a shader) made every colour darker and louder: neon grass, near-black leaves, a dark REALISTIC world.
func test_no_game_script_or_shader_decodes_a_picture_twice() -> void:
	var files: Array[String] = []
	for root: String in GAME_ROOTS:
		_files_under(root, files)
	assert_gt(files.size(), 100)
	var twice: Array[String] = []
	for path in files:
		if FileAccess.get_file_as_string(path).contains("force_srgb"):
			twice.append(path)
	assert_eq(twice, [] as Array[String], "a second sRGB decode")


func test_every_block_material_takes_its_picture_as_the_renderer_decodes_it() -> void:
	for style: String in ["blocky", "realistic"]:
		for m: Material in BlockLibrary.warmup_materials(style):
			if m is BaseMaterial3D:
				assert_false((m as BaseMaterial3D).albedo_texture_force_srgb, "%s %s" % [style, m])
	for page: int in [0, 13, 18]:
		for kind: StringName in [&"opaque", &"cutout", &"glow"]:
			assert_false(BlockLibrary.page_material(page, kind).albedo_texture_force_srgb, "page %d %s" % [page, kind])


## The census (data/shader_warmup.json) describes the materials as the game makes them: none decodes twice.
func test_the_census_s_materials_decode_once() -> void:
	var text := FileAccess.get_file_as_string(ShaderWarmup.CENSUS_PATH)
	assert_false(text.contains("force_srgb"))
