extends GutTest
## M3 Task 9: every player's look travels with their body (Player.look_code, synced on spawn and on
## change) so other players on LAN see it in their own style; the local player wears the profile's
## look and changes with it; a bad look from the network is the default look, never a crash.

var _avatar_before: AvatarLook


func before_each() -> void:
	_avatar_before = Profile.data.avatar.duplicate()


func after_each() -> void:
	Profile.data.avatar = _avatar_before


func _player(peer: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	return p


func _crowned() -> AvatarLook:
	var look := AvatarLook.new()
	look.hat = &"crown"
	look.shirt = &"pink"
	return look


func test_the_look_is_synced_on_spawn_and_on_change() -> void:
	var p := _player(4040)
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:look_code")
	assert_true(cfg.has_property(path))
	assert_true(cfg.property_get_spawn(path), "late joiners get it with the body")
	assert_eq(cfg.property_get_replication_mode(path), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func test_a_remote_players_look_is_worn_here() -> void:
	var p := _player(4041)
	p.look_code = _crowned().to_code()   # what the synchronizer does
	assert_not_null(p.avatar.find_child("hat_crown", true, false))
	assert_true(p.avatar.look().equals(_crowned()))


func test_a_look_arriving_before_the_body_is_ready_is_worn_at_ready() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "4042"
	p.look_code = _crowned().to_code()   # spawn state can be set before _ready
	add_child_autofree(p)
	assert_not_null(p.avatar.find_child("hat_crown", true, false))


func test_a_bad_look_from_the_network_is_the_default_look() -> void:
	var p := _player(4043)
	p.look_code = '{"hat": "crown_of_doom", "shirt": 12, "emotes": "all"}'
	assert_true(p.avatar.look().equals(AvatarLook.new()))
	p.look_code = "x".repeat(AvatarLook.MAX_CODE_LENGTH + 5)
	assert_eq(p.look_code, "", "oversized codes are dropped")


func test_the_local_player_wears_the_profile_look_and_follows_changes() -> void:
	Profile.data.avatar = _crowned()
	var p := _player(multiplayer.get_unique_id())
	assert_true(p.avatar.look().equals(_crowned()), "wears the profile's look")
	var other := AvatarLook.new()
	other.cape = &"hero"
	Profile.data.avatar = other
	Profile.avatar_changed.emit()
	assert_true(AvatarLook.from_code(p.look_code).equals(other), "the synced code follows")
	assert_not_null(p.avatar.find_child("cape_hero", true, false))
	assert_null(p.avatar.find_child("hat_crown", true, false))
