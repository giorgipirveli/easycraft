extends SceneTree
## Pictures of a Launch Site (spec §21d) for a look without the emulator: a NEW Green Meadows Sandbox world at seed
## 12345, its Launch Site stamped, the Moon rocket of tools/mission_smoke_steps.gd built on the pad, then views: the
## site from the spawn's side, the rocket close up, and the Mission Board open on each page (MISSIONS, MY ROCKET, PARTS),
## first blocky, then realistic. Windowed (headless draws nothing); the steps are in tools/launch_shots_steps.gd. It
## starts a new world in the Sandbox slot, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-launch-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/launch_shots.gd
## Small JPEGs (960 x 540) go to $XDG_DATA_HOME/launch_shots/; prints LAUNCH_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("launch_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/launch_shots_steps.gd").new())
