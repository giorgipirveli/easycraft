extends GutTest
## Owner feedback #42 (spec §12.16b): the treasure pack's rules while playing — the rainbow's timing and its
## pot of gold, the wishing well's once-a-day gift, the vault's levers, the ghosts' riddles — and its words
## and pictures (the Secret Book's picture riddles, what a find says, the hints).

const SEED := 777


# --- The rainbow ---

func test_a_rainbow_comes_after_the_first_dawn_and_then_about_every_other_dawn() -> void:
	assert_true(TreasureRules.rainbow_at_dawn(SEED, 1), "the first morning always")
	var n := 0
	for dawn in range(2, 202):
		if TreasureRules.rainbow_at_dawn(SEED, dawn):
			n += 1
	assert_between(n / 200.0, 0.35, 0.65, "about one dawn in two")
	assert_false(TreasureRules.rainbow_at_dawn(SEED, 0), "never before the first dawn")
	for dawn in range(1, 30):
		assert_eq(TreasureRules.rainbow_at_dawn(SEED, dawn), TreasureRules.rainbow_at_dawn(SEED, dawn), "the same world, the same mornings")


func test_a_rainbow_shows_in_daylight_only() -> void:
	assert_true(TreasureRules.rainbow_may_show(DayCycle.NOON))
	assert_true(TreasureRules.rainbow_may_show(DayCycle.DAY_START + 0.01))
	assert_false(TreasureRules.rainbow_may_show(0.0), "not at midnight")
	assert_false(TreasureRules.rainbow_may_show(DayCycle.DUSK_START + 0.02), "not at dusk")


func test_the_pot_of_gold_lands_on_dry_ground_near_the_player() -> void:
	var shape := MeadowsShape.new(SEED)
	var home := shape.spawn_column()
	var near := Vector3(home.x, shape.height_at(home.x, home.y), home.y)
	for n in range(1, 12):
		var spot := TreasureRules.rainbow_spot(SEED, n, near, shape.height_at)
		assert_false(spot.is_empty())
		var pot: Vector3i = spot.pot
		var d := Vector2(pot.x + 0.5 - near.x, pot.z + 0.5 - near.z).length()
		assert_between(d, TreasureRules.POT_MIN - 1.0, TreasureRules.POT_MAX + 1.0)
		assert_eq(pot.y, shape.height_at(pot.x, pot.z), "standing on the ground")
		assert_gt(pot.y, MeadowsShape.SEA_LEVEL + 1, "dry land")
		var arch := Basis(Vector3.UP, float(spot.yaw)) * Vector3.RIGHT      # the way the arch runs
		var view := Vector3(pot.x + 0.5 - near.x, 0, pot.z + 0.5 - near.z).normalized()
		assert_lt(absf(arch.dot(view)), 0.1, "the arch runs across the player's view, not away from it")
	var sea := func(_x: int, _z: int) -> int: return 5
	assert_true(TreasureRules.rainbow_spot(SEED, 1, near, sea).is_empty(), "no pot in the sea")


func test_the_pot_pays_a_fixed_pile_of_gold_scaled_by_the_universe() -> void:
	var one := TreasureRules.pot_reward(1, true)
	assert_eq(int(one.gold), TreasureRules.POT_GOLD)
	assert_eq(int(TreasureRules.pot_reward(2, true).gold), TreasureRules.POT_GOLD * 2)
	assert_eq(int(TreasureRules.pot_reward(3, true).gold), TreasureRules.POT_GOLD * 4)
	assert_eq(int(TreasureRules.pot_reward(1, false).gold), 0, "Sandbox: no gold")
	assert_eq(one, TreasureRules.pot_reward(1, true), "never random")
	var ids: Array = (one.items as Array).map(func(e: Array) -> int: return int(e[0]))
	for id in [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE]:
		assert_true(ids.has(id), "rainbow blocks")


func test_walking_up_to_the_pot_reaches_it() -> void:
	var pot := Vector3i(10, 30, -4)
	assert_true(TreasureRules.at_pot(Vector3(10.5, 30, -4.5), pot))
	assert_true(TreasureRules.at_pot(Vector3(12.4, 30.5, -4.5), pot))
	assert_false(TreasureRules.at_pot(Vector3(14.5, 30, -4.5), pot), "too far")
	assert_false(TreasureRules.at_pot(Vector3(10.5, 40, -4.5), pot), "flying over it")


# --- The wishing well ---

func test_a_wish_comes_true_once_per_day_for_each_player() -> void:
	var wishes := {}
	assert_true(TreasureRules.may_wish(wishes, "Ana", 0))
	TreasureRules.wish(wishes, "Ana", 0)
	assert_false(TreasureRules.may_wish(wishes, "Ana", 0), "once a day")
	assert_true(TreasureRules.may_wish(wishes, "Beka", 0), "each player their own")
	assert_true(TreasureRules.may_wish(wishes, "Ana", 1), "the next day again")
	TreasureRules.wish(wishes, "Ana", 1)
	assert_false(TreasureRules.may_wish(wishes, "Ana", 1))


func test_the_wells_gift_is_small_fixed_and_never_gold() -> void:
	for day in 20:
		var gift := TreasureRules.wish_gift(day)
		assert_eq(gift, TreasureRules.wish_gift(day), "the same gift for that day")
		assert_eq(int(gift.gold), 0, "never gold")
		assert_gt((gift.items as Array).size(), 0)
		for e: Array in gift.items:
			assert_true(ItemIds.is_hotbar_valid(int(e[0])) or ItemIds.is_item(int(e[0])), str(e))
			assert_between(int(e[1]), 1, 8, "small")
	var kinds := {}
	for day in TreasureRules.WISH_GIFTS.size():
		kinds[str(TreasureRules.wish_gift(day).items)] = true
	assert_eq(kinds.size(), TreasureRules.WISH_GIFTS.size(), "a different gift each day of the week")


# --- The vault's levers ---

func test_the_levers_open_the_vault_only_in_the_notes_order() -> void:
	var order := [2, 0, 1]
	var p: Array[int] = []
	var r := SurpriseRules.press_plate(p, 2, order)
	assert_eq(r.result, &"ok")
	r = SurpriseRules.press_plate(r.progress, 1, order)
	assert_eq(r.result, &"wrong")
	assert_eq(TreasureRules.levers_on(r.progress, 3), [false, false, false], "they all flip back")
	r = SurpriseRules.press_plate(r.progress, 2, order)
	assert_eq(TreasureRules.levers_on(r.progress, 3), [false, false, true])
	r = SurpriseRules.press_plate(r.progress, 0, order)
	r = SurpriseRules.press_plate(r.progress, 1, order)
	assert_eq(r.result, &"solved")
	assert_eq(TreasureRules.levers_on(r.progress, 3), [true, true, true])


func test_a_wrong_first_lever_that_starts_the_order_stays_on() -> void:
	var order := [1, 0, 2]
	var r := SurpriseRules.press_plate([] as Array[int], 1, order)
	r = SurpriseRules.press_plate(r.progress, 1, order)   # turned off and on again
	assert_eq(r.result, &"wrong")
	assert_eq(TreasureRules.levers_on(r.progress, 3), [false, true, false], "it starts the order again")


# --- Ghosts, words and pictures ---

func test_ghost_riddles_have_three_pictures_and_short_words() -> void:
	assert_gte(TreasureRules.GHOST_RIDDLES.size(), 6)
	for q: Dictionary in TreasureRules.GHOST_RIDDLES:
		assert_eq((q.choices as Array).size(), 3)
		assert_between(int(q.answer), 0, 2)
		assert_lte((q.question as String).length(), 40, q.question)
		for c: int in q.choices:
			assert_ne(Riddles.word(c), "", "a word under the picture %d" % c)
		assert_true(TreasureRules.is_right_ghost_answer(TreasureRules.GHOST_RIDDLES.find(q), int(q.answer)))
	assert_false(TreasureRules.is_right_ghost_answer(0, 5))
	assert_false(TreasureRules.is_right_ghost_answer(0, -1))


func test_every_kind_has_a_name_a_picture_a_find_line_a_hint_and_a_book_riddle() -> void:
	var pictures := {}
	for kind in TreasurePlaces.KINDS:
		assert_ne(TreasureRules.NAMES.get(kind, ""), "", String(kind))
		assert_true((TreasureRules.FOUND_TEXT.get(kind, "") as String).begins_with("You "), String(kind))
		var pic := int(TreasureRules.PICTURES.get(kind, -1))
		assert_between(pic, TreasureRules.FIRST_PICTURE, TreasureRules.FIRST_PICTURE + TreasureRules.PICTURE_COUNT - 1)
		pictures[pic] = true
		var riddle: Dictionary = TreasureRules.BOOK_RIDDLES.get(kind, {})
		assert_lte((riddle.get("text", "") as String).length(), 40, String(kind))
		assert_gt((riddle.get("text", "") as String).length(), 10, String(kind))
		assert_ne(int(riddle.get("picture", -1)), pic, "the riddle shows where to look, not the answer: %s" % kind)
		assert_true((TreasureRules.notice_text(kind)).begins_with("Look!"), String(kind))
	assert_eq(pictures.size(), TreasurePlaces.KINDS.size(), "a picture of its own each")
	assert_eq(TreasureRules.notice_text(&"temple"), "Look! Something secret over here!", "the M2 kinds keep theirs")


func test_new_pictures_have_words_and_live_after_the_m2_atlas() -> void:
	assert_gte(TreasureRules.FIRST_PICTURE, Pictures.COLUMNS * Pictures.ROWS, "after every tile of the M2 atlas")
	for id: int in [TreasureRules.ANCHOR, TreasureRules.CROWN, TreasureRules.GEM, TreasureRules.COIN,
			TreasureRules.GHOST, TreasureRules.FIRE, TreasureRules.PICKAXE, TreasureRules.LEVER]:
		assert_ne(Riddles.word(id), "", str(id))
	assert_eq(Riddles.word(Riddles.CAT), "cat", "the M2 words stay")


func test_the_vault_puzzle_uses_a_key_a_crown_and_a_gem() -> void:
	assert_eq(TreasureRules.VAULT_SYMBOLS, [Riddles.KEY, TreasureRules.CROWN, TreasureRules.GEM] as Array[int])
	assert_lte(TreasureRules.VAULT_TEXT.length(), 40)


func test_locked_chests_say_how_to_open_them() -> void:
	assert_string_contains(TreasureRules.lock_text(&"vault"), "levers")
	assert_string_contains(TreasureRules.lock_text(&"haunted"), "riddle")
	assert_eq(TreasureRules.lock_text(&"temple"), "Locked! Step on the plates in the right order.", "the temple's words stay")


func test_pets_that_sniff_out_treasure() -> void:
	assert_true(TreasureRules.sniffs(&"dog"))
	assert_true(TreasureRules.sniffs(&"fox"))
	assert_true(TreasureRules.sniffs(&"arctic_fox"), "owner #41's foxes, whatever their names")
	assert_true(TreasureRules.sniffs(&"fennec_fox"))
	assert_true(TreasureRules.sniffs(&"parrot"))
	assert_false(TreasureRules.sniffs(&"cat"))
	assert_false(TreasureRules.sniffs(&"cow"))


## Pets lead to chests they can hint at: every unlocked kind's chest, never a locked one.
func test_pets_sniff_every_chest_that_is_not_locked() -> void:
	for kind: StringName in [&"treasure", &"shipwreck", &"sunken", &"mineshaft", &"hollowtree", &"cove", &"ruins",
			&"camp", &"waterfall"]:
		assert_true(TreasureRules.SNIFF_KINDS.has(kind), String(kind))
	for kind: StringName in [&"vault", &"haunted", &"temple"]:
		assert_false(TreasureRules.SNIFF_KINDS.has(kind), String(kind))


## /secret knows the pack's kinds (and /secret rainbow brings a rainbow: TreasureDirector).
func test_slash_secret_knows_every_kind_of_the_pack() -> void:
	for kind: StringName in TreasurePlaces.PLACED + [TreasurePlaces.RAINBOW]:
		assert_eq(ChatCommands.parse("/secret %s" % kind), {"name": &"secret", "kind": kind}, String(kind))
	assert_string_contains(ChatCommands.COMMANDS[&"secret"].usage, "shipwreck")
