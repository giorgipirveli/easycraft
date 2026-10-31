class_name GhostRaceRules
extends RefCounted
## Racing a friend's ghost (M4 ghost races; spec §17.5, research T2: "my friend races my ghost and gets bronze;
## I have gold"). Medals against the ghost's time: its time is gold, then ×1.3 silver and ×1.6 bronze (the way a
## course's first run sets its goals, CourseRules.default_goals). A friend's name shows only to a viewer who may
## see names: 13+, or under 13 with a grown-up's verified consent (spec §17.2); anyone else sees "A friend's
## ghost". Plain, kind words for every answer; no ranking, no shame words.

## The server's limits (tests/unit/test_race_ghost.gd reads them from ghost_rules.ts).
const PER_SHOWCASE := 3
const SHARES_PER_HOUR := 12

const _MESSAGES := {
	"no_showcase": "Put up your showcase first: MORE, SHARE, MY SHOWCASE.",
	"not_on_course": "That course is not in your showcase. Stand by it and SHOW IT again!",
	"not_in_showcase": "That course is not in your showcase. Stand by it and SHOW IT again!",
	"bad_ghost": "That run can't be shared. Race it once more!",
	"impossible_run": "That run can't be shared. Race it once more!",
	"too_many_ghosts": "Your showcase has 3 races already. Take one down first!",
	"no_run": "Race your course first: then friends can race your ghost!",
	"offline": "Your friends' ghosts need the internet this time.",
}


## Gold, silver and bronze times against a ghost of `ghost_ms`.
static func goals(ghost_ms: int) -> Array[int]:
	return CourseRules.default_goals(ghost_ms)


## The medal a run of `ms` wins against a ghost of `ghost_ms` (as fast as the ghost or faster: gold).
static func medal(ms: int, ghost_ms: int) -> StringName:
	return CourseRules.medal(ms, goals(ghost_ms))


static func beat(ms: int, ghost_ms: int) -> bool:
	return ms < ghost_ms


## Names show to 13+ and to under-13 with a grown-up's verified consent (spec §17.2).
static func shows_names(band: StringName, consent: String) -> bool:
	return band == AgeBand.TEEN_PLUS or consent == OnlineRules.CONSENT_VERIFIED


static func ghost_name(owner: String, shown: bool) -> String:
	return Lang.t("%s's ghost") % owner if shown and owner != "" else Lang.t("A friend's ghost")


## The finish's words against the ghost (the race clock shows the medal).
static func result_line(ms: int, ghost_ms: int, owner: String, shown: bool) -> String:
	var who := ghost_name(owner, shown)
	var m := medal(ms, ghost_ms)
	var prize := Lang.t("  " + String(m).to_upper() + "!") if m != &"" else ""   # "  GOLD!" … (M3 Task 21a's lines)
	if ms < ghost_ms:
		return Lang.t("You beat %s!%s") % [_lower_first(who), prize]
	if ms == ghost_ms:
		return Lang.t("Side by side with %s!%s") % [_lower_first(who), prize]
	return Lang.t("%s got there first. Race again!%s") % [who, prize]


static func _lower_first(who: String) -> String:
	return who if not who.begins_with("A ") else "a " + who.substr(2)


static func message(code: String) -> String:
	var c := code.strip_edges()
	return _MESSAGES.get(c, GiftRules.message(c))


## A list_ghosts answer's ghosts (well-formed ones only), with who they belong to.
static func ghosts_of(value: Variant, owner_id: String, owner: String) -> Array[RaceGhost]:
	var out: Array[RaceGhost] = []
	if not value is Array:
		return out
	for d: Variant in value:
		var g := RaceGhost.from_wire(d)
		if g != null and g.id != "":
			g.owner_id = owner_id
			g.owner = owner
			out.append(g)
	return out
