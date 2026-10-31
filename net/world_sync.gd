class_name WorldSync
extends Node
## World sync by edits (M4 Wave 1 A, spec §17.0), a child of every WorldService. It replaces Voxel
## Tools' VoxelTerrainMultiplayerSynchronizer, which sent every block around a guest (0.2–0.9 MB when
## a guest joined, 4–9 Mbit/s while one flew; docs/devlog/parts/m4-online-spike.md).
##   Host: guests generate the terrain from the seed, so each guest gets only what differs from it.
##   When a chunk comes into a guest's view (SyncedTerrain.chunk_entered, from the VoxelViewer the
##   host streams around the guest's player) the guest is owed that chunk's edit list (EditLog;
##   a chunk the log does not know is compared with the generator on a worker thread, ChunkDiffer,
##   and its list waits meanwhile without holding back the others); every later change
##   (WorldService.block_changed) goes as a single change. GuestSync keeps the order,
##   SyncPacer the pace: one packet per guest per frame, within its byte budget, and nothing while
##   the relay link still has a backlog.
##   Guest: receive() puts the edits in the EditOverlay (EditedGenerator writes them over every chunk
##   it generates) and into the chunks already loaded; a chunk that was generating while its edits
##   arrived is checked again when it loads (block_loaded).
##   M4 Task 10 review I: the guest forgets a chunk's edits once its terrain has had the chunk unloaded
##   for FORGET_AFTER_MS (block_unloaded; loaded again sooner, they stay), and the host, told by Voxel
##   Tools that a chunk came into the guest's view again, sends its list again (GuestSync.forget). The
##   wait covers the host's copy of the guest's player lagging behind: a chunk that leaves the guest's
##   view for a moment may never leave the host's copy of it, and would not be sent again.
## Sending goes through Session's RPCs (the autoload has the same path in every game); tests inject
## `send`, `backlog_of` and `position_of`.

## Chunks remembered per guest (about 3,500 are in view at a view distance of 128); over this the
## ones the host has unloaded are forgotten.
const SEEN_MAX := 16384
## Guest: how long a chunk stays unloaded before its edits are forgotten (M4 Task 10 review I).
const FORGET_AFTER_MS := 10_000
const FORGET_CHECK_MS := 500


## Host: send(peer_id, packet). Default: Session._rpc_world_edits.
var send: Callable
## Host: bytes still queued on the link (RelayBridge + WebSocket); 0 on LAN. Default: Session's.
var backlog_of: Callable
## Host: where a guest's player is (lists go nearest first). Default: its Player node.
var position_of: Callable
## Guest: send_view(distance) tells the host this game's view distance. Default: Session's RPC.
var send_view: Callable
## Guest: FORGET_AFTER_MS (tests make it 0).
var forget_after_ms := FORGET_AFTER_MS
## Counts for measurements (net_test) and tests.
var stats := {"packets": 0, "bytes": 0, "lists": 0, "cells": 0, "diffs": 0, "diff_ms": 0.0,
	"received": 0, "received_bytes": 0, "applied": 0, "rechecked": 0, "entered": 0, "worst_ms": 0.0, "forgotten": 0}

var _world: WorldService
var _is_client := false
var _generator: VoxelGenerator
var _overlay: EditOverlay
var _log := EditLog.new()
var _pacer := SyncPacer.new()
var _guests := {}      # peer -> GuestSync (from its client_ready until it leaves)
var _views := {}       # peer -> the view distance the guest asked for
var _seen := {}        # peer -> {chunk: edited}: chunks that came into its view (kept while it is away)
var _racing := {}      # guest: chunk -> true: edits arrived while it was not loaded yet
var _unloaded := {}    # guest: chunk with edits -> msec its terrain unloaded it (forgotten after forget_after_ms)
var _next_forget := 0  # guest: msec of the next look at _unloaded
var _differ: ChunkDiffer   # host: saved chunks compared with the generator on worker threads
var _fresh := {}       # host: chunk -> its list from a diff over EditLog.CAP (not kept): this frame only


func setup(world: WorldService, is_client: bool, generator: VoxelGenerator, overlay: EditOverlay) -> void:
	_world = world
	_is_client = is_client
	_generator = generator
	_overlay = overlay
	var terrain := world.terrain() as SyncedTerrain
	if is_client:
		terrain.block_loaded.connect(_on_block_loaded)
		terrain.block_unloaded.connect(_on_block_unloaded)
	else:
		terrain.block_enter_notification_enabled = true
		terrain.chunk_entered.connect(_on_chunk_entered)
		world.block_changed.connect(_on_block_changed)
		var tool := terrain.get_voxel_tool()   # its own tool: the copies run on worker threads
		_differ = ChunkDiffer.new(generator, func(origin: Vector3i, into: VoxelBuffer) -> void:
			tool.copy(origin, into, 1 << VoxelBuffer.CHANNEL_TYPE))


func _ready() -> void:
	if _is_client:
		Game.settings_applied.connect(func(_s: Dictionary) -> void: _send_view_distance())
		_send_view_distance.call_deferred()
	else:
		Session.client_ready.connect(_on_client_ready)
		Session.peer_left.connect(guest_left)


## Every comparison still running is waited for: it reads the terrain, which goes with this world.
func _exit_tree() -> void:
	if _differ != null:
		_differ.wait_all()


# --- Host ---------------------------------------------------------------------------------------

## A guest's world is ready (its client_ready, also after a rejoin): it starts with nothing owed, and
## is owed the lists of the chunks around its player again (Voxel Tools tells about a chunk entering
## a viewer's area only once, and the guest's player and viewer on the host stay while it is away).
func _on_client_ready(peer: int) -> void:
	guest_ready(peer)


func guest_ready(peer: int) -> void:
	guest_gone(peer)
	var g := GuestSync.new()
	_guests[peer] = g
	var seen: Dictionary = _seen.get(peer, {})
	var terrain := _world.terrain()
	for chunk: Vector3i in seen:
		if terrain.has_data_block(chunk):
			_offer(g, chunk, seen[chunk])


## A guest's link dropped: nothing more is owed to that connection (it may come back: guest_ready).
func guest_gone(peer: int) -> void:
	_guests.erase(peer)
	_pacer.forget(peer)


## A guest left for good (Session.peer_left).
func guest_left(peer: int) -> void:
	guest_gone(peer)
	_seen.erase(peer)
	_views.erase(peer)


func is_guest(peer: int) -> bool:
	return _guests.has(peer)


func guest_count() -> int:
	return _guests.size()


## Host: the chunks being compared with the generator right now.
func diffing() -> Array:
	return _differ.chunks() if _differ != null else []


## Lists and single changes still to send to a guest.
func pending(peer: int) -> int:
	return (_guests[peer] as GuestSync).pending() if _guests.has(peer) else 0


## The host streams this far around the guest's player: as far as the guest itself sees.
func set_view_of(peer: int, distance: int) -> void:
	_views[peer] = GraphicsPreset.clamp_view_distance(distance)


## A chunk came into a guest's view (on the host, around the guest's player): remembered, also
## before the guest's world is ready, and offered to it.
func _on_chunk_entered(peer: int, chunk: Vector3i, edited: bool) -> void:
	stats.entered += 1
	var seen: Dictionary = _seen.get(peer, {})
	if seen.is_empty():
		_seen[peer] = seen
	elif seen.size() >= SEEN_MAX and not seen.has(chunk):
		_forget_unloaded(seen)
	seen[chunk] = edited or bool(seen.get(chunk, false))
	var g: GuestSync = _guests.get(peer)
	if g != null:
		g.forget(chunk)   # M4 Task 10 review I: back in view; the guest may have forgotten its edits
		_offer(g, chunk, edited)


## The chunks the host no longer has loaded are out of the guest's view.
func _forget_unloaded(seen: Dictionary) -> void:
	var terrain := _world.terrain()
	for chunk: Vector3i in seen.keys():
		if not terrain.has_data_block(chunk):
			seen.erase(chunk)


func _offer(g: GuestSync, chunk: Vector3i, edited: bool) -> void:
	if g.has_chunk(chunk):
		return
	if _log.knows(chunk):
		if _log.edit_count(chunk) == 0:
			g.chunk_as_generated(chunk)
		else:
			g.chunk_entered(chunk)
	elif not edited:
		_log.learn(chunk, {})   # untouched this session and not in the save: as generated
		g.chunk_as_generated(chunk)
	else:
		g.chunk_entered(chunk)


func _on_block_changed(pos: Vector3i, old_id: int, new_id: int) -> void:
	_log.record(pos, old_id, new_id)
	_differ.changed(pos, new_id)
	var chunk := EditLog.chunk_of(pos)
	for seen: Dictionary in _seen.values():
		if seen.has(chunk):
			seen[chunk] = true
	for g: GuestSync in _guests.values():
		g.changed(pos, new_id)


## The chunk's edits now (see GuestSync.take): the log's; null while the chunk is compared with
## the generator on a worker thread (the comparison starts here when a worker is free); false when
## the host has not got the chunk loaded (the guest's view moved on; it comes into view again).
func _list_of(chunk: Vector3i) -> Variant:
	if _fresh.has(chunk):
		return _fresh[chunk]
	if _log.knows(chunk):
		return _log.edits(chunk)
	if not _world.terrain().has_data_block(chunk):
		return false
	_differ.start(chunk)
	return null


## A comparison came back (main thread): the log learns the chunk. A chunk over EditLog.CAP is not
## kept; its list is handed out this frame, and the next guest that needs it gets a new comparison.
func _learn(result: Dictionary) -> void:
	var chunk: Vector3i = result.chunk
	stats.diffs += 1
	stats.diff_ms += float(result.ms)
	if _log.knows(chunk):
		return   # learned meanwhile (as generated) and kept up to date since
	_log.learn(chunk, result.cells)
	if not _log.knows(chunk):
		_fresh[chunk] = EditLog.flat(result.cells)


func _process(_delta: float) -> void:
	if _is_client:
		_forget_left_chunks()
		return
	var t0 := Time.get_ticks_usec()
	for result: Dictionary in _differ.done():
		_learn(result)
	if not _guests.is_empty():
		_send_all()
	_fresh.clear()
	stats.worst_ms = maxf(stats.worst_ms, (Time.get_ticks_usec() - t0) / 1000.0)


func _send_all() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var backlog: int = backlog_of.call() if backlog_of.is_valid() else Session.a_link_backlog()
	for peer: int in _guests.keys():
		_apply_view(peer)
		var g: GuestSync = _guests[peer]
		if not g.has_work():
			continue
		var budget := _pacer.budget(peer, now, backlog)
		if budget <= 0:
			continue
		var records := g.take(budget, _position(peer), _list_of)
		if records.is_empty():
			continue
		var packet := EditCodec.seal(records)
		_pacer.spend(peer, packet.size())
		backlog += packet.size()
		stats.packets += 1
		stats.bytes += packet.size()
		if send.is_valid():
			send.call(peer, packet)
		else:
			Session.a_send_world_edits(peer, packet)


func _apply_view(peer: int) -> void:
	if not _views.has(peer):
		return
	var p := _player(peer)
	if p != null and is_instance_valid(p.viewer) and p.viewer.view_distance != int(_views[peer]):
		p.set_view_distance(_views[peer])


func _position(peer: int) -> Vector3:
	if position_of.is_valid():
		return position_of.call(peer)
	var p := _player(peer)
	return p.global_position if p != null else Vector3.ZERO


func _player(peer: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p.peer_id == peer and not p.is_queued_for_deletion():
			return p
	return null


# --- Guest --------------------------------------------------------------------------------------

## A packet of edits from the host (Session._rpc_world_edits).
func receive(packet: PackedByteArray) -> void:
	stats.received += 1
	stats.received_bytes += packet.size()
	for rec: Dictionary in EditCodec.open(packet):
		if rec.kind == EditCodec.LIST:
			var chunk: Vector3i = rec.chunk
			var edits: PackedInt32Array = rec.edits
			_overlay.put_list(chunk, edits)
			stats.lists += 1
			for i in range(0, edits.size(), 2):
				_apply(EditLog.cell_pos(chunk, edits[i]), edits[i + 1])
		else:
			for c: Array in rec.cells:
				_overlay.put_cell(c[0], c[1])
				stats.cells += 1
				_apply(c[0], c[1])


func _apply(pos: Vector3i, id: int) -> void:
	if _world.is_editable(pos):
		if _world.get_block(pos) != id:
			_world.put_block(pos, id)
			stats.applied += 1
	else:
		_racing[EditLog.chunk_of(pos)] = true


## A chunk finished loading: if edits for it arrived while it was generating, make sure they are in.
func _on_block_loaded(chunk: Vector3i) -> void:
	_unloaded.erase(chunk)
	if not _racing.erase(chunk):
		return
	var edits := _overlay.edits(chunk)
	for i in range(0, edits.size(), 2):
		var pos := EditLog.cell_pos(chunk, edits[i])
		if _world.is_editable(pos) and _world.get_block(pos) != edits[i + 1]:
			_world.put_block(pos, edits[i + 1])
			stats.rechecked += 1


## Guest (M4 Task 10 review I): the terrain unloaded a chunk; its edits are forgotten if it stays unloaded.
func _on_block_unloaded(chunk: Vector3i) -> void:
	if _overlay.has_chunk(chunk):
		_unloaded[chunk] = Time.get_ticks_msec()


## Guest: the edits of chunks unloaded for forget_after_ms go (looked at every FORGET_CHECK_MS).
func _forget_left_chunks() -> void:
	var now := Time.get_ticks_msec()
	if _unloaded.is_empty() or (now < _next_forget and forget_after_ms > 0):
		return
	_next_forget = now + FORGET_CHECK_MS
	for chunk: Vector3i in _unloaded.keys():
		if now - int(_unloaded[chunk]) >= forget_after_ms:
			_unloaded.erase(chunk)
			_racing.erase(chunk)
			_overlay.forget(chunk)
			stats.forgotten += 1


## Guest: what is known of the host's edits (tests, measurements).
func edit_overlay() -> EditOverlay:
	return _overlay


func _send_view_distance() -> void:
	var d := GraphicsPreset.view_distance(Profile.data.settings)   # M5 Task 3: LOW sees 64 blocks
	if send_view.is_valid():
		send_view.call(d)
	elif multiplayer.multiplayer_peer != null and not multiplayer.is_server() \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		Session.a_send_view_distance(d)
