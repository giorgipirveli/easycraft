extends SceneTree
## Owner #133, #134 (Balance Altar, phase B1; docs/devlog/parts/game-altar-b.md): pictures of the temple's places for a
## look without the editor or the emulator: the arrival (the temple on its clouds at sunset; the door open), the
## Entrance Hall (wide, the ring of frozen altars, the dark chandelier), an altar as the child plays it (a gem lifted,
## amber, waiting for its twin), an altar close up (the crystal and its sleeping Glimmer, the chains, the runes), a
## crystal freed, the Great Altar at the chorus, the lit chandelier from below, and the Sky Room. Windowed (headless
## draws nothing), under nice, one at a time, into a private folder:
##   XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/altar_shots.gd \
##     -- [--only=hall,altar] [--wide]
## PNGs (and small JPGs for the notes) go to user://altar_shots/ (the path is printed); prints ALTAR_SHOT lines with each
## picture's draw calls.


func _initialize() -> void:
	var steps: Node = load("res://tools/altar_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
