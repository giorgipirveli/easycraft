class_name QuestDirector
extends Node
## Quests in a world (owner #45a, spec §14.17). The sandbox adds one on every peer, named "Quests", so its
## RPCs line up. For this game's child (the Progress autoload's data, QuestRules' rules):
## - places the universe's quest giver by the spawn (Tilly as a figure in a Sandbox — in Survivor she is the
##   trader at her stall —, Zara, Bram or Mimi in their universes; none in the Monster Wave arena), from the
##   seed alone, and keeps each giver's picture bubble ("!" a story waits, "?" come back to me);
## - a tap on a giver opens its card (start a story, go on with it, Tilly's SHOP);
## - moves the story being followed on: counting steps from the child's events (Progress.counted), "come
##   back" steps by walking up to the giver, "follow the arrow" steps by walking to the place; each step and
##   story done is celebrated and counted (quest_step, quest_done/<chain>); a story done gives its keepsake,
##   title and place (QuestRules.finish) and, in Survivor, its fixed gold from the host once;
## - points the HUD's arrow (a FindArrow in the compass's spot) at the step's place, when the child wants it.
## Co-op (the host decides): PLAY TOGETHER shares the host's story; every game sends its matching events to the
## host, the host counts them and the arrivals of any player, and everyone who helped gets the rewards.
## Decisions once a second (nothing per frame but a timer); places are looked up on a worker thread.

signal changed

const TICK := 1.0
const GIVER_NEAR := 4.5          # walking up this close to the giver is coming back
const REACH_NEAR := 12.0         # sideways, to a "follow the arrow" place
const REACH_HIGH := 30.0         # ... and up or down
const HELP_NEAR := 24.0          # co-op: players this close to a step done helped with it
const TARGET_RADIUS := 420.0     # how far the arrow looks for a place (then twice as far)
const TEAM_EVENTS := 20          # co-op: a guest's events the host counts ...
const TEAM_WINDOW_MS := 10_000   # ... in this long (LAN is trusted; this stops a flood)
const ASK_GAP_MS := 1500         # a guest asks the host where a place is at most this often

# --- Injected by the sandbox (tests use stand-ins) ---
var player: Player
var hud: Hud
var secrets: SecretDirector
var mode: StringName = ModeRules.SANDBOX
var universe := 1
var world_seed := 0
## A LAN guest's game never saves the world, so it saves the profile when a story moves on.
var saves_profile := false
var save_profile: Callable = func() -> void: Profile.save()
var survivor: Callable = _is_survivor
## (kind, from) -> Vector3: a place of a secret kind nobody found (INF: none). Unset: the world's secrets
## (a worker thread on the host or solo; a guest asks the host).
var find_target: Callable
var is_host: Callable = func() -> bool: return Session.is_host()
var own_peer: Callable = _own_peer
## The other players' games (co-op).
var others: Callable = _peers
## Host: pays `gold` to `peer` (Survivor gold through the host's wallet).
var give_gold: Callable = func(peer: int, gold: int) -> void: Session.gold_add(peer, gold, "quest")
## This game's child finished a story in Survivor: ask the host for its gold.
var ask_gold: Callable = request_gold
## Host → a helper's game: the shared story is done (peer, chain id, place).
var send_reward: Callable = _send_reward
var auto_tick := true

## Giver id -> the Node3D a child walks up to (a QuestGiver, or Tilly's stall in Survivor).
var givers := {}
var arrow: FindArrow
## The child's choice: the arrow shows the way (the quest book's ARROW).
var arrow_on := true
## Host: the shared story {"chain": id, "helpers": {peer: true}} ({} = none).
var team := {}
## Every game: the shared story as the host tells it {"chain", "step", "have", "need", "target"} ({} = none).
var team_view := {}

var book: QuestBook
var card: QuestCard
var more_button: TouchButton

var _t := 0.0
var _busy := false                # a step is being handled (the events it counts wait for the next check)
var _step_by := 0                 # host: the player whose event did the step being handled (0: this game's)
var _places := {}                 # chain id -> Vector3: where its "place" step was done (this session)
var _found := {}                  # secret kind -> Vector3: the nearest place nobody found (INF: none near)
var _asking := {}                 # secret kind -> true while a worker (or the host) looks for it
var _asked_ms := {}               # secret kind -> when a guest last asked the host
var _tasks: Array[int] = []
var _team_events := {}            # host: peer -> [window start ms, count]
var _paid := {}                   # host: "peer:chain" -> true (a story's gold once per player this session)
var _guest_targets := {}          # host: peer -> Vector3 (bots lead a guest to its own story's place)
var _last_sent_target := Vector3.INF


func _ready() -> void:
	Progress.counted.connect(_on_counted)


func _exit_tree() -> void:
	for id in _tasks:
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
	if Progress.counted.is_connected(_on_counted):
		Progress.counted.disconnect(_on_counted)


func data() -> ProgressData:
	return Progress.data()


func _is_survivor() -> bool:
	return mode == ModeRules.SURVIVOR


func _own_peer() -> int:
	return multiplayer.get_unique_id()


func _peers() -> Array:
	return Array(multiplayer.get_peers())


func _process(delta: float) -> void:
	if not auto_tick:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


## Whether this world tells stories (not the Monster Wave arena).
func tells_stories() -> bool:
	return mode == ModeRules.SANDBOX or mode == ModeRules.SURVIVOR


## An RPC to one peer, only when it is connected (tests and solo play have none).
func _send(peer: int, method: StringName, args: Array) -> void:
	if is_inside_tree() and multiplayer.get_peers().has(peer):
		callv(&"rpc_id", [peer, method] + args)


# --- The givers -------------------------------------------------------------------------------------------

## Places this universe's giver by the spawn (every game, from the seed): Tilly as a figure where her stall
## would be (Sandbox; Survivor has the stall itself), a helper where QuestRules puts it (a worker thread).
func place_givers(shape: MeadowsShape, spawn: Vector2i) -> void:
	if not tells_stories() or shape == null:
		return
	var id := QuestRules.giver_in(universe)
	if id == &"":
		return
	if id == &"tilly":
		if mode != ModeRules.SURVIVOR:
			var stall := TraderRules.stall_for_world(world_seed, shape, spawn)
			add_giver(id, stall.pos, float(stall.yaw))
		return
	var s := world_seed
	_tasks.append(WorkerThreadPool.add_task(func() -> void:
		var spot := QuestRules.giver_for_world(s, shape, spawn)
		_add_giver_later.call_deferred(id, spot)))


func _add_giver_later(id: StringName, spot: Dictionary) -> void:
	if is_inside_tree() and not givers.has(id):
		add_giver(id, spot.pos, float(spot.yaw))


## Adds a giver figure at `pos` (feet) facing `yaw`.
func add_giver(id: StringName, pos: Vector3, yaw: float) -> QuestGiver:
	var g := QuestGiver.new()
	g.setup({"id": id, "pos": pos, "yaw": yaw})
	add_child(g)
	givers[id] = g
	_update_bubbles(data())
	return g


## Tilly's stall in Survivor (the trader the host spawned; guests get her through the spawner).
func _tilly_stall() -> Node3D:
	if universe != 1 or mode != ModeRules.SURVIVOR or not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group(&"traders"):
		if n is Node3D and not n.is_queued_for_deletion():
			return n
	return null


func _giver_node(id: StringName) -> Node3D:
	var n: Variant = givers.get(id)
	if n is Node3D and is_instance_valid(n) and not (n as Node).is_queued_for_deletion():
		return n
	if id == &"tilly":
		var t := _tilly_stall()
		if t:
			givers[id] = t
		return t
	return null


## What this giver's bubble says to this game's child: "?" (come back to me), "!" (a story waits) or "".
func bubble_for(d: ProgressData, giver_id: StringName) -> String:
	var active := d.quests.active
	if active != &"" and QuestRules.chain(active).giver == giver_id \
			and QuestRules.current_step(d, active).get("type", &"") == QuestRules.GO:
		return QuestGiver.BUBBLE_BACK
	var offered := QuestRules.offered(d, giver_id, mode)
	return QuestGiver.BUBBLE_NEW if offered != &"" and offered != active else ""


func _update_bubbles(d: ProgressData) -> void:
	for id: StringName in QuestRules.GIVERS:
		var n := _giver_node(id)
		if n == null:
			continue
		var text := bubble_for(d, id)
		if n is QuestGiver:
			(n as QuestGiver).show_bubble(text)
		else:
			_stall_bubble(n, text)


## Tilly's stall gets a bubble of its own (a label over the awning).
func _stall_bubble(stall: Node3D, text: String) -> void:
	var b := stall.get_node_or_null("QuestBubble") as Label3D
	if b == null:
		if text == "":
			return
		b = Label3D.new()
		b.name = "QuestBubble"
		b.font_size = 110
		b.outline_size = 22
		b.pixel_size = 0.006
		b.modulate = Color("ffd23f")
		b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b.no_depth_test = true
		b.position = Vector3(0, 3.9, 0)
		stall.add_child(b)
	b.text = text
	b.visible = text != ""


## A tap on Tilly's stall: her card when she has something to say to this child (else her shop opens).
func wants_stall_tap() -> bool:
	return tells_stories() and universe == 1 and bubble_for(data(), &"tilly") != ""


# --- Every second -------------------------------------------------------------------------------------------

## One look (TICK seconds of play have passed; tests call it directly).
func tick() -> void:
	_prune_tasks()
	if not tells_stories():
		return
	var d := data()
	_check_steps(d)
	_arrivals(d)
	_finish_ready(d)
	_update_arrow()
	_update_bubbles(d)


func _prune_tasks() -> void:
	var left: Array[int] = []
	for id in _tasks:
		if WorkerThreadPool.is_task_completed(id):
			WorkerThreadPool.wait_for_task_completion(id)   # returns at once; frees the task
		else:
			left.append(id)
	_tasks = left


func _player_pos() -> Vector3:
	return player.global_position if is_instance_valid(player) and player.is_spawned() else Vector3.INF


## Steps that counted enough move on (`by`: the player whose event did it; 0 this game's).
func _check_steps(d: ProgressData, by: int = 0) -> void:
	if _busy:
		return
	_busy = true
	_step_by = by
	for e in QuestRules.check(d):
		_on_step_done(d, e)
	_step_by = 0
	_busy = false


## A story whose steps are all done (a load in between, a friend's help) gets its rewards now.
func _finish_ready(d: ProgressData) -> void:
	for id: String in d.quests.chains.keys():
		if QuestRules.is_ready_to_finish(d, StringName(id)):
			_finish(d, StringName(id))


## "Come back" and "follow the arrow" steps: this child walked there (the host: any player, for the shared story).
func _arrivals(d: ProgressData) -> void:
	var id := d.quests.active
	if id == &"" or QuestRules.universe_of(id) != universe:
		return
	var s := QuestRules.current_step(d, id)
	if s.is_empty() or s.type == QuestRules.DO:
		return
	var at := _step_target(id, QuestRules.step_index(d, id))
	if not at.is_finite():
		return
	var shared: bool = is_host.call() and team.get("chain", &"") == id
	for p in _players(shared):
		if not _arrived(s.type, p.global_position, at):
			continue
		var i := QuestRules.step_index(d, id)
		if QuestRules.arrive(d, id, s.type):
			_busy = true
			_step_by = p.peer_id if p != player else 0
			_on_step_done(d, {"chain": id, "step": i, "finished": QuestRules.is_ready_to_finish(d, id)})
			_step_by = 0
			_busy = false
		return


func _players(all: bool) -> Array[Player]:
	var out: Array[Player] = []
	if all and is_inside_tree():
		for n in get_tree().get_nodes_in_group(&"players"):
			var p := n as Player
			if is_instance_valid(p) and p.is_spawned():
				out.append(p)
	elif is_instance_valid(player) and player.is_spawned():
		out.append(player)
	return out


func _arrived(type: StringName, feet: Vector3, at: Vector3) -> bool:
	var flat := Vector2(feet.x - at.x, feet.z - at.z).length()
	if type == QuestRules.GO:
		return flat <= GIVER_NEAR and absf(feet.y - at.y) <= 4.0
	return flat <= REACH_NEAR and absf(feet.y - at.y) <= REACH_HIGH


## A step was done: counted, celebrated, the shared story told; the last step gives the rewards.
func _on_step_done(d: ProgressData, e: Dictionary) -> void:
	var id: StringName = e.chain
	var steps := QuestRules.steps_of(id)
	var i := int(e.step)
	var by := _step_by if _step_by != 0 else int(own_peer.call())
	var by_at := _pos_of(by)
	if i >= 0 and i < steps.size() and steps[i].get("place", false) and by_at.is_finite():
		_places[id] = by_at
	Progress.event(LevelRules.QUEST_STEP)
	if is_host.call() and team.get("chain", &"") == id:
		_helped_near(by, by_at)
	if e.finished:
		_finish(d, id)
	else:
		var next := QuestRules.current_step(d, id)
		_banner(tr("Well done! Next: %s") % str(next.get("words", "")))
		Audio.play(&"jingle_badge")
		_saved()
		_send_team()
	_found.clear()   # the next step looks for its own place
	changed.emit()


## Where a player stands (this game's own, or another player's body on the host).
func _pos_of(peer: int) -> Vector3:
	if peer == int(own_peer.call()) or peer == 0:
		return _player_pos()
	for p in _players(true):
		if p.peer_id == peer:
			return p.global_position
	return Vector3.INF


## The story is done: its keepsake, title and place (once), the celebration, Survivor gold from the host,
## and the helpers' rewards when it was shared.
func _finish(d: ProgressData, id: StringName) -> void:
	var place := _place_for(id)
	if not QuestRules.finish(d, id, place):
		return
	Progress.event(StringName("%s/%s" % [LevelRules.QUEST_DONE, id]))
	_celebrate(id)
	if is_host.call() and team.get("chain", &"") == id:
		var helped: Dictionary = team.helpers
		for peer: int in helped:
			if peer != int(own_peer.call()) and others.call().has(peer):
				send_reward.call(peer, id, place)
		team.clear()
	_send_team()
	_saved()
	changed.emit()


func _place_for(id: StringName) -> Dictionary:
	var at: Vector3 = _places.get(id, _player_pos())
	if not at.is_finite():
		return {}
	return {"u": universe, "seed": world_seed, "x": at.x, "y": at.y, "z": at.z}


func _celebrate(id: StringName) -> void:
	var c := QuestRules.chain(id)
	var gold := QuestRules.gold_for(id) if survivor.call() else 0
	var k := QuestRules.keepsake(id)
	_banner(tr("Story done: %s! You got %s%s") % [str(c.title), str(k.get("words", "")).to_lower(),
		(tr(" and %d gold") % gold) if gold > 0 else ""])
	Audio.play(&"jingle_goal")
	if is_instance_valid(player) and player.is_inside_tree():
		var s := player.size_scale()
		Celebration.confetti(player.get_parent(), player.eye_position() + Vector3.UP * 0.6 * s, s)
	if gold > 0:
		ask_gold.call(id)


func _banner(text: String) -> void:
	if is_instance_valid(hud):
		hud.show_banner(text, Riddles.STAR)


func _saved() -> void:
	if saves_profile:
		save_profile.call()


## A counted event: the story moves on at once; a shared story's matching events go to the host.
func _on_counted(kind: StringName, amount: int) -> void:
	if not is_inside_tree() or not tells_stories():
		return
	_check_steps(data())
	if not team_view.is_empty() and not is_host.call():
		var s := QuestRules.steps_of(StringName(str(team_view.get("chain", ""))))
		var i := int(team_view.get("step", -1))
		if i >= 0 and i < s.size() and s[i].type == QuestRules.DO and QuestRules.matches(s[i].kind, kind):
			_send(1, &"_rpc_team_event", [String(kind), amount])
	if LevelRules.family(kind) == LevelRules.SECRET:
		_found.clear()   # that place is found now: the arrow looks again


# --- Starting, stopping, the card ----------------------------------------------------------------------------

## Starts (or goes on with) a story this game's child picked on a giver's card.
func start_chain(id: StringName) -> bool:
	var d := data()
	if not tells_stories() or not QuestRules.allowed_in(id, mode) or not QuestRules.start(d, id):
		return false
	_stop_sharing_unless(id)
	_found.clear()
	arrow_on = true
	_saved()
	tick()
	changed.emit()
	return true


func resume_chain(id: StringName) -> bool:
	var d := data()
	if not QuestRules.allowed_in(id, mode) or not QuestRules.resume(d, id):
		return false
	_stop_sharing_unless(id)
	_found.clear()
	_saved()
	tick()
	changed.emit()
	return true


## Stops the story being followed; it waits where it was.
func stop_chain() -> void:
	QuestRules.stop(data())
	_stop_sharing_unless(&"")
	_saved()
	tick()
	changed.emit()


func _stop_sharing_unless(id: StringName) -> void:
	if not team.is_empty() and team.chain != id:
		team.clear()
		_send_team()


## A tap on a giver (or on Tilly's stall with something to say): a tap reaches only a giver close by, so a
## "come back to me" step is done by it; then the giver's card.
func open_card(giver_id: StringName) -> void:
	var d := data()
	var id := d.quests.active
	if id != &"" and QuestRules.chain(id).giver == giver_id and QuestRules.universe_of(id) == universe:
		var i := QuestRules.step_index(d, id)
		if QuestRules.arrive(d, id, QuestRules.GO):
			_busy = true
			_on_step_done(d, {"chain": id, "step": i, "finished": QuestRules.is_ready_to_finish(d, id)})
			_busy = false
			_update_bubbles(d)
	if card:
		card.open_for(giver_id)
	var giver := _giver_node(giver_id)   # M3 Task 21a: the giver says hello in babble
	if giver:
		BabbleVoices.say(giver, &"tilly" if giver_id == &"tilly" else &"giver", BabbleRules.NORMAL_SIZE,
			"Hello, friend! I have a story for you.", true, String(giver_id))


func set_arrow(on: bool) -> void:
	arrow_on = on
	_update_arrow()
	changed.emit()


## The quest book's places: the arrow points at a place a story led to in this world.
func point_to_place(place: Dictionary) -> bool:
	if arrow == null or int(place.get("seed", 0)) != world_seed or int(place.get("u", 0)) != universe:
		return false
	var c := QuestRules.chain(StringName(str(place.get("chain", ""))))
	arrow.player = player
	arrow.point_to(str(c.get("title", "")), Vector3(float(place.x), float(place.y), float(place.z)))
	arrow_on = false   # the story's own arrow steps aside while this one shows
	return true


# --- The arrow and the places ---------------------------------------------------------------------------------

## Where the step `i` of `chain_id` leads (INF: nowhere to show, or not found yet).
func _step_target(chain_id: StringName, i: int) -> Vector3:
	var steps := QuestRules.steps_of(chain_id)
	if i < 0 or i >= steps.size() or QuestRules.universe_of(chain_id) != universe:
		return Vector3.INF
	var s: Dictionary = steps[i]
	match s.type:
		QuestRules.GO:
			var g := _giver_node(QuestRules.chain(chain_id).giver)
			return g.global_position if g else Vector3.INF
		QuestRules.REACH:
			return place_of(s.kind)
	return place_of(s.find) if s.has("find") else Vector3.INF


## What the arrow's words say for step `i`.
func _step_label(chain_id: StringName, i: int) -> String:
	var steps := QuestRules.steps_of(chain_id)
	if i < 0 or i >= steps.size():
		return ""
	var s: Dictionary = steps[i]
	if s.type == QuestRules.GO:
		return str(QuestRules.giver(QuestRules.chain(chain_id).giver).get("name", ""))
	return "the " + SecretDirector.hint_name(s.kind if s.type == QuestRules.REACH else s.get("find", &""))


## The nearest place of a secret kind nobody found, around this child (INF while it is looked for, or none).
func place_of(kind: StringName) -> Vector3:
	if kind == &"":
		return Vector3.INF
	if _found.has(kind):
		return _found[kind]
	var from := _player_pos()
	if not from.is_finite():
		return Vector3.INF
	if find_target.is_valid():
		_found[kind] = find_target.call(kind, from)
		return _found[kind]
	_look_for(kind, from)
	return Vector3.INF


## Host or solo: a worker thread looks through the secrets around `from`; a guest asks the host.
func _look_for(kind: StringName, from: Vector3) -> void:
	if _asking.has(kind) or secrets == null or secrets.rules == null:
		return
	if not is_host.call():
		var now := Time.get_ticks_msec()
		if now - int(_asked_ms.get(kind, -ASK_GAP_MS)) < ASK_GAP_MS:
			return
		_asked_ms[kind] = now
		_send(1, &"_rpc_ask_target", [String(kind), from])
		return
	_asking[kind] = true
	var skip := secrets.state.found.duplicate()
	skip.merge(secrets.state.opened)
	var rules := secrets.rules
	_tasks.append(WorkerThreadPool.add_task(func() -> void:
		var at := QuestDirector.nearest_place(rules, kind, from, skip, TARGET_RADIUS)
		if not at.is_finite():
			at = QuestDirector.nearest_place(rules, kind, from, skip, TARGET_RADIUS * 2.0)
		_got_place.call_deferred(kind, at, 0)))


func _got_place(kind: StringName, at: Vector3, for_peer: int) -> void:
	if for_peer != 0:
		_send(for_peer, &"_rpc_target", [String(kind), at])
		return
	_asking.erase(kind)
	_found[kind] = at
	_update_arrow()


## The nearest place of `kind` within `radius` of `from` that is not in `skip` (secret ids), where a child
## goes to find it (next to a buried chest, at a hidden room's fake wall, at a place's entrance). Pure.
static func nearest_place(rules: SecretRules, kind: StringName, from: Vector3, skip: Dictionary, radius: float) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	if radius <= 0.0:
		return best
	for s: Dictionary in rules.secrets_near(from, radius):
		if s.kind != kind or skip.has(s.id):
			continue
		var at: Vector3
		match kind:
			SecretRules.TREASURE, SecretRules.ISLAND:
				at = Vector3(s.chest as Vector3i)
			SecretRules.ROOM:
				at = Vector3((s.fake_wall[0] as Vector3i) + (s.dir as Vector3i))
			_:
				at = Vector3(s.get("visit", s.anchor) as Vector3i)
		at += Vector3(0.5, 0.0, 0.5)
		var d := Vector2(at.x - from.x, at.z - from.z).length()
		if d < best_d:
			best_d = d
			best = at
	return best


## The HUD's arrow: the shared story's place, else this child's story's; hidden when the child turned it off.
func _update_arrow() -> void:
	var target := Vector3.INF
	var label := ""
	if not team_view.is_empty() and not is_host.call():
		target = team_view.get("target", Vector3.INF)
		label = _step_label(StringName(str(team_view.chain)), int(team_view.step))
	else:
		var d := data()
		var id := d.quests.active
		if id != &"":
			var i := QuestRules.step_index(d, id)
			target = _step_target(id, i)
			label = _step_label(id, i)
		if not is_host.call() and target != _last_sent_target and target.is_finite():
			_last_sent_target = target
			_send(1, &"_rpc_my_target", [target])   # the host's bot friends lead this child there
	if arrow == null:
		return
	var here := _player_pos()
	if here.is_finite() and target.is_finite() and Vector2(here.x - target.x, here.z - target.z).length() <= ChatCommands.FIND_HERE \
			and absf(here.y - target.y) < ChatCommands.FIND_HIGH:
		target = Vector3.INF   # at the place: the arrow rests (it would stop itself and blink back every second)
	if arrow_on and target.is_finite() and (arrow.target != target or not arrow.is_pointing()):
		arrow.player = player
		arrow.point_to(label, target)
	elif arrow_on and not target.is_finite() and arrow.is_pointing():
		arrow.stop()
	elif not arrow_on and arrow.is_pointing() and arrow.target == target:
		arrow.stop()


## Where this child's story (or the shared one) leads, for bot friends: {pos, kind} or {} (the host asks).
func target_for(peer: int) -> Dictionary:
	var at := Vector3.INF
	if not team.is_empty():
		at = team_state().get("target", Vector3.INF)
	elif peer == int(own_peer.call()):
		var d := data()
		if d.quests.active != &"":
			at = _step_target(d.quests.active, QuestRules.step_index(d, d.quests.active))
	else:
		at = _guest_targets.get(peer, Vector3.INF)
	return {"pos": at, "kind": &"quest"} if at.is_finite() else {}


# --- Co-op: the host decides ------------------------------------------------------------------------------

## Host: PLAY TOGETHER on or off: shares the host's story (of this world's universe) with everyone.
func share(on: bool) -> bool:
	if not is_host.call():
		return false
	if not on:
		team.clear()
		_send_team()
		changed.emit()
		return true
	var id := data().quests.active
	if id == &"" or QuestRules.universe_of(id) != universe or not QuestRules.allowed_in(id, mode):
		return false
	team = {"chain": id, "helpers": {int(own_peer.call()): true}}
	_send_team()
	changed.emit()
	return true


func is_sharing() -> bool:
	return not team.is_empty()


## Host: the shared story as every game sees it.
func team_state() -> Dictionary:
	if team.is_empty():
		return {}
	var d := data()
	var id: StringName = team.chain
	var i := QuestRules.step_index(d, id)
	var p := QuestRules.step_progress(d, id)
	return {"chain": String(id), "step": i, "have": p.x, "need": p.y, "target": _step_target(id, i)}


func _send_team() -> void:
	if not is_host.call() or not is_inside_tree():
		return
	var s := team_state()
	for peer: int in others.call():
		_send(peer, &"_rpc_team", [s])


## Host: a guest's game counted `amount` of `kind` for the shared story. True when it counted.
func on_team_event(peer: int, kind: StringName, amount: int) -> bool:
	if not is_host.call() or team.is_empty() or not LevelRules.is_kind(kind) or not others.call().has(peer):
		return false
	var now := Time.get_ticks_msec()
	var w: Array = _team_events.get(peer, [now, 0])
	if now - int(w[0]) > TEAM_WINDOW_MS:
		w = [now, 0]
	if int(w[1]) >= TEAM_EVENTS:
		return false
	w[1] = int(w[1]) + 1
	_team_events[peer] = w
	var d := data()
	if not QuestRules.help(d, team.chain, kind, clampi(amount, 1, 10)):
		return false
	(team.helpers as Dictionary)[peer] = true
	_check_steps(d, peer)
	_send_team()
	changed.emit()
	return true


## Host: the player who did a step and everyone near them helped.
func _helped_near(peer: int, at: Vector3) -> void:
	if team.is_empty():
		return
	(team.helpers as Dictionary)[peer] = true
	if not at.is_finite():
		return
	for p in _players(true):
		if p.global_position.distance_to(at) <= HELP_NEAR:
			(team.helpers as Dictionary)[p.peer_id] = true


func helpers() -> Array:
	return (team.get("helpers", {}) as Dictionary).keys()


func _send_reward(peer: int, chain_id: StringName, place: Dictionary) -> void:
	_send(peer, &"_rpc_team_reward", [String(chain_id), place])


## Every game: the shared story is done and this child helped: its keepsake, title and place (once) and,
## in Survivor, its gold from the host.
func receive_team_reward(chain_id: StringName, place: Dictionary) -> void:
	team_view = {}
	var d := data()
	if QuestRules.chain(chain_id).is_empty() or not QuestRules.finish(d, chain_id, place):
		changed.emit()
		return
	Progress.event(StringName("%s/%s" % [LevelRules.QUEST_DONE, chain_id]))
	_celebrate(chain_id)
	_saved()
	changed.emit()


## This game's child finished a story in Survivor: the host pays its fixed gold (once per player and story).
func request_gold(chain_id: StringName) -> void:
	if is_host.call():
		host_gold(int(own_peer.call()), chain_id)
	else:
		_send(1, &"_rpc_gold", [String(chain_id)])


func host_gold(peer: int, chain_id: StringName) -> bool:
	var gold := QuestRules.gold_for(chain_id)
	var key := "%d:%s" % [peer, chain_id]
	if not is_host.call() or gold <= 0 or not survivor.call() or _paid.has(key):
		return false
	_paid[key] = true
	give_gold.call(peer, gold)
	return true


## Host: a guest that just joined hears about the shared story.
func on_client_ready(peer: int) -> void:
	if is_host.call() and not team.is_empty():
		_send(peer, &"_rpc_team", [team_state()])


func on_peer_left(peer: int) -> void:
	_guest_targets.erase(peer)
	_team_events.erase(peer)


@rpc("authority", "call_remote", "reliable")
func _rpc_team(state: Dictionary) -> void:
	var id := StringName(str(state.get("chain", "")))
	if QuestRules.chain(id).is_empty():
		team_view = {}
	else:
		var t: Variant = state.get("target", Vector3.INF)
		team_view = {"chain": id, "step": int(state.get("step", 0)), "have": int(state.get("have", 0)),
			"need": int(state.get("need", 1)), "target": t if t is Vector3 else Vector3.INF}
	_update_arrow()
	changed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_team_event(kind: String, amount: int) -> void:
	on_team_event(multiplayer.get_remote_sender_id(), StringName(kind.substr(0, LevelRules.KIND_MAX_LENGTH)), amount)


@rpc("authority", "call_remote", "reliable")
func _rpc_team_reward(chain_id: String, place: Dictionary) -> void:
	receive_team_reward(StringName(chain_id.substr(0, 40)), place)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gold(chain_id: String) -> void:
	host_gold(multiplayer.get_remote_sender_id(), StringName(chain_id.substr(0, 40)))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ask_target(kind: String, from: Vector3) -> void:
	var k := StringName(kind.substr(0, 20))
	var peer := multiplayer.get_remote_sender_id()
	if not is_host.call() or not SecretRules.is_kind(k) or not from.is_finite() or secrets == null or secrets.rules == null:
		return
	var skip := secrets.state.found.duplicate()
	skip.merge(secrets.state.opened)
	var rules := secrets.rules
	_tasks.append(WorkerThreadPool.add_task(func() -> void:
		var at := QuestDirector.nearest_place(rules, k, from, skip, TARGET_RADIUS * 2.0)
		_got_place.call_deferred(k, at, peer)))


@rpc("authority", "call_remote", "reliable")
func _rpc_target(kind: String, at: Vector3) -> void:
	_asking.erase(StringName(kind))
	_found[StringName(kind)] = at
	_update_arrow()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_my_target(at: Vector3) -> void:
	if is_host.call() and at.is_finite():
		_guest_targets[multiplayer.get_remote_sender_id()] = at


# --- This game's HUD: QUESTS in MORE, the book, the card, the arrow ----------------------------------------------

## The quest book (MORE → QUESTS), the giver's card and the arrow, over `h`; `layer` holds the overlays.
func setup_local(p: Player, h: Hud, layer: Node, interactor: BlockInteractor) -> void:
	player = p
	hud = h
	if not tells_stories():
		return
	book = QuestBook.new()
	book.name = "QuestBook"
	book.director = self
	card = QuestCard.new()
	card.name = "QuestCard"
	card.director = self
	for c: Control in [book, card]:
		layer.add_child(c)
		if h:
			h.look_area.blockers.append(c)
	if h:
		arrow = FindArrow.new()
		arrow.name = "QuestArrow"
		arrow.player = p
		arrow.covered = func() -> bool:
			var find := h.get_node_or_null("FindArrow") as Control
			return h.compass.visible or (find != null and find.visible)
		h.add_child(arrow)
		more_button = TouchButton.new()
		more_button.name = "Quests"
		more_button.text = "QUESTS"
		more_button.symbol = &"quests"
		h.more.add(more_button, true)
		more_button.pressed.connect(book.open)
	if interactor:
		interactor.quest_giver_tapped.connect(func(g: QuestGiver) -> void: open_card(g.giver_id))
		interactor.stall_quest_tap = func() -> bool:
			if not wants_stall_tap():
				return false
			open_card(&"tilly")
			return true


## The book and the card close (the pause menu opened, Android Back). True when one was open.
func close_pages() -> bool:
	var was := (book != null and book.is_open()) or (card != null and card.is_open())
	if book:
		book.close()
	if card:
		card.close()
	return was
