extends SceneTree
## Headless cost check of the Sky Dragon's fight (owner feedback #39) against the Cake Monster's. The steps are in
## tools/sky_dragon_bench_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). Writes nothing (the arena's ground from ArenaShape in memory, a child standing near the middle).
##   godot --headless --path . --script res://tools/sky_dragon_bench.gd
## Prints SKY_BENCH lines (host step, looks, towers, world reads a second); exit 0.


func _initialize() -> void:
	var steps: Node = load("res://tools/sky_dragon_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
