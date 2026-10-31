extends GutTest
## Survivor gold (M2 §12.1): one currency, never negative, spent only when there is enough.


func test_a_wallet_earns_and_spends() -> void:
	var w := Wallet.new(25)
	assert_eq(w.balance, 25)
	w.add(10)
	assert_eq(w.balance, 35)
	assert_true(w.can_spend(35))
	assert_true(w.spend(30))
	assert_eq(w.balance, 5)


func test_spending_more_than_you_have_changes_nothing() -> void:
	var w := Wallet.new(5)
	assert_false(w.can_spend(6))
	assert_false(w.spend(6))
	assert_eq(w.balance, 5)


func test_gold_is_never_negative_and_bad_amounts_are_ignored() -> void:
	var w := Wallet.new(-40)
	assert_eq(w.balance, 0, "a broken save cannot start in debt")
	w.add(-10)
	assert_eq(w.balance, 0, "adding a negative amount does nothing")
	assert_false(w.spend(-3), "spending a negative amount is refused (it would add gold)")
	assert_eq(w.balance, 0)
	w.add(Wallet.MAX_GOLD + 5)
	assert_eq(w.balance, Wallet.MAX_GOLD, "capped")
