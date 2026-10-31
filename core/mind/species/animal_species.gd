class_name AnimalSpecies
extends RefCounted
## The animals' mind tables (M2 Task 18, spec §12.17): what a real animal does — graze and wander by
## day, stay with its herd and follow the leader, run over to a player it likes, run from danger,
## sleep at night by its den, go and look at something new, or stand and watch a player. The
## defaults are hand-made so a newborn animal already acts sensibly; species differ by TRAITS (dogs
## come closer, rabbits run sooner, sheep stick together). One table per species, built once.

const GRAZE := &"graze"
const WANDER := &"wander"
const HERD := &"herd"             # go back to the herd's leader
const APPROACH := &"approach"     # run over to a player it likes
const FLEE := &"flee"             # keep away from what scared it
const SLEEP := &"sleep"           # go to the den and sleep
const EXPLORE := &"explore"       # go and look at something new
const WATCH := &"watch"           # stand and look at a player
const ACTIONS: Array[StringName] = [GRAZE, WANDER, HERD, APPROACH, FLEE, SLEEP, EXPLORE, WATCH]

## The hidden units: readable features of the senses.
const F_DANGER := 0
const F_FRIEND := 1
const F_HUNGRY := 2
const F_SLEEPY := 3
const F_CURIOUS := 4
const F_LONELY := 5
const F_HOMESICK := 6
const F_CALM := 7
const F_WATCHFUL := 8
const F_CONTENT := 9
const F_DAY := 10
const F_ONE := 11

## What each species does more (× its action rows) than the plain herd animal.
const TRAITS := {
	&"dog": {APPROACH: 1.3, EXPLORE: 1.3, HERD: 0.6, FLEE: 0.7},
	&"cat": {EXPLORE: 1.4, HERD: 0.4, APPROACH: 0.9, WATCH: 1.3},
	&"pig": {GRAZE: 1.2},
	&"cow": {GRAZE: 1.2, HERD: 1.2, FLEE: 0.8},
	&"sheep": {HERD: 1.4},
	&"chicken": {GRAZE: 1.1, FLEE: 1.2},
	&"rabbit": {FLEE: 1.4, EXPLORE: 0.8, APPROACH: 0.8},
	&"fish": {HERD: 1.2},
	# M3 Task 11: a shy, curious fox; a watchful parrot; Pip, a friendly robot who comes over to look
	&"fox": {FLEE: 1.2, EXPLORE: 1.3, HERD: 0.4, WATCH: 1.1},
	&"parrot": {EXPLORE: 1.2, WATCH: 1.3, HERD: 0.8},
	&"pip": {APPROACH: 1.3, EXPLORE: 1.3, FLEE: 0.5, HERD: 0.4},
	&"dragon": {APPROACH: 1.4, EXPLORE: 1.2, FLEE: 0.4, HERD: 0.5, WATCH: 1.1},   # owner 39: a bold, curious baby
	# Owner #41 (spec §14.19): herd horses and camels, a watchful donkey, curious goats, shy deer, ducks and
	# penguins that stick together, a slow calm turtle, a busy squirrel, an owl that watches (and sleeps by day:
	# AnimalRules.nocturnal), a calm hedgehog, darting lizards, a gentle curious polar bear, lazy seals, friendly
	# gummy bunnies and flocking candy birds.
	&"horse": {HERD: 1.3, GRAZE: 1.2, APPROACH: 1.1},
	&"donkey": {GRAZE: 1.2, WATCH: 1.2, HERD: 0.9},
	&"goat": {EXPLORE: 1.3, GRAZE: 1.1, HERD: 1.1},
	&"deer": {FLEE: 1.5, HERD: 1.2, APPROACH: 0.6},
	&"duck": {HERD: 1.4, GRAZE: 1.1},
	&"frog": {WANDER: 1.2, GRAZE: 0.8, FLEE: 1.2},
	&"turtle": {GRAZE: 1.2, WANDER: 0.8, FLEE: 0.5},
	&"squirrel": {EXPLORE: 1.4, FLEE: 1.3, HERD: 0.5},
	&"owl": {WATCH: 1.4, SLEEP: 1.2, HERD: 0.4},
	&"hedgehog": {GRAZE: 1.1, FLEE: 0.6, WANDER: 1.1},
	&"camel": {GRAZE: 1.1, HERD: 1.2, FLEE: 0.6},
	&"lizard": {FLEE: 1.3, WANDER: 1.2, HERD: 0.4},
	&"fennec": {FLEE: 1.2, EXPLORE: 1.3, HERD: 0.4, WATCH: 1.1},
	&"penguin": {HERD: 1.5, WATCH: 1.1},
	&"polar_bear": {FLEE: 0.4, APPROACH: 1.1, EXPLORE: 1.2, HERD: 0.4},
	&"arctic_fox": {FLEE: 1.2, EXPLORE: 1.3, HERD: 0.4, WATCH: 1.1},
	&"seal": {GRAZE: 1.3, FLEE: 0.7, HERD: 1.1},
	&"gummy_bunny": {APPROACH: 1.2, HERD: 1.2},
	&"candy_bird": {HERD: 1.3, EXPLORE: 1.2},
	&"moon_bunny": {APPROACH: 1.3, HERD: 1.2, EXPLORE: 1.2},   # owner #55: curious and friendly
	# M3 Task 20b: a befriended monster stays close to its new friend; a boss's mini-buddy is bold like the dragon
	&"monster_friend": {APPROACH: 1.4, EXPLORE: 1.1, FLEE: 0.5, HERD: 0.4, WATCH: 1.1},
	&"mini_boss": {APPROACH: 1.4, EXPLORE: 1.0, FLEE: 0.4, HERD: 0.4, WATCH: 1.2},
}
## Rewards: animals like being fed and petted and dislike being hit or chased.
const REWARDS := {&"fed": 1.0, &"petted": 0.6, &"hit": -1.0, &"chased": -0.4, &"grazed": 0.2,
	&"slept": 0.1, &"explored": 0.1}

## A tap on an animal while holding one of these is a treat (plants: every animal here likes them).
const TREATS: Array[int] = [BlockIds.GRASS, BlockIds.LEAVES]

static var _tables := {}


static func index(action: StringName) -> int:
	return ACTIONS.find(action)


static func is_treat(item: int) -> bool:
	return TREATS.has(item)


## The mind table of an animal species (AnimalRules.SPECIES), built once.
static func table(species: StringName) -> MindSpecies:
	if not _tables.has(species):
		_tables[species] = _build(species)
	return _tables[species]


static func _build(species: StringName) -> MindSpecies:
	var t := MindSpecies.new(StringName("animal:%s" % species), ACTIONS)
	t.feature(F_DANGER, {Mind.S_FEAR: 1.0, Mind.S_RUSH: 1.5, Mind.S_THREAT: 1.2, Mind.S_AFRAID: 1.0})
	t.feature(F_FRIEND, {Mind.S_LIKE: 1.5, Mind.S_NEAR: 0.5, Mind.S_FEAR: -1.0}, -0.3)
	t.feature(F_HUNGRY, {Mind.S_DRIVE_A: 1.5, Mind.S_NIGHT: -0.5}, -0.3)
	t.feature(F_SLEEPY, {Mind.S_DRIVE_B: 1.5, Mind.S_NIGHT: 1.0}, -1.0)
	t.feature(F_CURIOUS, {Mind.S_CURIOUS: 1.0, Mind.S_NOVEL: 1.5}, -0.6)
	t.feature(F_LONELY, {Mind.S_LONELY: 1.5, Mind.S_KIN: -1.0}, -0.2)
	t.feature(F_HOMESICK, {Mind.S_HOME_FAR: 1.0, Mind.S_NIGHT: 1.0}, -1.0)
	t.feature(F_CALM, {Mind.S_AFRAID: -1.0, Mind.S_THREAT: -1.0, Mind.S_RUSH: -1.0}, 1.0)
	t.feature(F_WATCHFUL, {Mind.S_NEAR: 1.0, Mind.S_LIKE: -0.5, Mind.S_FEAR: -0.5}, -0.3)
	t.feature(F_CONTENT, {Mind.S_OUTCOME: 1.0}, -0.5)
	t.feature(F_DAY, {Mind.S_NIGHT: -1.0}, 1.0)
	t.feature(F_ONE, {}, 1.0)
	var traits: Dictionary = TRAITS.get(species, {})
	t.action_row(GRAZE, {F_HUNGRY: 2.0, F_CALM: 0.4, F_DAY: 0.4, F_DANGER: -2.0, F_SLEEPY: -1.0}, 0.0, traits.get(GRAZE, 1.0))
	t.action_row(WANDER, {F_CALM: 0.5, F_DAY: 0.3, F_DANGER: -1.0, F_SLEEPY: -1.5}, 0.0, traits.get(WANDER, 1.0))
	t.action_row(HERD, {F_LONELY: 2.5, F_DANGER: 0.5, F_SLEEPY: -0.5}, -0.3, traits.get(HERD, 1.0))
	t.action_row(APPROACH, {F_FRIEND: 3.5, F_DANGER: -1.5, F_SLEEPY: -1.0}, -0.5, traits.get(APPROACH, 1.0))
	t.action_row(FLEE, {F_DANGER: 3.0, F_CALM: -1.0}, -0.5, traits.get(FLEE, 1.0))
	t.action_row(SLEEP, {F_SLEEPY: 3.0, F_HOMESICK: 0.5, F_DANGER: -2.0}, -1.0, traits.get(SLEEP, 1.0))
	t.action_row(EXPLORE, {F_CURIOUS: 2.5, F_DANGER: -1.5, F_SLEEPY: -1.0}, -0.3, traits.get(EXPLORE, 1.0))
	t.action_row(WATCH, {F_WATCHFUL: 1.5, F_CALM: 0.2}, -0.2, traits.get(WATCH, 1.0))
	t.commit = PackedFloat32Array([4.0, 3.0, 2.0, 2.0, 2.0, 10.0, 4.0, 3.0])
	# hunger, sleepiness, fear, curiosity, company (and the unused monster/bot drives)
	t.drive_start = PackedFloat32Array([0.3, 0.1, 0.0, 0.4, 0.2, 0.0, 0.0, 0.0, 0.0])
	t.rewards = REWARDS
	t.thoughts = {index(APPROACH): Thought.HEART, index(FLEE): Thought.SWEAT, index(SLEEP): Thought.ZZZ,
		index(EXPLORE): Thought.QUESTION}
	return t
