extends SceneTree
## Owner #101 (VR on the Meta Quest, P2): pictures of the VR canvas, what the eye panel shows in a headset (its 1280 ×
## 720, every word lifted to 24 px or more by VrReadability, the buttons outlined), for the readability audit by eye:
## every screen of tools/vr_ui_screens.gd, the main menu's name screen with the VR keyboard up, the break card. A
## simulated session (Vr.simulate), a private profile, nothing saved. Windowed (headless draws nothing), into a folder of
## its own:
##   XDG_DATA_HOME=/tmp/easycraft-vr-shots godot --path . --disable-vsync --script res://tools/vr_ui_shots.gd
## PNGs go to user://vr_ui_shots/ (the path is printed); prints VR_UI_SHOT lines (the smallest word drawn on each).


func _initialize() -> void:
	var steps: Node = load("res://tools/vr_ui_shots_steps.gd").new()
	root.add_child.call_deferred(steps)
