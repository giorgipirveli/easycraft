extends SceneTree
## Headless smoke run of EasyCraft Shorts in the real sandbox (owner #94, spec §5.12b); the steps are in
## tools/shorts_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads). It
## starts a NEW Sandbox world and writes the profile, so run it with a private, fresh user folder:
##   XDG_DATA_HOME=/tmp/easycraft-shorts-smoke godot --headless --path . --script res://tools/shorts_smoke.gd
## (or tools/smoke_all.sh shorts). Prints SHORTS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("SHORTS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/shorts_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
