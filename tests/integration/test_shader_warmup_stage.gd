extends GutTest
## M7 (docs/devlog/parts/m7-shader-warmup.md): the warm-up draws every material the game will need once, in a little
## world of its own (a SubViewport nobody sees) lit like the game's (a copy of its environment and sun, an omni light
## for half of the things: lanterns and torches make other shaders), a few materials a frame, then frees that world.
## The built materials stay (a shader nobody uses is freed, and compiled again at its next sight).

const SKY_SCENE := "res://assets/characters/kenney_human/characterMedium.fbx"

var _env: Environment
var _sun: DirectionalLight3D


func before_each() -> void:
	ShaderWarmup.menu_first = true   # these tests pin the menu-first design (the game: off, 2026-09-29)
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = Sky.new()
	_env.sky.sky_material = ProceduralSkyMaterial.new()
	_env.fog_enabled = true
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	add_child_autofree(_sun)


func after_each() -> void:
	ShaderWarmup.menu_first = false
	ShaderWarmup.done = false
	ShaderWarmup.warmed_styles.clear()
	PlatformRules.simulated = {}


func _glow_material() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return {"material": ShaderWarmup.describe(m), "instanced": false, "shadow": true, "styles": ["blocky"]}


func _stage(styles: Array[String], census: Array) -> ShaderWarmup:
	var w := ShaderWarmup.new()
	w.styles = styles
	w.environment = _env
	w.sun = _sun
	w.census = census
	add_child_autofree(w)
	return w


## The shaders of a style's block materials: every page shares a few (the same settings, other pictures).
func _block_shaders(style: String) -> int:
	var keys := {}
	for m: Material in BlockLibrary.warmup_materials(style):
		keys[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	return keys.size()


func test_every_shader_is_drawn_once_lit_by_a_lantern_and_once_unlit() -> void:
	var w := _stage(["blocky"] as Array[String], [_glow_material(), _glow_material()])
	var drawn := w.drawn   # the node frees itself once done
	await wait_for_signal(w.finished, 10.0)
	var n := _block_shaders("blocky") + 1
	assert_lt(_block_shaders("blocky"), BlockLibrary.warmup_materials("blocky").size(), "pages share their shaders")
	assert_eq(drawn.size(), n * 2, "each shader twice, whatever uses it: %s" % str(drawn.slice(0, 4)))
	assert_eq(drawn.filter(func(d: Dictionary) -> bool: return d.lit).size(), n, "half by the omni light")


func test_the_little_world_is_lit_like_the_game_and_matches_its_view() -> void:
	get_viewport().scaling_3d_scale = 0.75
	var w := _stage(["blocky"] as Array[String], [])
	var view := w.view   # made as it enters the tree
	assert_not_null(view)
	assert_true(view.own_world_3d, "its own world: nothing of it shows in the game's")
	assert_eq(view.scaling_3d_scale, 0.75, "the game view's 3D scale (it decides whether tonemapping is in post)")
	assert_eq(view.msaa_3d, get_viewport().msaa_3d)
	var env := (view.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	assert_ne(env, _env, "a copy of the game's environment")
	assert_true(env.fog_enabled)
	var suns := view.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(suns.size(), 1)
	assert_true((suns[0] as DirectionalLight3D).shadow_enabled, "the sun's shadows as in the game")
	assert_eq(view.find_children("*", "OmniLight3D", true, false).size(), 1)
	get_viewport().scaling_3d_scale = 1.0


func test_particles_are_drawn_instanced_and_labels_as_labels() -> void:
	var census := [
		{"material": ShaderWarmup.describe(StandardMaterial3D.new()), "instanced": true, "shadow": false, "styles": ["blocky"]},
		{"label": {"billboard": BaseMaterial3D.BILLBOARD_ENABLED}, "styles": ["blocky"]},
		{"sprite": {"alpha_cut": SpriteBase3D.ALPHA_CUT_DISCARD}, "styles": ["blocky"]},
	]
	var w := _stage(["blocky"] as Array[String], census)
	var kinds := {}   # class -> what it was drawn with (the nodes are freed a frame later)
	w.node_drawn.connect(func(n: Node) -> void:
		kinds[n.get_class()] = {"shadow": n.get("cast_shadow"), "billboard": n.get("billboard"),
			"alpha_cut": n.get("alpha_cut")}
		if n is MultiMeshInstance3D:
			var mmi := n as MultiMeshInstance3D
			kinds[n.get_class()].transform = mmi.multimesh.get_instance_transform(0)
			kinds[n.get_class()].aabb = mmi.custom_aabb)
	await wait_for_signal(w.finished, 10.0)
	assert_true(kinds.has("MultiMeshInstance3D"), "instanced: %s" % str(kinds.keys()))
	assert_eq(kinds.MultiMeshInstance3D.shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_eq(kinds.MultiMeshInstance3D.transform, Transform3D.IDENTITY,
		"its one instance where it can be seen (a new MultiMesh's instances are all zeros: nothing is drawn)")
	assert_gt((kinds.MultiMeshInstance3D.aabb as AABB).get_volume(), 0.0,
		"never culled in its one frame (the MultiMesh's own box is worked out only as it is drawn)")
	assert_true(kinds.has("Label3D"))
	assert_eq(kinds.Label3D.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_true(kinds.has("Sprite3D"))
	assert_eq(kinds.Sprite3D.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)


func test_a_realistic_pass_turns_on_glow_and_the_realistic_sky_in_its_own_world_only() -> void:
	var w := _stage(["blocky", "realistic"] as Array[String], [_glow_material()])
	var skies := []
	var view := w.view   # made as it enters the tree; its first pass starts on its first frame
	w.pass_started.connect(func(style: String) -> void:
		var env := (view.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
		skies.append([style, env.glow_enabled, env.sky.sky_material.get_class()]))
	await wait_for_signal(w.finished, 10.0)
	var looks := {}
	for s: Array in skies:
		looks[s[0]] = s.slice(1)
	assert_eq(looks, {"blocky": [false, "ProceduralSkyMaterial"], "realistic": [true, "PanoramaSkyMaterial"]},
		"each pass in its style's look, however often they take turns (the first part, then the rest)")
	assert_eq(skies[0][0], "blocky", "the first style first")
	assert_false(_env.glow_enabled, "the game's own environment is untouched")
	assert_true(_env.sky.sky_material is ProceduralSkyMaterial)


func test_a_realistic_pass_draws_every_draw_and_the_realistic_ones() -> void:
	var realistic_only := {"material": ShaderWarmup.describe(StandardMaterial3D.new()), "instanced": false,
		"shadow": true, "styles": ["realistic"]}
	var census := [_glow_material(), realistic_only]
	var w := _stage(["blocky"] as Array[String], census)
	var drawn := w.drawn
	await wait_for_signal(w.finished, 10.0)
	var blocky_only := drawn.size()
	var both := _stage(["blocky", "realistic"] as Array[String], census)
	var both_drawn := both.drawn
	await wait_for_signal(both.finished, 10.0)
	var per_pass := {}
	for d: Dictionary in both_drawn:
		per_pass[d.style] = int(per_pass.get(d.style, 0)) + 1
	assert_eq(blocky_only, (_block_shaders("blocky") + 1) * 2,
		"a BLOCKY child never sees what only REALISTIC draws")
	assert_eq(per_pass.realistic, (_block_shaders("realistic") + 2) * 2,
		"REALISTIC: its blocks, and everything else again in its environment (glow changes every shader)")


func test_a_skinned_draw_is_drawn_on_its_scene() -> void:
	var skin := {"material": ShaderWarmup.describe(StandardMaterial3D.new()), "instanced": false, "shadow": true,
		"skinned": true, "scene": SKY_SCENE, "styles": ["realistic"]}
	var w := _stage(["realistic"] as Array[String], [skin])
	var skinned := []
	w.node_drawn.connect(func(n: Node) -> void:
		if n.scene_file_path == SKY_SCENE:
			skinned.append(n))
	await wait_for_signal(w.finished, 10.0)
	assert_eq(skinned.size(), 2, "the character itself (its bones, its mesh), lit and unlit")


func test_the_stage_finishes_frees_its_world_and_keeps_the_materials() -> void:
	var w := _stage(["blocky"] as Array[String], [_glow_material()])
	await wait_for_signal(w.finished, 10.0)
	await wait_frames(2)
	assert_false(is_instance_valid(w), "gone once done")
	assert_true(ShaderWarmup.kept().any(func(m: Variant) -> bool:
		return m is StandardMaterial3D and (m as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED),
		"the built materials stay: their shaders stay compiled")
	assert_has(ShaderWarmup.warmed_styles, "blocky")


## In a browser the game's own view is behind the loading page during the warm-up: it draws no 3D meanwhile (a
## software-drawn browser spent most of each warm-up frame on the menu's backdrop), and draws again afterwards.
func test_a_quiet_warm_up_pauses_the_game_view_s_3d_and_gives_it_back() -> void:
	var main := get_viewport()
	assert_false(main.disable_3d)
	var w := _stage(["blocky"] as Array[String], [_glow_material()])
	w.quiet_main_view = true
	await wait_process_frames(2)
	assert_true(main.disable_3d, "no 3D in the game's view while warming")
	await wait_for_signal(w.finished, 10.0)
	assert_false(main.disable_3d, "back as it was")


func test_a_warm_up_freed_early_gives_the_view_back_too() -> void:
	var main := get_viewport()
	var w := _stage(["blocky"] as Array[String], [_glow_material()])
	w.quiet_main_view = true
	await wait_process_frames(2)
	w.free()   # its menu went away (the page's fallback)
	assert_false(main.disable_3d)
