extends SceneTree
## The Reel Studio's renderer (owner #96, spec §5.12b): films a Short in a real window, frame by frame on its own clock.
## Windowed (headless draws nothing); the steps are in tools/reel_render_steps.gd. tools/reel_render.sh runs it under
## Godot's Movie Maker and makes the Theora video, its still and its frame sheet.
##
##   godot --path . --write-movie <dir>/frame.png --fixed-fps 30 --resolution 540x960 \
##       --script res://tools/reel_render.gd -- --short=rocket_launch --movie [--full]
##       every frame of the Short (its 3D picture only: the video; --full: captions and stickers too), then quits
##   godot --path . --resolution 540x960 --script res://tools/reel_render.gd -- --short=rocket_launch --frames=2,14.5,30 [--full]
##       PNGs of those moments (user://reel_render/), to look at
##   godot --path . --script res://tools/reel_render.gd -- --bench [--short=a,b] [--seconds=8]
##       a live reel's cost in a phone's player (288 × 512 and 432 × 768): its stage's GPU and CPU time, draws


func _initialize() -> void:
	var steps: Node = load("res://tools/reel_render_steps.gd").new()
	root.add_child.call_deferred(steps)
