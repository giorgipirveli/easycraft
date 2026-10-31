extends SceneTree
## Pictures and a bench of MAKE MY SHORT (spec §5.12b "As built (My Shorts)"), without the editor or the emulator.
## Windowed (headless draws nothing); the album gets the store's game pictures as sample photos:
##   XDG_DATA_HOME=/tmp/easycraft-my-shorts godot --path . --disable-vsync --script res://tools/my_shorts_shots.gd -- --panel
##       MY SHORTS and each step of the maker in the Theater's panel, at 1600 × 720 and 1280 × 720
##   ... -- --sheets            frame sheets of made Shorts (How I built it, 3 facts about a planet, a wonder, an animal,
##                              Step by step): a picture every 2 s
##   ... -- --bench [--novoice] frame times: MY SHORTS played and swiped, then the maker with its preview playing
##                              (--novoice: without the system voice, slow on a Linux desktop, asynchronous on a phone)
## PNGs go to user://my_shorts_shots/ (the path is printed); prints MY_SHORTS_SHOT and MY_SHORTS_BENCH lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/my_shorts_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
