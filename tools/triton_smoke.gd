extends SceneTree
## Headless smoke run of Triton (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/triton_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Triton (its card: three facts, LAND), land on
## the pad (its own world, sandbox_27: gravity 0.079, a black sky with stars by day, the Sun a tiny bright star, Neptune
## huge and blue in the north-east, peace, no animals, MY MAP's pad and seven sights, the Space Book's mark, the robots
## and the aliens' camp, the Neptune Lookout, the geysers watched, the portal home), fall slowly, jump very high, find the
## Hopper Lander (stand on its deck), stand at the Neptune Lookout, a geyser, a dark streak, the pink cap, the cantaloupe
## terrain, the frozen lake and the lone crater (their facts), ride a geyser's gentle puff up and drift north-east on the
## wind (nothing hurts), and walk home through the portal by the pad (back on the take-off column, home gravity again).
## It replaces the Sandbox worlds of Green Meadows and Triton in that folder, so run it with a private user folder whose
## path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-triton-smoke godot --headless --path . --script res://tools/triton_smoke.gd
## (or tools/smoke_all.sh triton). Prints TRITON_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TRITON_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/triton_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
