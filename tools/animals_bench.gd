extends SceneTree
## Owner feedback #41's performance check: 40 animals of the new kinds around a player on a flat stand-in world (a
## pond for the swimmers, an ice patch for the sliders, trees for the climbers and dens) against 40 of M1b's farm
## animals, simulated by the host's real Animal code in alternating 2 s blocks (a busy PC slows both alike). The
## steps are in tools/animals_bench_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that
## use autoloads). Writes nothing.
##   godot --headless --path . --script res://tools/animals_bench.gd [-- --seconds=40]
## Prints ANIMALS_BENCH lines (ms per frame for the 40 animals: average, 99th percentile, worst; per animal); exit 0.


func _initialize() -> void:
	var steps: Node = load("res://tools/animals_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
