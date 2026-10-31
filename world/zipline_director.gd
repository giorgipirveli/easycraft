class_name ZiplineDirector
extends Node
## Ziplines in a world, Sandbox and Survivor alike (M3 Task 14a, spec §13.3). The sandbox adds one on every
## peer, always named "Ziplines", so its RPCs line up across the network.
## Host:
## - Follows the world's block changes (note_block): a Zipline Post placed joins the links (ZiplineLinks: the
##   nearest waiting post of the same player, up to 48 blocks away, the line between them clear), one broken
##   leaves them and its partner waits again. Who placed a post is the player nearest to it (owner_near).
## - A checked ride request (Session.gadget_zip_requested) on a linked post sends that player's own game
##   down the line (Session.send_zip_start); a post without a partner says so kindly.
## - The links are saved (to_save, WorldMeta.ziplines).
## Every peer: every post has its pole and wheel over it, every line its cable (GadgetModels' shared meshes,
## from the host's list, _rpc_lines). Nothing here changes a block.

const NEEDS_PARTNER := "Place a second post (up to 48 blocks away) to hang a line!"
const VISIBLE_TO := 120.0         # cables and poles further than this from the camera are not drawn

## Host: block_at(cell: Vector3i) -> int (tests use stubs).
var block_at: Callable = _world_block
## Host: owner_near(post: Vector3i) -> String: who placed it (the sandbox: the nearest player's name).
var owner_near: Callable = func(_post: Vector3i) -> String: return ""
## Host: tell(peer_id, text).
var tell: Callable = func(peer_id: int, text: String) -> void: Session.send_feedback(peer_id, text)
var links := ZiplineLinks.new()

var _sent := []                 # the [lines, posts] every peer was told
var _holder := Node3D.new()
var _cables: Array[MeshInstance3D] = []
var _poles: Array[MeshInstance3D] = []


func _ready() -> void:
	_holder.name = "Lines"
	_holder.top_level = true
	add_child(_holder)
	Session.gadget_zip_requested.connect(_on_zip_requested)


func _world_block(cell: Vector3i) -> int:
	return Session.world.get_block(cell) if Session.world else BlockIds.AIR


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))

# --- Host --------------------------------------------------------------------------------------------------

## Host: a world's saved links (WorldMeta.ziplines); every game draws them.
func start(saved: Variant) -> void:
	links = ZiplineLinks.from_save(saved)
	_broadcast()


func to_save() -> Array:
	return links.to_save()


## Host: every block change in the world (WorldService.block_changed).
func note_block(pos: Vector3i, old_id: int, new_id: int) -> void:
	if new_id == BlockIds.ZIPLINE_POST and not links.has(pos):
		links.add(pos, str(owner_near.call(pos)), _clear_line)
		_broadcast()
	elif old_id == BlockIds.ZIPLINE_POST and new_id != BlockIds.ZIPLINE_POST and links.has(pos):
		links.remove(pos)
		_broadcast()


## Nothing solid between two posts' attach points.
func _clear_line(a: Vector3i, b: Vector3i) -> bool:
	return GadgetRules.line_clear(GadgetRules.attach_point(a), GadgetRules.attach_point(b), _is_solid)


## Host: the ride from `post` ({from, to}: attach points), or {} without a partner.
func ride_for(post: Vector3i) -> Dictionary:
	var other: Variant = links.partner_of(post)
	if other == null:
		return {}
	return {"from": GadgetRules.attach_point(post), "to": GadgetRules.attach_point(other)}


func _on_zip_requested(peer_id: int, post: Vector3i) -> void:
	if not multiplayer.is_server():
		return
	if not links.has(post) and block_at.call(post) == BlockIds.ZIPLINE_POST:
		note_block(post, BlockIds.AIR, BlockIds.ZIPLINE_POST)   # a post the save didn't know (placed before)
	var ride := ride_for(post)
	if ride.is_empty():
		tell.call(peer_id, NEEDS_PARTNER)
		return
	Session.send_zip_start(peer_id, ride.from, ride.to)


## Host -> a peer that just joined: the lines and posts.
func send_to(peer_id: int) -> void:
	if multiplayer.is_server() and peer_id != multiplayer.get_unique_id():
		_rpc_lines.rpc_id(peer_id, _sent[0] if _sent.size() == 2 else [], _sent[1] if _sent.size() == 2 else [])


func _broadcast() -> void:
	var lines: Array = links.lines()
	var posts: Array = links.posts()
	if _sent.size() == 2 and _sent[0] == lines and _sent[1] == posts:
		return
	_sent = [lines, posts]
	if multiplayer.is_server():
		_rpc_lines.rpc(lines, posts)

# --- Every peer: the cables and poles ----------------------------------------------------------------------

## [[post a, post b], ...] and every post: a cable per line, a pole per post.
@rpc("authority", "call_local", "reliable")
func _rpc_lines(lines: Variant, posts: Variant) -> void:
	var shown: Array = []
	if lines is Array:
		for e: Variant in lines:
			if e is Array and (e as Array).size() == 2 and e[0] is Vector3i and e[1] is Vector3i \
					and GadgetRules.can_link(e[0], e[1]) and shown.size() < ZiplineLinks.MAX:
				shown.append(e)
	var cells: Array = []
	if posts is Array:
		for p: Variant in posts:
			if p is Vector3i and cells.size() < ZiplineLinks.MAX:
				cells.append(p)
	_fit(_cables, shown.size(), GadgetModels.cable())
	_fit(_poles, cells.size(), GadgetModels.pole())
	for i in shown.size():
		GadgetLooks.stretch(_cables[i], GadgetRules.attach_point(shown[i][0]), GadgetRules.attach_point(shown[i][1]))
	for i in cells.size():
		var c: Vector3i = cells[i]
		_poles[i].position = Vector3(c.x + 0.5, c.y + 1.0, c.z + 0.5)


func _fit(list: Array[MeshInstance3D], n: int, mesh: Mesh) -> void:
	while list.size() > n:
		list.pop_back().free()
	while list.size() < n:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visibility_range_end = VISIBLE_TO
		_holder.add_child(m)
		list.append(m)


## Every peer: the cables and poles drawn (tests).
func cables() -> Array[MeshInstance3D]:
	return _cables


func poles() -> Array[MeshInstance3D]:
	return _poles
