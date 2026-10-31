extends SceneTree
## Headless smoke run of "invent it" (owner #78, spec §21e) in the real sandbox; the steps are in
## tools/inventions_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Survivor: FLY is refused until a flying machine is invented; the Inventions book (INVENT in MORE) makes the kite at a
## Workbench from the bag's materials and gold; the kite lifts the child on high ground and lets them down gently; the
## balloon flies free and its TRY IT pays once; the plane burns fuel; the jet and the rocket (kerosene) are made; the
## rocket opens the Launch Site's missions (the Mission Board's gate). Sandbox: the classic free flying stays, TRY IT
## flies the jet, FREE FLYING goes back, the bottle rocket launches. The profile on disk keeps the inventions.
## It replaces the first Survivor world and the first Sandbox world in that folder, so run it with a private user
## folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-inventions-smoke godot --headless --path . --script res://tools/inventions_smoke.gd
## Prints INVENT_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("INVENT_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/inventions_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
