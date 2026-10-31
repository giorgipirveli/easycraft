extends SceneTree
## Pictures of the planets' robots and aliens (owner #86, spec §21f) for a look without the emulator: a NEW Sandbox
## world of universe N (default 19, Mars; 17 or 18 for a village) at seed 12345: the helper robot, the rover buddy and
## the scout drone close up, the aliens' camp (or village) from a little way off, and each alien close up, by day,
## first blocky, then realistic. Windowed (headless draws nothing); the steps are in tools/creature_shots_steps.gd. It
## starts a new world in that universe's Sandbox slot, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-creature-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/creature_shots.gd -- --universe=19
## Small JPEGs (640 x 360) go to $XDG_DATA_HOME/creature_shots/; prints CREATURE_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("creature_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/creature_shots_steps.gd").new())
