extends SceneTree
## Headless smoke run of the tutorial with Pip in the real sandbox (M3 Task 15); the steps are in
## tools/tutorial_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## It starts a NEW solo Survivor world and writes the profile (the tutorial's state, Pip, the hat, gold), so run it
## with a private, fresh user folder holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-tutorial-smoke godot --headless --path . --script res://tools/tutorial_smoke.gd
##   (-- --seed=<n> for another world)
## Prints TUTORIAL_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TUTORIAL_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/tutorial_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
