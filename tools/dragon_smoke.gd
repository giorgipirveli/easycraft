extends SceneTree
## Headless smoke run of the Dragon Realm on real terrain (owner feedback #39); the steps are in
## tools/dragon_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## It starts a NEW Survivor world of universe 5, so run it with a private user folder whose path contains "smoke"
## (with a copy of profile.json under godot/app_userdata/EasyCraft/):
##   XDG_DATA_HOME=/tmp/easycraft-dragon-smoke godot --headless --path . --script res://tools/dragon_smoke.gd
## `-- --smoke-seed=<n>` repeats a world. Prints DRAGON_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("DRAGON_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/dragon_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
