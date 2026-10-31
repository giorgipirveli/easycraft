extends SceneTree
## Owner #94: what the meadow's ambient life (world/life: the birds by day, the fireflies at night) costs the frame. A new
## Sandbox world in Green Meadows, the player standing on the grass; four windows of WINDOW seconds each, the life on
## and off by turns, by day (the birds fly) and at night (the fireflies blink): day-on, day-off, night-on, night-off.
## Printed per window (LIFE_BENCH lines): the main thread's own CPU per frame (Linux /proc: the number to compare on a
## shared PC), the process time per frame (Performance), the life's own tick (it is stepped by hand in the "on"
## windows) and what showed (fireflies emitting, birds flying). Headless: no drawing is measured (the GPU's share is
## the emulator's to show). It starts a NEW world in the Sandbox slot, so run it with a private user folder whose path
## contains "smoke" (with a copy of profile.json under godot/app_userdata/EasyCraft/):
##   XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --max-fps 60 --path . --script res://tools/life_bench.gd
## Options after `--`: --smoke-seed=<n> (default 20260925), --window=<seconds> (default 15), --voxel-threads=<n> (2: a
## phone's share, as tools/frame_probe.gd advises).


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("LIFE_BENCH refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/life_bench_steps.gd").new()   # loaded now: it names the autoloads
	root.add_child.call_deferred(steps)

