extends GutTest
## Owner feedback #39 (spec §14.2a): the pet dragon. A PetRules kind given, never wild (a dragon egg hatches one, the
## Sky Dragon gives a baby dragon that lives in the profile like Pip); it follows its child on the ground and flies
## (glides) beside them when they are up in the air; it never fights anyone; it never takes a pet place.


func test_the_dragon_is_a_pet_kind_with_a_body_a_look_and_a_mind() -> void:
	assert_true(PetRules.is_pet_kind(PetRules.DRAGON))
	assert_false(PetRules.tames_by_petting(PetRules.DRAGON), "never wild: hatched or given")
	assert_false(PetRules.tames_by_treats(PetRules.DRAGON))
	assert_false(PetRules.counts_toward_cap(PetRules.DRAGON), "a gift never takes one of the three pet places")
	assert_true(PetRules.has_perk(PetRules.DRAGON, PetRules.GLIDE), "it glides with its child")
	assert_true(ItemIds.TREATS.has(PetRules.favourite(PetRules.DRAGON)), "a favourite treat Tilly sells")
	assert_true(AnimalRules.SPECIES.has(PetRules.DRAGON), "a body")
	assert_eq(int(AnimalRules.SPECIES[PetRules.DRAGON].weight), 0, "never picked for a wild herd")
	assert_true(bool(AnimalRules.SPECIES[PetRules.DRAGON].get("flies", false)))
	assert_true(BlockyAnimal.COLLAR.has(PetRules.DRAGON), "a collar")
	assert_not_null(BlockyAnimal.mesh_for(PetRules.DRAGON))
	assert_not_null(BlockyAnimal.part_mesh_for(PetRules.DRAGON), "wings that flap")
	assert_true(AnimalSpecies.TRAITS.has(PetRules.DRAGON))
	assert_eq(AnimalRules.DROPS.get(PetRules.DRAGON), [], "it leaves nothing")


func test_it_has_a_voice_audio_knows() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for s: StringName in [VoiceRules.animal_call(PetRules.DRAGON), VoiceRules.animal_hurt(PetRules.DRAGON)]:
		assert_ne(s, &"")
		assert_false((sounds.get(s, []) as Array).is_empty(), String(s))


func test_it_glides_only_when_its_child_is_up_in_the_air() -> void:
	assert_false(PetRules.glides(true, true, 0.0), "both on the ground: it walks")
	assert_false(PetRules.glides(true, false, 0.6), "a small jump: it hops along")
	assert_true(PetRules.glides(true, false, 3.0), "the child flies or glides up: it takes off")
	assert_true(PetRules.glides(false, false, 0.5), "flying already and the child still up: it keeps flying")
	assert_false(PetRules.glides(false, true, 0.0), "the child landed: it lands too")


func test_it_flies_beside_its_child_never_faster_than_it_may() -> void:
	var owner := Vector3(10, 50, 10)
	var spot := PetRules.glide_spot(owner, 0.0)
	assert_between(spot.distance_to(owner), 1.2, 2.5, "beside the child")
	assert_gt(spot.y, owner.y, "a little higher")
	var right := PetRules.glide_spot(owner, PI * 0.5)
	assert_almost_eq(right.distance_to(owner), spot.distance_to(owner), 0.001, "turning with the child")
	var far := PetRules.glide_velocity(Vector3(0, 40, 0), spot)
	assert_almost_eq(far.length(), PetRules.GLIDE_SPEED, 0.01, "catching up at its top speed")
	var near := PetRules.glide_velocity(spot + Vector3(0.1, 0, 0), spot)
	assert_lt(near.length(), 1.0, "it settles at the spot")
	assert_lte(PetRules.GLIDE_SPEED, Player.FLY_SPEED * 1.5, "never a rocket")


func test_the_baby_dragon_record_is_a_pets_record() -> void:
	var r := PetRules.baby_dragon_record()
	assert_eq(str(r.name), PetRules.BABY_DRAGON_NAME)
	assert_eq(PetRules.clean_pip(r), r, "cleaned like Pip's")
	var p := ProfileData.new()
	assert_true(PetRules.give_baby_dragon(p), "the first time")
	assert_false(PetRules.give_baby_dragon(p), "never twice")
	p.baby_dragon.name = "Sparky"
	assert_false(PetRules.give_baby_dragon(p))
	assert_eq(str(p.baby_dragon.name), "Sparky", "a named baby dragon is never renamed")
