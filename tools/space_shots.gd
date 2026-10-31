extends SceneTree
## Pictures of a space world (spec §21, §21b) for a look without the emulator: a NEW Sandbox world of universe N
## (default 19, Mars) at seed 12345, from above its landing pad: the four directions by day, one at sunset (the
## horizon's glow) and one at night, first blocky, then realistic. Windowed (headless draws nothing); the steps are in
## tools/space_shots_steps.gd. It starts a new world in that universe's Sandbox slot, so give it a private folder
## whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-space-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/space_shots.gd -- --universe=19
## Small JPEGs (640 x 360) go to $XDG_DATA_HOME/space_shots/; prints SPACE_SHOT lines. `-- --universe=20 --sights` adds
## a view of each of the world's big sights (SpaceShape.sights) in both styles; `-- --universe=19 --colony` only the
## colony's views (spec §21c: from the pad, from above, under the Great Dome by day and night, the homes, the control room,
## the rocket, the ice mine); `-- --universe=41 --close` the New Seven Wonders up close (owner #78's second tour);
## `-- --universe=41 --nature` only the Seven Natural Wonders as a child sees them (the third tour: the canyon, the reef
## and its underwater room, the bay and the Sugarloaf, Everest, the frozen lake by day and the northern lights at night,
## Parícutin, Victoria Falls, the region from high above).


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("space_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/space_shots_steps.gd").new())
