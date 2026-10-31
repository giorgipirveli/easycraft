extends SceneTree
## Headless smoke run of Play W1 (owner #132: learning inside the world) in the real sandbox; the steps are in
## tools/discovery_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## A new Green Meadows Sandbox world: DISCOVER is MORE's first picture; it opens the School over the world (the avatar
## held) and BACK gives the world back; the pause menu's DISCOVER does the same; Professor Hoot comes after the child has
## stood a while (his card, his line spoken) and not again the same day. It replaces the first Sandbox world of Green
## Meadows in that folder, so run it with a private user folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-discovery-smoke godot --headless --path . --script res://tools/discovery_smoke.gd
## Prints DISCOVERY_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("DISCOVERY_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/discovery_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
