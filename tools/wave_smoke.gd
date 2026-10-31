extends SceneTree
## Headless smoke run of the Monster Totem and its waves in the real sandbox (M2 Task 9); the steps are
## in tools/wave_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that
## use autoloads). It starts a NEW Sandbox world (Survivor has no Totem since owner feedback #44; Monster Wave's
## automatic waves are checked by tools/survivor_games_smoke.gd), so run it with a private user folder whose
## path contains "smoke" (with a copy of profile.json in it):
##   XDG_DATA_HOME=/tmp/easycraft-wave-smoke godot --headless --path . --script res://tools/wave_smoke.gd
## Prints WAVE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("WAVE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/wave_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
