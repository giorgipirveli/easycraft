extends GutTest
## M3 Task 7 (spec §14.4): smart blocks in a world, through the host. A tap on a button, lever or light
## switch is a request (Session.request_smart_tap): the host checks reach and a rate cap (at most 5 toggles
## a second per player), then its SmartDirector switches it and powers what it touches, one step. Plates
## power while a player or a bot friend stands on them; a button powers for a second; a powered doorway never
## closes on someone. Power changes sync like edits, are nobody's undo step and count nothing in Survivor.

const ME_AT := Vector3(0.5, 10.0, 6.5)
const LEVER := Vector3i(0, 10, 0)
const LAMP := Vector3i(1, 10, 0)
const FAR_LAMP := Vector3i(2, 10, 0)
const DOOR := Vector3i(0, 10, 2)          # a doorway of two powered doors, (0, 10..11, 2)
const BUTTON := Vector3i(1, 10, 2)        # touches the doorway's bottom door
const PLATE := Vector3i(-1, 10, 2)        # a plate beside the doorway


## Stands in for the terrain: a dictionary of cells over grass, all loaded.
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


## Stands in for a bot friend that is up (group bots).
class Stander:
	extends Node3D


var world: EditWorld
var me: Player
var smart: SmartDirector
var clock := [0]
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[LEVER] = BlockIds.LEVER
	world.cells[LAMP] = BlockIds.LAMP
	world.cells[FAR_LAMP] = BlockIds.LAMP
	world.cells[DOOR] = BlockIds.POWERED_DOOR
	world.cells[DOOR + Vector3i.UP] = BlockIds.POWERED_DOOR
	world.cells[BUTTON] = BlockIds.BUTTON
	world.cells[PLATE] = BlockIds.PRESSURE_PLATE
	Session.register_world(world)
	clock[0] = 0
	Session.smart_now_ms = func() -> int: return clock[0]
	me = _player(multiplayer.get_unique_id(), ME_AT)
	smart = _director({})


func after_each() -> void:
	Game.mode = _mode_before
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Session.survivor_reset()
	Session.smart_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _director(saved: Dictionary) -> SmartDirector:
	var d := SmartDirector.new()
	d.name = "Smart"
	d.block_at = world.get_block
	add_child_autofree(d)
	d.set_process(false)
	d.start(saved)
	world.block_changed.connect(d.note_block)
	return d


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _step(d: SmartDirector = smart, seconds: float = SmartDirector.CHECK_EVERY + 0.01) -> void:
	d.tick(seconds)


func _doorway() -> Array:
	return [world.get_block(DOOR), world.get_block(DOOR + Vector3i.UP)]


# --- Taps through the host --------------------------------------------------------------------------

func test_a_lever_lights_the_lamp_it_touches_and_turns_it_off_again() -> void:
	assert_true(Session.request_smart_tap(LEVER))
	assert_eq(world.get_block(LEVER), BlockIds.LEVER_ON)
	assert_eq(world.get_block(LAMP), BlockIds.LAMP_ON, "it touches the lever: lit at once")
	assert_eq(world.get_block(FAR_LAMP), BlockIds.LAMP, "one step: the lamp behind it stays dark")
	clock[0] = 300
	assert_true(Session.request_smart_tap(LEVER))
	assert_eq(world.get_block(LEVER), BlockIds.LEVER)
	assert_eq(world.get_block(LAMP), BlockIds.LAMP)


func test_a_button_opens_the_doorway_for_a_second() -> void:
	assert_true(Session.request_smart_tap(BUTTON))
	assert_eq(world.get_block(BUTTON), BlockIds.BUTTON_ON)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN], "the whole doorway")
	_step(smart, 0.5)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN], "still open after half a second")
	_step(smart, 0.6)
	assert_eq(world.get_block(BUTTON), BlockIds.BUTTON, "it pops back up")
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR], "and the doorway closes")


func test_a_tap_out_of_reach_changes_nothing() -> void:
	me.global_position = ME_AT + Vector3(0, 0, 40)
	watch_signals(Session)
	assert_false(Session.request_smart_tap(LEVER))
	assert_eq(world.get_block(LEVER), BlockIds.LEVER)
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [PlacementRules.TOO_FAR_MESSAGE])


func test_a_tap_on_something_else_is_no_switch() -> void:
	assert_false(Session.request_smart_tap(LAMP))
	assert_false(Session.request_smart_tap(DOOR))
	assert_eq(world.get_block(LAMP), BlockIds.LAMP)


func test_at_most_five_toggles_a_second_per_player() -> void:
	watch_signals(Session)
	var accepted := 0
	for i in 12:
		clock[0] = i * 40
		if Session.request_smart_tap(LEVER):
			accepted += 1
	assert_eq(accepted, PowerRules.MAX_TOGGLES_PER_SECOND)
	assert_signal_emit_count(Session, "smart_tap_requested", PowerRules.MAX_TOGGLES_PER_SECOND)
	assert_eq(world.get_block(LEVER), BlockIds.LEVER_ON, "five toggles: on")
	clock[0] = 1500
	assert_true(Session.request_smart_tap(LEVER), "a moment later it works again")


func test_power_changes_are_nobodys_undo_step() -> void:
	var interactor: BlockInteractor = me.get_node("BlockInteractor")
	Session.request_smart_tap(LEVER)
	assert_eq(interactor.undo_size(), 0, "a switch flipped is not an edit to undo")


func test_a_guests_tap_is_a_request_to_the_host() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	assert_true(Session.request_smart_tap(LEVER), "sent")
	assert_eq(world.get_block(LEVER), BlockIds.LEVER, "a guest never switches it itself")
	assert_gt(peer.sent_to.size(), 0)
	for target in peer.sent_to:
		assert_eq(target, 1, "only to the host")


func test_the_host_checks_a_guests_tap() -> void:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(5)
	peer.peer_connected.emit(6)
	_player(5, ME_AT + Vector3(0, 0, 40))
	assert_false(Session.host_smart_tap(5, LEVER), "too far from the guest's body the host knows")
	assert_eq(world.get_block(LEVER), BlockIds.LEVER)
	var near := _player(6, ME_AT)
	assert_true(Session.host_smart_tap(6, LEVER))
	assert_eq(world.get_block(LEVER), BlockIds.LEVER_ON)
	assert_false(Session.host_smart_tap(99, LEVER), "nobody's tap")
	near.queue_free()


func test_in_survivor_power_counts_nothing_and_on_states_break_into_their_block() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(me.peer_id, inv)
	Session.request_smart_tap(LEVER)
	assert_eq(inv.ids().size(), 0, "switching gives and takes nothing")
	assert_true(Session.request_set_block(LEVER, BlockIds.AIR))
	assert_eq(inv.count(BlockIds.LEVER), 1, "a lever that is on breaks into a lever")
	assert_true(Session.request_set_block(LAMP, BlockIds.AIR))
	assert_eq(inv.count(BlockIds.LAMP), 1, "and its lamp into a lamp")


# --- Plates, bodies and doorways ----------------------------------------------------------------------

func test_a_plate_powers_while_a_player_stands_on_it() -> void:
	var guest := _player(7, Vector3(-0.5, 10.125, 2.5))
	_step()
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN], "stepped on: open")
	guest.global_position = Vector3(-0.5, 10.0, 6.5)
	_step()
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR], "stepped off: closed")


func test_a_bot_friend_presses_a_plate_too() -> void:
	var bot := Stander.new()
	bot.add_to_group(&"bots")
	add_child_autofree(bot)
	bot.global_position = Vector3(-0.5, 10.125, 2.5)
	_step()
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN])


func test_a_plate_a_player_placed_powers_like_a_temple_plate() -> void:
	world.cells.erase(PLATE)
	assert_true(Session.request_set_block(Vector3i(3, 10, 0), BlockIds.PRESSURE_PLATE), "placed by the player")
	world.cells[Vector3i(4, 10, 0)] = BlockIds.LAMP
	smart.note_block(Vector3i(4, 10, 0), BlockIds.AIR, BlockIds.LAMP)
	_player(8, Vector3(3.5, 10.125, 0.5))
	_step()
	assert_eq(world.get_block(Vector3i(4, 10, 0)), BlockIds.LAMP_ON)


func test_a_powered_doorway_never_closes_on_someone() -> void:
	world.cells[BUTTON] = BlockIds.LEVER
	Session.request_smart_tap(BUTTON)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN])
	var guest := _player(9, Vector3(0.5, 10.0, 2.5))   # standing in the doorway
	clock[0] = 500
	Session.request_smart_tap(BUTTON)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR_OPEN, BlockIds.POWERED_DOOR_OPEN], "not on a child, not half of it")
	guest.global_position = Vector3(0.5, 10.0, 6.0)
	_step()
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR], "once they are through it closes")


func test_power_never_changes_what_a_cell_holds() -> void:
	assert_eq(Session.power_set_blocks([[LAMP, BlockIds.STONE], [LEVER, BlockIds.DIAMOND]]).size(), 0)
	assert_eq(world.get_block(LAMP), BlockIds.LAMP, "only on and off states of the same block")
	assert_eq(world.get_block(LEVER), BlockIds.LEVER)


# --- Saving -----------------------------------------------------------------------------------------------

func test_a_button_saved_while_pressed_pops_up_after_loading() -> void:
	Session.request_smart_tap(BUTTON)
	var saved := smart.to_save()
	assert_has(saved.power, BUTTON)
	var again := _director(saved)
	_step(again)
	assert_eq(world.get_block(BUTTON), BlockIds.BUTTON)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR])


func test_a_plate_saved_while_stood_on_is_looked_at_again() -> void:
	var guest := _player(7, Vector3(-0.5, 10.125, 2.5))
	_step()
	var saved := smart.to_save()
	assert_has(saved.power, PLATE)
	guest.queue_free()
	await wait_physics_frames(1)
	var again := _director(saved)
	_step(again)
	assert_eq(_doorway(), [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR], "nobody on it after loading: closed")
