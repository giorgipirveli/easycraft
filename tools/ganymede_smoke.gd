extends SceneTree
## Headless smoke run of Ganymede (cosmos, spec §21b.2) in the real sandbox; the steps are in
## tools/ganymede_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Ganymede (its card: three facts, LAND), land on
## the pad (its own world, sandbox_28: gravity 0.146, space's black sky with stars by day, a small Sun, Jupiter big and
## banded in the east, Io and Europa, peace, no animals, MY MAP's pad and seven sights, the Space Book's mark, the robots
## and the aliens' camp on the smooth plain, the Jupiter Lookout, the sky shows, the portal home), fall slowly, jump high,
## find the Solar Wing Lander (stand on its deck), stand at the Jupiter Lookout, the grooved terrain, the dark terrain, the
## bright ray crater, the polar frost, the Aurora Watch and the ocean drill (their facts), see the auroras glow at night
## and Io and Europa move, drop into the drill's shaft and jump out (nothing hurts), and walk home through the portal by
## the pad (back on the take-off column, home gravity again).
## It replaces the Sandbox worlds of Green Meadows and Ganymede in that folder, so run it with a private user folder whose
## path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-ganymede-smoke godot --headless --path . --script res://tools/ganymede_smoke.gd
## (or tools/smoke_all.sh ganymede). Prints GANYMEDE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("GANYMEDE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/ganymede_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
