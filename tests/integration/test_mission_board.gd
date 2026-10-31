extends GutTest
## Missions (spec §21d.1, §21d.3, §25.3): the Mission Board, one panel with big buttons, read aloud like the School:
## MISSIONS (each card: where, the real trip, what the rocket needs, whether it is on the route; CHOOSE), MY ROCKET (the
## rocket science panel: each stage, the numbers, the bar to the planet, green ticks and kind "not yet" lines; LAUNCH
## when it all passes) and PARTS (the Launch Site's shop: every part's picture, what it does, its numbers and its price
## in gold). Mouse and keys (Esc closes) and touch alike.

const OPEN: Array[int] = [16, 17, 18, 19, 20, 21, 22, 23]

var board: MissionBoard
var owned := {}
var gold := 5000
var bought: Array = []
var flown: Array = []
var rocket_cells := {}


func before_each() -> void:
	owned = {}
	gold = 5000
	bought = []
	flown = []
	rocket_cells = _moon_rocket()
	board = MissionBoard.new()
	board.read_rocket = func() -> Dictionary: return rocket_cells
	board.owned = func() -> Variant: return owned
	board.have = func(id: int) -> int: return int(owned.get(id, 0))
	board.gold = func() -> int: return gold
	board.buy = func(id: int, n: int) -> String:
		var cost := RocketParts.price(id) * n
		if cost > gold:
			return "You need more gold!"
		gold -= cost
		owned[id] = int(owned.get(id, 0)) + n
		bought.append([id, n])
		return ""
	board.launch = func(rocket: Dictionary) -> String:
		flown.append(rocket)
		return ""
	board.route = func() -> Array[int]: return [] as Array[int]
	board.available = func() -> Array[int]: return OPEN
	add_child_autofree(board)


## The test rocket of test_rocket_check.gd that flies to the Moon.
func _moon_rocket() -> Dictionary:
	var c := {}
	for x in range(2, 6):
		for z in range(3, 5):
			c[Vector3i(x, 0, z)] = BlockIds.ROCKET_ENGINE
			c[Vector3i(x, 1, z)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 2, 3)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 2, 4)] = BlockIds.FUEL_TANK
	for f: Vector3i in [Vector3i(1, 0, 3), Vector3i(6, 0, 3), Vector3i(3, 0, 2), Vector3i(4, 0, 5)]:
		c[f] = BlockIds.ROCKET_FINS
	c[Vector3i(3, 3, 4)] = BlockIds.STAGE_SEPARATOR
	c[Vector3i(3, 4, 4)] = BlockIds.SPACE_ENGINE
	c[Vector3i(3, 4, 3)] = BlockIds.SPACE_ENGINE
	for y in [5, 6]:
		c[Vector3i(3, y, 3)] = BlockIds.FUEL_TANK
		c[Vector3i(3, y, 4)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 7, 4)] = BlockIds.STAGE_SEPARATOR
	c[Vector3i(3, 8, 4)] = BlockIds.SPACE_ENGINE
	c[Vector3i(3, 9, 4)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 10, 4)] = BlockIds.SERVICE_MODULE
	c[Vector3i(3, 11, 4)] = BlockIds.CREW_CAPSULE
	c[Vector3i(3, 12, 4)] = BlockIds.NOSE_CONE
	for leg: Vector3i in [Vector3i(2, 8, 4), Vector3i(4, 8, 4), Vector3i(3, 8, 5)]:
		c[leg] = BlockIds.LANDING_LEGS
	c[Vector3i(2, 10, 4)] = BlockIds.SOLAR_ARRAY
	return c


func test_it_opens_on_the_missions_in_the_real_order() -> void:
	rocket_cells = {}   # an empty pad (owner #98: with rocket parts on it the board opens on MY ROCKET)
	board.open()
	assert_true(board.visible)
	assert_eq(board.page, MissionBoard.MISSIONS_PAGE)
	var names := board.card_names()
	assert_eq(names, ["Mission to the Moon", "Mission to Mars", "Mission to Europa", "Mission to Io", "Mission to Titan",
		"Mission to Mercury"])
	assert_eq(int(board.mission.world), SpaceRules.MOON, "the first mission not flown yet is chosen")
	assert_string_contains(board.words(), "Mission to the Moon")
	assert_string_contains(board.words(), "about 3 days")
	board.choose(SpaceRules.MARS)
	assert_eq(int(board.mission.world), SpaceRules.MARS)
	assert_eq(board.page, MissionBoard.ROCKET_PAGE, "choosing a mission checks the rocket for it")


func test_only_built_worlds_have_missions_and_the_route_is_marked() -> void:
	board.available = func() -> Array[int]: return [16, 17, 19] as Array[int]
	board.route = func() -> Array[int]: return [16] as Array[int]
	board.open()
	assert_eq(board.card_names(), ["Mission to the Moon", "Mission to Mars"])
	assert_eq(int(board.mission.world), SpaceRules.MARS, "the Moon is on the route: Mars comes next")
	assert_true(board.on_route(SpaceRules.MOON))
	assert_false(board.on_route(SpaceRules.MARS))


func test_the_rocket_science_panel_checks_the_rocket_on_the_pad() -> void:
	owned = RocketParts.count(rocket_cells)
	board.open()
	board.show_page(MissionBoard.ROCKET_PAGE)
	assert_true(board.result.ok, "the test rocket flies to the Moon")
	assert_eq(board.stage_count(), 3)
	assert_true(board.launch_button.visible and not board.launch_button.disabled)
	assert_almost_eq(board.bar.reach, float(board.result.dv), 0.001)
	assert_almost_eq(board.bar.need(), 15.3, 0.001)
	assert_string_contains(board.words(), "Lift-off")
	board.choose(SpaceRules.MARS)
	assert_false(board.result.ok)
	assert_false(board.launch_ready(), "not yet for Mars")
	assert_string_starts_with(board.launch_button.text, "NOT YET", "owner #98: a grey LAUNCH says why")
	assert_gt(board.miss_count(), 0)


## Owner #98: buying in one place: the paid line on MY ROCKET has its own button, and a card asks first.
func test_sandbox_buys_the_missing_parts_then_launches() -> void:
	board.open()
	assert_eq(board.page, MissionBoard.ROCKET_PAGE, "the pad has parts: MY ROCKET")
	assert_false(board.result.ok, "nothing bought yet")
	var cost := RocketParts.cost(RocketParts.count(rocket_cells))
	assert_eq(board.missing_cost(), cost)
	assert_true(board.buy_all_button.visible and board.buy_all_button.is_inside_tree(), "on MY ROCKET, under the paid line")
	assert_eq(board.buy_all_button.text, "BUY THE PARTS FOR THIS ROCKET: %d gold" % cost)
	board.buy_all_button.pressed.emit()
	assert_true(board.confirm_card.visible, "a card asks first")
	assert_string_starts_with(board.confirm_label.text, "Buy %d parts for %d gold?" % [rocket_cells.size(), cost])
	assert_string_contains(board.confirm_label.text, "8 rocket engines")
	assert_eq(gold, 5000, "nothing spent yet")
	board.confirm_yes.pressed.emit()
	assert_false(board.confirm_card.visible)
	assert_eq(gold, 5000 - cost)
	assert_false(board.buy_all_button.visible, "nothing missing now")
	assert_true(board.result.ok)
	assert_string_contains(board.message(), "Every part is paid for!")
	assert_eq(board.press_launch(), "")
	assert_eq(flown.size(), 1)
	assert_eq(flown[0].destination, SpaceRules.MOON)
	assert_eq((flown[0].stages as Array).size(), 3)
	assert_false(board.visible, "the board closes on launch")


func test_a_part_costs_gold_and_says_so_when_there_is_not_enough() -> void:
	gold = 30
	board.open()
	board.show_page(MissionBoard.PARTS_PAGE)
	assert_eq(board.part_cards(), RocketParts.ORDER.size(), "every part is on the shop's shelf")
	assert_eq(board.buy_part(BlockIds.FUEL_TANK), "", "5 gold")
	assert_eq(gold, 25)
	assert_ne(board.buy_part(BlockIds.CREW_CAPSULE), "", "40 gold: not enough")
	assert_eq(board.message(), "You need more gold!")
	assert_string_contains(board.gold_label.text, "25")


func test_survivor_has_no_bought_line() -> void:
	board.owned = func() -> Variant: return null
	board.open()
	board.show_page(MissionBoard.ROCKET_PAGE)
	assert_true(board.result.ok, "the bag paid for every part")
	assert_false(board.buy_all_button.visible)


func test_an_empty_pad_and_a_refused_launch() -> void:
	rocket_cells = {}
	board.open()
	board.show_page(MissionBoard.ROCKET_PAGE)
	assert_true(board.result.empty)
	assert_false(board.launch_ready())
	assert_string_starts_with(board.press_launch(), "Not yet: 1 line to fix. First: Build a rocket")
	rocket_cells = _moon_rocket()
	owned = RocketParts.count(rocket_cells)
	board.launch = func(_r: Dictionary) -> String: return "Space trips work when you play alone."
	board.check()
	assert_eq(board.press_launch(), "Space trips work when you play alone.")
	assert_eq(board.message(), "Space trips work when you play alone.")
	assert_true(board.visible, "it stays open to say why")


func test_esc_and_the_close_button_close_it() -> void:
	board.open()
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	board._unhandled_input(esc)
	assert_false(board.visible, "Esc closes it on a PC")
	board.open()
	board.close_button.pressed.emit()
	assert_false(board.visible)
	board.open()
	assert_true(board.close_if_open(), "Android Back")
	assert_false(board.close_if_open())


func test_the_star_map_button_is_there_when_a_planet_is_on_the_route() -> void:
	var opened := [0]
	rocket_cells = {}   # an empty pad: the board opens on MISSIONS
	board.star_map = func() -> void: opened[0] += 1
	board.open()
	assert_false(board.star_map_button.visible, "nothing reached yet")
	board.route = func() -> Array[int]: return [16] as Array[int]
	board.open()
	assert_true(board.star_map_button.visible)
	board.star_map_button.pressed.emit()
	assert_eq(opened[0], 1)
	assert_false(board.visible, "the Star Map takes over")
