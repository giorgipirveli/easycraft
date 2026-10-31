extends GutTest
## Owner #37 (spec §14.23): the host's open trades (pure). An ask waits for YES or NO THANKS; one ask and one trade
## per player; every change makes both not ready; asking again waits a moment; a player who leaves takes their
## ask and their trade with them.

var t: TradeTable


func before_each() -> void:
	t = TradeTable.new()


func _open(a: int = 1, b: int = 2) -> Dictionary:
	assert_eq(t.ask(a, b, 0).error, "")
	return t.answer(b, a, true)


func test_an_ask_waits_for_yes() -> void:
	assert_eq(t.ask(1, 2, 0).error, "")
	assert_eq(t.asker_of(2), 1)
	assert_true(t.trade_of(1).is_empty(), "nothing opens without YES")
	var tr := t.answer(2, 1, true)
	assert_false(tr.is_empty())
	assert_eq([tr.a, tr.b], [1, 2])
	assert_eq(t.trade_of(1), tr)
	assert_eq(t.trade_of(2), tr)
	assert_eq(t.asker_of(2), 0, "the ask is answered")


func test_no_thanks_opens_nothing() -> void:
	t.ask(1, 2, 0)
	assert_true(t.answer(2, 1, false).is_empty())
	assert_true(t.trade_of(1).is_empty())
	assert_eq(t.asker_of(2), 0)


func test_only_a_real_ask_can_be_answered() -> void:
	assert_true(t.answer(2, 1, true).is_empty(), "nobody asked")
	t.ask(1, 2, 0)
	assert_true(t.answer(3, 1, true).is_empty(), "not the one asked")
	assert_true(t.answer(2, 3, true).is_empty(), "not the one who asked")


func test_asks_are_refused_when_they_cannot_be() -> void:
	assert_eq(t.ask(1, 1, 0).error, "self")
	_open(1, 2)
	assert_eq(t.ask(3, 1, 10_000).error, "busy", "already trading")
	assert_eq(t.ask(1, 3, 10_000).error, "you_busy")
	var u := TradeTable.new()
	u.ask(1, 2, 0)
	assert_eq(u.ask(3, 2, 10_000).error, "busy", "someone else asked first")
	assert_eq(u.ask(1, 3, 100).error, "too_soon", "asking again waits a moment")
	var r := u.ask(1, 3, TradeTable.ASK_GAP_MS)
	assert_eq(r.error, "")
	assert_eq(r.dropped, 2, "a new ask takes back the old one")
	assert_eq(u.asker_of(2), 0)


func test_every_change_makes_both_not_ready() -> void:
	var tr := _open()
	t.set_ready(1, true)
	t.set_ready(2, false)
	assert_false(t.both_ready(tr))
	t.set_ready(2, true)
	assert_true(t.both_ready(tr))
	t.set_offer(1, TradeRules.clean_offer([[BlockIds.STONE, 1]], 0))
	assert_false(tr.ready[1])
	assert_false(tr.ready[2], "a change un-readies the other side too")


func test_a_player_who_leaves_takes_their_trade_and_ask() -> void:
	var tr := _open(1, 2)
	var gone := t.forget(2)
	assert_eq(gone.trade, tr)
	assert_true(t.trade_of(1).is_empty())
	t.ask(3, 4, 0)
	gone = t.forget(3)
	assert_eq(gone.asked, 4, "the child asked is told the ask went away")
	assert_eq(t.asker_of(4), 0)
	t.ask(5, 6, 0)
	gone = t.forget(6)
	assert_eq(gone.asker, 5, "the asker is told the other one left")


func test_each_side_sees_the_trade_its_own_way() -> void:
	var tr := _open(1, 2)
	t.set_offer(1, TradeRules.clean_offer([[BlockIds.STONE, 3]], 4))
	t.set_ready(2, true)
	var mine := t.state_for(tr, 1, "Bob")
	assert_eq(mine.other, 2)
	assert_eq(mine.name, "Bob")
	assert_eq(mine.mine.gold, 4)
	assert_eq(mine.theirs.gold, 0)
	assert_false(mine.my_ready)
	assert_true(mine.their_ready)
	var theirs := t.state_for(tr, 2, "Ann")
	assert_eq(theirs.theirs.items, [[BlockIds.STONE, 3]])
	assert_true(theirs.my_ready)


func test_closing_forgets_the_trade() -> void:
	var tr := _open()
	t.close(tr)
	assert_true(t.trade_of(1).is_empty())
	assert_true(t.trade_of(2).is_empty())
	assert_eq(t.ask(1, 2, TradeTable.ASK_GAP_MS).error, "", "they can trade again")
