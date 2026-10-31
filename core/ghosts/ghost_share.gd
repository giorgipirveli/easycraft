class_name GhostShare
extends RefCounted
## This player's own best runs as ghosts to share (M4 ghost races; spec §17.5): "a player's best run on a course
## they built" (CourseBook's own best, the world owner's) goes on their showcase with the area around it, or with a
## blueprint gift that holds the whole course. Only what the server will take (RaceGhost.check against the very
## blocks that travel): the course's START and FINISH inside, the run around it. Pure.


## The owner's best run on the course at `start` (a world cell) as a ghost for the box at `origin` of `size`,
## whose blocks are block_at(world cell) -> id; null without a run, or when the server would refuse it.
static func ghost_in_box(book: CourseBook, start: Vector3i, origin: Vector3i, size: Vector3i, block_at: Callable,
		look: String) -> RaceGhost:
	var c := book.course(start)
	var run := book.mine(start)
	if c.is_empty() or run == null or c.finish == CourseBook.NONE:
		return null
	var g := RaceGhost.from_run(run, book.mine_ms(start), start - origin, (c.finish as Vector3i) - origin, look)
	if g == null:
		return null
	var in_box := func(cell: Vector3i) -> int:
		if cell.x < 0 or cell.y < 0 or cell.z < 0 or cell.x >= size.x or cell.y >= size.y or cell.z >= size.z:
			return BlockIds.AIR
		return int(block_at.call(origin + cell))
	return g if g.check(size, in_box) == "" else null


## The owner's courses inside a showcase area, as ghosts: [{"start": world cell, "ghost"}], at most
## GhostRaceRules.PER_SHOWCASE, the courses raced most lately first.
static func showcase_ghosts(book: CourseBook, origin: Vector3i, size: Vector3i, block_at: Callable, look: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var starts := book.starts()
	starts.reverse()                    # CourseBook keeps the least lately raced first
	for s in starts:
		if out.size() >= GhostRaceRules.PER_SHOWCASE:
			break
		var g := ghost_in_box(book, s, origin, size, block_at, look)
		if g != null:
			out.append({"start": s, "ghost": g})
	return out


## The ghost that can travel with a picked build ({world cell: id}, BuildPicker): a course whose START and FINISH
## are both in it, with the owner's run; null when there is none.
static func gift_ghost(book: CourseBook, blocks: Dictionary, look: String) -> RaceGhost:
	if blocks.is_empty():
		return null
	var lo: Vector3i = blocks.keys()[0]
	var hi: Vector3i = lo
	for p: Vector3i in blocks:
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var read := func(cell: Vector3i) -> int: return int(blocks.get(cell, BlockIds.AIR))
	for p: Vector3i in blocks:
		if int(blocks[p]) != BlockIds.START:
			continue
		var c := book.course(p)
		if c.is_empty() or not blocks.has(c.finish):
			continue
		var g := ghost_in_box(book, p, lo, hi - lo + Vector3i.ONE, read, look)
		if g != null:
			return g
	return null


## Where the START of a gift's ghost lands when its stamp (a friend's build, `blocks` from its lowest corner) is
## placed at `anchor` facing `forward` (Blueprints.gift_local, then Blueprints.to_world).
static func stamped_start(g: RaceGhost, blocks: Dictionary, anchor: Vector3i, forward: Vector3i) -> Vector3i:
	var width := 0
	for p: Vector3i in blocks:
		width = maxi(width, p.x + 1)
	return Blueprints.to_world(Vector3i(g.start.x - floori(width / 2.0), g.start.y, g.start.z), anchor, forward)


## After a new own best on the course at `start` (a cell of `world`): the ghost to put on my showcase in its
## place, or null (the course is not in my showcase, the ghost there is as fast, or the server would refuse it).
static func replacement(book: CourseBook, ghosts: GhostBook, world: String, start: Vector3i, block_at: Callable,
		look: String) -> RaceGhost:
	if not ghosts.in_my_showcase(world, start):
		return null
	var there := ghosts.shared_at(world, start)
	if not there.is_empty() and int(there.ms) <= book.mine_ms(start):
		return null
	return ghost_in_box(book, start, ghosts.mine.origin, ghosts.mine.size, block_at, look)
