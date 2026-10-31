extends GutTest
## M3 Task 12: the progress event bus (the Progress autoload, one entry point `event(kind, amount)`) and
## Session's section for it. Each player's own game counts its own events; the host tells a guest about
## the events it decides (a monster beaten near the guest, blocks the guest placed); Survivor gold for a
## board goal or a present goes through the host's gold path, which checks it.

const NEAR := Vector3i(2, 10, 0)
const ME_AT := Vector3(0.5, 10.0, 4.5)


## Stands in for the terrain: a dictionary of cells, all loaded.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 0


## A network peer that is always connected and sends its packets nowhere (it notes who they were for).
class FakePeer:
	extends MultiplayerPeerExtension
	var id := 2
	var server := false
	var sent_to: Array[int] = []
	var _target := 0

	func _get_unique_id() -> int:
		return id

	func _is_server() -> bool:
		return server

	func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
		return MultiplayerPeer.CONNECTION_CONNECTED

	func _put_packet_script(_buffer: PackedByteArray) -> Error:
		sent_to.append(_target)
		return OK

	func _get_packet_script() -> PackedByteArray:
		return PackedByteArray()

	func _get_available_packet_count() -> int:
		return 0

	func _get_max_packet_size() -> int:
		return 1 << 20

	func _set_target_peer(peer: int) -> void:
		_target = peer

	func _get_packet_peer() -> int:
		return 1

	func _get_packet_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE

	func _get_packet_channel() -> int:
		return 0

	func _set_transfer_channel(_channel: int) -> void:
		pass

	func _get_transfer_channel() -> int:
		return 0

	func _set_transfer_mode(_mode: MultiplayerPeer.TransferMode) -> void:
		pass

	func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE

	func _poll() -> void:
		pass

	func _close() -> void:
		pass

	func _disconnect_peer(_peer: int, _force: bool) -> void:
		pass


var d: ProgressData
var asked_gold: Array = []
var asked_presents: Array = []
var survivor := [false]
var _saved := {}
var _mode: StringName


func before_each() -> void:
	_saved = {"survivor": Progress.survivor, "ask_goal_gold": Progress.ask_goal_gold, "ask_present": Progress.ask_present}
	_mode = Game.mode
	d = ProgressData.new()
	asked_gold = []
	asked_presents = []
	survivor[0] = false
	Progress.begin(d)
	Progress.survivor = func() -> bool: return survivor[0]
	Progress.ask_goal_gold = func(goal_id: StringName) -> void: asked_gold.append(goal_id)
	Progress.ask_present = func(gift_id: StringName) -> void: asked_presents.append(gift_id)


func after_each() -> void:
	Progress.end()
	for key: String in _saved:
		Progress.set(key, _saved[key])
	Game.mode = _mode
	Session.progress_reset()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)


# --- The bus -------------------------------------------------------------------------------------------

func test_nothing_counts_unless_a_world_is_being_played() -> void:
	var real := Profile.data.progress
	Profile.data.progress = d
	Progress.end()
	Progress.event(&"photo_taken")
	Profile.data.progress = real
	assert_eq(d.xp, 0, "tests and menus never touch the player's progress")
	Progress.begin(d)
	Progress.event(&"photo_taken")
	assert_eq(d.count(&"photo_taken"), 1)
	assert_eq(d.xp, 5 + 50, "the photo, and the starter goal \"Take a photo\"")


func test_an_event_counts_and_levels_up_once() -> void:
	watch_signals(Progress)
	Progress.event(&"boss_beaten/golem")
	assert_eq(d.count(&"boss_beaten"), 1)
	assert_signal_emit_count(Progress, "leveled_up", 1)
	assert_signal_emitted_with_parameters(Progress, "leveled_up", [2])
	Progress.event(&"photo_taken")
	assert_signal_emit_count(Progress, "leveled_up", 1, "no level-up without a new level")
	assert_signal_emitted(Progress, "changed")


func test_unknown_kinds_are_ignored() -> void:
	watch_signals(Progress)
	Progress.event(&"logged_in")
	Progress.event(&"photo_taken", -2)
	assert_eq(d.xp, 0)
	assert_signal_not_emitted(Progress, "changed")


func test_a_goal_done_in_survivor_asks_the_host_for_its_gold_and_gives_a_sticker() -> void:
	survivor[0] = true
	BoardRules.ensure_board(d)
	assert_true(Progress.pick_goal(2, &"find_geode"))
	watch_signals(Progress)
	Progress.event(&"secret_found/geode")
	assert_signal_emitted_with_parameters(Progress, "goal_done", [&"find_geode", 60])
	assert_eq(asked_gold, [&"find_geode"])
	assert_eq(int(d.stickers.get("find_geode", 0)), 1)
	assert_eq(d.count(&"goal_done"), 1)
	assert_eq(d.xp, 25 + 50, "the secret and the goal")
	Progress.event(&"secret_found/geode")
	assert_eq(asked_gold.size(), 1, "a goal pays once")


func test_a_goal_done_in_sandbox_gives_a_sticker_only() -> void:
	BoardRules.ensure_board(d)
	Progress.pick_goal(0, &"tame_dog")
	watch_signals(Progress)
	Progress.event(&"animal_tamed/dog")
	assert_signal_emitted_with_parameters(Progress, "goal_done", [&"tame_dog", 0])
	assert_eq(asked_gold, [])
	assert_eq(int(d.stickers.get("tame_dog", 0)), 1)


func test_a_creative_goal_never_asks_for_gold() -> void:
	survivor[0] = true
	BoardRules.ensure_board(d)
	Progress.event(&"photo_taken")
	assert_true(d.board[0].done, "the starter photo goal")
	assert_eq(asked_gold, [], "its own reward: a sticker")
	assert_eq(int(d.stickers.get("take_photo", 0)), 1)


func test_badges_unlock_once_with_a_signal() -> void:
	watch_signals(Progress)
	Progress.event(&"animal_tamed/dog")
	Progress.event(&"animal_tamed/cat")
	assert_signal_emit_count(Progress, "badge_unlocked", 1)
	assert_signal_emitted_with_parameters(Progress, "badge_unlocked", [&"first_pet"])
	assert_eq(d.achievements, ["first_pet"] as Array[String])


func test_a_level_badge_comes_with_the_level() -> void:
	watch_signals(Progress)
	d.xp = LevelRules.xp_to_reach(5) - 5
	Progress.event(&"photo_taken")
	assert_has(d.achievements, "level_5")
	assert_signal_emitted_with_parameters(Progress, "leveled_up", [5])


func test_the_board_is_ready_once_counting_begins() -> void:
	var fresh := ProgressData.new()
	Progress.begin(fresh)
	assert_eq(fresh.board[0].goal, String(BoardRules.STARTERS[0]), "starter goals on a new board")


func test_a_title_can_be_chosen_only_when_earned() -> void:
	d.style_xp = {"builder": 200, "photo": 60}
	assert_eq(Progress.shown_title(), &"builder")
	assert_false(Progress.choose_title(&"boss"))
	assert_true(Progress.choose_title(&"photo"))
	assert_eq(Progress.shown_title(), &"photo")
	assert_true(Progress.choose_title(&""), "back to the style played most")
	assert_eq(Progress.shown_title(), &"builder")


func test_the_name_tag_code() -> void:
	assert_eq(Progress.tag(), "1:")
	Progress.event(&"block_placed", 5)
	d.style_xp = {"builder": 120}
	d.xp = 120
	assert_eq(Progress.tag(), "2:builder")


func test_a_present_comes_with_a_signal_and_waits() -> void:
	watch_signals(Progress)
	for i in int(PresentRules.interval_s(0)) + 5:
		Progress.present_tick(1.0, true, true)
	assert_signal_emit_count(Progress, "present_ready", 1)
	assert_true(d.present_waiting)


func test_opening_a_sandbox_present_gives_a_sticker() -> void:
	d.present_waiting = true
	watch_signals(Progress)
	assert_false(Progress.open_present(&"gold"), "not on Sandbox's list")
	assert_true(Progress.open_present(&"gift_heart"))
	assert_eq(int(d.stickers.get("gift_heart", 0)), 1)
	assert_eq(asked_presents, [])
	assert_signal_emitted_with_parameters(Progress, "present_opened", [&"gift_heart"])
	assert_false(Progress.open_present(&"gift_heart"), "one present, one gift")


func test_opening_a_survivor_present_asks_the_host() -> void:
	survivor[0] = true
	d.present_waiting = true
	assert_true(Progress.open_present(&"lanterns"))
	assert_eq(asked_presents, [&"lanterns"])
	assert_false(d.present_waiting)


# --- Session: host and guests -----------------------------------------------------------------------

func _host_peer() -> FakePeer:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(2)
	peer.peer_connected.emit(3)
	return peer


func _world() -> EditWorld:
	var w := EditWorld.new()
	add_child_autofree(w)
	Session.register_world(w)
	return w


func _player(peer: int, feet: Vector3, world: WorldService) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.global_position = feet
	p._spawned = true
	return p


func test_solo_the_hosts_own_placements_count() -> void:
	var w := _world()
	var me := _player(multiplayer.get_unique_id(), ME_AT, w)
	assert_true(Session._host_apply(multiplayer.get_unique_id(), NEAR, BlockIds.STONE))
	assert_eq(d.count(&"block_placed"), 1)
	assert_true(Session._host_apply(multiplayer.get_unique_id(), NEAR, BlockIds.AIR))
	assert_eq(d.count(&"block_placed"), 1, "breaking is not placing")
	Session._host_apply_batch(multiplayer.get_unique_id(), [[NEAR, BlockIds.BRICK], [NEAR + Vector3i.UP, BlockIds.BRICK]])
	assert_eq(d.count(&"block_placed"), 3)
	Session._host_apply_batch(multiplayer.get_unique_id(), [[NEAR, BlockIds.AIR], [NEAR + Vector3i.UP, BlockIds.AIR]], true)
	Session._host_apply_batch(multiplayer.get_unique_id(), [[NEAR, BlockIds.BRICK]], true)
	assert_eq(d.count(&"block_placed"), 3, "an undo never counts")
	me.global_position = ME_AT + Vector3(0, 0, 60)   # too far to undo: the host sends the cell back for later
	assert_false(Session._host_apply(multiplayer.get_unique_id(), NEAR, BlockIds.AIR, true))
	assert_eq(d.count(&"block_placed"), 3, "an undo kept for later is not a new block")


func test_what_counts_as_placing() -> void:
	var p := Vector3i(1, 2, 3)
	assert_eq(Session.progress_placed_count([[p, BlockIds.AIR, BlockIds.STONE]]), 1)
	assert_eq(Session.progress_placed_count([[p, BlockIds.WATER, BlockIds.GLASS]]), 1, "into water")
	assert_eq(Session.progress_placed_count([[p, BlockIds.STONE, BlockIds.AIR]]), 0, "a break")
	assert_eq(Session.progress_placed_count([[p, BlockIds.STONE, BlockIds.BRICK]]), 0, "a swap is not a new block")
	assert_eq(Session.progress_placed_count([[p, BlockIds.AIR], "x", [p, "a", 3], [], [p, BlockIds.AIR, BlockIds.DIRT]]), 1)


func test_the_host_tells_a_guest_and_only_that_guest() -> void:
	var peer := _host_peer()
	peer.sent_to.clear()
	Session.progress_tell(2, &"animal_tamed/dog")
	assert_true(peer.sent_to.size() > 0 and peer.sent_to.all(func(t: int) -> bool: return t == 2), "to guest 2 only")
	assert_eq(d.xp, 0, "not counted on the host's own progress")
	peer.sent_to.clear()
	Session.progress_tell(2, &"cheat_code")
	Session.progress_tell(9, &"photo_taken")
	assert_eq(peer.sent_to, [] as Array[int], "unknown kinds and players are never sent")
	Session.progress_tell(1, &"photo_taken")
	assert_eq(d.count(&"photo_taken"), 1, "the host's own event counts here")


func test_a_guest_counts_what_the_host_tells_it() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	Session._rpc_progress("monster_defeated/slime", 1)
	assert_eq(d.count(&"monster_defeated/slime"), 1)
	Session._rpc_progress("gold_please", 1)
	Session._rpc_progress("monster_defeated", -4)
	Session._rpc_progress("monster_defeated", 99999999)
	assert_eq(d.count(&"monster_defeated"), 1 + LevelRules.MAX_AMOUNT, "bad kinds ignored, amounts clamped")


func test_a_monster_beaten_counts_for_the_players_near_it() -> void:
	var peer := _host_peer()
	var w := _world()
	_player(1, Vector3(0, 10, 0), w)
	_player(2, Vector3(10, 10, 0), w)
	_player(3, Vector3(200, 10, 0), w)
	peer.sent_to.clear()
	Session.progress_near(Vector3(5, 10, 0), &"monster_defeated/goblin")
	assert_eq(d.count(&"monster_defeated/goblin"), 1, "the host's player was near")
	assert_has(peer.sent_to, 2)
	assert_does_not_have(peer.sent_to, 3, "too far away")


func test_the_host_pays_a_guests_goal_now_and_then() -> void:
	_host_peer()
	Game.mode = ModeRules.SURVIVOR
	var before := Session.gold_of(2)
	assert_true(Session.progress_host_goal_gold(2, &"find_geode"))
	assert_eq(Session.gold_of(2), before + 60)
	assert_false(Session.progress_host_goal_gold(2, &"find_geode"), "a flood of claims is refused")
	assert_eq(Session.gold_of(2), before + 60)
	assert_false(Session.progress_host_goal_gold(3, &"take_photo"), "creative goals pay no gold")
	assert_false(Session.progress_host_goal_gold(3, &"made_up"))
	Game.mode = ModeRules.SANDBOX
	assert_false(Session.progress_host_goal_gold(3, &"find_geode"), "Sandbox gold is endless")


func test_the_host_gives_a_guest_its_present_now_and_then() -> void:
	_host_peer()
	Game.mode = ModeRules.SURVIVOR
	var inv := Session.inventory_of(3)
	var lanterns := inv.count(BlockIds.LANTERN)
	assert_true(Session.progress_host_present(3, &"lanterns"))
	assert_eq(inv.count(BlockIds.LANTERN), lanterns + 2)
	assert_false(Session.progress_host_present(3, &"lanterns"), "one present every few minutes")
	assert_false(Session.progress_host_present(2, &"gift_star"), "not a Survivor gift")
	var gold := Session.gold_of(2)
	assert_true(Session.progress_host_present(2, &"gold"), "a refused gift used up nothing")
	assert_eq(Session.gold_of(2), gold + 15)
