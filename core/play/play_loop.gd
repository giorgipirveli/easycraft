class_name PlayLoop
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §4, rules 2, 4, 5): a unit's play, as a loop.
## - HOOK: the problem appears in the place (`hook_line`, PlayBlock.hook).
## - TRY: the round's first challenge, before any words (productive failure: a level-1 challenge for a new unit).
## - WHY: the coach's one line after the try (`see_why`, the unit's first coach line: one idea, at most 12 words).
## - PLAY: the rest of the round (RoundPlan: 6 challenges, easy to harder, from the unit's exercises and generators;
##   a review starts at its own level). After a right answer the coach adds the next line (`why_after`).
## - WORLD: the world task (`world_task`), a real task to take into the open world; then END.
## A challenge: a miss is NOT_YET (the world reacts, the hint), the second GHOST (the coach's ghost does one step in the
## game), the third SHOWN (the worked answer). Only a challenge right the first try with no help (SHOW ME, the ghost)
## counts (`right_first`): the round's result goes to MasteryRules.after_round exactly as a quiz round's did.

const HOOK := &"hook"
const TRY := &"try"
const WHY := &"why"
const PLAY := &"play"
const WORLD := &"world"
const END := &"end"

const MAX_TRIES := 3
const RIGHT := "right"
const NOT_YET := "not_yet"
const GHOST := "ghost"
const SHOWN := "shown"

var challenges: Array[Dictionary] = []
var index := 0
var phase: StringName = HOOK
var tries := 0
var helped := false
var answered := false
## The last answer was right the first try with no help.
var first_try := false
var right_first := 0
var hook_line := ""
var coach_lines: Array[String] = []
var world_task := ""


## A unit's loop: its round from `seed` (the unit's stars choose how hard), its hook, coach lines and world task.
## Owner #133, #134: the round is made only of what plays without reading (PlayReadless.content: a written choice or a
## claim stays in the School); `count` > 0 is a short round (a discovery crystal's minute: its first `count`).
static func make(content: Dictionary, seed: int, stars: int, unit: Dictionary = {}, count: int = 0) -> PlayLoop:
	var l := PlayLoop.new()
	l.challenges = RoundPlan.plan(PlayReadless.content(content), seed, stars)
	if count > 0 and l.challenges.size() > count:
		l.challenges = l.challenges.slice(0, count)
	l.hook_line = PlayBlock.hook(content)
	l.coach_lines = PlayBlock.coach(content, unit)
	l.world_task = PlayBlock.world_task(content, unit)
	return l


func current() -> Dictionary:
	return challenges[index] if index >= 0 and index < challenges.size() else {}


func total() -> int:
	return challenges.size()


## The hook is over: the try begins.
func start() -> void:
	if phase == HOOK:
		phase = TRY


## The child's answer to the current challenge was judged (ExerciseCheck): what happens now ("" when it is answered
## already).
func answer(right: bool) -> String:
	if answered or phase not in [TRY, PLAY]:
		return ""
	if right:
		answered = true
		first_try = tries == 0 and not helped
		if first_try:
			right_first += 1
		return RIGHT
	tries += 1
	first_try = false
	if tries >= MAX_TRIES:
		answered = true
		return SHOWN
	return NOT_YET if tries == 1 else GHOST


## SHOW ME: the coach shows one step; this challenge no longer counts as right the first time.
func show_me() -> void:
	if not answered:
		helped = true


## On to the next challenge (only once this one is answered): after the try comes WHY, after the last WORLD.
func next() -> StringName:
	if not answered:
		return phase
	index += 1
	tries = 0
	helped = false
	answered = false
	first_try = false
	if phase == TRY:
		phase = WHY if index < challenges.size() else WORLD
	elif index >= challenges.size():
		phase = WORLD
	return phase


## The coach's line has been seen: play on.
func play_on() -> void:
	if phase == WHY:
		phase = PLAY


func finish() -> void:
	phase = END


## The coach's one line after the try.
func see_why() -> String:
	return coach_lines[0] if not coach_lines.is_empty() else ""


## The coach's line after a right answer to challenge `i` of the play (the try's is the see-why card): one idea each.
func why_after(i: int) -> String:
	return coach_lines[i] if i >= 1 and i < coach_lines.size() else ""
