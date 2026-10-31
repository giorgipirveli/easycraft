extends SceneTree
## Headless smoke run of MAKE MY SHORT in the real sandbox (spec §5.12b "As built (My Shorts)"); the steps are in
## tools/my_shorts_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## It starts a NEW Sandbox world and writes the profile, so run it with a private, fresh user folder:
##   XDG_DATA_HOME=/tmp/easycraft-my-shorts-smoke godot --headless --path . --script res://tools/my_shorts_smoke.gd
## (or tools/smoke_all.sh my_shorts). Prints MY_SHORTS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MY_SHORTS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/my_shorts_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
