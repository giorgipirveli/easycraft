extends SceneTree
## Headless smoke run of the cars in the real sandbox (owner #109); the steps are in tools/cars_smoke_steps.gd (loaded at
## run time: a --script SceneTree cannot compile scripts that use autoloads). It starts a NEW Sandbox world and, on real
## terrain with the real voxel library and physics, through the real systems (the garage's request, the RIDE button, the
## stick as Input actions, HOP OFF): every ground car is called, driven 300 m along a stone road the run lays ahead of it
## (an endless straight line from the spawn: 1.8 km in all, so the world streams ahead of every car, the race car at
## 14 m/s), and left; the two flying cars take off with JUMP, fly 300 m, LAND and are left. It checks each car's top
## speed (never past its kind's; 14 m/s on the ground at most, the paid Fly's 11 in the air), the flight ceiling, that
## HOP OFF is never inside blocks, that the ground 24 m ahead was ready while a car went fast, and that the save keeps the
## child's 4 cars out. It replaces the Sandbox world, so run it with a private user folder whose path contains "smoke"
## (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-cars-smoke godot --headless --path . --script res://tools/cars_smoke.gd
## `-- --smoke-seed=<n>` repeats a world; `-- --kinds=race_car,sky_taxi` only those. Prints CARS_SMOKE lines (a cost line
## per car: frames, the physics step, the car's own step) and exits 0 when every check passed. (tools/smoke_all.sh runs it.)


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("CARS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/cars_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
