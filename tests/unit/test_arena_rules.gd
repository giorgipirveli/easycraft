extends GutTest
## Monster Wave's rules (owner feedback #44, spec §12.20): waves one after another, the raid boss at wave 10,
## gold at the run's end for the time survived and the waves cleared (more time, more gold, × 2^(u−1)), a small
## kill bonus with Monster Hunter's combo (× 2, × 3 at most), a fixed kit per universe, the best per universe.


func test_the_raid_boss_is_wave_ten() -> void:
	assert_eq(ArenaRules.FINAL_WAVE, 10)
	assert_false(ArenaRules.is_boss_wave(9))
	assert_true(ArenaRules.is_boss_wave(10))
	assert_eq(ArenaRules.FIRST_DELAY, 8.0)
	assert_eq(ArenaRules.BREATHER, 8.0)


func test_more_time_means_more_gold() -> void:
	assert_eq(ArenaRules.run_gold(0.0, 0, 1), 0)
	assert_eq(ArenaRules.run_gold(9.9, 0, 1), 0)
	assert_eq(ArenaRules.run_gold(10.0, 0, 1), 1)
	assert_eq(ArenaRules.run_gold(204.0, 5, 1), 20 + 25, "3:24 and five waves")
	assert_eq(ArenaRules.run_gold(204.0, 5, 2), 90, "× 2 in the second universe")
	assert_eq(ArenaRules.run_gold(204.0, 5, 3), 180)
	var last := -1
	for s in range(0, 1200, 7):
		var g := ArenaRules.run_gold(float(s), 3, 1)
		assert_gte(g, last, "never less for more time")
		last = g
	assert_eq(ArenaRules.run_gold(-5.0, -2, 1), 0, "nothing broken pays")


func test_the_kill_bonus_is_small_with_monster_hunters_combo() -> void:
	assert_eq(ArenaRules.kill_gold(1, 1), 1)
	assert_eq(ArenaRules.kill_gold(2, 1), 2, "a second defeat within 5 s")
	assert_eq(ArenaRules.kill_gold(3, 1), 3)
	assert_eq(ArenaRules.kill_gold(9, 1), 3, "never more than × 3")
	assert_eq(ArenaRules.kill_gold(2, 2), 4, "× 2^(u-1)")
	assert_eq(ArenaRules.multiplier(0), 1)


func test_a_combo_counts_defeats_within_five_seconds_of_each_other() -> void:
	var c := ArenaRules.Combo.new()
	assert_eq(c.defeat(10.0), 1)
	assert_eq(c.defeat(14.0), 2, "4 s later")
	assert_eq(c.defeat(18.9), 3, "each within 5 s of the one before")
	assert_eq(c.defeat(25.5), 1, "5.5 s later: a new combo")
	c.defeat(26.0)
	c.reset()
	assert_eq(c.count, 0)
	assert_eq(c.defeat(26.5), 1, "a knock-out ends the combo")


func test_the_pops_and_lines() -> void:
	assert_eq(ArenaRules.paid_line(1, 1), "+1")
	assert_eq(ArenaRules.paid_line(4, 2), "+4 × 2!")
	assert_eq(ArenaRules.run_line(204.0, 5), "3:24 · Wave 5")
	assert_eq(ArenaRules.run_line(61.0, 10), "1:01 · Raid boss!")
	assert_eq(ArenaRules.best_line({"best_time": 190.0, "best_wave": 5}), "Best 3:10 · Wave 5")
	assert_eq(ArenaRules.best_line(ArenaRules.new_record()), "Your first run!")
	assert_eq(ArenaRules.result_line(204.0, 5, 45), "You lasted 3:24 and cleared 5 waves! +45 gold")
	assert_eq(ArenaRules.result_line(80.0, 1, 13), "You lasted 1:20 and cleared 1 wave! +13 gold")
	assert_eq(ArenaRules.result_line(42.0, 0, 4), "You lasted 0:42! +4 gold")
	for line in [ArenaRules.result_line(10.0, 0, 1), ArenaRules.BOSS_WORDS, ArenaRules.READY_WORDS]:
		for word in ["die", "dead", "death", "hurry", "lose", "failed"]:
			assert_false(line.to_lower().contains(word), "%s: %s" % [line, word])


func test_the_best_per_player_rises_never_falls() -> void:
	var r := ArenaRules.new_record()
	assert_eq(r, {"best_time": 0.0, "best_wave": 0})
	assert_true(ArenaRules.better(r, 100.0, 3))
	assert_eq(r, {"best_time": 100.0, "best_wave": 3})
	assert_false(ArenaRules.better(r, 90.0, 2), "a shorter run keeps the best")
	assert_eq(r, {"best_time": 100.0, "best_wave": 3})
	assert_true(ArenaRules.better(r, 80.0, 4), "a new best wave")
	assert_eq(r, {"best_time": 100.0, "best_wave": 4})
	var saved := ArenaRules.clean_all({"Kid": {"best_time": 120.5, "best_wave": 6}, "": {}, "Bad": 3,
		"Weird": {"best_time": -4, "best_wave": 1e20}})
	assert_eq(saved.Kid, {"best_time": 120.5, "best_wave": 6})
	assert_false(saved.has(""))
	assert_false(saved.has("Bad"))
	assert_eq(saved.Weird, {"best_time": 0.0, "best_wave": ArenaRules.FINAL_WAVE})
	assert_eq(ArenaRules.clean_all(null), {})


## The same kit for everyone, of the universe's tier (monsters grow × 2 a universe): stone, iron, crystal, cosmic.
func test_the_kit_is_fixed_per_universe() -> void:
	for u in [1, 2, 3, 4, 7]:
		var tier := mini(u, 4)
		var kit := ArenaRules.kit(u)
		for kind: int in [ItemIds.SWORD, ItemIds.BOW, ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]:
			var id: int = WeaponRules.TIERS[kind][tier]
			assert_eq(kit.count(id), 1, "%s in universe %d" % [ItemIds.display_name(id), u])
		assert_eq(kit.count(ItemIds.POTION_SPEED), 2)
		assert_eq(kit.count(ItemIds.POTION_JUMP), 2)
		for id in kit.ids():
			assert_false(BlockIds.is_valid(id), "no blocks: nothing to build in the arena")
		var bar := ArenaRules.kit_hotbar(u)
		assert_eq(bar.size(), WorldMeta.HOTBAR_SIZE)
		assert_eq(bar[0], WeaponRules.TIERS[ItemIds.SWORD][tier])
		for id in bar:
			assert_true(kit.has(id), "every slot holds something from the kit")
