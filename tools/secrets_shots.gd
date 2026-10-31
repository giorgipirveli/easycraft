extends SceneTree
## Screenshots of the secrets (M2 Task 16) in a new Sandbox world of seed 12345, for a look at the models,
## glows, plate pictures and structures without the editor. Windowed (headless draws nothing); the steps are
## in tools/secrets_shots_steps.gd. It starts a NEW world in the sandbox slot, so give it a private folder:
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/secrets_shots.gd
## PNGs go to $XDG_DATA_HOME/secret_shots/; prints SECRETS_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		print("SECRETS_SHOT refused: set XDG_DATA_HOME to a private folder (its path must contain 'shots')")
		quit(2)
		return
	var steps: Node = load("res://tools/secrets_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
