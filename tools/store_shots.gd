extends SceneTree
## The Google Play store pictures (docs/store/screenshots.md): eight 1920 x 1080 phone screenshots with the HUD and a
## HUD-less photo for the 1024 x 500 feature graphic, taken in real Sandbox worlds through the real systems (the chat
## commands' runner, the wand's spark request, the portal frames, the pets', stealth's and the courses' requests).
## Windowed (headless draws nothing); the steps are in tools/store_shots_steps.gd. It starts NEW Sandbox worlds and
## writes a made-up player's profile, so give it a private folder whose path contains "shots"; `--touch` shows the
## phone's touch HUD:
##   XDG_DATA_HOME=/tmp/easycraft-store-shots godot --path . --disable-vsync --resolution 1920x1080 \
##     --script res://tools/store_shots.gd -- --touch [--only=wake,size,...]
## JPEGs (1920 x 1080, quality 0.92, RGB) go to $XDG_DATA_HOME/store_shots/; prints STORE_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		print("STORE_SHOT refused: set XDG_DATA_HOME to a private folder (its path must contain 'shots')")
		quit(2)
		return
	var script: GDScript = load("res://tools/store_shots_steps.gd")
	if script == null or not script.can_instantiate():
		print("STORE_SHOT failed: tools/store_shots_steps.gd does not load")
		quit(1)
		return
	root.add_child.call_deferred(script.new())
