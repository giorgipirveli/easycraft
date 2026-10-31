class_name AltarSolver
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5's rules table, ruling 5, §4.3; the model's `shortest` and
## `budget`): the shortest list of twin moves that frees a crystal, found breadth-first over every legal move (takes of
## any size, adds up to AltarMoves.MAX_ADD, fair shares), and cached by the pans and the room's tools. Its first move is
## the ghost's next step; its length sets the move budget a SOLVED altar must keep. Pure, no nodes.

## The deepest search (the hall's and the Sky Room's altars need at most two moves; wing 8's twin altars three).
const DEPTH := 5
## min_ops when there is no solution within DEPTH.
const NONE := 99

static var _cache := {}


## A shortest solution ([] when the crystal is already free, or when there is none: see `solvable`).
static func shortest(s: AltarState, tools: Array[String], depth: int = DEPTH) -> Array[Dictionary]:
	var found: Variant = _search(s, tools, depth)
	var out: Array[Dictionary] = []
	if found is Array:
		for op: Dictionary in found:
			out.append(op)
	return out


static func solvable(s: AltarState, tools: Array[String], depth: int = DEPTH) -> bool:
	return _search(s, tools, depth) is Array


## The length of a shortest solution (0 when free; NONE when there is none).
static func min_ops(s: AltarState, tools: Array[String]) -> int:
	var found: Variant = _search(s, tools, DEPTH)
	return (found as Array).size() if found is Array else NONE


## The ghost's next step: the first move of a shortest solution ({} when none is needed or possible).
static func next_step(s: AltarState, tools: Array[String]) -> Dictionary:
	var path := shortest(s, tools)
	return path[0] if not path.is_empty() else {}


## The most operations a SOLVED altar may take: a one-move altar in one move (a detour there shows the child does not
## yet see which move undoes what), a longer one one move more than its shortest solution.
static func budget(shortest_ops: int) -> int:
	return shortest_ops if shortest_ops <= 1 else shortest_ops + 1


## The path (an Array of operations) or false, cached.
static func _search(s: AltarState, tools: Array[String], depth: int) -> Variant:
	var tools_key := ",".join(tools) + "|%d" % depth
	if not _cache.has(tools_key):
		_cache[tools_key] = {}
	var cache: Dictionary = _cache[tools_key]
	var start := s.key()
	if cache.has(start):
		return cache[start]
	var result: Variant = false
	if s.freed():
		result = []
	else:
		var seen := {start: true}
		var frontier: Array = [[s, []]]
		for level in depth:
			var next: Array = []
			for item: Array in frontier:
				var cur: AltarState = item[0]
				for op: Dictionary in AltarMoves.legal_ops(cur, tools):
					var after := AltarMoves.apply(cur, op)
					var k := after.key()
					if seen.has(k):
						continue
					seen[k] = true
					var path: Array = (item[1] as Array).duplicate()
					path.append(op)
					if after.freed():
						result = path
						break
					next.append([after, path])
				if result is Array:
					break
			if result is Array or next.is_empty():
				break
			frontier = next
	cache[start] = result
	return result
