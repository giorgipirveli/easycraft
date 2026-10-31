extends SceneTree
## Pictures of prospecting (spec §26) for a look without the emulator: a NEW Green Meadows Sandbox world at seed 12345
## (Gemma's camp, the river's gold gravel, the quartz vein in the hill, the rusty iron hilltop, the coal seam in a
## hillside, her board's quests, a map step and a find's card), then a NEW desert Sandbox world at the same seed (the
## copper mesa's malachite, the oil seep, the salt flat, an oil well on its dome), blocky, some realistic too.
## Windowed (headless draws nothing); the steps are in tools/prospecting_shots_steps.gd. It starts new worlds in the
## Sandbox slots of Green Meadows and the desert, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-prospecting-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/prospecting_shots.gd
## Small JPEGs (960 x 540) go to $XDG_DATA_HOME/prospecting_shots/; prints PROSPECT_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("prospecting_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/prospecting_shots_steps.gd").new())
