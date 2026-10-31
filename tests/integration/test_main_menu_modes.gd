extends GutTest
## M2 §12.1: the main menu's SURVIVOR button is on and leads to Survivor's own world (Continue /
## New world / Back when one exists), like Sandbox.

var menu: Node


func before_each() -> void:
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_main")
	await wait_frames(2)


func _button_starting(text: String) -> Button:
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and (b as Button).is_visible_in_tree():
			return b
	return null


## What the menu's own handler on `b` is bound to. The audio pass connects a click to every button's
## `pressed` as it enters the tree (Audio._on_node_added), after the menu's, so it is not the last one.
func _menu_bound(b: BaseButton) -> Array:
	for c: Dictionary in b.pressed.get_connections():
		if (c.callable as Callable).get_object() != Audio:
			return (c.callable as Callable).get_bound_arguments()
	return []


func test_survivor_is_open() -> void:
	var survivor := _button_starting("SURVIVOR")
	assert_not_null(survivor)
	assert_false(survivor.disabled, "no more 'Coming soon'")
	assert_false(survivor.text.contains("Coming soon"))


func test_each_mode_asks_about_its_own_world() -> void:
	if not WorldSaves.exists(ModeRules.slot(ModeRules.SURVIVOR)):
		pass_test("no Survivor world saved here: SURVIVOR starts a new one right away")
		return
	menu.call("_on_survivor")
	await wait_frames(2)
	assert_not_null(_button_starting("CONTINUE"))
	assert_not_null(_button_starting("NEW WORLD"))


## M2 Task 17: a new Survivor world asks how brave to be, in three big picture-and-word buttons.
func test_a_new_survivor_world_asks_cozy_normal_or_brave() -> void:
	menu.call("_choose_difficulty")
	await wait_frames(2)
	for word in ["COZY", "NORMAL", "BRAVE"]:
		var b := _button_starting(word)
		assert_not_null(b, word)
		if b:
			assert_gte(b.size.y, 90.0, "big enough for a child's finger")
	assert_not_null(_button_starting("BACK"))


## Owner feedback #33 (spec §12.18): after how brave, which game — three big picture cards, each with a short
## line, and BACK; the chosen difficulty and game go into the new world.
func test_after_how_brave_a_new_survivor_world_asks_which_game() -> void:
	menu.call("_choose_difficulty")
	await wait_frames(2)
	_button_starting("COZY").pressed.emit()
	await wait_frames(2)
	var games := {"CLASSIC": SurvivorGames.CLASSIC, "BUILD TO SURVIVE": SurvivorGames.BUILD}
	for word: String in games:
		var b := _button_starting(word)
		assert_not_null(b, word)
		if b == null:
			continue
		assert_gte(b.size.y, 120.0, "a big card")
		assert_not_null(b.icon, "%s has a picture" % word)
		var bound: Array = _bound(b)
		assert_eq(bound, [ModeRules.SURVIVOR, true, DifficultyRules.COZY, 1, games[word]])
	var lines := []
	for l in menu.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			lines.append((l as Label).text)
	for g: StringName in SurvivorGames.CHOICES:
		assert_has(lines, SurvivorGames.about(g), "the short line under %s" % g)
	var back := _button_starting("BACK")
	assert_not_null(back)
	back.pressed.emit()
	await wait_frames(2)
	assert_not_null(_button_starting("NORMAL"), "BACK goes to how brave")


func test_a_new_world_remembers_its_game_until_it_is_made() -> void:
	var before := Game.new_world_game
	Game.new_world_game = SurvivorGames.CLASSIC
	Game.set("new_world_game", SurvivorGames.BUILD)
	assert_eq(Game.new_world_game, SurvivorGames.BUILD)
	Game.new_world_game = before


## Owner feedback #44 (spec §12.20): SANDBOX / SURVIVOR / MONSTER WAVE / PLAY ONLINE in one row of big buttons,
## all on the screen.
func test_monster_wave_sits_between_survivor_and_play_online() -> void:
	var words := ["SANDBOX", "SURVIVOR", "MONSTER WAVE", "PLAY ONLINE"]
	var screen := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
	var xs: Array[float] = []
	for w: String in words:
		var b := _button_starting(w)
		assert_not_null(b, w)
		if b == null:
			return
		assert_true(screen.encloses(b.get_global_rect()), "%s on the screen: %s in %s" % [w, b.get_global_rect(), screen])
		assert_gte(b.size.y, 200.0, "%s: a main button" % w)
		assert_eq(b.get_global_rect().position.y, _button_starting("SANDBOX").get_global_rect().position.y, "one row")
		xs.append(b.get_global_rect().position.x)
	for i in range(1, xs.size()):
		assert_gt(xs[i], xs[i - 1], "%s right of %s" % [words[i], words[i - 1]])


## MONSTER WAVE opens a card for every universe unlocked; a card starts that universe's arena.
func test_monster_wave_lists_the_arenas_and_a_card_starts_one() -> void:
	var unlocked := Profile.data.universe_unlocked
	Profile.data.universe_unlocked = 2
	_button_starting("MONSTER WAVE").pressed.emit()
	await wait_frames(2)
	var cards: Array[UniverseCard] = []
	for c in menu.find_children("*", "UniverseCard", true, false):
		if (c as UniverseCard).is_visible_in_tree():
			cards.append(c)
	assert_eq(cards.size(), 2, "one per universe unlocked")
	var bound: Array = _bound(cards[1])
	assert_eq(bound, [2], "the second universe's arena")
	assert_not_null(_button_starting("BACK"))
	var labels := []
	for l in menu.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	assert_has(labels, "Monster Wave")
	Profile.data.universe_unlocked = unlocked


func test_an_arena_starts_as_monster_wave_in_its_universe() -> void:
	var calls: Array = []
	menu.set("start_world", func(m: StringName, fresh: bool, d: StringName, u: int) -> void: calls.append([m, fresh, d, u]))
	menu.call("_start_arena", 2)
	assert_eq(calls.size(), 1)
	assert_eq(calls[0][0], ModeRules.WAVE)
	assert_eq(calls[0][3], 2)
	assert_eq(calls[0][1], not WorldSaves.exists(ModeRules.slot(ModeRules.WAVE, 2)), "new only the first time")


## The arguments a button's own handler is bound with (the audio pass also connects its click to every button).
func _bound(b: BaseButton) -> Array:
	var args: Array = []
	for c: Dictionary in b.pressed.get_connections():
		if (c.callable as Callable).get_object() != Audio:
			args = (c.callable as Callable).get_bound_arguments()
	return args
