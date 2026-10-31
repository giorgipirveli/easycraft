extends Node
## M7 (docs/devlog/parts/m7-shader-warmup.md): phases of play for the shader measurements. scenes/main.gd adds this node
## for the developer arg --shader-probe=<phases> (comma-separated, in order):
##   new        a new Sandbox world (seed 20260923), until the child stands in it and a little longer
##   continue   CONTINUE: the saved Sandbox world of Green Meadows
##   play       the first minute: walk, jump, place and break blocks, animals, water (and under it), night with lanterns
##   creatures  every animal, every monster and boss, a bot friend, at night
##   features   weather, Size Magic, stamps, weapons, dances, a secret, the photo, the building tools (chat commands)
##   universes  a new Sandbox world in each other universe (desert, frost, candy, dragons): night, weather, its boss
##   glow       (and every WORLDS name) a world's landing: new Sandbox and Survivor worlds of it, once round the landing
##   moon       fly up through the space line and land on the Moon
##   realistic  switch to REALISTIC (waits for its pictures), look around, walk, an animal
##   leaf       Inside a Leaf's two voyages, opened from the menu (counted in the menu's phase: FIRST)
## --shader-probe-style=realistic makes REALISTIC the saved style before the menu (a REALISTIC child's start).
## Each phase prints `PROBE phase=<name>` as it starts; `PROBE done` at the end (the world saved, BLOCKY again, back
## to the menu). The page's phase is `boot` until `MENU ready`, then `menu` (this node waits MENU_SECONDS there).
## tools/web_shader_probe.py counts the WebGL programs each phase links in a browser.
##
## --shader-census=<file> also writes what the game draws (ShaderWarmup.draws_of the whole tree, every CENSUS_EVERY
## seconds, with the styles and phases each was seen in) as JSON: data/shader_warmup.json is made this way, on the
## desktop with the browser's renderer settings (a new world replaces the Sandbox slot: a private user folder):
##   XDG_DATA_HOME=/tmp/easycraft-census godot --headless --rendering-method gl_compatibility --path . -- \
##     --shader-probe=new,play,creatures,features,universes,moon,realistic --shader-census=res://data/shader_warmup.json
## Times are the wall clock (headless Chrome draws a few frames a second).

const MENU_SECONDS := 12.0
const SETTLE_SECONDS := 10.0
const SPAWN_TIMEOUT := 240.0
const CENSUS_EVERY := 0.5   # short-lived draws (a burst, a pop) are on screen for about that long
const SEED := 20260923
const ANIMALS: Array[StringName] = [&"dog", &"cow", &"pig", &"chicken", &"sheep", &"cat", &"rabbit", &"horse", &"fox",
	&"parrot", &"duck", &"frog"]
## The frame spikes (2026-09-30): each world's landing in a phase of its own, named as ShaderWarmup.world_phases names
## it: what the census sees on screen there is what that world's loading card waits for (ShaderWarmup.world_part).
## A new Sandbox world of it, standing, then a flight round the landing (LANDING_R) so its sights near the pad are seen.
const WORLDS := {"desert": 2, "frost": 3, "candy": 4, "dragon": 5, "boing": 17, "rainbow": 18, "mars": 19,
	"europa": 20, "io": 21, "titan": 22, "mercury": 23, "venus": 24, "rings": 25, "pluto": 26, "triton": 27, "ganymede": 28,
	"wonders": 41, "glow": 6}
## The census's phase between worlds (the world left behind, the loading, a rocket flight): no world's landing.
const TRAVEL := "travel"
const LANDING_R := 30.0          # the flight round a landing: this far out ...
const LANDING_UP := 5.0          # ... this high over the landing's ground
const LANDING_SECONDS := 12.0    # ... once round in this long

var phases: PackedStringArray = []
var menu_seconds := MENU_SECONDS
var census_path := ""
var phase := "menu"
var _census := {}   # key -> draw (with "styles" and "phases")
var _census_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MOON)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shader-probe="):
			phases = a.trim_prefix("--shader-probe=").split(",", false)
		elif a.begins_with("--shader-census="):
			census_path = a.trim_prefix("--shader-census=")
		elif a.begins_with("--shader-probe-menu="):   # seconds on the menu before the phases (a child who taps at once)
			menu_seconds = float(a.trim_prefix("--shader-probe-menu="))
		elif a.begins_with("--shader-probe-style="):   # the saved style from the start (before the menu's warm-up)
			Profile.data.settings["style"] = a.trim_prefix("--shader-probe-style=")
	_run.call_deferred()


func _process(delta: float) -> void:
	if census_path == "":
		return
	_census_t -= delta
	if _census_t <= 0.0:
		_census_t = CENSUS_EVERY
		_take_census()


func _run() -> void:
	await _until(func() -> bool: return _scene_is(Game.MENU_SCENE), 120.0)
	# MENU ready: after the shader warm-up where there is one (a menu of a build before it has no `announced`)
	await _until(func() -> bool: return get_tree().current_scene.get("announced") != false, 300.0)
	await _sleep(menu_seconds)
	for p: String in phases:
		phase = p
		print("PROBE phase=%s" % p)
		match p:
			"new":
				Game.new_world_seed = SEED
				Game.start_sandbox(true)
				await _world_stands()
				if census_path != "":
					await _census_prewarms()
			"continue":
				phase = TRAVEL
				Game.universe = 1
				Game.start_sandbox(false)
				await _world_stands(p)
			"play":
				await _play()
			"creatures":
				await _creatures()
			"features":
				await _features()
			"universes":
				await _universes()
			"moon":
				await _moon()
			"newseven":
				await _new_seven()
			"survivor":   # a new Survivor world of Green Meadows (a first world: ShaderWarmup.WORLD_PHASES)
				await _visit_in(ModeRules.SURVIVOR, 1, p)
			"realistic":
				await _realistic()
			"leaf":   # owner #133, #134: Inside a Leaf opens from the menu's School: what it draws is the menu's (FIRST)
				phase = "menu"
				await _leaf()
			_:
				if WORLDS.has(p):   # a world's landing, in a phase named after it (ShaderWarmup.world_phases)
					await _visit(int(WORLDS[p]), p)
	phase = "end"
	print("PROBE phase=end")
	var sandbox := _sandbox()
	if sandbox:
		_set_style("blocky")
		sandbox.call("save_world")
		await _sleep(3.0)
		Game.quit_to_menu()
		await _sleep(4.0)
	if census_path != "":
		_take_census()
		_write_census()
	print("PROBE done")
	if census_path != "" and not OS.has_feature("web"):
		get_tree().quit()


func _sandbox() -> Node:
	var s := get_tree().current_scene
	return s if s and s.scene_file_path == Game.SANDBOX_SCENE else null


func _player() -> Player:
	var s := _sandbox()
	return s.get("player") as Player if s else null


func _scene_is(path: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == path


func _sleep(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _until(cond: Callable, timeout: float) -> bool:
	var until := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < until:
		if cond.call():
			return true
		await get_tree().process_frame
	print("PROBE timeout")
	return false


## Until the world's player stands in it (spawned: the terrain under the feet is there), then SETTLE_SECONDS more.
func _world_stands(arrived: String = "") -> void:
	await _until(func() -> bool: return _scene_is(Game.SANDBOX_SCENE), 60.0)
	await _until(func() -> bool:
		var p := _player()
		return p != null and p.is_spawned(), SPAWN_TIMEOUT)
	if arrived != "":   # the census's phase from here: the world before and the way here are not this world's
		phase = arrived
	await _sleep(SETTLE_SECONDS)


func _play() -> void:
	var sandbox := _sandbox()
	var p := _player()
	if sandbox == null or p == null:
		return
	var it: BlockInteractor = p.get_node("BlockInteractor")
	var center := get_viewport().get_visible_rect().size * 0.5
	# walk and jump
	Input.action_press(&"move_forward")
	await _sleep(3.0)
	for i in 2:
		Input.action_press(&"jump")
		await _sleep(0.3)
		Input.action_release(&"jump")
		await _sleep(0.8)
	Input.action_release(&"move_forward")
	# place and break (the pop, the ring, the break particles)
	p.rig.pitch = -0.9
	for id: int in [BlockIds.PLANKS, BlockIds.GLASS, BlockIds.LANTERN, BlockIds.LEAVES]:
		it.set_slot_block(0, id)
		it.select_slot(0)
		it.place_at_screen(center + Vector2(0, 60))
		await _sleep(1.0)
	for i in 2:
		it.break_at_screen(center + Vector2(0, 60))
		await _sleep(1.0)
	p.rig.pitch = -0.2
	# animals
	for species: StringName in ANIMALS:
		sandbox.call("summon_animal", species, p.global_position)
	await _sleep(8.0)
	# water in front, then under it
	var feet := Vector3i(p.global_position.floor())
	var ahead := feet + Vector3i(0, 0, -3)
	for x in range(-2, 3):
		for z in range(-2, 3):
			p.world.set_block(ahead + Vector3i(x, -1, z), BlockIds.WATER)
	await _sleep(4.0)
	for x in range(-1, 2):
		for z in range(-1, 2):
			for y in range(0, 3):
				p.world.set_block(feet + Vector3i(x, y, z), BlockIds.WATER)
	await _sleep(4.0)
	for x in range(-1, 2):
		for z in range(-1, 2):
			for y in range(0, 3):
				p.world.set_block(feet + Vector3i(x, y, z), BlockIds.AIR)
	# night, with lanterns around
	sandbox.call("set_time_of_day", 0.0)
	for d: Vector3i in [Vector3i(2, 0, 0), Vector3i(-2, 0, 0), Vector3i(0, 0, 2)]:
		p.world.set_block(feet + d, BlockIds.LANTERN)
	await _sleep(8.0)
	# a cave: a roof over the head (the player's lantern)
	for x in range(-2, 3):
		for z in range(-2, 3):
			p.world.set_block(feet + Vector3i(x, 4, z), BlockIds.STONE)
	await _sleep(6.0)
	sandbox.call("set_time_of_day", 0.5)
	await _sleep(6.0)


## Every animal, every monster (level 1) and boss, a bot friend: at night, one kind at a time.
func _creatures() -> void:
	var sandbox := _sandbox()
	var p := _player()
	if sandbox == null or p == null:
		return
	var chat: Node = sandbox.get_node_or_null("ChatCommands")
	sandbox.call("set_time_of_day", 0.0)
	for species: String in ChatCommands.ANIMALS:
		sandbox.call("summon_animal", StringName(species), p.global_position)
		await _sleep(0.5)
	await _sleep(4.0)
	for kind: String in ChatCommands.MONSTERS:
		sandbox.call("summon_monster", StringName(kind), 1, p.global_position + Vector3(4, 0, 0))
		await _sleep(1.0)
	await _sleep(4.0)
	for boss: String in ChatCommands.BOSSES:
		if chat:
			chat.call("run", "/summon %s" % boss)
		await _sleep(4.0)
	if chat:
		chat.call("run", "/bot add builder")
		chat.call("run", "/peace on")
	await _sleep(6.0)
	sandbox.call("set_time_of_day", 0.5)
	await _sleep(3.0)


func _chat(line: String) -> void:
	var sandbox := _sandbox()
	var chat: Node = sandbox.get_node_or_null("ChatCommands") if sandbox else null
	if chat:
		chat.call("run", line)


## What chat commands show: weather, Size Magic, stamps, weapons, dances and emotes, a secret, the photo, the tools.
func _features() -> void:
	var p := _player()
	if p == null:
		return
	var it: BlockInteractor = p.get_node("BlockInteractor")
	var center := get_viewport().get_visible_rect().size * 0.5
	for line: String in ["/weather rain", "/weather snow", "/weather clear", "/size giant", "/size tiny", "/size normal",
			"/build house", "/build rainbow", "/build tree", "/dance", "/emote wave", "/emote cheer", "/secret treasure",
			"/find treasure", "/kit", "/fill glass 3", "/copy", "/pet", "/bot add explorer", "/bot add fighter"]:
		_chat(line)
		await _sleep(1.5)
	for item: String in ["sword", "bow", "blaster", "wand", "axe"]:
		_chat("/give %s" % item)
		it.select_slot(0)
		await _sleep(0.5)
		it.place_at_screen(center)
		await _sleep(0.5)
		it.break_at_screen(center + Vector2(0, 60))
		await _sleep(1.0)
	_chat("/photo")
	await _sleep(3.0)
	Input.action_press(&"pause")
	await _sleep(0.2)
	Input.action_release(&"pause")
	await _sleep(2.0)
	Input.action_press(&"pause")
	await _sleep(0.2)
	Input.action_release(&"pause")
	await _sleep(2.0)


## A new Sandbox world in each other universe: its terrain, night, its weather and boss. Its landing (standing and the
## flight round it) is recorded in a phase named after the world (the census: what its loading card waits for).
func _universes() -> void:
	for u in [2, 3, 4, 5]:
		await _visit_in(ModeRules.SURVIVOR, u, ShaderWarmup.world_phases(u)[0])
		await _visit_in(ModeRules.SANDBOX, u, ShaderWarmup.world_phases(u)[0])   # its night and boss below: the Sandbox's
		phase = "universes"
		var sandbox := _sandbox()
		if sandbox == null:
			continue
		sandbox.call("set_time_of_day", 0.0)
		for line: String in ["/weather sandstorm", "/weather snow", "/boss"]:
			_chat(line)
			await _sleep(2.0)
		await _sleep(4.0)
		sandbox.call("set_time_of_day", 0.5)
		await _sleep(2.0)


## A new Sandbox world of world `u`: until the child stands in it (the phase TRAVEL), then in phase `arrived` (the
## world's name) standing and once round its landing.
func _visit(u: int, arrived: String) -> void:
	await _visit_in(ModeRules.SANDBOX, u, arrived)
	await _visit_in(ModeRules.SURVIVOR, u, arrived)   # a Survivor world's spawn has the portal hub's circle too


## A new world of `mode` in world `u`, the census's phase TRAVEL until the child stands in it, then `arrived`: standing,
## then once round the landing.
func _visit_in(mode: StringName, u: int, arrived: String) -> void:
	var before := _sandbox()
	var left := before.get_instance_id() if before else 0
	phase = TRAVEL
	Game.new_world_seed = SEED
	Game.start_world(mode, true, DifficultyRules.NORMAL, u)
	await _until(func() -> bool: return _sandbox() != null and _sandbox().get_instance_id() != left, 120.0)
	await _world_stands(arrived)
	await _round_the_landing()


## Once round the landing, flying (the camera sees the pad's neighbours: the robots, the aliens' camp, a colony, a
## base), then back where the child stood.
func _round_the_landing() -> void:
	var p := _player()
	if p == null:
		return
	var centre := p.global_position
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(LANDING_SECONDS * 1000.0):
		var a := TAU * (Time.get_ticks_msec() - t0) / (LANDING_SECONDS * 1000.0)
		p.global_position = centre + Vector3(cos(a) * LANDING_R, LANDING_UP, sin(a) * LANDING_R)
		p.velocity = Vector3.ZERO
		p.rig.yaw = atan2(-cos(a), -sin(a))   # looking out (forward is Basis(UP, yaw) * FORWARD)
		await get_tree().process_frame
	p.global_position = centre
	p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	await _sleep(2.0)


## World 41's second tour: the New Seven Wonders' square at the end of the Wonders Road (it needs world 41: "wonders"
## first), standing on it, then once round it.
func _new_seven() -> void:
	var p := _player()
	if p == null or Game.universe != EarthRules.WONDERS:
		return
	var c := WonderTour.NEW_SQUARE
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	p.global_position = Vector3(c.x + 0.5, WonderTour.BASE_Y + 3.0, c.y + 0.5)
	await _until(func() -> bool: return p.world.is_area_ready(p.global_position), 60.0)
	p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	await _sleep(SETTLE_SECONDS)
	await _round_the_landing()


func _moon() -> void:
	var sandbox := _sandbox()
	var p := _player()
	if sandbox == null or p == null:
		return
	var space: SpaceDirector = sandbox.get("space")
	phase = TRAVEL   # the climb and the flight (the world left behind, the rocket): "moon" once the child stands there
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	var until := Time.get_ticks_msec() + 60000
	while not space.panel.visible and Time.get_ticks_msec() < until:
		p.global_position.y = minf(p.global_position.y + 1.5, SpaceRules.SPACE_Y + 2.0)
		await get_tree().process_frame
	if space.panel.visible:
		space.panel.body_for(&"moon").pressed.emit()
		space.panel.action_button.pressed.emit()
	else:
		sandbox.call("travel_to_space", SpaceRules.MOON)
	var left := sandbox.get_instance_id()
	await _until(func() -> bool: return _sandbox() != null and _sandbox().get_instance_id() != left, 120.0)
	await _world_stands("moon")
	var moon_p := _player()
	if moon_p:
		Input.action_press(&"move_forward")
		await _sleep(4.0)
		Input.action_release(&"move_forward")
	await _sleep(4.0)
	await _round_the_landing()


func _realistic() -> void:
	_set_style("realistic")
	await _until(func() -> bool: return BlockLibrary.style == "realistic", 400.0)
	await _sleep(8.0)
	var sandbox := _sandbox()
	var p := _player()
	if sandbox and p:
		sandbox.call("summon_animal", &"dog", p.global_position)
		sandbox.call("summon_animal", &"pip", p.global_position)   # Pip is shiny metal in REALISTIC
		_chat("/bot add builder")   # a bot friend's realistic body
		Input.action_press(&"move_forward")
		await _sleep(4.0)
		Input.action_release(&"move_forward")
		await _sleep(6.0)


## Inside a Leaf (owner #133, #134; docs/devlog/parts/game-leaf-b.md, finding 5): both voyages opened from the menu, as
## the School's PLAY opens them, and played through quickly: the garden, the dive, the leaf's inside (the sunflower's
## and the cactus's, by day and by night, every door open and the mist pouring), the return, the world's answer and the
## end card. Its draws are seen in the menu's phase, so the warm-up holds them before a child can open a voyage.
func _leaf() -> void:
	for voyage: String in ["5.1", "5.T1"]:
		var unit := "g5.science.plants_air_water"
		var host := LeafVoyageHost.new()
		host.progress_path = "user://census_leaf_voyage.json"
		host.setup(unit, {"id": unit, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage}}},
			SEED, 0, {})
		host.open(get_tree().current_scene)
		await _sleep(2.0)
		host.water_now()
		await _sleep(1.0)
		host.tap_target("leaf")
		await _until(func() -> bool: return host.journey.stage == LeafJourney.INSIDE, 30.0)
		await _sleep(3.0)
		host.place.show_all(false)
		await _sleep(2.0)
		host.place.show_all(true)
		await _sleep(2.0)
		host.journey.run.phase = LeafRun.DONE   # the bud full: the return, the answer, the end card
		await _until(func() -> bool: return host.journey.stage == LeafJourney.END, 40.0)
		await _sleep(2.0)
		host.end_choice(LeafVoyageHost.BACK)
		await _sleep(1.0)


func _set_style(style: String) -> void:
	Profile.data.settings["style"] = style
	Profile.save()
	Game.apply_settings()

# --- The census (--shader-census) ---

## The world's prewarms, drawn once for the census in a phase of their own ("prewarm"): where a warm-up runs they are
## left to it (ShaderWarmup.at_spawn), so what only they draw (the desert portal's window) must be in the census.
func _census_prewarms() -> void:
	var p := _player()
	var sandbox := _sandbox()
	if p == null or sandbox == null:
		return
	var was := phase
	phase = "prewarm"
	var cam := p.camera()
	Fx.prewarm(cam)
	ThoughtBubble.prewarm(cam)
	DesertPortal.prewarm(cam)
	PortalSwirl.prewarm(cam)
	GameRing.prewarm(cam)
	var blasters: Variant = sandbox.get("_blasters")
	if blasters is BlasterDirector:
		(blasters as BlasterDirector).prewarm(cam)
	var interactor := p.get_node_or_null("BlockInteractor") as BlockInteractor
	if interactor:
		interactor.prewarm_feedback()
	await get_tree().process_frame
	_take_census()
	await _sleep(1.0)   # until they are gone (BreakRing.PREWARM_SECONDS, the holders' 0.25 s): not seen in play
	phase = was

func _take_census() -> void:
	var style := str(Profile.data.settings.get("style", "blocky"))
	var on_screen := ShaderWarmup.visible_keys(get_tree().root, get_viewport().get_camera_3d())   # near the camera
	for pair: Array in ShaderWarmup.draws_and_nodes(get_tree().root):
		var d: Dictionary = pair[0]
		var k := ShaderWarmup.key(d)
		if not _census.has(k):
			var entry := d.duplicate(true)
			entry.styles = []
			entry.phases = []
			entry.shown = []
			entry.at = _where(pair[1])
			_census[k] = entry
		var e: Dictionary = _census[k]
		if not (e.styles as Array).has(style):
			(e.styles as Array).append(style)
		if not (e.phases as Array).has(phase):
			(e.phases as Array).append(phase)
		# On screen (a node drawing it is visible), not only there: ShaderWarmup.tier puts what the menu and a first world
		# show before the menu.
		if on_screen.has(k) and not (e.shown as Array).has(phase):
			(e.shown as Array).append(phase)


## Where a draw was first seen: the node's path under the scene (its last parts) and the nearest script up the tree.
static func _where(n: Node) -> String:
	var parts := str(n.get_path()).split("/", false)
	var script := ""
	var p := n
	while p and script == "":
		var s: Script = p.get_script()
		script = s.resource_path.get_file() if s else ""
		p = p.get_parent()
	return "%s (%s)" % ["/".join(parts.slice(maxi(parts.size() - 4, 0))), script]


func _write_census() -> void:
	var keys := _census.keys()
	keys.sort()
	var draws: Array = []
	for k: String in keys:
		draws.append(_census[k])
	var f := FileAccess.open(census_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "made_by": "tools/shader_probe_steps.gd --shader-census",
		"phases": Array(phases), "draws": draws}, "\t", false) + "\n")
	f.close()
	print("PROBE census %d draws -> %s" % [draws.size(), census_path])
