class_name SpaceCreatures
extends Node
## The robots and aliens of a space world (owner #86, spec §21f: "on the planets we should have some aliens, robots as
## well"), node "Creatures" in the sandbox (section "Owner #86"), this game's own: every game builds its own from the
## world's seed and its landing, so nothing is sent (space trips are solo).
## - The helper robot by the landing pad (HelperRobot, RobotRules.helper_spot): its arm points the way the HUD's
##   compass points (the planet guide's next place, PlanetGuideRules), else to the aliens; it greets the child who comes
##   near (its hello in its bubble, then the next place), and a tap opens its card: the planet's first fact and its
##   science quest (RobotRules: dig a sample with the rover, explore a place, come back and answer a question: gold
##   once per question right the first time, EarnRules.FACT_QUIZ_GOLD). It never repeats the guide card: it points
##   and speaks the next place; the guide card and the compass list and point.
## - The rover buddy (RoverBuddy) follows the child and digs a sample when tapped (its fact); the scout drone
##   (ScoutDrone) flies ahead towards the next place and says how far it is when tapped.
## - The aliens (AlienRules.site: a short walk from the pad): a travelling explorers' camp on the real bodies
##   (AlienCamp: the explorer befriends the child for a sample, gives a present and comes along; the trader sells
##   souvenirs for gold), a village on the playful planets (AlienVillage: the chief's game of Echo; winning it makes
##   the chief a friend). Every alien's words stay honest (CreatureWords.HONEST). Walking into the camp or the village
##   visits it (the world's secrets keep "creature:camp"; MY MAP shows it from the landing).
## Quiet: it thinks TICK a second; the drum game looks at the child's feet GAME_TICK a second while it is on.

const TICK := 0.25
const GAME_TICK := 0.1
const SAY_DELAY := 1.3
const NEXT_WORDS_DELAY := 5.5
const SIGHT_CLEAR := 14.0          # the aliens' site keeps this far from a big sight

# --- Hooks (the sandbox's; tests set their own) ---
var universe := 0
var shape: SpaceShape
var world_seed := 0
## (x, z) -> float: the first free y over the ground at a column.
var ground_y: Callable
## () -> Vector3: this game's child's feet (INF: none); () -> Vector3: the way they face (flat).
var player_position: Callable
var player_forward: Callable
## () -> Array[Vector3]: every player's feet (the creatures turn to the nearest; unset: the "players" group).
var players: Callable
## The world's secrets found (SecretState.found): the quest's marks and the sights' finds.
var found := {}
## The world's sights {id: {name, words}} (UniverseRegistry.sights).
var sights := {}
var profile: ProfileData
var save_profile: Callable
## (text) -> void: this game's words (the HUD's toast).
var toast: Callable
## (entry {id, kind, name, pos}) -> void: a place on MY MAP.
var mark: Callable
## (balance) -> void: the gold counter (Session.gold_changed).
var gold_changed: Callable
## () -> void: the alien buddy comes into this world (BuddyMagicDirector.bring_minis); (mini kind) -> void: one leaves.
var bring_buddy: Callable
var send_home: Callable
## Spots the helper robot keeps clear of ([{at: Vector2, r}]: Tilly's stall, the thermometer).
var avoid: Array = []
## The world's landmark (x, z): the aliens keep clear of it (INF: none).
var landmark := Vector2.INF
## Where the creature card goes (the HUD's layer).
var ui_parent: Node

var robot: HelperRobot
var rover: RoverBuddy
var drone: ScoutDrone
var camp: AlienCamp
var village: AlienVillage
var card: CreatureCard
## The aliens' camp or village: {pos, yaw}.
var site := {}

var _t := 0.0
var _game_t := 0.0
var _spots: Array[Dictionary] = []
var _tries := 0
var _question := {}
var _plays := 0


## A world with robots (a space world; never Monster Wave's arena).
static func wanted(u: int, mode: StringName) -> bool:
	return CreatureWords.has_robot(u) and mode != ModeRules.WAVE


## Builds the robots by the pad and the aliens' camp or village.
func setup() -> void:
	name = "Creatures"
	_spots = shape.sights()
	var pad := shape.spawn_column()
	var middle := Vector2(pad.x + 0.5, pad.y + 0.5)
	var fwd: Vector3 = player_forward.call() if player_forward.is_valid() else Vector3.FORWARD
	var spot := RobotRules.helper_spot(middle, Vector2(fwd.x, fwd.z), avoid)
	var r := CreatureWords.robot(universe)
	robot = HelperRobot.new()
	robot.setup({"pos": _on_ground(spot), "name": str(r.get("name", "Robot")),
		"badge": UniverseRegistry.card_colors(universe).get("ground", Color("139e9b"))})
	robot.on_tap = _on_robot
	robot.on_near = _greet
	_hook(robot)
	var rover_at := spot + (spot - middle).normalized().rotated(0.7) * 1.8
	rover = RoverBuddy.new()
	rover.setup({"pos": _on_ground(rover_at), "dust": UniverseRegistry.card_colors(universe).get("ground", Color("c9ccd6"))})
	rover.child_position = player_position
	rover.child_forward = player_forward
	rover.ground_y = _rover_ground
	rover.on_tap = _on_rover
	_hook(rover)
	drone = ScoutDrone.new()
	drone.setup({"pos": _on_ground(spot) + Vector3(0, RobotRules.DRONE_HEIGHT, 0)})
	drone.child_position = player_position
	drone.target = drone_target
	drone.ground_y = ground_y
	drone.on_tap = _on_drone
	_hook(drone)
	_setup_aliens()
	if ui_parent:
		card = CreatureCard.new()
		ui_parent.add_child(card)
		PadFocus.watch(card)   # owner #90: the robots' and aliens' card with a controller
	tick()


func _setup_aliens() -> void:
	var keep_clear: Array = []
	if landmark.is_finite():
		keep_clear.append({"at": landmark, "r": AlienRules.LANDMARK_CLEAR})
	for s: Dictionary in _spots:
		keep_clear.append({"at": Vector2(s.pos.x, s.pos.z), "r": SIGHT_CLEAR})
	var entry := {}
	if AlienRules.has_camp(universe):
		site = AlienRules.site(shape, world_seed, keep_clear, AlienRules.CAMP_HALF)
		camp = AlienCamp.new()
		camp.setup({"universe": universe, "pos": site.pos, "yaw": site.yaw, "ground_y": ground_y})
		add_child(camp)
		for a in camp.aliens():
			_hook(a, false)
		entry = {"id": "space_aliens", "kind": &"camp", "name": tr(CreatureWords.CAMP_NAME), "pos": site.pos}
	elif AlienRules.has_village(universe):
		site = AlienRules.village_site(shape, world_seed, keep_clear)
		village = AlienVillage.new()
		village.setup({"universe": universe, "pos": site.pos, "yaw": site.yaw, "ground_y": ground_y})
		village.feet = player_position
		village.echo_step.connect(_on_echo)
		add_child(village)
		for a in village.aliens():
			_hook(a, false)
		entry = {"id": "space_aliens", "kind": &"village", "name": str(CreatureWords.village(universe).name),
			"pos": site.pos}
	if not entry.is_empty() and mark.is_valid():
		mark.call(entry)


func _hook(c: SpaceCreature, own := true) -> void:
	if c.on_tap.is_null():
		c.on_tap = _on_alien
	if players.is_valid():
		c.players = players
	if own:
		add_child(c)


## The ground the rover drives on at a column: never down into Venus's clouds (a gap between two decks: it keeps its
## height, NAN, like a hover over the gap; the child is lifted back to the city anyway), nor into the open space between
## the rings' chunks.
func _rover_ground(x: int, z: int) -> float:
	var y := float(ground_y.call(x, z)) if ground_y.is_valid() else NAN
	if shape != null and shape.venus != null and y < VenusTerrain.LIFT_Y:
		return NAN
	if shape != null and shape.rings != null and y < RingsTerrain.LIFT_Y:
		return NAN
	return y


func _on_ground(xz: Vector2) -> Vector3:
	var y := float(ground_y.call(floori(xz.x), floori(xz.y))) if ground_y.is_valid() else 0.0
	return Vector3(xz.x, y, xz.y)


func _child() -> Vector3:
	return player_position.call() if player_position.is_valid() else Vector3.INF


func _process(delta: float) -> void:
	if village and village.playing:
		_game_t -= delta
		if _game_t <= 0.0:
			_game_t = GAME_TICK
			village.check_feet()
	_t -= delta
	if _t <= 0.0:
		_t = TICK
		tick()


## A look round: the camp visited, where the robot points, the robot's mark, who waits at the camp.
func tick() -> void:
	var child := _child()
	if not site.is_empty() and child.is_finite() and not found.has(RobotRules.CAMP) \
			and Vector2(child.x - site.pos.x, child.z - site.pos.z).length() <= AlienRules.VISIT_R:
		found[RobotRules.CAMP] = true
		_say(CreatureWords.CAMP_FOUND if camp else CreatureWords.VILLAGE_FOUND % str(CreatureWords.village(universe).name))
		Audio.play(&"sparkle")
	if robot:
		robot.point_at = robot_target()
		match RobotRules.quest_step(found):
			RobotRules.OFFER:
				robot.show_mark("!")
			RobotRules.BACK:
				robot.show_mark("?")
			_:
				robot.show_mark("")
	_wake(child)
	var buddy := profile.creatures.buddy if profile else ""
	if camp:
		camp.explorer.visible = buddy != String(camp.explorer.creature_id)   # it walks with the child now
	if village:
		village.chief.visible = buddy != String(village.chief.creature_id)


## Far from the child, the robot by the pad and the aliens sleep (no thinking, no easing); the rover and the drone
## are always with the child.
func _wake(child: Vector3) -> void:
	var sleepers: Array[Node] = []
	if robot:
		sleepers.append(robot)
	if camp:
		sleepers.append_array(camp.aliens())
	if village:
		sleepers.append_array(village.aliens())
		village.set_process(village.playing or _near(village.global_position, child, SpaceCreature.WAKE_R))
	for n in sleepers:
		n.set_process(_near((n as Node3D).global_position, child, SpaceCreature.WAKE_R))


static func _near(a: Vector3, b: Vector3, r: float) -> bool:
	return b.is_finite() and Vector2(a.x - b.x, a.z - b.z).length() <= r


# --- Where to go --------------------------------------------------------------------------------------------------

## Where the robot points: the quest's place while the child explores it, else the guide's next place (where the
## HUD's compass points), else the aliens.
func robot_target() -> Vector3:
	var from := robot.global_position if robot else _child()
	if RobotRules.quest_step(found) == RobotRules.FIND:
		var p := place_position(RobotRules.quest_place(found))
		if p.is_finite():
			return p
	var next := _guide_next(from)
	if not next.is_empty():
		return next.pos
	return site.get("pos", Vector3.INF)


## Where the drone scouts: the quest's place or the guide's next place from the child, else the aliens until visited,
## else nowhere (it circles over the child).
func drone_target() -> Vector3:
	var child := _child()
	if not child.is_finite():
		return Vector3.INF
	if RobotRules.quest_step(found) == RobotRules.FIND:
		var p := place_position(RobotRules.quest_place(found))
		if p.is_finite():
			return p
	var next := _guide_next(child)
	if not next.is_empty():
		return next.pos
	return site.get("pos", Vector3.INF) if not found.has(RobotRules.CAMP) else Vector3.INF


## A quest place's position ("sight:<id>" or RobotRules.CAMP_PLACE), INF for none.
func place_position(place: String) -> Vector3:
	if place == RobotRules.CAMP_PLACE:
		return site.get("pos", Vector3.INF)
	var id := StringName(place.trim_prefix(SpaceSights.PREFIX))
	for s: Dictionary in _spots:
		if s.id == id:
			return s.pos
	return Vector3.INF


func _place_name(place: String) -> String:
	if place == RobotRules.CAMP_PLACE or place == "":
		return tr("the aliens' camp") if camp else tr("the alien village")
	var id := StringName(place.trim_prefix(SpaceSights.PREFIX))
	return tr(str(sights.get(id, {}).get("name", id)))


func _guide_next(from: Vector3) -> Dictionary:
	if _spots.is_empty():
		return {}
	return PlanetGuideRules.next(PlanetGuideRules.checklist(_spots, sights, found, from), from)


## What the robot says about where to go next.
func where_words() -> String:
	var next := _guide_next(robot.global_position if robot else _child())
	if not next.is_empty():
		return tr(CreatureWords.POINT_WORDS) % tr(str(next.name))
	if camp:
		return tr(CreatureWords.POINT_CAMP)
	if village:
		return tr(CreatureWords.POINT_VILLAGE)
	return tr(CreatureWords.ALL_EXPLORED)


# --- The robot ------------------------------------------------------------------------------------------------------

## The child came near the robot the first time: its hello, then where to go.
func _greet() -> void:
	var r := CreatureWords.robot(universe)
	robot.say(str(r.hello))
	if is_inside_tree():
		get_tree().create_timer(NEXT_WORDS_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(robot):
				robot.say(where_words()))


func _on_robot(_c: SpaceCreature) -> void:
	if card == null:
		return
	var r := CreatureWords.robot(universe)
	var title := tr(CreatureWords.ROBOT_TITLE) % str(r.name)
	var place := RobotRules.quest_place(found)
	match RobotRules.quest_step(found):
		RobotRules.OFFER:
			card.show_page(title, [r.hello, r.fact, where_words(), CreatureWords.QUEST_OFFER],
				[[{"text": CreatureWords.QUEST_GO, "call": _start_quest}, {"text": CreatureWords.NOT_NOW, "color": Color()}]])
		RobotRules.DIG:
			card.show_page(title, [CreatureWords.QUEST_DIG, r.fact], [[{"text": "OK"}]], true)
		RobotRules.FIND:
			card.show_page(title, [tr(CreatureWords.QUEST_FIND) % _place_name(place)], [[{"text": "OK"}]], true)
		RobotRules.BACK:
			_ask(title, [CreatureWords.QUEST_ASK])
		_:
			if RobotRules.has_unpaid(universe, profile.creatures):
				card.show_page(title, [CreatureWords.QUIZ_MORE, r.fact, where_words()],
					[[{"text": CreatureWords.QUEST_ANOTHER, "call": _ask.bind(title, [])}, {"text": "OK", "color": Color()}]])
			else:
				card.show_page(title, [CreatureWords.QUIZ_ALL, r.fact, where_words()], [[{"text": "OK"}]])
	robot.say(card.spoken.get_slice(".", 0) + ".")


func _start_quest() -> void:
	var next := _guide_next(robot.global_position)
	RobotRules.start_quest(found, StringName(next.id) if not next.is_empty() else &"")
	card.close()
	_say(CreatureWords.QUEST_DIG)
	robot.cheer()
	tick()


func _ask(title: String, before: Array) -> void:
	_question = RobotRules.next_question(universe, profile.creatures)
	_tries = 0
	if _question.is_empty():
		return
	card.show_question(title, before, str(_question.q), _question.choices, _answer)


func _answer(choice: int) -> void:
	if _question.is_empty():
		return
	var q := _question
	if RobotRules.is_right(q, choice):
		var first := _tries == 0
		var gold := RobotRules.quiz_gold(profile.creatures, str(q.id), first)
		var said := tr(CreatureWords.QUIZ_RIGHT if first else CreatureWords.QUIZ_RIGHT_AGAIN)
		if gold > 0 and EarnRules.credit(profile, gold) > 0:
			said += " " + tr("+%d gold!") % gold
			if gold_changed.is_valid():
				gold_changed.call(profile.survivor_gold)
		Audio.play(&"jingle_goal")
		_after_question(said)
		return
	_tries += 1
	if choice >= 0 and choice < card.choice_buttons.size():
		card.choice_buttons[choice].disabled = true
	if _tries >= 2:
		_after_question(tr(CreatureWords.QUIZ_ANSWER) % tr(str(q.choices[int(q.answer)])))
	else:
		card.add_line(tr(CreatureWords.QUIZ_NOT_YET) % tr(str(q.hint)), false)


func _after_question(said: String) -> void:
	for b in card.choice_buttons:
		b.disabled = true
	card.add_line(said)
	if RobotRules.quest_step(found) == RobotRules.BACK and RobotRules.finish(found):
		card.add_line(CreatureWords.QUEST_DONE)
		robot.cheer()
		Audio.play(&"jingle_badge")
	_save()
	var title := card.title_label.text if card.title_label else ""
	var more: Array = []
	if RobotRules.has_unpaid(universe, profile.creatures):
		more.append({"text": CreatureWords.QUEST_ANOTHER, "call": _ask.bind(title, [])})
	more.append({"text": "OK", "color": Color() if not more.is_empty() else UiKit.GREEN})
	card.add_buttons(more)
	_question = {}
	tick()


# --- The rover and the drone -----------------------------------------------------------------------------------

func _on_rover(_c: SpaceCreature) -> void:
	var r := CreatureWords.robot(universe)
	var first := RobotRules.dig(found)
	rover.dig()
	_say(CreatureWords.ROVER_DIGS if first else CreatureWords.ROVER_AGAIN)
	if not is_inside_tree():
		return
	get_tree().create_timer(SAY_DELAY).timeout.connect(func() -> void:
		_say(str(r.sample))
		if is_instance_valid(rover):
			rover.say(str(r.sample)))
	tick()


func _on_drone(_c: SpaceCreature) -> void:
	var to := drone_target()
	var place := ""
	var aliens := false
	if to.is_finite():
		var next := _guide_next(_child())
		if RobotRules.quest_step(found) == RobotRules.FIND:
			place = _place_name(RobotRules.quest_place(found))
			aliens = RobotRules.quest_place(found) == RobotRules.CAMP_PLACE
		elif not next.is_empty():
			place = tr(str(next.name))
		else:
			aliens = true
	var words := RobotRules.drone_words(_child(), to, place, aliens)
	_say(words)
	drone.say(words)


# --- The aliens ---------------------------------------------------------------------------------------------------

func _on_alien(c: SpaceCreature) -> void:
	var a := c as Alien
	if a == null:
		return
	match a.role:
		&"explorer":
			_explorer_card(a)
		&"trader":
			_trader_card(a)
		&"chief":
			_chief_card(a)
		_:
			var lines := CreatureWords.VILLAGER_LINES
			a.say(lines[absi(hash(String(a.creature_id)) + _plays + Time.get_ticks_msec() / 997) % lines.size()])
			a.cheer()


func _explorer_card(a: Alien) -> void:
	if card == null:
		return
	var id := a.creature_id
	var info := CreatureWords.alien(id)
	var data := profile.creatures
	var title := tr("%s the explorer") % a.display_name
	var state := AlienRules.state(data, id, found.has(RobotRules.SAMPLE))
	var lines: Array = []
	var rows: Array = []
	match state:
		AlienRules.FRIEND:
			lines = [CreatureWords.FRIEND_HELLO, info.pretend, CreatureWords.HONEST, info.science]
			rows = [[{"text": CreatureWords.COME, "call": _come_along.bind(a)}, {"text": "OK", "color": Color()}]]
		AlienRules.BUDDY:
			lines = [CreatureWords.BUDDY_HELLO, CreatureWords.HONEST]
			rows = [[{"text": "OK"}]]
		_:
			lines = [tr(CreatureWords.MEET) % a.display_name if state == AlienRules.NEW else CreatureWords.AGAIN,
				info.pretend, CreatureWords.HONEST, info.science, info.asks]
			if state == AlienRules.CAN_GIVE or found.has(RobotRules.SAMPLE):
				rows = [[{"text": CreatureWords.GIVE, "call": _give_sample.bind(a)},
					{"text": CreatureWords.NOT_NOW, "color": Color()}]]
			else:
				lines.append(CreatureWords.WANTS_SAMPLE)
				rows = [[{"text": "OK"}]]
	if data.meet(id):
		_save()
	card.show_page(title, lines, rows)
	a.say(str(lines[0]))


func _give_sample(a: Alien) -> void:
	var gift := AlienRules.befriend(profile, a.creature_id)
	if gift == "":
		card.close()
		return
	_save()
	a.cheer()
	Audio.play(&"jingle_badge")
	_offer_friendship(a, gift)


## A new friend's thanks, its present, and whether it may come along.
func _offer_friendship(a: Alien, gift: String) -> void:
	var who := profile.username if profile.username != "" else tr("explorer")
	var thanks := tr(CreatureWords.THANKS) % [who, tr(str(CreatureWords.souvenir(gift).get("name", "")))]
	card.show_page(tr("%s is your friend!") % a.display_name, [thanks, str(CreatureWords.souvenir(gift).get("story", "")),
		CreatureWords.COME_ASK], [[{"text": CreatureWords.COME, "call": _come_along.bind(a)},
		{"text": CreatureWords.NOT_NOW, "color": Color()}]], true)
	a.say(thanks)


func _come_along(a: Alien) -> void:
	var before := AlienRules.come_along(profile, a.creature_id)
	_save()
	card.close()
	if before != "":
		if send_home.is_valid():
			send_home.call(AlienRules.mini_kind(StringName(before)))
		_say(tr(CreatureWords.ONE_BUDDY) % CreatureWords.alien_name(StringName(before)))
	if bring_buddy.is_valid():
		bring_buddy.call()
	_say(tr(CreatureWords.COMES) % a.display_name)
	if a.is_inside_tree():
		Fx.burst(get_tree().root, a.tap_center(), Color("ffd23f"), 16, 3.0)
	tick()


func _trader_card(a: Alien, said := "") -> void:
	if card == null:
		return
	var info := CreatureWords.alien(a.creature_id)
	var data := profile.creatures
	if data.meet(a.creature_id):
		_save()
	var lines: Array = [info.hello, CreatureWords.HONEST]
	if said != "":
		lines.push_front(said)
	lines.append(tr(CreatureWords.YOUR_GOLD) % profile.survivor_gold)
	var mine: Array[String] = []
	for id in data.souvenirs:
		mine.append(tr(str(CreatureWords.souvenir(id).get("name", id))))
	if not mine.is_empty():
		lines.append(tr(CreatureWords.YOUR_SOUVENIRS) % ", ".join(PackedStringArray(mine)))
	var row: Array = []
	for id in AlienRules.stock(a.creature_id):
		var s := CreatureWords.souvenir(id)
		if data.owns(id):
			row.append({"text": tr("%s (yours!)") % tr(str(s.name)), "disabled": true, "color": Color()})
		else:
			row.append({"text": "%s: %d gold" % [tr(str(s.name)), AlienRules.price(id)], "color": UiKit.ORANGE,
				"call": _buy.bind(a, id)})
	card.show_page(tr("%s the trader") % a.display_name, lines, [row, [{"text": "OK"}]], said != "")
	if said == "":
		a.say(str(info.hello))


func _buy(a: Alien, id: String) -> void:
	var s := CreatureWords.souvenir(id)
	match AlienRules.buy(profile, id):
		SpendRules.OK:
			_save()
			if gold_changed.is_valid():
				gold_changed.call(profile.survivor_gold)
			a.cheer()
			Audio.play(&"jingle_goal")
			_trader_card(a, tr(CreatureWords.GOT) % [tr(str(s.name)), tr(str(s.story))])
		SpendRules.NOT_ENOUGH:
			card.add_line(tr(CreatureWords.NEED_GOLD) % (AlienRules.price(id) - profile.survivor_gold), false)
		_:
			_trader_card(a)


func _chief_card(a: Alien) -> void:
	if card == null or village == null:
		return
	var info := CreatureWords.alien(a.creature_id)
	var data := profile.creatures
	if data.meet(a.creature_id):
		_save()
	var row: Array = [{"text": CreatureWords.PLAY_ECHO, "call": _start_echo}]
	var state := AlienRules.state(data, a.creature_id, false)
	if state == AlienRules.FRIEND:
		row.append({"text": CreatureWords.COME, "call": _come_along.bind(a), "color": UiKit.ORANGE})
	row.append({"text": CreatureWords.NOT_NOW, "color": Color()})
	var title := tr("%s, the chief of %s") % [a.display_name, tr(str(CreatureWords.village(universe).name))]
	card.show_page(title, [info.pretend, CreatureWords.HONEST, info.science, CreatureWords.ECHO_OFFER], [row])
	a.say(str(info.pretend))


func _start_echo() -> void:
	card.close()
	village.start_game(world_seed + _plays * 7919)
	_plays += 1
	_say(CreatureWords.ECHO_OFFER)


func _on_echo(result: StringName) -> void:
	match result:
		AlienVillage.YOUR_TURN:
			_say(CreatureWords.ECHO_YOUR_TURN)
			village.chief.say(CreatureWords.ECHO_YOUR_TURN)
		EchoGame.ROUND_DONE:
			_say(CreatureWords.ECHO_RIGHT)
			village.chief.say(CreatureWords.ECHO_RIGHT)
		EchoGame.NOT_YET:
			_say(CreatureWords.ECHO_NOT_YET)
			village.chief.say(CreatureWords.ECHO_NOT_YET)
		EchoGame.WON:
			Audio.play(&"jingle_badge")
			var chief := village.chief
			var gift := AlienRules.befriend(profile, chief.creature_id)
			if gift != "":
				_save()
				if card:
					_offer_friendship(chief, gift)
			else:
				_say(tr(CreatureWords.ECHO_WON) + " " + tr(CreatureWords.ECHO_AGAIN))
				chief.say(CreatureWords.ECHO_WON)


func _say(text: String) -> void:
	if toast.is_valid():
		toast.call(tr(text))


func _save() -> void:
	if save_profile.is_valid():
		save_profile.call()


## The card is open (the sandbox's overlays; Esc and Back close it).
func card_open() -> bool:
	return card != null and card.is_open()
