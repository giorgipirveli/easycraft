extends GutTest
## Owner feedback #40: the new commands run (ChatCommandRunner) in solo play, where this game is the host
## (peer 1): host commands through run_host (Session already checked them), local ones through run.
## Fakes stand in for the sandbox's parts; lines for this player arrive on Session.chat_received.

var lines: Array = []
var _mode_before: StringName
var _universe_before := 1


## Stone up to y = 9, air above (the Physics Lab test's floor).
class FlatWorld:
	extends WorldService

	func get_block(p: Vector3i) -> int:
		return BlockIds.STONE if p.y <= 9 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


class FakeSky:
	extends RefCounted
	var running := true


class FakePhoto:
	extends RefCounted
	var opened := 0

	func open() -> void:
		opened += 1


class FakeSandbox:
	extends Node3D
	var player: Player
	var world: WorldService
	var hud: Control
	var sky := FakeSky.new()
	var photo := FakePhoto.new()
	var pause_menu: PauseMenu
	var meta := WorldMeta.new()
	var client := false
	var saves := 0
	var travelled: Array = []
	var travel_reply := ""
	var bosses: Array = []
	var launch_site: LaunchDirector   # owner #98: /find launch

	func is_client() -> bool:
		return client

	func save_world() -> void:
		saves += 1

	func travel_to(u: int) -> String:
		travelled.append(u)
		return travel_reply

	func summon_boss(near: Vector3, kind: StringName = &"") -> String:
		bosses.append([near, kind])
		return ""


class FakeBot:
	extends RefCounted
	var bot_name := ""

	func _init(n: String) -> void:
		bot_name = n


class FakeDirector:
	extends Node
	var friends: Array = []
	var added: Array = []
	var removed: Array = []
	var full := false

	func bots() -> Array:
		return friends

	func add(personality: StringName) -> Object:
		if full:
			return null
		added.append(personality)
		var b := FakeBot.new("Pip")
		friends.append(b)
		return b

	func remove(bot_name: String) -> bool:
		for b: FakeBot in friends:
			if b.bot_name == bot_name:
				friends.erase(b)
				removed.append(bot_name)
				return true
		return false


func before_each() -> void:
	lines.clear()
	_mode_before = Game.mode
	_universe_before = Game.universe
	Game.mode = ModeRules.SANDBOX
	Session.chat_reset()
	Session.commands_enabled = true
	Session._last_emote.clear()   # an emote from another test file must not hold ours back
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.chat_received.disconnect(_on_line)
	Session.chat_reset()
	Session.survivor_reset()
	Session.command_state_reset()
	Session.commands_enabled = true
	Game.mode = _mode_before
	Game.universe = _universe_before


func _on_line(_from: String, text: String, kind: StringName) -> void:
	lines.append({"text": text, "kind": kind})


func _last() -> String:
	return str(lines.back().text) if not lines.is_empty() else ""


func _me() -> int:
	return multiplayer.get_unique_id()


## This game's player in a fake sandbox, standing still at `at` and looking along -Z.
func _world(at: Vector3 = Vector3(3, 20, -4)) -> Array:
	var fake := FakeSandbox.new()
	add_child_autofree(fake)
	fake.world = FlatWorld.new()
	fake.add_child(fake.world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(_me())
	p.world = fake.world
	fake.add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = at
	p.rig.yaw = 0.0
	fake.player = p
	fake.hud = Control.new()
	fake.add_child(fake.hud)
	var runner := ChatCommandRunner.new()
	runner.sandbox = fake
	add_child_autofree(runner)
	return [runner, fake, p]


# --- Host commands ----------------------------------------------------------------------------

func test_heal_fills_the_hearts() -> void:
	var w := _world()
	var p: Player = w[2]
	p.health.hp = 5
	(w[0] as ChatCommandRunner).run_host(_me(), ChatCommands.parse("/heal"))
	assert_eq(p.health.hp, Health.MAX_HP)
	assert_string_contains(_last(), "hearts")
	(w[0] as ChatCommandRunner).run_host(_me(), ChatCommands.parse("/heal"))
	assert_string_contains(_last(), "full already")
	p.health.hp = 0
	(w[0] as ChatCommandRunner).run_host(_me(), ChatCommands.parse("/heal"))
	assert_eq(p.health.hp, 0, "a knock-out is not skipped")


func test_clearbag_asks_twice_then_empties_the_bag() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var t := [100.0]
	runner.clock = func() -> float: return t[0]
	var inv := Inventory.new()
	inv.add(BlockIds.PLANKS, 10)
	inv.add(ItemIds.SWORD, 1)
	Session.set_inventory(_me(), inv)
	runner.run_host(_me(), ChatCommands.parse("/clearbag"))
	assert_eq(inv.count(BlockIds.PLANKS), 10, "the first one only asks")
	assert_string_contains(_last(), "/clearbag again")
	t[0] = 100.0 + ChatCommands.CLEARBAG_SECONDS + 1.0
	runner.run_host(_me(), ChatCommands.parse("/clearbag"))
	assert_eq(inv.count(BlockIds.PLANKS), 10, "too late: it asks again")
	t[0] += 3.0
	runner.run_host(_me(), ChatCommands.parse("/clearbag"))
	assert_eq(inv.ids().size(), 0, "the second one in time empties it")
	assert_string_contains(_last(), "empty")


func test_freeze_stops_the_clock_for_everyone() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run_host(_me(), ChatCommands.parse("/freeze"))
	assert_true(Session.clock_frozen)
	assert_false(fake.sky.running, "the sky's clock stops")
	assert_string_contains(_last(), "clock")
	runner.run_host(_me(), ChatCommands.parse("/freeze on"))
	assert_false(fake.sky.running, "on stays on")
	runner.run_host(_me(), ChatCommands.parse("/freeze"))
	assert_false(Session.clock_frozen, "/freeze alone switches it back")
	assert_true(fake.sky.running)


func test_a_guest_follows_the_hosts_clock_and_command_switch() -> void:
	var w := _world()
	var fake: FakeSandbox = w[1]
	watch_signals(Session)
	Session._rpc_command_state(true, false)   # what the host sends a guest
	assert_signal_emitted(Session, "clock_frozen_changed")
	assert_false(fake.sky.running)
	assert_false(Session.commands_enabled, "the host's command switch")
	assert_eq(ChatCommands.refusal(&"fly", Session.commands_enabled, Game.mode), ChatCommands.OFF_MESSAGE)


func test_peace_uses_the_monsters_switch() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	fake.pause_menu = PauseMenu.new()
	var toggled: Array = []
	fake.pause_menu.monsters_toggled.connect(func(on: bool) -> void:
		toggled.append(on)
		fake.meta.monsters_on = on)   # the sandbox's own handler does this (and puffs them away)
	runner.run_host(_me(), ChatCommands.parse("/peace"))
	assert_eq(toggled, [false], "monsters off")
	assert_string_contains(_last(), "monsters")
	runner.run_host(_me(), ChatCommands.parse("/peace off"))
	assert_eq(toggled, [false, true], "monsters back")
	runner.run_host(_me(), ChatCommands.parse("/peace off"))
	assert_eq(toggled, [false, true], "already off: nothing to switch")
	fake.pause_menu.free()


func test_weather_brings_what_the_universe_has() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run_host(_me(), ChatCommands.parse("/weather sandstorm"))
	assert_eq(lines.back().kind, &"error", "no sandstorms in Green Meadows")
	var storm := SandstormDirector.new()
	storm.name = "Sandstorm"
	fake.add_child(storm)
	storm.set_process(false)
	runner.run_host(_me(), ChatCommands.parse("/weather sandstorm"))
	assert_true(storm.on)
	assert_string_contains(_last(), "sandstorm")
	runner.run_host(_me(), ChatCommands.parse("/weather clear"))
	assert_false(storm.on)
	runner.run_host(_me(), ChatCommands.parse("/weather snow"))
	assert_eq(lines.back().kind, &"error", "no snow in the desert")
	runner.run_host(_me(), ChatCommands.parse("/weather rain"))
	assert_eq(lines.back().kind, &"error", "no rain yet")


func test_pet_calls_your_pets_only() -> void:
	var w := _world(Vector3(0, 40, 0))
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run_host(_me(), ChatCommands.parse("/pet"))
	assert_string_contains(_last(), "no pets")
	var animals := Node3D.new()
	animals.name = "Animals"
	fake.add_child(animals)
	var mine := Animal.new()
	mine.setup({"species": &"dog", "id": "p1", "pos": Vector3(60, 40, 0), "yaw": 0.0, "owner": _me(),
		"name": "Biscuit", "sitting": true})
	animals.add_child(mine)
	var wild := Animal.new()
	wild.setup({"species": &"cat", "id": "w1", "pos": Vector3(60, 40, 5), "yaw": 0.0, "owner": 0, "name": "",
		"sitting": false})
	animals.add_child(wild)
	for a: Animal in [mine, wild]:
		a.set_physics_process(false)
		a.set_process(false)
	runner.run_host(_me(), ChatCommands.parse("/pet"))
	assert_false(mine.sitting, "it stands up")
	assert_lt(mine.global_position.distance_to(Vector3(0, 40, 0)), ChatCommandRunner.PET_CALL_NEAR, "a far pet pops next to you")
	assert_eq(wild.global_position, Vector3(60, 40, 5), "a wild animal stays")
	assert_eq(_last(), "Biscuit is coming!")


func test_boss_calls_this_universes_boss() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	Game.universe = 2
	runner.run_host(_me(), ChatCommands.parse("/boss"))
	assert_eq(fake.bosses.size(), 1)
	assert_eq(fake.bosses[0][1], UniverseRegistry.boss_kind(2), "the Sand Serpent")


# --- Local commands ---------------------------------------------------------------------------

func test_give_with_a_count_and_the_kit() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var p: Player = w[2]
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	runner.run("/give planks 64")
	assert_eq(interactor.selected_block(), BlockIds.PLANKS)
	assert_eq(_last(), "You got 64 Planks!")
	runner.run("/kit")
	assert_eq(interactor.hotbar, ChatCommands.KIT)
	Game.mode = ModeRules.SURVIVOR
	runner.run("/kit")
	assert_eq(_last(), ChatCommands.SANDBOX_ONLY_MESSAGE)


func test_gravity_and_speed_are_the_labs_modes() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var p: Player = w[2]
	runner.run("/gravity moon")
	assert_eq(p.lab_mode, LabRules.Mode.MOON)
	runner.run("/gravity zero")
	assert_eq(p.lab_mode, LabRules.Mode.ZERO_G)
	runner.run("/gravity normal")
	assert_eq(p.lab_mode, LabRules.Mode.NORMAL)
	runner.run("/speed 1")
	assert_eq(p.lab_mode, LabRules.Mode.SLOW)
	runner.run("/speed 2")
	assert_eq(p.lab_mode, LabRules.Mode.NORMAL)
	runner.run("/speed 3")
	assert_true(p.potions.is_active(ItemIds.POTION_SPEED), "the Speed potion's 1.5×")


func test_build_sends_one_stamp_batch_ahead() -> void:
	var w := _world(Vector3(10.3, 64.0, -5.7))
	var runner: ChatCommandRunner = w[0]
	var sent: Array = []
	runner.place_edits = func(edits: Array) -> bool:
		sent.append(edits)
		return true
	runner.run("/build tower")
	assert_eq(sent.size(), 1, "one batch: one undo")
	var anchor := ChatCommands.build_anchor(Vector3(10.3, 64.0, -5.7), Vector3i(0, 0, -1))
	assert_eq(sent[0], Blueprints.place(ItemIds.STAMP_TOWER, anchor, Vector3i(0, 0, -1)))
	assert_string_contains(_last(), "UNDO")


func test_dance_plays_only_what_you_own() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	runner.owned = func() -> Array: return []
	watch_signals(Session)
	runner.run("/dance robot")
	assert_signal_emitted(Session, "emote_played")
	assert_eq(get_signal_parameters(Session, "emote_played")[1], &"dance_robot")
	runner.run("/dance star")
	assert_eq(lines.back().kind, &"error")
	assert_string_contains(_last(), "Star Spin")
	runner.run("/emote bow")
	assert_eq(lines.back().kind, &"error", "the Bow is bought")


func test_bot_add_and_remove_ask_the_hosts_friends() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var director := FakeDirector.new()
	director.add_to_group(&"bot_director")
	add_child_autofree(director)
	runner.run("/bot add fighter")
	assert_eq(director.added, [BotRules.FIGHTER])
	runner.run("/bot add")
	assert_true(BotRules.PERSONALITIES.has(director.added[1]), "any friend")
	director.friends = [FakeBot.new("Pip"), FakeBot.new("Bolt")]
	runner.run("/bot remove")
	assert_eq(director.removed, [], "which one?")
	assert_string_contains(_last(), "/bot remove")
	runner.run("/bot remove bo")
	assert_eq(director.removed, ["Bolt"], "a unique start of the name")
	director.full = true
	runner.run("/bot add")
	assert_string_contains(_last(), str(BotRules.MAX_BOTS))


func test_a_guest_has_no_bot_friends_to_add() -> void:
	var w := _world()
	(w[1] as FakeSandbox).client = true
	(w[0] as ChatCommandRunner).run("/bot add")
	assert_string_contains(_last(), "host")


func test_universe_travels_through_the_sandbox() -> void:
	Game.mode = ModeRules.SURVIVOR
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run("/universe desert")
	assert_eq(fake.travelled, [2])
	assert_string_contains(_last(), UniverseRegistry.display_name(2))
	fake.travel_reply = UniverseRules.travel_message("friends")
	runner.run("/universe 3")
	assert_eq(_last(), UniverseRules.travel_message("friends"), "the hub's own answer")
	Game.mode = ModeRules.SANDBOX
	runner.run("/universe 2")
	assert_eq(_last(), ChatCommands.ONE_WORLD_MESSAGE)


func test_save_and_photo() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run("/save")
	assert_eq(fake.saves, 1)
	assert_string_contains(_last(), "Saved")
	runner.run("/photo")
	assert_eq(fake.photo.opened, 1)
	fake.client = true
	runner.run("/save")
	assert_eq(fake.saves, 1, "a guest's world is the host's")
	assert_string_contains(_last(), "host")


func test_heavy_local_commands_are_rate_limited() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	for i in ChatRules.RATE_COUNT + 1:
		runner.run("/save")
	assert_eq(fake.saves, ChatRules.RATE_COUNT)
	assert_eq(_last(), ChatRules.message("too_fast"))


func test_find_shows_the_way() -> void:
	var w := _world(Vector3(0, 64, 0))
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run("/find tilly")
	assert_eq(_last(), ChatCommands.find_missing(&"tilly", ModeRules.SANDBOX))
	var traders := Node3D.new()
	traders.name = "Traders"
	fake.add_child(traders)
	var tilly := Node3D.new()
	traders.add_child(tilly)
	tilly.global_position = Vector3(0, 64, -42)
	runner.run("/find tilly")
	assert_string_contains(_last(), "42 blocks")
	assert_string_contains(_last(), "ahead")
	assert_not_null(runner.find_arrow)
	assert_true(runner.find_arrow.is_pointing())
	assert_eq(runner.find_arrow.target, Vector3(0, 64, -42))
	var p: Player = w[2]
	p.has_home = true
	p.home_bed = Vector3i(20, 64, 0)
	runner.run("/find home")
	assert_string_contains(_last(), "right")
	Game.mode = ModeRules.SURVIVOR
	runner.run("/find treasure")
	assert_eq(_last(), ChatCommands.NO_MAP_MESSAGE)


## Owner #98: /find launch points at the Mission Board of this home world's Launch Site.
func test_find_launch_points_at_the_mission_board() -> void:
	var w := _world(Vector3(0, 64, 0))
	var runner: ChatCommandRunner = w[0]
	var fake: FakeSandbox = w[1]
	runner.run("/find launch")
	assert_eq(_last(), ChatCommands.find_missing(&"launch", ModeRules.SANDBOX), "no Launch Site in this world")
	fake.launch_site = LaunchDirector.new()
	fake.add_child(fake.launch_site)
	fake.launch_site.site = {"pos": Vector3i(10, 63, -30), "facing": 0}
	runner.run("/find launch")
	assert_string_contains(_last(), "The Launch Site is ")
	assert_true(runner.find_arrow.is_pointing())
	assert_eq(runner.find_arrow.target, LaunchSite.board_position(fake.launch_site.site))


func test_music_off_on_and_what_comes_later() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var stored: Array = []
	runner.store_setting = func(key: String, value: Variant) -> void: stored.append([key, value])
	var before: Variant = Profile.data.settings.music_volume
	runner.run("/music off")
	assert_eq(stored, [["music_volume", 0.0]])
	Profile.data.settings.music_volume = 0.0
	runner.run("/music on")
	assert_eq(stored[1], ["music_volume", ChatCommandRunner.MUSIC_ON_VOLUME], "music comes back")
	Profile.data.settings.music_volume = before
	stored.clear()
	runner.run("/music classical")   # the audio pass's MUSIC setting (settings.music_style)
	assert_eq(stored, [["music_style", String(MusicPlan.CLASSICAL)]])
	runner.run("/music game")
	assert_eq(stored[1], ["music_style", String(MusicPlan.GAME)])


## M7: in a browser before the music pack is in there is no piece to skip to yet: say it is coming, not "Try /music
## classical!" to a child who chose classical already.
func test_music_next_says_more_music_is_coming_before_the_web_music_pack() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	MusicPieces.exists_check = func(path: String) -> bool: return not path.begins_with(MusicPieces.DIR)
	runner.run("/music next")
	MusicPieces.exists_check = Callable()
	assert_eq(_last(), ChatCommandRunner.NEXT_COMING)


## M7: in a browser before the realistic pack is in, /style realistic keeps the choice and says the pictures are coming
## (the world keeps the pixel pictures until then), never "The world looks realistic now."
func test_style_realistic_says_the_pictures_are_coming_before_the_web_realistic_pack() -> void:
	var w := _world()
	var runner: ChatCommandRunner = w[0]
	var stored: Array = []
	runner.store_setting = func(key: String, value: Variant) -> void: stored.append([key, value])
	RealisticPack.exists_check = func(path: String) -> bool: return not path in RealisticPack.files()
	runner.run("/style realistic")
	RealisticPack.exists_check = Callable()
	assert_eq(stored, [["style", "realistic"]], "the choice is kept")
	assert_eq(_last(), ChatCommandRunner.STYLE_COMING)
	runner.run("/style realistic")
	assert_eq(_last(), "The world looks realistic now.", "with the pictures here")


func test_xp_and_level_tell_the_progress() -> void:
	var w := _world()
	(w[0] as ChatCommandRunner).run("/xp")
	assert_eq(_last(), ChatCommands.xp_words(Progress.data()))
	(w[0] as ChatCommandRunner).run("/level")
	assert_eq(_last(), ChatCommands.level_words(Progress.data()))
