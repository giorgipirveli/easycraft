extends SceneTree
## Headless smoke run of Venus's cloud city (cosmos, spec §21b.2) in the real sandbox; the steps are in
## tools/venus_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Venus (its card: three facts, LAND), land on the
## cloud city's landing pad (its own world, sandbox_24: gravity 0.9, a golden sky of its own with the Sun a little bigger
## and rising in the west, Earth and our Moon as tiny points, peace, no animals, MY MAP's pad and five sights, the Space
## Book's mark, the lightning far below, the robots and the aliens' camp, the portal home), step off the landing deck
## (a warm breeze lifts the child back, long before the clouds), find the Research Blimp (walk into its gondola), stand
## at the cloud scope, the airship dock, the sky garden, the cloud homes and the west lookout (their facts; nothing
## hurts), and walk home through the portal by the pad (back on the take-off column, home's Sun rising in the east
## again). It replaces the Sandbox worlds of Green Meadows and Venus in that folder, so run it with a private user folder
## whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-venus-smoke godot --headless --path . --script res://tools/venus_smoke.gd
## Prints VENUS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("VENUS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/venus_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
