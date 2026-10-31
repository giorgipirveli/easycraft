extends SceneTree
## Owner #101 (VR on the Meta Quest, P5's measurement; P1's draw budget): Green Meadows through the VR rig on the desktop,
## before each headset run. It turns the desktop preview on (Vr.preview: the fake head, the `vr` preset, the blocky
## style), starts a new Sandbox world (seed 12345), waits until the child stands, lets 5 s settle, then prints a
## VR_BENCH line every second for 20 s (VrBench: fps, the worst frame, frames over 28 ms, draws, primitives, objects,
## process, physics and GPU ms) and a summary line, VR_BENCH summary, with the averages and the most draws.
## The draws are one eye's (multiview draws both eyes in one pass, so the headset's count is about the same); the frame
## times are this PC's, never a Quest's (its XR2 is several times slower): only the headset says those (the same lines in
## logcat). A window opens (draws need a renderer); run it with a private user folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-vr-bench-smoke nice godot --path . --resolution 1440x1584 --rendering-method mobile \
##     --script res://tools/vr_bench.gd [-- --seconds=20 --turns=4]
## --turns: snap turns of 90° through the run (the four ways from the spawn).

func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("VR_BENCH refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/vr_bench_steps.gd").new())
