class_name StudioShapes
extends RefCounted
## The Reel Studio (owner #96, round 2: learning reels, spec §5.12b): a `blocks` model's cells from shapes, so a volcano,
## a pyramid's courses, a ridge of rock layers or a tank of water is a few lines of data, not thousands of cells. Pure.
##
##   "fill": [{"box": [x0, y0, z0, x1, y1, z1], "block": "STONE"},   corners included, either order
##            {"disc": [x, y, z, r], "block": "GRASS"},                one layer: every cell within r of (x, z)
##            {"cylinder": [x, y, z, r, h], "block": "LOG"},           discs from y up, h layers
##            {"cone": [x, y, z, r, h], "block": "BASALT"},            discs from y up, the radius shrinking to its tip
##            {"ball": [x, y, z, r], "block": "HOT_LAVA"}]             every cell within r of the middle
##
## Shapes go in the order written and a later one overwrites; "AIR" carves (a cutaway: the front half of a volcano
## taken off to show its pipe). The model's `cells` ([x, y, z, block], AIR too) go in last. A model's cells are meshed
## like the world's blocks (Scene3DBuilds): the mesher draws only the faces that show, so a solid shape costs its skin.

const SHAPES := {"box": 6, "disc": 4, "cylinder": 5, "cone": 5, "ball": 4}
## At most this many cells and shapes a model (a phone meshes them when the reel is built: test_shorts_view's bench).
const MAX_CELLS := 12000
const MAX_SHAPES := 160
## A model's blocks fit in a box this wide on every side (cells).
const MAX_SPAN := 96
## A circle's edge: a cell is in when its middle is within r + EDGE of the centre (rounder small discs).
const EDGE := 0.35


## The cells ({Vector3i: block id}) of a `blocks` model's `fill` and `cells` (AIR leaves none).
static func cells(data: Dictionary) -> Dictionary:
	var out := {}
	var shapes: Variant = data.get("fill", [])
	if shapes is Array:
		for s: Variant in shapes:
			if s is Dictionary:
				_shape(s, out)
	var list: Variant = data.get("cells", [])
	if list is Array:
		for c: Variant in list:
			if c is Array and (c as Array).size() == 4:
				_put(out, Vector3i(int(c[0]), int(c[1]), int(c[2])), block(c[3]))
	return out


static var _ids := {}
static var _ids_lock := Mutex.new()


## A shape's or a cell's block: a BlockIds name or id, 0 for AIR (it carves), -1 for anything else. Kept by name
## (ShortCheck.block_id reads BlockIds' whole constant map each time: 0.3 ms a call, 50 ms for a volcano's shapes);
## any thread (the stage fills a live reel's buffers on a worker).
static func block(v: Variant) -> int:
	if v is String and v == "AIR":
		return BlockIds.AIR
	if typeof(v) in [TYPE_INT, TYPE_FLOAT] and int(v) == BlockIds.AIR:
		return BlockIds.AIR
	if v is String:
		_ids_lock.lock()
		var id: int = _ids.get(v, -2)
		_ids_lock.unlock()
		if id == -2:
			id = ShortCheck.block_id(v)
			_ids_lock.lock()
			_ids[v] = id
			_ids_lock.unlock()
		return id
	return ShortCheck.block_id(v)


## "" when `shape` is one this file can fill.
static func problem(shape: Variant) -> String:
	if not shape is Dictionary:
		return "a shape is {box | disc | cylinder | cone | ball: [numbers], block}"
	var d: Dictionary = shape
	var kind := kind_of(d)
	if kind == "":
		return "a shape is one of %s" % ", ".join(SHAPES.keys())
	var nums: Variant = d[kind]
	if not nums is Array or (nums as Array).size() != int(SHAPES[kind]):
		return "a %s is %d numbers" % [kind, int(SHAPES[kind])]
	for v: Variant in nums:
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
			return "a %s is %d numbers" % [kind, int(SHAPES[kind])]
	if kind in ["disc", "cylinder", "cone", "ball"] and float(nums[3]) <= 0.0:
		return "a %s's radius is above 0" % kind
	if kind in ["cylinder", "cone"] and int(nums[4]) < 1:
		return "a %s is 1 layer high at least" % kind
	if block(d.get("block")) < 0:
		return "a shape's block is a block's name or AIR, not %s" % d.get("block")
	return ""


static func kind_of(d: Dictionary) -> String:
	for k: String in SHAPES:
		if d.has(k):
			return k
	return ""


static func _shape(d: Dictionary, out: Dictionary) -> void:
	if problem(d) != "":
		return
	var kind := kind_of(d)
	var n: Array = d[kind]
	var id := block(d.block)
	match kind:
		"box":
			var a := Vector3i(int(n[0]), int(n[1]), int(n[2]))
			var b := Vector3i(int(n[3]), int(n[4]), int(n[5]))
			var lo := a.min(b)
			var hi := a.max(b)
			for x in range(lo.x, hi.x + 1):
				for y in range(lo.y, hi.y + 1):
					for z in range(lo.z, hi.z + 1):
						_put(out, Vector3i(x, y, z), id)
		"disc":
			_disc(out, float(n[0]), int(n[1]), float(n[2]), float(n[3]), id)
		"cylinder":
			for k in int(n[4]):
				_disc(out, float(n[0]), int(n[1]) + k, float(n[2]), float(n[3]), id)
		"cone":
			var h := int(n[4])
			for k in h:
				_disc(out, float(n[0]), int(n[1]) + k, float(n[2]), maxf(float(n[3]) * (1.0 - float(k) / h), 0.5), id)
		"ball":
			var c := Vector3(float(n[0]), float(n[1]), float(n[2]))
			var r := float(n[3])
			var reach := ceili(r + EDGE)
			for x in range(floori(c.x) - reach, floori(c.x) + reach + 1):
				for y in range(floori(c.y) - reach, floori(c.y) + reach + 1):
					for z in range(floori(c.z) - reach, floori(c.z) + reach + 1):
						if Vector3(x, y, z).distance_to(c) <= r + EDGE:
							_put(out, Vector3i(x, y, z), id)


static func _disc(out: Dictionary, cx: float, y: int, cz: float, r: float, id: int) -> void:
	var reach := ceili(r + EDGE)
	for x in range(floori(cx) - reach, floori(cx) + reach + 1):
		for z in range(floori(cz) - reach, floori(cz) + reach + 1):
			if Vector2(x - cx, z - cz).length() <= r + EDGE:
				_put(out, Vector3i(x, y, z), id)


static func _put(out: Dictionary, at: Vector3i, id: int) -> void:
	if id == BlockIds.AIR:
		out.erase(at)
	elif id > 0:
		out[at] = id


## The same cells in a VoxelBuffer ready for the blocky mesher: {buffer, lo} (lo: the cell at the buffer's (1, 1, 1),
## one voxel of padding all round), {} when nothing is left. Filled row by row in C++ (fill_area): a phone builds a
## reel in a frame of its own, and the volcano's 14,000 cells took 120 ms one by one here. Any thread (a VoxelBuffer).
static func buffer(data: Dictionary) -> Dictionary:
	var shapes: Array = []
	for s: Variant in data.get("fill", []) if data.get("fill") is Array else []:
		if s is Dictionary and problem(s) == "":
			shapes.append(s)
	var cells: Array = []
	for c: Variant in data.get("cells", []) if data.get("cells") is Array else []:
		if c is Array and (c as Array).size() == 4 and block(c[3]) >= 0:
			cells.append(c)
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := -lo
	for s: Dictionary in shapes:
		if block(s.block) == BlockIds.AIR:
			continue
		var b := _bounds(s)
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	for c: Array in cells:
		if block(c[3]) != BlockIds.AIR:
			var at := Vector3i(int(c[0]), int(c[1]), int(c[2]))
			lo = lo.min(at)
			hi = hi.max(at)
	if lo.x > hi.x:
		return {}
	var f := Filler.new()
	f.lo = lo
	f.size = hi - lo + Vector3i(3, 3, 3)
	f.buf = VoxelBuffer.new()
	f.buf.create(f.size.x, f.size.y, f.size.z)
	for sh: Dictionary in shapes:
		f.shape(sh)
	for c: Array in cells:
		var at := Vector3i(int(c[0]), int(c[1]), int(c[2]))
		f.cells(at, at, block(c[3]))
	if f.buf.is_uniform(CH) and f.buf.get_voxel(0, 0, 0, CH) == 0:   # carving may have left nothing
		return {}
	return {"buffer": f.buf, "lo": lo}


const CH := VoxelBuffer.CHANNEL_TYPE


## A shape's cells' bounds [lo, hi] (inclusive).
static func _bounds(d: Dictionary) -> Array:
	var kind := kind_of(d)
	var n: Array = d[kind]
	if kind == "box":
		var a := Vector3i(int(n[0]), int(n[1]), int(n[2]))
		var b := Vector3i(int(n[3]), int(n[4]), int(n[5]))
		return [a.min(b), a.max(b)]
	var reach := ceili(float(n[3]) + EDGE)
	var c := Vector3i(floori(float(n[0])), int(n[1]), floori(float(n[2])))
	var lo := c - Vector3i(reach, 0, reach)
	var hi := c + Vector3i(reach, 0, reach)
	match kind:
		"cylinder", "cone":
			hi.y += int(n[4]) - 1
		"ball":
			lo.y = floori(float(n[1])) - reach
			hi.y = floori(float(n[1])) + reach
	return [lo, hi]


## Fills shapes into a VoxelBuffer one row (or box) at a time, exactly the cells _shape() puts in a dictionary: a row's
## run is worked out from the circle's equation, then its two ends checked with the same test _disc() and _shape() use.
class Filler:
	extends RefCounted
	var buf: VoxelBuffer
	var lo: Vector3i
	var size: Vector3i

	## Cells a..b (inclusive) set to `id`, clipped to the buffer (inside its padding).
	func cells(a: Vector3i, b: Vector3i, id: int) -> void:
		var p := (a - lo + Vector3i.ONE).max(Vector3i.ONE)
		var q := (b - lo + Vector3i(2, 2, 2)).min(size - Vector3i.ONE)
		if p.x < q.x and p.y < q.y and p.z < q.z:
			buf.fill_area(id, p, q, CH)

	func shape(d: Dictionary) -> void:
		var kind := StudioShapes.kind_of(d)
		var n: Array = d[kind]
		var id := StudioShapes.block(d.block)
		match kind:
			"box":
				var a := Vector3i(int(n[0]), int(n[1]), int(n[2]))
				var b := Vector3i(int(n[3]), int(n[4]), int(n[5]))
				cells(a.min(b), a.max(b), id)
			"disc":
				disc(float(n[0]), int(n[1]), float(n[2]), float(n[3]), id)
			"cylinder":
				for k in int(n[4]):
					disc(float(n[0]), int(n[1]) + k, float(n[2]), float(n[3]), id)
			"cone":
				var h := int(n[4])
				for k in h:
					disc(float(n[0]), int(n[1]) + k, float(n[2]), maxf(float(n[3]) * (1.0 - float(k) / h), 0.5), id)
			"ball":
				ball(Vector3(float(n[0]), float(n[1]), float(n[2])), float(n[3]), id)

	func disc(cx: float, y: int, cz: float, r: float, id: int) -> void:
		var reach := ceili(r + EDGE)
		var lim := r + EDGE
		for z in range(floori(cz) - reach, floori(cz) + reach + 1):
			var dz := z - cz
			var rr := lim * lim - dz * dz
			if rr < 0.0:
				continue
			var h := sqrt(rr)
			var x0 := ceili(cx - h)
			var x1 := floori(cx + h)
			while x0 <= x1 and Vector2(x0 - cx, dz).length() > lim:
				x0 += 1
			while Vector2(x0 - 1 - cx, dz).length() <= lim:
				x0 -= 1
			while x1 >= x0 and Vector2(x1 - cx, dz).length() > lim:
				x1 -= 1
			while Vector2(x1 + 1 - cx, dz).length() <= lim:
				x1 += 1
			if x0 <= x1:
				cells(Vector3i(x0, y, z), Vector3i(x1, y, z), id)

	func ball(c: Vector3, r: float, id: int) -> void:
		var reach := ceili(r + EDGE)
		var lim := r + EDGE
		for y in range(floori(c.y) - reach, floori(c.y) + reach + 1):
			for z in range(floori(c.z) - reach, floori(c.z) + reach + 1):
				var dy := y - c.y
				var dz := z - c.z
				var rr := lim * lim - dy * dy - dz * dz
				if rr < 0.0:
					continue
				var h := sqrt(rr)
				var x0 := ceili(c.x - h)
				var x1 := floori(c.x + h)
				while x0 <= x1 and Vector3(x0, y, z).distance_to(c) > lim:
					x0 += 1
				while Vector3(x0 - 1, y, z).distance_to(c) <= lim:
					x0 -= 1
				while x1 >= x0 and Vector3(x1, y, z).distance_to(c) > lim:
					x1 -= 1
				while Vector3(x1 + 1, y, z).distance_to(c) <= lim:
					x1 += 1
				if x0 <= x1:
					cells(Vector3i(x0, y, z), Vector3i(x1, y, z), id)


## How many cells a model's shapes may make at most, before any carving (a quick bound for the checker).
static func bound(data: Dictionary) -> int:
	var n := 0
	for d: Variant in data.get("fill", []):
		if not d is Dictionary or problem(d) != "":
			continue
		var kind := kind_of(d)
		var v: Array = d[kind]
		match kind:
			"box":
				n += (absi(int(v[3]) - int(v[0])) + 1) * (absi(int(v[4]) - int(v[1])) + 1) * (absi(int(v[5]) - int(v[2])) + 1)
			"disc":
				n += ceili(PI * pow(float(v[3]) + 1.0, 2.0))
			"cylinder", "cone":
				n += ceili(PI * pow(float(v[3]) + 1.0, 2.0)) * int(v[4])
			"ball":
				n += ceili(4.0 / 3.0 * PI * pow(float(v[3]) + 1.0, 3.0))
	return n
