extends GutTest
## M2 Task 3 (§12.1–12.2): in Survivor each hotbar slot shows how many of it the player has
## (Session.my_inventory) and a slot with none looks faded; the palette shows only what the player
## owns, with counts. Both follow Session.inventory_changed (no per-frame updates). Sandbox is
## unchanged: nothing is counted or faded, the palette offers everything.

const SLOTS: Array[int] = [BlockIds.STONE, BlockIds.DIRT, ItemIds.SWORD, BlockIds.PLANKS, BlockIds.LOG,
	BlockIds.SAND, BlockIds.GLASS, BlockIds.BRICK, ItemIds.PICKAXE]

var inv: Inventory


func before_each() -> void:
	inv = Inventory.new()
	inv.add(BlockIds.STONE, 12)
	inv.add(ItemIds.SWORD, 1)
	inv.add(BlockIds.PLANKS, 1)
	Session.my_inventory = inv


func after_each() -> void:
	Session.survivor_reset()


func _hotbar(counted: bool) -> Hotbar:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	var interactor: BlockInteractor = p.get_node("BlockInteractor")
	interactor.hotbar = SLOTS.duplicate()
	var bar := Hotbar.new()
	bar.counted = counted
	add_child_autofree(bar)
	bar.setup(interactor)
	return bar


func _palette(counted: bool) -> BlockPalette:
	var p := BlockPalette.new()
	p.counted = counted
	add_child_autofree(p)
	return p


## The buttons a player can see in the palette (tooltips are the names).
static func _visible_names(p: BlockPalette) -> Array[String]:
	var names: Array[String] = []
	for b in p.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			names.append((b as Button).tooltip_text)
	return names


func test_survivor_slots_show_counts_and_empty_ones_are_faded() -> void:
	var bar := _hotbar(true)
	assert_eq(bar.count_text(0), "12", "stone")
	assert_false(bar.is_faded(0))
	assert_eq(bar.count_text(1), "", "no dirt: no number ...")
	assert_true(bar.is_faded(1), "... and faded")
	assert_eq(bar.count_text(2), "", "a single sword needs no number")
	assert_false(bar.is_faded(2))
	assert_eq(bar.count_text(3), "1", "one plank is still counted")
	assert_true(bar.is_faded(8), "a pickaxe the player doesn't own")


func test_the_hotbar_follows_every_inventory_change() -> void:
	var bar := _hotbar(true)
	Session.set_inventory(multiplayer.get_unique_id(), inv)
	await wait_frames(1)
	inv.add(BlockIds.DIRT, 5)
	inv.take(BlockIds.STONE, 12)
	assert_eq(bar.count_text(1), "", "not before the frame ends")
	await wait_frames(1)
	assert_eq(bar.count_text(1), "5")
	assert_false(bar.is_faded(1))
	assert_true(bar.is_faded(0), "the last stone was used")


func test_a_lan_guests_hotbar_follows_the_hosts_snapshot() -> void:
	var bar := _hotbar(true)
	Session._rpc_inventory([[BlockIds.SAND, 40]])
	assert_eq(bar.count_text(5), "40")
	assert_true(bar.is_faded(0), "the snapshot has no stone")


func test_sandbox_slots_are_never_counted_or_faded() -> void:
	Session.my_inventory = Inventory.new()
	var bar := _hotbar(false)
	for i in SLOTS.size():
		assert_eq(bar.count_text(i), "")
		assert_false(bar.is_faded(i))


func test_the_survivor_palette_shows_only_what_the_player_owns() -> void:
	var p := _palette(true)
	p.open()
	var names := _visible_names(p)
	names.sort()
	assert_eq(names, ["Planks", "Stone", "Sword"] as Array[String])
	assert_eq(p.count_text(BlockIds.STONE), "12")
	assert_eq(p.count_text(BlockIds.PLANKS), "1")
	assert_eq(p.count_text(ItemIds.SWORD), "")


func test_picking_from_the_survivor_palette_puts_it_in_the_hotbar() -> void:
	var p := _palette(true)
	p.open()
	watch_signals(p)
	for b in p.find_children("*", "Button", true, false):
		if (b as Button).tooltip_text == "Stone":
			(b as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [BlockIds.STONE])
	assert_false(p.visible)


func test_an_empty_survivor_palette_says_how_to_get_blocks() -> void:
	Session.my_inventory = Inventory.new()
	var p := _palette(true)
	p.open()
	assert_eq(_visible_names(p), [] as Array[String])
	assert_true(p.empty_hint().is_visible_in_tree())


func test_the_open_survivor_palette_follows_the_inventory() -> void:
	var p := _palette(true)
	p.open()
	inv.add(BlockIds.COAL, 3)
	Session.inventory_changed.emit()
	assert_has(_visible_names(p), "Coal")
	assert_eq(p.count_text(BlockIds.COAL), "3")


## Everything a player could own fits the panel (it scrolls), above the hotbar.
func test_a_full_survivor_palette_fits_the_panel() -> void:
	for id in BlockIds.PLACEABLE:
		inv.add(id, 999)
	for id in ItemIds.ALL:
		inv.add(id, 1)
	var p := _palette(true)
	p.open()
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	var content := panel.get_combined_minimum_size()
	assert_lte(content.y, panel.offset_bottom - panel.offset_top + 0.5)
	assert_lte(content.x, panel.offset_right - panel.offset_left + 0.5)


func test_the_sandbox_palette_still_offers_everything() -> void:
	Session.my_inventory = Inventory.new()
	var p := _palette(false)
	p.open()
	var blocks_page := _visible_names(p).size()
	assert_eq(p.count_text(BlockIds.STONE), "")
	p.show_page(1)   # M2 Task 6: the ARMORY page
	var armory_page := _visible_names(p).size()
	p.show_page(2)   # M3 Task 7: the SMART page
	var smart_page := _visible_names(p).size()
	p.show_page(BlockPalette.PETS_TAB)   # M3 Task 11: the PETS page (treats)
	var pets_page := _visible_names(p).size()
	p.show_page(BlockPalette.BUILD_TAB)   # M3 Task 8: the BUILD page (tools and paints)
	assert_eq(blocks_page + armory_page + smart_page + pets_page + _visible_names(p).size(), BlockIds.PLACEABLE.size() + ItemIds.ALL.size()
		- ItemIds.TREASURES.size() - ItemIds.CRAFTED.size() - ItemIds.AMMO.size() + SmartPage.SMART_ROW.size() + SmartPage.GAME_ROW.size()
		+ BlockPalette.GADGET_BLOCKS.size() + BlockPalette.MAGIC_BLOCKS.size()   # M3 Task 14a: the gadget blocks; 20a: the saddle
		+ BlockPalette.HOME_BLOCKS.size()   # M3 Task 21b: the shelves (SMART's HOME row)
		+ RocketPage.SPACE_ROW.size()   # spec §21d: the rocket parts (SMART's SPACE row)
		+ 1 - ItemIds.CRYSTALS.size() + CrystalRules.sandbox_crystals(Profile.data.universe_unlocked).size(),   # owner 39: PORTALS
		"everything but treasure, which is only ever found (M2 Task 16), and sticks, only crafted (§12.19), and blaster ammo (Survivor's, M3 Task 14b)")


## M2 Tasks 3 + 6: Survivor's palette is one page of what the player owns (tier weapons and potions
## included), so the ARMORY tab, which offers every tier, is hidden there.
func test_the_survivor_palette_has_no_armory_tab_and_lists_owned_tiers() -> void:
	inv.add(ItemIds.SWORD_IRON, 1)
	inv.add(ItemIds.POTION_SPEED, 2)
	var p := _palette(true)
	p.show_page(1)
	p.open()
	assert_true(p.tab_bar.is_tab_hidden(1), "no ARMORY tab in Survivor (its CRAFT tab shows, spec §12.19)")
	assert_eq(p.tab_bar.current_tab, 0, "it opens on what the player owns")
	var names := _visible_names(p)
	assert_has(names, ItemIds.display_name(ItemIds.SWORD_IRON))
	assert_has(names, ItemIds.display_name(ItemIds.POTION_SPEED))
	assert_does_not_have(names, ItemIds.display_name(ItemIds.SWORD_COSMIC), "only what the player owns")
