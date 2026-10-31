extends SceneTree
## Headless smoke run of Mars (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/mars_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Mars (its card: three facts, LAND), land on
## Mars's landing pad (its own world, sandbox_19: gravity 0.38, the butterscotch sky with Phobos and Deimos, peace, no
## animals, MY MAP's pad and sights, the Space Book's mark, the portal home), fall slowly, find the rover (climb onto
## its deck), stand on the giant volcano's summit (its fact), and walk home through the portal by the pad (back on the
## take-off column). It replaces the Sandbox worlds of Green Meadows and Mars in that folder, so run it with a private
## user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-mars-smoke godot --headless --path . --script res://tools/mars_smoke.gd
## Prints MARS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MARS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/mars_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
