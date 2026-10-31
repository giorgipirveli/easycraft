extends SceneTree
## tools/net_test.sh --login (owner #105): two test games, each in its own user folder, as a child plays on two devices:
## the "a" game claims a name, makes the account's password and backs its profile up; the "b" game (a new device, its own
## first-launch name) types that name with a wrong password (refused), then the right one, and plays as the account (its
## name and progress); the "a" game's link closes by itself, and its next sign-in says "You logged in on another device.
## LOG IN to play here." without making a new account (the server's 404 for create=false). The steps are in
## tools/net_test_login_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## User args: --role=a|b --me=<name> --password=<password> --server=<address>. Prints NETLOGIN lines; exits 0 when its
## side passed.


func _initialize() -> void:
	if OS.get_environment("XDG_DATA_HOME") == "":
		print("NETLOGIN refused: set XDG_DATA_HOME to the test game's own folder")
		quit(2)
		return
	var steps: Node = load("res://tools/net_test_login_steps.gd").new()
	root.add_child.call_deferred(steps)
