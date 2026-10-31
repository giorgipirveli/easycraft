extends GutTest
## Spec §23.1: the Science Lab's links. A School unit an experiment lists shows TRY IT IN THE LAB on its page, which
## opens the Lab on that experiment inside the School (its BACK comes back to the unit; its LEARN MORE opens a unit's
## page); a unit with no experiment has no such button. The book has a LAB tab: the Lab Book. In a world, a tap on a lab
## bench within reach opens the Lab (LabPanel over the HUD; BACK or Android Back closes it), whatever is in the hand; a
## hold still breaks it.

const BENCH := Vector3i(2, 10, 0)
const ME_AT := Vector3(0.5, 10.0, 4.5)

var profile: ProfileData
var school: SchoolScreen


func before_each() -> void:
	Curriculum.clear_cache()
	LabExperiments.clear_cache()
	profile = ProfileData.new()
	profile.school.grade = 3


func after_all() -> void:
	Audio.stop_all()


func _school() -> SchoolScreen:
	school = SchoolScreen.new()
	school.profile = profile
	school.save_profile = func() -> void: pass
	add_child_autofree(school)
	await wait_process_frames(2)
	return school


func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


# --- The School -----------------------------------------------------------------------------------------------------

func test_a_unit_with_an_experiment_says_try_it_in_the_lab() -> void:
	await _school()
	school.show_unit("g3.science.magnets")
	await wait_process_frames(1)
	var b := _find_button(school, "TRY IT IN THE LAB")
	assert_not_null(b)
	var size := school.get_combined_minimum_size()
	assert_lte(size.y, SchoolUi.FRAME.y, "the unit page still fits: %s" % size)
	assert_lte(size.x, SchoolUi.FRAME.x)
	school.show_unit("g3.maths.place_value" if not Curriculum.unit("g3.maths.place_value").is_empty() else
		str(Curriculum.units(3, "maths")[0].id))
	await wait_process_frames(1)
	assert_null(_find_button(school, "TRY IT IN THE LAB"), "no experiment, no button")
	# a unit not written yet ("Coming soon") still links to its experiment (any the Lab lists: they get written in turn)
	var coming := ""
	for e_id in LabExperiments.ids():
		for u: Variant in LabExperiments.experiment(e_id).get("units", []):
			if coming == "" and not Curriculum.has_content(str(u)) and not Curriculum.unit(str(u)).is_empty():
				coming = str(u)
	if coming == "":
		pass_test("every unit the Lab lists is written")
		return
	school.show_unit(coming)
	await wait_process_frames(1)
	assert_not_null(_find_button(school, "TRY IT IN THE LAB"), "%s (Coming soon) links to its experiment" % coming)


## Grade 4's written circuits, heat and states of matter units (owner #73) show the button too, and their pages (with
## three goals, LESSON, PRACTICE and TRY IT IN THE LAB) still fit the School's frame.
func test_every_written_unit_with_an_experiment_fits_its_page() -> void:
	await _school()
	var checked := 0
	for e_id in LabExperiments.ids():
		for u: Variant in LabExperiments.experiment(e_id).get("units", []):
			if not Curriculum.has_content(str(u)):
				continue
			checked += 1
			school.show_unit(str(u))
			await wait_process_frames(1)
			assert_not_null(_find_button(school, "TRY IT IN THE LAB"), str(u))
			var size := school.get_combined_minimum_size()
			assert_lte(size.y, SchoolUi.FRAME.y, "%s: the unit page fits: %s" % [u, size])
			assert_lte(size.x, SchoolUi.FRAME.x, str(u))
	assert_gte(checked, 5, "g3 magnets and plants, g4 circuits, heat and states of matter at least")


func test_the_lab_opens_inside_the_school_and_comes_back() -> void:
	await _school()
	school.show_unit("g3.science.magnets")
	_find_button(school, "TRY IT IN THE LAB").pressed.emit()
	await wait_process_frames(1)
	assert_eq(school.page, SchoolScreen.LAB)
	var lab := school.lab
	assert_not_null(lab)
	assert_eq(lab.page, LabScreen.PREDICT)
	assert_eq(lab.experiment_id, "magnets")
	var size := school.get_combined_minimum_size()
	assert_lte(size.y, SchoolUi.FRAME.y, "the Lab fits the School's frame: %s" % size)
	_find_button(lab, "BACK").pressed.emit()
	await wait_process_frames(1)
	assert_eq(school.page, SchoolScreen.UNIT, "BACK: the unit again")
	assert_eq(school.unit_id, "g3.science.magnets")
	# LEARN MORE from the Lab opens the unit of the child's grade in the School itself
	school.show_lab("magnets")
	school.lab.learn_more.call("g3.science.magnets")
	await wait_process_frames(1)
	assert_eq(school.page, SchoolScreen.UNIT)


# --- The book's LAB tab ---------------------------------------------------------------------------------------------

func test_the_book_has_a_lab_tab_with_the_lab_book() -> void:
	var before := Profile.data.lab
	Profile.data.lab = LabData.new()
	Profile.data.lab.finish("circuit")
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	var book := hud.secret_book
	book.open()
	assert_true(SecretBook.TABS.has(SecretBook.LAB_TAB))
	(book.tab_buttons[SecretBook.LAB_TAB] as Button).pressed.emit()
	assert_eq(book.tab, SecretBook.LAB_TAB)
	assert_true(book.lab_page.is_visible_in_tree())
	var c := LabExperiments.ids().find("circuit")
	assert_true(book.lab_page.tile_star(c), "the Lab Book's star")
	var need := book.page_panel.get_combined_minimum_size()
	assert_lte(need.y, 700.0, "the LAB tab fits the 720 px screen: %d" % need.y)
	assert_lte(need.x, 1280.0)
	book.lab_page.open_card("circuit")
	need = book.page_panel.get_combined_minimum_size()
	assert_lte(need.y, 700.0, "a Lab Book card: %d" % need.y)
	Profile.data.lab = before


# --- The bench in a world -------------------------------------------------------------------------------------------

## Stands in for the terrain: a dictionary of cells, all loaded.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


func _player() -> Array:
	var world := EditWorld.new()
	add_child_autofree(world)
	world.cells[BENCH] = BlockIds.LAB_BENCH
	Session.register_world(world)
	var me: Player = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	var interactor: BlockInteractor = me.get_node("BlockInteractor")
	me.viewer.free()
	me.rig.process_mode = Node.PROCESS_MODE_DISABLED     # the test aims the camera
	me.camera().look_at_from_position(me.eye_position(), Vector3(BENCH) + Vector3(0.5, 0.5, 0.5))
	return [world, interactor, interactor.get_viewport().get_visible_rect().size * 0.5]


func test_a_tap_on_a_lab_bench_opens_the_lab_whatever_is_in_the_hand() -> void:
	var mode := Game.mode
	Game.mode = ModeRules.SANDBOX
	var got := _player()
	var world: EditWorld = got[0]
	var interactor: BlockInteractor = got[1]
	var center: Vector2 = got[2]
	var taps: Array[Vector3i] = []
	interactor.lab_bench_tapped.connect(func(cell: Vector3i) -> void: taps.append(cell))
	for item in [BlockIds.PLANKS, ItemIds.SWORD, ItemIds.WAND]:
		interactor.hotbar[0] = item
		interactor.select_slot(0)
		assert_true(interactor.place_at_screen(center), ItemIds.display_name(item))
	assert_eq(taps, [BENCH, BENCH, BENCH] as Array[Vector3i])
	assert_eq(world.cells.values().count(BlockIds.PLANKS), 0, "no plank was placed against it")
	assert_true(interactor.break_at_screen(center), "a hold still breaks it")
	assert_eq(world.get_block(BENCH), BlockIds.AIR)
	Game.mode = mode
	Session.register_world(null)
	Session.survivor_reset()


func test_the_lab_panel_opens_over_the_world_and_closes() -> void:
	var panel := LabPanel.new()
	add_child_autofree(panel)
	panel.screen_profile = profile
	assert_false(panel.visible)
	panel.open()
	await wait_process_frames(1)
	assert_true(panel.visible)
	assert_eq(panel.screen.page, LabScreen.LIST)
	var size := panel.screen.get_combined_minimum_size()
	assert_lte(size.y, SchoolUi.FRAME.y)
	panel.screen.closed.emit()
	assert_false(panel.visible, "the Lab's BACK closes it")
	panel.open()
	assert_true(panel.close_if_open(), "Android Back closes it first")
	assert_false(panel.visible)
	assert_false(panel.close_if_open())


func test_survivor_supplies_are_taken_from_the_bag() -> void:
	var inv := Inventory.new()
	var e := LabExperiments.experiment("float_sink")
	assert_string_contains(LabSupplies.take(inv, e, false), "1 Planks and 1 Stone", "an empty bag: what it needs")
	inv.add(BlockIds.PLANKS, 2)
	inv.add(BlockIds.STONE, 1)
	assert_eq(LabSupplies.take(inv, e, false), "", "taken")
	assert_eq(inv.count(BlockIds.PLANKS), 1)
	assert_eq(inv.count(BlockIds.STONE), 0)
	assert_eq(LabSupplies.take(Inventory.new(), e, true), "", "the Sandbox's bench has endless supplies")
