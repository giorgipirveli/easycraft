class_name DifficultyRules
extends RefCounted
## A Survivor world's difficulty (M2 Task 17, the research's Cozy / Normal / Brave, docs/design/),
## chosen when the world is made and saved with it. Gold is the same in all three. Cozy: monsters hurt
## half as much (never nothing) and a knock-out keeps your blocks (KnockoutRules.drops_bag); Brave:
## monsters hurt half again as much, and the world wears a badge. The host scales every hit
## (Session.hurt_player).

const COZY := KnockoutRules.COZY
const NORMAL := KnockoutRules.NORMAL
const BRAVE := KnockoutRules.BRAVE
const CHOICES: Array[StringName] = [COZY, NORMAL, BRAVE]

const _LABELS := {COZY: "COZY", NORMAL: "NORMAL", BRAVE: "BRAVE"}
const _ABOUT := {COZY: "Gentle monsters. Keep your blocks.", NORMAL: "Just right!",
	BRAVE: "Tough monsters. A Brave badge!"}


## What a monster's hit of `amount` does in a world of this difficulty.
static func damage(amount: int, difficulty: StringName) -> int:
	if amount <= 0:
		return 0
	match KnockoutRules.valid_difficulty(difficulty):
		COZY:
			return maxi(1, amount / 2)
		BRAVE:
			return ceili(amount * 1.5)
	return amount


static func label(difficulty: StringName) -> String:
	return _LABELS.get(KnockoutRules.valid_difficulty(difficulty), "NORMAL")


## One short, kind line under the choice's button.
static func about(difficulty: StringName) -> String:
	return _ABOUT.get(KnockoutRules.valid_difficulty(difficulty), "")


static func has_badge(difficulty: StringName) -> bool:
	return KnockoutRules.valid_difficulty(difficulty) == BRAVE
