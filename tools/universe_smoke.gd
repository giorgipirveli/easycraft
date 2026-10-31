extends SceneTree
## Headless smoke run of the universe ladder in the real sandbox (M3 Task 5); the steps are in
## tools/universe_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that
## use autoloads). It starts a NEW Survivor world, walks into the stone circle, travels to universe 2 (a
## stand-in universe, tests/fakes/fake_universe.gd, until the desert's file is merged) with a cosmic sword
## and planks in the bag, and back again. It replaces the Survivor worlds of universes 1 and 2, so run it
## with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-universe-smoke godot --headless --path . --script res://tools/universe_smoke.gd
## Prints UNIVERSE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("UNIVERSE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/universe_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
