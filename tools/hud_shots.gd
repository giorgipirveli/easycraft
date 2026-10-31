extends SceneTree
## Pictures of the HUD (M2 Task 17) on the emulator's 20:9 screen (at 1600 × 720) and a small 16:9 phone
## (1334 × 750): awake (SLEEP, HELP UP and ATTACK showing), asleep (WAKE UP and STOP FOR TODAY),
## flying (UP and DOWN) and with the MORE panel open, over a plain background. For a look at the
## buttons' pictures and sizes without the editor or the emulator. Windowed (headless draws nothing):
##   godot --path . --disable-vsync --script res://tools/hud_shots.gd
## PNGs go to user://hud_shots/ (the path is printed); prints HUD_SHOT lines. No world, no save.


func _initialize() -> void:
	var steps: Node = load("res://tools/hud_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
