extends GutTest
## Bot friends in a world (M2 Task 15, owner feedback #18): up to three, added and removed by the
## host's BotDirector; they follow and catch up, pick behaviours by personality, fight monsters
## through the host's CombatDirector, are knocked out and come back, never take the player's things,
## are saved with the world, decide ten times a second and rest when nobody is near.
## Solo play (OfflineMultiplayerPeer): this game is the host. Monsters are stand-ins for Task 4's
## (group "monsters", take_hit(damage, from, knockback)).

## Stone below GROUND, air above; edits are recorded (and announced like the real world).
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}
	var edits: Array = []
	var loaded := true

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		edits.append([pos, id])
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for z in size.z:
			for x in size.x:
				for y in size.y:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return loaded


## Stands in for Task 4's monsters.
class FakeMonster:
	extends Node3D
	var hp := 100
	var hits: Array = []

	func take_hit(damage: int, from: Vector3, knockback: Vector3) -> void:
		hits.append([damage, from, knockback])
		hp -= damage
		if hp <= 0:
			queue_free()


class FakeAnimal:
	extends Node3D
	var pushes: Array[Vector3] = []

	func knockback(impulse: Vector3) -> void:
		pushes.append(impulse)


const STEP := 1.0 / 60.0

var world: FlatWorld
var combat: CombatDirector
var leader: Player
var director: BotDirector
var lines: Array[Dictionary] = []
var _container: Node3D
var _session_world: WorldService
var _mode: StringName
var _style: String


func before_each() -> void:
	_session_world = Session.world
	_mode = Game.mode
	_style = str(Profile.data.settings.style)
	Profile.data.settings.style = "blocky"
	Game.mode = ModeRules.SANDBOX
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)
	lines.clear()
	Session.chat_received.connect(_on_chat)


func after_each() -> void:
	Session.chat_received.disconnect(_on_chat)
	Session.world = _session_world
	Game.mode = _mode
	Profile.data.settings.style = _style
	Session.survivor_reset()


func _on_chat(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func _lines_from(bot: BotFriend) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for l in lines:
		if l.from == BotRules.chat_name(bot.bot_name):
			out.append(l)
	return out


## A flat, solid floor with its top at y = GROUND (bots walk on real physics).
func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, FlatWorld.GROUND - 0.5, 0)


## This game's player standing still at `pos` (the bots' leader).
func _leader_at(pos: Vector3 = Vector3(0.5, FlatWorld.GROUND, 0.5)) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	leader = p
	return p


func _director() -> BotDirector:
	_container = Node3D.new()
	add_child_autofree(_container)
	combat = CombatDirector.new()
	combat.name = "Combat"
	add_child_autofree(combat)
	combat.block_at = world.get_block
	var d := BotDirector.new()
	d.container = _container
	d.world = world
	d.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		b.combat = combat
		_container.add_child(b)
		return b
	add_child_autofree(d)
	director = d
	return d


## A leader, a director and one bot of `personality` standing at `at`.
func _bot(personality: StringName, at: Vector3 = Vector3.INF) -> BotFriend:
	if leader == null or not is_instance_valid(leader):
		_leader_at()
	if director == null or not is_instance_valid(director):
		_director()
	await get_tree().physics_frame   # players join the shared list between frames
	var b := director.add(personality)
	if at.is_finite():
		b.global_position = at
	return b


func _monster(pos: Vector3) -> FakeMonster:
	var m := FakeMonster.new()
	m.add_to_group(&"monsters")
	add_child_autofree(m)
	m.global_position = pos
	return m


func _steps(b: BotFriend, n: int, delta: float = STEP) -> void:
	for i in n:
		if not is_instance_valid(b):
			return
		b._physics_process(delta)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Adding and removing friends ---

func test_up_to_three_friends_each_with_a_name_and_a_look_of_their_own() -> void:
	var a := await _bot(BotRules.BUILDER)
	var b := director.add(BotRules.EXPLORER)
	var c := director.add(BotRules.FIGHTER)
	assert_not_null(b)
	assert_not_null(c)
	assert_null(director.add(BotRules.FIGHTER), "a fourth friend is refused")
	assert_false(director.can_add())
	assert_eq(director.bots().size(), 3)
	var names := {}
	var looks := {}
	for bot in [a, b, c]:
		names[bot.bot_name] = true
		looks[bot.look] = true
		assert_true(bot.is_in_group(&"bots"), "monsters can find it")
		assert_lte(_flat(bot.global_position, leader.global_position), 2.5, "appears next to the player")
		assert_true(BotRules.NAMES.has(bot.bot_name))
	assert_eq(names.size(), 3)
	assert_eq(looks.size(), 3)
	assert_eq([a.personality, b.personality, c.personality], [BotRules.BUILDER, BotRules.EXPLORER, BotRules.FIGHTER])


func test_removing_a_friend_makes_room_for_another() -> void:
	var a := await _bot(BotRules.BUILDER)
	director.add(BotRules.EXPLORER)
	director.add(BotRules.FIGHTER)
	assert_true(director.remove(a.bot_name))
	assert_true(a.is_queued_for_deletion())
	assert_eq(director.bots().size(), 2)
	assert_true(director.can_add())
	assert_false(director.remove("Nobody"))
	assert_eq(_lines_from(a).back().text, BotRules.line(&"bye", a.personality, 0, a.bot_name), "says bye")
	assert_not_null(director.add(BotRules.BUILDER))


func test_a_new_friend_says_hello_in_the_chat_marked_as_a_bot() -> void:
	var a := await _bot(BotRules.FIGHTER)
	var said := _lines_from(a)
	assert_eq(said.size(), 1)
	assert_eq(said[0].kind, &"bot")
	assert_eq(said[0].from, "%s (bot)" % a.bot_name)
	assert_string_contains(said[0].text, a.bot_name)


func test_at_most_one_line_per_friend_every_twenty_seconds() -> void:
	var a := await _bot(BotRules.EXPLORER)
	assert_false(a.say(&"win"), "just said hello")
	a.clock += BotRules.CHAT_GAP - 0.5
	assert_false(a.say(&"win"))
	a.clock += 0.5
	assert_true(a.say(&"win"))
	assert_eq(_lines_from(a).size(), 2)


func test_friends_wear_a_bot_badge_and_their_own_colours() -> void:
	var a := await _bot(BotRules.BUILDER)
	var b := director.add(BotRules.EXPLORER)
	assert_not_null(a.find_child("BotBadge", true, false), "a robot badge over the name")
	var tag := a.find_child("NameTag", true, false) as Label3D
	assert_string_contains(tag.text, a.bot_name)
	assert_true(a.avatar is BotBlockyAvatar)
	assert_not_null(a.avatar.find_child("Antenna", true, false))
	var ta := _torso(a)
	var tb := _torso(b)
	assert_ne(ta, tb, "each friend its own shirt")
	var again := BotBlockyAvatar.new()
	again.bot_look = a.look
	add_child_autofree(again)
	assert_same(_torso_of(again), ta, "the same colour is one shared material")


func _torso(b: BotFriend) -> Material:
	return _torso_of(b.avatar as BotBlockyAvatar)


func _torso_of(av: BotBlockyAvatar) -> Material:
	var torso_color: Color = av.colors().torso
	for mi: MeshInstance3D in av.find_children("*", "MeshInstance3D", true, false):
		var m := mi.material_override as StandardMaterial3D
		if m and m.albedo_color == torso_color and (mi.mesh as BoxMesh).size == Vector3(0.62, 0.72, 0.32):
			return m
	return null


func test_friends_follow_this_devices_style() -> void:
	Profile.data.settings.style = "realistic"
	var a := await _bot(BotRules.FIGHTER)
	assert_true(a.avatar is BotRealisticAvatar, "a real-looking person in the REALISTIC style")
	var skin := (a.avatar as BotRealisticAvatar).body_mesh().get_surface_override_material(0) as StandardMaterial3D
	assert_eq(skin.albedo_texture.resource_path, BotRealisticAvatar.skin_path(a.look), "its own dyed shirt")
	Profile.data.settings.style = "blocky"
	Game.settings_applied.emit(Profile.data.settings)
	assert_true(a.avatar is BotBlockyAvatar, "switches with the setting")
	assert_eq(a.avatar.name, &"Avatar")


func test_every_look_has_a_realistic_skin() -> void:
	for i in BotRules.LOOKS.size():
		assert_true(ResourceLoader.exists(BotRealisticAvatar.skin_path(i)), BotRealisticAvatar.skin_path(i))


func test_state_is_sent_to_guests_only_when_it_changes() -> void:
	var a := await _bot(BotRules.FIGHTER)
	var cfg := (a.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop: String in [".:held_item", ".:knocked_out", ".:pointing"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE, prop)
		assert_true(cfg.property_get_spawn(NodePath(prop)), prop)
	for prop: String in [".:position", ".:rotation"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ALWAYS, prop)


# --- Following ---

func test_follows_back_to_a_comfortable_distance() -> void:
	_ground()
	var a := await _bot(BotRules.FIGHTER, Vector3(9.5, FlatWorld.GROUND, 0.5))
	await get_tree().physics_frame
	_steps(a, 180)
	var d := _flat(a.global_position, leader.global_position)
	assert_lte(d, BotRules.follow_far(BotRules.FIGHTER), "walked back")
	assert_gte(d, 1.0, "but not onto the player")
	assert_almost_eq(a.global_position.y, float(FlatWorld.GROUND), 0.2, "on its feet")


func test_pops_up_next_to_the_player_when_far_behind() -> void:
	_ground()
	var a := await _bot(BotRules.BUILDER, Vector3(60.5, FlatWorld.GROUND, 0.5))
	await get_tree().physics_frame
	var before := a.decisions
	while a.decisions == before:
		_steps(a, 1)
	assert_lte(_flat(a.global_position, leader.global_position), 2.5)
	assert_between(a.global_position.y, FlatWorld.GROUND - 0.01, SpawnRules.spawn_y(FlatWorld.GROUND) + 0.01,
		"standing on the ground, never inside a block")
	_steps(a, 30)
	assert_almost_eq(a.global_position.y, float(FlatWorld.GROUND), 0.1, "on the ground")


func test_waits_for_the_ground_before_catching_up() -> void:
	var a := await _bot(BotRules.BUILDER, Vector3(60.5, 40, 0.5))
	world.loaded = false
	_steps(a, 30)
	assert_eq(a.global_position, Vector3(60.5, 40, 0.5), "rests where it is until the player's ground is there")


func test_decides_ten_times_a_second() -> void:
	var a := await _bot(BotRules.EXPLORER)
	var before := a.decisions
	_steps(a, 60)
	assert_between(a.decisions - before, 9, 11)


func test_rests_when_no_player_is_near() -> void:
	_director()
	var b := BotFriend.new()
	b.setup({"id": "Bot9", "name": "Pip", "personality": "explorer", "look": 0, "pos": Vector3(3, 40, 3), "yaw": 0.0})
	b.world = world
	add_child_autofree(b)
	_steps(b, 60)
	assert_eq(b.global_position, Vector3(3, 40, 3), "nobody here: it rests and costs nothing")
	assert_eq(b.behaviour, BotRules.IDLE)


# --- Personalities ---

func test_fighters_go_for_monsters_that_builders_leave_alone() -> void:
	var f := await _bot(BotRules.FIGHTER)
	var b := director.add(BotRules.BUILDER)
	_monster(leader.global_position + Vector3(10, 0, 0))
	_steps(f, 8)
	_steps(b, 8)
	assert_eq(f.behaviour, BotRules.FIGHT)
	assert_ne(b.behaviour, BotRules.FIGHT)
	assert_eq(ItemIds.SWORD, f.held_item)
	assert_eq(ItemIds.HAMMER, b.held_item)


func test_fighters_hit_monsters_by_the_hosts_rules_and_nobody_else() -> void:
	_ground()
	var f := await _bot(BotRules.FIGHTER, Vector3(0.5, FlatWorld.GROUND, 3.5))
	var m := _monster(Vector3(0.5, FlatWorld.GROUND, 1.8))
	var pet := FakeAnimal.new()
	pet.add_to_group(&"animals")
	add_child_autofree(pet)
	pet.global_position = Vector3(1.0, FlatWorld.GROUND + 0.2, 2.2)
	watch_signals(Session)
	await get_tree().physics_frame
	_steps(f, 120)
	assert_gt(m.hits.size(), 0, "the monster was hit")
	assert_lte(m.hits.size(), ceili(2.0 / BotRules.ATTACK_EVERY) + 1, "at a friendly pace")
	var hit: Array = m.hits[0]
	assert_eq(hit[0], WeaponRules.damage_to(WeaponRules.MONSTER, BotRules.WEAPON), "the weapon table's damage")
	assert_gt(Vector2(hit[2].x, hit[2].z).length(), 0.0, "pushed back")
	assert_eq(pet.pushes.size(), 0, "never hits animals")
	assert_signal_not_emitted(Session, "knocked_back", "never hits the player")


func test_a_friend_never_hits_through_walls() -> void:
	await _bot(BotRules.FIGHTER)
	var m := _monster(Vector3(0.5, FlatWorld.GROUND, -1.5))
	for x in range(-3, 4):
		for y in range(FlatWorld.GROUND, FlatWorld.GROUND + 3):
			world.cells[Vector3i(x, y, 0)] = BlockIds.STONE
	var origin := Vector3(0.5, FlatWorld.GROUND + 1.0, 1.5)
	assert_eq(combat.bot_melee(origin, Vector3.FORWARD, BotRules.WEAPON), [])
	world.cells.clear()
	assert_eq(combat.bot_melee(origin, Vector3.FORWARD, BotRules.WEAPON).size(), 1)
	assert_eq(m.hits.size(), 1)


func test_a_friends_swing_skips_players_animals_and_buddies() -> void:
	await _bot(BotRules.FIGHTER)
	var pet := FakeAnimal.new()
	pet.add_to_group(&"animals")
	add_child_autofree(pet)
	pet.global_position = Vector3(0.5, FlatWorld.GROUND, -0.5)
	watch_signals(Session)
	var hits := combat.bot_melee(leader.global_position + Vector3(0, 1, 1.5), Vector3.FORWARD, BotRules.WEAPON)
	assert_eq(hits, [])
	assert_eq(pet.pushes.size(), 0)
	assert_signal_not_emitted(Session, "knocked_back")


func test_players_weapons_pass_through_friends() -> void:
	var a := await _bot(BotRules.FIGHTER)
	for thing in CombatDirector.hittables(get_tree()):
		assert_ne(thing.node, a, "a player's swing never hits a friend")


func test_a_friend_cheers_when_its_monster_is_gone() -> void:
	_ground()
	var f := await _bot(BotRules.FIGHTER)
	var m := _monster(f.global_position + Vector3(0, 0, -1.2))
	m.hp = WeaponRules.damage_to(WeaponRules.MONSTER, BotRules.WEAPON) + 1   # two swings
	f.clock = 100.0
	await get_tree().physics_frame
	for i in 60:
		_steps(f, 1)
		if m.hits.size() == 1:
			break
	assert_eq(m.hits.size(), 1, "first swing")
	f.clock += BotRules.CHAT_GAP        # "Watch out!" was the last line; room for another
	_steps(f, 60)
	await get_tree().process_frame
	_steps(f, 4)
	assert_false(is_instance_valid(m), "defeated")
	var said: Array = _lines_from(f).map(func(l: Dictionary) -> String: return l.text)
	assert_true(said.any(func(t: String) -> bool: return BotRules.LINES[&"win"].has(t)), "cheers: %s" % [said])


func test_explorers_point_at_shiny_things_they_find() -> void:
	_ground()
	world.cells[Vector3i(4, FlatWorld.GROUND - 1, 3)] = BlockIds.GOLD
	var e := await _bot(BotRules.EXPLORER)
	e.clock = 100.0
	await get_tree().physics_frame
	var pointed := false
	for i in 400:
		_steps(e, 1)
		pointed = pointed or e.pointing
	assert_true(pointed, "went over and pointed")
	var said: Array = _lines_from(e).map(func(l: Dictionary) -> String: return l.text)
	assert_has(said, "Look! Something shiny over here!")


func test_the_secrets_hook_only_explorers_answer() -> void:
	var e := await _bot(BotRules.EXPLORER)
	var b := director.add(BotRules.BUILDER)
	var spot := leader.global_position + Vector3(6, 0, 2)
	assert_false(b.notice(spot), "builders don't point")
	assert_false(e.notice(leader.global_position + Vector3(BotRules.NOTICE_RADIUS + 5.0, 0, 0)), "too far from the player")
	assert_true(e.notice(spot, "A secret room!"))
	_steps(e, 8)
	assert_eq(e.behaviour, BotRules.POINT)
	assert_true(director.notice(spot + Vector3(1, 0, 0)), "the director asks an explorer")


## Found by the bots smoke run: an explorer that had spotted something kept walking back to it
## after the player jumped far away, popping up next to the player and walking off again.
func test_an_explorer_forgets_what_it_saw_when_the_player_moves_far_away() -> void:
	_ground()
	var e := await _bot(BotRules.EXPLORER)
	assert_true(e.notice(leader.global_position + Vector3(8, 0, 0)))
	_steps(e, 8)
	assert_eq(e.behaviour, BotRules.POINT)
	leader.global_position += Vector3(60, 0, 0)
	await get_tree().physics_frame
	_steps(e, 60)
	assert_ne(e.behaviour, BotRules.POINT, "gave it up")
	assert_lte(_flat(e.global_position, leader.global_position), BotRules.follow_far(BotRules.EXPLORER), "stays with the player")


func test_builders_build_next_to_the_players_build() -> void:
	_ground()
	var anchor := Vector3i(3, FlatWorld.GROUND, 0)
	var b := await _bot(BotRules.BUILDER)
	world.set_block(anchor, BlockIds.BRICK)          # the player builds (the director notices)
	world.edits.clear()
	b._build_t = 0.0
	b.clock = 100.0
	await get_tree().physics_frame
	for i in 600:
		_steps(b, 1)
		if not world.edits.is_empty():
			break
	assert_between(world.edits.size(), 2, BotRules.MAX_BUILD_BLOCKS, "a small build")
	assert_eq(world.get_block(anchor), BlockIds.BRICK, "the player's block is untouched")
	for e: Array in world.edits:
		var pos: Vector3i = e[0]
		assert_gte(Vector2(pos.x - anchor.x, pos.z - anchor.z).length(), float(BotRules.BUILD_GAP), "next to it, not on it")
		assert_lte(Vector2(pos.x - anchor.x, pos.z - anchor.z).length(), 7.0)
	var said: Array = _lines_from(b).map(func(l: Dictionary) -> String: return l.text)
	assert_true(said.any(func(t: String) -> bool: return BotRules.LINES[&"build"].has(t)), "tells the player: %s" % [said])
	assert_eq(director.build_anchor(leader.global_position), anchor, "its own build is not the player's")


func test_survivor_friends_never_take_the_players_things() -> void:
	Game.mode = ModeRules.SURVIVOR
	_ground()
	var gold_before := Profile.data.survivor_gold
	var b := await _bot(BotRules.BUILDER)
	var inv := Inventory.starter_kit()
	Session.set_inventory(leader.peer_id, inv)
	var kit := inv.to_save()
	world.set_block(Vector3i(3, FlatWorld.GROUND, 0), BlockIds.PLANKS)
	world.edits.clear()
	b._build_t = 0.0
	await get_tree().physics_frame
	for i in 600:
		_steps(b, 1)
		if not world.edits.is_empty():
			break
	assert_gt(world.edits.size(), 0)
	for e: Array in world.edits:
		assert_eq(e[1], BlockIds.LEAVES, "leaves only: nothing anyone can gather")
	assert_eq(Session.inventory_of(leader.peer_id).to_save(), kit, "the player's blocks are untouched")
	assert_eq(Profile.data.survivor_gold, gold_before, "and their gold")
	assert_false(b.is_in_group(&"players"), "coins, bags and wave rewards go to players only")


func test_the_host_edit_path_only_fills_empty_cells() -> void:
	_leader_at()
	world.cells[Vector3i(5, FlatWorld.GROUND, 5)] = BlockIds.BRICK
	var eye := Vector3(4.5, FlatWorld.GROUND + 1.6, 4.5)
	var changes := [[Vector3i(5, FlatWorld.GROUND, 5), BlockIds.RED], [Vector3i(6, FlatWorld.GROUND, 5), BlockIds.RED],
		[Vector3i(5, FlatWorld.GROUND - 1, 5), BlockIds.AIR], [Vector3i(40, FlatWorld.GROUND, 5), BlockIds.RED],
		[Vector3i(0, FlatWorld.GROUND, 0), BlockIds.RED]]
	assert_eq(Session.bot_set_blocks(changes, eye), 1)
	assert_eq(world.get_block(Vector3i(5, FlatWorld.GROUND, 5)), BlockIds.BRICK, "never replaces a block")
	assert_eq(world.get_block(Vector3i(6, FlatWorld.GROUND, 5)), BlockIds.RED)
	assert_eq(world.get_block(Vector3i(5, FlatWorld.GROUND - 1, 5)), BlockIds.STONE, "never breaks one")
	assert_eq(world.get_block(Vector3i(40, FlatWorld.GROUND, 5)), BlockIds.AIR, "within reach only")
	assert_eq(world.get_block(Vector3i(0, FlatWorld.GROUND, 0)), BlockIds.AIR, "never inside the player")


# --- Knocked out and back ---

func test_monsters_hurt_friends_through_the_bots_group() -> void:
	var a := await _bot(BotRules.EXPLORER)
	assert_has(get_tree().get_nodes_in_group(&"bots"), a)
	a.hurt(3, a.global_position + Vector3(1, 0, 0))
	assert_eq(a.health.hp, Health.MAX_HP - 3)
	assert_lt(a.velocity.x, 0.0, "pushed away from the hit")


func test_knocked_out_friends_come_back_after_ten_seconds() -> void:
	var a := await _bot(BotRules.FIGHTER, Vector3(8.5, FlatWorld.GROUND, 0.5))
	a.hurt(Health.MAX_HP, Vector3.ZERO)
	assert_true(a.knocked_out)
	assert_false(a.is_in_group(&"bots"), "monsters stop chasing it")
	assert_true(a.is_in_group(&"bot_friends"), "still one of the team")
	a._process(STEP)
	assert_false(a.visible)
	a.hurt(5, Vector3.ZERO)
	assert_eq(a.health.hp, 0, "nothing more happens while knocked out")
	_steps(a, 19, 0.5)
	assert_true(a.knocked_out, "9.5 s: still out")
	_steps(a, 2, 0.5)
	assert_false(a.knocked_out, "back after 10 s")
	assert_eq(a.health.hp, Health.MAX_HP)
	assert_true(a.health.is_protected())
	assert_true(a.is_in_group(&"bots"))
	assert_lte(_flat(a.global_position, leader.global_position), 2.5, "next to the player")
	a._process(STEP)
	assert_true(a.visible)


func test_friends_count_for_boss_health_like_players() -> void:
	var a := await _bot(BotRules.FIGHTER)
	director.add(BotRules.BUILDER)
	assert_eq(BotFriend.team_size(get_tree()), 3)
	a.hurt(Health.MAX_HP, Vector3.ZERO)
	assert_eq(BotFriend.team_size(get_tree()), 3, "a knocked-out friend still counts")


# --- Saving ---

func test_friends_are_saved_with_the_world_and_come_back() -> void:
	await _bot(BotRules.BUILDER)
	director.add(BotRules.FIGHTER)
	var saved := director.to_save()
	assert_eq(saved.size(), 2)
	var meta := WorldMeta.new_random()
	meta.bots = saved
	var back := WorldMeta.from_json(meta.to_json())
	var before: Array = director.bots().map(func(b: BotFriend) -> Array: return [b.bot_name, b.personality, b.look])
	for b in director.bots():
		b.free()
	director.restore(back.bots)
	var after: Array = director.bots().map(func(b: BotFriend) -> Array: return [b.bot_name, b.personality, b.look])
	assert_eq(after, before)


# --- The pause menu's FRIENDS row ---

func _button(root: Node, button_name: String) -> Button:
	return root.find_child(button_name, true, false) as Button


func test_the_friends_panel_adds_and_removes_friends() -> void:
	_leader_at()
	_director()
	await get_tree().physics_frame
	var panel := FriendsPanel.new()
	panel.director = director
	add_child_autofree(panel)
	assert_not_null(_button(panel, "AddBuilder"))
	_button(panel, "AddBuilder").pressed.emit()
	_button(panel, "AddExplorer").pressed.emit()
	assert_eq(director.bots().size(), 2)
	var pip := director.bots()[0]
	assert_not_null(_button(panel, "Bye%s" % pip.bot_name), "a row per friend with a BYE button")
	_button(panel, "AddFighter").pressed.emit()
	assert_eq(director.bots().size(), 3)
	for add in ["AddBuilder", "AddExplorer", "AddFighter"]:
		assert_true(_button(panel, add).disabled, "three friends: no more")
	var pip_name := pip.bot_name
	var bye := _button(panel, "Bye%s" % pip_name)
	bye.pressed.emit()
	assert_eq(director.bots().size(), 2)
	assert_true(is_instance_valid(bye) and bye.is_inside_tree(), "its row stays while the tap is handled")
	await get_tree().process_frame
	assert_null(_button(panel, "Bye%s" % pip_name), "then the row is gone")
	assert_false(_button(panel, "AddBuilder").disabled)
	watch_signals(panel)
	_button(panel, "Back").pressed.emit()
	assert_signal_emitted(panel, "closed")


func test_the_pause_menu_has_a_friends_row_for_the_host() -> void:
	_leader_at()
	_director()
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu._show_buttons()
	await get_tree().process_frame
	assert_null(_button(menu, "Friends"), "a guest (no director) has no FRIENDS row")
	menu.friends = director
	menu._show_buttons()
	await get_tree().process_frame
	var row := _button(menu, "Friends")
	assert_not_null(row)
	assert_string_contains(row.text, "0/%d" % BotRules.MAX_BOTS)
	row.pressed.emit()
	await get_tree().process_frame
	assert_eq(menu.find_children("*", "FriendsPanel", true, false).size(), 1, "the FRIENDS panel opens")
