extends Node
## Scene flow (menu <-> sandbox) and applying settings from the profile.

signal settings_applied(settings: Dictionary)

const MENU_SCENE := "res://ui/menus/menu.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox.tscn"
const SANDBOX_SLOT := "sandbox_1"   # Green Meadows' Sandbox world (owner 39: ModeRules.slot per universe)

## The mode of the world being played (ModeRules.SANDBOX or ModeRules.SURVIVOR); set before the
## world scene loads. A LAN client takes the host's.
var mode: StringName = ModeRules.SANDBOX
## The universe of the world being played (M3 Task 5, UniverseRules; owner 39: Sandbox and Monster Wave worlds too):
## its save slot, terrain, music, sky and scaling (never in Sandbox). Set before the world scene loads; a LAN guest
## takes the host's.
var universe := 1

## Read by the sandbox scene when it starts.
var start_new_world := false
## A new Survivor world's difficulty (M2 Task 17), chosen in the menu.
var new_world_difficulty: StringName = DifficultyRules.NORMAL
## Survivor games (spec §12.18): a new Survivor world's game, chosen in the menu after its difficulty, and
## the game of the world being played (the sandbox sets it from the world; a LAN guest takes the host's).
var new_world_game: StringName = SurvivorGames.CLASSIC
var survivor_game: StringName = SurvivorGames.CLASSIC
## &"solo", &"host" (developer LAN host) or &"client" (developer LAN join).
var net_mode: StringName = &"solo"
var join_address := "127.0.0.1"
## Developer: run the acceptance autopilot in the next sandbox session.
var autopilot := false
## Developer: the autopilot first brings 10 house-sized buddies to life around the player (the
## owner's "too much magic -> 3 FPS" scenario, feedback #9).
var autopilot_buddies := false
## Developer: the next autopilot runs at night with a full player's worth of monsters around it (M2
## Task 12, acceptance row 13; the developer menu's NIGHT RUN).
var autopilot_night := false
## Developer: the next autopilot runs in a new Survivor world of this universe (1 = the Sandbox, as
## before; M3 acceptance: every universe; the developer menu's WORLD).
var autopilot_universe := 1
## Developer: run the acceptance tour (tools/tour.gd, M1b Task 14) in the next sandbox session.
var autopilot_tour := false
## Developer: the seed of the next new world (0 = random); lets a tour run be repeated.
var new_world_seed := 0
## Worlds left for the menu in this run (M7: the menu's "Add EasyCraft to this device" card waits for some play).
var worlds_left := 0
## Changes the scene (tests record it instead).
var change_scene := func(path: String) -> void: get_tree().change_scene_to_file(path)


func _ready() -> void:
	apply_settings.call_deferred()


func start_sandbox(new_world: bool) -> void:
	start_world(ModeRules.SANDBOX, new_world)


func start_survivor(new_world: bool) -> void:
	start_world(ModeRules.SURVIVOR, new_world)


## Solo play in `world_mode`'s own world (both modes run in the same world scene); Survivor in
## `world_universe`'s world (M3 Task 5), a new one playing `game` (spec §12.18).
func start_world(world_mode: StringName, new_world: bool, difficulty: StringName = DifficultyRules.NORMAL,
		world_universe: int = 1, game: StringName = SurvivorGames.CLASSIC) -> void:
	new_world_difficulty = KnockoutRules.valid_difficulty(difficulty)
	new_world_game = SurvivorGames.valid(game)
	mode = ModeRules.valid(world_mode)
	universe = ModeRules.world_universe(mode, world_universe)   # owner 39: every mode keeps its universe (Sandbox's worlds, Monster Wave's arenas)
	net_mode = &"solo"
	start_new_world = new_world
	get_tree().paused = false
	get_tree().change_scene_to_file(SANDBOX_SCENE)


## Whether the current mode allows `rule` (ModeRules).
func allows(rule: StringName) -> bool:
	return ModeRules.allows(mode, rule)


func slot() -> String:
	return ModeRules.slot(mode, universe)


## Developer LAN mode: host this mode's saved world (Game.mode) for other devices on this network.
func host_lan_game() -> void:
	net_mode = &"host"
	start_new_world = false
	get_tree().paused = false
	get_tree().change_scene_to_file(SANDBOX_SCENE)


## Developer LAN mode: join a host. The sandbox scene connects once it is loaded.
func join_lan_game(address: String) -> void:
	net_mode = &"client"
	join_address = address
	get_tree().paused = false
	get_tree().change_scene_to_file(SANDBOX_SCENE)


func quit_to_menu() -> void:
	worlds_left += 1
	autopilot = false
	autopilot_buddies = false
	autopilot_night = false
	autopilot_universe = 1
	autopilot_tour = false
	new_world_seed = 0
	Session.close()
	net_mode = &"solo"
	get_tree().paused = false
	change_scene.call(MENU_SCENE)


func apply_settings() -> void:
	var s := Profile.data.settings
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(s.volume), 0.0001)))
	var preset := GraphicsPreset.params(s.graphics)
	var vp := get_viewport()
	vp.scaling_3d_scale = preset.scale_3d
	vp.msaa_3d = preset.msaa
	Fx.particle_scale = float(preset.particles)   # M5 Task 3: LOW draws half the particles
	Lang.apply()   # owner #52: English only
	settings_applied.emit(s)
