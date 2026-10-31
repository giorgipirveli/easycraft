extends GutTest
## The perks of pets (M3 Task 11, spec §14.7): only a tamed pet near its owner has one. A cat (and Pip)
## glows softly in caves and at night (one shared light for the nearest one), a dog pulls coins within 4
## blocks to its owner and barks when a monster comes within 16, a fox sniffs out buried treasure, a
## parrot points its beak at the nearest secret nobody found within 24 blocks.

const OWNER := Vector3(0, 10, 0)


# --- Only tamed pets near their owner ---

func test_perks_only_for_a_tamed_pet_near_its_owner() -> void:
	assert_true(PetPerks.active(true, Vector3(3, 10, 0), OWNER))
	assert_true(PetPerks.active(true, Vector3(PetPerks.NEAR_OWNER - 0.5, 10, 0), OWNER))
	assert_false(PetPerks.active(true, Vector3(PetPerks.NEAR_OWNER + 0.5, 10, 0), OWNER), "too far from its owner")
	assert_false(PetPerks.active(false, Vector3(3, 10, 0), OWNER), "a wild animal has no perk")
	assert_false(PetPerks.active(true, Vector3(3, 10, 0), Vector3.INF), "its owner left the game")
	assert_true(PetPerks.active(true, Vector3(3, 40, 0), OWNER), "sideways distance: a pet on a cliff above still helps")


# --- Glow ---

func test_a_cat_glows_in_caves_and_at_night_only() -> void:
	assert_true(PetPerks.glows(&"cat", 0.8, false), "in a cave")
	assert_true(PetPerks.glows(&"cat", 0.0, true), "at night")
	assert_false(PetPerks.glows(&"cat", 0.1, false), "not in the daylight")
	assert_true(PetPerks.glows(&"pip", 1.0, false), "Pip's lamp too")
	assert_false(PetPerks.glows(&"dog", 1.0, true), "dogs don't glow")


func test_the_one_light_goes_to_the_nearest_glowing_pet() -> void:
	var cats: Array[Vector3] = [Vector3(10, 0, 0), Vector3(3, 0, 1), Vector3(-6, 0, 0)]
	assert_eq(PetPerks.glow_pick(Vector3.ZERO, cats), 1)
	assert_eq(PetPerks.glow_pick(Vector3.ZERO, [Vector3(PetPerks.GLOW_RANGE + 1, 0, 0)] as Array[Vector3]), -1,
		"too far to light anything the player sees")
	assert_eq(PetPerks.glow_pick(Vector3.ZERO, [] as Array[Vector3]), -1)


# --- Coins ---

func test_a_dog_pulls_coins_within_4_blocks_to_its_owner() -> void:
	var dogs: Array[Vector3] = [Vector3(5, 10, 0), Vector3(-20, 10, 0)]
	var owners: Array[int] = [7, 9]
	assert_eq(PetPerks.coin_owner(Vector3(7, 10, 1), dogs, owners), 7)
	assert_eq(PetPerks.coin_owner(Vector3(5 + PetPerks.COIN_PULL + 0.2, 10, 0), dogs, owners), 0, "just out of reach")
	assert_eq(PetPerks.coin_owner(Vector3(-17, 10, 0), dogs, owners), 9, "the other child's dog")
	assert_eq(PetPerks.coin_owner(Vector3(0, 10, 50), dogs, owners), 0)
	assert_eq(PetPerks.coin_owner(Vector3(-12.5, 10, 0), [Vector3(-10, 10, 0), Vector3(-14, 10, 0)] as Array[Vector3],
		[3, 4] as Array[int]), 4, "the nearest dog's owner")
	assert_eq(PetPerks.COIN_PULL, 4.0)


# --- Bark ---

func test_a_dog_barks_when_a_monster_comes_within_16_blocks() -> void:
	var dog := Vector3(0, 10, 0)
	var r := PetPerks.bark(dog, {1: Vector3(20, 10, 0)}, {}, 10.0, -100.0)
	assert_false(r.bark, "17+ blocks away: quiet")
	r = PetPerks.bark(dog, {1: Vector3(15, 10, 0)}, r.known, 11.0, -100.0)
	assert_true(r.bark, "it came within 16: woof!")
	var again := PetPerks.bark(dog, {1: Vector3(12, 10, 0)}, r.known, 12.0, 11.0)
	assert_false(again.bark, "the same monster: one bark is enough")
	var second := PetPerks.bark(dog, {1: Vector3(12, 10, 0), 2: Vector3(0, 10, 14)}, again.known, 12.5, 11.0)
	assert_false(second.bark, "a new one right after: it waits BARK_GAP")
	var later := PetPerks.bark(dog, {1: Vector3(12, 10, 0), 2: Vector3(0, 10, 14)}, second.known,
		11.0 + PetPerks.BARK_GAP + 0.1, 11.0)
	assert_true(later.bark, "then barks at the new one")
	assert_eq(PetPerks.BARK_RANGE, 16.0)


func test_a_monster_that_left_and_came_back_is_barked_at_again() -> void:
	var dog := Vector3.ZERO
	var r := PetPerks.bark(dog, {5: Vector3(10, 0, 0)}, {}, 0.0, -100.0)
	assert_true(r.bark)
	r = PetPerks.bark(dog, {5: Vector3(30, 0, 0)}, r.known, 20.0, 0.0)
	assert_false(r.bark)
	r = PetPerks.bark(dog, {5: Vector3(10, 0, 0)}, r.known, 40.0, 0.0)
	assert_true(r.bark, "it left and came back")


# --- Parrot ---

func test_a_parrot_points_at_the_nearest_unfound_secret_within_24_blocks() -> void:
	var parrot := Vector3(0, 10, 0)
	var secrets: Array[Vector3] = [Vector3(20, 5, 0), Vector3(0, 12, -12), Vector3(100, 0, 0)]
	assert_eq(PetPerks.point_target(parrot, secrets), Vector3(0, 12, -12), "the nearest")
	assert_eq(PetPerks.point_target(parrot, [Vector3(30, 10, 0)] as Array[Vector3]), Vector3.INF, "beyond 24 blocks")
	assert_eq(PetPerks.point_target(parrot, [] as Array[Vector3]), Vector3.INF)
	assert_eq(PetPerks.POINT_RANGE, 24.0)


func test_the_beak_turns_towards_the_secret() -> void:
	var yaw := PetPerks.point_yaw(Vector3.ZERO, Vector3(0, 0, -5))
	assert_almost_eq(yaw, 0.0, 0.001, "models face -Z")
	var side := PetPerks.point_yaw(Vector3.ZERO, Vector3(5, 0, 0))
	assert_almost_eq(Vector3.FORWARD.rotated(Vector3.UP, side).x, 1.0, 0.001)


func test_a_parrot_points_every_so_often_not_all_the_time() -> void:
	assert_between(PetPerks.POINT_EVERY, 8.0, 40.0)
	assert_lt(PetPerks.POINT_HOLD, PetPerks.POINT_EVERY)
