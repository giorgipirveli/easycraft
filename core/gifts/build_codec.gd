class_name BuildCodec
extends RefCounted
## A build as one text, for friends and the server (M4 Wave 3, agent I): blueprint gifts, showcases,
## the tiny builds in bottles, a buddy waving in a showcase. The server's format
## (server/modules/src/rules/build_rules.ts, BuildRules): a version byte, the box's size (three bytes),
## then runs of (count, block id) as unsigned LEB128 until every cell of the box is covered, cells x
## fastest, then z, then y; the bytes in base64. The server decodes every build it keeps and checks
## sizes and ids itself; this side reads a build only when it is whole and inside the limits, and
## never lets an item or bedrock travel (they become air).

const VERSION := 1
const ITEM_FIRST := 100          # items own 100-175 and 400-511 (docs/DEVELOPMENT.md §5)
const ITEM_LAST := 175
const RESERVED_FIRST := 400      # cosmos: 400-511 stay the items' forever (BlockIds.RESERVED_FIRST/END) ...
const RESERVED_END := 512        # ... (the first id past them)
const BLOCK_MAX := 1023          # owner #45b: 256-399; cosmos: block pages go on past the items (Titan's page 29, 512-527)
const _MAX_VARINT_BYTES := 3
const _B64 := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

## The limits of each kind of build (the server's GiftRules; tests/unit/test_build_codec.gd compares).
const GIFT := {"max_dim": 8, "max_count": 512, "max_text": 2800}
const BOTTLE := {"max_dim": 4, "max_count": 64, "max_text": 400}
const SHOWCASE := {"max_dim": 32, "max_count": 32768, "max_text": 49152}
const BUDDY := {"max_dim": 17, "max_count": 200, "max_text": 3000}


## A block that may travel: air or a block, never an item, never bedrock.
static func is_block_id(id: int) -> bool:
	return id >= 0 and id <= BLOCK_MAX and id != BlockIds.BEDROCK and not (id >= ITEM_FIRST and id <= ITEM_LAST) \
		and not (id >= RESERVED_FIRST and id < RESERVED_END)


## The text of `blocks` ({Vector3i: id}; any corner), in a box from their lowest corner. `size`
## (optional) makes the box at least that big (a showcase keeps its air).
static func encode(blocks: Dictionary, size := Vector3i.ZERO) -> String:
	var lo := Vector3i.ZERO
	var hi := Vector3i(-1, -1, -1)
	var first := true
	for p: Vector3i in blocks:
		if first:
			lo = p
			hi = p
			first = false
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var box := (hi - lo + Vector3i.ONE).max(size).max(Vector3i.ONE)
	var cells := PackedInt32Array()
	cells.resize(box.x * box.y * box.z)
	cells.fill(BlockIds.AIR)
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		var l := p - lo
		cells[l.x + box.x * (l.z + box.z * l.y)] = id if is_block_id(id) else BlockIds.AIR
	return encode_cells(box, cells)


## The text of a box of `size` whose cells are in the format's order (x fastest, then z, then y).
static func encode_cells(size: Vector3i, cells: PackedInt32Array) -> String:
	var out := PackedByteArray([VERSION, size.x, size.y, size.z])
	var i := 0
	while i < cells.size():
		var j := i + 1
		while j < cells.size() and cells[j] == cells[i]:
			j += 1
		_push_varint(out, j - i)
		_push_varint(out, cells[i] if is_block_id(cells[i]) else BlockIds.AIR)
		i = j
	return Marshalls.raw_to_base64(out)


## The build of a text ({Vector3i: id}, air left out, from (0, 0, 0)), or {} when it is broken, holds
## nothing, or is outside `limits` (GIFT, BOTTLE, SHOWCASE, BUDDY).
static func decode(text: String, limits: Dictionary) -> Dictionary:
	var cells := _cells(text, limits)
	if cells.is_empty():
		return {}
	var size: Vector3i = cells.size
	var ids: PackedInt32Array = cells.ids
	var out := {}
	for y in size.y:
		for z in size.z:
			for x in size.x:
				var id := ids[x + size.x * (z + size.z * y)]
				if id != BlockIds.AIR:
					out[Vector3i(x, y, z)] = id
	return out


## The box of a text (ZERO when it is broken).
static func size_of(text: String) -> Vector3i:
	var bytes := _bytes(text)
	return Vector3i(bytes[1], bytes[2], bytes[3]) if bytes.size() >= 4 and bytes[0] == VERSION else Vector3i.ZERO


## How many blocks (not air) a text holds, whatever its size (0 when it is broken).
static func count_of(text: String) -> int:
	var cells := _cells(text, SHOWCASE)
	return int(cells.get("count", 0))


## {size, ids (every cell), count} or {}.
static func _cells(text: String, limits: Dictionary) -> Dictionary:
	if text == "" or text.length() > int(limits.max_text):
		return {}
	var bytes := _bytes(text)
	if bytes.size() < 4 or bytes[0] != VERSION:
		return {}
	var size := Vector3i(bytes[1], bytes[2], bytes[3])
	if size.x == 0 or size.y == 0 or size.z == 0 or maxi(size.x, maxi(size.y, size.z)) > int(limits.max_dim):
		return {}
	var total := size.x * size.y * size.z
	var ids := PackedInt32Array()
	ids.resize(total)
	var filled := 0
	var count := 0
	var at := 4
	while filled < total:
		var n := _varint(bytes, at)
		if n.is_empty() or int(n.value) == 0 or filled + int(n.value) > total:
			return {}
		var id := _varint(bytes, int(n.next))
		if id.is_empty() or not is_block_id(int(id.value)):
			return {}
		for i in int(n.value):
			ids[filled + i] = int(id.value)
		filled += int(n.value)
		if int(id.value) != BlockIds.AIR:
			count += int(n.value)
			if count > int(limits.max_count):
				return {}
		at = int(id.next)
	if at != bytes.size() or count == 0:
		return {}
	return {"size": size, "ids": ids, "count": count}


## The bytes of a standard base64 text; empty for anything else (checked first: Marshalls logs an
## engine error for bad text).
static func _bytes(text: String) -> PackedByteArray:
	if text.length() % 4 != 0 or text.length() == 0:
		return PackedByteArray()
	var body := text.trim_suffix("=").trim_suffix("=")
	if text.length() - body.length() > 2:
		return PackedByteArray()
	for i in body.length():
		if _B64.find(body[i]) < 0:
			return PackedByteArray()
	return Marshalls.base64_to_raw(text)


static func _varint(bytes: PackedByteArray, at: int) -> Dictionary:
	var value := 0
	for k in _MAX_VARINT_BYTES:
		if at + k >= bytes.size():
			return {}
		var b := bytes[at + k]
		value |= (b & 127) << (7 * k)
		if b & 128 == 0:
			return {"value": value, "next": at + k + 1}
	return {}


static func _push_varint(out: PackedByteArray, value: int) -> void:
	var v := value
	while v >= 128:
		out.append((v & 127) | 128)
		v >>= 7
	out.append(v)
