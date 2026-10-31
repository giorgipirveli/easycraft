extends GutTest
## M3 Task 21b (research R3): the saving list ("SAVE UP") — gold things the child wants, a tool at Tilly's or
## an avatar item with a gold price, each with a have/need bar of Survivor gold. A goal the child chose: never
## a nag, never a purchase (nothing here spends gold), no timers. Owner #35's wish list is the other list
## (things a grown-up could give); nothing goes on both.

const PRESSURE: Array[String] = ["hurry", "only today", "limited", "last chance", "sale", "don't miss", "buy",
	"ask your", "tell your", "mom", "dad", "parent", "streak", "now", "soon", "left", "expire"]


func test_gold_things_can_be_saved_for() -> void:
	assert_true(SavingRules.can_save(SavingRules.LOOK, "hat.crown"), "a gold avatar item")
	assert_true(SavingRules.can_save(SavingRules.SHOP, str(ItemIds.SWORD_CRYSTAL)), "a tool at Tilly's")
	assert_true(SavingRules.can_save(SavingRules.SHOP, str(BlockIds.BED)))
	assert_false(SavingRules.can_save(SavingRules.LOOK, "hat.cap"), "free")
	assert_false(SavingRules.can_save(SavingRules.LOOK, "outfit.cosmic"), "earned, never bought")
	assert_false(SavingRules.can_save(SavingRules.LOOK, "wings.phoenix"), "a pack item is the wish list's")
	assert_false(SavingRules.can_save(SavingRules.SHOP, str(BlockIds.BEDROCK)), "not sold")
	assert_false(SavingRules.can_save(SavingRules.SHOP, "nope"))
	assert_false(SavingRules.can_save(&"moon", "1"))
	var p := ProfileData.new()
	p.cosmetics.append("hat.crown")
	assert_false(SavingRules.can_save(SavingRules.LOOK, "hat.crown", p), "owned already")


func test_toggling_puts_it_on_and_takes_it_off() -> void:
	var w := WonderData.new()
	assert_true(SavingRules.toggle(w, SavingRules.LOOK, "hat.crown"))
	assert_true(SavingRules.has(w, SavingRules.LOOK, "hat.crown"))
	assert_false(SavingRules.toggle(w, SavingRules.LOOK, "hat.crown"))
	assert_false(SavingRules.has(w, SavingRules.LOOK, "hat.crown"))
	assert_false(SavingRules.toggle(w, SavingRules.LOOK, "hat.cap"), "free things never go on")
	assert_eq(w.saving.size(), 0)


func test_the_list_is_short() -> void:
	var w := WonderData.new()
	var ids: Array[String] = []
	for id: String in AvatarCatalog.ITEMS:
		if SavingRules.can_save(SavingRules.LOOK, id):
			ids.append(id)
	assert_gt(ids.size(), SavingRules.MAX)
	for id in ids:
		SavingRules.toggle(w, SavingRules.LOOK, id)
	assert_eq(w.saving.size(), SavingRules.MAX)


func test_the_have_need_bar() -> void:
	var crown := SavingRules.entry(SavingRules.LOOK, "hat.crown")
	var price := AvatarCatalog.price("hat.crown")
	assert_eq(SavingRules.have_need(crown, 100), Vector2i(100, price))
	assert_eq(SavingRules.have_need(crown, price * 3), Vector2i(price, price), "the bar stops when full")
	assert_eq(SavingRules.have_need(crown, -5), Vector2i(0, price))
	var sword := SavingRules.entry(SavingRules.SHOP, str(ItemIds.SWORD_IRON))
	assert_eq(SavingRules.have_need(sword, 0, 1).y, ShopRules.price(ItemIds.SWORD_IRON, 1))
	assert_eq(SavingRules.have_need(sword, 0, 3).y, ShopRules.price(ItemIds.SWORD_IRON, 3), "Tilly's price where the child is")
	assert_eq(SavingRules.bar_words(Vector2i(120, 400)), "120 / 400")
	assert_eq(SavingRules.bar_words(Vector2i(400, 400)), "400 / 400 ✓")


func test_owned_looks_leave_the_list() -> void:
	var p := ProfileData.new()
	SavingRules.toggle(p.wonder, SavingRules.LOOK, "hat.crown")
	SavingRules.toggle(p.wonder, SavingRules.LOOK, "wings.bat")
	p.cosmetics.append("hat.crown")
	SavingRules.tidy(p.wonder, p)
	assert_false(SavingRules.has(p.wonder, SavingRules.LOOK, "hat.crown"), "it came true")
	assert_true(SavingRules.has(p.wonder, SavingRules.LOOK, "wings.bat"))


func test_names_and_where_to_find_it() -> void:
	assert_eq(SavingRules.name_of(SavingRules.entry(SavingRules.LOOK, "hat.crown")), "Crown")
	assert_eq(SavingRules.name_of(SavingRules.entry(SavingRules.SHOP, str(ItemIds.SWORD_IRON))),
		ItemIds.display_name(ItemIds.SWORD_IRON))
	assert_ne(SavingRules.where_words(SavingRules.entry(SavingRules.SHOP, str(ItemIds.SWORD_IRON))), "")


func test_the_words_are_calm() -> void:
	var words: Array[String] = [SavingRules.SAVE_WORD, SavingRules.SAVING_WORD, SavingRules.EMPTY_WORDS,
		SavingRules.ON_WORDS, SavingRules.OFF_WORDS, SavingRules.FULL_WORDS, SavingRules.TITLE]
	for e: Dictionary in [SavingRules.entry(SavingRules.SHOP, "131"), SavingRules.entry(SavingRules.LOOK, "hat.crown")]:
		words.append(SavingRules.where_words(e))
	for w in words:
		for bad in PRESSURE:
			assert_false(w.to_lower().contains(bad), "'%s' in \"%s\"" % [bad, w])
