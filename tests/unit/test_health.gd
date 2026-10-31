extends GutTest
## Hearts (M2 §12.3): 10 hearts = 20 HP, regeneration after a quiet moment, knock-out at 0.


func test_damage_and_knock_out() -> void:
	var h := Health.new()
	assert_eq(h.hp, Health.MAX_HP)
	assert_false(h.damage(5))
	assert_eq(h.hp, 15)
	assert_true(h.damage(99), "0 HP: knocked out")
	assert_eq(h.hp, 0)
	assert_false(h.damage(3), "already out: nothing more happens")


func test_regeneration_waits_after_damage() -> void:
	var h := Health.new()
	h.damage(4)
	h.tick(Health.REGEN_DELAY - 0.1)
	assert_eq(h.hp, 16, "not yet")
	h.tick(0.1 + Health.REGEN_EVERY)
	assert_eq(h.hp, 17, "1 HP after the quiet moment")
	h.tick(Health.REGEN_EVERY * 10)
	assert_eq(h.hp, Health.MAX_HP, "up to full, never over")
	h.damage(1)
	h.tick(Health.REGEN_EVERY)
	assert_eq(h.hp, 19, "new damage restarts the wait")


func test_protection_after_respawn() -> void:
	var h := Health.new()
	h.damage(99)
	h.revive()
	assert_eq(h.hp, Health.MAX_HP)
	assert_false(h.damage(5), "protected right after coming back")
	assert_eq(h.hp, Health.MAX_HP)
	h.tick(Health.PROTECTION + 0.01)
	h.damage(5)
	assert_eq(h.hp, 15)


func test_bad_amounts_and_heal() -> void:
	var h := Health.new()
	h.damage(-5)
	assert_eq(h.hp, Health.MAX_HP, "negative damage heals nothing")
	h.damage(10)
	h.heal(3)
	assert_eq(h.hp, 13)
	h.heal(-3)
	assert_eq(h.hp, 13)
	assert_eq(Health.hearts(13), 6.5)
