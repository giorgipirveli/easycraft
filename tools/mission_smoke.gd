extends SceneTree
## Headless smoke run of missions (spec §21d, §25.3) in the real sandbox; the steps are in tools/mission_smoke_steps.gd
## (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: a new Green Meadows world gets its Launch Site (the pad stamped, the buildings standing); the Star Map says
## the Moon needs a mission (no LAND) while Planet Boing lands; walking up to the Mission Board opens it; a rocket built
## on the pad is checked (the parts not bought yet), the missing parts are bought with gold, LAUNCH flies it to the
## Moon ("Mission complete!", on the route, the Space Book's mark); HOME again the rocket still stands on the pad and the
## Moon's card says LAND. Survivor: a new world's board sells a part into the bag for gold.
## It replaces the Sandbox worlds of Green Meadows and the Moon and the first Survivor world in that folder, so run it
## with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-mission-smoke godot --headless --path . --script res://tools/mission_smoke.gd
## Prints MISSION_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("MISSION_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/mission_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
