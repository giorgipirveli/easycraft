extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 2; docs/devlog/parts/vr-r4-wonder.md): LensRules, the telescope and the
## magnifier. The zoom over the trigger, the lens's field of view (what the disc covers of the eye's view, over the zoom:
## the zoom happens only inside the lens, ruling R7), the steady filter (a zoomed tremor is smoothed), the magnifier's
## close-ups (a picture and a fact for the blocks a child looks at) and the two items (VR only).


func test_the_items_are_the_telescope_500_and_the_magnifier_501() -> void:
	assert_eq(ItemIds.TELESCOPE, 500)
	assert_eq(ItemIds.MAGNIFIER, 501)
	assert_eq(ItemIds.LENSES, [ItemIds.TELESCOPE, ItemIds.MAGNIFIER] as Array[int])
	assert_eq(ItemIds.display_name(ItemIds.TELESCOPE), "Telescope")
	assert_eq(ItemIds.display_name(ItemIds.MAGNIFIER), "Magnifier")
	assert_eq(LensRules.kind_of(ItemIds.TELESCOPE), LensRules.TELESCOPE)
	assert_eq(LensRules.kind_of(ItemIds.MAGNIFIER), LensRules.MAGNIFIER)
	assert_eq(LensRules.kind_of(ItemIds.WAND), &"")


## Off VR nothing changes: the lenses are in no palette row, chest or shop (ItemIds.ALL is as before); a hotbar may
## hold one (a VR palette put it there), never as a block, never counted in Survivor.
func test_the_lenses_are_items_but_not_in_the_catalogue() -> void:
	for id: int in ItemIds.LENSES:
		assert_false(ItemIds.ALL.has(id), "not in ALL: off VR the palettes, chests and shops stay as they were")
		assert_true(ItemIds.is_item(id))
		assert_true(ItemIds.is_lens(id))
		assert_true(ItemIds.is_hotbar_valid(id))
		assert_false(BlockIds.is_valid(id), "never a block")
		assert_true(ItemIds.is_free_tool(id), "a learning tool: never counted or faded in Survivor")
		assert_false(ItemIds.is_stamp(id))
	assert_false(ItemIds.is_lens(ItemIds.WAND))
	assert_false(ItemIds.is_lens(ItemIds.MY_STAMP_FIRST + 4), "499 is still a stamp slot")


func test_each_lens_has_its_own_icon() -> void:
	var t := BlockIcons.icon(ItemIds.TELESCOPE)
	var m := BlockIcons.icon(ItemIds.MAGNIFIER)
	assert_not_null(t)
	assert_not_null(m)
	assert_same(BlockIcons.icon(ItemIds.TELESCOPE), t, "made once")
	assert_eq(t.get_size(), Vector2(32, 32))
	var a := t.get_image()
	var b := m.get_image()
	var differ := 0
	var filled := 0
	for y in 32:
		for x in 32:
			if a.get_pixel(x, y).a > 0.5:
				filled += 1
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				differ += 1
	assert_gt(filled, 80, "a picture, not a speck")
	assert_gt(differ, 80, "two different pictures")


func test_the_trigger_zooms_the_telescope_from_2x_to_8x_and_the_magnifier_less() -> void:
	assert_almost_eq(LensRules.zoom(LensRules.TELESCOPE, 0.0), 2.0, 0.001)
	assert_almost_eq(LensRules.zoom(LensRules.TELESCOPE, 1.0), 8.0, 0.001, "the lens at 8x")
	assert_almost_eq(LensRules.zoom(LensRules.TELESCOPE, 0.5), 5.0, 0.001)
	assert_almost_eq(LensRules.zoom(LensRules.MAGNIFIER, 0.0), 2.0, 0.001)
	assert_almost_eq(LensRules.zoom(LensRules.MAGNIFIER, 1.0), 4.0, 0.001)
	assert_almost_eq(LensRules.zoom(LensRules.TELESCOPE, 3.0), 8.0, 0.001, "clamped")


## R7: the lens's camera sees the part of the world the disc covers, narrowed by the zoom (an 8 cm lens 40 cm from the
## eyes covers 11.4 degrees: at 8x its camera sees 1.4 degrees).
func test_the_lens_field_of_view_is_what_the_disc_covers_over_the_zoom() -> void:
	var cover := rad_to_deg(2.0 * atan(0.04 / 0.4))
	assert_almost_eq(LensRules.fov_degrees(0.04, 0.4, 1.0), cover, 0.01)
	assert_almost_eq(LensRules.fov_degrees(0.04, 0.4, 8.0), cover / 8.0, 0.01)
	assert_almost_eq(LensRules.fov_degrees(0.04, 0.4, 2.0), cover / 2.0, 0.01)
	assert_gte(LensRules.fov_degrees(0.04, 5.0, 8.0), LensRules.MIN_FOV, "never under the camera's least")
	assert_almost_eq(LensRules.fov_degrees(0.04, 0.0, 2.0), LensRules.fov_degrees(0.04, LensRules.MIN_EYE, 2.0), 0.001,
		"at the eye: as at MIN_EYE")


func test_the_steady_filter_smooths_a_tremor_more_at_a_higher_zoom() -> void:
	var still := Basis()
	var shaken := Basis(Vector3.UP, deg_to_rad(2.0))
	var at2 := LensRules.steady(still, shaken, 1.0 / 72.0, 2.0)
	var at8 := LensRules.steady(still, shaken, 1.0 / 72.0, 8.0)
	var a2 := rad_to_deg(still.get_rotation_quaternion().angle_to(at2.get_rotation_quaternion()))
	var a8 := rad_to_deg(still.get_rotation_quaternion().angle_to(at8.get_rotation_quaternion()))
	assert_gt(a2, 0.0, "it follows")
	assert_lt(a2, 2.0, "but not all the way in a frame")
	assert_lt(a8, a2, "steadier at 8x")
	var b := still
	for i in 72:
		b = LensRules.steady(b, shaken, 1.0 / 72.0, 8.0)
	assert_almost_eq(rad_to_deg(b.get_rotation_quaternion().angle_to(shaken.get_rotation_quaternion())), 0.0, 0.1,
		"a second later it is there")


func test_the_magnifier_has_a_close_up_and_a_fact_for_the_ground_a_child_meets() -> void:
	for id: int in [BlockIds.GRASS, BlockIds.DIRT, BlockIds.SAND, BlockIds.STONE, BlockIds.LOG, BlockIds.PLANKS,
			BlockIds.LEAVES, BlockIds.SNOW, BlockIds.ICE, BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.CACTUS,
			BlockIds.GLASS, BlockIds.BRICK]:
		var c := LensRules.closeup(id)
		assert_false(c.is_empty(), "%s has a close-up" % BlockIds.display_name(id))
		assert_true(LensRules.PICTURES.has(c.get("picture", &"")), "%s's picture is drawn" % BlockIds.display_name(id))
	assert_eq(LensRules.closeup(BlockIds.AIR), {})
	assert_eq(LensRules.closeup(BlockIds.WATER), {}, "water: the plain view")
	assert_eq(str(LensRules.closeup(BlockIds.SAND).fact), "Sand is tiny bits of rock and shell, worn down by water and wind.")


func test_every_fact_is_short_plain_and_ends_with_a_full_stop() -> void:
	for id: int in LensRules.CLOSEUPS:
		var c := LensRules.closeup(id)
		var fact := str(c.fact)
		assert_lte(fact.length(), LensRules.MAX_FACT, fact)
		assert_true(fact.ends_with("."), fact)
		assert_true(str(c.name).length() > 0 and str(c.name).length() <= 16, str(c.name))
		for ch: String in ["’", "“", "”", "!"]:
			assert_false(fact.contains(ch), "plain letters: %s" % fact)
		assert_true(BlockIds.is_valid(id), "a real block: %d" % id)


func test_the_close_up_shows_only_near_the_glass() -> void:
	assert_true(LensRules.shows_closeup(0.1))
	assert_true(LensRules.shows_closeup(LensRules.CLOSE_RANGE))
	assert_false(LensRules.shows_closeup(LensRules.CLOSE_RANGE + 0.01), "further: the magnified world alone")
	assert_false(LensRules.shows_closeup(-1.0), "no block")


## Every wonder teaches: the School's units the lenses link to are real, written units.
func test_the_lenses_link_to_written_school_units() -> void:
	Curriculum.clear_cache()
	assert_gt(LensRules.UNITS.size(), 3)
	for id: String in LensRules.UNITS:
		assert_false(Curriculum.unit(id).is_empty(), "%s is a School unit" % id)
		assert_true(Curriculum.has_content(id), "%s has its lessons written" % id)
