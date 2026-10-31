extends GutTest
## Bot friends fill the empty seats of an online world (M4 Wave 2, Agent E; spec §17.5, §12.14): the
## host's friends come along, and together with the players they are never more than four. When a
## player joins a full world the newest friend makes room (kindly, in the chat) and comes back when a
## seat is free again; friends making room are still saved with the world. Solo and LAN keep three.

class FlatWorld:
	extends WorldService
	const GROUND := 10

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < GROUND else BlockIds.AIR

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


var world: FlatWorld
var director: BotDirector
var players := 1
var lines: Array[String] = []
var _session_world: WorldService


func before_each() -> void:
	_session_world = Session.world
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)
	players = 1
	lines.clear()
	Session.chat_received.connect(_on_chat)
	var leader: Player = load("res://entities/player/player.tscn").instantiate()
	leader.name = str(multiplayer.get_unique_id())
	leader.world = world
	add_child_autofree(leader)
	leader.set_physics_process(false)
	leader.viewer.free()
	leader._spawned = true
	leader.global_position = Vector3(0.5, FlatWorld.GROUND, 0.5)
	var container := Node3D.new()
	add_child_autofree(container)
	director = BotDirector.new()
	director.container = container
	director.world = world
	director.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		container.add_child(b)
		return b
	add_child_autofree(director)
	await get_tree().physics_frame


func after_each() -> void:
	Session.chat_received.disconnect(_on_chat)
	Session.world = _session_world


func _on_chat(_from: String, text: String, _kind: StringName) -> void:
	lines.append(text)


func _online() -> void:
	director.seats = func() -> int: return BotRules.seats_for_bots(players)


func _names() -> Array[String]:
	var out: Array[String] = []
	for b in director.bots():
		out.append(b.bot_name)
	return out


func test_seats_are_what_the_players_leave() -> void:
	assert_eq(BotRules.seats_for_bots(1), 3)
	assert_eq(BotRules.seats_for_bots(2), 2)
	assert_eq(BotRules.seats_for_bots(4), 0)
	assert_eq(BotRules.seats_for_bots(9), 0)
	assert_eq(BotRules.seats_for_bots(0), BotRules.MAX_BOTS, "never more than the three friends")


func test_solo_and_lan_keep_three_friends() -> void:
	for p in [BotRules.BUILDER, BotRules.EXPLORER, BotRules.FIGHTER]:
		assert_not_null(director.add(p))
	players = 3
	director.fit_seats()
	assert_eq(director.bots().size(), 3, "no seat limit off the internet")


func test_the_hosts_friends_come_along_online_and_fill_the_empty_seats() -> void:
	_online()
	for p in [BotRules.BUILDER, BotRules.EXPLORER, BotRules.FIGHTER]:
		assert_not_null(director.add(p))
	assert_eq(director.bots().size(), 3, "alone online: three friends in three empty seats")
	assert_false(director.can_add(), "four is the most")


func test_a_friend_makes_room_when_a_player_joins_and_comes_back_when_a_seat_is_free() -> void:
	_online()
	director.add(BotRules.BUILDER)
	director.add(BotRules.EXPLORER)
	director.add(BotRules.FIGHTER)
	var newest: String = director.bots()[2].bot_name
	players = 2
	director.fit_seats()
	await get_tree().process_frame
	assert_eq(director.bots().size(), 2)
	assert_false(_names().has(newest), "the newest friend makes room")
	assert_true(lines.has(BotRules.MAKE_ROOM_LINE), "and says so kindly")
	assert_eq(director.to_save().size(), 3, "still saved with the world")
	assert_false(director.can_add(), "no seat for another friend")
	players = 1
	director.fit_seats()
	await get_tree().process_frame
	assert_eq(director.bots().size(), 3, "back when the seat is free")
	assert_true(_names().has(newest))


func test_a_full_world_has_no_friends_and_keeps_them_all() -> void:
	_online()
	director.add(BotRules.BUILDER)
	director.add(BotRules.EXPLORER)
	players = 4
	director.fit_seats()
	await get_tree().process_frame
	assert_eq(director.bots().size(), 0)
	assert_eq(director.to_save().size(), 2)
	players = 3
	director.fit_seats()
	await get_tree().process_frame
	assert_eq(director.bots().size(), 1, "one seat: one friend back")


func test_restoring_a_world_online_brings_only_as_many_as_there_are_seats() -> void:
	players = 3
	_online()
	var saved: Array[Dictionary] = [
		{"name": "Pip", "personality": "builder", "look": 0},
		{"name": "Bo", "personality": "explorer", "look": 1},
	]
	director.restore(saved)
	assert_eq(director.bots().size(), 1)
	assert_eq(director.to_save().size(), 2, "the other waits for a seat")
