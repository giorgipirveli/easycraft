extends SceneTree
## Headless smoke run of bot friends in the real sandbox (M2 Task 15); the steps are in
## tools/bots_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world, so run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-botsmoke godot --headless --path . --script res://tools/bots_smoke.gd
## Prints BOTS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("BOTS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/bots_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
