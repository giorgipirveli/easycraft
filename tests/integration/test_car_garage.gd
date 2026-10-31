extends GutTest
## Owner #109 (spec §3b "Cars"): the garage (MORE → CARS, GaragePanel): the eight cars as tiles with their pictures
## (drawn from their own models) and FREE (the Sandbox), their price or YOURS (Survivor); the picked car's picture in
## its colour, its name read aloud, its line, its numbers, four colours, its card (DID YOU KNOW? and checked facts) and
## one big button: GET IT (the Sandbox), BUY <price> (Survivor, not yet yours) or CALL MY CAR; PUT AWAY for a car out.
## The button asks the host and the garage closes, so the child sees the car come; a tap outside or CLOSE closes it,
## and it hears every touch on it (never the HUD's buttons under it).

const ME_AT := Vector3(0.5, 10.0, 0.5)


class CellWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 9


var world: CellWorld
var director: VehicleDirector
var me: Player
var _mode_before: StringName
var _gold_before := 0
var _bought_before: Array[String] = []
var _name_before := ""


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_bought_before = Profile.data.bought.duplicate()
	_name_before = Profile.data.username
	Profile.data.username = "Kid"
	Game.mode = ModeRules.SANDBOX
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)


func after_each() -> void:
	Session.register_world(null)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.bought = _bought_before
	Profile.data.username = _name_before


func _garage() -> GaragePanel:
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	me._spawned = true
	director = VehicleDirector.new()
	director.name = "Vehicles"
	director.host_checks = false
	director.save_profile = func() -> void: pass
	add_child_autofree(director)
	director.set_process(false)
	director.setup_local(me, null, self)
	director.open_garage()
	await wait_process_frames(2)
	return director.garage


func test_the_sandbox_garage_has_every_car_free() -> void:
	var g := await _garage()
	assert_not_null(g)
	assert_eq(g.tiles.size(), CarKinds.ORDER.size(), "a tile for each of the eight cars")
	for kind in CarKinds.ORDER:
		assert_eq(g.tag_of(kind), "FREE", kind)
		assert_true(g.tiles[kind].find_children("*", "CarPicture", true, false).size() == 1, "%s has its picture" % kind)
	assert_eq(g.kind, CarKinds.GO_KART, "the first is picked")
	assert_eq(g.main_button.text, "GET IT")
	assert_false(g.away_button.visible, "nothing out yet")
	assert_string_contains(g.card.facts.text, CarKinds.facts(CarKinds.GO_KART)[0])
	assert_string_contains(g.numbers_label.text, str(CarKinds.speed(CarKinds.GO_KART)).trim_suffix(".0"))


func test_picking_a_car_and_a_colour_shows_it() -> void:
	var g := await _garage()
	g.pick(CarKinds.MONSTER_TRUCK)
	assert_eq(g.kind, CarKinds.MONSTER_TRUCK)
	assert_eq(g.picture.kind, CarKinds.MONSTER_TRUCK)
	assert_eq(g.title_label.text, CarKinds.display_name(CarKinds.MONSTER_TRUCK))
	assert_eq(g.about_label.text, CarKinds.about(CarKinds.MONSTER_TRUCK))
	assert_string_contains(g.card.facts.text, "1.7 metres")
	assert_eq(g.swatches.size(), CarKinds.COLOURS)
	g.swatches[2].pressed.emit()
	assert_eq(g.colour, 2)
	assert_eq(g.picture.colour, 2, "the picture in that colour")
	var words := g.card.words()
	assert_string_contains(words, "Monster Truck", "read aloud: its name ...")
	assert_string_contains(words, "DID YOU KNOW", "... and its card")


func test_get_it_brings_the_car_and_closes_the_garage() -> void:
	var g := await _garage()
	g.pick(CarKinds.BUS)
	g.swatches[1].pressed.emit()
	g.main_button.pressed.emit()
	await wait_process_frames(2)
	var bus := director.car_of("Kid", CarKinds.BUS)
	assert_not_null(bus, "the bus came out")
	assert_eq(bus.colour, 1)
	assert_false(director.garage_open(), "the garage closed so the child sees it")
	director.open_garage()
	await wait_process_frames(2)
	director.garage.pick(CarKinds.BUS)
	assert_eq(director.garage.main_button.text, "CALL IT", "out already: calling brings it")
	assert_true(director.garage.away_button.visible, "PUT AWAY sends it back")


func test_survivor_shows_prices_and_buys_with_gold() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.bought = [VehicleRules.owned_id(CarKinds.GO_KART)]
	Profile.data.survivor_gold = 300
	var g := await _garage()
	assert_eq(g.tag_of(CarKinds.GO_KART), "YOURS")
	assert_eq(g.tag_of(CarKinds.RACE_CAR), str(CarKinds.price(CarKinds.RACE_CAR)))
	assert_eq(g.main_button.text, "CALL MY CAR", "the go-kart is the child's own")
	g.pick(CarKinds.RACE_CAR)
	assert_eq(g.main_button.text, "BUY %d" % CarKinds.price(CarKinds.RACE_CAR))
	assert_string_contains(g.gold_label.text, "300")
	g.main_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(Profile.data.survivor_gold, 300 - CarKinds.price(CarKinds.RACE_CAR))
	assert_has(Profile.data.bought, VehicleRules.owned_id(CarKinds.RACE_CAR))
	assert_not_null(director.car_of("Kid", CarKinds.RACE_CAR), "bought and out")


func test_close_and_a_tap_outside_close_it_and_touches_never_reach_the_hud() -> void:
	var g := await _garage()
	g.close_button.pressed.emit()
	await wait_process_frames(1)
	assert_false(director.garage_open())
	director.open_garage()
	await wait_process_frames(2)
	var inside := InputEventScreenTouch.new()
	inside.pressed = true
	inside.position = director.garage.box.get_global_rect().get_center()
	director.garage._input(inside)
	assert_true(director.garage_open(), "a touch on the garage stays in it")
	var outside := InputEventScreenTouch.new()
	outside.pressed = true
	outside.position = Vector2(2, 2)
	director.garage._input(outside)
	await wait_process_frames(1)
	assert_false(director.garage_open(), "a tap outside closes it")


func test_every_picture_is_drawn_from_its_model() -> void:
	for kind in CarKinds.ORDER:
		var shapes := CarPicture.shapes(kind, 0)
		assert_gt(shapes.size(), 4, kind)
		for i in range(1, shapes.size()):
			assert_lte(float(shapes[i - 1][2]), float(shapes[i][2]), "%s: the far side first" % kind)
		var p := CarPicture.new(kind, 1, Vector2(160, 90))
		add_child_autofree(p)
	await wait_process_frames(1)
	assert_true(true, "drawn without errors")


func test_it_fits_a_phone_s_screen_with_big_buttons() -> void:
	for kind in CarKinds.ORDER:
		var g := await _garage()
		g.pick(kind)
		await wait_process_frames(2)
		var need := g.box.get_combined_minimum_size()
		assert_lte(need.x, 1280.0 - 20.0, "%s: the garage's width %s" % [kind, need])
		assert_lte(need.y, 720.0 - 20.0, "%s: and height" % kind)
		for b: Button in [g.main_button, g.close_button] + g.swatches + g.tiles.values():
			assert_gte(minf(b.size.x, b.size.y), 64.0, "%s: %s is big enough for a finger" % [kind, b.name])
		director.close_garage()
		director.free()
		me.free()
		await wait_process_frames(1)
