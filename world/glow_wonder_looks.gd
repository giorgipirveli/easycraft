class_name GlowWonderLooks
extends RefCounted
## Universe 6, the Glow Caves: what the Cave Wonders' plays look like (GlowWondersDirector), as shared-material box meshes
## (GolemModels.glow_material: unshaded, vertex colours; no new material, no light, so nothing new to warm up and nothing
## a phone pays per lamp): the grotto's glow-worms in LEVELS brightness steps (a step's mesh is swapped in; the worms'
## dots under the ceiling, a few with a sticky thread under them), the threads that show the way after the grotto, a
## water drop, and the lake's pale cave fish (no eyes: they are blind).

const LEVELS := 6
const WORMS := 72
const DOT := 0.12
const THREAD := Vector3(0.03, 0.55, 0.03)
const DARK := Color(0.05, 0.11, 0.14)
const BRIGHT := Color(0.62, 1.0, 0.94)
const THREAD_DIM := 0.55          # a thread glows this much of its worm
const WAY_DOTS := 28              # the threads that show the way: this many dots ...
const WAY_STEP := 1.5             # ... this far apart
const DROP := Vector3(0.11, 0.17, 0.11)
const DROP_COLOR := Color(0.72, 0.9, 1.0)
const FISH_BODY := Vector3(0.46, 0.17, 0.18)
const FISH_TAIL := Vector3(0.1, 0.15, 0.04)
const FISH_COLOR := Color(0.96, 0.86, 0.86)


## The grotto's worms at every brightness step (0: dark, LEVELS - 1: bright). `ceiling_at(x, z) -> int`: the ceiling of a
## column (its lowest rock); the dots hang just under it, inside the grotto's round.
static func worm_meshes(w: Dictionary, ceiling_at: Callable) -> Array[ArrayMesh]:
	var c: Vector3i = w.anchor
	var r := float(w.get("radius", 5))
	var spots: Array[Array] = []   # [position, has a thread]
	for i in WORMS:
		var h := absi(hash(Vector3i(c.x * 3 + i, c.z * 5 - i, c.y)))
		var a := float(h % 6283) / 1000.0
		var d := sqrt(float((h >> 13) % 1000) / 1000.0) * (r + 0.4)
		var x := c.x + 0.5 + cos(a) * d
		var z := c.z + 0.5 + sin(a) * d
		var top := int(ceiling_at.call(floori(x), floori(z)))
		spots.append([Vector3(x, top - DOT * 0.5 - 0.02, z), (h >> 23) % 3 == 0])
	var out: Array[ArrayMesh] = []
	for level in LEVELS:
		var k := float(level) / float(LEVELS - 1)
		var col := DARK.lerp(BRIGHT, k)
		var st := _begin()
		for s: Array in spots:
			var p: Vector3 = s[0]
			BlockyAnimal._box(st, p, Vector3.ONE * DOT, col)
			if s[1]:
				BlockyAnimal._box(st, p - Vector3(0, THREAD.y * 0.5 + DOT * 0.5, 0), THREAD, DARK.lerp(col, THREAD_DIM))
		out.append(_end(st))
	return out


## The worms' threads after the grotto: bright dots under the ceilings from the grotto towards `to` (the way to a hidden
## chest), WAY_DOTS of them at most; none under a wall.
static func way_mesh(from: Vector3, to: Vector3, column_at: Callable) -> ArrayMesh:
	var st := _begin()
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	var way := flat.normalized() if flat.length() > 0.01 else Vector3.RIGHT
	var dots := 0
	for i in range(1, WAY_DOTS + 1):
		var p := from + way * (i * WAY_STEP)
		if i * WAY_STEP > flat.length():
			break
		var col: Vector3i = column_at.call(floori(p.x), floori(p.z))
		if col.x == col.y or col.y >= col.z:
			continue
		var y := col.y - DOT * 0.5 - 0.02
		BlockyAnimal._box(st, Vector3(p.x, y, p.z), Vector3.ONE * DOT * 1.3, BRIGHT)
		BlockyAnimal._box(st, Vector3(p.x, y - THREAD.y * 0.6, p.z), THREAD * Vector3(1, 1.2, 1), BRIGHT.darkened(0.2))
		dots += 1
	return _end(st) if dots > 0 else null


static func drop_mesh() -> ArrayMesh:
	var st := _begin()
	BlockyAnimal._box(st, Vector3.ZERO, DROP, DROP_COLOR)
	return _end(st)


## A pale cave fish facing +X: a body and a tail, and no eyes.
static func fish_mesh() -> ArrayMesh:
	var st := _begin()
	BlockyAnimal._box(st, Vector3.ZERO, FISH_BODY, FISH_COLOR)
	BlockyAnimal._box(st, Vector3(-FISH_BODY.x * 0.5 - FISH_TAIL.x * 0.5, 0, 0), FISH_TAIL, FISH_COLOR.darkened(0.12))
	return _end(st)


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _end(st: SurfaceTool) -> ArrayMesh:
	st.set_material(GolemModels.glow_material())
	return st.commit()
