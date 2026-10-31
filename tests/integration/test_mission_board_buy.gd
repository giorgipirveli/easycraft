extends GutTest
## Owner #98 (the rocket easier to build and to buy): the Mission Board's MY ROCKET has Mission Control's plan with BUILD
## IT FOR ME, buys in one place (BUY THE PARTS FOR THIS ROCKET, Survivor's BUY THE MISSING PARTS for the plan) after a
## card asks, says exactly how much gold is still needed, opens on MY ROCKET when the pad has parts, and its grey LAUNCH
## says why. The bugs: a friend's bulk buy that never paid for the owner's rocket (4), every BUY scrolling to the top
## (5), a stale bulk price charged with no confirmation (6).

const OPEN: Array[int] = [16, 17, 18, 19, 20, 21, 22, 23]

var board: MissionBoard
var owned: Variant = {}
var bag := {}
var gold := 5000
var bought: Array = []
var built: Array = []
var rocket_cells := {}
var guest := false
var crew := 1


func before_each() -> void:
	owned = {}
	bag = {}
	gold = 5000
	bought = []
	built = []
	rocket_cells = {}
	guest = false
	crew = 1
	board = MissionBoard.new()
	board.read_rocket = func() -> Dictionary: return rocket_cells
	board.owned = func() -> Variant: return owned
	board.have = func(id: int) -> int: return int(bag.get(id, 0)) if owned == null else int((owned as Dictionary).get(id, 0))
	board.gold = func() -> int: return gold
	board.buy = func(id: int, n: int) -> String:
		var cost := RocketParts.price(id) * n
		if cost > gold:
			return "You need more gold!"
		gold -= cost
		if owned == null:
			bag[id] = int(bag.get(id, 0)) + n
		else:
			owned[id] = int(owned.get(id, 0)) + n
		bought.append([id, n])
		return ""
	board.launch = func(_r: Dictionary) -> String: return ""
	board.route = func() -> Array[int]: return [] as Array[int]
	board.available = func() -> Array[int]: return OPEN
	board.build = func(world: int, n: int) -> String:
		built.append([world, n])
		return ""
	board.crew_here = func() -> int: return crew
	board.is_guest = func() -> bool: return guest
	add_child_autofree(board)


func _moon() -> Dictionary:
	return MissionRules.for_world(SpaceRules.MOON)


func test_it_opens_on_my_rocket_when_the_pad_has_parts() -> void:
	board.open()
	assert_eq(board.page, MissionBoard.MISSIONS_PAGE, "an empty pad: the missions")
	board.close()
	rocket_cells = {Vector3i(4, 0, 4): BlockIds.ROCKET_ENGINE}
	board.open()
	assert_eq(board.page, MissionBoard.ROCKET_PAGE, "a rocket on the pad: MY ROCKET at once")
	board.close()
	rocket_cells = {Vector3i(4, 0, 4): BlockIds.STONE}
	board.open()
	assert_eq(board.page, MissionBoard.MISSIONS_PAGE, "a child's other blocks are not a rocket")


func test_the_mission_card_says_the_plan_s_size_and_price() -> void:
	board.open()
	var words := _texts(board)
	assert_has(words, RocketPlan.card_words(_moon(), 1), "Mission Control's plan: n parts, n gold.")
	assert_string_contains(RocketPlan.card_words(_moon(), 1), "%d parts, %d gold" % [RocketPlan.size(_moon(), 1),
		RocketPlan.gold(_moon(), 1)])
	crew = 2
	board.show_page(MissionBoard.MISSIONS_PAGE)
	assert_has(_texts(board), RocketPlan.card_words(_moon(), 2), "the plan seats the friends here too")


## BUILD IT FOR ME sits under the empty-pad line; pressing it asks Mission Control (the sandbox's hook) for the
## chosen mission and the crew here, and the board closes so the child watches the rocket grow.
func test_build_it_for_me_on_the_empty_pad() -> void:
	board.open()
	board.choose(SpaceRules.MOON)
	assert_true(board.result.empty)
	assert_true(board.build_button.visible and board.build_button.is_inside_tree())
	assert_eq(board.build_button.text, "BUILD IT FOR ME")
	crew = 3
	board.show_page(MissionBoard.ROCKET_PAGE)
	board.build_button.pressed.emit()
	assert_eq(built, [[SpaceRules.MOON, 3]], "the Moon, for a crew of 3")
	assert_false(board.visible, "the board closes: watch the pad")


func test_build_it_for_me_says_why_not() -> void:
	board.build = func(_w: int, _n: int) -> String: return "The pad is still being made: wait a moment!"
	board.open()
	board.choose(SpaceRules.MOON)
	assert_eq(board.press_build(), "The pad is still being made: wait a moment!")
	assert_true(board.visible, "it stays open to say why")
	assert_eq(board.message(), "The pad is still being made: wait a moment!")
	guest = true
	assert_eq(board.press_build(), MissionRules.message(MissionRules.GUEST), "a friend's pad: LAUNCH's words")
	guest = false
	board.gate = func() -> String: return "Invent the rocket first!"
	assert_eq(board.press_build(), "Invent the rocket first!", "Survivor's invention first, like LAUNCH")
	board.gate = func() -> String: return ""
	crew = 4
	board.choose(SpaceRules.MERCURY)
	assert_false(board.build_button.visible, "no plan for 4 astronauts to Mercury")
	assert_string_contains(board.press_build(), "no plan", "it says so plainly")
	assert_has(_texts(board), RocketPlan.no_plan_words(MissionRules.for_world(SpaceRules.MERCURY), 4))


## Survivor: BUILD IT FOR ME takes the parts from the bag; what is missing is offered first (into the bag).
func test_survivor_buys_the_missing_parts_of_the_plan_into_the_bag() -> void:
	owned = null
	board.open()
	board.choose(SpaceRules.MOON)
	var need := RocketParts.count(RocketPlan.cells(_moon(), 1))
	assert_eq(board.plan_short(), need, "an empty bag needs every part")
	assert_string_starts_with(board.press_build(), "Your bag needs ")
	assert_eq(built, [], "nothing built without the parts")
	assert_true(board.buy_plan_button.visible and board.buy_plan_button.is_inside_tree())
	assert_eq(board.buy_plan_button.text, "BUY THE MISSING PARTS: %d gold" % RocketParts.cost(need))
	board.buy_plan_button.pressed.emit()
	assert_true(board.confirm_card.visible)
	board.confirm_yes.pressed.emit()
	assert_eq(bag, need, "into the bag")
	assert_eq(gold, 5000 - RocketParts.cost(need))
	assert_false(board.buy_plan_button.visible, "nothing missing now")
	assert_string_contains(board.message(), "BUILD IT FOR ME")
	assert_eq(board.press_build(), "")
	assert_eq(built, [[SpaceRules.MOON, 1]])


## Too little gold: the exact gold still to earn, and where to earn it (no card, nothing spent).
func test_too_little_gold_says_how_much_more() -> void:
	rocket_cells = RocketPlan.cells(_moon(), 1)
	var cost := RocketParts.cost(RocketParts.count(rocket_cells))
	gold = 120
	board.open()
	board.buy_all_button.pressed.emit()
	assert_false(board.confirm_card.visible)
	assert_eq(board.message(), "You have 120 gold: %d more to go. A School unit mastered gives 100 gold." % (cost - 120))
	assert_eq(gold, 120)
	assert_eq(bought, [])
	board.buy_all_button.pressed.emit()
	board.cancel_buy()
	gold = 5000
	board.buy_all_button.pressed.emit()
	board.confirm_no.pressed.emit()
	assert_false(board.confirm_card.visible)
	assert_eq(gold, 5000, "NO buys nothing")


## Bug 6: the price on the card was stale: the rocket changed (a friend added tanks) before YES. Now YES asks again with
## the new parts and price instead of charging what it never showed.
func test_the_card_asks_again_when_the_rocket_changed() -> void:
	rocket_cells = RocketPlan.cells(_moon(), 1)
	var cost := RocketParts.cost(RocketParts.count(rocket_cells))
	board.open()
	board.buy_all_button.pressed.emit()
	assert_string_contains(board.confirm_label.text, "%d gold?" % cost)
	_add_tank(rocket_cells)   # a friend adds a tank while the card is open
	var now := RocketParts.cost(RocketParts.count(RocketCheck.find_rocket(rocket_cells)))
	assert_ne(now, cost)
	board.confirm_yes.pressed.emit()
	assert_eq(gold, 5000, "nothing charged at the old price")
	assert_true(board.confirm_card.visible, "the card asks again")
	assert_string_starts_with(board.confirm_label.text, MissionBoard.CHANGED_WORDS)
	assert_string_contains(board.confirm_label.text, "%d gold?" % now)
	board.confirm_yes.pressed.emit()
	assert_eq(gold, 5000 - now)


## Bug 4: in a friend's Sandbox world the bulk buy charged the friend and paid for nothing on the owner's pad.
func test_a_friend_s_bulk_buy_is_refused_kindly() -> void:
	rocket_cells = RocketPlan.cells(_moon(), 1)
	guest = true
	board.open()
	assert_eq(board.ask_buy(MissionBoard.BUY_ROCKET), MissionBoard.GUEST_BUY_WORDS)
	assert_false(board.confirm_card.visible)
	assert_eq(gold, 5000, "nothing charged")
	assert_eq(board.buy_part(BlockIds.FUEL_TANK), "", "a part for their own rockets still buys")


## Bug 5: every BUY on PARTS rebuilt the page and jumped to its top.
func test_a_buy_keeps_the_page_s_place() -> void:
	board.open()
	board.show_page(MissionBoard.PARTS_PAGE)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll: ScrollContainer = board._scroll
	scroll.scroll_vertical = 300
	await get_tree().process_frame
	var at := scroll.scroll_vertical
	assert_gt(at, 0, "scrolled down to the lower parts")
	board.buy_part(BlockIds.LANDING_LEGS)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(scroll.scroll_vertical, at, "still there after BUY")
	board.show_page(MissionBoard.MISSIONS_PAGE)
	await get_tree().process_frame
	assert_eq(scroll.scroll_vertical, 0, "a new page starts at its top")


## A grey LAUNCH is still pressed: it says how many lines to fix and the first one.
func test_a_grey_launch_says_why() -> void:
	rocket_cells = {Vector3i(4, 0, 4): BlockIds.ROCKET_ENGINE, Vector3i(4, 1, 4): BlockIds.FUEL_TANK,
		Vector3i(4, 2, 4): BlockIds.CREW_CAPSULE}
	board.open()
	assert_false(board.launch_button.disabled, "it can be pressed")
	var n := board.miss_count()
	assert_eq(board.launch_button.text, "NOT YET: %d LINES TO FIX" % n)
	board.launch_button.pressed.emit()
	assert_string_starts_with(board.message(), "Not yet: %d lines to fix. First: " % n)
	assert_true(board.visible)


## The stage lines name the parts with plurals ("Stage 1: 8 rocket engines, 10 fuel tanks …").
func test_the_stage_lines_use_plurals() -> void:
	rocket_cells = RocketPlan.cells(_moon(), 1)
	board.open()
	var texts := _texts(board)
	assert_true(texts.any(func(t: String) -> bool: return t.begins_with("Stage 1: ") and t.contains("rocket engines")),
		"%s" % [texts])


## A fuel tank beside one of the rocket's tanks (touching it side to side, on the pad's square).
func _add_tank(cells: Dictionary) -> void:
	for p: Vector3i in cells.keys():
		if int(cells[p]) != BlockIds.FUEL_TANK:
			continue
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			if not cells.has(p + d) and RocketCheck.in_square(p + d):
				cells[p + d] = BlockIds.FUEL_TANK
				return


func _texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for n in root.find_children("*", "Label", true, false):
		out.append((n as Label).text)
	return out
