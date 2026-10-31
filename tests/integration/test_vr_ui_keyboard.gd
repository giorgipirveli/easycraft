extends GutTest
## Owner #101 (VR on the Meta Quest, P2): a headset has no phone keyboard, so the VR canvas has its own (VrKeyboard),
## for any text box there (the name, chat, codes, pet names, the online keys, the invite code, the Shorts maker: no box
## needs to know it). It comes up on the eye panel when a box has the focus, types into that box as keys do (its own
## rules hold: the longest name, what it lets in, Enter submits), shows what is typed in its own line (the box may be
## under it), and goes with DONE, the controller's B, or the focus moving on; a key never takes the focus. The laser
## presses its keys; the sticks move over them and A presses (PadFocus hands it the pad while it shows).

var _old_pad: PadFocus
var pad: PadFocus


class Owner:
	extends Node


func before_each() -> void:
	_old_pad = PadFocus.instance
	pad = PadFocus.new()
	add_child_autofree(pad)
	Vr.simulate(true)


func after_each() -> void:
	Vr.simulate(false)
	PadFocus.instance = _old_pad


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _screen(max_len: int = 0) -> Dictionary:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var box := VBoxContainer.new()
	box.theme = UiKit.theme()
	box.position = Vector2(300, 60)
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(520, 84)
	edit.max_length = max_len
	box.add_child(edit)
	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(240, 88)
	box.add_child(ok)
	layer.add_child(box)
	UiLayers.route(layer, o)
	PadFocus.watch(box)
	return {"edit": edit, "ok": ok, "box": box}


func _kb() -> VrKeyboard:
	return VrUi.instance.keyboard


func _key(word: String) -> void:
	var b := _kb().key(word)
	assert_not_null(b, "a %s key" % word)
	if b:
		b.pressed.emit()


func _typed() -> void:
	await _frames(2)


func test_a_focused_box_brings_the_keyboard_up_on_the_eye_panel() -> void:
	var s := _screen()
	await _frames(2)
	(s.ok as Button).grab_focus()
	await _frames(2)
	assert_false(_kb().visible, "a button has the focus: no keyboard")
	(s.edit as LineEdit).grab_focus()
	await _frames(2)
	assert_true(_kb().visible)
	assert_eq(_kb().target, s.edit)
	assert_eq(VrUi.instance.panel.place, VrPanelRules.EYE, "typing is done in front of the eyes")


func test_its_keys_type_into_the_box_as_keys_do() -> void:
	var s := _screen(5)
	var edit := s.edit as LineEdit
	var changes: Array[String] = []
	edit.text_changed.connect(func(t: String) -> void: changes.append(t))
	var submitted: Array[String] = []
	edit.text_submitted.connect(func(t: String) -> void: submitted.append(t))
	edit.grab_focus()
	await _frames(2)
	_key("SHIFT")
	_key("M")
	await _typed()
	_key("i")
	_key("a")
	await _typed()
	assert_eq(edit.text, "Mia", "SHIFT for one capital, then small letters again")
	assert_eq(changes.back(), "Mia", "the box's own text_changed (its checks run)")
	assert_eq(_kb().shown_text(), "Mia", "the keyboard's own line shows it")
	_key("DELETE")
	await _typed()
	assert_eq(edit.text, "Mi")
	for k: String in ["1", "2", "3", "4"]:
		_key(k)
	await _typed()
	assert_eq(edit.text, "Mi123", "the box's longest (5) holds")
	_key("ENTER")
	await _typed()
	assert_eq(submitted, ["Mi123"], "Enter submits, as on a keyboard")
	assert_eq(edit.get_viewport().gui_get_focus_owner(), edit, "a key never takes the focus")


func test_done_and_the_focus_moving_on_put_it_away() -> void:
	var s := _screen()
	(s.edit as LineEdit).grab_focus()
	await _frames(2)
	_key("DONE")
	await _frames(2)
	assert_false(_kb().visible, "DONE")
	assert_eq((s.edit as LineEdit).get_viewport().gui_get_focus_owner(), s.edit, "the box keeps the focus")
	await _frames(3)
	assert_false(_kb().visible, "and it stays away while nothing changes")
	(s.ok as Button).grab_focus()
	await _frames(2)
	(s.edit as LineEdit).grab_focus()
	await _frames(2)
	assert_true(_kb().visible, "back on the box: back up")
	(s.ok as Button).grab_focus()
	await _frames(2)
	assert_false(_kb().visible, "the focus moved on")


func test_the_laser_presses_its_keys_without_taking_the_focus() -> void:
	var s := _screen()
	var edit := s.edit as LineEdit
	edit.grab_focus()
	await _frames(2)
	var ui := VrUi.instance
	ui.set_process(false)
	ui.panel.head_source = func() -> Transform3D: return Transform3D(Basis(), Vector3(0, 1.6, 0))
	ui.panel.set_place(VrPanelRules.HIDDEN)
	ui.panel.set_place(VrPanelRules.EYE)
	var k := _kb().key("q")
	var at := k.get_global_rect().get_center()
	var uv := at / Vector2(VrPanelRules.CANVAS)
	var p := ui.panel.global_transform * Vector3((uv.x - 0.5) * ui.panel.size.x, (0.5 - uv.y) * ui.panel.size.y, 0)
	var from := Vector3(0.25, 1.2, -0.2)
	var down := [false]
	ui.pointer.ray_source = func() -> Array: return [from, (p - from).normalized()]
	ui.pointer.trigger_source = func() -> bool: return down[0]
	ui.pointer.step()
	down[0] = true
	ui.pointer.step()
	down[0] = false
	ui.pointer.step()
	await _typed()
	assert_eq(edit.text, "q")
	assert_eq(edit.get_viewport().gui_get_focus_owner(), edit)


func test_the_sticks_move_over_the_keys_and_a_presses() -> void:
	var s := _screen()
	var edit := s.edit as LineEdit
	edit.grab_focus()
	await _frames(2)
	var first := _kb().selected_word()
	_joy(JOY_BUTTON_DPAD_RIGHT)
	assert_ne(_kb().selected_word(), first, "the D-pad (or the stick) moves over the keys")
	var word := _kb().selected_word()
	_joy(JOY_BUTTON_A)
	await _typed()
	assert_eq(word.length(), 1, "a letter or a digit next to the first key")
	assert_eq(edit.text, word, "A presses the key it is on")
	assert_eq(edit.get_viewport().gui_get_focus_owner(), edit, "the screen's focus never moved")
	_joy(JOY_BUTTON_B)
	await _frames(2)
	assert_false(_kb().visible, "B puts it away")


func test_any_box_in_the_canvas_gets_it() -> void:
	# A box no one told about the keyboard (a pet's name on its card, made as the card opens).
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	UiLayers.route(layer, o)
	var card := PanelContainer.new()
	layer.add_child(card)
	var field := LineEdit.new()
	field.custom_minimum_size = Vector2(300, 60)
	card.add_child(field)
	await _frames(1)
	field.grab_focus()
	await _frames(2)
	assert_eq(_kb().target, field)
	_key("p")
	await _typed()
	assert_eq(field.text, "p")


func _joy(button: JoyButton) -> void:
	for d: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 12
		e.button_index = button
		e.pressed = d
		Vr.ui_viewport().push_input(e)
