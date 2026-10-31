extends SceneTree
## Owner #122 (G0): pictures of the play arena's stations, flat, for a look without the editor or the emulator: each
## mechanic's station with a sample exercise as it opens (the HUD over it), then with the worked answer shown. Windowed
## (headless draws nothing), into a private folder:
##   XDG_DATA_HOME=/tmp/easycraft-play-shots godot --path . --disable-vsync --script res://tools/play_shots.gd \
##     -- [--only=sort,make_coins] [--unit=g4.maths.big_numbers] [--wide]
## --unit plays that unit's own round instead (one picture per challenge). PNGs go to user://play_shots/ (the path is
## printed); prints PLAY_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/play_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
