extends GutTest
## Owner #109: a car left alone stays where it was parked and is saved with the world (WorldMeta.cars): its kind, colour,
## owner, place, turn and the pickup's load come back; a save without cars (every world before) has none; nonsense is
## dropped (VehicleRules.clean_save).


func test_parked_cars_go_round_the_world_s_save() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.cars, [], "a new world has no cars")
	m.cars = [{"kind": "bus", "colour": 2, "owner": "Ana", "pos": [1.5, 30.0, -4.0], "yaw": 0.5, "cargo": []},
		{"kind": "pickup", "colour": 1, "owner": "Bo", "pos": [3.0, 31.0, 2.0], "yaw": -1.0,
			"cargo": [BlockIds.BRICK, 8]}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.cars.size(), 2)
	assert_eq(back.cars[0].kind, "bus")
	assert_eq(back.cars[0].owner, "Ana")
	assert_eq(int(back.cars[0].colour), 2)
	assert_almost_eq(float(back.cars[0].yaw), 0.5, 0.0001)
	assert_almost_eq(float(back.cars[0].pos[2]), -4.0, 0.0001)
	assert_eq(back.cars[1].cargo, [BlockIds.BRICK, 8], "the pickup's load")


func test_an_old_save_has_no_cars_and_junk_is_dropped() -> void:
	var old := WorldMeta.new_random()
	var d: Dictionary = JSON.parse_string(old.to_json())
	d.erase("cars")
	assert_eq(WorldMeta.from_json(JSON.stringify(d)).cars, [], "a world saved before cars")
	d.cars = [{"kind": "rocket", "pos": [0, 0, 0]}, "junk", {"kind": "go_kart", "pos": [1, 2]}]
	assert_eq(WorldMeta.from_json(JSON.stringify(d)).cars, [])
