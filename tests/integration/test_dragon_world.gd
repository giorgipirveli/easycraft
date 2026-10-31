extends GutTest
## Owner feedback #39: a world of universe 5 is the Dragon Realm. WorldService.setup(..., 5) takes the realm's terrain
## rules and generator (UniverseRegistry: world.descriptor()), the ground it generates is the realm's (sky grass on the
## home island, the void beside it), and --universe=5 picks it for a Survivor world. With five universes unlocked the
## menu's Survivor hub and Monster Wave rows show five picture cards that fit the screen.

const FAKE_ARGS := ["--survivor", "--new-world", "--universe=5"]

var _unlocked := 1


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


func test_universe_5_is_the_dragon_realm() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 5)
	add_child_autofree(w)
	assert_eq(w.universe, 5)
	assert_eq(w.descriptor().get("name"), &"dragon")
	assert_true(w.generator_shape() is DragonShape)
	assert_eq(w.surface_height(10, 20), DragonShape.new(77).height_at(10, 20))
	assert_eq(w.spawn_column(), DragonShape.new(77).spawn_column())
	assert_true(DragonRules.world_has_void(w.descriptor(), w.generator_shape() is ArenaShape))


func test_the_arena_of_universe_5_is_flat_and_has_no_void() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 5, true)
	add_child_autofree(w)
	assert_true(w.generator_shape() is ArenaShape)
	assert_false(DragonRules.world_has_void(w.descriptor(), w.generator_shape() is ArenaShape), "no void in the arena")


func test_the_realm_generates_its_own_ground() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 5)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var below := Vector3i(spawn.x, h - 1, spawn.y)
	var deeper := below + Vector3i(0, -2, 0)
	await wait_until(func() -> bool: return w.is_editable(below) and w.is_editable(deeper), 15.0, "terrain loads")
	assert_eq(w.get_block(below), BlockIds.SKY_GRASS, "sky grass under the spawn")
	var gen := DragonGenerator.new()
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "the realm's generator's block")
	assert_eq(w.get_block(below + Vector3i(0, 2, 0)), BlockIds.AIR)
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a player stands on the home island")


func test_the_developer_argument() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", FAKE_ARGS), 5)


func _cards(menu: Node) -> Array[UniverseCard]:
	var out: Array[UniverseCard] = []
	for b in menu.find_children("*", "UniverseCard", true, false):
		if (b as Control).is_visible_in_tree() and not (b as Node).is_queued_for_deletion():
			out.append(b)
	return out


## Five cards of UniverseCard.SIZE side by side still fit the 1280 px wide screen, none over another.
func test_five_universe_cards_fit_the_screen() -> void:
	Profile.data.universe_unlocked = 5
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	for show in ["_show_hub", "_show_wave"]:
		menu.call(show)
		await wait_frames(3)
		var cards := _cards(menu)
		assert_eq(cards.size(), 5, "%s: every universe" % show)
		var width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
		var last := -INF
		for c in cards:
			var r := c.get_global_rect()
			assert_gte(r.position.x, 0.0, "%s: card %d on the screen" % [show, c.universe])
			assert_lte(r.end.x, width, "%s: card %d on the screen (%s)" % [show, c.universe, r])
			assert_gte(r.position.x, last, "%s: no card over another" % show)
			last = r.end.x
		assert_eq(cards[4].name_label.text, "Dragon Realm")
