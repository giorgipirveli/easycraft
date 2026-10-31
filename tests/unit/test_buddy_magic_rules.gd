extends GutTest
## Buddy magic's pure rules (M3 Task 20b, spec §14.21): befriending a monster with the wand (BefriendRules), the
## bosses' mini-buddies (MiniRules) and tricks (TrickRules).


# --- Befriending (research P4) ---

func _why(level: int = 1, chasing: bool = false, boss: bool = false, wave: bool = false, golden: bool = false,
		mode: StringName = ModeRules.SANDBOX, pets: int = 0) -> StringName:
	return BefriendRules.refusal(level, chasing, boss, wave, golden, mode, pets)


func test_a_calm_small_monster_can_be_befriended_in_sandbox_and_survivor() -> void:
	assert_eq(_why(1), BefriendRules.OK)
	assert_eq(_why(2), BefriendRules.OK)
	assert_eq(_why(1, false, false, false, false, ModeRules.SURVIVOR), BefriendRules.OK)


func test_the_rules_that_say_no() -> void:
	assert_eq(_why(3), BefriendRules.TOO_STRONG, "level 2 at most")
	assert_eq(_why(1, true), BefriendRules.NOT_CALM, "never while it chases someone")
	assert_eq(_why(1, false, true), BefriendRules.BOSS, "never a boss")
	assert_eq(_why(5, true, true), BefriendRules.BOSS, "a boss hears the boss words first")
	assert_eq(_why(1, false, false, true), BefriendRules.WAVE, "never a wave's monster")
	assert_eq(_why(1, false, false, false, true), BefriendRules.GOLDEN, "the golden slime is a secret to catch")
	assert_eq(_why(1, false, false, false, false, ModeRules.WAVE), BefriendRules.MODE, "not in Monster Wave")
	assert_eq(_why(1, false, false, false, false, ModeRules.SANDBOX, AnimalRules.MAX_PETS), BefriendRules.FULL,
		"a friend counts toward the pet cap")


func test_every_refusal_has_kind_words() -> void:
	for code: StringName in [BefriendRules.TOO_STRONG, BefriendRules.NOT_CALM, BefriendRules.BOSS, BefriendRules.WAVE,
			BefriendRules.GOLDEN, BefriendRules.MODE, BefriendRules.FULL, BefriendRules.TOO_FAR]:
		assert_ne(BefriendRules.message(code), "", str(code))
	assert_eq(BefriendRules.message(BefriendRules.OK), "")
	assert_string_contains(BefriendRules.message(BefriendRules.FULL), str(AnimalRules.MAX_PETS))


func test_a_friend_is_a_pet_that_counts_toward_the_cap_and_never_fights() -> void:
	var s := BefriendRules.SPECIES
	assert_true(PetRules.is_pet_kind(s))
	assert_true(PetRules.counts_toward_cap(s), "counts toward the pet cap")
	assert_false(PetRules.tames_by_petting(s), "only the wand befriends")
	assert_false(PetRules.tames_by_treats(s))
	for perk: StringName in PetRules.perks(s):
		assert_false(perk in [PetRules.BARK, PetRules.COINS], "nothing about fighting or chasing: %s" % perk)
	assert_true(AnimalRules.SPECIES.has(s))
	assert_true(AnimalRules.SPECIES[s].tameable, "saved with the world's pets")
	assert_eq(int(AnimalRules.SPECIES[s].weight), 0, "never wild")


func test_every_monster_kind_has_a_friend_look_and_bosses_have_none() -> void:
	for kind: StringName in MonsterRules.KINDS:
		assert_true(BefriendRules.is_befriendable_kind(kind), str(kind))
	for boss: StringName in [BossRules.GOLEM, BossRules.SERPENT, BossRules.FROST_GIANT, BossRules.CAKE, BossRules.SKY_DRAGON]:
		assert_false(BefriendRules.is_befriendable_kind(boss), str(boss))


# --- Mini-buddies (research P5) ---

func test_every_boss_gives_a_tiny_version_once() -> void:
	for boss: StringName in [BossRules.GOLEM, BossRules.SERPENT, BossRules.FROST_GIANT, BossRules.CAKE]:
		assert_true(MiniRules.gives_mini(boss), str(boss))
		assert_true(MiniRules.owed({}, boss))
		assert_false(MiniRules.owed({String(boss): MiniRules.record(boss)}, boss), "one per boss kind")
		assert_ne(MiniRules.title(boss), "")
		assert_string_contains(MiniRules.words(boss), MiniRules.title(boss))
	assert_eq(str(MiniRules.record(BossRules.GOLEM).name), "Pebble", "the Pebble Golem")
	assert_false(MiniRules.gives_mini(BossRules.SKY_DRAGON), "the Sky Dragon's is the baby dragon (owner #39)")
	assert_false(MiniRules.gives_mini(&"nonsense"))


func test_mini_records_keep_names_that_pass_the_filter() -> void:
	for boss: StringName in MiniRules.MINIS:
		var r := MiniRules.record(boss)
		assert_eq(PetRules.clean_pip(r), r, "a clean record: %s" % boss)
		assert_eq(str(r.name), str(MiniRules.MINIS[boss].name), "its own name passes the filter: %s" % boss)


func test_a_mini_is_a_gift_pet_that_never_takes_a_pet_place() -> void:
	var s := MiniRules.SPECIES
	assert_true(PetRules.is_pet_kind(s))
	assert_false(PetRules.counts_toward_cap(s))
	assert_false(AnimalRules.SPECIES[s].tameable, "never saved in a world: it lives in the profile")
	assert_eq(MiniRules.animal_id(BossRules.GOLEM, 7), "mini_golem_7")
	assert_eq(MiniRules.kind_of_id("mini_golem_7"), BossRules.GOLEM)
	assert_eq(MiniRules.kind_of_id("mini_giant_12"), BossRules.FROST_GIANT)
	assert_eq(MiniRules.kind_of_id("pet3"), &"")
	assert_true(PetDirector.is_profile_pet("mini_cake_3"), "worlds never save it")


# --- Tricks (research P2) ---

func test_three_dances_teach_a_trick() -> void:
	var state := {}
	assert_eq(TrickRules.lesson(state, &"dance_hop"), TrickRules.PRACTICE)
	assert_eq(TrickRules.lesson(state, &"dance_hop"), TrickRules.PRACTICE)
	assert_eq(TrickRules.lesson(state, &"dance_hop"), TrickRules.LEARNED, "the third time")
	assert_eq(TrickRules.lesson(state, &"dance_hop"), TrickRules.KNOWN, "after that it does it with you")
	assert_true(TrickRules.knows(state, &"dance_hop"))
	assert_false(TrickRules.knows(state, &"wave"))
	assert_eq(TrickRules.lesson(state, &"nonsense"), &"", "an unknown emote teaches nothing")


func test_each_emote_is_its_own_lesson() -> void:
	var state := {}
	TrickRules.lesson(state, &"wave")
	TrickRules.lesson(state, &"cheer")
	TrickRules.lesson(state, &"wave")
	assert_eq(TrickRules.lesson(state, &"cheer"), TrickRules.PRACTICE, "two cheers so far")
	assert_eq(TrickRules.lesson(state, &"wave"), TrickRules.LEARNED)
	assert_eq(TrickRules.lessons_of(state, &"cheer"), 2)


func test_what_each_trick_looks_like() -> void:
	assert_eq(TrickRules.move_of(&"dance_hop"), TrickRules.DANCE)
	assert_eq(TrickRules.move_of(&"dance_robot"), TrickRules.DANCE)
	assert_eq(TrickRules.move_of(&"dance_star"), TrickRules.SPIN)
	assert_eq(TrickRules.move_of(&"cheer"), TrickRules.SPIN, "spin with a free emote too")
	assert_eq(TrickRules.move_of(&"wave"), TrickRules.WAVE)
	assert_eq(TrickRules.move_of(&"sit"), TrickRules.SIT)
	assert_eq(TrickRules.move_of(&"bow"), TrickRules.BOW)
	for emote: StringName in EmotePoses.DURATIONS:
		assert_true(TrickRules.MOVES.has(TrickRules.move_of(emote)), str(emote))


func test_learned_tricks_are_saved_and_cleaned() -> void:
	var state := {}
	for i in 3:
		TrickRules.lesson(state, &"clap")
	assert_eq(TrickRules.learned(state), ["clap"])
	assert_eq(TrickRules.clean(["clap", "nope", 5, "clap", "wave"]), ["clap", "wave"])
	assert_eq(TrickRules.clean("clap"), [])
	var back := TrickRules.state_from(["wave"])
	assert_true(TrickRules.knows(back, &"wave"), "a loaded trick is known: never forgotten")


func test_the_words_say_what_it_learned() -> void:
	assert_eq(TrickRules.learned_words("Rex", &"cheer"), "Rex learned to spin!")
	assert_eq(TrickRules.learned_words("Frosty", &"dance_hop"), "Frosty learned to dance!")
	assert_string_contains(TrickRules.practice_words("Rex", 1), "Rex")
