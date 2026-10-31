extends SceneTree
## Headless smoke run of Mercury (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/mercury_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Mercury (its card: three facts, LAND), land on
## Mercury's landing pad (its own world, sandbox_23: gravity 0.38, space's black sky by day with the Sun three times as
## big, Venus, Earth and our Moon as tiny points, peace, no animals, MY MAP's pad and four sights, the Space Book's mark
## and the portal home), fall slowly, find the Sunshade Lander (stand on its deck), stand by the explorers' thermometer,
## on the long cliff's face, on a big crater's peak and on the ice of the ice crater (their facts; the heat never hurts),
## and walk home through the portal by the pad (back on the take-off column, home's Sun again). It replaces the Sandbox
## worlds of Green Meadows and Mercury in that folder, so run it with a private user folder whose path contains "smoke"
## (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-mercury-smoke godot --headless --path . --script res://tools/mercury_smoke.gd
## Prints MERCURY_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MERCURY_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/mercury_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
