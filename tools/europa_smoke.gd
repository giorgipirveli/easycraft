extends SceneTree
## Headless smoke run of Europa (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/europa_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Europa (its card: three facts, LAND), land on
## Europa's landing pad (its own world, sandbox_20: gravity 0.13, space's black sky with Jupiter and two of its moons,
## peace, no animals, MY MAP's pad and sights, the Space Book's mark, the plumes and the portal home), fall slowly, find
## the Ice Lander (stand on its deck), ride a water plume up from its vent, climb the ice cliffs, reach the ocean at the
## bottom of the well (its fact), and walk home through the portal by the pad (back on the take-off column). It replaces
## the Sandbox worlds of Green Meadows and Europa in that folder, so run it with a private user folder whose path
## contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-europa-smoke godot --headless --path . --script res://tools/europa_smoke.gd
## Prints EUROPA_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("EUROPA_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/europa_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
