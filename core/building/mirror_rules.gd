class_name MirrorRules
extends RefCounted
## Mirror mode: every edit is repeated on the other side of a vertical mirror plane.
## The plane runs through the middle of block column `plane`, so that column mirrors onto itself.

enum Axis { X, Z }


static func mirror(pos: Vector3i, axis: int, plane: int) -> Vector3i:
	if axis == Axis.X:
		return Vector3i(2 * plane - pos.x, pos.y, pos.z)
	return Vector3i(pos.x, pos.y, 2 * plane - pos.z)


## The axis that is "left/right" for a camera with this yaw (the mirror flips left and right).
static func axis_for_yaw(yaw: float) -> int:
	var right := Basis(Vector3.UP, yaw) * Vector3.RIGHT
	return Axis.X if absf(right.x) >= absf(right.z) else Axis.Z
