extends GutTest
## The block palette's CRAFT tab (spec §12.19): a picture recipe book in Survivor. Every recipe is a big card
## (the result's picture and count, each ingredient's picture with have/need, where it is made); what can be
## made now shines and comes first; a tap on a shining card crafts it through the host, a tap on another
## says kindly what is missing. Sandbox has everything already: no CRAFT tab there.

var _mode_before: StringName
var _me: Player
var _said: Array[String] = []
var _done: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_said.clear()
	_done.clear()
	_me = load("res://entities/player/player.tscn").instantiate()
	_me.name = str(multiplayer.get_unique_id())
	add_child_autofree(_me)
	_me.viewer.free()
	_me.set_physics_process(false)
	var inv := Inventory.new()
	Session.set_inventory(_me.peer_id, inv)
	Session.send_inventory(_me.peer_id)   # the host's own player reads the object itself
	Session.craft_done.connect(_on_done)


func after_each() -> void:
	Session.craft_done.disconnect(_on_done)
	Game.mode = _mode_before
	Session.survivor_reset()


func _on_done(ok: bool, text: String, id: int, count: int) -> void:
	_done.append([ok, text, id, count])


func _inv() -> Inventory:
	return Session.inventory_of(_me.peer_id)


func _palette(counted: bool, table: bool = false) -> BlockPalette:
	var p := BlockPalette.new()
	p.counted = counted
	add_child_autofree(p)
	p.craft_book.stations_provider = func() -> Dictionary:
		return {Recipes.HAND: true, Recipes.TABLE: table, Recipes.FURNACE: false}
	p.craft_book.said.connect(func(text: String) -> void: _said.append(text))
	return p


func test_survivor_shows_blocks_and_craft_sandbox_blocks_and_armory() -> void:
	var p := _palette(true)
	p.open()
	var tabs := p.tab_bar
	assert_true(tabs.is_visible_in_tree())
	assert_eq(tabs.get_tab_title(BlockPalette.CRAFT_PAGE), "CRAFT")
	assert_false(tabs.is_tab_hidden(BlockPalette.CRAFT_PAGE), "Survivor crafts")
	assert_true(tabs.is_tab_hidden(1), "no ARMORY in Survivor")
	assert_true(tabs.is_tab_hidden(BlockPalette.SMART_PAGE), "M3 Task 7's smart blocks are the Sandbox's")
	var s := _palette(false)
	s.open()
	assert_true(s.tab_bar.is_tab_hidden(BlockPalette.CRAFT_PAGE), "Sandbox has everything already")
	assert_false(s.tab_bar.is_tab_hidden(1))
	assert_eq(s.craft_book.cards().size(), 0, "no cards are made in the Sandbox")


func test_the_book_lists_every_recipe_what_can_be_made_first() -> void:
	_inv().add(BlockIds.LOG, 1)
	var p := _palette(true)
	p.open()
	p.show_page(BlockPalette.CRAFT_PAGE)
	var cards := p.craft_book.cards()
	assert_eq(cards.size(), Recipes.LIST.size())
	assert_eq(cards[0].recipe_id, &"planks")
	assert_true(cards[0].can, "a log makes planks by hand")
	assert_true(cards[0].shines())
	for c in cards.slice(1):
		assert_false(c.can, str(c.recipe_id))
		assert_false(c.shines())
	for c in cards:
		assert_gte(c.size.y, 110.0, "big enough for small fingers")
		assert_not_null(c.result_icon(), str(c.recipe_id))


func test_a_card_shows_have_and_need_for_each_ingredient() -> void:
	_inv().add(BlockIds.PLANKS, 1)
	var p := _palette(true)
	p.open()
	p.show_page(BlockPalette.CRAFT_PAGE)
	var sword := p.craft_book.card_for(&"sword")
	assert_eq(sword.have_need_lines(), ["1/2", "0/1"] as Array[String], "planks, then a stick")
	assert_eq(sword.count_text(), "", "one sword")
	assert_eq(p.craft_book.card_for(&"planks").count_text(), "×4")
	assert_eq(sword.station(), Recipes.TABLE)


func test_a_tap_on_a_shining_card_crafts_through_the_host() -> void:
	_inv().add(BlockIds.LOG, 2)
	var p := _palette(true)
	p.open()
	p.show_page(BlockPalette.CRAFT_PAGE)
	p.craft_book.card_for(&"planks").pressed.emit()
	assert_eq(_done, [[true, "You made 4 Planks!", BlockIds.PLANKS, 4]])
	assert_eq(_inv().count(BlockIds.PLANKS), 4)
	assert_eq(_inv().count(BlockIds.LOG), 1)
	await get_tree().process_frame   # the inventory's snapshot, then the book refreshes
	assert_true(p.craft_book.card_for(&"sticks").can, "now planks make sticks")


func test_a_tap_on_another_card_says_what_is_missing() -> void:
	_inv().add(BlockIds.PLANKS, 2)
	var p := _palette(true)
	p.open()
	p.show_page(BlockPalette.CRAFT_PAGE)
	p.craft_book.card_for(&"sword").pressed.emit()
	assert_eq(_said, ["Stand next to a Workbench!"] as Array[String])
	assert_eq(_done, [], "nothing asked of the host")
	var q := _palette(true, true)
	q.open()
	q.show_page(BlockPalette.CRAFT_PAGE)
	q.craft_book.card_for(&"sword").pressed.emit()
	assert_eq(_said.back(), "You need 1 more Stick!")


func test_a_table_nearby_lights_up_its_recipes() -> void:
	_inv().add(BlockIds.PLANKS, 2)
	_inv().add(ItemIds.STICK, 1)
	var p := _palette(true, true)
	p.open()
	p.show_page(BlockPalette.CRAFT_PAGE)
	assert_true(p.craft_book.card_for(&"sword").can)
	assert_true(p.craft_book.card_for(&"sword").shines())
