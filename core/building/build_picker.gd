class_name BuildPicker
extends RefCounted
## Picks a small build (M4 Wave 3, agent I: blueprint gifts and bottles; M3 Task 8's Build-and-Wear
## reuses it): the blocks connected to a tapped block (6 neighbours) that are not natural ground
## (CaptureRules.GROUND: grass, dirt, stone, sand, water, the underground and its ores; trees count, as
## for the wand's buddies), in a box of at most MAX_SIDE on every side and MAX_BLOCKS in all. Pure: it
## reads blocks through get_block(pos) -> id and stops as soon as the build is too big.

const MAX_SIDE := 8
const MAX_BLOCKS := 512
const _NEIGHBOURS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


## {"blocks": {world pos: id}, "origin": lowest corner, "size": box} or {"error": "not_a_build" | "too_big"}.
static func pick(start: Vector3i, get_block: Callable, max_side: int = MAX_SIDE, max_blocks: int = MAX_BLOCKS) -> Dictionary:
	var first: int = get_block.call(start)
	if not CaptureRules.is_capturable(first):
		return {"error": "not_a_build"}
	var blocks := {start: first}
	var lo := start
	var hi := start
	var queue: Array[Vector3i] = [start]
	while not queue.is_empty():
		var p: Vector3i = queue.pop_back()
		for n in _NEIGHBOURS:
			var q: Vector3i = p + n
			if blocks.has(q):
				continue
			var id: int = get_block.call(q)
			if not CaptureRules.is_capturable(id):
				continue
			lo = Vector3i(mini(lo.x, q.x), mini(lo.y, q.y), mini(lo.z, q.z))
			hi = Vector3i(maxi(hi.x, q.x), maxi(hi.y, q.y), maxi(hi.z, q.z))
			var side := hi - lo + Vector3i.ONE
			if maxi(side.x, maxi(side.y, side.z)) > max_side:
				return {"error": "too_big"}
			blocks[q] = id
			if blocks.size() > max_blocks:
				return {"error": "too_big"}
			queue.append(q)
	return {"blocks": blocks, "origin": lo, "size": hi - lo + Vector3i.ONE}


## A pick's blocks from its lowest corner ({} for an error).
static func local(picked: Dictionary) -> Dictionary:
	var out := {}
	var origin: Vector3i = picked.get("origin", Vector3i.ZERO)
	var blocks: Dictionary = picked.get("blocks", {})
	for p: Vector3i in blocks:
		out[p - origin] = blocks[p]
	return out


static func message(code: String) -> String:
	match code:
		"not_a_build":
			return "Tap a block of your build!"
		"too_big":
			return Lang.t("That build is too big. Pick one that fits in %d x %d x %d blocks!") % [MAX_SIDE, MAX_SIDE, MAX_SIDE]
	return ""
