extends SceneTree
## Pictures of the Daily Mission, postcards and FRIENDS (owner #81, #82, #85; docs/devlog/parts/daily-and-friends.md)
## for a look without the editor or the emulator: the School's map with TODAY'S MISSION, the mission's intro, a question
## and its card; the card rendered as the picture SAVE and SHARE give (CardPicture); a postcard in the School and one
## offered in a world; FRIENDS' tabs (friends and cheers, presents, a crew), the cheer and present pickers and MAKE A
## CREW, on a private profile and the tests' fake server (nothing is saved or sent). Windowed (headless draws nothing),
## into a folder with "shots":
##   XDG_DATA_HOME=/tmp/easycraft-daily-shots godot --path . --disable-vsync --script res://tools/daily_shots.gd [-- --wide]
## PNGs go to user://daily_shots/ (the path is printed); prints DAILY_SHOT lines.


func _initialize() -> void:
	var steps: Node = load("res://tools/daily_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
