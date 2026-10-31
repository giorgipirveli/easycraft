extends GutTest
## Deferred M1 minor "LAN client undo has gaps" (M1 final review): a LAN client recorded an undo
## step as soon as it sent an edit, even when the host then refused it; cells the host skipped
## inside a batch stayed in that batch's undo (and undoing it could break a friend's block); and
## cells an undo could not restore yet were dropped. Undo steps now come from the host: what it
## really changed, and for an undo, what it had to leave for later.
## Solo play (this game is the host) and LAN (a fake network peer whose packets go nowhere) are
## both covered.

const NEAR_A := Vector3i(2, 10, 0)
const NEAR_B := Vector3i(-2, 10, 0)
const ME_AT := Vector3(0.5, 10.0, 4.5)   # both cells are well within reach from here


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


var world: EditWorld


func before_each() -> void:
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)


func after_each() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)


## A player body for `peer` with its feet at `feet`. Other players count as bodies in the host's checks.
func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.global_position = feet
	if peer != multiplayer.get_unique_id():
		p._spawned = true
	return p


func _interactor(p: Player) -> BlockInteractor:
	return p.get_node("BlockInteractor")


## Joins as LAN client peer 2 of host 1. Nothing it sends arrives, so the host never answers.
func _join_as_client() -> FakePeer:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	return peer


func _stand_in(cell: Vector3i) -> Vector3:
	return Vector3(cell) + Vector3(0.5, 0.0, 0.5)


# --- Solo: this game is the host ---

## A mirrored copy landed inside a friend, so the host skipped it. Later the friend built there:
## undoing the batch removes my block and never the friend's.
func test_cells_the_host_skipped_are_not_in_the_undo_step() -> void:
	var me := _player(multiplayer.get_unique_id(), ME_AT)
	var friend := _player(5, _stand_in(NEAR_B))
	var interactor := _interactor(me)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE], [NEAR_B, BlockIds.STONE]], false))
	assert_eq(world.get_block(NEAR_A), BlockIds.STONE)
	assert_eq(world.get_block(NEAR_B), BlockIds.AIR, "skipped: the friend stands there")
	friend.global_position.z += 10.0            # the friend steps away ...
	world.set_block(NEAR_B, BlockIds.BRICK)      # ... and builds there
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.AIR, "my block is undone")
	assert_eq(world.get_block(NEAR_B), BlockIds.BRICK, "the friend's block stays")


## A friend stepped into one of the holes an undo has to fill: that cell waits for a later undo.
func test_cells_an_undo_could_not_restore_yet_are_kept_for_later() -> void:
	world.cells[NEAR_A] = BlockIds.STONE
	world.cells[NEAR_B] = BlockIds.STONE
	var me := _player(multiplayer.get_unique_id(), ME_AT)
	var interactor := _interactor(me)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.AIR], [NEAR_B, BlockIds.AIR]], false))
	var friend := _player(5, _stand_in(NEAR_B))
	assert_true(interactor.undo(), "A comes back")
	assert_eq(world.get_block(NEAR_A), BlockIds.STONE)
	assert_eq(world.get_block(NEAR_B), BlockIds.AIR, "never a block inside the friend")
	assert_eq(interactor.undo_size(), 1, "B is kept for later")
	friend.global_position.z += 10.0
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_B), BlockIds.STONE, "B comes back once the friend moved")
	assert_eq(interactor.undo_size(), 0)


## Already true before the fix (a guard): a refused undo of one block is kept for later.
func test_a_refused_undo_of_one_block_is_kept_for_later() -> void:
	world.cells[NEAR_B] = BlockIds.STONE
	var me := _player(multiplayer.get_unique_id(), ME_AT)
	var interactor := _interactor(me)
	assert_true(interactor.apply_edits([[NEAR_B, BlockIds.AIR]], false))
	var friend := _player(5, _stand_in(NEAR_B))
	assert_false(interactor.undo(), "the friend stands there")
	assert_eq(interactor.undo_size(), 1)
	friend.global_position.z += 10.0
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_B), BlockIds.STONE)


# --- LAN ---

func test_a_lan_client_records_no_undo_step_before_the_host_confirms() -> void:
	_join_as_client()
	var me := _player(2, ME_AT)
	var interactor := _interactor(me)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE]]), "sent to the host")
	assert_eq(interactor.undo_size(), 0, "the host may still refuse it")
	assert_false(interactor.undo(), "nothing to undo yet")


func test_the_host_tells_a_lan_client_what_it_changed() -> void:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(2)
	_player(2, ME_AT)                            # the client's body on the host
	peer.sent_to.clear()
	assert_true(Session._host_apply(2, NEAR_A, BlockIds.STONE))
	assert_has(peer.sent_to, 2, "the client hears what it can undo")


## The host's answer arrives over the network: that is the undo step. An undo the host could not
## finish comes back the same way and is kept for later.
func test_a_lan_client_records_the_undo_step_the_host_sends() -> void:
	_join_as_client()
	var interactor := _interactor(_player(2, ME_AT))
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE]]))
	Session._rpc_undo_step([[NEAR_A, BlockIds.AIR, BlockIds.STONE]])
	assert_eq(interactor.undo_size(), 1)
	assert_true(interactor.undo(), "the undo is sent to the host")
	assert_eq(interactor.undo_size(), 0)
	Session._rpc_undo_step([[NEAR_A, BlockIds.AIR, BlockIds.STONE]])   # the host couldn't do it yet
	assert_eq(interactor.undo_size(), 1, "kept for later")


func test_a_lan_client_ignores_malformed_undo_steps() -> void:
	_join_as_client()
	var interactor := _interactor(_player(2, ME_AT))
	Session._rpc_undo_step([["junk"], [NEAR_A, 1], [NEAR_A, "x", 2], 7])
	assert_eq(interactor.undo_size(), 0)


## Only this game's own player keeps an undo stack: the host's copy of a remote player ignores it.
func test_only_the_local_player_records_undo_steps() -> void:
	var me := _player(multiplayer.get_unique_id(), ME_AT)
	var friend := _player(5, _stand_in(NEAR_B) + Vector3(0, 0, 8))
	assert_true(_interactor(me).apply_edits([[NEAR_A, BlockIds.STONE]]))
	assert_eq(_interactor(me).undo_size(), 1)
	assert_eq(_interactor(friend).undo_size(), 0)
