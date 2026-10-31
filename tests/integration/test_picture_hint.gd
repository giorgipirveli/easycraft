extends GutTest
## M2 Task 3 (the lead's child-friendly feedback): the first time a player meets an ore that needs an
## iron pickaxe, a picture hint shows a pickaxe in the iron colour with a short line, below the
## toasts. It is shown once per profile (ProfileData.hints_seen).

var _seen_before: Array[String] = []


func before_each() -> void:
	_seen_before = Profile.data.hints_seen.duplicate()
	Profile.data.hints_seen.clear()


func after_each() -> void:
	Profile.data.hints_seen = _seen_before


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	return hud


func test_the_first_iron_pickaxe_refusal_shows_a_picture_once() -> void:
	var hud := _hud()
	assert_false(hud.picture_hint.visible)
	Session.magic_feedback.emit(GatherRules.NEED_IRON_MESSAGE)
	assert_true(hud.picture_hint.visible)
	assert_same(hud.picture_hint.icon.texture, BlockIcons.icon(ItemIds.PICKAXE))
	assert_eq(hud.picture_hint.icon.modulate, Hud.IRON_COLOR)
	assert_string_contains(hud.picture_hint.label.text, "IRON pickaxe")
	assert_has(Profile.data.hints_seen, Hud.IRON_HINT, "remembered in the profile")
	hud.picture_hint.visible = false
	Session.magic_feedback.emit(GatherRules.NEED_IRON_MESSAGE)
	assert_false(hud.picture_hint.visible, "only the first time")


func test_other_messages_show_no_picture() -> void:
	var hud := _hud()
	Session.magic_feedback.emit("You have no Stone left!")
	Session.magic_feedback.emit(GatherRules.NEED_PICKAXE_MESSAGE)
	assert_false(hud.picture_hint.visible)
	assert_eq(Profile.data.hints_seen, [] as Array[String])


func test_the_picture_fades_away_by_itself() -> void:
	var hud := _hud()
	hud.picture_hint.show_hint(BlockIcons.icon(ItemIds.PICKAXE), Hud.IRON_COLOR, "Hi", 0.1)
	await wait_seconds(0.1 + PictureHint.FADE_SECONDS + 0.2)
	assert_false(hud.picture_hint.visible)


func test_the_hint_sits_below_the_toasts_and_under_the_palette() -> void:
	var hud := _hud()
	assert_lt(hud.picture_hint.get_index(), hud.palette.get_index(), "the palette overlay covers it")
	assert_gt(hud.picture_hint.offset_top, 96.0 + 50.0, "below the toast line")
	assert_eq(hud.picture_hint.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never eats a tap")
