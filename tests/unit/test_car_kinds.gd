extends GutTest
## Owner #109 (spec §3b "Cars"): eight ready-made kinds, each with its own feel, look and seats: a go-kart, an off-roader
## (the brief's jeep), a race car, a pickup truck, a bus, a monster truck, a hover car and a sky taxi. Never faster than
## 14 m/s on the ground, and no flying car faster than the paid Fly; the go-kart the cheapest, the flying cars the dearest;
## four colours each; a card with checked facts for every kind.


func test_there_are_eight_kinds_in_the_garage_s_order() -> void:
	assert_eq(CarKinds.ORDER, [CarKinds.GO_KART, CarKinds.OFF_ROADER, CarKinds.RACE_CAR, CarKinds.PICKUP, CarKinds.BUS,
		CarKinds.MONSTER_TRUCK, CarKinds.HOVER_CAR, CarKinds.SKY_TAXI] as Array[StringName])
	for kind in CarKinds.ORDER:
		assert_true(CarKinds.exists(kind), kind)
		assert_ne(CarKinds.display_name(kind), "", "%s has a name" % kind)
	assert_false(CarKinds.exists(&"spaceship"))
	assert_eq(CarKinds.display_name(&"nothing"), "")


func test_the_brief_s_feel_of_each_kind() -> void:
	var top := 0.0
	var fastest := &""
	for kind in CarKinds.ORDER:
		if CarKinds.speed(kind) > top:
			top = CarKinds.speed(kind)
			fastest = kind
	assert_eq(fastest, CarKinds.RACE_CAR, "the race car is the fastest on flat ground")
	assert_eq(CarKinds.speed(CarKinds.RACE_CAR), CarKinds.GROUND_TOP)
	assert_eq(CarKinds.GROUND_TOP, 14.0, "the brief's 14 m/s at most")
	for kind in CarKinds.ORDER:
		assert_lte(CarKinds.speed(kind), CarKinds.GROUND_TOP, "%s on the ground" % kind)
		assert_gt(CarKinds.speed(kind), 0.0)
		assert_gt(CarKinds.reverse_speed(kind), 0.0)
		assert_lt(CarKinds.reverse_speed(kind), CarKinds.speed(kind), "%s backs up slower" % kind)
		assert_gt(CarKinds.accel(kind), 0.0)
		assert_gt(CarKinds.turn(kind), 0.0)
	var quickest := CarKinds.GO_KART
	for kind in CarKinds.ORDER:
		assert_lte(CarKinds.turn(kind), CarKinds.turn(quickest), "the go-kart turns the quickest")
	assert_eq(CarKinds.climb(CarKinds.OFF_ROADER), 2, "the jeep climbs 2 blocks")
	assert_eq(CarKinds.climb(CarKinds.MONSTER_TRUCK), 3, "the monster truck climbs 3")
	assert_true(CarKinds.bounces(CarKinds.MONSTER_TRUCK), "and bounces")
	for kind in [CarKinds.GO_KART, CarKinds.RACE_CAR, CarKinds.PICKUP, CarKinds.BUS, CarKinds.HOVER_CAR, CarKinds.SKY_TAXI]:
		assert_eq(CarKinds.climb(kind), 1, "%s climbs 1 block" % kind)
	var slowest := CarKinds.BUS
	for kind in CarKinds.ORDER:
		assert_gte(CarKinds.speed(kind), CarKinds.speed(slowest), "the bus is the slowest")
	assert_true(CarKinds.carries_load(CarKinds.PICKUP), "the pickup carries blocks in its bed")
	for kind in CarKinds.ORDER:
		if kind != CarKinds.PICKUP:
			assert_false(CarKinds.carries_load(kind))


func test_seats() -> void:
	var want := {CarKinds.GO_KART: 1, CarKinds.OFF_ROADER: 4, CarKinds.RACE_CAR: 1, CarKinds.PICKUP: 2, CarKinds.BUS: 8,
		CarKinds.MONSTER_TRUCK: 2, CarKinds.HOVER_CAR: 2, CarKinds.SKY_TAXI: 4}
	for kind: StringName in want:
		assert_eq(CarKinds.seats(kind), want[kind], "%s seats" % kind)
		assert_eq(CarKinds.seat_offsets(kind).size(), want[kind])
		var box := CarKinds.box(kind)
		for s: Vector3 in CarKinds.seat_offsets(kind):
			assert_lte(absf(s.x), CarKinds.size(kind).x * 0.5, "%s: a seat inside the car's width" % kind)
			assert_lte(absf(s.z), CarKinds.size(kind).z * 0.5, "%s: and its length" % kind)
			assert_gte(s.y, 0.0)
			assert_lt(s.y, box.y + 1.0, "%s: a seat on the car, not over it" % kind)
	var most := 0
	for kind in CarKinds.ORDER:
		most = maxi(most, CarKinds.seats(kind))
	assert_eq(most, CarKinds.seats(CarKinds.BUS), "the bus has room for the whole team")


func test_flying_cars() -> void:
	assert_eq(CarKinds.FLYING, [CarKinds.HOVER_CAR, CarKinds.SKY_TAXI] as Array[StringName])
	assert_eq(CarKinds.FLY_TOP, Player.FLY_SPEED, "never faster than the paid Fly (the rides' ruling)")
	for kind in CarKinds.ORDER:
		assert_eq(CarKinds.flies(kind), CarKinds.FLYING.has(kind), kind)
		if CarKinds.flies(kind):
			assert_gt(CarKinds.fly_speed(kind), 0.0)
			assert_lte(CarKinds.fly_speed(kind), CarKinds.FLY_TOP, "%s flies no faster than the paid Fly" % kind)
		else:
			assert_eq(CarKinds.fly_speed(kind), 0.0)
	assert_gt(CarKinds.seats(CarKinds.SKY_TAXI), CarKinds.seats(CarKinds.HOVER_CAR), "the taxi has seats for friends")
	assert_true(CarKinds.hovers(CarKinds.HOVER_CAR), "the hover car floats on air (no wheels)")
	assert_eq(CarKinds.wheels(CarKinds.HOVER_CAR).size(), 0)
	assert_lt(CarKinds.above_ground(CarKinds.HOVER_CAR), CarKinds.above_ground(CarKinds.SKY_TAXI),
		"the hover car flies gently, low")


func test_prices_in_line_with_the_rocket_s_parts() -> void:
	var cheapest := CarKinds.GO_KART
	for kind in CarKinds.ORDER:
		assert_gt(CarKinds.price(kind), 0, kind)
		assert_eq(CarKinds.price(kind) % 5, 0, "%s: a round price" % kind)
		assert_gte(CarKinds.price(kind), CarKinds.price(cheapest), "the go-kart is the cheapest")
		if not CarKinds.flies(kind):
			for f: StringName in CarKinds.FLYING:
				assert_lt(CarKinds.price(kind), CarKinds.price(f), "the flying cars are the dearest (%s, %s)" % [kind, f])
	assert_lte(CarKinds.price(CarKinds.GO_KART), RocketParts.PRICES[BlockIds.CREW_CAPSULE], "a go-kart for a part's price")
	assert_lte(CarKinds.price(CarKinds.HOVER_CAR), SpendRules.GUIDE.moon_rocket, "a flying car about a Moon rocket")
	assert_lte(CarKinds.price(CarKinds.SKY_TAXI), SpendRules.GUIDE.mars_rocket, "the dearest about a Mars rocket")


func test_looks_colours_and_sizes() -> void:
	for kind in CarKinds.ORDER:
		assert_eq(CarKinds.colours(kind).size(), CarKinds.COLOURS, "%s: four colours" % kind)
		assert_eq(CarKinds.colour_names(kind).size(), CarKinds.COLOURS)
		var s := CarKinds.size(kind)
		var b := CarKinds.box(kind)
		assert_true(s.x > 0.5 and s.y > 0.5 and s.z > 1.0, "%s has a size" % kind)
		assert_true(b.x <= s.x and b.z <= s.z + 0.01, "%s: its box inside its look" % kind)
		assert_lte(b.x, CarKinds.MAX_BOX.x, "%s: a compact box (owner feedback #9)" % kind)
		assert_lte(b.z, CarKinds.MAX_BOX.z)
		assert_gt(CarKinds.camera_distance(kind), 0.0)
		if not CarKinds.hovers(kind):
			assert_gte(CarKinds.wheels(kind).size(), 4, "%s has wheels" % kind)
			assert_gt(CarKinds.wheel_radius(kind), 0.1)
	assert_gt(CarKinds.wheel_radius(CarKinds.MONSTER_TRUCK), CarKinds.wheel_radius(CarKinds.OFF_ROADER) * 1.5,
		"the monster truck's huge wheels")
	assert_gt(CarKinds.size(CarKinds.BUS).z, CarKinds.size(CarKinds.GO_KART).z * 2.0, "the bus is long")
	assert_eq(CarKinds.colour_of(CarKinds.GO_KART, 99), CarKinds.colours(CarKinds.GO_KART)[0], "an unknown colour: the first")
	assert_eq(CarKinds.colour_index(-3), 0)
	assert_eq(CarKinds.colour_index(2), 2)


func test_every_card_has_its_facts() -> void:
	for kind in CarKinds.ORDER:
		assert_ne(CarKinds.about(kind), "", "%s: one line about it" % kind)
		var facts := CarKinds.facts(kind)
		assert_between(facts.size(), 2, 4, "%s: two to four facts" % kind)
		for f: String in facts:
			assert_lte(f.length(), 240, "%s: a short fact for a child: %s" % [kind, f])
	var all := " ".join(PackedStringArray(CarKinds.facts(CarKinds.SKY_TAXI)))
	assert_string_contains(all, "AirCar", "a real flying car that was tested (the brief's example)")
	assert_string_contains(" ".join(PackedStringArray(CarKinds.facts(CarKinds.HOVER_CAR))), "air")
	assert_string_contains(" ".join(PackedStringArray(CarKinds.facts(CarKinds.MONSTER_TRUCK))), "wheel")
	var electric := false
	for kind in CarKinds.ORDER:
		electric = electric or " ".join(PackedStringArray(CarKinds.facts(kind))).to_lower().contains("electric")
	assert_true(electric, "electric cars come up")
	for kind in CarKinds.ORDER:
		var words := CarKinds.numbers_words(kind)
		assert_string_contains(words, str(CarKinds.seats(kind)), "%s: its seats in its numbers" % kind)
