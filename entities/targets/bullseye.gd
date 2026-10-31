class_name Bullseye
extends PracticeTarget
## An archery target (M1b Task 11): arrows that hit its face score 1 (the rim) to 10 (gold).
## It faces -Z, towards the player who placed it.

var last_score := -1


func center() -> Vector3:
	return to_global(WeaponModels.BULLSEYE_CENTER)


func radius() -> float:
	return WeaponRules.BULLSEYE_RADIUS


## The front of the face, pointing towards the archer who placed it.
func face_normal() -> Vector3:
	return -global_basis.z.normalized()


func collision_size() -> Vector3:
	return Vector3(WeaponRules.BULLSEYE_RADIUS * 2.0, WeaponRules.BULLSEYE_RADIUS * 2.0, 0.16)


func collision_center() -> Vector3:
	return WeaponModels.BULLSEYE_CENTER


## Everyone sees the score where the arrow landed; a 10 gets a golden ding.
@rpc("authority", "call_local", "reliable")
func show_score(score: int, point: Vector3) -> void:
	last_score = score
	_tilt_vel += Vector2(1.2, 0.0)
	Audio.play(&"ding" if score >= 9 else &"thud", point)
	var color := Color("ffd23f") if score >= 9 else Color("ffffff")
	PracticeTarget.popup(get_tree().root, point + Vector3(0, 0.5, 0), "%d!" % score if score == 10 else str(score), color, 84 if score == 10 else 64)
	if score == 10:
		Fx.burst(get_tree().root, point, Color("ffd23f"), 18, 4.0, 0.1, 0.7, 4.0)
