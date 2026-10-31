extends SceneTree
## Screenshots of the bigger world (owner feedback #45b) in a new Sandbox world of seed 12345 (the wild meadows):
## the places (a village, a windmill, a lighthouse, a ship, a lookout tower, castle ruins, a town), the biomes (birch
## and dark forests, a flower field, a swamp with lily pads, a snowy mountain, an island, a river's mouth), a glowing
## mushroom cave and the world map, in both styles. Windowed (headless draws nothing); the steps are in
## tools/world_shots_steps.gd. It starts a NEW world in the sandbox slot, so give it a private folder whose path
## contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-world-shots godot --path . --disable-vsync --resolution 1280x720 --script res://tools/world_shots.gd
## Small JPEGs (640 x 360) go to $XDG_DATA_HOME/world_shots/; prints WORLD_SHOT lines.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		print("WORLD_SHOT refused: set XDG_DATA_HOME to a private folder (its path must contain 'shots')")
		quit(2)
		return
	var steps: Node = load("res://tools/world_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
