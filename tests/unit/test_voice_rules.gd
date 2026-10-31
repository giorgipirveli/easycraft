extends GutTest
## Animal and monster voices (the audio pass, owner feedback #27 and 2026-09-24 20:42: "animals should
## have sounds, like real ones"): every animal has its call (2-3 real recordings so they don't repeat),
## a hurt voice and a happy one; every animal sounds a little different (its own pitch, higher when
## small); idle calls reach 20 blocks; every monster has an idle voice and a hurt voice.

const LAND := [&"dog", &"cat", &"pig", &"cow", &"sheep", &"chicken", &"rabbit"]

var _sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS


func _files(sound: StringName) -> Array:
	return _sounds.get(sound, [])


func test_every_animal_has_a_call_a_hurt_voice_and_a_happy_voice() -> void:
	for species: StringName in AnimalRules.SPECIES:
		for sound: StringName in [VoiceRules.animal_call(species), VoiceRules.animal_hurt(species),
				VoiceRules.animal_happy(species)]:
			assert_ne(sound, &"", "%s has a voice" % species)
			assert_false(_files(sound).is_empty(), "%s: Audio knows %s" % [species, sound])


func test_the_call_is_the_species_own_sound() -> void:
	for species: StringName in AnimalRules.SPECIES:
		assert_eq(VoiceRules.animal_call(species), AnimalRules.SPECIES[species].sound)


func test_land_animals_have_two_or_three_real_recordings_of_their_call() -> void:
	for species: StringName in LAND:
		var files := _files(VoiceRules.animal_call(species))
		assert_between(files.size(), 2, 4, "%s: %d takes" % [species, files.size()])
		for path: String in files:
			assert_true(path.ends_with(".ogg"), "%s is a recording (ogg), not the old synthesised wav" % path)


func test_hurt_and_happy_voices_differ_from_the_call_where_the_animal_has_one() -> void:
	for species: StringName in LAND:
		assert_ne(VoiceRules.animal_hurt(species), VoiceRules.animal_call(species), String(species))
	assert_eq(VoiceRules.animal_happy(&"cat"), &"purr", "a petted cat purrs")
	assert_eq(VoiceRules.animal_happy(&"dog"), &"dog_happy", "a petted dog whines happily")


func test_unknown_animals_are_silent() -> void:
	assert_eq(VoiceRules.animal_call(&"griffin"), &"")   # owner 39: the dragon is an animal now (the pet dragon)
	assert_eq(VoiceRules.animal_hurt(&"griffin"), &"")
	assert_eq(VoiceRules.animal_happy(&"griffin"), &"")


func test_idle_calls_reach_twenty_blocks_now_and_then() -> void:
	assert_eq(VoiceRules.CALL_RADIUS, 20.0)
	# owner feedback #50: one chorus per device chooses them (test_animal_chorus_rules.gd)
	assert_gte(AnimalChorusRules.GAP_MIN, 6.0, "now and then, not all the time")


func test_every_animal_has_its_own_voice_pitch_the_same_every_time() -> void:
	var pitches := {}
	for i in 40:
		var p := VoiceRules.voice_pitch("animal_%d" % i)
		assert_between(p, 0.86, 1.14)
		assert_eq(p, VoiceRules.voice_pitch("animal_%d" % i), "the same animal sounds the same")
		pitches[snappedf(p, 0.01)] = true
	assert_gt(pitches.size(), 10, "animals sound different from each other")


func test_smaller_animals_sound_higher() -> void:
	assert_gt(VoiceRules.voice_pitch("a", 0.5), VoiceRules.voice_pitch("a", 1.0))
	assert_lt(VoiceRules.voice_pitch("a", 2.0), VoiceRules.voice_pitch("a", 1.0))
	assert_between(VoiceRules.voice_pitch("a", 0.01), 0.5, 2.0, "never squeaky beyond words")
	assert_between(VoiceRules.voice_pitch("a", 100.0), 0.5, 2.0)


func test_every_monster_kind_has_an_idle_voice_and_a_hurt_voice() -> void:
	for kind: StringName in MonsterRules.KIND:
		for sound: StringName in [VoiceRules.monster_idle(kind), VoiceRules.monster_hurt(kind)]:
			assert_ne(sound, &"", String(kind))
			assert_false(_files(sound).is_empty(), "%s: Audio knows %s" % [kind, sound])
	assert_eq(VoiceRules.monster_idle(MonsterRules.GOBLIN), &"grunt", "goblins grunt")
	assert_eq(VoiceRules.monster_idle(MonsterRules.SLIME), &"squish", "slimes squish")


## M5 Task 2: monsters no longer roll their own timers; the chorus's budget (test_monster_chorus_rules.gd).
func test_monster_idle_voices_come_now_and_then() -> void:
	assert_gte(MonsterChorusRules.GAP_MIN, 4.0, "never a stream of grunts")
	assert_gte(MonsterChorusRules.KIND_REST, 10.0)
