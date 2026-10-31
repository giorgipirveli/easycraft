extends GutTest
## Owner #84: "when i open it from windows browser and pc, it should start a game intended for this systems not mobile
## phone, so make it like usual game for pc as wll using browser". On a PC (a desktop browser or the desktop game) the
## menus and HUD are PC-sized (the window's content scale), a text box takes the typing at once (a phone keeps its
## keyboard shut until the child taps the box: owner #59), and the KEYS card tells the keyboard and mouse.

const PC := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
const PHONE := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}

var _profile: ProfileData


func before_each() -> void:
	PlatformRules.shader_warmup = false
	AgeBand.restrictions = false
	_profile = Profile.data
	Profile.data = ProfileData.new()


func after_each() -> void:
	Profile.data = _profile
	AgeBand.restrictions = true
	PlatformRules.simulated = {}
	PlatformRules.shader_warmup = true


func _name_box(f: Dictionary) -> LineEdit:
	PlatformRules.simulated = f
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_after_play")
	await wait_frames(3)
	var boxes := menu.find_children("*", "LineEdit", true, false)
	assert_eq(boxes.size(), 1, "the name box")
	return boxes[0] as LineEdit


func test_a_pc_types_its_name_at_once() -> void:
	var box: LineEdit = await _name_box(PC)
	assert_true(box.has_focus(), "the typing goes into the box")


func test_a_phone_keeps_its_keyboard_shut_until_the_box_is_tapped() -> void:
	var box: LineEdit = await _name_box(PHONE)
	assert_false(box.has_focus())


func test_a_pc_window_shows_pc_sized_menus() -> void:
	var w := Window.new()
	PlatformRules.apply_ui_scale(w, PC)
	assert_almost_eq(w.content_scale_factor, 0.8, 0.001)
	PlatformRules.apply_ui_scale(w, PHONE)
	assert_eq(w.content_scale_factor, 1.0)
	w.free()


## The page's loading tips speak to a PC as a PC: "click", not "tap", and a first tip with the keys.
func test_the_page_speaks_to_a_pc() -> void:
	var page := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(page, "matchMedia('(pointer: coarse)')", "it knows a finger from a mouse")
	assert_string_contains(page, "'Click'", "tap becomes click on a PC")
	assert_string_contains(page, "<b>F1</b>", "a PC's first tip: the keys")
