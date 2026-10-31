extends GutTest
## Owner feedback #38 (spec §12.14a): who of the child's bot friends hears, who answers, who acts
## (BotTalk), and what a friend remembers of what its child asks for (BotAsks).

const T := preload("res://core/bots/bot_talk.gd")
const I := preload("res://core/bots/bot_intents.gd")
const ASKS := preload("res://core/bots/bot_asks.gd")


func _bots() -> Array[Dictionary]:
	return [
		{"name": "Mossy", "leader": 1, "pos": Vector3(3, 0, 0), "personality": &"builder", "up": true},
		{"name": "Pip", "leader": 1, "pos": Vector3(0, 0, 6), "personality": &"explorer", "up": true},
		{"name": "Bolt", "leader": 1, "pos": Vector3(60, 0, 0), "personality": &"fighter", "up": true},
		{"name": "Zuzu", "leader": 2, "pos": Vector3(1, 0, 1), "personality": &"fighter", "up": true},
	]


func _heard(text: String, peer: int = 1) -> Array[int]:
	var names: Array[String] = ["Mossy", "Pip", "Bolt", "Zuzu"]
	return T.listeners(I.parse(text, names), peer, Vector3.ZERO, _bots())


func test_only_the_childs_own_friends_near_them_hear() -> void:
	assert_eq(_heard("build a house"), [0, 1] as Array[int], "Bolt is 60 blocks away; Zuzu is another child's")
	assert_eq(_heard("build a house", 2), [3] as Array[int], "the other child's words reach only their friend")
	assert_eq(_heard("build a house", 7), [] as Array[int], "a child with no friends")


func test_a_name_talks_to_that_friend_wherever_it_is() -> void:
	assert_eq(_heard("Bolt, build a house"), [2] as Array[int])
	assert_eq(_heard("Mossy, wait"), [0] as Array[int])
	assert_eq(_heard("Zuzu, follow me"), [] as Array[int], "another child's friend never listens")


func test_calls_reach_all_the_childs_friends() -> void:
	assert_eq(_heard("come here"), [0, 1, 2] as Array[int])
	assert_eq(_heard("help!"), [0, 1, 2] as Array[int])
	assert_eq(_heard("where are you?"), [0, 1, 2] as Array[int])


func test_a_knocked_out_friend_does_not_hear() -> void:
	var bots := _bots()
	bots[0].up = false
	var names: Array[String] = []
	assert_eq(T.listeners(I.parse("wait", names), 1, Vector3.ZERO, bots), [1] as Array[int])


func test_the_friend_the_request_is_about_answers() -> void:
	var bots := _bots()
	var all: Array[int] = [0, 1, 2]
	assert_eq(T.answerer(I.BUILD, all, bots, Vector3.ZERO), 0, "the builder")
	assert_eq(T.answerer(I.TREASURE, all, bots, Vector3.ZERO), 1, "the explorer")
	assert_eq(T.answerer(I.WHERE_TILLY, all, bots, Vector3.ZERO), 1, "the explorer shows the way")
	assert_eq(T.answerer(I.FIGHT, all, bots, Vector3.ZERO), 2, "the fighter")
	assert_eq(T.answerer(I.HELLO, all, bots, Vector3.ZERO), 0, "otherwise the nearest")
	assert_eq(T.answerer(I.HELLO, [] as Array[int], bots, Vector3.ZERO), -1)


func test_who_carries_out_a_request() -> void:
	var bots := _bots()
	var all: Array[int] = [0, 1, 2]
	assert_eq(T.actors(I.FOLLOW, all, bots, Vector3.ZERO), all, "everyone follows")
	assert_eq(T.actors(I.BUILD, all, bots, Vector3.ZERO), [0] as Array[int], "the builder builds")
	assert_eq(T.actors(I.BUILD, [1, 2] as Array[int], bots, Vector3.ZERO), [1] as Array[int],
		"no builder near: the nearest builds")
	assert_eq(T.actors(I.TREASURE, all, bots, Vector3.ZERO), [1] as Array[int], "the explorer leads")
	assert_eq(T.actors(I.RACE, all, bots, Vector3.ZERO), [0] as Array[int], "one friend races")
	assert_eq(T.actors(I.HELLO, all, bots, Vector3.ZERO), [] as Array[int], "a hello needs no doing")


func test_who_answers_in_words() -> void:
	var bots := _bots()
	var all: Array[int] = [0, 1, 2]
	assert_eq(T.speakers(I.WHERE_ARE_YOU, all, bots, Vector3.ZERO), all, "each friend says where it is")
	assert_eq(T.speakers(I.FOLLOW, all, bots, Vector3.ZERO), [0] as Array[int], "one answer for all ('we')")
	assert_eq(T.speakers(I.ACK, all, bots, Vector3.ZERO), [] as Array[int], "ok needs no answer")


func test_words_not_understood_get_a_hint_when_meant_for_the_bots() -> void:
	var names: Array[String] = ["Mossy"]
	assert_true(T.wants_hint(I.parse("banana", names), false), "alone in the world: they were for the bots")
	assert_false(T.wants_hint(I.parse("banana", names), true), "other players here: chat between people")
	assert_true(T.wants_hint(I.parse("Mossy banana", names), true), "a friend named")
	assert_false(T.wants_hint(I.parse("follow me", names), false), "understood")


# --- What a friend remembers of its child's requests ---

func test_asked_often_to_follow_it_keeps_closer() -> void:
	var a := ASKS.new()
	assert_eq(a.closeness(0.0), 0.0)
	for i in 3:
		a.note(I.FOLLOW, 10.0 * i)
	assert_gt(a.closeness(30.0), 1.5, "three asks: noticeably closer")
	assert_lte(a.closeness(30.0), ASKS.MAX_CLOSER)
	for i in 20:
		a.note(I.FOLLOW, 30.0 + i)
	assert_eq(a.closeness(60.0), ASKS.MAX_CLOSER, "never closer than the cap")
	a.note(I.SPACE, 60.0)
	a.note(I.SPACE, 61.0)
	assert_lt(a.closeness(61.0), ASKS.MAX_CLOSER, "asked for space: a little less")


func test_requests_fade_with_time() -> void:
	var a := ASKS.new()
	a.note(I.FOLLOW, 0.0)
	a.note(I.FOLLOW, 0.0)
	var now := a.count(I.FOLLOW, 0.0)
	assert_almost_eq(a.count(I.FOLLOW, ASKS.HALF_LIFE), now * 0.5, 0.01)


func test_asked_often_to_build_it_builds_more_often() -> void:
	var a := ASKS.new()
	assert_eq(a.build_every(40.0, 0.0), 40.0)
	for i in 5:
		a.note(I.BUILD, 0.0)
	assert_lt(a.build_every(40.0, 0.0), 40.0)
	assert_gte(a.build_every(40.0, 0.0), 40.0 * ASKS.MIN_BUILD_SHARE)


func test_what_it_remembers_is_saved() -> void:
	var a := ASKS.new()
	for i in 3:
		a.note(I.FOLLOW, 0.0)
	a.note(I.BUILD, 0.0)
	var b := ASKS.from_save(JSON.parse_string(JSON.stringify(a.to_save())))
	assert_almost_eq(b.count(I.FOLLOW, 0.0), 3.0, 0.01)
	assert_almost_eq(b.count(I.BUILD, 0.0), 1.0, 0.01)
	for bad: Variant in [null, 5, "x", {"c": 3}, {"c": {"follow": "lots", "nonsense": 2, "build": -4}}]:
		var c := ASKS.from_save(bad)
		assert_eq(c.count(I.FOLLOW, 0.0), 0.0, str(bad))
		assert_eq(c.count(&"nonsense", 0.0), 0.0)
		assert_gte(c.count(I.BUILD, 0.0), 0.0)


# --- What the child asked for, in BotRules ---

func test_what_the_child_asked_for_comes_first_but_a_monster_near_comes_before_it() -> void:
	const R := preload("res://core/rules/bot_rules.gd")
	assert_eq(R.choose_behaviour(R.BUILDER, {"order": R.STAY, "far": true}), R.STAY, "waiting, not following")
	assert_eq(R.choose_behaviour(R.BUILDER, {"order": R.DANCE, "wander_due": true}), R.DANCE)
	assert_eq(R.choose_behaviour(R.EXPLORER, {"order": R.GUIDE, "sight": true}), R.GUIDE)
	assert_eq(R.choose_behaviour(R.FIGHTER, {"order": R.STAY, "target": true}), R.FIGHT, "a monster at it: it fights")
	assert_eq(R.choose_behaviour(R.FIGHTER, {"order": R.HIDE, "target": true}), R.HIDE, "running away: it doesn't")
	assert_eq(R.choose_behaviour(R.FIGHTER, {"build_ready": true}), R.IDLE, "a fighter builds only when asked")
	assert_eq(R.choose_behaviour(R.FIGHTER, {"build_ready": true, "asked_build": true}), R.BUILD)


func test_guarding_widens_the_circle_and_waiting_only_defends_itself() -> void:
	const R := preload("res://core/rules/bot_rules.gd")
	var monster: Array[Vector3] = [Vector3(12, 0, 0)]
	assert_eq(R.choose_target(R.EXPLORER, Vector3.ZERO, Vector3.ZERO, monster), -1, "an explorer guards 8 blocks")
	assert_eq(R.choose_target(R.EXPLORER, Vector3.ZERO, Vector3.ZERO, monster, R.GUARD_RADIUS), 0, "guard me: 16")
	var near: Array[Vector3] = [Vector3(5, 0, 0)]
	assert_eq(R.choose_target(R.FIGHTER, Vector3(20, 0, 0), Vector3.ZERO, near, 0.0), -1, "waiting: not the child's circle")
	assert_eq(R.choose_target(R.FIGHTER, Vector3(6, 0, 0), Vector3.ZERO, near, 0.0), 0, "but a monster at it")


func test_the_builds_a_child_can_ask_for() -> void:
	const R := preload("res://core/rules/bot_rules.gd")
	var house := R.request_design(I.HOUSE)
	assert_eq(house.size(), 23, "a 3 x 3 hut: walls 2 high with a doorway, a roof")
	assert_eq(house[0][0], Vector3i.ZERO, "the base first")
	var cells := {}
	for c: Array in house:
		cells[c[0]] = c[1]
	assert_false(cells.has(Vector3i(1, 0, 1)) or cells.has(Vector3i(1, 1, 1)), "room inside")
	assert_false(cells.has(Vector3i(1, 0, 0)) or cells.has(Vector3i(1, 1, 0)), "a doorway")
	assert_eq(cells[Vector3i(1, 2, 1)], BlockIds.BRICK, "a roof")
	var tower := R.request_design(I.TOWER)
	assert_eq(tower.size(), 7)
	assert_eq(tower.back()[1], BlockIds.LIGHT, "a lamp on top")
	assert_eq(R.request_design(I.WALL).size(), 10)
	for what in [I.HOUSE, I.TOWER, I.WALL]:
		for c: Array in R.request_design(what, BlockIds.LEAVES):
			assert_eq(c[1], BlockIds.LEAVES, "one block for all (Survivor: leaves)")
	assert_eq(R.request_design(&""), [], "no request: the friend's own small design")
