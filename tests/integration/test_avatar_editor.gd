extends GutTest
## M3 Task 9 (spec §14.6): the avatar editor. Big, icon-first tabs and tiles; tapping anything tries it
## on the turning 3D preview; locked items show their fixed price (BUY) or how they are earned; DONE
## saves only what is owned. The editor's own tests use a private profile and save hook, so they
## never touch the real profile.

const SLOTS := AvatarCatalog.SLOTS

var editor: AvatarEditor
var profile: ProfileData
var _saves := 0


func before_each() -> void:
	_saves = 0
	profile = ProfileData.new()
	profile.survivor_gold = 500
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


func _torso_color() -> Color:
	var mi := editor.preview.avatar.find_child("Torso", true, false) as MeshInstance3D
	return (mi.material_override as StandardMaterial3D).albedo_color


func test_there_is_a_big_picture_tab_for_every_slot() -> void:
	assert_eq(editor.tab_buttons().size(), SLOTS.size())
	for b: AvatarTile in editor.tab_buttons():
		assert_gte(b.custom_minimum_size.x, 100.0, "finger-sized tab")
		assert_gte(b.custom_minimum_size.y, 64.0)
		assert_ne(b.caption, "", "a short word under the picture")


func test_each_tab_shows_its_items_as_big_tiles() -> void:
	for slot: StringName in SLOTS:
		editor.select_tab(slot)
		await wait_process_frames(1)
		var names := editor.tiles().map(func(t: AvatarTile) -> StringName: return t.item)
		for n: StringName in AvatarCatalog.items_in(slot):
			assert_has(names, n, "%s shows %s" % [slot, n])
		for t: AvatarTile in editor.tiles():
			assert_gte(t.custom_minimum_size.x, 120.0, "big tile")
	editor.select_tab(AvatarCatalog.HAIR)
	await wait_process_frames(1)
	var colours := editor.tiles().filter(func(t: AvatarTile) -> bool: return t.slot == AvatarCatalog.HAIR_COLOR)
	assert_eq(colours.size(), AvatarCatalog.HAIR_COLORS.size(), "the hair tab also has the hair colours")


func test_tapping_a_colour_dresses_the_preview() -> void:
	editor.select_tab(AvatarCatalog.SHIRT)
	await wait_process_frames(1)
	_tile(AvatarCatalog.SHIRT, &"red").pressed.emit()
	assert_eq(editor.look.shirt, &"red")
	assert_eq(_torso_color(), AvatarCatalog.CLOTH[&"red"], "the preview wears it at once")
	assert_true(_tile(AvatarCatalog.SHIRT, &"red").selected)


func test_a_locked_item_can_be_tried_on_and_bought_at_its_fixed_price() -> void:
	var price := AvatarCatalog.price("hat.crown")
	editor.pick(AvatarCatalog.HAT, &"crown")
	assert_not_null(editor.preview.avatar.find_child("hat_crown", true, false), "tried on")
	assert_true(editor.buy_button.visible)
	assert_false(editor.buy_button.disabled)
	assert_string_contains(editor.buy_button.text, str(price))
	editor.buy()
	assert_eq(profile.survivor_gold, 500 - price)
	assert_true(AvatarUnlocks.is_owned("hat.crown", profile.cosmetics))
	assert_eq(_saves, 1, "a purchase is saved at once")
	assert_false(editor.buy_button.visible)
	assert_eq(editor.gold_label.text, str(500 - price))


func test_without_enough_gold_buy_says_how_much_more() -> void:
	profile.survivor_gold = 50
	editor.refresh()
	editor.pick(AvatarCatalog.HAT, &"crown")
	assert_true(editor.buy_button.disabled)
	assert_eq(editor.message.text, "You need %d more gold." % (AvatarCatalog.price("hat.crown") - 50))
	editor.buy()
	assert_eq(profile.survivor_gold, 50)


func test_an_earned_item_says_how_to_earn_it() -> void:
	editor.pick(AvatarCatalog.OUTFIT, &"cosmic")
	assert_false(editor.buy_button.visible, "no price: it can't be bought")
	assert_string_contains(editor.message.text, "Cake Monster")
	var tile := _tile(AvatarCatalog.OUTFIT, &"cosmic")
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(1)
	tile = _tile(AvatarCatalog.OUTFIT, &"cosmic")
	assert_true(tile.locked)
	assert_eq(tile.rarity_color, AvatarCatalog.RARITY_COLORS[AvatarCatalog.LEGENDARY], "legendary gold rim")


func test_done_keeps_only_owned_items_and_saves() -> void:
	watch_signals(editor)
	editor.pick(AvatarCatalog.HAT, &"crown")    # tried on, not bought
	editor.pick(AvatarCatalog.CAPE, &"hero")    # free
	editor.pick(AvatarCatalog.SHIRT, &"green")
	editor.done()
	assert_eq(profile.avatar.hat, &"none", "a tried-on item is not kept")
	assert_eq(profile.avatar.cape, &"hero")
	assert_eq(profile.avatar.shirt, &"green")
	assert_eq(_saves, 1)
	assert_signal_emitted(editor, "closed")


func test_the_emote_tab_puts_owned_emotes_on_the_wheel() -> void:
	editor.select_tab(AvatarCatalog.EMOTE)
	await wait_process_frames(1)
	assert_eq(editor.wheel_slots().size(), AvatarCatalog.WHEEL_SLOTS)
	editor.select_wheel_slot(7)
	editor.pick(AvatarCatalog.EMOTE, &"bow")      # 60 gold, not owned yet
	assert_eq(editor.preview.avatar.emote(), &"bow", "the preview shows it")
	assert_ne(editor.look.emotes[7], &"bow", "not on the wheel before it is owned")
	editor.buy()
	editor.pick(AvatarCatalog.EMOTE, &"bow")
	assert_eq(editor.look.emotes[7], &"bow", "on the wheel")
	editor.select_wheel_slot(0)
	editor.pick(AvatarCatalog.EMOTE, &"bow")
	assert_eq(editor.look.emotes[0], &"bow", "moved to another spot")
	assert_eq(editor.look.emotes.count(&"bow"), 1, "never twice on the wheel")
	assert_eq(editor.look.emotes.size(), AvatarCatalog.WHEEL_SLOTS)


func test_the_preview_shows_either_style() -> void:
	assert_true(editor.preview.avatar is BlockyAvatar)
	editor.set_preview_style("realistic")
	assert_true(editor.preview.avatar is RealisticAvatar)
	assert_true(editor.preview.avatar.look().equals(editor.look), "wearing the same look")


func test_the_preview_turns_by_itself_and_by_dragging() -> void:
	var start := editor.preview.turntable.rotation.y
	await wait_process_frames(10)
	assert_ne(editor.preview.turntable.rotation.y, start, "turns slowly")
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.relative = Vector2(100, 0)
	var before := editor.preview.turntable.rotation.y
	editor.preview.gui_input.emit(drag)
	assert_ne(editor.preview.turntable.rotation.y, before, "a finger turns it")


func test_the_preview_makes_no_new_materials_while_open() -> void:
	editor.pick(AvatarCatalog.SHIRT, &"red")
	await wait_process_frames(5)
	var count := AvatarParts.material_count()
	await wait_process_frames(30)
	assert_eq(AvatarParts.material_count(), count)


func test_in_a_survivor_world_the_host_takes_the_gold() -> void:
	var mode := Game.mode
	var gold := Profile.data.survivor_gold
	var owned := Profile.data.cosmetics.duplicate()
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 1000
	Profile.data.cosmetics = [] as Array[String]
	var e := AvatarEditor.new()
	e.profile = Profile.data
	e.save_profile = func() -> void: _saves += 1
	e.world_economy = true
	add_child_autofree(e)
	await wait_process_frames(1)
	e.pick(AvatarCatalog.WINGS, &"bat")
	e.buy()
	assert_eq(Profile.data.survivor_gold, 1000 - AvatarCatalog.price("wings.bat"), "through Session.gold_spend")
	assert_true(AvatarUnlocks.is_owned("wings.bat", Profile.data.cosmetics))
	assert_eq(e.gold_label.text, str(1000 - AvatarCatalog.price("wings.bat")))
	Game.mode = mode
	Profile.data.survivor_gold = gold
	Profile.data.cosmetics = owned
