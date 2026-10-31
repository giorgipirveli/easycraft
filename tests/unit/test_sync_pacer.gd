extends GutTest
## Pacing on the one reliable stream (M4 Wave 1 A, spec §17.0): world data for each guest gets a
## byte budget per frame (a token bucket), and none at all while the link still has a backlog, so
## nothing big queues ahead of the players' positions.


func test_a_new_guest_may_have_one_burst_at_once() -> void:
	var p := SyncPacer.new()
	assert_eq(p.budget(5, 0.0, 0), SyncPacer.BURST)


func test_spent_bytes_come_back_at_the_rate() -> void:
	var p := SyncPacer.new()
	p.budget(5, 0.0, 0)
	p.spend(5, SyncPacer.BURST)
	assert_eq(p.budget(5, 0.0, 0), 0)
	assert_almost_eq(float(p.budget(5, 0.1, 0)), SyncPacer.RATE * 0.1, 1.0)
	assert_eq(p.budget(5, 60.0, 0), SyncPacer.BURST, "never more than one burst")


func test_a_big_record_puts_the_guest_in_debt() -> void:
	var p := SyncPacer.new()
	p.budget(5, 0.0, 0)
	p.spend(5, SyncPacer.BURST * 3)
	assert_eq(p.budget(5, 0.1, 0), 0, "still paying it back")
	var back := float(SyncPacer.BURST * 2) / SyncPacer.RATE
	assert_gt(p.budget(5, back + 0.05, 0), 0)


func test_guests_have_their_own_budgets() -> void:
	var p := SyncPacer.new()
	p.budget(5, 0.0, 0)
	p.spend(5, SyncPacer.BURST)
	assert_eq(p.budget(6, 0.0, 0), SyncPacer.BURST)


func test_a_backlog_on_the_link_holds_world_data_back() -> void:
	var p := SyncPacer.new()
	assert_eq(p.budget(5, 0.0, SyncPacer.BACKLOG_LIMIT + 1), 0)
	assert_eq(p.budget(5, 0.0, SyncPacer.BACKLOG_LIMIT), SyncPacer.BURST)


func test_a_guest_that_left_is_forgotten() -> void:
	var p := SyncPacer.new()
	p.budget(5, 0.0, 0)
	p.spend(5, SyncPacer.BURST)
	p.forget(5)
	assert_eq(p.budget(5, 0.0, 0), SyncPacer.BURST)


func test_the_rate_stays_far_under_what_a_phone_can_upload() -> void:
	assert_lte(SyncPacer.RATE * 8, 512 * 1024, "at most 0.5 Mbit/s of world data per guest while catching up")
