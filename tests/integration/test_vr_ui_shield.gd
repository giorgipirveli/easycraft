extends GutTest
## Owner #127 (2026-10-17, on the Quest 3): "the menu i see always on the screen should be shows not always, only when i
## raise my elbow like covering a shield". While the child plays, the HUD is hidden; raising the forearm of the hand
## that does not point in front of the face like a shield shows it on a small panel just above that hand, facing the
## eyes (VrPanelRules.SHIELD); lowering it hides it again. The wrist strips (hotbar, hearts, gold) rest while the shield
## shows the whole HUD. Menus, the pause menu and a loading world still come in front of the eyes (EYE), and the
## desktop preview keeps the old tray.

const HEAD := Transform3D(Basis(), Vector3(0, 1.6, 0))
const DOWN := Transform3D(Basis(), Vector3(-0.25, 1.0, -0.15))   # the arm down by the side
## The left forearm raised across the face: the hand ahead and a little below the eyes, its fingers' line pointing right.
var SHIELD := Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-0.05, 1.4, -0.35))

var _old_pad: PadFocus
var ui: VrUi
var hand := [DOWN]


class Owner:
	extends Node


class FakeHud:
	extends Control
	var rects := {&"hotbar": Rect2(303, 642, 674, 62), &"hearts": Rect2(165, 26, 220, 40), &"gold": Rect2(930, 62, 220, 48),
		&"toast": Rect2()}

	func _ready() -> void:
		add_to_group(Hud.GROUP)

	func vr_rects() -> Dictionary:
		return rects


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	Vr.simulate(true)
	Vr.ui_viewport()
	ui = VrUi.instance
	ui.set_process(false)
	hand[0] = DOWN
	ui.panel.head_source = func() -> Transform3D: return HEAD
	ui.panel.hand_source = func() -> Transform3D: return hand[0]
	ui.wrist.hand_source = func() -> Transform3D: return hand[0]


func after_each() -> void:
	ui.panel.hand_source = Callable()
	Vr.simulate(false)
	PadFocus.instance = _old_pad
	get_tree().paused = false


func _hud() -> FakeHud:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var hud := FakeHud.new()
	layer.add_child(hud)
	UiLayers.route(layer, o)
	return hud


func test_while_playing_the_hud_is_not_in_view_until_the_shield_is_raised() -> void:
	_hud()
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "the arm down: nothing in front of the eyes")
	assert_false(ui.panel.visible)
	assert_true(ui.wrist.part(&"hotbar").visible, "a glance at the wrist still shows the hotbar")


func test_the_raised_forearm_shows_the_hud_on_it_and_lowering_it_hides_it() -> void:
	_hud()
	hand[0] = SHIELD
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.SHIELD)
	assert_true(ui.panel.visible)
	assert_eq(ui.panel.size, VrPanelRules.SHIELD_SIZE)
	assert_lt(ui.panel.global_position.distance_to(SHIELD.origin), 0.2, "on the forearm")
	var to_eye := (HEAD.origin - ui.panel.global_position).normalized()
	assert_gt(ui.panel.global_transform.basis.z.normalized().dot(to_eye), 0.95, "facing the eyes")
	assert_false(ui.wrist.part(&"hotbar").visible, "the whole HUD is on the shield: the wrist strips rest")
	hand[0] = Transform3D(SHIELD.basis, SHIELD.origin + Vector3(0.0, 0.0, -0.05))   # the arm moves a little
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.SHIELD, "a small move keeps it")
	assert_lt(ui.panel.global_position.distance_to(hand[0].origin), 0.2, "it rides on the arm")
	hand[0] = DOWN
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "the arm down: gone")


func test_a_menu_or_the_pause_still_comes_in_front_of_the_eyes() -> void:
	_hud()
	get_tree().paused = true
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.EYE)


func test_the_laser_presses_the_hud_on_the_shield() -> void:
	_hud()
	hand[0] = SHIELD
	ui.step(0.016)
	var from := HEAD.origin + Vector3(0.25, -0.2, 0.0)
	var dir := (ui.panel.global_position - from).normalized()
	assert_ne(ui.panel.hit(from, dir), VrPanelRules.MISS, "the pointing hand's laser lands on it")
