extends GutTest
## Owner #109 together online: a car carries its riders at up to 14 m/s, so it syncs as often as a player does
## (SyncPace.PLAYER_HZ: on a guest's screen it is a shorter way behind) and, like every creature, only what changed (a
## parked car sends nothing); a guest's game shows it smoothly between syncs (RemoteSmoother follows its synchronizer).


func test_a_car_syncs_as_often_as_a_player_and_only_what_changed() -> void:
	var v := Vehicle.new()
	v.setup({"kind": "race_car", "colour": 0, "owner": "Kid", "pos": Vector3(0, 30, 0), "yaw": 0.0, "id": "Car1"})
	add_child_autofree(v)
	var sync := v.get_node("Sync") as MultiplayerSynchronizer
	assert_almost_eq(sync.replication_interval, 1.0 / SyncPace.PLAYER_HZ, 0.0001)
	assert_almost_eq(SyncPace.smoothing_delay(v), 1.0 / SyncPace.PLAYER_HZ + SyncPace.SMOOTHING_SLACK, 0.0001)
	assert_true(SyncPace.only_on_change(v), "a parked car sends nothing")
	var tracked := false
	for i in 3:
		await get_tree().process_frame
	var before := Session.a_smoother().count()
	var w := Vehicle.new()
	w.setup({"kind": "bus", "colour": 0, "owner": "Kid", "pos": Vector3(10, 30, 0), "yaw": 0.0, "id": "Car2"})
	add_child_autofree(w)
	tracked = Session.a_smoother().count() > before
	assert_true(tracked, "a guest's game shows it smoothly between syncs")
