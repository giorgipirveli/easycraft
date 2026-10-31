extends GutTest
## Owner feedback #51 (2026-09-25): "in the plus icon, where you open to see an inventory, in sandbox add a mob
## version, where all the monsters or pets are (not the pets we already added)". The palette's MOBS tab in the
## Sandbox: every animal kind, every monster kind and the bosses, each a picture tile; a tap closes the palette and
## asks for that creature in front of the child (the host's /summon, so its checks and chat line apply). Survivor has
## no MOBS tab (free monsters would break its fair play). The PETS tab (treats) stays as it is; Pip is a pet, not a mob.

const HOTBAR_TOP := 720.0 - 78.0

var _inv_before: Inventory


func before_each() -> void:
	_inv_before = Session.my_inventory
	Session.my_inventory = Inventory.new()


func after_each() -> void:
	Session.my_inventory = _inv_before


func _palette(counted := false) -> BlockPalette:
	var p := BlockPalette.new()
	p.counted = counted
	p.use_gift_book(GiftStampBook.new())
	add_child_autofree(p)
	return p


func _tiles(p: BlockPalette) -> Array[Button]:
	var list: Array[Button] = []
	for b in p.find_child("MOBS", true, false).find_children("Mob_*", "Button", true, false):
		list.append(b as Button)
	return list


func test_the_sandbox_has_a_mobs_tab_with_every_animal_monster_and_boss() -> void:
	var p := _palette()
	p.open()
	assert_eq(p.tab_bar.get_tab_title(BlockPalette.MOBS_TAB), "MOBS")
	assert_false(p.tab_bar.is_tab_hidden(BlockPalette.MOBS_TAB), "shown in the Sandbox")
	var words := {}
	for b in _tiles(p):
		words[String(b.name).trim_prefix("Mob_")] = true
	for w: String in ChatCommands.ANIMALS:
		if w == "pip":
			assert_false(words.has(w), "Pip is a pet, not a mob")
			continue
		assert_true(words.has(w), "the %s" % w)
	for w: String in ChatCommands.MONSTERS + ChatCommands.BOSSES:
		assert_true(words.has(w), "the %s" % w)
	assert_eq(words.size(), ChatCommands.ANIMALS.size() - 1 + ChatCommands.MONSTERS.size() + ChatCommands.BOSSES.size())


func test_survivor_has_no_mobs_tab() -> void:
	var p := _palette(true)
	p.open()
	assert_true(p.tab_bar.is_tab_hidden(BlockPalette.MOBS_TAB))


func test_a_tap_asks_for_that_creature_and_closes_the_palette() -> void:
	var p := _palette()
	p.open()
	watch_signals(p)
	(p.find_child("Mob_horse", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "mob_requested", ["horse"])
	assert_false(p.visible, "the palette closes: the horse comes out in front")
	p.open()
	(p.find_child("Mob_shadowbat", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "mob_requested", ["shadowbat"], 1)


func test_every_tile_has_a_picture_and_a_name() -> void:
	for b in _tiles(_palette()):
		assert_gt(b.get_child_count(), 0, "%s has a picture" % b.name)
		assert_ne(b.tooltip_text, "", "%s has a name" % b.name)
		assert_gte(b.custom_minimum_size.x, 64.0, "big enough for small fingers")


func test_every_animal_and_monster_can_be_drawn() -> void:
	for w: String in ChatCommands.ANIMALS:
		if w != "pip":
			assert_false(AnimalPortrait.faces(StringName(w)).is_empty(), w)
	for w: String in ChatCommands.MONSTERS:
		assert_false(AnimalPortrait.monster_faces(ChatCommands.monster_kind(w)).is_empty(), w)


func test_the_palette_still_fits_above_the_hotbar() -> void:
	var p := _palette()
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	p.show_page(BlockPalette.MOBS_TAB)
	var content := panel.get_combined_minimum_size()
	assert_lte(720.0 * 0.5 + panel.offset_bottom, HOTBAR_TOP, "above the hotbar")
	assert_lte(content.y, panel.offset_bottom - panel.offset_top + 0.5)
	assert_lte(content.x, panel.offset_right - panel.offset_left + 0.5)
