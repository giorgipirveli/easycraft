extends SceneTree
## Owner #133, #134 (Inside a Leaf, phase B2; docs/design/games/leaf-voyage.md §4.5): a voyage's draws and frame times in
## a real window (headless draws nothing), its moments one after another: the garden's hook, the dive, inside the
## sunflower at its heaviest (every door open, the mist pouring, a sugar at every spot, the avatar carrying three, Hoot,
## the HUD), the desert's night at its heaviest, the end card over the bloom. Under nice, nothing else running:
##   XDG_DATA_HOME=<private dir> nice -n 10 godot --path . --disable-vsync --script res://tools/leaf_bench.gd \
##     -- [--seconds=5]
## One line a moment: LEAF_BENCH <moment> frames=<n> fps=<average> worst_ms=<the longest frame> draws=<average draw calls
## a frame> draws_max=<most>. This PC's integrated GPU is not a phone or the Quest: the emulator's and the Quest's
## checks are the lead's (the budget: 30 fps, no frame over 100 ms, at most 100 draws on the Quest).


func _initialize() -> void:
	var steps: Node = load("res://tools/leaf_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
