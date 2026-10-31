extends GutTest
## Owner #101 (VR on the Meta Quest), the panel side: the main menu in a headset. Its camera never orbits (a camera move
## the child did not make: the plan's comfort ruling); the child stands on the backdrop's hill, the XR origin anchored
## there (Vr.anchor, kind &"menu"), and the menu's screens are on the eye panel (its layers in the VR canvas). A headset
## started in the menu (ENTER VR) stops the orbit and moves the screens; ended, the orbit and the screens come back.
## ENTER VR (the WebXR route) shows only in the Web VR export, where the browser says an immersive session can start,
## after the shader warm-up, and never while VR runs; it starts Vr with VrRules.WEBXR and shows the words if it can't.

var _profile: ProfileData
var _old_pad: PadFocus


func before_each() -> void:
	PlatformRules.shader_warmup = false
	_profile = Profile.data
	Profile.data = ProfileData.new()
	Profile.data.username = "Mia"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Profile.data.settings.simple_asked = true
	Profile.data.settings.reduce_motion = false
	_old_pad = PadFocus.instance
	PadFocus.instance = null


func after_each() -> void:
	Vr.simulate(false)
	Profile.data = _profile
	PlatformRules.shader_warmup = true
	PadFocus.instance = _old_pad


func _menu() -> Node3D:
	var menu: Node3D = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	return menu


func _cam(menu: Node) -> Camera3D:
	return menu.get("_cam") as Camera3D


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func test_in_vr_the_menu_holds_still_with_the_child_standing_on_the_hill() -> void:
	Vr.simulate(true)
	var menu := _menu()
	await _frames(2)
	var cam := _cam(menu)
	var at := cam.global_position
	await _frames(5)
	assert_eq(cam.global_position, at, "no orbit in a headset")
	assert_eq(Vr.anchor_kind(), &"menu", "the XR origin stands at the menu's spot")
	var stand := menu.get("vr_stand") as Node3D
	assert_not_null(stand)
	if stand == null:
		return
	var world := menu.get("_world") as WorldService
	var ground := world.surface_height(floori(stand.global_position.x), floori(stand.global_position.z))   # first air
	assert_almost_eq(stand.global_position.y - ground, CameraRig.HEAD_HEIGHT, 0.01,
		"the eyes at the avatar's height over the ground, not in the sky (a menu spot is the eye's place)")
	assert_almost_eq(cam.global_position, stand.global_position, Vector3.ONE * 0.001, "the window's camera there too")
	assert_almost_eq(cam.global_rotation.x, 0.0, 0.001, "level: the headset looks where the child looks")


func test_leaving_the_menu_lets_go_of_its_spot() -> void:
	Vr.simulate(true)
	var menu := _menu()
	await _frames(1)
	assert_eq(Vr.anchor_kind(), &"menu")
	remove_child(menu)   # a world starts: the menu leaves the tree before it is freed
	assert_eq(Vr.anchor_kind(), &"", "the headset never follows a spot out of the tree")
	menu.free()


func test_in_vr_the_menus_screens_are_on_the_panel() -> void:
	Vr.simulate(true)
	var menu := _menu()
	await _frames(1)
	var ui := menu.get("_ui") as Control
	assert_eq(ui.get_viewport(), Vr.ui_viewport(), "the menu's canvas layer is in the VR canvas")


func test_the_menu_is_on_the_eye_panel_with_the_games_pad_focus() -> void:
	var pad := PadFocus.install(get_tree().root)   # as main.gd does: under the root, added after this frame
	await _frames(1)
	Vr.simulate(true)
	var menu := _menu()
	await _frames(3)
	assert_eq(pad.get_viewport(), Vr.ui_viewport(), "the game's PadFocus lives in the canvas")
	assert_true(PadFocus.menu_has_pad(), "the menu's screens have the pad")
	assert_eq(VrUi.instance.panel.place, VrPanelRules.EYE, "so the menu is in front of the child, not on the tray")
	Vr.simulate(false)
	menu.free()
	pad.free()


func test_a_headset_started_in_the_menu_stops_the_orbit_and_ending_it_brings_it_back() -> void:
	var menu := _menu()
	await _frames(2)
	var cam := _cam(menu)
	var ui := menu.get("_ui") as Control
	var before := cam.global_position
	await _frames(3)
	assert_ne(cam.global_position, before, "off VR the camera orbits as before")
	assert_eq(ui.get_viewport(), get_tree().root, "and the screens are the window's")
	Vr.simulate(true)   # ENTER VR
	await _frames(1)
	var still := cam.global_position
	await _frames(3)
	assert_eq(cam.global_position, still)
	assert_eq(ui.get_viewport(), Vr.ui_viewport())
	Vr.simulate(false)
	await _frames(3)
	assert_ne(cam.global_position, still, "orbiting again")
	assert_eq(ui.get_viewport(), get_tree().root, "the screens back on the window")


func test_no_enter_vr_outside_the_web_vr_export() -> void:
	assert_false(VrEntry.wanted({}), "a phone, the PC, /play/")
	assert_true(VrEntry.wanted({"webxr": true}), "the Web VR export (/vr/)")
	var menu := _menu()
	await _frames(1)
	assert_null(menu.find_child("EnterVr", true, false), "no button on this build")


class FakeWebXr:
	extends RefCounted
	signal session_supported(session_mode: String, supported: bool)
	var asked: Array[String] = []

	func is_session_supported(mode: String) -> void:
		asked.append(mode)


func test_enter_vr_shows_where_the_browser_can_and_starts_webxr() -> void:
	var fake := FakeWebXr.new()
	var entry := VrEntry.new(fake)
	var started: Array[StringName] = []
	var answer := ["VR is coming soon."]
	entry.start = func(kind: StringName) -> String:
		started.append(kind)
		return answer[0]
	var ready := [false]
	entry.ready = func() -> bool: return ready[0]
	var b := entry.button()
	add_child_autofree(b)
	entry.ask()
	assert_eq(fake.asked, ["immersive-vr"])
	assert_false(b.visible, "not before the browser answers")
	fake.session_supported.emit("immersive-vr", true)
	assert_false(b.visible, "not before the warm-up is done")
	ready[0] = true
	entry.refresh()
	assert_true(b.visible)
	b.pressed.emit()
	assert_eq(started, [VrRules.WEBXR])
	assert_eq(entry.words.text, "VR is coming soon.", "the reason, in words")
	answer[0] = ""
	Vr.simulate(true)
	assert_false(b.visible, "never while VR runs")
	Vr.simulate(false)
	assert_true(b.visible, "back when it ends")
	fake.session_supported.emit("immersive-vr", false)
	assert_false(b.visible, "a browser that can't")
