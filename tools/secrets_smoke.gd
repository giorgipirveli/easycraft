extends SceneTree
## Headless smoke run of secrets and treasures in the real sandbox (M2 Task 16); the steps are in
## tools/secrets_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world (seed 12345) in the sandbox slot, so run it with a private,
## fresh user folder:
##   XDG_DATA_HOME=/tmp/easycraft-smoke-secrets godot --headless --path . --script res://tools/secrets_smoke.gd
## Prints SECRETS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("SECRETS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/secrets_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
