extends SceneTree
## Pictures of the School (owner feedback #68, spec §22) for a look without the editor or the emulator: its pages
## (welcome, the map of each subject, a unit, every lesson card, a round's exercises, the round's end, grades, the
## parent gate, the grown-ups' page) inside the menu's panel, on a private profile (nothing is saved). Windowed
## (headless draws nothing), into a folder with "shots":
##   XDG_DATA_HOME=/tmp/easycraft-school-shots godot --path . --disable-vsync --script res://tools/school_shots.gd \
##     -- [--unit=g4.maths.big_numbers] [--wide] [--exercises]
## --wide: the 20:9 canvas (1600 × 720); --exercises: every hand-written exercise of the unit, shown answered wrong
## twice (the worked answer). PNGs go to user://school_shots/ (the path is printed); prints SCHOOL_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/school_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
