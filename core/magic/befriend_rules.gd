class_name BefriendRules
extends RefCounted
## Befriend a monster with the wand (M3 Task 20b, spec §14.21, research P4 "a kind choice: fight, hide or
## befriend"): a tap with the Magic Wand on a calm (not chasing) monster of level 1 or 2 turns it into the child's
## pet friend (species SPECIES, the monster kind as its variant): it follows, never hurts anyone and fights
## nothing, and it counts toward the pet cap (AnimalRules.MAX_PETS). Never a boss, a wave's monster or a golden
## slime; Sandbox and Survivor (not Monster Wave). The host decides (BuddyMagicDirector). Pure.

const SPECIES := &"monster_friend"
const MAX_LEVEL := 2

const OK := &""
const TOO_STRONG := &"too_strong"
const NOT_CALM := &"not_calm"
const BOSS := &"boss"
const WAVE := &"wave"
const GOLDEN := &"golden"
const MODE := &"mode"
const FULL := &"full"
const TOO_FAR := &"too_far"

const _WORDS := {
	TOO_STRONG: "This one is too strong to be friends. Try a small monster (level 1 or 2)!",
	NOT_CALM: "It is too excited right now. Wait until it calms down, then try the wand.",
	BOSS: "Bosses are too big to be friends... but beat one and see what happens!",
	WAVE: "Not in the middle of a wave! Try after it.",
	GOLDEN: "The golden slime only wants to play catch!",
	MODE: "No new friends in Monster Wave.",
	TOO_FAR: "Get a little closer to make friends!",
}


## Why this monster can't become a friend (OK: it can). pets_owned: the child's pets that count toward the cap.
static func refusal(level: int, chasing: bool, is_boss: bool, in_wave: bool, golden: bool, mode: StringName,
		pets_owned: int) -> StringName:
	if is_boss:
		return BOSS
	if mode == ModeRules.WAVE:
		return MODE
	if golden:
		return GOLDEN
	if in_wave:
		return WAVE
	if level > MAX_LEVEL:
		return TOO_STRONG
	if chasing:
		return NOT_CALM
	if pets_owned >= AnimalRules.MAX_PETS:
		return FULL
	return OK


static func message(code: StringName) -> String:
	if code == FULL:
		return Lang.t("You already have %d pets! A new friend needs a free spot.") % AnimalRules.MAX_PETS
	return _WORDS.get(code, "")


## Every monster kind of the night can become a friend (bosses are not monster kinds).
static func is_befriendable_kind(kind: StringName) -> bool:
	return MonsterRules.KINDS.has(kind)


## The friend's first name: a fun pet name from its id (the same one every time).
static func friend_name(id: String) -> String:
	return PetRules.first_name(SPECIES, id)


## What the child hears.
static func words(pet_name: String) -> String:
	return Lang.t("%s is your friend now! It follows you and never fights.") % pet_name
