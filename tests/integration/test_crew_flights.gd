extends GutTest
## Crew flights (spec §21d.6 phase 2; the brief's items 1-4): the flow on the pilot's and a crew member's games
## (CrewFlights), over a fake session that records every message. The pilot's LAUNCH with friends here calls them;
## TAKE MY SEAT and STAY HERE; the countdown; the crew boards (seats, the rocket at the pad) and the others are left
## behind with kind words; too few seats: the pilot chooses; the pilot's flight goes to the crew; a friend arriving
## meanwhile is called, one back after a drop boards again; in the destination world each crew member is welcomed
## (its own mission and badge). A crew member's card, its flight following the pilot's, the move it follows.


class FakeNet:
	extends Node
	signal crew_called(pilot: String, destination: int, seconds: float)
	signal crew_answered(peer_id: int, take: bool)
	signal crew_boarded(rocket: Dictionary, seat: int, crew: Array)
	signal crew_left_behind(words: String)
	signal crew_cancelled(words: String)
	signal crew_noted(words: String)
	signal crew_state_received(state: Dictionary)
	signal crew_waved(peer_id: int)
	signal crew_moved(universe: int, home: bool, flew: bool)
	signal crew_welcomed(universe: int, mates: Array)
	signal peer_left(peer_id: int)
	signal client_ready(peer_id: int)
	signal crew_arrival(peer_id: int, token: int)
	var sent: Array = []

	func crew_arrived(token: int) -> void:
		sent.append(["arrived", token])

	func crew_call(peer: int, pilot: String, dest: int, seconds: float) -> void:
		sent.append(["call", peer, pilot, dest, seconds])

	func crew_answer(take: bool) -> void:
		sent.append(["answer", take])

	func crew_board(peer: int, rocket: Dictionary, seat: int, crew: Array) -> void:
		sent.append(["board", peer, rocket, seat, crew])

	func crew_leave(peer: int, words: String) -> void:
		sent.append(["leave", peer, words])

	func crew_cancel(peer: int, words: String) -> void:
		sent.append(["cancel", peer, words])

	func crew_note(peer: int, words: String) -> void:
		sent.append(["note", peer, words])

	func crew_state(peer: int, state: Dictionary) -> void:
		sent.append(["state", peer, state])

	func crew_wave() -> void:
		sent.append(["wave"])

	func crew_welcome(peer: int, u: int, mates: Array) -> void:
		sent.append(["welcome", peer, u, mates])

	func of(kind: String) -> Array:
		return sent.filter(func(m: Array) -> bool: return m[0] == kind)


class FakeFlight:
	extends Node
	var crew_follow := false
	var cockpit: Control = null
	var got: Array = []

	func crew_state() -> Dictionary:
		return {"i": 3, "t": 1.5}

	func follow_pilot(s: Dictionary) -> void:
		got.append(s)


var net: FakeNet
var crew: CrewFlights
var ui: Control
var now := 0.0
var here: Array[int] = []
var flown: Array = []
var followed: Array = []
var goodbyes: Array[String] = []
var credits: Array = []
var moved: Array = []
var the_flight: FakeFlight


func _two() -> Dictionary:
	var r: Dictionary = load("res://tests/unit/test_crew_flight_rules.gd").two_seats()
	return r


func _one() -> Dictionary:
	var r: Dictionary = load("res://tests/unit/test_crew_flight_rules.gd").one_seat()
	return r


func _make(host: bool, me: int) -> CrewFlights:
	var c := CrewFlights.new()
	c.net = net
	c.ui_parent = ui
	c.host = host
	c.me = me
	c.clock = func() -> float: return now
	c.my_name = func() -> String: return "Anna" if host else "Sam"
	c.names = func() -> Dictionary: return {1: "Anna", 2: "Sam", 3: "Mia", 4: "Leo"}
	c.looks = func() -> Dictionary: return {1: "", 2: "", 3: ""}
	c.peers = func() -> Array[int]: return here
	c.origin = func() -> Variant: return Vector3(10, 20, 30)
	c.fly = func(r: Dictionary) -> String:
		flown.append(r)
		return ""
	c.follow_fly = func(r: Dictionary, pilot: String, seat: int, size: int) -> Node:
		followed.append([r, pilot, seat, size])
		the_flight.crew_follow = true
		return the_flight
	c.flight = func() -> Node: return the_flight
	c.goodbye = func(words: String) -> void: goodbyes.append(words)
	c.credit = func(u: int, mates: Array, mission: bool) -> String:
		credits.append([u, mates, mission])
		return CrewFlightRules.badge_words(u, mates)
	c.follow_world = func(u: int, home: bool) -> void: moved.append([u, home])
	add_child_autofree(c)
	return c


func before_each() -> void:
	now = 0.0
	here = [2, 3]
	flown = []
	followed = []
	goodbyes = []
	credits = []
	moved = []
	CrewFlights.carried = {}
	CrewFlights.following = {}
	net = FakeNet.new()
	add_child_autofree(net)
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	the_flight = FakeFlight.new()
	add_child_autofree(the_flight)


func after_each() -> void:
	CrewFlights.carried = {}
	CrewFlights.following = {}
	Session.crew_reset()


func _card() -> CrewCallCard:
	for c in ui.get_children():
		if c is CrewCallCard and not c.is_queued_for_deletion():
			return c
	return null


func _tick(seconds: float) -> void:
	now += seconds
	crew._process(seconds)


# --- The pilot ---

func test_launch_with_friends_calls_them_all() -> void:
	crew = _make(true, 1)
	assert_eq(crew.launch(_two()), "", "calling: the board closes")
	var calls := net.of("call")
	assert_eq(calls.size(), 2)
	assert_eq(calls[0], ["call", 2, "Anna", SpaceRules.MOON, CrewFlightRules.CALL_SECONDS])
	assert_eq(flown, [], "nobody flies before the crew answers")
	assert_not_null(_card(), "the pilot's card")
	assert_true(_card().now_button.visible, "LAUNCH NOW")
	assert_string_contains(_card().words.text, "Calling your crew to the Moon!")


func test_without_friends_the_pilot_flies_at_once() -> void:
	here = []
	crew = _make(true, 1)
	assert_eq(crew.launch(_two()), "")
	assert_eq(flown.size(), 1)
	assert_eq(net.sent, [])


func test_a_friend_who_takes_a_seat_boards_and_one_who_stays_is_left_behind() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	net.crew_answered.emit(2, true)
	assert_string_contains(_card().lines.text, "Sam takes a seat!")
	net.crew_answered.emit(3, false)
	_tick(0.1)
	assert_eq(flown.size(), 1, "the pilot flies")
	var r: Dictionary = flown[0]
	assert_eq(r.origin, Vector3(10, 20, 30), "from the pad")
	assert_true(bool(r.crew), "a crew flight")
	var boards := net.of("board")
	assert_eq(boards.size(), 1)
	assert_eq(boards[0][1], 2, "Sam boards")
	assert_eq(boards[0][3], 1, "in seat 1")
	assert_eq((boards[0][4] as Array).size(), 2, "the crew: the pilot and Sam")
	assert_eq(boards[0][4][0].name, "Anna", "the pilot first")
	var leaves := net.of("leave")
	assert_eq(leaves.size(), 1)
	assert_eq(leaves[0][1], 3)
	assert_eq(leaves[0][2], CrewFlightRules.left_words(CrewFlightRules.STAYED, "Anna", SpaceRules.MOON))
	assert_true(crew.flying)
	assert_eq(crew.crew_peers(), [2] as Array[int])
	assert_true(crew.moving_crew(false), "landed, the world moves with its crew")


func test_the_countdown_decides_when_nobody_answers() -> void:
	here = [2]
	crew = _make(true, 1)
	crew.launch(_two())
	_tick(CrewFlightRules.CALL_SECONDS - 1.0)
	assert_eq(flown, [], "still calling")
	assert_string_contains(_card().count.text, "1")
	_tick(1.5)
	assert_eq(flown.size(), 1, "the time is up")
	assert_eq(net.of("board").size(), 1, "the friend who never answered comes along (ruling 2)")


func test_too_few_seats_let_the_pilot_choose() -> void:
	crew = _make(true, 1)
	crew.launch(_one())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, true)
	_tick(0.1)
	assert_eq(flown, [])
	assert_eq(_card().words.text, "2 friends want to fly and the rocket has 1 seat: add crew capsules!")
	assert_eq(_card().fly_button.text, "FLY ALONE")
	assert_true(_card().wait_button.visible)
	assert_eq(net.of("note").size(), 2, "the friends' cards wait while the pilot chooses")
	_card().fly_button.pressed.emit()
	_tick(0.1)
	assert_eq(flown.size(), 1, "the pilot flies alone")
	assert_eq(net.of("board").size(), 0)
	var leaves := net.of("leave")
	assert_eq(leaves.size(), 2)
	assert_string_contains(str(leaves[0][2]), "no seat for you")
	assert_false(crew.moving_crew(false), "alone: the world closes as before")


func test_the_pilot_may_wait_and_add_capsules() -> void:
	crew = _make(true, 1)
	crew.launch(_one())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, false)
	_tick(0.1)
	_card().wait_button.pressed.emit()
	assert_eq(flown, [])
	assert_eq(net.of("cancel").size(), 2, "everyone's card: the launch waits")
	assert_eq(net.of("cancel")[0][2], CrewFlightRules.WAITS)
	assert_eq(_card().words.text, CrewFlightRules.WAITS_PILOT)
	assert_null(crew.call)


func test_not_yet_ends_the_call() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	_card().not_yet_button.pressed.emit()
	assert_null(crew.call)
	assert_eq(net.of("cancel").size(), 2)


func test_the_pilots_flight_goes_to_the_crew_four_times_a_second() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, false)
	_tick(0.1)
	for i in 8:
		_tick(0.125)
	var states := net.of("state")
	assert_between(states.size(), 4, 5, "about 4 a second")
	assert_eq(states[0][1], 2, "to the crew only")
	assert_eq(states[0][2], {"i": 3, "t": 1.5})


func test_a_friend_arriving_during_the_call_is_called_too() -> void:
	here = [2]
	crew = _make(true, 1)
	crew.launch(_two())
	_tick(4.0)
	here = [2, 5]
	net.client_ready.emit(5)
	var late := net.of("call")[1] as Array
	assert_eq(late[1], 5)
	assert_almost_eq(float(late[4]), CrewFlightRules.CALL_SECONDS - 4.0, 0.01, "with the time left")


func test_a_crew_member_back_after_a_drop_boards_again() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, false)
	_tick(0.1)
	net.client_ready.emit(2)
	assert_eq(net.of("board").size(), 2, "on board again")
	net.client_ready.emit(3)
	assert_eq(net.of("board").size(), 2, "not a crew member")


func test_in_the_destination_world_each_crew_member_is_welcomed_once() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, false)
	_tick(0.1)
	crew.landed(SpaceRules.MOON)
	assert_eq(credits, [[SpaceRules.MOON, ["Sam"], false]], "the pilot's badge (its mission counts in mission_arrive)")
	assert_eq(int(CrewFlights.carried.universe), SpaceRules.MOON)
	var old_universe := Game.universe
	Game.universe = SpaceRules.MOON
	Session._crew_moving = true   # the new world's director, as after the move
	var next := _make(true, 1)
	Session.crew_reset()
	net.client_ready.emit(2)
	net.client_ready.emit(2)
	net.client_ready.emit(3)
	Game.universe = old_universe
	var w := net.of("welcome")
	assert_eq(w.size(), 1, "once, and only the crew")
	assert_eq(w[0], ["welcome", 2, SpaceRules.MOON, ["Anna"]])
	next.queue_free()


func test_on_lan_a_crew_member_with_a_new_peer_id_is_welcomed_by_its_crew_token() -> void:
	crew = _make(true, 1)
	crew.launch(_two())
	net.crew_answered.emit(2, true)
	net.crew_answered.emit(3, false)
	_tick(0.1)
	crew.landed(SpaceRules.MOON)
	var old_universe := Game.universe
	Game.universe = SpaceRules.MOON
	Session._crew_moving = true
	var next := _make(true, 1)
	Session.crew_reset()
	net.client_ready.emit(7)   # (LAN: the crew member came back as peer 7)
	assert_eq(net.of("welcome").size(), 0, "peer 7 was not in the crew")
	net.crew_arrival.emit(7, 2)
	net.crew_arrival.emit(7, 2)
	Game.universe = old_universe
	assert_eq(net.of("welcome"), [["welcome", 7, SpaceRules.MOON, ["Anna"]]], "the crew's seat 1, once")
	next.queue_free()


func test_a_crew_member_that_followed_tells_the_host_who_it_was() -> void:
	crew = _make(false, 2)
	net.crew_moved.emit(SpaceRules.MOON, false, true)
	Session._crew_follow_until = Time.get_ticks_msec() / 1000.0 + 30.0
	var next := _make(false, 9)   # the next scene: this game is peer 9 now
	next.arrived()
	assert_eq(net.of("arrived"), [["arrived", 2]], "it was peer 2 in the crew")
	next.queue_free()


# --- A crew member ---

func test_a_friend_takes_a_seat_and_flies_the_pilots_flight() -> void:
	crew = _make(false, 2)
	net.crew_called.emit("Anna", SpaceRules.MOON, 10.0)
	assert_eq(_card().words.text, "Anna is launching to the Moon! Take your seat.")
	assert_true(_card().take_button.visible and _card().stay_button.visible)
	_card().take_button.pressed.emit()
	assert_eq(net.of("answer"), [["answer", true]])
	assert_eq(_card().words.text, CrewFlightRules.SEAT_TAKEN)
	var r := _two()
	r["origin"] = Vector3(10, 20, 30)
	net.crew_boarded.emit(r, 1, [{"peer": 1, "name": "Anna", "look": "", "seat": 0},
		{"peer": 2, "name": "Sam", "look": "", "seat": 1}])
	assert_eq(followed.size(), 1)
	assert_eq(followed[0][1], "Anna", "the pilot's name")
	assert_eq(followed[0][2], 1, "its seat")
	assert_eq(followed[0][3], 2, "of two")
	assert_null(_card(), "the card closes")
	net.crew_state_received.emit({"i": 4})
	assert_eq(the_flight.got, [{"i": 4}], "the pilot's flight reaches its own")


func test_a_friend_who_stays_goes_back_to_the_menu_kindly() -> void:
	crew = _make(false, 2)
	net.crew_called.emit("Anna", SpaceRules.MOON, 10.0)
	_card().stay_button.pressed.emit()
	assert_eq(net.of("answer"), [["answer", false]])
	assert_string_contains(_card().words.text, "You stay here")
	net.crew_left_behind.emit("Anna's world is flying to the Moon…")
	assert_eq(goodbyes, ["Anna's world is flying to the Moon…"] as Array[String])


func test_a_launch_that_waits_closes_the_card() -> void:
	crew = _make(false, 2)
	net.crew_called.emit("Anna", SpaceRules.MOON, 10.0)
	net.crew_noted.emit(CrewFlightRules.CHOOSING % "Anna")
	assert_eq(_card().words.text, "Anna is checking the seats…")
	net.crew_cancelled.emit(CrewFlightRules.WAITS)
	assert_eq(_card().words.text, CrewFlightRules.WAITS)


func test_the_crew_member_follows_the_hosts_world_and_is_welcomed() -> void:
	crew = _make(false, 2)
	net.crew_moved.emit(SpaceRules.MOON, false, true)
	assert_eq(moved, [[SpaceRules.MOON, false]])
	assert_eq(_card().words.text, CrewFlightRules.LANDING)
	net.crew_welcomed.emit(SpaceRules.MOON, ["Anna"])
	assert_eq(credits, [[SpaceRules.MOON, ["Anna"], true]], "its own mission counts, and the badge")


func test_a_crew_member_that_cannot_follow_gets_kind_words_and_the_menu() -> void:
	CrewFlights.following = {"universe": SpaceRules.MOON, "home": false}
	Session._crew_follow_until = Time.get_ticks_msec() / 1000.0 + 0.01
	crew = _make(false, 2)
	assert_eq(_card().words.text, CrewFlightRules.LANDING, "a new scene still following")
	Session._crew_follow_until = 0.001   # (the time is up)
	_tick(0.1)
	assert_eq(goodbyes, [CrewFlightRules.LOST] as Array[String], "never a hang")
	assert_false(Session.crew_following())


func test_standing_in_the_new_world_ends_the_follow() -> void:
	CrewFlights.following = {"universe": 1, "home": true}
	Session._crew_follow_until = Time.get_ticks_msec() / 1000.0 + 30.0
	var toasts: Array[String] = []
	crew = _make(false, 2)
	crew.toast = func(t: String) -> void: toasts.append(t)
	crew.arrived()
	assert_false(Session.crew_following())
	assert_eq(toasts, [CrewFlightRules.HOME_ARRIVED] as Array[String])
	_tick(100.0)
	assert_eq(goodbyes, [] as Array[String])


func test_waves_reach_the_seats() -> void:
	crew = _make(false, 2)
	var cockpit := Control.new()
	cockpit.size = Vector2(1280, 720)
	add_child_autofree(cockpit)
	the_flight.cockpit = cockpit
	var r := _two()
	net.crew_boarded.emit(r, 1, [{"peer": 1, "name": "Anna", "look": "", "seat": 0},
		{"peer": 2, "name": "Sam", "look": "", "seat": 1}])
	assert_not_null(crew.seats, "the seats in the cockpit")
	assert_eq(crew.seats.seat_name(0), "Anna")
	crew.seats.wave_button.pressed.emit()
	assert_eq(net.of("wave").size(), 1)
	net.crew_waved.emit(1)
	assert_true(crew.seats.waving(1), "the pilot waves on this screen")
