extends GutTest
## M2 Task 16: secrets in a world, through the host's SecretDirector and Session (solo play: this game is
## the host). The world is a stub: SecretRules' blocks, plus whatever the director changed.

## Stands in for Task 15's BotDirector (explorer bots walk over and point at a secret).
class FakeBots:
	extends Node
	var points: Array[Vector3] = []

	func notice(point: Vector3, _text: String = "") -> bool:
		points.append(point)
		return true


const SEED := 12345

var director: SecretDirector
var rules: SecretRules
var cells := {}                   # blocks the director changed
var time := DayCycle.NOON
var feedback: Array[String] = []
var _indoors := false
var _mode_before: StringName
var _gold_before := 0
var _book_before := {}
var _shelf_before: Array[int] = []


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
	director = _director(SecretState.new())


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.secret_book = _book_before
	Profile.data.treasures = _shelf_before
	Session.survivor_reset()


func _on_feedback(text: String) -> void:
	feedback.append(text)


func _block(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	var id := rules.block_at(p)
	return id if id >= 0 else BlockIds.AIR


func _director(state: SecretState) -> SecretDirector:
	var d := SecretDirector.new()
	d.name = "Secrets"
	d.auto_tick = false
	d.block_at = _block
	d.set_block = func(p: Vector3i, id: int) -> void: cells[p] = id
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.ground_at = rules.shape.height_at
	d.standing_y = rules.shape.height_at
	d.time_of_day = func() -> float: return time
	d.save_profile = func() -> void: pass
	add_child_autofree(d)
	d.setup(SEED, state)
	return d


## This game's own player, standing still at `feet`.
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
	for az in range(-6, 6):
		for ax in range(-6, 6):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				if s.kind == kind:
					return s
	fail_test("no %s" % kind)
	return {}


func _book(kind: StringName) -> int:
	return int(Profile.data.secret_book.get(String(kind), 0))


func _tick() -> void:
	director.host_tick(SecretDirector.TICK)


# --- Chests ---

func test_chests_come_near_players_and_go_when_nobody_is_near() -> void:
	var s := _first(SecretRules.TREASURE)
	var p := _player(Vector3(s.chest) + Vector3(3.5, 5, 0.5))
	_tick()
	var chest := director.thing("chest_" + s.id) as TreasureChest
	assert_not_null(chest)
	assert_eq(chest.cell(), s.chest as Vector3i)
	assert_false(chest.opened)
	assert_eq(chest.rarity, LootRules.roll(&"buried", LootRules.chest_key(SEED, s.chest), 1, true).rarity, "glows in its loot's rarity")
	p.global_position += Vector3(500, 0, 0)
	_tick()
	assert_null(director.thing("chest_" + s.id), "nobody near: gone")


func test_a_chest_opens_once_and_the_world_remembers() -> void:
	var s := _first(SecretRules.TREASURE)
	_player(Vector3(s.chest) + Vector3(1.5, 0, 0.5))
	_tick()
	var loot := LootRules.roll(&"buried", LootRules.chest_key(SEED, s.chest), 1, true)
	var before := _book(SecretRules.TREASURE)
	Session.request_open_chest("chest_" + s.id)
	assert_eq(Profile.data.survivor_gold, int(loot.gold), "the treasure's gold")
	var block: Array = loot.items[0]
	assert_eq(Session.inventory_of(multiplayer.get_unique_id()).count(block[0]), int(block[1]), "and its rare blocks")
	assert_true(director.state.opened.has(s.id))
	assert_true((director.thing("chest_" + s.id) as TreasureChest).opened)
	assert_true(director.state.found.has(s.id), "opening a buried treasure finds it")
	assert_eq(_book(SecretRules.TREASURE), before + 1, "the Secret Book counts it")
	Session.request_open_chest("chest_" + s.id)
	assert_eq(Profile.data.survivor_gold, int(loot.gold), "never twice")
	assert_string_contains(feedback.back(), "opened it already")
	var saved := SecretState.from_save(JSON.parse_string(JSON.stringify(director.state.to_save())))
	director.free()
	director = _director(saved)
	_tick()
	assert_true((director.thing("chest_" + s.id) as TreasureChest).opened, "after a reload it is still open")


func test_sandbox_treasure_has_no_gold_but_fills_the_shelf() -> void:
	Game.mode = ModeRules.SANDBOX
	var s := _first(SecretRules.ISLAND)
	_player(Vector3(s.chest) + Vector3(1.5, 0, 0.5))
	_tick()
	var loot := LootRules.roll(&"sky", LootRules.chest_key(SEED, s.chest), 1, false)
	Session.request_open_chest("chest_" + s.id)
	assert_eq(Profile.data.survivor_gold, 0)
	for e: Array in loot.items:
		if LootRules.TREASURE_ONLY.has(int(e[0])):
			assert_true(Profile.data.treasures.has(int(e[0])), "on the Secret Book's shelf: %s" % ItemIds.display_name(e[0]))


func test_a_treasure_map_points_to_the_next_buried_chest_and_is_used_up() -> void:
	var s := _first(SecretRules.TREASURE)
	var p := _player(Vector3(s.chest) + Vector3(1.5, 0, 0.5))
	assert_eq(director.map_target(p.global_position).get("id"), s.id, "the nearest unopened buried treasure")
	var inv := Session.inventory_of(multiplayer.get_unique_id())
	inv.add(ItemIds.TREASURE_MAP, 1)
	_tick()
	var loot := LootRules.roll(&"buried", LootRules.chest_key(SEED, s.chest), 1, true)
	var found_map := (loot.items as Array).any(func(e: Array) -> bool: return e[0] == ItemIds.TREASURE_MAP)
	Session.request_open_chest("chest_" + s.id)
	assert_eq(inv.count(ItemIds.TREASURE_MAP), 1 if found_map else 0, "the map that led here crumbles")
	assert_ne(director.map_target(p.global_position).get("id"), s.id, "now it points to the next one")


# --- Temples ---

func _step(p: Player, s: Dictionary, plate: int) -> void:
	var cell: Vector3i = s.plates[plate]
	p.global_position = Vector3(cell) + Vector3(0.5, BlockLibrary.PLATE_HEIGHT, 0.5)
	director.plate_tick()
	p.global_position = Vector3(s.anchor) + Vector3(0.5, 0, 0.5) + Vector3(s.dir) * 3
	director.plate_tick()


func test_a_temple_opens_only_in_the_riddles_order() -> void:
	var s := _first(SecretRules.TEMPLE)
	var p := _player(Vector3(s.anchor) + Vector3(0.5, 0, 0.5))
	_tick()
	assert_true(director.state.found.has(s.id), "walking in finds the temple")
	var chest := director.thing("chest_" + s.id) as TreasureChest
	assert_true(chest.locked)
	var marks := director.thing("marks_" + s.id)
	assert_not_null(marks, "the plates' pictures")
	assert_not_null(director.thing("note_" + s.id), "the note with the order")
	Session.request_open_chest(chest.name)
	assert_eq(Profile.data.survivor_gold, 0, "locked")
	assert_string_contains(feedback.back(), "Locked")
	var order: Array = s.order
	for plate in [order[1], order[0], order[2]]:
		_step(p, s, plate)
	assert_false(director.state.solved.has(s.id), "the wrong order")
	for v: Vector3i in s.vault:
		assert_eq(_block(v), BlockIds.YELLOW, "the vault stays shut")
	for i in 3:
		_step(p, s, order[i])
	assert_true(director.state.solved.has(s.id))
	for v: Vector3i in s.vault:
		assert_eq(_block(v), BlockIds.AIR, "the vault door opens")
	assert_false(chest.locked)
	Session.request_open_chest(chest.name)
	assert_gt(Profile.data.survivor_gold, 0)


# --- Hidden rooms ---

func test_a_knock_opens_the_fake_wall_and_finds_the_hidden_room() -> void:
	var s := _first(SecretRules.ROOM)
	var wall: Vector3i = s.fake_wall[0]
	_player(Vector3(wall) + Vector3(0.5, -1, 0.5) + Vector3(s.dir) * 2)
	var before := _book(SecretRules.ROOM)
	Session.request_knock(Vector3i(wall.x, wall.y + 6, wall.z))
	assert_eq(cells.size(), 0, "plain stone stays")
	Session.request_knock(wall)
	for c: Vector3i in s.fake_wall:
		assert_eq(_block(c), BlockIds.AIR, "the whole fake wall opens")
	assert_true(director.state.found.has(s.id))
	assert_eq(_book(SecretRules.ROOM), before + 1)


# --- The Wanderer ---

func test_the_wanderer_comes_at_dusk_and_rewards_the_right_answer_once() -> void:
	var ground := rules.shape.height_at(rules.spawn.x, rules.spawn.y)
	var p := _player(Vector3(rules.spawn.x + 0.5, ground, rules.spawn.y + 0.5))
	time = 0.7
	_tick()
	assert_null(director.wanderer(), "not by day")
	time = DayCycle.DUSK_START + 0.01
	_tick()
	var w := director.wanderer()
	assert_not_null(w, "the first dusk brings him")
	assert_eq(director.state.dusks, 1)
	var d := Vector2(w.global_position.x - p.global_position.x, w.global_position.z - p.global_position.z).length()
	assert_between(d, SurpriseRules.WANDERER_MIN_DISTANCE - 1.0, SurpriseRules.WANDERER_MAX_DISTANCE + 1.0)
	var before := _book(SecretRules.WANDERER)
	p.global_position = w.global_position + Vector3(2, 0, 0)
	_tick()
	assert_eq(_book(SecretRules.WANDERER), before + 1, "met him")
	var r := w.question()
	Session.request_wanderer_answer(w.name, (int(r.answer) + 1) % 3)
	assert_eq(Profile.data.survivor_gold, 0)
	assert_false(w.is_queued_for_deletion(), "a wrong answer: he waits for another try")
	assert_string_contains(feedback.back(), "not quite")
	Session.request_wanderer_answer(w.name, int(r.answer))
	var gold := Profile.data.survivor_gold
	assert_gt(gold, 0, "the right answer is rewarded")
	assert_true(w.is_queued_for_deletion(), "then he vanishes in sparkles")
	Session.request_wanderer_answer(w.name, int(r.answer))
	assert_eq(Profile.data.survivor_gold, gold, "only once")


## A child indoors at dusk doesn't miss him: he waits through the dusk for a spot where he can be seen.
func test_the_wanderer_waits_through_the_dusk_for_a_place_to_be_seen() -> void:
	var ground := rules.shape.height_at(rules.spawn.x, rules.spawn.y)
	_player(Vector3(rules.spawn.x + 0.5, ground, rules.spawn.y + 0.5))
	_indoors = true                    # (a lambda copies a local bool: the flag is a member)
	director.standing_y = func(x: int, z: int) -> int: return ground + 50 if _indoors else rules.shape.height_at(x, z)
	time = 0.7
	_tick()
	time = DayCycle.DUSK_START + 0.01
	_tick()
	assert_null(director.wanderer(), "nowhere to be seen yet")
	_indoors = false
	time = DayCycle.DUSK_START + 0.03
	_tick()
	assert_not_null(director.wanderer(), "the child came outside: there he is")
	assert_eq(director.state.dusks, 1, "the same dusk")


func test_a_wanderer_missed_all_dusk_waits_for_another_dusk() -> void:
	var ground := rules.shape.height_at(rules.spawn.x, rules.spawn.y)
	_player(Vector3(rules.spawn.x + 0.5, ground, rules.spawn.y + 0.5))
	director.standing_y = func(_x: int, _z: int) -> int: return ground + 50
	time = 0.7
	_tick()
	time = DayCycle.DUSK_START + 0.01
	_tick()
	time = DayCycle.NIGHT_START + 0.01
	_tick()
	director.standing_y = rules.shape.height_at
	_tick()
	assert_null(director.wanderer(), "night: he did not come this time")


# --- Shooting stars ---

func test_a_star_falls_on_the_first_night_and_leaves_a_meteor() -> void:
	var p := _player(Vector3(rules.spawn.x + 0.5, 60, rules.spawn.y + 0.5))
	var spot := SurpriseRules.star_spot(SEED, 1, p.global_position, rules.shape.height_at)
	var build: Vector3i = (spot.ground as Vector3i) + Vector3i(1, 0, 0)
	cells[build] = BlockIds.BRICK          # a child built something right where it lands
	time = DayCycle.DUSK_START + 0.05
	_tick()
	time = DayCycle.NIGHT_START + 0.01
	_tick()
	assert_eq(director.state.nights, 1)
	director.host_tick(SurpriseRules.STAR_DELAY.y + 1.0)
	director.host_tick(SurpriseRules.STAR_FALL_TIME + 0.1)
	assert_eq(director.state.stars.size(), 1, "it landed")
	var ground: Vector3i = director.state.stars[0]
	assert_eq(ground, spot.ground as Vector3i)
	assert_eq(_block(ground + Vector3i.UP), BlockIds.CRYSTAL, "a glowing meteor")
	assert_eq(_block(build), BlockIds.BRICK, "the build stays")
	var before := _book(SecretRules.STAR)
	p.global_position = Vector3(ground) + Vector3(0.5, 0, 2.5)
	_tick()
	assert_eq(director.state.stars.size(), 0)
	assert_eq(_book(SecretRules.STAR), before + 1, "found the fallen star")


# --- Golden animals ---

func _golden_id(skip: String = "") -> String:
	for i in 4000:
		var id := "a%d_%d_0" % [i, i % 7]
		if id != skip and SurpriseRules.is_golden(SEED, id):
			return id
	fail_test("no golden animal id")
	return ""


func test_a_golden_animal_gives_gold_in_survivor_and_a_trophy_in_sandbox() -> void:
	_player(Vector3(0, 40, 0))
	var id := _golden_id()
	assert_true(director.is_golden_spawn(id))
	director.reward_golden(multiplayer.get_unique_id(), Vector3(1, 40, 1), id)
	assert_between(Profile.data.survivor_gold, LootRules.GOLDEN_GOLD.x, LootRules.GOLDEN_GOLD.y, "a pile of gold")
	assert_false(director.is_golden_spawn(id), "caught: it never comes back golden")
	Game.mode = ModeRules.SANDBOX
	Profile.data.treasures.clear()
	director.reward_golden(multiplayer.get_unique_id(), Vector3(1, 40, 1), _golden_id(id))
	assert_true(Profile.data.treasures.has(BlockIds.TROPHY), "a golden trophy in Sandbox")


# --- The Secret Book, the chime and explorer bots ---

func test_the_secret_book_counts_what_was_found_in_the_explored_areas() -> void:
	var s := _first(SecretRules.TEMPLE)
	_player(Vector3(s.anchor) + Vector3(0.5, 0, 0.5))
	_tick()
	var counts := director.book_counts()
	assert_eq(counts, Vector2i(1, rules.secrets_in_area(s.area).size() + rules.tiny_in_area(s.area).size()),
		"M3 Task 21c: the area's mouse villages count too")


func test_a_secret_chimes_once_when_a_player_comes_within_twelve_blocks() -> void:
	var s := _first(SecretRules.GEODE)
	var bots := FakeBots.new()
	bots.add_to_group(&"bot_director")
	add_child_autofree(bots)
	watch_signals(director)
	var p := _player(Vector3(s.anchor) + Vector3(20.5, 0, 0.5))
	_tick()
	assert_signal_not_emitted(director, "chimed")
	p.global_position = Vector3(s.anchor) + Vector3(9.5, 0, 0.5)
	_tick()
	_tick()
	assert_signal_emit_count(director, "chimed", 1, "once per secret")
	assert_signal_emitted_with_parameters(director, "chimed", [s.id])
	assert_true(director.state.chimed.has(s.id))
	assert_eq(bots.points, [Vector3(s.anchor) + Vector3(0.5, 0.5, 0.5)] as Array[Vector3], "an explorer bot is told")


## /secret (a Sandbox cheat): where the nearest secret of a kind is that nobody found yet.
func test_the_secret_hint_names_the_nearest_unfound_secret() -> void:
	var s := _first(SecretRules.TEMPLE)
	var near := Vector3(s.anchor) + Vector3(30, 0, 0)
	var at: Vector3i = s.anchor
	var hint := director.hint(SecretRules.TEMPLE, near)
	assert_string_contains(hint, "puzzle temple")
	assert_string_contains(hint, "/tp %d %d %d" % [at.x, at.y, at.z])
	director.state.found[s.id] = true
	assert_false(director.hint(SecretRules.TEMPLE, near).contains("/tp %d %d %d" % [at.x, at.y, at.z]), "found ones are skipped")
	assert_ne(director.hint(&"", near), "", "any kind")


func test_secret_things_share_their_meshes() -> void:
	var a := _first(SecretRules.TREASURE)
	_player(Vector3(a.chest) + Vector3(1.5, 0, 0.5))
	_tick()
	var chest := director.thing("chest_" + a.id) as TreasureChest
	var meshes := chest.find_children("*", "MeshInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	for mi: MeshInstance3D in meshes:
		assert_true(mi.mesh == InteractableModels.chest_base(false) or mi.mesh == InteractableModels.chest_lid(false)
			or mi.mesh == InteractableModels.glow_quad(), "a shared mesh")
