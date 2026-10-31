extends GutTest
## M7 (docs/devlog/parts/m7-shader-warmup.md): the OpenGL renderer (every browser) compiles a material's shader the
## first time it is drawn, on the main thread. ShaderWarmup draws every material the game will need once, hidden,
## before the menu. A material is described by what makes its shader (ShaderWarmup.describe: the class, the settings
## that change the shader's code, a ShaderMaterial's shader) and built again from that description (build), so the
## census of what the game draws (data/shader_warmup.json, tools/shader_probe_steps.gd --shader-census) can be warmed.



func before_each() -> void:
	ShaderWarmup.menu_first = true   # these tests pin the menu-first design (the game: off, 2026-09-29)
	PlatformRules.shader_warmup = true   # the rule's switch (a test turns it off)

func after_each() -> void:
	ShaderWarmup.menu_first = false
	PlatformRules.shader_warmup = true
	RealisticPack.exists_check = Callable()
	BlockLibrary.set_style("blocky")


func test_a_standard_material_is_described_by_the_settings_that_make_its_shader() -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.RED   # a uniform: the same shader
	m.roughness = 0.3            # a uniform too
	var d := ShaderWarmup.describe(m)
	assert_eq(d.class, "StandardMaterial3D")
	assert_eq(d.props, {"shading_mode": BaseMaterial3D.SHADING_MODE_UNSHADED, "vertex_color_use_as_albedo": true},
		"only what differs from a new material, and only what changes the shader")
	var plain := StandardMaterial3D.new()
	plain.albedo_color = Color.BLUE
	assert_eq(ShaderWarmup.describe(plain).props, {}, "a colour alone is the plain material's shader")


func test_the_same_shader_is_the_same_description() -> void:
	var a := StandardMaterial3D.new()
	a.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	a.albedo_color = Color.GREEN
	var b := StandardMaterial3D.new()
	b.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	b.alpha_scissor_threshold = 0.2
	assert_eq(ShaderWarmup.key(ShaderWarmup.describe(a)), ShaderWarmup.key(ShaderWarmup.describe(b)))
	b.cull_mode = BaseMaterial3D.CULL_DISABLED
	assert_ne(ShaderWarmup.key(ShaderWarmup.describe(a)), ShaderWarmup.key(ShaderWarmup.describe(b)),
		"two-sided is another shader")


func test_a_shader_material_is_described_by_its_shader() -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	m.set_shader_parameter("simple", true)
	var d := ShaderWarmup.describe(m)
	assert_eq(d.class, "ShaderMaterial")
	assert_eq(d.shader, "res://shaders/water.gdshader")
	var built := ShaderWarmup.build(d) as ShaderMaterial
	assert_not_null(built)
	assert_eq(built.shader, m.shader, "built again on the very same shader (its compiled programs are shared)")


func test_a_description_builds_a_material_with_the_same_shader() -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_texture_force_srgb = true
	var built := ShaderWarmup.build(ShaderWarmup.describe(m))
	assert_true(built is StandardMaterial3D)
	assert_eq(ShaderWarmup.describe(built), ShaderWarmup.describe(m))


func test_a_material_with_a_next_pass_describes_both() -> void:
	var m := StandardMaterial3D.new()
	var outline := StandardMaterial3D.new()
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.grow = true
	m.next_pass = outline
	var d := ShaderWarmup.describe(m)
	assert_eq(d.next_pass, ShaderWarmup.describe(outline))
	var built := ShaderWarmup.build(d) as StandardMaterial3D
	assert_not_null(built.next_pass, "the next pass is drawn (and compiled) too")
	assert_eq(ShaderWarmup.describe(built.next_pass), ShaderWarmup.describe(outline))


func test_nothing_describes_as_the_default_material() -> void:
	assert_eq(ShaderWarmup.describe(null), {"class": "default"}, "a surface without a material draws the default one")
	assert_null(ShaderWarmup.build({"class": "default"}), "built as no material (the default is drawn)")


# --- The blocks: every page, in both styles ---

const KINDS: Array[StringName] = [&"opaque", &"cutout", &"glow"]


## The shaders of every page's block materials while the blocks show `style` (page 0 and every registered page).
func _page_shaders(style: String) -> Array[String]:
	BlockLibrary.set_style(style)
	var out: Array[String] = []
	for page: int in [0] + BlockLibrary._pages.keys():
		for kind: StringName in KINDS:
			out.append(ShaderWarmup.key(ShaderWarmup.describe(BlockLibrary.page_material(page, kind))))
	return out


func _warm_shaders(style: String) -> Array[String]:
	var out: Array[String] = []
	for m: Material in BlockLibrary.warmup_materials(style):
		out.append(ShaderWarmup.key(ShaderWarmup.describe(m)))
	return out


func test_the_warm_up_has_every_page_s_block_materials_in_both_styles() -> void:
	RealisticPack.exists_check = func(_path: String) -> bool: return true   # the realistic pictures are in
	var blocky := _page_shaders("blocky")
	var realistic := _page_shaders("realistic")
	assert_ne(blocky[0], realistic[0], "REALISTIC blocks are other shaders (normal maps, smooth filtering)")
	BlockLibrary.set_style("blocky")
	var warm_realistic := _warm_shaders("realistic")
	for k in realistic:
		assert_has(warm_realistic, k, "while the blocks show BLOCKY, REALISTIC's block shaders are warmed too")
	assert_eq(BlockLibrary.style, "blocky", "warming REALISTIC's shaders changes nothing the child sees")
	BlockLibrary.set_style("realistic")
	var warm_blocky := _warm_shaders("blocky")
	for k in blocky:
		assert_has(warm_blocky, k, "and the other way round")
	assert_has(_warm_shaders("blocky"), ShaderWarmup.key(ShaderWarmup.describe(BlockLibrary._materials.water)), "water")


func test_a_page_registered_later_is_warmed_too() -> void:
	BlockLibrary.register_page(99, ["res://data/blocks/atlas.png", "res://data/blocks/atlas.png", "res://data/blocks/atlas.png"],
		{})
	var n := BlockLibrary.warmup_materials("blocky").size()
	BlockLibrary.unregister_page(99)
	assert_eq(n - BlockLibrary.warmup_materials("blocky").size(), 3, "a new page's materials come along by themselves")


func test_both_styles_stay_warm_whichever_the_blocks_show() -> void:
	RealisticPack.exists_check = func(_path: String) -> bool: return true
	BlockLibrary.set_style("blocky")
	var keepers := BlockLibrary.warmup_materials("blocky")
	assert_false(keepers.has(BlockLibrary.page_material(0, &"opaque")),
		"BLOCKY's own keepers, not the shared materials: those turn REALISTIC with the style")
	BlockLibrary.set_style("realistic")
	for m: Material in keepers:
		assert_true(m is ShaderMaterial or not (m as StandardMaterial3D).normal_enabled,
			"the keepers stay BLOCKY: a shader nobody uses is freed, and BLOCKY's would compile again on the way back")


func test_realistic_twins_stand_in_before_the_pictures_are_in() -> void:
	RealisticPack.exists_check = func(_path: String) -> bool: return false   # a browser before the realistic pack
	BlockLibrary.set_style("blocky")
	var twins := BlockLibrary.warmup_materials("realistic")
	assert_gt(twins.size(), 3)
	for m: Material in twins:
		if m is StandardMaterial3D and (m as StandardMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			assert_true((m as StandardMaterial3D).normal_enabled, "the realistic shader (normal maps) without its pictures")


# --- The census: what the game draws ---

func _mesh_with(mat: Material) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.material = mat
	return mesh


func test_the_census_lists_each_way_a_material_is_drawn_once() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var a := MeshInstance3D.new()
	a.mesh = _mesh_with(glow)
	root.add_child(a)
	var b := MeshInstance3D.new()   # the same shader again (another colour): listed once
	var glow2 := glow.duplicate() as StandardMaterial3D
	glow2.albedo_color = Color.RED
	b.mesh = BoxMesh.new()
	b.material_override = glow2
	b.visible = false   # hidden now, drawn later (a ring, a highlight): its shader is needed all the same
	root.add_child(b)
	var sparks := CPUParticles3D.new()   # particles draw instanced: another program
	sparks.mesh = _mesh_with(glow)
	root.add_child(sparks)
	var draws := ShaderWarmup.draws_of(root)
	assert_eq(draws.size(), 2, str(draws))
	var instanced := draws.filter(func(d: Dictionary) -> bool: return d.instanced)
	assert_eq(instanced.size(), 1, "the particles' way")
	assert_eq(instanced[0].material, ShaderWarmup.describe(glow))


## The census tells what is on screen from what waits hidden (ShaderWarmup.tier): a draw is shown when any node that
## draws it is visible, whichever node the census met first.
func test_the_census_tells_what_is_on_screen_from_what_waits_hidden() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := MeshInstance3D.new()   # hidden until a hold, met first
	ring.mesh = _mesh_with(glow)
	ring.visible = false
	root.add_child(ring)
	var lamp := MeshInstance3D.new()   # the same shader, on screen
	lamp.mesh = _mesh_with(glow.duplicate())
	root.add_child(lamp)
	var mirror := MeshInstance3D.new()   # another shader, hidden under a hidden parent
	var holder := Node3D.new()
	holder.visible = false
	root.add_child(holder)
	var plain := StandardMaterial3D.new()
	plain.vertex_color_use_as_albedo = true
	mirror.mesh = _mesh_with(plain)
	holder.add_child(mirror)
	var shown := ShaderWarmup.visible_keys(root)
	assert_true(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(glow), "instanced": false, "shadow": true})))
	assert_false(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(plain), "instanced": false,
		"shadow": true})), "hidden under its parent")
	assert_eq(shown.size(), 1)


func test_the_census_sees_labels_sprites_and_the_default_material() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	root.add_child(tag)
	var plain := MeshInstance3D.new()
	plain.mesh = BoxMesh.new()   # no material at all: the engine's default one
	root.add_child(plain)
	var draws := ShaderWarmup.draws_of(root)
	var labels := draws.filter(func(d: Dictionary) -> bool: return d.has("label"))
	assert_eq(labels.size(), 1)
	assert_eq(labels[0].label.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_true(labels[0].label.no_depth_test)
	assert_true(draws.any(func(d: Dictionary) -> bool: return d.get("material", {}).get("class", "") == "default"))


func test_the_census_skips_what_its_own_little_worlds_draw() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var view := SubViewport.new()   # the avatar editor's preview: its own world, lights and sky
	view.own_world_3d = true
	root.add_child(view)
	var inside := MeshInstance3D.new()
	inside.mesh = _mesh_with(StandardMaterial3D.new())
	view.add_child(inside)
	assert_eq(ShaderWarmup.draws_of(root), [], "not drawn in the game's world")


# --- Where it runs ---

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}


func test_it_runs_where_the_renderer_compiles_on_first_sight_unless_asked_not_to() -> void:
	assert_true(ShaderWarmup.wanted(PHONE_BROWSER, []), "a phone browser")
	assert_false(ShaderWarmup.wanted({PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}, []), "the Android app")
	assert_false(ShaderWarmup.wanted(PHONE_BROWSER, ["--no-shader-warmup"]),
		"the developer arg measures the same build without it (tools/web_shader_probe.py --no-warmup)")


## Measuring a build where the rule is off (tools/web_shader_probe.py --warmup): the developer arg --shader-warmup
## switches it on for that run; --shader-warmup-log prints each draw as it is made (which programs belong to which).
func test_the_developer_args_switch_it_on_and_log_its_draws() -> void:
	PlatformRules.shader_warmup = false
	ShaderWarmup.apply_args([])
	assert_false(PlatformRules.shader_warmup, "nothing without the arg")
	ShaderWarmup.apply_args(["--shader-warmup"])
	assert_true(PlatformRules.shader_warmup)
	assert_false(ShaderWarmup.wanted({PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}, ["--shader-warmup"]),
		"never where the renderer does not need it")
	assert_false(ShaderWarmup.logs_draws([]))
	assert_true(ShaderWarmup.logs_draws(["--shader-warmup-log"]))


# --- Spread and shown (the rework: the emulator's page stood 44 s at "Starting the game…") ---

## A browser waits for every new program inside the frame that draws it (a phone ~200 ms each, the probe's SwiftShader
## 5-15 ms): the next frame draws as many as the last frame's time says fit the budget, at least one, at most twice as
## many as before (a cheap draw says little about the next one) and never more than MAX_PER_FRAME.
func test_the_draws_a_frame_follow_the_time_budget() -> void:
	assert_eq(ShaderWarmup.next_count(0.0, 0, 150.0), 1, "nothing measured yet: one")
	assert_eq(ShaderWarmup.next_count(1200.0, 1, 150.0), 1, "a phone: one a frame, never none")
	assert_eq(ShaderWarmup.next_count(400.0, 4, 150.0), 1, "over the budget: fewer")
	assert_eq(ShaderWarmup.next_count(100.0, 4, 150.0), 6, "a quarter of the budget each: six fit")
	assert_eq(ShaderWarmup.next_count(30.0, 1, 150.0), 2, "at most twice the last")
	assert_eq(ShaderWarmup.next_count(10.0, 8, 150.0), ShaderWarmup.MAX_PER_FRAME, "a fast computer: the cap")


## After the menu is up the rest draws only where a slow frame hurts nobody: on the menu when it is not being touched,
## and behind a world's loading card; never in play (a phone's frame with a new shader is ~1 s).
func test_the_rest_runs_on_an_idle_menu_and_behind_a_loading_card_never_in_play() -> void:
	assert_true(ShaderWarmup.later_may_run(true, false, 5000.0), "the menu, nobody touching it")
	assert_false(ShaderWarmup.later_may_run(true, false, 300.0), "just after a tap: the menu answers first")
	assert_true(ShaderWarmup.later_may_run(true, false, ShaderWarmup.IDLE_AFTER_INPUT_MS))
	assert_true(ShaderWarmup.later_may_run(false, true, 0.0), "behind a world's loading card")
	assert_false(ShaderWarmup.later_may_run(false, false, 99999.0), "in play")


## The rest leaves the menu (and the loading card) as many normal frames as its own took: at most half the time.
func test_the_rest_draws_at_most_half_the_time() -> void:
	assert_eq(ShaderWarmup.rest_after(1000.0), 1000.0)
	assert_eq(ShaderWarmup.rest_after(40.0), 40.0)
	assert_eq(ShaderWarmup.rest_after(9000.0), ShaderWarmup.MAX_REST_MS,
		"a frame that also switched scenes (9 s in the probe) does not stop the rest for as long")


## The blocks before the menu (the menu's backdrop); by a lantern right after it, with the first world's draws (a
## returning child's world has lanterns and torches).
func test_the_blocks_come_before_the_menu_and_by_a_lantern_with_the_world() -> void:
	var entries := ShaderWarmup.plan(["blocky"] as Array[String], [])
	var blocks := {}
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		blocks[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	var first := entries.filter(func(e: Dictionary) -> bool: return e.first)
	assert_eq(first.size(), blocks.size())
	assert_true(first.all(func(e: Dictionary) -> bool: return not e.lit))
	var world := entries.filter(func(e: Dictionary) -> bool: return e.world)
	assert_eq(world.size(), blocks.size())
	assert_true(world.all(func(e: Dictionary) -> bool: return e.lit and not e.first))
	assert_eq(entries.slice(blocks.size(), blocks.size() * 2), world, "right after the menu")


## Before the menu: what the census saw on screen in the menu (FIRST). Right after it: what a first world shows near
## the spawn, and the player's own feedback on blocks (WORLD; the loading card waits for these). Then what the first
## minutes of play show, or the first world holds hidden until used (SOON); then the rest (LATER: monsters, bosses,
## the Moon, other universes).
func test_a_draw_s_tier_is_when_the_census_saw_it_on_screen() -> void:
	assert_eq(ShaderWarmup.tier({"phases": ["menu"], "shown": ["menu"]}), ShaderWarmup.FIRST, "the menu shows it")
	assert_eq(ShaderWarmup.tier({"phases": ["menu", "new"], "shown": ["menu", "new"]}), ShaderWarmup.FIRST)
	assert_eq(ShaderWarmup.tier({"phases": ["new", "play"], "shown": ["new"]}), ShaderWarmup.WORLD,
		"a first world: right after the menu, the loading card waits for it")
	assert_eq(ShaderWarmup.tier({"phases": ["new", "play"], "shown": ["play"]}), ShaderWarmup.SOON,
		"there from the start, hidden until the child plays (the break ring)")
	assert_eq(ShaderWarmup.tier({"phases": ["play"], "shown": ["play"]}), ShaderWarmup.SOON, "the first minutes")
	assert_eq(ShaderWarmup.tier({"phases": ["new"], "shown": []}), ShaderWarmup.SOON, "hidden in the first world")
	assert_eq(ShaderWarmup.tier({"phases": ["creatures", "moon"], "shown": ["creatures"]}), ShaderWarmup.LATER)
	assert_eq(ShaderWarmup.tier({"phases": ["universes"], "shown": []}), ShaderWarmup.LATER)
	assert_eq(ShaderWarmup.tier({"phases": ["new", "creatures"]}), ShaderWarmup.SOON,
		"a census without `shown` (older): there in the first world")
	assert_eq(ShaderWarmup.tier({"phases": ["new"], "shown": [], "at": "1/BlockInteractor/TargetHighlight (target_highlight.gd)"}),
		ShaderWarmup.WORLD, "the player's own feedback: hidden until the first look at a block, seconds after the spawn")
	assert_eq(ShaderWarmup.tier({"phases": ["new"], "shown": ["prewarm"],
		"at": "1/BlockInteractor/BreakRing/@MeshInstance3D@197 (break_ring.gd)"}), ShaderWarmup.WORLD, "the first break")


## The census plays its worlds in BLOCKY and switches to REALISTIC in its `realistic` phase: in the REALISTIC pass what
## that phase shows (the realistic avatar, a bot's realistic body) is a REALISTIC child's first world.
func test_what_the_realistic_phase_shows_is_a_realistic_child_s_first_world() -> void:
	var avatar := {"styles": ["realistic"], "phases": ["realistic"], "shown": ["realistic"]}
	assert_eq(ShaderWarmup.tier(avatar, "realistic"), ShaderWarmup.WORLD)
	assert_eq(ShaderWarmup.tier(avatar, "blocky"), ShaderWarmup.LATER, "a BLOCKY world never shows it")
	assert_eq(ShaderWarmup.tier({"phases": ["menu"], "shown": ["menu", "realistic"]}, "realistic"), ShaderWarmup.FIRST)


## Shown means near the camera (the census passes it): a label across the map is drawn much later than the spawn.
func test_the_census_counts_what_is_near_the_camera_as_shown() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var cam := Camera3D.new()
	root.add_child(cam)
	var near_mat := StandardMaterial3D.new()
	near_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var near := MeshInstance3D.new()
	near.mesh = _mesh_with(near_mat)
	near.position = Vector3(0, 0, -10)
	root.add_child(near)
	var far_mat := StandardMaterial3D.new()
	far_mat.vertex_color_use_as_albedo = true
	var far := MeshInstance3D.new()
	far.mesh = _mesh_with(far_mat)
	far.position = Vector3(0, 0, -ShaderWarmup.SHOWN_RADIUS - 20.0)
	root.add_child(far)
	var shown := ShaderWarmup.visible_keys(root, cam)
	assert_true(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(near_mat), "instanced": false,
		"shadow": true})))
	assert_false(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(far_mat), "instanced": false,
		"shadow": true})), "too far to be drawn at the spawn")
	assert_eq(ShaderWarmup.visible_keys(root).size(), 2, "without a camera: all that is visible")


## The frame spikes (2026-09-30): a child's first world may be a Survivor world, whose spawn has the portal hub's
## circle (its swirl and stones, HubCircle): the census's `survivor` phase (a new Survivor world) is a first world too.
func test_a_first_survivor_world_is_a_first_world() -> void:
	assert_has(ShaderWarmup.WORLD_PHASES, "survivor")
	assert_eq(ShaderWarmup.tier({"phases": ["survivor"], "shown": ["survivor"]}), ShaderWarmup.WORLD)


## The frame spikes (2026-09-30): the census plays each world's landing in a phase named after the world
## (tools/shader_probe_steps.gd); Green Meadows' first world is a new world or CONTINUE.
func test_a_world_s_census_phase_is_its_name() -> void:
	assert_eq(ShaderWarmup.world_phases(1), ShaderWarmup.WORLD_PHASES)
	assert_eq(ShaderWarmup.world_phases(2), ["desert"])
	assert_eq(ShaderWarmup.world_phases(SpaceRules.MOON), ["moon"])
	assert_eq(ShaderWarmup.world_phases(19), ["mars"])
	assert_eq(ShaderWarmup.world_phases(24), ["venus"])
	assert_eq(ShaderWarmup.world_phases(EarthRules.WONDERS), ["wonders"])
	assert_eq(ShaderWarmup.world_phases(999), [])


## The lead (2026-09-30): every world a child can land on has its landing in the census (tools/shader_probe_steps.gd's
## WORLDS; the Moon and Green Meadows have phases of their own), or its loading card waits for none of its own draws
## (Saturn's rings and Pluto came after the census's list was written).
func test_every_world_s_landing_is_in_the_census_steps() -> void:
	var steps: Dictionary = load("res://tools/shader_probe_steps.gd").WORLDS
	var worlds: Array[int] = UniverseRegistry.available()
	worlds.append_array(UniverseRegistry.space_available())
	worlds.append_array(UniverseRegistry.earth_available())
	for u in worlds:
		if u == 1 or u == SpaceRules.MOON:
			continue
		var phases := ShaderWarmup.world_phases(u)
		assert_eq(phases.size(), 1, "world %d has a census phase" % u)
		if phases.size() == 1:
			assert_eq(steps.get(phases[0], -1), u, "the census steps visit %s (world %d)" % [phases[0], u])


func _census_draw(m: StandardMaterial3D, phases: Array, shown: Array, at: String = "") -> Dictionary:
	return {"material": ShaderWarmup.describe(m), "instanced": false, "shadow": true, "styles": ["blocky"],
		"phases": phases, "shown": shown, "at": at}


## What a world's loading card waits for (in_world_part): the blocks (also by a lantern), what the menu shows (FIRST),
## the player's own feedback on blocks, and what the census saw on screen at that world's landing; a first world's
## (WORLD) only in Green Meadows. Never the rest's lanterns.
func test_a_world_s_part_is_what_the_census_saw_on_screen_at_its_landing() -> void:
	var moon_mat := StandardMaterial3D.new()
	moon_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var meadows_mat := StandardMaterial3D.new()
	meadows_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	var play_mat := StandardMaterial3D.new()
	play_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ring_mat := StandardMaterial3D.new()
	ring_mat.no_depth_test = true
	var menu_mat := StandardMaterial3D.new()
	menu_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var census := [_census_draw(moon_mat, ["moon"], ["moon"]), _census_draw(meadows_mat, ["new", "moon"], ["new"]),
		_census_draw(play_mat, ["play", "moon"], ["play"]),
		_census_draw(ring_mat, ["new"], [], "1/BlockInteractor/BreakRing/@MeshInstance3D@197 (break_ring.gd)"),
		_census_draw(menu_mat, ["menu"], ["menu"])]
	var entries := ShaderWarmup.plan(["blocky"] as Array[String], census)
	var of := func(m: Material, lit: bool) -> Dictionary:
		var k := ShaderWarmup.key(ShaderWarmup.describe(m))
		for e: Dictionary in entries:
			if e.lit == lit and ShaderWarmup.key(e.draw.material) == k:
				return e
		return {}
	for e: Dictionary in entries:
		if e.draw.get("block", false):
			assert_true(ShaderWarmup.in_world_part(e, SpaceRules.MOON), "the blocks, lit or not, everywhere")
			assert_true(ShaderWarmup.in_world_part(e, 1))
	assert_true(ShaderWarmup.in_world_part(of.call(moon_mat, false), SpaceRules.MOON), "what the Moon's landing shows")
	assert_false(ShaderWarmup.in_world_part(of.call(moon_mat, true), SpaceRules.MOON), "its lantern later")
	assert_false(ShaderWarmup.in_world_part(of.call(moon_mat, false), 1), "not Green Meadows'")
	assert_true(ShaderWarmup.in_world_part(of.call(meadows_mat, false), 1), "a first world's (WORLD)")
	assert_false(ShaderWarmup.in_world_part(of.call(meadows_mat, false), SpaceRules.MOON), "there, but never on screen")
	assert_false(ShaderWarmup.in_world_part(of.call(play_mat, false), SpaceRules.MOON), "the first minutes' (SOON)")
	assert_false(ShaderWarmup.in_world_part(of.call(play_mat, false), 1))
	assert_true(ShaderWarmup.in_world_part(of.call(ring_mat, false), SpaceRules.MOON), "the player's feedback, everywhere")
	assert_true(ShaderWarmup.in_world_part(of.call(menu_mat, false), SpaceRules.MOON), "what the menu shows (FIRST)")


## The frame spikes (2026-09-30, the probe's first sights in world 41's 2 km flight): the player's own lantern lights
## the child's avatar in every cave, tunnel and hill a ghost flies through: the avatar's materials by a lantern are in
## every world's part (like the blocks by a lantern), not with the rest's lanterns.
func test_the_avatar_by_its_own_lantern_is_in_every_world_s_part() -> void:
	var other := StandardMaterial3D.new()
	other.cull_mode = BaseMaterial3D.CULL_DISABLED
	var census := [
		{"material": ShaderWarmup.describe(AvatarParts.material(Color.RED)), "instanced": false, "shadow": true,
			"styles": ["blocky"], "phases": ["new"], "shown": ["new"]},
		{"material": ShaderWarmup.describe(AvatarParts.part_material()), "instanced": false, "shadow": false,
			"styles": ["blocky"], "phases": ["new"], "shown": ["new"]},
		_census_draw(other, ["new"], ["new"])]
	var entries := ShaderWarmup.plan(["blocky"] as Array[String], census)
	var lit_look := entries.filter(func(e: Dictionary) -> bool:
		return e.lit and not e.draw.get("block", false) and e.draw.get("player_look", false))
	assert_eq(lit_look.size(), 2, "the avatar's two materials by a lantern")
	for e: Dictionary in lit_look:
		assert_true(ShaderWarmup.in_world_part(e, 1))
		assert_true(ShaderWarmup.in_world_part(e, SpaceRules.MOON))
	var other_key := ShaderWarmup.key(ShaderWarmup.describe(other))
	for e: Dictionary in entries:
		if e.lit and ShaderWarmup.key(e.draw.material) == other_key:
			assert_false(ShaderWarmup.in_world_part(e, 1), "another material by a lantern: the rest's lanterns")


## The frame spikes (2026-09-30): the sky's bodies (the night's moon, a space world's planet: SkyCycle's NightSky, in
## the group ShaderWarmup.SKY) hang hundreds of metres away but are on screen wherever the child looks up; the census
## never counted them as shown, so the Moon's planet was left for later and compiled in the Moon's play.
func test_the_census_counts_the_sky_s_bodies_as_shown_however_far() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var cam := Camera3D.new()
	root.add_child(cam)
	var sky := Node3D.new()
	sky.add_to_group(ShaderWarmup.SKY)
	root.add_child(sky)
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var planet := MeshInstance3D.new()
	planet.mesh = _mesh_with(mat)
	planet.position = Vector3(0, 300, -400)
	sky.add_child(planet)
	var far_mat := StandardMaterial3D.new()
	far_mat.vertex_color_use_as_albedo = true
	var far := MeshInstance3D.new()
	far.mesh = _mesh_with(far_mat)
	far.position = Vector3(0, 0, -400)
	root.add_child(far)
	var shown := ShaderWarmup.visible_keys(root, cam)
	assert_true(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(mat), "instanced": false, "shadow": true})),
		"the sky's planet is on screen")
	assert_false(shown.has(ShaderWarmup.key({"material": ShaderWarmup.describe(far_mat), "instanced": false,
		"shadow": true})), "the ground's far things still are not")


func test_the_sky_cycle_s_bodies_are_the_sky_s() -> void:
	var src := FileAccess.get_file_as_string("res://world/sky_cycle.gd")
	assert_true(src.contains("_decor.add_to_group(ShaderWarmup.SKY)"), "SkyCycle's NightSky holds the stars, moon and planets")


## The Sandbox's own prewarms (a tiny draw in front of the camera as the world appears: the particles, the break ring,
## thought bubbles, the portals, the game ring, the blasters) were made for Vulkan, ~100 ms each. On WebGL each is
## a second or more, all at the spawn (41 of a new world's 71 programs); where the warm-up runs they are left to it.
func test_the_warm_up_takes_over_the_world_s_prewarms() -> void:
	ShaderWarmup.done = false
	assert_false(ShaderWarmup.covers_prewarms(), "no warm-up this run (Vulkan, or --no-shader-warmup)")
	ShaderWarmup.done = true
	assert_true(ShaderWarmup.covers_prewarms())
	ShaderWarmup.done = false


signal _spawned_for_test


func test_a_prewarm_waits_for_the_spawn_only_where_no_warm_up_ran() -> void:
	var calls := []
	var prewarm := func() -> void: calls.append(1)
	ShaderWarmup.done = false
	ShaderWarmup.at_spawn(_spawned_for_test, prewarm)
	_spawned_for_test.emit()
	_spawned_for_test.emit()
	assert_eq(calls.size(), 1, "once, as the world appears (Vulkan, or --no-shader-warmup)")
	ShaderWarmup.done = true
	ShaderWarmup.at_spawn(_spawned_for_test, prewarm)
	_spawned_for_test.emit()
	assert_eq(calls.size(), 1, "left to the warm-up")
	ShaderWarmup.done = false


## Every prewarm goes through ShaderWarmup.at_spawn (a new one hooked to `spawned` directly would freeze a browser's
## spawn again).
func test_no_script_hooks_a_prewarm_to_the_spawn_directly() -> void:
	var found: Array[String] = []
	for path: String in _scripts("res://"):
		if path == "res://world/shader_warmup.gd":
			continue   # at_spawn itself
		var text := FileAccess.get_file_as_string(path)
		for line: String in text.split("\n"):
			if line.contains("spawned.connect(") and line.to_lower().contains("prewarm"):
				found.append("%s: %s" % [path, line.strip_edges()])
	assert_eq(found, [] as Array[String])


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir):
		if not sub.begins_with(".") and sub not in ["addons", "tests", "build", "spikes"]:
			out.append_array(_scripts(dir.path_join(sub)))
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out


func test_a_realistic_child_warms_both_styles() -> void:
	assert_eq(ShaderWarmup.styles_for("blocky"), ["blocky"] as Array[String])
	assert_eq(ShaderWarmup.styles_for("realistic"), ["realistic", "blocky"] as Array[String],
		"what a REALISTIC child's worlds show first; BLOCKY after the menu (pictures still on their way)")


## The lead, 2026-09-29 (emulator: the first part held MENU ready 7.5 s for what the menu itself compiles in ~2.8 s):
## without menu_first nothing waits before the menu; the menu's own draws join the first world's, which a loading card
## still waits for.
func test_without_menu_first_the_menu_s_draws_join_the_world_part() -> void:
	ShaderWarmup.menu_first = false
	var entries := ShaderWarmup.plan(["blocky"] as Array[String], [])
	var keys := {}
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		keys[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	var blocks := keys.size()
	assert_eq(entries.filter(func(e: Dictionary) -> bool: return e.first).size(), 0, "nothing before the menu")
	var world := entries.filter(func(e: Dictionary) -> bool: return e.world)
	assert_eq(world.size(), blocks * 2, "the blocks, then the blocks by a lantern")
	assert_eq(entries.slice(0, world.size()), world, "first in the queue")
