extends SceneTree
## One of the two games of tools/ghost_net_test.sh (M4 ghost races over a real Nakama server): the steps are in
## tools/ghost_net_test_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). User args: --role=hopper|mia --server=<host:port> --hopper=<name> --mia=<name>.
## Prints GHOSTNET lines; exits 0 when its checks passed.


func _initialize() -> void:
	var steps: Node = load("res://tools/ghost_net_test_steps.gd").new()
	root.add_child.call_deferred(steps)
