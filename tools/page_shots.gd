extends SceneTree
## Pictures of every block page in both styles (M5 Task 3, the APK size pass): a wall with three blocks of each page,
## lit by a low sun (the normal maps' relief shows), seen close (1.6 m: a block a child is about to break) and at
## phone distance (4 m), on a phone's 2400 x 1080 screen. Run it before and after a change to the pages' textures and
## compare the pictures. Windowed (headless draws nothing):
##   godot --path . --disable-vsync --resolution 960x432 --script res://tools/page_shots.gd -- --out=/tmp/shots --tag=after
## PNGs <tag>_<style>_<shot>.png go to --out; prints PAGE_SHOT lines. Writes nothing else.


func _initialize() -> void:
	var steps: Node = load("res://tools/page_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
