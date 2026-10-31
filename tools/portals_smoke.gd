extends SceneTree
## Headless smoke run of universe portals you build (owner feedback #39, spec §14.2a) in the real sandbox; the steps
## are in tools/portals_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). Sandbox: a portal frame with the Desert Crystal's core travels to the desert's own Sandbox world
## (`sandbox_2`), a portal back stands at the arrival point, and walking into it comes back out in front of the first
## portal. Survivor: the crystals of the universes reached come into the bag, a crystal placed in a frame (paid from
## the bag) travels with the bag to the desert's Survivor world, and its portal back stands there. It replaces the
## Sandbox and Survivor worlds of universes 1 and 2, so run it with a private user folder whose path contains "smoke"
## (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-portals-smoke godot --headless --path . --script res://tools/portals_smoke.gd
## Prints PORTALS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PORTALS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/portals_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
