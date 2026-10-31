extends SceneTree
## Headless smoke run of buddy magic in the real sandbox (M3 Task 20b); the steps are in
## tools/buddy_magic_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world and, on real terrain through the real systems: builds a snowman next to
## the spawn and wakes it (a secret shape: its name, the reveal, the Secret Book and the album), befriends a calm
## slime with the wand's request (a pet friend that looks like a slime), beats a summoned Stone Golem (the Pebble Golem
## hops out and follows), teaches the snowman a dance with three emotes (and it dances along the fourth time), saves a
## small tower as one of My Stamps and places it (one undo takes it away), then saves the world (the snowman's trick
## and the friend's kind in world.json). It replaces the Sandbox world and writes the profile and my_stamps.json, so
## run it with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-magic-smoke godot --headless --path . --script res://tools/buddy_magic_smoke.gd
## `-- --smoke-seed=<n>` repeats a world. Prints MAGIC_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MAGIC_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/buddy_magic_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
