extends SceneTree
## Pictures of the Star Map (spec §21b.1) for a look without the editor or the emulator: the map from Green Meadows,
## a card (the Moon: LAND; Mars: coming soon; Jupiter: no ground), and the map from the Moon (HOME by STAY HERE).
## Windowed (headless draws nothing):
##   XDG_DATA_HOME=/tmp/easycraft-star-shots godot --path . --disable-vsync --script res://tools/star_map_shots.gd [-- --wide]
## --wide: the 20:9 canvas (1600 × 720). PNGs go to user://star_map_shots/ (the path is printed).



func _initialize() -> void:
	var wide := OS.get_cmdline_user_args().has("--wide")
	root.size = Vector2i(1600, 720) if wide else Vector2i(1280, 720)
	var steps: Node = load("res://tools/star_map_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
