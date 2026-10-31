extends GutTest
## M7, the warm-up's rework (docs/devlog/parts/m7-shader-warmup.md, "The rework"): all of it before the menu held the
## emulator's loading page 44 s. Now the first part (what the menu and a first world show) comes before the menu, its
## progress on the loading page; the rest after, only where its gate lets it (an idle menu, a loading card), each
## frame as many draws as a time budget allows.

var _env: Environment
var _sun: DirectionalLight3D


func before_each() -> void:
	ShaderWarmup.menu_first = true   # these tests pin the menu-first design (the game: off, 2026-09-29)
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = Sky.new()
	_env.sky.sky_material = ProceduralSkyMaterial.new()
	_sun = DirectionalLight3D.new()
	add_child_autofree(_sun)


func after_each() -> void:
	ShaderWarmup.menu_first = false
	ShaderWarmup.done = false
	ShaderWarmup.warmed_styles.clear()
	get_viewport().disable_3d = false


func _draw(shading: int, phases: Array, shown: Array) -> Dictionary:
	var m := StandardMaterial3D.new()
	m.shading_mode = shading
	return {"material": ShaderWarmup.describe(m), "instanced": false, "shadow": true, "styles": ["blocky"],
		"phases": phases, "shown": shown}


## One draw of each tier: the menu shows one (unshaded, "0"), a first world another (per vertex, "2"), the first
## minutes of play a third (two-sided, "c"), a monster at night the last (vertex colours, "9").
func _census() -> Array:
	var two_sided := StandardMaterial3D.new()
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	var monster := StandardMaterial3D.new()
	monster.vertex_color_use_as_albedo = true
	return [_draw(BaseMaterial3D.SHADING_MODE_UNSHADED, ["menu", "new"], ["menu"]),
		_draw(BaseMaterial3D.SHADING_MODE_PER_VERTEX, ["new", "play"], ["new"]),
		{"material": ShaderWarmup.describe(two_sided), "instanced": false, "shadow": true, "styles": ["blocky"],
			"phases": ["new", "play"], "shown": ["play"]},
		{"material": ShaderWarmup.describe(monster), "instanced": false, "shadow": true, "styles": ["blocky"],
			"phases": ["creatures"], "shown": ["creatures"]}]


## What a draw was: "b" a block, "w" the water, "9" vertex colours, "c" two-sided, else its shading mode; "L" by a lantern.
static func _what(n: Node, lit: bool) -> String:
	var mat := (n as GeometryInstance3D).material_override as StandardMaterial3D
	var what := "w"
	if mat and mat.albedo_texture:
		what = "b"
	elif mat and mat.vertex_color_use_as_albedo:
		what = "9"
	elif mat and mat.cull_mode == BaseMaterial3D.CULL_DISABLED:
		what = "c"
	elif mat:
		what = str(mat.shading_mode)
	return what + ("L" if lit else "")


func _stage(census: Array, gate_open: Array = [true]) -> ShaderWarmup:
	var w := ShaderWarmup.new()
	w.styles = ["blocky"] as Array[String]
	w.environment = _env
	w.sun = _sun
	w.census = census
	w.gate = func() -> bool: return gate_open[0]
	add_child_autofree(w)
	return w


func _block_shaders() -> int:
	var keys := {}
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		keys[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	return keys.size()


func test_the_first_part_is_what_the_menu_shows() -> void:
	var w := _stage(_census(), [false])
	var drawn := w.drawn
	assert_eq(w.first_total, _block_shaders() + 1, "the blocks and the menu's draw")
	await wait_for_signal(w.first_done, 10.0)
	assert_eq(drawn.size(), w.first_total)
	assert_true(drawn.all(func(d: Dictionary) -> bool: return d.first and not d.lit), "lanterns after the menu")
	await wait_process_frames(10)
	assert_eq(drawn.size(), w.first_total, "the rest waits for its gate")
	assert_true(is_instance_valid(w) and w.is_in_group(ShaderWarmup.RUNNING), "and is still there")


func test_the_rest_follows_when_its_gate_opens_in_the_order_the_child_needs_it() -> void:
	var gate := [false]
	var w := _stage(_census(), gate)
	var drawn := w.drawn
	var order: Array[String] = []   # what each draw was, in order
	w.node_drawn.connect(func(n: Node) -> void: order.append(_what(n, drawn[-1].lit)))
	await wait_for_signal(w.first_done, 10.0)
	gate[0] = true
	await wait_for_signal(w.finished, 10.0)
	assert_eq(drawn.size(), (_block_shaders() + 4) * 2, "every shader, out of a lantern's reach and by it")
	var after_menu := order.slice(w.first_total)
	assert_eq(after_menu[0], "2", "a first world's draw right after the menu")
	var blocks_lit := after_menu.slice(1, 1 + _block_shaders())
	assert_true(blocks_lit.all(func(s: String) -> bool: return s in ["bL", "wL"]), "then the blocks by a lantern: %s"
		% str(after_menu))
	assert_eq(after_menu[1 + _block_shaders()], "c", "then the first minutes of play")
	assert_eq(after_menu.slice(after_menu.size() - 2), ["9", "9L"] as Array[String], "the monster last")
	assert_true(after_menu.find("0L") < after_menu.find("9"), "the menu's lantern before the monster")


## The loading card stays until a first world's draws are drawn (LoadingCard.HOLD_GROUP): the child never meets them
## compiling in the world.
func test_the_world_s_draws_hold_the_loading_card_until_drawn() -> void:
	var gate := [false]
	var w := _stage(_census(), gate)
	await wait_for_signal(w.first_done, 10.0)
	assert_true(w.is_in_group(LoadingCard.HOLD_GROUP), "the world's draws are still to come")
	gate[0] = true
	var drawn := w.drawn
	var world_total := 1 + _block_shaders()
	for i in 200:
		if drawn.size() >= w.first_total + world_total:
			break
		await wait_process_frames(1)
	await wait_process_frames(1)
	assert_false(w.is_in_group(LoadingCard.HOLD_GROUP), "drawn: the card may go")
	assert_true(w.is_in_group(ShaderWarmup.RUNNING), "while the rest goes on")


## The frame spikes (2026-09-30): a loading card for a world the rest has not reached yet (the Moon from the developer
## menu, a rocket's landing, a space world CONTINUEd) waits for what that world shows round its landing (the census's
## phase of that world): those draws come next, before what is left of the rest, and the first world's own
## (Green Meadows') no longer hold that card.
func test_a_world_s_loading_card_waits_for_what_that_world_shows() -> void:
	var moon := StandardMaterial3D.new()
	moon.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED   # "1" (per pixel, not the others' settings)
	var census := _census()
	census.append({"material": ShaderWarmup.describe(moon), "instanced": false, "shadow": true, "styles": ["blocky"],
		"phases": ["moon"], "shown": ["moon"]})
	var gate := [false]
	var w := _stage(census, gate)
	var drawn := w.drawn
	var order: Array[String] = []
	w.node_drawn.connect(func(n: Node) -> void: order.append(_what(n, drawn[-1].lit)))
	await wait_for_signal(w.first_done, 10.0)
	var at_card := order.size()
	var card := LoadingCard.new()
	card.setup(ModeRules.SURVIVOR, SpaceRules.MOON)
	add_child_autofree(card)
	await wait_process_frames(1)
	assert_true(w.is_in_group(LoadingCard.HOLD_GROUP), "the Moon's own draws are still to come")
	var part := w.world_left
	assert_eq(part, _block_shaders() + 1, "the blocks by a lantern and the Moon's draw")
	gate[0] = true
	for i in 200:
		if not w.is_in_group(LoadingCard.HOLD_GROUP):
			break
		await wait_process_frames(1)
	var behind_card := order.slice(at_card, at_card + part)   # (the rest may go on in the same frame)
	assert_true(behind_card.has("1"), "the Moon's draw came behind its card: %s" % str(behind_card))
	assert_false(behind_card.has("2"), "not the first world's (Green Meadows'): %s" % str(behind_card))
	assert_false(behind_card.has("c"), "nor the first minutes of play's")
	assert_true(w.is_in_group(ShaderWarmup.RUNNING), "the rest goes on after it")
	await wait_for_signal(w.finished, 10.0)
	var after := order.slice(at_card)
	assert_true(after.find("1") < after.find("2"), "the Moon's before Green Meadows' then: %s" % str(after))


## Under a loading card (it covers the screen) the game's view draws no 3D while the world's draws are to come: what the
## world would show compiles in the warm-up's short frames, not all in one long frame.
func test_under_a_loading_card_the_game_view_waits_for_the_world_s_draws() -> void:
	var w := _stage(_census())
	w.quiet_main_view = true
	w.gate = func() -> bool: return false
	await wait_for_signal(w.first_done, 10.0)
	await wait_process_frames(1)
	assert_false(get_viewport().disable_3d, "the menu shows")
	var card := LoadingCard.new()
	add_child_autofree(card)
	await wait_process_frames(2)
	assert_true(get_viewport().disable_3d, "under the card, while the world's draws are to come")
	w.gate = func() -> bool: return true
	for i in 200:
		if not w.is_in_group(LoadingCard.HOLD_GROUP):
			break
		await wait_process_frames(1)
	await wait_process_frames(2)
	assert_false(get_viewport().disable_3d, "drawn: the world shows")


func test_the_first_part_tells_its_progress_and_ends_at_one() -> void:
	var w := _stage(_census(), [false])
	var seen: Array[float] = []
	w.progress_sink = func(p: float) -> void: seen.append(p)
	await wait_for_signal(w.first_done, 10.0)
	assert_gt(seen.size(), 1)
	for i in range(1, seen.size()):
		assert_true(seen[i] >= seen[i - 1], "never back: %s" % str(seen))
	assert_eq(seen[-1], 1.0)
	var at_done := seen.size()
	await wait_process_frames(5)
	assert_eq(seen.size(), at_done, "nothing after the menu is up (the page is gone)")


func test_a_frame_draws_as_many_as_its_budget_allows() -> void:
	var slow := _stage(_census())
	slow.budget_ms = 0.0   # one a frame
	var per_frame := {}
	slow.node_drawn.connect(func(_n: Node) -> void:
		var f := Engine.get_process_frames()
		per_frame[f] = int(per_frame.get(f, 0)) + 1)
	await wait_for_signal(slow.finished, 10.0)
	assert_eq(per_frame.values().max(), 1)
	var fast := _stage(_census())
	fast.budget_ms = 100000.0   # a fast computer
	var fast_frames := {}
	fast.node_drawn.connect(func(_n: Node) -> void:
		var f := Engine.get_process_frames()
		fast_frames[f] = int(fast_frames.get(f, 0)) + 1)
	await wait_for_signal(fast.finished, 10.0)
	assert_gt(fast_frames.values().max(), 2, "more a frame when they fit")
	assert_true(fast_frames.values().max() <= ShaderWarmup.MAX_PER_FRAME)


## Behind the loading page the game's view draws no 3D; the menu shows as soon as the first part is done, and the rest
## goes on with the view drawing again.
func test_the_game_view_draws_again_once_the_first_part_is_done() -> void:
	var w := _stage(_census(), [false])
	w.quiet_main_view = true
	await wait_process_frames(2)
	assert_true(get_viewport().disable_3d, "behind the loading page")
	await wait_for_signal(w.first_done, 10.0)
	assert_false(get_viewport().disable_3d, "the menu shows")
	assert_true(w.is_in_group(ShaderWarmup.RUNNING), "while the rest waits")


## The first part never holds the menu longer than max_seconds; what is left of it goes on with the rest.
func test_the_first_part_gives_up_holding_the_menu_after_its_time() -> void:
	var w := _stage(_census())
	w.max_seconds = 0.0
	var drawn := w.drawn
	await wait_for_signal(w.first_done, 5.0)
	assert_lt(drawn.size(), w.first_total, "the menu shows with draws left")
	await wait_for_signal(w.finished, 10.0)
	assert_eq(drawn.size(), (_block_shaders() + 4) * 2, "all drawn in the end")


## A style picked later joins a running warm-up first in the rest (after the world's draws, which a loading card waits
## for).
func test_a_style_added_later_comes_first_in_the_rest() -> void:
	var gate := [false]
	var w := _stage(_census(), gate)
	var drawn := w.drawn
	await wait_for_signal(w.first_done, 10.0)
	w.add_style("realistic")
	gate[0] = true
	await wait_for_signal(w.finished, 10.0)
	var after_menu := drawn.slice(w.first_total).filter(func(d: Dictionary) -> bool: return not d.world)
	assert_eq(after_menu[0].style, "realistic")
	assert_true(drawn.any(func(d: Dictionary) -> bool: return d.style == "blocky" and not d.first), "then the rest")
	assert_has(ShaderWarmup.warmed_styles, "realistic")
