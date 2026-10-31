extends SceneTree
## Pictures of the chat (owner feedback #49) on the emulator's 20:9 canvas (at 1600 × 720) and a 16:9
## phone (1280 × 720): a crowded HUD (a Survivor game's clock and round line, the Brave badge, the gold)
## with the chat bar open and Georgian typed in it, a phone keyboard over the bottom 55 % of the screen
## (a dark stand-in, the size of a phone's landscape keyboard), friends' lines in the history (a long one,
## Georgian, an emote, a bot's answer), then the typing without the phrase buttons, the quick-chat wheel
## and the closed history. For a look at the chat without the editor or the emulator. Windowed (headless
## draws nothing):
##   XDG_DATA_HOME=/tmp/easycraft-shots godot --path . --disable-vsync --script res://tools/chat_shots.gd
## PNGs go to user://chat_shots/ (the path is printed); prints CHAT_SHOT lines. No world, no save.


func _initialize() -> void:
	var steps: Node = load("res://tools/chat_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
