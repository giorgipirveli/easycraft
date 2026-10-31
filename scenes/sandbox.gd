extends Node3D
## The world scene for both modes (Game.mode: Sandbox or Survivor, M2 §12.1); each mode keeps its own
## save slot. Solo and LAN host load (or create) the saved world; a LAN client builds its world
## from the host's seed and never saves. Players live under Players/ and are replicated by the
## MultiplayerSpawner. Saves every 60 s, on Save & Quit, and when the app is paused or closed.

const WORLD_SCENE := preload("res://world/world.tscn")
const PLAYER_SCENE_PATH := "res://entities/player/player.tscn"
const PLAYER_SCENE := preload(PLAYER_SCENE_PATH)
const AUTOSAVE_SECONDS := 60.0
const CLIENT_SPAWN_OFFSET := Vector3(2, 0, 1)
## A new Survivor world's hotbar (M2 §12.1): the starter kit first; empty-count slots wait for blocks.
const SURVIVOR_HOTBAR: Array[int] = [ItemIds.SWORD, ItemIds.PICKAXE, BlockIds.PLANKS, BlockIds.DIRT,
	BlockIds.STONE, BlockIds.LOG, BlockIds.SAND, BlockIds.GLASS, BlockIds.BRICK]

var world: WorldService
var player: Player          # the local player
var hud: Hud
var pause_menu: PauseMenu
var meta: WorldMeta

var _slot := Game.slot()
var _start_ms := Time.get_ticks_msec()
var _interactor: BlockInteractor
var _players := Node3D.new()
var _spawner := MultiplayerSpawner.new()
var _buddies := Node3D.new()
var _buddy_spawner := MultiplayerSpawner.new()
var _next_buddy := 1
var _animals := Node3D.new()
var _animal_spawner := MultiplayerSpawner.new()
var _director: AnimalDirector
var _next_summon := 1
var _combat := CombatDirector.new()   # weapons, arrows and practice targets (M1b Task 11)
var _monsters := MonsterDirector.new()   # night monsters and their coins (M2 Task 4)

var _secrets := SecretDirector.new()  # secrets and treasures (M2 Task 16)
var _layer := CanvasLayer.new()
var _client_spawn := Vector3.ZERO
var _quitting := false


func _ready() -> void:
	_players.name = "Players"
	add_child(_players)
	_spawner.name = "PlayerSpawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_players)
	_spawner.add_spawnable_scene(PLAYER_SCENE_PATH)
	_spawner.spawned.connect(_on_player_replicated)
	_players.child_entered_tree.connect(_on_player_entered)   # this device's avatar style (Task 13)
	_buddies.name = "Buddies"
	add_child(_buddies)
	_buddy_spawner.name = "BuddySpawner"
	add_child(_buddy_spawner)
	_buddy_spawner.spawn_path = _buddy_spawner.get_path_to(_buddies)
	_buddy_spawner.spawn_function = _make_buddy
	_animals.name = "Animals"
	add_child(_animals)
	_animal_spawner.name = "AnimalSpawner"
	add_child(_animal_spawner)
	_animal_spawner.spawn_path = _animal_spawner.get_path_to(_animals)
	_animal_spawner.spawn_function = _make_animal
	var chorus := AnimalChorus.new()   # owner feedback #50: the animals' idle calls, on every peer (its own)
	chorus.name = "AnimalChorus"
	add_child(chorus)
	var voices := MonsterChorus.new()   # M5 Task 2: the monsters' idle voices share one budget too
	voices.name = "MonsterChorus"
	add_child(voices)
	var babble := BabbleVoices.new()   # M3 Task 21a: buddies, bot friends, Tilly and pets talk in babble (this game's)
	babble.name = "Babble"
	add_child(babble)
	_add_bot_spawner()   # bot friends (M2 Task 15), on every peer
	_combat.name = "Combat"
	add_child(_combat)
	_add_knockout()   # knock-outs and pickup bags (M2 Task 2)
	_add_trader_spawner()   # M2 Task 7: every peer, so guests receive Tilly
	_monsters.name = "Monsters"   # on every peer: its spawners and effects line up across the network
	add_child(_monsters)
	_secrets.name = "Secrets"
	add_child(_secrets)
	_add_waves()   # the Monster Totem and its waves (M2 Task 9), on every peer
	_add_survivor_game()   # Survivor games (spec §12.18), on every peer
	_add_arena()   # Monster Wave (owner feedback #44, spec §12.20), on every peer
	_add_stealth()   # M2 Task 5: on every peer (bodies go into hiding spots on every game)
	_add_boss()   # M2 Task 10: the Stone Golem and the portal, on every peer
	_add_defenses()   # M2 Task 8: spike traps, lantern fear and light, on every peer
	_add_portal_frames()   # M3 Task 5: portal frames and cores, on every peer
	_add_smart()   # M3 Task 7: smart blocks and Game Blocks, on every peer
	_add_games()   # M4 H: co-op games, on every peer
	_add_playdates()   # M4 I: buddy playdates, on every peer (the host decides)
	_add_action_kit()   # M3 Task 14b: blaster shots, surprise drops, goblin archers' arrows, on every peer
	_add_gadgets()   # M3 Task 14a: orbs, hooks' ropes, ziplines, on every peer
	_add_pets()   # M3 Task 11: pets' perks, on every peer (the host decides)
	_add_rides()   # M3 Task 20a: rideable buddies, on every peer (the host decides)
	_add_vehicles()   # owner #109: cars to drive, on every peer (the host decides)
	_add_music()   # owner #110: the music blocks played (taps, LOOP, VR's mallets), on every peer (the host passes notes on)
	_add_farm()   # M3 Task 10: the Gold Farm, on every peer
	_add_quests()   # owner #45a: quest givers and stories, on every peer (the host shares a story)
	_add_nests()   # owner 39: dragon eggs, on every peer (the host decides)
	_add_places()   # owner #45b: places to find in the wild meadows, on every peer (the host decides)
	_add_buddy_magic()   # M3 Task 20b: secret shapes, the album, befriending, mini-buddies, tricks, on every peer
	_add_trading()   # owner #37: the shop's way, market day, the helpers' stands, trading, on every peer
	_add_tutorial()   # M3 Task 15: the tutorial with Pip (this game only; solo Survivor)
	UiLayers.route(_layer, self)   # owner #101: in VR the HUD's layer is drawn on the world-space panels
	pause_menu = PauseMenu.new()
	_layer.add_child(pause_menu)
	pause_menu.save_and_quit_requested.connect(_save_and_quit)
	pause_menu.opened.connect(save_world)
	_setup_online()   # M4 C: the online host's INVITE row
	Game.settings_applied.connect(_apply_settings)
	if Game.autopilot or OS.get_cmdline_user_args().has("--autopilot"):
		var pilot: Node = load("res://tools/autopilot.gd").new()
		pilot.set("sandbox", self)
		add_child(pilot)
	if Game.autopilot_tour:
		var tour: Node = load(AcceptanceTour.script_for(Game.mode)).new()   # Survivor: the M2 tour
		tour.set("sandbox", self)
		add_child(tour)
	if OS.get_cmdline_user_args().has("--lan-test"):
		var test: Node = load("res://tools/lan_test.gd").new()
		test.set("sandbox", self)
		add_child(test)
	_add_net_overlay()   # M4 A: plain words for network problems, over everything
	_setup_crew()   # spec §21d.6 phase 2: crew flights (a guest following the host's world shows its words at once)
	if Game.net_mode == &"client":
		_start_client()
	else:
		_start_host_or_solo()


func is_client() -> bool:
	return Game.net_mode == &"client"


# --- Solo / host ------------------------------------------------------------------------------

func _start_host_or_solo() -> void:
	var fresh := Game.start_new_world or not WorldSaves.exists(_slot)
	if Game.start_new_world:
		WorldSaves.delete(_slot)
		meta = WorldMeta.new_random()
		meta.mode = Game.mode
		if Game.mode == ModeRules.SURVIVOR:
			meta.difficulty = Game.new_world_difficulty   # COZY / NORMAL / BRAVE (M2 Task 17)
		if Game.mode == ModeRules.SURVIVOR:
			meta.hotbar = SURVIVOR_HOTBAR.duplicate()
			meta.inventories[_home_key()] = Inventory.starter_kit().to_save()
			_new_survivor_game()   # Survivor games (spec §12.18): the game, its kit and its morning
		if Game.new_world_seed != 0:
			meta.seed = Game.new_world_seed
			Game.new_world_seed = 0
		Game.start_new_world = false
	else:
		meta = WorldSaves.load_meta(_slot)
		meta.mode = Game.mode   # the slot is the mode's own
	meta.universe = Game.universe   # M3 Task 5: the slot is the universe's
	Game.survivor_game = meta.game if Game.mode == ModeRules.SURVIVOR else SurvivorGames.CLASSIC   # spec §12.18
	if Game.mode == ModeRules.WAVE:
		_prepare_arena()   # spec §12.20: the kit, the Totem in the middle, the start spot, bright day
	world = WORLD_SCENE.instantiate()
	Session.world_terrain = meta.terrain   # owner #45b: the world keeps the terrain it was made with
	world.terrain_version = meta.terrain
	world.setup(WorldSaves.dir_for(_slot), meta.seed, false, Game.universe, Game.mode == ModeRules.WAVE)
	add_child(world)
	Session.register_world(world)
	_apply_universe_content()   # M3 Task 2: the universe's monsters, boss, secrets, weather and traps
	_add_sky(meta.time_of_day)
	_knockout.restore(meta.bags)   # at once: a save before the player spawns must keep them
	_knockout.difficulty = meta.difficulty   # M2 Task 17: Cozy keeps your blocks at a knock-out
	Session.difficulty = meta.difficulty     # ... and the host scales monsters' hits
	_place_trader()
	_start_trading(true)   # owner #37: after Tilly's stall (market day's cart stands beside it)
	if Game.mode != ModeRules.WAVE:   # spec §12.20: no secrets in the arena
		_secrets.setup(meta.seed, meta.secrets, world)
		_universe_secrets(meta.seed)   # M3 Task 2
		_start_places(true)   # owner #45b: after the secrets (a place gives way to them)
	_secrets.time_of_day = func() -> float: return sky.time
	_secrets.treasures.rainbows = not SpaceRules.is_space(Game.universe)   # cosmos: no rain, no rainbow in space worlds

	player = _add_player(multiplayer.get_unique_id())
	Session.set_inventory(player.peer_id, Inventory.from_save(meta.inventories.get(_home_key(), [])))
	_interactor = player.get_node("BlockInteractor")
	_interactor.hotbar = meta.hotbar.duplicate()
	_interactor.selected_slot = meta.selected_slot
	if meta.physics_mode != PhysicsMode.Mode.NORMAL:
		player.set_physics_mode(meta.physics_mode)
	if LabRules.is_lab_only(meta.lab_mode):
		player.set_lab_mode(meta.lab_mode)   # Moon, Zero-G, Slow motion (M3 Task 6; Survivor ignores it)
	_arrive_through_gate()   # owner 39: in front of this world's portal back, when it has one
	if _arrive_from_space():   # owner #55: home from space, on the column the child took off from
		pass
	elif meta.has_player_pos():
		player.spawn_at(meta.player_pos)
		player.rig.yaw = meta.player_yaw
	else:
		var home := world.spawn_column()
		player.spawn_on_surface(home.x, home.y)
	_setup_local_player()
	player.spawned.connect(_hand_over_crystals, CONNECT_ONE_SHOT)   # owner 39: the crystals of the universes reached
	Session.spark_requested.connect(_on_spark)
	Session.sleep_requested.connect(_on_sleep)
	Session.back_online.connect(_on_back_online)   # owner #95: signed in again by itself after an offline spell
	player.spawned.connect(_restore_buddies, CONNECT_ONE_SHOT)
	player.spawned.connect(func() -> void: vehicles.restore(meta.cars), CONNECT_ONE_SHOT)   # owner #109: parked cars
	_start_minds()   # M2 Task 18: before the first animal
	if Game.mode != ModeRules.WAVE:   # spec §12.20: no animals in the arena
		_start_animals()
		_start_pets()   # M3 Task 11: treats, names, collars, perks, Pip (no pets in the arena either)
		_start_nests()   # owner 39: dragon eggs hatch
	_start_monsters()
	_start_survivor_game()   # spec §12.18: after the monsters (it tunes them)
	_start_waves()   # M2 Task 9: after Tilly's stall and the monsters
	_start_action_kit_host()   # M3 Task 14b: piñatas and supply balloons (after the waves)
	_start_boss()   # M2 Task 10
	_start_defenses()   # M2 Task 8
	if Game.mode != ModeRules.WAVE:   # spec §12.20: no weather or traps in the arena
		_start_universe_host(meta.seed)   # M3 Task 2: the sandstorm's clock, the desert's traps
	else:
		_start_arena()
	player.spawned.connect(func() -> void: _combat.restore(meta.targets), CONNECT_ONE_SHOT)
	if fresh and Game.mode != ModeRules.WAVE:
		player.spawned.connect(func() -> void:
			hud.toast("Tip: build something, then tap it with the Magic Wand!", 5.0), CONNECT_ONE_SHOT)

	if Game.net_mode == &"host":
		Session.host_seed = meta.seed
		Session.host_mode = Game.mode
		player.spawned.connect(func() -> void: Session.host_spawn = player.global_position, CONNECT_ONE_SHOT)
		Session.client_ready.connect(func(id: int) -> void:
			if not _players.has_node(str(id)):   # a repeated "ready" must not spawn a second body
				_add_player(id))
		Session.peer_left.connect(_on_peer_left)
		if Session.crew_moving():   # spec §21d.6: the world moved here with its crew: the same match or LAN game goes on
			player.spawned.connect(Session.crew_world_ready, CONNECT_ONE_SHOT)   # (after host_spawn: the held hellos)
			_crew_keep_online.call_deferred()
		elif Session.wants_online():
			Session.host_online()   # M4 spike: a Nakama relayed match (prints its id when it exists)
		else:
			var err := Session.host_lan()
			print("LAN host_lan err=%s" % error_string(err))

	var timer := Timer.new()
	timer.wait_time = PlatformRules.autosave_seconds(PlatformRules.current(), AUTOSAVE_SECONDS)   # M7: a browser, more often
	timer.autostart = true
	timer.timeout.connect(save_world)
	add_child(timer)
	WorldSaves.save_meta(_slot, meta)
	_start_bots()
	_start_smart()   # M3 Task 7: after the bot friends (they race courses)
	_start_games()   # M4 H: after the bot friends, the waves and the boss
	_start_gadgets()   # M3 Task 14a: the world's ziplines
	_start_farm()   # M3 Task 10
	_start_buddy_magic()   # M3 Task 20b: after the pets and the boss


func _add_player(peer_id: int) -> Player:
	var p: Player = PLAYER_SCENE.instantiate()
	p.name = str(peer_id)
	p.world = world
	_players.add_child(p, true)
	return p


func _on_peer_left(peer_id: int) -> void:
	var p := _players.get_node_or_null(str(peer_id))
	if p:
		p.queue_free()


# --- Living buddies (host) --------------------------------------------------------------------

func _buddy_nodes() -> Array[Buddy]:
	var list: Array[Buddy] = []
	for child in _buddies.get_children():
		if child is Buddy and not child.is_queued_for_deletion():
			list.append(child)
	return list


func _make_buddy(data: Variant) -> Node:
	var b := Buddy.new()
	b.setup(data)
	return b


func _spawn_buddy(blocks: Dictionary, bottom_center: Vector3, yaw: float, buddy_name: String, owner_peer: int,
		fresh: bool = false) -> Buddy:
	var data := {"flat": Buddy.pack(blocks), "name": buddy_name, "owner": owner_peer,
		"pos": bottom_center, "yaw": yaw, "id": "Buddy%d" % _next_buddy, "fresh": fresh}   # fresh: the wake-up ceremony
	_next_buddy += 1
	return _buddy_spawner.spawn(data) as Buddy


func _on_spark(peer_id: int, block_pos: Vector3i) -> void:
	if _buddy_nodes().size() >= WorldMeta.MAX_BUDDIES:
		Session.send_feedback(peer_id, tr("You have %d buddies! Put one to sleep with the wand first.") % WorldMeta.MAX_BUDDIES)
		return
	var result := CaptureRules.capture(block_pos, world.get_block)
	if result.has("error"):
		Session.send_feedback(peer_id, CaptureRules.message(result.error))
		return
	var found: Dictionary = result.blocks
	var lo := block_pos
	var hi := block_pos
	for p: Vector3i in found:
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var blocks := {}
	for p: Vector3i in found:
		blocks[p - lo] = found[p]
		world.set_block(p, BlockIds.AIR)
	var size := hi - lo + Vector3i.ONE
	var bottom_center := Vector3(lo.x + size.x * 0.5, lo.y, lo.z + size.z * 0.5)
	# M3 Task 20b's secret shapes first, then M3 Task 21c's wake kinds (a cactus, a pumpkin, a snowman), then a plain buddy
	var buddy_name := BuddyMagicDirector.name_for(blocks) if BuddyRecipes.match_blocks(blocks) != &"" \
		else WakeKinds.name_for(blocks)
	var ride := RideRules.normalise(blocks)   # M3 Task 20a: a saddled flyer or car faces the way it goes (same look)
	var woken := _spawn_buddy(ride.blocks, bottom_center, ride.yaw, buddy_name, peer_id, true)
	Session.progress_tell(peer_id, LevelRules.BUDDY)   # M3 Task 12
	buddy_magic.host_buddy_woken(peer_id, woken)   # M3 Task 20b: the album, a secret shape's reveal
	Fx.burst(world, bottom_center + Vector3(0, size.y * 0.5, 0), Color("ffd23f"), 30, 5.0, 0.15, 1.0, 4.0)
	var line := RideRules.wake_line(RideRules.kind_of(blocks), RideRules.on_water(bottom_center, world.get_block))
	if woken and woken.recipe != &"":   # M3 Task 20b: a secret shape's own words
		var secret := BuddyMagicDirector.secret_words(woken.recipe, buddy_name)
		Session.send_feedback(peer_id, secret if line == "" else "%s %s" % [secret, line])
		return
	var woke := WakeKinds.wake_line(WakeKinds.kind_of(blocks), buddy_name)   # M3 Task 21c
	if woke != "" and line == "":
		Session.send_feedback(peer_id, woke)
		return
	Session.send_feedback(peer_id, tr("%s is alive! %s") % [buddy_name, line] if line != "" else tr("%s is alive! Tap it to cheer.") % buddy_name)


## Owner #95: the game signed in again by itself (ReconnectWatch): what was played offline is on the account now.
func _on_back_online() -> void:
	if is_instance_valid(hud):
		hud.toast(ReconnectRules.BACK_WORDS, 5.0)


func _on_sleep(peer_id: int, buddy_name: String) -> void:
	var b := _buddies.get_node_or_null(buddy_name) as Buddy
	var requester := Session._player_for_peer(peer_id)
	if b == null or requester == null or b.is_queued_for_deletion():
		return
	if b.owner_peer != peer_id:
		Session.send_feedback(peer_id, SleepRules.message("not_yours"))
		return
	if b.rider_peer != 0:   # M3 Task 20a
		Session.send_feedback(peer_id, "Hop off first, then it can sleep!")
		return
	if not PlacementRules.in_reach(requester.eye_position(), Vector3i(b.global_position.floor()),
			PlacementRules.REACH + PlacementRules.REACH_TOLERANCE + b.size_blocks.length()):
		Session.send_feedback(peer_id, SleepRules.message("too_far"))
		return
	var result := SleepRules.find_base(b.global_position, b.size_blocks, b.blocks,
		func(p: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(p)), Session._player_bodies())
	if result.has("error"):
		Session.send_feedback(peer_id, SleepRules.message(result.error))
		return
	var base: Vector3i = result.base
	for p: Vector3i in b.blocks:
		world.set_block(base + p, b.blocks[p])
	Session.send_feedback(peer_id, tr("%s is sleeping as blocks.") % b.buddy_name)
	b.queue_free()


func _restore_buddies() -> void:
	for saved: Dictionary in meta.buddies:
		var blocks := {}
		for e: Array in saved.blocks:
			blocks[Vector3i(e[0], e[1], e[2])] = e[3]
		var pos := Vector3(saved.pos[0], saved.pos[1], saved.pos[2])
		var b := _spawn_buddy(blocks, pos, saved.yaw, saved.name, player.peer_id)
		if b:
			b.load_tricks(saved)   # M3 Task 20b: the tricks it learned


# --- LAN client -------------------------------------------------------------------------------

func _start_client() -> void:
	Session.world_info_received.connect(_on_world_info, CONNECT_ONE_SHOT)
	Session.disconnected.connect(_on_disconnected)
	if Session.wants_online():
		if not Session.a_rejoining():   # M4 A: while rejoining, Session joins the match again itself
			Session.join_online(Session.online_config.match_id)   # M4 spike; a failure comes as disconnected
		return
	var err := Session.join_lan(Game.join_address)
	print("LAN join_lan %s err=%s" % [Game.join_address, error_string(err)])
	if err != OK:
		Game.quit_to_menu()


func _on_world_info(world_seed: int, spawn: Vector3) -> void:
	world = WORLD_SCENE.instantiate()
	world.terrain_version = Session.world_terrain   # owner #45b: the host's terrain version came just before
	world.setup("", world_seed, true, Game.universe, Game.mode == ModeRules.WAVE)   # the host's universe came just before (M3 Task 5); the arena (§12.20)
	add_child(world)
	Session.register_world(world)
	_apply_universe_content()   # M3 Task 2 (a guest's world knows its universe with M3 Task 5's handshake)
	_add_sky(DayCycle.START)   # the host sends its clock
	_start_trading(false)   # owner #37
	if Game.mode != ModeRules.WAVE:   # spec §12.20: no secrets in the arena
		_secrets.setup_client(world_seed)
		_universe_secrets(world_seed)   # M3 Task 2
		_start_places(false)   # owner #45b
	_client_spawn = spawn + CLIENT_SPAWN_OFFSET
	var kept: Vector3 = Session.a_take_rejoin_spot()
	if kept.is_finite():
		_client_spawn = kept   # M4 A: back where its player waited on the host
	for p: Player in _players.get_children():
		p.world = world
		_on_player_replicated(p)
	Session.send_client_ready()
	Session.gold_hello()


func _on_player_replicated(node: Node) -> void:
	var p := node as Player
	if p == null or world == null:
		return
	p.world = world
	if p.peer_id == multiplayer.get_unique_id() and player == null:
		player = p
		p.tree_exiting.connect(_on_own_player_leaving, CONNECT_ONE_SHOT)
		_interactor = p.get_node("BlockInteractor")
		p.spawn_at(_client_spawn)
		_setup_local_player()


func _on_disconnected() -> void:
	if Session.a_rejoining():
		return   # M4 A: Session is getting this guest back into the match
	process_mode = Node.PROCESS_MODE_DISABLED   # see _on_own_player_leaving
	if not _quitting:
		_goodbye()


## A client's own body belongs to the host's spawner, which removes it when the host leaves, often
## frames before the disconnect arrives. Everything here that follows the player stops at once (the
## client crashed in Ambience; docs/devlog/parts/m1-minors.md), then it is back to the menu. When the
## whole sandbox is being freed (quitting), the deferred call never runs.
func _on_own_player_leaving() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_back_to_menu.call_deferred()


func _back_to_menu() -> void:
	if not _quitting and not Session.a_rejoining():   # (M4 A: a rejoin reloads this scene instead)
		_goodbye()


# --- Shared -----------------------------------------------------------------------------------

func _setup_local_player() -> void:
	hud = Hud.new()
	_layer.add_child(hud)
	_layer.move_child(hud, 0)   # pause menu stays on top
	var show_touch := PlatformRules.touch_ui(PlatformRules.current())   # M7: phones and tablets in a browser too
	hud.setup(player, Profile.data.username, show_touch, bool(Profile.data.settings.show_fps))
	hud.pause_requested.connect(pause_menu.open)
	var ambience := Ambience.new()   # cave darkness, lantern, underwater view
	ambience.name = "Ambience"
	ambience.world = world
	ambience.player = player
	add_child(ambience)
	if not player.is_spawned():   # M5 Task 2: picture hints over the universe's scene until the child stands in it
		LoadingCard.cover(self, player, Game.mode, Game.universe)
	# Compiles the particle shader as the world appears (the camera must be in place to draw it). M7: every prewarm goes
	# through ShaderWarmup.at_spawn (left to the shader warm-up where one ran: on WebGL they froze the spawn).
	ShaderWarmup.at_spawn(player.spawned, func() -> void: Fx.prewarm(player.camera()))
	ShaderWarmup.at_spawn(player.spawned, func() -> void: ThoughtBubble.prewarm(player.camera()))   # M2 Task 18
	_setup_keys_card()   # owner #84: a PC's keys, once at the first world, then F1
	_setup_sleep()
	_knockout.setup_local(player, hud)   # hearts row and the knock-out fade (M2 Task 2)
	player.spawned.connect(func() -> void: print("SANDBOX spawned_ms=%d" % (Time.get_ticks_msec() - _start_ms)), CONNECT_ONE_SHOT)
	_apply_settings(Profile.data.settings)
	_setup_chat()
	_setup_photo()
	hud.shop.opened.connect(_on_shop_opened)
	hud.add_secret_controls(_secrets)
	hud.show_difficulty_badge(meta.difficulty if meta else DifficultyRules.NORMAL)   # M2 Task 17: a Brave world's badge (the host's)
	_secrets.hud = hud
	_secrets.interactor = _interactor
	if Game.mode != ModeRules.WAVE:   # spec §12.20: no Theater in the arena
		_setup_theater()
	_setup_launch_site()   # spec §21d: the Launch Site, its pad and the Mission Board (home worlds)
	_setup_life_town()   # owner #112: Life Town, its six places by the spawn (home worlds)
	_setup_discovery()   # owner #132 (W1): DISCOVER in MORE and the pause menu, Professor Hoot's invitation
	_setup_waves_hud()   # M2 Task 9
	_setup_stealth()   # M2 Task 5
	_setup_boss_hud()   # M2 Task 10
	_setup_universe_hub()   # M3 Task 5: the stone circle, the hub panel, the portals' swirl
	_setup_online_hud()   # M4 C
	_setup_team_chat()   # M4 E
	_universe_hud()   # M3 Task 2: the boss's name on the Totem, the sandstorm's view and words
	_setup_survivor_game_hud()   # spec §12.18, §12.19: the game clock, crafting's words
	_setup_progress()   # M3 Task 12: levels, the adventure board, presents
	_setup_smart_local()   # M3 Task 7: this player's feet on Game Blocks, the race clock
	_setup_games_hud()   # M4 H: the round's line, TEAM PHOTO, the counting screen
	_i_setup_local()   # M4 I: SHARE (presents and my showcase), friends' bottles
	_gh_setup_local()   # M4 ghost races: friends' ghosts on this world's courses, my races on my showcase
	_t8_setup_local()   # M3 Task 8: the building tools' bar, Build Rewind's view, Build-and-Wear's card
	_setup_action_kit_local()   # M3 Task 14b
	hud.setup_gadgets(player)   # M3 Task 14a: the GLIDE button
	_setup_pets_local()   # M3 Task 11: the pet's card, the shared glow, the parrot's words, Pip
	_rides.setup_local(player, hud)   # M3 Task 20a: the RIDE button
	vehicles.setup_local(player, hud, _layer)   # owner #109: MORE → CARS (the garage), HORN, FLY / LAND, taps on cars
	music.world = world
	music.setup_local(player, hud)   # owner #110: taps on music blocks (before the cars' tap), LOOP and STOP, VR's mallets
	_setup_farm_local()   # M3 Task 10: the farm's panel, its workers near this player, the welcome-back
	_setup_quests()   # owner #45a: the universe's quest giver, QUESTS in MORE, the book, the card, the arrow
	_setup_places_local()   # owner #45b: the world map (MORE → MAP), the finds' words
	_setup_prospecting()   # spec §26: Gemma's camp and quests, the deposits on MY MAP, oil wells, DIG in MORE
	_setup_inventions()   # owner #78: the Inventions book (INVENT in MORE, I), MAKE IT, TRY IT, the wind
	_setup_books()   # M3 Task 21b: the Animal and Memory Books, page rewards, trophy shelves, the Hub Tree
	_setup_buddy_magic_local()   # M3 Task 20b: this profile's album, shapes, minis and tricks; My Stamps' bar
	_setup_trading_local()   # owner #37: MORE → SHOP, the tip, a player's card, the ask card, the trade window
	_setup_tutorial_local()   # M3 Task 15: the offer, Pip's playground, the steps, the reward (after the trading)
	_space_local()   # owner #55: the space line, the picker, the world's gravity and sky, the landing
	_wonders_local()   # owner #78: Wonders of the World: the tour's sights, passport stamps, guide, signs and plaques
	_glow_local()   # universe 6 (owner #122): the Glow Caves' Cave Wonders, their plays, facts and Cave Book pages
	_rocket_local()   # owner #79, #87: the rocket flight, the Star Map's landing, the lander by the pad
	_crew_local()   # spec §21d.6 phase 2: standing in a world a crew moved into
	_setup_pad()   # owner #90: game controllers (last: every panel is there to watch)


## Saves the local player state and edited blocks (blocks are written in the background).
## LAN clients never save: the world belongs to the host.
func save_world() -> void:
	if is_client() or player == null:
		return
	if player.is_spawned():
		meta.player_pos = player.global_position
		meta.player_yaw = player.rig.yaw
	meta.physics_mode = player.physics_mode
	meta.lab_mode = player.lab_mode
	meta.hotbar = _interactor.hotbar.duplicate()
	meta.selected_slot = _interactor.selected_slot
	meta.buddies.clear()
	for b in _buddy_nodes():
		meta.buddies.append(b.to_save())
	meta.pets.clear()
	for a in _animal_nodes():
		if a.is_pet() and a.species != PetRules.PIP and not PetDirector.is_profile_pet(String(a.name)) \
				and meta.pets.size() < WorldMeta.MAX_PETS:   # M3 Task 11: Pip is the profile's (owner 39: the baby dragon too)
			meta.pets.append(a.to_save())
	_save_time_and_homes()

	meta.targets = _combat.to_save()
	meta.bags = _knockout.to_save()
	if _bot_director:
		meta.bots = _bot_director.to_save()
	meta.secrets = _secrets.state
	if places_director.enabled():
		meta.places_found = places_director.found_ids()   # owner #45b
	_boss.save_into(meta)   # M2 Task 10: honest help and the portal
	meta.portals = _portal_frames.to_save()   # M3 Task 5: portal links and frames
	meta.gates = _portal_frames.gates_to_save()   # owner 39: universe portals
	meta.smart = _smart_save()   # M3 Task 7
	meta.drops = _drops.to_save()   # M3 Task 14b: the piñata clock
	if _gadgets_started:
		meta.ziplines = _ziplines.to_save()   # M3 Task 14a
	meta.minds = MindBook.current.to_save()   # M2 Task 18
	meta.mind_hints = MonsterMinds.current.hints_given.duplicate()
	meta.game_scores = _survivor_game.scores   # spec §12.18
	if Game.mode == ModeRules.SURVIVOR:
		meta.inventories[_home_key()] = Session.inventory_of(player.peer_id).to_save()
	meta.farm = _farm.for_save(player.global_position if player.is_spawned() else Vector3.INF)   # M3 Task 10
	meta.rewind = _interactor.tools.rewind.to_save()   # M3 Task 8: Build Rewind's recording
	meta.market = trading.market_save()   # owner #37: the world's days (market day)
	meta.cars = vehicles.to_save()   # owner #109: the parked cars
	WorldSaves.save_meta(_slot, meta)
	Profile.save()   # Survivor gold changes in memory; it is saved with the world (Session M2 section)
	world.save()


func _save_and_quit() -> void:
	if _quitting:
		return
	_quitting = true
	save_world()
	if not is_client():
		await world.save_and_wait()
	Game.quit_to_menu()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if is_node_ready() and not _quitting:
			save_world()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		go_back()


## Android Back: close MOVE BUTTONS (over everything), leave photo mode, close the palette, else toggle the pause menu
## (never quit mid-game).
func go_back() -> void:
	if HudEditor.close_open():   # M5 Task 6 review: it closed the pause menu under the editor
		pass
	elif lab_panel and lab_panel.close_if_open():   # spec §23: the Science Lab (over the HUD)
		pass
	elif vehicles.close_if_open():   # owner #109: the garage
		pass
	elif _theater_school_closed():   # owner #94: a Short's LEARN IT page over the Theater
		pass
	elif launch_site and launch_site.board and launch_site.board.close_if_open():   # spec §21d: the Mission Board
		pass
	elif life_town and life_town.close_if_open():   # owner #112: Life over Life Town (a practice room's own card)
		pass
	elif discovery and discovery.close_if_open():   # owner #132 (W1): DISCOVER's School over the world
		pass
	elif prospecting and prospecting.close_if_open():   # spec §26: Gemma's board
		pass
	elif inventions and inventions.close_if_open():   # owner #78: the Inventions book
		pass
	elif photo and photo.is_open():
		photo.close()
	elif hud and hud.palette.visible:
		hud.palette.visible = false
	elif hud and hud.close_more():   # M2 Task 17
		pass
	elif hud and hud.shop.visible:
		hud.shop.close()
	elif _quests.close_pages():   # owner #45a: the quest book or a giver's card
		pass
	elif space and space.close_picker():   # owner #55: "Where shall we land?"
		pass
	elif trading.close_pages():   # owner #37: the SHOP card, a player's card, the ask, the trade (stopped)
		pass
	elif hud and hud.close_secret_panels():
		pass
	elif hud and hud.totem_panel.visible:
		hud.totem_panel.close()
	elif hud and hud.farm_panel and hud.farm_panel.visible:   # M3 Task 10
		hud.farm_panel.close()
	elif hud and hud.course_panel.visible:   # M3 Task 7
		hud.course_panel.close()
	elif hud and hud.chat.is_open():
		hud.chat.close()
	elif pause_menu.visible:
		pause_menu.close()
	else:
		pause_menu.open()


func _apply_settings(settings: Dictionary) -> void:
	if world == null or player == null:
		return
	world.apply_graphics(settings)
	world.photo_sky = UniverseRegistry.photo_sky(Game.universe)   # cosmos: Mars keeps its own sky when realistic
	world.apply_style(str(settings.style))
	_style_avatars(str(settings.style))
	player.set_view_distance(GraphicsPreset.view_distance(settings))   # M5 Task 3: LOW sees 64 blocks
	_monsters.apply_preset(str(settings.graphics))   # M5 Task 3: LOW brings fewer monsters and animals
	if _director:
		_director.apply_preset(str(settings.graphics))
	hud.fps_label.visible = bool(settings.show_fps)
	player.set_max_jumps(int(settings.max_jumps))


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look_delta((event as InputEventMouseMotion).relative, CameraRig.MOUSE_SENSITIVITY)
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and PlatformRules.captures_mouse(PlatformRules.current()):   # M7: never a tap on a phone browser
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode == KEY_F1 and keys_card != null:   # owner #84: the KEYS card again
		keys_card.open()
	elif event.is_action_pressed("physics_mode"):
		player.cycle_physics_mode()
	elif event.is_action_pressed("lab_mode"):
		hud.lab_pressed()   # the LAB button (Sandbox only)
	elif event.is_action_pressed("camera_toggle"):
		player.toggle_camera()
	elif event.is_action_pressed("size_mode"):
		player.cycle_size_mode()
	elif event.is_action_pressed("hotbar_prev") or event.is_action_pressed("hotbar_next"):   # owner #90: L1 / R1
		_interactor.select_slot(GamepadRules.next_slot(_interactor.selected_slot,
			-1 if event.is_action_pressed("hotbar_prev") else 1, _interactor.hotbar.size()))
	elif event.is_action_pressed("blocks") and not hud.palette.visible:   # owner #90: D-pad left, every block
		hud.palette.open()
	elif event.is_action_pressed("more"):   # owner #90: D-pad right, the MORE panel (map, photo, size, undo…)
		hud.more.toggle()
	elif event.is_action_pressed("map"):   # owner #90: the touchpad / View opens and closes MY MAP
		_pad_map()


func _process(_delta: float) -> void:
	if _interactor:
		# Owner #90: a game controller aims at the middle of the screen (the crosshair), as a captured mouse does.
		_interactor.crosshair_mode = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or player.rig.first_person \
			or PadFocus.playing_with_pad() or Vr.active()   # owner #101: in VR the hand's laser aims
		if PadFocus.playing_with_pad() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE \
				and PlatformRules.captures_mouse(PlatformRules.current()):
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN   # no arrow over the world while the pad plays (a click takes it back)


# --- Animals (M1b Task 9) -----------------------------------------------------------------------

## Host and solo: the director brings animals to life around every player; pets are restored.
func _start_animals() -> void:
	Session.pet_requested.connect(_on_pet)
	_director = AnimalDirector.new()
	_director.name = "AnimalDirector"
	_director.shape = world.generator_shape()
	_director.kinds = UniverseRegistry.animals(Game.universe)   # owner #41: the universe's own animals
	_director.block_at = world.get_block   # owner #41: the turtles' eggs on sand
	_director.container = _animals
	_director.player_positions = _player_positions
	_director.is_ready = world.is_area_ready
	_director.apply_preset(str(Profile.data.settings.graphics))   # M5 Task 3: LOW brings fewer
	_director.one_a_frame = true   # the frame spikes: a tick's animals are built one a frame
	_director.spawn = func(data: Dictionary) -> void:
		if _secrets.is_golden_spawn(str(data.id)):
			data.golden = true   # a rare golden animal (M2 Task 16)
		_animal_spawner.spawn(data)
	add_child(_director)
	if UniverseRegistry.lifeless(Game.universe):   # cosmos: Mars has no life we know of (the Totem still summons)
		_director.process_mode = Node.PROCESS_MODE_DISABLED
	_director.egg_hatched.connect(_on_egg_hatched)   # owner #41: a turtle's egg, a small secret
	_combat.animal_defeated.connect(_director.note_defeated)   # owner feedback #26: herds refill slowly
	player.spawned.connect(_restore_pets, CONNECT_ONE_SHOT)


## Host (owner #41): a turtle's egg hatched because a child came close: they found a small secret.
func _on_egg_hatched(pos: Vector3, finder: Vector3) -> void:
	for n in _players.get_children():
		var p := n as Player
		if p and p.global_position.distance_to(finder) < 0.5:
			Session.send_feedback(p.peer_id, "You found a turtle egg! A baby turtle hatched!")
			Session.progress_tell(p.peer_id, StringName("%s/turtle_egg" % LevelRules.SECRET))
	Audio.play(&"pickup", pos)


func _make_animal(data: Variant) -> Node:
	var a := Animal.new()
	a.setup(data)
	a.world = world
	if not is_client():   # M2 Task 17: pet dogs lead the way to buried treasure
		a.treasure_near = func(from: Vector3) -> Vector3: return _secrets.nearest_buried_chest(from)
	return a


func _animal_nodes() -> Array[Animal]:
	var list: Array[Animal] = []
	for child in _animals.get_children():
		if child is Animal and not child.is_queued_for_deletion():
			list.append(child)
	return list


func _player_positions() -> Array[Vector3]:
	var list: Array[Vector3] = []
	for p in _players.get_children():
		if p is Player and (p as Player).is_spawned():
			list.append((p as Player).global_position)
	return list


func _restore_pets() -> void:
	for saved: Dictionary in meta.pets:
		var pet := _animal_spawner.spawn({"species": StringName(saved.species), "id": saved.id if saved.id != "" else "pet%d" % _next_summon,
			"pos": Vector3(saved.pos[0], saved.pos[1], saved.pos[2]), "yaw": 0.0, "owner": player.peer_id,
			"name": saved.name, "sitting": false, "collar": saved.get("collar", PetRules.OWNER_COLOUR),
			"happiness": saved.get("happiness", PetRules.HAPPY_START),   # M3 Task 11
			"saddled": saved.get("saddled", false), "chest": saved.get("chest", []),   # owner #41
			"variant": saved.get("variant", "")}) as Animal   # M3 Task 20b: a befriended monster's kind
		if pet:
			pet.mind_load(saved.get("mind"))   # M2 Task 18: it remembers its owner
			pet.load_tricks(saved)   # M3 Task 20b
		_next_summon += 1


func _on_pet(peer_id: int, animal_name: String) -> void:
	var a := _animals.get_node_or_null(animal_name) as Animal
	var requester := Session._player_for_peer(peer_id)
	if a == null or requester == null or a.is_queued_for_deletion():
		return
	if not PlacementRules.in_reach(requester.eye_position(), Vector3i(a.global_position.floor()),
			PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		return
	if a.golden:
		_secrets.catch_golden(peer_id, a)   # caught! (M2 Task 16)
		return
	var owned := pets.pets_owned(peer_id)   # M3 Task 11: Pip never counts
	var tameable: bool = AnimalRules.SPECIES[a.species].tameable
	var was_pet := a.is_pet()
	if a.pet_tap(peer_id, Time.get_ticks_msec() / 1000.0, owned):
		a.cheer(true)
		Session.progress_tell(peer_id, StringName("%s/%s" % [LevelRules.TAMED, a.species]))   # M3 Task 12
		Session.send_feedback(peer_id, tr("%s is your pet now! Tap %s to see its card.") % [a.pet_name, a.pet_name])
	elif not was_pet and tameable and owned >= AnimalRules.MAX_PETS:
		Session.send_feedback(peer_id, tr("You already have %d pets!") % AnimalRules.MAX_PETS)
	elif was_pet and a.owner_peer == peer_id:
		Session.send_feedback(peer_id, (tr("%s sits and waits.") if a.sitting else tr("%s follows you again!")) % a.pet_name)


## Chat /summon (host): a wild animal of `species` appears in front of `near`.
## Returns why no animal came ("" = it came): capped near the player; fish need water.
func summon_animal(species: StringName, near: Vector3) -> String:
	if not AnimalRules.SPECIES.has(species) or _director == null:
		return ""
	if species == PetRules.PIP:
		return _summon_pip(near)   # M3 Task 11
	var pos := AnimalRules.summon_spot(near, world.get_block, randi() % AnimalRules.SUMMON_SIDES.size())
	if AnimalRules.SPECIES[species].habitat == &"water":
		pos = AnimalRules.water_spot(near, world.get_block)
	var animals: Array[Vector3] = []
	for a in _animal_nodes():
		animals.append(a.global_position)
	var refusal := AnimalRules.summon_refusal(species, near, animals, pos)
	if refusal != "":
		return refusal
	_animal_spawner.spawn({"species": species, "id": "s%d" % _next_summon, "pos": pos, "yaw": randf() * TAU,
		"owner": 0, "name": "", "sitting": false})
	_next_summon += 1
	return ""

# --- Chat commands (M1b Task 12) --------------------------------------------------------------

## The chat's commands run in a ChatCommandRunner. On the host it also runs the world-changing
## commands players send (time, home, summon) through hooks on this scene.
func _setup_chat() -> void:
	var runner := ChatCommandRunner.new()
	runner.name = "ChatCommands"
	runner.sandbox = self
	runner.chat = hud.chat
	add_child(runner)
	hud.chat.command_entered.connect(runner.run)
	# owner #51: a tap on the palette's MOBS page is the same as typing /summon (the host's checks, the chat line)
	hud.palette.mob_requested.connect(func(word: String) -> void: runner.run("/summon %s" % word))
	pause_menu.opened.connect(hud.chat.close)

# --- Shorts Theater (M3 Task 17) --------------------------------------------------------------

## The Theater near the spawn (every device builds it from the seed; the host saves where it
## stands) and its video panel, between the HUD and the pause menu.
func _setup_theater() -> void:
	var theater := TheaterDirector.new()
	theater.name = "Theater"
	theater.search_later = true   # M7: a new world's site is searched on a worker, not in the world switch's frame
	add_child(theater)
	var host := meta != null and not is_client()
	if host:
		theater.site_placed.connect(func(saved: Array) -> void: meta.theater = saved)
	theater.online = Session.online_service_or_null   # owner #89: the server's channel list when online
	var placed := theater.setup(world.generator_shape(), meta.theater if host else [], _layer, TheaterFeed.load_best())
	if host:
		meta.theater = placed
	if theater.panel == null:
		return
	_layer.move_child(theater.panel, hud.get_index() + 1)
	hud.look_area.blockers.append_array(theater.panel.blockers())
	theater.panel.visibility_changed.connect(func() -> void:
		hud.set_theater_open(theater.panel.visible, theater.panel))   # M2 Task 17; M5 Task 1: the panel's buttons
	theater.panel.layout_changed.connect(func() -> void:   # owner #94: the Shorts or the channels: tuck again
		if theater.panel.visible:
			hud.set_theater_open(true, theater.panel))
	theater.panel.learn_requested.connect(learn_from_short)   # owner #94: LEARN IT (the Theater has closed)
	theater.player_position = func() -> Vector3:
		return Player.position_or_none(player)
	theater.overlay_open = func() -> bool:
		return pause_menu.visible or hud.palette.visible or hud.chat.is_open() or hud.more.is_open() \
			or (keys_card != null and keys_card.visible)   # owner #89: the browser's player is over the game too

## Owner #94 (spec §5.12b): a Short's LEARN IT for the world: the Mission Board (the Launch Site's, in a home world) or
## the Star Map. A School unit opens inside the Theater itself (ShortsSchool).
func learn_from_short(link: Dictionary) -> void:
	if link.get(ShortRules.LINK_BOARD) == true:
		if launch_site != null and launch_site.board != null:
			launch_site.board.open()
		elif is_instance_valid(hud):
			hud.toast("The Mission Board stands at the Launch Site of your home world.", 5.0)
	elif link.get(ShortRules.LINK_STAR_MAP) == true and space != null:
		space.open_picker()


# --- Spec §21d: missions (the Launch Site, the Mission Board, rocket parts, the launch) --------------------------------
# Every home world (not Monster Wave's arena, not a space world) has a Launch Site a short walk from the spawn
# (LaunchDirector, node "LaunchSite"): its site is saved in WorldMeta.launch_site, its pad stamped once by the host, its
# buildings stood on every device. Walking up to the Mission Board opens it (MissionBoard): the missions, the rocket
# science panel (RocketCheck of the parts on the pad) and the parts' shop. Parts cost gold in every mode (spec §25.3):
# Survivor's go into the bag (the host's: a guest buys in its own world); the Sandbox's are this profile's
# (MissionData: building stays free, a launch needs every part on the pad bought). LAUNCH hands the rocket over through
# `fly`; a planet reached is on the route (the Star Map's LAND works for it, spec §21d.5).

var launch_site: LaunchDirector
## (rocket: Dictionary) -> void: flies a checked rocket (RocketCheck.description: destination, cells, stages, seats).
## Until the rocket flight (RocketFlight, spec §25.3) is merged it is the plain space trip that lands the child on the
## planet (the landing words, the Space Book). The lead joins them: `fly = func(r): flight.start(r,
## Game.universe)` and the flight's `landed(destination)` -> mission_arrive(destination).
## The core loop (owner #79): LAUNCH flies the rocket the child built (RocketFlight: sit at the controls), from the
## Launch Site's pad; tests may set their own.
var fly: Callable = func(rocket: Dictionary) -> void: _fly_mission(rocket)
## The flight under way is a mission's (its landing puts the planet on the route: mission_arrive), not the Star Map's.
var _flight_is_mission := false


func _fly_mission(rocket: Dictionary) -> void:
	var r := rocket.duplicate()
	if launch_site != null and not launch_site.site.is_empty():
		r["origin"] = Vector3(LaunchSite.corner(launch_site.site))   # the pad's corner: the rocket stands where it was built
	var why := fly_rocket(r)
	if why != "":
		if is_instance_valid(hud):
			hud.toast(why, 5.0)
		return
	_flight_is_mission = true
## The world a mission's rocket is landing on (the landing words say "Mission complete!"); kept across the world switch.
static var mission_landing := 0


func _setup_launch_site() -> void:
	if Game.mode == ModeRules.WAVE or not SpaceRules.is_home(Game.universe):
		return
	launch_site = LaunchDirector.new()
	launch_site.name = "LaunchSite"
	launch_site.world = world
	launch_site.host = not is_client()
	add_child(launch_site)
	var host := meta != null and not is_client()
	if host:
		launch_site.site_placed.connect(func(saved: Array) -> void: meta.launch_site = saved)
	launch_site.site_ready.connect(_mark_launch_site)   # owner #98: MY MAP shows the Launch Site from the start
	var placed := launch_site.setup(world.generator_shape(), meta.launch_site if host else [],
		meta.theater if host else [], _layer)
	if host and not placed.is_empty():
		meta.launch_site = placed
	var board := launch_site.board
	# Last in the layer: a PC's Esc reaches the open board before the pause menu (Esc closes it, owner #84); the pause
	# menu closes the board when it opens, so the two never show together.
	_layer.move_child(board, -1)
	hud.look_area.blockers.append_array(board.blockers())
	launch_site.player_position = func() -> Vector3: return Player.position_or_none(player)
	launch_site.overlay_open = func() -> bool:
		return pause_menu.visible or hud.palette.visible or hud.chat.is_open() or hud.more.is_open() \
			or (space != null and space.panel != null and space.panel.visible)
	board.read_rocket = launch_site.read_pad
	board.owned = func() -> Variant:
		return Profile.data.missions.owned() if Game.allows(ModeRules.UNLIMITED_BLOCKS) else null
	board.have = func(id: int) -> int:
		if Game.allows(ModeRules.UNLIMITED_BLOCKS):
			return int(Profile.data.missions.parts.get(id, 0))
		return Session.my_inventory.count(id)
	board.gold = func() -> int: return Profile.data.survivor_gold
	board.buy = buy_rocket_part
	board.launch = launch_rocket
	board.route = mission_route
	board.badges = func(w: int) -> Array:   # spec §21d.6 phase 2: the crew badges, on their missions' cards
		var out: Array = []
		for b: Dictionary in Profile.data.missions.crews.for_world(w):
			out.append(CrewFlightRules.badge_words(w, b.with))
		return out
	board.gate = mission_gate   # owner #78: in Survivor the rocket must be invented first
	board.star_map = func() -> void:
		if space:
			space.open_picker()
	# Owner #98: BUILD IT FOR ME for the crew here (the host builds on its pad); a friend's pad buys nothing for it.
	board.build = build_rocket_plan
	board.crew_here = func() -> int: return 1 if is_client() else 1 + multiplayer.get_peers().size()
	board.is_guest = is_client
	if not is_client():
		launch_site.write_cells = _write_rocket_cells
		launch_site.bodies = _rocket_build_bodies
		launch_site.say = _say_rocket_line
	pause_menu.opened.connect(func() -> void: board.close())


# --- Owner #112, Life Town (Life L2; docs/design/life-skills.md §7) ---------------------------------------------------
# Every home world (not Monster Wave's arena, not a space world) has Life Town a short walk from the spawn
# (LifeTownDirector, node "LifeTown"), placed like the Launch Site: its site is saved in WorldMeta.life_town once the
# host checked its ground and cleared the trees in its places' way; its buildings stand on every device. Walking up to
# a place opens Life on its Experience (LifeTownPanel, in the HUD's layer); while a practice room shows, the avatar is
# held still and kept safe.

var life_town: LifeTownDirector


func _setup_life_town() -> void:
	if Game.mode == ModeRules.WAVE or not SpaceRules.is_home(Game.universe):
		return
	life_town = LifeTownDirector.new()
	life_town.name = "LifeTown"
	life_town.world = world
	life_town.host = not is_client()
	add_child(life_town)
	var host := meta != null and not is_client()
	if host:
		life_town.site_placed.connect(func(saved: Array) -> void: meta.life_town = saved)
	life_town.site_ready.connect(_mark_life_town)   # MY MAP shows Life Town (a town's picture) once it stands
	life_town.market_ready.connect(_mark_market_square)   # owner #115 (S3): and the Market Square beside it
	var placed := life_town.setup(world.generator_shape(), meta.life_town if host else [], meta.theater if host else [],
		meta.launch_site if host else [], _layer)
	if host and not placed.is_empty():
		meta.life_town = placed
	_layer.move_child(life_town.panel, -1)   # over the HUD, like the Mission Board
	hud.look_area.blockers.append_array(life_town.panel.blockers())
	life_town.player_position = func() -> Vector3: return Player.position_or_none(player)
	life_town.overlay_open = func() -> bool:
		return pause_menu.visible or hud.palette.visible or hud.chat.is_open() or hud.more.is_open() \
			or (launch_site != null and launch_site.board != null and launch_site.board.visible)
	life_town.keep_safe = func() -> void:
		if is_instance_valid(player):
			player.health.protect(3.0)
	life_town.take_over = _life_take_over
	pause_menu.opened.connect(func() -> void: life_town.panel.close())


func _mark_life_town() -> void:
	if places_director == null or life_town == null or life_town.site.is_empty():
		return
	places_director.mark({"id": "life_town", "kind": &"town", "name": tr("Life Town"),
		"pos": LifeTown.door_position(life_town.site, "street", life_town.ground)})


func _mark_market_square() -> void:
	if places_director == null or life_town == null or not life_town.site.has("market"):
		return
	places_director.mark({"id": "market_square", "kind": &"town", "name": tr("Market Square"),
		"pos": MarketPlaza.door_position(life_town.site.market, "square", life_town.ground)})


# --- Owner #132 (W1): learning inside the world (docs/devlog/parts/play-w1.md) ---------------------------------------
# DISCOVER (MORE's first picture, and beside RESUME in the pause menu) opens the School over the world (DiscoverPanel,
# like Life Town's Life) in every world but Monster Wave's arena; while it shows the avatar is held and kept safe. In a
# home world Professor Hoot comes once the child has stood in it a while (each world's first visit, then at most once a
# day): his line spoken, his card's DISCOVER picture (in a headset: the toast strip). This device's own: nothing synced.

var discovery: DiscoveryDirector
var discover_button: TouchButton


func _setup_discovery() -> void:
	if not DiscoveryRules.discover_here(Game.mode, Game.universe):
		return
	discovery = DiscoveryDirector.new()
	discovery.name = "Discovery"
	add_child(discovery)
	var world_seed: int = meta.seed if meta != null and not is_client() else _secrets.world_seed
	discovery.setup(_layer, DiscoveryRules.world_key(_slot, world_seed), DiscoveryRules.hoot_here(Game.mode, Game.universe))
	_layer.move_child(discovery.hoot, pause_menu.get_index())   # over the HUD, under the pause menu
	_layer.move_child(discovery.panel, -1)   # over the HUD, like Life Town's panel (a PC's Esc reaches it first)
	hud.look_area.blockers.append_array(discovery.blockers())
	PadFocus.watch(discovery.panel)   # owner #90; in a headset the eye panel shows it (owner #101)
	discovery.player_ready = func() -> bool: return is_instance_valid(player) and player.is_spawned()
	discovery.overlay_open = _discovery_covered
	discovery.keep_safe = func() -> void:
		if is_instance_valid(player):
			player.health.protect(3.0)
	discovery.take_over = _life_take_over
	discovery.toast = func(text: String, seconds: float) -> void:
		if is_instance_valid(hud):
			hud.toast(text, seconds)
	# Stage 2: the discovery crystal (this device's own node in the world; DiscoveryDirector's rules say where and when)
	discovery.world_parent = self
	discovery.block_at = func(c: Vector3i) -> int: return world.get_block(c) if world != null else BlockIds.AIR
	discovery.player_feet = func() -> Vector3: return Player.position_or_none(player)
	discovery.player_yaw = func() -> float: return player.rig.yaw if is_instance_valid(player) else 0.0
	discovery.busy = _discovery_busy
	discovery.hand_points = func() -> Array[Vector3]:
		if not Vr.active():
			return [] as Array[Vector3]
		return [Vr.hand_grip(VrRules.LEFT).origin, Vr.hand_grip(VrRules.RIGHT).origin] as Array[Vector3]
	if _interactor:
		_interactor.discovery_tap = func(screen_pos: Vector2) -> bool:
			if not is_instance_valid(player):
				return false
			var ray := player.aim_ray(screen_pos)
			return discovery.tap(ray[0], ray[1])
	if DiscoveryRules.hoot_here(Game.mode, Game.universe):
		_setup_academy()   # stage 3: the Discovery Academy by the spawn (home worlds)
	discover_button = discovery.more_button()
	hud.more.add(discover_button, true)
	hud.more.grid.move_child(discover_button, 0)   # the first picture in MORE (owner #132: learning was nowhere)
	pause_menu.discover_on = true
	pause_menu.discover_requested.connect(discovery.open_discover)
	pause_menu.opened.connect(func() -> void:
		discovery.panel.close()
		discovery.hoot.hide_card())


## Stage 3: the Discovery Academy (node "Academy" under "Discovery"): placed like the Market Square after Life Town and
## it (AcademyPlacer: its saved site at once, else the search on a worker, the host's check and clearing; WorldMeta.academy
## keeps it; a guest stands it from the seed); MY MAP marks it (a tower); the HUD's compass points to it until the child
## has been to a door (chained before the world's own guide); its doors' "coming soon" card has the pad (VR: the eye panel).
var academy: AcademyPlacer


func _setup_academy() -> void:
	var host := meta != null and not is_client()
	academy = AcademyPlacer.new()
	academy.world = world
	academy.host = not is_client()
	discovery.add_child(academy)
	discovery.academy = academy
	if host:
		academy.placed.connect(func(s: Dictionary) -> void: meta.academy = AcademyPlaza.to_save(s))
	academy.stands.connect(_mark_academy)
	var shape: MeadowsShape = world.generator_shape()
	var ground: Callable = shape.height_at if shape != null else Callable()
	academy.setup(shape, AcademyPlaza.from_save(meta.academy) if host else {}, ground, meta.theater if host else [],
		meta.launch_site if host else [], meta.life_town if host else [])
	PadFocus.watch(discovery.academy_card)
	_chain_discovery_compass.call_deferred()


func _mark_academy() -> void:
	if places_director == null or academy == null or academy.site.is_empty():
		return
	var at := academy.door_position("maths")
	if bool(academy.site.get("island", false)):
		at = LifeTown.to_world_point(academy.site, Vector2.ZERO, float((academy.site.pos as Vector3i).y))
	places_director.mark({"id": "academy", "kind": &"tower", "name": tr("Discovery Academy"), "pos": at})


## The HUD's compass points to the Academy until the child has been to one of its doors, then to what it pointed to
## before (the world's own guide: Gemma's quests). Deferred: after every other setup has set its guide.
func _chain_discovery_compass() -> void:
	if discovery == null or not is_instance_valid(hud):
		return
	var before: Callable = hud.compass.guide
	hud.compass.guide = func(from: Vector3) -> Dictionary:
		var t := discovery.compass_target(from)
		if not t.is_empty():
			return t
		return before.call(from) if before.is_valid() else {}


## Stage 2: no crystal (and a crystal's play ends quietly) while the child is busy: in a fight (a monster near), a wave,
## a race, a round, riding, in a car, flying, seated in VR, hiding, asleep, knocked out, or in Pip's tutorial.
func _discovery_busy() -> bool:
	if not is_instance_valid(player) or not player.is_spawned():
		return true
	if player.is_riding() or player.is_hiding() or player.sleeping or player.knocked_out or Vr.seated():
		return true
	if (flight != null and flight.is_active()) or _waves.busy() or games.running() or hud.race_clock.visible:
		return true
	if tutorial.here and tutorial.is_running():
		return true
	var now := Time.get_ticks_msec()
	if now - _discovery_monster_at >= 400:   # the monsters near, looked at a few times a second (asked every frame)
		_discovery_monster_at = now
		_discovery_monster_near = false
		var feet := player.global_position
		for m: Monster in _monsters.monsters():
			if is_instance_valid(m) and m.global_position.distance_to(feet) < 18.0:
				_discovery_monster_near = true
				break
	return _discovery_monster_near


var _discovery_monster_at := -100000
var _discovery_monster_near := false


## Hoot waits while anything covers the world (a menu, a card, a place's panel, the tutorial's card).
func _discovery_covered() -> bool:
	if pause_menu.visible or hud.palette.visible or hud.chat.is_open() or hud.more.is_open() or hud.shop.visible:
		return true
	if life_town != null and life_town.panel != null and life_town.panel.visible:
		return true
	if launch_site != null and launch_site.board != null and launch_site.board.visible:
		return true
	if (keys_card != null and keys_card.visible) or (world_map != null and world_map.visible):
		return true
	if tutorial.card != null and is_instance_valid(tutorial.card) and tutorial.card.visible:
		return true
	var theater := get_node_or_null("Theater") as TheaterDirector
	return theater != null and theater.panel != null and theater.panel.visible


## While a practice room from Life Town shows: the avatar stands still (its physics off, no block taps), visible to
## friends; the room's own camera and HUD show (the HUD's layer is hidden by the room).
func _life_take_over(on: bool) -> void:
	if not is_instance_valid(player):
		return
	player.velocity = Vector3.ZERO
	player.set_physics_process(not on)
	if _interactor:
		_interactor.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


## Owner #78 (spec §21e): why the Launch Site's missions are shut ("" = open): in Survivor the rocket must be invented
## first (the Inventions book); the Sandbox's stay open.
func mission_gate() -> String:
	if InventionRules.missions_open(Game.allows(ModeRules.FREE_FLY), Profile.data.inventions):
		return ""
	return Lang.t(InventionRules.MISSIONS_WORDS)


## The worlds on this child's route (spec §21d.5): flown to by a mission, or landed on before.
func mission_route() -> Array[int]:
	return MissionRules.route(Profile.data.wonder, Profile.data.missions.flown)


## Buys `n` of a rocket part with this child's gold ("" = bought, else why not). Survivor: through the host's wallet,
## into the bag (a guest's bag is the host's world's: it buys in its own world, a ruling). Sandbox: the gold the child
## earned (the School's, Survivor's) buys parts kept by the profile for every Sandbox rocket; the rest of the Sandbox
## stays free (spec §25.3).
func buy_rocket_part(id: int, n: int) -> String:
	var cost := RocketParts.price(id) * n
	if cost <= 0:
		return "That is not a rocket part."
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		if is_client():
			return "Buy rocket parts in your own world: the bag here belongs to your friend's world."
		var bag := Session.inventory_of(player.peer_id)
		if bag.count(id) + n > Inventory.MAX_COUNT:
			return "Your bag is full of those!"
		if not Session.gold_spend(player.peer_id, cost):
			return "You need more gold!"
		bag.add(id, n)
		return ""
	var wallet := Wallet.new(Profile.data.survivor_gold)
	if not wallet.spend(cost):
		return "You need more gold!"
	Profile.data.survivor_gold = wallet.balance
	Profile.data.missions.add_part(id, n)
	Profile.save()
	return ""


# Owner #98: the rocket easier to build. BUILD IT FOR ME (the board's): the host builds Mission Control's plan
# (RocketPlan) for the crew here on its own pad, layer by layer (LaunchDirector.build), never on a friend's; it writes
# through _write_rocket_cells (Survivor's bag pays). The Launch Site is on MY MAP from the start, /find launch points
# there, and a mission the Star Map refuses points the arrow there too.

## BUILD IT FOR ME for `world_id`'s mission and `crew_n` astronauts: "" when Mission Control started, else why not.
func build_rocket_plan(world_id: int, crew_n: int) -> String:
	if is_client():
		return MissionRules.message(MissionRules.GUEST)
	if launch_site == null:
		return LaunchDirector.PAD_NOT_READY
	if not LaunchSite.near_board(launch_site.site, Player.position_or_none(player)):
		return "Stand at the Mission Board: Mission Control builds from there."
	if mission_gate() != "":
		return mission_gate()
	if (crew != null and (crew.call != null or crew.flying)) or is_instance_valid(flight):
		return "Mission Control waits: a flight is on its way."
	var m := MissionRules.for_world(world_id)
	var plan := RocketPlan.cells(m, crew_n)
	if plan.is_empty():
		return RocketPlan.no_plan_words(m, crew_n)
	return launch_site.build(plan, RocketPlan.stage_words(plan), str(m.get("place", "space")))


## BUILD IT FOR ME's writes (host): Survivor's bag pays for every cell (a part cleared off the pad goes back into it),
## never a cell inside a player; no XP, no undo step and no reach limit (the board's near_board gated it). "" or why
## the build stops.
func _write_rocket_cells(changes: Array) -> String:
	var ledger := Session.gather_ledger(player.peer_id, false)
	var bodies := Session._player_bodies()
	var ok: Array = []
	var pairs: Array = []
	for c: Array in changes:
		var id := int(c[1])
		if id != BlockIds.AIR and not PlacementRules.can_place(c[0], bodies, id):
			continue
		ok.append(c)
		pairs.append([world.get_block(c[0]), id])
	if ledger != null and not ledger.reserve(pairs):
		return ledger.message
	for e: Array in world.set_blocks(ok):
		if ledger != null:
			ledger.changed(int(e[1]), int(e[2]))
	return ""


## The players and bot friends here (BUILD IT FOR ME waits while one stands in the build box).
func _rocket_build_bodies() -> Array:
	var out: Array = Session._player_bodies()
	for n in get_tree().get_nodes_in_group(&"bot_friends"):
		out.append(PlacementRules.player_aabb((n as Node3D).global_position))
	return out


## A line of BUILD IT FOR ME for everyone here: this game's caption and voice, a friend's caption.
func _say_rocket_line(text: String) -> void:
	if is_instance_valid(hud):
		hud.toast(text, 4.0)
	ReadAloud.speak(text)
	for peer in multiplayer.get_peers():
		Session.send_feedback(peer, text)


## MY MAP: the Launch Site from the start (it is a short walk from the spawn, and the Moon needs it).
func _mark_launch_site() -> void:
	if places_director == null or launch_site == null or launch_site.site.is_empty():
		return
	places_director.mark({"id": "launch_site", "kind": &"launch", "name": tr("Launch Site"),
		"pos": LaunchSite.board_position(launch_site.site)})


## The words when the Star Map needs a mission first: where the Launch Site is, and the arrow points there.
func _launch_site_hint() -> String:
	var words := StarMap.action_words(StarMap.MISSION)
	var way := _point_to_launch_site()
	return words if way == "" else "%s. %s" % [words, way]


## Points the find arrow at the Mission Board: "Follow the arrow: the Launch Site is 32 blocks away." ("" when this
## world has none, or the child isn't standing in it yet).
func _point_to_launch_site() -> String:
	if launch_site == null or launch_site.site.is_empty() or not is_instance_valid(player) or not player.is_spawned():
		return ""
	var at := LaunchSite.board_position(launch_site.site)
	var runner := get_node_or_null("ChatCommands")
	if runner and runner.has_method(&"point_at"):
		runner.call(&"point_at", tr("the Launch Site"), at)
	var far := int(Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length())
	return tr("Follow the arrow: the Launch Site is %s away.") % Lang.blocks(far)


## The Star Map's card of a planet that needs a mission: its hint line says the way, and the arrow points there.
func _on_star_map_body(_id: StringName) -> void:
	if space != null and space.panel != null and space.panel.card_state_words() == StarMap.action_words(StarMap.MISSION):
		var way := _point_to_launch_site()
		if way != "":
			space.panel.say(way)


## LAUNCH (the check passed): flies the rocket, or says why not. In a shared world the owner (the host) calls its
## friends to fly along (spec §21d.6 phase 2: CrewFlights; everyone is told when it lifts off); a friend launches from
## its own pad.
func launch_rocket(rocket: Dictionary) -> String:
	if _quitting:
		return ""
	var u := int(rocket.get("destination", 0))
	var peers := 1 if is_client() else multiplayer.get_peers().size()
	var why := MissionRules.launch_refusal(true, is_client(), peers)
	if why != "":
		return MissionRules.message(why)
	if mission_gate() != "":
		return mission_gate()   # owner #78: Survivor's missions need the rocket invented
	if not SpaceRules.may_launch(Game.mode):
		return SpaceRules.message("no_flying")
	if not UniverseRegistry.space_available().has(u):
		return SpaceRules.message("coming_soon")
	print("MISSION launch to %d: %d parts in %d stages" % [u, (rocket.get("cells", {}) as Dictionary).size(),
		(rocket.get("stages", []) as Array).size()])
	if peers > 0 and crew != null:
		return crew.launch(rocket)   # spec §21d.6 phase 2: the friends here are called to take their seats
	fly.call(rocket)
	return ""


## A mission's rocket reached world u: it is on the route from now on, and the child lands there.
func mission_arrive(u: int) -> void:
	if _quitting or not MissionRules.has_mission(u):
		return
	if Profile.data.missions.fly(u) and u == SpaceRules.MOON:
		InviteRules.friend_landed("moon")   # the core loop: a friend's first Moon landing pays their inviter (#79)
	mission_landing = u
	if crew != null:
		crew.landed(u)   # spec §21d.6: the crew is carried into the Moon world (welcomed there), the pilot's badge
	_travel_space.call_deferred(u)


# --- Owner #106: a crash has fair costs --------------------------------------------------------------------------------
# The descent the child flies came down too fast: the flight played the way home (RocketFlight's crash steps) and the
# rocket fell by the Launch Site (_flight_wreck: the pad's rocket loses 15-35% of its parts, CrashRules; in the Sandbox
# they are gone from what the child owns too). Home, the child stands at the Mission Board (its line says what broke
# and the gold to rebuild) with half the hearts where hearts count (Survivor; the Sandbox has no harm: its words say so).
# The world is not on the route: only a landing puts it there. A crew crashes together: the host halves every crew
# member's hearts and nobody's world moves; each crew member's own flight comes home the same way.

## A flight's way home after a crash is over (the screen faded).
func _on_flight_crashed(u: int) -> void:
	var was: Node = flight
	flight = null   # (the flight puts everything back and frees itself)
	if _quitting:
		return
	if is_instance_valid(was) and bool(was.get("crew_follow")):
		_crash_home()
		if crew != null:
			crew.follower_crashed()
		_crash_words(CrewFlightRules.CRASHED_HOME)
		return
	if _flight_is_mission:
		_flight_is_mission = false
		mission_crash(u)
		return
	_crash_home()   # (the developer's test flight: home, nothing on the pad broke)
	_crash_words()


## A mission's descent crashed on world u: home by the Launch Site with half the hearts where hearts count (Survivor,
## where a knock-out costs something: ModeRules.LOSSES; the crew's too), the world not on the route, kind words. The
## Sandbox shows hearts for its gentle monsters but a knock-out costs nothing there: its hearts stay whole (the lead's
## ruling: its cost is the parts).
func mission_crash(u: int) -> void:
	if _quitting:
		return
	mission_landing = 0
	_crash_home()
	var hurt: Array[int] = [multiplayer.get_unique_id()]
	if crew != null:
		hurt.append_array(crew.crew_peers())
		crew.crashed()
	if Game.allows(ModeRules.LOSSES) and not is_client():
		for p: Player in _players.get_children():
			if hurt.has(p.peer_id):
				_crash_hearts(p)
	print("MISSION crash on %d: home by the Launch Site (%s), the route still %s" % [u,
		"half the hearts" if Game.allows(ModeRules.LOSSES) else "no harm", mission_route()])
	_crash_words()


## Survivor (host): this player's hearts after a crash (half at most, never a knock-out), sent to everyone.
func _crash_hearts(p: Player) -> void:
	var hp := CrashRules.hearts_after(p.health.hp, Health.MAX_HP)
	if hp == p.health.hp:
		return
	p.health.hp = hp
	Session.broadcast_health(p.peer_id, hp)
	Session.player_hurt.emit(p.peer_id, hp, Vector3.INF)


## The local player home at the Mission Board (its front; the board opens with the crash's line), kept safe a moment.
func _crash_home() -> void:
	if not is_instance_valid(player):
		return
	if launch_site != null and not launch_site.site.is_empty():
		var site := launch_site.site
		player.global_position = LaunchSite.to_world_point(site, LaunchSite.BOARD_AT + Vector2(0, 1.6),
			(site.pos as Vector3i).y + 1.05)
	player.velocity = Vector3.ZERO
	player.health.protect(3.0)


## The words once home: the hearts (or the Sandbox's no harm; the real fact was the way home's), then `more`.
func _crash_words(more: String = "") -> void:
	var line := tr(CrashRules.HEARTS_WORDS if Game.allows(ModeRules.LOSSES) else CrashRules.SANDBOX_WORDS)
	if more != "":
		line = "%s %s" % [line, tr(more)]
	if is_instance_valid(hud):
		hud.toast(line, 7.0)
	ReadAloud.speak(line)


## The falling rocket hit the ground by the Launch Site (the flight's `wreck`): the host's pad loses its broken parts
## (seeded per crash), the Sandbox's owned parts too; the board gets its line. What broke, for the flight's words.
func _flight_wreck() -> Dictionary:
	if is_client() or launch_site == null or not _flight_is_mission:
		return {}
	var seed := randi()
	var d := launch_site.crash_damage(seed)
	if d.is_empty():
		return {}
	var gold := 0
	if Game.allows(ModeRules.UNLIMITED_BLOCKS):   # the Sandbox: the parts the child bought are broken too
		Profile.data.missions.lose_parts(d.parts)
		Profile.save()
		gold = CrashRules.rebuild_gold(d.rocket, Profile.data.missions.owned())
	else:   # Survivor: they came from the bag; the bag's spares cover some
		var bag := Session.inventory_of(player.peer_id)
		var have := {}
		for id: int in d.parts:
			have[id] = bag.count(id)
		gold = CrashRules.rebuild_gold(d.parts, have)
	launch_site.notice_crash(CrashRules.words(int(d.count), gold))
	print("MISSION crash: %d parts broke (seed %d): %d gold to rebuild" % [int(d.count), seed, gold])
	return {"count": int(d.count), "gold": gold}

# --- Spec §26: prospecting (Gemma's camp, her quests, the deposits, oil wells) -----------------------------------------
# Green Meadows and the Sandstorm Desert hide rich deposits where real geology puts them (the generator writes them:
# DepositRules); spec §26.5: so do the Moon and Mars (Gemma's space camp by the landing pad; the planet guide's compass
# asks the quest's walk first: _setup_planet_guide). ProspectDirector (node "Prospecting", every game of those worlds,
# never the arena): Gemma's camp a short walk from the spawn and her board (walking up; DIG in MORE; J on a PC), the
# quest's steps (the HUD's compass points to its place), MY MAP's marks for the finds, the oil wells, the Metal
# Detector's beeps. Quests pay like the School (Survivor: the host's wallet; the Sandbox: the profile); a Survivor
# well's drums go into the bag. A LAN guest sees the camp but prospects in its own world. The world's part is saved in
# WorldMeta.prospect, the child's in the profile.

var prospecting: ProspectDirector
var dig_button: TouchButton


func _setup_prospecting() -> void:
	if Game.mode == ModeRules.WAVE or DepositKinds.in_universe(Game.universe).is_empty():
		return
	var gen: Object = world.terrain().generator
	if gen is EditedGenerator:
		gen = (gen as EditedGenerator).base
	var rules: DepositRules = (gen as MeadowsGenerator).deposits() if gen is MeadowsGenerator else null
	if rules == null:
		return
	prospecting = ProspectDirector.new()
	prospecting.name = "Prospecting"
	prospecting.universe = Game.universe
	prospecting.host = not is_client()
	prospecting.survivor = not Game.allows(ModeRules.INFINITE_GOLD)
	prospecting.player_position = func() -> Vector3: return Player.position_or_none(player)
	prospecting.overlay_open = func() -> bool:
		return pause_menu.visible or hud.palette.visible or hud.chat.is_open() or hud.more.is_open() \
			or (launch_site != null and launch_site.board != null and launch_site.board.is_open())
	prospecting.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 6.0)
	prospecting.mark_map = places_director.mark
	prospecting.pay = _prospect_pay
	prospecting.answer_gold = _prospect_answer_gold
	prospecting.give = func(id: int, n: int) -> bool:
		var bag := Session.inventory_of(player.peer_id)
		if bag.count(id) + n > Inventory.MAX_COUNT:
			return false
		bag.add(id, n)
		return true
	add_child(prospecting)
	var pad := Vector3.INF
	if meta != null and not is_client():
		var site := LaunchSite.from_save(meta.launch_site)
		if not site.is_empty():
			pad = Vector3(site.pos as Vector3i)
	prospecting.setup(world.generator_shape(), rules, meta if not is_client() else null, Profile.data.prospect, _layer, pad)
	_layer.move_child(prospecting.board, -1)   # a PC's Esc reaches the open board before the pause menu (like the Mission Board)
	hud.look_area.blockers.append_array(prospecting.board.blockers())
	pause_menu.opened.connect(prospecting.board.close)
	PadFocus.watch(prospecting.board)   # owner #90: Gemma's board with a controller
	if not hud.compass.guide.is_valid():
		hud.compass.guide = prospecting.compass_target
	dig_button = TouchButton.new()
	dig_button.name = "Dig"
	dig_button.text = "DIG"
	dig_button.symbol = &"dig"
	hud.more.add(dig_button, true)
	dig_button.pressed.connect(prospecting.open_journal)


## A prospecting quest's gold for this child: Survivor through the host's wallet (the HUD and the online ledger hear it),
## the Sandbox into the profile like the School's.
func _prospect_pay(gold: int) -> void:
	if gold <= 0:
		return
	if Game.allows(ModeRules.INFINITE_GOLD):
		EarnRules.credit(Profile.data, gold)
		Profile.save()
	else:
		Session.gold_add(player.peer_id, gold, "prospect")


## The quests' exercises pay the School's answer gold (EarnRules.answer_gold, its day's cap), in the same wallet.
func _prospect_answer_gold() -> int:
	var today := SchoolClock.today()
	if Game.allows(ModeRules.INFINITE_GOLD):
		return EarnRules.answer_gold(Profile.data, today)
	var before := Profile.data.survivor_gold
	var gold := EarnRules.answer_gold(Profile.data, today)   # counts the day's cap
	Profile.data.survivor_gold = before
	Session.gold_add(player.peer_id, gold, "prospect_answer")
	return gold

# --- Owner #78 (spec §21e): invent it -------------------------------------------------------------------------------
# The Inventions book (InventionsDirector, node "Inventions", every mode but Monster Wave's arena): how people learned to
# fly, in history's order. INVENT in MORE and I on a PC open it. In Survivor MAKE IT at a Workbench (the bag's
# materials, the host's wallet; a LAN guest invents in its own world), TRY IT (the try's gold: the host's wallet in
# Survivor, the profile in the Sandbox), FLY WITH IT; the Player flies what was invented (InventionRules).

var inventions: InventionsDirector
var invent_button: TouchButton


func _setup_inventions() -> void:
	if Game.mode == ModeRules.WAVE:
		return
	inventions = InventionsDirector.new()
	inventions.name = "Inventions"
	inventions.survivor = not Game.allows(ModeRules.FREE_FLY)
	inventions.host = not is_client()
	inventions.world_seed = meta.seed if meta != null else 0
	inventions.data = Profile.data.inventions
	inventions.school = Profile.data.school
	inventions.player = player
	inventions.bag = func() -> Inventory:
		if is_client() or Game.allows(ModeRules.UNLIMITED_BLOCKS):
			return null
		return Session.inventory_of(player.peer_id)
	inventions.near_workbench = func() -> bool:
		return bool(Session.craft_stations_near(player.eye_position(), CraftRules.REACH).get(Recipes.TABLE, false))
	inventions.gold = func() -> int: return Profile.data.survivor_gold
	inventions.spend = func(g: int) -> bool: return Session.gold_spend(player.peer_id, g)
	inventions.pay = func(g: int) -> void:   # a try's gold: Survivor's wallet, the Sandbox's profile (like the quests')
		if Game.allows(ModeRules.INFINITE_GOLD):
			EarnRules.credit(Profile.data, g)
			Profile.save()
		else:
			Session.gold_add(player.peer_id, g, "invent_try")
	inventions.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 6.0)
	add_child(inventions)
	inventions.setup(_layer, hud)
	_layer.move_child(inventions.panel, -1)   # a PC's Esc reaches the open book before the pause menu
	hud.look_area.blockers.append_array(inventions.panel.blockers())
	pause_menu.opened.connect(inventions.panel.close)
	PadFocus.watch(inventions.panel)   # owner #90: the book with a controller
	invent_button = TouchButton.new()
	invent_button.name = "Invent"
	invent_button.text = "INVENT"
	invent_button.symbol = &"invent"
	hud.more.add(invent_button, true)
	invent_button.pressed.connect(func() -> void: inventions.open())

# --- The PC's KEYS card (owner #84) and the CONTROLLER card (owner #90) ---------------------------

var keys_card: KeysCard


## On a PC: the card over the world, shown once at the first spawn (settings.keys_seen), then by F1. Owner #90: on every
## device the same card is the CONTROLLER card while a game controller plays (once by itself: settings.pad_seen; then
## the pause menu's CONTROLLER). Never headless (tests and tools share the profile file).
func _setup_keys_card() -> void:
	if DisplayServer.get_name() == "headless":
		return
	keys_card = KeysCard.new(PadFocus.current_family() if PadFocus.pad_active() else &"")
	keys_card.visible = false
	_layer.add_child(keys_card)
	if KeysRules.due(Profile.data.settings, PlatformRules.current()):
		player.spawned.connect(func() -> void:
			Profile.data.settings.keys_seen = true
			Profile.save()
			keys_card.open(), CONNECT_ONE_SHOT)


# --- Day and night, beds and sleeping (M1b Task 10) -------------------------------------------

var sky: SkyCycle
var _sleep: SleepDirector


func _add_sky(time_of_day: float) -> void:
	sky = SkyCycle.new()
	sky.name = "SkyCycle"
	sky.world = world
	sky.time = time_of_day
	sky.game = Game.survivor_game   # spec §12.18: Build to Survive's fast clock (a guest has the host's game by now)
	sky.running = Game.mode != ModeRules.WAVE   # spec §12.20: the arena is always bright day
	add_child(sky)
	_apply_universe_look()   # M3 Task 5: the universe's daytime sky and music
	Music.follow_sky(sky)   # day, night and boss music follow this clock (M2 Task 11)


func _setup_sleep() -> void:
	_sleep = SleepDirector.new()
	_sleep.name = "SleepDirector"
	_sleep.world = world
	_sleep.sky = sky
	_sleep.player = player
	_sleep.hud = hud
	add_child(_sleep)
	hud.stop_for_today.connect(_save_and_quit)   # asleep: STOP FOR TODAY saves and leaves (M2 Task 17)
	if not is_client() and meta.homes.has(_home_key()):
		_sleep.restore_home(meta.homes[_home_key()])


## Host: jumps the clock to time of day t (0..1; DayCycle.SUNRISE, NOON, SUNSET, MIDNIGHT) for
## everyone. The chat's /time uses it.
func set_time_of_day(t: float) -> void:
	if sky and not is_client():
		sky.set_time(t)


## Host: where the nearest secret of `kind` (&"" for any) nobody found yet is. The chat's /secret uses it.
func find_secret(kind: StringName, near: Vector3) -> String:
	return _secrets.hint(kind, near)


## Host: sends a player home, to the bed they last slept in or the world spawn without one. The
## chat's /home uses it.
func go_home(peer_id: int) -> void:
	if _sleep and not is_client():
		_sleep.send_player_home(peer_id)


func _save_time_and_homes() -> void:
	if sky:
		meta.time_of_day = sky.time
	if _sleep:
		var bed := _sleep.home_of(player.peer_id)
		if bed == BedRules.NO_BED:
			meta.homes.erase(_home_key())
		else:
			meta.homes[_home_key()] = bed


## Homes are saved per player name. Only the host's own player has a name here yet; LAN guests'
## homes last for the session (see docs/devlog/parts/task-10.md).
func _home_key() -> String:
	var n := str(Profile.data.username)
	return n if n != "" else "player"


# --- Avatar style (M1b Task 13) -----------------------------------------------------------------

## Every player on this device wears this device's style: real-looking people in REALISTIC.
func _style_avatars(style: String) -> void:
	for p in _players.get_children():
		if p is Player and p.is_node_ready():
			(p as Player).set_avatar_style(style)


## Players who join later (host: _add_player; client: replicated) get it as soon as they are ready.
func _on_player_entered(node: Node) -> void:
	if node is Player:
		node.ready.connect(func() -> void: (node as Player).set_avatar_style(str(Profile.data.settings.style)), CONNECT_ONE_SHOT)

# --- Photo mode (M3 Task 16) -------------------------------------------------------------------

var photo: PhotoMode


## The HUD's camera button (or P) opens photo mode over the HUD and under the pause menu.
func _setup_photo() -> void:
	photo = PhotoMode.new()
	photo.name = "PhotoMode"
	_layer.add_child(photo)
	_layer.move_child(photo, pause_menu.get_index())
	photo.setup(player, hud, func(cell: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(cell)))
	hud.photo_requested.connect(photo.open)

# --- Knock-outs and pickup bags (M2 Task 2) -----------------------------------------------------

var _knockout := KnockoutDirector.new()


## Every peer, before any bag can arrive (a LAN guest's too): same name, same spawner.
func _add_knockout() -> void:
	_knockout.name = "Knockout"
	_knockout.name_of = _player_name
	add_child(_knockout)


## Host: a player's name, which owns their bags: this device's player is the profile's name (like
## homes and inventories), a LAN guest their chat name ("" if they never joined the chat: anyone's).
func _player_name(peer_id: int) -> String:
	if peer_id == multiplayer.get_unique_id():
		return _home_key()
	return str(Session.chat_names.get(peer_id, ""))

# --- M2 Task 7: Tilly the trader ----------------------------------------------------------------

var _traders := Node3D.new()
var _trader_spawner := MultiplayerSpawner.new()


func _add_trader_spawner() -> void:
	_traders.name = "Traders"
	add_child(_traders)
	_trader_spawner.name = "TraderSpawner"
	add_child(_trader_spawner)
	_trader_spawner.spawn_path = _trader_spawner.get_path_to(_traders)
	_trader_spawner.spawn_function = _make_trader


func _make_trader(data: Variant) -> Node:
	var t := Trader.new()
	t.setup(data)
	print("TRADER at %s" % t.position)   # host and guests (the spawner replicates her)
	return t


## Host and solo: a Survivor world's stall, placed once from the seed and saved with the world.
func _place_trader() -> void:
	if TraderRules.place_in(meta, Game.mode, world.generator_shape(), world.spawn_column()):
		_trader_spawner.spawn(TraderRules.spawn_data(meta))


## The player's first visit: the hint arrow goes on this device, and the host's world remembers it.
func _on_shop_opened() -> void:
	for t in _traders.get_children():
		if t is Trader:
			(t as Trader).show_hint(false)
	if not is_client():
		meta.trader_visited = true

# --- Monsters (M2 Task 4) ---------------------------------------------------------------------------

var _voxel_tool: VoxelTool        # host: copies boxes of blocks for the lantern check


## Host and solo: night monsters around every player (§12.4); gentle ones in Sandbox, with the world
## setting MONSTERS: ON / OFF in the pause menu (§12.15). Wild monsters are not saved.
func _start_monsters() -> void:
	_monsters.universe = UniverseRules.scale_universe(Game.mode, Game.universe)   # M3 Task 5: × 2^(u−1) health, hits and coins (waves copy it); owner 39: never in Sandbox
	_monsters.gentle = Game.allows(ModeRules.GENTLE_MONSTERS)
	_monsters.player_positions = _player_positions
	_monsters.is_ready = world.is_area_ready
	_monsters.stand_spot = func(x: int, z: int) -> Vector3:
		var start := maxi(world.surface_height(x, z), MeadowsShape.SEA_LEVEL)
		return MonsterRules.surface_spot(x, z, start, world.get_block, WorldService.MAX_Y)
	_monsters.lights_near = func(pos: Vector3) -> Array[Vector3i]:
		if _voxel_tool == null:
			_voxel_tool = world.terrain().get_voxel_tool()
		return MonsterDirector.lights_around(_voxel_tool, pos)
	_monsters.home_beds = func() -> Array[Vector3i]: return _sleep.home_beds() if _sleep else ([] as Array[Vector3i])
	_monsters.time_of_day = func() -> float: return sky.time
	_monsters.enabled = func() -> bool: return MonsterRules.spawns_enabled(Game.mode, meta.monsters_on)
	var home := world.spawn_column()
	_monsters.world_spawn = Vector3(home.x + 0.5, 0.0, home.y + 0.5)
	_monsters.block_at = world.get_block
	_monsters.golden_caught = func(peer: int, pos: Vector3, id: String) -> void: _secrets.reward_golden(peer, pos, id)   # §12.16 #4
	_monsters.start()
	if Game.allows(ModeRules.GENTLE_MONSTERS):
		pause_menu.show_monsters_setting(meta.monsters_on)
		pause_menu.monsters_toggled.connect(_on_monsters_toggled)


## MONSTERS: ON / OFF (Sandbox, pause menu): OFF sends every monster away at once.
func _on_monsters_toggled(on: bool) -> void:
	meta.monsters_on = on
	if not on:
		_monsters.puff_all()


## Chat /summon slime 3 (host): a monster of that level a few blocks from `near`; "" when it came.
func summon_monster(kind: StringName, level: int, near: Vector3) -> String:
	return "" if is_client() else _monsters.summon(kind, level, near)

# --- Bot friends (M2 Task 15) -------------------------------------------------------------------

var _bots := Node3D.new()
var _bot_spawner := MultiplayerSpawner.new()
var _bot_director: BotDirector   # host and solo only


## Every peer: friends are replicated like animals (the host simulates them).
func _add_bot_spawner() -> void:
	_bots.name = "Bots"
	add_child(_bots)
	_bot_spawner.name = "BotSpawner"
	add_child(_bot_spawner)
	_bot_spawner.spawn_path = _bot_spawner.get_path_to(_bots)
	_bot_spawner.spawn_function = _make_bot


func _make_bot(data: Variant) -> Node:
	var b := BotFriend.new()
	b.setup(data)
	b.world = world
	b.combat = _combat
	return b


## Host and solo: the pause menu's FRIENDS row adds and removes friends; saved ones come back
## next to the player once it stands in the world.
func _start_bots() -> void:
	_bot_director = BotDirector.new()
	_bot_director.name = "BotDirector"
	_bot_director.add_to_group(&"bot_director")   # the secrets' chime asks an explorer to point (M2 Task 16)
	_bot_director.container = _bots
	_bot_director.world = world
	_bot_director.spawn = func(data: Dictionary) -> Node: return _bot_spawner.spawn(data)
	_bot_director.quest_near = _quests.target_for   # owner #45a: "follow the arrow" leads to the story's place
	add_child(_bot_director)
	pause_menu.friends = _bot_director
	player.spawned.connect(func() -> void: _bot_director.restore(meta.bots), CONNECT_ONE_SHOT)
	_setup_bot_seats()   # M4 E: online, friends fill the seats the players leave

# --- M2 Task 9: the Monster Totem and waves -----------------------------------------------------------

var _waves := WaveDirector.new()


## Every peer, before the Totem can arrive (a LAN guest's too): same name, same spawner and RPCs.
func _add_waves() -> void:
	_waves.name = "Waves"
	_waves.monsters = _monsters
	add_child(_waves)


## Host and solo: every world's Totem (Survivor and Sandbox), placed once from the seed after Tilly's
## stall and saved with the wave it offers; wave monsters come through the MonsterDirector, and no
## night monsters come while a wave is on (the budget of 20). Sandbox MONSTERS: OFF ends a wave.
func _start_waves() -> void:
	if not Game.allows(ModeRules.TOTEM):
		return   # owner feedback #44: Survivor has no Totem waves (a world's saved wave number stays, unused)
	WaveRules.place_in(meta, world.generator_shape(), world.spawn_column())
	_waves.gentle = Game.allows(ModeRules.GENTLE_MONSTERS)
	_waves.universe = _monsters.universe
	_waves.stand_spot = _monsters.stand_spot
	_waves.is_ready = world.is_area_ready
	_waves.monsters_allowed = func() -> bool: return MonsterRules.spawns_enabled(Game.mode, meta.monsters_on)
	_waves.next_wave = meta.wave_next
	_waves.next_changed.connect(func(n: int) -> void: meta.wave_next = n)
	_monsters.enabled = _waves.night_allowed(_monsters.enabled)
	if Game.allows(ModeRules.GENTLE_MONSTERS):
		pause_menu.monsters_toggled.connect(func(on: bool) -> void:
			if not on:
				_waves.stop())
	_waves.place_totem(meta.totem_pos, meta.totem_yaw)


## This game's HUD follows the wave state (the wave line, the Totem's panel).
func _setup_waves_hud() -> void:
	_waves.state_changed.connect(hud.show_wave_state)
	if not _waves.current.is_empty():
		hud.show_wave_state(_waves.current)


## Host (Task 10's hook): the WaveDirector with boss_offered, boss_requested and set_boss_running.
func waves() -> WaveDirector:
	return _waves

# --- M2 Task 5: stealth -------------------------------------------------------------------------

var _stealth := StealthDirector.new()


## Every peer, before any player arrives: the host's word puts bodies into hiding spots on every game.
func _add_stealth() -> void:
	_stealth.name = "Stealth"
	add_child(_stealth)


## Once the world and this game's player exist (host and guests): the light, bushes and this player's
## noise (the HUD's eye and bars); the host also checks hiding and logs the noises monsters hear.
func _setup_stealth() -> void:
	_stealth.block_at = world.get_block
	_stealth.surface_height = world.sky_height   # universe 6: under the Glow Caves' roof is underground
	_stealth.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
	_stealth.lights_near = func(head: Vector3) -> bool: return StealthDirector.light_around(world, head)
	_stealth.local_player = player
	_stealth.watch_local(_interactor)
	hud.setup_stealth(_stealth)
	if not is_client():
		_stealth.start_host()
		_stealth.watch_blocks(world)

# --- M2 Task 10: the Stone Golem and the portal -------------------------------------------------

var _boss := BossDirector.new()


## Every peer, before any Golem or portal can arrive: same name, same spawners.
func _add_boss() -> void:
	_boss.name = "Boss"
	add_child(_boss)


## Host and solo: the world's honest help and its portal come back; a fight's end is saved at once
## (the profile too: a win opens the next universe).
func _start_boss() -> void:
	_boss.block_at = world.get_block
	_boss.opens_portal = Game.mode != ModeRules.WAVE   # spec §12.20: the raid boss offers a choice instead
	_boss.restore(meta.boss_help, meta.portal_pos)
	_boss.fight_ended.connect(func(_won: bool, _percent: int) -> void: save_world())
	_link_totem.call_deferred()


## M2 Task 9's Totem (merged separately): its Stone Golem button starts the fight here, and the Totem
## knows while the Golem fights (BossDirector.link_waves). Deferred: the wave director may be made later.
func _link_totem() -> void:
	if has_method(&"waves"):
		_boss.link_waves(call(&"waves"))


## Host: the Golem rises at the Totem (Task 9 calls this when the boss is accepted after wave 5).
## Returns why it can't ("" = it comes).
func start_boss(totem_pos: Vector3) -> String:
	return "" if is_client() else _boss.start(totem_pos)


## Chat /summon golem (Sandbox, host): the Golem rises a few steps from `near` (/summon serpent: the
## Sand Serpent, M3 Task 2).
func summon_boss(near: Vector3, kind: StringName = &"") -> String:
	return "" if is_client() else _boss.start(near, kind)


## Every peer: the HUD's boss bar, and the portal's and the Golem's shaders compiled as the world
## appears (never in the middle of a fight).
func _setup_boss_hud() -> void:
	_boss.bar = hud.boss_bar
	ShaderWarmup.at_spawn(player.spawned, func() -> void: DesertPortal.prewarm(player.camera()))

# --- M2 Task 8: defenses (spike traps, lantern fear, lantern light) -----------------------------------

var _defenses := DefenseDirector.new()


## Every peer: the node (its spike RPC lines up across the network) and this game's lantern lights. The
## world is read through closures, so they work once it exists. A guest's world does not announce
## edits: its lantern index looks again every 2 s.
func _add_defenses() -> void:
	_defenses.name = "Defenses"
	_defenses.block_at = func(p: Vector3i) -> int: return world.get_block(p) if world else BlockIds.AIR
	_defenses.chunk_ready = func(c: Vector3i) -> bool: return world != null and world.is_editable(c * DefenseDirector.CHUNK)
	_defenses.scan_chunk = _lanterns_in_chunk
	_defenses.camera = func() -> Camera3D: return player.camera() if is_instance_valid(player) and player.is_spawned() else null
	_defenses.time_of_day = func() -> float: return sky.time if sky else DayCycle.START
	if is_client():
		_defenses.cache_seconds = 2.0
	add_child(_defenses)
	_on_defense_settings(Profile.data.settings)
	Game.settings_applied.connect(_on_defense_settings)


## Host and solo: traps hurt monsters and weak monsters fear lanterns; placed and broken lanterns reach
## the index at once.
func _start_defenses() -> void:
	world.block_changed.connect(_defenses.note_block)
	_defenses.start()


## One bulk copy of a 16-block chunk and a native search for lanterns in it.
func _lanterns_in_chunk(chunk: Vector3i) -> Array[Vector3i]:
	var origin := chunk * DefenseDirector.CHUNK
	var ids: Array[int] = [BlockIds.LANTERN]
	return MonsterDirector.find_blocks(world.copy_box(origin, Vector3i.ONE * DefenseDirector.CHUNK), origin, ids)


## The Low graphics preset has no lantern lights (the lanterns still glow).
func _on_defense_settings(settings: Dictionary) -> void:
	_defenses.set_light_count(DefenseDirector.lights_for(str(settings.get("graphics", "medium"))))

# --- M4 C: online play (PLAY ONLINE, invites) ---

## The online host: once the relayed match exists, the pause menu gets its INVITE row and the player
## a short tip; if hosting online fails, plain words (the world goes on here, solo).
func _setup_online() -> void:
	if Game.net_mode != &"host" or not Session.wants_online():
		return
	Session.online_match_ready.connect(_on_online_match_ready)
	Session.online_failed.connect(_on_online_failed)


func _on_online_match_ready(match_id: String) -> void:
	var service := Session.online_service()
	service.sign_in()   # already signed in from PLAY ONLINE; developer args start here
	pause_menu.online = service
	pause_menu.online_match = match_id
	pause_menu.online_world = OnlineRules.world_name(Game.mode)
	_setup_online_hud()
	if is_instance_valid(hud):
		hud.toast("Your world is online! Invite friends from the menu.", 5.0)


func _on_online_failed(reason: String) -> void:
	pause_menu.online_match = ""
	if is_instance_valid(hud) and not is_client():
		hud.toast(OnlineRules.message(reason), 5.0)


## The invite toast's JOIN must not build or break under it (LookBuildArea reads touches first).
func _setup_online_hud() -> void:
	if not is_instance_valid(hud):
		return
	for c in Session.online_toast_blockers():
		if not hud.look_area.blockers.has(c):
			hud.look_area.blockers.append(c)


## An invite's JOIN while playing here (OnlineFlow.join): save this world, then join the friend's.
func leave_for_online(match_id: String) -> void:
	if _quitting:
		return
	_quitting = true
	save_world()
	if not is_client() and world:
		await world.save_and_wait()
	OnlineFlow.join_now(match_id)

# --- M4 A: plain words for network problems ---------------------------------------------------------

var net_overlay: NetOverlay


## Over everything: "Trying again…" while a guest rejoins, short notes, and the goodbye words.
func _add_net_overlay() -> void:
	net_overlay = NetOverlay.new()
	net_overlay.name = "NetOverlay"
	_layer.add_child(net_overlay)


## A guest's game ended (the host left, the link could not come back, …): the words for why stay a
## moment, then the menu. `words`: the crew's own (spec §21d.6: the world flew away, a follow that failed).
func _goodbye(words: String = "") -> void:
	_quitting = true
	WorldService.stop_viewers(self)   # M4 A2: the world stops streaming, so it goes at once (not 6-13 s)
	var code: StringName = Session.a_last_notice()
	if code in [&"", NetWords.BACK, NetWords.LINK_LOST, NetWords.SERVER_GONE]:
		code = NetWords.HOST_LEFT
	Session.a_clear_notice()
	if words == "" and Session.crew_following():
		words = CrewFlightRules.LOST   # following the host's world did not work out
	Session.crew_follow_done()
	net_overlay.goodbye(words if words != "" else NetWords.text(code))
	var me: WeakRef = weakref(self)
	get_tree().create_timer(NetOverlay.GOODBYE_SECONDS).timeout.connect(func() -> void:
		if me.get_ref() != null:
			Game.quit_to_menu())

# --- Creature minds (M2 Task 18, owner feedback #24) ------------------------------------------------

## Host and solo: this world's learned species tables (WorldMeta.minds), the animals' clock (the sky),
## and the treats and pets that make an animal like a player (the host checks the reach).
func _start_minds() -> void:
	MindBook.current = MindBook.new()
	MindBook.current.load_save(meta.minds)
	Animal.time_source = _time_of_day
	Animal.storm_source = _storm_strength   # owner #41: a horse slows in a sandstorm, a camel doesn't
	Session.mind_treat_requested.connect(_on_mind_treat)
	Session.pet_requested.connect(_on_mind_pet)
	_start_monster_minds()


## Host and solo (part 2): the guards around monster tactics — Cozy worlds never learn, Sandbox's
## gentle monsters learn slowly, a child's knock-outs make them ease off (fading over minutes) — and
## the one-time hints of what a species learned, told to every child as a toast.
func _start_monster_minds() -> void:
	MonsterMinds.current = MonsterMinds.new()
	MonsterMinds.current.difficulty = Session.difficulty
	MonsterMinds.current.gentle = Game.allows(ModeRules.GENTLE_MONSTERS)
	MonsterMinds.current.load_hints(meta.mind_hints)
	MonsterMinds.current.hint.connect(_on_mind_hint)
	Session.knockout_received.connect(func(peer_id: int, _at_home: bool) -> void:
		MonsterMinds.current.note_knockout(peer_id))
	var clock := Timer.new()
	clock.name = "MindClock"
	clock.wait_time = 1.0
	clock.autostart = true
	clock.timeout.connect(func() -> void: MonsterMinds.current.tick(1.0))
	add_child(clock)


func _on_mind_hint(text: String) -> void:
	for p in _players.get_children():
		if p is Player:
			Session.send_feedback((p as Player).peer_id, text)


func _time_of_day() -> float:
	return sky.time if sky else DayCycle.NOON


## Owner #41: the storm's strength 0..1 (0 in a universe without storms).
func _storm_strength() -> float:
	return _sandstorm.strength if is_instance_valid(_sandstorm) else 0.0


func _on_mind_treat(peer_id: int, animal_name: String) -> void:
	Animal.mind_treat(_animals, Session._player_for_peer(peer_id), animal_name, true)


func _on_mind_pet(peer_id: int, animal_name: String) -> void:
	Animal.mind_treat(_animals, Session._player_for_peer(peer_id), animal_name, false)


func _exit_tree() -> void:
	if Animal.time_source == Callable(self, &"_time_of_day"):
		Animal.time_source = Callable()   # the sky goes with this scene
	if Animal.storm_source == Callable(self, &"_storm_strength"):
		Animal.storm_source = Callable()   # owner #41

# --- M4 E: online team chat ---

## In an online match with this device's OnlineService (PLAY ONLINE), the HUD's chat talks in the
## match's team room; developer matches without a service keep the host's relay chat. The host's
## match may be made after its player: then the room opens when the match is ready.
func _setup_team_chat() -> void:
	var service := Session.online_service_or_null()
	if service == null or not Session.wants_online() or not is_instance_valid(hud):
		return
	var match_id := Session.online_match_id()
	if match_id != "":
		hud.chat.use_team_chat(service, match_id)
	elif not is_client():
		Session.online_match_ready.connect(func(id: String) -> void:
			if is_instance_valid(hud):
				hud.chat.use_team_chat(service, id), CONNECT_ONE_SHOT)


# --- M4 E: bot friends fill the empty seats of an online world ---

## Online (four players at most), the host's bot friends take the seats the players leave: the newest
## makes room when a player joins and comes back when one leaves (BotDirector.fit_seats).
func _setup_bot_seats() -> void:
	if not Session.wants_online() or _bot_director == null:
		return
	_bot_director.seats = func() -> int: return BotRules.seats_for_bots(Session.online_players())
	Session.client_ready.connect(_on_bot_seats_changed)
	Session.peer_left.connect(_on_bot_seats_changed)


func _on_bot_seats_changed(_peer_id: int) -> void:
	if is_instance_valid(_bot_director):
		_bot_director.fit_seats.call_deferred()


# --- M3 Task 2: a universe's own content (the Sandstorm Desert) ---------------------------------------
# The world's universe descriptor (world.descriptor(): UniverseRegistry's) brings its night and wave
# monsters, its boss, its secrets and what finding them says, its weather (the desert's sandstorms:
# SandstormDirector) and its traps (cacti and arrow slits: DesertTraps). Green Meadows (universe 1) keeps
# everything as it was. Guests get the same: the host's universe arrives before the world (M3 Task 5).

var _sandstorm: SandstormDirector
var _desert_traps: DesertTraps


## Every peer, right after the world exists: the directors learn the universe's monsters and boss, and
## the nodes its weather and traps need are added (their RPCs line up because every peer adds them).
func _apply_universe_content() -> void:
	var own: Object = world.descriptor()
	if own == null:
		return
	_monsters.universe = UniverseRules.scale_universe(Game.mode, int(own.get("index")))   # owner 39: Sandbox never scales
	_monsters.kinds.assign(own.get("monster_kinds"))
	_waves.kinds.assign(own.get("monster_kinds"))
	_waves.boss_name = str(BossRules.words(StringName(own.get("boss_kind"))).name)
	_boss.boss_kind = StringName(own.get("boss_kind"))
	var weather: Variant = own.get("weather")
	if weather == &"sandstorm" or weather == &"snowstorm":   # M3 Task 3: Frostpeak's snowstorms are the same code
		_sandstorm = SandstormDirector.new()
		_sandstorm.snow = weather == &"snowstorm"
		_sandstorm.name = "Snowstorm" if _sandstorm.snow else "Sandstorm"
		add_child(_sandstorm)
	if own.get("traps") == true:
		_desert_traps = DesertTraps.new()
		_desert_traps.name = "DesertTraps"
		add_child(_desert_traps)


## Every peer, after the SecretDirector is set up: the universe's own secrets and their words.
func _universe_secrets(seed: int) -> void:
	var own: Object = world.descriptor()
	if own == null or not own.has_method(&"secret_rules"):
		return
	_secrets.rules = own.call(&"secret_rules", seed, world.generator_shape())
	var words: Variant = own.get("secret_words")
	if words is Dictionary:
		for kind: Variant in words:
			_secrets.found_text[kind] = words[kind]


## Host: the sandstorm's clock, the traps, and the storm's hold on how visible everyone is.
func _start_universe_host(seed: int) -> void:
	if _sandstorm:
		_sandstorm.start_host(seed)
		_stealth.weather = _sandstorm.visibility
	if _desert_traps:
		_desert_traps.block_at = world.get_block
		_desert_traps.traps_near = func(pos: Vector3) -> Array:
			var out: Array = []
			for s: Dictionary in _secrets.rules.secrets_near(pos, DesertTraps.TRAP_RADIUS):
				out.append_array(s.get("traps", []))
			return out
		_desert_traps.start_host()
	_monsters.light_at = _sneaker_light   # M3 Task 4: a candy sneaker hides in the dark
	_start_dragon_host()   # owner 39: the Dragon Realm's void (monsters puff, friends come back)
	_start_space_host()   # owner #55: no monsters come by themselves in space


## Every peer, once the HUD exists: the Totem's boss button names the world's boss; the sandstorm's
## sandy view and its words reach this game's player.
func _universe_hud() -> void:
	if _boss.boss_kind != BossRules.GOLEM and hud.totem_panel.boss_button:
		hud.totem_panel.boss_button.text = WaveRules.boss_word(BossRules.words(_boss.boss_kind).name)
	if _sandstorm:
		_sandstorm.toast = func(text: String) -> void:
			if is_instance_valid(hud):
				hud.toast(text, 4.0)
		_sandstorm.apply_view = func(strength: float) -> void:
			var amb := get_node_or_null("Ambience") as Ambience
			if amb:
				amb.storm_snow = _sandstorm.snow   # M3 Task 3: white fog and a whiter screen
				amb.storm = strength
	_candy_local()   # M3 Task 4: the chocolate view under water, the night's sprinkles
	_dragon_local()   # owner 39: the wind carries a faller back (the words and the sparkle)
# --- M3 Task 5: the universe ladder and portals -------------------------------------------------------

## Every peer: this world's universe paints the daytime sky and plays its own music (UniverseRegistry;
## Green Meadows keeps today's).
func _apply_universe_look() -> void:
	sky.palette = UniverseRegistry.sky(Game.universe)
	sky.refresh()
	Music.use_tracks(UniverseRegistry.music(Game.universe))
	_apply_liquid()   # M3 Task 4: chocolate water in the Candy Kingdom, water elsewhere
	Music.use_favourites(UniverseRegistry.classical(Game.universe))   # the audio pass: its own pieces first


var universe_hub: UniverseHub


## Every peer, once this game's player exists: the hub panel (between the HUD and the pause menu), the
## stone circle by a Survivor world's spawn (from the seed: every game agrees where), walking into the
## Golem's portal, and the portals' swirl compiled as the world appears.
func _setup_universe_hub() -> void:
	universe_hub = UniverseHub.new()
	universe_hub.name = "UniverseHub"
	add_child(universe_hub)
	universe_hub.player_position = func() -> Vector3:
		return Player.position_or_none(player)
	universe_hub.travel = travel_to
	universe_hub.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 4.0)
	universe_hub.setup_panel(_layer)
	_layer.move_child(universe_hub.panel, hud.get_index() + 1)
	hud.look_area.blockers.append_array(universe_hub.panel.blockers())
	pause_menu.opened.connect(universe_hub.panel.close)
	if UniverseRules.wants_hub(Game.mode):
		var shape := world.generator_shape()
		universe_hub.setup_circle(HubRules.circle_for_world(shape.seed, shape, world.spawn_column()), shape, self)
	_boss.portal_entered.connect(universe_hub.portal_entered)
	if not is_client():
		_start_portal_frames()
	ShaderWarmup.at_spawn(player.spawned, func() -> void: PortalSwirl.prewarm(player.camera()))


## Survivor, played alone (solo, or a host nobody joined): saves this world and opens universe u's world
## (made the first time, with this world's difficulty); the child's bag and hotbar come along
## (UniverseRules.carry) and they arrive by its spawn. Returns why not ("" = on the way).
func travel_to(u: int) -> String:
	if _quitting:
		return ""
	var peers := 1 if is_client() else multiplayer.get_peers().size()
	var why := UniverseRules.travel_refusal(u, Profile.data.universe_unlocked, UniverseRegistry.available(), peers,
		Game.universe)
	if why == "" and not UniverseRules.wants_hub(Game.mode):
		why = "locked"   # the stone circle's travel is Survivor's (owner 39: Sandbox travels through universe portals)
	if why != "":
		return UniverseRules.travel_message(why)
	var plus := Session.shop_travel_refusal(u)   # Owner 35: a universe that comes with EasyCraft Plus
	if plus != "":
		return plus
	_travel.call_deferred(u)
	return ""


func _travel(u: int, via_gate: bool = false) -> void:
	if _quitting:
		return
	_quitting = true
	var slot := ModeRules.slot(ModeRules.SURVIVOR, u)
	var fresh_slot := not WorldSaves.exists(slot)
	var arrival := UniverseRules.arrival_meta(WorldSaves.load_meta(slot) if WorldSaves.exists(slot) else null, u,
		meta.difficulty, _home_key())   # a new world: M2's starter kit, the bag on top
	if fresh_slot:
		arrival.game = meta.game   # spec §12.18: the next universe plays the same game
	arrival.arrival_gate = Game.universe if via_gate else 0   # owner 39: the portal back at the arrival point
	var hotbar: Array[int] = _interactor.hotbar.duplicate()
	UniverseRules.carry(meta, arrival, _home_key(), Session.inventory_of(player.peer_id).to_save(), hotbar,
		_interactor.selected_slot)
	WorldSaves.save_meta(slot, arrival)   # first: a crash in between may copy the bag, never lose it
	Session.set_inventory(player.peer_id, Inventory.from_save(meta.inventories.get(_home_key(), [])))
	save_world()
	Audio.play(&"portal_whoosh")
	await world.save_and_wait()
	print("UNIVERSE travel %d -> %d" % [Game.universe, u])
	var kept: bool = await _close_or_move(u, true)   # spec §21d.6: HOME with a crew brings it along
	Game.start_world(ModeRules.SURVIVOR, false, meta.difficulty, u)
	if kept:
		Game.net_mode = &"host"


var _portal_frames := PortalDirector.new()


## Every peer, before the host's list of swirling doorways can arrive: same name, same RPCs.
func _add_portal_frames() -> void:
	_portal_frames.name = "PortalFrames"
	add_child(_portal_frames)


## Host and solo: the world's saved portal links and frames; every block change can make or break one;
## a guest who joins hears which doorways swirl.
func _start_portal_frames() -> void:
	_portal_frames.block_at = world.get_block
	_portal_frames.area_ready = func(cell: Vector3i) -> bool:
		return world.is_editable(cell - PortalRules.WATCH) and world.is_editable(cell + PortalRules.WATCH)
	_portal_frames.start(meta.portals)
	_start_gates()   # owner 39: universe portals
	world.block_changed.connect(_portal_frames.note_block)
	Session.client_ready.connect(_portal_frames.send_to)

# --- Survivor games and crafting (owner feedback #33, #34; spec §12.18, §12.19) ----------------------------

var _survivor_game := SurvivorGameDirector.new()


## Every peer: the node its RPC-free hooks hang on (the host ticks it; every game fills its HUD's clock).
func _add_survivor_game() -> void:
	_survivor_game.name = "SurvivorGame"
	add_child(_survivor_game)


## Host and solo, a new Survivor world: the game chosen in the menu, its starter kit and its morning.
func _new_survivor_game() -> void:
	meta.game = Game.new_world_game
	Game.new_world_game = SurvivorGames.CLASSIC
	meta.inventories[_home_key()] = SurvivorGames.starter_kit(meta.game).to_save()
	meta.hotbar = SurvivorGames.starter_hotbar(meta.game, meta.hotbar)
	meta.time_of_day = SurvivorGames.new_world_time(meta.game)


## Host and solo: the world's game ticks (shelters, nights, packs, pay) and tunes the night monsters.
func _start_survivor_game() -> void:
	_survivor_game.game = Game.survivor_game
	_survivor_game.scores = meta.game_scores
	_survivor_game.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
	_survivor_game.set_time = set_time_of_day
	_survivor_game.block_at = world.get_block
	_survivor_game.box_reader = world.box_reader
	_survivor_game.name_of = _player_name
	_survivor_game.monsters = _monsters
	if Game.survivor_game != SurvivorGames.CLASSIC:
		_survivor_game.start()
	if _sleep:
		_sleep.may_sleep = _survivor_game.sleep_refusal   # Build to Survive: beds in a shelter only


## Every peer, once this game's player and HUD exist: the game clock (a guest reads its own world and sky),
## and crafting's answers (a toast; a new thing into a free hotbar slot).
func _setup_survivor_game_hud() -> void:
	if Game.mode == ModeRules.WAVE:
		_setup_arena_hud()   # spec §12.20: the arena's clock and result panel instead
		return
	_survivor_game.game = Game.survivor_game
	if not _survivor_game.time_of_day.is_valid():
		_survivor_game.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
		_survivor_game.block_at = world.get_block
		_survivor_game.box_reader = world.box_reader
	hud.add_game_clock()
	_survivor_game.setup_local(player, hud.game_clock)
	hud.setup_crafting()

# --- M3 Task 12: levels, the adventure board, badges and the pet's presents ---

var progress_director: ProgressDirector


## This game's player's progress: the Progress autoload counts while the director is in the world.
## Secrets found and photos taken are this game's own events; on the host (and solo) monsters beaten,
## waves and the boss won become events for the players they belong to.
func _setup_progress() -> void:
	progress_director = ProgressDirector.new()
	progress_director.name = "ProgressDirector"
	progress_director.player = player
	progress_director.hud = hud
	progress_director.saves_profile = is_client()   # a LAN guest never saves the world: it saves its profile
	progress_director.pet_near = _pet_near
	add_child(progress_director)
	_secrets.found_shown.connect(func(kind: StringName) -> void:
		Progress.event(StringName("%s/%s" % [LevelRules.SECRET, kind])))
	if photo:
		photo.photo_saved.connect(func(_path: String) -> void: Progress.event(LevelRules.PHOTO))
		# MAKE MY SHORT (spec §5.12b): a small copy for the Shorts' album, on this device (made on a worker thread)
		photo.photo_saved.connect(func(path: String) -> void: MyShortAlbum.keep_photo(photo.last_png(), path))
	if not is_client():
		Session.progress_reset()
		progress_director.watch_host(_monsters, _waves, _boss, Game.mode == ModeRules.WAVE)   # owner #45a: arena waves


## The name of this game's player's pet within PresentRules.PET_NEAR ("" = none there).
func _pet_near() -> String:
	if not is_instance_valid(player):
		return ""
	for a in _animal_nodes():
		if a.owner_peer == player.peer_id and a.global_position.distance_to(player.global_position) <= PresentRules.PET_NEAR:
			return a.pet_name
	return ""

# --- M3 Task 7: smart blocks and Game Blocks ------------------------------------------------------------

var _smart := SmartDirector.new()
var _courses := CourseDirector.new()
var _smart_started := false


## Every peer, before any of their RPCs can arrive: same names, same RPCs.
func _add_smart() -> void:
	_smart.name = "Smart"
	add_child(_smart)
	_courses.name = "Courses"
	add_child(_courses)


## Host and solo: power, teleport pads and courses from the save; every block change can make or break them;
## bot friends race the courses' best runs (the FRIENDS page's RACE ME!).
func _start_smart() -> void:
	_smart.block_at = world.get_block
	_smart.area_ready = world.is_editable
	_smart.start(meta.smart)
	world.block_changed.connect(_smart.note_block)
	_courses.name_of = _player_name
	_courses.start(meta.smart)
	if _bot_director:
		_bot_director.race_with = _courses.race_bot
	_smart_started = true


## Every peer, once this game's player exists: its feet on Game Blocks and teleport pads, the race clock.
func _setup_smart_local() -> void:
	_courses.setup_local(player)
	hud.setup_races(_courses)
	pause_menu.opened.connect(hud.course_panel.close)


func _smart_save() -> Dictionary:
	if not _smart_started:
		return meta.smart
	var d := _smart.to_save()
	d.courses = _courses.to_save()
	return d

# --- M4 H: co-op games (hide-and-seek, Storm Run, the team photo after a boss) --------------------------

var games := GamesDirector.new()


## Every peer, before any round's state can arrive: same name, same RPCs.
func _add_games() -> void:
	games.name = "Games"
	add_child(games)


## Host and solo: who plays (the bot friends), what keeps a round from starting (a wave, the boss), the
## monsters kept away and the Totem waiting while one is on, Storm Run's best, the photo after a boss.
func _start_games() -> void:
	games.world = world
	games.bot_list = func() -> Array: return _bot_director.bots() if is_instance_valid(_bot_director) else []
	games.busy = func() -> StringName:
		if _boss.fighting():
			return GameRules.BOSS
		return GameRules.WAVE if _waves.busy() else &""
	games.monsters_away = _monsters.puff_all
	games.storm_best = meta.storm_best
	games.save_best = func(best: int) -> void:
		meta.storm_best = best
		save_world()
	_monsters.enabled = games.monsters_allowed(_monsters.enabled)
	_waves.game_on = games.running
	_boss.fight_ended.connect(func(won: bool, _percent: int) -> void:
		if won:
			games.offer_photo())


## Every peer, once this game's player and HUD exist: the round's line and TEAM PHOTO on the HUD, the
## seeker's counting screen under the HUD's buttons, the team photo through photo mode, and the ring's and
## stars' shaders compiled as the world appears.
func _setup_games_hud() -> void:
	games.world = world
	games.local_player = player
	games.fov = player.camera().fov
	games.take_photo = func(view: Transform3D) -> void:
		if is_instance_valid(photo):
			photo.take_team_photo(view)
	hud.setup_games(games)
	var overlay := GameOverlay.new()
	overlay.name = "GameOverlay"
	overlay.director = games
	_layer.add_child(overlay)
	_layer.move_child(overlay, hud.get_index())
	ShaderWarmup.at_spawn(player.spawned, func() -> void: GameRing.prewarm(player.camera()))

# --- M4 I: gifts and visits (M4 Wave 3, agent I; spec §17.5) ---
# SHARE in the MORE panel (a present for a friend or my showcase, from this world: the host's or a solo
# game, signed in with friends allowed), friends' bottles floating up near this player (BottleShore,
# this game only) and buddy playdates (PlaydateDirector, every peer; the host decides).

var _playdates := PlaydateDirector.new()
var share_panel: SharePanel
var share_button := TouchButton.new()
var bottle_card: BottleCard
var bottles: BottleShore
var build_outline: BuildOutline


func _add_playdates() -> void:
	_playdates.name = "Playdates"
	_playdates.buddies_root = _buddies
	add_child(_playdates)


func playdates() -> PlaydateDirector:
	return _playdates


func _i_setup_local() -> void:
	var service := Session.online_service_or_null()
	build_outline = BuildOutline.new()
	build_outline.name = "BuildOutline"
	add_child(build_outline)
	share_panel = SharePanel.new()
	share_panel.name = "SharePanel"
	share_panel.service = service
	share_panel.interactor = _interactor
	share_panel.world = world
	share_panel.player = player
	share_panel.outline = build_outline
	share_panel.player_toast = hud.toast
	share_panel.own_buddies = _i_own_buddies
	_layer.add_child(share_panel)
	_layer.move_child(share_panel, pause_menu.get_index())
	hud.look_area.blockers.append_array(share_panel.blockers())
	share_button.name = "Share"
	share_button.text = "SHARE"
	share_button.symbol = &"gift"
	hud.more.add(share_button, true)
	share_button.pressed.connect(share_panel.open)
	bottle_card = BottleCard.new()
	bottle_card.name = "BottleCard"
	bottle_card.service = service
	_layer.add_child(bottle_card)
	_layer.move_child(bottle_card, pause_menu.get_index())
	hud.look_area.blockers.append_array(bottle_card.blockers())
	bottles = BottleShore.new()
	bottles.name = "Bottles"
	bottles.world = world
	bottles.player = player
	bottles.service = service
	add_child(bottles)
	bottles.opened.connect(bottle_card.show_result)
	_i_update_share()
	if service:
		service.status_changed.connect(_i_on_online_status)
		service.account_changed.connect(_i_update_share)
		player.spawned.connect(_i_bring_bottles, CONNECT_ONE_SHOT)


## SHARE shows only where it works: this child's own world (host or solo), signed in, friends allowed.
func _i_update_share() -> void:
	var service := Session.online_service_or_null()
	share_button.visible = SharePanel.offered(service, is_client())
	if not share_button.visible and share_panel and share_panel.is_open():
		share_panel.close()


func _i_on_online_status(_status: StringName) -> void:
	_i_update_share()
	_i_bring_bottles()


func _i_bring_bottles() -> void:
	var service := Session.online_service_or_null()
	if service and service.social_allowed() and player and player.is_spawned():
		bottles.start()


## This player's buddies ([{"blocks", "pos"}]): one of them may wait in the showcase.
func _i_own_buddies() -> Array:
	var out: Array = []
	for b in _buddy_nodes():
		if b.owner_peer == player.peer_id:
			out.append({"blocks": b.blocks, "pos": b.global_position})
	return out

# --- M3 Task 4: the Candy Kingdom (chocolate water, sprinkles at night) -----------------------------------------
# The kingdom's descriptor brings the rest through the M3 Task 2 section (monsters, the Cake Monster, secrets and
# their words). Here: its water looks like chocolate (BlockLibrary.set_liquid; every world sets it, so the next
# world's water is water again), the view under it is brown (Ambience.chocolate), and sprinkles fall at night
# round this game's player (CandySprinkles). The host's MonsterDirector measures light for the candy sneaker
# (StealthDirector.light_at, set in _start_universe_host).

var _sprinkles: CandySprinkles


## Host: the light where a candy sneaker stands (StealthDirector.light_at), its lanterns from the lantern index
## (DefenseDirector: chunks copied once, not a box per look; DEVELOPMENT.md §8).
func _sneaker_light(feet: Vector3) -> float:
	var head := feet + Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	var lamps := _defenses.lanterns_near(head, float(StealthRules.LIGHT_RADIUS), [1])
	return _stealth.light_at(feet, 0 if lamps.is_empty() else 1)


## Every peer, every world (with the sky): how the water looks.
func _apply_liquid() -> void:
	var own: Object = world.descriptor() if world else null
	var liquid: Variant = own.get("liquid") if own != null else null
	BlockLibrary.set_liquid(StringName(liquid) if liquid is StringName or liquid is String else &"")


## Every peer, once this game's player exists: the chocolate view and the sprinkles.
func _candy_local() -> void:
	_meadow_local()   # owner #94: before the descriptor's early return (Green Meadows, universe 1, has none)
	var own: Object = world.descriptor()
	if own == null:
		return
	var amb := get_node_or_null("Ambience") as Ambience
	if amb:
		amb.chocolate = own.get("liquid") == &"chocolate"
		amb.methane = TitanRules.floaty(own.get("liquid"))   # cosmos: Titan's lakes are liquid methane
	if own.get("weather") == &"sprinkles":
		_sprinkles = CandySprinkles.new()
		_sprinkles.name = "Sprinkles"
		_sprinkles.player = player
		_sprinkles.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
		_sprinkles.underground = func() -> float: return amb.underground if is_instance_valid(amb) else 0.0
		add_child(_sprinkles)
	_colony_insects(amb)   # spec §21c: bees and butterflies under the Great Dome


## Every peer: bees and butterflies (owner #41) and the meadow's ambient life (owner #94: fireflies at night, birds by
## day) round this game's player where its universe has "insects" (Green Meadows). Owner #94 found them missing:
## WorldService.descriptor() is null for universe 1 (it only names the other universes), so they read the registry.
func _meadow_local() -> void:
	var own: Object = UniverseRegistry.descriptor(world.universe)
	if own == null or own.get("insects") != true or Game.mode == ModeRules.WAVE:
		return
	var amb := get_node_or_null("Ambience") as Ambience
	var bugs := MeadowInsects.new()
	bugs.name = "Insects"
	bugs.player = player
	bugs.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
	bugs.underground = func() -> float: return amb.underground if is_instance_valid(amb) else 0.0
	bugs.ground = func() -> int:
		return world.get_block(FrostRules.floor_cell(player.global_position)) if is_instance_valid(player) else BlockIds.AIR
	add_child(bugs)
	_add_ambient_life(amb)

# --- Monster Wave (owner feedback #44, spec §12.20) ---------------------------------------------------------

var _arena := ArenaDirector.new()


## Every peer, before the host's state can arrive: same name, same RPCs.
func _add_arena() -> void:
	_arena.name = "Arena"
	add_child(_arena)


## Host and solo, an arena world (new or saved): everyone's kit, the Totem in the middle, the start spot and
## bright day; every run starts from there.
func _prepare_arena() -> void:
	meta.inventories[_home_key()] = ArenaRules.kit(Game.universe).to_save()
	meta.hotbar = ArenaRules.kit_hotbar(Game.universe)
	meta.selected_slot = 0
	var c := ArenaShape.totem_cell()
	meta.totem_pos = Vector3(c.x + 0.5, ArenaShape.FLOOR, c.y + 0.5)
	meta.totem_yaw = 0.0
	meta.time_of_day = DayCycle.NOON
	meta.player_pos = Vector3.INF
	meta.physics_mode = PhysicsMode.Mode.NORMAL


## Host and solo: the run begins (after the waves, the boss and the monsters are set up).
func _start_arena() -> void:
	_arena.waves = _waves
	_arena.boss = _boss
	_arena.monsters = _monsters
	_arena.universe = Game.universe
	_arena.totem_pos = meta.totem_pos
	_arena.name_of = _player_name
	_arena.bests = meta.arena
	_arena.travel = travel_to_arena
	Session.client_ready.connect(func(id: int) -> void: Session.set_inventory(id, ArenaRules.kit(Game.universe)))
	_arena.start()


## Every peer: the arena's clock (where Build to Survive's clock sits) and its result panel; the kit's hotbar;
## no WALK/FLY button (no flying in the arena).
func _setup_arena_hud() -> void:
	hud.add_game_clock()
	_arena.setup_local(hud.game_clock)
	hud.add_arena_panel()
	_arena.result_shown.connect(hud.arena_panel.show_result)
	hud.arena_panel.again_pressed.connect(_arena.request_again)
	hud.arena_panel.next_pressed.connect(_arena.request_next)
	hud.arena_panel.leave_pressed.connect(_save_and_quit)
	hud.physics_button.visible = false
	if is_client():
		_interactor.hotbar = ArenaRules.kit_hotbar(Game.universe)
		_interactor.select_slot(0)


## Host, solo: NEXT UNIVERSE after the raid boss: saves this arena and opens universe u's (made the first time).
## Returns why not ("" = on the way).
func travel_to_arena(u: int) -> String:
	if _quitting or is_client() or not multiplayer.get_peers().is_empty():
		return UniverseRules.travel_message("friends")
	_travel_to_arena.call_deferred(u)
	return ""


func _travel_to_arena(u: int) -> void:
	if _quitting:
		return
	_quitting = true
	save_world()
	await world.save_and_wait()
	Session.close()
	Game.start_world(ModeRules.WAVE, not WorldSaves.exists(ModeRules.slot(ModeRules.WAVE, u)), DifficultyRules.NORMAL, u)

# --- M3 Task 14b: blasters, surprise drops and goblin archers ---------------------------------------------

var _blasters := BlasterDirector.new()
var _drops := DropDirector.new()


## Every peer, before any shot or drop can come: same names, same spawner and RPCs.
func _add_action_kit() -> void:
	_blasters.name = "Blasters"
	add_child(_blasters)
	_monsters.shoot_arrow = _blasters.monster_arrow   # goblin archers (host)
	_drops.name = "Drops"
	add_child(_drops)


## Host and solo: the piñata clock (saved with the world) and the supply balloons of Survivor waves.
func _start_action_kit_host() -> void:
	_drops.world_seed = meta.seed
	_drops.universe = UniverseRules.scale_universe(Game.mode, Game.universe)   # owner 39: Sandbox never scales
	_drops.survivor = Game.mode == ModeRules.SURVIVOR
	_drops.stand_spot = _monsters.stand_spot
	_drops.is_ready = world.is_area_ready
	_drops.wave_now = func() -> int: return _waves.wave if _waves.phase == WaveDirector.Phase.RUNNING else 0
	_drops.totem_pos = _waves.totem_position
	_drops.restore(meta.drops)
	_drops.start()


## The surprise drops (tests and tools).
func drops() -> DropDirector:
	return _drops


## This game: the bubble's and the paint mark's shaders compile as the world appears.
func _setup_action_kit_local() -> void:
	ShaderWarmup.at_spawn(player.spawned, func() -> void: _blasters.prewarm(player.camera()))


## The blaster shots (tests and tools).
func blasters() -> BlasterDirector:
	return _blasters

# --- M3 Task 14a: gadgets and ziplines ------------------------------------------------------------------------

var _gadgets := GadgetDirector.new()
var _ziplines := ZiplineDirector.new()
var _gadgets_started := false


## Every peer, before any of their RPCs can arrive: same names, same RPCs.
func _add_gadgets() -> void:
	_gadgets.name = "Gadgets"
	add_child(_gadgets)
	_ziplines.name = "Ziplines"
	add_child(_ziplines)


## Host and solo: the saved zipline links; every block change can add or break a post; who placed a post is
## the player nearest to it; a guest who joins is sent the lines.
func _start_gadgets() -> void:
	_gadgets.block_at = world.get_block
	_ziplines.block_at = world.get_block
	_ziplines.owner_near = _post_owner
	_ziplines.start(meta.ziplines)
	world.block_changed.connect(_ziplines.note_block)
	Session.client_ready.connect(_ziplines.send_to)
	_gadgets_started = true


func _post_owner(post: Vector3i) -> String:
	var best := ""
	var best_d := INF
	for p in Monster.players_now(get_tree()):
		var d := p.global_position.distance_to(Vector3(post) + Vector3(0.5, 0.5, 0.5))
		if d < best_d:
			best_d = d
			best = _player_name(p.peer_id)
	return best


## The gadgets and ziplines (tests and tools).
func gadgets() -> GadgetDirector:
	return _gadgets


func ziplines() -> ZiplineDirector:
	return _ziplines
# --- M3 Task 11: pets with perks ---------------------------------------------------------------------------
# PetDirector (node "Pets", every game): the host decides treats, pats, names, collars, the perks (the dog's bark
# and coins, the parrot's pointing; the fox and the dog sniff for treasure themselves) and brings each child's
# Pip (he lives in the profile); every game shows its own player's pet card (a tap on your own pet), one shared
# glow on the nearest glowing pet in the dark, and the parrot repeating this player's own words.

var pets := PetDirector.new()
var pet_panel: PetPanel


func _add_pets() -> void:
	pets.name = "Pets"
	pets.animals = _animals
	add_child(pets)


## Host and solo: the monsters' coins, the secrets nobody found, Survivor's treats from the bag, Pip's spawns.
func _start_pets() -> void:
	pets.coins = func() -> Array: return _monsters.coins()
	pets.secrets_near = _unfound_secrets
	pets.take_treat = func(peer: int, item: int) -> bool:
		return Game.allows(ModeRules.UNLIMITED_BLOCKS) or Session.inventory_of(peer).take(item, 1)
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):   # owner #41: a donkey's chest moves things from and to the bag
		pets.bag_count = func(peer: int, id: int) -> int: return Session.inventory_of(peer).count(id)
		pets.take_items = func(peer: int, id: int, n: int) -> bool: return Session.inventory_of(peer).take(id, n)
		pets.give_items = func(peer: int, id: int, n: int) -> int: return Session.inventory_of(peer).add(id, n)
	pets.spawn = func(data: Dictionary) -> Animal: return _animal_spawner.spawn(data) as Animal
	pets.start_host()


## Host: where the secrets nobody found yet are within `radius` of `pos` (the parrot points at the nearest).
func _unfound_secrets(pos: Vector3, radius: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if _secrets.rules == null:
		return out
	for s: Dictionary in _secrets.rules.secrets_near(pos, radius):
		if not _secrets.state.found.has(s.id) and not _secrets.state.opened.has(s.id):
			out.append(Vector3(s.anchor) + Vector3(0.5, 0.5, 0.5))
	return out


## Every game, once its player exists: the card (a tap on your own pet), the glow, the parrot, Pip coming along.
func _setup_pets_local() -> void:
	pets.local_player = player
	pets.underground = func() -> float:
		var amb := get_node_or_null("Ambience") as Ambience
		return amb.underground if amb else 0.0
	pets.is_night = func() -> bool: return DayCycle.is_night(sky.time) if sky else false
	hud.chat.own_line_sent.connect(pets.hear_own)
	pet_panel = PetPanel.new()
	pet_panel.name = "PetPanel"
	pet_panel.band = Profile.data.age_band
	pet_panel.held_item = func() -> int: return _interactor.selected_block()   # owner #41: a donkey's PUT IN
	pet_panel.player_position = func() -> Vector3:
		return Player.position_or_none(player)
	_layer.add_child(pet_panel)
	_layer.move_child(pet_panel, pause_menu.get_index())
	hud.look_area.blockers.append_array(pet_panel.blockers())
	pause_menu.opened.connect(pet_panel.close)
	_interactor.pet_tapped.connect(pet_panel.open)
	player.spawned.connect(pets.bring_pip, CONNECT_ONE_SHOT)
	player.spawned.connect(pets.bring_baby_dragon, CONNECT_ONE_SHOT)   # owner 39: the Sky Dragon's baby dragon


## M3 Task 15's tutorial (after PetRules.give_pip) and anything else that gives Pip now: he comes at once.
func bring_pip() -> void:
	pets.bring_pip()


## Chat /summon pip (Sandbox, host): the asking child's own Pip comes; without one, a visiting Pip for this
## game (only the tutorial gives Pip for keeps, PetRules.give_pip).
func _summon_pip(near: Vector3) -> String:
	var asker: Player = null
	for p in _players.get_children():
		if p is Player and (p as Player).is_spawned() and (asker == null
				or (p as Player).global_position.distance_to(near) < asker.global_position.distance_to(near)):
			asker = p
	if asker == null:
		return ""
	if pets.pip_of(asker.peer_id) != null:
		return "Pip is already here!"
	var record: Dictionary = Profile.data.pip if asker == player and not Profile.data.pip.is_empty() \
		else PetRules.pip_record(PetRules.PIP_NAME, PetRules.OWNER_COLOUR, PetRules.HAPPY_START)
	pets.on_pip(asker.peer_id, record)
	return ""

# --- M3 Task 20a: rideable buddies ---------------------------------------------------------------------------

## Node "Rides" on every peer: the RIDE button here, every ride decided by the host (RideDirector).
var _rides := RideDirector.new()


func _add_rides() -> void:
	_rides.name = "Rides"
	_rides.buddies_root = _buddies
	_rides.animals_root = _animals   # owner #41: saddled horses and camels
	add_child(_rides)

# --- Owner #109: cars to drive ------------------------------------------------------------------------------

## Node "Vehicles" on every peer: the cars, the garage (MORE → CARS), every seat and move decided by the host
## (VehicleDirector); the RIDE button gets into a car too.
var vehicles := VehicleDirector.new()


func _add_vehicles() -> void:
	vehicles.name = "Vehicles"
	add_child(vehicles)
	_rides.cars = vehicles

# --- Owner #110 (VR round 4): the music blocks ------------------------------------------------------------------

## Node "Music" on every peer: the xylophone and the bongos played by taps, LOOP and, in VR, mallets; friends' notes
## through the host (MusicDirector).
var music := MusicDirector.new()


func _add_music() -> void:
	music.name = "Music"
	add_child(music)

# --- M3 Task 10: the Gold Farm ------------------------------------------------------------------------------

var _farm := FarmDirector.new()


## Every peer, before the host's farm can arrive: same name, same RPCs.
func _add_farm() -> void:
	_farm.name = "Farm"
	add_child(_farm)


## Host and solo: the world's farm (its owner is this game's player), the requests to place and upgrade it,
## a guest who joins hears it, and once the player stands in the world, the welcome-back.
func _start_farm() -> void:
	_farm.universe = Game.universe
	_farm.slot = _slot
	_farm.mode = Game.mode
	_farm.save_now = save_world
	_farm.save_meta = func() -> void:
		meta.farm = _farm.farm.duplicate(true)
		WorldSaves.save_meta(_slot, meta)
	_farm.changed.connect(func(f: Dictionary) -> void: meta.farm = f.duplicate(true))
	Session.farm_place_requested.connect(_farm.host_place)
	Session.farm_upgrade_requested.connect(_farm.host_upgrade)
	Session.farm_move_requested.connect(_farm.host_move)
	Session.client_ready.connect(_farm.send_to)
	_farm.start(meta.farm)
	if FarmRules.wants_farm(Game.mode):
		player.spawned.connect(func() -> void:
			get_tree().create_timer(1.0).timeout.connect(_farm.welcome_back), CONNECT_ONE_SHOT)


## Every game with a local player: its workers wake near this player; in Survivor the barn's panel and the
## welcome-back's banner and coin shower.
func _setup_farm_local() -> void:
	_farm.local_feet = func() -> Vector3:
		return Player.position_or_none(player)
	if FarmRules.wants_farm(Game.mode):
		hud.add_farm_controls(_farm)
		_farm.welcomed.connect(func(gold: int, _capped: bool) -> void: hud.farm_welcome(gold))

# --- Owner #45a: quests (quest givers, picture-story chains, the quest book; spec §14.17) ---------------------

var _quests := QuestDirector.new()


## Every peer, with the other directors: same name, same RPCs (the shared story in co-op).
func _add_quests() -> void:
	_quests.name = "Quests"
	add_child(_quests)


func quests() -> QuestDirector:
	return _quests


## Every game with a local player: this universe's giver by the spawn (placed from the seed on every game),
## QUESTS in MORE, the book, the giver's card and the arrow; the host hears guests come and go.
func _setup_quests() -> void:
	_quests.mode = Game.mode
	_quests.universe = Game.universe
	var shape := world.generator_shape()
	_quests.world_seed = shape.seed
	_quests.secrets = _secrets
	_quests.saves_profile = is_client()   # a LAN guest's world is never saved: its profile is
	_quests.setup_local(player, hud, _layer, _interactor)
	for c: Control in [_quests.book, _quests.card]:
		if c:
			_layer.move_child(c, pause_menu.get_index())   # over the HUD, under the pause menu
	pause_menu.opened.connect(_quests.close_pages)
	_quests.place_givers(shape, world.spawn_column())
	if not is_client():
		Session.client_ready.connect(_quests.on_client_ready)
		Session.peer_left.connect(_quests.on_peer_left)


# --- M3 Task 8: building tools (paint, LINE, FILL, COPY, Build Rewind, Build-and-Wear) ------------------------------
# The tools live in the local player's BlockInteractor (BuildToolUser); the host checks their edits (Session section
# "M3 Task 8"). Here, this game's screens: the tools' bar (top centre, only with LINE, FILL or COPY in the hand),
# Build Rewind's time-lapse (RewindView; the recording is saved with the world, host and solo) and Build-and-Wear's
# card (the wand on a small build). All three sit under the pause menu, and their taps never build.

var build_bar: BuildToolBar
var rewind_view: RewindView
var wear_card: WearCard


func _t8_setup_local() -> void:
	var tools := _interactor.tools
	tools.outline = build_outline   # M4 I's glow: the first corner, the box or line being chosen
	tools.said.connect(hud.toast)
	if meta and not is_client():
		tools.rewind = RewindLog.from_save(meta.rewind)   # a guest's recording stays in its memory
	build_bar = BuildToolBar.new()
	build_bar.name = "BuildToolBar"
	_layer.add_child(build_bar)
	_layer.move_child(build_bar, pause_menu.get_index())
	build_bar.setup(tools)
	hud.look_area.blockers.append_array(build_bar.blockers())
	rewind_view = RewindView.new()
	rewind_view.name = "RewindView"
	rewind_view.hud = hud
	_layer.add_child(rewind_view)
	_layer.move_child(rewind_view, pause_menu.get_index())
	hud.look_area.blockers.append_array(rewind_view.blockers())
	rewind_view.restart_requested.connect(tools.restart_rewind)
	tools.rewind_requested.connect(func() -> void:
		if not rewind_view.open(tools.rewind):
			hud.toast(RewindView.NOTHING_YET))
	wear_card = WearCard.new()
	wear_card.name = "WearCard"
	_layer.add_child(wear_card)
	_layer.move_child(wear_card, pause_menu.get_index())
	hud.look_area.blockers.append_array(wear_card.blockers())
	tools.wear_enabled = true
	tools.wear_requested.connect(func(picked: Dictionary, cell: Vector3i) -> void:
		build_outline.show_blocks(picked.get("blocks", {}))
		wear_card.show_for(picked, cell))
	wear_card.chosen.connect(_t8_wear_chosen)


## WAKE UP sparks the build as the wand always did; HAT, BACKPACK or WINGS wear a copy of it (saved in the profile,
## sent to other players with the look).
func _t8_wear_chosen(choice: StringName) -> void:
	build_outline.clear()
	if choice == &"wake":
		Session.request_spark(wear_card.cell)
		return
	if not WearRules.is_slot(choice) or not is_instance_valid(player):
		return
	var words := BuildToolUser.wear(Profile.data, wear_card.picked, choice, Blueprints.facing_for_yaw(player.rig.yaw))
	Profile.save()
	Profile.avatar_changed.emit()   # this game's player wears it; its look code goes to everyone
	hud.toast(words)
	Audio.play(&"chime")


# --- Owner feedback #39: universe portals you build (spec §14.2a) ------------------------------------------------
# A portal frame with a universe crystal's core in its core slot (PortalDirector's gates) travels, solo: Survivor to
# that universe's Survivor world (the bag comes along, _travel), Sandbox to that universe's own Sandbox world
# (`sandbox_<u>`, made the first time). The traveller arrives in front of the destination's portal back to where
# they came from (WorldMeta.arrival_gate): the world's own one, else one built a few steps in front of them
# (ReturnGate). The universes a profile reached give their crystals once, into the bag of the child's own Survivor
# world (CrystalRules.owed).

const CRYSTAL_WORDS := "You got the %s! Put it in a portal frame's bottom row."


## Host and solo: the world's universe portals; walking into one travels (solo) through travel_through_gate.
func _start_gates() -> void:
	_portal_frames.here = Game.universe
	_portal_frames.travel = travel_through_gate
	_portal_frames.start_gates(meta.gates)


## A walk into a universe portal to u: travels there (solo), or says why not ("" = on the way).
func travel_through_gate(u: int) -> String:
	if _quitting:
		return ""
	var peers := 1 if is_client() else multiplayer.get_peers().size()
	var why := UniverseRules.travel_refusal(u, Profile.data.universe_unlocked, UniverseRegistry.available(), peers,
		Game.universe)
	if why == "" and not ModeRules.allows(Game.mode, ModeRules.BUILDING):
		why = "locked"   # Monster Wave's arenas have no portals to build (never reached)
	if why != "":
		return UniverseRules.travel_message(why)
	var plus := Session.shop_travel_refusal(u)   # Owner 35: a Plus universe is Plus in Sandbox too (a place to explore)
	if plus != "":
		return plus
	if Game.mode == ModeRules.SURVIVOR:
		_travel.call_deferred(u, true)
	else:
		_travel_sandbox.call_deferred(u)
	return ""


## Sandbox: saves this world and opens universe u's Sandbox world (made the first time: its terrain, sky, music and
## gentle monsters; everything free); the hotbar comes along; arrival at its portal back.
func _travel_sandbox(u: int) -> void:
	if _quitting:
		return
	_quitting = true
	var slot := ModeRules.slot(ModeRules.SANDBOX, u)
	var arrival := UniverseRules.sandbox_arrival_meta(WorldSaves.load_meta(slot) if WorldSaves.exists(slot) else null, u,
		Game.universe)
	arrival.hotbar = _interactor.hotbar.duplicate()
	arrival.selected_slot = _interactor.selected_slot
	WorldSaves.save_meta(slot, arrival)
	save_world()
	Audio.play(&"portal_whoosh")
	await world.save_and_wait()
	print("UNIVERSE sandbox travel %d -> %d" % [Game.universe, u])
	var kept: bool = await _close_or_move(u, true)   # spec §21d.6: HOME with a crew brings it along
	Game.start_world(ModeRules.SANDBOX, false, DifficultyRules.NORMAL, u)
	if kept:
		Game.net_mode = &"host"


## Host and solo, before the player spawns: after a trip through a universe portal, arrive in front of this world's
## own portal back when it has one; else one is built in front of the child once they stand here (_build_gate_back).
func _arrive_through_gate() -> void:
	if meta.arrival_gate <= 0:
		return
	var at := ReturnGate.arrival(PortalGates.from_save(meta.gates), meta.arrival_gate)
	if not at.is_empty():
		meta.player_pos = at.pos
		meta.player_yaw = float(at.yaw)
		meta.arrival_gate = 0
		return
	var from := meta.arrival_gate
	player.spawned.connect(func() -> void: _build_gate_back(from), CONNECT_ONE_SHOT)


## Host: a portal to universe `from` a few steps in front of the child (ReturnGate), built block by block by the
## host (no undo step, nothing paid); the PortalDirector finds it like any portal a child builds.
func _build_gate_back(from: int) -> void:
	meta.arrival_gate = 0
	if not is_instance_valid(player) or not player.is_spawned():
		return
	var plan := ReturnGate.plan(player.global_position, player.rig.yaw, from, world.get_block)
	for e: Array in plan.get("edits", []):
		world.set_block(e[0], e[1])
	print("UNIVERSE gate back to %d at %s" % [from, plan.get("core", Vector3i.ZERO)])


## Host and solo, in the child's own Survivor world: the crystals of the universes they reached (and gifts) go into
## their bag once (CrystalRules.owed), each said once.
func _hand_over_crystals() -> void:
	if Game.mode != ModeRules.SURVIVOR or is_client() or not is_instance_valid(player):
		return
	var owed := CrystalRules.owed(Profile.data.universe_unlocked, Profile.data.crystals_given, Profile.data.crystal_gifts)
	if owed.is_empty():
		return
	var inv := Session.inventory_of(player.peer_id)
	var names: Array[String] = []
	for u in owed:
		inv.add(CrystalRules.crystal_of(u), 1)
		names.append(ItemIds.display_name(CrystalRules.crystal_of(u)))
	Profile.data.crystals_given = CrystalRules.given_after(Profile.data.universe_unlocked, Profile.data.crystals_given)
	Profile.data.crystal_gifts.clear()
	Profile.save()
	if is_instance_valid(hud):
		hud.toast(tr(CRYSTAL_WORDS) % (names[0] if names.size() == 1 else tr("%d universe crystals") % names.size()), 5.0)

# --- Owner feedback #39: dragon eggs --------------------------------------------------------------------------------
# DragonNests (node "DragonNests", every game): the host hatches a tapped egg into the tapper's pet dragon; the
# SecretDirector brings the eggs (DragonEgg secret things) of nests whose egg has not hatched.

var nests := DragonNests.new()


func _add_nests() -> void:
	nests.name = "DragonNests"
	add_child(nests)


## Host and solo: taps on eggs hatch them.
func _start_nests() -> void:
	nests.state = _secrets.state
	nests.eggs = func(egg_name: String) -> DragonEgg: return _secrets.thing(egg_name) as DragonEgg
	nests.spawn = func(data: Dictionary) -> Animal: return _animal_spawner.spawn(data) as Animal
	Session.egg_hatch_requested.connect(nests.hatch)
	tree_exiting.connect(func() -> void:
		if Session.egg_hatch_requested.is_connected(nests.hatch):
			Session.egg_hatch_requested.disconnect(nests.hatch))

# --- Owner 39: the Dragon Realm ---
# The realm's descriptor brings its terrain, secrets (dragon nests), monsters and boss through the M3 Task 2 section.
# Here: its void. Every game's own player carries itself back (Player.carry_back); this game says so with kind words
# and a sparkle where it lands. The host's VoidWatch puffs monsters that fall into the void away and brings animals,
# pets, bot friends and buddies back next to their child (or the world spawn). Monster Wave's arena has no void.

var void_watch: VoidWatch


## Host and solo, a world over the void (not the arena: _start_universe_host is never called there).
func _start_dragon_host() -> void:
	if not DragonRules.world_has_void(world.descriptor(), world.generator_shape() is ArenaShape):
		return
	void_watch = VoidWatch.new()
	void_watch.name = "VoidWatch"
	void_watch.line = DragonRules.rescue_y(world.descriptor())   # cosmos: Venus's line far over its clouds
	void_watch.monsters = func() -> Array: return _monsters.monsters()
	void_watch.puff = func(m: Node3D) -> void: _monsters.puff(m as Monster)
	void_watch.friends = func() -> Array:
		var out: Array = []
		out.append_array(_animal_nodes())
		out.append_array(_buddy_nodes())
		for b in _bots.get_children():
			if b is BotFriend and not b.is_queued_for_deletion():
				out.append(b)
		return out
	void_watch.child_of = _void_child_feet
	void_watch.spawn_feet = func() -> Vector3:
		var c := world.spawn_column()
		return Vector3(c.x + 0.5, world.surface_height(c.x, c.y), c.y + 0.5)
	add_child(void_watch)


## The feet of a fallen friend's child while that child stands safely (on solid ground, above the void), else INF:
## a pet's or a buddy's owner, a bot friend's leader; a wild animal has none.
func _void_child_feet(body: Node3D) -> Vector3:
	var peer := 0
	if body is Animal:
		peer = (body as Animal).owner_peer
	elif body is Buddy:
		peer = (body as Buddy).owner_peer
	elif body is BotFriend:
		peer = (body as BotFriend).leader_peer
	var child := _players.get_node_or_null(str(peer)) as Player if peer > 0 else null
	if child == null or not child.is_spawned():
		return Vector3.INF
	var feet := child.global_position
	var under := world.get_block(Vector3i((feet + Vector3(0, -0.05, 0)).floor()))
	return feet if DragonRules.is_safe_spot(true, under, feet, DragonRules.rescue_y(world.descriptor())) else Vector3.INF


## Every game with a local player in a void world: "Whoosh! The wind carried you back." and a sparkle where it lands.
func _dragon_local() -> void:
	if not player.in_void_world():
		return
	player.carried_back.connect(func(_to: Vector3) -> void:
		if is_instance_valid(hud):
			hud.toast(DragonRules.carried_back_words(world.descriptor()), 3.0)   # cosmos: Venus's warm breeze
		player.spawned.connect(func() -> void:
			Fx.burst(get_tree().root, player.global_position + Vector3(0, 0.6, 0), Color("d9c8ff"), 18, 3.0)
			Audio.play(&"sparkle", player.global_position, -4.0), CONNECT_ONE_SHOT))


# --- Owner 45b: a bigger world ------------------------------------------------------------------------------
# The wild meadows' places (villages, windmills, towers, lighthouses, ships, castles, towns): the PlacesDirector (node
# "Places" on every game) finds them near players (the host decides and saves them in WorldMeta.places_found) and
# stands villagers in the villages near players; the world map (MORE → MAP) shows the found ones and points the /find
# arrow at one. Worlds without places (the old meadows, the other universes, Monster Wave's arena) show no MAP.

var places_director: PlacesDirector
var world_map: WorldMapPanel
var map_button: TouchButton


func _add_places() -> void:
	places_director = PlacesDirector.new()
	places_director.name = "Places"
	add_child(places_director)


## After the secrets: the host with the world's saved finds, a guest asking the host for them.
func _start_places(host: bool) -> void:
	if Game.mode == ModeRules.WAVE or _secrets.rules == null:
		return
	places_director.trades = TraderRules.wants_trader(Game.mode)   # Survivor: villagers trade with Tilly's rules
	var gen: Object = world.terrain().generator
	if gen is EditedGenerator:
		gen = (gen as EditedGenerator).base
	var shared: MeadowsPlaces = (gen as MeadowsBiomeGenerator).places if gen is MeadowsBiomeGenerator else null
	if shared != null and _secrets.rules.tiny != null:
		_secrets.rules.tiny.share_places(shared)   # M3 Task 21c: the mouse villages keep off the same places
	if host:
		places_director.setup_host(world.generator_shape(), _secrets.rules, meta.places_found, shared)
	else:
		places_director.setup_client(world.generator_shape(), _secrets.rules, shared)
	_update_map_button()   # a guest's HUD may be up before the world


func _setup_places_local() -> void:
	places_director.toast = hud.toast
	world_map = WorldMapPanel.new()
	world_map.name = "WorldMap"
	world_map.entries_source = places_director.found_places
	world_map.player_position = func() -> Vector3:
		return Player.position_or_none(player)
	world_map.player_yaw = func() -> float: return player.rig.yaw if is_instance_valid(player) else 0.0
	world_map.home_position = func() -> Vector3:
		var sp := world.spawn_column()
		return Vector3(sp.x + 0.5, world.surface_height(sp.x, sp.y), sp.y + 0.5)
	world_map.point_to = func(label: String, pos: Vector3) -> void:
		var runner := get_node_or_null("ChatCommands")
		if runner and runner.has_method(&"point_at"):
			runner.call(&"point_at", label, pos)
			hud.toast(tr("Follow the arrow to %s!") % label, 3.0)
	_layer.add_child(world_map)
	_layer.move_child(world_map, pause_menu.get_index())
	hud.look_area.blockers.append_array(world_map.blockers())
	pause_menu.opened.connect(world_map.close)
	map_button = WorldMapPanel.more_button()
	hud.more.add(map_button, true)
	map_button.pressed.connect(world_map.open)
	places_director.found_changed.connect(_update_map_button)
	_update_map_button()


## MAP shows in a world with places (and when another task marked a place on the map).
func _update_map_button() -> void:
	if map_button:
		map_button.visible = places_director.enabled() or not places_director.marks.is_empty()

# --- M3 Task 21b: books and memories -------------------------------------------------------------------------

var books: BooksDirector


## This game's player's books (after _setup_progress: the Progress bus counts): the Animal Book, the Memory Book,
## Secret Book page rewards; the world owner's trophy shelves and Hub Tree (by the stone circle, Survivor); the
## saving list's bar under the gold; a bookshelf's tap opens the books.
func _setup_books() -> void:
	books = BooksDirector.new()
	books.name = "Books"
	books.center = func() -> Vector3:
		return Player.position_or_none(player)
	books.peer_id = player.peer_id
	books.universe = Game.universe
	books.nights = Game.mode == ModeRules.SURVIVOR
	books.explores = Game.mode != ModeRules.WAVE
	books.is_owner = not is_client()
	books.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
	books.animals = func() -> Array:
		var out: Array = []
		for a in _animal_nodes():
			if is_instance_valid(a) and a.is_inside_tree():
				out.append([a.species, a.global_position])
		return out
	if not is_client():
		books.save_profile = func() -> void: pass   # the host saves the profile with the world (every minute, on pause)
	add_child(books)
	books.said.connect(func(text: String) -> void: hud.toast(text, 3.0))
	books.bannered.connect(func(text: String) -> void: hud.show_banner(text))
	_books_shelves()
	_books_tree()
	photo.photo_saved.connect(func(_path: String) -> void: books.note_photo(photo.last_png()))
	_interactor.animal_fed.connect(books.note_fed)
	_interactor.bookshelf_tapped.connect(func(_cell: Vector3i) -> void: hud.secret_book.open_tab(SecretBook.MEMORIES_TAB))
	_interactor.lab_bench_tapped.connect(func(_cell: Vector3i) -> void: open_lab())   # spec §23: the Science Lab
	hud.setup_books()
	books.start()


# --- Spec §23: the Science Lab ---------------------------------------------------------------------------------

## The Lab over the world (built on the first tap on a lab bench).
var lab_panel: LabPanel


## A tap on a lab bench: the Lab. In Survivor a run's supplies come from this player's bag when this game holds the bag
## (the host: solo play); in a guest's game the bag is the host's, so the bench is free there for now (a ruling:
## docs/devlog/parts/science-lab.md). The Sandbox's bench has endless supplies.
func open_lab() -> void:
	if lab_panel == null:
		lab_panel = LabPanel.new()
		lab_panel.supplies = func(e: Dictionary) -> String:
			if is_client() or player == null:
				return ""
			return LabSupplies.take(Session.inventory_of(player.peer_id), e, Game.allows(ModeRules.UNLIMITED_BLOCKS))
		hud.add_child(lab_panel)
		hud.look_area.blockers.append(lab_panel)   # a tap on the Lab never builds behind it
		PadFocus.watch(lab_panel)   # owner #90
	hud.move_child(lab_panel, -1)   # over every HUD button
	lab_panel.open()


## Trophy shelves near this game's player, from a chunk index of shelf blocks (the host hears every edit; a guest
## looks again every 2 s).
func _books_shelves() -> void:
	var shelves := TrophyShelves.new()
	shelves.center = func() -> Vector3:
		return Player.position_or_none(player)
	shelves.index.chunk_ready = func(c: Vector3i) -> bool: return world != null and world.is_editable(c * BlockIndex.CHUNK)
	shelves.index.scan_chunk = func(c: Vector3i) -> Array[Vector3i]:
		var origin := c * BlockIndex.CHUNK
		var ids: Array[int] = [BlockIds.TROPHY_SHELF]
		return MonsterDirector.find_blocks(world.copy_box(origin, Vector3i.ONE * BlockIndex.CHUNK), origin, ids)
	if is_client():
		shelves.index.cache_seconds = TrophyShelves.CACHE_SECONDS
		shelves.scans_per_look = TrophyShelves.GUEST_SCANS_PER_LOOK
	else:
		world.block_changed.connect(shelves.index.note_block)
	add_child(shelves)
	books.shelves = shelves


## The Hub Tree beside the stone circle (Survivor worlds have the circle), on dry ground the terrain rules pick.
func _books_tree() -> void:
	if universe_hub == null or universe_hub.circle == null:
		return
	var shape := world.generator_shape()
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z)
	var at := HubTreeRules.spot(universe_hub.circle.position, universe_hub.circle.rotation.y, shape.height_at, ground_ok,
		shape.tree_at)
	if not at.is_finite():
		return
	var tree := HubTree.new()
	tree.position = at
	add_child(tree)
	books.tree = tree

# --- M4 ghost races (spec §17.5, research T2) ---
# Friends' ghosts race on this game only (GhostRaces, never over the network): a gift's race waits on the START
# where its stamp was stamped in this child's own world (host or solo; a guest's stamp is in the host's world),
# kept on the device (GhostBook) and linked again when the world opens. SHARE's MY SHOWCASE and GIFT A BUILD take
# the child's own best runs along (SharePanel's section); a new best on a course inside the child's showcase
# replaces its ghost there.

var ghost_races := GhostRaces.new()


func _gh_setup_local() -> void:
	ghost_races.name = "GhostRaces"
	add_child(ghost_races)
	var service := Session.online_service_or_null()
	ghost_races.names_shown = func() -> bool: return service.ghost_names_shown() if service else GhostBook.current().names_ok
	ghost_races.result_noted = func(key: String, ms: int) -> bool:
		if service:
			return service.note_ghost_result(key, ms)
		var best := GhostBook.current().note_result(key, ms, int(Time.get_unix_time_from_system()))
		GhostBook.save_current()
		return best
	ghost_races.start_ok = func(cell: Vector3i) -> bool: return world.get_block(cell) == BlockIds.START
	ghost_races.setup(_courses, player)
	if share_panel:
		share_panel.course_book = func() -> CourseBook: return _courses.book
		share_panel.world_key = gh_world_key()
	_courses.state_changed.connect(_gh_on_run)
	_interactor.stamped.connect(_gh_on_stamped)
	if not is_client():
		for p: Dictionary in GhostBook.current().placed_in(gh_world_key()):
			ghost_races.link(p.start, p.ghost, p.forward, p.key)


## This world on this device: its save slot and seed (a new world in the same slot is another world). A LAN guest has
## no WorldMeta (the host keeps the world): no key, so nothing of its ghosts is kept for a friend's world.
func gh_world_key() -> String:
	return "%s:%d" % [_slot, meta.seed] if meta else ""


## A gift's stamp placed in this child's own world: its sender's race waits on its START.
func _gh_on_stamped(stamp: int, anchor: Vector3i, forward: Vector3i) -> void:
	if is_client() or not ItemIds.is_gift_stamp(stamp):
		return
	var slot := GiftStampBook.slot_of(stamp)
	var book := GhostBook.current()
	var e := book.gift_entry(slot)
	if e.is_empty():
		return
	var g: RaceGhost = e.ghost
	var start := GhostShare.stamped_start(g, GiftStampBook.current().blocks_of(slot), anchor, forward)
	book.place(str(e.key), gh_world_key(), start, forward)
	GhostBook.save_current()
	ghost_races.link(start, g, forward, str(e.key))
	hud.toast(tr("%s came with it! Step on START to race.") % GhostRaceRules.ghost_name(g.owner, bool(ghost_races.names_shown.call())), 4.0)


## A new own best on a course inside the child's showcase: it replaces the ghost there.
func _gh_on_run(s: Dictionary) -> void:
	if str(s.get("event", "")) != "finish" or not bool(s.get("mine_best", false)) or is_client() \
			or not s.get("start") is Vector3i:
		return
	var service := Session.online_service_or_null()
	if service == null or not service.social_allowed():
		return
	var g := GhostShare.replacement(_courses.book, GhostBook.current(), gh_world_key(), s.start, world.get_block,
		Profile.data.avatar.to_code())
	if g == null:
		return
	var err: String = await service.share_ghost(g, gh_world_key(), s.start)
	if err == "" and is_inside_tree():
		hud.toast("Your new best is on your showcase: friends can race it!", 4.0)


# --- M3 Task 20b: buddy magic (secret shapes, the Buddy Album, My Stamps, befriending, mini-buddies, tricks) --------
# BuddyMagicDirector (node "BuddyMagic", every game): the host puts each woken buddy into its child's album (and a
# secret shape into their Secret Book), befriends calm monsters tapped with the wand (as pets: PetDirector's spawn),
# gives everyone there a beaten boss's mini-buddy (BossDirector.boss_won) and teaches buddies and pets the emotes
# their child does near them; every game keeps its own profile's part and brings its minis along. My Stamps: the
# palette's NEW STAMP opens MyStampBar (the next tap on the world picks a build to save).

var buddy_magic := BuddyMagicDirector.new()
var my_stamp_bar: MyStampBar


func _add_buddy_magic() -> void:
	buddy_magic.name = "BuddyMagic"
	buddy_magic.buddies_root = _buddies
	buddy_magic.animals_root = _animals
	add_child(buddy_magic)


## Host and solo: after the pets (their spawn) and the boss.
func _start_buddy_magic() -> void:
	buddy_magic.pets = pets
	buddy_magic.monsters = func() -> Array: return _monsters.monsters()
	buddy_magic.start_host()
	_boss.boss_won.connect(buddy_magic.host_boss_won)


## Every game, once its player exists: its profile's album, secret shapes, minis and tricks; My Stamps' bar.
func _setup_buddy_magic_local() -> void:
	buddy_magic.setup_local(player)
	player.spawned.connect(buddy_magic.bring_minis, CONNECT_ONE_SHOT)
	my_stamp_bar = MyStampBar.new()
	my_stamp_bar.name = "MyStampBar"
	my_stamp_bar.interactor = _interactor
	my_stamp_bar.world = world
	my_stamp_bar.outline = build_outline
	my_stamp_bar.facing = func() -> Vector3i: return Blueprints.facing_for_yaw(player.rig.yaw)
	my_stamp_bar.toast = hud.toast
	_layer.add_child(my_stamp_bar)
	_layer.move_child(my_stamp_bar, pause_menu.get_index())
	hud.look_area.blockers.append_array(my_stamp_bar.blockers())
	hud.palette.new_stamp_requested.connect(my_stamp_bar.open)
	pause_menu.opened.connect(my_stamp_bar.close)


# --- Owner #37: the shop and trading (spec §14.23) ------------------------------------------------------------------
# The TradeDirector (node "Trading" on every game): MORE → SHOP (Tilly's way and distance, Nico's cart on market day,
# the other players with TRADE), the first-time tip, market day (the host counts the days and places Nico's cart
# beside Tilly's stall), the universe helper's stand, a tap on another player's name tag (their card: TRADE), the ask
# card and the trade window (Session section "Trading" decides every trade). Survivor only.

var trading := TradeDirector.new()


func _add_trading() -> void:
	trading.name = "Trading"
	add_child(trading)


## Every game once its world exists: the rules it needs; the host also the saved days and Tilly's stall.
func _start_trading(host: bool) -> void:
	trading.mode = Game.mode
	trading.universe = Game.universe
	var shape := world.generator_shape()
	trading.world_seed = shape.seed
	trading.time_of_day = func() -> float: return sky.time if sky else DayCycle.START
	trading.tilly = func() -> Node3D:
		for t in _traders.get_children():
			if t is Trader and not t.is_queued_for_deletion():
				return t
		return null
	trading.giver = func(id: StringName) -> Node3D:
		var g: Variant = _quests.givers.get(id)
		return g if is_instance_valid(g) and g is Node3D else null
	trading.setup_world(shape)
	if host:
		trading.setup_host(meta.market, meta.trader_pos, meta.trader_yaw, world.spawn_column())
		Session.client_ready.connect(trading.on_client_ready)


func _setup_trading_local() -> void:
	trading.point_at = func(what: String, pos: Vector3) -> void:
		var runner := get_node_or_null("ChatCommands")
		if runner and runner.has_method(&"point_at"):
			runner.call(&"point_at", what, pos)
	trading.stop_arrow = func() -> void:
		var runner := get_node_or_null("ChatCommands")
		var arrow: Variant = runner.get("find_arrow") if runner else null
		if arrow is FindArrow and is_instance_valid(arrow):
			(arrow as FindArrow).stop()
	trading.setup_local(player, hud, _layer, _interactor)
	for c: Control in trading.pages():
		_layer.move_child(c, pause_menu.get_index())   # over the HUD, under the pause menu
	pause_menu.opened.connect(func() -> void:
		for page: QuestOverlay in [trading.shop_menu, trading.player_card]:
			if page:
				page.close())

# --- M3 Task 15: the tutorial with Pip (spec §14.9) -----------------------------------------------------------------
# The TutorialDirector (node "Tutorial", this game only): the first solo Survivor start offers PLAY WITH PIP / SKIP
# (owner #37's first-time shop tip waits for it), lays "Pip's playground" out near the spawn and puts every cell
# back afterwards (WorldMeta.tutorial_props: a crash's cells go back at the next start of this world), brings a
# visiting Pip, spawns the practice slime, and pays the reward once (500 gold through the host, Pip's Cap, Pip).

var tutorial := TutorialDirector.new()
var _tutorial_slimes := 0


func _add_tutorial() -> void:
	add_child(tutorial)


## Every game once its player exists (after the trading's setup: the tip and the arrow are its).
func _setup_tutorial_local() -> void:
	tutorial.here = TutorialDirector.plays_now() and not is_client()
	tutorial.profile = Profile.data
	tutorial.world = world
	tutorial.player = player
	tutorial.hud = hud
	if not is_client():
		tutorial.meta = meta
		tutorial.save_meta = func() -> void: WorldSaves.save_meta(_slot, meta)
	tutorial.shape = world.generator_shape()
	tutorial.spawn = world.spawn_column()
	tutorial.avoid = _tutorial_avoid
	tutorial.bring_pip = func(record: Dictionary) -> void: pets.on_pip(player.peer_id, record)
	tutorial.pip_node = func() -> Node3D:
		return pets.pip_of(player.peer_id) if is_instance_valid(player) else null
	tutorial.spawn_slime = func(pos: Vector3, yaw: float) -> Node3D:
		_tutorial_slimes += 1
		return _monsters.spawn_monster({"kind": MonsterRules.SLIME, "level": 1, "id": "tutorial_slime_%d" % _tutorial_slimes,
			"pos": pos, "yaw": yaw, "wild": false, "universe": Game.universe, "practice": true})
	tutorial.puff = func(m: Node3D) -> void:
		if m is Monster:
			_monsters.puff(m)
		else:
			m.queue_free()
	tutorial.gold_add = func(n: int) -> void: Session.gold_add(player.peer_id, n, "tutorial")
	tutorial.bag = func() -> Inventory: return Session.inventory_of(player.peer_id)
	tutorial.show_tip = trading.show_tip
	tutorial.release_tip = trading.maybe_tip
	tutorial.tilly = trading.tilly
	tutorial.point_at = trading.point_at
	tutorial.stop_arrow = trading.stop_arrow
	trading.hold_tip = tutorial.holds_tip
	tutorial.setup_local(_layer)
	for c: Control in [tutorial.card, tutorial.offer]:
		_layer.move_child(c, pause_menu.get_index())   # over the HUD, under the pause menu
	player.spawned.connect(tutorial.start_session, CONNECT_ONE_SHOT)


## The landmarks near the spawn the playground keeps clear of ([{at: Vector2, r}]): Tilly's stall (and Nico's cart
## beside it), the Totem, the portal, the stone circle, the Theater, the quest giver, the helper's stand.
func _tutorial_avoid() -> Array:
	var out: Array = []
	var add := func(p: Vector3, r: float) -> void:
		if p.is_finite():
			out.append({"at": Vector2(p.x, p.z), "r": r})
	if meta:
		if meta.has_trader():
			add.call(meta.trader_pos, 9.0)
		if meta.has_totem():
			add.call(meta.totem_pos, 5.0)
		if meta.has_portal():
			add.call(meta.portal_pos, 5.0)
		var theater := TheaterSite.from_save(meta.theater)
		if not theater.is_empty():
			add.call(Vector3(theater.pos) + Vector3(0.5, 0, 0.5), float(TheaterSite.HALF + TheaterSite.APRON + 3))
		var launch := LaunchSite.from_save(meta.launch_site)   # spec §21d: the Launch Site's plaza
		if not launch.is_empty():
			add.call(Vector3(launch.pos) + Vector3(0.5, 0, 0.5), 16.0)
	if UniverseRules.wants_hub(Game.mode):
		var shape := world.generator_shape()
		add.call(HubRules.circle_for_world(shape.seed, shape, world.spawn_column()).pos, 6.0)
	for g: Variant in _quests.givers.values():
		if is_instance_valid(g) and g is Node3D:
			add.call((g as Node3D).global_position, 5.0)
	if trading.stand and is_instance_valid(trading.stand):
		add.call(trading.stand.global_position, 5.0)
	return out

# --- Owner #55: space (the Moon and the planets; spec §21) ---------------------------------------------------------
# Flying high enough above any world crosses the space line (SpaceRules): the SpaceDirector (node "Space", this game's
# own player) turns the sky to space on the way up and opens "Where shall we land?" (SpacePanel). Landing (solo): the
# space world's save is written (SpaceTrip.arrival: made the first time; the bag comes along in Survivor), this world
# remembers the column the child took off from, and the space world loads with the child on its landing pad and the
# portal home (owner #39's arrival gate) beside it. HOME in the picker and that portal both go home through
# travel_through_gate; the home world lands the child where they took off (_arrive_from_space). A space world brings its
# gravity (LabRules.world_gravity), its sky (SkyCycle.space, a planet in it) and peace (no monsters come by themselves).

var space: SpaceDirector
var _space_home_arrival := false


## Every game with a local player, after its HUD: the world's gravity and sky, the space line and the picker, the
## landing's words, the landing pad on MY MAP.
func _space_local() -> void:
	LabRules.world_gravity = UniverseRegistry.gravity(Game.universe)
	if not tree_exiting.is_connected(_space_gravity_off):
		tree_exiting.connect(_space_gravity_off)
	sky.space = UniverseRegistry.space_sky(Game.universe)
	sky.sun_size = UniverseRegistry.sun_size(Game.universe)   # cosmos: Mercury's Sun, three times as big
	sky.sun_light = UniverseRegistry.sun_light(Game.universe)   # the visuals brief: Mars's dimmer sunlight
	sky.sun_west = UniverseRegistry.sun_rises_west(Game.universe)   # cosmos: Venus spins backwards
	sky.show_planet(UniverseRegistry.sky_planet(Game.universe))
	sky.refresh()
	space = SpaceDirector.new()
	space.name = "Space"
	space.player_position = func() -> Vector3: return Player.position_or_none(player)
	space.here = Game.universe
	space.home = meta.space_home if meta else UniverseRules.FIRST
	space.travel = land_on_space   # owner #87: the Star Map's LAND plays a real landing first (RocketFlight.land)
	space.go_home = go_home_from_space
	space.stay = _space_stay
	space.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 3.0)
	space.sky_climb = func(c: float) -> void: sky.set_space_climb(c)
	space.may_hold = func() -> bool: return not is_client() and multiplayer.get_peers().is_empty()
	space.unlocked = func() -> int: return Profile.data.universe_unlocked
	space.route = func() -> Variant: return mission_route()   # spec §21d.5: a planet not reached needs a mission
	space.seen = func(id: StringName) -> void:   # the Space Book (spec §21b.2)
		if Profile.data.wonder.see_body(id):
			Profile.save()
	add_child(space)
	space.setup_panel(_layer)
	space.panel.body_seen.connect(_on_star_map_body)   # owner #98: a mission's planet shows the way to the Launch Site
	_layer.move_child(space.panel, pause_menu.get_index())
	hud.look_area.blockers.append_array(space.panel.blockers())
	pause_menu.opened.connect(func() -> void: space.panel.close(false))   # the pause menu holds the game now
	_space_landed()
	_space_map()
	_space_sights()   # cosmos (spec §21b.2): Mars's sights and their facts
	_space_geysers()   # cosmos: Europa's water plumes, Io's volcanoes
	_space_lightning()   # cosmos: soft lightning far below Venus's cloud city
	_space_ganymede_sky()   # cosmos: Ganymede's auroras at night, Io and Europa swinging past Jupiter
	_space_creatures()   # owner #86: the robots by the pad, the rover and the drone, the aliens' camp or village


func _space_gravity_off() -> void:
	LabRules.world_gravity = 1.0


## Host and solo, not the arena: a peaceful world (space) has no night monsters (the Totem and /summon still work).
func _start_space_host() -> void:
	if UniverseRegistry.peaceful(Game.universe):
		_monsters.enabled = func() -> bool: return false
	_start_colony_animals()


# --- Spec §21c: colonies under domes (owner #77) ------------------------------------------------------------------
# The Moon's and Mars's colony is terrain (ColonyLayout, written by the generator); its parts' facts are the space
# world's sights (above). Here: the Great Dome's animals (ColonyAnimals, node "ColonyAnimals", host and solo), living only
# under the glass (on Mars the only ones), and bees and butterflies over its garden for this game's player.

var colony_animals: ColonyAnimals


func _start_colony_animals() -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or shape.colony == null or Game.mode == ModeRules.WAVE:
		return
	colony_animals = ColonyAnimals.new()
	colony_animals.name = "ColonyAnimals"
	colony_animals.layout = shape.colony
	colony_animals.container = _animals
	colony_animals.player_positions = _player_positions
	colony_animals.is_ready = world.is_area_ready
	colony_animals.spawn = func(data: Dictionary) -> void: _animal_spawner.spawn(data)
	add_child(colony_animals)
	_combat.animal_defeated.connect(colony_animals.note_defeated)


## Owner #94 (world/life): this game's player's meadow life, fireflies over the grass at night and a flock of birds
## circling high by day (AmbientLife). The developer arg --no-ambient-life leaves it out (tools/life_bench.gd's before).
func _add_ambient_life(amb: Ambience) -> void:
	if OS.get_cmdline_user_args().has("--no-ambient-life"):
		return
	var life := AmbientLife.new()
	life.name = "AmbientLife"
	life.player = player
	life.time_of_day = func() -> float: return sky.time if sky else DayCycle.NOON
	life.underground = func() -> float: return amb.underground if is_instance_valid(amb) else 0.0
	life.ground = func() -> int:
		return world.get_block(FrostRules.floor_cell(player.global_position)) if is_instance_valid(player) else BlockIds.AIR
	add_child(life)


## This game's player: bees and butterflies over the Great Dome's garden (by the grow lamps' light, day and night).
func _colony_insects(amb: Ambience) -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or shape.colony == null or Game.mode == ModeRules.WAVE:
		return
	var bugs := MeadowInsects.new()
	bugs.name = "ColonyInsects"
	bugs.player = player
	bugs.time_of_day = func() -> float: return DayCycle.NOON
	bugs.underground = func() -> float: return amb.underground if is_instance_valid(amb) else 0.0
	bugs.ground = func() -> int:
		if not is_instance_valid(player) or not shape.colony.in_great_dome(floori(player.global_position.x),
				floori(player.global_position.z)):
			return BlockIds.AIR
		return world.get_block(FrostRules.floor_cell(player.global_position))
	add_child(bugs)


## A card of the picker: lands on space world u (solo), or says why not ("" = on the way).
func travel_to_space(u: int) -> String:
	if _quitting:
		return ""
	if not SpaceRules.may_launch(Game.mode):
		return SpaceRules.message("no_flying")
	var peers := 1 if is_client() else multiplayer.get_peers().size()
	var why := SpaceRules.refusal(u, Game.universe, UniverseRegistry.trip_available(), peers)
	if why != "":
		return SpaceRules.message(why)
	if MissionRules.needs_mission(u, mission_route()):   # spec §21d.5
		return _launch_site_hint()   # owner #98: and where the Launch Site is (the arrow points there)
	_travel_space.call_deferred(u)
	return ""


## Saves this world (the take-off column, walking) and the space world u (SpaceTrip.arrival), then opens u.
func _travel_space(u: int) -> void:
	if _quitting:
		return
	_quitting = true
	var survivor := Game.mode == ModeRules.SURVIVOR
	var bag: Array = Session.inventory_of(player.peer_id).to_save() if survivor else []
	var hotbar: Array[int] = _interactor.hotbar.duplicate()
	SpaceTrip.arrival(meta, u, Game.mode, ModeRules.slot(Game.mode, u), _home_key(), bag, hotbar, _interactor.selected_slot)
	if survivor:
		Session.set_inventory(player.peer_id, Inventory.from_save(meta.inventories.get(_home_key(), [])))
	var feet := player.global_position
	save_world()
	SpaceRules.take_off(meta, feet)
	WorldSaves.save_meta(_slot, meta)
	SpaceDirector.landing = u
	Audio.play(&"portal_whoosh")
	await world.save_and_wait()
	print("SPACE travel %d -> %d" % [Game.universe, u])
	var kept: bool = await _close_or_move(u, false)   # spec §21d.6: a crew's landing brings it along
	Game.start_world(Game.mode, false, meta.difficulty, u)
	if kept:
		Game.net_mode = &"host"


## HOME in the picker (a space world): the way owner #39's portal home goes (the bag comes along in Survivor). Spec
## §21d.6 phase 2: the host brings the friends here home with it (the crew follows); a guest's HOME goes home on its
## own, kindly (the crew stays).
func go_home_from_space() -> String:
	if not SpaceRules.is_away(Game.universe):   # owner #78: Earth's own worlds go home the same way
		return SpaceRules.message("here")
	if is_client():
		return _crew_guest_home()
	var home := SpaceRules.home_for(Game.universe, meta.space_home if meta else UniverseRules.FIRST)
	if crew != null and crew.moving_crew(true):
		return _crew_home(home)
	return travel_through_gate(home)


## STAY HERE: back under the line (so flying up again opens the picker again).
func _space_stay() -> void:
	if is_instance_valid(player) and player.global_position.y > SpaceRules.STAY_Y:
		player.global_position.y = SpaceRules.STAY_Y
		player.velocity = Vector3.ZERO


## Host and solo, before the player spawns: home from space lands on the column the child took off from.
func _arrive_from_space() -> bool:
	var col := SpaceRules.landing_spot(meta)
	if col.is_empty():
		return false
	meta.space_return = []
	meta.player_pos = Vector3.INF
	player.spawn_on_surface(int(col[0]), int(col[1]))
	_space_home_arrival = true
	return true


## The landing's words, a whoosh and a puff of dust (a trip that landed here), or "Welcome home!".
func _space_landed() -> void:
	if Profile.data.wonder.land_on_world(Game.universe):   # the Space Book's flag (spec §21b.2)
		Profile.save()
	var said := ""
	var postcard := {}
	if SpaceDirector.take_landing(Game.universe):
		postcard = PostcardRules.for_landing(Game.universe, mission_landing == Game.universe)   # owner #85: once a place
		said = UniverseRegistry.landing_words(Game.universe)
		if said == "":
			said = SpaceRules.landing_words(UniverseRegistry.display_name(Game.universe))
		if mission_landing == Game.universe:   # spec §21d: a mission's rocket brought the child here
			said = tr(MissionRules.COMPLETE) + tr(said)
	elif _space_home_arrival:
		said = SpaceRules.HOME_WORDS
	mission_landing = 0
	_space_home_arrival = false
	if not postcard.is_empty():   # after the landing's words: MAKE A POSTCARD (offered once per place, ever)
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_inside_tree() and is_instance_valid(_layer):
				PostcardOffer.offer(_layer, postcard))
	if said == "":
		return
	var land := func() -> void:
		if is_instance_valid(hud):
			hud.toast(tr(said), 5.0)
		Audio.play(&"portal_whoosh", player.global_position, -6.0)
		Fx.burst(get_tree().root, player.global_position + Vector3(0, 0.2, 0), Color("dde2ee"), 24, 3.0)
	if player.is_spawned():
		land.call()
	else:
		player.spawned.connect(land, CONNECT_ONE_SHOT)


## MY MAP in a space world: its landing pad, and its landmark (the Moon Base, …) once someone found it.
func _space_map() -> void:
	if not SpaceRules.is_space(Game.universe) or places_director == null:
		return
	var sp := world.spawn_column()
	places_director.mark({"id": "space_pad", "kind": &"pad", "name": tr("Landing Pad"),
		"pos": Vector3(sp.x + 0.5, world.surface_height(sp.x, sp.y), sp.y + 0.5)})
	var rules := _secrets.rules as SpaceSecretRules
	if rules == null or rules.landmark().is_empty():
		return
	var lm := rules.landmark()
	var at: Vector3i = lm.anchor
	var entry := {"id": "space_landmark", "kind": &"landmark", "name": tr(str(lm.get("name", "Landmark"))),
		"pos": Vector3(at.x + 0.5, at.y, at.z + 0.5)}
	if _secrets.state.found.has(lm.id):
		places_director.mark(entry)
	else:
		_secrets.found_shown.connect(func(kind: StringName) -> void:
			if kind == SecretRules.ISLAND:
				places_director.mark(entry))


# --- Cosmos: a space world's sights (spec §21b.2) -----------------------------------------------------------------
# Mars's sights (SpaceSights, node "Sights", this game's own player): walking onto the volcano's summit, the canyon's
# floor, an ice cap or a dry river bed says a real fact once per world (kept in the world's secrets) and marks MY MAP.

var sights: SpaceSights


func _space_sights() -> void:
	var shape := world.generator_shape() as SpaceShape
	var own := UniverseRegistry.sights(Game.universe)
	if shape == null or own.is_empty() or places_director == null:
		return
	sights = SpaceSights.new()
	sights.name = "Sights"
	sights.shape = shape
	sights.sights = own
	sights.found = _secrets.state.found
	sights.player_position = func() -> Vector3: return Player.position_or_none(player)
	sights.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 6.0)
	sights.mark = places_director.mark
	add_child(sights)
	sights.setup()
	_setup_planet_guide(shape, own)


## Owner #88 ("what should i do after i land on mercury, there should be some guides"): the explorer's card when the
## child stands on the planet (its places, PlanetGuideCard), the HUD's compass to the nearest place not found yet, and
## after each find how many are found and which is next.
func _setup_planet_guide(shape: SpaceShape, own: Dictionary) -> void:
	var spots := shape.sights()
	if spots.is_empty() or not is_instance_valid(hud):
		return
	var list_now := func() -> Array[Dictionary]:
		return PlanetGuideRules.checklist(spots, own, _secrets.state.found, Vector3.ZERO)
	var here := func() -> Vector3:
		var at := Player.position_or_none(player)
		return at if at.is_finite() else Vector3.ZERO
	hud.compass.guide = func(from: Vector3) -> Dictionary:
		if prospecting != null:   # spec §26.5: a prospecting quest's walk first
			var q := prospecting.quest_target(from)
			if not q.is_empty():
				return q
		var n := PlanetGuideRules.next(list_now.call(), from)
		if n.is_empty() and prospecting != null:
			return prospecting.compass_target(from)   # every place found: the Metal Detector's, the Ice Finder's
		return {} if n.is_empty() else {"chest": Vector3i(n.pos)}
	sights.sight_found.connect(func(id: StringName) -> void:   # after the fact's own words
		if shape.is_part_sight(id):
			return   # spec §21c: a colony's part is no place of the checklist (its Great Dome is)
		get_tree().create_timer(6.5).timeout.connect(func() -> void:
			if is_instance_valid(hud):
				hud.toast(PlanetGuideRules.progress_words(list_now.call(), here.call()), 6.0)))
	var show_card := func() -> void:
		var card := PlanetGuideCard.new(UniverseRegistry.display_name(Game.universe), list_now.call())
		_layer.add_child(card)
		if PlatformRules.captures_mouse(PlatformRules.current()):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # a PC clicks LET'S GO (the next click looks around again)
		card.closed.connect(card.queue_free)
	if player.is_spawned():
		show_card.call()
	else:
		player.spawned.connect(show_card, CONNECT_ONE_SHOT)


# --- Owner #78: the world's wonders (spec §24) -------------------------------------------------------------------
# World 41, Wonders of the World (Earth's own, reached from the Star Map's Earth card): the WondersDirector (node
# "Wonders", this game's own player) watches the wonders as sights (reaching one says its real fact and stamps the
# Wonders Passport), puts them and the landing spot on MY MAP, names the signposts and plaques, points the HUD's compass
# to the nearest wonder not reached, shows the explorer's card on landing, and opens a wonder's card and fact quiz from
# its plaque (the quiz's gold: _wonder_pay, like prospecting's).

var wonders: WondersDirector


func _wonders_local() -> void:
	if Game.universe != EarthRules.WONDERS or places_director == null or not is_instance_valid(hud):
		return
	wonders = WondersDirector.new()
	wonders.name = "Wonders"
	wonders.found = _secrets.state.found
	wonders.player_position = func() -> Vector3: return Player.position_or_none(player)
	wonders.toast = func(text: String, seconds: float) -> void:
		if is_instance_valid(hud):
			hud.toast(text, seconds)
	wonders.mark = places_director.mark
	wonders.pay = _wonder_pay
	wonders.ui_parent = _layer
	wonders.sky_time = func() -> float: return sky.time if is_instance_valid(sky) else DayCycle.NOON   # the third tour's northern lights
	wonders.stamp_won.connect(func(_id: StringName) -> void:   # owner #94: a new stamp is worth a jump for joy
		if is_instance_valid(player):
			player.react_happy())
	add_child(wonders)
	wonders.setup()
	hud.compass.guide = wonders.compass_target
	_interactor.plaque_tapped.connect(func(cell: Vector3i) -> void: wonders.open_plaque(cell))
	var show_card := func() -> void:
		var card := wonders.guide_card()
		_layer.add_child(card)
		if PlatformRules.captures_mouse(PlatformRules.current()):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # a PC clicks LET'S GO (the next click looks around again)
		card.closed.connect(card.queue_free)
	if player.is_spawned():
		show_card.call()
	else:
		player.spawned.connect(show_card, CONNECT_ONE_SHOT)


## A wonder's quiz gold for this child: Survivor through the host's wallet, the Sandbox into the profile like the
## School's (as prospecting pays).
func _wonder_pay(gold: int) -> void:
	if gold <= 0:
		return
	if Game.allows(ModeRules.INFINITE_GOLD):
		EarnRules.credit(Profile.data, gold)
		Profile.save()
	else:
		Session.gold_add(player.peer_id, gold, "wonder_quiz")


# --- Universe 6: the Glow Caves' Cave Wonders (owner #122, learning is play) -----------------------------------------
# GlowWondersDirector (node "GlowWonders", every game, this game's own child): near a wonder it says its problem (never
# the answer), makes its tap spots and looks; a play won says the world's cheer and the real fact, pays fixed gold once
# (as the wonders' quiz pays), opens the Cave Book's page and is kept with the world; the compass points to the nearest
# wonder not solved (a prospecting quest's walk first).

var glow_wonders: GlowWondersDirector


func _glow_local() -> void:
	var rules := _secrets.rules as GlowSecretRules
	if rules == null or not is_instance_valid(hud) or player == null:
		return
	glow_wonders = GlowWondersDirector.new()
	glow_wonders.name = "GlowWonders"
	glow_wonders.wonders = rules.wonders
	glow_wonders.universe = Game.universe
	glow_wonders.found = _secrets.state.found
	glow_wonders.player_position = func() -> Vector3: return Player.position_or_none(player)
	glow_wonders.noise = _stealth.local_noise
	glow_wonders.holds_light = func() -> bool:   # a lamp in hand, or a light near (the stealth eye's "lit")
		return is_instance_valid(player) and (player.stealth_light >= StealthRules.NEAR_LIGHT \
			or StealthRules.LIGHT_BLOCKS.has(_interactor.selected_block()))
	glow_wonders.toast = func(text: String, seconds: float) -> void:
		if is_instance_valid(hud):
			hud.toast(text, seconds)
	glow_wonders.voice_on = func() -> bool: return PlayVoice.on()   # owner #133/#134: heard, few words on screen
	glow_wonders.speak = func(text: String) -> void: PlayVoice.say(text)
	glow_wonders.pay = _wonder_pay
	glow_wonders.book = func(kind: StringName) -> void:
		if Profile.data.wonder.find_cave(kind):
			Profile.save()
	glow_wonders.block_at = world.get_block
	glow_wonders.set_block = world.set_block
	if places_director != null:
		glow_wonders.mark = places_director.mark
	glow_wonders.nearest_chest = func(from: Vector3) -> Vector3:
		var s := _secrets.rules.nearest_buried(from, _secrets.state.opened)
		return Vector3(s.chest as Vector3i) + Vector3(0.5, 0.0, 0.5) if not s.is_empty() else Vector3.INF
	add_child(glow_wonders)
	var before: Callable = hud.compass.guide
	hud.compass.guide = func(from: Vector3) -> Dictionary:
		if prospecting != null:   # spec §26.5: a prospecting quest's walk first
			var q := prospecting.quest_target(from)
			if not q.is_empty():
				return q
		var t := glow_wonders.compass_target(from)
		return before.call(from) if t.is_empty() and before.is_valid() else t


# Europa's water plumes and Io's volcanoes (SpaceGeysers, node "Geysers", this game's own player): the vents near the
# player erupt now and then; a vent itself throws a child up (PadRules).
var geysers: SpaceGeysers


func _space_geysers() -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or not shape.has_vents():
		return
	geysers = SpaceGeysers.new()
	geysers.name = "Geysers"
	geysers.shape = shape
	geysers.player_position = func() -> Vector3: return Player.position_or_none(player)
	add_child(geysers)


# Venus's lightning (VenusLightning, node "Lightning", this game's own player): now and then a soft, silent flash far
# below in the yellow clouds, never near the child.
var lightning: VenusLightning


func _space_lightning() -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or shape.venus == null:
		return
	lightning = VenusLightning.new()
	lightning.name = "Lightning"
	lightning.shape = shape
	lightning.player_position = func() -> Vector3: return Player.position_or_none(player)
	add_child(lightning)


# Ganymede's sky shows (GanymedeSky, node "GanymedeSky", this game's own player): the auroras' glowing belts over both
# poles at night, Io and Europa swinging back and forth past Jupiter.
var ganymede_sky: GanymedeSky


func _space_ganymede_sky() -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or shape.ganymede == null:
		return
	ganymede_sky = GanymedeSky.new()
	ganymede_sky.name = "GanymedeSky"
	ganymede_sky.shape = shape
	ganymede_sky.sky = sky
	ganymede_sky.sky_time = func() -> float: return sky.time if is_instance_valid(sky) else DayCycle.NOON
	add_child(ganymede_sky)


# --- Owner #86: robots and aliens on the planets (spec §21f) -------------------------------------------------------
# SpaceCreatures (node "Creatures", this game's own; space trips are solo): the helper robot by the landing pad (its
# arm points where the HUD's compass points; its science quest pays the planets' fact-quiz gold), the rover buddy that
# follows and digs samples, the scout drone that flies ahead, and the aliens' camp (the real bodies) or village (the
# playful planets), a short walk away and on MY MAP. An alien friend who comes along is a mini-buddy (the buddy
# system: BuddyMagicDirector brings it into every world). A tap on any of them: BlockInteractor._tap_space_creature.

var creatures: SpaceCreatures


func _space_creatures() -> void:
	var shape := world.generator_shape() as SpaceShape
	if shape == null or is_client() or not SpaceCreatures.wanted(Game.universe, Game.mode):
		return
	creatures = SpaceCreatures.new()
	creatures.universe = Game.universe
	creatures.shape = shape
	creatures.world_seed = shape.seed
	creatures.ground_y = func(x: int, z: int) -> float: return float(world.find_standing_y(x, z))
	creatures.player_position = func() -> Vector3: return Player.position_or_none(player)
	creatures.player_forward = func() -> Vector3:
		return player.rig.forward_flat() if is_instance_valid(player) else Vector3.FORWARD
	creatures.found = _secrets.state.found
	creatures.sights = UniverseRegistry.sights(Game.universe)
	creatures.profile = Profile.data
	creatures.save_profile = Profile.save
	creatures.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(text, 5.0)
	if places_director:
		creatures.mark = places_director.mark
	creatures.gold_changed = func(balance: int) -> void: Session.gold_changed.emit(balance)
	creatures.bring_buddy = buddy_magic.bring_minis
	creatures.send_home = func(kind: StringName) -> void:   # an alien buddy goes back to its camp (one at a time)
		var a: Animal = buddy_magic.mini_of(player.peer_id, kind) if is_instance_valid(player) else null
		if a:
			Fx.burst(get_tree().root, a.global_position + Vector3(0, 0.5, 0), Color("ffd23f"), 12, 2.5)
			a.queue_free()
	creatures.avoid = _creature_avoid(shape)
	var rules := _secrets.rules as SpaceSecretRules
	if rules != null and not rules.landmark().is_empty():
		var at: Vector3i = rules.landmark().anchor
		creatures.landmark = Vector2(at.x, at.z)
	creatures.ui_parent = _layer
	add_child(creatures)
	creatures.setup()
	_layer.move_child(creatures.card, pause_menu.get_index())   # over the HUD, under the pause menu
	hud.look_area.blockers.append_array(creatures.card.blockers())
	pause_menu.opened.connect(creatures.card.close)


## What the helper robot keeps clear of by the pad: Tilly's stall (and Nico's cart beside it), the portal home that
## stands by the pad from an earlier visit, Mercury's thermometer (the landing's own portal and the lander: RobotRules).
func _creature_avoid(shape: SpaceShape) -> Array:
	var out: Array = []
	if meta and meta.has_trader():
		out.append({"at": Vector2(meta.trader_pos.x, meta.trader_pos.z), "r": 3.5})
	if meta:
		var gate := ReturnGate.arrival(PortalGates.from_save(meta.gates), meta.space_home)
		if not gate.is_empty():
			var exit: Vector3 = gate.pos
			out.append({"at": Vector2(exit.x, exit.z), "r": 3.0})
	if shape.planet == SpaceShape.MERCURY:
		var t := shape.thermometer_column()
		out.append({"at": Vector2(t.x + 0.5, t.y + 0.5), "r": 1.5})
	return out


# --- Owner #79, #86, #87: the rocket flight (spec §25.3, §21d.4) -------------------------------------------------
# The missions' LAUNCH hands the rocket the child built to fly_rocket (their `fly` Callable: the lead joins them): a
# RocketFlight stands at the pad and the child flies it (the cockpit over the game, the player hidden, held and safe on
# the pad); landed, the space world loads as a trip does (_travel_space: the landing's words and dust) and the lander
# stands by the landing pad (FlightTicket.parked, this session). The Star Map's LAND (owner #87: "landing on mercury
# should be done like real landing") plays the landing on its own first (land_on_space). QUIT aborts a flight (all put
# back). Developer: FlightTicket.test_pending (the developer menu's FLY, --fly-moon, --fly=<world>, --land=<world>).
# RocketFlight is loaded when a flight starts (never compiled with the world: M7's start-up rule).

const FLIGHT_SCRIPT := "res://entities/flight/rocket_flight.gd"

## The flight flying now (a RocketFlight; untyped: its script loads when a flight starts), else null.
var flight = null
var _flight_warming := false


## RocketFlight's script: from the worker that compiled it as the world appeared, or loaded now.
func _flight_script() -> GDScript:
	if _flight_warming:
		_flight_warming = false
		var got := ResourceLoader.load_threaded_get(FLIGHT_SCRIPT) as GDScript
		if got:
			return got
	return load(FLIGHT_SCRIPT) as GDScript


func _rocket_local() -> void:
	pause_menu.save_and_quit_requested.connect(func() -> void:
		if is_instance_valid(flight):
			flight.abort())
	tree_exiting.connect(func() -> void:   # the worker's compile is taken, never left pending to the engine's shutdown
		if _flight_warming:
			_flight_warming = false
			ResourceLoader.load_threaded_get(FLIGHT_SCRIPT))
	var parked := FlightTicket.take_parked(Game.universe)
	var test := FlightTicket.take_test()
	var on_spawn := func() -> void:
		if ResourceLoader.load_threaded_request(FLIGHT_SCRIPT) == OK:   # compiled on a worker, never in LAUNCH's frame
			_flight_warming = true
		if not parked.is_empty():
			_stand_lander(parked.cells)
		if int(test.get("destination", 0)) > 0:
			_start_test_flight(int(test.destination), bool(test.get("landing", false)))
	if player.is_spawned():
		on_spawn.call()
	else:
		player.spawned.connect(on_spawn, CONNECT_ONE_SHOT)


## The missions' LAUNCH: the child flies `rocket` (RocketStages' description; "origin": the pad's corner in the world,
## else in front of the child). "" when it lifts off, else why not (the words).
func fly_rocket(rocket: Dictionary) -> String:
	if _quitting or is_instance_valid(flight):
		return ""
	var why := _rocket_refusal(int(rocket.get("destination", SpaceRules.MOON)), bool(rocket.get("crew", false)))
	if why != "":
		return why
	var origin: Variant = rocket.get("origin")
	var at := Vector3(origin) if origin is Vector3 or origin is Vector3i else _pad_in_front(rocket)
	var dest := int(rocket.get("destination", SpaceRules.MOON))
	_start_flight(at, dest).start(rocket, Game.universe)
	UniverseRegistry.warm_space()   # the world it lands on loads in the background while it flies (the climb does it too)
	_layer.move_child(flight.cockpit, pause_menu.get_index())   # over the HUD, under the pause menu
	return ""


## The Star Map's LAND (owner #87): the landing plays (RocketFlight.land, ~14 s), then world u loads; "" or why not.
func land_on_space(u: int) -> String:
	if _quitting or is_instance_valid(flight):
		return ""
	var why := _rocket_refusal(u)
	if why != "":
		return why
	if EarthRules.is_earth(u):   # owner #78 (spec §24): back down to Earth's wonders, no rocket landing (a plane: later)
		_travel_space.call_deferred(u)
		return ""
	var landing := func() -> void:
		if not _quitting and not is_instance_valid(flight):
			_start_flight(player.global_position, u).land(u)
			_layer.move_child(flight.cockpit, pause_menu.get_index())
	landing.call_deferred()
	return ""


## Why a flight to world u can't go ("" = it can). crew_flight: the pilot's crew flight (spec §21d.6: its friends fly
## along, so they never stop it).
func _rocket_refusal(u: int, crew_flight: bool = false) -> String:
	if not SpaceRules.may_launch(Game.mode):
		return SpaceRules.message("no_flying")
	var peers := 0 if crew_flight else (1 if is_client() else multiplayer.get_peers().size())
	var built: Array[int] = []   # is its file there (loading every world's descriptor to know took 290 ms)
	var path := UniverseRegistry.path_for(u)
	if path != "" and ResourceLoader.exists(path):
		built.append(u)
	var why := SpaceRules.refusal(u, Game.universe, built, peers)
	return SpaceRules.message(why) if why != "" else ""


## A RocketFlight to world `dest` at `origin` (the pad's corner) with the sandbox's hooks; the caller starts it.
func _start_flight(origin: Vector3, dest: int) -> Node3D:
	flight = _flight_script().new()
	flight.name = "RocketFlight"
	flight.position = origin
	flight.ui_parent = _layer
	flight.from_camera = player.camera()
	flight.skippable = _been_to(dest)
	flight.take_over = _rocket_take_over
	flight.world_light = func(on: bool) -> void: world.sun().visible = on
	flight.sky_climb = func(c: float) -> void: sky.set_space_climb(c)
	flight.keep_safe = func() -> void: player.health.protect(3.0)
	flight.ground_at = func(x: float, z: float) -> float: return float(world.surface_height(floori(x), floori(z)))
	flight.pause_requested.connect(pause_menu.open)
	flight.first_try = not _been_to(dest)   # owner #106: the easy first descent, with its hint card
	flight.wreck = _flight_wreck   # owner #106: the rocket falls by the Launch Site and parts break
	flight.crashed.connect(_on_flight_crashed)
	_flight_is_mission = false
	flight.landed.connect(func(u: int) -> void:
		AnimIdle.cheer_on_arrival = true   # owner #94: the child jumps for joy once it stands on the new world
		if is_instance_valid(flight) and flight.crew_follow:
			if crew != null:
				crew.follower_landed()   # spec §21d.6: a crew member's flight only fades out; the pilot's world moves
			return
		if _flight_is_mission:
			_flight_is_mission = false
			mission_arrive(u)   # the route, the Space Book, a friend's Moon bonus (InviteRules.friend_landed)
		else:
			_travel_space(u))
	flight.ended.connect(func() -> void: flight = null)
	add_child(flight)
	return flight


## Owner #87's ruling: SKIP shows on a repeat visit (world u was landed on before: the Space Book, spec §21b.2).
func _been_to(u: int) -> bool:
	var id := StarMap.body_for_world(u)
	return id != &"" and (int(Profile.data.wonder.bodies.get(str(id), 0)) & WonderData.LANDED) != 0


func _rocket_take_over(on: bool) -> void:
	if not is_instance_valid(player):
		return
	player.visible = not on
	player.velocity = Vector3.ZERO
	player.set_physics_process(not on)
	if is_instance_valid(hud):
		hud.visible = not on
	if _interactor:
		_interactor.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if space:
			space.close_picker()
		if keys_card and keys_card.visible:   # the flight's own keys are on it; the cockpit is what matters now
			keys_card.close()
	else:
		player.camera().make_current()
		_lend_chat(false)


## Where a rocket with no pad stands (the developer's test rocket): its footprint's middle 7 blocks in front of the
## child, on the ground there.
func _pad_in_front(rocket: Dictionary) -> Vector3:
	var r := RocketStages.normalize(rocket)
	var pivot := RocketStages.pivot(r.cells)
	var ahead := player.global_position + player.rig.forward_flat() * 7.0
	var x := floori(ahead.x)
	var z := floori(ahead.z)
	var y := float(world.find_standing_y(x, z))
	return Vector3(x - floorf(pivot.x), y, z - floorf(pivot.z))


## The lander that just touched down stands by the landing pad, to the child's left (the portal home is in front).
func _stand_lander(cells: Dictionary) -> void:
	var forward := player.rig.forward_flat()
	var left := Vector3.UP.cross(forward).normalized()
	var at := player.global_position + left * 7.0
	var x := floori(at.x)
	var z := floori(at.z)
	var lander: Node3D = _flight_script().stand(cells)
	lander.position = Vector3(x + 0.5, float(world.find_standing_y(x, z)), z + 0.5)
	lander.rotation.y = player.rig.yaw
	add_child(lander)
	print("ROCKET lander parked at %s" % lander.position)


## Developer: a test rocket (two stages of blocks every world has) to world u in front of the child, or (landing) the
## landing on its own.
func _start_test_flight(u: int, landing: bool) -> void:
	var why := land_on_space(u) if landing else fly_rocket(RocketStages.test_rocket(u, 2))
	print("ROCKET test %s to %d %s" % ["landing" if landing else "flight", u, why if why != "" else "started"])
# --- Owner #90: game controllers (PlayStation, Xbox, any pad) ------------------------------------------

## Every panel of this world a game controller moves round in (PadFocus: the newest one showing has the pad and the
## world's pad inputs wait; Circle / B goes back). The pause menu and the Star Map watch themselves; the Science Lab
## when it is built (open_lab).
func _setup_pad() -> void:
	var panels: Array = [pause_menu, hud.palette, hud.more, hud.shop, hud.secret_book, hud.riddle_panel, hud.totem_panel,
		hud.course_panel, hud.arena_panel, hud.farm_panel, keys_card, world_map, pet_panel, share_panel, bottle_card,
		wear_card, lab_panel, photo, _quests.book, _quests.card, trading.player_card, trading.ask_card, trading.trade_window]
	if universe_hub:
		panels.append(universe_hub.panel)
	if launch_site:
		panels.append(launch_site.board)   # spec §21d: the Mission Board (X closes it; it waits till the child walks away)
	for p: Variant in panels:
		if p is Control:
			PadFocus.watch(p)
	pad_theater(get_node_or_null("Theater") as TheaterDirector)
	if PadFocus.instance:
		PadFocus.instance.device_changed.connect(_on_pad_changed)
	_on_pad_changed(PadFocus.pad_active())


## Owner #94: Android Back closes the School page a Short's LEARN IT opened over the Theater (true when it did).
func _theater_school_closed() -> bool:
	var theater := get_node_or_null("Theater") as TheaterDirector
	return theater != null and theater.panel != null and (theater.panel.school.close_if_open()
		or theater.panel.shorts.back_if_making())   # MAKE MY SHORT: Back is a step back in the maker


## Owner #89's Theater: inside it the screen has the pad (the D-pad picks a channel and a video, Cross / A plays);
## Circle / B stops a video (CLOSE), then leaves (EXIT, marked as its back button: its BACK is the video before), and
## the child walks on.
static func pad_theater(theater: TheaterDirector) -> void:
	if theater == null or theater.panel == null:
		return
	PadFocus.watch(theater.panel)
	theater.panel.exit_button.set_meta(&"pad_back", true)


## The hands changed: the touch HUD hides while a pad plays (a finger brings it back), a card showing follows, and the
## CONTROLLER card comes by itself the first time a pad plays in a world.
func _on_pad_changed(on: bool) -> void:
	if not is_instance_valid(hud):
		return
	hud.set_pad(on)
	if keys_card == null:
		return
	keys_card.show_for(PadFocus.current_family() if on else &"")
	if on and GamepadRules.card_due(Profile.data.settings) and is_instance_valid(player) and player.is_spawned():
		Profile.data.settings.pad_seen = true
		Profile.save()
		keys_card.open()


## The touchpad / View: MY MAP opens (in a world with places, and no panel open) or closes.
func _pad_map() -> void:
	if world_map == null:
		return
	if world_map.visible:
		world_map.close()
	elif map_button != null and map_button.visible and not PadFocus.menu_has_pad():
		world_map.open()

# --- Spec §21d.6 phase 2: crew flights (owner #78 "which can be built by team or alone", #79) --------------------------
# LAUNCH with friends here calls them (CrewFlights, node "Crew": the call's card, the seats, the pilot's flight going to
# the crew); each crew member flies the pilot's flight from a seat of their own (_crew_fly: a RocketFlight following the
# pilot's, the HUD's chat lent to the cockpit); landed or HOME, the host's world moves with its friends (_close_or_move:
# the session goes on, Session.crew_move) and each guest follows it (_crew_follow: a fresh guest scene joins the same
# match or LAN host); a crew member's own profile flies the mission and keeps the crew badge (_crew_credit).

## The host waits at most this long for its guests to let go of the world it leaves with them.
const CREW_LET_GO_SECONDS := 2.0

var crew: CrewFlights
var _chat_home := -1


func _setup_crew() -> void:
	crew = CrewFlights.new()
	crew.name = "Crew"
	crew.ui_parent = _layer
	crew.host = not is_client()
	crew.my_id = func() -> int: return multiplayer.get_unique_id()
	crew.my_name = func() -> String: return str(Session.chat_names.get(multiplayer.get_unique_id(), Profile.data.username))
	crew.names = func() -> Dictionary: return Session.chat_names
	crew.looks = _crew_looks
	crew.peers = func() -> Array[int]:
		var out: Array[int] = []
		out.assign(multiplayer.get_peers())
		return out
	crew.origin = func() -> Variant:
		return Vector3(LaunchSite.corner(launch_site.site)) if launch_site != null and not launch_site.site.is_empty() \
			else null
	crew.fly = _crew_pilot_fly
	crew.follow_fly = _crew_fly
	crew.standing = func() -> bool: return is_instance_valid(player) and player.is_spawned()
	crew.flight = func() -> Node: return flight if is_instance_valid(flight) else null
	crew.goodbye = func(words: String) -> void:
		if not _quitting:
			process_mode = Node.PROCESS_MODE_DISABLED   # (the world stops with its viewers, as _on_disconnected's does)
			_goodbye(words)
	crew.toast = func(text: String) -> void:
		if is_instance_valid(hud):
			hud.toast(tr(text), 6.0)
	crew.credit = _crew_credit
	crew.follow_world = func(u: int, home: bool) -> void: _crew_follow.call_deferred(u, home)
	add_child(crew)


## Every game with a local player: once it stands, a world a crew moved into says so (CrewFlights.arrived).
func _crew_local() -> void:
	if player.is_spawned():
		crew.arrived()
	else:
		player.spawned.connect(crew.arrived, CONNECT_ONE_SHOT)


## Each player's avatar look here (the crew's seats show them).
func _crew_looks() -> Dictionary:
	var out := {}
	for p: Player in _players.get_children():
		out[p.peer_id] = p.look_code
	return out


## The pilot's flight with its crew: the rocket from the pad (its "origin"; "crew" lets it fly with friends here).
func _crew_pilot_fly(r: Dictionary) -> String:
	var why := fly_rocket(r)
	if why != "":
		return why
	_flight_is_mission = true
	_lend_chat(true)
	Session.broadcast_chat_line(MissionRules.launched_words(str(Session.chat_names.get(multiplayer.get_unique_id(),
		Profile.data.username)), MissionRules.for_world(int(r.get("destination", 0)))))
	return ""


## A crew member's flight: the pilot's rocket from the same pad, following the pilot's flight from seat `seat` of
## `size` (RocketFlight.crew_follow). Null when it can't (a flight already on, leaving).
func _crew_fly(r: Dictionary, pilot: String, seat: int, size: int) -> Node:
	if _quitting or is_instance_valid(flight) or not is_instance_valid(player):
		return null
	var dest := int(r.get("destination", SpaceRules.MOON))
	var o: Variant = r.get("origin")
	var at := Vector3(o) if o is Vector3 or o is Vector3i else _pad_in_front(r)
	var f := _start_flight(at, dest)
	f.set("crew_follow", true)
	f.set("pilot", pilot)
	f.set("seat", seat)
	f.set("crew_size", size)
	f.call("start", r, Game.universe)
	UniverseRegistry.warm_space()
	_layer.move_child(flight.cockpit, pause_menu.get_index())
	_lend_chat(true)
	return f


## During a crew flight the HUD's chat rides on the cockpit (the HUD is hidden): over the cockpit, under the pause
## menu; its keys go to the chat bar while it is open. Back into the HUD when the flight is over.
func _lend_chat(on: bool) -> void:
	if not is_instance_valid(hud) or hud.chat == null:
		return
	var chat: ChatPanel = hud.chat
	if on and chat.get_parent() == hud and is_instance_valid(flight) and flight.cockpit != null:
		_chat_home = chat.get_index()
		hud.remove_child(chat)
		_layer.add_child(chat)
		_layer.move_child(chat, flight.cockpit.get_index() + 1)
		flight.cockpit.keys_free = func() -> bool: return is_instance_valid(chat) and chat.is_open()
	elif not on and chat.get_parent() == _layer:
		chat.close()
		_layer.remove_child(chat)
		hud.add_child(chat)
		hud.move_child(chat, clampi(_chat_home, 0, hud.get_child_count() - 1))


## This child's own profile after a crew flight to world u with `mates`: the mission flown (mission: a crew member's;
## the pilot's counted in mission_arrive: nothing pays twice) and the crew badge; its words when the badge is new.
func _crew_credit(u: int, mates: Array, mission: bool) -> String:
	if mission and Profile.data.missions.fly(u) and u == SpaceRules.MOON:
		InviteRules.friend_landed("moon")   # (#79: a friend's first Moon landing pays their inviter, once)
	var fresh := Profile.data.missions.crews.add(u, mates)
	Profile.save()
	return CrewFlightRules.badge_words(u, mates) if fresh else ""


## Host: leaving this world for world u (a landing, or HOME): with friends who come along the session goes on and they
## follow (true: the caller's next world keeps hosting); else the session closes as before. The world changes once the
## guests have let go of it (their bodies' last syncs never reach the next world), a moment at most.
func _close_or_move(u: int, home: bool) -> bool:
	if crew != null and crew.moving_crew(home):
		Session.crew_move(u, home, crew.crew_peers())
		await Session.crew_guests_gone(CREW_LET_GO_SECONDS)
		for p: Player in _players.get_children():   # nobody waits here for them: a guest that joins again this
			if p.peer_id != multiplayer.get_unique_id():   # moment gets no old body of its own from this world
				p.queue_free()
		WorldService.stop_viewers(self)   # the world stops streaming and its queue drains first (as a guest's rejoin
		process_mode = Node.PROCESS_MODE_DISABLED   # does): no voxel task finishes into a world already gone
		await WorldService.drain(get_tree(), Session.RELOAD_DRAIN_SECONDS)
		return true
	Session.close()
	return false


## Host: its world moved here with a crew: the online match's INVITE row as before (no new match).
func _crew_keep_online() -> void:
	var id := Session.online_hosted_match()
	if id == "":
		return
	pause_menu.online = Session.online_service()
	pause_menu.online_match = id
	pause_menu.online_world = OnlineRules.world_name(Game.mode)
	_setup_online_hud()


## Host's HOME with friends here: the same trip home (travel_through_gate's way), and they follow.
func _crew_home(home: int) -> String:
	if _quitting:
		return ""
	var why := UniverseRules.travel_refusal(home, Profile.data.universe_unlocked, UniverseRegistry.available(), 0,
		Game.universe)
	if why != "":
		return UniverseRules.travel_message(why)
	if Game.mode == ModeRules.SURVIVOR:
		_travel.call_deferred(home, true)
	else:
		_travel_sandbox.call_deferred(home)
	return ""


## A guest's HOME (the brief's item 5): it leaves the crew alone and kindly, for its own home world.
func _crew_guest_home() -> String:
	if _quitting:
		return ""
	_quitting = true
	WorldService.stop_viewers(self)
	process_mode = Node.PROCESS_MODE_DISABLED   # (nothing here looks for its viewer again)
	net_overlay.goodbye(tr(CrewFlightRules.GUEST_HOME) % CrewFlightRules.place(Game.universe))
	var mode := Game.mode
	print("CREW a guest flies home on its own")
	get_tree().create_timer(NetOverlay.GOODBYE_SECONDS).timeout.connect(func() -> void:
		Session.close()
		Game.start_world(mode, false, DifficultyRules.NORMAL, UniverseRules.FIRST))
	return ""


## Guest: the host's world moves to u (a landing, or HOME with `home`): the landing's words, the postcard and the guide
## for everyone; this world lets go of its link, drains, and a fresh guest scene joins the same match or LAN host again,
## into the host's new world (no menu, no invite, no code).
func _crew_follow(u: int, home: bool) -> void:
	if _quitting:
		return
	_quitting = true
	Session.crew_follow_leave()
	if not home and MissionRules.has_mission(u):
		SpaceDirector.landing = u
		mission_landing = u
		if int(FlightTicket.parked.get("destination", 0)) != u and not crew.rocket.is_empty():
			FlightTicket.parked = {"destination": u, "cells": RocketStages.lander(RocketStages.normalize(crew.rocket))}
	print("CREW follow to %d (%s)" % [u, "home" if home else "landing"])
	WorldService.stop_viewers(self)
	process_mode = Node.PROCESS_MODE_DISABLED   # (nothing here looks for its viewer again; the cards keep going)
	await WorldService.drain(get_tree(), Session.RELOAD_DRAIN_SECONDS)
	print("CREW joining the host's world %d again at %d ms" % [u, Time.get_ticks_msec()])
	Game.universe = u
	Game.join_lan_game(Game.join_address)
