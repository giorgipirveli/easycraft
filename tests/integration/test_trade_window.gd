extends GutTest
## Owner #37 (spec §14.23): the trade window. Both sides as the host tells them; the child's bag under them (a tap
## gives one, ten or all); a tap on your own thing takes it back; gold chips never offer more than you have or the
## cap; READY and X go to the host; it fits a phone and its buttons are big.

const SCREEN := Vector2(1280, 720)

var w: TradeWindow
var inv: Inventory
var sent: Array = []
var readies: Array = []
var cancels: Array = []
var purse := [100]


func before_each() -> void:
	inv = Inventory.new()
	inv.add(BlockIds.STONE, 25)
	inv.add(ItemIds.SWORD, 1)
	inv.add(ItemIds.CRYSTAL_DESERT, 1)
	sent.clear()
	readies.clear()
	cancels.clear()
	purse[0] = 100
	w = TradeWindow.new()
	w.bag = func() -> Inventory: return inv
	w.gold = func() -> int: return purse[0]
	w.send_offer = func(items: Array, g: int) -> void: sent.append([items, g])
	w.send_ready = func(on: bool) -> void: readies.append(on)
	w.send_cancel = func() -> void: cancels.append(true)
	add_child_autofree(w)
	w.show_state(_state({}, {}, false, false))


func _state(mine: Dictionary, theirs: Dictionary, my_ready: bool, their_ready: bool) -> Dictionary:
	return {"id": 1, "other": 77, "name": "Bob",
		"mine": TradeRules.to_wire(TradeRules.clean_offer(mine, 0)), "theirs": TradeRules.to_wire(TradeRules.clean_offer(theirs, 7)),
		"my_ready": my_ready, "their_ready": their_ready}


func test_it_shows_both_sides_with_the_other_childs_name() -> void:
	w.show_state(_state({}, {BlockIds.DIAMOND: 3}, false, true))
	assert_true(w.is_open())
	assert_eq(w.title.text, "Trade with Bob")
	assert_eq(w.their_heading.text, "BOB GIVES")
	assert_eq([w.their_slots[0].id, w.their_slots[0].count], [BlockIds.DIAMOND, 3])
	assert_eq(w.their_gold.text, "7")
	assert_eq(w.their_ready_label.text, "READY!")


func test_the_bag_shows_what_can_be_given() -> void:
	assert_true(w.bag_ids().has(BlockIds.STONE))
	assert_true(w.bag_ids().has(ItemIds.SWORD))
	assert_false(w.bag_ids().has(ItemIds.CRYSTAL_DESERT), "a crystal can't be traded")


func test_a_tap_on_the_bag_gives_one_ten_or_all() -> void:
	w.add_from_bag(BlockIds.STONE)
	assert_eq(sent.back(), [[[BlockIds.STONE, 1]], 0])
	w.next_step()
	assert_eq(w.step_button.text, "×10")
	w.add_from_bag(BlockIds.STONE)
	assert_eq(sent.back(), [[[BlockIds.STONE, 11]], 0])
	w.add_from_bag(BlockIds.STONE)
	assert_eq(sent.back(), [[[BlockIds.STONE, 21]], 0])
	w.add_from_bag(BlockIds.STONE)
	assert_eq(sent.back(), [[[BlockIds.STONE, 25]], 0], "never more than the bag holds")
	w.next_step()
	assert_eq(w.step_button.text, "ALL")
	w.add_from_bag(ItemIds.SWORD)
	assert_eq(sent.back(), [[[BlockIds.STONE, 25], [ItemIds.SWORD, 1]], 0])
	assert_false(w.bag_ids().has(BlockIds.STONE), "all of it is offered")
	var before := sent.size()
	w.add_from_bag(ItemIds.CRYSTAL_DESERT)
	assert_eq(sent.size(), before, "a crystal is never offered")
	assert_eq(w.message.text, TradeRules.message("not_tradable"))


func test_a_tap_on_your_own_thing_takes_it_back() -> void:
	w.add_from_bag(BlockIds.STONE)
	assert_eq(w.mine_slots[0].id, BlockIds.STONE)
	w.mine_slots[0].pressed.emit()
	assert_eq(sent.back(), [[], 0])
	assert_eq(w.mine_slots[0].id, -1)


func test_gold_chips_never_offer_more_than_you_have_or_the_cap() -> void:
	w.gold_buttons[2].pressed.emit()   # +100
	assert_eq(sent.back()[1], 100)
	w.gold_buttons[0].pressed.emit()   # +1
	assert_eq(sent.back()[1], 100, "only 100 in the purse")
	w.clear_gold_button.pressed.emit()
	assert_eq(sent.back()[1], 0)
	purse[0] = 99999
	for i in 8:
		w.gold_buttons[2].pressed.emit()
	assert_eq(sent.back()[1], TradeRules.gold_cap(Game.universe), "at most the trade's cap")


func test_ready_and_x_go_to_the_host() -> void:
	w.ready_button.pressed.emit()
	assert_eq(readies, [true])
	w.show_state(_state({BlockIds.STONE: 2}, {}, true, false))
	assert_eq(w.ready_button.text, "NOT READY")
	assert_eq(w.my_ready_label.text, "READY!")
	assert_eq(w.message.text, "Waiting for Bob...")
	w.ready_button.pressed.emit()
	assert_eq(readies, [true, false])
	watch_signals(w)
	w.close_button.pressed.emit()
	assert_eq(cancels, [true])
	assert_false(w.is_open())
	assert_signal_emitted(w, "closed")


func test_the_hosts_word_wins() -> void:
	w.add_from_bag(BlockIds.STONE)
	w.show_state(_state({BlockIds.STONE: 4}, {}, false, false))
	assert_eq([w.mine_slots[0].id, w.mine_slots[0].count], [BlockIds.STONE, 4])


func test_it_fits_a_phone_and_its_buttons_are_big() -> void:
	get_window().size = Vector2i(1280, 720)
	await wait_process_frames(2)
	var view := Rect2(Vector2.ZERO, w.get_viewport_rect().size)
	assert_true(view.encloses(w.box.get_global_rect()), "on the screen: %s" % w.box.get_global_rect())
	for b in w.find_children("*", "Button", true, false):
		var r := (b as Control).get_global_rect()
		assert_gte(minf(r.size.x, r.size.y), 64.0, "%s is big enough for a finger" % b.name)
		assert_true(w.box.get_global_rect().encloses(r), "%s is in the window" % b.name)


func test_no_word_rushes_or_shames() -> void:
	w.show_state(_state({BlockIds.STONE: 2}, {}, true, false))
	var text := ""
	for n in w.find_children("*", "Label", true, false):
		text += (n as Label).text + " "
	for n in w.find_children("*", "Button", true, false):
		text += (n as Button).text + " "
	for bad: String in ["hurry", "last chance", "only today", "loser"]:
		assert_false(text.to_lower().contains(bad))
