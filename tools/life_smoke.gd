extends SceneTree
## Headless smoke run of Life L1 (owner #112, spec §27): every Experience played through on every track, flat (normal and
## the Expert try) and in a simulated headset, through the real Life screen, practice room and room host, by a child
## who always does the right thing (fingers on the targets' screen points; simulated hands, head and laser in VR). The
## steps are in tools/life_smoke_steps.gd (a --script SceneTree cannot compile scripts that use autoloads). It writes
## only its own measurement file, so run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-life-smoke godot --headless --path . --script res://tools/life_smoke.gd
##   ... -- --only=fire_escape.middle --modes=flat,vr,expert      (--only: skills or Experiences, comma-separated)
## Prints LIFE_SMOKE lines; exits 0 when every run passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("LIFE_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/life_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
