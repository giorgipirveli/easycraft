extends GutTest
## Buddy magic in the world (M3 Task 20b, spec §14.21): the host's BuddyMagicDirector. A woken buddy goes into its
## child's album (and a secret shape into their book, once); a wand tap befriends a calm monster of level 1-2 (never
## a chasing one, a boss, a wave's, past the pet cap; Sandbox and Survivor); a beaten boss gives every child there
## its tiny version once, which lives in the profile and comes along; three emotes near a buddy or pet teach it a
## trick, and a known trick is done with the child.

var _told: Array = []
var _names: Dictionary
var _book: MindBook
var _profile: ProfileData
var _saves := 0
var _toasts: Array = []
var _events: Array = []


func before_each() -> void:
	_told.clear()
	_toasts.clear()
	_events.clear()
	_saves = 0
	_names = Session.chat_names.duplicate()
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_profile = ProfileData.new()


func after_each() -> void:
	Session.chat_names = _names
	MindBook.current = _book


func after_all() -> void:
	Audio.stop_all()


func _player(peer: int, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	Session.chat_names[peer] = "Kid%d" % peer
	return p


## A host director with its own buddies, animals and pets; its tells go to this test (and to the local game's
## own handler for this game's player, like Session.buddy_magic_tell).
func _director(mode := ModeRules.SANDBOX) -> BuddyMagicDirector:
	var d := BuddyMagicDirector.new()
	d.buddies_root = Node3D.new()
	add_child_autofree(d.buddies_root)
	d.animals_root = Node3D.new()
	add_child_autofree(d.animals_root)
	var pets := PetDirector.new()
	pets.auto_tick = false
	pets.animals = d.animals_root
	pets.spawn = func(data: Dictionary) -> Animal:
		var a := Animal.new()
		a.setup(data)
		d.animals_root.add_child(a)
		a.set_physics_process(false)
		a.global_position = data.pos
		return a
	add_child_autofree(pets)
	d.pets = pets
	d.mode = func() -> StringName: return mode
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	d.tell_game = func(peer: int, kind: StringName, info: Dictionary) -> void:
		_told.append([peer, kind, info])
		if peer == 1:
			d.on_told(kind, info)
	d.profile = _profile
	d.save_profile = func() -> void: _saves += 1
	d.toast = func(text: String) -> void: _toasts.append(text)
	d.progress = func(kind: StringName) -> void: _events.append(kind)
	d.now_unix = func() -> int: return 1790000000
	d.say_delay = 0.0   # the words at once (the game waits SAY_LATER)
	add_child_autofree(d)
	d.start_host()   # Session's requests (a mini asked for by this game's own player comes through Session)
	return d


func _last_told(peer: int) -> String:
	for i in range(_told.size() - 1, -1, -1):
		if _told[i][0] == peer and _told[i].size() == 2:
			return _told[i][1]
	return ""


func _buddy(d: BuddyMagicDirector, blocks: Dictionary, owner := 1, id := "Buddy1", pos := Vector3(1, 40, 0)) -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": BuddyMagicDirector.name_for(blocks), "owner": owner, "pos": pos,
		"yaw": 0.0, "id": id})
	d.buddies_root.add_child(b)
	b.set_physics_process(false)
	b.set_process(false)
	return b


func _snowman() -> Dictionary:
	return {Vector3i(0, 0, 0): BlockIds.PAINTED_WHITE, Vector3i(0, 1, 0): BlockIds.PAINTED_WHITE,
		Vector3i(0, 2, 0): BlockIds.PAINTED_WHITE, Vector3i(1, 2, 0): BlockIds.PAINTED_ORANGE}


var _n := 0


func _monster(d: BuddyMagicDirector, kind: StringName, level: int, pos: Vector3) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "m%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = func(_p: Vector3i) -> int: return BlockIds.AIR
	add_child_autofree(m)
	m.set_physics_process(false)
	var list: Array = []
	for c in get_children():
		if c is Monster and not c.is_queued_for_deletion():
			list.append(c)
	d.monsters = func() -> Array: return list
	return m


# --- The album and the secret shapes ---

func test_a_woken_buddy_goes_into_its_childs_album() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var b := _buddy(d, {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.RED})
	d.host_buddy_woken(1, b)
	assert_eq(_profile.buddy_magic.album.size(), 1)
	var e: Dictionary = _profile.buddy_magic.album[0]
	assert_eq(e.name, b.buddy_name)
	assert_eq(e.recipe, "")
	assert_eq(e.pic, BuddyPicture.code_of(b.blocks), "its picture")
	assert_eq(e.at, 1790000000)
	assert_gt(_saves, 0, "saved in the profile")
	assert_true(_toasts.is_empty(), "a plain buddy: no secret")


func test_a_secret_shape_is_named_revealed_and_found_once() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	assert_eq(BuddyMagicDirector.name_for(_snowman()), "Frosty", "the recipe's own name")
	var b := _buddy(d, _snowman())
	d.host_buddy_woken(1, b)
	assert_true(_profile.buddy_magic.has_found(&"snowman"))
	assert_eq(_toasts.size(), 1)
	assert_string_contains(_toasts[0], "Jolly Snowman")
	assert_has(_events, StringName("secret_found/buddy_shape"), "counts as a secret found")
	assert_true(d.shown.any(func(s: Array) -> bool: return s[0] == "reveal"), "a burst on every game")
	d.host_buddy_woken(1, _buddy(d, _snowman(), 1, "Buddy2"))
	assert_eq(_toasts.size(), 1, "found once")
	assert_eq(_profile.buddy_magic.album.size(), 2, "but both are in the album")


func test_a_guests_buddy_goes_to_the_guests_game() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	_player(5, Vector3(3, 40, 0))
	d.host_buddy_woken(5, _buddy(d, _snowman(), 5))
	assert_true(_profile.buddy_magic.album.is_empty(), "the host's own profile is not the guest's")
	assert_eq(_told[-1][0], 5)
	assert_eq(_told[-1][1], BuddyMagicDirector.WOKEN)
	assert_eq(_told[-1][2].recipe, "snowman")


# --- Befriending ---

func test_a_calm_small_monster_becomes_a_pet_friend() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var m := _monster(d, MonsterRules.GOBLIN, 1, Vector3(2, 40, 0))
	d.on_befriend(1, String(m.name))
	assert_true(m.is_queued_for_deletion(), "the monster is gone ...")
	var pets := d.pets.pets_of(1)
	assert_eq(pets.size(), 1, "... and a pet friend is here")
	var a: Animal = pets[0]
	assert_eq(a.species, BefriendRules.SPECIES)
	assert_eq(a.variant, MonsterRules.GOBLIN, "it still looks like a goblin")
	assert_false(a.is_in_group(&"monsters"), "it is no monster: nothing fights it, it fights nothing")
	assert_string_contains(_last_told(1), a.pet_name)
	assert_true(d.shown.any(func(s: Array) -> bool: return s[0] == "hearts"), "hearts")
	assert_eq(d.pets.pets_owned(1), 1, "it counts toward the pet cap")


func test_befriending_says_no_kindly() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var big := _monster(d, MonsterRules.SLIME, 3, Vector3(2, 40, 0))
	d.on_befriend(1, String(big.name))
	assert_false(big.is_queued_for_deletion())
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.TOO_STRONG))
	var angry := _monster(d, MonsterRules.SLIME, 1, Vector3(-2, 40, 0))
	angry.state = Monster.State.CHASE
	d.on_befriend(1, String(angry.name))
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.NOT_CALM))
	var waver := _monster(d, MonsterRules.SLIME, 1, Vector3(0, 40, 2))
	waver.wave = 3
	d.on_befriend(1, String(waver.name))
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.WAVE))
	var far := _monster(d, MonsterRules.SLIME, 1, Vector3(30, 40, 0))
	d.on_befriend(1, String(far.name))
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.TOO_FAR))
	assert_eq(d.pets.pets_of(1).size(), 0)


func test_befriending_stops_at_the_pet_cap() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	for i in AnimalRules.MAX_PETS:
		d.pets.spawn.call({"species": &"dog", "id": "dog%d" % i, "pos": Vector3(i, 40, 3), "owner": 1, "name": "Rex"})
	var m := _monster(d, MonsterRules.SLIME, 1, Vector3(2, 40, 0))
	d.on_befriend(1, String(m.name))
	assert_false(m.is_queued_for_deletion())
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.FULL))


func test_no_friends_in_monster_wave() -> void:
	var d := _director(ModeRules.WAVE)
	_player(1, Vector3(0, 40, 0))
	var m := _monster(d, MonsterRules.SLIME, 1, Vector3(2, 40, 0))
	d.on_befriend(1, String(m.name))
	assert_false(m.is_queued_for_deletion())
	assert_eq(_last_told(1), BefriendRules.message(BefriendRules.MODE))


func test_survivor_befriends_too() -> void:
	var d := _director(ModeRules.SURVIVOR)
	_player(1, Vector3(0, 40, 0))
	var m := _monster(d, MonsterRules.MUMMY, 2, Vector3(2, 40, 0))
	d.on_befriend(1, String(m.name))
	assert_eq(d.pets.pets_of(1).size(), 1)


# --- Mini-buddies ---

func test_a_beaten_boss_gives_everyone_there_its_tiny_version_once() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	_player(5, Vector3(3, 40, 0))
	d.host_boss_won(BossRules.GOLEM, Vector3(10, 40, 10))
	assert_true(_profile.buddy_magic.minis.has("golem"), "the host's own child keeps it")
	assert_true(_told.any(func(t: Array) -> bool: return t[0] == 5 and t.size() == 3 and t[1] == BuddyMagicDirector.MINI),
		"the guest's game is told too")
	assert_string_contains(_toasts[-1], "Pebble Golem")
	var mini := d.mini_of(1, BossRules.GOLEM)
	assert_not_null(mini, "it hopped out")
	assert_eq(mini.species, MiniRules.SPECIES)
	assert_eq(mini.pet_name, "Pebble")
	assert_almost_eq(mini.global_position, Vector3(10, 40, 10), Vector3.ONE * 0.01, "out of the boss's spot")
	assert_eq(d.pets.pets_owned(1), 0, "a mini never takes a pet place")
	var toasts := _toasts.size()
	d.host_boss_won(BossRules.GOLEM, Vector3(10, 40, 10))
	assert_eq(_toasts.size(), toasts, "once per boss kind")
	assert_eq(d.pets.pets_of(1).filter(func(a: Animal) -> bool: return a.species == MiniRules.SPECIES).size(), 1, "never two")


func test_no_mini_for_the_sky_dragon() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	d.host_boss_won(BossRules.SKY_DRAGON, Vector3.ZERO)
	assert_true(_profile.buddy_magic.minis.is_empty(), "its baby dragon is owner #39's")


func test_minis_come_along_into_a_world_and_are_never_saved_there() -> void:
	var d := _director()
	var p := _player(1, Vector3(0, 40, 0))
	_profile.buddy_magic.minis["serpent"] = MiniRules.record(BossRules.SERPENT)
	_profile.buddy_magic.minis["cake"] = MiniRules.record(BossRules.CAKE)
	d.local_player = p
	d.bring_minis()
	assert_not_null(d.mini_of(1, BossRules.SERPENT))
	assert_not_null(d.mini_of(1, BossRules.CAKE))
	assert_lt(d.mini_of(1, BossRules.CAKE).global_position.distance_to(p.global_position), 3.0, "next to its child")
	assert_true(PetDirector.is_profile_pet(String(d.mini_of(1, BossRules.CAKE).name)), "worlds never save it")
	d.on_peer_left(1)
	assert_true(d.mini_of(1, BossRules.CAKE).is_queued_for_deletion(), "it goes home with its child")


func test_a_minis_name_and_collar_are_kept_in_the_profile() -> void:
	var d := _director()
	var p := _player(1, Vector3(0, 40, 0))
	d.local_player = p
	d.host_boss_won(BossRules.FROST_GIANT, Vector3(4, 40, 0))
	var mini := d.mini_of(1, BossRules.FROST_GIANT)
	mini.pet_name = "Biscuit"
	mini.collar = 3
	d.local_tick()
	assert_eq(_profile.buddy_magic.minis["giant"].name, "Biscuit")
	assert_eq(_profile.buddy_magic.minis["giant"].collar, 3)


# --- Tricks ---

func test_three_dances_near_a_buddy_teach_it_and_then_it_dances_along() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var b := _buddy(d, _snowman())
	var far := _buddy(d, _snowman(), 1, "Buddy2", Vector3(40, 40, 0))
	var not_mine := _buddy(d, _snowman(), 5, "Buddy3")
	d.on_emote(1, &"dance_hop")
	assert_string_contains(_last_told(1), "2 more")
	d.on_emote(1, &"dance_hop")
	d.on_emote(1, &"dance_hop")
	assert_eq(_last_told(1), TrickRules.learned_words("Frosty", &"dance_hop"))
	assert_true(TrickRules.knows(b.trick_state, &"dance_hop"))
	assert_false(TrickRules.knows(far.trick_state, &"dance_hop"), "too far away to watch")
	assert_false(TrickRules.knows(not_mine.trick_state, &"dance_hop"), "only your own buddies learn from you")
	d.shown.clear()
	d.on_emote(1, &"dance_hop")
	assert_eq(d.shown, [[0, "Buddy1", TrickRules.DANCE]], "it dances along on every game")


func test_pets_learn_a_spin_and_pip_keeps_his_in_the_profile() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var dog: Animal = d.pets.spawn.call({"species": &"dog", "id": "dog1", "pos": Vector3(2, 40, 0), "owner": 1, "name": "Rex"})
	var pip: Animal = d.pets.spawn.call({"species": &"pip", "id": "pip_1", "pos": Vector3(-2, 40, 0), "owner": 1, "name": "Pip"})
	for i in 3:
		d.on_emote(1, &"cheer")
	assert_true(TrickRules.knows(dog.trick_state, &"cheer"))
	assert_true(TrickRules.knows(pip.trick_state, &"cheer"))
	assert_string_contains(_last_told(1), "learned to spin")
	assert_eq(_profile.buddy_magic.tricks_of("pip"), ["cheer"], "Pip's trick lives in the profile")
	assert_eq(_profile.buddy_magic.tricks_of("dog1"), [], "a world pet's is saved with the world")


func test_a_profile_pets_tricks_come_back_to_the_host() -> void:
	var d := _director()
	var p := _player(1, Vector3(0, 40, 0))
	d.local_player = p
	_profile.buddy_magic.tricks["pip"] = ["wave"]
	var pip: Animal = d.pets.spawn.call({"species": &"pip", "id": "pip_1", "pos": Vector3(-2, 40, 0), "owner": 1, "name": "Pip"})
	d.local_tick()
	assert_true(TrickRules.knows(pip.trick_state, &"wave"), "never forgotten, in any world")


func test_a_known_trick_does_not_need_three_again() -> void:
	var d := _director()
	_player(1, Vector3(0, 40, 0))
	var b := _buddy(d, _snowman())
	b.load_tricks({"tricks": ["wave"]})
	d.on_emote(1, &"wave")
	assert_eq(d.shown[-1], [0, "Buddy1", TrickRules.WAVE])
