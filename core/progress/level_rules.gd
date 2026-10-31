class_name LevelRules
extends RefCounted
## Levels, XP and play-style titles (M3 Task 12, spec §5.8, §14.11; research R5 and §1.8). Pure.
##
## Every progress event has a kind: a family ("monster_defeated") or a family with a detail
## ("monster_defeated/slime", "animal_tamed/dog"). The detail is for board goals and badges; XP and
## titles come from the family only. XP is informational (it never buys anything), so building earns
## it too, but a stamp's 200 blocks count as a few (MAX_PER_EVENT).

const MONSTER := &"monster_defeated"
const SECRET := &"secret_found"
const BLOCK := &"block_placed"
const WAVE := &"wave_won"
const BOSS := &"boss_beaten"
const BUDDY := &"buddy_woken"
const TAMED := &"animal_tamed"
const PHOTO := &"photo_taken"
const RACE := &"race_finished"      # M3 Task 7 (Game Blocks) calls Progress.event(&"race_finished")
const FRIEND := &"friend_played"
const EXPLORED := &"area_explored"
const GOAL := &"goal_done"          # an adventure board goal done (BoardRules)
# Owner #45a (spec §14.17): more counters for the board's new goals and the quest chains.
const CRAFTED := &"item_crafted"    # a craft the host made ("item_crafted/<recipe>", Session.host_craft)
const FED := &"pet_fed"             # a treat given to a pet or a pet-to-be ("pet_fed/<species>", PetDirector)
const RIDDEN := &"buddy_ridden"     # a ride on a buddy began ("buddy_ridden/<fly|drive|sail|walk>", RideDirector)
const QUEST_STEP := &"quest_step"   # a step of a quest chain done (QuestDirector)
const QUEST_DONE := &"quest_done"   # a quest chain done ("quest_done/<chain>", QuestDirector)

## XP for one of each event family.
const XP := {MONSTER: 10, SECRET: 25, BLOCK: 1, WAVE: 40, BOSS: 150, BUDDY: 20, TAMED: 30, PHOTO: 5, RACE: 25,
	FRIEND: 15, EXPLORED: 5, GOAL: 50, CRAFTED: 10, FED: 5, RIDDEN: 10, QUEST_STEP: 20, QUEST_DONE: 100}
## One event gives XP for at most this many (a stamp or a mirror batch is one event).
const MAX_PER_EVENT := {BLOCK: 5}
const DEFAULT_MAX_PER_EVENT := 10
## An event counts at most this many at once (a broken caller can't count a billion).
const MAX_AMOUNT := 10000

const MAX_LEVEL := 99
## Levels need 25 (L − 1)(L + 2) XP in all: level 2 at 100, 3 at 250, 5 at 700, 10 at 2,700; each
## level needs 50 more than the one before.
const CURVE := 25
## About what a child earns in a minute of mixed play (building, a monster now and then, a photo, a
## new place): level 2 in about 9 minutes, level 10 in about 4 hours. The curve test checks it.
const TYPICAL_XP_PER_MINUTE := 11.0
const KIND_MAX_LENGTH := 40

## Play styles: the families that make each one and its title. A style's title is earned at
## TITLE_XP XP in it; the name tag shows the chosen one, or the style played most (by XP).
const STYLES := {
	&"builder": {"families": [BLOCK], "title": "Master Builder"},
	&"hunter": {"families": [SECRET], "title": "Secret Hunter"},
	&"fighter": {"families": [MONSTER, WAVE], "title": "Monster Buster"},
	&"boss": {"families": [BOSS], "title": "Boss Slayer"},
	&"animals": {"families": [TAMED, FED], "title": "Animal Friend"},
	&"magic": {"families": [BUDDY, RIDDEN], "title": "Buddy Maker"},
	&"explorer": {"families": [EXPLORED], "title": "Explorer"},
	&"photo": {"families": [PHOTO], "title": "Photographer"},
	&"racer": {"families": [RACE], "title": "Speedy Racer"},
	&"friend": {"families": [FRIEND], "title": "Team Player"},
	&"crafter": {"families": [CRAFTED], "title": "Master Crafter"},              # owner #45a
	&"quester": {"families": [QUEST_STEP, QUEST_DONE], "title": "Quest Hero"},   # owner #45a
}
## The order styles are listed in, and the winner of a tie.
const STYLE_ORDER: Array[StringName] = [&"builder", &"hunter", &"fighter", &"boss", &"animals", &"magic",
	&"explorer", &"photo", &"racer", &"friend", &"crafter", &"quester"]
const TITLE_XP := 50
## Everyone's title before a style is earned.
const START_TITLE := "Adventurer"


## The family of a kind ("animal_tamed/dog" -> &"animal_tamed").
static func family(kind: StringName) -> StringName:
	var s := String(kind)
	var slash := s.find("/")
	return StringName(s.substr(0, slash) if slash >= 0 else s)


## Whether `kind` is one we count: a known family, maybe with a short detail of letters, digits and _.
static func is_kind(kind: StringName) -> bool:
	var s := String(kind)
	if s.is_empty() or s.length() > KIND_MAX_LENGTH or not XP.has(family(kind)):
		return false
	var slash := s.find("/")
	if slash < 0:
		return true
	var detail := s.substr(slash + 1)
	if detail.is_empty():
		return false
	for c in detail:
		if not (c == "_" or (c >= "a" and c <= "z") or (c >= "0" and c <= "9")):
			return false
	return true


## The XP one event of `kind` (counting `amount`) gives.
static func xp_for(kind: StringName, amount: int = 1) -> int:
	if not is_kind(kind) or amount <= 0:
		return 0
	var f := family(kind)
	return int(XP[f]) * mini(amount, int(MAX_PER_EVENT.get(f, DEFAULT_MAX_PER_EVENT)))


## All the XP it takes to reach `level` (level 1 needs none).
static func xp_to_reach(level: int) -> int:
	var l := clampi(level, 1, MAX_LEVEL)
	return CURVE * (l - 1) * (l + 2)


static func level_for(xp: int) -> int:
	var l := 1
	while l < MAX_LEVEL and xp >= xp_to_reach(l + 1):
		l += 1
	return l


## Vector2i(XP into this level, XP this level needs): the XP bar. At the top level, (0, 0).
static func level_progress(xp: int) -> Vector2i:
	var l := level_for(xp)
	if l >= MAX_LEVEL:
		return Vector2i.ZERO
	var base := xp_to_reach(l)
	return Vector2i(maxi(xp - base, 0), xp_to_reach(l + 1) - base)


## The style an event family belongs to (&"" when none).
static func style_of(kind: StringName) -> StringName:
	var f := family(kind)
	for s: StringName in STYLE_ORDER:
		if (STYLES[s].families as Array).has(f):
			return s
	return &""


static func title_text(style: StringName) -> String:
	if STYLES.has(style):
		return str(STYLES[style].title)
	if QuestRules.is_title(style):
		return QuestRules.title_words(style)   # owner #45a: a quest chain's title
	return START_TITLE


## A title the name tag may show: a play style's or a quest chain's (owner #45a).
static func is_title(id: StringName) -> bool:
	return STYLES.has(id) or QuestRules.is_title(id)


## The styles whose title the child has earned (style_xp: style -> XP), in STYLE_ORDER.
static func earned_titles(style_xp: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	for s: StringName in STYLE_ORDER:
		if int(style_xp.get(s, 0)) >= TITLE_XP:
			out.append(s)
	return out


## The style played most among the earned ones (&"" before any is earned). Ties: STYLE_ORDER.
static func main_style(style_xp: Dictionary) -> StringName:
	var best: StringName = &""
	var best_xp := -1
	for s in earned_titles(style_xp):
		if int(style_xp.get(s, 0)) > best_xp:
			best = s
			best_xp = int(style_xp.get(s, 0))
	return best


## The title shown: the one the child chose (if earned), else the style played most.
static func shown_title(style_xp: Dictionary, chosen: StringName) -> StringName:
	if chosen != &"" and earned_titles(style_xp).has(chosen):
		return chosen
	return main_style(style_xp)


## The name tag's line under the name: "Lv 5 Master Builder".
static func tag_line(level: int, style: StringName) -> String:
	return Lang.t("Lv %d %s") % [clampi(level, 1, MAX_LEVEL), title_text(style)]
