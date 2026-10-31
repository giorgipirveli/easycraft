class_name GridRay
extends RefCounted
## Walks the block grid along a ray, cell by cell (Amanatides & Woo), and returns the first cell
## for which is_target(cell) is true. The starting cell is skipped (a camera squeezed into leaves
## should not target the leaves it sits in).


## What a tap ray stops at: any non-air block, but a ray that starts in water passes through water
## (so players can build and dig underwater, and still build on the water surface from above).
static func stops_ray(id: int, from_water: bool) -> bool:
	return id != BlockIds.AIR and not (from_water and id == BlockIds.WATER)


static func cast(origin: Vector3, direction: Vector3, max_dist: float, is_target: Callable) -> BlockHit:
	var d := direction.normalized()
	var cell := Vector3i(origin.floor())
	var step := Vector3i(signi(ceili(d.x) if d.x > 0.0 else floori(d.x)), signi(ceili(d.y) if d.y > 0.0 else floori(d.y)),
		signi(ceili(d.z) if d.z > 0.0 else floori(d.z)))
	var t_max := Vector3(INF, INF, INF)
	var t_delta := Vector3(INF, INF, INF)
	for axis in 3:
		if d[axis] > 0.0:
			t_max[axis] = (floorf(origin[axis]) + 1.0 - origin[axis]) / d[axis]
			t_delta[axis] = 1.0 / d[axis]
		elif d[axis] < 0.0:
			t_max[axis] = (origin[axis] - floorf(origin[axis])) / -d[axis]
			t_delta[axis] = 1.0 / -d[axis]
	while true:
		var axis := 0
		if t_max.y < t_max[axis]:
			axis = 1
		if t_max.z < t_max[axis]:
			axis = 2
		var t: float = t_max[axis]
		if t > max_dist:
			return null
		var before := cell
		cell[axis] += step[axis]
		t_max[axis] += t_delta[axis]
		if is_target.call(cell):
			return BlockHit.new(cell, before, t)
	return null
