extends GutTest
## M3 Task 5 (spec §14.1): the portal hub in the main menu. SURVIVOR works as in M2 until a second
## universe is unlocked; then it lists every unlocked universe with a picture (a universe whose file
## isn't there yet says "Coming soon!" and can't be picked), and a card leads to that universe's own world.

const FAKE := preload("res://tests/fakes/fake_universe.gd")

var menu: Node
var _unlocked := 1


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_main")
	await wait_frames(2)


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


func _buttons() -> Array[Button]:
	var out: Array[Button] = []
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b as Node).is_queued_for_deletion():
			out.append(b)
	return out


func _cards() -> Array[UniverseCard]:
	var out: Array[UniverseCard] = []
	for b in _buttons():
		if b is UniverseCard:
			out.append(b)
	return out


func _button_starting(text: String) -> Button:
	for b in _buttons():
		if b.text.begins_with(text):
			return b
	return null


func _labels() -> Array[String]:
	var out: Array[String] = []
	for l in menu.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree() and not (l as Node).is_queued_for_deletion():
			out.append((l as Label).text)
	return out


func test_with_one_universe_survivor_is_as_before() -> void:
	Profile.data.universe_unlocked = 1
	menu.call("_on_survivor")
	await wait_frames(2)
	assert_eq(_cards().size(), 0, "no hub for one universe")
	var m2_screen := _button_starting("CONTINUE") != null or _button_starting("COZY") != null
	assert_true(m2_screen, "Continue / New world, or a new world's difficulty")


func test_with_two_universes_survivor_lists_both_with_pictures() -> void:
	Profile.data.universe_unlocked = 2
	UniverseRegistry.use(2, FAKE.new())
	UniverseRegistry.use(3, null)
	UniverseRegistry.use(4, null)
	menu.call("_on_survivor")
	await wait_frames(2)
	var cards := _cards()
	assert_eq(cards.size(), 2, "only the unlocked universes")
	assert_eq(cards[0].universe, 1)
	assert_eq(cards[1].universe, 2)
	assert_eq(cards[0].name_label.text, "Green Meadows")
	assert_eq(cards[1].name_label.text, "Test Land")
	for c in cards:
		assert_false(c.disabled)
		assert_not_null(c.picture, "a picture each")
		assert_gte(c.size.y, 200.0, "big enough for a child's finger")
	assert_not_null(_button_starting("BACK"))


func test_a_universe_without_its_file_is_coming_soon() -> void:
	Profile.data.universe_unlocked = 2
	UniverseRegistry.use(2, null)
	menu.call("_on_survivor")
	await wait_frames(2)
	var cards := _cards()
	assert_eq(cards.size(), 2, "the child beat the Golem: the desert is listed")
	assert_true(cards[1].disabled, "can't be picked")
	assert_eq(cards[1].state_label.text, "Coming soon!")
	assert_eq(cards[1].name_label.text, "Sandstorm Desert")


func test_a_card_leads_to_that_universes_own_world() -> void:
	Profile.data.universe_unlocked = 2
	UniverseRegistry.use(2, FAKE.new())
	menu.call("_on_survivor")
	await wait_frames(2)
	_cards()[1].pressed.emit()
	await wait_frames(2)
	if WorldSaves.exists(ModeRules.slot(ModeRules.SURVIVOR, 2)):
		var cont := _button_starting("CONTINUE")
		assert_not_null(cont)
		var bound: Array = _bound(cont)
		assert_eq(bound.back(), 2, "universe 2's world")
		assert_true(_labels().has("Test Land"), "titled with its name")
	else:
		var cozy := _button_starting("COZY")
		assert_not_null(cozy, "a new world of universe 2 asks how brave to be")
		cozy.pressed.emit()   # then which game (spec §12.18)
		await wait_frames(2)
		var classic := _button_starting("CLASSIC")
		assert_not_null(classic)
		var bound: Array = _bound(classic)
		assert_eq(bound, [ModeRules.SURVIVOR, true, DifficultyRules.COZY, 2, SurvivorGames.CLASSIC])
		_button_starting("BACK").pressed.emit()   # back to how brave, and BACK again to the hub below
		await wait_frames(2)
	var back := _button_starting("BACK")
	back.pressed.emit()
	await wait_frames(2)
	assert_eq(_cards().size(), 2, "BACK returns to the hub")


## The arguments the menu bound to a button's press (its last own connection: every button's automatic
## click, the audio pass, is Audio's).
func _bound(b: BaseButton) -> Array:
	var args: Array = []
	for c: Dictionary in b.pressed.get_connections():
		if (c.callable as Callable).get_object() != Audio:
			args = (c.callable as Callable).get_bound_arguments()
	return args
