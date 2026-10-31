extends GutTest
## Where a sleeping buddy's blocks land: never inside a player, rising over slopes, else refused.

var solid := {}
var blocks := {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.RED, Vector3i(0, 1, 0): BlockIds.BLUE}


func _is_solid(p: Vector3i) -> bool:
	return solid.has(p)


func before_each() -> void:
	solid.clear()
	for x in range(-5, 6):
		for z in range(-5, 6):
			solid[Vector3i(x, 9, z)] = true   # ground top at y = 9, free from y = 10


func test_flat_ground_uses_the_buddy_spot() -> void:
	var r := SleepRules.find_base(Vector3(1.0, 10.0, 0.5), Vector3i(2, 2, 1), blocks, _is_solid, [])
	assert_eq(r.base, Vector3i(0, 10, 0))


func test_slope_rises_until_every_block_fits() -> void:
	solid[Vector3i(1, 10, 0)] = true   # a bump under the buddy's right foot
	var r := SleepRules.find_base(Vector3(1.0, 10.0, 0.5), Vector3i(2, 2, 1), blocks, _is_solid, [])
	assert_eq(r.base, Vector3i(0, 11, 0))


func test_player_inside_the_footprint_is_refused() -> void:
	var bodies: Array[AABB] = [PlacementRules.player_aabb(Vector3(0.5, 10.0, 0.5))]
	var r := SleepRules.find_base(Vector3(1.0, 10.0, 0.5), Vector3i(2, 2, 1), blocks, _is_solid, bodies)
	assert_eq(r.error, "player_in_the_way")


func test_every_error_has_a_message() -> void:
	for code in ["player_in_the_way", "no_room", "too_far", "not_yours"]:
		assert_ne(SleepRules.message(code), "", code)
