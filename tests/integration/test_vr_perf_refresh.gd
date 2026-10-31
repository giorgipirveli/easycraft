extends GutTest
## P5 (owner #108): the refresh rate a real session asks for (Vr._tune): the VR preset's (vr 72 Hz, vr_plus 90 Hz),
## the nearest the headset offers; again when the child picks the other VR preset; stepped down once when frames keep
## missing (90 Hz only while there is headroom); nothing after the session. A stand-in XR interface records the asks.


class FakeXr:
	extends XRInterfaceExtension
	var offered: Array = [72.0, 80.0, 90.0, 120.0]
	var asked: Array[float] = []

	func get_available_display_refresh_rates() -> Array:
		return offered

	func set_display_refresh_rate(rate: float) -> void:
		asked.append(rate)


var _graphics := ""
var _vrs := Viewport.VRS_DISABLED


func before_each() -> void:
	_graphics = str(Profile.data.settings.graphics)
	_vrs = get_viewport().vrs_mode


func after_each() -> void:
	Vr._set_focus(true)
	Vr._end_refresh()
	Profile.data.settings.graphics = _graphics
	GraphicsPreset.headset = ""
	get_viewport().vrs_mode = _vrs


func _tuned(graphics: String, offered: Array = [72.0, 80.0, 90.0, 120.0]) -> FakeXr:
	Profile.data.settings.graphics = graphics
	var xr := FakeXr.new()
	xr.offered = offered
	Vr._tune(xr)
	return xr


func test_vr_asks_72_and_vr_plus_90() -> void:
	assert_eq(_tuned("vr").asked, [72.0] as Array[float])
	assert_eq(Vr.refresh_rate, 72.0)
	assert_eq(_tuned("vr_plus").asked, [90.0] as Array[float])
	assert_eq(Vr.refresh_rate, 90.0)


func test_a_headset_without_90_gets_its_nearest() -> void:
	assert_eq(_tuned("vr_plus", [60.0, 72.0]).asked, [72.0] as Array[float])


func test_a_quest_3_that_never_picked_asks_90_and_a_quest_2_72() -> void:
	GraphicsPreset.headset = "Quest 3"
	assert_eq(_tuned("medium").asked, [90.0] as Array[float])
	GraphicsPreset.headset = "Quest 2"
	assert_eq(_tuned("medium").asked, [72.0] as Array[float])


func test_picking_the_other_vr_preset_asks_its_rate_and_other_settings_dont() -> void:
	var xr := _tuned("vr")
	Profile.data.settings.graphics = "vr_plus"
	Game.settings_applied.emit(Profile.data.settings)
	assert_eq(xr.asked, [72.0, 90.0] as Array[float])
	Game.settings_applied.emit(Profile.data.settings)   # the volume, say: the same preset
	assert_eq(xr.asked, [72.0, 90.0] as Array[float], "no ask without a new preset")


func test_frames_that_keep_missing_90_step_down_once() -> void:
	var xr := _tuned("vr_plus")
	for i in 75 * 15:
		Vr._process(1.0 / 75.0)
	assert_eq(xr.asked, [90.0, 80.0] as Array[float], "the next rate the headset offers")
	Game.settings_applied.emit(Profile.data.settings)
	assert_eq(xr.asked, [90.0, 80.0] as Array[float], "another setting never brings 90 back (no see-saw)")
	for i in 60 * 30:
		Vr._process(1.0 / 60.0)
	assert_eq(xr.asked.size(), 2, "once")


func test_nothing_after_the_session() -> void:
	var xr := _tuned("vr_plus")
	Vr._end_refresh()
	assert_eq(Vr.refresh_rate, 0.0)
	Profile.data.settings.graphics = "vr"
	Game.settings_applied.emit(Profile.data.settings)
	for i in 75 * 15:
		Vr._process(1.0 / 75.0)
	assert_eq(xr.asked, [90.0] as Array[float])


func test_frames_while_the_quests_menu_is_up_never_step_down() -> void:
	var xr := _tuned("vr_plus")
	Vr._set_focus(false)   # the Quest's own menu, or the headset taken off: the runtime slows the app's frames
	for i in 75 * 15:
		Vr._process(1.0 / 75.0)
	assert_eq(xr.asked, [90.0] as Array[float], "a frame rate the child never saw is no reason")
