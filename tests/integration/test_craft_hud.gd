extends GutTest
## Crafting on the HUD (spec §12.19): the host's answer is a toast; something new goes into the first hotbar
## slot that holds nothing (unless it is on the hotbar already); the book knows where the player can craft.

var _mode_before: StringName
var _hud: Hud


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	_hud = Hud.new()
	add_child_autofree(_hud)
	_hud.setup(p, "Kid", true, false)
	_hud.setup_crafting()
	var inv := Inventory.new()
	inv.add(BlockIds.PLANKS, 3)
	inv.add(BlockIds.STONE, 5)
	Session.set_inventory(p.peer_id, inv)
	Session.send_inventory(p.peer_id)
	_hud.interactor.hotbar = [BlockIds.PLANKS, BlockIds.STONE, BlockIds.DIRT, BlockIds.SAND, BlockIds.LOG,
		BlockIds.GLASS, BlockIds.BRICK, ItemIds.SWORD, ItemIds.PICKAXE] as Array[int]


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func test_the_hosts_answer_is_a_toast() -> void:
	Session.craft_done.emit(false, "You need 1 more Stick!", ItemIds.SWORD, 0)
	assert_eq(_hud._toast_label.text, "You need 1 more Stick!")
	assert_true(_hud._toast_panel.visible)


func test_something_new_goes_into_the_first_empty_slot() -> void:
	Session.my_inventory.add(BlockIds.CRAFTING_TABLE, 1)
	Session.craft_done.emit(true, "You made a Workbench!", BlockIds.CRAFTING_TABLE, 1)
	assert_eq(_hud.interactor.hotbar[2], BlockIds.CRAFTING_TABLE, "dirt: none left, so its slot takes the table")
	assert_eq(_hud.interactor.hotbar[0], BlockIds.PLANKS, "slots with something stay")
	Session.craft_done.emit(true, "You made a Workbench!", BlockIds.CRAFTING_TABLE, 1)
	assert_eq(_hud.interactor.hotbar.count(BlockIds.CRAFTING_TABLE), 1, "never twice")


func test_the_book_asks_where_the_player_stands() -> void:
	var st: Dictionary = _hud.palette.craft_book.stations_provider.call()
	assert_true(st.has(Recipes.TABLE))
	assert_true(st[Recipes.HAND])
