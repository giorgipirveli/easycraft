extends SceneTree
## Headless smoke run of the Survivor games and crafting in the real sandbox (owner feedback #33, #34; spec
## §12.18, §12.19); the steps are in tools/survivor_games_smoke_steps.gd (loaded at run time: a --script
## SceneTree cannot compile scripts that use autoloads). It starts NEW Survivor worlds (Build to Survive,
## then Monster Hunter), so run it with a private, fresh user folder holding a profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-games-smoke-1 godot --headless --path . --script res://tools/survivor_games_smoke.gd
## Prints GAMES_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("GAMES_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/survivor_games_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
