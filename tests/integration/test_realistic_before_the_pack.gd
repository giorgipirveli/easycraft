extends GutTest
## M7 (owner 2026-09-28: "make sure it loads fast, load any unnessesary data later"): in a browser the REALISTIC style's
## pictures come in the realistic pack a little after the start (WebContent, RealisticPack). A child who chooses
## REALISTIC before it is in keeps the pixel pictures (never a missing texture), the choice stays saved, the settings
## say the pictures are on their way, and the world turns realistic by itself when the pack lands (no remesh: the
## shared materials are restyled). A pack that lands while BLOCKY is chosen changes nothing.
## RealisticPack.exists_check pretends the pictures are missing.

var _style := ""


func before_each() -> void:
	_style = str(Profile.data.settings.style)


func after_each() -> void:
	RealisticPack.exists_check = Callable()
	BlockLibrary.set_style("blocky")
	Profile.data.settings.style = _style


## The first download: every realistic picture is missing.
func _first_download() -> void:
	RealisticPack.exists_check = func(path: String) -> bool: return not path in RealisticPack.files()


## The realistic pack has landed.
func _pack_lands() -> void:
	RealisticPack.exists_check = Callable()
	RealisticPack.on_pack_loaded(RealisticPack.PACK)


func _opaque() -> StandardMaterial3D:
	return BlockLibrary.page_material(0, &"opaque") as StandardMaterial3D


func _world() -> WorldService:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 42)
	add_child_autofree(w)
	return w


# --- the blocks ------------------------------------------------------------------------------------------------------

func test_before_the_pack_realistic_keeps_the_pixel_pictures() -> void:
	_first_download()
	BlockLibrary.set_style("realistic")
	assert_eq(BlockLibrary.style, "blocky", "the style the blocks show")
	assert_eq(_opaque().albedo_texture, BlockLibrary.ATLAS, "the pixel atlas, never a missing picture")
	assert_false(_opaque().normal_enabled)
	var desert := BlockLibrary.page_material(DesertBlocks.PAGE, &"opaque") as StandardMaterial3D
	assert_eq(desert.albedo_texture.resource_path, DesertBlocks.FILES[0], "every page keeps its pixel page")


func test_with_the_pictures_here_realistic_is_realistic() -> void:
	BlockLibrary.set_style("realistic")
	assert_eq(BlockLibrary.style, "realistic")
	assert_eq(_opaque().albedo_texture.resource_path, BlockLibrary.REALISTIC_ALBEDO)


func test_a_page_whose_pictures_are_not_in_keeps_its_pixel_page() -> void:
	BlockLibrary.set_style("realistic")
	var page := 30   # no game page: a page registered later whose realistic twin the pack lacks
	BlockLibrary.register_page(page, [DesertBlocks.FILES[0], "res://data/blocks/pages/none_albedo.png",
		"res://data/blocks/pages/none_normal.png"], {})
	var m := BlockLibrary.page_material(page, &"opaque") as StandardMaterial3D
	BlockLibrary.unregister_page(page)
	assert_eq(m.albedo_texture.resource_path, DesertBlocks.FILES[0], "its pixel page, not a crash")
	assert_false(m.normal_enabled)


# --- the world -------------------------------------------------------------------------------------------------------

func test_before_the_pack_a_realistic_world_shows_the_blocky_sky() -> void:
	_first_download()
	var w := _world()
	var painted := w.environment().sky.sky_material
	w.apply_style("realistic")
	assert_same(w.environment().sky.sky_material, painted, "the painted sky: the HDRI is not here")
	assert_false(w.environment().glow_enabled)


func test_the_world_turns_realistic_by_itself_when_the_pack_lands() -> void:
	_first_download()
	var w := _world()
	w.apply_style("realistic")
	_pack_lands()
	assert_eq(BlockLibrary.style, "realistic")
	assert_eq(_opaque().albedo_texture.resource_path, BlockLibrary.REALISTIC_ALBEDO, "the same shared materials")
	assert_true(w.environment().sky.sky_material is PanoramaSkyMaterial, "the photo sky")
	assert_true(w.environment().glow_enabled)


func test_a_pack_that_lands_while_blocky_changes_nothing() -> void:
	_first_download()
	var w := _world()
	w.apply_style("blocky")
	var painted := w.environment().sky.sky_material
	_pack_lands()
	assert_eq(BlockLibrary.style, "blocky")
	assert_eq(_opaque().albedo_texture, BlockLibrary.ATLAS)
	assert_same(w.environment().sky.sky_material, painted)


func test_another_pack_landing_changes_nothing() -> void:
	_first_download()
	var w := _world()
	w.apply_style("realistic")
	RealisticPack.exists_check = Callable()
	RealisticPack.on_pack_loaded(Music.PACK)
	assert_eq(BlockLibrary.style, "blocky", "only the realistic pack's arrival restyles")


# --- the menu --------------------------------------------------------------------------------------------------------

func _menu() -> Node:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	return menu


## REALISTIC picked in the menu's SETTINGS before the pack: the menu's world keeps the pixel pictures, then turns
## realistic by itself when the pack lands (the child waits in the menu).
func test_in_the_menu_realistic_picked_before_the_pack_turns_on_when_it_lands() -> void:
	_first_download()
	Profile.data.settings.style = "blocky"
	var menu := _menu()
	await wait_frames(2)
	Profile.data.settings.style = "realistic"   # SETTINGS, REALISTIC
	Game.apply_settings()
	assert_eq(BlockLibrary.style, "blocky", "the pixel pictures meanwhile")
	_pack_lands()
	assert_eq(BlockLibrary.style, "realistic", "the menu's world turns realistic by itself")
	var w: WorldService = menu.get("_world")
	assert_true(w.environment().sky.sky_material is PanoramaSkyMaterial, "the photo sky")
	Profile.data.settings.style = _style
	Game.apply_settings()


## The menu's world shows the style picked in its SETTINGS at once (it kept its first style until the next menu).
func test_the_menu_shows_a_style_picked_in_its_settings() -> void:
	Profile.data.settings.style = "blocky"
	var menu := _menu()
	await wait_frames(2)
	Profile.data.settings.style = "realistic"
	Game.apply_settings()
	assert_eq(BlockLibrary.style, "realistic")
	assert_true((menu.get("_world") as WorldService).environment().sky.sky_material is PanoramaSkyMaterial)
	Profile.data.settings.style = "blocky"
	Game.apply_settings()
	assert_eq(BlockLibrary.style, "blocky")
	Profile.data.settings.style = _style
	Game.apply_settings()


# --- the settings ----------------------------------------------------------------------------------------------------

func _panel() -> SettingsPanel:
	var box := PanelContainer.new()        # as the menus show it: themed, in a panel
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass       # never writes the shared profile
	box.add_child(s)
	add_child_autofree(box)
	return s


func _note(s: SettingsPanel) -> Label:
	return s.find_child("RealisticNote", true, false) as Label


func _press(s: SettingsPanel, word: String) -> void:
	for b: Button in s.find_children("*", "Button", true, false):
		if b.text == word:
			b.pressed.emit()
			return
	fail_test("no %s button" % word)


func test_the_settings_say_the_realistic_pictures_are_on_their_way() -> void:
	_first_download()
	Profile.data.settings.style = "realistic"
	var s := _panel()
	var note := _note(s)
	assert_not_null(note, "a small line beside the style")
	if note == null:
		return
	assert_true(note.is_visible_in_tree())
	assert_eq(note.text, SettingsPanel.REALISTIC_COMING)
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	assert_lte(size.x, 1280.0, "still fits a 1280 x 720 screen: %s" % size)
	assert_lte(size.y, 720.0, "still fits a 1280 x 720 screen: %s" % size)
	_pack_lands()
	assert_false(note.visible, "gone once the pictures are in")


func test_choosing_realistic_before_the_pack_says_so_and_keeps_the_choice() -> void:
	_first_download()
	Profile.data.settings.style = "blocky"
	var s := _panel()
	assert_true(_note(s) == null or not _note(s).visible, "nothing to say while BLOCKY is chosen")
	_press(s, "REALISTIC")
	assert_eq(Profile.data.settings.style, "realistic", "the choice is kept")
	assert_eq(BlockLibrary.style, "blocky", "the pixel pictures meanwhile")
	assert_true(_note(s) != null and _note(s).is_visible_in_tree(), "the pictures are on their way")
	_press(s, "BLOCKY")
	assert_false(_note(s).visible)


func test_the_settings_say_nothing_when_the_pictures_are_here() -> void:
	Profile.data.settings.style = "realistic"
	var s := _panel()
	assert_true(_note(s) == null or not _note(s).visible)


## Cosmos (spec §21b.2): a world with its own sky (Mars: butterscotch by day, a blue glow at sunset) keeps its painted
## sky in the realistic style too: the photo sky is Earth's blue with white clouds.
func test_a_world_without_the_photo_sky_keeps_its_painted_sky_when_realistic() -> void:
	var w := _world()
	var painted := w.environment().sky.sky_material
	w.photo_sky = false
	w.apply_style("realistic")
	assert_same(w.environment().sky.sky_material, painted, "its own painted sky")
	assert_true(w.environment().glow_enabled, "the rest of the realistic look stays")
	assert_false(UniverseRegistry.photo_sky(SpaceRules.MARS), "Mars has its own sky")
	assert_true(UniverseRegistry.photo_sky(1), "Green Meadows: the photo sky")

