extends SceneTree
## Headless smoke run of Real Builder (owner #116, #117, round 4b): the Little wall, the Middle shed and the Big house built
## through the real ToolRoomHost and RealBuilderSite by a child who always does the right thing (tools/real_builder_driver.gd:
## the tray's tool and a finger flat; fake hands in a simulated headset), on a fixed clock. Each run checks: finished with
## no hint, the build complete and in bond (the wall's joints staggered; the shed's and the house's every brick, lintel,
## rafter and tile), the Tool Book's stamps recorded. The steps are in tools/real_builder_smoke_steps.gd (a --script
## SceneTree cannot compile scripts that use autoloads). It writes nothing but its log, but runs with a private user
## folder like every smoke:
##   XDG_DATA_HOME=/tmp/easycraft-real-builder-smoke godot --headless --path . --script res://tools/real_builder_smoke.gd
##   ... -- --runs=little.flat,middle.vr
## Prints REAL_BUILDER_SMOKE lines; exits 0 when every run passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("REAL_BUILDER_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/real_builder_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
