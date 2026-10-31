class_name VisitShape
extends MeadowsShape
## The terrain rules the player asks a world for (surface height, spawn column), for the flat island of
## a showcase visit (VisitGenerator; M4 Wave 3, agent I).


func _init() -> void:
	super(0)


func height_at(_x: int, _z: int) -> int:
	return VisitGenerator.GROUND_TOP


func is_river(_x: int, _z: int) -> bool:
	return false


## The visitor arrives on the grass in front of the showcase, looking at it.
func spawn_column() -> Vector2i:
	return Vector2i(0, VisitGenerator.ISLAND - 14)


func tree_at(_x: int, _z: int) -> bool:
	return false
