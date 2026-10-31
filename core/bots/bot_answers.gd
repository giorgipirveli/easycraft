class_name BotAnswers
extends RefCounted
## What bot friends answer when the child talks to them (owner feedback #38, spec §12.14a): fixed, friendly
## lines in English (owner #52: English only), some filled in from the game
## (directions from where the child looks, hearts, the day clock, what the bot does). Nothing is generated
## freely: every word a bot says is written here, and tests check them all (no guilt, no pressure, never
## asking for anything personal, plain short text). A bot's name stays as the chat shows it ("Pip").

const EN := &"en"

const NEAR := 3.0                 # closer than this (sideways) is "right here"
const HIGH := 6.0                 # this much higher / lower: "up high" / "down below"
const DEEP := 12.0                # deeper than this: "deep underground"

## Plain lines by key, per language (a pick varies them). "We" lines (several friends answer at once) in WE.
const LINES := {
	&"follow": {EN: ["OK! I'm right behind you!", "Coming!", "On my way!"]},
	&"wait": {EN: ["OK, I'll wait right here!", "I'll stay here!"]},
	&"home": {EN: ["OK! I'll wait for you at home!"]},
	&"no_home": {EN: ["You don't have a home yet. Sleep in a bed to make one!"]},
	&"space": {EN: ["OK! I'll give you some space."]},
	&"build_house": {EN: ["A house? Coming right up!"]},
	&"build_tower": {EN: ["A tower? Coming right up!"]},
	&"build_wall": {EN: ["A wall? Coming right up!"]},
	&"build_thing": {EN: ["Let's build! Coming right up!"]},
	&"built_house": {EN: ["Ta-da! A little house for you!"]},
	&"built_tower": {EN: ["Ta-da! A tall tower for you!"]},
	&"built_wall": {EN: ["Ta-da! A strong wall for you!"]},
	&"built_thing": {EN: ["Ta-da! Do you like it?"]},
	&"no_room": {EN: ["I can't find a flat spot here. Let's try somewhere else!"]},
	&"leaves_only": {EN: ["In Survivor I build with leaves, so your blocks stay yours!"]},
	&"guard": {EN: ["I'll keep you safe!", "I'm on guard!"]},
	&"fight": {EN: ["I see it! Stay behind me!"]},
	&"run": {EN: ["Run! This way!"]},
	&"hide": {EN: ["OK, I'm hiding! Shh!"]},
	&"dance": {EN: ["Watch my moves!", "Dance time!"]},
	&"trick": {EN: ["Watch this trick!"]},
	&"race_ready": {EN: ["Ready! Step on START and let's race!"]},
	&"race_none": {EN: ["Let's race! Finish a course first, then I'll race your best run!"]},
	&"help": {EN: ["I'm coming! Stay close!"]},
	&"hello": {EN: ["Hi! I'm happy to play with you!", "Hello, friend!"]},
	&"thanks": {EN: ["You're welcome!", "Anytime, friend!"]},
	&"praise": {EN: ["Thanks! You're great too!", "Yay! We make a great team!"]},
	&"bye": {EN: ["Bye! See you soon!"]},
	&"look": {EN: ["Ooh! What is it?", "Wow, let me see!"]},
	&"feel": {EN: ["I'm great! Playing with you is the best!"]},
	&"what_can_i_say": {EN: ["You can say: follow me, wait, build a house, find treasure, guard me, dance!"]},
	&"hint": {EN: ["Hmm? You can say: follow me, build a house, find treasure..."]},
	&"found_it": {EN: ["Here it is!", "Look, right here!"]},
	&"this_way": {EN: ["This way!"]},
	&"stuck": {EN: ["Hmm, I can't get through here. It's that way!"]},
	&"coming": {EN: ["I'm coming!"]},
	&"at_home": {EN: ["I'm at your home! Say come here and I'll come."]},
}
const WE := {
	&"follow": {EN: "OK! We're right behind you!"},
	&"wait": {EN: "OK, we'll wait right here!"},
	&"home": {EN: "OK! We'll wait for you at home!"},
	&"space": {EN: "OK! We'll give you some space."},
	&"guard": {EN: "We'll keep you safe!"},
	&"hide": {EN: "OK, we're hiding! Shh!"},
	&"dance": {EN: "Dance party!"},
	&"help": {EN: "We're coming! Stay close!"},
	&"run": {EN: "Run! This way, everyone!"},
}
## What it says it is doing, by behaviour (BotRules) or order.
const DOING := {
	&"idle": {EN: "I'm hanging out with you!"},
	&"follow": {EN: "I'm walking with you!"},
	&"wander": {EN: "I'm looking around near you!"},
	&"fight": {EN: "I'm chasing a monster away!"},
	&"build": {EN: "I'm building something for you!"},
	&"point": {EN: "I'm showing you something!"},
	&"stay": {EN: "I'm waiting here, like you asked!"},
	&"home": {EN: "I'm waiting at your home!"},
	&"guide": {EN: "I'm showing you the way! Follow me!"},
	&"hide": {EN: "I'm hiding! Shh!"},
	&"run": {EN: "I'm running from the monsters!"},
	&"dance": {EN: "I'm dancing!"},
	&"race": {EN: "I'm racing!"},
	&"guard": {EN: "I'm guarding you!"},
}
const KINDS := {
	&"treasure": {EN: "buried treasure"},
	&"room": {EN: "a hidden room"},
	&"temple": {EN: "a puzzle temple"},
	&"island": {EN: "a sky island"},
	&"geode": {EN: "a crystal geode"},
	&"star": {EN: "a fallen star"},
	&"secret": {EN: "a secret"},
	&"quest": {EN: "the place of your quest"},   # owner #45a
}
const PERSONALITY := {&"builder": {EN: "builder"}, &"explorer": {EN: "explorer"},
	&"fighter": {EN: "fighter"}}
## Sides, clockwise from straight ahead (45° each).
const SIDES := {
	EN: ["straight ahead", "ahead, to the right", "to your right", "behind you, to the right", "behind you",
		"behind you, to the left", "to your left", "ahead, to the left"],
}
const TEMPLATES := {
	&"blocks": {EN: "%d blocks %s"},
	&"here": {EN: "right here"},
	&"up": {EN: ", up high"},
	&"down": {EN: ", down below"},
	&"deep": {EN: ", deep underground"},
	&"tilly": {EN: "Tilly's shop is %s!"},
	&"no_tilly": {EN: "There's no shop in this world. Tilly's stall is in Survivor worlds!"},
	&"follow_me": {EN: " Follow me!"},
	&"treasure": {EN: "I know! There's %s %s."},
	&"no_treasure": {EN: "I don't know any secrets near here yet. Let's look around!"},
	&"knocked_out": {EN: "You're knocked out, but you'll be back in a moment!"},
	&"safe": {EN: "You have all %d hearts. Nothing can hurt you here!"},
	&"full": {EN: "You have all %d hearts!"},
	&"hearts": {EN: "You have %s out of %d!"},
	&"careful": {EN: " Let's be careful!"},
	&"day": {EN: "It's day. Night comes in about %s."},
	&"setting": {EN: "The sun is setting! Night starts in less than a minute."},
	&"night": {EN: "It's night now! The sun comes up in about %s."},
	&"name": {EN: "I'm %s, your %s bot!"},
	&"next_to_you": {EN: "I'm right here, next to you!"},
	&"over_here": {EN: "Over here! I'm %s."},
}
const LOW_HEARTS := 6             # hit points at or under this: "Let's be careful!"


## A plain line of `key` in `lang` (pick varies it); `we`: several friends answer together.
static func line(key: StringName, lang: StringName, pick: int = 0, we: bool = false) -> String:
	var l := _lang(lang)
	if we and WE.has(key):
		return str(WE[key][l])
	if not LINES.has(key):
		return ""
	var list: Array = LINES[key][l]
	return str(list[posmod(pick, list.size())])


## Where `to` is from a child at `from` looking along `facing`: "40 blocks to your left, up high".
static func direction(from: Vector3, facing: Vector3, to: Vector3, lang: StringName) -> String:
	var l := _lang(lang)
	var flat := Vector2(to.x - from.x, to.z - from.z)
	var dy := to.y - from.y
	var height := ""
	if dy > HIGH:
		height = TEMPLATES[&"up"][l]
	elif dy < -DEEP:
		height = TEMPLATES[&"deep"][l]
	elif dy < -HIGH:
		height = TEMPLATES[&"down"][l]
	if flat.length() < NEAR:
		return str(TEMPLATES[&"here"][l]) + height
	var look := Vector2(facing.x, facing.z)
	if look.length() < 0.01:
		look = Vector2(0, -1)
	# Angle from the look direction, clockwise seen from above (x to the right of -z is +x).
	var angle := fposmod(atan2(look.x * flat.y - look.y * flat.x, look.dot(flat)), TAU)
	var side := posmod(roundi(angle / (TAU / 8.0)), 8)
	return str(TEMPLATES[&"blocks"][l]) % [roundi(flat.length()), SIDES[l][side]] + height


## Where Tilly's stall is (INF: none in this world); `lead`: the bot shows the way.
static func tilly(from: Vector3, facing: Vector3, stall: Vector3, lang: StringName, lead: bool) -> String:
	var l := _lang(lang)
	if not stall.is_finite():
		return str(TEMPLATES[&"no_tilly"][l])
	var words := str(TEMPLATES[&"tilly"][l]) % direction(from, facing, stall, l)
	return words + (str(TEMPLATES[&"follow_me"][l]) if lead else "")


## Where the nearest secret nobody found is ({pos, kind}; {} for none); `lead`: the bot shows the way.
static func treasure(from: Vector3, facing: Vector3, secret: Dictionary, lang: StringName, lead: bool) -> String:
	var l := _lang(lang)
	if secret.is_empty() or not (secret.get("pos", Vector3.INF) as Vector3).is_finite():
		return str(TEMPLATES[&"no_treasure"][l])
	var kind: Dictionary = KINDS.get(StringName(str(secret.get("kind", ""))), KINDS[&"secret"])
	var words := str(TEMPLATES[&"treasure"][l]) % [kind[l], direction(from, facing, secret.pos, l)]
	return words + (str(TEMPLATES[&"follow_me"][l]) if lead else "")


## The child's hearts (hit points `hp` of `max_hp`; `can_hurt`: this world can hurt players).
static func hearts(hp: int, max_hp: int, can_hurt: bool, lang: StringName) -> String:
	var l := _lang(lang)
	var most := maxi(max_hp / 2, 1)
	if not can_hurt:
		return str(TEMPLATES[&"safe"][l]) % most
	if hp <= 0:
		return str(TEMPLATES[&"knocked_out"][l])
	if hp >= max_hp:
		return str(TEMPLATES[&"full"][l]) % most
	var whole := hp / 2
	var half := hp % 2 == 1
	var count := ""
	if half:
		count = "%d and a half hearts" % whole if whole > 0 else "a half heart"
	else:
		count = "1 heart" if whole == 1 else "%d hearts" % whole
	var words := str(TEMPLATES[&"hearts"][l]) % [count, most]
	return words + (str(TEMPLATES[&"careful"][l]) if hp <= LOW_HEARTS else "")


## Is it night soon? From the day clock (DayCycle: 0..1, a day of 20 minutes).
static func night(time_of_day: float, lang: StringName) -> String:
	var l := _lang(lang)
	var t := fposmod(time_of_day, 1.0)
	if DayCycle.is_night(t):
		var until_sunrise := fposmod(DayCycle.SUNRISE - t, 1.0) * DayCycle.LENGTH
		return str(TEMPLATES[&"night"][l]) % _minutes(until_sunrise, l)
	var until_sunset := (DayCycle.SUNSET - t) * DayCycle.LENGTH
	if until_sunset < 60.0:
		return str(TEMPLATES[&"setting"][l])
	return str(TEMPLATES[&"day"][l]) % _minutes(until_sunset, l)


## What it is doing (a BotRules behaviour or an order); anything else: hanging out.
static func doing(what: StringName, lang: StringName) -> String:
	return str((DOING.get(what, DOING[&"idle"]) as Dictionary)[_lang(lang)])


## Its name, always as a bot: "I'm Mossy, your builder bot!".
static func name_line(bot_name: String, personality: StringName, lang: StringName) -> String:
	var l := _lang(lang)
	var kind: Dictionary = PERSONALITY.get(personality, PERSONALITY[&"explorer"])
	return str(TEMPLATES[&"name"][l]) % [bot_name, kind[l]]


## Where the bot is, from the child's view.
static func where_me(child: Vector3, facing: Vector3, bot: Vector3, lang: StringName) -> String:
	var l := _lang(lang)
	if Vector2(bot.x - child.x, bot.z - child.z).length() < NEAR:
		return str(TEMPLATES[&"next_to_you"][l])
	return str(TEMPLATES[&"over_here"][l]) % direction(child, facing, bot, l)


static func _minutes(seconds: float, l: StringName) -> String:
	var m := maxi(roundi(seconds / 60.0), 1)
	return "1 minute" if m == 1 else "%d minutes" % m


## Every answer is English (owner #52); `lang` stays in the calls for the chat's older callers.
static func _lang(_lang_asked: StringName) -> StringName:
	return EN
