class_name ToolSample
extends RefCounted
## Owner #117 (docs/design/life-skills.md §13): ToolMotion's samples, made the same way from a hand and a finger. The
## work has its own frame (work_frame: x along the work, y out of its surface, z across, the origin at the work point);
## a held tool has a tip (its working point: -Z where it points or strikes, +X its side, +Y its up). VR: the tip's pose
## in that frame, its trigger and the other hand (the cut's claw grip). Flat: the finger's ray from the camera meets the
## work's surface there (a finger down touches; its fingertip's size there in metres is `reach`).


## The work's frame: x along `along` (made square to `up`), y = `up` (the surface's outward normal).
static func work_frame(origin: Vector3, along: Vector3, up: Vector3) -> Transform3D:
	var y := up.normalized()
	var x := (along - y * along.dot(y)).normalized()
	if x.length() < 0.5:
		x = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x, y, z), origin)


## A hand's sample: the tool's `tip` (global), its trigger (0..1), the other hand (global; INF: not asked).
static func vr(frame: Transform3D, tip: Transform3D, trigger: float, dt: float, other: Vector3 = Vector3.INF) -> Dictionary:
	var inv := frame.affine_inverse()
	var to_frame := frame.basis.inverse()
	var s := {"dt": dt, "flat": false, "at": inv * tip.origin, "axis": (to_frame * -tip.basis.z).normalized(),
		"side": (to_frame * tip.basis.x).normalized(), "tilt": tip.basis.y.normalized().angle_to(Vector3.UP),
		"trigger": clampf(trigger, 0.0, 1.0)}
	s.touch = (s.at as Vector3).y <= 0.02
	if other.is_finite():
		s.other = inv * other
	return s


## A finger's sample: its ray (global, from the camera), whether it is down, a fingertip's size there (m). No `at` when
## the ray never meets the surface (along it, or away from it).
static func flat(frame: Transform3D, ray_from: Vector3, ray_dir: Vector3, down: bool, dt: float, reach: float) -> Dictionary:
	var s := {"dt": dt, "flat": true, "touch": down, "trigger": 1.0 if down else 0.0, "reach": reach}
	var n := frame.basis.y.normalized()
	var denom := ray_dir.dot(n)
	if absf(denom) < 0.0001:
		return s
	var t := (frame.origin - ray_from).dot(n) / denom
	if t <= 0.0:
		return s
	var local := frame.affine_inverse() * (ray_from + ray_dir * t)
	s.at = Vector3(local.x, 0.0, local.z)
	return s
