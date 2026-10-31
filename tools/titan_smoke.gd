extends SceneTree
## Headless smoke run of Titan (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/titan_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Titan (its card: three facts, LAND), land on
## Titan's landing pad (its own world, sandbox_22: gravity 0.14, an orange haze by day with Saturn and its rings, the
## water shown as liquid methane, peace, no animals, MY MAP's pad and sights, the Space Book's mark and the portal home),
## fall slowly, find the Landing Probe (stand on it), reach the methane sea's beach (its fact), swim in the sea and leap
## out of it with JUMP (very floaty, no harm), stand on a dune and on the icy mountains' top and by a methane lake (their
## facts), and walk home through the portal by the pad (back on the take-off column, the water water again). It replaces
## the Sandbox worlds of Green Meadows and Titan in that folder, so run it with a private user folder whose path contains
## "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-titan-smoke godot --headless --path . --script res://tools/titan_smoke.gd
## Prints TITAN_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TITAN_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/titan_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
