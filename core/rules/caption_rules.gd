class_name CaptionRules
extends RefCounted
## Sound captions (M5 Task 1, spec §15.1a), as rules: which of Audio's sounds get a small picture and a word on the
## HUD, how often, and where. For children who play with the sound off (phones are often muted) or can't hear it:
## a monster nearby (its voice), the Sneaker's jingle, a hiss, a boss's roar, the Sand Serpent's rumble below, the
## wave horn, night falling (SoundCaptions watches the sky) and someone talking (a friend's babble). One per kind
## every REST seconds, at most MAX_SHOWN at once, each for SHOW_TIME seconds.

const REST := 4.0
const MAX_SHOWN := 3
const SHOW_TIME := 2.5
const FADE_TIME := 0.5
## A chip: the picture and a few words on a dark backing.
const CHIP := Vector2(230, 48)
## Where chips sit: on an oval round the middle of the screen, towards the sound, inside the HUD's corner buttons and
## above the hotbar (this far in from each edge).
const INSET := Vector2(320, 150)

const KINDS := {
	&"monster": {"words": "Monster near", "icon": &"monster"},
	&"sneak": {"words": "Jingle! Sneaker", "icon": &"bell"},
	&"hiss": {"words": "Hiss!", "icon": &"snake"},
	&"boss": {"words": "Boss roar!", "icon": &"crown"},
	&"rumble": {"words": "Rumble below!", "icon": &"rumble"},
	&"horn": {"words": "Wave horn!", "icon": &"horn"},
	&"night": {"words": "Night falls", "icon": &"moon"},
	&"talk": {"words": "Someone talks", "icon": &"chat"},
}
## The pictures SoundCaptions draws (HudIcons draws moon and chat).
const ICONS: Array[StringName] = [&"monster", &"bell", &"snake", &"crown", &"rumble", &"horn", &"moon", &"chat"]

## Audio's sound -> its caption's kind. Monsters' voices (VoiceRules.monster_idle, MonsterRules.KIND) and the flyers'
## dive squeaks; the bosses' roars; the serpent's warning rumble; the wave horn; the babble of friends talking.
const SOUNDS := {
	&"squish": &"monster", &"grunt": &"monster", &"growl": &"monster", &"moan": &"monster",
	&"scorpion_click": &"monster", &"yeti_roar": &"monster", &"screech": &"monster", &"gummy": &"monster",
	&"shadow_squeak": &"monster", &"shadow_flutter": &"monster", &"wisp_hum": &"monster", &"wisp_chime": &"monster",
	&"wisp_charge": &"monster",
	&"jingle": &"sneak",
	&"hiss": &"hiss",
	&"golem_roar": &"boss", &"serpent_roar": &"boss", &"giant_roar": &"boss", &"cake_roar": &"boss",
	&"sky_dragon_roar": &"boss",
	&"serpent_rumble": &"rumble",
	&"horn": &"horn",
	&"babble": &"talk",
}


## The caption's kind for one of Audio's sounds (&"" for none).
static func kind_of(sound: StringName) -> StringName:
	return SOUNDS.get(sound, &"")


## May a caption of `kind` show now (`last`: kind -> when one last showed; `shown`: how many show)?
static func may_show(kind: StringName, now: float, last: Dictionary, shown: int) -> bool:
	return KINDS.has(kind) and shown < MAX_SHOWN and now - float(last.get(kind, -INF)) >= REST


## The middle of a chip for a sound in direction `dir` from the screen's middle (screen axes: right +x, down +y).
static func place(screen: Vector2, dir: Vector2) -> Vector2:
	var radii := (screen * 0.5 - INSET).max(CHIP)
	var d := dir.normalized() if dir.length() > 0.001 else Vector2.UP
	var p := screen * 0.5 + d * radii
	var half := CHIP * 0.5 + Vector2(8, 8)
	return p.clamp(half, screen - half)
