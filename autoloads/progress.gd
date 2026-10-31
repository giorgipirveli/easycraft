extends Node
## The progress event bus (M3 Task 12, spec §5.8, §14.11): one entry point, `event(kind, amount)`, for
## everything a child does that counts: monsters beaten, secrets found, blocks placed, waves won,
## bosses beaten, buddies woken, animals tamed, photos taken, races finished (M3 Task 7 calls
## `Progress.event(&"race_finished")`), friends played with, new places explored. Kinds are
## LevelRules families, or "family/detail" ("animal_tamed/dog") for the board's goals and the badges.
##
## Each player's own game counts its own events into its own profile (Profile.data.progress): XP and
## the level, the style titles, the adventure board, badges and the pet's present clock. The host tells
## a guest about the events the host decides (Session.progress_tell). Events count only while a world
## is being played (`begin` / `end`, called by the world's ProgressDirector), so menus and tests never
## touch a child's progress. The profile is saved with the world (every minute, on pause and on quit),
## like Survivor gold.

## Anything changed (the board, the XP bar, the name tag follow it).
signal changed
## This player reached a new level (the local celebration).
signal leveled_up(level: int)
## A board goal was done: its fixed Survivor gold (0 in Sandbox or for a creative goal).
signal goal_done(goal_id: StringName, gold: int)
## A new badge for the trophy room.
signal badge_unlocked(badge_id: StringName)
## The pet brought a present; it waits on the board until the child picks a gift.
signal present_ready
signal present_opened(gift_id: StringName)
## Owner #45a: an event was counted (the quests follow it; co-op sends it to the host's shared story).
signal counted(kind: StringName, amount: int)

## Owner #45a: the universe events happen in (counted per universe too: a goal or a story of one universe).
var universe: Callable = func() -> int: return Game.universe

## Whether this world pays Survivor gold (Sandbox gold is endless: stickers there).
var survivor: Callable = func() -> bool: return not Game.allows(ModeRules.INFINITE_GOLD)
## Asks the host for a goal's gold (the host checks it: Session.progress_host_goal_gold).
var ask_goal_gold: Callable = func(goal_id: StringName) -> void: Session.progress_goal_gold(goal_id)
## Asks the host for a Survivor present's gift (Session.progress_host_present).
var ask_present: Callable = func(gift_id: StringName) -> void: Session.progress_present(gift_id)

var _counting := false
var _data: ProgressData   # a test's own data; null = the profile's


## A world is being played: events count from now (tests pass their own data).
func begin(data_override: ProgressData = null) -> void:
	_data = data_override
	_counting = true
	BoardRules.ensure_board(data())


func end() -> void:
	_counting = false
	_data = null


func is_counting() -> bool:
	return _counting


## The progress being counted (the profile's; read each time, so a restored backup is followed).
func data() -> ProgressData:
	return _data if _data else Profile.data.progress


## Counts `amount` of `kind` (LevelRules): XP, the board's goals, badges and a level-up.
func event(kind: StringName, amount: int = 1) -> void:
	if not _counting or not LevelRules.is_kind(kind) or amount <= 0:
		return
	var d := data()
	var before := d.level()
	d.record(kind, amount, int(universe.call()))
	counted.emit(kind, amount)
	for goal_id in BoardRules.check(d):
		_goal_done(d, goal_id)
	for badge_id in AchievementRules.check(d):
		badge_unlocked.emit(badge_id)
	if d.level() > before:
		leveled_up.emit(d.level())
	changed.emit()


## A goal is done: its sticker, its XP, and in Survivor its gold from the host.
func _goal_done(d: ProgressData, goal_id: StringName) -> void:
	d.add_sticker(String(goal_id))
	d.record(LevelRules.GOAL)
	var gold := BoardRules.gold_for(goal_id) if survivor.call() else 0
	if gold > 0:
		ask_goal_gold.call(goal_id)
	goal_done.emit(goal_id, gold)


## The child picked goal `goal_id` for board slot `slot` (a new one, or instead of the one there).
func pick_goal(slot: int, goal_id: StringName) -> bool:
	if not BoardRules.pick(data(), slot, goal_id):
		return false
	changed.emit()
	return true


## The title on the name tag: an earned style, or &"" for the style played most.
func choose_title(style: StringName) -> bool:
	var d := data()
	if style != &"" and not LevelRules.earned_titles(d.style_xp).has(style) and not QuestRules.titles(d).has(style):
		return false
	d.title = style
	changed.emit()
	return true


func level() -> int:
	return data().level()


func shown_title() -> StringName:
	var d := data()
	if QuestRules.titles(d).has(d.title):
		return d.title   # owner #45a: a quest story's title the child picked
	return LevelRules.shown_title(d.style_xp, d.title)


## The synced name tag code, "<level>:<style>" (Player.progress_tag).
func tag() -> String:
	return "%d:%s" % [level(), shown_title()]


## Counts `delta` seconds toward the pet's present (only active play with a pet near counts).
func present_tick(delta: float, active: bool, has_pet: bool) -> void:
	if _counting and PresentRules.tick(data(), delta, active, has_pet):
		present_ready.emit()
		changed.emit()


## Opens the waiting present with the gift the child picked (Sandbox: a sticker; Survivor: from the host).
func open_present(gift_id: StringName) -> bool:
	var is_survivor: bool = survivor.call()
	var g := PresentRules.open(data(), gift_id, is_survivor)
	if g.is_empty():
		return false
	if is_survivor:
		ask_present.call(gift_id)
	present_opened.emit(gift_id)
	changed.emit()
	return true
