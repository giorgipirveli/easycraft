extends SceneTree
## Pictures of "invent it" (owner #78, spec §21e) for a look without the emulator: a NEW Sandbox world of Green Meadows
## at seed 12345: the child in the hot-air balloon, the plane and the jet, and holding the kite up (from a camera of the
## tool's own a little way off), blocky then realistic; then the Inventions book (the balloon's page, the rocket's
## bottle rocket) and the try's banner over the world. Windowed (headless draws nothing); the steps are in
## tools/invention_shots_steps.gd. It starts a new Sandbox world, so give it a private folder whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-invention-shots godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/invention_shots.gd
## Small JPEGs (640 x 360) go to $XDG_DATA_HOME/invention_shots/; prints INVENTION_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("invention_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/invention_shots_steps.gd").new())
