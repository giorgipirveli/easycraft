extends SceneTree
## Headless smoke run of prospecting on the Moon and Mars (spec §26.5, owner #80) in the real sandbox; the steps are in
## tools/prospecting_space_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). Sandbox, the Moon: Gemma's space camp stands by the landing pad, off the colony, and her board opens when
## the child walks up (the Moon's five quests); the ice quest runs through the real board and world: the map read, the
## walk to the crater's rim (the HUD's compass, the planet guide's, points there), down into the crater to the icy dust
## in the generated ground (its fact), the problem, the clue, the quiz (dig, melt, split, fly in order), MARK IT (the
## gold paid once, MY MAP's mark, the find's card following the ice to rocket fuel). Survivor, Mars: its five quests,
## the ice quest marked through the wallet, the ground ice in the generated crater, and living off the land in the bag:
## ground ice melted at an Ice Melter, the water split into hydrogen fuel at an Oxygen Maker (each step's fact), and Tilly
## buying the fuel (gold for the next rocket's tanks) and titanium.
## It replaces the Sandbox world of the Moon and the Survivor world of Mars in that folder, so run it with a private
## user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-prospecting-space-smoke godot --headless --path . --script res://tools/prospecting_space_smoke.gd
## Prints PROSPECT_SPACE_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PROSPECT_SPACE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/prospecting_space_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
