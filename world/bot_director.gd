class_name BotDirector
extends Node
## Host-side: the bot friends of this world (M2 §12.14, owner feedback #18). The pause menu's
## FRIENDS row adds up to BotRules.MAX_BOTS and removes them; they are spawned through the sandbox's
## MultiplayerSpawner (replicated like animals), saved in WorldMeta.bots and brought back next to
## the player. It remembers where players put blocks lately, so builders build next to the
## player's build, and it is the path of a builder's blocks (Session.bot_set_blocks: the host's
## checks, only empty cells, no undo step). Task 16's secrets ask it for an explorer (notice()).
## World access and spawning are injected, so tests can drive it with stubs.

signal changed                    # a friend came or left (the FRIENDS row redraws)

const MEMORY := 32                # recent player blocks remembered

var container: Node               # holds the BotFriend nodes
var spawn: Callable               # (data: Dictionary) -> Node: spawns a BotFriend for everyone
## () -> Player: the player the friends play with (this game's own: the host's).
var leader: Callable = _local_player
var world: WorldService

var _next_id := 1
var _player_blocks: Array[Vector3i] = []
var _placing := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if world and not world.block_changed.is_connected(_on_block_changed):
		world.block_changed.connect(_on_block_changed)


func _local_player() -> Player:
	return Session._player_for_peer(multiplayer.get_unique_id())


func bots() -> Array[BotFriend]:
	var list: Array[BotFriend] = []
	if container:
		for child in container.get_children():
			if child is BotFriend and not child.is_queued_for_deletion():
				list.append(child)
	return list


func can_add() -> bool:
	return bots().size() + _benched.size() < BotRules.MAX_BOTS and bots().size() < _seat_limit()


## Adds a friend of `personality` next to the player; it says hello. A saved friend keeps its name
## and look (when still free). Returns null when there are MAX_BOTS already or no player yet.
func add(personality: StringName, bot_name: String = "", look: int = -1, mind: Variant = null) -> BotFriend:
	if not BotRules.valid_personality(personality) or not can_add() or world == null:
		return null
	var p: Player = leader.call() if leader.is_valid() else null
	if p == null:
		return null
	var names: Array[String] = []
	var looks: Array[int] = []
	for b in bots():
		names.append(b.bot_name)
		looks.append(b.look)
	if not BotRules.NAMES.has(bot_name) or names.has(bot_name):
		bot_name = BotRules.pick_name(names, _rng.randi())
	if not BotRules.valid_look(look) or looks.has(look):
		look = BotRules.pick_look(looks)
	var spot := BotFriend.spot_near(world, p.global_position, names.size() * 3)
	if not spot.is_finite():
		spot = p.global_position + Vector3(1.5, 0.2, 1.5)
	while container.has_node("Bot%d" % _next_id):
		_next_id += 1
	var data := {"id": "Bot%d" % _next_id, "name": bot_name, "personality": String(personality),
		"look": look, "pos": spot, "yaw": _rng.randf() * TAU}
	_next_id += 1
	var bot := spawn.call(data) as BotFriend
	if bot == null:
		return null
	bot.director = self
	bot.leader_peer = p.peer_id
	bot.mind_load(mind)   # M2 Task 18: what it learned of its child (a saved friend)
	bot.mind_hello()      # hello (by the child's name when it knows them)
	changed.emit()
	return bot


## Sends the friend called `bot_name` home (it says bye). False when there is no such friend.
func remove(bot_name: String) -> bool:
	for b in bots():
		if b.bot_name == bot_name:
			b.say_goodbye()
			b.queue_free()
			changed.emit()
			return true
	return false


## For WorldMeta.bots (friends making room for players too: they come back next time).
func to_save() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for b in bots():
		list.append(b.to_save())
	list.append_array(_benched)
	return list


## Brings back the saved friends (WorldMeta.bots, already validated) next to the player; online,
## as many as there are seats (the rest wait for one).
func restore(saved: Array[Dictionary]) -> void:
	for e in saved:
		if bots().size() < _seat_limit():
			add(StringName(str(e.personality)), str(e.name), int(e.look), e.get("mind"))   # M2 Task 18: its mind comes back
		elif _benched.size() + bots().size() < BotRules.MAX_BOTS:
			_benched.append(e)


# --- M4 E: bot friends fill the empty seats of an online world (§17.5) ---

## () -> int: seats left for bot friends (BotRules.seats_for_bots); -1 = no limit (solo and LAN).
var seats: Callable = func() -> int: return -1
var _benched: Array[Dictionary] = []   # friends making room for players (their saves), newest last


func _seat_limit() -> int:
	var n := int(seats.call())
	return BotRules.MAX_BOTS if n < 0 else mini(n, BotRules.MAX_BOTS)


## Host: players came or went. The newest friends make room for players; friends waiting for a seat
## come back when there is one.
func fit_seats() -> void:
	var limit := _seat_limit()
	var list := bots()
	var changed_any := false
	while list.size() > limit:
		var b: BotFriend = list.pop_back()
		_benched.append(b.to_save())
		b.say_make_room()
		b.queue_free()
		changed_any = true
	while not _benched.is_empty() and bots().size() < limit:
		var e: Dictionary = _benched.pop_back()
		if add(StringName(str(e.personality)), str(e.name), int(e.look), e.get("mind")) == null:
			_benched.append(e)
			break
		changed_any = true
	if changed_any:
		changed.emit()


## The player's most recent block within BotRules.BUILD_NEAR of `near`, or BotRules.NO_CELL.
func build_anchor(near: Vector3) -> Vector3i:
	for i in range(_player_blocks.size() - 1, -1, -1):
		var cell := _player_blocks[i]
		if (Vector3(cell) + Vector3(0.5, 0.5, 0.5)).distance_to(near) <= BotRules.BUILD_NEAR:
			return cell
	return BotRules.NO_CELL


## A builder's blocks go up through the host's edit path. They never count as the player's build.
func place(bot: BotFriend, changes: Array) -> int:
	_placing = true
	var n := Session.bot_set_blocks(changes, bot.eye_position())
	_placing = false
	return n


## Task 16's secrets: the explorer nearest to `point` walks over and points at it. True if one will.
func notice(point: Vector3, text: String = "") -> bool:
	var explorers := bots().filter(func(b: BotFriend) -> bool: return b.personality == BotRules.EXPLORER)
	explorers.sort_custom(func(a: BotFriend, b: BotFriend) -> bool:
		return a.global_position.distance_squared_to(point) < b.global_position.distance_squared_to(point))
	for b: BotFriend in explorers:
		if b.notice(point, text):
			return true
	return false


func _on_block_changed(pos: Vector3i, _old_id: int, new_id: int) -> void:
	if _placing or new_id == BlockIds.WATER:
		return                          # a friend's build, or flowing water
	_mind_block(pos, new_id)            # M2 Task 18: friends learn from the child's blocks
	_player_blocks.erase(pos)
	if new_id != BlockIds.AIR:
		_player_blocks.append(pos)
		if _player_blocks.size() > MEMORY:
			_player_blocks.pop_front()

# --- M2 Task 18: creature minds ------------------------------------------------------------------

## A block the child placed (builders learn their favourite blocks and shapes) or broke (a builder
## whose build it was learns the child didn't want it).
func _mind_block(pos: Vector3i, new_id: int) -> void:
	var prev: Vector3i = _player_blocks.back() if not _player_blocks.is_empty() else BotStyle.NO_CELL
	for b in bots():
		if new_id == BlockIds.AIR:
			b.mind_block_broken(pos)
		elif b.personality == BotRules.BUILDER:
			b.mind_saw_block(new_id, pos, prev)

# --- M3 Task 7: bot friends race a course --------------------------------------------------------------

## (bot: BotFriend) -> String: the sandbox's CourseDirector.race_bot ("" = it will race; else why not).
var race_with: Callable = func(_bot: BotFriend) -> String: return CourseDirector.NO_COURSE


## The FRIENDS page's RACE ME!: the friend called `bot_name` races the nearest course's best run. "" when it
## will, else a few words why not.
func race(bot_name: String) -> String:
	for b in bots():
		if b.bot_name == bot_name:
			return str(race_with.call(b))
	return ""

# --- Owner 38: the child's words to their own bot friends (spec §12.14a) ----------------------------------

## (from: Vector3) -> {pos, kind}: the nearest secret nobody found yet, next to it ({} when none).
var secret_near: Callable = _secret_near
## Owner #45a: (peer_id) -> {pos, kind: &"quest"}: where that child's quest story leads now ({} when none);
## "find treasure" and "follow the arrow" lead there first (the sandbox sets it: QuestDirector.target_for).
var quest_near: Callable = func(_peer: int) -> Dictionary: return {}
## (peer_id: int) -> bool: other people play in this world (words not understood then get a hint only when
## a friend is named).
var others_present: Callable = _others_present

const SECRET_LOOK := 400.0        # how far the friends know of secrets
## Secrets that move or come and go are not led to.
const NOT_LED_TO: Array[StringName] = [&"golden", &"wanderer", &"star"]


## Host (Session): `text` from player `peer_id` (cleaned and filtered by the host) to their own friends: they
## do what was asked and answer (BotTalk: who hears, answers and acts; BotAnswers: the words). Returns what
## was understood (BotIntents.parse), {} when the child has no friends here. Nothing is kept.
func hear(peer_id: int, text: String) -> Dictionary:
	var child := Session._player_for_peer(peer_id)
	if child == null:
		return {}
	var own: Array[BotFriend] = []
	var names: Array[String] = []
	var infos: Array[Dictionary] = []
	for b in bots():
		if b.leader_peer == peer_id:
			own.append(b)
			names.append(b.bot_name)
			infos.append({"name": b.bot_name, "leader": b.leader_peer, "pos": b.global_position,
				"personality": b.personality, "up": not b.knocked_out})
	if own.is_empty():
		return {}
	var said := BotIntents.parse(text, names)
	var cp := child.global_position
	var hearing := BotTalk.listeners(said, peer_id, cp, infos)
	if hearing.is_empty():
		return said
	var intent: StringName = said.intent
	for i in hearing:
		own[i].talk_language(said.lang)
	if intent == BotIntents.UNKNOWN:
		if BotTalk.wants_hint(said, others_present.call(peer_id)):
			var who := own[BotTalk.answerer(intent, hearing, infos, cp)]
			who.talk_reply(who.talk_line(&"hint"))
		return said
	var acting: Array[BotFriend] = []
	for i in BotTalk.actors(intent, hearing, infos, cp):
		acting.append(own[i])
		own[i].asks.note(intent, own[i].clock)
	var speaking: Array[BotFriend] = []
	for i in BotTalk.speakers(intent, hearing, infos, cp):
		speaking.append(own[i])
	_do(said, child, acting, speaking)
	return said


## What the friends do and say for `said` from `child`.
func _do(said: Dictionary, child: Player, acting: Array[BotFriend], speaking: Array[BotFriend]) -> void:
	var cp := child.global_position
	var look := BotFriend.facing_of(child)
	var lang: StringName = said.lang
	var we := acting.size() > 1
	var voice: BotFriend = speaking[0] if not speaking.is_empty() else null
	var line := StringName(str(said.intent))
	match said.intent:
		BotIntents.FOLLOW:
			for b in acting:
				b.talk_follow()
		BotIntents.WAIT:
			for b in acting:
				b.talk_stay(b.global_position)
		BotIntents.HOME:
			if not child.has_home:
				line = &"no_home"
			else:
				for b in acting:
					b.talk_stay(Vector3(child.home_bed) + Vector3(0.5, 0.0, 0.5), true)
		BotIntents.SPACE:
			for b in acting:
				b.talk_space()
		BotIntents.BUILD:
			line = _build(said, acting)
		BotIntents.TREASURE:
			var s: Dictionary = quest_near.call(child.peer_id)   # owner #45a: the quest's place first
			if s.is_empty():
				s = secret_near.call(cp)
			var lead := not s.is_empty() and _flat(s.pos, cp) <= BotRules.GUIDE_MAX
			if lead:
				for b in acting:
					b.talk_guide(s.pos)
			_say(voice, BotAnswers.treasure(cp, look, s, lang, lead))
			return
		BotIntents.FIGHT:
			for b in acting:
				b.talk_guard()
			line = &"fight" if not _monsters_near(cp, BotRules.GUARD_RADIUS).is_empty() else &"guard"
		BotIntents.HELP:
			for b in acting:
				b.talk_guard(BotRules.HELP_TIME)
		BotIntents.HIDE:
			var near := _monsters_near(cp, BotRules.RUN_FROM_MONSTERS)
			for b in acting:
				b.talk_hide(near)
			line = &"run" if not near.is_empty() else &"hide"
		BotIntents.DANCE:
			var trick: bool = said.what == BotIntents.TRICK
			for b in acting:
				b.talk_dance(trick)
			line = &"trick" if trick and not we else &"dance"
		BotIntents.LOOK:
			for b in acting:
				b.talk_follow(BotRules.LOOK_TIME)
		BotIntents.RACE:
			line = &"race_none"
			for b in acting:
				b._last_said = b.clock      # its own English ready line waits: it answers in the child's words
				if race(b.bot_name) == "":
					line = &"race_ready"
		BotIntents.WHERE_TILLY:
			var stall := _trader_at()
			var lead := stall.is_finite() and _flat(stall, cp) <= BotRules.GUIDE_MAX
			if lead:
				for b in acting:
					b.talk_guide(stall)
			_say(voice, BotAnswers.tilly(cp, look, stall, lang, lead))
			return
		BotIntents.DOING:
			if voice:
				_say(voice, BotAnswers.doing(voice.talk_doing(), lang))
			return
		BotIntents.HEARTS:
			_say(voice, BotAnswers.hearts(child.health.hp, Health.MAX_HP, Game.allows(ModeRules.DAMAGE), lang))
			return
		BotIntents.NIGHT:
			var t: float = Animal.time_source.call() if Animal.time_source.is_valid() else DayCycle.NOON
			_say(voice, BotAnswers.night(t, lang))
			return
		BotIntents.NAME:
			if voice:
				_say(voice, BotAnswers.name_line(voice.bot_name, voice.personality, lang))
			return
		BotIntents.WHERE_ARE_YOU:
			for b in speaking:
				b.talk_wave()
				_say(b, b.talk_line(&"at_home") if b.talk_at_home() else BotAnswers.where_me(cp, look, b.global_position, lang))
			return
		BotIntents.HOW_ARE_YOU:
			line = &"feel"
		BotIntents.HELLO, BotIntents.THANKS, BotIntents.PRAISE:
			for b in speaking:
				b.talk_kind(child)
		BotIntents.BYE:
			pass
	if voice and line != &"":
		_say(voice, voice.talk_line(line, we))


## A build the child asked for: the friend (a builder when one is near) plans it next to the child. The line
## to answer with.
func _build(said: Dictionary, acting: Array[BotFriend]) -> StringName:
	var why := &"no_room"
	for b in acting:
		why = b.talk_build(said.what, said.mine)
	if why != &"":
		return why
	if said.mine and ModeRules.valid(Game.mode) == ModeRules.SURVIVOR:
		return &"leaves_only"
	return StringName("build_%s" % (said.what if said.what != &"" else &"thing"))


func _say(b: BotFriend, text: String) -> void:
	if b:
		b.talk_reply(text)


func _monsters_near(at: Vector3, radius: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m and not m.is_queued_for_deletion() and m.global_position.distance_to(at) <= radius:
			out.append(m.global_position)
	return out


## Tilly's stall (the first trader in the world), or INF when this world has none.
func _trader_at() -> Vector3:
	for n in get_tree().get_nodes_in_group(&"traders"):
		if n is Node3D and not n.is_queued_for_deletion():
			return (n as Node3D).global_position
	return Vector3.INF


## The world's secrets (the sandbox's SecretDirector, "Secrets"): the nearest one nobody found or opened.
func _secret_near(from: Vector3) -> Dictionary:
	var scene := get_tree().current_scene
	var secrets := scene.get_node_or_null("Secrets") as SecretDirector if scene else null
	if secrets == null or secrets.rules == null:
		return {}
	var best := {}
	var best_d := INF
	for s: Dictionary in secrets.rules.secrets_near(from, SECRET_LOOK):
		if NOT_LED_TO.has(StringName(str(s.kind))) or secrets.state.found.has(s.id) or secrets.state.opened.has(s.id):
			continue
		var d := _flat(Vector3(s.anchor as Vector3i), from)
		if d < best_d:
			best_d = d
			best = s
	if best.is_empty():
		return {}
	return {"pos": Vector3(secrets._hint_spot(best)) + Vector3(0.5, 0.0, 0.5), "kind": StringName(str(best.kind))}


func _others_present(peer_id: int) -> bool:
	for n in get_tree().get_nodes_in_group(&"players"):
		if n is Player and (n as Player).peer_id != peer_id:
			return true
	return false


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
