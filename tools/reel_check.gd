extends SceneTree
## The Reel Studio (owner #96): every finding of the quality checkers on some Shorts, headless and quick, while a reel is
## being written (the studio's window shows the same; the tests run them on every reel). The steps are in
## tools/reel_check_steps.gd (a Node: the game's autoloads are there by then).
##
##   godot --headless --path . --script res://tools/reel_check.gd -- --short=volcano_erupts,plants_food
##   godot --headless --path . --script res://tools/reel_check.gd -- --all
## Prints "CHECK <id> ... ok" or one "CHECK <id>   <finding>" line a finding (ShortCheck, ReelCheck), with each stage's
## cells.


func _initialize() -> void:
	var steps: Node = load("res://tools/reel_check_steps.gd").new()
	root.add_child.call_deferred(steps)
