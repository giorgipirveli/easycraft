extends SceneTree
## Headless smoke run of night monsters in the real sandbox (M2 Task 4); the steps are in
## tools/monster_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that
## use autoloads). It starts a NEW world (Survivor, or Sandbox with --smoke-sandbox), so run it with a
## private user folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-monster-smoke godot --headless --path . --script res://tools/monster_smoke.gd
##   XDG_DATA_HOME=/tmp/easycraft-monster-smoke2 godot --headless --path . --script res://tools/monster_smoke.gd -- --smoke-sandbox
## Prints MONSTER_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MONSTER_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/monster_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
