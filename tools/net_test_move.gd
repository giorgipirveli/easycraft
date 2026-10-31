extends SceneTree
## tools/net_test.sh --move (owner #99): two test games, each in its own user folder, move one account from the "old"
## device to the "new" one as a child does, with proof: the old game claims a name and backs its profile up; the new one
## types the same name (taken), asks to move the game there and prints its 6-digit code; the script hands that code to
## the old game (a file: a person reading one screen and typing on the other), which first types a wrong code, then the
## right one; the new game takes its one-time key and plays as the account (its name and progress); the old game hears
## "Your game is on a computer now too." The steps are in tools/net_test_move_steps.gd (loaded at run time: a --script
## SceneTree cannot compile scripts that use autoloads). User args: --role=old|new --me=<name> --server=<address>
## --code-file=<path> (old). Prints NETMOVE lines; exits 0 when its side passed.


func _initialize() -> void:
	if OS.get_environment("XDG_DATA_HOME") == "":
		print("NETMOVE refused: set XDG_DATA_HOME to the test game's own folder")
		quit(2)
		return
	var steps: Node = load("res://tools/net_test_move_steps.gd").new()
	root.add_child.call_deferred(steps)
