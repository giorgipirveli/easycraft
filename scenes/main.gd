extends Control
## Boot entry point. Builds tagged "spike" open the Voxel Tools feasibility scene; the developer
## user args --auto-host / --auto-join=<ip> skip the menu and start a LAN session, and --tour
## (optionally --tour-seed=<n>) runs the acceptance tour in a new Sandbox world (with --survivor: the
## M2 tour in a new Survivor world). --survivor alone opens the
## Survivor world (--new-world starts a new one; --auto-host with it hosts Survivor on LAN).
## M3 Task 5: --universe=<u> with --survivor (or --auto-host --survivor) opens that universe's world.
## M4 early spike: --online-host / --online-join=<match id> play over the Nakama server instead of
## LAN (_start_online), and --net-test runs the two-instance check (tools/net_test.gd) on either.
## --autopilot-night runs the performance autopilot at night with monsters in the Sandbox world.
## M7: --shader-probe=<phases> plays the shader measurement's phases (tools/shader_probe_steps.gd).
## Owner #79, #87: --fly-moon, --fly=<world> (a test rocket flies there from the Sandbox world, or with --survivor the
## Survivor world) and --land=<world> (the Star Map's landing on its own) try the rocket flight (FlightTicket).


func _ready() -> void:
	PlatformRules.apply_ui_scale(get_window(), PlatformRules.current())   # owner #84: PC-sized menus and HUD on a PC
	PadFocus.install(get_tree().root)   # owner #90: a game controller's focus in every menu (it outlives the scenes)
	WebStorage.ask_persistent()   # M7: in a browser, ask once to keep the worlds' storage (no-op elsewhere)
	start_packs(get_tree().root)   # M7: in a browser, the music pack comes after the menu (no-op elsewhere)
	var args := Array(OS.get_cmdline_user_args())
	ShaderWarmup.apply_args(args)   # M7: --shader-warmup measures the warm-up where its rule is off
	if args.has("--net-test"):
		var net_test: Node = load("res://tools/net_test.gd").new()
		net_test.name = "NetTest"   # the same path on every instance: its RPCs need that
		get_tree().root.add_child.call_deferred(net_test)
	if args.any(func(a: String) -> bool: return a.begins_with("--shader-probe=")):   # M7: tools/web_shader_probe.py
		get_tree().root.add_child.call_deferred(load("res://tools/shader_probe_steps.gd").new())
	if OS.has_feature("spike"):
		get_tree().change_scene_to_file.call_deferred("res://spikes/voxel_spike.tscn")
	elif args.has("--auto-host"):
		if args.has("--survivor"):
			Game.mode = ModeRules.SURVIVOR
			Game.universe = _universe_arg(args)
		Game.host_lan_game.call_deferred()
	elif args.any(func(a: String) -> bool: return a.begins_with("--auto-join=")):
		var arg: String = args.filter(func(a: String) -> bool: return a.begins_with("--auto-join="))[0]
		Game.join_lan_game.call_deferred(arg.trim_prefix("--auto-join="))
	elif args.has("--online-host") or args.any(func(a: String) -> bool: return a.begins_with("--online-join=")):
		_start_online(args)
	elif args.has("--tour"):
		_start_tour(args)
	elif int(FlightTicket.from_args(args).destination) > 0:   # owner #79: the developer's test flight
		var fly := FlightTicket.from_args(args)
		FlightTicket.test_pending = int(fly.destination)
		FlightTicket.test_landing = bool(fly.landing)
		var survivor := args.has("--survivor")
		Game.start_world.call_deferred(ModeRules.SURVIVOR if survivor else ModeRules.SANDBOX, false,
			DifficultyRules.NORMAL, _universe_arg(args) if survivor else 1)
	elif args.has("--autopilot-night"):   # M2 Task 12: the dev menu's NIGHT RUN on the desktop
		Game.autopilot = true
		Game.autopilot_night = true
		Game.start_sandbox.call_deferred(false)
	elif args.has("--survivor"):
		_start_survivor(args)
	else:
		get_tree().change_scene_to_file.call_deferred(Game.MENU_SCENE)


## The tour starts a NEW world in the Sandbox slot. On a desktop that slot is shared by every
## worktree and the developer's own game, so it only runs with a private XDG_DATA_HOME there.
func _start_tour(args: Array) -> void:
	if not OS.has_feature("mobile") and OS.get_environment("XDG_DATA_HOME") == "":
		print("TOUR refused: set XDG_DATA_HOME to a private folder (the tour replaces the Sandbox world)")
		get_tree().quit.call_deferred(2)
		return
	for a: String in args:
		if a.begins_with("--tour-seed="):
			Game.new_world_seed = int(a.trim_prefix("--tour-seed="))
	Game.autopilot_tour = true
	if args.has("--survivor"):   # the M2 tour (tools/tour_survivor.gd) in a new Survivor world (Normal)
		Game.start_world.call_deferred(ModeRules.SURVIVOR, true)
	else:
		Game.start_sandbox.call_deferred(true)


## Developer: straight into the Survivor world. A new world replaces the Survivor slot, so on a desktop
## that needs a private XDG_DATA_HOME (like the tour).
func _start_survivor(args: Array) -> void:
	var fresh := args.has("--new-world")
	if fresh and not OS.has_feature("mobile") and OS.get_environment("XDG_DATA_HOME") == "":
		print("SURVIVOR refused: --new-world needs a private XDG_DATA_HOME (it replaces the Survivor world)")
		get_tree().quit.call_deferred(2)
		return
	Game.start_world.call_deferred(ModeRules.SURVIVOR, fresh, DifficultyRules.NORMAL, _universe_arg(args))


## Developer (M4 early spike): online play through the Nakama server (server/README.md). The host
## prints "ONLINE host match_id=<id>" once its match exists; a guest joins with --online-join=<id>.
## The world scene then hosts or joins as for LAN, and Session uses the relay (Session.wants_online).
func _start_online(args: Array) -> void:
	var cfg := OnlineConfig.from_args(args)
	if cfg.has("error"):
		print("ONLINE refused: %s" % cfg.error)
		get_tree().quit.call_deferred(2)
		return
	Session.online_config = cfg
	if cfg.role == OnlineConfig.HOST:
		if args.has("--survivor"):
			Game.mode = ModeRules.SURVIVOR
		Game.host_lan_game.call_deferred()
	else:
		Game.join_lan_game.call_deferred("")


## M7 (owner 2026-09-28): in a browser the first download leaves the music pack and the REALISTIC style's pictures out;
## WebContent (under `root`, so it outlives the scene changes) fetches them after the menu is up; Music and the worlds
## (RealisticPack) take them in. A child whose saved style is REALISTIC gets its pictures first (what they see).
## Null off the web. `f`: the platform ({}: this device).
static func start_packs(root: Node, f: Dictionary = {}) -> WebContent:
	var packs := WebContent.begin(root, f)
	if packs:
		packs.pack_loaded.connect(Music.on_pack_loaded)
		packs.pack_loaded.connect(RealisticPack.on_pack_loaded)
		packs.pack_loaded.connect(ReelPack.on_pack_loaded)   # owner #96: the Reel Studio's videos
		packs.first = func() -> String:
			return RealisticPack.PACK if str(Profile.data.settings.get("style", "")) == "realistic" else ""
		var platform := f if not f.is_empty() else PlatformRules.current()
		packs.later = func(pack_name: String) -> bool:
			if pack_name == ReelPack.PACK:   # an iPhone keeps its memory for the game until the Shorts are opened
				return PlatformRules.holds_big_packs(platform) and not ReelPack.wanted
			return pack_name == RealisticPack.PACK and PlatformRules.holds_big_packs(platform) \
				and str(Profile.data.settings.get("style", "")) != "realistic"
	return packs


## M3 Task 5: --universe=<u> (Survivor), 1 without it.
static func _universe_arg(args: Array) -> int:
	for a: Variant in args:
		if str(a).begins_with("--universe="):
			return UniverseRules.valid(int(str(a).trim_prefix("--universe=")))
	return 1
