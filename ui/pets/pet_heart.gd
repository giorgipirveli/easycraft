class_name PetHeart
extends Control
## The happiness heart on a pet's card (M3 Task 11): HudIcons' heart, drawn as big as the pet is happy
## (`fill`, PetRules.heart_scale: never empty), in code (no texture).

const COLOR := Color("ff5c8a")
const BACK := Color(1, 1, 1, 0.12)

var fill := 1.0:
	set(v):
		fill = clampf(v, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	HudIcons.draw(self, &"heart", full, BACK)
	var side := size * fill
	HudIcons.draw(self, &"heart", Rect2((size - side) * 0.5, side), COLOR)
