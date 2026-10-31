extends GutTest
## Owner feedback #45b (spec §14.18): the world map (MORE → MAP). A picture page of the places found in this world
## (their picture and name) round the child's arrow and the home marker; a place nobody found is never on it; a tap
## on a place sets the find arrow towards it and closes the map; it fits the emulator's screen and a 16:9 phone.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]

var panel: WorldMapPanel
var entries: Array = []
var chosen: Array = []
var _window_size: Vector2i


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func before_each() -> void:
	entries = []
	chosen = []
	panel = WorldMapPanel.new()
	add_child_autofree(panel)
	panel.entries_source = func() -> Array: return entries
	panel.player_position = func() -> Vector3: return Vector3(0, 30, 0)
	panel.home_position = func() -> Vector3: return Vector3(12, 30, -20)
	panel.point_to = func(label: String, pos: Vector3) -> void: chosen.append([label, pos])


func _three() -> Array:
	return [{"id": "village_1_0", "kind": MeadowsPlaces.VILLAGE, "name": "Maplebrook", "pos": Vector3(300, 40, 20)},
		{"id": "windmill_0_1", "kind": MeadowsPlaces.WINDMILL, "name": "Honeyfield Mill", "pos": Vector3(-90, 35, 180)},
		{"id": "ship_-2_0", "kind": MeadowsPlaces.SHIP, "name": "the Sea Otter", "pos": Vector3(-420, 25, -60)}]


func test_an_empty_map_asks_the_child_to_explore() -> void:
	panel.open()
	assert_true(panel.is_open())
	assert_eq(panel.badges.size(), 0, "nothing found: no place on the map")
	assert_true(panel.empty_label.visible)
	assert_ne(panel.empty_label.text, "")


func test_every_found_place_has_its_picture_and_name() -> void:
	entries = _three()
	panel.open()
	assert_eq(panel.badges.size(), 3)
	assert_false(panel.empty_label.visible)
	var names: Array = []
	for b: Button in panel.badges:
		names.append(b.tooltip_text)
		assert_true(WorldMapPanel.knows_picture(b.get_meta(&"kind")), "a picture for %s" % b.get_meta(&"kind"))
	assert_eq(names, ["Maplebrook", "Honeyfield Mill", "the Sea Otter"])
	for kind: StringName in MeadowsPlaces.KINDS:
		assert_true(WorldMapPanel.knows_picture(kind), String(kind))


## Only what the world found (the director's found_places) is drawn: the map never shows a place by itself.
func test_only_the_places_it_is_given_are_on_the_map() -> void:
	entries = _three().slice(0, 1)
	panel.open()
	assert_eq(panel.badges.size(), 1)
	panel.close()
	entries = _three()
	panel.open()
	assert_eq(panel.badges.size(), 3, "a new find shows next time")


func test_a_tap_on_a_place_sets_the_arrow_and_closes_the_map() -> void:
	entries = _three()
	panel.open()
	watch_signals(panel)
	panel.badges[1].pressed.emit()
	assert_eq(chosen, [["Honeyfield Mill", Vector3(-90, 35, 180)]])
	assert_false(panel.is_open())
	assert_signal_emitted(panel, "closed")


func test_close_and_pause_close_it() -> void:
	panel.open()
	panel.close_button.pressed.emit()
	assert_false(panel.is_open())
	panel.open()
	panel.notification(NOTIFICATION_PAUSED)
	assert_false(panel.is_open())


func test_it_fits_the_screen_and_far_places_stay_on_the_map() -> void:
	entries = _three()
	entries.append({"id": "town_20_0", "kind": MeadowsPlaces.TOWN, "name": "Rosyvale Town", "pos": Vector3(5200, 40, 900)})
	for screen in SCREENS:
		get_window().size = screen
		panel.close()
		panel.open()
		await wait_process_frames(2)
		var view := Rect2(Vector2.ZERO, panel.get_viewport_rect().size)
		var card := panel.card.get_global_rect()
		assert_true(view.encloses(card), "%s: the map is on the screen (%s)" % [screen, card])
		var area := panel.map_area.get_global_rect()
		for b: Button in panel.badges:
			var r := b.get_global_rect()
			assert_true(area.grow(2).encloses(r), "%s: %s on the map (%s in %s)" % [screen, b.tooltip_text, r, area])
			assert_gte(minf(r.size.x, r.size.y), 64.0, "%s: big enough for a thumb" % b.tooltip_text)
		var cb := panel.close_button.get_global_rect()
		assert_true(card.encloses(cb))
		assert_gte(minf(cb.size.x, cb.size.y), 64.0)


func test_the_map_button_has_a_picture() -> void:
	assert_true(HudIcons.knows(&"map"))
	var b := WorldMapPanel.more_button()
	autofree(b)
	assert_eq(b.symbol, &"map")
	assert_eq(b.text, "MAP")
