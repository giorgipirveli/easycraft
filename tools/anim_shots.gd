extends SceneTree
## Pictures of owner #94's moving School pictures (SchoolPictureMotion), for a look without the editor or the emulator:
## every moving sample at three moments (time 0 = its still picture, then later), six to a sheet. Windowed (headless
## draws nothing), into a folder with "shots":
##   XDG_DATA_HOME=/tmp/easycraft-anim-shots godot --path . --disable-vsync --script res://tools/anim_shots.gd
## PNGs go to user://anim_shots/ (the path is printed); prints ANIM_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/anim_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
