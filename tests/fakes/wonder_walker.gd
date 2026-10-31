extends RefCounted
## A child's walk over world 41's wonders for the tests (owner #78, spec §24; the second tour's tests use it): the block
## at a cell is the secrets' (a fake door open when `open`), else the tours' builds (WonderBuilds), else the ground
## (WondersShape: stone under its height, air over it). Standing needs two free cells over a solid one; a step up is
## `up` blocks at most with room over the head; a fall a few blocks at most. Blocks are remembered (the builds' buckets
## are big).

var shape: WondersShape
var rules: WondersSecretRules
var open := false
var _memo := {}


func _init(ground: WondersShape, secrets: WondersSecretRules = null, fakes_open: bool = false) -> void:
	shape = ground
	rules = secrets
	open = fakes_open


func block(p: Vector3i) -> int:
	var hit: Variant = _memo.get(p)
	if hit != null:
		return hit
	var b := -1
	if rules != null:
		b = rules.block_at(p)
		if b >= 0 and open and SecretRules.is_fake_wall(b):
			b = BlockIds.AIR
	if b < 0:
		b = WonderBuilds.block_at(p)
	if b < 0:
		b = BlockIds.STONE if p.y < shape.height_at(p.x, p.z) else BlockIds.AIR
	_memo[p] = b
	return b


static func is_free(id: int) -> bool:
	return not BlockIds.is_solid(id) or id == BlockIds.FLOWERS


func stands(p: Vector3i) -> bool:
	return is_free(block(p)) and is_free(block(p + Vector3i.UP)) and not is_free(block(p + Vector3i.DOWN))


## Can a child walk from `from` (feet) to any feet cell `goal` accepts? `up`: the highest step (2: a double jump);
## `within` (x, z): the ground the walk keeps to.
func walks(from: Vector3i, goal: Callable, within: Rect2i, up: int = 1, limit: int = 120000) -> bool:
	if not stands(from):
		push_warning("not standing at the start %s" % from)
		return false
	var seen := {from: true}
	var queue: Array[Vector3i] = [from]
	var head := 0
	while head < queue.size() and head < limit:
		var p: Vector3i = queue[head]
		head += 1
		if goal.call(p):
			return true
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			for q: Vector3i in _moves(p, p + d, up):
				if not seen.has(q) and within.has_point(Vector2i(q.x, q.z)):
					seen[q] = true
					queue.append(q)
	return false


func _moves(p: Vector3i, c: Vector3i, up: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for dy in range(1, up + 1):   # up a step: room over the head here and there
		var q := c + Vector3i(0, dy, 0)
		var room := true
		for k in range(2, dy + 2):
			room = room and is_free(block(p + Vector3i(0, k, 0)))
		if room and stands(q):
			out.append(q)
	if is_free(block(c)) and is_free(block(c + Vector3i.UP)):   # across, then down a few at most
		var y := c.y
		while y > c.y - 4 and is_free(block(Vector3i(c.x, y - 1, c.z))):
			y -= 1
		var q := Vector3i(c.x, y, c.z)
		if stands(q):
			out.append(q)
	return out


## A goal: a feet cell inside the box lo..hi (inclusive, any order).
static func inside(lo: Vector3i, hi: Vector3i) -> Callable:
	var a := lo.min(hi)
	var b := lo.max(hi)
	return func(p: Vector3i) -> bool:
		return p.x >= a.x and p.y >= a.y and p.z >= a.z and p.x <= b.x and p.y <= b.y and p.z <= b.z


## A cell of wonder `id`'s own frame in the world (y up from the tour's ground).
static func at(id: StringName, x: int, y: int, z: int) -> Vector3i:
	var q := WonderTour.to_world(id, Vector2i(x, z))
	return Vector3i(q.x, WonderTour.BASE_Y + y, q.y)


## The world rect (x, z) round wonder `id`'s reach, `margin` blocks wider.
static func around(id: StringName, margin: int = 12) -> Rect2i:
	return WonderTour.reach(id).grow(margin)
