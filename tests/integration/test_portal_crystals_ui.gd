extends GutTest
## Owner feedback #39 (spec §14.2a): where a child meets universe crystals and Sandbox worlds. The Sandbox palette's
## SMART page has a PORTALS row (a frame and the crystal of every universe reached); a crystal in the hand places its
## universe's core; Tilly's HOME lists the crystals up to her universe; the main menu's SANDBOX offers a card per
## Sandbox world once a portal made a second one ("Frostpeak Sandbox").

var _unlocked := 1


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


func _palette() -> BlockPalette:
	var p := BlockPalette.new()
	add_child_autofree(p)
	return p


func _row_ids(p: BlockPalette) -> Array[int]:
	var ids: Array[int] = []
	for b in p.crystal_row.get_children():
		if b is Button:
			for id in [BlockIds.PORTAL_FRAME] + ItemIds.CRYSTALS:
				if (b as Button).tooltip_text == ItemIds.display_name(id):
					ids.append(id)
	return ids


func test_the_sandbox_palette_has_the_crystals_of_the_universes_reached() -> void:
	Profile.data.universe_unlocked = 2
	var p := _palette()
	assert_eq(_row_ids(p), [BlockIds.PORTAL_FRAME, ItemIds.CRYSTAL_MEADOWS, ItemIds.CRYSTAL_DESERT] as Array[int])
	Profile.data.universe_unlocked = 5
	var q := _palette()
	assert_eq(_row_ids(q).size(), 6, "a frame and five crystals")


func test_picking_a_crystal_puts_it_in_the_hotbar() -> void:
	Profile.data.universe_unlocked = 3
	var p := _palette()
	var got: Array[int] = []
	p.picked.connect(func(id: int) -> void: got.append(id))
	for b in p.crystal_row.get_children():
		if b is Button and (b as Button).tooltip_text == "Frost Crystal":
			(b as Button).pressed.emit()
	assert_eq(got, [ItemIds.CRYSTAL_FROST] as Array[int])
	assert_true(ItemIds.is_hotbar_valid(ItemIds.CRYSTAL_FROST))


func test_the_menu_offers_a_card_per_sandbox_world_once_there_are_two() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(2)
	var none := func(_slot: String) -> bool: return false
	var frost := func(slot: String) -> bool: return slot == "sandbox_3"
	assert_eq(menu.call("sandbox_worlds", none), [1] as Array[int], "one Sandbox world: SANDBOX as before")
	assert_eq(menu.call("sandbox_worlds", frost), [1, 3] as Array[int])
	assert_eq(menu.call("_world_title", ModeRules.SANDBOX, 1), "Sandbox")
	assert_eq(menu.call("_world_title", ModeRules.SANDBOX, 3), "Frostpeak Sandbox")


func test_tilly_sells_crystals_in_her_home_shelf_up_to_her_universe() -> void:
	var home := ShopRules.catalog(ShopRules.HOME, 3)
	for id in [ItemIds.CRYSTAL_MEADOWS, ItemIds.CRYSTAL_DESERT, ItemIds.CRYSTAL_FROST]:
		assert_true(home.has(id), ItemIds.display_name(id))
	assert_false(home.has(ItemIds.CRYSTAL_CANDY))
	var inv := Inventory.new()
	var wallet := Wallet.new(1000)
	var r := ShopRules.buy(ItemIds.CRYSTAL_DESERT, wallet, inv, 3)
	assert_true(r.ok)
	assert_eq(inv.count(ItemIds.CRYSTAL_DESERT), 1, "one crystal")
	assert_eq(int(r.gold), CrystalRules.PRICE * 4)


func test_the_hub_panel_fits_five_universes_on_a_1280_screen() -> void:
	var panel := HubPanel.new()
	add_child_autofree(panel)
	var entries: Array[Dictionary] = []
	for u in range(1, 6):
		entries.append({"universe": u, "open": true})
	panel.open(entries, 1)
	await wait_frames(2)
	var box := panel.find_children("*", "PanelContainer", true, false)[0] as PanelContainer
	assert_lte(box.get_combined_minimum_size().x, 1280.0, "five cards and the panel's margins fit (%.0f)" % box.get_combined_minimum_size().x)
