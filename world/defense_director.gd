class_name DefenseDirector
extends Node
## Spike traps and lanterns in a world (M2 Task 8, spec §12.6). The sandbox adds one on every peer,
## always named "Defenses", so its effects line up across the network (like MonsterDirector).
## - Host, TICK apart: every monster (group `monsters`) standing on or in a spike trap is hurt
##   (DefenseRules.trap_tick: 2 a second through take_hit, from the first step) and the spikes pop up
##   on every game (Fx.spikes, one cached mesh). Players, bot friends and animals are never looked at.
##   Weak monsters (level 2 or less) are told the lanterns within LANTERN_LOOK_RADIUS (Monster.lanterns),
##   so they keep 6 blocks away.
## - The lanterns come from an index of 16-block chunks: each chunk is copied once (one bulk copy and
##   a native byte search), only once it is loaded, at most a few a tick, nearest first; the host keeps
##   it up to date from its world's block changes (note_block), a guest looks again every
##   cache_seconds. A copy waits on the voxel threads while terrain streams (19 ms on average, 202 ms at
##   worst in the benchmark, against 0.02 ms once settled), so looks are never made per monster.
## - This game: at most MAX_LIGHTS shared warm lights sit on the lanterns nearest the camera. Never a
##   light per lantern: on the emulator's GL renderer each light is one more pass over what it touches.
## World access is injected (tests use stubs). Nothing here ever changes a block.

const TICK := 0.1
const CHUNK := 16
const LANTERN_LOOK_RADIUS := 8.0  # a weak monster knows the lanterns this close
const LANTERN_REFRESH_TICKS := 3  # ... told again every 3 ticks, in turn (a block of walking at most)
const MAX_SCANS_PER_TICK := 4     # chunk copies per host tick
const MAX_SCANS_PER_LOOK := 4     # ... and per light look
const MAX_CHUNKS := 1024          # the index forgets everything past this (it fills again as needed)
const MAX_LIGHTS := 2
const LIGHT_RADIUS := 12.0        # lanterns this close to the camera get a light
const LIGHT_LOOK := 0.5           # seconds between light looks
const LIGHT_COLOR := Color(1.0, 0.72, 0.42)
const LIGHT_ENERGY := 1.6
const LIGHT_DAY_SHARE := 0.35     # by day a lantern's light is this share of its night strength
const LIGHT_RANGE := 7.0

## block_at(pos: Vector3i) -> int (host): the world, read only.
var block_at: Callable
## scan_chunk(chunk: Vector3i) -> Array[Vector3i]: every lantern in that chunk (one bulk copy).
var scan_chunk: Callable
## chunk_ready(chunk: Vector3i) -> bool: the chunk is loaded (a copy would read real blocks).
var chunk_ready: Callable
## camera() -> Camera3D (this game): where the lights go; time_of_day() -> float.
var camera: Callable
var time_of_day: Callable
## A guest's world does not announce edits: its index looks again after this long (host: never).
var cache_seconds := INF
var running := false              # host: traps and lantern fear (start())

var _t := 0.0
var _turn := 0
var _clock := 0.0
var _cooldowns := {}              # monster instance id -> seconds until a trap may hurt it again
var _under := {}                  # monster instance id -> [its feet cell, the trap there or NO_TRAP]
var _ticks := 0
var _chunks := {}                 # chunk -> {"at": clock when copied, "lanterns": Array[Vector3i]}
var _light_count := MAX_LIGHTS
var _lights: Array[OmniLight3D] = []
var _light_t := 0.0


func _ready() -> void:
	for i in MAX_LIGHTS:
		var l := OmniLight3D.new()
		l.name = "LanternLight%d" % i
		l.light_color = LIGHT_COLOR
		l.omni_range = LIGHT_RANGE
		l.omni_attenuation = 1.2
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		_lights.append(l)


## Host: traps and lantern fear begin (once the world and the callables are in place).
func start() -> void:
	running = true


func _process(delta: float) -> void:
	advance(delta)
	if running:
		_t += delta
		if _t >= TICK:
			_t -= TICK
			tick(TICK)
	if _light_count > 0 and camera.is_valid():
		_light_t -= delta
		if _light_t <= 0.0:
			_light_t = LIGHT_LOOK
			var cam: Camera3D = camera.call()
			if cam and cam.is_inside_tree():
				update_lights(cam.global_position, time_of_day.call() if time_of_day.is_valid() else DayCycle.MIDNIGHT)


## The index's clock (a guest's chunks grow old with it).
func advance(delta: float) -> void:
	_clock += delta


# --- Host: spike traps and lantern fear ----------------------------------------------------------------

## Host, TICK apart: traps hurt the monsters on them; weak monsters learn the lanterns near them (a
## third of them each tick).
func tick(delta: float) -> void:
	var budget := [MAX_SCANS_PER_TICK]
	var fearful := 0
	_turn = (_turn + 1) % LANTERN_REFRESH_TICKS
	_ticks += 1
	for n in get_tree().get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m == null or m.is_queued_for_deletion() or not m.has_method(&"take_hit"):
			continue
		_stab(m, delta)
		var monster := m as Monster
		if monster and not monster.is_queued_for_deletion() and DefenseRules.fears_lanterns(monster.level):
			if fearful % LANTERN_REFRESH_TICKS == (_turn + LANTERN_REFRESH_TICKS - 1) % LANTERN_REFRESH_TICKS:
				monster.lanterns = lanterns_near(monster.global_position, LANTERN_LOOK_RADIUS, budget)
			fearful += 1
	if _ticks % 10 == 0:                  # forget monsters that are gone
		for id: int in _under.keys():
			if not is_instance_id_valid(id):
				_under.erase(id)
				_cooldowns.erase(id)


## A monster on a spike trap is stabbed (DefenseRules.trap_tick). What is under its feet is read again
## only when it stands in another cell (or a trap was placed or broken: note_block).
func _stab(m: Node3D, delta: float) -> void:
	var id := m.get_instance_id()
	var feet := Vector3i((m.global_position + Vector3(0.0, 0.05, 0.0)).floor())
	var seen: Variant = _under.get(id)
	var trap: Vector3i
	if seen != null and seen[0] == feet:
		trap = seen[1]
	else:
		trap = DefenseRules.trap_under(m.global_position, block_at)
		_under[id] = [feet, trap]
	var cooldown: float = _cooldowns.get(id, 0.0)
	if trap == DefenseRules.NO_TRAP and cooldown <= 0.0:
		return                          # off the traps and ready: nothing to count
	var r := DefenseRules.trap_tick(cooldown, trap != DefenseRules.NO_TRAP, delta)
	if r.cooldown > 0.0:
		_cooldowns[id] = r.cooldown
	else:
		_cooldowns.erase(id)
	if r.hit:
		_rpc_spikes.rpc(trap)
		m.take_hit(DefenseRules.TRAP_DAMAGE, Vector3(trap) + Vector3(0.5, 1.0, 0.5), Vector3.ZERO)


## Everyone: the spikes of the trap at `cell` pop up.
@rpc("authority", "call_local", "unreliable")
func _rpc_spikes(cell: Vector3i) -> void:
	Fx.spikes(get_tree().root, cell)
	Audio.play(&"spikes", Vector3(cell) + Vector3(0.5, 1.0, 0.5), -4.0)


# --- The lantern index -----------------------------------------------------------------------------------

static func chunk_of(cell: Vector3i) -> Vector3i:
	return Vector3i(floori(cell.x / float(CHUNK)), floori(cell.y / float(CHUNK)), floori(cell.z / float(CHUNK)))


## The lanterns within `radius` of pos (cell middles), from the index. Chunks not copied yet are copied
## while `budget[0]` lasts (nearest first); the rest wait for a later look.
func lanterns_near(pos: Vector3, radius: float, budget: Array = [MAX_SCANS_PER_LOOK]) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var lo := chunk_of(Vector3i((pos - Vector3.ONE * radius).floor()))
	var hi := chunk_of(Vector3i((pos + Vector3.ONE * radius).floor()))
	var missing: Array[Vector3i] = []
	for cx in range(lo.x, hi.x + 1):
		for cy in range(lo.y, hi.y + 1):
			for cz in range(lo.z, hi.z + 1):
				var c := Vector3i(cx, cy, cz)
				var entry: Variant = _chunks.get(c)
				if entry == null or _clock - float(entry.at) > cache_seconds:
					missing.append(c)
				else:
					_collect(entry.lanterns, pos, radius, out)
	if missing.is_empty() or budget[0] <= 0 or not scan_chunk.is_valid():
		return out
	if missing.size() > 1:                # only when copying: the nearest chunks first
		var half := Vector3.ONE * CHUNK * 0.5
		missing.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
			return (Vector3(a * CHUNK) + half).distance_squared_to(pos) < (Vector3(b * CHUNK) + half).distance_squared_to(pos))
	for c in missing:
		if budget[0] <= 0:
			break
		if chunk_ready.is_valid() and not chunk_ready.call(c):
			continue
		budget[0] -= 1
		var found: Array[Vector3i] = []
		found.assign(scan_chunk.call(c))
		if _chunks.size() >= MAX_CHUNKS:
			_chunks.clear()
		_chunks[c] = {"at": _clock, "lanterns": found}
		_collect(found, pos, radius, out)
	return out


static func _collect(lanterns: Array[Vector3i], pos: Vector3, radius: float, out: Array[Vector3i]) -> void:
	for l in lanterns:
		if (Vector3(l) + Vector3(0.5, 0.5, 0.5)).distance_to(pos) <= radius:
			out.append(l)


## Host: a block changed in the world (WorldService.block_changed): a spike trap placed or broken
## counts at once, and so does a lantern in a chunk already copied.
func note_block(pos: Vector3i, old_id: int, new_id: int) -> void:
	if old_id == BlockIds.SPIKE_TRAP or new_id == BlockIds.SPIKE_TRAP:
		_under.clear()
	if old_id != BlockIds.LANTERN and new_id != BlockIds.LANTERN:
		return
	var entry: Variant = _chunks.get(chunk_of(pos))
	if entry == null:
		return
	var list: Array[Vector3i] = entry.lanterns
	if new_id == BlockIds.LANTERN:
		if not list.has(pos):
			list.append(pos)
	else:
		list.erase(pos)


# --- This game: the warm light around lanterns ----------------------------------------------------------

## Lantern lights for a graphics preset: none on Low (the lanterns still glow), else MAX_LIGHTS.
static func lights_for(preset: String) -> int:
	return 0 if preset == "low" else MAX_LIGHTS


func set_light_count(n: int) -> void:
	_light_count = clampi(n, 0, MAX_LIGHTS)
	if _light_count == 0:
		for l in _lights:
			l.visible = false


## The lights go to the lanterns nearest `from` (within LIGHT_RADIUS), softer by day.
func update_lights(from: Vector3, time_of_day_now: float) -> void:
	var near: Array[Vector3i] = []
	if _light_count > 0:
		near = DefenseRules.nearest(from, lanterns_near(from, LIGHT_RADIUS), _light_count)
	var energy := LIGHT_ENERGY * lerpf(1.0, LIGHT_DAY_SHARE, DayCycle.daylight(time_of_day_now))
	for i in _lights.size():
		var l := _lights[i]
		var on := i < near.size()
		if on:
			var at := Vector3(near[i]) + Vector3(0.5, 0.5, 0.5)
			if not l.global_position.is_equal_approx(at):
				l.global_position = at
			if not is_equal_approx(l.light_energy, energy):
				l.light_energy = energy
		if l.visible != on:
			l.visible = on
