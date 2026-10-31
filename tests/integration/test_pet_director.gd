extends GutTest
## Pets with perks in the world (M3 Task 11): the host's PetDirector (treats tame foxes and parrots, feed pets
## and teach their minds; pats; the heart falls only while the child plays; the dog's bark and coins; the
## parrot's pointing; names through the list or the filter; collars; Pip coming and going) and every game's
## part (one shared glow light for the nearest glowing pet; the parrot repeating its own child's words).

var _book: MindBook
var _names: Dictionary
var _told: Array = []
var _saves: Array = []


func before_each() -> void:
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_names = Session.chat_names.duplicate()
	_told.clear()
	_saves.clear()


func after_each() -> void:
	MindBook.current = _book
	Session.chat_names = _names


func after_all() -> void:
	for n in Audio.get_children():   # sounds still playing at exit show as leaks (DEVELOPMENT.md §8)
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()
		elif n is AudioStreamPlayer:
			(n as AudioStreamPlayer).stop()


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


func _director() -> PetDirector:
	var d := PetDirector.new()
	d.auto_tick = false
	d.animals = Node3D.new()
	add_child_autofree(d.animals)
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	d.save_profile = func() -> void: _saves.append(true)
	d.spawn = func(data: Dictionary) -> Animal: return _add(d, data)
	add_child_autofree(d)
	return d


func _add(d: PetDirector, data: Dictionary) -> Animal:
	var a := Animal.new()
	a.setup(data)
	d.animals.add_child(a)
	a.global_position = data.pos
	return a


func _animal(d: PetDirector, species: StringName, id: String, pos: Vector3, owner: int = 0) -> Animal:
	return _add(d, {"species": species, "id": id, "pos": pos, "owner": owner, "name": "Rex" if owner else ""})


func _last_told(peer: int) -> String:
	for i in range(_told.size() - 1, -1, -1):
		if _told[i][0] == peer:
			return _told[i][1]
	return ""


# --- Treats ---

func test_a_fox_is_tamed_with_two_treats_from_the_same_child() -> void:
	var d := _director()
	var kid := _player(5, Vector3(0, 10, 0))
	var fox := _animal(d, &"fox", "a1_1_0", Vector3(2, 10, 0))
	d.on_treat(5, fox.name, ItemIds.TREAT_BERRIES)
	assert_false(fox.is_pet(), "one treat is a start")
	assert_gt(fox.mind.memory.like(Animal.mind_name(kid)), 0.0, "it likes the child for it")
	d.on_treat(5, fox.name, ItemIds.TREAT_FISH)
	assert_eq(fox.owner_peer, 5, "any treat works; the second tames it")
	assert_ne(fox.pet_name, "")
	assert_string_contains(_last_told(5), fox.pet_name)


## Owner #45a: every treat given counts for the child ("Give 3 pet treats"), the taming too ("Tame a fox").
func test_treats_count_for_the_childs_progress() -> void:
	var d := _director()
	var me := multiplayer.get_unique_id()
	_player(me, Vector3(0, 10, 0))
	var fox := _animal(d, &"fox", "a1_1_1", Vector3(2, 10, 0))
	var data := ProgressData.new()
	Progress.begin(data)
	d.on_treat(me, fox.name, ItemIds.TREAT_BERRIES)
	d.on_treat(me, fox.name, ItemIds.TREAT_SEEDS)
	d.on_treat(me, fox.name, BlockIds.PLANKS)
	Progress.end()
	assert_eq(data.count(&"pet_fed/fox"), 2, "two treats (planks are no treat)")
	assert_eq(data.count(&"animal_tamed/fox"), 1)


func test_three_quick_pets_never_tame_a_fox_or_a_parrot() -> void:
	var fox := Animal.new()
	fox.setup({"species": &"fox", "id": "f", "pos": Vector3.ZERO})
	add_child_autofree(fox)
	for t in 5:
		fox.pet_tap(7, t * 0.2, 0)
	assert_false(fox.is_pet(), "a fox wants treats")


func test_a_parrot_is_tamed_with_treats_but_not_past_the_pet_cap() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	for i in AnimalRules.MAX_PETS:
		_animal(d, &"cat", "c%d" % i, Vector3(1, 10, i), 5)
	var parrot := _animal(d, &"parrot", "a2_2_0", Vector3(2, 10, 0))
	for i in 3:
		d.on_treat(5, parrot.name, ItemIds.TREAT_SEEDS)
	assert_false(parrot.is_pet(), "three pets already")
	assert_string_contains(_last_told(5), "%d pets" % AnimalRules.MAX_PETS)


func test_pip_never_takes_a_place_under_the_pet_cap() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	_animal(d, &"pip", "pip_5", Vector3(1, 10, 0), 5)
	_animal(d, &"cat", "c1", Vector3(1, 10, 1), 5)
	assert_eq(d.pets_owned(5), 1, "Pip does not count")


func test_a_treat_raises_a_pets_heart_and_teaches_its_mind() -> void:
	var d := _director()
	var kid := _player(5, Vector3(0, 10, 0))
	var dog := _animal(d, &"dog", "d1", Vector3(2, 10, 0), 5)
	dog.happiness = 0.5
	d.on_treat(5, dog.name, ItemIds.TREAT_FISH)
	var after_any := dog.happiness
	assert_gt(after_any, 0.5, "a treat raises the heart")
	d.on_treat(5, dog.name, ItemIds.TREAT_BISCUIT)
	assert_gt(dog.happiness - after_any, after_any - 0.5, "its favourite raises it more")
	assert_gt(dog.mind.memory.like(Animal.mind_name(kid)), 0.5, "its mind learns it was fed (Task 18's reward)")


func test_survivor_pays_one_treat_and_a_missing_treat_does_nothing() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var paid: Array = []
	var have := [true]
	d.take_treat = func(peer: int, item: int) -> bool:
		paid.append([peer, item])
		return have[0]
	var dog := _animal(d, &"dog", "d1", Vector3(2, 10, 0), 5)
	dog.happiness = 0.5
	d.on_treat(5, dog.name, ItemIds.TREAT_BISCUIT)
	assert_eq(paid, [[5, ItemIds.TREAT_BISCUIT]], "one treat from the bag")
	var h := dog.happiness
	have[0] = false
	d.on_treat(5, dog.name, ItemIds.TREAT_BISCUIT)
	assert_eq(dog.happiness, h, "no treat left: nothing happens")


func test_a_treat_out_of_reach_or_for_a_farm_animal_is_kept() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var paid: Array = []
	d.take_treat = func(peer: int, item: int) -> bool:
		paid.append(item)
		return true
	var far := _animal(d, &"fox", "far", Vector3(30, 10, 0))
	var cow := _animal(d, &"cow", "cow", Vector3(2, 10, 0))
	d.on_treat(5, far.name, ItemIds.TREAT_BERRIES)
	d.on_treat(5, cow.name, ItemIds.TREAT_BERRIES)
	d.on_treat(5, "nobody", ItemIds.TREAT_BERRIES)
	d.on_treat(5, cow.name, BlockIds.STONE)
	assert_eq(paid, [], "nothing was used")
	assert_false(far.is_pet())


# --- Pats and the heart ---

func test_a_pat_raises_the_heart_but_tapping_fast_is_no_faster() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	cat.happiness = 0.5
	d.now = func() -> float: return 10.0
	d.on_pat(5, cat.name)
	var once := cat._heart
	assert_gt(once, 0.5)
	d.on_pat(5, cat.name)
	assert_eq(cat._heart, once, "within PAT_GAP: no more")
	d.now = func() -> float: return 11.0
	d.on_pat(5, cat.name)
	assert_gt(cat._heart, once)


func test_the_heart_falls_while_its_child_plays_and_never_while_they_are_away() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	var waiting := _animal(d, &"dog", "d9", Vector3(2, 10, 3), 9)   # its child left the game
	cat.happiness = 0.8
	waiting.happiness = 0.8
	for i in 600:
		d.host_tick(1.0)   # ten minutes
	assert_lt(cat._heart, 0.8, "a little lower after ten minutes")
	assert_gt(cat._heart, 0.6, "only a little")
	assert_eq(waiting.happiness, 0.8, "a pet waiting for its child never gets sadder")
	for i in 10000:
		d.host_tick(1.0)
	assert_eq(cat.happiness, PetRules.HAPPY_FLOOR, "never below the floor")
	assert_true(cat.is_pet(), "a sad pet never leaves")
	assert_eq(cat.owner_peer, 5)


func test_a_sad_pet_still_follows_obeys_and_helps() -> void:
	var d := _director()
	var kid := _player(5, Vector3(0, 10, 0))
	var dog := _animal(d, &"dog", "d1", Vector3(8, 10, 0), 5)
	dog.happiness = PetRules.HAPPY_FLOOR
	dog._follow_owner()
	assert_lt(dog._dir.x, 0.0, "it walks back towards its child at x = %.0f" % kid.global_position.x)
	dog.pet_tap(5, 1.0, 1)
	assert_true(dog.sitting, "it sits when asked")
	dog.pet_tap(5, 5.0, 1)
	var monster := _monster(Vector3(8, 10, 12))
	d.host_tick(0.2)
	assert_true(dog.mark_shown(), "and still barks at a monster")
	monster.queue_free()


# --- Bark ---

func _monster(pos: Vector3) -> Node3D:
	var m := Node3D.new()
	m.add_to_group(&"monsters")
	add_child_autofree(m)
	m.global_position = pos
	return m


func test_a_dog_barks_once_when_a_monster_comes_within_16_blocks() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var dog := _animal(d, &"dog", "d1", Vector3(2, 10, 0), 5)
	var m := _monster(Vector3(2, 10, 20))
	d.host_tick(0.2)
	assert_false(dog.mark_shown(), "18 blocks away: quiet")
	m.global_position = Vector3(2, 10, 14)
	d.host_tick(0.2)
	assert_true(dog.mark_shown(), "woof! and a '!' over it")
	var first := dog.bark_last
	d.host_tick(0.2)
	assert_eq(dog.bark_last, first, "one bark for that monster")


func test_a_wild_dog_or_one_far_from_its_child_never_barks() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var wild := _animal(d, &"dog", "w", Vector3(2, 10, 0))
	var far := _animal(d, &"dog", "far", Vector3(60, 10, 0), 5)
	_monster(Vector3(2, 10, 8))
	_monster(Vector3(60, 10, 8))
	d.host_tick(0.2)
	assert_false(wild.mark_shown(), "wild")
	assert_false(far.mark_shown(), "too far from its child")
	var cat := _animal(d, &"cat", "c", Vector3(1, 10, 1), 5)
	d.host_tick(0.2)
	assert_false(cat.mark_shown(), "cats don't bark")


# --- Coins ---

func _coin(pos: Vector3) -> Coin:
	var c := Coin.new()
	c.setup({"id": "coin%d" % randi(), "pos": pos, "value": 2})
	add_child_autofree(c)
	c.set_physics_process(false)
	c._landed = true
	c.global_position = pos
	return c


func test_a_dog_pulls_coins_within_4_blocks_to_its_child() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	_animal(d, &"dog", "d1", Vector3(6, 10, 0), 5)
	var near := _coin(Vector3(9, 10.25, 0))
	var far := _coin(Vector3(15, 10.25, 0))
	d.coins = func() -> Array: return [near, far]
	d.host_tick(0.2)
	assert_eq(near.collector, 5, "it flies to the dog's child")
	assert_eq(far.collector, 0, "too far from the dog")


func test_a_cat_or_a_wild_dog_pulls_no_coins() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	_animal(d, &"cat", "c1", Vector3(6, 10, 0), 5)
	_animal(d, &"dog", "w1", Vector3(-6, 10, 0))
	var a := _coin(Vector3(7, 10.25, 0))
	var b := _coin(Vector3(-7, 10.25, 0))
	d.coins = func() -> Array: return [a, b]
	d.host_tick(0.2)
	assert_eq(a.collector, 0)
	assert_eq(b.collector, 0)


# --- The parrot points at secrets ---

func test_a_parrot_points_at_the_nearest_secret_nobody_found() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var parrot := _animal(d, &"parrot", "p1", Vector3(2, 10, 0), 5)
	var asked: Array = []
	d.secrets_near = func(pos: Vector3, radius: float) -> Array[Vector3]:
		asked.append(radius)
		return [Vector3(2, 8, -12)] as Array[Vector3]
	parrot.point_t = 0.1
	d.host_tick(0.2)
	assert_eq(asked, [PetPerks.POINT_RANGE])
	assert_true(parrot.pointing(), "beak towards the secret")
	assert_almost_eq(parrot._hold_yaw, PetPerks.point_yaw(parrot.global_position, Vector3(2, 8, -12)), 0.001)
	assert_almost_eq(parrot.point_t, PetPerks.POINT_EVERY, 0.001, "then not again for a while")


func test_a_parrot_with_no_secret_near_just_follows() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	var parrot := _animal(d, &"parrot", "p1", Vector3(2, 10, 0), 5)
	parrot.point_t = 0.1
	d.host_tick(0.2)
	assert_false(parrot.pointing())


# --- Names and collars ---

func test_an_under_13_child_names_a_pet_from_the_list_only() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	d.band_of = func(_peer: int) -> StringName: return AgeBand.UNDER_13
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	d.on_name(5, cat.name, "Sparkles")
	assert_eq(cat.pet_name, "Rex", "not on the list")
	assert_eq(_last_told(5), PetRules.name_message("list_only"))
	d.on_name(5, cat.name, "Mochi")
	assert_eq(cat.pet_name, "Mochi")


func test_a_13_plus_child_may_type_a_name_through_the_filter() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	d.band_of = func(_peer: int) -> StringName: return AgeBand.TEEN_PLUS
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	d.on_name(5, cat.name, "Sparkles")
	assert_eq(cat.pet_name, "Sparkles")
	d.on_name(5, cat.name, "stupidcat")
	assert_eq(cat.pet_name, "Sparkles", "the filter says no")


func test_only_its_own_child_renames_it_or_changes_its_collar() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	_player(6, Vector3(1, 10, 0))
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	d.on_name(6, cat.name, "Mochi")
	d.on_collar(6, cat.name, 3)
	assert_eq(cat.pet_name, "Rex")
	assert_eq(cat.collar, PetRules.OWNER_COLOUR)
	d.on_collar(5, cat.name, 3)
	assert_eq(cat.collar, 3)
	d.on_collar(5, cat.name, 11)
	assert_eq(cat.collar, 3, "only the 8 colours")


func test_a_new_collar_colour_shows_on_every_game() -> void:
	var cat := Animal.new()
	cat.setup({"species": &"cat", "id": "c", "pos": Vector3.ZERO, "owner": 5, "name": "Rex"})
	add_child_autofree(cat)
	cat.collar = 6   # as the sync delivers it
	cat._process(0.016)
	var band := cat.find_child("Collar", true, false) as MeshInstance3D
	assert_eq((band.material_override as StandardMaterial3D).albedo_color, PetRules.COLLARS[6])
	assert_same(band.material_override, Animal.collar_material(PetRules.COLLARS[6]), "one shared material per colour")


# --- Pip ---

func test_pip_comes_with_his_child_once() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	d.on_pip(5, PetRules.pip_record("Bolt", 2, 0.9))
	var pips := d.pets_of(5).filter(func(a: Animal) -> bool: return a.species == &"pip")
	assert_eq(pips.size(), 1)
	var pip: Animal = pips[0]
	assert_eq(pip.pet_name, "Bolt")
	assert_eq(pip.collar, 2)
	assert_eq(pip.happiness, 0.9)
	d.on_pip(5, PetRules.pip_record("Pip", 0, 0.5))
	assert_eq(d.pets_of(5).size(), 1, "never two")
	d.on_pip(8, PetRules.pip_record("Pip", 0, 0.5))
	assert_eq(d.pets_of(8).size(), 0, "no player 8 here")


func test_pip_leaves_with_a_guest_who_leaves_and_the_other_pets_wait() -> void:
	var d := _director()
	_player(5, Vector3(0, 10, 0))
	d.on_pip(5, PetRules.pip_record("Pip", -1, 0.7))
	var cat := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	d.on_peer_left(5)
	for a: Animal in d.pets_of(5):
		if a.species == &"pip":
			assert_true(a.is_queued_for_deletion(), "Pip goes home with his child")
	assert_false(cat.is_queued_for_deletion(), "the cat waits (M1b)")


func test_this_games_pip_is_kept_in_the_profile() -> void:
	var d := _director()
	var me := _player(multiplayer.get_unique_id(), Vector3(0, 10, 0))
	d.local_player = me
	var profile := ProfileData.new()
	d.profile = profile
	PetRules.give_pip(profile)
	var pip := _animal(d, &"pip", "pip_1", Vector3(1, 10, 0), me.peer_id)
	pip.pet_name = "Bolt"
	pip.collar = 4
	d.keep_pip_record()
	assert_eq(profile.pip, PetRules.pip_record("Bolt", 4, pip.happiness))
	assert_eq(_saves.size(), 1, "saved when it changed")
	d.keep_pip_record()
	assert_eq(_saves.size(), 1, "not again when nothing changed")


func test_a_summoned_pip_is_a_visitor_when_the_child_has_no_pip() -> void:
	var d := _director()
	var me := _player(multiplayer.get_unique_id(), Vector3(0, 10, 0))
	d.local_player = me
	var profile := ProfileData.new()
	d.profile = profile
	_animal(d, &"pip", "pip_1", Vector3(1, 10, 0), me.peer_id)
	d.keep_pip_record()
	assert_eq(profile.pip, {}, "only the tutorial gives Pip for keeps (PetRules.give_pip)")


# --- Glow: one shared light, only this game ---

func test_one_light_goes_to_the_nearest_glowing_pet_in_the_dark() -> void:
	var d := _director()
	var me := _player(5, Vector3(0, 10, 0))
	d.local_player = me
	d.is_night = func() -> bool: return true
	var near := _animal(d, &"cat", "c1", Vector3(2, 10, 0), 5)
	for i in 4:
		_animal(d, &"cat", "c%d" % (i + 2), Vector3(6 + i, 10, 4), 5)
	_animal(d, &"dog", "d1", Vector3(1, 10, 0), 5)
	d.local_tick(0.3)
	assert_eq(d.glow_target(), near, "the nearest glowing pet")
	assert_eq(d.find_children("*", "OmniLight3D", true, false).size(), 1, "one light, never one per pet")
	assert_true(d.glow.visible)
	for i in 30:
		d.local_tick(0.1)
	assert_almost_eq(d.glow.global_position.x, near.global_position.x, 0.01, "it sits on the cat")
	d.is_night = func() -> bool: return false
	d.local_tick(0.3)
	assert_null(d.glow_target(), "daylight: no glow")


func test_a_cave_lights_the_cat_and_a_wild_cat_never_glows() -> void:
	var d := _director()
	var me := _player(5, Vector3(0, 10, 0))
	d.local_player = me
	d.underground = func() -> float: return 0.9
	var wild := _animal(d, &"cat", "w", Vector3(2, 10, 0))
	d.local_tick(0.3)
	assert_null(d.glow_target(), "a wild cat has no perk")
	var pip := _animal(d, &"pip", "pip_5", Vector3(3, 10, 0), 5)
	d.local_tick(0.3)
	assert_eq(d.glow_target(), pip, "Pip's lamp in the cave")
	assert_ne(wild, pip)


## "Measure" (the brief): the local tick with a dozen pets and a light costs microseconds.
func test_the_glow_costs_little() -> void:
	var d := _director()
	var me := _player(5, Vector3(0, 10, 0))
	d.local_player = me
	d.is_night = func() -> bool: return true
	for i in 12:
		_animal(d, &"cat", "c%d" % i, Vector3(i, 10, 2), 5)
	var t0 := Time.get_ticks_usec()
	for i in 200:
		d.local_tick(0.2)
	var per_tick := (Time.get_ticks_usec() - t0) / 200.0
	gut.p("PET_GLOW local tick with 12 glowing pets: %.1f us" % per_tick)
	assert_lt(per_tick, 2000.0, "well under a millisecond on this PC")


# --- The parrot's words: its own child's only, this game only ---

func test_a_parrot_repeats_its_own_childs_words() -> void:
	var d := _director()
	var me := _player(multiplayer.get_unique_id(), Vector3(0, 10, 0))
	d.local_player = me
	var parrot := _animal(d, &"parrot", "p1", Vector3(2, 10, 0), me.peer_id)
	var theirs := _animal(d, &"parrot", "p2", Vector3(3, 10, 0), me.peer_id + 7)
	d.hear_own("Hello!")
	assert_eq(parrot.bubble_text(), "", "a moment later")
	d.local_tick(PetDirector.ECHO_DELAY + 0.1)
	assert_eq(parrot.bubble_text(), "Squawk! Hello!")
	assert_eq(theirs.bubble_text(), "", "another child's parrot never says my words")


func test_the_parrot_code_never_listens_to_others_chat_or_sends_its_words() -> void:
	var text := FileAccess.get_file_as_string("res://world/pet_director.gd")
	assert_false(text.contains("chat_received"), "never other players' lines")
	var i := text.find("func hear_own")
	var body := text.substr(i, text.find("\nfunc ", i + 1) - i)
	assert_false(body.contains("rpc") or body.contains("Session."), "its words never travel")
