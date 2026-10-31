extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's void as pure rules (DragonRules). Fall off an island and the
## wind carries you back to the island you fell from: never lost, no knock-out, nothing dropped. A body remembers
## the last spot it stood on solid ground (at most every half second); below RESCUE_Y (under every island) it goes
## back there. Animals, pets, bot friends and living buddies come back next to their child (or the world spawn);
## monsters puff away.


class Desc:
	var has_void := true


class Plain:
	var name := &"plain"


func test_rescue_y_lies_under_every_island() -> void:
	assert_lt(DragonRules.RESCUE_Y, float(DragonShape.MIN_BOTTOM), "no island's underside reaches the rescue line")
	assert_gt(DragonRules.RESCUE_Y, SpawnRules.FALL_LIMIT_Y, "long before the old fall-out-of-the-world line")
	assert_true(DragonRules.fell_into_void(DragonRules.RESCUE_Y - 0.1))
	assert_false(DragonRules.fell_into_void(DragonRules.RESCUE_Y + 0.1))


func test_a_descriptor_with_a_void() -> void:
	assert_true(DragonRules.has_void(Desc.new()))
	assert_false(DragonRules.has_void(Plain.new()), "no field: no void")
	assert_false(DragonRules.has_void(null), "Green Meadows has no descriptor object here")
	var d := Desc.new()
	d.has_void = false
	assert_false(DragonRules.has_void(d))


## Monster Wave's arena of the realm is flat ground (ArenaShape): no void there, so no rescue either.
func test_the_arena_of_a_void_universe_has_no_void() -> void:
	assert_true(DragonRules.world_has_void(Desc.new(), false))
	assert_false(DragonRules.world_has_void(Desc.new(), true), "the arena's flat ground")
	assert_false(DragonRules.world_has_void(Plain.new(), false))


func test_a_safe_spot_is_solid_ground_under_the_feet() -> void:
	var feet := Vector3(3.5, 50.0, 7.5)
	assert_true(DragonRules.is_safe_spot(true, BlockIds.SKY_GRASS, feet))
	assert_false(DragonRules.is_safe_spot(false, BlockIds.SKY_GRASS, feet), "in the air")
	assert_false(DragonRules.is_safe_spot(true, BlockIds.CLOUD, feet), "a cloud holds nobody")
	assert_false(DragonRules.is_safe_spot(true, BlockIds.AIR, feet))
	assert_false(DragonRules.is_safe_spot(true, BlockIds.WATER, feet))
	assert_false(DragonRules.is_safe_spot(true, BlockIds.STONE, Vector3(0, DragonRules.RESCUE_Y - 1.0, 0)), "under the line")


func test_the_last_safe_spot_is_remembered_at_most_every_half_second() -> void:
	var s := DragonRules.SafeSpot.new()
	assert_false(s.has, "nothing yet")
	assert_true(s.note(0.016, true, BlockIds.FLOATSTONE, Vector3(1, 50, 1)), "the first solid step counts at once")
	assert_eq(s.spot, Vector3(1, 50, 1))
	assert_false(s.note(0.2, true, BlockIds.FLOATSTONE, Vector3(2, 50, 1)), "too soon")
	assert_eq(s.spot, Vector3(1, 50, 1))
	assert_true(s.note(0.4, true, BlockIds.FLOATSTONE, Vector3(3, 50, 1)), "half a second on")
	assert_eq(s.spot, Vector3(3, 50, 1))
	assert_false(s.note(1.0, false, BlockIds.AIR, Vector3(4, 45, 1)), "falling: the island's spot stays")
	assert_eq(s.spot, Vector3(3, 50, 1))
	assert_true(s.has)
	assert_between(DragonRules.SAFE_EVERY, 0.3, 0.6)


func test_where_the_wind_carries_a_fallen_player() -> void:
	var safe := Vector3(10.5, 60.0, -3.5)
	var home := Vector3(0.5, NAN, 0.5)
	assert_eq(DragonRules.rescue_target(safe, true, true, true, home), safe, "back where it last stood")
	var ground := DragonRules.rescue_target(safe, true, false, true, home)
	assert_eq(Vector2(ground.x, ground.z), Vector2(safe.x, safe.z), "its block is gone: the same island's ground")
	assert_true(is_nan(ground.y), "on that column's ground (spawn on the surface)")
	var back := DragonRules.rescue_target(safe, true, false, false, home)
	assert_true(is_nan(back.y) and back.x == home.x and back.z == home.z, "a broken bridge over the void: home")
	var none := DragonRules.rescue_target(Vector3.ZERO, false, false, false, home)
	assert_true(none.x == home.x and none.z == home.z, "no safe spot yet (a saved game in mid-air): home")


func test_words_are_kind() -> void:
	assert_string_contains(DragonRules.CARRIED_BACK, "wind")
	assert_string_contains(DragonRules.CARRIED_BACK, "back")
	for bad in ["fell", "died", "dead", "lost", "fail"]:
		assert_false(DragonRules.CARRIED_BACK.to_lower().contains(bad), bad)


## What happens to other bodies below the line: monsters puff away, everyone else comes back.
func test_other_bodies_below_the_line() -> void:
	assert_eq(DragonRules.fate(DragonRules.MONSTER), DragonRules.PUFF)
	for kind in [DragonRules.ANIMAL, DragonRules.PET, DragonRules.BOT, DragonRules.BUDDY]:
		assert_eq(DragonRules.fate(kind), DragonRules.COME_BACK, str(kind))


func test_a_body_comes_back_next_to_its_child_or_the_spawn() -> void:
	var child := Vector3(20.5, 55.0, 4.5)
	var spawn := Vector3(0.5, 56.0, 0.5)
	var spots := {}
	for i in 8:
		var p := DragonRules.return_spot(child, true, spawn, i)
		assert_almost_eq(Vector2(p.x, p.z).distance_to(Vector2(child.x, child.z)), 1.8, 0.8, "beside the child")
		assert_eq(p.y, child.y + 1.0, "a little above, to land")
		spots[p] = true
	assert_gte(spots.size(), 4, "several fallen friends don't all land on one spot")
	var p := DragonRules.return_spot(child, false, spawn, 0)
	assert_almost_eq(Vector2(p.x, p.z).distance_to(Vector2(spawn.x, spawn.z)), 1.8, 0.8, "a child in the air: by the spawn")


# --- Cosmos (spec §21b.2): a world's own line (Venus's cloud city: the warm breeze) ---------------------------------

class HighVoid:
	var has_void := true
	var void_y := 56.0
	var void_words := "Whoosh! A warm breeze lifted you back up to the city."


func test_a_world_draws_its_own_line_and_says_its_own_words() -> void:
	assert_eq(DragonRules.rescue_y(Desc.new()), DragonRules.RESCUE_Y, "the Dragon Realm's line by default")
	assert_eq(DragonRules.rescue_y(null), DragonRules.RESCUE_Y)
	assert_eq(DragonRules.rescue_y(HighVoid.new()), 56.0, "Venus's: far over its clouds")
	assert_eq(DragonRules.carried_back_words(Desc.new()), DragonRules.CARRIED_BACK)
	assert_eq(DragonRules.carried_back_words(HighVoid.new()), "Whoosh! A warm breeze lifted you back up to the city.")
	assert_true(DragonRules.fell_into_void(55.9, 56.0))
	assert_false(DragonRules.fell_into_void(56.1, 56.0))
	assert_false(DragonRules.is_safe_spot(true, BlockIds.CLOUD_DECK, Vector3(0, 50, 0), 56.0), "under its line")
	assert_true(DragonRules.is_safe_spot(true, BlockIds.CLOUD_DECK, Vector3(0, 80, 0), 56.0))
	var s := DragonRules.SafeSpot.new()
	assert_false(s.note(0.016, true, BlockIds.VENUS_CLOUD, Vector3(1, 40, 1), 56.0), "the clouds are never a safe spot")
	assert_true(s.note(0.016, true, BlockIds.CLOUD_DECK, Vector3(1, 80, 1), 56.0))
