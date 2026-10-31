extends SceneTree
## Long frames on a world trip, headless (2026-09-28, the browser's freezes): starts a new Green Meadows Sandbox world,
## flies up for real (the jump action held in FLY), picks the Moon, and prints every frame over 50 ms with the nodes
## added in it (after the pick), for 30 s after arriving. The browser runs this logic about 10x slower (the emulator's
## Chrome: 4.7 s at the switch, 2.1 s about 7 s after arriving). Run with a private user folder whose path contains
## "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-trip-smoke godot --headless --path . --script res://tools/frame_trip.gd
## Prints TRIP lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("TRIP refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/frame_trip_steps.gd").new())
