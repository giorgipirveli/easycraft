extends SceneTree
## Headless smoke run of the planets' robots and aliens (owner #86, spec §21f) in the real sandbox; the steps are in
## tools/creatures_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## A new Mars Sandbox world: the helper robot by the landing pad (on the ground, its arm pointing where the compass
## points), the rover buddy and the scout drone, the aliens' camp on MY MAP; a tap on the robot through the real
## BlockInteractor (its card: LET'S GO), a tap on the rover (a sample), the quest's place found by standing on it, the
## robot's question answered right (gold), the camp visited, the explorer befriended with the sample (its present) and
## coming along (its mini-buddy follows the child), a souvenir bought from the trader, the creatures' frame cost; then
## a new Planet Boing world: the village, the chief's Echo played by hopping on the drums, the chief a friend. It
## replaces the Sandbox worlds of Mars and Planet Boing in that folder, so run it with a private user folder whose
## path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-creatures-smoke godot --headless --path . --script res://tools/creatures_smoke.gd
## Prints CREATURES_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("CREATURES_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/creatures_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
