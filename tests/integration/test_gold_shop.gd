extends GutTest
## Owner #83 (spec §25.5): the Gold Shop's shelves (SpendRules). Explorer lessons open for good; weapons and tools go
## into the backpack; avatar things are the child's; the rocket parts' shelf says they arrive with the Launch Site until
## the missions hang parts on it; HOW TO EARN lists what pays (learning, never time). Every page fits the menu's frame.
## The shop works on its own profile and save hook (tests never touch the real profile).

const BONUS := "g4.science.rockets_explorer"

var profile: ProfileData
var saves := 0
var shop: GoldShop


func before_each() -> void:
	Curriculum.clear_cache()
	for g in Curriculum.grades():
		Curriculum.put_grade(g, {"grade": g, "subjects": []})
	Curriculum.put_grade(4, {"grade": 4, "subjects": [{"id": "science", "title": "Science", "units": [
		{"id": "g4.science.rocks", "title": "Rocks", "standards": ["x"], "goals": ["Rocks"]},
		{"id": BONUS, "title": "How rockets work", "standards": ["Explorer"], "goals": ["Why a rocket flies"], "bonus": true,
			"price": 150}]}]})
	SpendRules.clear_extra()
	profile = ProfileData.new()
	profile.survivor_gold = 500
	saves = 0


func after_each() -> void:
	Curriculum.clear_cache()
	SpendRules.clear_extra()


func after_all() -> void:
	Audio.stop_all()


func _open() -> void:
	shop = GoldShop.new()
	shop.profile = profile
	shop.save_profile = func() -> void: saves += 1
	add_child_autofree(shop)
	await wait_process_frames(2)


func _fits() -> void:
	await wait_process_frames(2)
	var size := shop.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s %s is %s" % [shop.view, shop.shelf, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s %s is %s" % [shop.view, shop.shelf, size])


func test_an_explorer_lesson_opens_for_good() -> void:
	await _open()
	assert_eq(shop.shelf, SpendRules.LESSONS)
	assert_eq(shop.cards.size(), 1, "only the Explorer lesson: the grade's own units are never sold")
	shop.cards[0].pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.survivor_gold, 350)
	assert_true(SpendRules.lesson_open(profile, BONUS))
	assert_eq(shop.message.text, "Opened for good! Find it in the SCHOOL.")
	assert_true(shop.cards[0].disabled)
	assert_string_contains(shop.cards[0].text, "YOURS")
	assert_gt(saves, 0)


func test_not_enough_gold_says_how_to_earn_it() -> void:
	profile.survivor_gold = 100
	await _open()
	shop.cards[0].pressed.emit()
	await wait_process_frames(1)
	assert_eq(shop.message.text, "You need 50 more gold. Lessons in the SCHOOL earn it!")
	assert_eq(profile.survivor_gold, 100)


## Every shelf holds things now: the rocket shelf the missions' parts (RocketParts.register_shelf), DECORATIONS the
## colonies' dome decorations (spec §21c, ColonyRules.register_shelf).
func test_every_shelf_shows_and_fits() -> void:
	await _open()
	for s in SpendRules.SHELVES:
		(shop.find_child("Shelf_" + String(s), true, false) as Button).pressed.emit()
		await wait_process_frames(1)
		assert_eq(shop.shelf, s)
		await _fits()
		assert_gt(shop.cards.size(), 0, str(s))
		assert_lte(shop.cards.size(), GoldShop.PER_PAGE)


func test_dome_decorations_go_into_the_backpack() -> void:
	profile.survivor_gold = 1000
	await _open()
	var ids: Array = SpendRules.items(SpendRules.DECOR, profile).map(func(it: Dictionary) -> String: return str(it.id))
	shop.show_shelf(SpendRules.DECOR, ids.find("decor:dome_glass") / GoldShop.PER_PAGE)   # the aliens' souvenirs come first
	await wait_process_frames(1)
	var glass: Array = shop.cards.filter(func(c: Button) -> bool: return c.text.contains("Dome Glass"))   # souvenirs too
	assert_eq(glass.size(), 1, "Dome Glass on the shelf")
	(glass[0] as Button).pressed.emit()
	await wait_process_frames(1)
	assert_eq(shop.message.text, "In your backpack: it comes into your next Survivor world.")
	assert_eq(int(profile.backpack.get(BlockIds.DOME_GLASS, 0)), 20)
	glass = shop.cards.filter(func(c: Button) -> bool: return c.text.contains("Dome Glass"))   # the shelf redrawn
	assert_false((glass[0] as Button).disabled, "bought again and again")


func test_weapons_go_into_the_backpack_and_pages_turn() -> void:
	profile.survivor_gold = 100_000
	await _open()
	shop.show_shelf(SpendRules.GEAR)
	await wait_process_frames(1)
	var first := shop.cards[0]
	first.pressed.emit()
	await wait_process_frames(1)
	assert_eq(shop.message.text, "In your backpack: it comes into your next Survivor world.")
	assert_eq(profile.backpack.size(), 1)
	assert_not_null(shop.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "NEXT"))
	shop.show_shelf(SpendRules.GEAR, 1)
	await wait_process_frames(1)
	assert_eq(shop.page_index, 1)
	await _fits()


func test_the_missions_rocket_parts_hang_on_their_shelf() -> void:
	await _open()   # the shop hangs the missions' parts (RocketParts.register_shelf)
	shop.show_shelf(SpendRules.ROCKET)
	await wait_process_frames(1)
	assert_eq(shop.cards.size(), mini(RocketParts.ORDER.size(), GoldShop.PER_PAGE))
	assert_string_contains(shop.cards[0].text, BlockIds.display_name(RocketParts.ORDER[0]))


func test_how_to_earn_lists_learning_never_time() -> void:
	await _open()
	shop.show_earn()
	await wait_process_frames(1)
	var list := shop.find_child("EarnList", true, false) as Container   # a grid when the ways to earn fill two columns
	var text := ""
	for l: Label in list.get_children():
		text += l.text + "\n"
	assert_string_contains(text, "+5 gold   An answer right the first time in the School (up to 150 a day)")
	assert_string_contains(text, "+100 gold   A School unit mastered")
	assert_string_contains(text, "+250 gold   A friend you invited learned a whole unit")
	assert_string_contains(text, "+10 gold   A wonder's quiz question right the first time", "owner #78: it pays now")
	await _fits()


## What the Gold Shop put in the backpack comes into this game's own next Survivor world, once; never into Sandbox.
func test_the_backpack_comes_into_the_next_survivor_world() -> void:
	var saved := Profile.data
	var mode := Game.mode
	Profile.data = ProfileData.new()
	Profile.data.backpack = {ItemIds.SWORD_STONE: 1}
	Game.mode = ModeRules.SANDBOX
	var sandbox := Inventory.new()
	Session.set_inventory(multiplayer.get_unique_id(), sandbox)
	assert_eq(sandbox.count(ItemIds.SWORD_STONE), 0, "not in Sandbox")
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(multiplayer.get_unique_id(), inv)
	assert_eq(inv.count(ItemIds.SWORD_STONE), 1)
	assert_eq(Profile.data.backpack, {}, "once")
	Game.mode = mode
	Profile.data = saved
	Session.survivor_reset()
