extends SceneTree
## Headless cost check of creature minds (M2 Task 18): 24 animals in six herds and three bot friends
## around a player on a flat stand-in world. The steps are in tools/minds_bench_steps.gd (loaded at run
## time: a --script SceneTree cannot compile scripts that use autoloads). Writes nothing.
##   godot --headless --path . --script res://tools/minds_bench.gd
## Prints MINDS_BENCH lines (per decision, per frame with and without the animals' minds); exit 0.


func _initialize() -> void:
	var steps: Node = load("res://tools/minds_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
