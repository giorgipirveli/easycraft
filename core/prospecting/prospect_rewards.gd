class_name ProspectRewards
extends RefCounted
## What a prospecting quest pays when its deposit is marked on MY MAP (spec §26.4, §25.1; EarnRules' lines): the first
## time a child finishes a quest, EarnRules.PROSPECT_QUEST_GOLD (once per quest, like a School unit); every later
## deposit found with it (the next one is farther on), EarnRules.PROSPECT_FIND_GOLD while today's cap has room. Never for
## time, never random. Pure: the caller pays it into the child's gold (Survivor: the host's wallet; the Sandbox: the
## profile, like the School) and saves.


## The quest of `kind` is finished on `today` (a day number): counts the find and returns the gold it pays.
static func finish(data: ProspectData, kind: StringName, today: int) -> int:
	if not DepositKinds.is_kind(kind):
		return 0
	data.finds = mini(data.finds + 1, ProspectData.MAX_FINDS)
	if not data.has_done(kind):
		data.done.append(String(kind))
		return EarnRules.PROSPECT_QUEST_GOLD
	var d := int(data.today.get("d", -1))
	if today < d:
		return 0   # the clock went back: a day already counted is never paid again
	var had := int(data.today.get("g", 0)) if d == today else 0
	var pay := mini(EarnRules.PROSPECT_FIND_GOLD, EarnRules.PROSPECT_FIND_DAY_CAP - had)
	if pay <= 0:
		return 0
	data.today = {"d": today, "g": had + pay}
	return pay


## "+100 gold: you found your first copper!" / "+20 gold: another find!" / the day's cap.
static func words(gold: int, kind: StringName, first: bool) -> String:
	if gold <= 0:
		return "That's all the finding gold for today. Your finds still go on your map!"
	if first:
		return "+%d gold: you found your first %s!" % [gold, DepositKinds.display_name(kind).to_lower()]
	return "+%d gold: another find!" % gold
