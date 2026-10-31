class_name SecretDirector
extends Node
## Secrets and treasures in a world (M2 Task 16, spec §12.16). The sandbox adds one on every peer, always
## named "Secrets", so its spawner and RPCs line up across the network.
##
## Host: brings the secrets' things (chests, riddle notes, a temple's plate pictures) to life near players
## and removes them when nobody is near; notices players finding secrets (walking into a temple, a sky
## island, a geode or a hidden room), rings the secret chime once per secret within 12 blocks, and decides
## every request (Session): a chest opens once per world, a temple's chest stays locked until its plates are
## stepped on in the riddle's order, a knock opens a fake wall. It keeps the world's clock of surprises:
## the Wanderer at dusk (his riddle is rewarded once), shooting stars at night, golden animals.
## Every peer: plays the effects and, for its own player, shows banners and fills the Secret Book.
## World access is injected (setup() takes it from a WorldService; tests use stubs).

## Local: this device's player heard a secret chime / saw a find's banner / got treasure.
signal chimed(secret_id: String)
signal found_shown(kind: StringName)
signal loot_shown(loot: Dictionary)
## Local: the Secret Book's world counts arrived (LAN guests ask the host).
signal counts_changed(counts: Vector2i)

const TICK := 0.5                 # seconds between the host's checks
const PLATE_TICK := 0.1           # temple plates are checked more often (a step is short)
const SPAWN_RADIUS := 40.0        # secrets' things appear within this (sideways) of a player
const DESPAWN_RADIUS := 64.0      # and go when every player is farther
const TELL_RADIUS := 24.0         # players this close to a find see its banner too
const MAX_THINGS := 48
const UNIVERSE := 1               # Green Meadows; treasure uses the world's universe, Game.universe (M3 Task 5)
const FOUND_TEXT := {
	SecretRules.TREASURE: "You found buried treasure!", SecretRules.ROOM: "You found a hidden room!",
	SecretRules.ISLAND: "You found a sky island!", SecretRules.GOLDEN: "You caught a golden animal!",
	SecretRules.TEMPLE: "You found a puzzle temple!", SecretRules.WANDERER: "You met the Wanderer!",
	SecretRules.STAR: "You found a fallen star!", SecretRules.GEODE: "You found a crystal geode!",
}
const PICTURES := {
	SecretRules.TREASURE: Riddles.CHEST, SecretRules.ROOM: Riddles.ROOM_DOOR, SecretRules.ISLAND: Riddles.ISLAND,
	SecretRules.GOLDEN: Riddles.GOLDEN, SecretRules.TEMPLE: Riddles.TEMPLE, SecretRules.WANDERER: Riddles.WANDERER,
	SecretRules.STAR: Riddles.STAR, SecretRules.GEODE: Riddles.GEODE,
}
const SPARKLE := Color("ffd23f")
const MAGIC := Color("b58cff")
const HINT_RADIUS := 700.0        # /secret looks this far
const HINT_NAMES := {SecretRules.TREASURE: "buried treasure", SecretRules.ROOM: "hidden room",
	SecretRules.TEMPLE: "puzzle temple", SecretRules.ISLAND: "sky island", SecretRules.GEODE: "crystal geode"}

var rules: SecretRules
## What a find says, per kind (M3 Task 2: a universe has its own words, e.g. the desert's pyramid; owner 42:
## the treasure pack's kinds too).
var found_text := FOUND_TEXT.merged(TreasureRules.FOUND_TEXT).merged(MouseVillages.FOUND_TEXT)   # M3 Task 21c: villages
## Owner 42: the treasure pack's host logic and effects (its child "Treasures" on every peer).
var treasures := TreasureDirector.new()
## M3 Task 21c: the Tiny world's mouse villages and the chest mimic (its child "Tiny" on every peer).
var tiny := TinyDirector.new()
var state := SecretState.new()    # host: the world's (WorldMeta.secrets); a guest: the opened chests
var world_seed := 0
var auto_tick := true             # tests call host_tick / plate_tick themselves
# World access (setup() fills them from a WorldService).
var block_at: Callable            # (pos: Vector3i) -> block id
var set_block: Callable           # (pos: Vector3i, id: int) -> void (host)
var is_ready: Callable            # (pos: Vector3) -> bool: terrain loaded there
var ground_at: Callable           # (x: int, z: int) -> the generator's ground height
var standing_y: Callable          # (x: int, z: int) -> where feet stand in that loaded column
var time_of_day: Callable         # () -> 0..1 (the host's clock)
var save_profile: Callable = func() -> void: Profile.save()
## This device's HUD (banners, the riddle panel) and player's interactor (a found map goes in hand).
var hud: Node
var interactor: BlockInteractor

var _things := Node3D.new()
var _spawner := MultiplayerSpawner.new()
var _t := 0.0
var _plate_t := 0.0
var _temples_near: Array = []
var _progress := {}               # temple id -> the plates stepped on in the right order so far
var _standing := {}               # "temple id:peer" -> the plate under that player (-1: none)
var _last_phase := -1
var _wanderer_left := 0.0
var _wanderer_due := false        # a visit this dusk, waiting for a spot where he can be seen
var _met := {}                    # peer -> true: met this visit's Wanderer
var _star_in := -1.0              # seconds until tonight's star falls (-1: none)
var _landing_in := -1.0           # seconds until a falling star lands
var _landing_at := Vector3i.ZERO
var _client_counts := Vector2i.ZERO
var _warm_task := -1              # the frame spikes: a waiting spawn's secrets worked out on a worker (warm_pending)
var _warmed := {}                 # player instance id -> the area its waiting spawn was warmed at


func _ready() -> void:
	add_to_group(&"secret_director")
	_things.name = "Things"
	add_child(_things)
	_spawner.name = "ThingSpawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_things)
	_spawner.spawn_function = _make_thing
	treasures.name = "Treasures"
	treasures.secrets = self
	add_child(treasures)
	tiny.name = "Tiny"   # M3 Task 21c
	tiny.secrets = self
	add_child(tiny)
	Session.secret_chest_requested.connect(_on_chest_requested)
	Session.secret_knock_requested.connect(_on_knock_requested)
	Session.secret_answer_requested.connect(_on_answer_requested)


## Host (or solo): the world's seed and saved state; world, when given, provides the block access.
func setup(seed: int, secret_state: SecretState, world: WorldService = null) -> void:
	world_seed = seed
	state = secret_state
	rules = SecretRules.new(seed, world.generator_shape() if world else null)
	if world:
		block_at = world.get_block
		set_block = world.set_block
		is_ready = world.is_area_ready
		ground_at = world.surface_height
		standing_y = world.find_standing_y


## A LAN guest: the same rules from the host's seed; the host sends which chests are open.
func setup_client(seed: int) -> void:
	world_seed = seed
	rules = SecretRules.new(seed)
	_rpc_hello.rpc_id(1)


func _process(delta: float) -> void:
	if not auto_tick or rules == null or not multiplayer.is_server():
		return
	warm_pending()
	_plate_t += delta
	if _plate_t >= PLATE_TICK:
		_plate_t = 0.0
		plate_tick()
	_t += delta
	if _t >= TICK:
		host_tick(_t)
		_t = 0.0


func thing(thing_name: String) -> SecretThing:
	var n := _things.get_node_or_null(NodePath(thing_name)) as SecretThing
	return n if n != null and not n.is_queued_for_deletion() else null


func wanderer() -> Wanderer:
	for n in _things.get_children():
		if n is Wanderer and not n.is_queued_for_deletion():
			return n
	return null


## The treasure map's target from `from`: the nearest buried treasure not opened yet ({} for none).
func map_target(from: Vector3) -> Dictionary:
	return rules.nearest_buried(from, state.opened) if rules else {}


## The Secret Book's world line: (found, total) secrets in the areas explored.
func book_counts() -> Vector2i:
	return state.counts() if multiplayer.is_server() else _client_counts


## /secret (a Sandbox cheat, for testing and for grown-ups helping a child): where the nearest secret of
## `kind` (&"" for any) that nobody found yet is, with a /tp to a spot next to it.
func hint(kind: StringName, near: Vector3) -> String:
	var best := {}
	var best_d := INF
	for s: Dictionary in rules.secrets_near(near, HINT_RADIUS) + rules.tiny_near(near, HINT_RADIUS):   # M3 Task 21c
		if (kind != &"" and s.kind != kind) or state.found.has(s.id) or state.opened.has(s.id):
			continue
		var d := Vector2(s.anchor.x - near.x, s.anchor.z - near.z).length()
		if d < best_d:
			best_d = d
			best = s
	if best.is_empty():
		if kind == TreasurePlaces.RAINBOW:
			return treasures.rainbow_now()   # owner 42: a rainbow comes while playing
		return tr("No %s nearby that nobody found.") % (hint_name(kind) if kind != &"" else "secret")
	var to := _hint_spot(best)
	return tr("Nearest %s: %s away. /tp %d %d %d") % [hint_name(best.kind), Lang.blocks(roundi(best_d)), to.x, to.y, to.z]


static func hint_name(kind: StringName) -> String:
	if kind == MouseVillages.KIND:
		return Lang.t(MouseVillages.HINT_NAME)   # M3 Task 21c
	return HINT_NAMES.get(kind, TreasureRules.HINT_NAMES.get(kind, "secret"))


## The picture of a kind of secret (the M2 kinds' or the treasure pack's).
static func picture_of(kind: StringName) -> int:
	if kind == MouseVillages.KIND:
		return TinyPictures.MOUSE   # M3 Task 21c
	return PICTURES.get(kind, TreasureRules.PICTURES.get(kind, Riddles.QUESTION))


## Where /secret sends you: into a room or temple, onto an island or into a geode, next to an X.
func _hint_spot(s: Dictionary) -> Vector3i:
	match s.kind:
		SecretRules.TREASURE:
			var c: Vector3i = s.chest
			return Vector3i(c.x + 2, rules.shape.height_at(c.x + 2, c.z), c.z)
		SecretRules.ISLAND:
			return (s.chest as Vector3i) + Vector3i(1, 0, 0)
		SecretRules.ROOM:
			return (s.fake_wall[0] as Vector3i) + (s.dir as Vector3i)
	return s.get("visit", s.anchor)   # owner 42: next to the pack's entrances


## Asks the host for the world counts (a guest's Secret Book); counts_changed answers.
func request_book_counts() -> void:
	if multiplayer.is_server():
		counts_changed.emit(state.counts())
	else:
		_rpc_ask_counts.rpc_id(1)


# --- Host: the checks ---------------------------------------------------------------------------

## Host (the frame spikes, 2026-09-30): the first tick next to a child worked out every secret and mouse village in
## reach on the main thread (world 41's spawn: 18-24 ms on the desktop, a phone's 3-5x as the child stands). While a
## player's spawn waits for its terrain (parked at its target: Player._begin_spawn), a worker works out what is in reach
## there (SecretRules' and MouseVillages' caches are locked: the generator's threads fill them too); once per spawn.
func warm_pending() -> void:
	if _warm_task >= 0:
		if not WorkerThreadPool.is_task_completed(_warm_task):
			return
		WorkerThreadPool.wait_for_task_completion(_warm_task)
		_warm_task = -1
	if rules == null:
		return
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p == null or p.is_spawned() or p.is_queued_for_deletion():
			continue
		var at := p.global_position
		var area := SecretRules.area_of(floori(at.x), floori(at.z))
		if _warmed.get(p.get_instance_id()) == area:
			continue
		_warmed[p.get_instance_id()] = area
		var r := rules
		_warm_task = WorkerThreadPool.add_task(func() -> void:
			r.secrets_near(at, SPAWN_RADIUS)
			r.tiny_near(at, SPAWN_RADIUS), false, "Secrets near a spawn")
		return


## A spawn's secrets are being worked out on a worker (warm_pending).
func warming() -> bool:
	return _warm_task >= 0 and not WorkerThreadPool.is_task_completed(_warm_task)


func _exit_tree() -> void:
	if _warm_task >= 0:   # it reads the rules only, but a task must be waited for once
		WorkerThreadPool.wait_for_task_completion(_warm_task)
		_warm_task = -1


func host_tick(delta: float) -> void:
	var players := _players()
	_update_clock(delta, players)
	var temples: Array = []
	for p in players:
		var pos := p.global_position
		var area := SecretRules.area_of(floori(pos.x), floori(pos.z))
		state.explore(area, rules.secrets_in_area(area).size() + rules.tiny_in_area(area).size())   # M3 Task 21c: villages
		for s: Dictionary in rules.secrets_near(pos, SPAWN_RADIUS) + rules.tiny_near(pos, SPAWN_RADIUS):
			_check_presence(p, s)
			_check_chime(p, s)
			_spawn_things(s)
			if s.kind == SecretRules.TEMPLE and not state.solved.has(s.id) and not temples.has(s):
				temples.append(s)
		_check_stars(p)
		_check_wanderer(p)
	_temples_near = temples
	treasures.host_tick(delta, players)   # owner 42
	tiny.host_tick(players)   # M3 Task 21c: tiny children find mouse villages
	_despawn_far(players)


## Temple plates: a player stepping onto a plate presses it (once per step).
func plate_tick() -> void:
	treasures.lever_tick()   # owner 42: the vaults' levers
	tiny.fast_tick(PLATE_TICK)   # M3 Task 21c: the chest mimics hop
	if _temples_near.is_empty():
		return
	var players := _players()
	for s: Dictionary in _temples_near:
		if state.solved.has(s.id):
			continue
		var plates: Array = s.plates
		for p in players:
			var feet := Vector3i(p.global_position.floor())
			var i := plates.find(feet)
			var key := "%s:%d" % [s.id, p.peer_id]
			if i == int(_standing.get(key, -1)):
				continue
			_standing[key] = i
			if i >= 0 and block_at.call(feet) == BlockIds.PRESSURE_PLATE:
				_press(s, i, p.peer_id)


func _players() -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.is_spawned() and not p.is_queued_for_deletion():
			out.append(p)
	return out


func _check_presence(p: Player, s: Dictionary) -> void:
	if state.found.has(s.id) or not s.has("inside"):
		return
	var feet := Vector3i(p.global_position.floor())
	if SecretRules._contains(s.inside[0], s.inside[1], feet):
		_mark_found(s, p.peer_id)


func _check_chime(p: Player, s: Dictionary) -> void:
	if state.chimed.has(s.id) or state.found.has(s.id):
		return
	if SurpriseRules.should_chime(p.global_position, s.anchor):
		state.chimed[s.id] = true
		_tell(p.peer_id, &"_rpc_chime", [s.id])
		_bot_notice(Vector3(s.anchor) + Vector3(0.5, 0.5, 0.5), MouseVillages.NOTICE if s.kind == MouseVillages.KIND \
			else TreasureRules.notice_text(s.kind))   # M3 Task 21c


## Host: the nearest chest nobody opened yet that isn't locked (its cell's centre), or INF — pets sniff it
## out (M2 Task 17, TreasureSniff; owner 42: every unlocked kind, not only buried treasure).
func nearest_buried_chest(from: Vector3) -> Vector3:
	if rules == null:
		return Vector3.INF
	var s := rules.nearest_buried(from, state.opened, SecretRules.NEAR_RINGS, TreasureRules.SNIFF_KINDS)
	return Vector3(s.chest) + Vector3(0.5, 0.0, 0.5) if not s.is_empty() else Vector3.INF


## Task 15's explorer bots walk over and point (BotDirector.notice), when that system is in the game.
func _bot_notice(point: Vector3, text: String) -> void:
	for n in get_tree().get_nodes_in_group(&"bot_director"):
		if n.has_method(&"notice"):
			n.call(&"notice", point, text)
			return
	var scene := get_tree().current_scene
	var bots := scene.get_node_or_null("BotDirector") if scene else null
	if bots and bots.has_method(&"notice"):
		bots.call(&"notice", point, text)


func _spawn_things(s: Dictionary) -> void:
	if _things.get_child_count() >= MAX_THINGS or not is_ready.call(Vector3(s.anchor)):
		return
	if s.has("chest") and thing("chest_" + s.id) == null:
		var cell: Vector3i = s.chest
		_spawner.spawn({"kind": "chest", "id": "chest_" + s.id, "secret": s.id, "pos": Vector3(cell) + Vector3(0.5, 0, 0.5),
			"yaw": s.yaw, "chest_kind": String(s.chest_kind), "golden": s.kind == SecretRules.ISLAND,
			"rarity": LootRules.roll(s.chest_kind, LootRules.chest_key(world_seed, cell), Game.universe, _survivor()).rarity,
			"opened": state.opened.has(s.id), "locked": bool(s.get("locked", false)) and not state.solved.has(s.id)})
	if s.has("note") and thing("note_" + s.id) == null:
		var cell: Vector3i = s.note.cell
		_spawner.spawn({"kind": "note", "id": "note_" + s.id, "secret": s.id, "pos": Vector3(cell) + Vector3(0.5, 0, 0.5),
			"yaw": s.note.yaw, "text": s.note.text, "pictures": s.note.pictures})
	if s.kind == SecretRules.TEMPLE and thing("marks_" + s.id) == null:
		_spawner.spawn({"kind": "marks", "id": "marks_" + s.id, "secret": s.id, "pos": Vector3(s.anchor),
			"yaw": SecretRules._yaw(-(s.dir as Vector3i)), "plates": s.plates, "symbols": s.symbols})
	treasures.spawn_things(s)   # owner 42: ghosts, wells, the pictures over a vault's levers
	tiny.spawn_things(s)   # M3 Task 21c: a mouse village's family
	if DragonNests.has_egg(s, state) and thing("egg_" + s.id) == null:   # owner 39: a dragon nest's egg
		_spawner.spawn({"kind": "egg", "id": "egg_" + s.id, "secret": s.id, "pos": Vector3(s.egg) + Vector3(0.5, 0, 0.5)})


func _despawn_far(players: Array[Player]) -> void:
	for n in _things.get_children():
		var t := n as SecretThing
		if t == null or t is Wanderer or t.stays or t.is_queued_for_deletion():
			continue
		var near := false
		for p in players:
			if Vector2(p.global_position.x - t.position.x, p.global_position.z - t.position.z).length() <= DESPAWN_RADIUS:
				near = true
				break
		if not near:
			t.queue_free()


func _make_thing(data: Variant) -> Node:
	var d: Dictionary = data
	var t: SecretThing
	match str(d.kind):
		"chest":
			t = TreasureChest.new()
		"note":
			t = RiddleNote.new()
		"marks":
			t = TempleMarks.new()
		"egg":
			t = DragonEgg.new()   # owner 39
		_:
			t = TreasureDirector.make_thing(str(d.kind))   # owner 42
			if t == null:
				t = TinyDirector.make_thing(str(d.kind))   # M3 Task 21c: mice, a chest mimic
			if t == null:
				t = Wanderer.new()
	t.call(&"setup", d)
	return t


func _survivor() -> bool:
	return Game.mode == ModeRules.SURVIVOR


# --- Host: finds and rewards --------------------------------------------------------------------

func _mark_found(s: Dictionary, finder: int) -> void:
	state.found[s.id] = true
	_announce(s.kind, finder, Vector3(s.anchor) + Vector3(0.5, 0.5, 0.5), str(s.get("words", "")))


## The finder, and every player within TELL_RADIUS, see the banner and count it in their Secret Book. `words` (owner
## #78): a secret's own words (a wonder's hidden room ends with its own real fact); else the kind's (found_text).
func _announce(kind: StringName, finder: int, pos: Vector3, words: String = "") -> void:
	var method := &"_rpc_found" if words == "" else &"_rpc_found_words"
	var args: Array = [String(kind), pos] if words == "" else [String(kind), pos, words]
	_tell(finder, method, args)
	for p in _players():
		if p.peer_id != finder and p.global_position.distance_to(pos) <= TELL_RADIUS:
			_tell(p.peer_id, method, args)


## Runs `method` with `args` on `peer`'s game: here when it is this game, else as an RPC.
func _tell(peer: int, method: StringName, args: Array) -> void:
	if peer == multiplayer.get_unique_id():
		callv(method, args)
	elif multiplayer.get_peers().has(peer):
		callv(&"rpc_id", [peer, method] + args)


func _give(peer: int, loot: Dictionary) -> void:
	if _survivor():
		if int(loot.gold) > 0:
			Session.gold_add(peer, int(loot.gold), "treasure")
		var inv := Session.inventory_of(peer)
		for e: Array in loot.items:
			inv.add(int(e[0]), int(e[1]))
	_tell(peer, &"_rpc_loot", [loot])


func _on_chest_requested(peer: int, chest_name: String) -> void:
	var chest := thing(chest_name) as TreasureChest
	var requester := Session._player_for_peer(peer)
	if chest == null or requester == null or not multiplayer.is_server():
		return
	if not PlacementRules.in_reach(requester.eye_position(), chest.cell(), PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		Session.send_feedback(peer, "Too far away!")
		return
	if state.opened.has(chest.secret_id) or chest.opened:
		Session.send_feedback(peer, "Empty! You opened it already.")
		return
	if chest.locked:
		Session.send_feedback(peer, TreasureRules.lock_text(chest.chest_kind))   # owner 42: levers, riddles
		return
	state.opened[chest.secret_id] = true
	chest.play_open.rpc()
	chest.opened = true
	_rpc_opened.rpc(chest.secret_id)
	if chest.chest_kind == &"buried" and _survivor() and Session.inventory_of(peer).take(ItemIds.TREASURE_MAP, 1):
		Session.send_feedback(peer, "Your map led you here! It crumbles to dust.")
	var s := rules.find(chest.secret_id)
	if not s.is_empty() and not state.found.has(s.id):
		_mark_found(s, peer)
	_give(peer, LootRules.roll(chest.chest_kind, LootRules.chest_key(world_seed, chest.cell()), Game.universe, _survivor()))


func _on_knock_requested(peer: int, pos: Vector3i) -> void:
	var requester := Session._player_for_peer(peer)
	if requester == null or not multiplayer.is_server():
		return
	if not PlacementRules.in_reach(requester.eye_position(), pos, PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		return
	var cells := SecretRules.fake_wall_group(pos, block_at)
	if cells.is_empty():
		return
	for c in cells:
		set_block.call(c, BlockIds.AIR)
	_rpc_knock.rpc(Vector3(pos) + Vector3(0.5, 0.5, 0.5))
	for s: Dictionary in rules.secrets_near(Vector3(pos), 32.0):
		if s.kind == SecretRules.ROOM and (s.fake_wall as Array).has(pos) and not state.found.has(s.id):
			_mark_found(s, peer)


func _press(s: Dictionary, plate: int, peer: int) -> void:
	var progress: Array[int] = _progress.get(s.id, [] as Array[int])
	var r := SurpriseRules.press_plate(progress, plate, s.order)
	_progress[s.id] = r.progress
	var cell: Vector3i = s.plates[plate]
	_rpc_plate.rpc(Vector3(cell) + Vector3(0.5, 0.3, 0.5), r.result != &"wrong")
	match r.result:
		&"ok":
			Session.send_feedback(peer, tr("Click! %d of 3") % (r.progress as Array).size())
		&"wrong":
			Session.send_feedback(peer, "Clunk! The plates pop back up. Look at the note!")
		&"solved":
			_solve(s, peer)


func _solve(s: Dictionary, peer: int) -> void:
	state.solved[s.id] = true
	for v: Vector3i in s.vault:
		set_block.call(v, BlockIds.AIR)
	var chest := thing("chest_" + s.id) as TreasureChest
	if chest:
		chest.locked = false
	var at := Vector3(s.vault[0]) + Vector3(0.5, 1.0, 0.5)
	_rpc_poof.rpc(at, SPARKLE)
	for p in _players():
		if p.peer_id == peer or p.global_position.distance_to(at) <= TELL_RADIUS:
			_tell(p.peer_id, &"_rpc_banner", ["The vault is open!", Riddles.CHEST])


# --- Host: dusk, night, the Wanderer, shooting stars ----------------------------------------------

func _update_clock(delta: float, players: Array[Player]) -> void:
	if time_of_day.is_valid():
		var phase := int(DayCycle.phase(float(time_of_day.call())))
		if _last_phase != -1 and phase != _last_phase:
			if phase == DayCycle.Phase.DUSK:
				_on_dusk()
			elif phase == DayCycle.Phase.NIGHT:
				_on_night()
		_last_phase = phase
		if phase == DayCycle.Phase.DUSK:
			_try_wanderer(players)
	if _wanderer_left > 0.0:
		_wanderer_left -= delta
		if _wanderer_left <= 0.0:
			_wanderer_leave()
	if _star_in >= 0.0:
		_star_in -= delta
		if _star_in < 0.0:
			_drop_star(players)
	if _landing_in >= 0.0:
		_landing_in -= delta
		if _landing_in < 0.0:
			_land_star()


func _on_dusk() -> void:
	state.dusks += 1
	_met.clear()
	_wanderer_due = wanderer() == null and SurpriseRules.wanderer_visits(world_seed, state.dusks)


## A visit due this dusk: he appears next to the first player with a spot at their level in sight. Tried
## every tick of the dusk, so a child who is indoors when it starts still meets him outside.
func _try_wanderer(players: Array[Player]) -> void:
	if not _wanderer_due:
		return
	for p in players:
		if not is_ready.call(p.global_position):
			continue
		var place := SurpriseRules.wanderer_place(world_seed, state.dusks, p.global_position, standing_y, _sees)
		if place.is_empty():
			continue
		_wanderer_due = false
		var pos: Vector3 = place.pos
		var to := p.global_position - pos
		_spawner.spawn({"kind": "wanderer", "id": "Wanderer%d" % state.dusks, "pos": pos, "yaw": atan2(-to.x, -to.z),
			"riddle": SurpriseRules.wanderer_riddle(world_seed, state.dusks), "dusk": state.dusks})
		_wanderer_left = SurpriseRules.WANDERER_STAY
		_rpc_poof.rpc(pos + Vector3(0, 1, 0), MAGIC)
		for other in players:
			if other.global_position.distance_to(pos) <= TELL_RADIUS * 2.0:
				Session.send_feedback(other.peer_id, "A stranger in a hood is here...")
		return


## A clear line from `from` to `to` (a grid ray over the voxel data; water and air don't block).
func _sees(from: Vector3, to: Vector3) -> bool:
	var dist := from.distance_to(to)
	return dist < 0.001 or GridRay.cast(from, to - from, dist,
		func(p: Vector3i) -> bool: return BlockIds.is_solid(block_at.call(p))) == null


func _check_wanderer(p: Player) -> void:
	var w := wanderer()
	if w == null or _met.has(p.peer_id):
		return
	if Vector2(p.global_position.x - w.position.x, p.global_position.z - w.position.z).length() <= SurpriseRules.WANDERER_MEET:
		_met[p.peer_id] = true
		_tell(p.peer_id, &"_rpc_found", [String(SecretRules.WANDERER), w.position + Vector3(0, 1.5, 0)])


func _wanderer_leave() -> void:
	_wanderer_left = 0.0
	var w := wanderer()
	if w:
		_rpc_poof.rpc(w.position + Vector3(0, 1, 0), MAGIC)
		w.queue_free()


func _on_answer_requested(peer: int, visitor_name: String, choice: int) -> void:
	var w := _things.get_node_or_null(NodePath(visitor_name)) as Wanderer
	var requester := Session._player_for_peer(peer)
	if w == null or requester == null or w.is_queued_for_deletion() or not multiplayer.is_server():
		return
	if state.wanderer_rewarded == w.dusk:
		return
	if requester.global_position.distance_to(w.global_position) > SurpriseRules.WANDERER_REACH + PlacementRules.REACH_TOLERANCE:
		Session.send_feedback(peer, "Come closer to answer!")
		return
	if not SurpriseRules.is_right_answer(w.riddle, choice):
		Session.send_feedback(peer, "Hmm, not quite! Try again.")
		return
	state.wanderer_rewarded = w.dusk
	Session.send_feedback(peer, "\"Well done!\" says the Wanderer.")
	_give(peer, LootRules.roll(&"wanderer", LootRules.chest_key(world_seed, Vector3i(w.dusk, -7, 11)), Game.universe, _survivor()))
	_wanderer_leave()


func _on_night() -> void:
	_wanderer_due = false   # missed this time
	state.nights += 1
	if SurpriseRules.star_falls(world_seed, state.nights):
		_star_in = SurpriseRules.star_delay(world_seed, state.nights)


func _drop_star(players: Array[Player]) -> void:
	if players.is_empty():
		return
	var spot := SurpriseRules.star_spot(world_seed, state.nights, players[0].global_position, ground_at)
	if spot.is_empty():
		return
	_landing_at = spot.ground
	var to := Vector3(_landing_at) + Vector3(0.5, 0.5, 0.5)
	_rpc_star.rpc(to + Vector3(-40, 90, -25), to)
	_landing_in = SurpriseRules.STAR_FALL_TIME


func _land_star() -> void:
	for e: Array in SurpriseRules.meteor_blocks(_landing_at):
		if SurpriseRules.meteor_may_replace(block_at.call(e[0])):
			set_block.call(e[0], e[1])
	if state.stars.size() < SecretState.MAX_STARS:
		state.stars.append(_landing_at)


func _check_stars(p: Player) -> void:
	for g in state.stars.duplicate():
		var at := Vector3(g) + Vector3(0.5, 0.5, 0.5)
		if Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() <= SurpriseRules.STAR_REACH \
				and absf(p.global_position.y - at.y) < 6.0:
			state.stars.erase(g)
			_announce(SecretRules.STAR, p.peer_id, at)


# --- Host: golden animals (and Task 4's golden slimes) ------------------------------------------

## Should the wild animal with this id be golden (and not caught yet in this world)?
func is_golden_spawn(animal_id: String) -> bool:
	return SurpriseRules.is_golden(world_seed, animal_id) and not state.caught.has(animal_id)


## A player caught a golden animal (the sandbox checked the reach): its reward, the banner, and it
## vanishes in sparkles.
func catch_golden(peer: int, animal: Node3D) -> void:
	reward_golden(peer, animal.global_position + Vector3(0, 0.5, 0), str(animal.name))
	animal.queue_free()


## The reward for a golden creature `id` caught by `peer` at `pos`: a pile of gold (Survivor) or a golden
## trophy (Sandbox), once per id. Task 4's golden slimes call it too.
func reward_golden(peer: int, pos: Vector3, id: String) -> void:
	if state.caught.has(id):
		return
	state.caught[id] = true
	_announce(SecretRules.GOLDEN, peer, pos)
	_give(peer, LootRules.golden_reward(LootRules.chest_key(world_seed, Vector3i(hash(id), 3, -3)), Game.universe, _survivor()))
	_rpc_poof.rpc(pos, SPARKLE)


# --- Every peer: effects and this player's banners ------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func _rpc_found(kind: String, pos: Vector3) -> void:
	_found_here(StringName(kind), pos, "")


## Owner #78: a secret's own words split for the banner (one line: the find, up to its first "!") and the toast (the
## fact after it): ["You found a hidden room!", "In 2017 ..."].
static func split_words(words: String) -> Array[String]:
	var i := words.find("! ")
	if i < 0:
		return [words, ""]
	return [words.substr(0, i + 1), words.substr(i + 2).strip_edges()]


## Owner #78: a find with its own words (a wonder's secret and its real fact).
@rpc("authority", "call_remote", "reliable")
func _rpc_found_words(kind: String, pos: Vector3, words: String) -> void:
	_found_here(StringName(kind), pos, words)


func _found_here(k: StringName, pos: Vector3, words: String) -> void:
	Profile.data.record_secret(k)
	save_profile.call()
	var said := split_words(words)
	_banner(said[0] if words != "" else found_text.get(k, "You found a secret!"), picture_of(k))
	if said[1] != "" and is_instance_valid(hud) and hud.has_method(&"toast"):
		hud.call(&"toast", said[1], 8.0)   # the real fact after the find, long enough to read
	Audio.play(&"sparkle")
	if is_inside_tree():
		Fx.burst(get_tree().root, pos, SPARKLE, 30, 4.0, 0.1, 1.2, 2.0)
	found_shown.emit(k)


@rpc("authority", "call_remote", "reliable")
func _rpc_loot(loot: Dictionary) -> void:
	for e: Array in loot.get("items", []):
		if Profile.data.add_treasure(int(e[0])):
			save_profile.call()
	var text := LootRules.describe(loot)
	if text != "":
		_banner(_loot_title(loot) + text, int(loot.get("picture", Riddles.CHEST)))
	var has_map := (loot.get("items", []) as Array).any(func(e: Array) -> bool: return int(e[0]) == ItemIds.TREASURE_MAP)
	if has_map and is_instance_valid(interactor):
		interactor.set_slot_block(interactor.selected_slot, ItemIds.TREASURE_MAP)   # hold it: the arrow shows the way
	loot_shown.emit(loot)


@rpc("authority", "call_remote", "reliable")
func _rpc_banner(text: String, picture: int) -> void:
	_banner(text, picture)
	Audio.play(&"sparkle")


## The secret chime: a hint that something is near, never where (a sound for this player only, and a
## twinkle around them, not at the secret).
@rpc("authority", "call_remote", "reliable")
func _rpc_chime(secret_id: String) -> void:
	Audio.play(&"chime")
	if is_instance_valid(interactor) and interactor.player.is_inside_tree():
		Fx.burst(get_tree().root, interactor.player.global_position + Vector3(0, 2.2, 0), Color("fff3a8"), 12, 1.5, 0.07, 1.0, -0.5)
	chimed.emit(secret_id)


@rpc("authority", "call_local", "reliable")
func _rpc_knock(at: Vector3) -> void:
	Audio.play(&"knock", at)
	Fx.burst(get_tree().root, at, Color("8e949b"), 22, 3.0, 0.14, 0.8, 9.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_plate(at: Vector3, good: bool) -> void:
	Audio.play(&"plate_click" if good else &"plate_wrong", at)
	Fx.burst(get_tree().root, at, Color("7cf28a") if good else Color("e8403a"), 10, 2.0, 0.08, 0.5, 4.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_poof(at: Vector3, color: Color) -> void:
	Fx.burst(get_tree().root, at, color, 36, 4.5, 0.12, 1.1, 1.0)
	Audio.play(&"sparkle", at)


@rpc("authority", "call_local", "reliable")
func _rpc_star(from: Vector3, to: Vector3) -> void:
	ShootingStar.fall(get_tree().root, from, to)


@rpc("authority", "call_remote", "reliable")
func _rpc_opened(secret_id: String) -> void:
	state.opened[secret_id] = true


@rpc("authority", "call_remote", "reliable")
func _rpc_opened_list(ids: Array) -> void:
	for id: Variant in ids:
		if id is String:
			state.opened[id] = true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_hello() -> void:
	if multiplayer.is_server():
		_rpc_opened_list.rpc_id(multiplayer.get_remote_sender_id(), state.opened.keys())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ask_counts() -> void:
	if multiplayer.is_server():
		var c := state.counts()
		_rpc_counts.rpc_id(multiplayer.get_remote_sender_id(), c.x, c.y)


@rpc("authority", "call_remote", "reliable")
func _rpc_counts(found: int, total: int) -> void:
	_client_counts = Vector2i(found, total)
	counts_changed.emit(_client_counts)


func _banner(text: String, picture: int) -> void:
	if is_instance_valid(hud) and hud.has_method(&"show_banner"):
		hud.call(&"show_banner", text, picture)


## A treasure banner's first words: the pack's chests name their rarity ("Epic treasure! "), a wish or a pot
## of gold its own (owner 42); the M2 chests "Treasure! ".
static func _loot_title(loot: Dictionary) -> String:
	if loot.has("title"):
		return str(loot.title)
	if loot.has("tier"):
		return Lang.t("%s treasure! ") % ItemRarity.label(int(loot.tier))
	return "Treasure! "
