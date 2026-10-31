extends GutTest


func test_every_sound_file_loads() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	assert_gt(sounds.size(), 0)
	for key: StringName in sounds:
		for path: String in sounds[key]:
			assert_not_null(load(path), path)


func test_every_block_has_an_opaque_particle_color() -> void:
	for id in BlockIds.PLACEABLE:
		var c := BlockLibrary.average_color(id)
		assert_gt(c.a, 0.5, BlockIds.display_name(id))


func test_grass_particles_are_greenish() -> void:
	var c := BlockLibrary.average_color(BlockIds.GRASS)
	assert_gt(c.g, c.r)


## M2 Task 11 (§12.10): coin pickups (Tasks 4, 9, 10) play Audio's "coin".
func test_there_is_a_coin_sound_for_pickups() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	assert_has(sounds, &"coin")
