extends SceneTree
## Pictures of EasyCraft Shorts (owner #94, spec §5.12b), for a look without the editor or the emulator. Windowed
## (headless draws nothing):
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/shorts_shots.gd -- --short=rocket_parts
##   ... -- --short=lesson:g4.science.circuits --frames=10     a contact sheet of 10 moments, evenly through the Short
##   ... -- --all                                                every hand-made Short, a sheet each
##   ... -- --panel                                              the Theater's SHORTS tab at 1600 × 720 and 1280 × 720
## PNGs go to user://shorts_shots/ (the path is printed); prints SHORTS_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/shorts_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
