extends GutTest


func test_low_has_no_shadows_and_lower_resolution() -> void:
	var p := GraphicsPreset.params("low")
	assert_false(p.shadows)
	assert_lt(p.scale_3d, 1.0)


func test_medium_has_short_shadows() -> void:
	var p := GraphicsPreset.params("medium")
	assert_true(p.shadows)
	assert_eq(p.shadow_distance, 40.0)


func test_high_has_longer_shadows_and_msaa() -> void:
	var p := GraphicsPreset.params("high")
	assert_eq(p.shadow_distance, 80.0)
	assert_eq(p.msaa, Viewport.MSAA_2X)


func test_unknown_falls_back_to_medium() -> void:
	assert_eq(GraphicsPreset.params("ultra"), GraphicsPreset.params("medium"))


func test_view_distance_is_clamped() -> void:
	assert_eq(GraphicsPreset.clamp_view_distance(10), GraphicsPreset.MIN_VIEW_DISTANCE)
	assert_eq(GraphicsPreset.clamp_view_distance(9999), GraphicsPreset.MAX_VIEW_DISTANCE)
	assert_eq(GraphicsPreset.clamp_view_distance(128), 128)


## Owner-facing FPS (M1b): a surface player must not stream the whole underground (every cave chunk
## down to bedrock); a player in a cave still gets everything around them; and a player flying high
## (found on the emulator: the ground vanished) still streams the ground below.
func test_vertical_streaming_range() -> void:
	var surface := GraphicsPreset.vertical_range(30.0, 30, 128)
	assert_gte(surface.y, float(MeadowsShape.MAX_HEIGHT), "the tallest mountains stay visible")
	assert_gte(surface.x, -10.0, "no deep caves loaded from the surface")
	var cave := GraphicsPreset.vertical_range(-40.0, 60, 128)
	assert_lte(cave.x, float(MeadowsShape.WORLD_BOTTOM), "down to bedrock from a deep cave")
	assert_gte(cave.y, 40.0, "and up to the surface")
	var near := GraphicsPreset.vertical_range(30.0, 30, GraphicsPreset.MIN_VIEW_DISTANCE)
	assert_lte(near.x, 30.0 - 12.0, "always some ground below the feet")


func test_flying_high_still_streams_the_ground() -> void:
	var high := GraphicsPreset.vertical_range(150.0, 30, 128)
	assert_lte(high.x, 30.0 - 12.0, "the ground below a high flyer is streamed")
	var sea := GraphicsPreset.vertical_range(80.0, MeadowsShape.SEA_LEVEL, 128)
	assert_lte(sea.x, MeadowsShape.SEA_LEVEL - 12.0, "and the sea below")


## Review I2: on a mountain top the box started 24 blocks under the feet, so the valleys and the
## sea below vanished. The surface world is always streamed from under the sea level up.
func test_a_mountain_top_still_streams_the_valley_and_the_sea() -> void:
	var peak := GraphicsPreset.vertical_range(95.0, 95, 128)
	assert_lte(peak.x, MeadowsShape.SEA_LEVEL - 12.0, "the sea below a peak is streamed")
	assert_gte(peak.y, float(MeadowsShape.MAX_HEIGHT), "and so is the peak itself")
	var near := GraphicsPreset.vertical_range(95.0, 95, GraphicsPreset.MIN_VIEW_DISTANCE)
	assert_lte(near.x, MeadowsShape.SEA_LEVEL - 12.0, "at the shortest view distance too")
	assert_gte(near.y, 95.0 + 2.0, "without losing the ground under the feet")
