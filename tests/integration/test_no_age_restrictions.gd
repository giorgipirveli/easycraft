extends GutTest
## The owner (2026-09-29): "who told you to add age restrictions into game and edult confirmations??? remove all such
## restrictions … remove it right now". The game ships with AgeBand.restrictions off: no age question, every player
## counts as 13+, every grown-up gate passes at once. (The other tests switch the rules on: tests/pre_run.gd.)

var _profile: ProfileData


func before_each() -> void:
	AgeBand.restrictions = false
	_profile = Profile.data
	Profile.data = ProfileData.new()


func after_each() -> void:
	Profile.data = _profile
	AgeBand.restrictions = true


func test_everyone_counts_as_13_plus() -> void:
	assert_eq(AgeBand.effective(AgeBand.UNDER_13), AgeBand.TEEN_PLUS)
	assert_eq(AgeBand.effective(&""), AgeBand.TEEN_PLUS, "unknown too")
	assert_eq(AgeBand.unknown(), AgeBand.TEEN_PLUS, "a peer before the server answers")
	assert_eq(ChatRules.effective_band(AgeBand.UNDER_13), AgeBand.TEEN_PLUS, "chat: no under-13 limits")
	assert_eq(AgeSignalsRules.stricter(AgeBand.UNDER_13, AgeBand.TEEN_PLUS), AgeBand.TEEN_PLUS, "a store signal lowers nothing")


func test_a_server_answer_for_an_under_13_account_limits_nothing() -> void:
	var a := OnlineRules.account({"metadata": {"age_band": "under_13", "consent": "none", "online_allowed": false,
		"chat": "quick"}}, AgeBand.UNDER_13)
	assert_eq(a.age_band, AgeBand.TEEN_PLUS)
	assert_true(a.online_allowed, "online without a grown-up's consent")
	assert_eq(a.chat, OnlineRules.CHAT_FILTERED, "typed chat (the word filter stays)")


func test_the_first_play_asks_no_age() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_after_play")
	await wait_frames(2)
	assert_eq(Profile.data.age_band, AgeBand.TEEN_PLUS, "13+ without a question")
	var titles := menu.find_children("*", "Label", true, false).map(func(l: Node) -> String: return (l as Label).text)
	assert_false(titles.has("How old are you?"), "no age screen")
	assert_true(titles.has("Pick your name"), "straight to the name")


func test_a_grown_up_gate_passes_at_once() -> void:
	var gate := GrownUpGate.new()
	var passed := [false]
	gate.passed.connect(func() -> void: passed[0] = true)
	add_child_autofree(gate)
	await wait_frames(2)
	assert_true(passed[0], "no question, no confirmation")
	assert_eq(gate.find_children("*", "Button", true, false).size(), 0, "nothing to answer")
