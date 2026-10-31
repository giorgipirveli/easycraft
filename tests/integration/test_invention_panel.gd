extends GutTest
## Owner #78 (spec §21e): the Inventions book, how people learned to fly, in history's order: a tab for each invention
## (its picture and its year), a page with its real story, its science, what it opens (read aloud), and in Survivor
## what it is made of at a Workbench (have / need), its price (or free with its School unit), MAKE IT for the next one,
## TRY IT once invented and FLY WITH IT for a flying machine. In the Sandbox everything is open: TRY IT and FLY WITH IT
## for every one, and FREE FLYING back to the classic flying. Esc and Back close it.

var panel: InventionsPanel
var data: InventionData
var is_survivor := true
var stock := {}
var coins := 100
var made: Array = []
var tried: Array = []
var flown: Array = []
var craft := FlightCrafts.Craft.NONE
var workbench := true


func before_each() -> void:
	data = InventionData.new()
	is_survivor = true
	stock = {}
	coins = 100
	made = []
	tried = []
	flown = []
	craft = FlightCrafts.Craft.NONE
	workbench = true
	panel = InventionsPanel.new()
	panel.data = func() -> InventionData: return data
	panel.survivor = func() -> bool: return is_survivor
	panel.have = func(m: StringName) -> int: return int(stock.get(m, 0))
	panel.gold = func() -> int: return coins
	panel.mastered = func(_id: StringName) -> bool: return false
	panel.near_workbench = func() -> bool: return workbench
	panel.chosen = func() -> int: return craft
	panel.make_pressed.connect(func(id: StringName) -> void: made.append(id))
	panel.try_pressed.connect(func(id: StringName) -> void: tried.append(id))
	panel.fly_pressed.connect(func(id: StringName) -> void: flown.append(id))
	add_child_autofree(panel)


func test_it_opens_on_the_next_invention_with_a_tab_for_each_in_order() -> void:
	panel.open()
	assert_true(panel.is_open())
	assert_eq(panel.shown, InventionLine.KITE, "the first to invent")
	assert_eq(panel.tab_ids(), InventionLine.ORDER)
	assert_string_contains(panel.tab_text(InventionLine.BALLOON), "1783")
	assert_string_contains(panel.tab_text(InventionLine.PLANE), "1903")
	panel.close()
	data.add(InventionLine.KITE)
	data.add(InventionLine.BALLOON)
	panel.open()
	assert_eq(panel.shown, InventionLine.GLIDER, "the next one")
	panel.open(InventionLine.ROCKET)
	assert_eq(panel.shown, InventionLine.ROCKET, "or the one asked for")


func test_each_page_tells_its_story_and_its_science_aloud() -> void:
	panel.open(InventionLine.PLANE)
	var w := panel.words()
	assert_string_contains(w, "The Plane")
	assert_string_contains(w, "12 seconds")
	assert_string_contains(w, "push air backwards")
	assert_string_contains(w, "10 gold a minute", "what it opens")
	panel.show_invention(InventionLine.KITE)
	assert_string_contains(panel.words(), "power lines", "the kite's safety line")


func test_survivor_shows_what_it_is_made_of_and_makes_the_next() -> void:
	stock = {&"sticks": 2, &"cloth": 3}
	panel.open()
	assert_eq(panel.need_lines(), ["Sticks 2/4", "Cloth 3/3"] as Array[String])
	assert_string_contains(panel.price_text(), "10 gold")
	assert_string_contains(panel.price_text(), "Pushes, pulls and friction")
	assert_true(panel.make_button.visible)
	panel.make_button.pressed.emit()
	assert_eq(made, [InventionLine.KITE], "the director makes it (and says why not)")
	assert_false(panel.try_button.visible, "TRY IT once it is invented")
	panel.show_invention(InventionLine.JET)
	assert_false(panel.make_button.visible, "not the next one yet")
	assert_eq(panel.status(InventionLine.JET), &"later")
	assert_string_contains(panel.message(), "The Kite", "what comes first")


func test_an_invention_made_can_be_tried_and_flown() -> void:
	data.add(InventionLine.KITE)
	data.add(InventionLine.BALLOON)
	panel.open(InventionLine.BALLOON)
	assert_eq(panel.status(InventionLine.BALLOON), &"invented")
	assert_false(panel.make_button.visible)
	assert_true(panel.try_button.visible)
	assert_true(panel.fly_button.visible, "a flying machine")
	panel.try_button.pressed.emit()
	panel.fly_button.pressed.emit()
	assert_eq(tried, [InventionLine.BALLOON])
	assert_eq(flown, [InventionLine.BALLOON])
	assert_false(panel.free_button.visible, "Survivor has no free flying")
	panel.show_invention(InventionLine.KITE)
	assert_true(panel.fly_button.visible, "the kite's lift is picked the same way")


func test_the_sandbox_opens_everything_to_try() -> void:
	is_survivor = false
	panel.open()
	assert_eq(panel.shown, InventionLine.KITE)
	for id in InventionLine.ORDER:
		panel.show_invention(id)
		assert_eq(panel.status(id), &"open")
		assert_false(panel.make_button.visible, "%s: nothing to make in the Sandbox" % id)
		assert_true(panel.try_button.visible, "%s: TRY IT" % id)
		assert_eq(panel.fly_button.visible, FlightCrafts.of_invention(id) != FlightCrafts.Craft.NONE, "%s: FLY WITH IT" % id)
	assert_false(panel.free_button.visible, "the classic flying is already on")
	craft = FlightCrafts.Craft.JET
	panel.refresh()
	assert_true(panel.free_button.visible)
	panel.free_button.pressed.emit()
	assert_eq(flown, [&""], "back to the classic flying")


func test_the_rocket_s_try_is_a_bottle_rocket_in_the_book() -> void:
	is_survivor = false
	panel.open(InventionLine.ROCKET)
	panel.open_bottle()
	assert_true(panel.bottle_open())
	assert_true(panel.bottle.pump())
	assert_gt(panel.bottle.fire(), 0.0)
	panel.bottle.back_pressed.emit()
	assert_false(panel.bottle_open())
	assert_eq(panel.shown, InventionLine.ROCKET)


func test_esc_and_back_close_it() -> void:
	panel.open()
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	panel._unhandled_input(esc)
	assert_false(panel.is_open())
	panel.open()
	assert_true(panel.close_if_open())
	assert_false(panel.close_if_open())


func test_it_fits_a_phone_screen() -> void:
	panel.open(InventionLine.ROCKET)
	await wait_frames(2)
	var need := panel.page_panel.get_combined_minimum_size() * panel.page_panel.scale
	assert_lte(need.x, 1280.0)
	assert_lte(need.y, 720.0)
