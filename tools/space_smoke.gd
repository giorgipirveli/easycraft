extends SceneTree
## Headless smoke run of space (owner feedback #55, spec §21) in the real sandbox; the steps are in
## tools/space_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the sky turns to space, "Where shall we land?" holds the game, the
## Moon card lands on the Moon's landing pad (its own world, sandbox_16: gravity, sky, peace, MY MAP, the portal home),
## the Moon Base is found, flying up again offers HOME first and home lands on the take-off column. Survivor: the bag
## flies to Planet Boing and comes home through the portal by the landing pad. It replaces the Sandbox and Survivor
## worlds of Green Meadows and the space worlds in that folder, so run it with a private user folder whose path contains
## "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-space-smoke godot --headless --path . --script res://tools/space_smoke.gd
## Prints SPACE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("SPACE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/space_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
