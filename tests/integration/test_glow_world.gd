extends GutTest
## Universe 6, the Glow Caves: a world of universe 6 is the caves. WorldService.setup(..., 6) takes the caves' terrain
## rules and generator (UniverseRegistry), the ground it generates is the caves' (the home hall's floor, its ceiling,
## the meadow on the roof), the caves' mood is the world's (WorldService.cave_mood; the arena has none), the open
## sky's ground is the roof (sky_height: every cavern is underground), and --universe=6 picks it. With six universes
## unlocked the menu's Survivor hub and Monster Wave rows show six picture cards that fit the screen.

const FAKE_ARGS := ["--survivor", "--new-world", "--universe=6"]

var _unlocked := 1


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


func test_universe_6_is_the_glow_caves() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 6)
	add_child_autofree(w)
	assert_eq(w.universe, 6)
	assert_eq(w.descriptor().get("name"), &"glow")
	assert_true(w.generator_shape() is GlowShape)
	var shape := GlowShape.new(77)
	assert_eq(w.surface_height(10, 20), shape.height_at(10, 20), "the ground is the cavern floor")
	assert_eq(w.sky_height(10, 20), shape.roof_at(10, 20), "the open sky's ground is the roof")
	assert_eq(w.spawn_column(), shape.spawn_column())
	assert_false(w.cave_mood.is_empty(), "the caves' soft blue-violet dark")
	assert_true(w.ambience_base.has("ambient_color"))


func test_the_arena_of_universe_6_has_no_cave_mood() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 6, true)
	add_child_autofree(w)
	assert_true(w.generator_shape() is ArenaShape)
	assert_true(w.cave_mood.is_empty(), "Monster Wave's arena is open ground")
	assert_eq(w.sky_height(3, 4), w.surface_height(3, 4))


func test_the_caves_generate_their_own_ground() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 6)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var c := GlowShape.new(77).column(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var below := Vector3i(spawn.x, h - 1, spawn.y)
	var ceiling := Vector3i(spawn.x, c.y, spawn.y)
	await wait_until(func() -> bool: return w.is_editable(below) and w.is_editable(ceiling), 15.0, "terrain loads")
	var gen := GlowGenerator.new()
	gen.world_seed = 77
	assert_eq(w.get_block(below), gen.reference_block(below.x, below.y, below.z), "the caves' floor")
	assert_has([BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.FLOWSTONE], w.get_block(below), "the home hall's floor")
	assert_eq(w.get_block(Vector3i(spawn.x, h + 2, spawn.y)), BlockIds.AIR, "room over the spawn")
	assert_true(BlockIds.is_solid(w.get_block(ceiling)), "a ceiling over the home hall")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a player stands on the cavern floor")


func test_the_developer_argument() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", FAKE_ARGS), 6)


func _cards(menu: Node) -> Array[UniverseCard]:
	var out: Array[UniverseCard] = []
	for b in menu.find_children("*", "UniverseCard", true, false):
		if (b as Control).is_visible_in_tree() and not (b as Node).is_queued_for_deletion():
			out.append(b)
	return out


## Six cards side by side still fit the 1280 px wide screen, none over another.
func test_six_universe_cards_fit_the_screen() -> void:
	Profile.data.universe_unlocked = 6
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	for show in ["_show_hub", "_show_wave"]:
		menu.call(show)
		await wait_frames(3)
		var cards := _cards(menu)
		assert_eq(cards.size(), 6, "%s: every universe" % show)
		var width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
		var last := -INF
		for c in cards:
			var r := c.get_global_rect()
			assert_gte(r.position.x, 0.0, "%s: card %d on the screen" % [show, c.universe])
			assert_lte(r.end.x, width, "%s: card %d on the screen (%s)" % [show, c.universe, r])
			assert_gte(r.position.x, last, "%s: no card over another" % show)
			last = r.end.x
		assert_eq(cards[5].name_label.text, "Glow Caves")
