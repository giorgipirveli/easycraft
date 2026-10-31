extends SceneTree
## Headless smoke run of weapons in the real sandbox (M1b Task 11); the steps are in
## tools/weapons_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts
## that use autoloads). It starts a NEW world in the sandbox slot, so run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-smoke godot --headless --path . --script res://tools/weapons_smoke.gd
## Prints WEAPONS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("WEAPONS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/weapons_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
