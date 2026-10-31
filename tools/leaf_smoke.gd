extends SceneTree
## Owner #133, #134 (Inside a Leaf, phase B2; docs/devlog/parts/game-leaf-b.md): plays both voyages from start to end
## with the rule bot, flat (taps on the screen) and in a simulated headset (the hands: the can lifted and tilted, a hand
## on the leaf, one trigger on each door, sugar carried to the gold pipe), headless, and checks the record: at least 6
## events for the unit, the rule masters it (5 of 6 right the first time), each solved beat paid once, the desert's
## beats NEW_SETTING, the outcome a round's, nothing written on the screen with a voice (headless has none: words then, as
## for a reader), no script error. One line a run:
##   LEAF_SMOKE voyage=5.1 mode=flat events=7 right_first=7 transfer=0 gold=7 words=0 voice=on stage=end seconds=195.0 ok
## and `LEAF_SMOKE done ok` (or `fail`, exit code 1). In a private folder:
##   XDG_DATA_HOME=<private dir> godot --headless --path . --script res://tools/leaf_smoke.gd [-- --modes=flat,vr]


func _initialize() -> void:
	var steps: Node = load("res://tools/leaf_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
