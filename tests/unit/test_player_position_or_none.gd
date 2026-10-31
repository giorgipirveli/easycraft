extends GutTest
## The M3 review (M3 Task 19): when the host quits, the guest's own player leaves the tree before it is freed, and the
## Theater read its global_position once ("!is_inside_tree()", an error line). Every "where is my player" callback
## (the Theater, the universe hub, the pet panel, the world map) asks Player.position_or_none: INF when the player is
## gone, out of the tree or not spawned yet.


func _player() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.set_physics_process(false)
	return p


func test_a_spawned_player_in_the_world_has_its_position() -> void:
	var p := _player()
	add_child_autofree(p)
	p.global_position = Vector3(3, 12, -4)
	p._spawned = true
	assert_eq(Player.position_or_none(p), Vector3(3, 12, -4))


func test_a_player_out_of_the_tree_has_none_and_no_error() -> void:
	var p := _player()
	add_child(p)
	p._spawned = true
	remove_child(p)
	assert_eq(Player.position_or_none(p), Vector3.INF)
	assert_eq(get_errors().size(), 0, "no !is_inside_tree() error")
	p.free()


func test_no_player_or_not_spawned_has_none() -> void:
	assert_eq(Player.position_or_none(null), Vector3.INF)
	var p := _player()
	add_child_autofree(p)
	assert_eq(Player.position_or_none(p), Vector3.INF, "not spawned yet")


## Found in the live relay test (2026-09-25 19:48): when the host quits, the guest's player can already be freed, and a
## typed `p: Player` argument failed ("previously freed") before the check could run.
func test_a_freed_player_has_none_and_no_error() -> void:
	var p := _player()
	add_child(p)
	p._spawned = true
	p.free()
	assert_eq(Player.position_or_none(p), Vector3.INF)
	assert_eq(get_errors().size(), 0, "no error for a freed player")
