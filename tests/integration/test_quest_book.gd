extends GutTest
## Owner #45a (spec §14.17): the quest pages. QUESTS lives in the MORE panel (no new always-visible button) and
## opens the quest book: the story being followed as pictures with the step's words and progress, ARROW, STOP
## FOR NOW, stories waiting (GO ON), PLAY TOGETHER for a host with friends, the givers, the keepsakes and the
## places. A giver's card tells a story in pictures and read-aloud words (LET'S GO / NOT NOW). Every page
## fits the screen, has no clock or hurry words, and keeps touches from the HUD's buttons behind it.

const SCREEN := Vector2(1280, 720)
const TILLY_AT := Vector3(10.5, 20.0, 0.5)
const TIME_WORDS := ["time", "timer", "second", "minute", "hour", "day", "expire", "deadline", "streak", "hurry",
	"quick", "countdown", "last chance", "left"]

var d: ProgressData
var me: Player
var hud: Hud
var layer: CanvasLayer
var q: QuestDirector
var shops: Array = []
var _saved := {}


func before_each() -> void:
	d = ProgressData.new()
	shops = []
	_saved = {"universe": Progress.universe}
	Progress.universe = func() -> int: return 1
	Progress.begin(d)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = "1"
	add_child_autofree(me)
	me.viewer.free()
	me.set_physics_process(false)
	me.global_position = Vector3(0.5, 20, 0.5)
	me._spawned = true
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(me, "Kid", true, false)
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	q = _director(ModeRules.SANDBOX)


func after_each() -> void:
	Progress.end()
	Progress.universe = _saved.universe
	for a: StringName in [&"jump"]:
		Input.action_release(a)


func after_all() -> void:
	Audio.stop_all()


func _director(mode: StringName) -> QuestDirector:
	var dir := QuestDirector.new()
	dir.name = "Quests"
	dir.mode = mode
	dir.universe = 1
	dir.world_seed = 42
	dir.auto_tick = false
	dir.find_target = func(_kind: StringName, _from: Vector3) -> Vector3: return Vector3(0.5, 20, 80.5)
	dir.is_host = func() -> bool: return true
	dir.own_peer = func() -> int: return 1
	dir.others = func() -> Array: return []
	dir.give_gold = func(_peer: int, _gold: int) -> void: pass
	add_child_autofree(dir)
	dir.setup_local(me, hud, layer, me.get_node("BlockInteractor") as BlockInteractor)
	return dir


func _press(root: Control, node_name: String) -> void:
	var found := root.find_children(node_name, "Button", true, false)
	assert_gt(found.size(), 0, "a %s button" % node_name)
	if found.size() > 0:
		(found[0] as Button).pressed.emit()


func _has_text(root: QuestOverlay, part: String) -> bool:
	for t in root.texts():
		if t.contains(part):
			return true
	return false


func _fits(page: QuestOverlay, what: String) -> void:
	await wait_process_frames(2)
	assert_lte(page.box.size.y, SCREEN.y - 20.0, "%s fits the screen's height (%d)" % [what, page.box.size.y])
	assert_lte(page.box.size.x, SCREEN.x - 20.0, "%s fits the screen's width (%d)" % [what, page.box.size.x])
	assert_lte(page.box.size.x, SCREEN.x - 20.0, "%s fits the screen's width (%d)" % [what, page.box.size.x])


func _no_clock_words(page: QuestOverlay, what: String) -> void:
	for t in page.texts():
		for w: String in TIME_WORDS:
			assert_false(RegEx.create_from_string("(?i)\\b%s" % w).search(t) != null, "%s: no '%s' in \"%s\"" % [what, w, t])


# --- QUESTS in MORE ---

func test_quests_is_a_big_picture_button_in_more_and_opens_the_book() -> void:
	assert_has(hud.more.buttons(), q.more_button, "in the MORE panel, not on the screen")
	assert_eq(q.more_button.text, "QUESTS")
	assert_eq(q.more_button.symbol, &"quests")
	assert_true(HudIcons.knows(&"quests"))
	assert_eq(q.more_button.custom_minimum_size, Vector2(HudLayout.BUTTON, HudLayout.BUTTON))
	hud.more.open()
	q.more_button.pressed.emit()
	assert_true(q.book.is_open())
	assert_false(hud.more.is_open(), "MORE closes behind it")


func test_the_arena_has_no_quests() -> void:
	var w := _director(ModeRules.WAVE)
	assert_null(w.book)
	assert_null(w.more_button)


# --- The book ---

func test_with_no_story_the_book_invites_to_find_a_giver() -> void:
	q.book.open()
	assert_true(_has_text(q.book, "No story yet!"))
	assert_true(_has_text(q.book, "Tilly 0/3"))
	assert_true(_has_text(q.book, "Zara 0/2"))
	await _fits(q.book, "the empty book")
	_no_clock_words(q.book, "the empty book")


func test_the_book_shows_the_story_step_by_step_with_arrow_and_stop() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	q.start_chain(&"tilly_pets")
	Progress.event(&"animal_tamed/dog")
	Progress.event(&"monster_defeated/slime")
	q.book.open()
	assert_true(_has_text(q.book, "Tilly: A home for animals"))
	assert_eq(q.book.find_children("Step*", "PanelContainer", true, false).size(), 4, "4 steps as pictures")
	var now := q.book.find_children("StepWords", "Label", true, false)[0] as Label
	assert_eq(now.text, "Chase away 3 slimes  1/3")
	assert_string_contains(q.book.spoken, "Chase away 3 slimes")
	await _fits(q.book, "a story")
	_no_clock_words(q.book, "a story")
	_press(q.book, "Arrow")
	assert_false(q.arrow_on, "the child turned the arrow off")
	assert_true(_has_text(q.book, "ARROW: OFF"))
	_press(q.book, "Stop")
	assert_eq(d.quests.active, &"")
	assert_eq(q.book.find_children("Waiting_tilly_pets", "HBoxContainer", true, false).size(), 1, "waiting")
	assert_true(_has_text(q.book, "step 2 of 4"))
	_press(q.book, "GoOn")
	assert_eq(d.quests.active, &"tilly_pets")
	assert_eq(QuestRules.step_progress(d, &"tilly_pets"), Vector2i(1, 3), "nothing lost")


func test_the_keepsakes_page() -> void:
	d.quests.done.append("tilly_map")
	q.book.open()
	_press(q.book, "Keepsakes")
	assert_eq((q.book.find_children("Count", "Label", true, false)[0] as Label).text,
		"1 of %d keepsakes" % QuestRules.CHAINS.size())
	var tiles := q.book.find_children("Keepsake_*", "PanelContainer", true, false)
	assert_eq(tiles.size(), QuestRules.CHAINS.size())
	assert_true(_has_text(q.book, "Tilly's old key"))
	assert_true(_has_text(q.book, "Ask Zara"), "a keepsake still to find says who has the story")
	await _fits(q.book, "the keepsakes")
	_no_clock_words(q.book, "the keepsakes")
	_press(q.book, "Back")
	assert_eq(q.book.page, QuestBook.MAIN)


func test_the_places_page_shows_the_way_back_in_this_world() -> void:
	d.quests.places.append({"chain": "tilly_map", "u": 1, "seed": 42, "x": 5.5, "y": 20.0, "z": 90.5})
	d.quests.places.append({"chain": "zara_scarab", "u": 2, "seed": 42, "x": 1.0, "y": 2.0, "z": 3.0})
	q.book.open()
	_press(q.book, "Places")
	assert_true(_has_text(q.book, "in another world (Sandstorm Desert)"))
	await _fits(q.book, "the places")
	_no_clock_words(q.book, "the places")
	_press(q.book, "Show")
	assert_false(q.book.is_open())
	assert_true(q.arrow.is_pointing())
	assert_eq(q.arrow.target, Vector3(5.5, 20.0, 90.5))
	assert_eq(q.arrow.what, "Tilly's lost map")


func test_a_host_with_friends_can_play_together() -> void:
	q.others = func() -> Array: return [7]
	q.start_chain(&"tilly_map")
	q.book.open()
	_press(q.book, "Together")
	assert_true(q.is_sharing())
	assert_true(_has_text(q.book, "PLAY ALONE"))
	await _fits(q.book, "a shared story")


func test_a_guest_sees_the_shared_story() -> void:
	q.is_host = func() -> bool: return false
	q._rpc_team({"chain": "tilly_map", "step": 0, "have": 0, "need": 1, "target": Vector3(1, 20, 1)})
	q.book.open()
	assert_true(_has_text(q.book, "Playing together: Tilly's lost map"))
	assert_false(_has_text(q.book, "No story yet!"), "the shared story is this child's story too")
	_no_clock_words(q.book, "a guest's book")


## The book is over the HUD: a finger on it never presses JUMP behind it; one outside it closes it.
func test_touches_on_the_book_never_reach_the_hud_buttons() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(SCREEN)
	add_child_autofree(view)
	var h := Hud.new()
	view.add_child(h)
	var book := QuestBook.new()
	book.director = q
	view.add_child(book)
	await wait_process_frames(2)
	var at := h.jump_button.get_global_rect().get_center()
	book.open()
	await wait_process_frames(2)
	_touch(view, 3, at, true)
	assert_false(Input.is_action_pressed(&"jump"), "JUMP never hears a finger over the book")
	_touch(view, 3, at, false)
	var inside := book.box.get_global_rect()
	if inside.has_point(at):
		book.close()
	else:
		assert_false(book.is_open(), "a finger outside the book closed it")
	_touch(view, 4, at, true)
	assert_true(Input.is_action_pressed(&"jump"), "with the book closed JUMP works")
	_touch(view, 4, at, false)


func _touch(view: SubViewport, index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	view.push_input(t, true)


# --- The giver's card ---

func test_a_giver_tells_a_new_story_in_pictures_and_words() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	q.open_card(&"tilly")
	assert_true(q.card.is_open())
	assert_true(_has_text(q.card, "Tilly's lost map"))
	assert_true(_has_text(q.card, "The wind blew my old map away!"))
	assert_true(_has_text(q.card, "LET'S GO!"))
	assert_true(_has_text(q.card, "NOT NOW"))
	assert_true(_has_text(q.card, "You get: tilly's old key"))
	assert_false(_has_text(q.card, "gold"), "the Sandbox pays no gold")
	assert_string_contains(q.card.spoken, "The wind blew my old map away!", "read aloud: the story too")
	await _fits(q.card, "a giver's card")
	_no_clock_words(q.card, "a giver's card")
	_press(q.card, "NotNow")
	assert_false(q.card.is_open())
	assert_eq(d.quests.active, &"", "nothing started")
	q.open_card(&"tilly")
	_press(q.card, "LetsGo")
	assert_false(q.card.is_open())
	assert_eq(d.quests.active, &"tilly_map")


func test_a_tap_on_the_giver_is_coming_back() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	q.start_chain(&"tilly_map")
	Progress.event(&"secret_found/treasure")
	Progress.event(&"secret_found/ruins")
	assert_eq(QuestRules.current_step(d, &"tilly_map").type, QuestRules.GO)
	q.open_card(&"tilly")
	assert_true(QuestRules.is_done(d, &"tilly_map"), "the tap finished the story")
	assert_true(_has_text(q.card, "A home for animals"), "and the card tells the next one")


func test_a_waiting_story_goes_on_from_its_givers_card() -> void:
	q.start_chain(&"tilly_pets")
	q.stop_chain()
	q.open_card(&"tilly")
	assert_true(_has_text(q.card, "This story waits for you."))
	_press(q.card, "GoOn")
	assert_eq(d.quests.active, &"tilly_pets")


func test_when_every_story_is_told_the_giver_says_thank_you() -> void:
	for id in QuestRules.chains_of(&"tilly"):
		d.quests.done.append(String(id))
	q.open_card(&"tilly")
	assert_true(_has_text(q.card, "Thank you! You helped me with every story."))
	assert_false(_has_text(q.card, "LET'S GO!"))


func test_tillys_survivor_card_has_her_shop_and_her_gold() -> void:
	var s := _director(ModeRules.SURVIVOR)
	s.open_card(&"tilly")
	assert_true(_has_text(s.card, "SHOP"))
	assert_true(_has_text(s.card, "and 100 gold"))
	await _fits(s.card, "Tilly's Survivor card")
