extends SceneTree
## Owner #122 (G0): the headless smoke run of the play layer. Through the real PlayHost (the arena, the stations, the
## HUD), a child who always does the right thing (the coach's own steps) plays:
## - TYPES: one hand-written exercise of every exercise type the School has, each in its mechanic's station, flat (a
##   finger on each thing's screen point) and in a simulated headset (a hand squeezing at each thing, carrying it to its
##   place, letting go; the laser for what is far);
## - UNITS: the first unit of every subject of every grade that plays without reading (owner #134: PlayHost.plays; a
##   subject with none says so), its whole round to the end (flat; and grade 5's in VR too), checking the round's
##   result counts six challenges right the first time. Written choices and claims are shelved: the TYPES run says so.
## The steps are in tools/play_smoke_steps.gd (a --script SceneTree cannot compile scripts that use autoloads). It saves
## nothing, but run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-play-smoke godot --headless --path . --script res://tools/play_smoke.gd
##   ... -- --only=types|units  --modes=flat,vr  --grades=4,5
## Prints PLAY_SMOKE lines; exits 0 when every run passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PLAY_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/play_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
