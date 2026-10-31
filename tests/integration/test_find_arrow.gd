extends GutTest
## Owner feedback #40: /find's arrow points the way, says how far, says when you got there, gives way to
## the treasure map's compass and goes away after a while.

var arrow: FindArrow


func before_each() -> void:
	arrow = FindArrow.new()
	add_child_autofree(arrow)


func test_points_the_way_with_the_distance() -> void:
	assert_false(arrow.is_pointing())
	arrow.point_to("Tilly", Vector3(0, 64, -42))
	assert_true(arrow.is_pointing())
	arrow.update(Vector3(0, 64, 0), 0.0)
	assert_almost_eq(arrow.angle, 0.0, 0.001, "straight ahead (yaw 0 looks along -Z)")
	assert_eq(arrow.distance, 42)
	arrow.update(Vector3(0, 64, 0), PI * 0.5)   # turned left: Tilly is now on the right
	assert_gt(arrow.angle, 1.0)


func test_getting_there_says_so_and_stops() -> void:
	var found: Array = []
	arrow.arrived.connect(func(what: String) -> void: found.append(what))
	arrow.point_to("your bed", Vector3(10, 64, 10))
	arrow.update(Vector3(9, 64, 9), 0.0)
	assert_eq(found, ["your bed"])
	assert_false(arrow.is_pointing())
	assert_false(arrow.visible)


func test_it_goes_away_after_a_while_or_without_a_player() -> void:
	arrow.point_to("Tilly", Vector3(0, 64, -42))
	arrow.tick(0.1)
	assert_false(arrow.is_pointing(), "no player in the world: nothing to point from")
	arrow.point_to("Tilly", Vector3(0, 64, -42))
	arrow.stop()
	assert_false(arrow.visible)


func test_it_gives_way_to_the_treasure_compass_and_takes_no_touch() -> void:
	assert_eq(arrow.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var spot: Array = HudLayout.SPOTS[&"compass"]
	assert_eq(arrow.anchor_left, (spot[0] as Vector2).x, "the compass's spot")
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0, 64, 0)
	arrow.player = p
	var map_shows := [false]
	arrow.covered = func() -> bool: return map_shows[0]
	arrow.point_to("Tilly", Vector3(0, 64, -42))
	arrow.tick(0.1)
	assert_true(arrow.visible)
	map_shows[0] = true
	arrow.tick(0.1)
	assert_false(arrow.visible, "the map's compass has the spot")
	assert_true(arrow.is_pointing(), "it waits")
	map_shows[0] = false
	arrow.tick(FindArrow.SHOW_SECONDS)
	assert_false(arrow.is_pointing(), "gone after SHOW_SECONDS")
