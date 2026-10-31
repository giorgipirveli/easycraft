extends SceneTree
## Headless smoke run of the Stone Golem and the portal in the real sandbox (M2 Task 10); the steps are
## in tools/boss_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that
## use autoloads). It starts a NEW world (Survivor, through the sandbox's start_boss hook that the Totem
## uses; or Sandbox with --smoke-sandbox, through /summon golem's summon_boss), so run it with a private
## user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-boss-smoke godot --headless --path . --script res://tools/boss_smoke.gd
##   XDG_DATA_HOME=/tmp/easycraft-boss-smoke2 godot --headless --path . --script res://tools/boss_smoke.gd -- --smoke-sandbox
## Prints BOSS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("BOSS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/boss_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
