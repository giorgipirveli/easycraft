class_name BuddyMagicDirector
extends Node
## Buddy magic (M3 Task 20b, spec §14.21), node "BuddyMagic" in the sandbox on every game.
## Host: a woken buddy goes into its child's Buddy Album (and a secret shape into their book: host_buddy_woken);
## a wand tap on a calm monster of level 1-2 makes it that child's pet friend (on_befriend, BefriendRules: it
## becomes a BefriendRules.SPECIES pet with its kind as the variant, and hearts); a beaten boss gives every child
## there its tiny version once (host_boss_won -> each child's game keeps it in the profile and asks for it:
## on_mini, like Pip); a child's emote near their own buddies and pets is a lesson, three make a trick, and a
## known trick is done with them (on_emote, TrickRules; the move on every game by one reliable RPC).
## This game: what the host tells it goes into its own profile (the album, secret shapes, minis, profile pets'
## tricks), its minis come along when it arrives, their records and their tricks are kept.

const WOKEN := &"woken"           # {name, recipe, pic, u}: a buddy this child woke
const MINI := &"mini"             # {kind}: a boss this child was there for was beaten
const TRICK := &"trick"           # {key, emote}: a profile pet of this child learned a trick
const KEEP_EVERY := 2.0           # this game keeps its minis' records this often
const MINI_SIDE := 1.6            # a mini comes next to its child, each one a little further round
const HOP_OUT_TIME := 60.0        # a mini asked for this soon after its boss fell hops out of the boss's spot
const SECRET_SOUND := &"jingle_goal"
const HEARTS := Color("ff5c8a")
## This game's own words (a shape in the book, a mini) wait this long: a toast replaces the one showing, and the
## host's line ("A secret shape! ... is alive!", a boss's "A portal opened!") comes at the same moment.
const SAY_LATER := 2.8

## The sandbox's Buddies and Animals (every game).
var buddies_root: Node
var animals_root: Node

# --- Host ---
## The sandbox's PetDirector (pets_owned, spawn: the animal spawner).
var pets: PetDirector
## () -> Array: the monsters in the world (MonsterDirector.monsters()).
var monsters: Callable = func() -> Array: return []
var mode: Callable = func() -> StringName: return Game.mode
var tell: Callable = func(peer: int, text: String) -> void: Session.send_feedback(peer, text)
## (peer, kind, info): tells one player's own game (Session.buddy_magic_tell).
var tell_game: Callable = func(peer: int, kind: StringName, info: Dictionary) -> void: Session.buddy_magic_tell(peer, kind, info)
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

var _last_win := {}               # host: {kind, at, t} of the last boss beaten

# --- This game ---
var local_player: Player
var profile: ProfileData = Profile.data
var save_profile: Callable = func() -> void: Profile.save()
var toast: Callable = func(text: String) -> void: Session.magic_feedback.emit(text)
var progress: Callable = func(kind: StringName) -> void: Progress.event(kind)
var universe: Callable = func() -> int: return Game.universe
var now_unix: Callable = func() -> int: return int(Time.get_unix_time_from_system())
var say_delay := SAY_LATER
## Trick moves this game played ([kind, name, move]) and hearts shown (tests).
var shown: Array = []

var _keep_t := 0.0
var _restored := {}               # this game: profile pets whose tricks were sent back to the host


func _process(delta: float) -> void:
	if local_player == null:
		return
	_keep_t -= delta
	if _keep_t <= 0.0:
		_keep_t = KEEP_EVERY
		local_tick()


## Host and solo: the children's requests and emotes.
func start_host() -> void:
	Session.emote_played.connect(on_emote)
	Session.befriend_requested.connect(on_befriend)
	Session.mini_requested.connect(on_mini)
	Session.pet_tricks_requested.connect(on_pet_tricks)
	Session.peer_left.connect(on_peer_left)


## Every game: what the host tells it for its own profile.
func setup_local(player: Player) -> void:
	local_player = player
	Session.buddy_magic_told.connect(on_told)


func _exit_tree() -> void:
	for pair: Array in [[Session.emote_played, on_emote], [Session.befriend_requested, on_befriend],
			[Session.mini_requested, on_mini], [Session.pet_tricks_requested, on_pet_tricks],
			[Session.peer_left, on_peer_left], [Session.buddy_magic_told, on_told]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])

# --- Host: buddies woken ---

## The name a woken build gets: a secret shape's own name, else BuddyNames'.
static func name_for(blocks: Dictionary) -> String:
	var r := BuddyRecipes.recipe(BuddyRecipes.match_blocks(blocks))
	return str(r.name) if not r.is_empty() else BuddyNames.name_for(blocks)


## The words when a secret shape wakes.
static func secret_words(recipe: StringName, buddy_name: String) -> String:
	return Lang.t("A secret shape! %s the %s is alive!") % [buddy_name, Lang.t(BuddyRecipes.recipe(recipe).title)]


## Host: `peer` woke `buddy`: into their album (and their book, for a secret shape); a secret shape's reveal on
## every game.
func host_buddy_woken(peer: int, buddy: Buddy) -> void:
	if buddy == null:
		return
	tell_game.call(peer, WOKEN, {"name": buddy.buddy_name, "recipe": String(buddy.recipe),
		"pic": BuddyPicture.code_of(buddy.blocks), "u": int(universe.call())})
	if buddy.recipe != &"":
		var at := buddy.position + Vector3(0, buddy.size_blocks.y * 0.5, 0)
		_rpc_reveal.rpc(at, BuddyRecipes.recipe(buddy.recipe).color)

# --- Host: befriending ---

## Host: `peer` tapped the monster `monster_name` with the wand.
func on_befriend(peer: int, monster_name: String) -> void:
	var m: Monster = null
	for n: Variant in monsters.call():
		if n is Monster and is_instance_valid(n) and not (n as Monster).is_queued_for_deletion() \
				and String((n as Monster).name) == monster_name:
			m = n
	var p := Session._player_for_peer(peer)
	if m == null or p == null:
		return
	if not PlacementRules.in_reach(p.eye_position(), Vector3i(m.global_position.floor()),
			PlacementRules.REACH + PlacementRules.REACH_TOLERANCE + 1.0):
		tell.call(peer, BefriendRules.message(BefriendRules.TOO_FAR))
		return
	var no_pets := pets == null or not pets.spawn.is_valid()
	var why := BefriendRules.refusal(m.level, m.state == Monster.State.CHASE or m.state == Monster.State.WINDUP,
		false, m.wave, m.golden, ModeRules.WAVE if no_pets else mode.call(), pets.pets_owned(peer) if pets else 0)
	if why != BefriendRules.OK:
		tell.call(peer, BefriendRules.message(why))
		return
	var id := "friend_%s" % m.monster_id
	var friend_name := BefriendRules.friend_name(id)
	var at := m.global_position
	pets.spawn.call({"species": BefriendRules.SPECIES, "variant": String(m.kind), "id": id, "pos": at,
		"yaw": m.rotation.y, "owner": peer, "name": friend_name, "sitting": false})
	m.queue_free()
	_rpc_hearts.rpc(at + Vector3(0, 0.8, 0))
	tell.call(peer, BefriendRules.words(friend_name))
	Session.progress_tell(peer, StringName("%s/%s" % [LevelRules.TAMED, BefriendRules.SPECIES]))

# --- Host: bosses' mini-buddies ---

## Host: a boss of `kind` was beaten at `at`: every player there gets its tiny version (their game keeps it once).
func host_boss_won(kind: StringName, at: Vector3) -> void:
	if not MiniRules.gives_mini(kind):
		return
	_last_win = {"kind": kind, "at": at, "t": float(clock.call())}
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			tell_game.call(p.peer_id, MINI, {"kind": String(kind)})


## Host: `peer`'s mini of `kind` comes along (their profile's record), next to them; never two of a kind. Asked
## right after its boss fell, it hops out of the boss's spot.
func on_mini(peer: int, kind: StringName, record: Dictionary, tricks: Array) -> void:
	if not MiniRules.gives_mini(kind) or pets == null or not pets.spawn.is_valid() or mini_of(peer, kind) != null:
		return
	var p := Session._player_for_peer(peer)
	if p == null or not p.is_spawned():
		return
	var clean := PetRules.clean_pip(record)
	if clean.is_empty():
		clean = MiniRules.record(kind)
	var i := MiniRules.MINIS.keys().find(kind)
	var at := p.global_position + Vector3(MINI_SIDE, 0.5, 0.0).rotated(Vector3.UP, 0.9 * (i + 1))
	var hops_out: bool = _last_win.get("kind", &"") == kind and float(clock.call()) - float(_last_win.get("t", -INF)) < HOP_OUT_TIME
	if hops_out:
		at = _last_win.at
	var id := MiniRules.animal_id(kind, peer)
	var a := pets.spawn.call({"species": MiniRules.SPECIES, "variant": String(kind), "id": id, "pos": at, "yaw": 0.0,
		"owner": peer, "name": PetRules.saved_name(str(clean.name), MiniRules.SPECIES, id), "sitting": false,
		"collar": clean.collar, "happiness": clean.happiness}) as Animal
	if a:
		a.load_tricks({"tricks": tricks})
	if hops_out:
		_rpc_hearts.rpc(at)


func mini_of(peer: int, kind: StringName) -> Animal:
	if animals_root == null:
		return null
	return animals_root.get_node_or_null(MiniRules.animal_id(kind, peer)) as Animal


## Host: a guest left: their minis go home with them (they live in their profile).
func on_peer_left(peer: int) -> void:
	for kind: StringName in MiniRules.MINIS:
		var a := mini_of(peer, kind)
		if a:
			a.queue_free()

# --- Host: tricks ---

## Host: `peer` did `emote`: a lesson for each of their own buddies and pets near them (TrickRules); a creature
## that knows it does its move with them on every game.
func on_emote(peer: int, emote: StringName) -> void:
	var p := Session._player_for_peer(peer)
	if p == null or not EmotePoses.has(emote):
		return
	var learned: Array[String] = []
	var watching := ""
	var lessons := 0
	for c: Node3D in creatures_of(peer):
		if c.global_position.distance_to(p.global_position) > TrickRules.TEACH_RANGE:
			continue
		var r: StringName = c.call(&"learn", emote)
		var nm := _name_of(c)
		if r == TrickRules.KNOWN or r == TrickRules.LEARNED:
			_rpc_trick.rpc(1 if c is Animal else 0, String(c.name), TrickRules.move_of(emote))
		if r == TrickRules.LEARNED:
			learned.append(nm)
			_rpc_hearts.rpc(c.global_position + Vector3(0, 1.0, 0))
			var key := profile_key(String(c.name))
			if key != "":
				tell_game.call(peer, TRICK, {"key": key, "emote": String(emote)})
		elif r == TrickRules.PRACTICE:
			var n := TrickRules.lessons_of(c.get(&"trick_state"), emote)
			if n > lessons:
				lessons = n
				watching = nm
	if not learned.is_empty():
		var who := learned[0] if learned.size() == 1 else tr("%s and %s") % [", ".join(learned.slice(0, -1)), learned[-1]]
		tell.call(peer, TrickRules.learned_words(who, emote))
	elif watching != "":
		tell.call(peer, TrickRules.practice_words(watching, lessons))


## Host: `peer`'s own buddies and pets (every one: plain, special, friends, minis, Pip).
func creatures_of(peer: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for root: Node in [buddies_root, animals_root]:
		if root == null:
			continue
		for n in root.get_children():
			if n is Buddy and (n as Buddy).owner_peer == peer and not (n as Buddy).visiting and not n.is_queued_for_deletion():
				out.append(n)
			elif n is Animal and (n as Animal).is_pet() and (n as Animal).owner_peer == peer and not n.is_queued_for_deletion():
				out.append(n)
	return out


static func _name_of(c: Node) -> String:
	return (c as Buddy).buddy_name if c is Buddy else (c as Animal).pet_name


## The profile's trick key of a profile pet's animal id ("pip", "baby_dragon", "mini_golem"), "" for a world pet.
static func profile_key(animal_id: String) -> String:
	if animal_id.begins_with("pip_"):
		return "pip"
	if animal_id.begins_with(PetDirector.BABY_DRAGON_PREFIX):
		return "baby_dragon"
	var kind := MiniRules.kind_of_id(animal_id)
	return MiniRules.trick_key(kind) if kind != &"" else ""


## Host: `peer` sends back the tricks their profile pet `animal_name` knows (Pip, the baby dragon).
func on_pet_tricks(peer: int, animal_name: String, tricks: Array) -> void:
	if animals_root == null:
		return
	var a := animals_root.get_node_or_null(NodePath(animal_name)) as Animal
	if a == null or a.owner_peer != peer or profile_key(animal_name) == "":
		return
	var all := TrickRules.learned(a.trick_state) + TrickRules.clean(tricks)
	a.load_tricks({"tricks": all})

# --- Every game ---

@rpc("authority", "call_local", "reliable")
func _rpc_trick(kind: int, creature_name: String, move: StringName) -> void:
	shown.append([kind, creature_name, move])
	var root := animals_root if kind == 1 else buddies_root
	var c := root.get_node_or_null(NodePath(creature_name)) if root else null
	if c and c.has_method(&"do_trick"):
		c.call(&"do_trick", move)


@rpc("authority", "call_local", "reliable")
func _rpc_hearts(at: Vector3) -> void:
	shown.append(["hearts", at])
	if not is_inside_tree() or not at.is_finite():
		return
	Fx.burst(get_tree().root, at, HEARTS, 12, 3.0, 0.12, 0.9, 3.0)
	Audio.play(&"sparkle", at, -4.0)


@rpc("authority", "call_local", "reliable")
func _rpc_reveal(at: Vector3, color: Color) -> void:
	shown.append(["reveal", at])
	if not is_inside_tree() or not at.is_finite():
		return
	var root := get_tree().root
	Fx.burst(root, at, color, 30, 6.0, 0.14, 1.2, 4.0)
	Fx.burst(root, at, Color("ffd23f"), 24, 7.0, 0.1, 1.0, 5.0)
	Audio.play(SECRET_SOUND, at)


## This game: the host told it something for its own profile.
func on_told(kind: StringName, info: Dictionary) -> void:
	if profile == null:
		return
	var m := profile.buddy_magic
	match kind:
		WOKEN:
			var recipe := StringName(str(info.get("recipe", "")))
			m.add_album(str(info.get("name", "Buddy")), recipe, str(info.get("pic", "")), int(info.get("u", 1)),
				int(now_unix.call()))
			if m.add_found(recipe):
				_say(tr("New in your Secret Book: the %s!") % tr(BuddyRecipes.recipe(recipe).title))
				progress.call(StringName("%s/buddy_shape" % LevelRules.SECRET))
			save_profile.call()
		MINI:
			var boss := StringName(str(info.get("kind", "")))
			if not MiniRules.owed(m.minis, boss):
				return
			m.minis[String(boss)] = MiniRules.record(boss)
			save_profile.call()
			_say(MiniRules.words(boss))
			_bring_mini(boss)
		TRICK:
			if m.add_trick(str(info.get("key", "")), StringName(str(info.get("emote", "")))):
				save_profile.call()


## This game's words, a moment later (SAY_LATER).
func _say(text: String) -> void:
	if say_delay <= 0.0 or not is_inside_tree():
		toast.call(text)
	else:
		get_tree().create_timer(say_delay).timeout.connect(toast.bind(text))


## This game's player brings its minis (once it stands in the world).
func bring_minis() -> void:
	if profile == null:
		return
	for kind: String in profile.buddy_magic.minis:
		if AlienRules.comes_along(profile, StringName(kind)):   # owner #86: one alien friend at a time (spec §21f)
			_bring_mini(StringName(kind))


func _bring_mini(kind: StringName) -> void:
	var rec: Dictionary = profile.buddy_magic.minis.get(String(kind), {})
	if rec.is_empty():
		return
	if local_player:
		_restored[MiniRules.animal_id(kind, local_player.peer_id)] = true   # its tricks travel with it
	Session.request_mini(kind, rec, profile.buddy_magic.tricks_of(MiniRules.trick_key(kind)))


## This game, every KEEP_EVERY: its minis' names, collars and hearts into the profile; Pip's and the baby dragon's
## tricks back to the host once they are here.
func local_tick() -> void:
	if profile == null or not is_instance_valid(local_player) or animals_root == null:
		return
	var m := profile.buddy_magic
	var changed := false
	for kind: String in m.minis:
		var a := mini_of(local_player.peer_id, StringName(kind))
		if a == null:
			continue
		var id := MiniRules.animal_id(StringName(kind), local_player.peer_id)
		var rec := {"name": PetRules.saved_name(a.pet_name, MiniRules.SPECIES, id), "collar": PetRules.clean_collar(a.collar),
			"happiness": PetRules.clean_happiness(a.happiness)}
		if rec != m.minis[kind]:
			m.minis[kind] = rec
			changed = true
	if changed:
		save_profile.call()
	for n in animals_root.get_children():
		var a := n as Animal
		if a == null or a.owner_peer != local_player.peer_id or _restored.has(String(a.name)):
			continue
		var key := profile_key(String(a.name))
		if key == "":
			continue
		_restored[String(a.name)] = true
		var tricks := m.tricks_of(key)
		if not tricks.is_empty():
			Session.request_pet_tricks(String(a.name), tricks)
