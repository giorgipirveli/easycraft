extends SceneTree
## Headless smoke run of prospecting (spec §26, owner #80) in the real sandbox; the steps are in
## tools/prospecting_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox, Green Meadows: Gemma's camp stands by the spawn and her board opens when the child walks up; the gold quest
## runs through the real board and world: the map read (the right direction), the walk to the river (the compass points
## there), the gold gravel in the generated ground found up close (its fact), the flakes' problem, the quartz vein in
## the hill (its block in the world), the quiz, MARK IT (the gold paid once, MY MAP's mark, the world's save). Survivor,
## the Sandstorm Desert: the oil quest's well stands on its dome, walking up to the pump jack fills a drum into the bag,
## a Refinery beside it makes kerosene (its fact), and Tilly buys it; DIG in MORE and J open the journal.
## It replaces the Sandbox world of Green Meadows and the Survivor world of the desert in that folder, so run it with a
## private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-prospecting-smoke godot --headless --path . --script res://tools/prospecting_smoke.gd
## Prints PROSPECT_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PROSPECT_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/prospecting_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
