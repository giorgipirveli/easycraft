class_name Animal
extends CharacterBody3D
## A blocky animal (shared meshes per species). The host simulates it: it wanders, looks for safe
## ground (AnimalRules.can_step), looks at a player standing close, scurries away from a player
## rushing at it, and, once tamed, follows its owner like a buddy, sits when its owner taps it and
## hops when the owner jumps. Every peer animates the idle part (tail wag, head bob) and a pet's
## collar in its owner's colour. Other peers see a synced copy. Owner feedback #26 overrules M1b's
## "weapons only push animals": they have health by kind and take hits (take_hit, the section at the end).

const LAYER := 8                  # physics layer 4: animals (tap rays); players and the world ignore it
const GRAVITY := 20.0
const ACCEL := 12.0
const FOLLOW_DISTANCE := 2.8
const TELEPORT_DISTANCE := 40.0
const HOP_WALK := 0.35            # height of the little hops while walking
const HOP_EVERY := 0.42           # seconds between walking hops
const THINK_MIN := 1.5
const THINK_MAX := 4.5
const FLEE_TIME := 1.6
const AI_INTERVAL := 0.1          # host: decisions (flee, follow, safe step, look) ten times a second
const MOVING_SPEED := 0.3         # faster than this (from the synced position) counts as walking
const PET_NAMES: Array[String] = PetRules.FUN_NAMES   # M3 Task 11: the pet name list

var species: StringName = &"sheep"
var animal_id := ""               # stable: the spawn area slot (wild) or the saved pet id
var owner_peer := 0               # 0 = wild; otherwise the pet's owner
var pet_name := ""
var sitting := false
var _grip := -1.0                 # host: the grip under its feet (FrostRules, M3 Task 3), looked at every decision
## A rare golden animal (M2 Task 16): shines, runs from anyone close, is caught with a tap (the host's
## SecretDirector gives the reward), never tamed.
var golden := false
var world: WorldService           # set by the sandbox; the host uses it for safe steps

var _body := Node3D.new()         # visual root: hops, squash and tilt
var _dir := Vector3.ZERO
var _think := 0.0
var _flee := 0.0
var _hop := 0.0
var _taps: Array[float] = []
var _tag: Label3D
var _anim: Tween
var _rng := RandomNumberGenerator.new()
var _was_owner_on_floor := true
var _part: Node3D                 # the wagging tail or bobbing head (BlockyAnimal.PART_PIVOT)
var _collar: MeshInstance3D
var _idle_t := 0.0
var _last_pos := Vector3.ZERO
var _look := NAN                  # host: the yaw towards a close player, NAN = nobody close
var _ai_t := 0.0                  # host: time to the next decision (staggered between animals)
var _active := true               # host: near a player (AnimalRules.is_active), so simulated

## Every player, looked up once per physics frame for all animals.
static var _players_frame := -1
static var _players: Array[Player] = []
static var _player_spots: Array[Vector3] = []

static var _collar_materials := {}


## data = {species, id, pos, yaw, owner, name, sitting}
func setup(data: Dictionary) -> void:
	species = StringName(data.species)
	animal_id = str(data.id)
	name = animal_id
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	owner_peer = int(data.get("owner", 0))
	pet_name = str(data.get("name", ""))
	sitting = bool(data.get("sitting", false))
	golden = bool(data.get("golden", false))
	collar = PetRules.clean_collar(data.get("collar", PetRules.OWNER_COLOUR))   # M3 Task 11
	happiness = PetRules.clean_happiness(data.get("happiness", PetRules.HAPPY_START))
	if PetRules.has_perk(species, PetRules.SNIFF):
		_sniff_t = PetRules.sniff_every(species) * 0.5   # the first treasure trip, at its own pace
	max_hp = AnimalRules.max_hp(species)   # owner feedback #26
	hp = max_hp
	_shown_hp = hp
	_pack_setup(data)   # owner #41: a baby (hatched from an egg), a saddle, a donkey's chest
	_rng.seed = hash(animal_id)
	_rng.randf()   # owner #50: was its own idle-call timer (AnimalChorus calls now); kept so its choices stay the same
	_ai_t = _rng.randf() * AI_INTERVAL   # animals decide on different frames
	variant = StringName(str(data.get("variant", "")))   # M3 Task 20b: a befriended monster's or a mini's kind
	_build()
	_mind_setup()   # M2 Task 18


func is_pet() -> bool:
	return owner_peer != 0


func to_save() -> Dictionary:
	var d := {"species": String(species), "name": pet_name, "pos": [global_position.x, global_position.y, global_position.z],
		"id": animal_id}
	if mind:
		d.mind = mind.to_save()   # M2 Task 18: a pet remembers its owner by name
	d.collar = collar   # M3 Task 11
	d.happiness = happiness
	if saddled:
		d.saddled = true   # owner #41: a horse's or camel's saddle
	if not DonkeyChest.is_empty(chest):
		d.chest = Array(chest)   # owner #41: what a donkey carries
	_t20b_save(d)   # M3 Task 20b: its kind and tricks
	return d


## A pet (tap) from `peer` at time `now` (seconds). pets_owned: how many pets that peer already has.
## Wild dogs and cats become the peer's pet on the third quick pet; a pet's owner makes it sit or
## stand. Returns true when this tap tamed the animal. Host only.
func pet_tap(peer: int, now: float, pets_owned: int) -> bool:
	if golden:
		return false
	if is_pet():
		if peer == owner_peer:
			sitting = not sitting
		return false
	var r := AnimalRules.tame_tap(_taps, now)
	_taps = r.taps
	if not r.tamed or not AnimalRules.can_tame(species, pets_owned) or not PetRules.tames_by_petting(species):
		return false   # M3 Task 11: foxes and parrots want treats (treat)
	owner_peer = peer
	pet_name = PetRules.first_name(species, animal_id)
	_taps.clear()
	_make_tag()
	return true


## Weapons push animals around; they are never hurt.
func knockback(impulse: Vector3) -> void:
	Audio.play(VoiceRules.animal_hurt(species), global_position, 0.0, voice())   # the audio pass: it cries out
	velocity += impulse
	_flee = FLEE_TIME
	_dir = Vector3(impulse.x, 0.0, impulse.z).normalized()
	_mind_hit(impulse)   # M2 Task 18: it remembers who hit it
	if AnimalRules.curls_up(species) and not is_pet():
		_curl()          # owner #41: a hedgehog curls up (the push still moves it)


## Happy feedback (sound, hearts on taming), played on the peer that tapped.
func cheer(tamed: bool = false) -> void:
	Audio.play(VoiceRules.animal_happy(species), global_position, 0.0, voice())   # a purr, a happy whine, a moo
	if tamed:
		Fx.burst(get_tree().root, global_position + Vector3(0, _size().y + 0.4, 0), Color("ff5c8a"), 14, 3.0, 0.12, 0.9, 3.0)
	if _anim and _anim.is_valid():
		_anim.kill()
	AnimLife.rest(_body)   # owner #94: a fidget cut short
	_anim = create_tween()
	_anim.tween_property(_body, "position:y", 0.35, 0.12).set_trans(Tween.TRANS_QUAD)
	_anim.tween_property(_body, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE)


func _size() -> Vector3:
	return AnimalRules.SPECIES[species].size * _scale   # owner #41: a baby is smaller


## This animal's own voice pitch (VoiceRules.voice_pitch): the same every time, different from its herd (owner
## #41: a baby's higher).
func voice() -> float:
	return VoiceRules.voice_pitch(animal_id, _scale)


## Idle calls: owner feedback #50 moved them to one AnimalChorus per device (world/animal_chorus.gd): every
## animal rolling its own 8-20 s timer made ~4 calls a minute per animal, a flock a constant clucking.


func _is_fish() -> bool:
	return AnimalRules.SPECIES[species].habitat == &"water"


func _build() -> void:
	add_to_group(&"animals")
	collision_layer = LAYER
	collision_mask = 1
	add_child(_body)
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	if MagicPetModels.has(species):
		mi.mesh = MagicPetModels.mesh_for(species, variant)   # M3 Task 20b: a befriended monster, a boss's mini-buddy
	else:
		mi.mesh = BlockyAnimal.dressed_mesh_for(species) if _dressed() else BlockyAnimal.mesh_for(species)
	_shown_dressed = _dressed()
	if golden:
		mi.material_override = golden_material()
	_body.add_child(mi)
	var part_mesh := BlockyAnimal.part_mesh_for(species)
	if part_mesh:
		_part = Node3D.new()
		_part.name = "Part"
		_part.position = BlockyAnimal.PART_PIVOT[species]
		var pm := MeshInstance3D.new()
		pm.mesh = part_mesh
		if golden:
			pm.material_override = golden_material()
		_part.add_child(pm)
		_body.add_child(_part)
	var s := _size()
	var box := BoxShape3D.new()
	box.size = Vector3(minf(s.x, 0.9), s.y * 0.9, minf(s.z, 0.9))
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = 0.0 if _is_fish() else s.y * 0.45
	add_child(shape)
	if is_pet():
		_make_tag()
		_make_collar()
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:owner_peer", ".:pet_name", ".:sitting", ".:thought", ".:hp",
			".:collar", ".:happiness", ".:egg_at", ".:saddled", ".:rider_peer", ".:chest"]:
		cfg.add_property(NodePath(prop))
	# Owner, name and sitting rarely change: sent with the spawn, then only on a change (reliable),
	# not every frame (review M8). So is the thought over its head (M2 Task 18), and its health (#26),
	# and (M3 Task 11) its collar and heart, and (owner #41) a turtle's egg, a saddle, the rider and a chest.
	for prop in [".:owner_peer", ".:pet_name", ".:sitting", ".:thought", ".:hp", ".:collar", ".:happiness",
			".:egg_at", ".:saddled", ".:rider_peer", ".:chest"]:
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


func _make_tag() -> void:
	if _tag:
		_tag.text = pet_name
		return
	_tag = Label3D.new()
	_tag.text = pet_name
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.font_size = 40
	_tag.outline_size = 10
	_tag.pixel_size = 0.01
	_tag.modulate = Color("ffd23f")
	_tag.position.y = _size().y + 0.35
	add_child(_tag)


## A band round the neck in the owner's colour (dogs and cats; spec §3b).
func _make_collar() -> void:
	if _collar or not BlockyAnimal.COLLAR.has(species):
		return
	var color := PetRules.collar_color(collar, owner_peer)   # M3 Task 11: the one its child picked
	_shown_collar = collar
	if not _collar_materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.6
		_collar_materials[color] = m
	var band: Array = BlockyAnimal.COLLAR[species]
	var box := BoxMesh.new()
	box.size = band[1]
	_collar = MeshInstance3D.new()
	_collar.name = "Collar"
	_collar.mesh = box
	_collar.position = band[0]
	_collar.material_override = _collar_materials[color]
	_body.add_child(_collar)
	_t20b_fit_collar()   # M3 Task 20b


## Idle animation, on every peer: the tail wags (faster for a pet), the head bobs down to graze
## while the animal stands; walking or sitting brings the head back up.
func _animate_part(delta: float) -> void:
	_idle_t += delta
	var moving := delta > 0.0 and global_position.distance_to(_last_pos) / delta > MOVING_SPEED
	_moving = moving   # owner #41: a slider lies down only while it moves
	_last_pos = global_position
	if _part == null:
		return
	var phase := float(_rng.seed % 13)
	if BlockyAnimal.PART_KIND[species] == BlockyAnimal.WAG:
		_part.rotation.y = sin(_idle_t * (14.0 * PetRules.play_factor(happiness) if is_pet() else 8.0) + phase) * 0.5
	else:
		var target := 0.0 if moving or sitting else -(0.5 + 0.5 * sin(_idle_t * 1.1 + phase)) * 0.4
		_part.rotation.x = lerpf(_part.rotation.x, target, clampf(6.0 * delta, 0.0, 1.0))


func _process(delta: float) -> void:
	if _tag and _tag.text != pet_name:   # synced name on clients
		_tag.text = pet_name
	if is_pet() and _tag == null:
		_make_tag()
	if is_pet() and _collar == null:     # tamed here, or the owner synced to a client
		_make_collar()
	_animate_part(delta)
	_life_step(delta)   # owner #94: a hop, a shake or a sniff now and then (AnimLife)
	_mind_show()   # M2 Task 18: the thought bubble, on every peer
	_pet_show(delta)   # M3 Task 11: its collar colour, the bark's "!", the parrot's words, Pip's look
	_show_hurt()   # owner feedback #26: every peer squashes it when its (synced) health drops
	if golden:
		_twinkle(delta)
	# sitting: lower and still; otherwise a gentle tilt with speed
	var target_scale := (Vector3(1.0, 0.75, 1.0) if sitting else Vector3.ONE) * _scale   # owner #41: babies are small
	if not _body.scale.is_equal_approx(target_scale):   # a transform write costs, even an unchanged one
		_body.scale = _body.scale.lerp(target_scale, clampf(10.0 * delta, 0.0, 1.0))
	if _is_fish():
		_body.rotation.y = sin(Time.get_ticks_msec() * 0.008 + _rng.seed % 10) * 0.18
	_check_water(delta)
	_pack_show(delta)   # owner #41: a belly-slide, a turtle's egg, a hatch's sparkle, a saddle


# --- Owner #94: small idle life (AnimLife) ---------------------------------------------------------------------

var _life_t := -1.0
var _life_n := 0


## Every peer: while it stands (not walking, sitting, swimming or golden) it hops, shakes or sniffs now and then.
func _life_step(delta: float) -> void:
	if _life_t < 0.0:
		_life_t = AnimLife.wait(animal_id, 0)
	if _moving or sitting or golden or rider_peer != 0:   # never under a rider
		return
	_life_t -= delta
	if _life_t > 0.0:
		return
	_life_n += 1
	_life_t = AnimLife.wait(animal_id, _life_n)
	if _anim and _anim.is_running():
		return   # a cheer's hop is playing
	var what := AnimLife.action(species)
	if what != &"":
		_anim = AnimLife.play(self, _body, what, _scale)


## Host. Cost matters here (M1b acceptance: ~20 animals simulated in full every physics step made
## frames of up to 150 ms on the emulator): animals far from every player rest, decisions run
## AI_INTERVAL apart, and a wild animal standing still on the ground skips the physics move.
func _physics_process(delta: float) -> void:
	if world == null or not multiplayer.is_server():
		return
	if global_position.y < SpawnRules.FALL_LIMIT_Y:
		if is_pet():
			var owner := _owner_player()
			if owner:
				global_position = owner.global_position + Vector3(1.5, 1.0, 1.5)
				velocity = Vector3.ZERO
			else:
				_come_home()
		else:
			queue_free()
		return
	_ai_t -= delta
	var decide := _ai_t <= 0.0
	if decide:
		_ai_t += AI_INTERVAL
		_active = AnimalRules.is_active(global_position, _spots(), is_pet() or rider_peer != 0)
	if not _active:
		return                          # resting far from everyone: keeps its spot and pose
	if rider_peer != 0:
		_ride_step(delta, decide)       # owner #41: a horse or camel carries its rider (the host moves it)
		return
	_pads.tick(delta)
	_think -= delta
	_flee -= delta
	var speed: float = AnimalRules.SPECIES[species].speed * (1.8 if _flee > 0.0 else _pace)
	if golden and _flee > 0.0:
		speed = SurpriseRules.golden_speed(AnimalRules.SPECIES[species].speed)   # catchable
	if sitting:
		speed = 0.0
	if decide:
		_decide(speed)
	if decide or _grip < 0.0:
		_grip = FrostRules.grip_at(global_position, world.get_block)   # M3 Task 3: ice is slippery
		if _swimmer:
			_wet = _water_at_feet()      # owner #41: looked at with the decisions (the host steers by it)
	speed *= AnimalRules.slide_factor(species, _grip)   # owner #41: penguins and seals belly-slide on ice
	velocity.x = move_toward(velocity.x, _dir.x * speed, ACCEL * _grip * delta)
	velocity.z = move_toward(velocity.z, _dir.z * speed, ACCEL * _grip * delta)
	if _dir != Vector3.ZERO and speed > 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(-_dir.x, -_dir.z), clampf(8.0 * delta, 0.0, 1.0))
	elif not is_nan(_look):
		rotation.y = lerp_angle(rotation.y, _look, clampf(4.0 * delta, 0.0, 1.0))
	if _glide_step(delta):
		return                          # owner 39: a pet dragon flies beside its child in the air
	# Standing still on the ground: nothing to move until the next decision, which moves it once
	# (so a floor dug away still drops it). Pets keep moving every step: they jump when you jump.
	if not decide and not is_pet() and not _is_fish() and _dir == Vector3.ZERO and is_on_floor() \
			and velocity.is_zero_approx():
		return
	if _is_fish():
		_swim(delta)
	elif _swimmer and _wet:
		_paddle(delta)                  # owner #41: a duck (and its kin) floats on the water's top
	else:
		_walk(delta, speed)
	_touch_pads(decide)
	move_and_slide()


## Host, every AI_INTERVAL: flee from a player rushing at it, follow the owner or pick where to
## wander, keep off water and cliffs (looking further ahead the faster it goes), and look at a
## player standing close (spec §3b).
func _decide(speed: float) -> void:
	if is_pet():
		_follow_owner()
		_mind_pet()                     # M2 Task 18: remembers its owner, greets them, thinks aloud
		_sniff_treasure()               # M2 Task 17: a pet dog leads the way to buried treasure (M3 Task 11: a fox too)
		_pet_hold()                     # M3 Task 11: a parrot stands still, beak towards a secret
	else:
		if _curled():                   # owner #41: a curled-up hedgehog keeps still a while
			_look = NAN
			return
		_check_flee()
		_check_golden_flee()
		if _curl_t > 0.0:
			return
		if _mind_decide():              # M2 Task 18: the mind picks what to do (fish and golden: no mind)
			pass
		elif _think <= 0.0 and _flee <= 0.0:
			_think = _rng.randf_range(THINK_MIN, THINK_MAX)
			_dir = Vector3.ZERO if _rng.randf() < 0.4 else Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
	var reach := speed * AI_INTERVAL
	if _dir != Vector3.ZERO and not _safe_ahead(reach):
		_dir = -_dir if _flee <= 0.0 else _dir.rotated(Vector3.UP, PI * 0.5)
		_think = 1.0
		if not _safe_ahead(reach):
			_dir = Vector3.ZERO
	_look = AnimalRules.look_yaw(global_position, _spots()) if _dir == Vector3.ZERO and not _is_fish() else NAN
	if _hold_t > 0.0:
		_look = _hold_yaw               # M3 Task 11: pointing


func _walk(delta: float, speed: float) -> void:
	if _dir != Vector3.ZERO and speed > 0.0 and _up_a_trunk():
		velocity.y = TRUNK_CLIMB                              # owner #41: a squirrel runs up a tree trunk
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		return
	_hop -= delta
	var hop_height := 0.0
	if _dir != Vector3.ZERO and speed > 0.0 and is_on_wall():
		hop_height = AnimalRules.SPECIES[species].hop       # climb a 1-block step (owner #41: a goat 2)
	elif _dir != Vector3.ZERO and speed > 0.0 and _hop <= 0.0:
		_hop = AnimalRules.hop_every(species)               # owner #41: frogs and gummy bunnies hop high
		hop_height = 0.0 if AnimalRules.slides_on(species, _grip) else AnimalRules.walk_hop(species)   # a belly-slide: no hops
	if is_pet() and _owner_jumped() and _plays():
		hop_height = maxf(hop_height, 1.0)                   # jumps when you jump (M3 Task 11: a happier pet more often)
	if hop_height > 0.0:
		velocity.y = sqrt(2.0 * GRAVITY * hop_height)


func _swim(delta: float) -> void:
	var here := world.get_block(Vector3i(global_position.floor()))
	if here != BlockIds.WATER:
		velocity.y -= GRAVITY * delta                        # flopped out: fall back in
		return
	var above := world.get_block(Vector3i((global_position + Vector3.UP * 0.5).floor()))
	var target_vy := sin(Time.get_ticks_msec() * 0.0015 + float(_rng.seed % 7)) * 0.4
	if above != BlockIds.WATER:
		target_vy = -0.6                                      # stay under the surface
	velocity.y = move_toward(velocity.y, target_vy, 4.0 * delta)


## extra: how far it moves before the next check.
func _safe_ahead(extra: float = 0.0) -> bool:
	var ahead := global_position + _dir * (_size().z * 0.5 + 0.45 + extra)
	var feet := Vector3i(Vector3(ahead.x, global_position.y + 0.1, ahead.z).floor())
	return AnimalRules.can_step(species, feet, world.get_block)


func _check_flee() -> void:
	for p in _players_now():
		var away := AnimalRules.flee_from(species, global_position, p.global_position, p.velocity)   # owner #41: a shy deer
		if away != Vector3.ZERO:
			if AnimalRules.curls_up(species):
				_curl()                  # owner #41: a hedgehog curls up instead of running
				return
			_dir = away
			_flee = FLEE_TIME
			return


func _follow_owner() -> void:
	var owner := _owner_player()
	_note_owner(owner)
	if owner == null or not owner.is_spawned():
		_dir = Vector3.ZERO
		return
	var to := owner.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > TELEPORT_DISTANCE:
		global_position = owner.global_position + Vector3(1.5, 1.0, 1.5)
		velocity = Vector3.ZERO
		sitting = false
		return
	_dir = to / dist if dist > FOLLOW_DISTANCE and not sitting else Vector3.ZERO


func _owner_jumped() -> bool:
	var owner := _owner_player()
	if owner == null:
		return false
	var jumped := _was_owner_on_floor and not owner.is_on_floor() and owner.velocity.y > 4.0
	_was_owner_on_floor = owner.is_on_floor()
	return jumped


func _owner_player() -> Player:
	for p in _players_now():
		if p.peer_id == owner_peer:
			return p
	return null


func _nearest_player_distance() -> float:
	var best := INF
	for p in _players_now():
		best = minf(best, p.global_position.distance_to(global_position))
	return best


## Every player (and where they stand), refreshed once per physics frame and shared by all animals.
func _players_now() -> Array[Player]:
	var frame := Engine.get_physics_frames()
	if frame != _players_frame or not _players.all(is_instance_valid):
		_players_frame = frame
		_players.clear()
		_player_spots.clear()
		for n in get_tree().get_nodes_in_group(&"players"):
			var p := n as Player
			if p and not p.is_queued_for_deletion():
				_players.append(p)
				_player_spots.append(p.global_position)
	return _players


func _spots() -> Array[Vector3]:
	_players_now()
	return _player_spots

# --- Review M12: a guest's pets when the guest leaves (host) --------------------------------------

## Spots around the world spawn where fallen pets come back up (the spawn column stays free).
const HOME_SPOTS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]

static var _homecomings := 0      # fallen pets sent to the spawn so far: each gets the next spot

var _waiting := false             # sat down only because its owner left the game
var _home := Vector3.ZERO         # its spot next to the spawn, at ground height (once _has_home)
var _has_home := false


## A pet whose owner left the game (player == null) sits down where it is and waits: it wags its
## tail and looks at players who come close. If its owner comes back, it stands up again; a pet its
## owner told to sit stays sitting. After a reload it belongs to the host (ruling 15).
func _note_owner(player: Player) -> void:
	if player == null:
		if not sitting:
			sitting = true
			_waiting = true
	elif _waiting:
		_waiting = false
		sitting = false


## A pet without its owner that fell out of the world (its ground unloads when the guest goes)
## comes back up next to the world spawn and waits there. Until the ground there is loaded, it
## waits below the world, where nobody sees it.
func _come_home() -> void:
	if not _has_home:
		var c := world.spawn_column() + HOME_SPOTS[_homecomings % HOME_SPOTS.size()]
		_homecomings += 1
		_home = Vector3(c.x + 0.5, world.surface_height(c.x, c.y), c.y + 0.5)
		_has_home = true
	if not world.is_area_ready(_home):
		return
	var feet := world.find_standing_y(floori(_home.x), floori(_home.z))
	global_position = Vector3(_home.x, SpawnRules.spawn_y(feet), _home.z)
	velocity = Vector3.ZERO
	_note_owner(null)

# --- Real water (M2 Task 14, owner feedback #17) ---

const WATER_CHECK := 0.1          # s between looks at the water under a land animal (every game)
const SPLASH := 0.3               # a small splash (SwimRules.splash_strength scale)

var _water_t := 0.0
var _wet := false


## A land animal that falls or is pushed into water splashes (a small one), in every game. Fish live
## in the water and never splash. One block lookup every WATER_CHECK.
func _check_water(delta: float) -> void:
	if world == null or _is_fish():
		return
	_water_t -= delta
	if _water_t > 0.0:
		return
	_water_t = WATER_CHECK
	_look_under()   # owner #41: a penguin on ice belly-slides
	var wet := world.get_block(Vector3i((global_position + Vector3(0, 0.1, 0)).floor())) == BlockIds.WATER
	if wet and not _wet:
		var at := Vector3(global_position.x, SwimRules.surface_y(global_position, world.get_block), global_position.z)
		Fx.splash(get_tree().root, at, SPLASH, maxf(_size().x, _size().z))
		Audio.play(&"splash_small", at, -8.0)
	_wet = wet

# --- Golden animals (M2 Task 16) ---------------------------------------------------------------------

const TWINKLE_EVERY := 1.4        # seconds between a golden animal's little sparkles

static var _golden: StandardMaterial3D
var _twinkle_t := 0.0


## The one shiny gold material every golden animal wears (made once, never per animal).
static func golden_material() -> StandardMaterial3D:
	if _golden == null:
		_golden = StandardMaterial3D.new()
		_golden.albedo_color = Color("f2c230")
		_golden.metallic = 0.85
		_golden.roughness = 0.3
		_golden.emission_enabled = true
		_golden.emission = Color("7a5a00")
	return _golden


## Host: a golden animal runs from any player within SurpriseRules.GOLDEN_FLEE, rushing or not.
func _check_golden_flee() -> bool:
	if not golden:
		return false
	var away := SurpriseRules.golden_flee(global_position, _spots())
	if away == Vector3.ZERO:
		return false
	_dir = away
	_flee = FLEE_TIME
	return true


func _twinkle(delta: float) -> void:
	_twinkle_t -= delta
	if _twinkle_t > 0.0 or not is_inside_tree():
		return
	_twinkle_t = TWINKLE_EVERY
	Fx.burst(get_tree().root, global_position + Vector3(0, _size().y + 0.2, 0), Color("fff3a8"), 5, 1.2, 0.07, 0.6, -0.5)

# --- Jump and speed pads (M3 Task 6) ---------------------------------------------------------------

var _pads := PadRules.new()
var _pad_floor := false           # on the floor at the last pad check


## Host: a jump pad throws the animal up, a speed pad sends it running (PadRules). The block under its
## feet is looked up when it lands (walking animals hop, so they are mostly in the air) and with the
## decisions while it stands; a burst holds every step. The other games get the boing and the puff.
func _touch_pads(decide: bool) -> void:
	var fired := 0
	var on_floor := is_on_floor() and not _is_fish()
	if on_floor and (decide or not _pad_floor):
		fired = _pads.touch(PadRules.pad_under(global_position, 0.0, world.get_block), velocity, -global_basis.z)
	_pad_floor = on_floor
	velocity = _pads.apply(velocity, fired)
	if fired != 0:
		_rpc_pad_fx(fired)
		_rpc_pad_fx.rpc(fired)


@rpc("authority", "call_remote", "unreliable")
func _rpc_pad_fx(pad: int) -> void:
	PadFx.play(get_tree().root, global_position, pad)

# --- M2 Task 18: creature minds (owner feedback #24, spec §12.17) ---------------------------------
# A wild animal's Mind picks what it does next (AnimalSpecies: graze, wander, go back to the herd's
# leader, run over to a player it likes, keep away from one it fears, sleep by its den at night,
# look at something new, watch a player) from what it senses and remembers; the steering and the
# safe steps above carry it out. Pets keep following their owner (M1b) and remember them by name.
# Fish and golden animals keep their old ways. Host only; decisions stay AI_INTERVAL apart, and the
# mind picks again only when its action has run its course or something happened.

const MIND_NEAR := 20.0           # players this close count for the senses
const LIKED := 0.3                # a player liked this much is run over to
const FEARED := 0.25              # a player feared this much is kept away from
const KEEP_AWAY := 9.0
const APPROACH_STOP := 2.2
const HERD_NEAR := 6.0            # this close to its leader, a herd animal feels at home
const HERD_STOP := 2.5
const NOVEL_NEAR := 12.0          # a new block this close is worth a look
const NOVEL_FACE := 10.0          # and so is a new face
const NOVEL_TIME := 40.0          # seconds a placed block counts as new
const LOOK_STOP := 1.8
const THOUGHT_NEAR := 16.0        # thoughts only when a player can see them
const MIND_STUCK := 4.0           # not getting closer to a goal this long: think again
## The senses and drives are read this often (about 3 times a second, like the monsters' looks);
## steering follows every decision, and an event (a hit, a treat) is felt at the next one.
const SENSE_EVERY := 0.3
const DEN_HALF := Vector3i(8, 4, 8)   # trees looked for around the herd's home (one bulk copy)
const _GRAZE := 1 << 0
const _WANDER := 1 << 1
const _HERD := 1 << 2
const _APPROACH := 1 << 3
const _FLEE := 1 << 4
const _SLEEP := 1 << 5
const _EXPLORE := 1 << 6
const _WATCH := 1 << 7
# The same actions by index (AnimalSpecies.ACTIONS; test_animal_minds checks they match).
const _I_GRAZE := 0
const _I_WANDER := 1
const _I_HERD := 2
const _I_APPROACH := 3
const _I_FLEE := 4
const _I_SLEEP := 5
const _I_EXPLORE := 6
const _I_WATCH := 7
const NO_HERD := []

## The time of day (0..1) for every animal's mind; the sandbox points it at its sky.
static var time_source: Callable
## Every player's name for the minds, looked up with _players_now once per physics frame.
static var _mind_names: Array[String] = []
static var _mind_names_frame := -1
static var _herds := {}           # herd key -> [Animal]
static var _news: Array[Vector3] = []   # blocks players placed lately (the world's block_changed)
static var _news_t: Array[float] = []
static var _news_world := 0
static var _news_serial := 0

var mind: Mind
## Synced (on change): the picture over its head, Thought.NONE when there is none.
var thought := Thought.NONE
var _thought_t := 0.0
var _shown_thought := Thought.NONE
var _herd := ""
var _herd_index := 0
var _leader: Animal
var _leader_until := 0
var _mind_dt := 0.0
var _pace := 1.0
var _goal_d := INF
var _stuck_t := 0.0
var _threat := 0.0
var _night := false
var _den := Vector3.INF
var _home_spot := Vector3.INF
var _liked_pos := Vector3.INF
var _feared_pos := Vector3.INF
var _novel := Vector3.INF
var _novel_key: Variant = null
var _novel_block := Vector3.INF
var _news_seen := -1
var _news_next := 0.0
var _looked := {}
var _had_liked := false
var _had_feared := false
var _had_novel := false
var _lonely := false
var _rushed := false
var _owner_away := 0.0


## A player's name for the animals' memory (their chat name).
static func mind_name(p: Player) -> String:
	var who := str(Session.chat_names.get(p.peer_id, ""))
	return who if who != "" else "Player%d" % p.peer_id


## Every player (as _players_now) with their names in _mind_names, once per physics frame.
func _mind_players() -> Array[Player]:
	var players := _players_now()
	var frame := Engine.get_physics_frames()
	if frame != _mind_names_frame or _mind_names.size() != players.size():
		_mind_names_frame = frame
		_mind_names.clear()
		for p in players:
			_mind_names.append(mind_name(p))
	return players


## What its mind is doing now (AnimalSpecies action), or &"" without a mind.
func mind_action() -> StringName:
	return AnimalSpecies.ACTIONS[mind.action] if mind and mind.action >= 0 else &""


## Host: `p` gave it a treat (tapped it holding grass or leaves): it likes them more, is less hungry,
## and remembers the spot.
func mind_fed(p: Player) -> void:
	if mind == null or p == null:
		return
	mind.set_drive(Mind.HUNGER, mind.drive(Mind.HUNGER) - 0.5)
	mind.memory.note_place(MindMemory.FOOD, global_position, 1.0, mind.clock)
	_mind_kind(p, 0.6, &"fed")


## Host: `p` petted it.
func mind_petted(p: Player) -> void:
	if mind and p:
		_mind_kind(p, 0.3, &"petted")


## Host: `requester` fed (a treat) or petted the animal called `animal_name` in `animals`, if it is
## within their reach (like petting) and not golden (those are caught). True when it counted.
static func mind_treat(animals: Node, requester: Player, animal_name: String, fed: bool) -> bool:
	var a := animals.get_node_or_null(NodePath(animal_name)) as Animal
	if a == null or requester == null or a.golden or a.mind == null or a.is_queued_for_deletion():
		return false
	if not PlacementRules.in_reach(requester.eye_position(), Vector3i(a.global_position.floor()),
			PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		return false
	if fed:
		a.mind_fed(requester)
	else:
		a.mind_petted(requester)
	return true


## A pet's saved mind (WorldMeta.pets[i].mind).
func mind_load(saved: Variant) -> void:
	if mind:
		mind.load_save(saved)


## The first of its herd (the herd's leader), or null for an animal without a herd. Looked up again
## once a second (or when the leader went), not every decision.
func herd_leader() -> Animal:
	if _herd == "":
		return null
	var now := Time.get_ticks_msec()
	if now < _leader_until and is_instance_valid(_leader) and not _leader.is_pet() and not _leader.is_queued_for_deletion():
		return _leader
	_leader = null
	for n: Variant in _herds.get(_herd, NO_HERD):
		var a := n as Animal
		if is_instance_valid(a) and not a.is_pet() and not a.is_queued_for_deletion() \
				and (_leader == null or a._herd_index < _leader._herd_index):
			_leader = a
	_leader_until = now + 1000
	return _leader


func _mind_setup() -> void:
	_home_spot = position
	if _is_fish() or golden:
		return
	var table := AnimalSpecies.table(species)
	mind = Mind.create(table, animal_id, MindBook.current.net_for(table))
	var parts := animal_id.split("_")
	if not is_pet() and parts.size() == 3 and parts[0].begins_with("a") and parts[2].is_valid_int():
		_herd = "%s:%s_%s" % [species, parts[0], parts[1]]   # AnimalRules.spawns_for_cell ids: a<x>_<z>_<i>
		_herd_index = parts[2].to_int()


func _enter_tree() -> void:
	if _herd != "":
		var list: Array = _herds.get(_herd, [])
		if not list.has(self):
			list.append(self)
		_herds[_herd] = list


func _exit_tree() -> void:
	if is_instance_valid(_rider) and _rider.riding_animal == self:   # owner #41: its rider is off
		_rider.riding_animal = null
	_rider = null
	if _herds.has(_herd):
		(_herds[_herd] as Array).erase(self)
		if (_herds[_herd] as Array).is_empty():
			_herds.erase(_herd)


func _mind_kind(p: Player, amount: float, event: StringName) -> void:
	var who := mind_name(p)
	mind.memory.feel_about(who, amount, -amount, mind.clock)
	if is_pet() and p.peer_id == owner_peer and not _pinned(who):
		mind.memory.pin(who)
		sitting = false                  # tamed while asleep: up it gets
	mind.feel(event)
	mind.show_thought(Thought.HEART, true)
	mind.interrupt()


func _pinned(who: String) -> bool:
	for e in mind.memory.players:
		if e.name == who:
			return e.pinned
	return false


## Host: something hit it (a weapon's push): it remembers who (the player it was pushed away from),
## wakes up and runs.
func _mind_hit(impulse: Vector3) -> void:
	if mind == null:
		return
	var attacker := _attacker(impulse)
	if attacker:
		mind.memory.feel_about(mind_name(attacker), -0.4, 0.8, mind.clock)
		_feared_pos = attacker.global_position
	mind.feel(&"hit")
	mind.memory.note_place(MindMemory.DANGER, global_position, 1.0, mind.clock)
	mind.set_drive(Mind.FEAR, 1.0)
	mind.show_thought(Thought.SWEAT, true)
	mind.interrupt()
	_threat = 1.0
	if not is_pet():
		sitting = false


## The player a push came from: the nearest one on the side it was pushed away from.
func _attacker(impulse: Vector3) -> Player:
	var back := Vector2(-impulse.x, -impulse.z)
	var best: Player = null
	var best_d := 24.0
	for p in _players_now():
		var to := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z)
		var d := to.length()
		if d < best_d and (back.length() < 0.01 or d < 0.5 or to.dot(back) > 0.0):
			best = p
			best_d = d
	return best


## A pet: remembers its owner, is happy to see them again (never sad they were away), thinks aloud.
func _mind_pet() -> void:
	if mind == null:
		return
	mind.tick(AI_INTERVAL)
	var owner := _owner_player()
	if owner and _flat_to(owner.global_position) < 8.0:
		if _owner_away >= 20.0:
			mind.show_thought(Thought.HEART, true)   # happy to see its owner again
		_owner_away = 0.0
	else:
		_owner_away += AI_INTERVAL
	_mind_thoughts()


## Host, every decision of a wild animal: senses, drives, a new pick when due, then the action's
## steering. False without a mind (the old wander runs).
func _mind_decide() -> bool:
	if mind == null:
		return false
	var t0 := Time.get_ticks_usec() if Mind.profiling else 0
	mind.tick(AI_INTERVAL)
	_mind_dt += AI_INTERVAL
	if _mind_dt >= SENSE_EVERY - 0.001 or mind.due():
		_mind_sense_and_pick(_mind_dt)
		_mind_dt = 0.0
	if _flee <= 0.0:
		_mind_act()
	_mind_thoughts()
	if Mind.profiling:
		Mind.note_cost(Time.get_ticks_usec() - t0)
	return true


## Senses, drives and, when due, a new pick (SENSE_EVERY apart, or at once when something happened).
func _mind_sense_and_pick(dt: float) -> void:
	_watch_news()
	var allow := _mind_senses()
	var night := mind.senses[Mind.S_NIGHT] > 0.5
	if night != _night:
		_night = night
		_den = Vector3.INF               # each night the herd looks for its den again
		mind.interrupt()
	_mind_drives(dt)
	if mind.due() or mind.action < 0 or not (allow & (1 << mind.action)):
		var before := mind.action
		mind.think(allow)
		if mind.action != before:
			_mind_enter(before)


## Fills the senses; returns which actions are possible now.
func _mind_senses() -> int:
	var s := mind.senses
	var nearest := INF
	var like := 0.0
	var fear := 0.0
	var rush := false
	_liked_pos = Vector3.INF
	_feared_pos = Vector3.INF if _threat <= 0.0 else _feared_pos
	var face := Vector3.INF
	var face_key := ""
	var players := _mind_players()
	for i in players.size():
		var p := players[i]
		var pos := p.global_position
		var d := _flat_to(pos)
		if d > MIND_NEAR:
			continue
		nearest = minf(nearest, d)
		var who := _mind_names[i]
		var e := mind.memory.entry(who)      # one look in its memory for all it feels about them
		var l: float = e.get("like", 0.0)
		var f: float = e.get("fear", 0.0)
		if l > like and d > APPROACH_STOP + 0.4:
			like = l
			_liked_pos = pos
		if f > fear and d < KEEP_AWAY:
			fear = f
			_feared_pos = pos
		if AnimalRules.flee_from(species, global_position, pos, p.velocity) != Vector3.ZERO:   # owner #41: a shy deer sooner
			rush = true
			if not _rushed:
				mind.memory.feel_about(who, 0.0, 0.2, mind.clock)
				mind.feel(&"chased")
		if d <= NOVEL_FACE and not face.is_finite() and e.is_empty():
			face = pos
			face_key = who
	_rushed = rush
	var leader := herd_leader()
	var leader_d := _flat_to(leader.global_position) if leader and leader != self else 0.0
	var home := _den if _den.is_finite() else _home_spot
	_find_novelty(face, face_key)
	s[Mind.S_NEAR] = clampf(1.0 - nearest / MIND_NEAR, 0.0, 1.0) if nearest < INF else 0.0
	s[Mind.S_LIKE] = like
	s[Mind.S_FEAR] = fear
	s[Mind.S_RUSH] = 1.0 if rush else 0.0
	s[Mind.S_HEALTH] = 1.0
	s[Mind.S_NIGHT] = 1.0 if AnimalRules.feels_night(species, _is_night()) else 0.0   # owner #41: an owl's night is the day
	s[Mind.S_KIN] = 1.0 if leader_d <= HERD_NEAR else 0.0
	s[Mind.S_THREAT] = _threat
	s[Mind.S_NOVEL] = 1.0 if _novel.is_finite() else 0.0
	s[Mind.S_HOME_FAR] = clampf(_flat_to(home) / 20.0, 0.0, 1.0) if home.is_finite() else 0.0
	var allow := _GRAZE | _WANDER
	if leader and leader != self:
		allow |= _HERD
	if like >= LIKED:
		allow |= _APPROACH
	if fear >= FEARED or rush or _threat > 0.2:
		allow |= _FLEE
	if s[Mind.S_NIGHT] > 0.5:
		allow |= _SLEEP
	if _novel.is_finite():
		allow |= _EXPLORE
	if nearest <= NOVEL_FACE:
		allow |= _WATCH
	# Something new happened: think again now, not when the current action ends.
	var liked := like >= LIKED
	var feared := fear >= FEARED or rush
	var novel := _novel.is_finite()
	var lonely := leader_d > HERD_NEAR
	if (liked and not _had_liked) or (feared and not _had_feared) or (novel and not _had_novel) or (lonely and not _lonely):
		mind.interrupt()
	_had_liked = liked
	_had_feared = feared
	_had_novel = novel
	_lonely = lonely
	return allow


## Hunger rises (and falls while grazing), sleepiness follows the night, fear fades, curiosity
## grows, and a herd animal misses its leader when it is far.
func _mind_drives(dt: float) -> void:
	var d := mind.drives                  # shared with the mind (packed arrays are references)
	d[Mind.HUNGER] = clampf(d[Mind.HUNGER] + (-dt / 12.0 if mind.action == _I_GRAZE else dt / 240.0), 0.0, 1.0)
	d[Mind.SLEEPY] = clampf(d[Mind.SLEEPY] + (dt / 8.0 if _night else -dt / 4.0), 0.0, 1.0)
	_threat = maxf(_threat - dt / 8.0, 0.0)
	d[Mind.FEAR] = clampf(maxf(d[Mind.FEAR] - dt / 6.0, maxf(_threat, mind.senses[Mind.S_FEAR])), 0.0, 1.0)
	d[Mind.CURIOSITY] = minf(d[Mind.CURIOSITY] + dt / 90.0, 1.0)
	d[Mind.COMPANY] = clampf(d[Mind.COMPANY] + (dt / 2.0 if _lonely else -dt / 3.0), 0.0, 1.0)


func _mind_enter(before: int) -> void:
	_goal_d = INF
	_stuck_t = 0.0
	_think = 0.0
	_pace = 1.0
	if before == _I_SLEEP and not is_pet():
		sitting = false                  # awake
	if mind.action == _I_GRAZE and mind.drive(Mind.HUNGER) > 0.6:
		mind.show_thought(Thought.FOOD)


## Carries out the current action: where to go (the safe-step check in _decide follows).
func _mind_act() -> void:
	match mind.action:
		_I_GRAZE, _I_WATCH:
			_dir = Vector3.ZERO
		_I_WANDER:
			if _think <= 0.0:
				_think = lerpf(THINK_MIN, THINK_MAX, mind.roll())
				var fav := mind.memory.place(MindMemory.FOOD, global_position)
				if _tree_climber and mind.roll() < 0.4 and _trunk_near().is_finite():
					_dir = _flat_dir(_trunk)   # owner #41: a squirrel scampers over to its tree (and up it)
				elif fav.is_finite() and _flat_to(fav) > 6.0 and mind.roll() < 0.3:
					_dir = _flat_dir(fav)      # back to a favourite spot
				elif mind.roll() < 0.35:
					_dir = Vector3.ZERO
				else:
					_dir = Vector3.FORWARD.rotated(Vector3.UP, mind.roll() * TAU)
		_I_HERD:
			var leader := herd_leader()
			if leader == null or leader == self:
				_dir = Vector3.ZERO
			else:
				var d := _flat_to(leader.global_position)
				_pace = 1.5 if d > 8.0 else 1.1
				_go_to(leader.global_position + _ring(_herd_index, 1.5), HERD_STOP)
		_I_APPROACH:
			_pace = 1.5
			if _liked_pos.is_finite():
				_go_to(_liked_pos, APPROACH_STOP)
			else:
				_dir = Vector3.ZERO
		_I_FLEE:
			_pace = 1.8
			var from := _feared_pos if _feared_pos.is_finite() else mind.memory.place(MindMemory.DANGER, global_position)
			if from.is_finite() and _flat_to(from) < KEEP_AWAY:
				_dir = -_flat_dir(from)
			else:
				_dir = Vector3.ZERO
		_I_SLEEP:
			if sitting:
				_dir = Vector3.ZERO
			elif _go_to(_sleep_spot(), 0.8):
				sitting = true            # asleep (lying down on every peer)
				mind.feel(&"slept")
		_I_EXPLORE:
			if not _novel.is_finite():
				_dir = Vector3.ZERO
			elif _go_to(_novel, LOOK_STOP):
				_mind_looked()


## Walks towards `goal` until `stop` away (true once there). Not getting closer for MIND_STUCK
## seconds counts as there.
func _go_to(goal: Vector3, stop: float) -> bool:
	var d := _flat_to(goal)
	if d <= stop:
		_dir = Vector3.ZERO
		return true
	if d < _goal_d - 0.2:
		_goal_d = d
		_stuck_t = 0.0
	else:
		_stuck_t += AI_INTERVAL
		if _stuck_t >= MIND_STUCK:
			_stuck_t = 0.0
			_goal_d = INF
			mind.interrupt()
			_dir = Vector3.ZERO
			return true
	_dir = _flat_dir(goal)
	return false


## It had a good look at the new thing: less curious, and it knows it now.
func _mind_looked() -> void:
	if _looked.size() > 64:
		_looked.clear()
	if _novel_key is String:
		mind.memory.saw(_novel_key, mind.clock)
	else:
		_looked[_novel_key] = true
	_novel = Vector3.INF
	mind.set_drive(Mind.CURIOSITY, 0.1)
	mind.feel(&"explored")
	mind.interrupt()


## Where it sleeps: by its herd's den (its leader's), each a little apart.
func _sleep_spot() -> Vector3:
	var leader := herd_leader()
	if leader and leader != self:
		return leader._den_spot() + _ring(_herd_index, 1.3)
	return _den_spot()


func _den_spot() -> Vector3:
	if not _den.is_finite():
		_den = _find_den()
	return _den


## The foot of the tree nearest to its home (where its herd lives; one bulk copy of the box around
## it, searched natively), else the home spot itself. Remembered as its den.
func _find_den() -> Vector3:
	var home := _home_spot if _home_spot.is_finite() else global_position
	var origin := Vector3i(home.floor()) - DEN_HALF
	var best := Vector3.INF
	var best_d := INF
	if world:
		var logs := BotRules.find_in_buffer(world.copy_box(origin, DEN_HALF * 2 + Vector3i.ONE), origin,
			[BlockIds.LOG] as Array[int])
		for cell in logs:
			if world.get_block(cell + Vector3i.DOWN) == BlockIds.LOG:
				continue                 # not the foot of the trunk
			var foot := Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
			var side := Vector3(home.x - foot.x, 0.0, home.z - foot.z)
			var spot := foot + (side.normalized() if side.length() > 0.01 else Vector3.RIGHT) * 1.3
			var d := Vector2(spot.x - home.x, spot.z - home.z).length()
			if d < best_d:
				best = spot
				best_d = d
				_trunk = foot                # owner #41: the tree a squirrel runs up
	var den := best if best.is_finite() else home
	mind.memory.note_place(MindMemory.DEN, den, 1.0, mind.clock)
	return den


## Something new near: a block a player placed lately that it hasn't looked at, else a new face.
func _find_novelty(face: Vector3, face_key: String) -> void:
	if _news_seen != _news_serial or mind.clock >= _news_next:   # the news again: when there is more, or each second
		_news_seen = _news_serial
		_news_next = mind.clock + 1.0
		_novel_block = Vector3.INF
		var now := Time.get_ticks_msec() / 1000.0
		for i in range(_news.size() - 1, -1, -1):
			var pos := _news[i]
			if now - _news_t[i] <= NOVEL_TIME and not _looked.has(pos) and _flat_to(pos) <= NOVEL_NEAR:
				_novel_block = pos
				break
	if _novel_block.is_finite() and not _looked.has(_novel_block):
		_novel = _novel_block
		_novel_key = _novel_block
		return
	if _novel_key is String and _novel.is_finite() and face_key == _novel_key:
		_novel = face                    # the same face, where it stands now
		return
	_novel = face
	_novel_key = face_key if face.is_finite() else null


## Host: the next thought (at most one every Mind.BUBBLE_GAP), shown only when a player is near to
## see it, for ThoughtBubble.SHOW_TIME; synced to every peer through `thought`.
func _mind_thoughts() -> void:
	if thought != Thought.NONE:
		_thought_t -= AI_INTERVAL
		if _thought_t <= 0.0:
			thought = Thought.NONE
		return
	var t := mind.take_thought()
	if t != Thought.NONE and _nearest_player_distance() <= THOUGHT_NEAR:
		thought = t
		_thought_t = ThoughtBubble.SHOW_TIME


## Every peer: shows or hides the bubble when the synced thought changes.
func _mind_show() -> void:
	if thought == _shown_thought:
		return
	_shown_thought = thought
	if thought == Thought.NONE:
		ThoughtBubble.hide_on(self)
	else:
		ThoughtBubble.show_on(self, thought, _size().y + (0.95 if is_pet() else 0.6))


func _is_night() -> bool:
	return DayCycle.is_night(float(time_source.call())) if time_source.is_valid() else false


## Players' placed blocks, for every animal's curiosity (one connection per world).
func _watch_news() -> void:
	if world == null or world.get_instance_id() == _news_world:
		return
	_news_world = world.get_instance_id()
	_news.clear()
	_news_t.clear()
	world.block_changed.connect(Animal._note_news)


static func _note_news(pos: Vector3i, _old_id: int, new_id: int) -> void:
	if new_id == BlockIds.AIR or new_id == BlockIds.WATER:
		return
	_news.append(Vector3(pos.x + 0.5, pos.y, pos.z + 0.5))
	_news_t.append(Time.get_ticks_msec() / 1000.0)
	_news_serial += 1
	if _news.size() > 16:
		_news.pop_front()
		_news_t.pop_front()


func _flat_to(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


func _flat_dir(p: Vector3) -> Vector3:
	var v := Vector3(p.x - global_position.x, 0.0, p.z - global_position.z)
	return v.normalized() if v.length() > 0.01 else Vector3.ZERO


## A spot around a centre for herd member `index` (the leader, 0, is the centre).
static func _ring(index: int, radius: float) -> Vector3:
	if index == 0:
		return Vector3.ZERO
	var a := index * 2.1
	return Vector3(cos(a), 0.0, sin(a)) * radius


# --- Pet dogs sniff out buried treasure (M2 Task 17, TreasureSniff) --------------------------------

## Host: (from) -> the nearest unopened buried chest, or INF (the sandbox asks the secrets).
var treasure_near: Callable
var sniffing := false             # on a trip towards a treasure
var _sniff_t := TreasureSniff.EVERY * 0.5
var _trip_t := 0.0
var _sniff_to := Vector3.INF
var _sniff_chest := Vector3.INF
var _paw_t := 0.0


## Every decision of a pet: now and then a dog trots towards a buried treasure and paws the ground
## over it; otherwise it follows its owner as always.
func _sniff_treasure() -> void:
	var owner := _owner_player()
	if not (TreasureRules.sniffs(species) or PetRules.has_perk(species, PetRules.SNIFF)) or sitting or treasure_near.is_null() \
			or owner == null or not PetPerks.active(is_pet(), global_position, owner.global_position):   # owner 42, M3 Task 11
		sniffing = false
		_pace = 1.0
		return
	if sniffing:
		_trip_t -= AI_INTERVAL
		if _trip_t <= 0.0:
			sniffing = false
			_pace = 1.0
			_sniff_t = PetRules.sniff_every(species)
			return
		var to := _sniff_to - global_position
		to.y = 0.0
		_dir = to.normalized() if to.length() > 0.4 else Vector3.ZERO
		_paw_t -= AI_INTERVAL
		if _paw_t <= 0.0 and TreasureSniff.digs(global_position, _sniff_chest):
			_paw_t = 0.8
			_rpc_dig.rpc()   # M3 Task 11: every game sees the dirt fly (a fox digs a bigger puff)
			_rpc_dig()
		return
	_sniff_t -= AI_INTERVAL
	if _sniff_t > 0.0:
		return
	_sniff_t = PetRules.sniff_every(species)
	var chest: Vector3 = treasure_near.call(global_position)
	var t := TreasureSniff.target(global_position, chest, owner.global_position)
	if not t.is_finite():
		return
	_sniff_chest = chest
	_sniff_to = t
	_trip_t = TreasureSniff.TRIP
	sniffing = true
	_pace = PetRules.sniff_pace(species)   # M3 Task 11: a fox trots there faster
	Audio.play(AnimalRules.SPECIES[species].sound, global_position, 0.0, voice())

# --- Owner feedback #26: animals can be defeated --------------------------------------------------
# Health by kind (AnimalRules.HEALTH). A weapon's, a fist's or an arrow's hit (CombatDirector.apply_hit,
# host) pushes it and it runs (knockback: its mind learns fear of the one who hit it), then takes the
# damage; at 0 it is gone and the CombatDirector puffs it away in the monsters' cartoon cloud and gives
# the Survivor drops. Pets and golden animals are only pushed (AnimalRules.can_be_hurt). Every peer
# sees the hurt: a squash, a few white stars and its cry, when the synced health drops.

const HURT_SQUASH := Vector3(1.25, 0.65, 1.25)   # the body springs back through _process's lerp
const HURT_STARS := Color("fffbe6")

var hp := 1                       # synced on change
var max_hp := 1
var _shown_hp := 1


## Host: a hit of `damage` from `_from` with the push `push`. True when this hit defeated it (then it
## is already on its way out; the caller puffs it away).
func take_hit(damage: int, _from: Vector3, push: Vector3) -> bool:
	if not multiplayer.is_server() or is_queued_for_deletion() or hp <= 0:
		return false
	if push.is_finite():
		knockback(push)
	if not AnimalRules.can_be_hurt(is_pet(), golden):
		return false
	hp = maxi(hp - maxi(damage, 0), 0)
	if hp > 0:
		return false
	queue_free()
	return true


## The sound hook for a hurt animal: its own voice for now (the audio pass may give each kind a yelp).
func hurt_sound() -> StringName:
	return AnimalRules.SPECIES[species].sound


func _show_hurt() -> void:
	if hp >= _shown_hp:
		_shown_hp = hp
		return
	_shown_hp = hp
	_body.scale = HURT_SQUASH
	if is_inside_tree():
		Fx.burst(get_tree().root, global_position + Vector3(0, _size().y + 0.2, 0), HURT_STARS, 6, 2.5, 0.08, 0.35, 2.0)
		Audio.play(hurt_sound(), global_position, 2.0)


# --- M3 Task 11: pets with perks ------------------------------------------------------------------
# Collars in the colour its child picked (synced `collar`), the happiness heart (synced `happiness`, in
# PetRules.STEPS; the host keeps the exact value), taming foxes and parrots with treats, pats and treats
# raising the heart, the dog's bark (an RPC: every game hears it and sees a "!" over it), the parrot
# pointing its beak at a secret (the host holds it still; every game hears the squawk and sees a sparkle),
# the dig puff over buried treasure (an RPC), the parrot's own-words bubble (this device only, never sent)
# and Pip's shiny look in the realistic style. The host's PetDirector decides the perks; see PetPerks.

const MARK_HEIGHT := 0.9          # the bark's "!" floats this far over its head
const MARK_TIME := 1.5
const BUBBLE_TIME := 3.5          # the parrot's words stay this long
const SPARKLE := Color("fff3a8")
const DIRT := Color("8a5a2b")

## The collar colour its child picked (PetRules.COLLARS index; OWNER_COLOUR = the owner's). Synced on change.
var collar := PetRules.OWNER_COLOUR
## The happiness heart, 0..1 in PetRules.STEPS (never below PetRules.HAPPY_FLOOR). Synced on change.
var happiness := PetRules.HAPPY_START:
	set(v):
		happiness = v
		_heart = v
## Host: the dog's bark memory (PetPerks.bark) and the parrot's next point.
var bark_known := {}
var bark_last := -INF
var point_t := PetPerks.POINT_EVERY * 0.5

var _heart := PetRules.HAPPY_START   # host: the exact heart (happiness is its synced step)
var _fed := {}                    # host: peer -> treats given while wild (PetRules.treat_tames)
var _pat_at := -INF
var _hold_t := 0.0                # host: seconds it still stands pointing
var _hold_yaw := 0.0
var _shown_collar := PetRules.OWNER_COLOUR
var _mark: MeshInstance3D
var _mark_t := 0.0
var _bubble: Label3D
var _bubble_t := 0.0
var _pip_style := ""

static var _pip_shiny: StandardMaterial3D


## Host: a treat `item` from `peer`, who has `pets_owned` pets that count toward the cap. Returns &"tamed"
## (a wild fox or parrot became theirs), &"fed" (a pet ate it: its heart rises), &"liked" (a wild animal
## that can be a pet ate it and likes them more) or &"" (nothing happened: the treat is kept).
func treat(peer: int, item: int, pets_owned: int) -> StringName:
	if golden or not PetRules.is_treat(item) or not PetRules.is_pet_kind(species):
		return &""
	if is_pet():
		_set_heart(PetRules.after_treat(_heart, species, item))
		return &"fed"
	if not PetRules.tames_by_treats(species):
		return &"liked"                  # a wild dog or cat: a treat is also a pet (three tame it)
	if not AnimalRules.can_tame(species, pets_owned) or not PetRules.treat_tames(_fed, peer):
		return &"liked"
	owner_peer = peer
	pet_name = PetRules.first_name(species, animal_id)
	sitting = false
	_fed.clear()
	_make_tag()
	return &"tamed"


## Host: a pat from its child; the heart rises (PetRules.PAT_GAP apart). True when it counted.
func pat(now: float) -> bool:
	if not is_pet() or now - _pat_at < PetRules.PAT_GAP:
		return false
	_pat_at = now
	_set_heart(PetRules.after_pat(_heart))
	return true


## Host: `seconds` of play with its child around: the heart falls a little (never below the floor).
func pet_tick(seconds: float) -> void:
	if is_pet():
		_set_heart(PetRules.after_time(_heart, seconds))


func _set_heart(h: float) -> void:
	var exact := clampf(h, PetRules.HAPPY_FLOOR, 1.0)
	var step := PetRules.synced(exact)
	if step != happiness:
		happiness = step
	_heart = exact


## Whether it jumps along with its child this time (a happier pet more often; never needed).
func _plays() -> bool:
	return _rng.randf() < PetRules.play_factor(happiness)


## Host: the dog barks — every game hears it and sees a "!" over it.
func bark() -> void:
	bark_last = Time.get_ticks_msec() / 1000.0
	_rpc_bark.rpc()
	_rpc_bark()


@rpc("authority", "call_remote", "reliable")
func _rpc_bark() -> void:
	Audio.play(AnimalRules.SPECIES[species].sound, global_position, 2.0)
	_show_mark()


## Host: the parrot stands still for PetPerks.POINT_HOLD, beak towards `target` (a secret nobody found).
func point_at(target: Vector3) -> void:
	_hold_t = PetPerks.POINT_HOLD
	_hold_yaw = PetPerks.point_yaw(global_position, target)
	_dir = Vector3.ZERO
	_rpc_point.rpc(target)
	_rpc_point(target)


func pointing() -> bool:
	return _hold_t > 0.0


@rpc("authority", "call_remote", "reliable")
func _rpc_point(target: Vector3) -> void:
	if not is_inside_tree():
		return
	Audio.play(AnimalRules.SPECIES[species].sound, global_position)
	var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z).normalized()
	for i in 3:   # a little trail of sparkles the way the beak points
		Fx.burst(get_tree().root, global_position + Vector3(0, _size().y, 0) + to * (0.6 + i * 0.7), SPARKLE, 4, 1.0, 0.07, 0.5, -0.5)


## Every decision of a pet: while it points it stands still.
func _pet_hold() -> void:
	if _hold_t > 0.0:
		_hold_t -= AI_INTERVAL
		_dir = Vector3.ZERO


## Dirt flies over buried treasure (a fox digs a bigger puff).
@rpc("authority", "call_remote", "reliable")
func _rpc_dig() -> void:
	if not is_inside_tree():
		return
	var big := PetRules.digs(species)
	Fx.burst(get_tree().root, global_position + Vector3(0, 0.1, 0), DIRT, 14 if big else 6, 3.0 if big else 2.0,
		0.1 if big else 0.08, 0.6 if big else 0.5, 6.0)


## This device only: the parrot squawks `text` (its own child's words, PetEcho) in a bubble over its head.
## Never sent anywhere.
func squawk_line(text: String) -> void:
	if text == "" or not is_inside_tree():
		return
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.name = "Squawk"
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.font_size = 36
		_bubble.outline_size = 12
		_bubble.pixel_size = 0.01
		_bubble.modulate = Color("fffbe6")
		_bubble.outline_modulate = Color("2f7fe0")
		_bubble.position.y = _size().y + 0.75
		add_child(_bubble)
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = BUBBLE_TIME
	Audio.play(AnimalRules.SPECIES[species].sound, global_position)


func bubble_text() -> String:
	return _bubble.text if _bubble and _bubble.visible else ""


## Every peer: the collar in its (synced) colour, the "!" and the bubble while they show, Pip's look.
func _pet_show(delta: float) -> void:
	if _collar and collar != _shown_collar:
		_shown_collar = collar
		_collar.material_override = collar_material(PetRules.collar_color(collar, owner_peer))
	if _mark_t > 0.0:
		_mark_t -= delta
		_mark.visible = _mark_t > 0.0
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam and _mark.visible:
			_mark.global_basis = cam.global_basis
	if _bubble_t > 0.0:
		_bubble_t -= delta
		_bubble.visible = _bubble_t > 0.0
	if species == PetRules.PIP and _pip_style != BlockLibrary.style:
		_pip_look(BlockLibrary.style)


func _show_mark() -> void:
	if _mark == null:
		_mark = MeshInstance3D.new()
		_mark.name = "BarkMark"
		_mark.mesh = AlertMarks.mesh(StealthRules.MARK_BANG)   # the monsters' shared "!" (no new material)
		_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark.position.y = _size().y + MARK_HEIGHT
		add_child(_mark)
	_mark.visible = true
	_mark_t = MARK_TIME


func mark_shown() -> bool:
	return _mark != null and _mark.visible


## One cached collar material per colour (at most the 8 collar colours and the owners' colours).
static func collar_material(color: Color) -> StandardMaterial3D:
	if not _collar_materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.6
		_collar_materials[color] = m
	return _collar_materials[color]


## Pip in the realistic style: shiny metal. The same vertex-colour shader as every animal (only the metal
## and roughness numbers differ), so no new shader compiles; blocky Pip wears the animals' own material.
func _pip_look(style: String) -> void:
	_pip_style = style
	var shiny := style == "realistic"
	for mi: MeshInstance3D in [_body.get_child(0) as MeshInstance3D, _part.get_child(0) as MeshInstance3D if _part else null]:
		if mi:
			mi.material_override = pip_material() if shiny else null


static func pip_material() -> StandardMaterial3D:
	if _pip_shiny == null:
		_pip_shiny = StandardMaterial3D.new()
		_pip_shiny.vertex_color_use_as_albedo = true
		_pip_shiny.vertex_color_is_srgb = true
		_pip_shiny.metallic = 0.75
		_pip_shiny.roughness = 0.3
	return _pip_shiny

# --- Owner feedback #39: the pet dragon glides with its child ---------------------------------------------------
# Host: a pet of a species that flies (AnimalRules.SPECIES "flies": the dragon) takes off when its child is up in the
# air above it and flies beside them (PetRules.glides, glide_spot, glide_velocity), landing when they land. The
# child's "on the ground" is read from the blocks under their feet, the same for the host's own player and a guest's
# (a guest's body is not simulated on the host, so its is_on_floor() says nothing).

var gliding := false
var _glide_yaw := 0.0


func _glide_step(_delta: float) -> bool:
	if not is_pet() or sitting or not bool(AnimalRules.SPECIES.get(species, AnimalRules.NO_SPECIES).get("flies", false)):
		gliding = false
		return false
	var owner := _owner_player()
	if owner == null or not owner.is_spawned():
		gliding = false
		return false
	var above := owner.global_position.y - global_position.y
	if not PetRules.glides(is_on_floor() and not gliding, _stands(owner.global_position), above):
		gliding = false
		return false
	gliding = true
	var flat := Vector2(owner.velocity.x, owner.velocity.z)
	if flat.length() > 1.0:
		_glide_yaw = atan2(-flat.x, -flat.y)
	velocity = PetRules.glide_velocity(global_position, PetRules.glide_spot(owner.global_position, _glide_yaw))
	rotation.y = lerp_angle(rotation.y, _glide_yaw, 0.2)
	move_and_slide()
	return true


## Something solid right under `feet` (standing, or about to land).
func _stands(feet: Vector3) -> bool:
	for dy in [0.2, 1.0]:
		if BlockIds.is_solid(world.get_block(Vector3i((feet - Vector3(0, dy, 0)).floor()))):
			return true
	return false

# --- Owner feedback #41: more animals (spec §14.19) ------------------------------------------------------------
# Swimmers float on the water's top (a duck and its kin), a squirrel runs up tree trunks, a hedgehog curls up,
# penguins and seals belly-slide on ice (every game tilts them), a turtle's egg (the host's AnimalDirector lays and
# hatches it; every game shows it), babies (hatched: small, a higher voice), and a saddled horse or camel that a
# player rides (RideDirector decides; the host moves it here with the rider's stick, RideRules and AnimalRideRules;
# every game puts the rider on its back, Player.riding_animal). A tamed donkey carries a chest of 9 slots (DonkeyChest,
# the host's PetDirector fills and empties it; synced as `chest`).

const TRUNK_CLIMB := 2.4          # m/s up a tree trunk
const FLOAT_DEPTH := 0.3          # a swimmer floats this share of its height under the water's top
const SLIDE_TILT := -1.3          # a belly-slider's tilt (lying forward on its belly)
const EGG_COLOR := Color("f4ecd8")

## The sandstorm's (or snowstorm's) strength 0..1 for ridden horses (the sandbox points it at its storm).
static var storm_source: Callable

## A turtle's egg on the sand (Vector3.INF: none). The host lays and hatches it; synced on change.
var egg_at := Vector3.INF
## Host: seconds since this turtle last laid an egg (AnimalRules.EGG_EVERY between).
var since_egg := 0.0
## A horse's or camel's saddle (a pet's; saved with it). Synced on change: every game shows it.
var saddled := false:
	set(v):
		saddled = v
		ride_kind = AnimalRideRules.kind_of(species, v)
## The player riding it (0: nobody). The host decides (RideDirector); synced, so every game seats that player.
var rider_peer := 0:
	set(v):
		rider_peer = v
		_link_rider()
## A tamed donkey's chest: 9 slots of [id, count] flattened (DonkeyChest). Synced on change.
var chest := PackedInt32Array()
## What it does when ridden (RideRules.Kind: GALLOP, TREK or NONE), from its kind and saddle.
var ride_kind: int = RideRules.Kind.NONE
## Host: the rider's stick (RideRules.clean_wish).
var ride_input := Vector3.ZERO
## Its size in whole blocks, for RideRules' reach and getting-off spots.
var size_blocks := Vector3i.ONE

var baby := false
var _scale := 1.0
var _swimmer := false
var _slider := false
var _tree_climber := false
var _trunk := Vector3.INF
var _curl_t := 0.0
var _sliding := false
var _moving := false
var _tilt := 0.0
var _egg: MeshInstance3D
var _shown_egg := Vector3.INF
var _hatch_fx := false
var _shown_dressed := false
var _rider: Player
var _input_age := INF
var _ride_blocked := false
var _relink_t := 0.0

static var _egg_mesh: ArrayMesh


func _pack_setup(data: Dictionary) -> void:
	baby = bool(data.get("baby", false))
	_scale = 0.55 if baby else 1.0
	_hatch_fx = bool(data.get("hatched", false))
	_swimmer = AnimalRules.swims(species)
	_slider = bool(AnimalRules.SPECIES[species].get("slides", false))
	_tree_climber = AnimalRules.climbs_trees(species)
	size_blocks = AnimalRideRules.size_blocks(species)
	saddled = bool(data.get("saddled", false)) and AnimalRideRules.takes_saddle(species)
	chest = DonkeyChest.clean(data.get("chest", []))


## A tamed donkey wears its packs, a saddled horse or camel its saddle.
func _dressed() -> bool:
	if species == &"donkey":
		return is_pet()
	return saddled


## Host: a hedgehog curls up (sitting, still) for AnimalRules.CURL_TIME.
func _curl() -> void:
	_curl_t = AnimalRules.CURL_TIME
	_dir = Vector3.ZERO
	_flee = 0.0
	sitting = true


## Host, every decision: still curled up? (It uncurls when the time is up.)
func _curled() -> bool:
	if _curl_t <= 0.0:
		return false
	_curl_t -= AI_INTERVAL
	_dir = Vector3.ZERO
	if _curl_t <= 0.0:
		sitting = false
		return false
	return true


func curled_up() -> bool:
	return _curl_t > 0.0


func _water_at_feet() -> bool:
	return world != null and world.get_block(Vector3i((global_position + Vector3(0, 0.1, 0)).floor())) == BlockIds.WATER


## Host: a swimmer in the water floats up to just under the water's top and paddles along.
func _paddle(delta: float) -> void:
	var top := SwimRules.surface_y(global_position, world.get_block)
	var target := top - _size().y * FLOAT_DEPTH
	velocity.y = move_toward(velocity.y, clampf((target - global_position.y) * 3.0, -2.0, 2.0), 8.0 * delta)
	if _dir != Vector3.ZERO and is_on_wall():
		velocity.y = maxf(velocity.y, sqrt(2.0 * GRAVITY * 1.2))   # out onto a bank


## Host: pressed against a tree trunk going its way (a squirrel runs up it).
func _up_a_trunk() -> bool:
	if not _tree_climber or not is_on_wall() or world == null:
		return false
	var ahead := global_position + _dir * (_size().z * 0.5 + 0.3) + Vector3(0, 0.2, 0)
	return AnimalRules.is_trunk(world.get_block(Vector3i(ahead.floor())))


## The trunk of its home tree (found with its den), or INF.
func _trunk_near() -> Vector3:
	if not _trunk.is_finite() and mind:
		_den_spot()
	return _trunk


func sliding() -> bool:
	return _sliding


## Every game: a slider lies on its belly while it moves on ice; a turtle's egg; a hatch's sparkle; the saddle or
## the packs when they come or go; a rider not found yet (still joining) is looked for.
func _pack_show(delta: float) -> void:
	if _hatch_fx and is_inside_tree():
		_hatch_fx = false
		Fx.burst(get_tree().root, global_position + Vector3(0, 0.3, 0), Color("fff3a8"), 14, 2.5, 0.08, 0.7, 1.0)
	if _slider:
		var target := SLIDE_TILT if _sliding else 0.0
		if not is_equal_approx(_tilt, target):
			_tilt = lerpf(_tilt, target, clampf(8.0 * delta, 0.0, 1.0))
			_body.rotation.x = _tilt
	if egg_at != _shown_egg:
		_show_egg()
	if _dressed() != _shown_dressed:
		_shown_dressed = _dressed()
		var mi := _body.get_node_or_null("Body") as MeshInstance3D
		if mi:
			mi.mesh = BlockyAnimal.dressed_mesh_for(species) if _shown_dressed else BlockyAnimal.mesh_for(species)
	if rider_peer != 0 and rider() == null:
		_relink_t -= delta
		if _relink_t <= 0.0:
			_relink_t = 0.1
			_link_rider()


## Every game (with the water look, WATER_CHECK apart): is it a slider moving on ice?
func _look_under() -> void:
	if not _slider or world == null:
		return
	var under := world.get_block(Vector3i((global_position - Vector3(0, 0.1, 0)).floor()))
	_sliding = _moving and AnimalRules.slides_on(species, FrostRules.grip(under))


func _show_egg() -> void:
	_shown_egg = egg_at
	if not egg_at.is_finite():
		if _egg:
			_egg.visible = false
		return
	if _egg == null:
		_egg = MeshInstance3D.new()
		_egg.name = "Egg"
		_egg.mesh = egg_mesh()
		_egg.top_level = true
		_egg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_egg)
	_egg.visible = true
	_egg.position = egg_at   # top_level: a world position (set before or after entering the tree)


## The one shared egg mesh (the animals' vertex-colour material).
static func egg_mesh() -> ArrayMesh:
	if _egg_mesh == null:
		_egg_mesh = BlockyAnimal._build([[Vector3(0, 0.1, 0), Vector3(0.16, 0.2, 0.16), EGG_COLOR],
			[Vector3(0, 0.21, 0), Vector3(0.1, 0.04, 0.1), EGG_COLOR.lightened(0.3)],
			[Vector3(0.04, 0.12, -0.081), Vector3(0.03, 0.03, 0.01), Color("b8a888")]])
	return _egg_mesh

# --- Owner #41: riding a horse or a camel -----------------------------------------------------------------------

## Where the rider's feet go now, in the world.
func seat_position() -> Vector3:
	var local := AnimalRideRules.seat_offset(species)
	return global_transform * local if is_inside_tree() else transform * local


## The player riding it on this game (null for none).
func rider() -> Player:
	return _rider if is_instance_valid(_rider) and _rider.peer_id == rider_peer else null


## Host: `peer` gets on (RideDirector checked it may).
func start_ride(peer: int) -> void:
	rider_peer = peer
	ride_input = Vector3.ZERO
	_input_age = INF
	sitting = false
	_dir = Vector3.ZERO


## Host: the rider is off; it stands where it is (a pet follows its child again).
func end_ride() -> void:
	rider_peer = 0
	ride_input = Vector3.ZERO
	velocity = Vector3(0.0, minf(velocity.y, 0.0), 0.0)


## Host: the rider's stick, as it came from the rider's game.
func set_ride_input(wish: Vector3) -> void:
	ride_input = RideRules.clean_wish(wish)
	_input_age = 0.0


func resting() -> bool:
	return is_on_floor()


## A ridden animal never flies (RideDirector's Survivor landing rule is for dragons).
func was_airborne() -> bool:
	return false


## Every game: puts this game's rider on (or off) its back when rider_peer changes.
func _link_rider() -> void:
	if not is_inside_tree():
		return
	var next: Player = null
	if rider_peer != 0:
		for n in get_tree().get_nodes_in_group(&"players"):
			var p := n as Player
			if p and p.peer_id == rider_peer and not p.is_queued_for_deletion():
				next = p
				break
	if is_instance_valid(_rider) and _rider != next and _rider.riding_animal == self:
		_rider.riding_animal = null
	_rider = next
	if next:
		next.riding_animal = self


## Host, every physics step while ridden: the stick moves it (RideRules.step at its GALLOP or TREK), a camel keeps
## its pace in a sandstorm (a horse slows), it never walks into water or off a big drop (looked at with the
## decisions), gravity, and a hop onto a 1-block step.
func _ride_step(delta: float, _decide_now: bool) -> void:
	_input_age += delta
	var wish := ride_input if _input_age < RideRules.INPUT_STALE else Vector3.ZERO
	var storm := float(storm_source.call()) if storm_source.is_valid() else 0.0
	wish = Vector3(wish.x, 0.0, wish.z) * AnimalRideRules.storm_factor(species, storm)
	var kind := ride_kind if ride_kind != RideRules.Kind.NONE else RideRules.Kind.WALK
	var r := RideRules.step(kind, velocity, rotation.y, wish, 0.0, delta)
	var going := Vector3(r.velocity.x, 0.0, r.velocity.z)
	_ride_blocked = false   # looked at every step (one rider, one mount): a gallop covers a block in 0.1 s
	if going.length() > 0.3 and world != null:
		var ahead := global_position + going.normalized() * (minf(_size().z, 0.9) * 0.5 + 0.5 + going.length() * delta)
		_ride_blocked = not AnimalRideRules.can_ride_step(Vector3i(Vector3(ahead.x, global_position.y + 0.1, ahead.z).floor()),
			world.get_block)
	velocity.x = 0.0 if _ride_blocked else going.x
	velocity.z = 0.0 if _ride_blocked else going.z
	rotation.y = r.yaw
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif is_on_wall() and Vector2(wish.x, wish.z).length() > 0.3:
		velocity.y = sqrt(2.0 * GRAVITY * float(AnimalRules.SPECIES[species].hop))   # up a 1-block step
	move_and_slide()

# --- M3 Task 20b: buddy magic (befriended monsters, bosses' mini-buddies, tricks) --------------------------------
# A befriended monster (BefriendRules.SPECIES) and a boss's mini-buddy (MiniRules.SPECIES) are pets whose `variant`
# is their monster or boss kind: their look is MagicPetModels' shared mesh of that kind, their collar fits it. Every
# pet learns tricks (TrickRules): the host counts its child's emotes near it (BuddyMagicDirector) and every game
# plays the move (do_trick). A world pet's variant and tricks are saved with it (to_save); Pip's, the baby dragon's
# and a mini's tricks live in their child's profile (BuddyMagicData.tricks).

## The kind a befriended monster or a mini-buddy is (&"" for every other animal); sent with the spawn.
var variant: StringName = &""
## Host: its tricks (TrickRules state).
var trick_state := {}


func _t20b_save(d: Dictionary) -> void:
	if variant != &"":
		d.variant = String(variant)
	var learned := TrickRules.learned(trick_state)
	if not learned.is_empty():
		d.tricks = learned


## Host: its tricks from a save entry (WorldMeta.pets) or a profile record ({"tricks": [...]}).
func load_tricks(saved: Dictionary) -> void:
	trick_state = TrickRules.state_from(saved.get("tricks"))


## Host: one emote its child did near it (TrickRules.lesson).
func learn(emote: StringName) -> StringName:
	return TrickRules.lesson(trick_state, emote)


## The collar band of a magic pet sits where its own model is.
func _t20b_fit_collar() -> void:
	if _collar == null or not MagicPetModels.has(species):
		return
	var band := MagicPetModels.collar_for(species, variant)
	_collar.position = band[0]
	(_collar.mesh as BoxMesh).size = band[1]


## Every game: a trick (TrickRules move) its child just did with it.
func do_trick(move: StringName) -> void:
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = create_tween()
	match move:
		TrickRules.DANCE:
			for i in 2:
				_anim.tween_property(_body, "rotation:z", 0.3, 0.14).set_trans(Tween.TRANS_SINE)
				_anim.parallel().tween_property(_body, "position:y", 0.3, 0.14).set_trans(Tween.TRANS_QUAD)
				_anim.tween_property(_body, "rotation:z", -0.3, 0.14).set_trans(Tween.TRANS_SINE)
				_anim.parallel().tween_property(_body, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE)
			_anim.tween_property(_body, "rotation:z", 0.0, 0.1)
		TrickRules.SPIN:
			_anim.tween_property(_body, "rotation:y", _body.rotation.y + TAU, 0.5).set_trans(Tween.TRANS_BACK)
			_anim.parallel().tween_property(_body, "position:y", 0.4, 0.22).set_trans(Tween.TRANS_QUAD)
			_anim.tween_property(_body, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE)
		TrickRules.WAVE:
			for i in 3:
				_anim.tween_property(_body, "rotation:z", 0.25, 0.1).set_trans(Tween.TRANS_SINE)
				_anim.tween_property(_body, "rotation:z", -0.25, 0.1).set_trans(Tween.TRANS_SINE)
			_anim.tween_property(_body, "rotation:z", 0.0, 0.08)
		TrickRules.HOP:
			for i in 2:
				_anim.tween_property(_body, "position:y", 0.35, 0.13).set_trans(Tween.TRANS_QUAD)
				_anim.tween_property(_body, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_BOUNCE)
		TrickRules.SIT:
			_anim.tween_property(_body, "rotation:x", -0.35, 0.2)
			_anim.tween_interval(1.0)
			_anim.tween_property(_body, "rotation:x", 0.0, 0.25)
		_:   # BOW
			_anim.tween_property(_body, "rotation:x", 0.45, 0.22)
			_anim.tween_interval(0.3)
			_anim.tween_property(_body, "rotation:x", 0.0, 0.3)
