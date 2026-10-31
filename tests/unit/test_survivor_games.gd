extends GutTest
## Owner feedback #33 (spec §12.18): a new Survivor world picks a game after COZY / NORMAL / BRAVE —
## CLASSIC (today's Survivor) or BUILD TO SURVIVE (night comes fast: build a shelter). Monster Hunter was
## folded into the MONSTER WAVE mode (owner feedback #44, §12.20). Old worlds are CLASSIC. Short, kind words;
## children are knocked out, never killed.


func test_two_games_classic_first() -> void:
	assert_eq(SurvivorGames.CHOICES, [SurvivorGames.CLASSIC, SurvivorGames.BUILD] as Array[StringName])
	assert_eq(SurvivorGames.CLASSIC, &"classic")
	assert_eq(SurvivorGames.BUILD, &"build")


func test_anything_unknown_is_classic() -> void:
	assert_eq(SurvivorGames.valid(&"build"), SurvivorGames.BUILD)
	assert_eq(SurvivorGames.valid(&"hunter"), SurvivorGames.CLASSIC, "the first plan's Monster Hunter (#44)")
	assert_eq(SurvivorGames.valid(&""), SurvivorGames.CLASSIC)
	assert_eq(SurvivorGames.valid(&"battle royale"), SurvivorGames.CLASSIC)


func test_each_game_has_a_big_word_and_a_short_kind_line() -> void:
	assert_eq(SurvivorGames.label(SurvivorGames.CLASSIC), "CLASSIC")
	assert_eq(SurvivorGames.label(SurvivorGames.BUILD), "BUILD TO SURVIVE")
	for g: StringName in SurvivorGames.CHOICES:
		assert_ne(SurvivorGames.about(g), "")
		assert_lte(SurvivorGames.about(g).length(), 40, "short enough to read at a glance")
		for word in ["die", "dead", "death", "kill", "hurry"]:
			assert_false(SurvivorGames.about(g).to_lower().contains(word), "%s: no '%s'" % [g, word])


func test_classic_keeps_the_starter_kit_build_gets_a_quick_start() -> void:
	var plain := Inventory.starter_kit().to_save()
	assert_eq(SurvivorGames.starter_kit(SurvivorGames.CLASSIC).to_save(), plain)
	var kit := SurvivorGames.starter_kit(SurvivorGames.BUILD)
	assert_eq(kit.count(BlockIds.PLANKS), 48, "32 more planks")
	assert_eq(kit.count(BlockIds.DOOR), 2, "a doorway")
	assert_eq(kit.count(BlockIds.LANTERN), 1)
	assert_eq(kit.count(ItemIds.SWORD), 1)
	assert_eq(kit.count(ItemIds.PICKAXE), 1)
	assert_eq(kit.count(BlockIds.DIRT), 8)


func test_a_new_build_world_starts_in_the_morning_the_others_as_before() -> void:
	assert_eq(SurvivorGames.new_world_time(SurvivorGames.CLASSIC), DayCycle.START)
	assert_eq(SurvivorGames.new_world_time(SurvivorGames.BUILD), BuildRules.START_TIME)
	assert_eq(DayCycle.phase(BuildRules.START_TIME), DayCycle.Phase.DAY, "full daylight")


func test_only_build_to_survive_runs_the_clock_fast() -> void:
	for t in [0.0, 0.3, 0.5, 0.9]:
		assert_eq(SurvivorGames.clock_speed(SurvivorGames.CLASSIC, t), 1.0)
	assert_eq(SurvivorGames.clock_speed(SurvivorGames.BUILD, 0.5), BuildRules.DAY_SPEED)
	assert_eq(SurvivorGames.clock_speed(SurvivorGames.BUILD, 0.95), BuildRules.NIGHT_SPEED)


## §12.18: fiercer nights outside in Build to Survive: 14 per player (20 in all) and a level more.
func test_build_nights_are_fiercer_outside() -> void:
	assert_eq(SurvivorGames.per_player_cap(SurvivorGames.CLASSIC), MonsterRules.MAX_PER_PLAYER)
	assert_eq(SurvivorGames.per_player_cap(SurvivorGames.BUILD), 14)
	assert_eq(SurvivorGames.level_bonus(SurvivorGames.CLASSIC), 0)
	assert_eq(SurvivorGames.level_bonus(SurvivorGames.BUILD), 1)
	assert_eq(SurvivorGames.night_level(3, SurvivorGames.BUILD), 4)
	assert_eq(SurvivorGames.night_level(5, SurvivorGames.BUILD), 5, "never past level 5")
	assert_eq(SurvivorGames.night_level(3, SurvivorGames.CLASSIC), 3)


## Tilly (§12.18): Build to Survive's building blocks 8 per gold, except logs (charcoal must never sell for
## more than its logs cost); prices as in Classic.
func test_tillys_prices_per_game() -> void:
	assert_eq(ShopRules.price(ItemIds.SWORD_IRON, 1, SurvivorGames.BUILD), 120)
	assert_eq(ShopRules.price(ItemIds.SWORD_IRON, 1, SurvivorGames.CLASSIC), 120)
	assert_eq(ShopRules.price(ItemIds.SWORD_IRON, 1, &"hunter"), 120, "no Monster Hunter prices any more (#44)")
	assert_eq(ShopRules.amount(BlockIds.PLANKS, SurvivorGames.BUILD), 8)
	assert_eq(ShopRules.amount(BlockIds.STONE, SurvivorGames.BUILD), 8)
	assert_eq(ShopRules.amount(BlockIds.LOG, SurvivorGames.BUILD), 4)
	assert_eq(ShopRules.amount(BlockIds.PLANKS, SurvivorGames.CLASSIC), 4)
	assert_eq(ShopRules.amount(BlockIds.DOOR, SurvivorGames.BUILD), 2, "packs stay packs")


func test_buying_in_a_game_pays_the_games_price_and_gets_its_amount() -> void:
	var inv := Inventory.new()
	var w := Wallet.new(100)
	var r := ShopRules.buy(BlockIds.PLANKS, w, inv, 1, SurvivorGames.BUILD)
	assert_true(r.ok)
	assert_eq(r.gold, 1)
	assert_eq(r.count, 8)
	assert_eq(inv.count(BlockIds.PLANKS), 8)
	assert_eq(w.balance, 99)


## The no-mint rule stays: in every game, a building block bought costs at least what selling it pays.
func test_no_game_price_lets_gold_be_made_by_buying_and_selling() -> void:
	var checked := 0
	for g: StringName in SurvivorGames.CHOICES:
		for section: StringName in ShopRules.SECTIONS:
			for id: int in ShopRules.catalog(section):
				var per_block := float(ShopRules.price(id, 1, g)) / ShopRules.amount(id, g)
				assert_gte(per_block, float(ShopRules.sell_price(id)), "%s: %s" % [g, ItemIds.display_name(id)])
				assert_gt(ShopRules.price(id, 1, g), 0, "%s: %s is never free" % [g, ItemIds.display_name(id)])
				checked += 1
	assert_gt(checked, 60)


## Build to Survive's quick start: the doorway and the lantern sit on the hotbar (instead of glass and bricks).
func test_a_build_world_has_its_door_and_lantern_on_the_hotbar() -> void:
	var base: Array[int] = [ItemIds.SWORD, ItemIds.PICKAXE, BlockIds.PLANKS, BlockIds.DIRT, BlockIds.STONE,
		BlockIds.LOG, BlockIds.SAND, BlockIds.GLASS, BlockIds.BRICK]
	var build := SurvivorGames.starter_hotbar(SurvivorGames.BUILD, base)
	assert_eq(build.slice(0, 7), base.slice(0, 7))
	assert_eq(build[7], BlockIds.DOOR)
	assert_eq(build[8], BlockIds.LANTERN)
	assert_eq(SurvivorGames.starter_hotbar(SurvivorGames.CLASSIC, base), base)
	assert_eq(base[7], BlockIds.GLASS, "the given hotbar is not changed")
