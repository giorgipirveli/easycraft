extends SceneTree
## Pictures of M5 Task 2's polish pass without the editor or the emulator (windowed: headless draws nothing):
## the menu with the title diorama at a few moments of its loop, the Survivor hub's five universe cards, a universe's
## own screens (how brave, which game) and the loading card of every universe; on the emulator's 20:9 canvas
## (1600 x 720) and a small 16:9 phone (1334 x 750).
##   XDG_DATA_HOME=<scratch> godot --path . --disable-vsync --script res://tools/polish_shots.gd
## PNGs go to user://polish_shots/ (the path is printed); prints POLISH_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/polish_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
