extends SceneTree
## The look's fixed views and their bench (the visuals brief, 2026-10-01): pictures of a world in both styles at fixed
## places and times, and each view's frame time, so a change to the light, the sky, the fog, the water or the blocks
## can be judged by eye and by cost, before and after. Windowed (headless draws nothing); the steps are in
## tools/look_shots_steps.gd. A NEW Sandbox world goes into the Sandbox slot, so give it a private folder whose path
## contains "shots" (with a copy of profile.json):
##   XDG_DATA_HOME=/tmp/easycraft-look-shots godot --path . --disable-vsync --resolution 1600x720 \
##     [--rendering-method gl_compatibility] --script res://tools/look_shots.gd -- --universe=1 --tag=before
## `--universe=1` Green Meadows (noon, sunset, night from above the spawn; the ground at eye level; a cave; the sea's
## shore), another universe (16 the Moon, 19 Mars, 24 Venus, 25 Saturn's rings, 41 the Wonders) noon, sunset and night
## from above its landing; `--menu` the title screen instead; `--style=blocky|realistic` one style only (both by
## default); `--views=noon,ground` only these; `--frames=90` frames measured per view; `--no-shots` the bench only;
## `--env=tonemap_mode:3,fog_begin:0.5` Environment settings to try; `--no-shadows`, `--no-lantern` (a cost alone).
## JPEGs (1200 wide) go to $XDG_DATA_HOME/look_shots/<tag>/<renderer>/; each view prints a LOOK_BENCH line: the
## frames' average and worst wall time, the GPU's and the CPU's render time (RenderingServer's measure), draw calls
## and primitives. Compare the GPU time between runs: the wall time on this shared PC is other programs' too.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("look_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/look_shots_steps.gd").new())
