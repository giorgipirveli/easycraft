extends SceneTree
## What everything merged costs the host together (M5 Task 3, spec §15.3): a new Survivor world of one universe, the
## player standing (in the wild meadows: in the nearest village, among its villagers), a quiet window, then 20
## monsters of the universe around the player, two pets and a tamed, saddled horse (a camel in the desert) that the
## player rides in a circle, the Gold Farm, a race running and the universe's own animals: a busy window. Prints the
## physics step and process times per frame of both windows (HOST_BENCH lines); steps in tools/host_bench_steps.gd.
## It starts a NEW world in that universe's Survivor slot, so run it with a private user folder whose path contains
## "smoke" (with a copy of profile.json under godot/app_userdata/EasyCraft/):
##   XDG_DATA_HOME=/tmp/easycraft-bench-smoke godot --headless --max-fps 60 --path . --script res://tools/host_bench.gd -- --universe=2
## (--max-fps 60: a phone's frame rate, so the main thread's CPU per frame is a frame's cost). Options: `--smoke-seed=<n>`
## repeats a world; `--preset=low` runs as a LOW phone (6 monsters, its caps); `--without=ride,monsters,farm,pets,race`
## leaves parts out; `--off=<names or index ranges>` switches scene nodes off for the busy window (compare two runs).
## Exits 0 when the scene came together (every part set up).


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("HOST_BENCH refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/host_bench_steps.gd").new()
	root.add_child.call_deferred(steps)
