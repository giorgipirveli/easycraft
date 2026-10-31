class_name Wallet
extends RefCounted
## Gold (M2 §12.1): one currency, kept per mode (Survivor gold lives in the profile). Never negative;
## spending needs enough; bad amounts (negative) are ignored, so a buggy caller can never mint gold.

const MAX_GOLD := 999_999_999

var balance := 0


func _init(start: int = 0) -> void:
	balance = clampi(start, 0, MAX_GOLD)


func add(amount: int) -> void:
	if amount > 0:
		balance = mini(balance + amount, MAX_GOLD)


func can_spend(amount: int) -> bool:
	return amount >= 0 and amount <= balance


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	balance -= amount
	return true
