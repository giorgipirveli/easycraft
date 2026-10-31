extends GutTest
## Block targeting by walking the grid cell by cell (water is targetable too).

var cells := {}


func _target(p: Vector3i) -> bool:
	return cells.has(p)


func before_each() -> void:
	cells.clear()


func test_hits_the_first_block_and_reports_the_cell_before_it() -> void:
	cells[Vector3i(5, 0, 0)] = true
	cells[Vector3i(8, 0, 0)] = true
	var hit := GridRay.cast(Vector3(0.5, 0.5, 0.5), Vector3.RIGHT, 20.0, _target)
	assert_eq(hit.position, Vector3i(5, 0, 0))
	assert_eq(hit.previous_position, Vector3i(4, 0, 0))


func test_negative_directions() -> void:
	cells[Vector3i(-3, -2, 0)] = true
	var hit := GridRay.cast(Vector3(0.5, 0.5, 0.5), Vector3(-1, -0.66, 0).normalized(), 20.0, _target)
	assert_not_null(hit)
	assert_eq(hit.position, Vector3i(-3, -2, 0))


func test_misses_beyond_max_distance() -> void:
	cells[Vector3i(30, 0, 0)] = true
	assert_null(GridRay.cast(Vector3(0.5, 0.5, 0.5), Vector3.RIGHT, 10.0, _target))


func test_ray_length_covers_a_far_camera() -> void:
	var giant_camera := Vector3(0, 9, 13.5)
	var eye := Vector3(0, 4.6, 0)
	assert_gte(PlacementRules.ray_length(giant_camera, eye), giant_camera.distance_to(eye) + PlacementRules.REACH)


func test_first_person_taps_use_the_crosshair() -> void:
	var screen := Vector2(1600, 720)
	assert_eq(LookBuildArea.target_point(Vector2(100, 600), true, screen), Vector2(800, 360))
	assert_eq(LookBuildArea.target_point(Vector2(100, 600), false, screen), Vector2(100, 600))


## Found with the oceans (M1b): underwater, every tap hit the water block in front of the face.
## A ray that starts in water passes through water; from above, water is still a target.
func test_rays_from_inside_water_see_through_water() -> void:
	assert_false(GridRay.stops_ray(BlockIds.WATER, true))
	assert_true(GridRay.stops_ray(BlockIds.SAND, true))
	assert_true(GridRay.stops_ray(BlockIds.WATER, false), "build on the water surface from above")
	assert_false(GridRay.stops_ray(BlockIds.AIR, false))
