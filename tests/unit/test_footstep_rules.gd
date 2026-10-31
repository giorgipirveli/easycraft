extends GutTest
## Footsteps by block (the audio pass, owner feedback #27; spec §15.2 "footsteps per block type"): grass
## rustles, dirt and sand crunch softly, stone and brick knock, wood thuds, leaves crackle, snow creaks,
## glass and crystal tink, the coloured blocks are soft like cloth, and wet feet wade (M2 Task 14).

var _sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS


func test_each_ground_has_its_own_step() -> void:
	assert_eq(FootstepRules.sound(BlockIds.GRASS), &"step")
	assert_eq(FootstepRules.sound(BlockIds.DIRT), &"step_dirt")
	assert_eq(FootstepRules.sound(BlockIds.STONE), &"step_stone")
	assert_eq(FootstepRules.sound(BlockIds.BRICK), &"step_stone")
	assert_eq(FootstepRules.sound(BlockIds.DEEPSTONE), &"step_stone")
	assert_eq(FootstepRules.sound(BlockIds.SAND), &"step_sand")
	assert_eq(FootstepRules.sound(BlockIds.RED_SAND), &"step_sand")
	assert_eq(FootstepRules.sound(BlockIds.PLANKS), &"step_wood")
	assert_eq(FootstepRules.sound(BlockIds.LOG), &"step_wood")
	assert_eq(FootstepRules.sound(BlockIds.LEAVES), &"step_leaves")
	assert_eq(FootstepRules.sound(BlockIds.GLASS), &"step_glass")
	assert_eq(FootstepRules.sound(BlockIds.RED), &"step_cloth")
	assert_eq(FootstepRules.sound(BlockIds.SANDSTONE), &"step_stone")


func test_wet_feet_wade_whatever_the_ground() -> void:
	assert_eq(FootstepRules.sound(BlockIds.STONE, true), &"step_wet")
	assert_eq(FootstepRules.sound(BlockIds.GRASS, true), &"step_wet")
	assert_eq(FootstepRules.sound(BlockIds.WATER), &"step_wet")


func test_frostpeak_blocks_crunch_like_snow() -> void:
	for id in range(FootstepRules.FROST_FIRST, FootstepRules.FROST_LAST + 1):
		assert_eq(FootstepRules.sound(id), &"step_snow", str(id))


func test_air_and_unknown_blocks_fall_back_to_the_grass_step() -> void:
	assert_eq(FootstepRules.sound(BlockIds.AIR), &"step")
	assert_eq(FootstepRules.sound(999), &"step")


func test_every_placeable_block_has_a_step_that_audio_knows() -> void:
	for id: int in BlockIds.PLACEABLE:
		var s := FootstepRules.sound(id)
		assert_true(_sounds.has(s), "%s: %s" % [BlockIds.display_name(id), s])
		assert_gte((_sounds.get(s, []) as Array).size(), 2, "%s: steps vary (%s)" % [BlockIds.display_name(id), s])
