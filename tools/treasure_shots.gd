extends SceneTree
## Screenshots of the treasure pack (owner feedback #42) in a new Sandbox world of seed 12345, for a look at the
## structures, chests, ghosts, the rainbow and the Secret Book's page without the editor. Windowed (headless
## draws nothing); the steps are in tools/treasure_shots_steps.gd. It starts a NEW world in the sandbox slot,
## so give it a private folder:
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --resolution 1280x720 --script res://tools/treasure_shots.gd
## PNGs go to $XDG_DATA_HOME/treasure_shots/; prints TREASURE_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		print("TREASURE_SHOT refused: set XDG_DATA_HOME to a private folder (its path must contain 'shots')")
		quit(2)
		return
	var steps: Node = load("res://tools/treasure_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
