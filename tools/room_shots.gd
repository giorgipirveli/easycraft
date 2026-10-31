extends SceneTree
## The practice rooms' look (the rooms' look brief, 2026-10-17; docs/devlog/parts/rooms-look.md): every Life and Success
## Experience's room on each track opened by its real host (LifeRoomHost: the HUD, the first step's view), a picture of
## its first view and the draws and primitives it costs, before and after a change to the rooms. Windowed (headless draws
## nothing); the steps are in tools/room_shots_steps.gd. Nothing is saved but the pictures; give it a private folder whose
## path contains "shots":
##   XDG_DATA_HOME=/tmp/easycraft-room-shots nice godot --path . --rendering-method mobile --resolution 1280x720 \
##     --script res://tools/room_shots.gd -- --tag=after [--only=fire_escape,talk_deal] [--tracks=big] [--vr]
##     [--style=realistic] [--no-shots] [--no-sun]
## `--vr`: the desktop preview of the headset (Vr.preview, the Quest's platform and the `vr` preset, as tools/vr_bench.gd)
## instead of the phone's view: the room's start stand looked at four ways (snap turns), the most draws of the four.
## `--no-sun`: without the menu world's sun (the room's own light only). Prints ROOM_SHOT lines (draws_3d: the scene's,
## draws_2d: the canvases', primitives) and JPEGs go to $XDG_DATA_HOME/room_shots/<tag>/<flat|vr>/<style>/<id>.<track>.jpg.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("shots"):
		push_error("room_shots: give XDG_DATA_HOME a private folder whose path contains \"shots\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/room_shots_steps.gd").new())
