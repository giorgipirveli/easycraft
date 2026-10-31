extends GutTest
## M2 Task 16 (spec §12.16): the secrets that happen while playing — the Wanderer at dusk, shooting stars,
## golden animals, the temple's plates, the secret chime and the treasure map's compass.


func test_the_wanderer_comes_on_the_first_dusk_then_about_one_in_three() -> void:
	assert_true(SurpriseRules.wanderer_visits(12345, 1), "the first dusk of a world always")
	var visits := 0
	for dusk in range(2, 302):
		if SurpriseRules.wanderer_visits(12345, dusk):
			visits += 1
	assert_between(visits / 300.0, 0.2, 0.45, "rare")
	assert_eq(SurpriseRules.wanderer_visits(7, 9), SurpriseRules.wanderer_visits(7, 9), "deterministic")


func test_the_wanderers_riddles_have_three_picture_answers() -> void:
	for r: Dictionary in Riddles.WANDERER_RIDDLES:
		assert_eq((r.choices as Array).size(), 3, r.question)
		assert_between(int(r.answer), 0, 2)
		assert_lte((r.question as String).length(), 34, "short: %s" % r.question)
		for picture: int in r.choices:
			assert_ne(Riddles.word(picture), "", "a short word under each picture")
	var i := SurpriseRules.wanderer_riddle(12345, 4)
	assert_between(i, 0, Riddles.WANDERER_RIDDLES.size() - 1)
	var r := Riddles.wanderer_riddle(i)
	assert_true(SurpriseRules.is_right_answer(i, r.answer))
	assert_false(SurpriseRules.is_right_answer(i, (int(r.answer) + 1) % 3))
	assert_false(SurpriseRules.is_right_answer(i, 7), "nonsense from the network")


func test_the_wanderer_appears_a_few_steps_from_the_player() -> void:
	var near := Vector3(100, 40, -50)
	for dusk in 20:
		var p := SurpriseRules.wanderer_spot(3, dusk, near)
		var d := Vector2(p.x - near.x, p.y - near.z).length()
		assert_between(d, SurpriseRules.WANDERER_MIN_DISTANCE, SurpriseRules.WANDERER_MAX_DISTANCE + 0.01)
	var spots := {}
	for attempt in SurpriseRules.WANDERER_TRIES:
		spots[SurpriseRules.wanderer_spot(3, 5, near, attempt)] = true
	assert_eq(spots.size(), SurpriseRules.WANDERER_TRIES, "other tries, other places around the player")


## He stands where the player can see him: on ground about as high as the player's feet.
func test_the_wanderer_picks_a_spot_at_the_players_level() -> void:
	var near := Vector3(0.5, 40, 0.5)
	var first := SurpriseRules.wanderer_spot(3, 5, near, 0)
	var wall := func(x: int, z: int) -> int: return 60 if Vector2i(x, z) == Vector2i(floori(first.x), floori(first.y)) else 40
	var spot := SurpriseRules.wanderer_place(3, 5, near, wall)
	assert_false(spot.is_empty())
	assert_eq(spot.pos.y, 40.0, "not on the roof of the wall in the first try's spot")
	var cliffs := func(_x: int, _z: int) -> int: return 90
	assert_true(SurpriseRules.wanderer_place(3, 5, near, cliffs).is_empty(), "nowhere at the player's level")
	var flat := func(_x: int, _z: int) -> int: return 40
	var behind_wall := func(_from: Vector3, to: Vector3) -> bool: return floori(to.x) != floori(first.x) or floori(to.z) != floori(first.y)
	var seen := SurpriseRules.wanderer_place(3, 5, near, flat, behind_wall)
	assert_ne(Vector2(seen.pos.x, seen.pos.z).floor(), first.floor(), "never behind a wall: the player must see him")


func test_a_star_falls_on_the_first_night_then_about_every_other_night() -> void:
	assert_true(SurpriseRules.star_falls(12345, 1))
	var falls := 0
	for night in range(2, 202):
		if SurpriseRules.star_falls(12345, night):
			falls += 1
	assert_between(falls / 200.0, 0.35, 0.65)
	for night in 20:
		var delay := SurpriseRules.star_delay(12345, night)
		assert_between(delay, SurpriseRules.STAR_DELAY.x, SurpriseRules.STAR_DELAY.y)


func test_a_star_lands_on_dry_ground_nearby() -> void:
	var near := Vector3(0, 40, 0)
	var land := func(x: int, z: int) -> int: return 40 if x > 0 else MeadowsShape.SEA_LEVEL - 3   # sea on the west
	for night in 30:
		var spot := SurpriseRules.star_spot(12345, night, near, land)
		if spot.is_empty():
			continue
		var cell: Vector3i = spot.ground
		assert_gt(cell.x, 0, "never into the sea")
		assert_eq(cell.y, 40, "on the ground")
		var d := Vector2(cell.x - near.x, cell.z - near.z).length()
		assert_between(d, SurpriseRules.STAR_MIN_DISTANCE - 1.0, SurpriseRules.STAR_MAX_DISTANCE + 1.0)
	var sea := func(_x: int, _z: int) -> int: return MeadowsShape.SEA_LEVEL - 3
	assert_true(SurpriseRules.star_spot(12345, 1, near, sea).is_empty(), "all sea: no star")


func test_a_fallen_star_is_a_glowing_meteor_with_crystals() -> void:
	var ground := Vector3i(10, 40, 10)
	var blocks := SurpriseRules.meteor_blocks(ground)
	var crystals := 0
	for e: Array in blocks:
		var p: Vector3i = e[0]
		assert_lte(absi(p.x - ground.x), 1)
		assert_lte(absi(p.z - ground.z), 1)
		assert_between(p.y, ground.y - 1, ground.y + 1)
		if e[1] == BlockIds.CRYSTAL:
			crystals += 1
	assert_gte(crystals, 3)
	assert_true(blocks.any(func(e: Array) -> bool: return e[0] == ground + Vector3i.UP and e[1] == BlockIds.CRYSTAL), "a glowing top")


## A meteor lands in nature: it never smashes a child's build.
func test_a_meteor_only_replaces_air_and_natural_ground() -> void:
	for id in [BlockIds.AIR, BlockIds.GRASS, BlockIds.DIRT, BlockIds.SAND, BlockIds.STONE, BlockIds.LEAVES]:
		assert_true(SurpriseRules.meteor_may_replace(id), BlockIds.display_name(id))
	for id in [BlockIds.PLANKS, BlockIds.BRICK, BlockIds.GLASS, BlockIds.BED, BlockIds.RED, BlockIds.LOG, BlockIds.WATER]:
		assert_false(SurpriseRules.meteor_may_replace(id), BlockIds.display_name(id))


func test_about_one_herd_in_twenty_has_a_golden_animal() -> void:
	var golden := 0
	for i in 2000:
		if SurpriseRules.is_golden(12345, "a%d_%d_0" % [i, -i]):
			golden += 1
		assert_false(SurpriseRules.is_golden(12345, "a%d_%d_1" % [i, -i]), "only a herd's first animal")
	assert_between(golden / 2000.0, 0.03, 0.08)
	assert_false(SurpriseRules.is_golden(12345, "s12"), "summoned animals never")
	assert_false(SurpriseRules.is_golden(12345, "pet3"))


func test_a_golden_animal_runs_from_anyone_close_but_can_be_caught() -> void:
	var at := Vector3(0, 40, 0)
	var away := SurpriseRules.golden_flee(at, [Vector3(3, 40, 0)] as Array[Vector3])
	assert_almost_eq(away.x, -1.0, 0.001, "away from the player")
	assert_eq(SurpriseRules.golden_flee(at, [Vector3(20, 40, 0)] as Array[Vector3]), Vector3.ZERO, "calm when nobody is near")
	assert_lt(SurpriseRules.golden_speed(3.6), Player.WALK_SPEED, "slower than a walking child")
	assert_gt(SurpriseRules.golden_speed(1.6), 1.6)


func test_temple_plates_open_only_in_the_riddles_order() -> void:
	var order := [2, 0, 1]
	var r := SurpriseRules.press_plate([] as Array[int], 2, order)
	assert_eq(r.result, &"ok")
	r = SurpriseRules.press_plate(r.progress, 0, order)
	assert_eq(r.result, &"ok")
	r = SurpriseRules.press_plate(r.progress, 1, order)
	assert_eq(r.result, &"solved")
	r = SurpriseRules.press_plate([] as Array[int], 0, order)
	assert_eq(r.result, &"wrong")
	assert_eq(r.progress, [] as Array[int], "the plates pop back up")
	r = SurpriseRules.press_plate([2] as Array[int], 1, order)
	assert_eq(r.result, &"wrong")
	r = SurpriseRules.press_plate([2, 0] as Array[int], 2, order)
	assert_eq(r.result, &"wrong")
	assert_eq(r.progress, [2] as Array[int], "a wrong step on the first plate starts again from it")
	assert_eq(SurpriseRules.press_plate([] as Array[int], 9, order).result, &"wrong", "nonsense")


func test_the_secret_chime_rings_within_twelve_blocks() -> void:
	assert_true(SurpriseRules.should_chime(Vector3(0, 40, 0), Vector3i(7, 38, 7)))
	assert_false(SurpriseRules.should_chime(Vector3(0, 40, 0), Vector3i(12, 40, 12)))
	assert_eq(SurpriseRules.CHIME_DISTANCE, 12.0)


func test_the_compass_points_where_the_treasure_is() -> void:
	var from := Vector3(0, 40, 0)
	var ahead := SurpriseRules.compass(from, Vector3(0, 30, -50), 0.0)     # yaw 0 looks along -Z
	assert_almost_eq(float(ahead.angle), 0.0, 0.001)
	assert_eq(ahead.distance, 50)
	var right := SurpriseRules.compass(from, Vector3(20, 40, 0), 0.0)
	assert_almost_eq(float(right.angle), PI / 2, 0.001, "to the right")
	var behind := SurpriseRules.compass(from, Vector3(0, 40, 30), 0.0)
	assert_almost_eq(absf(float(behind.angle)), PI, 0.001)
	var turned := SurpriseRules.compass(from, Vector3(20, 40, 0), -PI / 2)  # facing +X now
	assert_almost_eq(float(turned.angle), 0.0, 0.001)


## Spec §12.16 #4: golden slimes, Survivor only, one night slime in GOLDEN_SLIME_ONE_IN.
func test_one_survivor_night_slime_in_twenty_is_golden() -> void:
	assert_eq(SurpriseRules.GOLDEN_SLIME_ONE_IN, 20)
	assert_true(SurpriseRules.golden_slime(40, true))
	assert_false(SurpriseRules.golden_slime(41, true))
	assert_false(SurpriseRules.golden_slime(40, false), "no golden slimes in Sandbox (golden animals there)")


## M3 (lead, after the desert merge): a falling star lands on desert ground too (never a build).
func test_a_meteor_lands_on_desert_ground() -> void:
	for id: int in BlockIds.DESERT_GROUND:
		assert_true(SurpriseRules.METEOR_REPLACES.has(id), BlockIds.display_name(id))
	assert_false(SurpriseRules.METEOR_REPLACES.has(BlockIds.CUT_SANDSTONE), "a build stays")
