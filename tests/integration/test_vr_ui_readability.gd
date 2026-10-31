extends GutTest
## Owner #101 (VR on the Meta Quest, P2): the readability pass. In a headset the eye panel is 1.4 m away (about 21
## canvas pixels a degree): no word on the VR canvas is drawn under 24 px, whatever size its screen gave it (put back
## when VR ends), and the buttons' white words get the labels' dark outline (white on the game's green is 2.9:1, under
## the 4.5:1 floor). Off VR nothing changes.

var _old_pad: PadFocus


class Owner:
	extends Node


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null


func after_each() -> void:
	Vr.simulate(false)
	PadFocus.instance = _old_pad


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _screen() -> Dictionary:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var box := VBoxContainer.new()
	box.theme = UiKit.theme()
	layer.add_child(box)
	var label := Label.new()
	label.text = "Made by Alexander Pirveli"
	label.add_theme_font_size_override("font_size", 20)
	box.add_child(label)
	var plain := Label.new()
	plain.text = "the theme's 30 px"
	box.add_child(plain)
	var button := Button.new()
	button.text = "admin panel"
	button.add_theme_font_size_override("font_size", 14)
	box.add_child(button)
	var rich := RichTextLabel.new()
	rich.text = "a hint"
	rich.fit_content = true
	rich.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(rich)
	var touch := TouchButton.new()
	touch.text = "JUMP"
	touch.font_size = 16
	touch.custom_minimum_size = Vector2(100, 100)
	box.add_child(touch)
	UiLayers.route(layer, o)
	return {"label": label, "plain": plain, "button": button, "rich": rich, "touch": touch, "box": box}


func test_the_contrast_rule() -> void:
	assert_almost_eq(VrReadability.contrast(Color.WHITE, Color.BLACK), 21.0, 0.01)
	assert_almost_eq(VrReadability.contrast(Color.BLACK, Color.WHITE), 21.0, 0.01, "either way round")
	var green := VrReadability.contrast(Color.WHITE, UiKit.GREEN)
	gut.p("white on the game's green %.2f:1, orange %.2f:1, blue %.2f:1, the dark box %.2f:1" % [green,
		VrReadability.contrast(Color.WHITE, UiKit.ORANGE), VrReadability.contrast(Color.WHITE, UiKit.BLUE),
		VrReadability.contrast(Color.WHITE, Color(0.16, 0.2, 0.32))])
	assert_lt(green, VrReadability.MIN_CONTRAST, "why the buttons' words get an outline in VR")
	assert_gt(VrReadability.contrast(Color.WHITE, Color(0.16, 0.2, 0.32)), VrReadability.MIN_CONTRAST,
		"the theme's dark button and panel pass by themselves")


func test_off_vr_nothing_changes() -> void:
	var s := _screen()
	await _frames(2)
	assert_eq((s.label as Label).get_theme_font_size("font_size"), 20)
	assert_eq((s.button as Button).get_theme_font_size("font_size"), 14)
	assert_eq((s.button as Button).get_theme_constant("outline_size"), 0, "no outline on buttons on a phone")


func test_in_vr_no_word_is_drawn_under_24_px_and_each_comes_back() -> void:
	Vr.simulate(true)
	var s := _screen()
	await _frames(2)
	assert_eq(VrReadability.too_small(Vr.ui_viewport()), [] as Array[String], "every word 24 px or more")
	assert_eq((s.label as Label).get_theme_font_size("font_size"), VrReadability.MIN_PX)
	assert_eq((s.rich as RichTextLabel).get_theme_font_size("normal_font_size"), VrReadability.MIN_PX)
	assert_eq((s.touch as TouchButton).font_size, VrReadability.MIN_PX, "the HUD's buttons' words too")
	assert_eq((s.plain as Label).get_theme_font_size("font_size"), 30, "big enough already: untouched")
	assert_eq((s.button as Button).get_theme_constant("outline_size"), VrReadability.OUTLINE_PX, "white words outlined")
	var ink := Button.new()   # the books' dark ink on paper: no outline
	ink.text = "MAKE IT"
	ink.add_theme_color_override("font_color", Color("4a2f18"))
	(s.box as Control).add_child(ink)
	await _frames(2)
	assert_eq(ink.get_theme_constant("outline_size"), 0, "dark words on a light button keep none")
	Vr.simulate(false)
	await _frames(1)
	assert_eq((s.label as Label).get_theme_font_size("font_size"), 20, "its own size again off VR")
	assert_eq((s.button as Button).get_theme_font_size("font_size"), 14)
	assert_eq((s.touch as TouchButton).font_size, 16)
	assert_false((s.plain as Label).has_theme_font_size_override("font_size"))
	assert_eq((s.button as Button).get_theme_constant("outline_size"), 0, "off VR: no outline again")


func test_words_added_later_are_lifted_too() -> void:
	Vr.simulate(true)
	var s := _screen()
	await _frames(2)
	var late := Label.new()
	late.text = "a toast that came later"
	(s.box as Control).add_child(late)
	late.add_theme_font_size_override("font_size", 18)   # its screen sizes it after adding it
	await _frames(2)
	assert_eq(late.get_theme_font_size("font_size"), VrReadability.MIN_PX)


func test_a_screen_drawn_smaller_counts_as_its_drawn_size() -> void:
	var holder := Control.new()
	holder.scale = Vector2(0.8, 0.8)   # a menu panel too tall for the screen
	add_child_autofree(holder)
	var l := Label.new()
	l.text = "Pick your name"
	l.add_theme_font_size_override("font_size", 26)
	holder.add_child(l)
	assert_almost_eq(VrReadability.drawn_px(l), 20.8, 0.01)
	assert_eq(VrReadability.too_small(holder).size(), 1, "the audit sees it")
