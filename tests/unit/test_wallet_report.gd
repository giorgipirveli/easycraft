extends GutTest
## Survivor gold changes in an online world go to the server's wallet ledger (wallet_award, M4 Wave 2
## agent F; spec §17.1, §17.6) in batches: one report a few seconds after the first change, never one
## per coin, earned and spent netted, and never bigger than the server takes at once (2,000 × 2^(u−1)).


func test_nothing_to_report_at_first() -> void:
	var w := WalletReport.new()
	assert_false(w.due(1_000_000))
	assert_eq(w.take(1), [] as Array[int])


func test_changes_wait_for_the_batch_then_go_together() -> void:
	var w := WalletReport.new()
	w.add(5, 1000)
	w.add(10, 1500)
	w.add(0, 1600)
	w.add(-7, 1700)   # spent at Tilly's: netted with what was earned
	assert_eq(w.pending, 8)
	assert_false(w.due(1000 + WalletReport.BATCH_MSEC - 1))
	assert_true(w.due(1000 + WalletReport.BATCH_MSEC), "counted from the first change")
	assert_eq(w.take(1), [8] as Array[int])
	assert_eq(w.pending, 0)
	assert_false(w.due(99_999))


func test_spending_goes_as_one_report() -> void:
	var w := WalletReport.new()
	w.add(-4500, 0)
	assert_true(w.due(WalletReport.BATCH_MSEC))
	assert_eq(w.take(1), [-4500] as Array[int], "a spend is one report (the server checks the balance)")


func test_a_big_pile_goes_in_pieces_the_server_takes() -> void:
	var w := WalletReport.new()
	w.add(4500, 0)
	assert_eq(w.take(1), [2000, 2000, 500] as Array[int])
	w.add(4500, 0)
	assert_eq(w.take(2), [4000, 500] as Array[int], "universe 2 doubles the limit")
	w.add(10, 0)
	assert_eq(w.take(0), [10] as Array[int], "a bad universe counts as the first")
	assert_eq(WalletReport.max_award(99), WalletReport.AWARD_MAX_BASE << (WalletReport.MAX_UNIVERSE - 1))


func test_a_report_the_network_lost_is_tried_again() -> void:
	var w := WalletReport.new()
	w.add(30, 0)
	var pieces := w.take(1)
	w.give_back(pieces[0], 20_000)
	assert_eq(w.pending, 30)
	assert_false(w.due(20_000 + WalletReport.BATCH_MSEC - 1), "not at once")
	assert_true(w.due(20_000 + WalletReport.BATCH_MSEC))


# --- The gold-double bug's leftover (module 0.2.19, docs/devlog/parts/gold-double.md): the host's word, counted ---
# The host tells a guest every gold move with its number (seq) and reports the number with the last piece of the
# batch: the guest's game then knows when the server has every move it was told.

func test_every_change_is_counted() -> void:
	var w := WalletReport.new()
	w.add(5, 0)
	w.add(0, 10)   # no change
	w.add(-3, 20)
	assert_eq(w.seq, 2)
	assert_eq(w.sent_seq, 0, "nothing sent yet")
	w.take(1)
	w.give_back(2, 30)
	assert_eq(w.seq, 2, "a piece given back is no new change")


func test_a_batch_that_netted_to_nothing_is_still_due_for_its_count() -> void:
	var w := WalletReport.new()
	w.add(5, 1000)
	w.add(-5, 1200)
	assert_eq(w.pending, 0)
	assert_false(w.due(1000 + WalletReport.BATCH_MSEC - 1))
	assert_true(w.due(1000 + WalletReport.BATCH_MSEC), "the host's word that nothing changed in the end")
	assert_eq(w.take(1), [] as Array[int])
	w.sent_seq = w.seq
	assert_false(w.due(99_999))


func test_a_lost_count_is_due_again() -> void:
	var w := WalletReport.new()
	w.add(5, 0)
	w.add(-5, 0)
	w.take(1)
	w.give_back(0, 20_000)   # the network lost the count-only report
	assert_true(w.due(20_000 + WalletReport.BATCH_MSEC))
