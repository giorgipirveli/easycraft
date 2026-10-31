extends SceneTree
## Headless cost check of the Dragon Realm's flyers (owner #39): one physics step of 20 wisps, of 20 shadow bats
## and of 20 ice bats (the flyer they are measured against) around a walking player on a flat stand-in world,
## stepped by hand in alternating 2 s blocks so a busy PC slows every kind alike. The steps are in
## tools/dragon_monster_bench_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). Writes nothing.
##   godot --headless --path . --script res://tools/dragon_monster_bench.gd
## Prints DRAGON_BENCH lines (per physics step and per drawn frame for each kind); exit 0.


func _initialize() -> void:
	var steps: Node = load("res://tools/dragon_monster_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
