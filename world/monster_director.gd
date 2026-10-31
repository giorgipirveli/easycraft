class_name MonsterDirector
extends Node
## Monsters in a world (M2 Task 4, spec §12.4 and §12.15). The sandbox adds one on every peer, always
## named "Monsters", so its spawners and effects line up across the network (like CombatDirector).
## Host: once a second (tick) it brings night monsters to every player (MonsterRules: on the surface
## 18-40 blocks away, never near a light or a home bed, 20 in all and 10 per player, level by the
## distance from the world spawn, at most MAX_SPAWNS_PER_TICK a tick), puffs the wild ones away at
## sunrise (no gold), sends far-away ones home, and turns each defeat into confetti, coins (Survivor)
## and, for a big slime, two small ones. Sandbox monsters are gentle: 8 at most, levels 1-2, confetti
## only. /summon brings one of a chosen level that is not wild (it stays in the day).
## World access is injected, so tests drive the host side with stubs. Wild monsters are not saved:
## they come back at night. Monsters never change blocks (lead ruling): nothing here edits the world.

## Everyone hears about a defeat here (waves, bots and the HUD can listen): kind, level, where.
signal monster_defeated(kind: StringName, level: int, pos: Vector3)

const TICK := 1.0
## Monsters built per tick, over all players (the animals' lesson: building many in one frame costs).
const MAX_SPAWNS_PER_TICK := 3
const MAX_TRIES_PER_TICK := 8     # spots looked at per tick (each reads the world a little)
const MAX_COINS := 40             # coins lying around at once; the oldest goes first
const CROWDED_MESSAGE := "Lots of monsters here already!"
const CONFETTI: Array[Color] = [Color("ffd23f"), Color("ff5c8a"), Color("3fc1ff"), Color("7be05e")]
const PUFF_COLOR := Color(0.93, 0.93, 0.97)
const BURST_CONFETTI := 0
const BURST_PUFF := 1

# Host side, injected by the sandbox (tests use stubs).
var player_positions: Callable    # () -> Array[Vector3]
var is_ready: Callable            # (pos: Vector3) -> bool: terrain (and collision) loaded there
var stand_spot: Callable          # (x: int, z: int) -> Vector3: feet on the surface, or Vector3.INF
var lights_near: Callable         # (pos: Vector3) -> Array[Vector3i]: lanterns and light blocks around
var home_beds: Callable           # () -> Array[Vector3i]: every player's home bed
var time_of_day: Callable         # () -> float (DayCycle)
var enabled: Callable             # () -> bool: monsters come by themselves (mode and world setting)
var gentle := false               # Sandbox (§12.15): fewer, weaker, confetti only
var world_spawn := Vector3.ZERO
var universe := 1
## The universe's night monsters (M3 Task 2: the desert's mummies and scorpions); the first is 3 in 5.
var kinds: Array[StringName] = MonsterRules.MEADOWS_KINDS
## Every peer: block_at(pos: Vector3i) -> int for monsters and coins, read only.
var block_at: Callable = _world_block
## Host: light_at(feet: Vector3) -> float, the light where a monster stands (M3 Task 4: a candy sneaker hides
## in the dark; the sandbox gives StealthDirector.light_at).
var light_at: Callable
var rng := RandomNumberGenerator.new()
var running := false              # host: ticking (start())

var _t := 0.0
var _turn := 0
var _next_id := 1
var _list := Node3D.new()
var _spawner := MultiplayerSpawner.new()
var _coins := Node3D.new()
var _coin_spawner := MultiplayerSpawner.new()


func _init() -> void:
	rng.randomize()


func _ready() -> void:
	_list.name = "List"
	add_child(_list)
	_spawner.name = "MonsterSpawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_list)
	_spawner.spawn_function = _make_monster
	_coins.name = "Coins"
	add_child(_coins)
	_coin_spawner.name = "CoinSpawner"
	add_child(_coin_spawner)
	_coin_spawner.spawn_path = _coin_spawner.get_path_to(_coins)
	_coin_spawner.spawn_function = _make_coin


## Host: begin the night spawns (once the world and the callables are in place).
func start() -> void:
	running = true


func _process(delta: float) -> void:
	if not running:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


func _world_block(pos: Vector3i) -> int:
	return Session.world.get_block(pos) if Session.world else BlockIds.AIR


func monsters() -> Array[Monster]:
	var out: Array[Monster] = []
	for n in _list.get_children():
		if n is Monster and not n.is_queued_for_deletion():
			out.append(n)
	return out


func coins() -> Array[Coin]:
	var out: Array[Coin] = []
	for n in _coins.get_children():
		if n is Coin and not n.is_queued_for_deletion():
			out.append(n)
	return out


# --- Host: the night ------------------------------------------------------------------------------

## Host, once a second: sunrise puffs, far ones leave, and at night new ones come.
func tick() -> void:
	var players: Array[Vector3] = []
	players.assign(player_positions.call())
	var t: float = time_of_day.call()
	var on: bool = enabled.call()
	for m in monsters():
		if MonsterRules.puffs(t, m.wild) or (m.wild and not on):
			puff(m)
		elif m.wave == 0 and MonsterRules.should_despawn(m.global_position, players):   # wave monsters stay (M2 Task 9)
			m.queue_free()
	if players.is_empty() or not on or not DayCycle.is_night(t):
		return
	var spots: Array[Vector3] = []
	for m in monsters():
		spots.append(m.global_position)
	var homes: Array[Vector3i] = []
	homes.assign(home_beds.call())
	var fresh := MAX_SPAWNS_PER_TICK
	var tries := MAX_TRIES_PER_TICK
	_turn += 1
	for k in players.size():
		var p := players[(_turn + k) % players.size()]   # a different player goes first each tick
		var budget := _budget(spots.size(), _near(spots, p))   # Survivor games: Build to Survive allows more
		while budget > 0 and fresh > 0 and tries > 0:
			tries -= 1
			var pos := _spot_near(p, players, homes)
			if not pos.is_finite():
				continue
			var from_spawn := Vector2(pos.x - world_spawn.x, pos.z - world_spawn.z).length()
			var kind := MonsterRules.pick_kind(rng.randf(), kinds)
			var id := _new_id()
			var level := _night_level(MonsterRules.level_for(from_spawn, rng.randi_range(-1, 1), gentle))
			kind = ArcherRules.night_kind(kind, level, posmod(hash(id + ":bow"), 1000) / 1000.0)   # M3 Task 14b
			spawn_monster({"kind": kind, "id": id, "pos": pos,
				"level": level,
				"yaw": rng.randf() * TAU, "wild": true, "universe": universe,
				"golden": MonsterRules.can_be_golden(kind) and SurpriseRules.golden_slime(rng.randi(), not gentle)})
			spots.append(pos)
			budget -= 1
			fresh -= 1


## A spot for a night monster around the player at `p`, or Vector3.INF. The cheap checks come first;
## the light scan reads a box of blocks, so it comes last.
func _spot_near(p: Vector3, players: Array[Vector3], homes: Array[Vector3i]) -> Vector3:
	var xz := MonsterRules.ring_spot(p, rng.randf() * TAU, rng.randf())
	var pos: Vector3 = stand_spot.call(floori(xz.x), floori(xz.y))
	if not pos.is_finite() or not is_ready.call(pos):
		return Vector3.INF
	var no_lights: Array[Vector3i] = []
	if MonsterRules.spot_refusal(pos, players, no_lights, homes) != &"":
		return Vector3.INF
	var lights: Array[Vector3i] = []
	lights.assign(lights_near.call(pos))
	if MonsterRules.spot_refusal(pos, players, lights, homes) != &"":
		return Vector3.INF
	return pos


func _near(spots: Array[Vector3], p: Vector3) -> int:
	var n := 0
	for s in spots:
		if Vector2(s.x - p.x, s.z - p.z).length() <= MonsterRules.NEAR_PLAYER:
			n += 1
	return n


func _new_id() -> String:
	_next_id += 1
	return "m%d" % (_next_id - 1)


## Host (M3 Task 14b): shoot_arrow(from, velocity, damage) -> int for goblin archers (BlasterDirector.monster_arrow).
var shoot_arrow: Callable


## Host: a golden slime was caught: (peer, where, its id) -> the secrets' reward (the sandbox sets it).
var golden_caught: Callable = func(_peer: int, _pos: Vector3, _id: String) -> void: pass


## Host: a monster for everyone. data = Monster.setup's.
func spawn_monster(data: Dictionary) -> Monster:
	return _spawner.spawn(data) as Monster


func _make_monster(data: Variant) -> Node:
	var m := Monster.new()
	m.setup(data)
	m.block_at = block_at
	m.light_at = light_at   # M3 Task 4
	m.shoot_arrow = shoot_arrow   # M3 Task 14b: goblin archers' arrows (host)
	if multiplayer.is_server():
		m.defeated.connect(_on_defeated)
		m.lost.connect(puff)   # owner #39: a flyer lost in the void puffs away (no gold)
	return m


## Host: the monster puffs away (sunrise, Monsters: OFF): a little cloud, no gold.
func puff(m: Monster) -> void:
	_rpc_burst.rpc(m.hit_center(), BURST_PUFF)
	m.queue_free()


func puff_all() -> void:
	for m in monsters():
		puff(m)


## Host: /summon (Sandbox cheat): a monster of `level` a few blocks from `near`, facing the player.
## It is not wild, so the sun never puffs it away. Returns why none came ("" = it came).
func summon(kind: StringName, level: int, near: Vector3) -> String:
	if not MonsterRules.KINDS.has(kind):
		return ""
	if monsters().size() >= MonsterRules.MAX_TOTAL or _crowded_on_low(near):
		return CROWDED_MESSAGE
	var pos := MonsterRules.summon_spot(near, block_at, rng.randi())
	var to := near - pos
	spawn_monster({"kind": kind, "level": MonsterRules.level_of(level), "id": _new_id(), "pos": pos,
		"yaw": atan2(-to.x, -to.z) if Vector2(to.x, to.z).length() > 0.01 else 0.0, "wild": false, "universe": universe})
	return ""


# --- Host: defeats and coins -----------------------------------------------------------------------

## A defeat: confetti for everyone (the shared Fx material), coins in Survivor, and a big slime
## splits into two small ones (level 1, never splitting again).
func _on_defeated(m: Monster) -> void:
	var at := m.hit_center()
	_rpc_burst.rpc(at, BURST_CONFETTI)
	if m.golden:   # §12.16 #4: the one who caught it gets the secret's reward instead of coins
		golden_caught.call(_catcher(m.last_hit_from), m.global_position, m.monster_id)
		monster_defeated.emit(m.kind, m.level, m.global_position)
		return
	if not gentle and not _paid_by_game(m):   # Monster Hunter pays the hunter itself (no coins)
		spawn_coins(at, MonsterRules.gold(m.kind, m.level, m.universe, m.half))
	if MonsterRules.splits(m.kind, m.level, m.half):
		var halves := MonsterRules.halves(m.kind)   # M3 Task 2: a big mummy unwraps into its top and its legs
		for i in MonsterRules.SPLIT_COUNT:
			var side := Vector3(0.45 if i == 0 else -0.45, 0.2, 0.0).rotated(Vector3.UP, m.rotation.y)
			spawn_monster({"kind": m.kind, "level": MonsterRules.SPLIT_LEVEL, "id": _new_id(),
				"pos": m.global_position + side, "yaw": m.rotation.y, "wild": m.wild, "universe": m.universe,
				"wave": m.wave, "goal": m.goal, "half": halves[i]})   # a wave slime's small ones join its wave (M2 Task 9)
	monster_defeated.emit(m.kind, m.level, m.global_position)


## Host: who caught a golden slime: the player nearest to where the last hit came from (the host's own
## player when nobody is known).
func _catcher(from: Vector3) -> int:
	var best := INF
	var peer := multiplayer.get_unique_id()
	for p in Monster.players_now(get_tree()):
		var d := p.global_position.distance_to(from) if from.is_finite() else 0.0
		if d < best:
			best = d
			peer = p.peer_id
	return peer


## Host: coins worth `gold` pop out at `at` (MonsterRules.coin_values: at most 5).
func spawn_coins(at: Vector3, gold: int) -> Array[Coin]:
	var out: Array[Coin] = []
	var values := MonsterRules.coin_values(gold)
	for i in values.size():
		_make_coin_room()
		var angle := TAU * i / values.size() + rng.randf() * 0.6
		var data := {"id": "c%d" % _next_id, "pos": at, "vel": Vector3(cos(angle) * 2.0, 4.5, sin(angle) * 2.0),
			"value": values[i]}
		_next_id += 1
		out.append(_coin_spawner.spawn(data) as Coin)
	return out


func _make_coin_room() -> void:
	var list := coins()
	if list.size() >= MAX_COINS:
		list[0].queue_free()


func _make_coin(data: Variant) -> Node:
	var c := Coin.new()
	c.setup(data)
	c.block_at = block_at
	return c


## Everyone: confetti (a defeat) or a puff (sunrise). Little cubes with the shared Fx material.
@rpc("authority", "call_local", "unreliable")
func _rpc_burst(pos: Vector3, kind: int) -> void:
	var root := get_tree().root
	if kind == BURST_CONFETTI:
		Fx.confetti(root, pos, CONFETTI, 32, 5.0, 0.1, 0.9, 7.0)   # M5 Task 2: one emitter, every colour
		Audio.play(&"pop", pos)
	else:
		Fx.burst(root, pos, PUFF_COLOR, 18, 2.2, 0.22, 0.8, -1.5)
		Audio.play(&"poof", pos, -4.0)


# --- Lanterns and lights near a spot ------------------------------------------------------------------

## The light blocks (MonsterRules.LIGHT_BLOCKS) within MonsterRules.LIGHT_CLEAR of `pos`: one bulk copy
## of the box around it and a scan of its bytes (no per-cell reads).
static func lights_around(tool: VoxelTool, pos: Vector3) -> Array[Vector3i]:
	var r := int(MonsterRules.LIGHT_CLEAR)
	var origin := Vector3i(pos.floor()) - Vector3i(r, r, r)
	var buf := VoxelBuffer.new()
	buf.create(2 * r + 1, 2 * r + 1, 2 * r + 1)
	tool.copy(origin, buf, 1 << VoxelBuffer.CHANNEL_TYPE)
	return find_blocks(buf, origin, MonsterRules.LIGHT_BLOCKS)


## Every cell of `buf` (copied from the world at `origin`) that holds one of `ids`. The channel's bytes are
## searched natively; a 16-bit voxel is its id's low byte then its high byte, so a match is a voxel's first
## byte whose next byte is the id's high byte (M3 Task 19: ROOF_TILES, 266, is 0x0A 0x01 and was taken for
## LIGHT, 10). Voxels are stored y fastest, then x, then z.
static func find_blocks(buf: VoxelBuffer, origin: Vector3i, ids: Array[int]) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var size := buf.get_size()
	if buf.is_uniform(VoxelBuffer.CHANNEL_TYPE):
		if ids.has(buf.get_voxel(0, 0, 0, VoxelBuffer.CHANNEL_TYPE)):
			out.append(origin)
		return out
	var stride := 2 if buf.get_channel_depth(VoxelBuffer.CHANNEL_TYPE) == VoxelBuffer.DEPTH_16_BIT else 1
	var bytes := buf.get_channel_as_byte_array(VoxelBuffer.CHANNEL_TYPE)
	for id in ids:
		if id < 0 or id >= (1 << (8 * stride)):
			continue   # an id this box can't hold
		var low := id & 0xFF
		var i := bytes.find(low)
		while i >= 0:
			if i % stride == 0 and (stride == 1 or bytes[i + 1] == id >> 8):
				var v := i / stride
				out.append(origin + Vector3i((v / size.y) % size.x, v % size.y, v / (size.y * size.x)))
			i = bytes.find(low, i + 1)
	return out

# --- Survivor games (spec §12.18; SurvivorGameDirector sets these on the host) ------------------------------

## Build to Survive: night monsters per player (MonsterRules.MAX_PER_PLAYER in the other games; the 20 in
## all stay) and levels added to a night monster's (at most 5).
var per_player_cap := MonsterRules.MAX_PER_PLAYER
var level_bonus := 0
## Monster Hunter: (m: Monster) -> bool, true when the game paid for this defeat itself (then no coins).
var defeat_payer: Callable


## M5 Task 3: the host phone's graphics preset caps the night monsters near each child (LOW: 6, so never more than
## 6 within the 32 blocks where monsters are simulated), whatever the game allows. 0: the game's caps only.
var near_cap := 0


func apply_preset(preset: String) -> void:
	near_cap = int(GraphicsPreset.params(preset).monsters_near)


## M5 Task 6 review: the cap holds for summons too (owner #51's MOBS tab brings one a tap): a child who has
## `near_cap` monsters around them on a weak phone gets the crowded words.
func _crowded_on_low(near: Vector3) -> bool:
	if near_cap <= 0:
		return false
	var spots: Array[Vector3] = []
	for m in monsters():
		spots.append(m.global_position)
	return _near(spots, near) >= near_cap


func _budget(total: int, near_player: int) -> int:
	var budget := 0
	if gentle or per_player_cap == MonsterRules.MAX_PER_PLAYER:
		budget = MonsterRules.spawn_budget(total, near_player, gentle)
	else:
		budget = maxi(mini(MonsterRules.MAX_TOTAL - total, per_player_cap - near_player), 0)
	return mini(budget, maxi(near_cap - near_player, 0)) if near_cap > 0 else budget


func _night_level(level: int) -> int:
	return level if gentle else MonsterRules.level_of(level + level_bonus)


func _paid_by_game(m: Monster) -> bool:
	return defeat_payer.is_valid() and bool(defeat_payer.call(m))

