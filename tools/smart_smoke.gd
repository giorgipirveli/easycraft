extends SceneTree
## Headless smoke run of smart blocks and Game Blocks in the real sandbox (M3 Task 7); the steps are in
## tools/smart_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world and, on real terrain with the real voxel library and physics:
## a lever lights a lamp, a button opens a powered doorway for a second (a physics ray goes through it while
## open), a plate opens it while the player stands on it, two teleport pads carry the player across, a
## course is run (START, a coin, a checkpoint and a fall back to it, FINISH: a gold medal and the race clock),
## a bot friend races the recorded best run, and everything is saved in world.json. It replaces the Sandbox
## world, so run it with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-smart-smoke godot --headless --path . --script res://tools/smart_smoke.gd
## Prints SMART_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("SMART_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/smart_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
