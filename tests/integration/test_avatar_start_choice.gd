extends GutTest
## Owner feedback #48 (spec §14.6a): BOY / GIRL / JUST ME at the top of the avatar editor and as the last
## first-launch step. The choice puts on a matching starting look and shows the ready-made looks (one tap
## each); every part stays free to mix; the CLOTHES tab dresses the preview. Private profiles and save
## hooks: the real profile file is never written (user://profile.json is shared by every worktree).

const C := preload("res://core/avatar/avatar_catalog.gd")
const SCREEN := Vector2i(2400, 1080)   # the emulator's landscape screen

var editor: AvatarEditor
var profile: ProfileData
var _saves := 0
var _window_size: Vector2i


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func before_each() -> void:
	_saves = 0
	profile = ProfileData.new()
	editor = AvatarEditor.new()
	editor.profile = profile
	editor.save_profile = func() -> void: _saves += 1
	editor.preview_style = "blocky"
	add_child_autofree(editor)
	await wait_process_frames(2)


func _tile(slot: StringName, item: StringName) -> AvatarTile:
	for t: AvatarTile in editor.tiles():
		if t.slot == slot and t.item == item:
			return t
	return null


func test_the_first_choice_is_at_the_top_of_the_editor() -> void:
	var buttons := editor.base_buttons()
	assert_eq(buttons.size(), 3)
	assert_eq(buttons.map(func(b: AvatarTile) -> String: return b.caption), ["BOY", "GIRL", "JUST ME"])
	var top := editor.get_global_rect().position.y
	for b: AvatarTile in buttons:
		assert_gte(b.custom_minimum_size.x, 100.0, "finger-sized")
		assert_gte(b.custom_minimum_size.y, 80.0)
		assert_almost_eq(b.get_global_rect().position.y, top, 1.0, "at the very top of the editor")
		assert_lt(b.get_global_rect().end.y, editor.preview.get_global_rect().position.y + 1.0, "over the preview")
	assert_true(buttons[2].selected, "a look from before is JUST ME")


func test_tapping_girl_puts_on_the_girl_start_and_shows_the_ready_looks() -> void:
	editor.look.skin = &"brown"
	editor.base_buttons()[1].pressed.emit()
	assert_eq(editor.look.base, C.GIRL)
	assert_eq(editor.look.hair, StringName(C.STARTS[C.GIRL].hair))
	assert_eq(editor.look.skin, &"brown", "the skin tone stays the child's")
	assert_not_null(editor.preview.avatar.find_child("hair_%s" % C.STARTS[C.GIRL].hair, true, false), "the preview wears it at once")
	assert_true(editor.base_buttons()[1].selected)
	assert_false(editor.base_buttons()[2].selected)
	assert_eq(editor.tab, AvatarEditor.LOOKS, "the ready-made looks show")
	var names := editor.tiles().map(func(t: AvatarTile) -> StringName: return t.item)
	assert_eq(names.size(), C.PRESETS.size(), "every ready look, one tap each")
	assert_eq(names.slice(0, 2), [&"adventurer", &"princess"], "the girls' first")
	for t: AvatarTile in editor.tiles():
		assert_false(t.locked, "%s is free" % t.item)
		assert_gte(t.custom_minimum_size.x, 120.0, "big tile")
	assert_ne(editor.message.text, "", "a kind line says anything can still change")
	assert_false(editor.buy_button.visible)


func test_a_ready_look_is_one_tap_and_done_keeps_it() -> void:
	editor.choose_base(C.GIRL)
	_tile(AvatarIcon.PRESET, &"princess").pressed.emit()
	assert_eq(editor.look.hat, &"flower_crown")
	assert_eq(editor.look.clothes, &"gown")
	assert_true(_tile(AvatarIcon.PRESET, &"princess").selected)
	assert_false(_tile(AvatarIcon.PRESET, &"adventurer").selected)
	assert_not_null(editor.preview.avatar.find_child("extra_gown_skirt", true, false), "the preview wears the gown")
	assert_false(editor.buy_button.visible, "nothing to buy")
	editor.done()
	assert_eq(profile.avatar.clothes, &"gown")
	assert_eq(profile.avatar.hat, &"flower_crown")
	assert_eq(profile.avatar.base, C.GIRL)
	assert_eq(_saves, 1)


func test_after_the_choice_every_part_still_mixes() -> void:
	editor.choose_base(C.GIRL)
	editor.pick(C.HAIR, &"spiky")
	editor.pick(C.CAPE, &"hero")
	editor.pick(C.CLOTHES, &"overalls")
	editor.done()
	assert_eq(profile.avatar.base, C.GIRL)
	assert_eq(profile.avatar.hair, &"spiky", "a girl can have spiky hair")
	assert_eq(profile.avatar.cape, &"hero")
	assert_eq(profile.avatar.clothes, &"overalls")
	editor.choose_base(C.BOY)
	editor.pick(C.HAIR, &"pigtails")
	editor.pick(C.CLOTHES, &"dress")
	editor.done()
	assert_eq(profile.avatar.base, C.BOY)
	assert_eq(profile.avatar.hair, &"pigtails", "a boy can have long hair")
	assert_eq(profile.avatar.clothes, &"dress")


func test_tapping_the_chosen_one_again_keeps_the_look() -> void:
	editor.choose_base(C.GIRL)
	editor.pick(C.HAIR, &"braid")
	editor.select_tab(C.HAT)
	editor.choose_base(C.GIRL)
	assert_eq(editor.look.hair, &"braid", "only a new choice puts on a new start")
	assert_eq(editor.tab, AvatarEditor.LOOKS, "and the ready looks show again")


func test_the_clothes_tab_dresses_the_preview() -> void:
	editor.select_tab(C.CLOTHES)
	await wait_process_frames(1)
	var items := editor.tiles().map(func(t: AvatarTile) -> StringName: return t.item)
	for cut: StringName in C.items_in(C.CLOTHES):
		assert_has(items, cut)
	assert_eq(_tile(C.CLOTHES, &"none").caption, "Classic")
	assert_same(_tile(C.CLOTHES, &"dress").look, editor.look, "drawn in the child's own colours")
	_tile(C.CLOTHES, &"dress").pressed.emit()
	assert_eq(editor.look.clothes, &"dress")
	assert_not_null(editor.preview.avatar.find_child("extra_dress_skirt", true, false))
	assert_true(_tile(C.CLOTHES, &"dress").selected)
	editor.set_preview_style("realistic")
	assert_not_null(editor.preview.avatar.find_child("extra_dress_skirt_real", true, false), "a real skirt in REAL")


func test_the_editor_still_fits_the_phone_screen_after_girl() -> void:
	get_window().size = SCREEN
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_avatar")
	await wait_process_frames(2)
	var e: AvatarEditor = null
	for n in menu.find_children("*", "", true, false):
		if n is AvatarEditor:
			e = n
	assert_not_null(e)
	e.save_profile = func() -> void: pass
	var viewport := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
	var panel := e.get_parent() as Control
	for step: StringName in [C.GIRL, C.CLOTHES, C.HAIR, C.EMOTE]:
		if step in C.BASES:
			e.choose_base(step)
		else:
			e.select_tab(step)
		await wait_process_frames(2)
		gut.p("%s: the editor's panel %s in %s" % [step, panel.get_global_rect(), viewport])
		assert_true(viewport.grow(-8.0).encloses(panel.get_global_rect()), "%s: the whole panel fits, with a margin" % step)


func test_the_first_launch_look_step_offers_boy_girl_or_just_me() -> void:
	var step := LookChoice.new()
	var mine := ProfileData.new()
	mine.avatar.skin = &"tan"
	step.profile = mine
	var saves := [0]
	step.save_profile = func() -> void: saves[0] += 1
	add_child_autofree(step)
	await wait_process_frames(1)
	watch_signals(step)
	var buttons := step.choices()
	assert_eq(buttons.map(func(b: AvatarTile) -> String: return b.caption), ["BOY", "GIRL", "JUST ME"])
	for b: AvatarTile in buttons:
		assert_gte(b.custom_minimum_size.y, 150.0, "big picture buttons")
	buttons[1].pressed.emit()
	assert_eq(mine.avatar.base, C.GIRL)
	assert_eq(mine.avatar.hair, StringName(C.STARTS[C.GIRL].hair))
	assert_eq(mine.avatar.skin, &"tan")
	assert_eq(saves[0], 1, "saved at once")
	assert_signal_emitted_with_parameters(step, "chosen", [C.GIRL])


func test_the_main_menu_shows_the_look_step_and_it_fits() -> void:
	get_window().size = SCREEN
	var asked: bool = Profile.data.settings.simple_asked
	Profile.data.settings.simple_asked = true   # M3 Task 21a: the welcome card was seen (test_welcome_cards.gd)
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_look_step")
	await wait_process_frames(2)
	var step: LookChoice = null
	for n in menu.find_children("*", "", true, false):
		if n is LookChoice:
			step = n
	assert_not_null(step, "the look step after the name")
	if step == null:
		return
	var viewport := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
	assert_true(viewport.encloses(step.get_global_rect()), "it fits on the screen")
	step.profile = ProfileData.new()
	step.save_profile = func() -> void: pass
	step.choices()[2].pressed.emit()
	await wait_process_frames(2)
	var main_found := false
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text == "SANDBOX\nBuild anything!" and (b as Button).is_visible_in_tree():
			main_found = true
	Profile.data.settings.simple_asked = asked
	assert_true(main_found, "then the main screen")
