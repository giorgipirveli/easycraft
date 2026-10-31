extends SceneTree
## Headless smoke run of the M4 ghost races in the real sandbox and the real visit scene; the steps are in
## tools/ghosts_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). Two players on the game's fake server (tests/fakes/fake_online_server.gd): Hopper builds a course
## in a NEW Sandbox world and races it (his feet on the real blocks), puts his showcase up with SHARE (his race
## goes with it), beats his time (the new best replaces his ghost) and gifts Mia the whole course with his race;
## Mia visits his showcase and races his ghost, then again offline from her device's copy, then stamps his gift
## in her own world and races his ghost there. It writes worlds, so run it with a private, fresh user folder
## holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-ghosts-smoke godot --headless --path . --script res://tools/ghosts_smoke.gd
## Prints GHOSTS_SMOKE lines (and MEASURE lines); exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("GHOSTS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/ghosts_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
