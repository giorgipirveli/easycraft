class_name LifeMoney
extends RefCounted
## Owner #112, #115 (docs/design/life-skills.md §5 #3; docs/design/success-skills.md §2.1, S1 and S2's Little stand):
## My Money Stall's sums. Pretend market coins of 1, 2, 5 and 10 (a ruling: the child's real gold is never spent in
## practice); change given coin by coin; the day's takings; the pretend bank's interest week by week, simple on the
## Middle track and compound on the Big (a generous RATE so the growth shows; the Experience says real banks pay much
## less); the values vary with the run's seed, so a repeat comes back a little different, and always add up.

const RATE := 10      # percent a week (pretend)
const WEEKS := 3
const COINS := {"little": [1, 2], "middle": [1, 2, 5], "big": [1, 2, 5, 10]}


## True when `amount` (> 0) can be made of any number of these coins.
static func can_make(amount: int, coins: Array) -> bool:
	if amount <= 0:
		return false
	var reach := {0: true}
	for v in range(1, amount + 1):
		for c: Variant in coins:
			if v - int(c) >= 0 and reach.has(v - int(c)):
				reach[v] = true
				break
	return reach.has(amount)


## The fewest coins that make `amount` (biggest first; the coach's way).
static func fewest(amount: int, coins: Array) -> Array:
	var values := coins.duplicate()
	values.sort()
	values.reverse()
	var out := []
	var left := amount
	for c: Variant in values:
		while left >= int(c):
			out.append(int(c))
			left -= int(c)
	return out


static func simple(amount: int, rate_percent: int, weeks: int) -> int:
	return amount + floori(amount * rate_percent / 100.0) * weeks


## Each week's interest on everything in the account, in whole coins.
static func compound(amount: int, rate_percent: int, weeks: int) -> int:
	var a := amount
	for w in weeks:
		a += floori(a * rate_percent / 100.0)
	return a


## The stall's values for a track and a run's seed: coins (the tray), price (a loaf), first_paid (the first customer
## pays exactly), qty, cost and paid (the second customer), change, takings (the cash box after both) with two wrong
## counts, jar (coins to save), deposit, bank_after and a wrong bank_wrong (and bank_simple on the Big track), budget
## (the shopping trip), and on the Big track sales, costs, profit and a wrong profit_wrong, and the Expert try's
## costs_up and profit_up.
static func stall_vars(track: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["money_stall", track, seed])
	var v := {"coins": (COINS.get(track, COINS.little) as Array).duplicate(), "weeks": WEEKS, "rate": RATE}
	match track:
		"middle":
			v.price = 3   # the cost of 2 and a profit of 1 (the price step)
			v.qty = rng.randi_range(1, 3)
			v.cost = int(v.price) * int(v.qty)
			v.paid = 10
			v.deposit = 10 * rng.randi_range(1, 2)
			v.bank_after = simple(int(v.deposit), RATE, WEEKS)
			v.bank_wrong = int(v.deposit) * 3
			v.budget = 10
		"big":
			v.price = 3
			v.cost = rng.randi_range(11, 18)
			v.qty = 1
			v.paid = 20
			v.deposit = 100
			v.bank_after = compound(100, RATE, WEEKS)
			v.bank_simple = simple(100, RATE, WEEKS)
			v.bank_wrong = 300
			v.budget = 20
			v.sales = 5 * rng.randi_range(8, 10)
			v.costs = 5 * rng.randi_range(3, 5)
			v.profit = int(v.sales) - int(v.costs)
			v.profit_wrong = int(v.sales) + int(v.costs)   # added instead of taken away
			v.costs_up = int(v.costs) + 5   # the Expert try: flour got dearer
			v.profit_up = int(v.profit) - 5
		_:
			v.price = 2
			v.qty = 1
			v.cost = 2
			v.paid = rng.randi_range(4, 5)
			v.deposit = 0
			v.bank_after = 0
			v.budget = 5
	v.first_paid = v.price
	v.change = int(v.paid) - int(v.cost)
	v.takings = int(v.first_paid) + int(v.cost)
	v.takings_wrong_a = int(v.takings) + int(v.change)
	v.takings_wrong_b = int(v.takings) - 1   # the takings are 4 or more on every track
	v.jar = 2 if track == "little" else 5
	return v
