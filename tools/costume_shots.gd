extends SceneTree
## Pictures of the Storybook costume pack (owner feedback #36) in both graphics styles, for a look without the
## editor or the emulator: every costume front and back (a blocky body over a realistic person), the faces close up,
## and the avatar editor's COSTUME tab on the emulator's 20:9 canvas. Windowed (headless draws nothing), into a
## folder of its own:
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/costume_shots.gd
## PNGs go to user://costume_shots/ (the path is printed); prints COSTUME_SHOT lines. No world; the editor's profile
## is a private copy (nothing is saved).


func _initialize() -> void:
	var steps: Node = load("res://tools/costume_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
