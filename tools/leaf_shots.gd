extends SceneTree
## Owner #133, #134 (Inside a Leaf, phase B1; docs/devlog/parts/game-leaf-b.md): pictures of the voyage's places for a
## look without the editor or the emulator: the garden (the hook, and the bloom), the dive's steps, under the leaf, inside
## (Act 1's open doors and mist, a cloud with the air coming in and sugar built, the blaze with the doors shut, looking up
## into the cathedral), and the cactus's stem by day and under the stars. Windowed (headless draws nothing), under nice,
## one at a time, into a private folder:
##   XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/leaf_shots.gd \
##     -- [--only=garden_droop,inside_cloud] [--wide]
## PNGs go to user://leaf_shots/ (the path is printed); prints LEAF_SHOT lines with each picture's draw calls.


func _initialize() -> void:
	var steps: Node = load("res://tools/leaf_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
