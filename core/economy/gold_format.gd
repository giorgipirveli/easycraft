class_name GoldFormat
extends RefCounted
## Gold as children read it (M2 Task 7, the lead's child-psychology note): short numbers everywhere
## ("1.2K", "3.4M"). Always rounded down, so nobody sees more gold than they have.

const _UNITS: Array = [[1_000_000_000, "B"], [1_000_000, "M"], [1_000, "K"]]


static func short(amount: int) -> String:
	if amount < 0:
		return "-" + short(-amount)
	for unit: Array in _UNITS:
		var size: int = unit[0]
		if amount >= size:
			var whole := amount / size
			var tenth := (amount % size) * 10 / size
			if whole < 10 and tenth > 0:
				return "%d.%d%s" % [whole, tenth, unit[1]]
			return "%d%s" % [whole, unit[1]]
	return str(amount)


## A change of gold: "+12", "-1.2K".
static func change(amount: int) -> String:
	return ("+" if amount > 0 else "") + short(amount)


## What you have of what you need: "340 / 1.2K".
static func have_need(have: int, need: int) -> String:
	return "%s / %s" % [short(have), short(need)]
