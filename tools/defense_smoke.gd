extends SceneTree
## Headless smoke run of doors, spike traps and lanterns in the real sandbox (M2 Task 8), on real
## terrain with the real voxel collision; the steps are in tools/defense_smoke_steps.gd (loaded at run
## time: a --script SceneTree cannot compile scripts that use autoloads). It starts a NEW Sandbox world,
## so run it with a private user folder whose path contains "smoke" (and a copy of profile.json):
##   XDG_DATA_HOME=/tmp/easycraft-defense-smoke godot --headless --path . --script res://tools/defense_smoke.gd
## Prints DEFENSE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("DEFENSE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/defense_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
