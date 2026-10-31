extends SceneTree
## Headless smoke run of the co-op games in the real sandbox (M4 Wave 3, agent H); the steps are in
## tools/games_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world, so run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-games-smoke godot --headless --path . --script res://tools/games_smoke.gd
## Prints GAMES_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("GAMES_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/games_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
