extends GutTest
## Owner #78 (spec §21e): "invent it" in a played world. In Survivor MAKE IT at a Workbench takes exactly the
## materials from the bag and the gold (free once its School unit is mastered) and keeps the invention in the profile;
## a LAN guest invents in its own world; the Sandbox has nothing to make. TRY IT runs the challenge from the child's
## body and pays EarnRules' try-it gold once (a guest in a friend's world: nothing); the rocket's is the bottle rocket.
## FLY WITH IT: Survivor's pick is saved, the Sandbox's is this session's. The wind blows one way for a while.

var director: InventionsDirector
var inv: Inventory
var coins := 100
var spent: Array = []
var paid: Array = []
var toasts: Array[String] = []
var saves := 0
var workbench := true
var feed := {}


func before_each() -> void:
	inv = Inventory.new()
	coins = 100
	spent = []
	paid = []
	toasts = []
	saves = 0
	workbench = true
	feed = {}
	director = InventionsDirector.new()
	director.survivor = true
	director.world_seed = 12345
	director.auto_tick = false
	director.data = InventionData.new()
	director.school = SchoolData.new()
	director.bag = func() -> Inventory: return inv
	director.near_workbench = func() -> bool: return workbench
	director.gold = func() -> int: return coins
	director.spend = func(g: int) -> bool:
		if g > coins:
			return false
		coins -= g
		spent.append(g)
		return true
	director.pay = func(g: int) -> void: paid.append(g)
	director.toast = func(t: String) -> void: toasts.append(t)
	director.save_profile = func() -> void: saves += 1
	director.sample = func() -> Dictionary: return feed
	director.now = func() -> float: return 1000.0
	add_child_autofree(director)
	var ui := Control.new()
	add_child_autofree(ui)
	director.setup(ui, ui)


func _stock(id: StringName) -> void:
	for n: Array in InventionLine.entry(id).needs:
		inv.add(int(InventionLine.MATERIALS[n[0]].ids[0]), int(n[1]))


func test_making_the_kite_takes_its_materials_and_its_gold() -> void:
	_stock(InventionLine.KITE)
	inv.add(ItemIds.STICK, 1)
	assert_eq(director.make(InventionLine.KITE), "")
	assert_true(director.data.has(InventionLine.KITE))
	assert_eq(inv.count(ItemIds.STICK), 1, "exactly its four sticks")
	assert_eq(spent, [10])
	assert_gt(saves, 0, "kept in the profile")
	assert_string_contains(toasts[-1], "You invented the kite!")
	assert_string_contains(director.make(InventionLine.KITE), "already")


func test_it_needs_a_workbench_the_one_before_and_the_materials() -> void:
	_stock(InventionLine.BALLOON)
	assert_string_contains(director.make(InventionLine.BALLOON), "The Kite", "the kite first")
	workbench = false
	_stock(InventionLine.KITE)
	assert_eq(director.make(InventionLine.KITE), "Stand next to a Workbench to make it!")
	workbench = true
	coins = 3
	assert_eq(director.make(InventionLine.KITE), "You need 10 gold to make it!")
	assert_false(director.data.has(InventionLine.KITE))
	assert_eq(inv.count(ItemIds.STICK), 8, "nothing taken")


func test_a_school_unit_mastered_makes_it_free() -> void:
	_stock(InventionLine.KITE)
	director.school.set_progress(str(InventionLine.entry(InventionLine.KITE).unit), {"s": MasteryRules.MASTERED})
	coins = 0
	assert_eq(director.make(InventionLine.KITE), "")
	assert_eq(spent, [], "learning paid for it")


func test_a_guest_invents_at_home_and_the_sandbox_makes_nothing() -> void:
	_stock(InventionLine.KITE)
	director.host = false
	assert_string_contains(director.make(InventionLine.KITE), "your own world")
	director.host = true
	director.survivor = false
	assert_string_contains(director.make(InventionLine.KITE), "TRY IT")
	assert_false(director.data.has(InventionLine.KITE))


func test_a_try_runs_from_the_body_and_pays_once() -> void:
	assert_string_contains(director.try_it(InventionLine.BALLOON), "Invent it first")
	director.data = InventionData.invented_to(InventionLine.BALLOON)
	assert_eq(director.try_it(InventionLine.BALLOON), "")
	assert_true(director.trial.active())
	assert_true(director.banner.visible, "the banner shows the goal")
	feed = {"pos": Vector3(0, 30, 0), "craft": FlightCrafts.Craft.BALLOON, "flying": true, "on_floor": false,
		"facing": Vector3.FORWARD, "yaw": 0.0}
	director.tick(0.1)
	feed.pos = Vector3(0, 46, 0)
	director.tick(0.1)
	assert_false(director.trial.active(), "done")
	assert_eq(paid, [EarnRules.INVENT_TRY_GOLD])
	assert_true(director.data.was_tried(InventionLine.BALLOON))
	assert_string_contains(toasts[-1], "lighter than the cold air")
	director.try_it(InventionLine.BALLOON)
	feed.pos = Vector3(0, 30, 0)
	director.tick(0.1)
	feed.pos = Vector3(0, 46, 0)
	director.tick(0.1)
	assert_eq(paid, [EarnRules.INVENT_TRY_GOLD], "once")


func test_the_rocket_s_try_is_the_bottle_rocket() -> void:
	director.survivor = false
	director.try_it(InventionLine.ROCKET)
	director.panel.open(InventionLine.ROCKET)
	director.panel.open_bottle()
	for i in 3:
		director.panel.bottle.pump()
	director.panel.bottle.fire()
	assert_eq(paid, [], "16 metres: not yet")
	director.panel.bottle._fly_t = -1.0
	for i in 7:
		director.panel.bottle.pump()
	director.panel.bottle.fire()
	assert_eq(paid, [EarnRules.INVENT_TRY_GOLD], "30 metres and more")
	director.panel.bottle._fly_t = -1.0
	director.panel.bottle.pump()
	for i in 8:
		director.panel.bottle.pump()
	director.panel.bottle.fire()
	assert_eq(paid, [EarnRules.INVENT_TRY_GOLD], "once")


func test_a_guest_s_try_pays_nothing() -> void:
	director.host = false
	director.data = InventionData.invented_to(InventionLine.PLANE)
	director.try_it(InventionLine.PLANE)
	feed = {"pos": Vector3(0, 40, 0), "craft": FlightCrafts.Craft.PLANE, "flying": true, "on_floor": false}
	for i in 130:
		director.tick(0.1)
	assert_false(director.trial.active(), "done")
	assert_eq(paid, [])
	assert_string_contains(toasts[-1], "your own world")


func test_fly_with_it_saves_survivor_s_pick_and_keeps_the_sandbox_s_for_now() -> void:
	director.data = InventionData.invented_to(InventionLine.PLANE)
	assert_eq(director.chosen_craft(), FlightCrafts.Craft.PLANE, "the newest")
	director.fly_with(InventionLine.BALLOON)
	assert_eq(director.data.craft, InventionLine.BALLOON)
	assert_eq(director.chosen_craft(), FlightCrafts.Craft.BALLOON)
	assert_string_contains(director.fly_with(InventionLine.JET), "Invent it first")
	director.survivor = false
	assert_eq(director.chosen_craft(), FlightCrafts.Craft.NONE, "the Sandbox's classic flying")
	director.fly_with(InventionLine.JET)
	assert_eq(director.chosen_craft(), FlightCrafts.Craft.JET)
	director.fly_with(&"")
	assert_eq(director.chosen_craft(), FlightCrafts.Craft.NONE)


func test_the_wind_blows_one_way_for_a_while() -> void:
	var w := director.wind()
	assert_almost_eq(w.length(), FlightCrafts.WIND_SPEED, 0.001)
	director.now = func() -> float: return 1000.0 + FlightCrafts.WIND_CHANGE * 0.5
	assert_eq(director.wind(), w, "the same five minutes")
	assert_almost_eq(InventionsDirector._screen_angle(Vector3(0, 0, -1), 0.0), 0.0, 0.001, "ahead: up")
	assert_almost_eq(InventionsDirector._screen_angle(Vector3(1, 0, 0), 0.0), PI / 2.0, 0.001, "to the right")
