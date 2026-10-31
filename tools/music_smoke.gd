extends SceneTree
## Headless smoke run of the music blocks in the real sandbox (owner #110, VR round 4 idea 7); the steps are in
## tools/music_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads). It
## starts a NEW Sandbox world and writes the profile, so run it with a private, fresh user folder holding a copy of
## profile.json (tools/smoke_all.sh music does that):
##   XDG_DATA_HOME=/tmp/easycraft-music-smoke godot --headless --path . --script res://tools/music_smoke.gd
## Prints MUSIC_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MUSIC_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/music_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
