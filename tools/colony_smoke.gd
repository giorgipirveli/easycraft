extends SceneTree
## Headless smoke run of the colonies under domes (owner #77, spec §21c) in the real sandbox; the steps are in
## tools/colony_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, land on Mars (the Star Map), find the colony on MY MAP and the explorer's
## checklist, walk into the Great Dome (its glass, grass and garden in the real terrain, its animals coming, bees and
## butterflies), walk into every part (each says its fact), tap the lab's bench (the Science Lab opens), time the frames
## standing under the dome, then fly up again and land on the Moon: its colony, its sights and its dome's animals. It
## replaces the Sandbox worlds of Green Meadows, Mars and the Moon in that folder, so run it with a private user folder
## whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-colony-smoke godot --headless --path . --script res://tools/colony_smoke.gd
## Prints COLONY_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("COLONY_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/colony_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
