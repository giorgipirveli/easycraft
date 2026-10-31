class_name VoiceRules
extends RefCounted
## Animal and monster voices, as pure rules (the audio pass, owner feedback #27; owner 2026-09-24 20:42:
## "animals should have sounds, like real ones"). The sounds are Audio.SOUNDS names; the animals' are real
## CC0 recordings (tools/make_audio_pass_sfx.py). An animal calls now and then while this device's
## listener is within CALL_RADIUS (owner feedback #50: one chorus per device chooses the calls,
## AnimalChorusRules), cries out when pushed or hit, and makes its happy sound when petted or fed. Every
## animal has its own voice pitch (from its id; smaller animals higher), so a herd never sounds like one sample.

const CALL_RADIUS := 20.0         # blocks: an idle call is played only with the listener this close
const PITCH_SPREAD := 0.12        # every animal's voice is 1 ± this (before its size)

const _HURT := {
	&"dog": &"dog_hurt", &"cat": &"cat_hurt", &"pig": &"pig_hurt", &"cow": &"cow_hurt",
	&"sheep": &"sheep_hurt", &"chicken": &"chicken_hurt", &"rabbit": &"rabbit_hurt", &"fish": &"splash_small",
	# M3 Task 11's pets: their own real voices since owner #41's animals pack (Pip is a robot: a thud)
	&"fox": &"fox_hurt", &"parrot": &"parrot_hurt", &"pip": &"thud",
	# owner #41: every new kind's own hurt voice (real recordings; tools/make_audio_pass_sfx.py `pack`)
	&"horse": &"horse_hurt", &"donkey": &"donkey_hurt", &"goat": &"goat_hurt", &"deer": &"deer_hurt",
	&"duck": &"duck_hurt", &"frog": &"frog_hurt", &"turtle": &"turtle_hurt", &"squirrel": &"squirrel_hurt",
	&"owl": &"owl_hurt", &"hedgehog": &"hedgehog_hurt", &"camel": &"camel_hurt", &"lizard": &"lizard_hurt",
	&"fennec": &"fennec_hurt", &"penguin": &"penguin_hurt", &"polar_bear": &"bear_hurt", &"arctic_fox": &"arctic_fox_hurt",
	&"seal": &"seal_hurt", &"gummy_bunny": &"gummy_bunny_hurt", &"candy_bird": &"candy_bird_hurt",
	&"moon_bunny": &"rabbit_hurt",   # owner #55: the rabbits' recordings
	&"dragon": &"dragon_chirp",   # owner 39: a baby dragon only chirps
	&"monster_friend": &"gummy_bunny_hurt", &"mini_boss": &"thud",   # M3 Task 20b: a befriended monster, a boss's mini
}
## Petted or fed: a dog whines happily, a cat purrs, a horse nickers softly; the others make their own call.
const _HAPPY := {&"dog": &"dog_happy", &"cat": &"purr", &"horse": &"horse_happy"}
const _MONSTER_IDLE := {&"slime": &"squish", &"goblin": &"grunt", &"mummy": &"moan", &"scorpion": &"scorpion_click",
	&"shadow_bat": &"shadow_flutter", &"wisp": &"wisp_hum",   # owner #39: the Dragon Realm's
	&"spore_puff": &"spore_puff", &"crawler": &"crawler_click"}   # universe 6: the Glow Caves'
const _MONSTER_HURT := {&"slime": &"slime_hurt", &"goblin": &"goblin_hurt", &"mummy": &"mummy_hurt",
	&"scorpion": &"scorpion_hurt", &"shadow_bat": &"shadow_hurt", &"wisp": &"wisp_hurt",
	&"spore_puff": &"spore_hurt", &"crawler": &"crawler_hurt"}


## The species' own call (AnimalRules.SPECIES.sound); &"" for an unknown animal.
static func animal_call(species: StringName) -> StringName:
	var s: Dictionary = AnimalRules.SPECIES.get(species, {})
	return s.get("sound", &"")


static func animal_hurt(species: StringName) -> StringName:
	return _HURT.get(species, &"") if AnimalRules.SPECIES.has(species) else &""


static func animal_happy(species: StringName) -> StringName:
	return _HAPPY.get(species, animal_call(species))


# --- Owner feedback #50: the kinds' calls evened out -----------------------------------------------
## dB added to a kind's idle call. Measured through a phone speaker (EBU R128 after a 500 Hz high-pass,
## the takes looped): chickens -12.3 LUFS, rabbits -14.7, sheep -16.5, cats -17.1, dogs -19.2, pigs -21.7,
## cows -25.5 (a moo is mostly below 500 Hz). Brought towards -17; boosts capped at +3 dB (no clipping).
const CALL_GAIN_DB := {&"chicken": -5.0, &"rabbit": -2.0, &"sheep": 0.0, &"cat": 0.0, &"dog": 2.0,
	&"pig": 3.0, &"cow": 3.0,
	# Owner #41, measured the same way (docs/devlog/parts/owner-41-animals.md): candy birds -12.5 LUFS (as loud as
	# the hens: softened the same), parrots -15.3, foxes -16.5, squirrels -16.7, horses -17.0, arctic foxes -17.3,
	# goats and frogs -17.7, owls -18.0, gummy bunnies -18.4, fennecs -18.6, turtles -19.0, deer -19.4, donkeys
	# -19.5, penguins -19.8, ducks -19.9, camels -20.1, hedgehogs -21.2, lizards -22.8, seals -26.7, polar bears
	# -27.9 (a grizzly's low huff is mostly under 500 Hz). Towards -17; boosts capped at +3 dB.
	&"candy_bird": -4.5, &"parrot": -1.7, &"fox": -0.5, &"squirrel": -0.3, &"horse": 0.0, &"arctic_fox": -0.3,
	&"goat": 0.7, &"frog": 0.7, &"owl": 1.0, &"gummy_bunny": 1.4, &"fennec": 1.6, &"turtle": 2.0, &"deer": 2.4,
	&"donkey": 2.5, &"penguin": 2.8, &"duck": 2.9, &"camel": 3.0, &"hedgehog": 3.0, &"lizard": 3.0, &"seal": 3.0,
	&"polar_bear": 3.0,
	# measured with them: the fish's takes -15.2 (the blub) to -33.8 (a splash), kept at 0 as #50 left them (a louder
	# fish was the old flood's other half); Pip's beep -17.6
	&"fish": 0.0, &"pip": 0.0,
	# owner #39's pet dragon, measured the same way by the lead (2026-09-25): its two chirps -13.9 LUFS -> -3 dB
	&"dragon": -3.0,
	# M3 Task 20b: a befriended monster squeaks with the gummy bunnies' takes, a boss's mini-buddy chirps with the pet
	# dragon's (the same recordings, so the same measured levels)
	&"monster_friend": 1.4, &"mini_boss": -3.0,
	# owner #55: a moon bunny squeaks with the rabbits' takes (the same recordings, so the rabbits' measured level)
	&"moon_bunny": -2.0}


static func call_gain_db(species: StringName) -> float:
	return float(CALL_GAIN_DB.get(species, 0.0))


## An animal's own voice: 1 ± PITCH_SPREAD from its id (the same every time), divided by the square root
## of its size (a baby at 0.5 is ~1.4× higher). Clamped to 0.6..1.7 so it always sounds like the animal.
static func voice_pitch(id: String, size: float = 1.0) -> float:
	var h := float(((hash(id) * 2654435761) >> 13) & 0xFFFF) / 65535.0   # mixed: similar ids spread out
	var own := 1.0 + PITCH_SPREAD * (h * 2.0 - 1.0)
	return clampf(own / sqrt(maxf(size, 0.01)), 0.6, 1.7)


## A monster's voice while it goes about (a goblin grunts, a slime squishes); an unknown kind uses its
## MonsterRules sound.
static func monster_idle(kind: StringName) -> StringName:
	if _MONSTER_IDLE.has(kind):
		return _MONSTER_IDLE[kind]
	var k: Dictionary = MonsterRules.KIND.get(kind, {})
	return k.get("sound", &"")


## A monster's cry when a hit lands (a kind without its own uses the weapons' hit).
static func monster_hurt(kind: StringName) -> StringName:
	return _MONSTER_HURT.get(kind, &"hit")


## M5 Task 2: a monster kind's idle voice evened out through a phone speaker towards the goblins' grunts (dB;
## Loudness, measured by tools/measure_loudness.py; MonsterChorusRules.volume_db adds it).
static func monster_gain_db(kind: StringName) -> float:
	return Loudness.voice_gain_db(kind)
