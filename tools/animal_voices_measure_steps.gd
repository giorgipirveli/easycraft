extends Node
## The steps of tools/animal_voices_measure.gd (owner feedback #50): a new Sandbox world by day; after
## WARMUP seconds (the animals come a few a second where the ground is ready) every Audio play is counted
## by name for --seconds, with its distance from the listener (the camera) and its level there (the
## player's volume plus the inverse-distance fall-off of Audio's 3D players). Once a second it also
## counts the animals within 20 and 40 blocks by kind.
## Where the player is:
##   (default)        standing at the world spawn
##   --walk           walking along +x at WALK_SPEED from the spawn
##   --busiest        standing where the most animals live within 20 blocks (AnimalRules' own spawns in the
##                    cells around the spawn): the loudest place of this world
##   --busiest=chicken  the same, counting only that kind (a chicken flock)
##   --summon=chicken:10  at the spawn, having /summoned 10 chickens (what a child does)

const WARMUP := 30.0
const WALK_SPEED := 2.5           # m/s: a child strolling about
const TIMEOUT_EXTRA := 60.0
const SEARCH_CELLS := 6           # --busiest looks this many 32-block cells around the spawn

var _seconds := 150.0
var _seed := 7
var _walk := false
var _busiest := false
var _busiest_kind: StringName = &""
var _summon_kind: StringName = &""
var _summon_count := 0
var _t := 0.0
var _measuring := false
var _m_t := 0.0                   # seconds measured
var _sample_t := 0.0
var _samples := 0
var _near20 := {}                 # species -> animal-seconds within 20 blocks
var _near40 := {}
var _all := {}                    # sound -> plays
var _calls: Array[Dictionary] = []   # animal idle calls: {t, sound, d, db}
var _call_sounds := {}            # the animals' call sounds -> species
var _cam: Camera3D
var _walk_x := NAN
var _stand := Vector3.INF         # pinned here (busiest/summon/spawn); INF until chosen
var _summoned := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			_seed = int(arg.get_slice("=", 1))
		elif arg == "--walk":
			_walk = true
		elif arg.begins_with("--busiest"):
			_busiest = true
			if arg.contains("="):
				_busiest_kind = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--summon="):
			var what := arg.get_slice("=", 1)
			_summon_kind = StringName(what.get_slice(":", 0))
			_summon_count = int(what.get_slice(":", 1))
	for sp: StringName in AnimalRules.SPECIES:
		_call_sounds[VoiceRules.animal_call(sp)] = sp
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Game.new_world_seed = _seed
	Audio.sound_played.connect(_on_sound)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("VOICES begin seed=%d seconds=%.0f walk=%s busiest=%s%s summon=%s:%d" % [_seed, _seconds, _walk, _busiest,
		":" + _busiest_kind if _busiest_kind != &"" else "", _summon_kind, _summon_count])


func _process(delta: float) -> void:
	_t += delta
	if _t > WARMUP + _seconds + TIMEOUT_EXTRA:
		print("VOICES FAIL timeout (the world never started?)")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	_cam = p.camera()
	if not _stand.is_finite() and is_nan(_walk_x):
		sandbox.call("set_time_of_day", DayCycle.NOON)
		_walk_x = p.global_position.x
		_stand = _busiest_spot(p.world) if _busiest else p.global_position
		print("VOICES standing at %s" % _stand)
	if _walk and _measuring:
		_walk_x += WALK_SPEED * delta
		var y := p.world.find_standing_y(int(floor(_walk_x)), int(floor(_stand.z)))
		if y > -1000:
			_stand = Vector3(_walk_x, y + 0.05, _stand.z)
	p.global_position = _stand   # pinned: standing still (or walking step by step)
	p.velocity = Vector3.ZERO
	if _summoned < _summon_count and _t > 8.0:
		var why: String = sandbox.call("summon_animal", _summon_kind, p.global_position)
		_summoned += 1
		if why != "":
			print("VOICES summon refused: %s" % why)
	if not _measuring:
		if _t >= WARMUP:
			_measuring = true
			print("VOICES measuring from t=%.1f at %s" % [_t, p.global_position])
		return
	_m_t += delta
	_sample_t -= delta
	if _sample_t <= 0.0:
		_sample_t = 1.0
		_sample(sandbox)
	if _m_t >= _seconds:
		_report()
		get_tree().quit(0)


## Where the most animals of AnimalRules' spawns live within 20 blocks (of `_busiest_kind`, or any), in the
## cells around the world spawn; the player stands 2 blocks beside that animal, on the generated ground.
func _busiest_spot(world: WorldService) -> Vector3:
	var shape := world.generator_shape()
	var home := world.spawn_column()
	var c0 := Vector2i(floori(float(home.x) / AnimalRules.CELL), floori(float(home.y) / AnimalRules.CELL))
	var land: Array[Dictionary] = []
	for cz in range(c0.y - SEARCH_CELLS, c0.y + SEARCH_CELLS + 1):
		for cx in range(c0.x - SEARCH_CELLS, c0.x + SEARCH_CELLS + 1):
			for s in AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz)):
				if AnimalRules.SPECIES[s.species].habitat == &"land":
					land.append(s)
	var best := Vector3.INF
	var most := -1
	var mix := {}
	for s in land:
		var n := 0
		var kinds := {}
		for o in land:
			if (o.pos as Vector3).distance_to(s.pos) <= 20.0:
				kinds[o.species] = int(kinds.get(o.species, 0)) + 1
				if _busiest_kind == &"" or o.species == _busiest_kind:
					n += 1
		if n > most:
			most = n
			best = s.pos
			mix = kinds
	print("VOICES busiest spot %s: %d animals%s within 20 blocks there %s" % [best, most,
		" (%s)" % _busiest_kind if _busiest_kind != &"" else "", mix])
	var x := int(best.x) + 2
	var z := int(best.z) + 2
	return Vector3(x + 0.5, shape.height_at(x, z) + 1.05, z + 0.5)


func _sample(sandbox: Node) -> void:
	_samples += 1
	var at := _cam.global_position
	for n in sandbox.get_node("Animals").get_children():
		var a := n as Animal
		if a == null:
			continue
		var d := a.global_position.distance_to(at)
		if d <= 20.0:
			_near20[a.species] = int(_near20.get(a.species, 0)) + 1
		if d <= 40.0:
			_near40[a.species] = int(_near40.get(a.species, 0)) + 1


func _on_sound(sound: StringName, at: Vector3, volume_db: float) -> void:
	if not _measuring or _cam == null:
		return
	_all[sound] = int(_all.get(sound, 0)) + 1
	if not _call_sounds.has(sound) or not at.is_finite():
		return
	var d := at.distance_to(_cam.global_position)
	var db := minf(volume_db + linear_to_db(1.0 / (d / 6.0 + 0.0001)), 3.0)   # Audio's unit_size 6, max_db 3
	_calls.append({"t": _m_t, "sound": sound, "d": d, "db": db})


func _report() -> void:
	var n := _calls.size()
	var minutes := _m_t / 60.0
	var most10 := 0
	var min_gap := INF
	var same_kind := 0
	for i in n:
		var c: Dictionary = _calls[i]
		var k := 0
		for j in range(i, n):
			if float(_calls[j].t) - float(c.t) < 10.0:
				k += 1
		most10 = maxi(most10, k)
		if i > 0:
			min_gap = minf(min_gap, float(c.t) - float(_calls[i - 1].t))
			if _calls[i - 1].sound == c.sound:
				same_kind += 1
	print("VOICES calls=%d per_min=%.1f most_in_10s=%d min_gap=%.2fs back_to_back_same_kind=%d/%d (%.0f%%) seconds=%.0f" % [
		n, n / maxf(minutes, 0.001), most10, min_gap if n > 1 else -1.0, same_kind, maxi(n - 1, 0),
		100.0 * same_kind / maxf(n - 1, 1), _m_t])
	for sound: StringName in _call_sounds:
		var k := 0
		var dsum := 0.0
		var dbsum := 0.0
		var near := 0
		for c in _calls:
			if c.sound == sound:
				k += 1
				dsum += float(c.d)
				dbsum += float(c.db)
				near += int(float(c.d) <= 10.0)
		var sp: StringName = _call_sounds[sound]
		if k == 0 and not _near40.has(sp):
			continue
		print("VOICES kind %-8s calls=%3d share=%5.1f%% per_min=%4.1f mean_dist=%5.1f within10=%3d mean_level=%6.1f dB  animals_within20=%.1f within40=%.1f" % [
			sp, k, 100.0 * k / maxf(n, 1), k / maxf(minutes, 0.001), dsum / maxf(k, 1), near, dbsum / maxf(k, 1),
			float(_near20.get(sp, 0)) / maxf(_samples, 1), float(_near40.get(sp, 0)) / maxf(_samples, 1)])
	var others: Array[String] = []
	for sound: StringName in _all:
		if not _call_sounds.has(sound):
			others.append("%s=%d" % [sound, _all[sound]])
	print("VOICES other sounds: %s" % ", ".join(others))
	var timeline: Array[String] = []
	for c in _calls:
		timeline.append("%.1f:%s@%.0f" % [c.t, c.sound, c.d])
	print("VOICES timeline %s" % " ".join(timeline))
