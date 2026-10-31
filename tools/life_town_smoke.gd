extends SceneTree
## Headless smoke run of Life Town (owner #112, Life L2) in the real sandbox; the steps are in
## tools/life_town_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## A new Green Meadows world gets Life Town (its site found on a worker, its ground checked and its places' trees cleared
## by the host, the six places standing, the save keeping it), clear of the Theater and the Launch Site; walking up to
## each place opens Life on its Experience; TRY IT at the kitchen opens the practice room over the loaded world (the
## HUD hidden, the avatar held and kept safe), its frames measured, and STOP FOR NOW gives the world back. It replaces
## the first Sandbox world of Green Meadows in that folder, so run it with a private user folder whose path contains
## "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-life-town-smoke godot --headless --path . --script res://tools/life_town_smoke.gd
## Prints LIFE_TOWN_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("LIFE_TOWN_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/life_town_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
