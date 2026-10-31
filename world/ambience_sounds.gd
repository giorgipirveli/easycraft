class_name AmbienceSounds
extends Node
## The world's ambience loops (the audio pass, owner feedback #27; spec §15.2): birds by day, crickets at
## night, drips in caves, waves by the sea, wind on the peaks, a universe's own (AmbienceSoundRules). Two
## players on the Effects bus cross-fade in FADE seconds; a silent one is stopped, so a phone decodes one
## loop (two while fading). A child of the world's Ambience, which knows the caves, the water and the
## sandstorm; it looks around for the sea once a SCAN_INTERVAL. Caves also set Music's cave mood.

const PLAYERS := 2
const FADE := 3.0
const SCAN_INTERVAL := 1.0
const SEA_RADIUS := 14            # blocks: the ring of ground looked at for open sea
const SEA_SAMPLES := 8
const SEA_DEPTH := 4              # the sea floor is at least this far under the sea level (not a river)
const CAVE_ON := 0.6              # Music's cave mood starts at this much underground ...
const CAVE_OFF := 0.3             # ... and ends below this (no flicker at a cave mouth)

## The loop wanted now (&"" = quiet).
var chosen: StringName = &""

var _players: Array[AudioStreamPlayer] = []
var _ids: Array[StringName] = []
var _gains: Array[float] = []
var _cave := false
var _scan_t := 0.0
var _sea := 0.0


func _ready() -> void:
	for i in PLAYERS:
		var p := AudioStreamPlayer.new()
		p.name = "Ambience_%d" % i
		p.bus = Audio.BUS
		p.volume_db = MusicMix.SILENT_DB
		add_child(p)
		_players.append(p)
		_ids.append(&"")
		_gains.append(0.0)


func player(i: int) -> AudioStreamPlayer:
	return _players[i]


func loop_on(i: int) -> StringName:
	return _ids[i]


func index_of(id: StringName) -> int:
	return _ids.find(id) if id != &"" else -1


func in_cave() -> bool:
	return _cave


func _process(delta: float) -> void:
	var amb := get_parent() as Ambience
	if amb == null or not is_instance_valid(amb.player) or not amb.player.is_spawned():
		return
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = SCAN_INTERVAL
		_sea = _measure_sea(amb.world, amb.player.global_position)
	tick(delta, {
		"time": _time_of_day(amb), "underground": amb.underground, "underwater": amb.underwater,
		"storm": amb.storm, "height": amb.player.eye_position().y - MeadowsShape.SEA_LEVEL, "sea": _sea,
		"own": UniverseRegistry.ambience(amb.world.universe) if amb.world else {},
	})


## `delta` seconds in these surroundings (AmbienceSoundRules.choose's keys).
func tick(delta: float, ctx: Dictionary) -> void:
	_set_cave(float(ctx.get("underground", 0.0)))
	chosen = AmbienceSoundRules.choose(ctx)
	if chosen != &"" and index_of(chosen) < 0:
		_start(_free_or_quietest(), chosen)
	var step := delta / FADE if is_finite(delta) and delta > 0.0 else 0.0
	for i in PLAYERS:
		var target := 1.0 if _ids[i] == chosen and chosen != &"" else 0.0
		_gains[i] = move_toward(_gains[i], target, step)
		var p := _players[i]
		if _gains[i] <= 0.0 and target == 0.0:
			if p.playing:
				p.stop()
			_ids[i] = &""
			continue
		var db := AmbienceSoundRules.volume_db(_ids[i]) + maxf(linear_to_db(sin(_gains[i] * PI * 0.5)), -80.0)
		if not is_equal_approx(p.volume_db, db):
			p.volume_db = db


func _free_or_quietest() -> int:
	for i in PLAYERS:
		if _ids[i] == &"":
			return i
	return 0 if _gains[0] <= _gains[1] else 1


func _start(i: int, id: StringName) -> void:
	var stream := load(AmbienceSoundRules.path(id)) as AudioStream
	_ids[i] = id
	_gains[i] = 0.0
	var p := _players[i]
	p.stream = stream
	p.volume_db = MusicMix.SILENT_DB
	if stream:
		p.play(randf() * maxf(stream.get_length() - 1.0, 0.0))   # not always the same bird first


func _set_cave(underground: float) -> void:
	var cave := underground >= CAVE_ON if not _cave else underground > CAVE_OFF
	if cave != _cave:
		_cave = cave
		Music.set_underground(cave)


## The share of the ground around `at` that is open sea (water at the sea level over a deep floor).
func _measure_sea(world: WorldService, at: Vector3) -> float:
	if world == null:
		return 0.0
	var wet := 0
	for k in SEA_SAMPLES:
		var a := TAU * k / SEA_SAMPLES
		var x := floori(at.x + cos(a) * SEA_RADIUS)
		var z := floori(at.z + sin(a) * SEA_RADIUS)
		if world.get_block(Vector3i(x, MeadowsShape.SEA_LEVEL, z)) == BlockIds.WATER \
				and world.surface_height(x, z) <= MeadowsShape.SEA_LEVEL - SEA_DEPTH:
			wet += 1
	return float(wet) / SEA_SAMPLES


## The world's clock: the sandbox's SkyCycle (its `sky`), noon without one.
func _time_of_day(amb: Ambience) -> float:
	var host := amb.get_parent()
	var sky: Variant = host.get(&"sky") if host else null
	return float((sky as Object).get(&"time")) if sky is Object and is_instance_valid(sky) else DayCycle.NOON


func _exit_tree() -> void:
	for p in _players:
		p.stop()
	for i in _ids.size():
		_ids[i] = &""
		_gains[i] = 0.0
	chosen = &""
	if _cave:
		_cave = false
		Music.set_underground(false)
