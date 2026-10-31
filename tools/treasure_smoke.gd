extends SceneTree
## Headless smoke run of the treasure pack (owner feedback #42) in the real sandbox; the steps are in
## tools/treasure_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world (seed 12345) in the sandbox slot, so run it with a private,
## fresh user folder:
##   XDG_DATA_HOME=/tmp/easycraft-smoke-treasure godot --headless --path . --script res://tools/treasure_smoke.gd
## Prints TREASURE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TREASURE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/treasure_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
