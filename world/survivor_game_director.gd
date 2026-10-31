class_name SurvivorGameDirector
extends Node
## The Survivor games in a world (owner feedback #33, spec §12.18). The sandbox adds one on every peer,
## named "SurvivorGame".
## Host (start(), then tick() every TICK seconds):
## - BUILD (Build to Survive): each player's shelter (ShelterRules; Player.sheltered, so monsters can't see
##   them); the night's knock-outs; at sunrise every player who got through the night outside a knock-out
##   counts a night (GameScores) and hears it; a knock-out ends the run, and when every player has been
##   knocked out this night the clock jumps to the morning (they wake at home); fiercer nights outside
##   (MonsterDirector.per_player_cap, level_bonus); beds only in a shelter (sleep_refusal).
## (The first plan's Monster Hunter was folded into Monster Wave by owner feedback #44: ArenaDirector.)
## Every peer (setup_local): the HUD's GameClock — the night clock, the shelter's words and the score (the host
## sends each player theirs).
## World access is injected, so tests drive it with stubs. Nothing here changes a block.

const TICK := 0.5
const BED_WORDS := "Build walls and a roof around your bed first!"
const MORNING_WORDS := "Good morning! You're home."

var game: StringName = SurvivorGames.CLASSIC

# Host side, injected by the sandbox (tests use stubs).
var time_of_day: Callable            # () -> float (DayCycle)
var set_time: Callable               # (t: float) -> void: jumps the clock for everyone (SkyCycle.set_time)
var now: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
var block_at: Callable               # (cell: Vector3i) -> int, read only
var box_reader: Callable             # optional: (origin, size) -> Callable(cell) -> int, one bulk copy
var name_of: Callable                # (peer_id) -> String: whose scores (like inventories and homes)
var monsters: MonsterDirector
## {player name: GameScores record}: the world's WorldMeta.game_scores (the same dictionary).
var scores: Dictionary = {}
var rng := RandomNumberGenerator.new()
var running := false                 # host: ticking (start())

var _t := 0.0
var _was_night := false
var _knocked_tonight := {}           # host: peer -> true, knocked out since the sun went down
var _shelter := {}                   # host: peer -> ShelterRules state


func _init() -> void:
	rng.randomize()


## Every peer, from the start: a guest's score comes at client_ready, before its HUD exists.
func _ready() -> void:
	Session.game_score_received.connect(func(s: Dictionary) -> void: _my_score = GameScores.clean(s))


## Host: begin (once the world, the sky and the monsters are in place).
func start() -> void:
	running = true
	_was_night = DayCycle.is_night(float(time_of_day.call())) if time_of_day.is_valid() else false
	if monsters:
		monsters.per_player_cap = SurvivorGames.per_player_cap(game)
		monsters.level_bonus = SurvivorGames.level_bonus(game)
	Session.knockout_received.connect(_on_knockout)
	Session.knockout_respawned.connect(_on_respawned)
	Session.client_ready.connect(_on_client_ready)
	if is_instance_valid(local_player):
		_my_score = record_of(local_player.peer_id).duplicate()   # the host's HUD came first


func _process(delta: float) -> void:
	if running:
		_t += delta
		if _t >= TICK:
			tick()
	_local_process(delta)


## Host, every TICK seconds.
func tick() -> void:
	_t = 0.0
	var players := _players()
	if game == SurvivorGames.BUILD:
		_tick_build(players)


## A player's score record (made the first time).
func record_of(peer_id: int) -> Dictionary:
	var key := _key(peer_id)
	if not scores.has(key):
		scores[key] = GameScores.new_record()
	return scores[key]


## Host: a player's shelter as of the last tick (ShelterRules state).
func shelter_of(peer_id: int) -> StringName:
	return _shelter.get(peer_id, ShelterRules.OPEN)


## Host: why a player may not sleep now ("" = they may): Build to Survive's beds need a shelter.
func sleep_refusal(peer_id: int) -> String:
	if game != SurvivorGames.BUILD:
		return ""
	var p := _player_of(peer_id)
	if p == null or check(p) == ShelterRules.SAFE:
		return ""
	return BED_WORDS


## A player's shelter now (ShelterRules), from one read of the box around them.
func check(p: Player) -> StringName:
	var feet := ShelterRules.feet_cell(p.global_position)
	return ShelterRules.check(feet, _solid_reader(feet))


func _solid_reader(feet: Vector3i) -> Callable:
	var read := block_at
	if box_reader.is_valid():
		var box := ShelterRules.box(feet)
		read = box_reader.call(box[0], box[1])
	return func(cell: Vector3i) -> bool: return BlockIds.is_solid(int(read.call(cell)))


# --- Build to Survive ---------------------------------------------------------------------------------

func _tick_build(players: Array[Player]) -> void:
	for p in players:
		var state := check(p)
		_shelter[p.peer_id] = state
		p.sheltered = state == ShelterRules.SAFE
	var night := DayCycle.is_night(float(time_of_day.call()))
	if night and not _was_night:
		_knocked_tonight.clear()
	elif _was_night and not night:
		_morning(players)
	_was_night = night


## Sunrise: everyone who got through the night outside a knock-out counts it.
func _morning(players: Array[Player]) -> void:
	for p in players:
		if _knocked_tonight.has(p.peer_id):
			continue
		var r := record_of(p.peer_id)
		var best := GameScores.night_survived(r)
		_tell(p.peer_id, BuildRules.morning_line(int(r.nights), best))
		Session.send_game_score(p.peer_id, r)
	_knocked_tonight.clear()


func _on_knockout(peer_id: int, _at_home: bool) -> void:
	if not running or game == SurvivorGames.CLASSIC:
		return
	var r := record_of(peer_id)
	GameScores.knocked_out(r, game)
	if DayCycle.is_night(float(time_of_day.call())):
		_knocked_tonight[peer_id] = true
	Session.send_game_score(peer_id, r)


## Build to Survive: once every player has been knocked out this night, they wake at home in the morning.
func _on_respawned(_peer_id: int, _at_home: bool) -> void:
	if not running or game != SurvivorGames.BUILD or not DayCycle.is_night(float(time_of_day.call())):
		return
	var players := _players()
	for p in players:
		if not _knocked_tonight.has(p.peer_id):
			return
	set_time.call(DayCycle.SUNRISE)
	for p in players:
		_tell(p.peer_id, MORNING_WORDS)


# --- Shared -------------------------------------------------------------------------------------------

func _players() -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and not p.is_queued_for_deletion() and p.is_spawned():
			out.append(p)
	return out


func _player_of(peer_id: int) -> Player:
	for p in _players():
		if p.peer_id == peer_id:
			return p
	return null


## Scores are kept by player name; a guest without one keeps theirs for the session.
func _key(peer_id: int) -> String:
	var n := str(name_of.call(peer_id)) if name_of.is_valid() else ""
	return n if n != "" else "#%d" % peer_id


func _tell(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer_id):
		Session.send_feedback(peer_id, text)


func _on_client_ready(peer_id: int) -> void:
	if game != SurvivorGames.CLASSIC:
		Session.send_game_score(peer_id, record_of(peer_id))

# --- Every peer: the HUD's clock ----------------------------------------------------------------------

var clock: GameClock
var local_player: Player
var _local_t := 0.0
var _my_score := GameScores.new_record()


## This game's player and its HUD label; the host hears its own score like any player.
func setup_local(p: Player, c: GameClock) -> void:
	local_player = p
	clock = c
	clock.visible = game != SurvivorGames.CLASSIC
	if running:
		_my_score = record_of(p.peer_id).duplicate()
	update_clock()


func _local_process(delta: float) -> void:
	if clock == null:
		return
	_local_t += delta
	if _local_t >= TICK:
		_local_t = 0.0
		update_clock()


## The label now. A guest works out its own player's shelter (the host's answer is the one monsters obey).
func update_clock() -> void:
	if not is_instance_valid(clock) or game == SurvivorGames.CLASSIC or not time_of_day.is_valid():
		return
	var state := ShelterRules.OPEN
	if is_instance_valid(local_player) and local_player.is_spawned():
		if running:
			state = shelter_of(local_player.peer_id)
		else:
			state = check(local_player)
			local_player.sheltered = state == ShelterRules.SAFE
	clock.show_build(float(time_of_day.call()), int(_my_score.nights), int(_my_score.best_nights), state)
