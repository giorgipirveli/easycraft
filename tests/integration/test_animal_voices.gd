extends GutTest
## Real animal voices (owner 2026-09-24 20:42: "animals should have sounds, like real ones"): a petted or
## fed animal makes its happy sound, a pushed one its hurt voice, every animal in its own voice
## (VoiceRules.voice_pitch). Its idle calls are the AnimalChorus's (owner #50, test_animal_chorus.gd).


func _animal(species: StringName, id: String = "") -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id if id != "" else "v_%s" % species, "pos": Vector3(1, 40, 2),
		"yaw": 0.0, "owner": 0, "name": "", "sitting": false})
	add_child_autofree(a)
	return a


func after_all() -> void:
	Audio.stop_all()


func test_a_petted_animal_makes_its_happy_sound_in_its_own_voice() -> void:
	for species: StringName in AnimalRules.SPECIES:
		var a := _animal(species)
		var before: int = Audio.played
		a.cheer()
		assert_eq(Audio.played, before + 1, String(species))
		assert_eq(Audio.last_sound, VoiceRules.animal_happy(species), String(species))
		assert_almost_eq(float(Audio.last_voice_pitch), VoiceRules.voice_pitch(a.animal_id), 0.001, String(species))


func test_a_pushed_animal_cries_out() -> void:
	for species: StringName in AnimalRules.SPECIES:
		var a := _animal(species)
		a.knockback(Vector3(2, 0, 0))
		assert_eq(Audio.last_sound, VoiceRules.animal_hurt(species), String(species))


# Idle calls (now and then within 20 blocks): owner feedback #50 moved them to one AnimalChorus per device,
# tested in test_animal_chorus.gd.


func test_two_animals_of_a_kind_sound_different() -> void:
	var a := _animal(&"dog", "rex")
	var b := _animal(&"dog", "fido")
	a.cheer()
	var pa: float = Audio.last_voice_pitch
	b.cheer()
	assert_ne(pa, Audio.last_voice_pitch)
