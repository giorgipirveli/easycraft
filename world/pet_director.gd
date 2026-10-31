class_name PetDirector
extends Node
## Pets with perks (M3 Task 11, spec §14.7), node "Pets" in the sandbox on every game.
## Host: five times a second the perks of every tamed pet near its child (PetPerks: the dog barks at a monster
## coming within 16 blocks and pulls coins within 4 blocks to its child; the parrot points at the nearest
## secret nobody found; the fox and the dog sniff for treasure themselves, Animal._sniff_treasure), the heart
## falling slowly while its child plays; and the children's requests (Session section "M3 Task 11"): treats
## (they tame foxes and parrots, raise a pet's heart and teach its mind; Survivor pays one), pats, names,
## collars, and Pip coming along from a child's profile (and going home with a guest who leaves).
## Every game: ONE shared light on the glowing pet nearest this game's player in caves and at night (never a
## light per pet), the parrot squawking this game's own player's words (PetEcho; never sent, never others'),
## and this game's Pip kept in the profile (he follows the child between worlds: PetRules).

const TICK := 0.2
const GLOW_EVERY := 0.2           # this game looks for the pet to light this often; the light follows it every frame
const GLOW_ENERGY := 1.4
const GLOW_RANGE := 7.0
const GLOW_FADE := 3.0            # energy per second
const GLOW_WARM := Color("ffd9a0")   # a cat's soft glow
const GLOW_COOL := Color("bfe6ff")   # Pip's lamp
const ECHO_DELAY := 1.2           # the parrot repeats a line this long after its child said it
const ECHO_NEAR := 16.0
const ECHO_EVERY := Vector2(45.0, 90.0)   # and now and then one of the lines it knows
const PIP_RECORD_EVERY := 2.0
const PIP_OFFSET := Vector3(1.5, 0.5, 1.0)

# --- Host ---
var animals: Node                 # the sandbox's Animals (every game)
## () -> Array: the monsters' coins lying about (MonsterDirector.coins).
var coins: Callable = func() -> Array: return []
## (pos, radius) -> Array[Vector3]: where the secrets nobody found are, near pos.
var secrets_near: Callable = func(_pos: Vector3, _radius: float) -> Array[Vector3]: return [] as Array[Vector3]
## (peer, item) -> bool: Survivor takes one treat from that child's bag (false: they have none); Sandbox: true.
var take_treat: Callable = func(_peer: int, _item: int) -> bool: return true
## Owner #41, a donkey's chest: (peer, id) -> how many that child holds (Sandbox: a full slot's worth), (peer, id,
## n) -> bool takes them from the bag (Sandbox: true), (peer, id, n) -> int gives them back (how many fit).
var bag_count: Callable = func(_peer: int, _id: int) -> int: return DonkeyChest.SLOT_MAX
var take_items: Callable = func(_peer: int, _id: int, _n: int) -> bool: return true
var give_items: Callable = func(_peer: int, _id: int, n: int) -> int: return n
## (data) -> Animal: the sandbox's animal spawner (Pip).
var spawn: Callable
var band_of: Callable = func(peer: int) -> StringName: return Session.pet_band_of(peer)
var tell: Callable = func(peer: int, text: String) -> void: Session.send_feedback(peer, text)
var now: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
var auto_tick := true

# --- This game ---
var local_player: Player
var underground: Callable = func() -> float: return 0.0   # Ambience.underground
var is_night: Callable = func() -> bool: return false
var profile: ProfileData = Profile.data
var save_profile: Callable = func() -> void: Profile.save()
var echo := PetEcho.new()
var glow := OmniLight3D.new()

var _t := 0.0
var _glow_t := 0.0
var _glow_pet: Animal
var _echo_due := -1.0
var _echo_line := ""
var _echo_next := 0.0
var _record_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	glow.name = "PetGlow"
	glow.shadow_enabled = false
	glow.omni_range = GLOW_RANGE
	glow.light_energy = 0.0
	glow.light_color = GLOW_WARM
	glow.visible = false
	add_child(glow)
	_rng.randomize()
	_echo_next = _rng.randf_range(ECHO_EVERY.x, ECHO_EVERY.y)


func _process(delta: float) -> void:
	if not auto_tick:
		return
	if multiplayer.is_server():
		_t += delta
		if _t >= TICK:
			host_tick(_t)
			_t = 0.0
	if local_player:
		local_tick(delta)


## Host and solo: the children's requests.
func start_host() -> void:
	Session.pet_treat_requested.connect(on_treat)
	Session.pet_pat_requested.connect(on_pat)
	Session.pet_name_requested.connect(on_name)
	Session.pet_collar_requested.connect(on_collar)
	Session.pip_requested.connect(on_pip)
	Session.peer_left.connect(on_peer_left)
	Session.baby_dragon_requested.connect(on_baby_dragon)   # owner 39
	Session.peer_left.connect(baby_dragon_left)
	Session.pet_saddle_requested.connect(on_saddle)   # owner #41
	Session.pet_chest_put_requested.connect(on_chest_put)
	Session.pet_chest_take_requested.connect(on_chest_take)


func _exit_tree() -> void:
	for pair: Array in [[Session.pet_treat_requested, on_treat], [Session.pet_pat_requested, on_pat],
			[Session.pet_name_requested, on_name], [Session.pet_collar_requested, on_collar],
			[Session.pip_requested, on_pip], [Session.peer_left, on_peer_left],
			[Session.baby_dragon_requested, on_baby_dragon], [Session.peer_left, baby_dragon_left],   # owner 39
			[Session.pet_saddle_requested, on_saddle], [Session.pet_chest_put_requested, on_chest_put],
			[Session.pet_chest_take_requested, on_chest_take]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])

# --- Host: perks and the heart ---

## Host, every TICK: the hearts of pets whose child plays, the dogs' barks and coins, the parrots' pointing.
func host_tick(dt: float) -> void:
	var players := _players_by_peer()
	var dogs: Array[Vector3] = []
	var owners: Array[int] = []
	var monsters := {}
	var looked := false
	var t := float(now.call())
	for a in all_pets():
		var owner: Player = players.get(a.owner_peer)
		if owner == null:
			continue                     # waiting for its child: never sadder (PetRules)
		a.pet_tick(dt)
		if not PetPerks.active(true, a.global_position, owner.global_position):
			continue
		if PetRules.has_perk(a.species, PetRules.BARK):
			if not looked:
				monsters = _monster_spots()
				looked = true
			var r := PetPerks.bark(a.global_position, monsters, a.bark_known, t, a.bark_last)
			a.bark_known = r.known
			if r.bark:
				a.bark()
				a.bark_last = t
		if PetRules.has_perk(a.species, PetRules.COINS):
			dogs.append(a.global_position)
			owners.append(a.owner_peer)
		if PetRules.has_perk(a.species, PetRules.POINT) and not a.sitting:
			a.point_t -= dt
			if a.point_t <= 0.0:
				a.point_t = PetPerks.POINT_EVERY
				var target := PetPerks.point_target(a.global_position, secrets_near.call(a.global_position, PetPerks.POINT_RANGE))
				if target.is_finite():
					a.point_at(target)
	if not dogs.is_empty():
		_pull_coins(dogs, owners)


func _pull_coins(dogs: Array[Vector3], owners: Array[int]) -> void:
	for n: Variant in coins.call():
		var c := n as Coin
		if c == null or not is_instance_valid(c) or c.is_queued_for_deletion() or c.collector != 0 or not c.is_landed():
			continue
		var peer := PetPerks.coin_owner(c.global_position, dogs, owners)
		if peer != 0:
			c.collector = peer           # it flies to that child and pays them (Coin, M2 Task 4)


func _monster_spots() -> Dictionary:
	var out := {}
	for n in get_tree().get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m and not m.is_queued_for_deletion():
			out[m.get_instance_id()] = m.global_position
	return out


func _players_by_peer() -> Dictionary:
	var out := {}
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.is_spawned() and not p.is_queued_for_deletion():
			out[p.peer_id] = p
	return out


## Every tamed pet in the world.
func all_pets() -> Array[Animal]:
	var out: Array[Animal] = []
	if animals == null:
		return out
	for n in animals.get_children():
		var a := n as Animal
		if a and a.is_pet() and not a.is_queued_for_deletion():
			out.append(a)
	return out


func pets_of(peer: int) -> Array[Animal]:
	var out: Array[Animal] = []
	for a in all_pets():
		if a.owner_peer == peer:
			out.append(a)
	return out


## How many of `peer`'s pets count toward AnimalRules.MAX_PETS (Pip never does).
func pets_owned(peer: int) -> int:
	var n := 0
	for a in pets_of(peer):
		if PetRules.counts_toward_cap(a.species):
			n += 1
	return n

# --- Host: requests ---

## The animal called `animal_name` within reach of `peer`'s player (like petting), or null.
func _reachable(peer: int, animal_name: String) -> Animal:
	if animals == null:
		return null
	var a := animals.get_node_or_null(NodePath(animal_name)) as Animal
	var p := Session._player_for_peer(peer)
	if a == null or p == null or a.is_queued_for_deletion():
		return null
	if not PlacementRules.in_reach(p.eye_position(), Vector3i(a.global_position.floor()),
			PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		return null
	return a


func on_treat(peer: int, animal_name: String, item: int) -> void:
	if not PetRules.is_treat(item):
		return
	var a := _reachable(peer, animal_name)
	if a != null and not a.golden and not PetRules.is_pet_kind(a.species):
		_feed_wild(peer, a, item)   # owner #41: a penguin's fish snack, a squirrel's seeds
		return
	if a == null or a.golden or not PetRules.is_pet_kind(a.species):
		return
	if not a.is_pet() and PetRules.tames_by_treats(a.species) and not AnimalRules.can_tame(a.species, pets_owned(peer)):
		tell.call(peer, tr("You already have %d pets!") % AnimalRules.MAX_PETS)
		return
	if not take_treat.call(peer, item):
		return                           # Survivor: none left in the bag
	var p := Session._player_for_peer(peer)
	var what := a.treat(peer, item, pets_owned(peer))
	if what == &"":
		return
	a.mind_fed(p)                        # M2 Task 18's reward: it likes this child more, its mind learns
	Session.progress_tell(peer, StringName("%s/%s" % [LevelRules.FED, a.species]))   # owner #45a: a treat given
	match what:
		&"tamed":
			a.cheer(true)
			Session.progress_tell(peer, StringName("%s/%s" % [LevelRules.TAMED, a.species]))   # M3 Task 12
			tell.call(peer, tr("%s is your pet now! Tap %s to see its card.") % [a.pet_name, a.pet_name])
		&"liked":
			if PetRules.tames_by_treats(a.species):
				tell.call(peer, tr("The %s loves it! One more treat…") % tr(String(a.species).replace("_", " ")))   # owner #41: "arctic fox"; M3 Task 21a


func on_pat(peer: int, animal_name: String) -> void:
	var a := _reachable(peer, animal_name)
	if a == null or not a.is_pet():
		return
	if a.pat(float(now.call())):
		a.mind_petted(Session._player_for_peer(peer))


func on_name(peer: int, animal_name: String, pet_name: String) -> void:
	var a := _own_pet(peer, animal_name)
	if a == null:
		return
	var why := PetRules.name_refusal(pet_name, band_of.call(peer))
	if why != "":
		tell.call(peer, PetRules.name_message(why))
		return
	a.pet_name = PetRules.clean_name(pet_name)
	tell.call(peer, tr("Hello, %s!") % a.pet_name)


func on_collar(peer: int, animal_name: String, collar: int) -> void:
	var a := _own_pet(peer, animal_name)
	if a and PetRules.valid_collar(collar):
		a.collar = collar


func _own_pet(peer: int, animal_name: String) -> Animal:
	if animals == null:
		return null
	var a := animals.get_node_or_null(NodePath(animal_name)) as Animal
	return a if a and a.is_pet() and a.owner_peer == peer and not a.is_queued_for_deletion() else null


## Host: `peer`'s Pip comes along (their profile's record, cleaned), next to their player; never two.
func on_pip(peer: int, record: Dictionary) -> void:
	var clean := PetRules.clean_pip(record)
	var p := Session._player_for_peer(peer)
	if clean.is_empty() or p == null or not p.is_spawned() or pip_of(peer) != null or not spawn.is_valid():
		return
	spawn.call({"species": PetRules.PIP, "id": "pip_%d" % peer, "pos": p.global_position + PIP_OFFSET, "yaw": 0.0,
		"owner": peer, "name": clean.name, "sitting": false, "collar": clean.collar, "happiness": clean.happiness})


func pip_of(peer: int) -> Animal:
	for a in pets_of(peer):
		if a.species == PetRules.PIP:
			return a
	return null


## Host: a guest left: their Pip goes home with them (he lives in their profile); their other pets wait (M1b).
func on_peer_left(peer: int) -> void:
	var pip := pip_of(peer)
	if pip:
		pip.queue_free()

# --- This game: the glow, the parrot's words, Pip's record ---

## Every game, every frame: the shared light and the parrot's words.
func local_tick(delta: float) -> void:
	_glow_t -= delta
	if _glow_t <= 0.0:
		_glow_t = GLOW_EVERY
		_glow_pet = _pick_glow()
		if _glow_pet:
			glow.light_color = GLOW_COOL if _glow_pet.species == PetRules.PIP else GLOW_WARM
	_move_glow(delta)
	_echo_tick(delta)
	_record_t -= delta
	if _record_t <= 0.0:
		_record_t = PIP_RECORD_EVERY
		keep_pip_record()
		keep_baby_dragon_record()   # owner 39


func glow_target() -> Animal:
	return _glow_pet if is_instance_valid(_glow_pet) else null


## The glowing pet (a cat or Pip whose perk works: near its child) nearest this game's player, when it is
## dark here (a cave or the night); null otherwise.
func _pick_glow() -> Animal:
	if not is_instance_valid(local_player) or not local_player.is_spawned():
		return null
	var dark := float(underground.call())
	var night := bool(is_night.call())
	var players := _players_by_peer()
	var list: Array[Animal] = []
	var spots: Array[Vector3] = []
	for a in all_pets():
		var owner: Player = players.get(a.owner_peer)
		if owner and PetPerks.glows(a.species, dark, night) and PetPerks.active(true, a.global_position, owner.global_position):
			list.append(a)
			spots.append(a.global_position)
	var i := PetPerks.glow_pick(local_player.global_position, spots)
	return list[i] if i >= 0 else null


func _move_glow(delta: float) -> void:
	var target := glow_target()
	var want := GLOW_ENERGY if target else 0.0
	glow.light_energy = move_toward(glow.light_energy, want, GLOW_FADE * delta)
	glow.visible = glow.light_energy > 0.01
	if target:
		glow.global_position = target.global_position + Vector3(0, AnimalRules.SPECIES[target.species].size.y + 0.4, 0)


## This game's player said `text` (typed or a quick phrase: ChatPanel.own_line_sent). The parrot learns it
## (only this player's own words, PetEcho) and repeats it a moment later. Nothing is sent anywhere.
func hear_own(text: String) -> void:
	if not is_instance_valid(local_player):
		return
	if echo.hear_own(text, local_player.peer_id, local_player.peer_id):
		_echo_line = echo.lines()[-1]
		_echo_due = ECHO_DELAY


func _echo_tick(delta: float) -> void:
	if _echo_due >= 0.0:
		_echo_due -= delta
		if _echo_due < 0.0:
			_squawk(tr(PetEcho.SQUAWK) % _echo_line)
		return
	_echo_next -= delta
	if _echo_next <= 0.0:
		_echo_next = _rng.randf_range(ECHO_EVERY.x, ECHO_EVERY.y)
		_squawk(echo.squawk(_rng.randf()))


## My own parrots near me say it (on this game only).
func _squawk(text: String) -> void:
	if text == "" or not is_instance_valid(local_player):
		return
	for a in pets_of(local_player.peer_id):
		if PetRules.has_perk(a.species, PetRules.ECHO) and a.global_position.distance_to(local_player.global_position) <= ECHO_NEAR:
			a.squawk_line(text)
			BabbleVoices.say(a, &"pet", 1.0, text, true, str(a.name))   # M3 Task 21a: the parrot babbles it back


## This game's Pip (when the child has him: PetRules.give_pip) keeps his name, collar and heart in the
## profile, saved when they change. A Pip summoned without one is a visitor and is not kept.
func keep_pip_record() -> void:
	if profile == null or profile.pip.is_empty() or not is_instance_valid(local_player):
		return
	var pip := pip_of(local_player.peer_id)
	if pip == null:
		return
	var record := PetRules.pip_record(pip.pet_name, pip.collar, pip.happiness)
	if record != profile.pip:
		profile.pip = record
		save_profile.call()


## This game's player brings their Pip (once they stand in the world).
func bring_pip() -> void:
	if profile and not profile.pip.is_empty():
		Session.pet_request_pip(profile.pip)

# --- Owner feedback #39: the Sky Dragon's baby dragon (it lives in the profile, like Pip) ----------------------

const BABY_DRAGON_PREFIX := "babydragon_"
const BABY_DRAGON_OFFSET := Vector3(-1.5, 0.5, 1.0)


## A pet that lives in a child's profile, never in a world's save (Pip, the baby dragon).
static func is_profile_pet(animal_id: String) -> bool:
	return animal_id.begins_with(BABY_DRAGON_PREFIX) or animal_id.begins_with("pip_") \
		or MiniRules.kind_of_id(animal_id) != &""   # M3 Task 20b: a boss's mini-buddy


## Host: `peer`'s baby dragon comes along (their profile's record, cleaned), next to their player; never two.
func on_baby_dragon(peer: int, record: Dictionary) -> void:
	var clean := PetRules.clean_pip(record)
	var p := Session._player_for_peer(peer)
	if clean.is_empty() or p == null or not p.is_spawned() or baby_dragon_of(peer) != null or not spawn.is_valid():
		return
	spawn.call({"species": PetRules.DRAGON, "id": BABY_DRAGON_PREFIX + str(peer), "pos": p.global_position + BABY_DRAGON_OFFSET,
		"yaw": 0.0, "owner": peer, "name": clean.name, "sitting": false, "collar": clean.collar, "happiness": clean.happiness})


func baby_dragon_of(peer: int) -> Animal:
	for a in pets_of(peer):
		if String(a.name).begins_with(BABY_DRAGON_PREFIX):
			return a
	return null


## This game's player brings their baby dragon (once they stand in the world).
func bring_baby_dragon() -> void:
	if profile and not profile.baby_dragon.is_empty():
		Session.pet_request_baby_dragon(profile.baby_dragon)


## This game's baby dragon keeps its name, collar and heart in the profile, saved when they change.
func keep_baby_dragon_record() -> void:
	if profile == null or profile.baby_dragon.is_empty() or not is_instance_valid(local_player):
		return
	var d := baby_dragon_of(local_player.peer_id)
	if d == null:
		return
	var record := PetRules.pip_record(d.pet_name, d.collar, d.happiness)
	record.name = PetRules.saved_name(d.pet_name, PetRules.DRAGON, "babydragon")
	if record != profile.baby_dragon:
		profile.baby_dragon = record
		save_profile.call()


## Host: a guest left: their baby dragon goes home with them.
func baby_dragon_left(peer: int) -> void:
	var d := baby_dragon_of(peer)
	if d:
		d.queue_free()

# --- Owner feedback #41: saddles, a donkey's chest, feeding the wild ones (spec §14.19) ---------------------

## Host: a treat for a wild animal that is never a pet (a penguin's fish snack): if it eats it (AnimalFood), the
## child pays one (Survivor) and the animal likes them more (M2 Task 18's mind); a treat it doesn't eat is kept.
func _feed_wild(peer: int, a: Animal, item: int) -> void:
	if not AnimalFood.eats(a.species, item) or a.mind == null:
		return
	if not take_treat.call(peer, item):
		return
	a.mind_fed(Session._player_for_peer(peer))


## Host: `peer` taps their own tamed horse or camel holding a SADDLE: it wears it from now on (Survivor pays one).
func on_saddle(peer: int, animal_name: String) -> void:
	var a := _reachable(peer, animal_name)
	if a == null or not AnimalRideRules.takes_saddle(a.species) or a.saddled:
		return
	if not a.is_pet() or a.owner_peer != peer:
		tell.call(peer, "Tame it first: two treats!" if not a.is_pet() else tr("That's a friend's %s.") % tr(String(a.species)))
		return
	if not take_treat.call(peer, AnimalRideRules.SADDLE):
		tell.call(peer, "You need a saddle! Tilly sells them.")
		return
	a.saddled = true
	a.cheer()
	tell.call(peer, tr("%s has a saddle! Stand close and press RIDE.") % a.pet_name)


## Host: `peer` puts all of their held `item` that fits into their own donkey's chest.
func on_chest_put(peer: int, animal_name: String, item: int) -> void:
	var a := _own_pet(peer, animal_name)
	if a == null or not PetRules.has_perk(a.species, PetRules.CHEST) or not Inventory.ownable(item):
		return
	var n := mini(int(bag_count.call(peer, item)), DonkeyChest.room_for(a.chest, item))
	if n <= 0:
		return
	if not take_items.call(peer, item, n):
		return
	a.chest = DonkeyChest.put(a.chest, item, n).chest


## Host: `peer` takes slot `slot` of their own donkey's chest back into their bag (what doesn't fit stays).
func on_chest_take(peer: int, animal_name: String, slot: int) -> void:
	var a := _own_pet(peer, animal_name)
	if a == null or not PetRules.has_perk(a.species, PetRules.CHEST):
		return
	var s := DonkeyChest.slot(a.chest, slot)
	if s.y <= 0:
		return
	var r := DonkeyChest.take(a.chest, slot)
	var given := int(give_items.call(peer, s.x, s.y))
	var chest: PackedInt32Array = r.chest
	if given < s.y:
		chest = DonkeyChest.put(chest, s.x, s.y - given).chest   # the bag was full: the rest stays
	a.chest = chest
