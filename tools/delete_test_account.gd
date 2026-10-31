extends SceneTree
## Deletes the online test account of the user folder it runs in (its saved device id), through the game's own
## data-rights path (OnlineService.delete_account_start / delete_account), then quits: 0 when it is gone, 1 when not.
## tools/net_test.sh --delete-accounts runs it for both games once they finished, so a run against the live server
## leaves no test accounts behind. The steps are in tools/delete_test_account_steps.gd (loaded at run time: a
## --script SceneTree cannot compile scripts that use autoloads). User args: --server=<address>, and --password=<…>
## once the account has a password (owner #105: the server asks for it).
##   XDG_DATA_HOME=<a test game's folder> godot --headless --path . --script res://tools/delete_test_account.gd -- --server=…


func _initialize() -> void:
	if OS.get_environment("XDG_DATA_HOME") == "":
		print("DELETE_ACCOUNT refused: set XDG_DATA_HOME to the test game's own folder")
		quit(2)
		return
	var steps: Node = load("res://tools/delete_test_account_steps.gd").new()
	root.add_child.call_deferred(steps)
