extends SceneTree
## Owner feedback #50 ("a lot chicken sounds only everywhere"): how many animal calls a child hears in a real
## Meadows world, and of which kinds. Starts a NEW Sandbox world (by day), lets the animals come, then counts
## every Audio play by sound name for a while (standing at the spawn, or walking with --walk). The steps are
## in tools/animal_voices_measure_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts
## that use autoloads). It writes a world, so run it with a private user folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-voices-smoke godot --headless --path . --script res://tools/animal_voices_measure.gd -- --seed=7 --seconds=150 [--walk]
## Prints VOICES lines (a summary per kind at the end) and exits 0.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("VOICES refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/animal_voices_measure_steps.gd").new()
	root.add_child.call_deferred(steps)
