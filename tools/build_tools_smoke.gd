extends SceneTree
## Headless smoke run of the building tools in the real sandbox (M3 Task 8); the steps are in
## tools/build_tools_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world and writes the profile (a built hat), so run it with a private, fresh
## user folder holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-build-smoke godot --headless --path . --script res://tools/build_tools_smoke.gd
## Prints BUILD_SMOKE lines (checks and timings); exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("BUILD_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/build_tools_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
