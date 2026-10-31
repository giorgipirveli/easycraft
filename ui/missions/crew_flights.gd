class_name CrewFlights
extends Node
## Crew flights (spec §21d.6 phase 2; owner #78: "which can be built by team or alone", #79: "you just sit into it at
## steering wheel and fly to moon"; brief docs/superpowers/plans/2026-09-30-crew-flights-brief.md) on every game, node
## "Crew" in the sandbox. The flow; the rules are CrewCall and CrewFlightRules, the messages Session's crew section.
## The pilot (the host): LAUNCH with friends here calls them (launch: the call's card on every game, CrewCall on the
## pilot's), then flies with the crew who took a seat (their seats, the pilot's flight to them 4 times a second) and
## leaves the others behind with kind words; landed (landed), the host's world moves and the crew follows (the
## sandbox, Session.crew_move); a crew member arriving in the destination world is welcomed (its own mission counts).
## A crew member (a guest): the call's card (TAKE MY SEAT, STAY HERE), its own RocketFlight following the pilot's
## (the sandbox's follow_fly), the seats with everyone's avatar and WAVE, then following the host into its new world
## ("Landing with your crew…" until it stands there; after CrewFlightRules.FOLLOW_SECONDS, kind words and the menu).
## Everything the game does is a hook from the sandbox; `net` is Session (tests: a fake with the same signals).

## Kept across the world's move. Host: the crew that flew ({"universe", "crew", "badge"}): its new world welcomes them.
static var carried := {}
## Guest: the move it follows ({"universe", "home"}).
static var following := {}

var net: Node
var ui_parent: Node
## This game hosts the world (the pilot's side).
var host := false
## This game's peer id (my_id, when set, says it: a guest's id comes with its join).
var me := 1
var my_id := Callable()

## () -> String: this game's player name as the world shows it.
var my_name: Callable = func() -> String: return ""
## () -> Dictionary: peer id -> the name the world shows (Session.chat_names).
var names: Callable = func() -> Dictionary: return {}
## () -> Dictionary: peer id -> the avatar's look code (the players in the world).
var looks: Callable = func() -> Dictionary: return {}
## () -> Array[int]: the other players here (host).
var peers: Callable = func() -> Array[int]: return [] as Array[int]
## () -> Variant: where the rocket stands (the pad's corner, Vector3), or null.
var origin: Callable = func() -> Variant: return null
## (rocket) -> String: the pilot's own flight ("" = it lifts off, else why not).
var fly: Callable = func(_rocket: Dictionary) -> String: return ""
## (rocket, pilot, seat, crew size) -> Node: a crew member's flight (a RocketFlight following the pilot's), or null.
var follow_fly: Callable = func(_rocket: Dictionary, _pilot: String, _seat: int, _size: int) -> Node: return null
## () -> bool: the local player stands in the world (a crew member's flight waits for it after a rejoin).
var standing: Callable = func() -> bool: return true
## () -> Node: the flight flying now (the sandbox's), or null.
var flight: Callable = func() -> Node: return null
## (words) -> void: back to the menu with these words.
var goodbye: Callable = func(_words: String) -> void: pass
## (text) -> void: a toast on the HUD.
var toast: Callable = func(_text: String) -> void: pass
## (universe, mates, mission) -> String: this child's own profile: the mission flown (mission: a crew member's; the
## pilot's counts in the sandbox's mission_arrive) and the crew badge; the badge's words when it is new, else "".
var credit: Callable = func(_u: int, _mates: Array, _mission: bool) -> String: return ""
## (universe, home) -> void: a guest follows the host into its new world (the sandbox leaves this one).
var follow_world: Callable = func(_u: int, _home: bool) -> void: pass
## () -> float: seconds now.
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

## Host: the call under way (null: none).
var call: CrewCall
var card: CrewCallCard
var seats: CrewSeats
## The crew flight's rocket (RocketCheck.description with "origin" and "crew").
var rocket := {}
## [{peer, name, look, seat}], the pilot first.
var crew: Array = []
## A crew flight is on (this game's pilot or crew member).
var flying := false
## Guest: the pilot's name (the call's).
var pilot_name := ""

var _state_t := 0.0
var _choosing_shown := false
var _welcomed := {}          # host: crew members welcomed in the destination world
var _board_later: Array = []  # guest: a boarding that waits for its player (after a rejoin)
var _follow_card: CrewCallCard
var _badge_words := ""


func _ready() -> void:
	name = "Crew" if name == "" else name
	if net == null:
		net = Session
	net.crew_called.connect(_on_called)
	net.crew_answered.connect(_on_answered)
	net.crew_boarded.connect(_on_boarded)
	net.crew_left_behind.connect(_on_left_behind)
	net.crew_cancelled.connect(_on_cancelled)
	net.crew_noted.connect(_on_noted)
	net.crew_state_received.connect(_on_state)
	net.crew_waved.connect(_on_waved)
	net.crew_moved.connect(_on_moved)
	net.crew_welcomed.connect(_on_welcomed)
	net.peer_left.connect(_on_peer_left)
	net.client_ready.connect(_on_client_ready)
	net.crew_arrival.connect(_on_arrival)
	if host and not Session.crew_moving():
		carried = {}   # (a world the crew did not move into)
	if not host and not Session.crew_following():
		following = {}
	if not host and not following.is_empty() and ui_parent:   # a guest following the host into its new world
		_follow_card = _card()
		_follow_card.say(CrewFlightRules.HOME if bool(following.get("home", false)) else CrewFlightRules.LANDING)


# --- The pilot's side ------------------------------------------------------------------------------------------------

## LAUNCH with friends here (the check passed for the pilot): the call goes to everyone ("" = calling; the board
## closes). Without friends the pilot flies as before.
func launch(r: Dictionary) -> String:
	var friends: Array[int] = peers.call()
	if friends.is_empty():
		return fly.call(r)
	if call != null or flying:
		return ""
	rocket = r.duplicate()
	var at: Variant = origin.call()
	if at != null:
		rocket["origin"] = at
	rocket["crew"] = true
	call = CrewCall.new(friends, rocket, clock.call())
	_choosing_shown = false
	var dest := int(rocket.get("destination", 0))
	for f in friends:
		net.crew_call(f, my_name.call(), dest, CrewFlightRules.CALL_SECONDS)
	card = _card()
	card.launch_now_pressed.connect(func() -> void:
		if call != null:
			call.launch_now())
	card.not_yet_pressed.connect(func() -> void: _cancel(CrewFlightRules.WAITS_PILOT))
	card.chose.connect(func(go: bool) -> void:
		if call == null:
			return
		call.choose(go)
		if call.state == CrewCall.CANCELLED:
			_cancel(CrewFlightRules.WAITS_PILOT))
	_pilot_card()
	print("CREW call to %d: %d friends" % [dest, friends.size()])
	return ""


## The host's world moves with a crew: landing (a crew flew) or HOME (friends are here).
func moving_crew(home: bool) -> bool:
	if not host:
		return false
	if home:
		return not (peers.call() as Array).is_empty()
	return flying and crew.size() > 1


## The crew's peers (the pilot's friends who fly).
func crew_peers() -> Array[int]:
	var out: Array[int] = []
	for c: Dictionary in crew:
		if int(c.peer) != _me():
			out.append(int(c.peer))
	return out


## The pilot landed on world u: the crew is carried into the next world (welcomed there) and the pilot's badge kept.
func landed(u: int) -> void:
	if not host or crew.size() < 2:
		return
	var badge: String = credit.call(u, _mates_of(_me()), false)
	carried = {"universe": u, "crew": crew.duplicate(true), "badge": badge}
	print("CREW landed on %d with %s" % [u, crew_peers()])


## The local player stands in this world (after a move, a guest is no longer following and tells the host who it was,
## for the welcome; the host shows its badge).
func arrived() -> void:
	if not following.is_empty():
		var home := bool(following.get("home", false))
		var token := int(following.get("token", 0))
		following = {}
		Session.crew_follow_done()
		if home:
			toast.call(CrewFlightRules.HOME_ARRIVED)
		elif token != 0:
			net.crew_arrived(token)
	if is_instance_valid(_follow_card):
		_follow_card.close()
	if host and int(carried.get("universe", 0)) == Game.universe and str(carried.get("badge", "")) != "":
		_later_toast(CrewFlightRules.BADGE_NEW % str(carried.badge))
		carried.badge = ""


func _process(delta: float) -> void:
	if call != null:
		_tick_call()
	if flying and host:
		_state_t -= delta
		if _state_t <= 0.0:
			_state_t = CrewFlightRules.STATE_EVERY
			_send_state()
	if not _board_later.is_empty() and standing.call():
		var b := _board_later
		_board_later = []
		_on_boarded(b[0], b[1], b[2])
	if not following.is_empty() and not host and Session.crew_following() and Session.crew_follow_seconds_left() <= 0.0:
		following = {}
		Session.crew_follow_done()
		print("CREW could not follow the host into its new world")
		goodbye.call(CrewFlightRules.LOST)


func _tick_call() -> void:
	var st := call.tick(clock.call())
	match st:
		CrewCall.CALLING:
			_pilot_card()
		CrewCall.CHOOSING:
			if not _choosing_shown:
				_choosing_shown = true
				card.choose(call.words(), CrewFlightRules.fly_with_words(call.room()))
				for f in call.friends:   # their cards wait while the pilot chooses
					net.crew_note(f, CrewFlightRules.CHOOSING % CrewFlightRules.shown_name(my_name.call()))
		CrewCall.GO:
			_go()
		CrewCall.CANCELLED:
			_cancel(CrewFlightRules.WAITS_PILOT)


func _pilot_card() -> void:
	if card == null or call == null:
		return
	var who: Dictionary = names.call()
	var friend_lines: Array[String] = []
	for f in call.friends:
		var n := CrewFlightRules.shown_name(str(who.get(f, "")))
		var what := "…"
		if call.answered(f):
			what = "takes a seat!" if not call.stayed(f) else "stays here."
		friend_lines.append("%s %s" % [n, what])
	card.calling(CrewFlightRules.CALLING % CrewFlightRules.place(int(rocket.get("destination", 0))), friend_lines,
		call.seconds_left(clock.call()))


## GO: the pilot flies with the crew (their seats, the rocket), the others are left behind with kind words.
func _go() -> void:
	var c := call
	call = null
	var dest := int(rocket.get("destination", 0))
	var who: Dictionary = names.call()
	var look: Dictionary = looks.call()
	var list: Array = [{"peer": _me(), "name": my_name.call(), "look": str(look.get(_me(), "")), "seat": 0}]
	for f in c.crew():
		list.append({"peer": f, "name": str(who.get(f, "")), "look": str(look.get(f, "")), "seat": list.size()})
	crew = list
	flying = true   # (before the flight: the sandbox's take-over lends the chat to a crew flight)
	var why: String = fly.call(rocket)
	if why != "":
		flying = false
		crew = []
		for f in c.friends:
			net.crew_cancel(f, CrewFlightRules.WAITS)
		if is_instance_valid(card):
			card.say(why, 5.0)
		return
	for entry: Dictionary in crew:
		if int(entry.peer) != _me():
			net.crew_board(int(entry.peer), rocket, int(entry.seat), crew)
	for f in c.left_behind():
		var why_left := CrewFlightRules.STAYED if c.stayed(f) else CrewFlightRules.NO_SEAT
		net.crew_leave(f, CrewFlightRules.left_words(why_left, my_name.call(), dest))
	if is_instance_valid(card):
		card.close()
	card = null
	_state_t = 0.0
	_attach_seats()
	print("CREW launch to %d with %s (left behind: %s)" % [dest, crew_peers(), c.left_behind()])


func _cancel(words: String) -> void:
	var friends: Array[int] = call.friends if call != null else [] as Array[int]
	call = null
	for f in friends:
		net.crew_cancel(f, CrewFlightRules.WAITS)
	if is_instance_valid(card):
		card.say(words, 4.0)
	card = null


func _send_state() -> void:
	var f: Node = flight.call()
	if f == null or not is_instance_valid(f) or not f.has_method(&"crew_state"):
		return
	var s: Dictionary = f.crew_state()
	var here: Array = peers.call()
	for p in crew_peers():
		if here.has(p):
			net.crew_state(p, s)


func _on_answered(peer: int, take: bool) -> void:
	if call != null and call.answer(peer, take):
		_pilot_card()


func _on_peer_left(peer: int) -> void:
	if call != null:
		call.gone(peer)
	if is_instance_valid(seats) and flying:
		seats.gone(peer)


## A guest's world is ready (it joined, came back, or followed into this world).
func _on_client_ready(peer: int) -> void:
	if not host:
		return
	if call != null and call.state == CrewCall.CALLING:   # arrived during the call: called too
		call.add(peer)
		net.crew_call(peer, my_name.call(), int(rocket.get("destination", 0)), call.seconds_left(clock.call()))
		return
	if flying and crew_peers().has(peer):   # a crew member back after its link dropped: on board again
		var seat := 0
		for c: Dictionary in crew:
			if int(c.peer) == peer:
				seat = int(c.seat)
		net.crew_board(peer, rocket, seat, crew)
		_state_t = 0.0
		print("CREW %d back on board" % peer)
		return
	_welcome(peer, peer)   # (online a crew member keeps its peer id: one that came back without the move too)


## Host: a crew member stands in this world; it was peer `token` in the crew (LAN gives a new id on the way).
func _on_arrival(peer: int, token: int) -> void:
	if host:
		_welcome(peer, token)


## Host: in the destination world, crew member `token` (now `peer`) is welcomed once: its own mission counts.
func _welcome(peer: int, token: int) -> void:
	var u := int(carried.get("universe", 0))
	if u == 0 or u != Game.universe or _welcomed.has(token) or flying:
		return
	for c: Dictionary in carried.get("crew", []):
		if int(c.peer) == token and token != _me():
			_welcomed[token] = true
			net.crew_welcome(peer, u, _mates_of(token, carried.crew))
			print("CREW welcome %d (crew member %d) on %d" % [peer, token, u])


## The other crew members' names for `peer`'s badge.
func _mates_of(peer: int, list: Array = crew) -> Array:
	var out: Array = []
	for c: Dictionary in list:
		if int(c.peer) != peer:
			out.append(CrewFlightRules.shown_name(str(c.get("name", ""))))
	return out


# --- A crew member's side --------------------------------------------------------------------------------------------

func _on_called(pilot: String, dest: int, seconds: float) -> void:
	if host or flying:
		return
	pilot_name = pilot
	if is_instance_valid(card):
		card.close()
	card = _card()
	card.ask(CrewFlightRules.call_words(pilot, dest), seconds)
	card.answered.connect(func(take: bool) -> void:
		net.crew_answer(take)
		card.say(CrewFlightRules.SEAT_TAKEN if take else CrewFlightRules.STAYING % CrewFlightRules.shown_name(pilot),
			-1.0, true))


func _on_boarded(r: Dictionary, seat: int, list: Array) -> void:
	if host:
		return
	if not standing.call():
		_board_later = [r, seat, list]   # (back after a rejoin: its player first)
		return
	var on: Node = flight.call()
	if on != null and is_instance_valid(on) and bool(on.get("crew_follow")):
		return   # (on board already: the host said it twice)
	if is_instance_valid(card):
		card.close()
	card = null
	rocket = r
	crew = list
	if list.size() > 0:
		pilot_name = str((list[0] as Dictionary).get("name", pilot_name))
	flying = true
	var f: Node = follow_fly.call(r, CrewFlightRules.shown_name(pilot_name), seat, list.size())
	if f == null:
		flying = false
		return
	_attach_seats()
	print("CREW on board in seat %d of %d" % [seat, list.size()])


func _on_state(s: Dictionary) -> void:
	var f: Node = flight.call()
	if f != null and is_instance_valid(f) and bool(f.get("crew_follow")):
		f.follow_pilot(s)


func _on_left_behind(words: String) -> void:
	if is_instance_valid(card):
		card.close()
	card = null
	goodbye.call(words)


func _on_cancelled(words: String) -> void:
	if host:
		return
	if is_instance_valid(card):
		card.say(words, 4.0)
	card = null


func _on_noted(words: String) -> void:
	if not host and is_instance_valid(card):
		card.say(words)


func _on_waved(peer: int) -> void:
	if is_instance_valid(seats):
		seats.wave(peer)


## The host's world moves to `u`: this game follows it there (the sandbox).
func _on_moved(u: int, home: bool, _flew: bool) -> void:
	if host:
		return
	following = {"universe": u, "home": home, "token": _me()}
	if not is_instance_valid(_follow_card) and ui_parent:
		_follow_card = _card()
	if is_instance_valid(_follow_card):
		_follow_card.say(CrewFlightRules.HOME if home else CrewFlightRules.LANDING)
	follow_world.call(u, home)


## In the destination world: this child's own mission counts, and the crew badge.
func _on_welcomed(u: int, mates: Array) -> void:
	var badge: String = credit.call(u, mates, true)
	print("CREW welcomed on %d with %s (badge: %s)" % [u, mates, badge])
	if badge != "":
		_later_toast(CrewFlightRules.BADGE_NEW % badge)


## Owner #106 (host): the pilot's descent crashed and the way home is over: nobody's world moves (everyone on board is
## home by the host's Launch Site); the crew flight is over.
func crashed() -> void:
	if not host or not flying:
		return
	print("CREW crashed home with %s" % [crew_peers()])
	flying = false
	crew = []
	rocket = {}


## Owner #106: a crew member's flight came home after the pilot's crash (it stands in the host's world already; the
## sandbox says CrewFlightRules.CRASHED_HOME).
func follower_crashed() -> void:
	flying = false
	crew = []


## A crew member's flight landed (the screen faded): the words wait with it for the host's world to move.
func follower_landed() -> void:
	if not is_instance_valid(_follow_card) and ui_parent:
		_follow_card = _card()
		_follow_card.say(CrewFlightRules.LANDING)


# --- Both -------------------------------------------------------------------------------------------------------------

func _attach_seats() -> void:
	var f: Node = flight.call()
	if f == null or not is_instance_valid(f):
		return
	var cockpit: Control = f.get("cockpit")
	if cockpit == null:
		return
	seats = CrewSeats.new()
	cockpit.add_child(seats)
	seats.setup(crew, _me())
	seats.wave_pressed.connect(func() -> void: net.crew_wave())


func _me() -> int:
	return int(my_id.call()) if my_id.is_valid() else me


func _card() -> CrewCallCard:
	var c := CrewCallCard.new()
	if ui_parent:
		ui_parent.add_child(c)
	else:
		add_child(c)
	return c


func _later_toast(text: String) -> void:
	if not is_inside_tree():
		return
	get_tree().create_timer(7.0).timeout.connect(func() -> void:
		if is_inside_tree():
			toast.call(text))
