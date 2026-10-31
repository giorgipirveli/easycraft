class_name ShaderWarmup
extends Node
## M7 (docs/devlog/parts/m7-shader-warmup.md): the OpenGL renderer (every browser) compiles a material's shader the
## first time the material is drawn, and the browser waits for it on the main thread: the first world load froze for
## seconds, and the first animal, night light, water or effect later on. ShaderWarmup draws every material the game
## will need once, where nobody sees it, so later sights find their shaders compiled.
##
## In two parts (the rework: all of it before the menu held the emulator's loading page 44 s). The first part is what
## the menu and the child's first world show (`tier` FIRST), before the menu says it is ready, with its progress on the
## browser's loading page. The rest comes after the menu is up, in the order the child will need it, only where a slow
## frame hurts nobody (an idle menu, a world's loading card: `later_may_run`). Each frame draws as much as a time
## budget allows (`next_count`); the node lives under the tree's root, so the rest goes on behind the next scenes.
##
## A material is described by what makes its shader (describe: the class, the settings that change the shader's code,
## a ShaderMaterial's shader) and built again from that (build).

## BaseMaterial3D settings that are uniforms or bookkeeping, not part of the shader's code.
const NOT_SHADER := ["resource_local_to_scene", "render_priority"]
## What the game draws besides the blocks (tools/shader_probe_steps.gd --shader-census writes it).
const CENSUS_PATH := "res://data/shader_warmup.json"
const END_FRAMES := 2          # frames after the last draw (it is drawn at the end of its frame)
const LINGER_FRAMES := 2       # frames this node stays after `finished`
const MAX_SECONDS := 60.0      # the first part never holds the menu longer (its draws left go on with the rest)
## The time a frame of the warm-up aims at (next_count); a draw that takes longer is drawn alone.
const BUDGET_MS := 150.0
const MAX_PER_FRAME := 8
## After the menu is up: no draws this long after a touch, a click or a key (the menu answers first).
const IDLE_AFTER_INPUT_MS := 1500.0
## After the menu is up: normal frames for as long as a warm-up frame took, times this (rest_after).
const REST_FACTOR := 1.0
const VIEW_SIZE := Vector2i(128, 128)
const LAMP_AT := Vector3(-2.0, 0.0, -5.0)   # the lantern's group, in front of the little world's camera
const LAMP_RANGE := 1.8
const DAYLIGHT_AT := Vector3(2.0, 0.0, -5.0)   # out of the lantern's reach
const SLOT := 0.4              # between the things drawn in one frame
## Nodes of the warm-up itself (never counted by a census).
const GROUP := &"shader_warmup"
## A warm-up that is drawing (until `finished`).
const RUNNING := &"shader_warmup_running"
## The main menu is on screen (ui/menus/menu.gd joins it): the rest may draw there while nobody touches it.
const AT_MENU := &"main_menu"
## When a draw is needed (tier): what the menu shows (before MENU ready), what a first world shows (first after the
## menu; a loading card waits for it), what the first minutes of play show, the rest.
const FIRST := 0
const WORLD := 1
const SOON := 2
const LATER := 3
## The census's phases (tools/shader_probe_steps.gd) of the menu, and of a first world (a new Sandbox world, CONTINUE,
## a new Survivor world: its spawn has the portal hub's circle).
const MENU_PHASES := ["menu"]
const WORLD_PHASES := ["new", "continue", "survivor"]
## The player's own feedback on blocks (the census's `at`): hidden in a first world until the first look at a block or
## the first tap, seconds after the spawn, so FIRST (the brief's "the HUD's 3D bits").
const PLAYER_FEEDBACK := ["(target_highlight.gd)", "(break_ring.gd)", "(place_pop.gd)"]
## The census counts a draw as shown when a node drawing it is this near the camera (a first world's spawn view).
const SHOWN_RADIUS := 48.0
## The sky's bodies (SkyCycle's NightSky: the stars, the night's moon, a space world's planet and moons) hang hundreds
## of metres away but are on screen wherever the child looks up: the census counts what is under a node in this group
## as shown however far it is (the frame spikes, 2026-09-30: the Moon's planet compiled in the Moon's play).
const SKY := &"sky_decor"
## The longest pause after a frame of the rest (rest_after).
const MAX_REST_MS := 2000.0
## The settings of a Label3D / Sprite3D that make the material the engine gives it.
const LABEL_PROPS := ["billboard", "shaded", "double_sided", "no_depth_test", "fixed_size", "alpha_cut",
	"alpha_antialiasing_mode", "texture_filter"]
const SPRITE_PROPS := ["billboard", "shaded", "double_sided", "no_depth_test", "fixed_size", "alpha_cut",
	"alpha_antialiasing_mode", "texture_filter", "transparent"]

## The first part is drawn: the menu may say it is ready (the loading page leaves).
signal first_done
## Everything is drawn.
signal finished
signal pass_started(style: String)
signal node_drawn(node: Node)

## The warm-up before the menu ran (once a run).
static var done := false
## The styles whose shaders are warm.
static var warmed_styles: Array[String] = []
static var _defaults := {}   # class -> {prop: default value}
static var _keep: Array = []   # every material built for a warm-up: a shader nobody uses is freed
static var _census_cache: Variant = null
static var _watching := false   # watch_style connected
static var _box: BoxMesh
static var _tiny: ImageTexture
static var _look_keys := {}   # player_look_keys

## The styles to warm, in order: "blocky" (what a browser shows before the realistic pictures, and the default) and
## "realistic" (its blocks, sky and glow, and everything else again under its glow).
var styles: Array[String] = ["blocky"]
## The game's look to copy (the menu's backdrop world): its environment and sun.
var environment: Environment
var sun: DirectionalLight3D
## The census to draw (null: CENSUS_PATH).
var census: Variant = null
## False: everything is for after the menu (a style picked later).
var first_part := true
## The lead's ruling (2026-09-29, measured on the emulator with tools/web_emu_flow.py): the menu does not wait for its
## own draws. Drawn before `MENU ready` they held the loading page 7.5 s (MENU ready 8.5 → 16 s), while the menu itself
## compiles them in ~2.8 s of its first frames. Off: the menu is ready at once and its draws join the first world's
## part, which a loading card still waits for (the 11 s freeze when a world first appears stays gone). On: the design of
## docs/devlog/parts/m7-shader-warmup.md (its tests switch it on). Cost if wrong: two ~1.4 s frames as the menu appears.
static var menu_first := false
## The first part gives up holding the menu after this long (its draws left go on with the rest).
var max_seconds := MAX_SECONDS
## The time a frame aims at (next_count; 0: one draw a frame).
var budget_ms := BUDGET_MS
## (fraction: float) -> void: the first part's progress, 0 to 1 (start(): the browser's loading page).
var progress_sink: Callable
## () -> bool: whether the rest may draw now (start(): later_may_run on this tree). None: always.
var gate: Callable
## The little world it draws in.
var view: SubViewport
## What was drawn: {"style", "lit", "first"} per node (tests, the log lines).
var drawn: Array[Dictionary] = []
## The first part's draws: all of them, and those drawn so far.
var first_total := 0
var first_drawn := 0
## The world's draws still to come (plan's `world`): while there are any, a loading card waits (LoadingCard.HOLD_GROUP)
## and the game's view draws no 3D under it (quiet_main_view).
var world_left := 0
## In a browser the game's view is behind the loading page during the first part: it draws no 3D then (a phone's
## time goes to the shaders, not to the menu's backdrop), and draws again when the menu shows.
var quiet_main_view := false
## Print each draw as it is made (logs_draws).
var log_draws := false

var _queue: Array[Dictionary] = []
var _shown: Array[Node] = []
var _env: Environment
var _blocky_sky: Material
var _style := ""                # the look the little world is in (a pass)
var _t0 := 0
var _end := -1
var _linger := 0
var _quieted: Viewport   # the game's view, while its 3D is paused
var _first_open := true   # first_done not said yet
var _count := 1           # draws the next frame
var _drew := 0            # draws in the last frame
var _last_ms := 0         # when the last frame started
var _rest_until := 0
var _last_input_ms := -1000000
var _busy_ms := 0.0          # the frames that drew, in all
var _worst_later_ms := 0.0   # the longest frame that drew after the menu was up
var _drew_usec := 0          # when the last draws were made (until their frame is drawn)
var _draw_cost_ms := -1.0    # from the last draws to the end of their frame (RenderingServer.frame_post_draw)
var _card_id := 0            # the loading card last seen (a new one: world_part for its world)
var _part_of := 1            # the world whose draws world_left counts


## The warm-up that starts with the menu (ui/menus/menu.gd waits for its first_done before it says it is ready): where
## the renderer compiles shaders on first sight (PlatformRules.warms_shaders: a browser), once a run, in the look of
## `world` (the menu's backdrop: the game's environment and sun), the saved style first. Under the tree's root (the
## rest goes on behind the next scenes); its first part's progress goes to the browser's loading page. Null where none
## is wanted. From then on a child who picks REALISTIC gets it next in the rest (watch_style).
static func start(parent: Node, world: WorldService, f: Dictionary = {}) -> ShaderWarmup:
	var platform := f if not f.is_empty() else PlatformRules.current()
	var args := Array(OS.get_cmdline_user_args())
	if done or world == null or not wanted(platform, args):
		return null
	done = true
	var w := ShaderWarmup.new()
	w.styles = styles_for(str(Profile.data.settings.get("style", "blocky")))
	w.log_draws = logs_draws(args)
	w.environment = world.environment()
	w.sun = world.sun()
	w.quiet_main_view = PlatformRules.is_web(platform)   # behind the page's loading screen
	if w.quiet_main_view and menu_first:   # from the menu's first frame (it drew its backdrop's shaders at once, with no progress)
		w._quieted = parent.get_viewport()
		w._quieted.disable_3d = true
	w.progress_sink = func(fraction: float) -> void: WebGlue.warmup_progress(fraction)
	w.gate = w.default_gate
	parent.get_tree().root.add_child.call_deferred(w)   # the root may be busy adding the menu
	watch_style(parent.get_tree())
	return w


## The rest's rule on this tree (later_may_run): the main menu is up (AT_MENU) and nobody touched anything for a
## moment, or a world's loading card is up.
func default_gate() -> bool:
	var tree := get_tree()
	return later_may_run(tree.get_first_node_in_group(AT_MENU) != null,
		tree.get_first_node_in_group(LoadingCard.GROUP) != null, float(Time.get_ticks_msec() - _last_input_ms))


## Where a warm-up runs: the renderer compiles shaders on first sight (PlatformRules.warms_shaders), and the developer arg
## --no-shader-warmup is not given (it measures the same build without it: tools/web_shader_probe.py --no-warmup).
static func wanted(f: Dictionary, args: Array) -> bool:
	return PlatformRules.warms_shaders(f) and not args.has("--no-shader-warmup")


## How many draws the next frame makes: as many as fit `budget_ms` at the last frame's cost per draw (`last_ms` over
## `last_count`), at least one, at most twice the last and MAX_PER_FRAME. A browser waits for every new program in
## the frame that draws it (a phone ~200 ms a program, SwiftShader 5-15 ms): short frames let the page move.
static func next_count(last_ms: float, last_count: int, budget_ms: float) -> int:
	if last_count <= 0 or last_ms <= 0.0:
		return 1
	var fit := int(budget_ms * last_count / last_ms)
	return clampi(mini(fit, last_count * 2), 1, MAX_PER_FRAME)


## Whether the part after the menu may draw now: behind a world's loading card, or on the menu when nobody touched it
## for IDLE_AFTER_INPUT_MS; never in play (a phone's frame with a new shader is ~1 s).
static func later_may_run(at_menu: bool, card_up: bool, ms_since_input: float) -> bool:
	return card_up or (at_menu and ms_since_input >= IDLE_AFTER_INPUT_MS)


## How long the part after the menu waits after a frame of `frame_ms` with draws in it (the menu and the loading card
## keep at least half the time).
static func rest_after(frame_ms: float) -> float:
	return minf(frame_ms * REST_FACTOR, MAX_REST_MS)


## The developer arg --shader-warmup switches the rule on for a run (measuring a build where it is off:
## tools/web_shader_probe.py --warmup). scenes/main.gd calls this at boot.
static func apply_args(args: Array) -> void:
	if args.has("--shader-warmup"):
		PlatformRules.shader_warmup = true


## The developer arg --shader-warmup-log: every draw is printed as it is made (`WARMUP draw <n> <what>`), so the probe
## tells the warm-up's own frames and programs from first sights (tools/web_shader_probe.py passes it).
static func logs_draws(args: Array) -> bool:
	return args.has("--shader-warmup-log")


## The styles to warm for a saved style, the first one before the menu: BLOCKY; for a REALISTIC child REALISTIC first
## (its pictures are kept on the device and land seconds after the start), then BLOCKY (shown on a device where they
## are still on their way).
static func styles_for(saved_style: String) -> Array[String]:
	if saved_style == "realistic":
		return ["realistic", "blocky"] as Array[String]
	return ["blocky"] as Array[String]


## A child who picks REALISTIC in SETTINGS (Game.settings_applied) gets its shaders next in the rest (in a browser its
## pictures may land minutes later, in the middle of play: a 949 ms freeze on the emulator): into the running warm-up,
## or a new one in the look of the world on screen, drawing where the rest draws (an idle menu, a loading card).
## Nothing when REALISTIC is warm already.
static func watch_style(tree: SceneTree) -> void:
	if _watching:
		return
	_watching = true
	Game.settings_applied.connect(func(settings: Dictionary) -> void:
		if str(settings.get("style", "")) != "realistic" or warmed_styles.has("realistic") \
				or not PlatformRules.warms_shaders(PlatformRules.current()):
			return
		var running := tree.get_first_node_in_group(RUNNING) as ShaderWarmup
		if running:
			running.add_style("realistic")
			return
		var world := tree.get_first_node_in_group(RealisticPack.GROUP) as WorldService
		if world == null:
			return
		var w := ShaderWarmup.new()
		w.styles = ["realistic"] as Array[String]
		w.first_part = false
		w.environment = world.environment()
		w.sun = world.sun()
		w.gate = w.default_gate
		tree.root.add_child.call_deferred(w))


## Adds `style` to a running warm-up, first in the rest (after what is left of the first part and the world's draws).
func add_style(style: String) -> void:
	if styles.has(style):
		return
	styles.append(style)
	var draws: Array = census if census != null else census_draws()
	var at := _queue.size()
	for i in _queue.size():
		if not _queue[i].first and not _queue[i].world:
			at = i
			break
	var add := plan([style] as Array[String], draws, false)
	for i in add.size():
		_queue.insert(at + i, add[i])
	_end = -1


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(RUNNING)
	_t0 = Time.get_ticks_msec()
	view = SubViewport.new()
	view.own_world_3d = true   # nothing of it shows in the game's world
	view.size = VIEW_SIZE
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var main := get_viewport()
	# What decides a shader's variant besides the material: the 3D scale (below 1, tonemapping moves to a later pass),
	# MSAA, the environment (fog, sky light, glow) and the lights (a sun, its shadows, a lantern).
	view.scaling_3d_mode = main.scaling_3d_mode
	view.scaling_3d_scale = main.scaling_3d_scale
	view.msaa_3d = main.msaa_3d
	view.screen_space_aa = main.screen_space_aa
	view.use_debanding = main.use_debanding
	view.use_hdr_2d = main.use_hdr_2d
	add_child(view)
	var cam := Camera3D.new()
	cam.current = true
	view.add_child(cam)
	_env = environment.duplicate(true) if environment else Environment.new()
	_blocky_sky = _env.sky.sky_material if _env.sky else null
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	view.add_child(world_env)
	var light: DirectionalLight3D = sun.duplicate() if sun else DirectionalLight3D.new()
	view.add_child(light)
	var lamp := OmniLight3D.new()
	lamp.position = LAMP_AT
	lamp.omni_range = LAMP_RANGE
	lamp.shadow_enabled = false
	view.add_child(lamp)
	view.add_child(Lines.new())   # the 2D canvas' lines (a HUD draws them)
	_queue = plan(styles, census if census != null else census_draws(), first_part)
	first_total = _queue.filter(func(e: Dictionary) -> bool: return e.first).size()
	world_left = _queue.filter(func(e: Dictionary) -> bool: return e.world).size()
	if world_left > 0:
		add_to_group(LoadingCard.HOLD_GROUP)
	RenderingServer.frame_post_draw.connect(_on_frame_drawn)


## A touch, a click or a key: the rest waits a moment (the menu answers first).
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton \
			or event is InputEventKey or event is InputEventJoypadButton:
		_last_input_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var frame_ms := float(now - _last_ms) if _last_ms > 0 else 0.0   # the last frame, its drawing included
	_last_ms = now
	_watch_cards()
	_quiet_the_view()
	for n in _shown:
		n.queue_free()
	_shown.clear()
	if _linger > 0:
		_linger -= 1
		if _linger == 0:
			queue_free()
		return
	if _drew > 0:
		# What the draws cost: from them to the end of their frame (the programs link as it is drawn); without a draw
		# signal (headless), the whole frame.
		var cost := _draw_cost_ms if _draw_cost_ms >= 0.0 else frame_ms
		_count = next_count(cost, _drew, budget_ms)
		_busy_ms += cost
		if not _first_open:
			_worst_later_ms = maxf(_worst_later_ms, cost)
			_rest_until = now + int(rest_after(cost))
		_drew = 0
	_draw_cost_ms = -1.0
	if _first_open and (first_drawn >= first_total or now - _t0 > int(max_seconds * 1000.0)):
		_open_menu()
	if _end >= 0:
		_end -= 1
		if _end < 0:
			_finish()
		return
	if _queue.is_empty():
		_end = END_FRAMES
		return
	if not _first_open and ((now < _rest_until and not _card_waits()) or (gate.is_valid() and not gate.call())):
		return
	_draw_some()
	if _first_open and first_total > 0 and progress_sink.is_valid():
		progress_sink.call(float(first_drawn) / first_total)


## The game's view draws no 3D behind the loading page (the first part) and under a loading card while the world's
## draws are to come (it covers the screen: what the world would show compiles in the warm-up's short frames, not all
## in its first frame). Where quiet_main_view (a browser).
func _quiet_the_view() -> void:
	if not quiet_main_view:
		return
	var want := _first_open or (world_left > 0 and get_tree().get_first_node_in_group(LoadingCard.GROUP) != null)
	if want and _quieted == null and not get_viewport().disable_3d:
		_quieted = get_viewport()
		_quieted.disable_3d = true
	elif not want and _quieted != null:
		_give_view_back()


## A new loading card after the menu is up: its world's draws come next and hold it (world_part).
func _watch_cards() -> void:
	var card := get_tree().get_first_node_in_group(LoadingCard.GROUP)
	var id := card.get_instance_id() if card != null else 0
	if id == _card_id or _first_open:   # before the menu is up: looked at again once it is
		return
	_card_id = id
	if card is LoadingCard:
		world_part((card as LoadingCard).universe())


## A loading card that only waits for this warm-up now (the child stands in the world): no pause between frames.
func _card_waits() -> bool:
	var card := get_tree().get_first_node_in_group(LoadingCard.GROUP)
	return card != null and card.get("holding") == true


## Up to `_count` draws in one look (a pass), the first part's alone.
func _draw_some() -> void:
	var slot := 0
	while not _queue.is_empty() and slot < _count:
		var e: Dictionary = _queue[0]
		if _first_open and not e.first:
			break
		if e.style != _style:
			if slot > 0:
				break
			_begin_pass(str(e.style))
		_queue.pop_front()
		if log_draws:
			print("WARMUP draw %d %s %s" % [drawn.size(), e.style, key(e.draw).left(150)])
		var n := _node_for(e.draw)
		n.position = (LAMP_AT if e.lit else DAYLIGHT_AT) + Vector3((slot % 3 - 1) * SLOT, (slot / 3) * SLOT, 0.0)
		n.add_to_group(GROUP)
		view.add_child(n)
		_shown.append(n)
		drawn.append({"style": e.style, "lit": e.lit, "first": e.first, "world": e.world})
		if e.first:
			first_drawn += 1
		if e.world:
			world_left -= 1
			if world_left == 0:
				remove_from_group(LoadingCard.HOLD_GROUP)
				var which := "" if _part_of == 1 else " (%s)" % ",".join(world_phases(_part_of))
				print("WARMUP world %s%s: %d draws in %d ms" % [styles[0], which, drawn.size(), Time.get_ticks_msec() - _t0])
		node_drawn.emit(n)
		slot += 1
	_drew = slot
	if slot > 0:
		_drew_usec = Time.get_ticks_usec()


func _on_frame_drawn() -> void:
	if _drew_usec > 0:
		_draw_cost_ms = (Time.get_ticks_usec() - _drew_usec) / 1000.0
		_drew_usec = 0


## The first part is drawn (or held the menu long enough): the menu may say it is ready, the game's view draws again.
func _open_menu() -> void:
	_first_open = false
	_give_view_back()
	if first_total > 0 and progress_sink.is_valid():
		progress_sink.call(1.0)
	if first_part:
		print("WARMUP first %s: %d draws in %d ms" % [styles[0], first_drawn, Time.get_ticks_msec() - _t0])
	for e: Dictionary in _queue:
		e.first = false   # what is left of it goes on with the rest
	first_done.emit()


func _finish() -> void:
	if _first_open:
		_open_menu()
	for s: String in styles:
		if not warmed_styles.has(s):
			warmed_styles.append(s)
	print("WARMUP %s: %d draws in %d ms (%d ms of frames drawing; the worst after the menu %d ms)" % [
		",".join(styles), drawn.size(), Time.get_ticks_msec() - _t0, int(_busy_ms), int(_worst_later_ms)])
	remove_from_group(RUNNING)
	remove_from_group(LoadingCard.HOLD_GROUP)
	_give_view_back()
	view.queue_free()   # its little world goes now; this node a few frames later (whoever waits on `finished` first)
	_linger = LINGER_FRAMES
	finished.emit()


func _exit_tree() -> void:
	_give_view_back()   # freed before it was done (its menu went away)
	if RenderingServer.frame_post_draw.is_connected(_on_frame_drawn):
		RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)


func _give_view_back() -> void:
	if is_instance_valid(_quieted):
		_quieted.disable_3d = false
	_quieted = null


func _begin_pass(style: String) -> void:
	var realistic := style == "realistic"
	_env.glow_enabled = realistic   # as WorldService.apply_style: glow moves tonemapping to a later pass
	_env.glow_intensity = 0.6
	_env.glow_bloom = 0.05
	if _env.sky:
		_env.sky.sky_material = _realistic_sky() if realistic else _blocky_sky
	_style = style
	pass_started.emit(style)


## The warm-up's order: [{"style", "draw", "lit", "first", "world"}]. Each draw twice, out of a lantern's reach and by
## it (lanterns, the cave lantern, torches make another shader). With `first_part_too`, the first style's FIRST draws
## out of the lantern's reach come first (`first`: before the menu), then its WORLD draws and the blocks by a lantern
## (`world`: a loading card waits for them); then the other styles' FIRST and WORLD draws; then per style: SOON,
## the other lanterns on FIRST and WORLD, SOON's lanterns, LATER, LATER's lanterns.
static func plan(for_styles: Array[String], draws: Array, first_part_too: bool = true) -> Array[Dictionary]:
	var first: Array[Dictionary] = []
	var world: Array[Dictionary] = []
	var others: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for i in for_styles.size():
		var style := for_styles[i]
		var by_tier := [[], [], [], []]
		for d: Dictionary in _draws_for(style, draws, for_styles.has("realistic")):
			(by_tier[int(d.tier)] as Array).append(d)
		var its := i == 0 and first_part_too
		var entry := func(d: Dictionary, lit: bool, part: String) -> Dictionary:
			return {"style": style, "draw": d, "lit": lit, "first": its and part == "first", "world": its and part == "world"}
		var blocks: Array = by_tier[FIRST].filter(func(d: Dictionary) -> bool: return d.get("block", false))
		for d: Dictionary in by_tier[FIRST]:
			if its and not menu_first:
				world.append(entry.call(d, false, "world"))   # the menu draws them itself; a first world needs them too
			else:
				(first if its else others).append(entry.call(d, false, "first"))
		for d: Dictionary in by_tier[WORLD]:
			(world if its else others).append(entry.call(d, false, "world"))
		for d: Dictionary in blocks:   # the blocks by a lantern: a child's world has lanterns and torches
			(world if its else others).append(entry.call(d, true, "world"))
		var look: Array = []   # the child's own look by the player's lantern (player_look_keys)
		for t: int in [FIRST, WORLD, SOON, LATER]:
			for d: Dictionary in by_tier[t]:
				if d.get("player_look", false) and not blocks.has(d):
					look.append(d)
					(world if its else others).append(entry.call(d, true, "world"))
		for batch: Array in [[SOON, false], [FIRST, true], [WORLD, true], [SOON, true], [LATER, false], [LATER, true]]:
			for d: Dictionary in by_tier[batch[0]]:
				if not (batch[1] and (blocks.has(d) or look.has(d))):
					rest.append(entry.call(d, batch[1], "rest"))
	return first + world + others + rest


## When a census draw is needed: FIRST when the census saw it on screen in the menu (`shown`), WORLD in a first world
## near the camera or the player's own feedback on blocks, SOON when it shows in the first minutes of play or waits
## hidden in the first world, else LATER. A census without `shown` (older) counts every draw of a first world as SOON.
## The census plays its worlds in BLOCKY and switches to REALISTIC in its `realistic` phase: in the REALISTIC pass
## (`style`) what that phase shows is a REALISTIC child's first world too.
static func tier(d: Dictionary, style: String = "blocky") -> int:
	var phases: Array = d.get("phases", [])
	var shown: Array = d.get("shown", [])
	var at := str(d.get("at", ""))
	for p: String in MENU_PHASES:
		if shown.has(p):
			return FIRST
	for script: String in PLAYER_FEEDBACK:
		if at.ends_with(script):
			return WORLD
	for p: String in WORLD_PHASES + (["realistic"] if style == "realistic" else []):
		if shown.has(p):
			return WORLD
	if shown.has("play"):
		return SOON
	for p: String in MENU_PHASES + WORLD_PHASES:
		if phases.has(p):
			return SOON
	return LATER


## The census's phases of world `u`'s landing: Green Meadows' first world (WORLD_PHASES: a new world, CONTINUE), else
## the world's own name (tools/shader_probe_steps.gd plays each world's landing in a phase named after it: "desert",
## "moon", "mars", "venus", "wonders" ...). [] for a world the census cannot know.
static func world_phases(u: int) -> Array:
	if u == 1:
		return WORLD_PHASES
	var n := UniverseRegistry.ladder_name(u)
	if n == &"":
		n = UniverseRegistry.space_name(u)
	if n == &"" and UniverseRegistry.EARTH.has(u):
		n = UniverseRegistry.EARTH[u].name
	return [String(n)] if n != &"" else []


## Whether an entry of the plan is part of what world `u`'s loading card waits for (world_part): the blocks (also by a
## lantern), what the menu shows (FIRST) and the player's own feedback on blocks, out of a lantern's reach; and what the
## census saw on screen at that world's landing (world_phases; Green Meadows: a first world's draws, WORLD).
static func in_world_part(e: Dictionary, u: int) -> bool:
	var d: Dictionary = e.draw
	if d.get("block", false):
		return true
	if e.lit:   # by a lantern: the blocks (above) and the child's own look (the player's lantern is always near it)
		return d.get("player_look", false)
	var t := int(d.get("tier", LATER))
	if t == FIRST or d.get("feedback", false):
		return true
	if u == 1:
		return t == WORLD
	var shown: Array = d.get("shown_in", [])
	for p: String in world_phases(u):
		if shown.has(p):
			return true
	return false


## The shaders of the child's own look (the blocky avatar's parts: AvatarParts' materials; a realistic body is a skinned
## draw): the player's lantern lights them in every cave, tunnel and hill a ghost flies through, so their lantern
## draws are in every world's part (the frame spikes, 2026-09-30: world 41's flight compiled them mid-flight).
static func player_look_keys() -> Dictionary:
	if _look_keys.is_empty():
		for m: Material in [AvatarParts.material(Color.WHITE), AvatarParts.part_material()]:
			_look_keys[key(describe(m))] = true
	return _look_keys


## A world's loading card came up (world `u`; the frame spikes, 2026-09-30): what that world shows round its landing
## (in_world_part) comes next, ahead of what is left of the rest, and holds the card (world_left, LoadingCard.HOLD_GROUP);
## another world's draws go back to the rest in their order. The Moon from the developer menu, a rocket's landing or
## a space world CONTINUEd used to meet its own draws (LATER) compiling in play, the warm-up still on SOON.
func world_part(u: int) -> void:
	var style := styles[0]
	var head: Array[Dictionary] = []
	var part: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for e: Dictionary in _queue:
		if e.first:
			head.append(e)
		elif e.style == style and in_world_part(e, u):
			e.world = true
			part.append(e)
		else:
			e.world = false
			rest.append(e)
	_queue = head + part + rest
	world_left = part.size()
	_part_of = u
	if world_left > 0:
		add_to_group(LoadingCard.HOLD_GROUP)
	else:
		remove_from_group(LoadingCard.HOLD_GROUP)


## The Sandbox's prewarms (a tiny draw in front of the camera as the world appears: Fx, the break ring and the pop,
## thought bubbles, the portals, the game ring, the blasters) are left to the warm-up when one ran this run: made for
## Vulkan (~100 ms each), on WebGL they froze the spawn for seconds.
static func covers_prewarms() -> bool:
	return done


## Runs `prewarm` once as the world appears (`spawned`), unless the warm-up covers it (covers_prewarms).
static func at_spawn(spawned: Signal, prewarm: Callable) -> void:
	if not covers_prewarms():
		spawned.connect(prewarm, CONNECT_ONE_SHOT)


## The blocks of `style`, then what the census saw in it, each with its `tier`; with REALISTIC warmed, every pass draws
## everything (a REALISTIC child sees BLOCKY until its pictures are in, and REALISTIC's glow makes every material
## another shader). One draw per shader and way of drawing: every block page shares its kind's shader (the pictures
## are uniforms).
static func _draws_for(style: String, draws: Array, all: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for m: Material in BlockLibrary.warmup_materials(style):
		var d := {"material": describe(m), "instanced": false, "shadow": true}
		if not seen.has(key(d)):
			seen[key(d)] = true
			d.mat = m   # the block material itself (its style's twin keeps the shader)
			d.tier = FIRST   # the menu's backdrop and every world
			d.block = true
			out.append(d)
	for d: Dictionary in draws:
		if not all and not (d.get("styles", ["blocky"]) as Array).has(style):
			continue
		var e := d.duplicate()
		for note: String in ["styles", "phases", "shown", "at"]:
			e.erase(note)
		if seen.has(key(e)):
			continue
		seen[key(e)] = true
		if d.has("material"):
			e.mat = build(d.material)
		e.tier = tier(d, style)
		e.shown_in = d.get("shown", [])   # the phases (worlds' landings too) it was on screen in: world_part
		var at := str(d.get("at", ""))
		e.feedback = PLAYER_FEEDBACK.any(func(script: String) -> bool: return at.ends_with(script))
		e.player_look = d.has("material") and not d.get("instanced", false) \
			and (player_look_keys().has(key(d.material)) or d.get("skinned", false))
		out.append(e)
	return out


func _node_for(d: Dictionary) -> Node3D:
	var mat: Material = d.get("mat")
	if mat and not _keep.has(mat):
		_keep.append(mat)
	var shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if d.get("shadow", true) \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if d.has("label"):
		var label := Label3D.new()
		label.text = "Aa"
		_set_props(label, d.label)
		return label
	if d.has("sprite"):
		var sprite := Sprite3D.new()
		sprite.texture = _tiny_texture()
		_set_props(sprite, d.sprite)
		return sprite
	if d.get("skinned", false) and ResourceLoader.exists(str(d.get("scene", ""))):
		var model := (load(str(d.scene)) as PackedScene).instantiate()   # its bones move its mesh: the skinning shader
		if model is Node3D:
			for mi: Node in model.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = mat
				(mi as MeshInstance3D).cast_shadow = shadow
			(model as Node3D).scale = Vector3.ONE * 0.1
			return model
		model.free()
	var box := _box_mesh()
	if d.get("instanced", false):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = box
		mm.instance_count = 1
		mm.set_instance_transform(0, Transform3D.IDENTITY)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.custom_aabb = AABB(-Vector3.ONE, Vector3.ONE * 2.0)   # never culled in its one frame: the MultiMesh's own
		# box is only worked out as it is drawn (the first stages drew no instanced shader at all)
		mmi.material_override = mat
		mmi.cast_shadow = shadow
		return mmi
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = shadow
	return mi


static func _set_props(n: Object, props: Dictionary) -> void:
	for p: String in props:
		n.set(p, props[p])


static func _box_mesh() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE * 0.2
	return _box


static func _tiny_texture() -> ImageTexture:
	if _tiny == null:
		_tiny = ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	return _tiny


## The REALISTIC style's sky (every PanoramaSkyMaterial shares the engine's one panorama shader).
static func _realistic_sky() -> PanoramaSkyMaterial:
	var sky := PanoramaSkyMaterial.new()
	sky.panorama = load(WorldService.REALISTIC_SKY) if RealisticPack.file_present(WorldService.REALISTIC_SKY) \
		else _tiny_texture()   # the same sky shader without its picture
	return sky


## Every material a warm-up built (kept: their shaders stay compiled).
static func kept() -> Array:
	return _keep


## The census (CENSUS_PATH), read once; numbers that JSON made floats are whole numbers again (enum settings).
static func census_draws() -> Array:
	if _census_cache == null:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CENSUS_PATH)) \
			if FileAccess.file_exists(CENSUS_PATH) else null
		var draws: Array = (parsed as Dictionary).get("draws", []) if parsed is Dictionary else []
		_census_cache = _whole_numbers(draws)
	return _census_cache


static func _whole_numbers(v: Variant) -> Variant:
	if v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	if v is Array:
		return (v as Array).map(func(x: Variant) -> Variant: return _whole_numbers(x))
	if v is Dictionary:
		var out := {}
		for k: Variant in v:
			out[k] = _whole_numbers(v[k])
		return out
	return v


## The lines a HUD draws (the 2D canvas' primitive shader).
class Lines extends Node2D:
	func _draw() -> void:
		draw_line(Vector2.ZERO, Vector2(8, 8), Color.WHITE, 1.0)


## What makes `material`'s shader: {"class", "props": {setting: value that differs from a new one}} for a
## BaseMaterial3D (colours, textures and other uniforms left out), {"class", "shader"} for a ShaderMaterial,
## {"class": "default"} for none (the engine's default material), and "next_pass" when it has one.
static func describe(material: Material) -> Dictionary:
	if material == null:
		return {"class": "default"}
	var d := {"class": material.get_class()}
	if material is ShaderMaterial:
		var shader := (material as ShaderMaterial).shader
		if shader and shader.resource_path != "":
			d.shader = shader.resource_path
		elif shader:
			d.code = shader.code
	elif material is BaseMaterial3D:
		d.props = _shader_props(material)
	if material.next_pass:
		d.next_pass = describe(material.next_pass)
	return d


## One string per shader: descriptions with the same key draw with the same compiled programs.
static func key(description: Dictionary) -> String:
	return JSON.stringify(description, "", true)


## A material with the shader of `description` (null for the default material).
static func build(description: Dictionary) -> Material:
	var cls := str(description.get("class", "default"))
	if cls == "default" or not ClassDB.can_instantiate(cls):
		return null
	var m: Material = ClassDB.instantiate(cls)
	if m is ShaderMaterial:
		if description.has("shader") and ResourceLoader.exists(str(description.shader)):
			(m as ShaderMaterial).shader = load(str(description.shader))
		elif description.has("code"):
			var s := Shader.new()
			s.code = str(description.code)
			(m as ShaderMaterial).shader = s
	elif m is BaseMaterial3D:
		var props: Dictionary = description.get("props", {})
		for p: String in props:
			m.set(p, props[p])
	if description.has("next_pass"):
		m.next_pass = build(description.next_pass)
	return m


static func _shader_props(material: BaseMaterial3D) -> Dictionary:
	var cls := material.get_class()
	if not _defaults.has(cls):
		var fresh: Object = ClassDB.instantiate(cls)
		var defaults := {}
		for p: Dictionary in fresh.get_property_list():
			if p.usage & PROPERTY_USAGE_STORAGE and (p.type == TYPE_BOOL or p.type == TYPE_INT) \
					and not NOT_SHADER.has(p.name):
				defaults[p.name] = fresh.get(p.name)
		_defaults[cls] = defaults
	var out := {}
	var defaults: Dictionary = _defaults[cls]
	for p: String in defaults:
		var v: Variant = material.get(p)
		if v != defaults[p]:
			out[p] = v
	return out

# --- The census: what the game draws ------------------------------------------------------------------------------

## Every way something under `root` is drawn in the game's own world, once each (hidden nodes too: a ring or a
## highlight shows later): {"material": describe(...), "instanced": particles or a MultiMesh, "shadow": it casts one,
## "skinned": bones move it (with "scene": the scene that has it)}, {"label": its settings} for a Label3D and
## {"sprite": ...} for a Sprite3D (the engine makes their materials). What a SubViewport with a world of its own draws
## is left out: other lights, another sky.
static func draws_of(root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pair: Array in draws_and_nodes(root):
		out.append(pair[0])
	return out


## draws_of with the first node seen drawing each: [[draw, node], ...] (the census notes where it saw them).
static func draws_and_nodes(root: Node) -> Array[Array]:
	var seen := {}
	var out: Array[Array] = []
	for n: Node in [root] + root.find_children("*", "GeometryInstance3D", true, false):
		if n is GeometryInstance3D and not _in_own_world(n, root) and not n.is_in_group(GROUP):
			for d: Dictionary in _draws(n):
				var k := key(d)
				if not seen.has(k):
					seen[k] = true
					out.append([d, n])
	return out


## The keys of the draws under `root` that are on screen: any node drawing them is visible in the tree and, with a
## `camera`, within SHOWN_RADIUS of it or one of the sky's bodies (SKY) (the census's `shown`; ShaderWarmup.tier).
static func visible_keys(root: Node, camera: Camera3D = null) -> Dictionary:
	var out := {}
	for n: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if camera and g.global_position.distance_to(camera.global_position) > SHOWN_RADIUS and not _in_sky(g):
			continue
		if g.is_visible_in_tree() and not _in_own_world(g, root) and not g.is_in_group(GROUP):
			for d: Dictionary in _draws(g):
				out[key(d)] = true
	return out


static func _in_sky(n: Node) -> bool:
	var p := n
	while p != null:
		if p.is_in_group(SKY):
			return true
		p = p.get_parent()
	return false


static func _in_own_world(n: Node, root: Node) -> bool:
	var p := n.get_parent()
	while p and p != root.get_parent():
		if p is SubViewport and ((p as SubViewport).own_world_3d or (p as SubViewport).world_3d != null):
			return true
		p = p.get_parent()
	return false


static func _draws(g: GeometryInstance3D) -> Array[Dictionary]:
	if g is Label3D:
		return [{"label": _node_props(g, LABEL_PROPS)}]
	if g is SpriteBase3D:
		return [{"sprite": _node_props(g, SPRITE_PROPS)}]
	var shadow := g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh: Mesh = null
	var instanced := false
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D:
		instanced = true
		var mm := (g as MultiMeshInstance3D).multimesh
		mesh = mm.mesh if mm else null
	elif g is CPUParticles3D:
		instanced = true
		mesh = (g as CPUParticles3D).mesh
	var mats: Array[Material] = []
	if g.material_override:
		mats.append(g.material_override)
	elif mesh:
		for i in mesh.get_surface_count():
			var m: Material = (g as MeshInstance3D).get_surface_override_material(i) if g is MeshInstance3D else null
			mats.append(m if m else mesh.surface_get_material(i))
	if g.material_overlay:
		mats.append(g.material_overlay)
	var skinned := g is MeshInstance3D and ((g as MeshInstance3D).skin != null or (mesh is ArrayMesh
		and mesh.get_surface_count() > 0 and (mesh as ArrayMesh).surface_get_format(0) & Mesh.ARRAY_FORMAT_BONES != 0))
	var out: Array[Dictionary] = []
	for m in mats:
		var d := {"material": describe(m), "instanced": instanced, "shadow": shadow}
		if skinned:
			d.skinned = true
			d.scene = _scene_of(g)
		out.append(d)
	return out


static func _node_props(n: Node, names: Array) -> Dictionary:
	var fresh: Node = ClassDB.instantiate(n.get_class())
	var out := {}
	for p: String in names:
		if p in n and n.get(p) != fresh.get(p):
			out[p] = n.get(p)
	fresh.free()
	return out


static func _scene_of(n: Node) -> String:
	var p := n
	while p:
		if p.scene_file_path != "":
			return p.scene_file_path
		p = p.get_parent()
	return ""
