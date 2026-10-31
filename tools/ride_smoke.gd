extends SceneTree
## Headless smoke run of rideable buddies in the real sandbox (M3 Task 20a); the steps are in
## tools/ride_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world and, on real terrain with the real voxel library and physics:
## builds a dragon with a SADDLE sideways next to the spawn, wakes it with the wand (the line, the quarter turn),
## gets on with the RIDE button, flies it for 60 s over the terrain from the world spawn (the autopilot's start),
## measuring frames, the physics step and the ridden buddy's own step, lands, hops off beside it (never inside
## blocks), then builds a car and drives it; the saddled buddies are saved in world.json. It replaces the
## Sandbox world, so run it with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-ride-smoke godot --headless --path . --script res://tools/ride_smoke.gd
## `-- --smoke-seed=<n>` repeats a world. Prints RIDE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("RIDE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/ride_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
