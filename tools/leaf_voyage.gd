extends SceneTree
## Owner #133, #134 (Inside a Leaf, B2; the design's §4.4 "a developer argument opens a voyage directly"): opens a voyage
## at once, in a window, to play it with the mouse (a tap acts, a drag looks), the keys (WASD, Space and E up, C and Q
## down, V the camera, Escape the break) or a game controller; it quits when the voyage is left. `--vr-preview` plays it
## through the desktop's VR preview (Vr.preview: the fake head, the rig and its comfort rules):
##   godot --path . --script res://tools/leaf_voyage.gd -- --leaf-voyage=5.T1 [--vr-preview]
## In the game itself the same argument makes the School's PLAY on "Plants grow from air and water" open that voyage
## (LeafVoyageHost.voyage_of). The garden kept is this machine's user://leaf_voyage.json.


func _initialize() -> void:
	var steps: Node = load("res://tools/leaf_voyage_steps.gd").new()
	root.add_child.call_deferred(steps)
