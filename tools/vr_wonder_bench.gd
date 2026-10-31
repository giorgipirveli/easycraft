extends SceneTree
## Owner #110 (VR round 4, VR-WONDER; docs/devlog/parts/vr-r4-wonder.md): the draws of the three wonders beside P5's
## budget (at most 100 in play), through the desktop's VR preview on the Quest APK's platform (tools/vr_hands_bench.gd's
## way): a NEW Sandbox (Green Meadows, seed 12345), then a few seconds each of: playing, looking down, the Star Map with
## the orrery, TRUE SIZE, a planet in the hand, the telescope at 8x, the magnifier (its magnified world, then a close-up),
## the Lab bench (float or sink). A line a phase:
##   VR_WONDER_BENCH phase=<p> frames=<n> fps=<f> draws=<avg> most=<max> draws_3d=<avg> draws_2d=<avg> lens=<avg>
## (`lens`: the lens's own viewport's draws, part of draws_3d). A window opens (draws need a renderer); a private user
## folder whose path holds "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-vr-wonder-smoke nice godot --display-driver x11 --disable-vsync --path . \
##     --resolution 1440x1584 --rendering-method mobile --script res://tools/vr_wonder_bench.gd [-- --seconds=6]

func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("VR_WONDER_BENCH refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/vr_wonder_bench_steps.gd").new())
