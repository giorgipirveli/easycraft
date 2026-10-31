extends SceneTree
## The rocket flight (owner #79, #86, #87; spec §25.3) played in the real sandbox for a look and a measurement without the
## emulator: a NEW Sandbox world (seed 12345), after SETTLE seconds standing there a test rocket flown to world N through
## the sandbox's fly_rocket (the missions' way), a child who presses what is asked at once and holds the burns; pictures
## at the big moments (in a window) and the frame times of every phase (FLIGHT_FRAMES lines: frames, the average and
## worst frame, how many over 33, 50 and 100 ms, and the flight's own tick; headless measures the CPU side only).
## It starts a new world in the Sandbox slot, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-flight-shots godot --path . --resolution 1280x720 \
##     --script res://tools/flight_shots.gd -- --dest=16
## -- --landing: the Star Map's landing on its own (owner #87); --style=realistic; --no-shots (frame times only).
## Small JPEGs (640 x 360) go to $XDG_DATA_HOME/flight_shots/.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("flight_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/flight_shots_steps.gd").new())
