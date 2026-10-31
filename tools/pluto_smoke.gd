extends SceneTree
## Headless smoke run of Pluto (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/pluto_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Pluto (its card: three facts, LAND), land on the
## pad (its own world, sandbox_26: gravity 0.063, a black sky with stars by day and a blue haze, the Sun a tiny bright
## star, Charon big and still in the west, peace, no animals, MY MAP's pad and six sights, the Space Book's mark, the
## robots and the aliens' camp, the Charon Lookout, the portal home), fall slowly, jump very high, find the Balloon Lander
## (stand on its deck), stand at the Charon Lookout, on the heart's plain, on a floating hill, on the ice mountains' top,
## in the red-brown lands and on the heart's bright side (their facts; nothing hurts), and walk home through the portal by
## the pad (back on the take-off column, home gravity again). It replaces the Sandbox worlds of Green Meadows and Pluto in
## that folder, so run it with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-pluto-smoke godot --headless --path . --script res://tools/pluto_smoke.gd
## (or tools/smoke_all.sh pluto). Prints PLUTO_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PLUTO_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/pluto_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
