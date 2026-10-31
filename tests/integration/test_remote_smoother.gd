extends GutTest
## Remote bodies shown smoothly between syncs (M4 Wave 2 A2, spec §17.0): a RemoteSmoother follows
## every MultiplayerSynchronizer that syncs its body's place. On a game that receives a sync, the
## synced place goes into the body's MotionBuffer and the body is put back where it is shown; each
## frame it is shown a little behind, between syncs. The game that simulates the body (its
## authority) never receives syncs, so nothing there changes. The frames are stepped by hand here,
## with a clock the test sets.

const INTERVAL := 0.1
const DELAY := 0.15

var smoother: RemoteSmoother
var clock := [10.0]


func before_each() -> void:
	Session.a_smoother().enabled = false   # these bodies are followed by the test's own smoother
	clock[0] = 10.0
	smoother = RemoteSmoother.new()
	smoother.now = func() -> float: return clock[0]
	add_child_autofree(smoother)
	smoother.set_process(false)


func after_each() -> void:
	Session.a_smoother().enabled = true


## A body with a synchronizer of these properties ([body, sync]); an "Avatar" child for players.
func _body(props: Array) -> Array:
	var body := CharacterBody3D.new()
	var avatar := Node3D.new()
	avatar.name = "Avatar"
	body.add_child(avatar)
	var sync := MultiplayerSynchronizer.new()
	var cfg := SceneReplicationConfig.new()
	for p: String in props:
		cfg.add_property(NodePath(p))
	sync.replication_config = cfg
	body.add_child(sync)
	add_child_autofree(body)
	smoother.track(sync, INTERVAL, DELAY)
	return [body, sync]


## What the multiplayer API does when a sync arrives: it writes the values, then says so.
func _arrive(pair: Array, pos: Vector3, yaw: float = 0.0, turn: Node3D = null) -> void:
	var body: Node3D = pair[0]
	body.position = pos
	(turn if turn != null else body).rotation.y = yaw
	(pair[1] as MultiplayerSynchronizer).synchronized.emit()


func _step(t: float) -> void:
	clock[0] = t
	smoother.step()


func test_a_remote_body_moves_smoothly_between_two_syncs() -> void:
	var pair := _body([".:position", ".:rotation"])
	var body: Node3D = pair[0]
	_arrive(pair, Vector3.ZERO)
	assert_eq(body.position, Vector3.ZERO, "the first sync is shown as it is")
	clock[0] = 10.1
	_arrive(pair, Vector3(1, 0, 0))
	assert_eq(body.position, Vector3.ZERO, "a new sync does not jump: the body stays where it is shown")
	_step(10.2)   # shows 10.05: half way
	assert_almost_eq(body.position, Vector3(0.5, 0, 0), Vector3.ONE * 0.001)
	_step(10.25)
	assert_almost_eq(body.position, Vector3(1, 0, 0), Vector3.ONE * 0.001)
	_step(11.0)
	assert_eq(body.position, Vector3(1, 0, 0), "and waits there for the next sync")


func test_the_turn_is_smoothed_on_the_node_that_is_synced() -> void:
	var pair := _body([".:position", "Avatar:rotation"])   # like a player
	var avatar: Node3D = (pair[0] as Node).get_node("Avatar")
	_arrive(pair, Vector3.ZERO, 0.0, avatar)
	clock[0] = 10.1
	_arrive(pair, Vector3.ZERO, 1.0, avatar)
	assert_eq(avatar.rotation.y, 0.0)
	_step(10.2)
	assert_almost_eq(avatar.rotation.y, 0.5, 0.001)
	assert_eq((pair[0] as Node3D).rotation.y, 0.0, "the body itself does not turn")


func test_the_game_that_simulates_the_body_is_left_alone() -> void:
	var pair := _body([".:position", ".:rotation"])
	var body: Node3D = pair[0]
	body.position = Vector3(3, 0, 0)   # its own physics moved it; no sync ever arrives here
	_step(10.5)
	assert_eq(body.position, Vector3(3, 0, 0))


func test_something_else_moving_the_body_wins() -> void:
	var pair := _body([".:position", ".:rotation"])
	var body: Node3D = pair[0]
	_arrive(pair, Vector3.ZERO)
	clock[0] = 10.1
	_arrive(pair, Vector3(1, 0, 0))
	_step(10.2)
	body.position = Vector3(50, 0, 50)   # e.g. put into a hiding spot on every game
	_step(10.25)
	assert_eq(body.position, Vector3(50, 0, 50))
	clock[0] = 10.3
	_arrive(pair, Vector3(51, 0, 50))
	assert_eq(body.position, Vector3(51, 0, 50), "it starts again from the next sync")


func test_a_sync_without_the_place_keeps_the_last_synced_place() -> void:
	# Creatures sync only what changed: a turn on the spot carries no place.
	var pair := _body([".:position", ".:rotation"])
	var body: Node3D = pair[0]
	_arrive(pair, Vector3.ZERO)
	clock[0] = 10.1
	_arrive(pair, Vector3(1, 0, 0))
	_step(10.2)   # shown at 0.5
	clock[0] = 10.2
	body.rotation.y = 1.0   # the delta sync wrote only the turn
	(pair[1] as MultiplayerSynchronizer).delta_synchronized.emit()
	assert_almost_eq(body.position, Vector3(0.5, 0, 0), Vector3.ONE * 0.001)
	_step(10.4)
	assert_almost_eq(body.position, Vector3(1, 0, 0), Vector3.ONE * 0.001, "the place synced last, not the one shown")
	assert_almost_eq(body.rotation.y, 1.0, 0.001)


func test_bodies_without_a_synced_place_are_not_followed_and_freed_ones_are_forgotten() -> void:
	_body([".:collector"])   # like a coin
	assert_eq(smoother.count(), 0)
	var pair := _body([".:position"])
	assert_eq(smoother.count(), 1)
	(pair[0] as Node).free()
	assert_eq(smoother.count(), 0)
	smoother.step()


func test_session_follows_every_synchronizer_that_enters_the_tree() -> void:
	Session.a_smoother().enabled = true
	var before := Session.a_smoother().count()
	var body := Node3D.new()
	var sync := MultiplayerSynchronizer.new()
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	sync.replication_config = cfg
	body.add_child(sync)
	add_child(body)
	assert_eq(Session.a_smoother().count(), before + 1)
	body.free()
	assert_eq(Session.a_smoother().count(), before)


func test_a_player_is_followed_with_its_avatars_turn() -> void:
	Session.a_smoother().enabled = true
	var before := Session.a_smoother().count()
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "7"
	add_child_autofree(p)
	assert_eq(Session.a_smoother().count(), before + 1)
