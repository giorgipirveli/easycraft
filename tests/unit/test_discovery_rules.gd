extends GutTest
## Owner #132 (W1): learning inside the world. Where Discovery plays (DISCOVER: every world but Monster Wave's arena;
## Professor Hoot's invitation: every home world), when Hoot comes (each world's first visit; a world seen before at
## most once a day), and the word budget a screen keeps (owner #133: no child has to read).

const DAY := 20380


func test_discover_is_in_every_world_but_monster_wave() -> void:
	assert_true(DiscoveryRules.discover_here(ModeRules.SANDBOX, 1))
	assert_true(DiscoveryRules.discover_here(ModeRules.SURVIVOR, 3))
	assert_true(DiscoveryRules.discover_here(ModeRules.SANDBOX, SpaceRules.FIRST), "a space world too")
	assert_false(DiscoveryRules.discover_here(ModeRules.WAVE, 1), "the arena is a fight")


func test_hoot_comes_to_home_worlds_only() -> void:
	assert_true(DiscoveryRules.hoot_here(ModeRules.SANDBOX, 1))
	assert_true(DiscoveryRules.hoot_here(ModeRules.SURVIVOR, 5))
	assert_false(DiscoveryRules.hoot_here(ModeRules.WAVE, 1))
	assert_false(DiscoveryRules.hoot_here(ModeRules.SANDBOX, SpaceRules.FIRST), "not on the Moon")


func test_a_world_key_names_the_slot_and_its_seed() -> void:
	assert_eq(DiscoveryRules.world_key("sandbox_1", 777), "sandbox_1:777")
	assert_ne(DiscoveryRules.world_key("sandbox_1", 777), DiscoveryRules.world_key("sandbox_1", 778),
		"a new world in the same slot is a new world")


func test_hoot_comes_on_a_worlds_first_visit() -> void:
	assert_true(DiscoveryRules.hoot_due({}, "sandbox_1:7", DAY))


func test_hoot_does_not_come_twice_the_same_day_to_a_world() -> void:
	var seen := DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)
	assert_false(DiscoveryRules.hoot_due(seen, "sandbox_1:7", DAY))


func test_a_new_world_gets_hoot_even_on_a_day_he_came() -> void:
	var seen := DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)
	assert_true(DiscoveryRules.hoot_due(seen, "survivor_1:9", DAY), "every world's first visit")


func test_a_world_seen_before_waits_for_a_day_hoot_has_not_come() -> void:
	var seen := DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY - 3)
	seen = DiscoveryRules.after_hoot(seen, "survivor_1:9", DAY)
	assert_false(DiscoveryRules.hoot_due(seen, "sandbox_1:7", DAY), "at most once a day")
	assert_true(DiscoveryRules.hoot_due(seen, "sandbox_1:7", DAY + 1), "the next day he comes again")


func test_hoots_memory_stays_small() -> void:
	var seen := {}
	for i in DiscoveryRules.MAX_WORLDS + 10:
		seen = DiscoveryRules.after_hoot(seen, "w:%d" % i, DAY + i)
	assert_eq((seen.worlds as Dictionary).size(), DiscoveryRules.MAX_WORLDS)
	assert_false((seen.worlds as Dictionary).has("w:0"), "the oldest visit goes first")
	assert_true((seen.worlds as Dictionary).has("w:%d" % (DiscoveryRules.MAX_WORLDS + 9)))


func test_broken_memory_is_a_fresh_start() -> void:
	assert_true(DiscoveryRules.hoot_due({"worlds": "nonsense", "day": "x"}, "a:1", DAY))
	var seen := DiscoveryRules.after_hoot({"worlds": 5}, "a:1", DAY)
	assert_false(DiscoveryRules.hoot_due(seen, "a:1", DAY))


func test_words_are_counted_as_a_child_sees_them() -> void:
	assert_eq(DiscoveryRules.word_count(""), 0)
	assert_eq(DiscoveryRules.word_count("DISCOVER"), 1)
	assert_eq(DiscoveryRules.word_count("  Let's   discover! 3 + 4 "), 2, "numbers and signs are not words to read")


func test_hoots_lines_are_short_and_spoken() -> void:
	for line: String in [DiscoveryRules.HOOT_LINE, DiscoveryRules.HOOT_LINE_VR]:
		assert_lte(DiscoveryRules.word_count(line), 24, "a short line: %s" % line)
		assert_gt(DiscoveryRules.word_count(line), 3)
