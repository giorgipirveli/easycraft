extends Node
## The steps of tools/host_bench.gd (M5 Task 3): a new Survivor world of one universe; in the wild meadows the player
## goes to the nearest village first (its villagers). A quiet window, then everything at once: 20 of the universe's
## monsters on a ring 9-15 blocks out (level 1-5, not wild: the sun leaves them), a dog and a cat tamed as pets, a
## horse (a camel in the desert) tamed, saddled and ridden in a slow circle, the Gold Farm on flat ground, a race
## running (START touched and left), the universe's wild animals as they come: a busy window.
## Printed per window: the main thread's own CPU time per frame (Linux /proc: what the frame costs, whatever else
## the PC runs: the number to compare), the physics step and the process time per frame (Performance monitors: wall
## time, inflated on a busy PC while the main thread waits for Jolt's and the voxel threads), second by second for the
## busy window, and the hand-stepped monsters' and animals' own share. Desktop numbers: phones are 3-5 times slower.

const TIMEOUT := 300.0
const SETTLE := 6.0               # seconds for the ground around to stream in
const WINDOW := 20.0              # seconds of each window
const BUSY_SETTLE := 5.0          # seconds after the setup before the busy window (spawns, the farm's building, meshing)
const MONSTERS := 20
const RIDE_TURN := 0.35           # radians a second the rider's wish turns: a circle of a few dozen blocks

var _u := 1
var _t := 0.0
var _step := 0
var _step_t := 0.0
var _quiet_phys: Array[float] = []
var _quiet_proc: Array[float] = []
var _busy_phys: Array[float] = []
var _busy_proc: Array[float] = []
var _settle_phys: Array[float] = []
var _settle_proc: Array[float] = []
## The busy window second by second: [physics ms sum, ticks, process ms sum, frames] per second.
var _series: Array = []
## The main thread's own CPU time (Linux /proc: robust to other programs on a busy PC, unlike the frame times) at the
## start of the window and the frames since: [cpu ms, frames].
var _cpu_at := [0.0, 0]
var _frames := 0
var _parts := {}
var _mount: Animal
var _fails: Array[String] = []
var _village := ""
## --without=ride,monsters,farm,pets,race leaves those parts out (to see what one part costs).
var _without: Array[String] = []
## Busy window: the monsters and the animals are stepped by hand here (their own engine steps off), so their
## scripts' and move_and_slide's time is measured: group -> [physics us total, process us total].
var _cost := {"monsters": [0.0, 0.0], "animals": [0.0, 0.0]}
var _stepped: Array[Node] = []
## --off=A,B,...: the scene's nodes with these names (or "first-last" ranges of its children by index) are switched
## off for the busy window (to find what costs).
var _off: Array[String] = []
## The monsters' world reads (block_at) in the busy window: [calls, us inside, worst us].
var _reads := [0, 0, 0]
## --preset=low|medium|high: this phone's graphics preset for the run (LOW: its caps; the ring then has as many
## monsters as LOW lets come near a child).
var _preset := ""
var _monsters := MONSTERS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--universe="):
			_u = UniverseRules.valid(int(a.trim_prefix("--universe=")))
		elif a.begins_with("--preset="):
			_preset = a.trim_prefix("--preset=")
		elif a.begins_with("--off="):
			_off.assign(a.trim_prefix("--off=").split(","))
		elif a.begins_with("--without="):
			_without.assign(a.trim_prefix("--without=").split(","))
		elif a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	if Game.new_world_seed == 0:
		Game.new_world_seed = 12345
	if _preset != "":
		Profile.data.settings.graphics = _preset   # this run only (the private profile copy)
		var cap := int(GraphicsPreset.params(_preset).monsters_near)
		_monsters = cap if cap > 0 else MONSTERS
		Game.apply_settings()
	Game.mode = ModeRules.SURVIVOR
	Game.universe = _u
	Game.new_world_difficulty = DifficultyRules.COZY
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("HOST_BENCH begin universe=%d seed=%d preset=%s load=%s" % [_u, Game.new_world_seed,
		Profile.data.settings.graphics, _load()])


func _sandbox() -> Node:
	var s := get_tree().current_scene
	if s == null or s.get("player") == null or not (s.player as Player).is_spawned():
		return null
	return s


func _physics_process(_delta: float) -> void:
	var s := _sandbox()
	if s == null:
		return
	if _step == 1:
		_quiet_phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	elif _step == 3:
		_settle_phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_ride(s)
	elif _step == 4:
		_busy_phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_second()[0] += _busy_phys.back()
		_second()[1] += 1
		_ride(s)
		_hand_step(s, true, get_physics_process_delta_time())


func _process(delta: float) -> void:
	_t += delta
	_frames += 1
	if _t > TIMEOUT:
		_fail("timeout at step %d" % _step)
		_finish()
		return
	var s := _sandbox()
	if s == null:
		return
	_step_t += delta
	var p: Player = s.player
	match _step:
		0:   # the wild meadows: to the nearest village first; then let the ground stream in
			if _step_t < 1.0:
				return
			if _u == 1 and _village == "" and s.get("places_director") != null:
				var places: MeadowsPlaces = (s.places_director as PlacesDirector).places
				var v: Dictionary = places.nearest(p.global_position, &"village", 8) if places else {}
				_village = "none"
				if not v.is_empty():
					var at: Vector3i = v.anchor
					_village = "%s at %s" % [v.get("name", "a village"), at]
					p.spawn_on_surface(at.x + 3, at.z + 3)
					_step_t = 0.0
					return
			if _step_t < SETTLE:
				return
			_next()
		1:   # the quiet window: the world, the player, what the universe brings by itself
			_quiet_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			if _step_t >= WINDOW:
				print("HOST_BENCH u=%d quiet %s village=%s" % [_u, _summary(_quiet_phys, _quiet_proc), _village])
				_cpu_line("quiet")
				_next()
		2:   # everything at once
			_setup(s, p)
			_next()
		3:   # the things spawned settle (their first seconds cost more: see the per-second line)
			_settle_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			if _step_t >= BUSY_SETTLE:
				print("HOST_BENCH u=%d settling process_avg_ms=%.2f process_worst_ms=%.2f physics_avg_ms=%.2f physics_worst_ms=%.2f" % [
					_u, _avg(_settle_proc), _max(_settle_proc), _avg(_settle_phys), _max(_settle_phys)])
				_next()
		4:   # the busy window
			_busy_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			_second()[2] += _busy_proc.back()
			_second()[3] += 1
			_hand_step(s, false, delta)
			if _step_t >= WINDOW:
				_report(s, p)
				_finish()


func _setup(s: Node, p: Player) -> void:
	var w: WorldService = s.world
	p.health.protect(600.0)   # like every smoke run's cost window: the monsters swing, nothing hurts (no knock-out)
	# the Gold Farm on flat ground near the player (the farm smoke's search), the player at its door
	var farm: FarmDirector = s.get("_farm")
	var anchor := _flat_spot(w, Vector3i(p.global_position.floor())) if not _without.has("farm") else Vector3i(-99999, 0, 0)
	if anchor.x != -99999:
		p.global_position = Vector3(anchor) + Vector3(0.5, 0.0, 3.5)
		Session.inventory_of(p.peer_id).add(ItemIds.FARM, 1)
		var said := farm.host_place(p.peer_id, anchor, 0)
		_parts.farm = "yes" if said == "" else said
	else:
		_parts.farm = "no flat spot"
	# pets: a dog and a cat, and a horse (a camel in the desert) saddled and ridden
	var pets := 0
	for species: StringName in ([] if _without.has("pets") else [&"dog", &"cat"]):
		var a := _summon(s, species, p)
		if a and _tame(a, p):
			pets += 1
	_parts.pets = pets
	for species: StringName in ([] if _without.has("ride") else [&"horse", &"camel"]):
		_mount = _summon(s, species, p)
		if _mount and _tame(_mount, p):
			break
		_mount = null
	var rides: RideDirector = s.get("_rides")
	if _mount:
		_mount.saddled = true
		p.global_position = _mount.global_position + Vector3(1.2, 0.0, 0.0)
		var why := rides.host_ride(p.peer_id, _mount.name)
		_parts.ride = "%s %s" % [_mount.species, "ridden" if why == "" else why]
	else:
		_parts.ride = "no mount"
	# 20 of the universe's monsters on a ring round the player (the desert smoke's cost window)
	var monsters: MonsterDirector = s.get("_monsters")
	var shape := w.generator_shape()
	var n := 0
	for i in (0 if _without.has("monsters") else 40):
		if n >= _monsters:
			break
		var ang := TAU * i / 24.0 + (0.13 if i >= 24 else 0.0)
		var d := 9.0 + (i % 4) * 2.0
		var x := floori(p.global_position.x + cos(ang) * d)
		var z := floori(p.global_position.z + sin(ang) * d)
		var y := w.find_standing_y(x, z)
		if y >= shape.height_at(x, z) + 6:
			continue
		var kinds := monsters.kinds
		monsters.spawn_monster({"kind": kinds[i % kinds.size()], "level": 1 + i % 5, "id": "bench%d" % i,
			"pos": Vector3(x + 0.5, y, z + 0.5), "yaw": 0.0, "wild": false, "universe": _u})
		n += 1
	_parts.monsters = n
	# a race: the player's feet on START, then off it (the host's clock runs, sampled 10 times a second)
	var courses: CourseDirector = s.get("_courses")
	var cell := Vector3i(p.global_position.floor()) + Vector3i.DOWN
	if not _without.has("race"):
		courses.touch(p.peer_id, BlockIds.START, cell, false)
		courses.touch(p.peer_id, BlockIds.START, cell, true)
	_parts.race = "running" if courses.is_running(p.peer_id) else "not running"
	print("HOST_BENCH u=%d setup %s without=%s" % [_u, _parts, _without])
	var names: Array[String] = []
	var kids := s.get_children()
	for i in kids.size():
		names.append("%d:%s" % [i, kids[i].name])
	print("HOST_BENCH u=%d children %s" % [_u, " ".join(names)])
	for o: String in _off:
		var range_ := o.split("-")
		var lo := int(range_[0]) if range_[0].is_valid_int() else -1
		var hi := int(range_[1]) if range_.size() > 1 and range_[1].is_valid_int() else lo
		for i in kids.size():
			if kids[i].name == o or (lo >= 0 and i >= lo and i <= hi):
				kids[i].process_mode = Node.PROCESS_MODE_DISABLED
				print("HOST_BENCH u=%d off %s" % [_u, kids[i].name])
	for k: String in ["farm", "ride", "race"]:
		if not _without.is_empty():
			break
		if not (str(_parts[k]) == "yes" or str(_parts[k]).ends_with("ridden") or _parts[k] == "running"):
			_fail("%s: %s" % [k, _parts[k]])
	if _without.is_empty() and (int(_parts.pets) < 2 or int(_parts.monsters) < _monsters):
		_fail("pets %d, monsters %d" % [_parts.pets, _parts.monsters])


## The rider's stick: a slow turn, so the horse gallops round a wide circle among the monsters.
func _ride(s: Node) -> void:
	var p: Player = s.player
	if not p.health.is_knocked_out() and p.health.hp < Health.MAX_HP:
		p.health.heal(Health.MAX_HP)   # the child stays on its feet among 20 monsters (a knock-out ends the race)
	if _mount == null or not is_instance_valid(_mount):
		return
	var a := _step_t * RIDE_TURN
	(s.get("_rides") as RideDirector).host_ride_input((s.player as Player).peer_id, _mount.name, Vector3(cos(a), 0.0, sin(a)))


## The monsters' and the animals' steps, by hand and timed (their engine steps are turned off the first time).
func _hand_step(s: Node, physics: bool, dt: float) -> void:
	var groups := {"monsters": (s.get("_monsters") as MonsterDirector).monsters(), "animals": s.call(&"_animal_nodes")}
	for g: String in groups:
		var t0 := Time.get_ticks_usec()
		for n: Node in groups[g]:
			if not is_instance_valid(n) or n.is_queued_for_deletion():
				continue
			if not _stepped.has(n):
				_stepped.append(n)
				n.set_physics_process(false)
				n.set_process(false)
				if n is Monster:
					var inner: Callable = (n as Monster).block_at
					var reads := _reads
					(n as Monster).block_at = func(pos: Vector3i) -> int:
						var r0 := Time.get_ticks_usec()
						var id: int = inner.call(pos)
						var us := Time.get_ticks_usec() - r0
						reads[0] += 1
						reads[1] += us
						reads[2] = maxi(reads[2], us)
						return id
			if physics:
				n._physics_process(dt)
			else:
				n._process(dt)
		(_cost[g] as Array)[0 if physics else 1] += Time.get_ticks_usec() - t0


## This second's slot of the busy window's series.
func _second() -> Array:
	var i := int(_step_t)
	while _series.size() <= i:
		_series.append([0.0, 0, 0.0, 0, _cpu_ms(), _queue_ms()])
	return _series[i]


func _report(s: Node, p: Player) -> void:
	var line := ""
	_cpu_line("busy")
	for k in _series.size():
		var sec: Array = _series[k]
		var cpu_next: float = _series[k + 1][4] if k + 1 < _series.size() else _cpu_ms()
		var queue_next: float = _series[k + 1][5] if k + 1 < _series.size() else _queue_ms()
		line += " %.1f/%.1f/%.0f%%/%.0f" % [float(sec[0]) / maxf(int(sec[1]), 1), float(sec[2]) / maxf(int(sec[3]), 1),
			(cpu_next - float(sec[4])) / 10.0, queue_next - float(sec[5])]
	print("HOST_BENCH u=%d busy per second (physics ms/process ms/main thread busy/ms waiting for a CPU):%s" % [_u, line])
	var monsters: MonsterDirector = s.get("_monsters")
	var active := 0
	for m in monsters.monsters():
		if m.global_position.distance_to(p.global_position) <= MonsterRules.ACTIVE_DISTANCE:
			active += 1
	var animals: Array = s.call(&"_animal_nodes")
	var villagers := get_tree().get_nodes_in_group(&"villagers").size()
	var riding := _mount != null and is_instance_valid(_mount) and _mount.rider_peer == p.peer_id
	print("HOST_BENCH u=%d busy %s monsters=%d active=%d animals=%d villagers=%d riding=%s race=%s nodes=%d" % [_u,
		_summary(_busy_phys, _busy_proc), monsters.monsters().size(), active, animals.size(), villagers, riding,
		(s.get("_courses") as CourseDirector).is_running(p.peer_id), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	print("HOST_BENCH u=%d busy monster world reads=%d per_second=%.0f total_ms=%.1f avg_us=%.1f worst_us=%d" % [_u,
		_reads[0], _reads[0] / WINDOW, _reads[1] / 1000.0, float(_reads[1]) / maxf(_reads[0], 1.0), _reads[2]])
	for g: String in _cost:
		print("HOST_BENCH u=%d busy %s physics_ms_per_tick=%.2f process_ms_per_frame=%.2f" % [_u, g,
			(_cost[g] as Array)[0] / 1000.0 / maxf(_busy_phys.size(), 1.0), (_cost[g] as Array)[1] / 1000.0 / maxf(_busy_proc.size(), 1.0)])


func _summon(s: Node, species: StringName, p: Player) -> Animal:
	var before := {}
	for a: Animal in s.call(&"_animal_nodes"):
		before[a] = true
	s.call(&"summon_animal", species, p.global_position)
	for a: Animal in s.call(&"_animal_nodes"):
		if not before.has(a) and a.species == species:
			return a
	return null


func _tame(a: Animal, p: Player) -> bool:
	for i in 3:
		Session.request_pet(a.name)
	if a.owner_peer == 0:
		a.owner_peer = p.peer_id   # a horse or a camel wants treats: the bench hands it over
	return a.owner_peer == p.peer_id


## A flat, open spot near `feet` whose farm (door facing +Z) FarmSite accepts (tools/farm_smoke_steps.gd's search).
func _flat_spot(world: WorldService, feet: Vector3i) -> Vector3i:
	for r in range(4, 40, 2):
		for i in 24:
			var a := TAU * i / 24.0
			var x := feet.x + roundi(cos(a) * r)
			var z := feet.z + roundi(sin(a) * r)
			var anchor := Vector3i(x, world.find_standing_y(x, z), z)
			var center := FarmSite.center_for(anchor, 0)
			if not world.is_area_ready(Vector3(center)):
				continue
			var box: Array = FarmSite.box(center)
			if FarmSite.refusal(center, 0, world.box_reader(box[0], box[1])) == "":
				return anchor
	return Vector3i(-99999, 0, 0)


func _summary(phys: Array[float], proc: Array[float]) -> String:
	return "physics_ticks=%d physics_avg_ms=%.2f physics_p95_ms=%.2f physics_worst_ms=%.2f frames=%d process_avg_ms=%.2f process_p95_ms=%.2f process_worst_ms=%.2f load=%s" % [
		phys.size(), _avg(phys), _p95(phys), _max(phys), proc.size(), _avg(proc), _p95(proc), _max(proc), _load()]


func _avg(a: Array[float]) -> float:
	var t := 0.0
	for v in a:
		t += v
	return t / maxf(a.size(), 1.0)


func _p95(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	var s: Array[float] = a.duplicate()
	s.sort()
	return s[mini(int(s.size() * 0.95), s.size() - 1)]


func _max(a: Array[float]) -> float:
	var m := 0.0
	for v in a:
		m = maxf(m, v)
	return m


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next() -> void:
	_step += 1
	_step_t = 0.0
	if _step == 1 or _step == 4:
		_cpu_at = [_cpu_ms(), _frames]


## The main thread's user + system CPU time so far, in ms (0 where /proc is missing).
func _cpu_ms() -> float:
	var f := FileAccess.open("/proc/thread-self/stat", FileAccess.READ)
	if f == null:
		return 0.0
	var fields := f.get_line().get_slice(")", 1).split(" ", false)   # /proc files have no length: read a line
	return (int(fields[11]) + int(fields[12])) * 10.0   # utime, stime (fields 14, 15) in 100 Hz ticks


## How long the main thread has waited for a CPU while it could run (Linux schedstat, ms): the PC's other programs.
func _queue_ms() -> float:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return 0.0
	var fields := f.get_line().split(" ", false)
	return int(fields[1]) / 1e6 if fields.size() > 1 else 0.0


## The window's main-thread CPU per frame and how busy it was (run with --max-fps 60: a phone's frame rate).
func _cpu_line(window: String) -> void:
	var cpu := _cpu_ms() - float(_cpu_at[0])
	var frames := _frames - int(_cpu_at[1])
	print("HOST_BENCH u=%d %s main_thread_cpu_ms_per_frame=%.2f frames=%d cpu_s=%.2f" % [_u, window,
		cpu / maxf(frames, 1.0), frames, cpu / 1000.0])


func _fail(what: String) -> void:
	print("HOST_BENCH FAIL %s" % what)
	_fails.append(what)


func _finish() -> void:
	print("HOST_BENCH u=%d done fails=%d" % [_u, _fails.size()])
	set_process(false)
	set_physics_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
