class_name PowerTools
extends RefCounted
## The Sandbox power tools (M3 Task 8; spec §14.5, §5.5), as pure rules: LINE (two taps: a straight line of the
## block held last, each block touching the last by a face, so it can be walked along and up), FILL (the box
## between two taps, at most FILL_MAX blocks) and COPY (two taps select a box of at most COPY_MAX_SIDE on every
## side; a tap pastes it). A copy is kept in "stamp" coordinates (Blueprints: x right, y up, z away from the
## child) as it faced the child, so a paste turns with the child; TURN adds quarter turns. Every tool only
## fills empty cells (air or water): nothing is ever broken or replaced, a friend's build included. The host
## checks the same caps (Session section "M3 Task 8").

const LINE_MAX := 64
const FILL_MAX := 4096
const COPY_MAX_SIDE := 16
## How far from the requester's eyes the host lets a tool build (the collision distance around a player: the
## chunks there are loaded). The two taps are within building reach when they are made.
const REACH := 48.0

const TOO_LONG := "too_long"
const TOO_BIG := "too_big"
const TOO_BIG_COPY := "too_big_copy"
const NOTHING := "nothing"      # nothing to copy, or nowhere empty to build


## The cells of a straight line from a to b, both ends included: one axis step at a time (a staircase on a
## diagonal), always the axis that is furthest behind, so it stays within a block of the true line.
static func line_cells(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var d := b - a
	var n := absi(d.x) + absi(d.y) + absi(d.z)
	var dir := Vector3i(signi(d.x), signi(d.y), signi(d.z))
	var total := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var done := Vector3i.ZERO
	var p := a
	var out: Array[Vector3i] = [a]
	for i in n:
		var best := -1
		var best_t := INF
		for k in 3:
			if done[k] < int(total[k]):
				var t := (done[k] + 0.5) / total[k]
				if t < best_t:
					best_t = t
					best = k
		p[best] += dir[best]
		done[best] += 1
		out.append(p)
	return out


static func line_refusal(a: Vector3i, b: Vector3i) -> String:
	var d := (b - a).abs()
	return TOO_LONG if d.x + d.y + d.z + 1 > LINE_MAX else ""


static func box_size(a: Vector3i, b: Vector3i) -> Vector3i:
	return (b - a).abs() + Vector3i.ONE


static func box_count(a: Vector3i, b: Vector3i) -> int:
	var s := box_size(a, b)
	return s.x * s.y * s.z


static func box_cells(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var lo := a.min(b)
	var hi := a.max(b)
	var out: Array[Vector3i] = []
	for y in range(lo.y, hi.y + 1):
		for z in range(lo.z, hi.z + 1):
			for x in range(lo.x, hi.x + 1):
				out.append(Vector3i(x, y, z))
	return out


static func fill_refusal(a: Vector3i, b: Vector3i) -> String:
	return TOO_BIG if box_count(a, b) > FILL_MAX else ""


static func copy_refusal(a: Vector3i, b: Vector3i) -> String:
	var s := box_size(a, b)
	return TOO_BIG_COPY if maxi(s.x, maxi(s.y, s.z)) > COPY_MAX_SIDE else ""


## Air and water: the only cells a tool builds in.
static func is_empty(id: int) -> bool:
	return id == BlockIds.AIR or id == BlockIds.WATER


## [[pos, id], ...] for the empty cells of a line (get_block(pos) -> id).
static func line_edits(a: Vector3i, b: Vector3i, id: int, get_block: Callable) -> Array:
	return _into_empty(line_cells(a, b), id, get_block)


## [[pos, id], ...] for the empty cells of the box between a and b.
static func fill_edits(a: Vector3i, b: Vector3i, id: int, get_block: Callable) -> Array:
	return _into_empty(box_cells(a, b), id, get_block)


static func _into_empty(cells: Array[Vector3i], id: int, get_block: Callable) -> Array:
	var out: Array = []
	for c in cells:
		if is_empty(get_block.call(c)):
			out.append([c, id])
	return out


## [[pos, id], ...] for the cells whose block (ids[i], read in one go: WorldService.blocks_at) is air or water.
static func empty_edits(cells: Array, ids: PackedInt32Array, id: int) -> Array:
	var out: Array = []
	for i in cells.size():
		if is_empty(ids[i]):
			out.append([cells[i], id])
	return out


## A copied box's blocks {offset from its lowest corner: id}: every placeable block (no air, bedrock or ids no
## block owns). Reads the buffer's bytes (one bulk copy of the world, never a call per cell: DEVELOPMENT.md §8).
static func copy_buffer(buf: VoxelBuffer) -> Dictionary:
	buf.decompress_channel(VoxelBuffer.CHANNEL_TYPE)   # a box of one block is stored as one value
	var bytes := buf.get_channel_as_byte_array(VoxelBuffer.CHANNEL_TYPE)
	var wide := buf.get_channel_depth(VoxelBuffer.CHANNEL_TYPE) == VoxelBuffer.DEPTH_16_BIT
	var size := buf.get_size()
	var out := {}
	for z in size.z:
		for x in size.x:
			for y in size.y:
				var v := y + size.y * (x + size.x * z)
				var id: int = (bytes[v * 2] | (bytes[v * 2 + 1] << 8)) if wide else bytes[v]
				if id != BlockIds.AIR and BlockIds.is_valid(id):
					out[Vector3i(x, y, z)] = id
	return out


## A copy (world offsets) as stamp coordinates for a child facing `facing` (a Blueprints.facing_for_yaw
## direction): x to the child's right, z away from them; standing on y = 0, the nearest row at z = 0, centred
## left to right like a gift stamp (Blueprints.gift_local).
static func to_stamp(blocks: Dictionary, facing: Vector3i) -> Dictionary:
	var right := Vector3i(-facing.z, 0, facing.x)
	var out := {}
	for p: Vector3i in blocks:
		out[Vector3i(p.x * right.x + p.z * right.z, p.y, p.x * facing.x + p.z * facing.z)] = blocks[p]
	return _settle(out)


## The stamp turned `quarter_turns` times to the right (seen from above), settled again.
static func turned(stamp: Dictionary, quarter_turns: int) -> Dictionary:
	var n := posmod(quarter_turns, 4)
	var out := stamp
	for i in n:
		var next := {}
		for p: Vector3i in out:
			next[Vector3i(p.z, p.y, -p.x)] = out[p]   # away -> right, right -> towards
		out = _settle(next)
	return out


## [[pos, id], ...] of a stamp pasted at `anchor` (the tapped empty cell) for a child facing `facing`.
static func paste_edits(stamp: Dictionary, anchor: Vector3i, facing: Vector3i) -> Array:
	var out: Array = []
	for p: Vector3i in stamp:
		out.append([Blueprints.to_world(p, anchor, facing), stamp[p]])
	return out


## Stands a stamp on y = 0 with its nearest row at z = 0, centred left to right (x from -floor(width / 2)).
static func _settle(stamp: Dictionary) -> Dictionary:
	if stamp.is_empty():
		return {}
	var lo := Vector3i(1 << 20, 1 << 20, 1 << 20)
	var hi := -lo
	for p: Vector3i in stamp:
		lo = lo.min(p)
		hi = hi.max(p)
	var shift := Vector3i(-floori((hi.x - lo.x + 1) / 2.0) - lo.x, -lo.y, -lo.z)
	var out := {}
	for p: Vector3i in stamp:
		out[p + shift] = stamp[p]
	return out


static func message(code: String) -> String:
	match code:
		TOO_LONG:
			return Lang.t("That line is too long! At most %d blocks.") % LINE_MAX
		TOO_BIG:
			return "That box is too big! At most 4,096 blocks."
		TOO_BIG_COPY:
			return Lang.t("That's too big to copy! At most %d blocks on each side.") % COPY_MAX_SIDE
		NOTHING:
			return "Nothing to build there!"
	return ""
