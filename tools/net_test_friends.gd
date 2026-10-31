extends SceneTree
## tools/net_test.sh --invite, before the two games start: in one test game's user folder, sign in, claim its name
## and become friends with the other test game (the host asks, the guest says yes), as two players do. A real server
## lets only invited friends into a match (M4 consent gates); the host game then invites the guest (net_test.gd
## --net-test-invite). The steps are in tools/net_test_friends_steps.gd (loaded at run time: a --script SceneTree
## cannot compile scripts that use autoloads). User args: --role=host|guest --me=<name> --other=<name> --server=<address>.
## Prints NETFRIENDS lines; exits 0 when they are friends.


func _initialize() -> void:
	if OS.get_environment("XDG_DATA_HOME") == "":
		print("NETFRIENDS refused: set XDG_DATA_HOME to the test game's own folder")
		quit(2)
		return
	var steps: Node = load("res://tools/net_test_friends_steps.gd").new()
	root.add_child.call_deferred(steps)
