class_name StealthDirector
extends Node
## Stealth in a world (M2 Task 5, spec §12.5). The sandbox adds one on every peer, named "Stealth".
## Host: five times a second it measures the light around every player and bot friend (the sky, a
## cave, lanterns and light blocks) and whether a player stands in a bush (Player.stealth_light,
## stealth_in_bush; a bot's light is its "stealth_light" meta); it keeps the short log of noises that
## monsters hear (landings, broken blocks, attacks; Monster reads it with heard_at); it checks every
## request to hide in a barrel or closet (close enough, nobody else inside, not knocked out or asleep)
## and tells every game; it brings a player out when the block breaks or they are knocked out; and
## monsters that saw someone go in search next to the spot (Monster.saw_hide).
## Every game puts bodies into hiding spots and out again (Session.stealth_hidden_changed). A guest
## measures only its own player's light and noise, for the HUD's eye and noise bars.
## World access is injected (block_at, time_of_day, surface_height, lights_near), so tests use stubs.

const REFRESH := 0.2              # seconds between light and bush checks
const MAX_NOISES := 24
const CEILING_SCAN := 32          # blocks above the head searched for a ceiling (like Ambience)
const MERGE := 1.5                # a noise this close to a logged one refreshes it instead
const HIT_HEARING := 40.0         # a monster that is hit hears the attack this far away (the far archer)

var block_at: Callable            # (pos: Vector3i) -> int
var time_of_day: Callable         # () -> float (DayCycle); none: daylight
var surface_height: Callable      # (x: int, z: int) -> int: the generated ground
var lights_near: Callable         # (head: Vector3) -> bool: a lantern or light block within LIGHT_RADIUS
## M3 Task 2: the weather's factor on the light (underground: 0..1) -> float; the Sandstorm Desert's storms
## halve it outdoors (SandstormDirector.visibility). None: clear skies.
var weather: Callable
## This game's own player (the HUD shows its eye and noise).
var local_player: Player
var host := false

## Noises monsters can hear: [pos: Vector3, radius: float, until: float (seconds), attack: bool].
static var _noises: Array = []

var _t := 0.0
var _vy := {}                     # body instance id -> its vertical speed a frame ago (landings)
var _local_noise := 0.0           # this game's player: the last event noise and when it fades
var _local_noise_until := 0.0


func _ready() -> void:
	Session.stealth_hidden_changed.connect(_on_hidden_changed)


## Host and solo: checks hide requests and listens for noises and knock-outs.
func start_host() -> void:
	host = true
	Session.stealth_hide_requested.connect(_on_hide_requested)
	Session.stealth_unhide_requested.connect(_on_unhide_requested)
	Session.attack_requested.connect(_on_attack)
	Session.spear_throw_requested.connect(_on_spear_throw)
	Session.player_hurt.connect(_on_player_hurt)
	Session.client_ready.connect(_send_hidden_to)


## Host: breaking a block is loud, and breaking a hiding spot brings whoever is inside out.
func watch_blocks(world: WorldService) -> void:
	world.block_changed.connect(_on_block_changed)


## This game's player: breaking a block makes noise the HUD shows (guests too).
func watch_local(interactor: BlockInteractor) -> void:
	interactor.edited.connect(_on_local_edit)


func _on_local_edit(kind: StringName) -> void:
	if kind == &"break":
		_local_event(StealthRules.NOISE_BREAK)


func _on_attack(peer_id: int, _weapon_id: int, _dir: Vector3, _power: float) -> void:
	_attack_noise(peer_id)


func _on_spear_throw(peer_id: int, _weapon_id: int, _dir: Vector3) -> void:
	_attack_noise(peer_id)


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _physics_process(delta: float) -> void:
	for p in _bodies_to_watch():
		_watch_landing(p)
	_t -= delta
	if _t > 0.0:
		return
	_t = REFRESH
	if host:
		for p in Monster.players_now(get_tree()):
			refresh(p)
		for b in Monster.bots_now(get_tree()):
			refresh(b)
	elif is_instance_valid(local_player) and local_player.is_spawned():
		refresh(local_player)


func _bodies_to_watch() -> Array[Player]:
	if host:
		return Monster.players_now(get_tree())
	var out: Array[Player] = []
	if is_instance_valid(local_player) and local_player.is_spawned():
		out.append(local_player)
	return out


## Measures the light around a player or bot friend (and a player's bush) and stores it on it.
func refresh(body: Node3D) -> void:
	if block_at.is_null():
		return
	var feet := body.global_position
	var light := light_at(feet)
	if body is Player:
		var p := body as Player
		p.stealth_light = light
		var f := Vector3i(feet.floor())
		p.stealth_in_bush = StealthRules.in_bush(block_at.call(f), block_at.call(f + Vector3i.UP))
	else:
		body.set_meta(&"stealth_light", light)


## The light around someone standing at `feet` (the sky, a cave, lanterns and light blocks, the weather):
## players and bot friends (refresh), and a candy sneaker deciding whether it is dark (M3 Task 4). `lamp`: 0 or 1
## when the caller already knows whether a light is near (a sneaker asks the lantern index: no box copy), -1 to
## look (lights_near).
func light_at(feet: Vector3, lamp: int = -1) -> float:
	if block_at.is_null():
		return StealthRules.DAYLIGHT
	var head := feet + Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	var daylight := DayCycle.daylight(time_of_day.call()) if time_of_day.is_valid() else 1.0
	var cell := Vector3i(head.floor())
	var ground: int = surface_height.call(cell.x, cell.z) if surface_height.is_valid() else cell.y
	var under := AmbienceRules.underground_target(head.y, ground, _has_ceiling(cell))
	var near: bool = lamp == 1 if lamp >= 0 else (lights_near.call(head) if lights_near.is_valid() else false)
	var light := StealthRules.light_level(daylight, under, near)
	if weather.is_valid():
		light *= float(weather.call(under))   # M3 Task 2: a sandstorm hides everyone outdoors
	return light


func _has_ceiling(head: Vector3i) -> bool:
	for dy in range(1, CEILING_SCAN + 1):
		if BlockIds.is_solid(block_at.call(head + Vector3i(0, dy, 0))):
			return true
	return false


## A body that lands a fall with a thud makes noise (a jump from the ground is enough).
func _watch_landing(p: Player) -> void:
	var id := p.get_instance_id()
	var vy := p.velocity.y
	if StealthRules.landed(float(_vy.get(id, 0.0)), vy):
		if host:
			add_noise(p.global_position, StealthRules.NOISE_LANDING)
		if p == local_player:
			_local_event(StealthRules.NOISE_LANDING)
	_vy[id] = vy


# --- Noises monsters hear -------------------------------------------------------------------------

## Host: a noise at `pos` heard up to `radius` blocks away for StealthRules.NOISE_TIME (from `at`).
static func add_noise(pos: Vector3, radius: float, attack: bool = false, at: float = -1.0) -> void:
	if not pos.is_finite() or radius <= 0.0:
		return
	var t := at if at >= 0.0 else Time.get_ticks_msec() / 1000.0
	var until := t + StealthRules.NOISE_TIME
	for n: Array in _noises:
		if (n[0] as Vector3).distance_to(pos) <= MERGE:
			n[0] = pos
			n[1] = maxf(n[1], radius)
			n[2] = maxf(n[2], until)
			n[3] = n[3] or attack
			return
	_noises.append([pos, radius, until, attack])
	if _noises.size() > MAX_NOISES:
		_noises.pop_front()


## The nearest noise a listener at `pos` hears at time `t` (seconds), or INF.
static func heard_at(pos: Vector3, t: float) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for n: Array in _noises:
		if n[2] < t:
			continue
		var d := (n[0] as Vector3).distance_to(pos)
		if d <= n[1] and d < best_d:
			best_d = d
			best = n[0]
	return best


## The newest attack heard at time `t` within HIT_HEARING of `pos` (a hit monster hears where the shot
## came from), or INF.
static func last_attack_near(pos: Vector3, t: float) -> Vector3:
	var best := Vector3.INF
	var newest := -INF
	for n: Array in _noises:
		if n[3] and n[2] >= t and (n[0] as Vector3).distance_to(pos) <= HIT_HEARING and n[2] > newest:
			newest = n[2]
			best = n[0]
	return best


static func clear_noises() -> void:
	_noises.clear()


func _attack_noise(peer_id: int) -> void:
	var p := Session._player_for_peer(peer_id)
	if p:
		add_noise(p.global_position, StealthRules.NOISE_ATTACK, true)
		if p == local_player:
			_local_event(StealthRules.NOISE_ATTACK)


func _on_block_changed(pos: Vector3i, old_id: int, new_id: int) -> void:
	if new_id == BlockIds.AIR and BlockIds.is_solid(old_id):
		add_noise(Vector3(pos) + Vector3(0.5, 0.5, 0.5), StealthRules.NOISE_BREAK)
	if StealthRules.is_hiding_block(new_id):
		return
	for p in Monster.players_now(get_tree()):
		if p.hidden_in == pos:
			Session.stealth_broadcast_hidden(p.peer_id, false, pos)


# --- This game's player: the HUD ------------------------------------------------------------------

func _local_event(radius: float) -> void:
	if now() > _local_noise_until or radius > _local_noise:
		_local_noise = radius
	_local_noise_until = now() + StealthRules.NOISE_TIME


## How far away this game's player is heard right now (moving, landing, breaking, attacking).
func local_noise() -> float:
	if not is_instance_valid(local_player) or local_player.is_hiding():
		return 0.0
	var v := local_player.velocity
	var noise := StealthRules.move_noise(Vector2(v.x, v.z).length(), local_player.crouching)
	if now() <= _local_noise_until:
		noise = maxf(noise, _local_noise)
	return noise

# --- Hiding in barrels and closets ----------------------------------------------------------------

## Host: may this player hide in `cell`? Then every game puts them inside, and monsters that were
## after them go to search next to it.
func _on_hide_requested(peer_id: int, cell: Vector3i) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null or not p.is_spawned() or p.knocked_out or p.sleeping or block_at.is_null():
		return
	var why := StealthRules.hide_refusal(p.eye_position(), cell, block_at.call(cell), _taken(cell, p), StealthRules.HIDE_SLACK)
	if why != "":
		if why != "?":
			Session.send_feedback(peer_id, why)
		return
	var spot := StealthRules.search_spot(cell, p.global_position, func(c: Vector3i) -> bool: return BlockIds.is_solid(block_at.call(c)))
	Session.stealth_broadcast_hidden(peer_id, true, cell)
	for m in Monster.all_monsters():
		m.saw_hide(p, spot)


func _taken(cell: Vector3i, by: Player) -> bool:
	for p in Monster.players_now(get_tree()):
		if p != by and p.hidden_in == cell:
			return true
	for b in get_tree().get_nodes_in_group(&"bot_friends"):   # M4 H: a bot friend hiding in it
		if b is BotFriend and (b as BotFriend).game_hidden_in == cell:
			return true
	return false


func _on_unhide_requested(peer_id: int) -> void:
	var p := Session._player_for_peer(peer_id)
	if p and p.is_hiding():
		Session.stealth_broadcast_hidden(peer_id, false, p.hidden_in)


## A knock-out brings a hidden player out first (they lie down outside).
func _on_player_hurt(peer_id: int, hp: int, _from: Vector3) -> void:
	if hp > 0:
		return
	var p := Session._player_for_peer(peer_id)
	if p and p.is_hiding():
		Session.stealth_broadcast_hidden(peer_id, false, p.hidden_in)


func _send_hidden_to(to_peer: int) -> void:
	for p in Monster.players_now(get_tree()):
		if p.is_hiding():
			Session.stealth_send_hidden(to_peer, p.peer_id, p.hidden_in)


## Every game: the host said a player is inside a hiding spot now, or out of it.
func _on_hidden_changed(peer_id: int, hidden: bool, cell: Vector3i) -> void:
	var p := Session._player_for_peer(peer_id)
	if p:
		p.set_hidden(hidden, cell)


## A lantern or light block within StealthRules.LIGHT_RADIUS of `head`: one bulk copy of the box and a
## native search of its bytes (MonsterDirector.find_blocks), not a call per cell.
static func light_around(world: WorldService, head: Vector3) -> bool:
	var r := StealthRules.LIGHT_RADIUS
	var origin := Vector3i(head.floor()) - Vector3i(r, r, r)
	var buf := world.copy_box(origin, Vector3i(2 * r + 1, 2 * r + 1, 2 * r + 1))
	return not MonsterDirector.find_blocks(buf, origin, StealthRules.LIGHT_BLOCKS).is_empty()
