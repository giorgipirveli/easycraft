extends GutTest
## M3 Task 21c: the Tiny world in a world, through the host's SecretDirector (its child TinyDirector "Tiny") and
## Session, in solo play (this game is the host). A tiny child walking into a mouse village finds it (the Secret
## Book counts it); a normal-size child who got in (dug in, or grew there) is shown out to the door and finds
## nothing; the mice and the tiny chest come near players; the tiny chest holds the mice's cheese. And the chest
## mimic: the wand wakes an opened chest, it hops after the child, giggles, gives a small present and hops back to
## sleep — never harmful, once per chest. The world is a stub: the terrain rules, the secrets and villages, and
## whatever the directors changed.

const SEED := 12345

var director: SecretDirector
var rules: SecretRules
var cells := {}
var feedback: Array[String] = []
var _mode_before: StringName
var _gold_before := 0
var _book_before := {}
var _shelf_before: Array[int] = []
var village: Dictionary


func before_all() -> void:
	var r := SecretRules.new(SEED)
	for az in range(-4, 5):
		for ax in range(-4, 5):
			for s: Dictionary in r.tiny_in_area(Vector2i(ax, az)):
				if village.is_empty():
					village = s


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_book_before = Profile.data.secret_book.duplicate()
	_shelf_before = Profile.data.treasures.duplicate()
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	rules = SecretRules.new(SEED)
	cells.clear()
	feedback.clear()
	Session.magic_feedback.connect(_on_feedback)
	director = SecretDirector.new()
	director.name = "Secrets"
	director.auto_tick = false
	director.block_at = _block
	director.set_block = func(p: Vector3i, id: int) -> void: cells[p] = id
	director.is_ready = func(_p: Vector3) -> bool: return true
	director.ground_at = rules.shape.height_at
	director.standing_y = rules.shape.height_at
	director.time_of_day = func() -> float: return DayCycle.NOON
	director.save_profile = func() -> void: pass
	add_child_autofree(director)
	director.setup(SEED, SecretState.new())
	Session.set_inventory(multiplayer.get_unique_id(), Inventory.new())


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.secret_book = _book_before
	Profile.data.treasures = _shelf_before
	Session.survivor_reset()


func after_all() -> void:
	Audio.stop_all()


func _on_feedback(text: String) -> void:
	feedback.append(text)


func _block(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	var id := rules.block_at(p)
	if id >= 0:
		return id
	return rules.shape.column_block(p.y, rules.shape.height_at(p.x, p.z))


func _player(feet: Vector3, tiny: bool) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true   # spawned (the real spawn shows the body)
	p.global_position = feet
	if tiny:
		p.set_size_mode(SizeMagic.Mode.TINY)
	return p


func _at(cell: Vector3i) -> Vector3:
	return Vector3(cell) + Vector3(0.5, 0.0, 0.5)


func _book() -> int:
	return int(Profile.data.secret_book.get(String(MouseVillages.KIND), 0))


func test_a_village_to_play_in() -> void:
	assert_false(village.is_empty(), "seed %d has a mouse village near the spawn" % SEED)


func test_a_tiny_child_walking_in_finds_the_village() -> void:
	var before := _book()
	var p := _player(_at(village.visit), true)
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	assert_eq(_book(), before, "outside, nothing yet")
	p.global_position = _at(village.anchor)
	director.host_tick(SecretDirector.TICK)
	assert_eq(_book(), before + 1, "inside the room: found")
	assert_true(director.state.found.has(village.id))
	director.host_tick(SecretDirector.TICK)
	assert_eq(_book(), before + 1, "once")


## A normal-size child in the room (dug in, or grew there) is shown out to the door and finds nothing: only tiny
## friends fit in the mice's home.
func test_a_normal_size_child_inside_is_shown_out() -> void:
	var before := _book()
	var p := _player(_at(village.anchor), false)
	director.host_tick(SecretDirector.TICK)
	assert_eq(_book(), before, "never found by a big child")
	director.tiny.local_tick()
	assert_almost_eq(p.global_position, _at(village.visit), Vector3(0.01, 0.01, 0.01), "at the door, outside")
	assert_has(feedback, MouseVillages.TOO_BIG)
	var tiny := _player(_at(village.anchor), true)
	tiny.name = "tiny_one"
	director.tiny.local_tick()
	assert_almost_eq(tiny.global_position, _at(village.anchor), Vector3(0.01, 0.01, 0.01), "a tiny child stays")


func test_the_mice_and_their_tiny_chest_come_near_players() -> void:
	_player(_at(village.visit), true)
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	var chest := director.thing("chest_" + village.id) as TreasureChest
	assert_not_null(chest, "the tiny chest")
	if chest:
		assert_eq(chest.chest_kind, MouseVillages.CHEST_KIND)
		assert_almost_eq(chest.scale.x, MouseVillages.CHEST_SCALE, 0.001, "a tiny chest")
	var family := director.thing("mice_" + village.id) as MouseFamily
	assert_not_null(family, "the mouse family")
	if family:
		assert_eq(family.mouse_count(), 3, "two grown-ups and a little one")
		assert_same(family.shared_mesh(), (director.thing("mice_" + village.id) as MouseFamily).shared_mesh())


## The mouse family waves at a child close by and squeaks hello (at most once in a while).
func test_the_mice_wave_hello() -> void:
	var p := _player(_at(village.visit) + Vector3(0, 0, 0), true)
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	var family := director.thing("mice_" + village.id) as MouseFamily
	if family == null:
		fail_test("no family")
		return
	p.global_position = family.global_position + Vector3(1.5, 0, 0)
	family.look_around()
	assert_true(family.greeting(), "they wave")
	var squeaks := family.squeaks
	assert_eq(squeaks, 1, "hello!")
	family.look_around()
	assert_eq(family.squeaks, squeaks, "not every look")
	p.global_position = family.global_position + Vector3(30, 0, 0)
	family.look_around()
	assert_false(family.greeting())


## The tiny chest holds the mice's cheese (treasure only: it goes on the Secret Book's shelf) and a little gold in
## Survivor; opening it finds the village too.
func test_the_tiny_treasure_is_the_mice_cheese() -> void:
	_player(_at(village.anchor), true)
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	Session.request_open_chest("chest_" + village.id)
	assert_true(director.state.opened.has(village.id))
	assert_true(Profile.data.treasures.has(BlockIds.CHEESE), "the cheese on the shelf")
	assert_eq(Session.inventory_of(multiplayer.get_unique_id()).count(BlockIds.CHEESE), 1)
	assert_eq(Profile.data.survivor_gold, MouseVillages.GOLD, "a little gold, always the same")
	var loot := LootRules.roll(MouseVillages.CHEST_KIND, 77, 2, true)
	assert_eq(int(loot.gold), MouseVillages.GOLD * 2, "× 2^(u-1)")
	assert_eq(loot, LootRules.roll(MouseVillages.CHEST_KIND, 77, 2, true), "the same chest, the same treasure")
	assert_eq(int(LootRules.roll(MouseVillages.CHEST_KIND, 77, 1, false).gold), 0, "no gold in the Sandbox")


func test_secret_tells_where_the_nearest_mouse_village_is() -> void:
	var near: Vector3 = _at(village.visit) + Vector3(20, 0, 0)
	var line := director.hint(MouseVillages.KIND, near)
	assert_true(line.begins_with("Nearest mouse village:"), line)
	var visit: Vector3i = village.visit
	assert_true(line.ends_with("/tp %d %d %d" % [visit.x, visit.y, visit.z]), "the /tp goes to its door: " + line)
	assert_eq(ChatCommands.parse("/secret mice"), {"name": &"secret", "kind": &"mice"})
	assert_eq(SecretDirector.hint_name(MouseVillages.KIND), MouseVillages.HINT_NAME)
	assert_eq(director.found_text[MouseVillages.KIND], MouseVillages.FOUND_TEXT[MouseVillages.KIND])

# --- The chest mimic -----------------------------------------------------------------------------------------------


func _open_chest_with(p: Player) -> TreasureChest:
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	var chest := director.thing("chest_" + village.id) as TreasureChest
	Session.request_open_chest(chest.name)
	p.global_position = _at(village.anchor)
	return chest


func _mimic() -> ChestMimic:
	for n in director.get_node("Things").get_children():
		if n is ChestMimic and not n.is_queued_for_deletion():
			return n
	return null


func test_the_wand_wakes_an_opened_chest_that_hops_after_you_and_gives_a_present() -> void:
	var p := _player(_at(village.anchor), true)
	var chest: TreasureChest = await _open_chest_with(p)
	var hp := p.health.hp
	var bag := Session.inventory_of(p.peer_id)
	var before := _total(bag)
	var gold := Profile.data.survivor_gold
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	var mimic := _mimic()
	assert_not_null(mimic, "the chest woke up")
	if mimic == null:
		return
	assert_has(feedback, WakeKinds.MIMIC_WAKE)
	assert_false(chest.visible, "the chest itself hops about: the still one hides")
	assert_eq(mimic.collision_layer, SecretThing.LAYER, "only taps find it: nobody bumps into it")
	assert_eq(mimic.collision_mask, 0)
	assert_false(mimic.is_in_group(&"monsters"), "never a monster")
	var start := mimic.position
	for i in 40:
		director.plate_tick()
	assert_ne(mimic.landing(), start, "it hopped")
	for i in int((WakeKinds.MIMIC_HOPS + 2) * WakeKinds.HOP_EVERY / SecretDirector.PLATE_TICK):
		director.plate_tick()
	assert_gt(_total(bag), before, "a present in the bag")
	assert_eq(Profile.data.survivor_gold, gold, "never gold")
	for i in int((WakeKinds.PRESENT_TIME + 1.0) / SecretDirector.PLATE_TICK):
		director.plate_tick()
	await wait_physics_frames(2)
	assert_null(_mimic(), "it hopped back to sleep")
	assert_true(chest.visible, "the chest is back")
	assert_eq(p.health.hp, hp, "never harmful")
	feedback.clear()
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	assert_null(_mimic(), "once per chest")
	assert_has(feedback, WakeKinds.MIMIC_AGAIN)


func _total(bag: Inventory) -> int:
	var n := 0
	for id: int in bag.ids():
		n += bag.count(id)
	return n


func test_a_closed_chest_is_opened_not_woken() -> void:
	_player(_at(village.anchor), true)
	director.host_tick(SecretDirector.TICK)
	await wait_physics_frames(1)
	var chest := director.thing("chest_" + village.id) as TreasureChest
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	assert_null(_mimic())
	assert_has(feedback, WakeKinds.MIMIC_CLOSED)


func test_a_mimic_is_too_far_to_wake_from_afar() -> void:
	var p := _player(_at(village.anchor), true)
	var chest: TreasureChest = await _open_chest_with(p)
	p.global_position = _at(village.visit) + Vector3(30, 0, 0)
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	assert_null(_mimic())
	assert_has(feedback, "Too far away!")


## M3 Task 19 (the review): a mimic whose child left before its present goes back to sleep without using the chest
## up (it was marked "gave its present", so nobody could wake that chest again in this world).
func test_a_mimic_whose_child_left_can_be_woken_again() -> void:
	var p := _player(_at(village.anchor), true)
	var chest: TreasureChest = await _open_chest_with(p)
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	assert_not_null(_mimic(), "the chest woke up")
	p.free()   # the child went home (a LAN guest leaving)
	for i in int(2 * WakeKinds.HOP_EVERY / SecretDirector.PLATE_TICK):
		director.plate_tick()
	await wait_physics_frames(2)
	assert_null(_mimic(), "nobody to hop after: it went back to sleep")
	_player(_at(village.anchor), true)   # the child is back
	feedback.clear()
	Session.request_wake_chest(chest.name)
	await wait_physics_frames(1)
	assert_not_null(_mimic(), "its present still waits: it wakes again")
	assert_does_not_have(feedback, WakeKinds.MIMIC_AGAIN)
