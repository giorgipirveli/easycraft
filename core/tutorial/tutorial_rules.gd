class_name TutorialRules
extends RefCounted
## The tutorial with Pip (M3 Task 15, spec §14.9, §5.10) as pure rules: its steps in order, each with a line id,
## a picture and very short words (icon-first; read aloud with "Read to me"); where it plays (a solo Survivor
## world: never LAN, online, Sandbox or Monster Wave); the first-start offer (PLAY WITH PIP / SKIP); SKIP never
## asked again; stopping and going on from the same step; SETTINGS' replay; the reward once per profile.
## The state lives in ProfileData.tutorial (TutorialData).

## Every line the tutorial says, by id (English is the key the Georgian translates; read aloud as they show).
const LINES := {
	&"tutorial_move": "Walk to the arrow and look around!",
	&"tutorial_jump": "Jump over the hole: tap JUMP three times!",
	&"tutorial_bridge": "Put 3 blocks in the hole to make a bridge!",
	&"tutorial_wall": "Break the wall to get through!",
	&"tutorial_hide": "A practice slime! Crouch in the bush to hide.",
	&"tutorial_craft": "Make sticks by the Workbench: tap +, then CRAFT.",
	&"tutorial_tilly": "Follow the arrow to Tilly's shop!",
	&"tutorial_jump_again": "Jump out and try again!",
	&"tutorial_bridge_gift": "Here are 3 blocks for your bridge!",
	&"tutorial_hide_seen": "It sees you! Crouch in the bush.",
	&"tutorial_step_back": "Step off so Pip can build the playground!",
	&"tutorial_praise_1": "Great!",
	&"tutorial_praise_2": "Yay! Well done!",
	&"tutorial_praise_3": "You did it!",
	&"tutorial_hello": "Hi! I'm Pip!",
	&"tutorial_offer": "Shall we learn together?",
	&"tutorial_resume": "Shall we go on where we stopped?",
	&"tutorial_done": "You did it! You know it all!",
	&"tutorial_reward_gold": "+500 gold",
	&"tutorial_reward_hat": "Pip's Cap",
	&"tutorial_reward_pip": "Pip is your pet now!",
	&"tutorial_again_done": "Well done! You know it all!",
}

## The steps, in order. picture: [&"hud", a HudIcons symbol] or [&"block", a block or item id].
const STEPS: Array[Dictionary] = [
	{"id": &"move", "line": &"tutorial_move", "picture": [&"hud", &"walk"]},
	{"id": &"jump", "line": &"tutorial_jump", "picture": [&"hud", &"jump"]},
	{"id": &"bridge", "line": &"tutorial_bridge", "picture": [&"block", BlockIds.PLANKS]},
	{"id": &"wall", "line": &"tutorial_wall", "picture": [&"block", ItemIds.PICKAXE]},
	{"id": &"hide", "line": &"tutorial_hide", "picture": [&"block", BlockIds.BUSH]},
	{"id": &"craft", "line": &"tutorial_craft", "picture": [&"block", ItemIds.STICK]},
	{"id": &"tilly", "line": &"tutorial_tilly", "picture": [&"hud", &"shop"]},
]
const PRAISE: Array[StringName] = [&"tutorial_praise_1", &"tutorial_praise_2", &"tutorial_praise_3"]

## The reward (spec §5.10): Survivor gold, the free hat (AvatarCatalog's EARN_TUTORIAL item) and Pip.
const REWARD_GOLD := 500
const EARN := AvatarCatalog.EARN_TUTORIAL
## The universes it plays in (the Dragon Realm floats over a void: no ground to lay the playground on).
const PLAYS_IN: Array[StringName] = [&"meadows", &"desert", &"frost", &"candy"]
## The playground's name on the find arrow ("You found Pip's playground!").
const PLAYGROUND := "Pip's playground"


static func count() -> int:
	return STEPS.size()


static func step_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for s: Dictionary in STEPS:
		out.append(s.id)
	return out


static func step_id(i: int) -> StringName:
	return STEPS[clampi(i, 0, count() - 1)].id


static func line_id(i: int) -> StringName:
	return STEPS[clampi(i, 0, count() - 1)].line


static func picture(i: int) -> Array:
	return STEPS[clampi(i, 0, count() - 1)].picture


## A step's words (English; the card and the voice translate them).
static func words(i: int) -> String:
	return line(line_id(i))


static func line(id: StringName) -> String:
	return str(LINES.get(id, ""))


## The praise after step i (a few kinds, in turn).
static func praise(i: int) -> StringName:
	return PRAISE[posmod(i, PRAISE.size())]


# --- Where it plays ---

## A Survivor world played alone (`net`: Game.net_mode; `online`: an online match), the CLASSIC game (Build to
## Survive's night comes fast), in a universe with ground to lay the playground on.
static func plays_here(mode: StringName, net: StringName, online: bool, game: StringName, universe: StringName) -> bool:
	return mode == ModeRules.SURVIVOR and net == &"solo" and not online and SurvivorGames.valid(game) == SurvivorGames.CLASSIC \
		and PLAYS_IN.has(universe)


# --- The offer and the replay ---

## The card PLAY WITH PIP / SKIP: never started, or stopped part way; never after SKIP or when done.
static func wants_offer(t: TutorialData, here: bool) -> bool:
	return here and not t.replay and (t.state == TutorialData.NEW or t.state == TutorialData.STARTED)


## SETTINGS asked for it: it starts without the card.
static func starts_now(t: TutorialData, here: bool) -> bool:
	return here and t.replay


## Owner #37's first-time shop tip waits while the tutorial is offered or starts (its Tilly step shows it).
static func holds_tip(t: TutorialData, here: bool) -> bool:
	return wants_offer(t, here) or starts_now(t, here)


## The offer goes on where it stopped.
static func is_resume(t: TutorialData) -> bool:
	return t.state == TutorialData.STARTED and t.step > 0


static func ask_replay(t: TutorialData) -> void:
	t.replay = true


# --- Playing ---

## PLAY WITH PIP (or SETTINGS): the step to start at. A tutorial never finished goes on where it stopped; a replay
## (after SKIP or when done) starts at the beginning and changes nothing (it is never offered again).
static func begin(t: TutorialData) -> int:
	t.replay = false
	match t.state:
		TutorialData.NEW:
			t.state = TutorialData.STARTED
			t.step = 0
			return 0
		TutorialData.STARTED:
			return clampi(t.step, 0, count() - 1)
	return 0


## Step `done_step` was done: a first run remembers the next one (a stop goes on from there).
static func advance(t: TutorialData, done_step: int) -> void:
	if t.state == TutorialData.STARTED:
		t.step = clampi(done_step + 1, 0, count() - 1)


## SKIP: no reward, never asked again.
static func skip(t: TutorialData) -> void:
	t.replay = false
	if t.state == TutorialData.NEW or t.state == TutorialData.STARTED:
		t.state = TutorialData.SKIPPED
		t.step = 0


## Every step done: true when the reward is due now (the first finish of this profile, also after a skip).
static func finish(t: TutorialData) -> bool:
	var due := not t.rewarded
	t.rewarded = true
	t.state = TutorialData.DONE
	t.step = 0
	t.replay = false
	return due
