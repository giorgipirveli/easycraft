class_name SkyDragon
extends StoneGolem
## The Sky Dragon, the Dragon Realm's boss (owner feedback #39, spec §14.2a; rules in SkyDragonRules; our own design).
## To the BossDirector it is a StoneGolem (the same fight, health bar, honest help, gold, win and loss); its flight,
## dive, crystal towers and looks are here. The host flies it (it is moved, never pushed: no physics but a small box
## for taps), round `center` (the Totem it came to):
## - it ARRIVES from high up and CIRCLES at FLY_HEIGHT over the ground under it;
## - it picks the nearest child, climbs and glows (DIVE_WARN) while its dive line shows on the ground on every screen
##   (dive_from, dive_to, synced), then swoops along that line: a child on it when it passes low is hurt through
##   Session.hurt_player (a bot friend through hurt()) and pushed off it; a step off the line dodges it;
## - it GLIDES low and slow after a dive (sword range), and after every second dive LANDS and RESTS (double damage);
## - crystal towers (SkyDragonTower, its children) rise when it has arrived and at a third of its health, and heal it
##   every second until broken (tower_spots, tower_hits, synced: every screen builds and breaks them).
## It never leaves the arena circle (SkyDragonRules.keep_in), keeps above the ground and cover under its body (read
## through block_at ten times a second, and along a dive's line once), and never changes a block. Cost: decisions at
## 10 Hz, a few vector sums a step, shared meshes; the boss music plays while it is in the world.

const P := SkyDragonRules.Phase
const BOX := Vector3(1.8, 1.6, 1.8)   # the collision box for taps: a small footprint (Buddy.MAX_FOOTPRINT)
const BOX_Y := 1.5
const HIT_UP := 1.6               # its hit centre over its feet
const HIT_R := 2.0                # it is big: children aim loosely
const CLIMB_SPEED := 12.0         # m/s up when the ground under it rises (cover ahead)
const WARN_CLIMB := 2.0           # m/s up while its line shows
const TURN_FAST := 9.0
const AHEAD := 2.0                # it looks at least this far ahead for rising ground
const LEAVE_SPEED := 7.0          # a lost fight: it flies up and away ...
const LEAVE_TIME := 2.2           # ... and is gone after this long
const LINE_LIFT := 0.06           # the dive line lies this far over the ground
const LINE_PULSE := 0.1           # the line breathes this much wider (never narrower than it hits)
const LOW_ABOVE := 5.0            # closer than this over the ground it reads under its whole body
const LINE_READS := 2             # samples of the ground along its dive line read each step of the wind-up
const READ_MEMORY := 10.0         # seconds it remembers the cells it read

## Synced (on change): the dive line on the ground, and the crystal towers (where they stand, the hits on each).
var dive_from := Vector3.INF
var dive_to := Vector3.INF
var tower_spots := PackedVector3Array()
var tower_hits := PackedByteArray()
## The middle of the arena it circles (the Totem it came to).
var center := Vector3.ZERO

# Host
var _floor := 0.0                 # the ground under it (and a little ahead), ten times a second
var _floor_here := 0.0
var _angle := 0.0                 # its place on the circle round `center`
var _dives := 0                   # dives since it last rested
var _dive_len := 0.0
var _dive_s := 0.0
var _dive_target_s := 0.0
var _dive_start_h := 0.0
var _dive_floors := PackedFloat32Array()   # the ground along the line, every DIVE_SAMPLE (smoothed, once all read)
var _line_raw := PackedFloat32Array()      # ... as read so far
var _memory := {}                 # cells read lately (Vector3i -> id)
var _memory_t := 0.0
## Host: world cells read so far (the cost bench and tests).
var reads := 0
var _dove := {}                   # instance ids this dive already hit
var _rises := 0                   # tower rises so far
var _heal_t := 0.0
var _arrive_from := Vector3.ZERO
var _arrive_to := Vector3.ZERO
var _vel := Vector3.ZERO

# Every screen
var _neck := Node3D.new()
var _wings: Array[Node3D] = []
var _tail := Node3D.new()
var _eyes := MeshInstance3D.new()
var _aura := MeshInstance3D.new()
var _line := MeshInstance3D.new()
var _towers: Array[SkyDragonTower] = []
var _built_spots := PackedVector3Array()
var _flap := 0.0
var _pitch := 0.0
var _bank := 0.0
var _last_yaw := 0.0
var _line_from := Vector3.INF
var _line_to := Vector3.INF


## data = {id, pos (its spot on the ground), yaw, max_hp, tired, center (the Totem; its spot when missing)}
func setup(data: Dictionary) -> void:
	super.setup(data)
	var c: Variant = data.get("center", position)
	center = c if c is Vector3 and (c as Vector3).is_finite() else position
	_floor = position.y
	_floor_here = position.y
	_angle = atan2(position.z - center.z, position.x - center.x) if _flat(position, center) > 0.1 else 0.0
	_arrive_to = SkyDragonRules.circle_point(center, _angle, _floor + SkyDragonRules.FLY_HEIGHT)
	_arrive_from = position + Vector3(0, SkyDragonRules.ARRIVE_HEIGHT, 0)
	position = _arrive_from
	_last_pos = position
	_last_yaw = rotation.y


func boss_kind() -> StringName:
	return BossRules.SKY_DRAGON


func win_sound() -> StringName:
	return &"sky_dragon_roar"


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = 0               # arriving: not a target yet
	collision_mask = 0                # it flies: nothing pushes it
	for unused: Node in [_arm_l, _arm_r, _held_rock]:   # the Golem's parts: not a dragon's
		unused.free()
	var box := BoxShape3D.new()
	box.size = BOX
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = BOX_Y
	add_child(shape)
	add_child(_body)
	_add_mesh(_body, SkyDragonModels.body_mesh())
	_add_mesh(_body, SkyDragonModels.gem_mesh())
	_aura.mesh = SkyDragonModels.aura_mesh()
	_aura.visible = false
	_body.add_child(_aura)
	_neck.name = "Neck"
	_neck.position = SkyDragonModels.NECK
	_add_mesh(_neck, SkyDragonModels.neck_mesh())
	_eyes.mesh = SkyDragonModels.eyes_mesh()
	_neck.add_child(_eyes)
	_stars.mesh = GolemModels.stars_mesh()
	_stars.position = SkyDragonModels.HEAD + Vector3(0, 1.0, 0)
	_stars.visible = false
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_neck.add_child(_stars)
	_body.add_child(_neck)
	for side in [1.0, -1.0]:
		var wing := Node3D.new()
		wing.name = "WingR" if side > 0.0 else "WingL"
		wing.position = Vector3(SkyDragonModels.WING.x * side, SkyDragonModels.WING.y, SkyDragonModels.WING.z)
		wing.scale.x = side
		_add_mesh(wing, SkyDragonModels.wing_mesh())
		_body.add_child(wing)
		_wings.append(wing)
	_tail.name = "Tail"
	_tail.position = SkyDragonModels.TAIL
	_add_mesh(_tail, SkyDragonModels.tail_mesh())
	_body.add_child(_tail)
	_line.name = "DiveLine"
	_line.mesh = SkyDragonModels.line_mesh()
	_line.top_level = true
	_line.visible = false
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:hp", ".:phase", ".:dive_from", ".:dive_to", ".:tower_spots", ".:tower_hits"]:
		cfg.add_property(NodePath(prop))
	for prop in [".:hp", ".:phase", ".:dive_from", ".:dive_to", ".:tower_spots", ".:tower_hits"]:   # rare: on change
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


func _ready() -> void:
	Music.play_boss(true)
	Audio.play(&"sky_dragon_roar", global_position)


func hit_center() -> Vector3:
	return global_position + Vector3(0, HIT_UP, 0)


func hit_radius() -> float:
	return HIT_R


func is_dazed() -> bool:
	return SkyDragonRules.is_resting(phase)


func is_down() -> bool:
	return phase == P.DOWN


## Its crystal towers on this screen (the ones of the last rise, broken ones too).
func towers() -> Array[SkyDragonTower]:
	var out: Array[SkyDragonTower] = []
	for t in _towers:
		if is_instance_valid(t) and not t.is_queued_for_deletion():
			out.append(t)
	return out


func standing_towers() -> int:
	return SkyDragonRules.standing(tower_hits)


func line_shown() -> bool:
	return _line.visible


func line_node() -> MeshInstance3D:
	return _line


# --- Hits (host) -------------------------------------------------------------------------------------------------

## Not while it arrives or is gone; double while it rests. At a third of its health the towers rise again. At 0 HP it
## announces `defeated` once and is gone (its towers with it).
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server() or not SkyDragonRules.hittable(phase):
		return
	hp = maxi(hp - SkyDragonRules.hit_taken(damage, is_dazed()), 0)
	if hp == 0:
		_defeated = true
		phase = P.DOWN
		defeated.emit(self)
		queue_free()
		return
	if SkyDragonRules.towers_due(_rises, hp, max_hp):
		_raise_towers()


## Host: tower `i` was hit (SkyDragonTower.take_hit); TOWER_HITS break it.
func hit_tower(i: int) -> void:
	if not multiplayer.is_server() or _defeated or _sleeping or i < 0 or i >= tower_hits.size():
		return
	if not SkyDragonRules.tower_standing(tower_hits[i]):
		return
	var h := tower_hits.duplicate()
	h[i] = h[i] + 1
	tower_hits = h
	_update_tower_looks()


## Host: a lost fight: it flies up and away and is gone.
func go_to_sleep() -> void:
	if _defeated or _sleeping:
		return
	_sleeping = true
	phase = P.DOWN
	collision_layer = 0
	_sink_t = 0.0


# --- Simulation (host) -------------------------------------------------------------------------------------------

func start_phase(p: int) -> void:
	phase = p
	_phase_t = 0.0
	collision_layer = LAYER if SkyDragonRules.hittable(p) else 0
	match p:
		P.DIVE_WARN:
			_plan_dive()
		P.DIVE:
			_read_line(1 << 20)           # whatever the wind-up left unread
			_dove.clear()
			_dive_s = 0.0
			_dive_len = _flat(dive_from, dive_to)
			_dive_start_h = global_position.y - _floor_along(0.0)
		P.CLIMB, P.TAKE_OFF:
			if _flat(global_position, center) > 0.1:
				_angle = atan2(global_position.z - center.z, global_position.x - center.x)
		P.REST:
			_dives = 0
			global_position.y = _floor_here


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or block_at.is_null():
		return
	if _sleeping:
		_fly_away(delta)
		return
	if _defeated:
		return
	if _dance_hold(delta):   # M3 Task 14a: the Dance Orb (StoneGolem): it hovers and wiggles
		return
	_phase_t += delta
	_memory_t += delta
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t += AI_INTERVAL
		_decide_dragon()
	_heal(delta)
	if phase == P.DIVE_WARN:
		_read_line(LINE_READS)
	var before := global_position
	match phase:
		P.RISE:
			var k := clampf(_phase_t / SkyDragonRules.phase_time(P.RISE, tired), 0.0, 1.0)
			global_position = _arrive_from.lerp(_arrive_to, 1.0 - (1.0 - k) * (1.0 - k))
		P.CIRCLE:
			_angle += SkyDragonRules.CIRCLE_SPEED / SkyDragonRules.CIRCLE_RADIUS * delta
			_fly_to(SkyDragonRules.circle_point(center, _angle, _floor + SkyDragonRules.FLY_HEIGHT),
				SkyDragonRules.CIRCLE_SPEED * 1.6, 4.0, delta)
		P.DIVE_WARN:
			_fly_to(Vector3(dive_from.x, _floor_along(0.0) + SkyDragonRules.FLY_HEIGHT + SkyDragonRules.WARN_RISE, dive_from.z),
				4.0, WARN_CLIMB, delta)
		P.DIVE:
			_dive_step(delta)
		P.GLIDE:
			var off := Vector3(global_position.x - center.x, 0.0, global_position.z - center.z)
			var goal := global_position
			if off.length() > SkyDragonRules.GLIDE_STOP:
				goal = center + off.normalized() * SkyDragonRules.GLIDE_STOP
			_fly_to(Vector3(goal.x, _floor + SkyDragonRules.GLIDE_HEIGHT, goal.z), SkyDragonRules.GLIDE_SPEED, 3.0, delta)
		P.CLIMB, P.TAKE_OFF:
			var goal := SkyDragonRules.circle_point(center, _angle, _floor + SkyDragonRules.FLY_HEIGHT)
			var left := maxf(SkyDragonRules.phase_time(phase, tired) - _phase_t, delta)
			_fly_to(goal, maxf(_flat(goal, global_position) / left, 2.0), maxf(absf(goal.y - global_position.y) / left, 2.0), delta)
		P.LAND:
			var left := maxf(SkyDragonRules.phase_time(P.LAND, tired) - _phase_t, delta)
			_fly_to(Vector3(global_position.x, _floor_here, global_position.z), 0.0,
				maxf(absf(global_position.y - _floor_here) / left, 1.5), delta, false)
	if phase == P.DIVE:
		_dive_hits(before, global_position)
	_vel = (global_position - before) / maxf(delta, 0.0001)
	_face(before, delta)
	if _phase_t >= SkyDragonRules.phase_time(phase, tired, _dive_len):
		_next_dragon()


## The end of a phase: the towers rise after it arrives, a dive is counted, and the schedule goes on. With nobody to
## dive at it keeps circling.
func _next_dragon() -> void:
	var old := phase
	if old == P.RISE:
		_raise_towers()
	elif old == P.DIVE:
		_dives += 1
	if old == P.CIRCLE and _target_node() == null:
		start_phase(P.CIRCLE)
		return
	start_phase(SkyDragonRules.next_phase(old, _dives))


## Ten times a second: the nearest child or bot friend in the arena, and the ground under it (and ahead of it, where
## it is going: it rises over cover before it gets there). High in the air it reads the ground under its feet only;
## low, under its whole body and as far round as it moves before it looks again.
func _decide_dragon() -> void:
	var best: Node3D = null
	var best_d := INF
	for n in _targets_now():
		if _flat(n.global_position, center) > BossRules.ARENA:
			continue
		var d := n.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = n
	_target = best
	var flat := Vector3(_vel.x, 0.0, _vel.z)
	var low := global_position.y - _floor_here < LOW_ABOVE or phase in [P.GLIDE, P.LAND, P.REST, P.DIVE]
	var reach := SkyDragonRules.FOOTPRINT + flat.length() * AI_INTERVAL if low else 0.0
	_floor_here = SkyDragonRules.floor_under_body(global_position.x, global_position.z, _floor_here, _read, reach)
	if phase == P.LAND or phase == P.REST:
		_floor = _floor_here
		return
	var way := flat.normalized() if flat.length() > 0.2 else facing()
	var ahead := global_position + way * maxf(flat.length() * 0.5, AHEAD)
	_floor = maxf(_floor_here, SkyDragonRules.floor_under_body(ahead.x, ahead.z, _floor_here, _read, reach))


## block_at through a short memory (READ_MEMORY seconds): circling, it flies over the same ground again and again.
## Reading a voxel costs 15-35 µs on the desktop (DEVELOPMENT.md §8); the arena never changes during a fight, and in
## Sandbox a new block is seen within the memory's time.
func _read(cell: Vector3i) -> int:
	if _memory_t >= READ_MEMORY:
		_memory.clear()
		_memory_t = 0.0
	var id: Variant = _memory.get(cell)
	if id == null:
		id = block_at.call(cell)
		_memory[cell] = id
		reads += 1
	return id


## Moves towards `goal` (flat at `hspeed`, up and down at `vspeed`), never out of the arena, never under the ground
## (`keep_up`: it climbs fast when the ground under it rises).
func _fly_to(goal: Vector3, hspeed: float, vspeed: float, delta: float, keep_up: bool = true) -> void:
	var p := global_position
	var flat := Vector2(goal.x - p.x, goal.z - p.z)
	var step := hspeed * delta
	if flat.length() > step:
		flat = flat.normalized() * step
	var y := move_toward(p.y, goal.y, vspeed * delta)
	if keep_up and y < _floor + SkyDragonRules.DIVE_LOW:
		y = minf(move_toward(p.y, _floor + SkyDragonRules.DIVE_LOW, CLIMB_SPEED * delta), maxf(goal.y, _floor + SkyDragonRules.DIVE_LOW))
		y = maxf(y, _floor)
	global_position = SkyDragonRules.keep_in(Vector3(p.x + flat.x, y, p.z + flat.y), center)


## Host, as the wind-up begins: the line through the nearest child. The ground along it is read while the line shows
## (a few samples a step: _read_line), so no single step reads it all.
func _plan_dive() -> void:
	var t := _target_node()
	var at := t.global_position if t else center
	var line := SkyDragonRules.dive_line(global_position, at, center)
	dive_from = line[0]
	dive_to = line[1]
	_dive_target_s = _flat(dive_from, at)
	_dive_len = _flat(dive_from, dive_to)
	_line_raw = PackedFloat32Array()
	_dive_floors = PackedFloat32Array()
	_read_line(1)


## Host: the next `samples` readings of the ground along the dive's line (every DIVE_SAMPLE metres, on it and
## DIVE_SIDE to each side); once all are in, the swoop's ground (smoothed).
func _read_line(samples: int) -> void:
	var count := ceili(_dive_len / SkyDragonRules.DIVE_SAMPLE) + 1
	if _line_raw.size() >= count:
		return
	var dir := (dive_to - dive_from).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x) * SkyDragonRules.DIVE_SIDE
	var guess := _line_raw[-1] if not _line_raw.is_empty() else _floor_here
	for k in samples:
		var i := _line_raw.size()
		if i >= count:
			break
		var q := dive_from + dir * minf(i * SkyDragonRules.DIVE_SAMPLE, _dive_len)
		var f := SkyDragonRules.column_floor(q.x, q.z, guess, _read)
		f = maxf(f, SkyDragonRules.column_floor(q.x + side.x, q.z + side.z, guess, _read))
		f = maxf(f, SkyDragonRules.column_floor(q.x - side.x, q.z - side.z, guess, _read))
		_line_raw.append(f)
		guess = f
	if _line_raw.size() >= count:
		_dive_floors = SkyDragonRules.smooth_floors(_line_raw, SkyDragonRules.DIVE_SAMPLE)


## The ground along the dive's line `s` metres from its start (between two samples, the higher one); before it is all
## read, what has been read so far.
func _floor_along(s: float) -> float:
	var f := _dive_floors if not _dive_floors.is_empty() else _line_raw
	if f.is_empty():
		return _floor
	var k := s / SkyDragonRules.DIVE_SAMPLE
	var i := clampi(floori(k), 0, f.size() - 1)
	var j := clampi(i + 1, 0, f.size() - 1)
	return maxf(f[i], f[j]) if k > float(i) + 0.001 else f[i]


func _dive_step(delta: float) -> void:
	_dive_s = minf(_dive_s + SkyDragonRules.dive_speed(tired) * delta, _dive_len)
	var dir := (dive_to - dive_from).normalized()
	var flat := dive_from + dir * _dive_s
	var y := _floor_along(_dive_s) + SkyDragonRules.dive_height(_dive_s, _dive_target_s, _dive_start_h)
	global_position = SkyDragonRules.keep_in(Vector3(flat.x, y, flat.z), center)


## This step of the swoop: whoever is on the line where it passed, low enough: a fair hit and a push off the line.
func _dive_hits(from: Vector3, to: Vector3) -> void:
	var nodes := _targets_now()
	var dir := dive_to - dive_from
	for i in SkyDragonRules.dive_hits(from, to, _info(nodes)):
		var id := nodes[i].get_instance_id()
		if _dove.has(id):
			continue
		_dove[id] = true
		_hurt(nodes[i], SkyDragonRules.DIVE_DAMAGE, SkyDragonRules.dive_push(dir, nodes[i].global_position, to, center))


## Faces along its dive while its line shows and while it swoops, its target while it rests, else the way it flies.
func _face(before: Vector3, delta: float) -> void:
	var look := Vector3.ZERO
	var turn := TURN
	match phase:
		P.DIVE_WARN, P.DIVE:
			look = dive_to - dive_from
			turn = TURN_FAST
		P.REST, P.LAND:
			var t := _target_node()
			look = t.global_position - global_position if t else Vector3.ZERO
			turn = TURN * 0.4
		_:
			look = global_position - before
	if Vector2(look.x, look.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), clampf(turn * delta, 0.0, 1.0))


## Every second: each standing tower heals it a little (the bar shows it: the health is synced).
func _heal(delta: float) -> void:
	if phase == P.RISE or hp <= 0:
		return
	_heal_t += delta
	while _heal_t >= SkyDragonRules.HEAL_EVERY:
		_heal_t -= SkyDragonRules.HEAL_EVERY
		var n := standing_towers()
		if n > 0:
			hp = SkyDragonRules.healed(hp, max_hp, n)


## Host: a new rise of crystal towers round the arena (on the ground there), and the line that says what to do.
func _raise_towers() -> void:
	_rises += 1
	var spots := SkyDragonRules.tower_spots(center, _rises - 1, SkyDragonRules.tower_count(tired))
	for i in spots.size():
		spots[i].y = BossRules.stand_y(spots[i].x, spots[i].z, center.y, block_at)
	tower_spots = PackedVector3Array(spots)
	var h := PackedByteArray()
	h.resize(spots.size())
	h.fill(0)
	tower_hits = h
	_sync_towers()
	_rpc_towers.rpc(_rises)


func _fly_away(delta: float) -> void:
	_sink_t += delta
	global_position.y += LEAVE_SPEED * delta
	if _sink_t >= LEAVE_TIME:
		queue_free()


# --- Everyone: effects, the towers, the line ---------------------------------------------------------------------

## Towers rose: every screen hears the crystals hum and reads what to do.
@rpc("authority", "call_local", "reliable")
func _rpc_towers(rise: int) -> void:
	Audio.play(&"sky_crystal_hum", center)
	Session.magic_feedback.emit(SkyDragonRules.TOWER_LINE if rise <= 1 else SkyDragonRules.TOWER_LINE_AGAIN)


## Every screen: the towers of the synced spots (a new rise replaces the last one's).
func _sync_towers() -> void:
	if tower_spots == _built_spots:
		return
	for t in _towers:
		if is_instance_valid(t):
			t.remove_from_group(&"monsters")
			t.queue_free()
	_towers.clear()
	for i in tower_spots.size():
		var t := SkyDragonTower.new()
		t.setup(i, self)
		add_child(t)
		t.global_position = tower_spots[i]
		_towers.append(t)
	_built_spots = tower_spots
	_update_tower_looks(true)


## Every screen: each tower shows the hits the host counted (a broken one shatters).
func _update_tower_looks(quiet: bool = false) -> void:
	for i in _towers.size():
		if is_instance_valid(_towers[i]):
			_towers[i].show_hits(int(tower_hits[i]) if i < tower_hits.size() else 0, quiet)


## Every screen: the dive line on the ground while its line shows and while it swoops (from the synced ends).
func _show_line() -> void:
	var on := (phase == P.DIVE_WARN or phase == P.DIVE) and dive_from.is_finite() and dive_to.is_finite() \
		and _flat(dive_from, dive_to) > 0.5
	if _line.visible != on:
		_line.visible = on
	if not on or not _line.is_inside_tree():
		return
	var d := Vector3(dive_to.x - dive_from.x, 0.0, dive_to.z - dive_from.z)
	var width := 2.0 * SkyDragonRules.LINE_HALF_WIDTH * (1.0 + LINE_PULSE * (0.5 + 0.5 * sin(_look_t * 10.0)))
	var mid := (dive_from + dive_to) * 0.5 + Vector3(0, LINE_LIFT, 0)
	_line.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP) * Basis.from_scale(Vector3(width, 1.0, d.length())), mid)
	_line_from = dive_from
	_line_to = dive_to


# --- Looks (every screen) ----------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if phase != _look_phase:
		_enter_dragon_look()
	_look_t += delta
	_sync_towers()
	_update_tower_looks()
	_show_line()
	var beams := phase != P.DOWN
	var at := hit_center()
	for t in _towers:
		if is_instance_valid(t):
			t.set_beam(beams)
			t.aim_beam(at)
	if hp < _shown_hp:
		_took_hit_look()   # M5 Task 2: a squash and a lean back
	_shown_hp = hp
	_pose_dragon(delta)


## A new phase on this screen: its sound, its glow (eyes and belly while its line shows), the stars while it rests.
func _enter_dragon_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	var warn := phase == P.DIVE_WARN
	_eyes.mesh = SkyDragonModels.eyes_mesh(warn)
	_aura.visible = warn
	_stars.visible = phase == P.REST
	match phase:
		P.DIVE_WARN:
			Audio.play(&"sky_dragon_roar", global_position, -3.0)
		P.DIVE:
			Audio.play(&"sky_dragon_dive", global_position)
		P.DOWN:
			_win_roar()   # M5 Task 2: it won: a roar as it flies off, its head held high


## Wings beat (fast while it climbs, folded back in a dive, spread while it glides, folded down while it rests), the
## tail sways, the head lifts while it winds up and droops while it rests, the body pitches with its climb or dive
## and banks into turns.
func _pose_dragon(delta: float) -> void:
	var moved := global_position - _last_pos
	_last_pos = global_position
	var k := _look_t
	var period := 0.9
	var amp := 0.6
	var fixed := NAN                  # a held wing angle instead of beating
	var sweep := 0.0
	var neck := 0.0
	var bob := 0.0
	match phase:
		P.RISE, P.CLIMB, P.TAKE_OFF, P.DOWN:
			period = 0.5
			amp = 0.9
			if phase == P.DOWN and CreatureMoves.cheering(k):
				neck = 0.35               # M5 Task 2: head up, roaring
		P.DIVE_WARN:
			period = 0.35
			amp = 1.0
			neck = 0.3
		P.DIVE:
			fixed = -0.3
			sweep = -0.7
			neck = -0.15
		P.GLIDE:
			fixed = 0.12 + sin(k * 3.0) * 0.05
			bob = sin(k * 3.0) * 0.08
		P.LAND:
			period = 0.6
			amp = 0.7
		P.REST:
			fixed = -0.55
			sweep = -0.9
			neck = -0.35
			bob = sin(k * 2.0) * 0.04
			_stars.rotation.y = k * 4.0
	var wing := fixed
	if is_nan(fixed):
		var before := _flap
		_flap = fmod(_flap + delta / period, 1.0)
		wing = sin(_flap * TAU) * amp + 0.15
		if _flap < before and is_inside_tree():   # a downstroke: the wings' whoosh
			Audio.play(&"sky_dragon_wings", global_position, -8.0)
	for i in _wings.size():
		var side := 1.0 if i == 0 else -1.0
		var r := Vector3(0.0, sweep * side, wing * side)
		if _wings[i].rotation != r:
			_wings[i].rotation = r
	var tail := Vector3(0.12 if phase == P.DIVE else 0.0, sin(k * 2.0) * 0.25, 0.0)
	if _tail.rotation != tail:
		_tail.rotation = tail
	if _neck.rotation.x != neck:
		_neck.rotation.x = lerpf(_neck.rotation.x, neck, clampf(delta * 6.0, 0.0, 1.0))
	var flat := Vector2(moved.x, moved.z).length()
	var pitch := clampf(atan2(moved.y, flat), -0.7, 0.5) if delta > 0.0 and (flat + absf(moved.y)) / delta > 0.5 else 0.0
	if phase == P.REST or phase == P.LAND:
		pitch = 0.0
	_pitch = lerpf(_pitch, pitch, clampf(delta * 6.0, 0.0, 1.0))
	var yaw_rate := angle_difference(_last_yaw, rotation.y) / maxf(delta, 0.0001)
	_last_yaw = rotation.y
	_bank = lerpf(_bank, clampf(yaw_rate * 0.3, -0.4, 0.4), clampf(delta * 4.0, 0.0, 1.0))
	var s := Vector3.ONE
	if _squash > 0.0:
		_squash -= delta
		var q := clampf(_squash / 0.15, 0.0, 1.0)
		s = Vector3(1.0 + 0.06 * q, 1.0 - 0.08 * q, 1.0 + 0.06 * q)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	var p := Vector3(0.0, bob, 0.0)
	if not _body.position.is_equal_approx(p):
		_body.position = p
	var rot := Vector3(_pitch + _recoil_lean(delta), 0.0, _bank)
	if not _body.rotation.is_equal_approx(rot):
		_body.rotation = rot


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
