extends GutTest
## M3 Task 19 (the whole-branch review): a buddy whose owner left a LAN game (a guest who woke it went home) waits
## where it is, like a pet (review M12, docs/devlog/parts/review-minors-animals.md). Buddy._find_owner fell back to
## the last player it looked at, so the buddy walked after another child for the rest of the game.


func _player(peer: int, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	p._spawned = true
	return p


func _buddy(owner: int, at: Vector3) -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack({Vector3i.ZERO: BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.PLANKS}), "name": "Bo",
		"owner": owner, "pos": at, "yaw": 0.0, "id": "Buddy_owner_left"})
	add_child_autofree(b)
	b.set_physics_process(false)
	return b


func test_a_buddy_whose_owner_left_waits_instead_of_following_another_child() -> void:
	_player(3, Vector3(20, 40, 0))   # another child; the owner (peer 2) is gone
	var b := _buddy(2, Vector3(0, 40, 0))
	await get_tree().physics_frame
	for i in 10:
		b._physics_process(1.0 / 60.0)
	assert_almost_eq(b.velocity.x, 0.0, 0.001, "it doesn't walk to player 3")
	assert_almost_eq(b.global_position.x, 0.0, 0.001)


func test_a_buddy_still_follows_its_owner() -> void:
	_player(3, Vector3(-20, 40, 0))
	_player(2, Vector3(20, 40, 0))
	var b := _buddy(2, Vector3(0, 40, 0))
	await get_tree().physics_frame
	for i in 10:
		b._physics_process(1.0 / 60.0)
	assert_gt(b.velocity.x, 0.0, "towards its owner (peer 2), not player 3")
