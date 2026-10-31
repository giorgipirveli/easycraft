extends GutTest
## Owner #101 (VR on the Meta Quest, P2): while the child plays, the hotbar, the hearts and the gold also show on the
## wrist of the hand that does not point (parts of the VR canvas, taken from where the HUD drew them: Hud.vr_rects), a
## small strip that faces the eyes; and a toast, the wave line or the boss bar float on a strip just above the gaze,
## lazily following the head, only while one shows. Never while a menu is in front of the child; never without a HUD.

const HEAD := Transform3D(Basis(), Vector3(0, 1.6, 0))

var _old_pad: PadFocus
var ui: VrUi
var hand := [Vector3(-0.25, 1.15, -0.35)]


class Owner:
	extends Node


## Stands in for the HUD: where its parts are on the canvas (an empty rect: not showing).
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
	ui.panel.head_source = func() -> Transform3D: return HEAD
	ui.wrist.hand_source = func() -> Transform3D: return Transform3D(Basis(), hand[0])


func after_each() -> void:
	Vr.simulate(false)
	PadFocus.instance = _old_pad


func _hud() -> FakeHud:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var hud := FakeHud.new()
	layer.add_child(hud)
	UiLayers.route(layer, o)
	return hud


func _uv(strip: MeshInstance3D) -> Rect2:
	var m := (strip.mesh as QuadMesh).material as StandardMaterial3D
	var c := Vector2(VrPanelRules.CANVAS)
	return Rect2(Vector2(m.uv1_offset.x, m.uv1_offset.y) * c, Vector2(m.uv1_scale.x, m.uv1_scale.y) * c)


func test_the_hotbar_hearts_and_gold_ride_on_the_other_wrist() -> void:
	var hud := _hud()
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "playing (owner #127: the HUD only on a raised forearm)")
	for part: StringName in [&"hotbar", &"hearts", &"gold"]:
		var strip := ui.wrist.part(part)
		assert_true(strip.visible, "%s on the wrist" % part)
		assert_almost_eq(_uv(strip).position, (hud.rects[part] as Rect2).position, Vector2.ONE * 0.5, "%s: its own part" % part)
		assert_almost_eq(_uv(strip).size, (hud.rects[part] as Rect2).size, Vector2.ONE * 0.5)
		assert_lt(strip.global_position.distance_to(hand[0]), 0.25, "%s at the hand" % part)
		var to_eye := (HEAD.origin - strip.global_position).normalized()
		assert_gt(strip.global_transform.basis.z.normalized().dot(to_eye), 0.9, "%s faces the eyes" % part)
	var bar := ui.wrist.part(&"hotbar")
	assert_almost_eq((bar.mesh as QuadMesh).size.x, 674.0 * VrWrist.METRES_PER_PX, 0.0001, "drawn to scale")
	hand[0] = Vector3(0.3, 1.0, -0.2)
	ui.step(0.016)
	assert_lt(bar.global_position.distance_to(hand[0]), 0.25, "it follows the hand")


func test_a_toast_floats_above_the_gaze_only_while_it_shows() -> void:
	var hud := _hud()
	ui.step(0.016)
	assert_false(ui.wrist.toast.visible, "no toast: no strip")
	hud.rects[&"toast"] = Rect2(440, 96, 400, 60)
	ui.step(0.016)
	assert_true(ui.wrist.toast.visible)
	assert_gt(ui.wrist.toast.global_position.y, HEAD.origin.y, "above the gaze")
	assert_almost_eq(_uv(ui.wrist.toast).position, Vector2(440, 96), Vector2.ONE * 0.5)
	var ahead := Vector2(ui.wrist.toast.global_position.x, ui.wrist.toast.global_position.z)
	assert_gt(ahead.dot(Vector2(0, -1)), 0.5, "in front of the head's yaw")


func test_nothing_on_the_wrist_while_a_menu_is_in_front_or_without_a_hud() -> void:
	ui.step(0.016)
	assert_false(ui.wrist.part(&"hotbar").visible, "no HUD (the main menu): nothing on the wrist")
	_hud()
	get_tree().paused = true
	ui.step(0.016)
	assert_eq(ui.panel.place, VrPanelRules.EYE)
	assert_false(ui.wrist.part(&"hotbar").visible, "the pause menu: the wrist rests")
	get_tree().paused = false
