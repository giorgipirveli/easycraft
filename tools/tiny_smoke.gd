extends SceneTree
## Headless smoke run of the wonder pack (M3 Task 21c) in the real sandbox; the steps are in tools/tiny_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads). It starts a NEW Sandbox world
## (seed 12345) in the sandbox slot, so run it with a private, fresh user folder holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-tiny-smoke godot --headless --path . --script res://tools/tiny_smoke.gd
## Prints TINY_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TINY_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/tiny_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
