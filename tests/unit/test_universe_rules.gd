extends GutTest
## M3 Task 5 (spec §14.1, §5.1): the universe ladder as pure rules — a save slot per Survivor universe
## (universe 1 keeps M2's "survivor_1"), the order universes open in, where a boss portal leads, what
## the portal hub lists, who may travel, and the scaling × 2^(u−1) of gold, monster health and hits,
## and trader prices.


# --- Save slots ---

func test_every_survivor_universe_has_its_own_slot_and_universe_1_keeps_the_m2_slot() -> void:
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR), "survivor_1", "M2 saves keep working")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 1), "survivor_1")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 2), "survivor_u2")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 3), "survivor_u3")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 4), "survivor_u4")
	var seen := {}
	for u in range(1, 5):
		seen[ModeRules.slot(ModeRules.SURVIVOR, u)] = true
	assert_eq(seen.size(), 4, "four different worlds")


## Owner feedback #39: a Sandbox world per universe (a universe portal leads there); universe 1 keeps M1's slot.
func test_sandbox_has_a_world_per_universe_and_keeps_its_old_one() -> void:
	assert_eq(ModeRules.slot(ModeRules.SANDBOX), "sandbox_1", "old Sandbox saves keep working")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 1), "sandbox_1")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 2), "sandbox_2")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 5), "sandbox_5")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 0), "sandbox_1", "a broken universe is Green Meadows")


## Owner feedback #39: Sandbox never scales (everything free, gentle monsters of the universe); every mode keeps the
## universe it is played in (Monster Wave's arenas too).
func test_sandbox_never_scales_and_every_mode_keeps_its_universe() -> void:
	assert_eq(UniverseRules.scale_universe(ModeRules.SANDBOX, 4), 1)
	assert_eq(UniverseRules.scale_universe(ModeRules.SURVIVOR, 4), 4)
	assert_eq(UniverseRules.scale_universe(ModeRules.WAVE, 3), 3)
	for mode: StringName in ModeRules.MODES:
		assert_eq(ModeRules.world_universe(mode, 3), 3, String(mode))
		assert_eq(ModeRules.world_universe(mode, 0), 1)


func test_a_broken_universe_number_reads_as_universe_1() -> void:
	assert_eq(UniverseRules.valid(0), 1)
	assert_eq(UniverseRules.valid(-7), 1)
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 0), "survivor_1")
	assert_eq(UniverseRules.valid(3), 3)
	assert_eq(UniverseRules.valid(99999), UniverseRules.MAX_UNIVERSE)


# --- Scaling (§5.1: × 2^(u−1)) ---

func test_the_scale_doubles_with_every_universe() -> void:
	assert_eq(UniverseRules.scale(1), 1)
	assert_eq(UniverseRules.scale(2), 2)
	assert_eq(UniverseRules.scale(3), 4)
	assert_eq(UniverseRules.scale(4), 8)


func test_gold_monster_health_hits_and_prices_scale_for_universes_1_to_4() -> void:
	var expected := [1, 2, 4, 8]
	for u in range(1, 5):
		var k: int = expected[u - 1]
		assert_eq(UniverseRules.gold(10, u), 10 * k, "gold in universe %d" % u)
		assert_eq(UniverseRules.monster_hp(6, u), 6 * k, "monster health in universe %d" % u)
		assert_eq(UniverseRules.monster_hit(2, u), 2 * k, "monster hits in universe %d" % u)
		assert_eq(UniverseRules.price(30, u), 30 * k, "a stone tool's price in universe %d" % u)


func test_the_monsters_scale_and_the_ladder_scale_are_the_same_rule() -> void:
	for u in range(1, 5):
		assert_eq(MonsterRules.universe_scale(u), UniverseRules.scale(u), "universe %d" % u)
		assert_eq(MonsterRules.hp(MonsterRules.GOBLIN, 1, u), UniverseRules.monster_hp(MonsterRules.hp(MonsterRules.GOBLIN, 1), u))


func test_nothing_scales_to_zero_or_below() -> void:
	assert_eq(UniverseRules.gold(0, 4), 0)
	assert_eq(UniverseRules.price(-5, 3), 0, "a price is never negative")
	assert_eq(UniverseRules.gold(-5, 3), 0)


# --- The ladder: unlock order and the portal's target ---

func test_universes_open_one_after_another() -> void:
	assert_eq(UniverseRules.next_universe(1), 2)
	assert_eq(UniverseRules.next_universe(2), 3)
	assert_eq(UniverseRules.next_universe(3), 4)
	assert_eq(UniverseRules.unlocked_after_boss(1, 1), 2, "the Golem opens universe 2")
	assert_eq(UniverseRules.unlocked_after_boss(2, 2), 3, "the desert's boss opens universe 3")
	assert_eq(UniverseRules.unlocked_after_boss(4, 1), 4, "never lowered by beating an earlier boss again")
	assert_eq(UniverseRules.unlocked_after_boss(1, 3), 4, "a boss beaten in universe 3 opens 4")


func test_a_boss_portal_leads_to_the_next_universe_when_it_exists() -> void:
	var all: Array[int] = [1, 2, 3, 4]
	assert_eq(UniverseRules.portal_target(1, all), 2)
	assert_eq(UniverseRules.portal_target(3, all), 4)
	var only_meadows: Array[int] = [1]
	assert_eq(UniverseRules.portal_target(1, only_meadows), 0, "no desert yet: coming soon")
	assert_eq(UniverseRules.portal_target(4, all), 0, "the last universe of the ladder so far")


func test_the_portal_words_say_where_it_goes_or_that_it_is_coming() -> void:
	assert_eq(UniverseRules.portal_words("Sandstorm Desert", false, ModeRules.SURVIVOR),
		"Sandstorm Desert opens in the next update!", "the M2 words while the desert isn't here")
	assert_eq(UniverseRules.portal_words("Sandstorm Desert", true, ModeRules.SURVIVOR), "Walk in: Sandstorm Desert!")
	assert_eq(UniverseRules.portal_words("Sandstorm Desert", true, ModeRules.SANDBOX),
		"Sandstorm Desert waits in Survivor!", "a Sandbox Golem only peeks")


# --- The portal hub ---

func test_the_hub_lists_only_unlocked_universes_in_order() -> void:
	var all: Array[int] = [1, 2, 3, 4]
	var entries := UniverseRules.hub_entries(2, 4, all)
	assert_eq(entries.size(), 2)
	assert_eq(entries[0].universe, 1)
	assert_eq(entries[1].universe, 2)
	assert_true(entries[0].open and entries[1].open)
	assert_eq(UniverseRules.hub_entries(1, 4, all).size(), 1, "only Green Meadows at first")
	assert_eq(UniverseRules.hub_entries(4, 4, all).size(), 4)


func test_an_unlocked_universe_without_its_file_is_coming_soon() -> void:
	var only_meadows: Array[int] = [1]
	var entries := UniverseRules.hub_entries(2, 4, only_meadows)
	assert_eq(entries.size(), 2, "the child beat the Golem: the desert is listed")
	assert_true(entries[0].open)
	assert_false(entries[1].open, "coming soon")


func test_the_hub_never_lists_past_the_ladder_or_a_broken_count() -> void:
	var all: Array[int] = [1, 2, 3, 4]
	assert_eq(UniverseRules.hub_entries(9, 4, all).size(), 4)
	assert_eq(UniverseRules.hub_entries(0, 4, all).size(), 1, "Green Meadows is always there")
	assert_eq(UniverseRules.hub_entries(-3, 4, all).size(), 1)


func test_the_menu_shows_the_hub_once_a_second_universe_is_unlocked() -> void:
	assert_false(UniverseRules.shows_hub(1))
	assert_true(UniverseRules.shows_hub(2))


# --- Travel ---

func test_travel_needs_an_unlocked_universe_that_exists_and_no_friends_online() -> void:
	var all: Array[int] = [1, 2, 3, 4]
	var only_meadows: Array[int] = [1]
	assert_eq(UniverseRules.travel_refusal(2, 2, all, 0, 1), "")
	assert_eq(UniverseRules.travel_refusal(3, 2, all, 0, 1), "locked", "beat the boss first")
	assert_eq(UniverseRules.travel_refusal(2, 2, only_meadows, 0, 1), "coming_soon")
	assert_eq(UniverseRules.travel_refusal(2, 2, all, 1, 1), "friends", "not while friends play here")
	assert_eq(UniverseRules.travel_refusal(1, 2, all, 0, 1), "here", "already here")
	assert_eq(UniverseRules.travel_refusal(0, 2, all, 0, 1), "locked")
	for key in ["locked", "coming_soon", "friends", "here"]:
		assert_ne(UniverseRules.travel_message(key), "", key)


# --- Sky colours ---

func test_a_universe_sky_tints_the_day_and_leaves_the_night() -> void:
	var night := Color(0.02, 0.03, 0.1)
	var desert := Color(1.0, 0.7, 0.4)
	assert_eq(UniverseRules.sky_color(night, desert, 0.0), night, "night stays night")
	assert_eq(UniverseRules.sky_color(night, desert, 1.0), desert, "the full day is the universe's")
	var dusk := UniverseRules.sky_color(night, desert, 0.5)
	assert_almost_eq(dusk.r, 0.51, 0.001)
