extends GutTest
## M2 Task 8 (spec §12.6): doors. A tap on a door asks the host to open or close it
## (Session.request_door): the host checks reach and that nobody (a player, a bot friend or a monster)
## stands in a door it would close, then changes the whole stack of doors like any edit: one undo
## step, nothing counted in Survivor (the door comes back and is used again). A LAN guest only asks.
## Solo play (this game is the host) through Session and the player's BlockInteractor, as in the
## real game; LAN with a fake network peer whose packets go nowhere.

const DOOR := Vector3i(2, 10, 0)
const TOP := Vector3i(2, 11, 0)
const ME_AT := Vector3(0.5, 10.0, 4.5)   # the doorway is well within reach from here


## Stands in for the terrain: a dictionary of cells, all loaded.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


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


## Stands in for a bot friend that is up (group bots) or anything else standing somewhere.
class Stander:
	extends Node3D


var world: EditWorld
var me: Player
var interactor: BlockInteractor
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[DOOR] = BlockIds.DOOR
	world.cells[TOP] = BlockIds.DOOR
	Session.register_world(world)
	me = _player(multiplayer.get_unique_id(), ME_AT)
	interactor = me.get_node("BlockInteractor")


func after_each() -> void:
	Game.mode = _mode_before
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


## A player body for `peer` with its feet at `feet`. Other players count as bodies in the host's checks.
func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	if peer != multiplayer.get_unique_id():
		p._spawned = true
	return p


func _doorway() -> Array:
	return [world.get_block(DOOR), world.get_block(TOP)]


# --- Opening and closing through the host -------------------------------------------------------------

func test_a_request_opens_the_whole_doorway() -> void:
	assert_true(Session.request_door(TOP))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN])


func test_asking_again_closes_it() -> void:
	Session.request_door(DOOR)
	assert_true(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR, BlockIds.DOOR])


func test_opening_is_one_undo_step() -> void:
	Session.request_door(DOOR)
	assert_eq(interactor.undo_size(), 1)
	assert_true(interactor.undo())
	assert_eq(_doorway(), [BlockIds.DOOR, BlockIds.DOOR], "undo closes it again")


func test_a_door_too_far_away_stays_as_it_is() -> void:
	me.global_position = ME_AT + Vector3(0, 0, 30)
	watch_signals(Session)
	assert_false(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR, BlockIds.DOOR])
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [PlacementRules.TOO_FAR_MESSAGE])


func test_it_never_closes_on_someone_in_the_doorway() -> void:
	Session.request_door(DOOR)
	_player(5, Vector3(2.5, 10.0, 0.5))
	watch_signals(Session)
	assert_false(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN], "nothing closes, not even the top")
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [PlacementRules.BODY_MESSAGE])


func test_it_never_closes_on_a_monster_in_the_doorway() -> void:
	Session.request_door(DOOR)
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "door_goblin", "pos": Vector3(2.5, 10.0, 0.4), "yaw": 0.0})
	m.block_at = world.get_block
	add_child_autofree(m)
	m.set_physics_process(false)
	watch_signals(Session)
	assert_false(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN], "it would stand inside a closed door")
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [Session.DOOR_MONSTER_MESSAGE])
	m.global_position = Vector3(2.5, 10.0, -3.0)
	assert_true(Session.request_door(DOOR), "once it is out of the way")


func test_a_bot_friend_in_the_doorway_stops_it_closing() -> void:
	Session.request_door(DOOR)
	var bot := Stander.new()
	bot.add_to_group(&"bots")
	add_child_autofree(bot)
	bot.global_position = Vector3(2.5, 10.0, 0.5)
	assert_false(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN])


func test_a_player_leaning_on_the_door_can_still_open_it() -> void:
	_player(5, Vector3(1.72, 10.0, 0.5))                  # the body's side overlaps the door a little
	assert_true(Session.request_door(DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN])


func test_a_block_that_is_not_a_door_is_left_alone() -> void:
	world.cells[DOOR + Vector3i(1, 0, 0)] = BlockIds.STONE
	watch_signals(Session)
	assert_false(Session.request_door(DOOR + Vector3i(1, 0, 0)))
	assert_eq(world.get_block(DOOR + Vector3i(1, 0, 0)), BlockIds.STONE)
	assert_eq(interactor.undo_size(), 0)
	assert_signal_not_emitted(Session, "magic_feedback")


func test_everyone_hears_the_door() -> void:
	watch_signals(Session)
	Session.request_door(DOOR)
	assert_signal_emitted_with_parameters(Session, "door_toggled", [Vector3(2.5, 11.0, 0.5), true])
	Session.request_door(DOOR)
	assert_signal_emitted_with_parameters(Session, "door_toggled", [Vector3(2.5, 11.0, 0.5), false])


# --- Survivor: counted blocks ---------------------------------------------------------------------------

func test_in_survivor_opening_and_closing_costs_nothing_even_with_no_doors_left() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(me.peer_id, inv)
	assert_true(Session.request_door(DOOR))
	assert_true(Session.request_door(DOOR))
	assert_eq(inv.ids().size(), 0, "nothing given, nothing taken")
	assert_eq(_doorway(), [BlockIds.DOOR, BlockIds.DOOR])


func test_in_survivor_a_broken_door_comes_back_and_placing_uses_one() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(me.peer_id, inv)
	Session.request_door(DOOR)
	assert_true(Session.request_set_block(TOP, BlockIds.AIR))
	assert_eq(inv.count(BlockIds.DOOR), 1, "an open door gives a door")
	assert_true(Session.request_set_block(DOOR + Vector3i(0, 0, 2), BlockIds.DOOR))
	assert_eq(inv.count(BlockIds.DOOR), 0)
	for id in [BlockIds.SPIKE_TRAP, BlockIds.LANTERN]:
		inv.add(id, 1)
		assert_true(Session.request_set_block(DOOR + Vector3i(-2, 0, 0), id), BlockIds.display_name(id))
		assert_eq(inv.count(id), 0)
		assert_true(Session.request_set_block(DOOR + Vector3i(-2, 0, 0), BlockIds.AIR))
		assert_eq(inv.count(id), 1, "breaking gives it back")


# --- LAN: only the host changes doors -----------------------------------------------------------------

func test_a_guest_only_asks_the_host() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	assert_true(Session.request_door(DOOR), "sent")
	assert_eq(_doorway(), [BlockIds.DOOR, BlockIds.DOOR], "the guest's world waits for the host")
	assert_false(peer.sent_to.is_empty(), "a request went out")
	for to in peer.sent_to:
		assert_eq(to, 1, "to the host only (the first packets carry Godot's node path cache)")


func test_the_host_opens_a_guests_door_within_the_guests_reach() -> void:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(2)
	var guest := _player(2, Vector3(2.5, 10.0, 3.5))
	assert_true(Session.host_door(2, DOOR))
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN])
	guest.global_position = Vector3(2.5, 10.0, 40.0)
	assert_false(Session.host_door(2, DOOR), "too far from the guest")
	assert_false(Session.host_door(9, DOOR), "nobody with that id")
	assert_eq(_doorway(), [BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN])


# --- Taps ------------------------------------------------------------------------------------------------

func _look_at_door() -> Vector2:
	me.viewer.free()
	me.rig.process_mode = Node.PROCESS_MODE_DISABLED     # the test aims the camera
	me.camera().look_at_from_position(me.eye_position(), Vector3(DOOR) + Vector3(0.5, 0.5, 0.5))
	return interactor.get_viewport().get_visible_rect().size * 0.5


func test_a_tap_on_a_door_opens_it_whatever_is_in_the_hand() -> void:
	var center := _look_at_door()
	for item in [BlockIds.PLANKS, ItemIds.SWORD, ItemIds.PICKAXE, ItemIds.WAND]:
		interactor.hotbar[0] = item
		interactor.select_slot(0)
		var before: int = world.get_block(DOOR)
		assert_true(interactor.place_at_screen(center), ItemIds.display_name(item))
		assert_eq(world.get_block(DOOR), DefenseRules.toggled(before), "%s: the door, not the item" % ItemIds.display_name(item))
	assert_eq(world.cells.values().count(BlockIds.PLANKS), 0, "no plank was placed against it")


func test_holding_a_finger_on_a_door_still_breaks_it() -> void:
	var center := _look_at_door()
	assert_true(interactor.break_at_screen(center))
	assert_eq(world.get_block(DOOR), BlockIds.AIR)
