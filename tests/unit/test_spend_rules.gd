extends GutTest
## Owner #83 (spec §25.5): what gold buys, in one table (SpendRules), on the Gold Shop's shelves. Explorer lessons are
## School units marked "bonus": true with a price: buying opens one for good, and the grade's own units stay free and
## open. Weapons and tools cost what Tilly asks in the highest universe opened and wait in the backpack for the next
## Survivor world; avatar things keep their own prices; the rocket parts' and decorations' shelves start empty with
## hooks the missions fill.

const G := 4
const FREE := "g4.science.rocks"
const BONUS := "g4.science.rockets_explorer"
const PRICED := "g4.science.volcanoes_explorer"

var profile: ProfileData


func before_each() -> void:
	Curriculum.clear_cache()
	for g in Curriculum.grades():
		Curriculum.put_grade(g, {"grade": g, "subjects": []})   # only this test's grade has units
	Curriculum.put_grade(G, {"grade": G, "ages": "9-10", "subjects": [
		{"id": "maths", "title": "Maths", "units": []},
		{"id": "science", "title": "Science", "units": [
			{"id": FREE, "title": "Rocks", "standards": ["4-ESS1-1"], "goals": ["Read rock layers"]},
			{"id": BONUS, "title": "How rockets work", "standards": ["Explorer"], "goals": ["Why a rocket flies"],
				"bonus": true},
			{"id": PRICED, "title": "Volcanoes", "standards": ["Explorer"], "goals": ["Why volcanoes erupt"],
				"bonus": true, "price": 150}]},
		{"id": "english", "title": "English", "units": []}]})
	profile = ProfileData.new()
	profile.survivor_gold = 1000
	SpendRules.clear_extra()


func after_each() -> void:
	Curriculum.clear_cache()
	SpendRules.clear_extra()


func test_the_shelves_in_order_with_their_words() -> void:
	assert_eq(SpendRules.SHELVES, [SpendRules.LESSONS, SpendRules.ROCKET, SpendRules.GEAR, SpendRules.LOOKS,
		SpendRules.DECOR] as Array[StringName])
	for s in SpendRules.SHELVES:
		assert_ne(str(SpendRules.SHELF_WORDS.get(s, "")), "", str(s))
	assert_eq(SpendRules.items(SpendRules.ROCKET, profile), [] as Array[Dictionary], "the missions fill it")
	assert_ne(str(SpendRules.COMING_WORDS.get(SpendRules.ROCKET, "")), "")
	assert_ne(str(SpendRules.COMING_WORDS.get(SpendRules.DECOR, "")), "")


func test_the_grade_units_stay_free_and_open_explorer_lessons_have_a_price() -> void:
	assert_true(SpendRules.lesson_open(profile, FREE), "a grade's own unit: always open, never for sale")
	assert_eq(SpendRules.price("lesson:" + FREE, profile), 0)
	assert_false(SpendRules.lesson_open(profile, BONUS))
	assert_eq(SpendRules.price("lesson:" + BONUS, profile), SpendRules.LESSON_PRICE, "no price of its own: the default")
	assert_eq(SpendRules.price("lesson:" + PRICED, profile), 150)
	var shelf := SpendRules.items(SpendRules.LESSONS, profile)
	var ids: Array[String] = []
	for it in shelf:
		ids.append(str(it.id))
	assert_eq(ids, ["lesson:" + BONUS, "lesson:" + PRICED] as Array[String], "every grade's bonus units, only those")
	assert_eq(str(shelf[0].name), "How rockets work")


func test_buying_an_explorer_lesson_opens_it_for_good() -> void:
	assert_eq(SpendRules.buy(profile, "lesson:" + PRICED), SpendRules.OK)
	assert_eq(profile.survivor_gold, 850)
	assert_true(SpendRules.lesson_open(profile, PRICED))
	assert_eq(SpendRules.buy(profile, "lesson:" + PRICED), SpendRules.OWNED, "once")
	assert_eq(profile.survivor_gold, 850)
	assert_eq(SpendRules.buy(profile, "lesson:" + FREE), SpendRules.UNKNOWN, "a grade's own unit is never sold")
	profile.survivor_gold = 10
	assert_eq(SpendRules.buy(profile, "lesson:" + BONUS), SpendRules.NOT_ENOUGH)
	assert_false(SpendRules.lesson_open(profile, BONUS))
	var back := ProfileData.from_json(profile.to_json())
	assert_true(SpendRules.lesson_open(back, PRICED), "kept in the profile")


func test_a_lesson_price_is_kept_in_bounds() -> void:
	assert_eq(SpendRules.lesson_price({"bonus": true, "price": 5}), SpendRules.LESSON_PRICE_MIN)
	assert_eq(SpendRules.lesson_price({"bonus": true, "price": 99999}), SpendRules.LESSON_PRICE_MAX)
	assert_eq(SpendRules.lesson_price({"bonus": true, "price": "x"}), SpendRules.LESSON_PRICE)


func test_weapons_and_tools_cost_what_tilly_asks_and_wait_in_the_backpack() -> void:
	var sword := "gear:%d" % ItemIds.SWORD_STONE
	assert_eq(SpendRules.price(sword, profile), ShopRules.price(ItemIds.SWORD_STONE, 1))
	profile.universe_unlocked = 3
	assert_eq(SpendRules.price(sword, profile), ShopRules.price(ItemIds.SWORD_STONE, 3), "the highest universe opened")
	var cost := SpendRules.price(sword, profile)
	assert_eq(SpendRules.buy(profile, sword), SpendRules.OK)
	assert_eq(profile.survivor_gold, 1000 - cost)
	assert_eq(profile.backpack, {ItemIds.SWORD_STONE: 1})
	assert_eq(SpendRules.buy(profile, sword), SpendRules.OWNED, "nobody needs two")
	var inv := Inventory.new()
	assert_eq(SpendRules.unpack_backpack(profile, inv), 1)
	assert_eq(inv.count(ItemIds.SWORD_STONE), 1)
	assert_eq(profile.backpack, {}, "emptied once")
	assert_eq(SpendRules.unpack_backpack(profile, inv), 0)
	var gear_ids: Array = []
	for it in SpendRules.items(SpendRules.GEAR, profile):
		gear_ids.append(it.id)
	assert_has(gear_ids, "gear:%d" % ItemIds.PICKAXE)
	assert_has(gear_ids, "gear:%d" % ItemIds.BOW_IRON)


func test_avatar_things_keep_their_own_prices() -> void:
	var crown := "look:hat.crown"
	assert_eq(SpendRules.price(crown, profile), AvatarCatalog.price("hat.crown"))
	assert_eq(SpendRules.buy(profile, crown), SpendRules.OK)
	assert_true(profile.cosmetics.has("hat.crown"))
	assert_eq(SpendRules.buy(profile, crown), SpendRules.OWNED)
	var looks: Array = []
	for it in SpendRules.items(SpendRules.LOOKS, profile):
		looks.append(it.id)
	assert_has(looks, "look:wings.dragon")


func test_the_missions_hang_rocket_parts_on_their_shelf() -> void:
	var granted: Array[String] = []
	SpendRules.register(SpendRules.ROCKET, {"id": "part:nose_cone", "name": "Nose cone", "price": 250},
		func(p: ProfileData, id: String) -> void: granted.append(id))
	var shelf := SpendRules.items(SpendRules.ROCKET, profile)
	assert_eq(shelf.size(), 1)
	assert_eq(SpendRules.price("part:nose_cone", profile), 250)
	assert_eq(SpendRules.buy(profile, "part:nose_cone"), SpendRules.OK)
	assert_eq(granted, ["part:nose_cone"] as Array[String])
	assert_true(profile.bought.has("part:nose_cone"))
	assert_eq(SpendRules.buy(profile, "part:nose_cone"), SpendRules.OWNED)
	assert_between(int(SpendRules.GUIDE.moon_rocket), 150, 550, "owner #98: the Moon about a good day of learning (EarnRules)")
	assert_lte(int(SpendRules.GUIDE.first_part), int(SpendRules.GUIDE.moon_rocket))


func test_saved_lists_are_cleaned() -> void:
	assert_eq(SpendRules.clean_bought(["lesson:g4.maths.x", 5, "", "lesson:g4.maths.x"]), ["lesson:g4.maths.x"] as Array[String])
	assert_eq(SpendRules.clean_backpack({str(ItemIds.SWORD): 1, "junk": 2, str(ItemIds.BOW): -3}), {ItemIds.SWORD: 1})
	assert_eq(SpendRules.clean_backpack("x"), {})
