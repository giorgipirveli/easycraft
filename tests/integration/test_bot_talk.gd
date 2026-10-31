extends GutTest
## Owner feedback #38 (spec §12.14a): bot friends understand what the child says and asks. The child's words
## go to the host (Session.request_bot_talk), which gives them to the child's own friends (BotDirector.hear):
## they switch behaviour and answer in the chat as bots, from the game's state. Solo (OfflineMultiplayerPeer):
## this game is the host. The world is a flat stand-in (like test_bot_friends.gd); monsters are stand-ins.

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


class FakeMonster:
	extends Node3D
	var hp := 100

	func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
		hp -= damage
		if hp <= 0:
			queue_free()


const STEP := 1.0 / 60.0
const G := float(FlatWorld.GROUND)

var world: FlatWorld
var combat: CombatDirector
var leader: Player
var director: BotDirector
var lines: Array[Dictionary] = []
var _container: Node3D
var _session_world: WorldService
var _mode: StringName
var _style: String
var _time_source: Callable


func before_each() -> void:
	_session_world = Session.world
	_mode = Game.mode
	_style = str(Profile.data.settings.style)
	_time_source = Animal.time_source
	Profile.data.settings.style = "blocky"
	Game.mode = ModeRules.SANDBOX
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)
	Session.bot_talk_reset()
	lines.clear()
	Session.chat_received.connect(_on_chat)
	_ground()


func after_each() -> void:
	Session.chat_received.disconnect(_on_chat)
	Session.world = _session_world
	Session.bot_talk_reset()
	Game.mode = _mode
	Profile.data.settings.style = _style
	Animal.time_source = _time_source
	Session.survivor_reset()


func _on_chat(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func _said(b: BotFriend) -> Array[String]:
	var out: Array[String] = []
	for l in lines:
		if l.from == BotRules.chat_name(b.bot_name) and l.kind == &"bot":
			out.append(str(l.text))
	return out


func _last(b: BotFriend) -> String:
	var said := _said(b)
	return said.back() if not said.is_empty() else ""


func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, G - 0.5, 0)


## A player standing still at `pos`, looking along -Z; peer 0 = this game's own.
func _player(pos: Vector3 = Vector3(0.5, G, 0.5), peer: int = 0) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer if peer > 0 else multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	p.avatar.rotation.y = 0.0
	p.rig.yaw = 0.0
	if peer == 0:
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
		b.set_physics_process(false)   # the test steps it (DEVELOPMENT.md §8)
		return b
	d.add_to_group(&"bot_director")
	add_child_autofree(d)
	d.secret_near = func(_from: Vector3) -> Dictionary: return {}
	director = d
	return d


## A friend of `personality` standing at `at` (the leader and the director first, when there are none).
func _bot(personality: StringName, at: Vector3 = Vector3.INF) -> BotFriend:
	if leader == null or not is_instance_valid(leader):
		_player()
	if director == null or not is_instance_valid(director):
		_director()
	await get_tree().physics_frame   # players join the shared list between frames
	var b := director.add(personality)
	if at.is_finite():
		b.global_position = at
	lines.clear()                      # the hello
	b.clock = 100.0                    # long past its hello: idle lines are allowed again
	b._last_said = -INF
	return b


func _monster(pos: Vector3) -> FakeMonster:
	var m := FakeMonster.new()
	m.add_to_group(&"monsters")
	add_child_autofree(m)
	m.global_position = pos
	return m


func _steps(b: BotFriend, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		if not is_instance_valid(b):
			return
		b._physics_process(STEP)


## The child (peer 0: this game's own player) says `text` to their friends; `fresh`: the chat's rate limit
## starts again (a test says many things at once).
func _say(text: String, peer: int = 0, fresh: bool = true) -> void:
	if fresh:
		Session.bot_talk_reset()
	Session._host_bot_talk(peer if peer > 0 else multiplayer.get_unique_id(), text)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _placed() -> Array:
	return world.edits.filter(func(e: Array) -> bool: return int(e[1]) != BlockIds.AIR)


# --- Requests ---

func test_follow_me_brings_a_friend_close_and_it_answers() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	_steps(b, 1.0)
	assert_gt(_flat(b.global_position, leader.global_position), 8.0, "an explorer roams 15 blocks out on its own")
	_say("follow me")
	assert_eq(_last(b), "OK! I'm right behind you!")
	_steps(b, 4.0)
	assert_lt(_flat(b.global_position, leader.global_position), 4.5, "it came close")


## Owner #52: English only. Words in another language get the English hint, never a translated answer.
func test_the_answer_is_english_whatever_letters_are_typed() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	_say("გამომყევი")
	assert_eq(_last(b), BotAnswers.line(&"hint", BotAnswers.EN, 0))


func test_wait_keeps_a_friend_where_it_is_until_it_is_called() -> void:
	var b := await _bot(BotRules.FIGHTER, Vector3(2.5, G, 0.5))
	_say("wait here")
	assert_eq(_last(b), "OK, I'll wait right here!")
	var post := b.global_position
	leader.global_position = Vector3(30.5, G, 0.5)   # more than the catch-up distance
	await get_tree().physics_frame
	_steps(b, 2.0)
	assert_eq(b.behaviour, BotRules.STAY)
	assert_lt(_flat(b.global_position, post), 1.0, "it waits instead of popping up next to the child")
	_say("come here")
	_steps(b, 0.5)
	assert_lt(_flat(b.global_position, leader.global_position), 4.0, "called: it comes")


func test_a_waiting_friend_comes_along_after_a_while() -> void:
	var b := await _bot(BotRules.FIGHTER, Vector3(2.5, G, 0.5))
	_say("stay")
	leader.global_position = Vector3(30.5, G, 0.5)
	await get_tree().physics_frame
	_steps(b, 1.0)
	assert_eq(b.behaviour, BotRules.STAY)
	b._talk_t = 0.05
	_steps(b, 0.5)
	assert_lt(_flat(b.global_position, leader.global_position), 4.0, "done waiting: back with the child")


func test_go_home_waits_at_the_childs_bed() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	leader.set_home(true, Vector3i(40, FlatWorld.GROUND, 0))
	_say("go home")
	assert_eq(_last(b), "OK! I'll wait for you at home!")
	_steps(b, 0.5)
	assert_lt(_flat(b.global_position, Vector3(40.5, G, 0.5)), 3.0, "far away: it pops over to the bed")
	leader.global_position = Vector3(-30.5, G, 0.5)
	await get_tree().physics_frame
	_steps(b, 2.0)
	assert_lt(_flat(b.global_position, Vector3(40.5, G, 0.5)), 3.0, "and waits there")
	_say("where are you?")
	assert_eq(_last(b), "I'm at your home! Say come here and I'll come.")


func test_go_home_without_a_home_says_how_to_make_one() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	_say("go home")
	assert_eq(_last(b), BotAnswers.line(&"no_home", BotAnswers.EN))
	assert_eq(b.talk_order(), &"")


func test_give_me_space_moves_a_friend_back() -> void:
	var b := await _bot(BotRules.FIGHTER, Vector3(1.5, G, 0.5))
	var space := b.style.space
	_say("give me some space")
	assert_eq(_last(b), "OK! I'll give you some space.")
	assert_gt(b.style.space, space, "it keeps more space from now on")
	_steps(b, 3.0)
	assert_gt(_flat(b.global_position, leader.global_position), 4.0)


func test_build_a_house_goes_up_in_steps_next_to_the_child() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	_say("build a house")
	assert_eq(_last(b), "A house? Coming right up!")
	_steps(b, 12.0)
	var placed := _placed()
	assert_gte(placed.size(), 20, "a little house of more than 20 blocks")
	var child_box := PlacementRules.player_aabb(leader.global_position)
	for e: Array in placed:
		assert_false(child_box.intersects(AABB(Vector3(e[0] as Vector3i), Vector3.ONE)), "never inside the child")
		assert_true(int(e[1]) in [BlockIds.PLANKS, BlockIds.BRICK], "house blocks in Sandbox")
	assert_eq(_last(b), "Ta-da! A little house for you!")


func test_a_tower_with_my_blocks_is_made_of_the_childs_blocks() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	for i in 3:
		b.style.saw_block(BlockIds.BLUE, Vector3i(-20, FlatWorld.GROUND + i, -20), BotStyle.NO_CELL)
	_say("build a tower with my blocks")
	assert_eq(_last(b), "A tower? Coming right up!")
	_steps(b, 8.0)
	var placed := _placed()
	assert_gte(placed.size(), 5)
	for e: Array in placed:
		assert_eq(int(e[1]), BlockIds.BLUE)


func test_survivor_builds_stay_leaves_and_the_friend_says_so() -> void:
	Game.mode = ModeRules.SURVIVOR
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	_say("build a wall with my blocks")
	assert_eq(_said(b).front(), BotAnswers.line(&"leaves_only", BotAnswers.EN))
	_steps(b, 8.0)
	var placed := _placed()
	assert_gte(placed.size(), 8)
	for e: Array in placed:
		assert_eq(int(e[1]), BlockIds.LEAVES, "the child's blocks stay the child's")


func test_with_no_builder_near_another_friend_builds() -> void:
	var b := await _bot(BotRules.FIGHTER, Vector3(2.5, G, 0.5))
	_say("build a tower")
	assert_eq(_last(b), "A tower? Coming right up!")
	_steps(b, 8.0)
	assert_gte(_placed().size(), 5)


func test_a_builder_answers_for_a_build_and_the_others_leave_it_to_it() -> void:
	var f := await _bot(BotRules.FIGHTER, Vector3(1.5, G, 0.5))
	var b := director.add(BotRules.BUILDER)
	b.global_position = Vector3(3.5, G, 0.5)
	b.clock = 100.0
	lines.clear()
	_say("build a wall")
	assert_eq(_said(f), [] as Array[String])
	assert_eq(_last(b), "A wall? Coming right up!")
	assert_false(f.talk_building())


func test_no_room_to_build_is_said_kindly() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	for x in range(-8, 9):
		for z in range(-8, 9):
			if absi(x) > 0 or absi(z) > 0:
				world.cells[Vector3i(x, FlatWorld.GROUND, z)] = BlockIds.PLANKS   # the child's floor everywhere
	_say("build a house")
	assert_eq(_last(b), BotAnswers.line(&"no_room", BotAnswers.EN))


func test_find_treasure_the_explorer_leads_the_way_and_waits_for_the_child() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	var spot := Vector3(0.5, G, -40.5)
	director.secret_near = func(_from: Vector3) -> Dictionary: return {"pos": spot, "kind": &"room"}
	_say("find treasure")
	assert_eq(_last(b), "I know! There's a hidden room 41 blocks straight ahead. Follow me!")
	_steps(b, 6.0)
	assert_eq(b.behaviour, BotRules.GUIDE)
	assert_lt(_flat(b.global_position, leader.global_position), BotRules.GUIDE_AHEAD + 2.0, "it waits for the child")
	assert_gt(_flat(leader.global_position, b.global_position), 4.0, "but it went ahead")
	for i in 30:                       # the child follows
		var ahead := b.global_position.move_toward(spot, -2.0)
		leader.global_position = Vector3(ahead.x, G, ahead.z)
		await get_tree().physics_frame
		_steps(b, 0.5)
		if b.pointing:
			break
	assert_true(b.pointing, "it got there and points at it")
	assert_lt(_flat(b.global_position, spot), BotFriend.POINT_REACH + 0.5)
	assert_eq(_last(b), BotAnswers.line(&"found_it", BotAnswers.EN))


## Owner #45a: with a quest story going, "follow the arrow" (or "find treasure") leads to the story's place first.
func test_follow_the_arrow_leads_to_the_quest_place_first() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	var spot := Vector3(0.5, G, -30.5)
	director.secret_near = func(_from: Vector3) -> Dictionary: return {"pos": Vector3(0.5, G, 40.5), "kind": &"room"}
	var asked: Array = []
	director.quest_near = func(peer: int) -> Dictionary:
		asked.append(peer)
		return {"pos": spot, "kind": &"quest"}
	_say("follow the arrow")
	assert_eq(asked, [multiplayer.get_unique_id()], "the child's own story")
	assert_eq(_last(b), "I know! There's the place of your quest 31 blocks straight ahead. Follow me!")
	_steps(b, 6.0)
	assert_eq(b.behaviour, BotRules.GUIDE)
	director.quest_near = func(_peer: int) -> Dictionary: return {}
	_say("find treasure")
	assert_string_contains(_last(b), "hidden room", "no story going: the nearest secret as before")


func test_where_is_the_treasure_with_none_near_says_so() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	_say("where is the treasure?")
	assert_eq(_last(b), BotAnswers.treasure(Vector3.ZERO, Vector3.FORWARD, {}, BotAnswers.EN, true))
	assert_eq(b.talk_order(), &"")


func test_where_is_tilly_from_her_stall() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	_say("where is tilly?")
	assert_string_contains(_last(b), "Survivor", "no shop in a Sandbox world")
	var tilly := Node3D.new()
	tilly.add_to_group(&"traders")
	add_child_autofree(tilly)
	tilly.global_position = Vector3(-13.5, G, 0.5)
	_say("where is tilly?")
	assert_eq(_last(b), "Tilly's shop is 14 blocks to your left! Follow me!")
	_steps(b, 1.0)
	assert_eq(b.behaviour, BotRules.GUIDE, "and it shows the way")


func test_guard_me_widens_the_circle_a_friend_guards() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	var m := _monster(Vector3(12.5, G, 0.5))
	await get_tree().physics_frame
	_steps(b, 0.3)
	assert_ne(b.behaviour, BotRules.FIGHT, "an explorer leaves a monster 12 blocks away alone")
	_say("guard me")
	assert_eq(_last(b), "I see it! Stay behind me!")
	_steps(b, 0.3)
	assert_eq(b.behaviour, BotRules.FIGHT)
	assert_true(is_instance_valid(m))


func test_run_away_from_monsters_instead_of_fighting() -> void:
	var b := await _bot(BotRules.FIGHTER, Vector3(1.5, G, 0.5))
	_monster(Vector3(6.5, G, 0.5))
	await get_tree().physics_frame
	_steps(b, 0.3)
	assert_eq(b.behaviour, BotRules.FIGHT)
	_say("run away")
	assert_eq(_last(b), "Run! This way!")
	_steps(b, 2.0)
	assert_eq(b.behaviour, BotRules.HIDE)
	assert_lt(b.global_position.x, 0.0, "away from the monster")


func test_hide_with_no_monsters_near_is_quiet_hiding() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	_say("hide")
	assert_eq(_last(b), "OK, I'm hiding! Shh!")
	_steps(b, 1.0)
	assert_eq(b.behaviour, BotRules.HIDE)


func test_dance_plays_a_dance_where_it_stands() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	_say("dance!")
	assert_eq(_last(b), BotAnswers.line(&"dance", BotAnswers.EN, 0))
	_steps(b, 0.3)
	assert_eq(b.behaviour, BotRules.DANCE)
	assert_ne(b.avatar.emote(), &"", "a dance plays on its body")
	_steps(b, BotRules.DANCE_TIME + 0.5)
	assert_ne(b.behaviour, BotRules.DANCE)
	assert_eq(b.avatar.emote(), &"")


func test_race_me_asks_for_a_race() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	var asked: Array[String] = []
	director.race_with = func(bot: BotFriend) -> String:
		asked.append(bot.bot_name)
		return CourseDirector.NO_COURSE
	_say("race me")
	assert_eq(asked, [b.bot_name] as Array[String])
	assert_eq(_last(b), BotAnswers.line(&"race_none", BotAnswers.EN))
	director.race_with = func(_bot: BotFriend) -> String: return ""
	_say("lets race")
	assert_eq(_last(b), BotAnswers.line(&"race_ready", BotAnswers.EN))


func test_kind_words_get_kind_answers_and_a_heart() -> void:
	var name := str(Profile.data.username)
	Profile.data.username = "Hopper"
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	var who := b.child_name(leader)
	assert_eq(who, "Hopper")
	var like := b.mind.memory.like(who)
	_say("thank you")
	assert_eq(_last(b), BotAnswers.line(&"thanks", BotAnswers.EN, 0))
	_say("good job")
	assert_true(_last(b) in BotAnswers.LINES[&"praise"][BotAnswers.EN])
	assert_gt(b.mind.memory.like(who), like, "it likes its child a little more")
	b._physics_process(STEP * 7)
	assert_eq(b.thought, Thought.HEART, "a heart over its head")
	_say("hi")
	assert_true(_last(b) in BotAnswers.LINES[&"hello"][BotAnswers.EN])
	_say("bye")
	assert_eq(_last(b), BotAnswers.line(&"bye", BotAnswers.EN))
	assert_true(is_instance_valid(b) and not b.is_queued_for_deletion(), "a bye never sends a friend away")
	Profile.data.username = name


# --- Questions answered from the game ---

func test_questions_are_answered_from_the_game() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	_say("what are you doing?")
	assert_eq(_last(b), BotAnswers.doing(b.behaviour, BotAnswers.EN))
	leader.health.hp = 14
	_say("how many hearts do i have?")
	assert_eq(_last(b), "You have 7 hearts out of 10!")
	Animal.time_source = func() -> float: return 0.5
	_say("is it night soon?")
	assert_eq(_last(b), "It's day. Night comes in about 7 minutes.")
	_say("whats your name")
	assert_eq(_last(b), "I'm %s, your builder bot!" % b.bot_name)
	_say("what can you do?")
	assert_eq(_last(b), BotAnswers.line(&"what_can_i_say", BotAnswers.EN))
	_say("how are you?")
	assert_eq(_last(b), BotAnswers.line(&"feel", BotAnswers.EN))


func test_what_it_is_doing_follows_what_it_was_asked() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(1.5, G, 0.5))
	_say("wait")
	_steps(b, 0.3)
	_say("what are you doing")
	assert_eq(_last(b), BotAnswers.doing(&"stay", BotAnswers.EN))


func test_each_friend_says_where_it_is() -> void:
	var a := await _bot(BotRules.BUILDER, Vector3(0.5, G, 12.5))
	var b := director.add(BotRules.EXPLORER)
	b.global_position = Vector3(1.5, G, 0.5)
	b.clock = 100.0
	lines.clear()
	_say("where are you?")
	assert_eq(_last(a), "Over here! I'm 12 blocks behind you.")
	assert_eq(_last(b), "I'm right here, next to you!")


# --- Who hears ---

func test_a_name_talks_to_one_friend() -> void:
	var a := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	var b := director.add(BotRules.FIGHTER)
	b.global_position = Vector3(-2.5, G, 0.5)
	b.clock = 100.0
	lines.clear()
	_say("%s, wait" % b.bot_name)
	assert_eq(b.talk_order(), BotRules.STAY)
	assert_eq(a.talk_order(), &"", "the other friend was not named")
	assert_eq(_said(a), [] as Array[String])
	_say("wait")
	assert_eq(a.talk_order(), BotRules.STAY, "unnamed: everyone near")
	assert_eq(_last(a), BotAnswers.line(&"wait", BotAnswers.EN, 0, true), "one answer for both")


func test_a_guests_words_reach_only_the_guests_own_friends() -> void:
	var host_bot := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	var guest := _player(Vector3(0.5, G, 8.5), 2)
	var guest_bot := director.add(BotRules.FIGHTER)
	guest_bot.leader_peer = 2
	guest_bot.global_position = Vector3(1.5, G, 8.5)
	guest_bot.clock = 100.0
	await get_tree().physics_frame
	lines.clear()
	_say("wait", 2)
	assert_eq(guest_bot.talk_order(), BotRules.STAY, "the guest's friend listens to the guest")
	assert_eq(host_bot.talk_order(), &"", "the host's friend never listens to another child")
	_say("dance")
	assert_eq(host_bot.talk_order(), BotRules.DANCE)
	assert_eq(guest_bot.talk_order(), BotRules.STAY, "and the guest's never listens to the host")
	assert_not_null(guest)


func test_words_not_understood_get_a_kind_hint() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	_say("banana")
	assert_eq(_last(b), BotAnswers.line(&"hint", BotAnswers.EN))
	lines.clear()
	_say("ok")
	assert_eq(_said(b), [] as Array[String], "ok needs no answer")
	_player(Vector3(0.5, G, 8.5), 2)   # another child in the world
	await get_tree().physics_frame
	_say("i like pizza")
	assert_eq(_said(b), [] as Array[String], "chat between people is never interrupted")
	_say("%s banana" % b.bot_name)
	assert_eq(_last(b), BotAnswers.line(&"hint", BotAnswers.EN), "named: the hint")


func test_the_chat_filter_still_applies() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	_say("follow me my number is 555 123 4567")
	_say("follow me shit")
	assert_eq(_said(b), [] as Array[String], "bots never react to personal information or bad words")
	assert_eq(b.talk_order(), &"")
	assert_false(b._talk_close_t > 0.0)


func test_too_many_words_at_once_are_let_go() -> void:
	var b := await _bot(BotRules.BUILDER, Vector3(2.5, G, 0.5))
	for i in ChatRules.RATE_COUNT + 2:
		_say("hi", 0, false)
	assert_eq(_said(b).size(), ChatRules.RATE_COUNT, "the chat's rate limit")


func test_the_quick_chat_phrases_reach_the_friends() -> void:
	var names: Array[String] = []
	for phrase in OnlineChatRules.WHEEL + ChatRules.QUICK_PHRASES + BotTalkWheel.PHRASES:
		var intent: StringName = BotIntents.parse(phrase, names).intent
		assert_ne(intent, BotIntents.UNKNOWN, phrase)
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	_say("Follow me!")
	assert_eq(_last(b), "OK! I'm right behind you!")


# --- Memory ---

func test_asked_often_to_follow_it_keeps_closer_and_remembers_it() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(1.5, G, 0.5))
	for i in 3:
		_say("follow me")
		Session.bot_talk_reset()
	assert_gt(b.asks.closeness(b.clock), 1.5)
	var saved: Dictionary = b.to_save()
	assert_true((saved.mind as Dictionary).has("a"), "saved with its mind")
	var d := WorldMeta.from_json(JSON.stringify({"version": 1, "seed": 1, "bots": [saved]}))
	var again := await _bot(BotRules.EXPLORER, Vector3(-1.5, G, 0.5))
	again.mind_load(d.bots[0].mind)
	assert_almost_eq(again.asks.closeness(again.clock), b.asks.closeness(b.clock), 0.05)


# --- The chat bar and the wheel ---

func test_the_chat_bar_and_the_wheel_talk_to_the_childs_friends() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	var panel := ChatPanel.new()
	add_child_autofree(panel)
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel.open()
	lines.clear()
	panel._submit("wait here")
	assert_eq(b.talk_order(), BotRules.STAY, "typed words (13+) reach the friends")
	var kinds: Array = lines.map(func(l: Dictionary) -> StringName: return l.kind)
	assert_eq(kinds, [&"chat", &"bot"], "the child's own line first, then the answer")
	Session.bot_talk_reset()
	panel.wheel.chosen.emit("Follow me!")
	await get_tree().process_frame
	assert_eq(b.talk_order(), &"", "a wheel phrase too")
	assert_gt(b._talk_close_t, 0.0)


func test_under_13_players_talk_to_their_friends_with_pictures_and_words() -> void:
	var b := await _bot(BotRules.EXPLORER, Vector3(12.5, G, 0.5))
	var panel := ChatPanel.new()
	add_child_autofree(panel)
	panel.setup("Hopper", AgeBand.UNDER_13)
	panel.open()
	assert_true(panel.wheel.visible, "under 13: the wheel")
	assert_true(panel.wheel.has_bot_page(), "with a page for the child's bot friends")
	panel.wheel.open_bots()
	assert_eq(panel.wheel.phrases(), BotTalkWheel.PHRASES)
	panel.wheel.chosen.emit("Wait here!")
	await get_tree().process_frame
	assert_eq(b.talk_order(), BotRules.STAY)
	Session.bot_talk_reset()
	var before := lines.size()
	panel._submit("dance")
	assert_eq(b.talk_order(), BotRules.DANCE, "typed words to their own friends reach them")
	for l in lines.slice(before):
		assert_ne(l.kind, &"chat", "and never anyone else: no chat line for other players")
		assert_ne(l.kind, &"error", "no 'use the quick chat' refusal")
