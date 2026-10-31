extends GutTest
## Owner feedback #42 (spec §12.16b): the treasure pack in a world, through the host's SecretDirector (its
## TreasureDirector child "Treasures") and Session, in solo play (this game is the host). The world is a
## stub: SecretRules' blocks plus whatever the directors changed.

class FakeBots:
	extends Node
	var said: Array[String] = []

	func notice(_point: Vector3, text: String = "") -> bool:
		said.append(text)
		return true


const SEED := 12345

var director: SecretDirector
var rules: SecretRules
var cells := {}                   # blocks the directors changed
var time := DayCycle.NOON
var feedback: Array[String] = []
var _mode_before: StringName
var _gold_before := 0
var _book_before := {}
var _shelf_before: Array[int] = []
var _all: Array = []


func before_all() -> void:
	var r := SecretRules.new(SEED)
	for az in range(-6, 6):
		for ax in range(-6, 6):
			_all.append_array(r.secrets_in_area(Vector2i(ax, az)))


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_book_before = Profile.data.secret_book.duplicate()
	_shelf_before = Profile.data.treasures.duplicate()
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	rules = SecretRules.new(SEED)
	cells.clear()
	time = DayCycle.NOON
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
	director.time_of_day = func() -> float: return time
	director.save_profile = func() -> void: pass
	add_child_autofree(director)
	director.setup(SEED, SecretState.new())


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.secret_book = _book_before
	Profile.data.treasures = _shelf_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()
		elif n is AudioStreamPlayer:
			(n as AudioStreamPlayer).stop()


func _on_feedback(text: String) -> void:
	feedback.append(text)


func _block(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	var id := rules.block_at(p)
	return id if id >= 0 else BlockIds.AIR


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _first(kind: StringName) -> Dictionary:
	for s: Dictionary in _all:
		if s.kind == kind:
			return s
	fail_test("no %s" % kind)
	return {}


func _book(kind: StringName) -> int:
	return int(Profile.data.secret_book.get(String(kind), 0))


func _tick(delta: float = SecretDirector.TICK) -> void:
	director.host_tick(delta)


func _center(box: Array) -> Vector3:
	var lo: Vector3i = box[0]
	var hi: Vector3i = box[1]
	return Vector3(lo.x + hi.x, 2 * lo.y, lo.z + hi.z) / 2.0


func _me() -> int:
	return multiplayer.get_unique_id()


# --- Chests and rarities ---

func test_the_packs_chests_come_near_players_glowing_in_their_rarity() -> void:
	var camp := _first(TreasurePlaces.CAMP)
	_player(Vector3(camp.anchor) + Vector3(0.5, 0, 2.5))
	_tick()
	var chest := director.thing("chest_" + camp.id) as TreasureChest
	assert_not_null(chest)
	assert_eq(chest.rarity, ItemRarity.COMMON)
	assert_false(chest.locked)


func test_a_campsites_supply_chest_opens_once_with_fixed_gold() -> void:
	var camp := _first(TreasurePlaces.CAMP)
	var before := _book(TreasurePlaces.CAMP)
	_player(Vector3(camp.chest) + Vector3(1.5, 0, 0.5))
	_tick()
	Session.request_open_chest("chest_" + camp.id)
	assert_eq(Profile.data.survivor_gold, TreasureLoot.GOLD[ItemRarity.COMMON], "a common chest's fixed gold")
	var loot := TreasureLoot.roll(&"camp", LootRules.chest_key(SEED, camp.chest), 1, true)
	for e: Array in loot.items:
		assert_gte(Session.inventory_of(_me()).count(int(e[0])), int(e[1]), "its supplies")
	assert_true(director.state.found.has(camp.id))
	assert_eq(_book(TreasurePlaces.CAMP), before + 1, "the Secret Book counts it, once")
	Session.request_open_chest("chest_" + camp.id)
	assert_eq(Profile.data.survivor_gold, TreasureLoot.GOLD[ItemRarity.COMMON], "no gold loop: it opens once")
	assert_string_contains(feedback.back(), "Empty")


func test_walking_into_a_place_finds_it() -> void:
	var s := _first(TreasurePlaces.MINESHAFT)
	var before := _book(TreasurePlaces.MINESHAFT)
	_player(_center(s.inside) + Vector3(0.5, 0, 0.5))
	_tick()
	assert_true(director.state.found.has(s.id))
	assert_eq(_book(TreasurePlaces.MINESHAFT), before + 1)


# --- The dungeon vault ---

func _flip(s: Dictionary, i: int) -> void:
	var cell: Vector3i = s.levers[i]
	cells[cell] = BlockIds.LEVER_ON if _block(cell) == BlockIds.LEVER else BlockIds.LEVER
	director.plate_tick()


func test_the_vault_opens_only_after_the_levers_in_the_notes_order() -> void:
	var s := _first(TreasurePlaces.VAULT)
	_player(_center(s.hall) + Vector3(0.5, 0, 0.5))
	_tick()
	director.plate_tick()
	var chest := director.thing("chest_" + s.id) as TreasureChest
	assert_not_null(chest)
	assert_eq(chest.rarity, ItemRarity.LEGENDARY)
	assert_true(chest.locked)
	assert_not_null(director.thing("note_" + s.id), "the note with the order")
	assert_not_null(director.thing("levers_" + s.id), "the pictures over the levers")
	Session.request_open_chest(chest.name)
	assert_eq(Profile.data.survivor_gold, 0, "locked")
	assert_string_contains(feedback.back(), "levers")
	var order: Array = s.order
	_flip(s, order[1])                                 # a wrong one first
	assert_string_contains(feedback.back(), "Clunk")
	for cell: Vector3i in s.levers:
		assert_eq(_block(cell), BlockIds.LEVER, "the levers flip back")
	for v: Vector3i in s.vault:
		assert_eq(_block(v), BlockIds.YELLOW, "the vault stays shut")
	_flip(s, order[0])
	assert_string_contains(feedback.back(), "1 of 3")
	_flip(s, order[1])
	_flip(s, order[2])
	assert_true(director.state.solved.has(s.id))
	for v: Vector3i in s.vault:
		assert_eq(_block(v), BlockIds.AIR, "the golden door opens")
	assert_false(chest.locked)
	assert_true(director.state.found.has(s.id), "opening it finds the vault")
	Session.request_open_chest(chest.name)
	assert_eq(Profile.data.survivor_gold, TreasureLoot.GOLD[ItemRarity.LEGENDARY])
	assert_true(Profile.data.treasures.has(BlockIds.TROPHY), "a legendary chest's golden trophy")


func test_levers_turned_on_before_anyone_came_do_not_count() -> void:
	var s := _first(TreasurePlaces.VAULT)
	var order: Array = s.order
	cells[s.levers[order[0]]] = BlockIds.LEVER_ON        # someone left one on in a saved world
	_player(_center(s.hall) + Vector3(0.5, 0, 0.5))
	_tick()
	director.plate_tick()
	_flip(s, order[1])
	_flip(s, order[2])
	assert_false(director.state.solved.has(s.id), "only the levers flipped while watched count")


# --- The friendly haunted house ---

func test_a_ghosts_riddle_opens_the_haunted_houses_chest() -> void:
	var s := _first(TreasurePlaces.HAUNTED)
	_player(_center(s.inside) + Vector3(0.5, 0, 0.5))
	_tick()
	var ghost := director.thing("ghost_%s_0" % s.id) as FriendlyGhost
	assert_not_null(ghost, "a friendly ghost floats inside")
	assert_not_null(director.thing("ghost_%s_1" % s.id), "and a second one")
	var chest := director.thing("chest_" + s.id) as TreasureChest
	assert_true(chest.locked)
	assert_eq(chest.rarity, ItemRarity.EPIC)
	var q := ghost.question()
	Session.request_wanderer_answer(ghost.name, (int(q.answer) + 1) % 3)
	assert_eq(feedback.back(), TreasureRules.GHOST_WRONG)
	assert_true(chest.locked)
	Session.request_wanderer_answer(ghost.name, int(q.answer))
	assert_eq(feedback.back(), TreasureRules.GHOST_RIGHT)
	assert_false(chest.locked)
	assert_true(director.state.solved.has(s.id))
	assert_false(ghost.is_queued_for_deletion(), "the ghosts stay: they live here")
	Session.request_open_chest(chest.name)
	assert_eq(Profile.data.survivor_gold, TreasureLoot.GOLD[ItemRarity.EPIC])
	Session.request_wanderer_answer(ghost.name, int(q.answer))
	assert_eq(Profile.data.survivor_gold, TreasureLoot.GOLD[ItemRarity.EPIC], "one reward")


# --- The wishing well ---

func _day_passes() -> void:
	time = DayCycle.NIGHT_START + 0.02
	_tick()
	time = DayCycle.DAWN_START + 0.02
	_tick()
	time = DayCycle.DAY_START + 0.05
	_tick()


func test_the_wishing_well_gives_a_small_gift_once_a_day() -> void:
	var s := _first(TreasurePlaces.WELL)
	_player(Vector3(s.well) + Vector3(2.5, 0, 0.5))
	_tick()
	var well := director.thing("well_" + s.id)
	assert_not_null(well)
	var inv := Session.inventory_of(_me())
	var first := TreasureRules.wish_gift(0)
	Session.request_wish(well.name)
	var e0: Array = first.items[0]
	assert_eq(inv.count(int(e0[0])), int(e0[1]), "today's gift")
	assert_eq(Profile.data.survivor_gold, 0, "never gold")
	assert_true(director.state.found.has(s.id), "a wish finds the well")
	Session.request_wish(well.name)
	assert_eq(feedback.back(), TreasureRules.WISH_DONE)
	assert_eq(inv.count(int(e0[0])), int(e0[1]), "once a day")
	_day_passes()
	assert_eq(director.state.more.dawns, 1)
	Session.request_wish(well.name)
	var e1: Array = TreasureRules.wish_gift(1).items[0]
	assert_gte(inv.count(int(e1[0])), int(e1[1]), "the next day's gift")


func test_a_wish_from_too_far_away_does_nothing() -> void:
	var s := _first(TreasurePlaces.WELL)
	var p := _player(Vector3(s.well) + Vector3(2.5, 0, 0.5))
	_tick()
	var well := director.thing("well_" + s.id)
	p.global_position += Vector3(20, 0, 0)
	Session.request_wish(well.name)
	assert_false(director.state.more.wishes.has(director.treasures.player_key(_me())))


# --- The rainbow's end ---

func _rainbow_player() -> Player:
	var ground := rules.shape.height_at(rules.spawn.x, rules.spawn.y)
	return _player(Vector3(rules.spawn.x + 0.5, ground, rules.spawn.y + 0.5))


func test_a_rainbow_comes_on_the_first_morning_and_its_pot_pays_each_player_once() -> void:
	var p := _rainbow_player()
	time = 0.7
	_tick()
	assert_null(director.thing("rainbow_1"), "no rainbow on the first afternoon")
	_day_passes()
	var arch := director.thing("rainbow_1")
	var pot := director.thing("pot_1")
	assert_not_null(arch, "the first morning's rainbow")
	assert_not_null(pot, "its pot of gold")
	var before := _book(TreasurePlaces.RAINBOW)
	p.global_position = pot.global_position
	_tick()
	assert_eq(Profile.data.survivor_gold, TreasureRules.POT_GOLD, "a fixed pile of gold")
	assert_eq(_book(TreasurePlaces.RAINBOW), before + 1)
	assert_gte(Session.inventory_of(_me()).count(BlockIds.RED), TreasureRules.POT_BLOCKS, "rainbow blocks")
	p.global_position += Vector3(10, 0, 0)
	_tick()
	p.global_position = pot.global_position
	_tick()
	assert_eq(Profile.data.survivor_gold, TreasureRules.POT_GOLD, "once per rainbow")
	director.host_tick(TreasureRules.RAINBOW_STAY + 1.0)
	assert_null(director.thing("rainbow_1"), "the rainbow fades")
	assert_null(director.thing("pot_1"))


## Cosmos (spec §21b.2): no rainbows where there is no rain (the space worlds: the Moon, Mars, …).
func test_no_rainbow_in_a_world_without_rain() -> void:
	_rainbow_player()
	director.treasures.rainbows = false
	time = 0.7
	_tick()
	_day_passes()
	assert_null(director.thing("rainbow_1"), "no rainbow in the morning")
	director.treasures.rain_ended()
	_tick()
	assert_null(director.thing("rainbow_1"), "nor after rain")
	assert_ne(director.treasures.rainbow_now(), director.treasures.RAINBOW_WORDS, "nor from the cheat")


func test_the_rainbow_and_its_pot_stay_even_when_players_walk_away() -> void:
	var p := _rainbow_player()
	_day_passes()
	p.global_position += Vector3(300, 0, 0)
	_tick()
	assert_not_null(director.thing("rainbow_1"), "a rainbow is seen from far away")


func test_after_rain_a_rainbow_comes_but_only_in_daylight() -> void:
	_rainbow_player()
	time = 0.02
	_tick()
	director.treasures.rain_ended()
	assert_null(director.thing("rainbow_1"), "not at night")
	time = DayCycle.NOON
	_tick()
	director.treasures.rain_ended()
	assert_not_null(director.thing("rainbow_1"), "after rain by day")


# --- Hints ---

func test_pets_are_led_to_the_packs_chests_but_never_to_locked_ones() -> void:
	var camp := _first(TreasurePlaces.CAMP)
	var near := Vector3(camp.chest) + Vector3(3.5, 0, 0.5)
	var got := director.nearest_buried_chest(near)
	var best := INF
	for s: Dictionary in rules.secrets_near(near, 200.0):
		if TreasureRules.SNIFF_KINDS.has(s.kind) and s.has("chest"):
			best = minf(best, Vector2(s.chest.x + 0.5 - near.x, s.chest.z + 0.5 - near.z).length())
	assert_almost_eq(Vector2(got.x - near.x, got.z - near.z).length(), best, 0.01, "the nearest unlocked chest")
	var vault := _first(TreasurePlaces.VAULT)
	var at_vault := director.nearest_buried_chest(Vector3(vault.chest))
	assert_ne(Vector3i(at_vault.floor()), vault.chest as Vector3i, "never a locked vault")


func test_slash_secret_knows_the_pack() -> void:
	var camp := _first(TreasurePlaces.CAMP)
	var line := director.hint(TreasurePlaces.CAMP, Vector3(camp.anchor) + Vector3(30, 0, 0))
	assert_string_contains(line, "campsite")
	assert_string_contains(line, "/tp")
	_rainbow_player()
	var r := director.hint(TreasurePlaces.RAINBOW, Vector3(rules.spawn.x, 40, rules.spawn.y))
	assert_string_contains(r, "rainbow")
	assert_not_null(director.thing("rainbow_1"), "/secret rainbow brings one")


func test_explorer_bots_say_what_they_spotted() -> void:
	var bots := FakeBots.new()
	bots.add_to_group(&"bot_director")
	add_child_autofree(bots)
	var s := _first(TreasurePlaces.SHIPWRECK)
	_player(Vector3(s.anchor) + Vector3(3.5, 0, 0.5))
	_tick()
	assert_true(bots.said.has("Look! An old ship!"), str(bots.said))
