extends SceneTree
## Owner #110 (VR round 4, VR-HANDS; docs/devlog/parts/vr-r4-hands.md): the draws of round 4's hands features beside P5's
## budget (at most 100 in play), through the desktop's VR preview on the Quest APK's platform (tools/vr_bench.gd's way):
## a NEW Sandbox (Green Meadows, seed 12345), then a few seconds each of: playing, the Build Table open with a small
## build on it, a brick in the hand with its ghost, MODEL VIEW. A line a phase:
##   VR_HANDS_BENCH phase=<p> frames=<n> fps=<f> draws=<avg> most=<max> draws_3d=<avg> draws_2d=<avg>
## --taps also asks a world tap every second through BlockInteractor.in_space and once the old way (straight from
## _process): with `physics/3d/run_on_separate_thread` on (an override.cfg) the old way logs the engine's "Space state is
## inaccessible" and the new way none (VR P5's follow-up a). A window opens (draws need a renderer); a private user
## folder whose path holds "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-vr-hands-smoke nice godot --display-driver x11 --disable-vsync --path . \
##     --resolution 1440x1584 --rendering-method mobile --script res://tools/vr_hands_bench.gd [-- --seconds=6 --taps]

func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("VR_HANDS_BENCH refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/vr_hands_bench_steps.gd").new())
