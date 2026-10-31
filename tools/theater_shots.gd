extends SceneTree
## Pictures of the Theater's panel (owner #89) on the emulator's 20:9 canvas (1600 × 720) and a 16:9 phone
## (1280 × 720): the bundled channels as picture tabs, the still where the player goes, the video cards, a second
## page, and the end card. For a look at the panel without the editor or the emulator. Windowed (headless draws
## nothing):
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/theater_shots.gd
## PNGs go to user://theater_shots/ (the path is printed); prints THEATER_SHOT lines. No world, no save.


func _initialize() -> void:
	var steps: Node = load("res://tools/theater_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
