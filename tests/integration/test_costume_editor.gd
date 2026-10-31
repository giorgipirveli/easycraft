extends GutTest
## Owner feedback #36 (spec §14.6b): the costumes in the avatar editor. The OUTFIT tab is the COSTUME tab: the
## Storybook pack's costumes first (one tap puts on the whole look), then the outfits. A locked costume can be tried
## on and says how it is earned (never a price); DONE keeps only what is owned. Opening the editor gives costumes
## already earned by playing (an old profile gets them too). Private profiles and save hooks: the real profile file
## is never written.

var editor: AvatarEditor
var profile: ProfileData
var _saves := 0


func _open(p: ProfileData) -> void:
	_saves = 0
	profile = p
	editor = AvatarEditor.new()
	editor.profile = profile
	editor.save_profile = func() -> void: _saves += 1
	editor.preview_style = "blocky"
	add_child_autofree(editor)
	await wait_process_frames(2)


func _costume_tiles() -> Array[AvatarTile]:
	var out: Array[AvatarTile] = []
	for t: AvatarTile in editor.tiles():
		if t.slot == AvatarIcon.COSTUME:
			out.append(t)
	return out


func _tile(id: StringName) -> AvatarTile:
	for t in _costume_tiles():
		if t.item == id:
			return t
	return null


func test_the_costume_tab_shows_every_costume_first() -> void:
	await _open(ProfileData.new())
	var tab: AvatarTile = null
	for t: AvatarTile in editor.tab_buttons():
		if t.slot == AvatarCatalog.OUTFIT:
			tab = t
	assert_eq(tab.caption, "COSTUME")
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(1)
	var tiles := _costume_tiles()
	assert_eq(tiles.map(func(t: AvatarTile) -> StringName: return t.item), Array(CostumeRules.ORDER), "in the pack's order")
	for i in tiles.size():
		assert_eq(editor.tiles()[i], tiles[i], "costumes come first")
		assert_gte(tiles[i].custom_minimum_size.x, 120.0, "a big tile")
		assert_true(tiles[i].locked, "a new profile has earned none yet")
		assert_eq(tiles[i].price, 0, "never a price")
		assert_eq(tiles[i].caption, AvatarCatalog.display_name(CostumeRules.item_id(tiles[i].item)))
		var font := tiles[i].get_theme_default_font()
		assert_lte(font.get_string_size(tiles[i].caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x,
			tiles[i].custom_minimum_size.x - 8.0, "%s's name fits under its picture" % tiles[i].item)
	var outfits := editor.tiles().filter(func(t: AvatarTile) -> bool: return t.slot == AvatarCatalog.OUTFIT)
	assert_eq(outfits.size(), AvatarCatalog.items_in(AvatarCatalog.OUTFIT).size(), "the outfits are still there")


func test_a_locked_costume_can_be_tried_on_and_says_how_to_earn_it() -> void:
	await _open(ProfileData.new())
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(1)
	_tile(&"dorothy").pressed.emit()
	assert_eq(editor.look.clothes, &"gingham", "the whole costume goes on")
	assert_eq(editor.look.hat, &"sunbonnet")
	assert_not_null(editor.preview.avatar.find_child("hat_sunbonnet", true, false), "the preview wears it")
	assert_eq(editor.message.text, CostumeRules.line(&"dorothy"), "how it is earned")
	assert_false(editor.buy_button.visible, "never for gold")
	assert_false(editor.wish_button.visible, "never on a grown-up's list")
	assert_true(_tile(&"dorothy").selected)
	editor.done()
	assert_eq(profile.avatar.hat, &"none", "DONE keeps only what is owned")
	assert_eq(profile.avatar.clothes, &"none")
	assert_eq(profile.avatar.hair, &"pigtails", "free parts of it stay")


func test_an_earned_costume_is_one_tap_and_done_keeps_it() -> void:
	var p := ProfileData.new()
	AvatarUnlocks.grant(p, CostumeRules.item_id(&"robin_hood"))
	p.avatar.skin = &"tan"
	await _open(p)
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(1)
	assert_false(_tile(&"robin_hood").locked)
	_tile(&"robin_hood").pressed.emit()
	assert_eq(editor.message.text, "Robin Hood")
	assert_eq(editor.look.skin, &"tan", "the child's own skin tone")
	editor.done()
	assert_true(profile.avatar.equals(CostumeRules.wear(&"robin_hood", profile.avatar)), "kept whole")
	assert_eq(profile.avatar.hat, &"feather_cap")
	assert_eq(_saves, 1)


func test_costume_parts_mix_in_their_own_tabs_once_earned() -> void:
	var p := ProfileData.new()
	AvatarUnlocks.grant(p, CostumeRules.item_id(&"hatter"))
	await _open(p)
	editor.pick(AvatarCatalog.HAT, &"hatter")
	editor.pick(AvatarCatalog.CLOTHES, &"gown")
	editor.done()
	assert_eq(profile.avatar.hat, &"hatter", "the Hatter's hat with a princess gown")
	assert_eq(profile.avatar.clothes, &"gown")
	editor.pick(AvatarCatalog.HAT, &"deerstalker")
	assert_string_contains(editor.message.text, "Sherlock Holmes", "a locked part says which costume brings it")


func test_opening_the_editor_gives_costumes_already_earned() -> void:
	var p := ProfileData.new()
	p.progress.xp = LevelRules.xp_to_reach(3)
	p.progress.quests.done.append("tilly_pets")
	await _open(p)
	assert_true(CostumeRules.is_complete(&"alice", profile.cosmetics), "level 3: Alice")
	assert_true(CostumeRules.is_complete(&"dorothy", profile.cosmetics), "Tilly's pet story: Dorothy")
	assert_eq(_saves, 1, "saved at once")
	assert_string_contains(editor.message.text, "Alice")
	assert_string_contains(editor.message.text, "Dorothy")
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(1)
	assert_false(_tile(&"alice").locked)
	assert_true(_tile(&"pinocchio").locked)


func test_the_editor_still_fits_the_phone_screen_on_the_costume_tab() -> void:
	await _open(ProfileData.new())
	editor.select_tab(AvatarCatalog.OUTFIT)
	await wait_process_frames(2)
	assert_lte(editor.get_combined_minimum_size().y, 720.0 - 130.0, "under the logo on a 720 px canvas")
	assert_lte(editor.get_combined_minimum_size().x, 1280.0)
