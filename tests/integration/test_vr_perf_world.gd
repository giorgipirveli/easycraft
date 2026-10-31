extends GutTest
## P5 (owner #108): a world in a headset session follows the VR preset in use: `vr` shows the blocky style and no sun
## shadows; `vr_plus` (a Quest 3) the child's style (REALISTIC allowed) with near sun shadows; glow never in a session.
## Off VR a world is exactly as before.

var world: WorldService


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 7)
	add_child_autofree(world)


func after_each() -> void:
	GraphicsPreset.vr_session = false
	GraphicsPreset.headset = ""
	BlockLibrary.set_style("blocky")


func test_vr_shows_blocky_and_vr_plus_the_childs_realistic() -> void:
	GraphicsPreset.vr_session = true
	world.apply_graphics({"graphics": "vr", "view_distance": 128})
	world.apply_style("realistic")
	assert_eq(BlockLibrary.style, "blocky", "Quest 2's preset: blocky only")
	world.apply_graphics({"graphics": "vr_plus", "view_distance": 128})
	world.apply_style("realistic")
	assert_eq(BlockLibrary.style, "realistic", "vr_plus: REALISTIC allowed")
	assert_false(world.environment().glow_enabled, "no glow in a headset")


func test_a_quest_3_that_never_picked_shows_realistic_with_near_shadows() -> void:
	GraphicsPreset.vr_session = true
	GraphicsPreset.headset = "Quest 3"
	world.apply_graphics({"graphics": "medium", "view_distance": 128})
	world.apply_style("realistic")
	assert_eq(BlockLibrary.style, "realistic")
	assert_true(world.sun().shadow_enabled, "vr_plus's near sun shadows")
	assert_eq(world.sun().directional_shadow_max_distance, 24.0)
	assert_eq(world.environment().fog_depth_end, 80.0, "vr_plus's 80-block view")
	GraphicsPreset.headset = "Quest 2"
	world.apply_graphics({"graphics": "medium", "view_distance": 128})
	world.apply_style("realistic")
	assert_eq(BlockLibrary.style, "blocky")
	assert_false(world.sun().shadow_enabled)


func test_off_vr_a_world_is_as_before() -> void:
	world.apply_graphics({"graphics": "medium", "view_distance": 128})
	world.apply_style("realistic")
	assert_eq(BlockLibrary.style, "realistic")
	assert_true(world.environment().glow_enabled, "REALISTIC's glow, as before")
	assert_true(world.sun().shadow_enabled)
	assert_eq(world.sun().directional_shadow_max_distance, 40.0)


func test_the_menus_backdrop_streams_32_cube_blocks_in_vr() -> void:
	# Nothing walks on the menu's backdrop (its viewer builds no collisions), so the collision stutter of 32-cube blocks
	# never comes; with 16-cube ones its 96-block view drew 191 a frame in a headset. A played world: 16.
	GraphicsPreset.vr_session = true
	var backdrop: WorldService = load("res://world/world.tscn").instantiate()
	backdrop.setup("", 5)
	add_child_autofree(backdrop)
	assert_eq(backdrop.terrain().mesh_block_size, 32, "the menu's backdrop (no save folder, not a guest's world)")
	var guest: WorldService = load("res://world/world.tscn").instantiate()
	guest.setup("", 5, true)
	add_child_autofree(guest)
	assert_eq(guest.terrain().mesh_block_size, 16, "a guest walks in its world")
	GraphicsPreset.vr_session = false
	var phone: WorldService = load("res://world/world.tscn").instantiate()
	phone.setup("", 5)
	add_child_autofree(phone)
	assert_eq(phone.terrain().mesh_block_size, 16, "off VR as before")
