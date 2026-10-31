extends GutTest
## Player and creature sync stays small and paced (M4 Wave 1 A, spec §17.0). Every
## MultiplayerSynchronizer used to send each frame (a headless host at 60 FPS sent a guest 234 kbit/s
## of positions while they played together, 371 kbit/s while it flew); now players sync
## SyncPace.PLAYER_HZ times a second and everything else SyncPace.OTHER_HZ, set by Session for every
## synchronizer that enters the tree (no entity script had to change).


func test_players_sync_faster_than_creatures() -> void:
	assert_gt(SyncPace.PLAYER_HZ, SyncPace.OTHER_HZ)
	assert_lte(SyncPace.PLAYER_HZ, 30.0)
	assert_gte(SyncPace.OTHER_HZ, 10.0, "creatures still move smoothly enough")


func test_a_players_synchronizer_is_paced_when_it_enters_the_tree() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "7"
	add_child_autofree(p)
	var sync := p.get_node("Sync") as MultiplayerSynchronizer
	assert_almost_eq(sync.replication_interval, 1.0 / SyncPace.PLAYER_HZ, 0.0001)
	assert_almost_eq(sync.delta_interval, 1.0 / SyncPace.PLAYER_HZ, 0.0001)


func test_a_creatures_synchronizer_is_paced_slower() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var sync := MultiplayerSynchronizer.new()
	holder.add_child(sync)
	assert_almost_eq(sync.replication_interval, 1.0 / SyncPace.OTHER_HZ, 0.0001)
	assert_almost_eq(sync.delta_interval, 1.0 / SyncPace.OTHER_HZ, 0.0001)


func _creature_sync() -> MultiplayerSynchronizer:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var sync := MultiplayerSynchronizer.new()
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	sync.replication_config = cfg
	holder.add_child(sync)
	return sync


func test_in_a_networked_game_a_creature_syncs_its_position_only_when_it_changed() -> void:
	var sync := _creature_sync()
	Session._a_pace(sync, true)
	assert_eq(sync.replication_config.property_get_replication_mode(NodePath(".:position")),
		SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func test_solo_nothing_changes_how_a_creature_syncs() -> void:
	var sync := _creature_sync()   # (this test game is offline)
	assert_eq(sync.replication_config.property_get_replication_mode(NodePath(".:position")),
		SceneReplicationConfig.REPLICATION_MODE_ALWAYS)


func test_a_player_keeps_syncing_its_position_every_time() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "8"
	add_child_autofree(p)
	Session._a_pace(p.get_node("Sync") as MultiplayerSynchronizer, true)
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_eq(cfg.property_get_replication_mode(NodePath(".:position")), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)


func test_the_interval_for_a_body() -> void:
	assert_almost_eq(SyncPace.interval_for(autofree(Player.new())), 1.0 / SyncPace.PLAYER_HZ, 0.0001)
	assert_almost_eq(SyncPace.interval_for(autofree(Node3D.new())), 1.0 / SyncPace.OTHER_HZ, 0.0001)
	assert_almost_eq(SyncPace.interval_for(null), 1.0 / SyncPace.OTHER_HZ, 0.0001)


## M4 Wave 2 A2: remote bodies are shown one sync interval and a little behind their newest sync
## (RemoteSmoother): about 100 ms for players, 150 ms for creatures.
func test_remote_bodies_are_shown_a_sync_interval_and_a_little_behind() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	assert_almost_eq(SyncPace.smoothing_delay(p), 0.1, 0.001)
	p.free()
	var creature := Node3D.new()
	assert_almost_eq(SyncPace.smoothing_delay(creature), 0.15, 0.001)
	creature.free()
