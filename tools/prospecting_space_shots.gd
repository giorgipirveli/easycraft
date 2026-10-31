extends SceneTree
## Pictures of prospecting on the Moon and Mars (spec §26.5) for a look without the emulator: a NEW Moon Sandbox world
## at seed 12345 (Gemma's space camp by the landing pad, the ice in a dark crater's floor, the dark sea with ilmenite,
## the helium-3 sea, KREEP on a crater's rim, an iron meteorite in a small crater, her board's quests, a map step and a
## find's card), then a NEW Mars Sandbox world at the same seed (the camp, the ground ice in a fresh crater, the
## blueberries, the dark sand, the salt basin, a meteorite on the plain), blocky, some realistic too. Windowed (headless
## draws nothing); the steps are in tools/prospecting_space_shots_steps.gd. It starts new worlds in the Sandbox slots of
## the Moon and Mars, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-prospecting-space-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/prospecting_space_shots.gd
## Small JPEGs (960 x 540) go to $XDG_DATA_HOME/prospecting_space_shots/; prints PROSPECT_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("prospecting_space_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/prospecting_space_shots_steps.gd").new())
