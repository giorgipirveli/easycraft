class_name AlienVillage
extends Node3D
## An alien village on a playful planet (owner #86, spec §21f: "whole alien villages with their own homes, games and
## music"): Planet Boing's Boingaloo (mushroom huts) and Rainbow Planet's Prismtown (striped cone huts). Four homes
## round a square (each its own mesh on its own ground), four drum pads in the square, the chief by them, three
## villagers strolling, a sign. Every game builds its own from the seed (AlienRules.site), so nothing is sent.
## Echo, the drum game (EchoGame's rules): the chief plays the round's song on the drums (each lights up, bounces and
## rings its note), then the child hops on them in the same order; this node watches the child's feet on the pads
## (check_feet, a few times a second while it is the child's turn) and says each result (echo_step). Walking away
## ends the game quietly: nothing is lost.

## A hop's result or a moment of the game: EchoGame's results, &"your_turn" (the chief finished playing).
signal echo_step(result: StringName)

const YOUR_TURN := &"your_turn"
const NOTE_GAP := 0.72            # seconds between the chief's notes
const LIGHT_TIME := 0.45
const FIRST_PAUSE := 1.0
const AGAIN_PAUSE := 1.6
const AWAY := 24.0                # the child this far from the square: the game ends
const VOLUME_DB := -4.0

var universe := 0
var chief: Alien
var villagers: Array[Alien] = []
var pads: Array[Node3D] = []
var game := EchoGame.new()
## A game of Echo is on.
var playing := false
## () -> Vector3: the child's feet (INF: none).
var feet: Callable
var _queue: Array[int] = []
var _note_t := 0.0
var _lights: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _on_pad := -1
var _sound: Array[AudioStreamPlayer3D] = []
var _next_sound := 0
var _pad_base: Array[float] = []


## data = {universe: int, pos: Vector3 (the square's middle, on the ground), yaw: float, ground_y: Callable (x, z)}
func setup(data: Dictionary) -> void:
	universe = int(data.universe)
	name = "AlienVillage"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	var ground: Callable = data.get("ground_y", Callable())
	var v := CreatureWords.village(universe)
	for i in AlienRules.HOME_ANGLES.size():   # the homes, round the square, their doors towards it
		var a := AlienRules.HOME_ANGLES[i]
		var at := Vector3(cos(a), 0, sin(a)) * AlienRules.HOME_RING
		at.y = _local_ground(at, ground)
		var h := CreatureLook.add(self, AlienModels.home(universe, i), CreatureLook.CAMP_RANGE, "Home%d" % i)
		h.position = at
		h.rotation.y = RobotRules.yaw_to(at, Vector3(0, at.y, 0))
		_solid(at + Vector3(0, 1.0, 0), Vector3(1.7, 2.0, 1.7))
	for i in AlienRules.PAD_SPOTS.size():
		var p := Node3D.new()
		p.name = "Pad%d" % i
		p.position = AlienRules.PAD_SPOTS[i]
		p.position.y = _local_ground(p.position, ground)
		add_child(p)
		CreatureLook.add(p, AlienModels.pad(i), CreatureLook.CAMP_RANGE)
		pads.append(p)
		_pad_base.append(p.position.y)
	var sign := Label3D.new()
	sign.name = "Sign"
	sign.text = str(v.get("name", "Village"))
	sign.font_size = 60
	sign.outline_size = 14
	sign.pixel_size = 0.006
	sign.modulate = Color("ffd23f")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(0, 4.0, 0)
	sign.visibility_range_end = CreatureLook.CAMP_RANGE
	add_child(sign)
	var spot := AlienRules.CHIEF_SPOT
	spot.y = _local_ground(spot, ground)
	chief = _alien(v.chief, spot, ground)
	var ids: Array = v.get("villagers", [])
	for i in ids.size():
		var a := PI / 4.0 + PI / 2.0 * (i + 1)
		var at := Vector3(cos(a), 0, sin(a)) * (AlienRules.HOME_RING - 2.4)
		at.y = _local_ground(at, ground)
		villagers.append(_alien(ids[i], at, ground))
	for i in 2:
		var s := AudioStreamPlayer3D.new()
		s.stream = BuildMelody.STREAMS[BuildNotes.BELL]
		s.unit_size = 8.0
		s.max_distance = Audio.HEARING
		s.bus = Audio.BUS
		s.volume_db = VOLUME_DB
		add_child(s)
		_sound.append(s)


func aliens() -> Array[Alien]:
	var out: Array[Alien] = [chief]
	out.append_array(villagers)
	return out


## Drum i's middle in the world.
func pad_position(i: int) -> Vector3:
	return pads[i].global_position


## The drum a child's feet stand on (-1: none): on its disc, not flying over it.
func pad_at(at: Vector3) -> int:
	if not at.is_finite():
		return -1
	for i in pads.size():
		var p := pads[i].global_position
		if Vector2(at.x - p.x, at.z - p.z).length() <= AlienModels.PAD_R + 0.2 and at.y > p.y - 0.8 and at.y < p.y + 1.8:
			return i
	return -1


## A new game of Echo (the same seed, the same song): the chief plays the first round.
func start_game(game_seed: int) -> void:
	game.start(game_seed)
	playing = true
	_on_pad = -1
	_play_round(FIRST_PAUSE)


func stop_game() -> void:
	playing = false
	_queue.clear()
	game.listening = false


## The chief is playing the round's song (not the child's turn).
func chief_playing() -> bool:
	return playing and not _queue.is_empty()


## Drum i plays: it lights up, bounces and rings its note.
func play_pad(i: int) -> void:
	if i < 0 or i >= pads.size():
		return
	_lights[i] = LIGHT_TIME
	var s := _sound[_next_sound]
	_next_sound = (_next_sound + 1) % _sound.size()
	s.pitch_scale = BuildNotes.pitch(EchoGame.degree(i))
	if is_inside_tree():
		s.global_position = pads[i].global_position
		s.play()
		Fx.burst(get_tree().root, pads[i].global_position + Vector3(0, 0.4, 0), AlienModels.PAD_COLORS[i], 8, 2.0)


## A look at the child's feet (the director calls it a few times a second while the game is on).
func check_feet() -> StringName:
	if not playing:
		return EchoGame.IDLE
	var at: Vector3 = feet.call() if feet.is_valid() else Vector3.INF
	if at.is_finite() and Vector2(at.x - global_position.x, at.z - global_position.z).length() > AWAY:
		stop_game()
		return EchoGame.IDLE
	var pad := pad_at(at)
	if pad == _on_pad:
		return EchoGame.IDLE
	_on_pad = pad
	if pad < 0 or not game.listening:
		return EchoGame.IDLE
	var result := game.hop(pad)
	play_pad(pad)
	match result:
		EchoGame.ROUND_DONE:
			_play_round(AGAIN_PAUSE)
		EchoGame.NOT_YET:
			_play_round(AGAIN_PAUSE)
		EchoGame.WON:
			playing = false
			celebrate()
	echo_step.emit(result)
	return result


## Everyone hops for joy.
func celebrate() -> void:
	for a in aliens():
		a.cheer()


func _play_round(delay: float) -> void:
	_queue = game.round_song()
	_note_t = delay
	if chief:
		chief.say(CreatureWords.ECHO_LISTEN)


func _process(delta: float) -> void:
	for i in pads.size():
		if _lights[i] > 0.0:
			_lights[i] = maxf(_lights[i] - delta, 0.0)
		var k := _lights[i] / LIGHT_TIME
		pads[i].position.y = _pad_base[i] + sin(k * PI) * 0.22
		pads[i].scale = Vector3.ONE * (1.0 + k * 0.12)
	if _queue.is_empty():
		return
	_note_t -= delta
	if _note_t > 0.0:
		return
	play_pad(_queue.pop_front())
	_note_t = NOTE_GAP
	if _queue.is_empty():
		game.your_turn()
		_on_pad = pad_at(feet.call() if feet.is_valid() else Vector3.INF)   # standing on one already: hop off first
		echo_step.emit(YOUR_TURN)


func _local_ground(local: Vector3, ground: Callable) -> float:
	if not ground.is_valid():
		return 0.0
	var world := transform * Vector3(local.x, 0, local.z)
	return float(ground.call(floori(world.x), floori(world.z))) - position.y


func _alien(id: StringName, at: Vector3, ground: Callable) -> Alien:
	var a := Alien.new()
	a.setup({"id": id, "pos": at, "yaw": 0.0})
	a.ground_y = ground
	add_child(a)
	return a


func _solid(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = center
	body.add_child(cs)
