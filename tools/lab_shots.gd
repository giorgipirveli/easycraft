extends SceneTree
## Pictures of the Science Lab (spec §23) for a look without the editor or the emulator: the list, every experiment's
## three steps (a guess made; the scene at the start, halfway and seen; what happened and why), the Lab Book and a card,
## the School's unit page with TRY IT IN THE LAB and the Lab inside the School, on a private profile (nothing is saved).
## Windowed (headless draws nothing), into a folder with "shots":
##   XDG_DATA_HOME=/tmp/easycraft-lab-shots godot --path . --disable-vsync --script res://tools/lab_shots.gd [-- --wide]
## --wide: the 20:9 canvas (1600 × 720). PNGs go to user://lab_shots/ (the path is printed); prints LAB_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/lab_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
