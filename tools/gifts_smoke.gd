extends SceneTree
## Headless smoke run of friends apart (M4 Wave 3, agent I) in the real sandbox and the real visit scene;
## the steps are in tools/gifts_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile
## scripts that use autoloads). Two players on the game's fake server (tests/fakes/fake_online_server.gd):
## Hopper plays a NEW Sandbox world, picks a build with SHARE and sends it to Mia, puts a showcase up,
## gets Mia's bottle floating near him and opens it, and watches two buddies have a playdate; then Mia
## visits Hopper's showcase and leaves a sticker. It writes worlds, so run it with a private, fresh user
## folder holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-gifts-smoke godot --headless --path . --script res://tools/gifts_smoke.gd
## Prints GIFTS_SMOKE lines (and MEASURE lines); exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("GIFTS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/gifts_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
