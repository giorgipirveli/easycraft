extends GutTest
## Owner #101 (VR on the Meta Quest, P2; the research's acceptance: "a test like test_pad_screens over VrUi finds every
## School and menu screen reachable with the pointer and with the sticks"). Every screen of the main menu (the start, the
## name, BOY / GIRL / JUST ME, the mode choice, SETTINGS' pages with VR COMFORT, AVATAR, the Gold Shop, the School's map,
## a unit and a round, the codes, Monster Wave), the pause menu and the Mission Board, shown in the VR canvas on the eye
## panel: the headset's sticks (the virtual pad, PadFocus in the canvas) reach every control the pad can focus, and the
## laser lands on each of them (nothing covers one; one in a scroll counts once it is scrolled into view).

const SCREENS := preload("res://tools/vr_ui_screens.gd")
const HEAD := Transform3D(Basis(), Vector3(0, 1.6, 0))
const HAND := Vector3(0.25, 1.2, -0.2)

var _old_pad: PadFocus
var _profile: ProfileData
var pad: PadFocus
var ui: VrUi


class Owner:
	extends Node


func before_each() -> void:
	PlatformRules.shader_warmup = false
	_old_pad = PadFocus.instance
	pad = PadFocus.new()
	add_child_autofree(pad)
	_profile = Profile.data
	Profile.data = ProfileData.new()
	Profile.data.username = "Mia"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Profile.data.settings.simple_asked = true
	Vr.simulate(true)
	Vr.ui_viewport()
	ui = VrUi.instance
	ui.panel.head_source = func() -> Transform3D: return HEAD


func after_each() -> void:
	Vr.simulate(false)
	get_tree().paused = false
	Profile.data = _profile
	PadFocus.instance = _old_pad
	PlatformRules.shader_warmup = true
	Curriculum.clear_cache()
	SpendRules.clear_extra()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _settle() -> void:
	await get_tree().create_timer(0.3).timeout   # the panels' pop-in
	await _frames(3)


## The controls of `root` the sticks cannot reach from the focus (GamepadRules' rules, PadFocus's own candidates).
func _by_sticks(root: Control) -> Array:
	var list := pad.candidates(root)
	var rects := []
	var own := []
	for i in list.size():
		rects.append(list[i].get_global_rect())
		if PadFocus.sideways_own(list[i]):
			own.append(i)
	var focus := Vr.ui_viewport().gui_get_focus_owner()
	var start := list.find(focus)
	if start < 0:
		return ["the focus %s is not on the screen" % focus]
	var seen := GamepadRules.reachable(start, rects, own)
	var out := []
	for i in list.size():
		if not seen.has(i):
			out.append("%s '%s'" % [list[i].name, list[i].get("text")])
	return out


## The controls of `root` the laser does not land on (aimed at each one's middle from the pointing hand).
func _by_laser(root: Control) -> Array:
	ui.set_process(false)
	ui.panel.set_place(VrPanelRules.HIDDEN)
	ui.panel.set_place(VrPanelRules.EYE)
	var out := []
	var aim := [Vector2.ZERO]
	ui.pointer.trigger_source = func() -> bool: return false
	ui.pointer.ray_source = func() -> Array:
		var uv: Vector2 = aim[0] / Vector2(VrPanelRules.CANVAS)
		var p := ui.panel.global_transform * Vector3((uv.x - 0.5) * ui.panel.size.x, (0.5 - uv.y) * ui.panel.size.y, 0.0)
		return [HAND, (p - HAND).normalized()]
	for c: Control in pad.candidates(root):
		if c is TouchButton or not _in_view(c):
			continue
		aim[0] = c.get_global_transform() * (c.size * 0.5)
		ui.pointer.step()
		var hovered := Vr.ui_viewport().gui_get_hovered_control()
		if not ui.pointer.hovering or hovered == null or not (hovered == c or c.is_ancestor_of(hovered)):
			out.append("%s '%s' (the laser found %s)" % [c.name, c.get("text"), hovered.name if hovered else "nothing"])
	ui.set_process(true)
	return out


## The control's middle shows: on the canvas, and inside every scroll round it.
func _in_view(c: Control) -> bool:
	var mid := c.get_global_transform() * (c.size * 0.5)
	if not Rect2(Vector2.ZERO, Vector2(VrPanelRules.CANVAS)).has_point(mid):
		return false
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer and not (p as ScrollContainer).get_global_rect().has_point(mid):
			return false
		p = p.get_parent()
	return true


func _check(label: String, root: Control) -> void:
	await _settle()
	if ui.keyboard.visible:   # a text box has the focus: the keyboard covers the screen's foot, as a phone's does
		var keys := ui.keyboard.find_children("Key_*", "Button", true, false)
		var missed := []
		for k: Node in keys:
			if (k as Control).is_visible_in_tree() and not _laser_lands_on(k as Control):
				missed.append(k.name)
		assert_eq(missed, [], "%s: every key of the keyboard by the laser" % label)
		ui.keyboard.key(VrKeyboard.DONE).pressed.emit()   # DONE: the screen under it
		await _frames(2)
		assert_false(ui.keyboard.visible)
	assert_eq(_by_sticks(root), [], "%s: every control by the sticks" % label)
	assert_eq(_by_laser(root), [], "%s: every control by the laser" % label)


func _laser_lands_on(c: Control) -> bool:
	ui.set_process(false)
	ui.panel.set_place(VrPanelRules.HIDDEN)
	ui.panel.set_place(VrPanelRules.EYE)
	var aim: Vector2 = c.get_global_transform() * (c.size * 0.5)
	ui.pointer.trigger_source = func() -> bool: return false
	ui.pointer.ray_source = func() -> Array:
		var uv: Vector2 = aim / Vector2(VrPanelRules.CANVAS)
		var p := ui.panel.global_transform * Vector3((uv.x - 0.5) * ui.panel.size.x, (0.5 - uv.y) * ui.panel.size.y, 0.0)
		return [HAND, (p - HAND).normalized()]
	ui.pointer.step()
	var hovered := Vr.ui_viewport().gui_get_hovered_control()
	ui.set_process(true)
	return ui.pointer.hovering and hovered != null and (hovered == c or c.is_ancestor_of(hovered))


func test_the_main_menus_screens() -> void:
	var menu: Node3D = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await _frames(3)
	var center := menu.get("_center") as Control
	for step: String in ["_show_start", "_show_name", "_show_look_step", "_show_main", "_show_avatar", "_show_school",
			"_show_codes", "_show_wave"]:
		menu.call(step)
		await _check(step, center)
	menu.call("_show_settings")
	await _settle()
	var settings := Vr.ui_viewport().find_children("*", "SettingsPanel", true, false)
	assert_eq(settings.size(), 1)
	for page: StringName in [SettingsPanel.GAME, SettingsPanel.WORDS, SettingsPanel.ACCESS, SettingsPanel.VR]:
		(settings[0] as SettingsPanel).show_page(page)
		await _check("SETTINGS %s" % page, center)


func test_the_stick_moves_the_focus_in_the_canvas() -> void:
	var menu: Node3D = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await _frames(3)
	menu.call("_show_main")
	await _settle()
	var before := Vr.ui_viewport().gui_get_focus_owner()
	assert_not_null(before, "the headset's pad has a focus on the menu")
	for v: float in [0.9, 0.0]:   # the walking stick pushed right and let go: one step
		var e := InputEventJoypadMotion.new()
		e.device = 12
		e.axis = JOY_AXIS_LEFT_X
		e.axis_value = v
		Vr.ui_viewport().push_input(e)
	await _frames(1)
	assert_ne(Vr.ui_viewport().gui_get_focus_owner(), before, "the stick moved it")


func _screen(screen_name: String) -> Control:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(VrPanelRules.CANVAS)
	layer.add_child(holder)
	UiLayers.route(layer, o)
	var screen: Control = SCREENS.build(screen_name, holder)
	PadFocus.watch(holder)
	return screen


func test_the_schools_pages() -> void:
	for n: String in ["school_map", "school_unit", "school_round"]:
		var screen := _screen(n)
		await _frames(1)
		SCREENS.open(n, screen)
		await _check(n, screen.get_parent().get_parent() as Control)


func test_the_mission_boards_pages_and_the_gold_shop() -> void:
	for n: String in ["board_missions", "board_rocket", "board_parts", "gold_shop"]:
		var screen := _screen(n)
		await _frames(1)
		SCREENS.open(n, screen)
		await _check(n, screen.get_parent() as Control if n.begins_with("board") else screen.get_parent().get_parent() as Control)


func test_the_pause_menu() -> void:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var menu := PauseMenu.new()
	layer.add_child(menu)
	UiLayers.route(layer, o)
	await _frames(1)
	menu.open()
	await _check("the pause menu", menu)
	menu.close()
