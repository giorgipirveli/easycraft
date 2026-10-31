extends SceneTree
## Headless smoke run of Saturn's rings (cosmos, spec §21b.2) in the real sandbox; the steps are in
## tools/rings_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Saturn (its card: three facts, "Saturn's
## rings: LAND"), land on the landing chunk's pad (its own world, sandbox_25: gravity 0.05, space's black sky with stars
## by day, the Sun about ten times smaller, Saturn huge over the northern horizon, peace, no animals, MY MAP's pad and six
## sights, the Space Book's mark, the robots and the aliens' camp, the portal home), step off the landing chunk into the
## open space between the chunks (a slow float down, then the space suit's little jets carry the child back to the ice),
## find the Ring Explorer (walk into it), stand at the Saturn scope, the Ring Station, the Cassini Division's beacon, the C
## ring's, the F ring's and on top of Pan (their facts; nothing hurts), and walk home through the portal by the pad (back
## on the take-off column, home gravity again). It replaces the Sandbox worlds of Green Meadows and the rings in that
## folder, so run it with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-rings-smoke godot --headless --path . --script res://tools/rings_smoke.gd
## (or tools/smoke_all.sh rings). Prints RINGS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("RINGS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/rings_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
