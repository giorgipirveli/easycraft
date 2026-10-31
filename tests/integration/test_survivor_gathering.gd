extends GutTest
## M2 Task 3 (§12.2): in Survivor every block edit is paid for on the host. Placing takes one of the
## block from the requester's inventory (refused with a message at zero), breaking gives the drop
## (ores need the right pickaxe), batches (stamps, mirror copies, tool powers) are paid for like
## single edits, and an undo gives back or takes back exactly what its edit took or gave. Every
## change reaches the player's HUD (Session.my_inventory). Sandbox never counts.
## Solo play (this game is the host) through Session and the player's BlockInteractor, as in the
## real game; LAN with a fake network peer whose packets go nowhere.

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
var me: Player
var interactor: BlockInteractor
var inv: Inventory
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	me = _player(multiplayer.get_unique_id(), ME_AT)
	interactor = me.get_node("BlockInteractor")
	inv = Inventory.new()
	Session.set_inventory(me.peer_id, inv)


func after_each() -> void:
	Game.mode = _mode_before
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Session.survivor_reset()


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


## Tier pickaxes become ownable in Task 6 (ItemIds.ALL, with their icons); until then the test puts
## one in directly.
static func _give(to: Inventory, id: int, n: int) -> void:
	if to.add(id, n) == 0:
		to._counts[id] = to.count(id) + n


# --- Placing and breaking -------------------------------------------------------------------------

func test_placing_takes_one_block() -> void:
	inv.add(BlockIds.STONE, 2)
	assert_true(Session.request_set_block(NEAR_A, BlockIds.STONE))
	assert_eq(world.get_block(NEAR_A), BlockIds.STONE)
	assert_eq(inv.count(BlockIds.STONE), 1)


func test_placing_with_none_left_is_refused_with_a_message() -> void:
	watch_signals(Session)
	assert_false(Session.request_set_block(NEAR_A, BlockIds.STONE))
	assert_eq(world.get_block(NEAR_A), BlockIds.AIR, "nothing is placed")
	assert_signal_emitted(Session, "edit_rejected")
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You have no Stone left!"])
	assert_eq(interactor.undo_size(), 0, "nothing to undo")


func test_breaking_gives_the_drop() -> void:
	world.cells[NEAR_A] = BlockIds.GRASS
	world.cells[NEAR_B] = BlockIds.LEAVES
	world.cells[NEAR_A + Vector3i.UP] = BlockIds.LOG
	assert_true(Session.request_set_block(NEAR_A, BlockIds.AIR))
	assert_true(Session.request_set_block(NEAR_B, BlockIds.AIR))
	assert_true(Session.request_set_block(NEAR_A + Vector3i.UP, BlockIds.AIR))
	assert_eq(inv.count(BlockIds.DIRT), 1, "grass gives dirt")
	assert_eq(inv.count(BlockIds.LOG), 1)
	assert_eq(inv.ids().size(), 2, "leaves give nothing")


func test_ores_need_the_right_pickaxe_and_nothing_breaks_without_it() -> void:
	world.cells[NEAR_A] = BlockIds.COAL
	world.cells[NEAR_B] = BlockIds.GOLD
	watch_signals(Session)
	assert_false(Session.request_set_block(NEAR_A, BlockIds.AIR))
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You need a pickaxe for this!"])
	assert_eq(world.get_block(NEAR_A), BlockIds.COAL)
	inv.add(ItemIds.PICKAXE, 1)
	assert_true(Session.request_set_block(NEAR_A, BlockIds.AIR), "a wooden pickaxe mines coal")
	assert_false(Session.request_set_block(NEAR_B, BlockIds.AIR))
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You need an iron pickaxe for this!"])
	assert_eq(world.get_block(NEAR_B), BlockIds.GOLD, "nothing breaks")
	_give(inv, ItemIds.PICKAXE_IRON, 1)
	assert_true(Session.request_set_block(NEAR_B, BlockIds.AIR))
	assert_eq([inv.count(BlockIds.COAL), inv.count(BlockIds.GOLD)], [1, 1])


# --- Batches: stamps, mirror copies, tool powers --------------------------------------------------

func _house() -> Array:
	return Blueprints.place(ItemIds.STAMP_HOUSE, Vector3i(0, 10, -8), Vector3i(0, 0, -1))


## What a batch needs, placed into empty cells: {block id: count}.
static func _needs(changes: Array) -> Dictionary:
	var need := {}
	for e: Array in changes:
		if e[1] != BlockIds.AIR:
			need[e[1]] = int(need.get(e[1], 0)) + 1
	return need


func test_a_stamp_is_built_whole_or_not_at_all() -> void:
	var house := _house()
	var need := _needs(house)
	assert_true(need.has(BlockIds.PLANKS))
	for id: int in need:
		inv.add(id, need[id])
	inv.take(BlockIds.PLANKS, 1)
	watch_signals(Session)
	assert_false(interactor.apply_edits(house), "one plank short")
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You need 1 more Planks!"])
	assert_eq(world.cells.size(), 0, "nothing is built")
	inv.add(BlockIds.PLANKS, 1)
	assert_true(interactor.apply_edits(house))
	assert_eq(inv.ids(), [] as Array[int], "every block went into the house")
	for e: Array in house:
		if world.get_block(e[0]) != e[1]:
			fail_test("%s not built" % e[0])
			return


func test_mirror_copies_cost_a_block_each() -> void:
	inv.add(BlockIds.STONE, 1)
	interactor.mirror_enabled = true
	interactor.mirror_axis = MirrorRules.Axis.X
	interactor.mirror_plane = 0
	var copy := MirrorRules.mirror(NEAR_A, MirrorRules.Axis.X, 0)
	assert_ne(copy, NEAR_A)
	assert_false(interactor.apply_edits([[NEAR_A, BlockIds.STONE]]), "a mirrored block needs two")
	assert_eq([world.get_block(NEAR_A), world.get_block(copy)], [BlockIds.AIR, BlockIds.AIR])
	inv.add(BlockIds.STONE, 1)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE]]))
	assert_eq([world.get_block(NEAR_A), world.get_block(copy)], [BlockIds.STONE, BlockIds.STONE])
	assert_eq(inv.count(BlockIds.STONE), 0)


## A small tree on grass: three logs and a crown of leaves.
func _tree(base: Vector3i) -> void:
	world.cells[base] = BlockIds.GRASS
	for y in range(1, 4):
		world.cells[base + Vector3i(0, y, 0)] = BlockIds.LOG
	for x in range(-1, 2):
		for z in range(-1, 2):
			if x != 0 or z != 0:
				world.cells[base + Vector3i(x, 3, z)] = BlockIds.LEAVES
	world.cells[base + Vector3i(0, 4, 0)] = BlockIds.LEAVES


func test_the_axe_fells_a_tree_into_logs() -> void:
	var base := Vector3i(4, 7, -3)
	_tree(base)
	var edits := ToolPowers.fell_tree(base + Vector3i.UP, world.get_block)
	assert_gt(edits.size(), 3)
	assert_true(interactor.apply_edits(edits, false))
	assert_eq(inv.count(BlockIds.LOG), 3)
	assert_eq(inv.ids(), [BlockIds.LOG] as Array[int], "leaves give nothing")
	assert_eq(world.get_block(base), BlockIds.GRASS, "the ground stays")


func test_the_hammer_smash_gathers_the_ground() -> void:
	var center := Vector3i(3, 8, -2)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			world.cells[center + Vector3i(dx, 0, dz)] = BlockIds.GRASS if dx == 0 else BlockIds.STONE
	assert_true(interactor.apply_edits(ToolPowers.smash(center, world.get_block)))
	assert_eq(inv.count(BlockIds.DIRT), 3)
	assert_eq(inv.count(BlockIds.STONE), 6)


func test_the_pickaxe_step_leaves_an_ore_it_may_not_mine() -> void:
	inv.add(ItemIds.PICKAXE, 1)
	world.cells[NEAR_A] = BlockIds.DIAMOND
	world.cells[NEAR_A + Vector3i.UP] = BlockIds.STONE
	watch_signals(Session)
	var edits := ToolPowers.tunnel(NEAR_A, Vector3i(0, 0, 1), NEAR_A.y, world.get_block)
	assert_eq(edits.size(), 2)
	assert_true(interactor.apply_edits(edits, false), "the stone is dug")
	assert_eq(world.get_block(NEAR_A), BlockIds.DIAMOND)
	assert_eq(world.get_block(NEAR_A + Vector3i.UP), BlockIds.AIR)
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You need an iron pickaxe for this!"])
	assert_eq(inv.count(BlockIds.STONE), 1)


# --- Undo -----------------------------------------------------------------------------------------

func test_undoing_a_placement_returns_the_block() -> void:
	inv.add(BlockIds.STONE, 1)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE]]))
	assert_eq(inv.count(BlockIds.STONE), 0)
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.AIR)
	assert_eq(inv.count(BlockIds.STONE), 1)


func test_undoing_a_break_takes_the_block_back_out() -> void:
	world.cells[NEAR_A] = BlockIds.STONE
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.AIR]]))
	assert_eq(inv.count(BlockIds.STONE), 1)
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.STONE)
	assert_eq(inv.count(BlockIds.STONE), 0, "no free stone")


## The broken block was used up elsewhere (not through this undo stack): the undo waits for one.
func test_undoing_a_break_waits_until_the_block_is_owned_again() -> void:
	world.cells[NEAR_A] = BlockIds.BRICK
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.AIR]]))
	inv.take(BlockIds.BRICK, 1)
	watch_signals(Session)
	assert_false(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.AIR)
	assert_signal_emitted_with_parameters(Session, "magic_feedback", ["You have no Brick left!"])
	assert_eq(interactor.undo_size(), 1, "kept for later")
	inv.add(BlockIds.BRICK, 1)
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.BRICK)
	assert_eq(inv.count(BlockIds.BRICK), 0)
	assert_eq(interactor.undo_size(), 0)


func test_undoing_broken_grass_costs_the_dirt_it_gave() -> void:
	world.cells[NEAR_A] = BlockIds.GRASS
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.AIR]]))
	assert_true(interactor.undo())
	assert_eq(world.get_block(NEAR_A), BlockIds.GRASS)
	assert_eq(inv.ids(), [] as Array[int])


func test_undoing_a_stamp_gives_every_block_back() -> void:
	var house := _house()
	var need := _needs(house)
	for id: int in need:
		inv.add(id, need[id])
	var before := inv.to_save()
	assert_true(interactor.apply_edits(house))
	assert_true(interactor.undo())
	assert_eq(inv.to_save(), before)
	for e: Array in house:
		if world.get_block(e[0]) != BlockIds.AIR:
			fail_test("%s not undone" % e[0])
			return


func test_undoing_a_felled_tree_puts_back_what_it_still_owns() -> void:
	var base := Vector3i(4, 7, -3)
	_tree(base)
	var before := world.cells.duplicate()
	assert_true(interactor.apply_edits(ToolPowers.fell_tree(base + Vector3i.UP, world.get_block), false))
	inv.take(BlockIds.LOG, 1)   # one log went elsewhere
	assert_true(interactor.undo(), "the rest comes back")
	assert_eq(inv.count(BlockIds.LOG), 0)
	var missing := 0
	for pos: Vector3i in before:
		if world.get_block(pos) != before[pos]:
			missing += 1
	assert_eq(missing, 1, "one log waits for later")
	assert_eq(interactor.undo_size(), 1)


# --- Sandbox --------------------------------------------------------------------------------------

func test_sandbox_never_counts() -> void:
	Game.mode = ModeRules.SANDBOX
	world.cells[NEAR_B] = BlockIds.GRASS
	world.cells[NEAR_B + Vector3i.UP] = BlockIds.GOLD
	assert_true(Session.request_set_block(NEAR_A, BlockIds.STONE), "unlimited blocks")
	assert_true(Session.request_set_block(NEAR_B + Vector3i.UP, BlockIds.AIR), "no pickaxe needed")
	assert_true(interactor.apply_edits(_house()))
	assert_true(Session.request_set_block(NEAR_B, BlockIds.AIR))
	assert_eq(inv.ids(), [] as Array[int], "nothing is gathered")


# --- The player's HUD hears every change ----------------------------------------------------------

func test_the_local_player_sees_the_inventory_once_per_frame() -> void:
	await wait_frames(1)
	assert_same(Session.my_inventory, inv, "the host's own player reads the host's inventory")
	inv.add(BlockIds.STONE, 3)
	await wait_frames(1)
	watch_signals(Session)
	assert_true(interactor.apply_edits([[NEAR_A, BlockIds.STONE], [NEAR_B, BlockIds.STONE]], false))
	Session.request_set_block(NEAR_A + Vector3i.UP, BlockIds.STONE)
	assert_signal_not_emitted(Session, "inventory_changed", "not before the frame ends")
	await wait_frames(1)
	assert_signal_emit_count(Session, "inventory_changed", 1, "three changes, one update")
	assert_eq(Session.my_inventory.count(BlockIds.STONE), 0)


func test_the_host_sends_a_lan_player_their_inventory() -> void:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(2)
	_player(2, ME_AT + Vector3(0, 0, 3))
	var theirs := Inventory.new()
	theirs.add(BlockIds.STONE, 1)
	Session.set_inventory(2, theirs)
	Session._send_inventories()   # what the end of the frame does
	assert_true(Session._host_apply(2, NEAR_A, BlockIds.STONE))
	assert_eq(theirs.count(BlockIds.STONE), 0, "the guest's own block is used")
	assert_eq(inv.count(BlockIds.STONE), 0)
	peer.sent_to.clear()          # the undo step went out already
	Session._send_inventories()
	assert_eq(peer.sent_to, [2] as Array[int], "the guest hears its inventory, once")


func test_a_lan_player_shows_what_the_host_sent() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	watch_signals(Session)
	Session._rpc_inventory([[BlockIds.STONE, 7], [ItemIds.PICKAXE, 1], ["junk"]])
	assert_eq(Session.my_inventory.count(BlockIds.STONE), 7)
	assert_eq(Session.my_inventory.count(ItemIds.PICKAXE), 1)
	assert_signal_emitted(Session, "inventory_changed")


# --- Saving ---------------------------------------------------------------------------------------

func test_gathered_blocks_survive_a_save_and_load() -> void:
	world.cells[NEAR_A] = BlockIds.GRASS
	world.cells[NEAR_B] = BlockIds.LOG
	Session.request_set_block(NEAR_A, BlockIds.AIR)
	Session.request_set_block(NEAR_B, BlockIds.AIR)
	var m := WorldMeta.new_random()
	m.mode = ModeRules.SURVIVOR
	m.inventories["Hopper"] = Session.inventory_of(me.peer_id).to_save()
	var back := WorldMeta.from_json(m.to_json())
	var loaded := Inventory.from_save(back.inventories["Hopper"])
	assert_eq([loaded.count(BlockIds.DIRT), loaded.count(BlockIds.LOG)], [1, 1])
	Session.set_inventory(me.peer_id, loaded)
	assert_true(Session.request_set_block(NEAR_A, BlockIds.LOG), "the loaded inventory pays")
	assert_eq(loaded.count(BlockIds.LOG), 0)
