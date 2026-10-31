extends GutTest
## Player.set_avatar_style swaps the body between the blocky and the realistic avatar (M1b Task 13)
## and keeps what the rest of the game relies on: the node name "Avatar" (the synchronizer replicates
## Avatar:rotation), visibility, facing and the Size Magic scale. A missing asset never leaves the
## player invisible.

var player: Player


func before_each() -> void:
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = "7"   # a remote player: the local camera never touches its avatar's visibility
	add_child_autofree(player)


func after_each() -> void:
	RealisticAvatar.model_path = RealisticAvatar.MODEL_PATH


func _models() -> int:
	var n := 0
	for c in player.get_children():
		if c is AvatarModel:
			n += 1
	return n


func test_a_player_starts_blocky() -> void:
	assert_true(player.avatar is BlockyAvatar)


func test_the_realistic_style_swaps_in_the_realistic_avatar_and_back() -> void:
	player.set_avatar_style("realistic")
	assert_true(player.avatar is RealisticAvatar)
	assert_same(player.get_node("Avatar"), player.avatar, "still named Avatar")
	assert_eq(_models(), 1, "the blocky body is gone")
	player.set_avatar_style("blocky")
	assert_true(player.avatar is BlockyAvatar)
	assert_same(player.get_node("Avatar"), player.avatar)
	assert_eq(_models(), 1)


func test_the_same_style_keeps_the_same_model() -> void:
	player.set_avatar_style("realistic")
	var first := player.avatar
	player.set_avatar_style("realistic")
	assert_same(player.avatar, first)


func test_an_unknown_style_is_blocky() -> void:
	player.set_avatar_style("realistic")
	player.set_avatar_style("plasticine")
	assert_true(player.avatar is BlockyAvatar)


func test_the_swap_keeps_visibility_facing_and_size() -> void:
	player.set_physics_mode(PhysicsMode.Mode.FLY)   # growing while walking would unstuck against a world
	player.set_size_mode(SizeMagic.Mode.GIANT)
	player.avatar.rotation.y = 1.25
	player.avatar.visible = false
	player.set_avatar_style("realistic")
	assert_almost_eq(player.avatar.rotation.y, 1.25, 0.001, "facing")
	assert_false(player.avatar.visible, "hidden stays hidden (camera inside the body)")
	assert_almost_eq(player.avatar.scale.x, SizeMagic.scale(SizeMagic.Mode.GIANT), 0.001, "giant stays giant")
	player.set_size_mode(SizeMagic.Mode.TINY)
	assert_almost_eq(player.avatar.scale.x, SizeMagic.scale(SizeMagic.Mode.TINY), 0.001, "Size Magic reaches the new body")


func test_a_missing_asset_falls_back_to_the_blocky_avatar() -> void:
	RealisticAvatar.model_path = "res://assets/characters/missing/character.fbx"
	player.set_avatar_style("realistic")
	assert_true(player.avatar is BlockyAvatar, "never an invisible player")
	assert_true(player.avatar.is_inside_tree())
	assert_true(player.avatar.visible)
	assert_eq(_models(), 1)


func test_a_realistic_remote_player_runs_with_its_synced_velocity() -> void:
	player.set_avatar_style("realistic")
	player.velocity = Vector3(Player.WALK_SPEED, 0.0, 0.0)
	await wait_physics_frames(3)
	assert_eq((player.avatar as RealisticAvatar).animation_player().current_animation, "run")
