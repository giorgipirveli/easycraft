extends SceneTree
## The learning places' look (2026-10-18, docs/devlog/parts/academy-look.md): pictures of the Discovery Academy, a
## discovery crystal and Professor Hoot in a real Green Meadows world (seed 12345, as the W1 smoke), and the draws they
## cost. Windowed (headless draws nothing); the steps are in tools/academy_shots_steps.gd (loaded at run time: a
## --script SceneTree cannot compile scripts that use autoloads). It replaces the first Sandbox world in its user folder,
## so give it a private one whose path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-academy-shots nice godot --path . --rendering-method mobile --resolution 1280x720 \
##     --script res://tools/academy_shots.gd -- --tag=after [--vr] [--style=realistic] [--only=from_spawn,plaza]
## `--vr`: the headset's desktop preview (Vr.preview with the Quest's platform: the vr preset), each view at the child's
## eye, level. Prints ACADEMY_SHOT lines (draws_3d: the scene's and its shadows', primitives) and JPEGs go to
## $XDG_DATA_HOME/academy_shots/<tag>/<flat|vr>/<style>/<name>.jpg.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		print("ACADEMY_SHOT refused: set XDG_DATA_HOME to a private folder (its path must contain 'shots')")
		quit(2)
		return
	var steps: Node = load("res://tools/academy_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
