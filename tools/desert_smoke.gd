extends SceneTree
## Headless smoke run of the Sandstorm Desert on real terrain (M3 Task 2); the steps are in
## tools/desert_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Survivor world of universe 2, so run it with a private user folder whose path
## contains "smoke" (with a copy of profile.json under godot/app_userdata/EasyCraft/):
##   XDG_DATA_HOME=/tmp/easycraft-desert-smoke godot --headless --path . --script res://tools/desert_smoke.gd
## `-- --smoke-seed=<n>` repeats a world. Prints DESERT_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("DESERT_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/desert_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
