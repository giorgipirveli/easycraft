extends GutTest
## Photo filters (M3 Task 16): one post-process shader, one material; each filter is a set of that
## shader's parameters.

const F := PhotoFilters.Filter


func test_normal_is_the_untouched_picture_and_needs_no_shader() -> void:
	assert_eq(PhotoFilters.params(F.NORMAL), PhotoFilters.IDENTITY)
	assert_false(PhotoFilters.uses_shader(F.NORMAL))


func test_warm_is_warmer() -> void:
	var p := PhotoFilters.params(F.WARM)
	var tint: Vector3 = p.tint
	assert_gt(tint.x, 1.0, "more red")
	assert_lt(tint.z, 1.0, "less blue")
	assert_true(PhotoFilters.uses_shader(F.WARM))


func test_cool_is_cooler() -> void:
	var p := PhotoFilters.params(F.COOL)
	var tint: Vector3 = p.tint
	assert_gt(tint.z, 1.0, "more blue")
	assert_lt(tint.x, 1.0, "less red")


func test_black_and_white_has_no_colour() -> void:
	var p := PhotoFilters.params(F.BW)
	assert_eq(p.saturation, 0.0)
	assert_eq(p.outline, 0.0)


func test_comic_draws_outlines_and_flat_colours() -> void:
	var p := PhotoFilters.params(F.COMIC)
	assert_gt(p.outline, 0.0)
	assert_gte(p.levels, 3.0, "a few flat colour steps")
	assert_gt(p.saturation, 1.0, "bold colours")


func test_every_filter_sets_every_parameter_and_has_a_short_label() -> void:
	assert_eq(PhotoFilters.ORDER.size(), 5)
	for f: int in PhotoFilters.ORDER:
		var p := PhotoFilters.params(f)
		assert_eq(p.keys(), PhotoFilters.IDENTITY.keys(), "filter %d" % f)
		var label: String = PhotoFilters.LABELS[f]
		assert_between(label.length(), 2, 6, "kids read short words: %s" % label)
		assert_true(PhotoFilters.SWATCHES.has(f))


func test_an_unknown_filter_is_normal() -> void:
	assert_eq(PhotoFilters.params(99), PhotoFilters.IDENTITY)


func test_every_parameter_is_a_uniform_of_the_one_shader() -> void:
	var code := FileAccess.get_file_as_string(PhotoFilters.SHADER_PATH)
	assert_ne(code, "", "the shader exists")
	var re := RegEx.create_from_string("uniform\\s+\\w+\\s+(\\w+)")
	var uniforms: Array[String] = []
	for m in re.search_all(code):
		uniforms.append(m.get_string(1))
	for key: String in PhotoFilters.IDENTITY:
		assert_has(uniforms, key)
	var shader := load(PhotoFilters.SHADER_PATH) as Shader
	assert_not_null(shader)
	assert_eq(shader.get_mode(), Shader.MODE_CANVAS_ITEM, "a full-screen overlay, no per-object materials")
