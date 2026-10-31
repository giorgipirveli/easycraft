extends SceneTree
## Pictures of the boy and girl looks (owner feedback #48) in both graphics styles, for a look without the
## editor or the emulator: the four presets and the three starting looks, front and back; every girl hair
## style; every clothes cut; the realistic faces close up; the avatar editor after GIRL and the first-launch
## look step on the emulator's 20:9 canvas. Windowed (headless draws nothing), into a folder with "shots":
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/girl_avatar_shots.gd
## PNGs go to user://girl_avatar_shots/ (the path is printed); prints GIRL_SHOT lines. No world; the editor's
## profile is a private copy (nothing is saved).


func _initialize() -> void:
	var steps: Node = load("res://tools/girl_avatar_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
