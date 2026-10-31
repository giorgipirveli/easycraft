extends GutTest
## M3 Task 8's two small screens (no new always-visible HUD button): the building tools' bar (top centre, only
## while LINE, FILL or COPY is in the hand: what to tap next, CANCEL, TURN and NEW COPY) and Build-and-Wear's
## card (the wand tapped a small build: WAKE UP, HAT, BACKPACK, WINGS, each with a picture, or CANCEL).

const ME_AT := Vector3(0.5, 10.0, 0.5)


class EditWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.GRASS if pos.y < 10 else BlockIds.AIR

	func is_editable(_pos: Vector3i) -> bool:
		return true


var me: Player
var tools: BuildToolUser
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	var world := EditWorld.new()
	add_child_autofree(world)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	me._spawned = true
	tools = (me.get_node("BlockInteractor") as BlockInteractor).tools


func after_each() -> void:
	Game.mode = _mode_before


func _hold(id: int) -> void:
	var i := me.get_node("BlockInteractor") as BlockInteractor
	i.set_slot_block(i.selected_slot, id)


func _bar() -> BuildToolBar:
	var bar := BuildToolBar.new()
	add_child_autofree(bar)
	bar.setup(tools)
	return bar


func test_the_bar_shows_only_with_a_power_tool_in_the_hand() -> void:
	var bar := _bar()
	_hold(BlockIds.STONE)
	assert_false(bar.visible, "a block: no bar")
	_hold(ItemIds.PAINT_RED)
	assert_false(bar.visible, "paint is one tap: no bar")
	_hold(ItemIds.REWIND)
	assert_false(bar.visible)
	_hold(ItemIds.FILL_TOOL)
	assert_true(bar.visible)
	assert_eq(bar.words.text, "FILL: tap two corners")
	assert_false(bar.cancel_button.visible, "nothing to cancel yet")
	tools.tap(ItemIds.FILL_TOOL, Vector3i(2, 10, 2))
	assert_eq(bar.words.text, BuildToolUser.OTHER_CORNER)
	assert_true(bar.cancel_button.visible)
	bar.cancel_button.pressed.emit()
	assert_eq(tools.first, BuildToolUser.NO_CELL, "CANCEL drops the first tap")
	assert_false(bar.cancel_button.visible)


func test_turn_and_new_copy_show_with_a_copy() -> void:
	var bar := _bar()
	_hold(ItemIds.COPY_TOOL)
	assert_false(bar.turn_button.visible)
	tools.clipboard = {Vector3i.ZERO: BlockIds.RED}
	tools.state_changed.emit()
	assert_true(bar.turn_button.visible)
	assert_true(bar.new_copy_button.visible)
	assert_eq(bar.words.text, BuildToolUser.PASTE_HINT)
	bar.turn_button.pressed.emit()
	assert_eq(tools.turns, 1)
	bar.new_copy_button.pressed.emit()
	assert_eq(tools.clipboard, {})
	assert_false(bar.turn_button.visible)


func test_the_bars_buttons_are_big_enough() -> void:
	var bar := _bar()
	for b: Button in [bar.cancel_button, bar.turn_button, bar.new_copy_button]:
		assert_gte(b.custom_minimum_size.x, HudLayout.BUTTON_MIN)
		assert_gte(b.custom_minimum_size.y, 64.0)
	assert_has(bar.blockers(), bar.box, "its taps never build")


func test_the_wear_card_offers_four_pictures() -> void:
	var card := WearCard.new()
	add_child_autofree(card)
	assert_false(card.visible)
	card.show_for({"blocks": {Vector3i(1, 10, 1): BlockIds.RED}}, Vector3i(1, 10, 1))
	assert_true(card.visible)
	var names: Array[String] = []
	for b: Button in card.choice_buttons():
		names.append(b.text)
		assert_not_null(b.icon, b.text)
		assert_gte(b.custom_minimum_size.x, HudLayout.BUTTON_MIN)
	assert_eq(names, ["WAKE UP", "HAT", "BACKPACK", "WINGS"] as Array[String])
	var got: Array = []
	card.chosen.connect(func(c: StringName) -> void: got.append(c))
	card.choice_buttons()[2].pressed.emit()
	assert_eq(got, [WearRules.BACK])
	assert_false(card.visible, "a choice closes it")
	card.show_for({"blocks": {}}, Vector3i.ZERO)
	card.cancel_button.pressed.emit()
	assert_eq(got, [WearRules.BACK, &""])
	assert_eq(card.cell, Vector3i.ZERO)
