class_name UniverseBackdrop
extends Control
## A universe's own scene behind its menu screens (M5 Task 2, spec §15.2): CONTINUE / NEW WORLD, a new world's "how
## brave" and "which game". It fills the panel's inside behind the buttons (UniverseArt) under a soft veil that keeps
## the words readable, takes no taps and never asks for room. Drawn only when the panel redraws.

var universe := 1
var veil := Color(0.08, 0.1, 0.17, 0.62)
## Rows of blocks the height holds (the scene stands in the bottom UniverseArt.ROWS of them; 0: the whole height).
var rows_high := 0.0


func _init(u: int = 1) -> void:
	universe = u
	name = "UniverseBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO


## Fills `panel`'s inside (its style's content margins in from its edges): an internal child drawn before the
## panel's content, so the menu's screens keep their content as the panel's first child.
func fit_inside(panel: PanelContainer) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := panel.get_theme_stylebox("panel")
	if box:
		offset_left = box.get_margin(SIDE_LEFT)
		offset_top = box.get_margin(SIDE_TOP)
		offset_right = -box.get_margin(SIDE_RIGHT)
		offset_bottom = -box.get_margin(SIDE_BOTTOM)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UniverseArt.draw(self, r, universe, false, floorf(size.y / rows_high) if rows_high > 0.0 else 0.0)
	draw_rect(r, veil)
