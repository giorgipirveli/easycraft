class_name ChatCommands
extends RefCounted
## Chat commands as pure rules (spec §3b): parsing "/name args" (case-insensitive names, extra
## spaces and "quoted words" allowed, "~" meaning "here" in coordinates), the registry with usage
## text, friendly errors, suggestions for what has been typed so far (the tappable buttons), and
## where each command runs. ChatCommandRunner runs them.
##
## Where commands run: &"local" ones act on this device's own player, hotbar and settings (each
## player simulates their own body, so /tp, /fly or /size need nobody's permission); &"host" ones
## change the world for everyone, so the host re-parses the text (host_check) and runs them.
##
## Owner feedback #40 (spec §3b "More commands"): /weather /heal /peace /freeze /kit /speed /gravity
## /universe /build /dance /emote /pet /bot /boss /xp /level /music /photo /save /clearbag /find, counts
## for /give. /help and the "/" buttons show what this child may use in this mode (a context from `context`).
## (Its Georgian command names were removed by owner #52: English only.)

## Times of day for /time: 0..1 with 0 = midnight. The contract with the day/night cycle
## (sandbox.set_time_of_day(t)).
const TIME_MIDNIGHT := DayCycle.MIDNIGHT
const TIME_SUNRISE := DayCycle.SUNRISE
const TIME_DAY := DayCycle.START                       # a bright morning
const TIME_NOON := DayCycle.NOON
const TIME_SUNSET := DayCycle.SUNSET
const TIME_NIGHT := DayCycle.NIGHT_START + 0.03         # early night: the moon is up
const TIMES := {
	"day": TIME_DAY, "night": TIME_NIGHT, "noon": TIME_NOON, "midnight": TIME_MIDNIGHT,
	"sunrise": TIME_SUNRISE, "sunset": TIME_SUNSET,
}
const SIZES := {"giant": SizeMagic.Mode.GIANT, "tiny": SizeMagic.Mode.TINY, "normal": SizeMagic.Mode.NORMAL}
const JUMPS: Array[String] = ["2", "3"]
const ANIMALS: Array[String] = ["dog", "cat", "pig", "cow", "sheep", "chicken", "rabbit", "fish",
	"fox", "parrot", "pip",   # M3 Task 11: /summon pip brings Pip the robot to you (Sandbox)
	"horse", "donkey", "goat", "deer", "duck", "frog", "turtle", "squirrel", "owl", "hedgehog", "camel", "lizard",
	"fennec", "penguin", "polar_bear", "arctic_fox", "seal", "gummy_bunny", "candy_bird",   # owner #41
	"moon_bunny"]   # owner #55
## /summon slime 3 (M2 Task 4): monsters take a level, 1 when none is given.
const MONSTERS: Array[String] = ["slime", "goblin", "mummy", "scorpion", "yeti", "bat", "gummy", "sneaker", "archer",
	"shadowbat", "wisp", "puff", "crawler"]   # M3 Tasks 2-4: the desert's, Frostpeak's and the Candy Kingdom's too; 14b: goblin archers; owner #39: the Dragon Realm's; universe 6: the Glow Caves'
## The word a child types for a monster whose kind is spelled differently (owner #39: /summon shadowbat).
const MONSTER_WORDS := {"shadowbat": "shadow_bat", "puff": "spore_puff"}
## /summon golem (M2 Task 10): the Stone Golem, in Sandbox (Survivor's comes from the Totem); /summon serpent
## (M3 Task 2): the Sand Serpent.
const BOSSES: Array[String] = ["golem", "serpent", "giant", "cake", "skydragon", "sporemother"]   # universe 6: /summon sporemother   # M3 Task 3: /summon giant, the Frost Giant; M3 Task 4: /summon cake, the Cake Monster; owner 39: /summon skydragon
## A /summon word whose boss kind is spelled otherwise (owner 39: the Sky Dragon's kind is sky_dragon).
const BOSS_KINDS := {"skydragon": &"sky_dragon", "sporemother": &"spore_mother"}
## /tp stays inside these bounds (far-out coordinates lose float precision).
const TP_LIMIT := 30000.0
const TP_MIN_Y := -63.0
const TP_MAX_Y := 256.0
const OFF_MESSAGE := "Commands are off in this game. /help still works."
const SANDBOX_ONLY_MESSAGE := "That works in Sandbox only."
## Commands that would make Survivor too easy (M2 §12.1): off there, on in Sandbox.
const CHEATS: Array[StringName] = [&"tp", &"spawn", &"home", &"give", &"fly", &"ghost", &"time", &"summon", &"size",
	&"secret",
	# Owner feedback #40
	&"weather", &"heal", &"peace", &"freeze", &"kit", &"speed", &"gravity", &"build", &"boss",
	&"fill", &"copy"]   # M3 Task 8: the Sandbox power tools
## /secret's kinds (M2 Task 16: the secrets the terrain hides; owner 42: the treasure pack's, and a rainbow).
const SECRET_KINDS: Array[String] = ["treasure", "room", "temple", "island", "geode", "shipwreck", "sunken",
	"mineshaft", "vault", "waterfall", "hollowtree", "well", "cove", "ruins", "haunted", "camp", "rainbow",
	"mice"]   # M3 Task 21c: the Tiny world's mouse villages

## Every command, in /help order: usage, what it does and where it runs.
const COMMANDS := {
	&"help": {"usage": "/help  or  /help tp", "about": "Show the commands.", "runs": &"local"},
	&"tp": {"usage": "/tp x y z  (~ means here)  or  /tp name", "about": "Jump to a place or to a friend.",
		"runs": &"local"},
	&"spawn": {"usage": "/spawn", "about": "Go back to where the world started.", "runs": &"local"},
	&"home": {"usage": "/home", "about": "Go to your bed.", "runs": &"host"},
	&"time": {"usage": "/time day|night|noon|midnight", "about": "Change the time of day for everyone.",
		"runs": &"host"},
	&"give": {"usage": "/give block-or-item  (like /give planks 64)", "about": "Put it in your hand.",
		"runs": &"local"},
	&"summon": {"usage": "/summon dog|cat|pig|cow|sheep|chicken|rabbit|fish|fox|parrot|pip|horse|donkey|goat|deer|duck|frog|turtle|squirrel|owl|hedgehog|camel|lizard|fennec|penguin|polar_bear|arctic_fox|seal|gummy_bunny|candy_bird|moon_bunny  or  /summon slime|goblin|mummy|scorpion|yeti|bat|gummy|sneaker|archer|shadowbat|wisp|puff|crawler 1-5  or  /summon golem|serpent|giant|cake|skydragon|sporemother",
		"about": "Call an animal, or a monster of that level, to you.", "runs": &"host"},
	&"secret": {"usage": "/secret  or  /secret treasure|room|temple|island|geode|shipwreck|sunken|mineshaft|vault|waterfall|hollowtree|well|cove|ruins|haunted|camp|rainbow|mice",
		"about": "Where is the nearest secret nobody found yet?", "runs": &"host"},
	&"fly": {"usage": "/fly", "about": "Fly around.", "runs": &"local"},
	&"ghost": {"usage": "/ghost", "about": "Fly through blocks.", "runs": &"local"},
	&"walk": {"usage": "/walk", "about": "Walk again.", "runs": &"local"},
	&"size": {"usage": "/size giant|tiny|normal", "about": "Size Magic.", "runs": &"local"},
	&"jumps": {"usage": "/jumps 2|3", "about": "Double or triple jump.", "runs": &"local"},
	&"style": {"usage": "/style blocky|realistic", "about": "Change how the world looks.", "runs": &"local"},
	&"seed": {"usage": "/seed", "about": "Show the world's seed.", "runs": &"local"},
	&"clear": {"usage": "/clear", "about": "Clear the chat.", "runs": &"local"},
	# Owner feedback #40
	&"weather": {"usage": "/weather clear|rain|snow|sandstorm", "about": "Change the weather (what this universe has).",
		"runs": &"host"},
	&"heal": {"usage": "/heal", "about": "Fill your hearts.", "runs": &"host"},
	&"peace": {"usage": "/peace on|off", "about": "Monsters go home and stay away.", "runs": &"host"},
	&"freeze": {"usage": "/freeze on|off", "about": "Stop the day clock for everyone.", "runs": &"host"},
	&"kit": {"usage": "/kit", "about": "A builder's hotbar.", "runs": &"local"},
	&"speed": {"usage": "/speed 1|2|3  (slow, normal, fast)", "about": "How fast you move.", "runs": &"local"},
	&"gravity": {"usage": "/gravity moon|normal|zero", "about": "Floaty moon jumps, or no gravity at all.",
		"runs": &"local"},
	&"universe": {"usage": "/universe 1-5  or  /universe desert", "about": "Travel to a universe you opened.",
		"runs": &"local"},
	&"build": {"usage": "/build house|tower|bridge|tree|rainbow", "about": "Build it in front of you.",
		"runs": &"local"},
	&"dance": {"usage": "/dance  or  /dance hop|robot|star|victory", "about": "Dance!", "runs": &"local"},
	&"emote": {"usage": "/emote wave|cheer|laugh|clap|sit|bow", "about": "Wave, cheer, clap and more.",
		"runs": &"local"},
	&"pet": {"usage": "/pet", "about": "Call your pets to you.", "runs": &"host"},
	&"bot": {"usage": "/bot add builder|explorer|fighter  or  /bot remove name", "about": "Bring a bot friend, or send one home.",
		"runs": &"local"},
	&"boss": {"usage": "/boss", "about": "Call this universe's boss!", "runs": &"host"},
	&"xp": {"usage": "/xp", "about": "How much XP you have.", "runs": &"local"},
	&"level": {"usage": "/level", "about": "Your level and the next one.", "runs": &"local"},
	&"music": {"usage": "/music next|classical|game|on|off", "about": "Change the music.", "runs": &"local"},
	&"photo": {"usage": "/photo", "about": "Take a photo.", "runs": &"local"},
	&"save": {"usage": "/save", "about": "Save the world now.", "runs": &"local"},
	&"clearbag": {"usage": "/clearbag", "about": "Empty your bag (it asks first).", "runs": &"host"},
	&"find": {"usage": "/find tilly|home|portal|treasure|launch", "about": "An arrow shows the way.", "runs": &"local"},
	# M3 Task 8: the building tools
	&"fill": {"usage": "/fill block  or  /fill block 5  or  /fill block 5 3 5",
		"about": "Fill a box in front of you (up to 16 a side).", "runs": &"local"},
	&"copy": {"usage": "/copy", "about": "Copy the build you look at, then tap to paste it.", "runs": &"local"},
}
const _ALIASES := {"log": BlockIds.LOG, "wand": ItemIds.WAND}
## Treasure is found by playing, never given (M2 Task 16, spec §12.16); the secrets' own blocks are not
## given either (a fake wall is just stone to /give).
const TREASURE_ONLY: Array[int] = [BlockIds.TROPHY, BlockIds.GOLD_LAMP, ItemIds.TREASURE_MAP, BlockIds.CHEESE]
const NEVER_GIVEN: Array[int] = [BlockIds.TROPHY, BlockIds.GOLD_LAMP, ItemIds.TREASURE_MAP, BlockIds.FAKE_WALL,
	BlockIds.PRESSURE_PLATE,
	BlockIds.PYRAMID_GOLD, BlockIds.ARROW_SLIT, BlockIds.TRAP_SAND, BlockIds.FAKE_SANDSTONE,   # M3 Task 2: the desert's secrets
	BlockIds.FAKE_SNOW,   # M3 Task 3: Frostpeak's secret floor
	BlockIds.GOLDEN_CANDY, BlockIds.FAKE_CHOCOLATE,   # M3 Task 4: the Candy Kingdom's
	BlockIds.DRAGON_GOLD, BlockIds.FAKE_FLOATSTONE,   # owner 39: the Dragon Realm's
	BlockIds.CHEESE,   # M3 Task 21c: the mice's present
	BlockIds.STAR_GOLD, BlockIds.FAKE_MOON_ROCK, BlockIds.FAKE_BOING_ROCK, BlockIds.FAKE_RAINBOW,   # owner #55: space's secrets
	BlockIds.FAKE_BASALT,   # cosmos: Mars's hidden door
	BlockIds.FAKE_DEEP_ICE,   # cosmos: Europa's hidden door
	BlockIds.FAKE_IO_ROCK,   # cosmos: Io's hidden door
	BlockIds.FAKE_ICY_ROCK,   # cosmos: Titan's hidden door
	BlockIds.FAKE_MERCURY_ROCK,   # cosmos: Mercury's hidden door
	BlockIds.FAKE_LIMESTONE, BlockIds.FAKE_MARBLE, BlockIds.FAKE_BABYLON_BRICK,   # owner #78: the wonders' hidden doors
	BlockIds.FAKE_WALL_BRICK, BlockIds.FAKE_TRAVERTINE, BlockIds.FAKE_MAYA_STONE, BlockIds.FAKE_INCA_STONE,   # the New Seven's
	BlockIds.FAKE_WHITE_BRICK,
	BlockIds.FAKE_FLOAT_HULL,   # cosmos: Venus's hidden door
	BlockIds.FAKE_RING_ICE,   # cosmos: Saturn's rings' hidden door
	BlockIds.FAKE_WATER_ICE,   # cosmos: Pluto's hidden door
	BlockIds.FAKE_PINK_ICE,   # cosmos: Triton's hidden door
	BlockIds.FAKE_GROOVED_ICE,   # cosmos: Ganymede's hidden door
	BlockIds.CAVE_GOLD, BlockIds.FAKE_CAVE_STONE]   # universe 6: the Glow Caves' treasure and hidden door
const TREASURE_ONLY_MESSAGE := "That is only found in treasure. Go exploring!"
const _FIRST_ITEM_ID := 100
const _LAST_ITEM_ID := 450   # M3: gadgets and blasters 400-429 (Task 14), paint 435-450 (Task 8); pet treats 430-434 (Task 11)

# --- Owner feedback #40: the new commands' words -----------------------------------------------

const WEATHERS: Array[String] = ["clear", "rain", "snow", "sandstorm"]
## A universe's weather (its descriptor's `weather`) -> the /weather word that brings it.
const WEATHER_OF := {&"sandstorm": "sandstorm", &"snowstorm": "snow"}
const SWITCHES: Array[String] = ["on", "off"]
const SPEEDS := {"1": 1, "2": 2, "3": 3, "slow": 1, "normal": 2, "fast": 3}
const SPEED_CHOICES: Array[String] = ["1", "2", "3"]
const GRAVITIES := {"moon": LabRules.Mode.MOON, "normal": LabRules.Mode.NORMAL, "zero": LabRules.Mode.ZERO_G}
const STAMPS := {"house": ItemIds.STAMP_HOUSE, "tower": ItemIds.STAMP_TOWER, "bridge": ItemIds.STAMP_BRIDGE,
	"tree": ItemIds.STAMP_TREE, "rainbow": ItemIds.STAMP_RAINBOW}
const DANCES := {"hop": &"dance_hop", "robot": &"dance_robot", "star": &"dance_star", "victory": &"victory"}
const MUSIC_CHOICES: Array[String] = ["next", "classical", "game", "on", "off"]
const FIND_TARGETS: Array[String] = ["tilly", "home", "portal", "treasure", "launch"]   # owner #98: the Launch Site
## /kit (Sandbox): a builder's hotbar.
const KIT: Array[int] = [BlockIds.PLANKS, BlockIds.BRICK, BlockIds.GLASS, BlockIds.STONE, BlockIds.LOG,
	BlockIds.DOOR, BlockIds.LANTERN, BlockIds.BED, ItemIds.WAND]
## /give planks 64: 1 to this many (a bag's cap).
const MAX_GIVE := Inventory.MAX_COUNT
## /build puts the stamp this many blocks ahead of the feet.
const BUILD_AHEAD := 2
## /find: this close counts as there.
const FIND_HERE := 3
const FIND_HIGH := 8.0
## /clearbag asks first; a second /clearbag within this many seconds empties the bag.
const CLEARBAG_SECONDS := 15.0
## Local commands that send work to the host or the disk: this device limits them (ChatRules' rate).
const LIMITED: Array[StringName] = [&"build", &"save", &"bot", &"fill", &"copy"]   # M3 Task 8: /fill, /copy
const ENDLESS_BAG_MESSAGE := "Your Sandbox bag never runs out: nothing to clear!"
const ONE_WORLD_MESSAGE := "In Sandbox, build a portal and put a crystal in it to visit another universe!"   # owner #39
const NO_MAP_MESSAGE := "Find a Treasure Map first! Chests and the Wanderer have them."

const _WEATHER_WORDS := {"clear": "%s cleared the sky.", "sandstorm": "%s called a sandstorm!",
	"snow": "%s called a snowstorm!"}

static func is_command(text: String) -> bool:
	return text.strip_edges().begins_with("/")


static func usage(name: StringName) -> String:
	return str(COMMANDS.get(name, {}).get("usage", ""))


static func about(name: StringName) -> String:
	return str(COMMANDS.get(name, {}).get("about", ""))


## The command a typed name means (any case), or &"" for none.
static func command_name(word: String) -> StringName:
	var w := word.strip_edges().trim_prefix("/").to_lower()
	return StringName(w) if COMMANDS.has(StringName(w)) else &""


static func runs_on_host(name: StringName) -> bool:
	return COMMANDS.get(name, {}).get("runs", &"") == &"host"


## Why `name` may not run here ("" = it may): commands can be switched off (only /help works then),
## cheats work in Sandbox only (M2 §12.1), /clearbag only where blocks are counted and /universe only
## where universes are worlds of their own (Survivor; owner feedback #40).
static func refusal(name: StringName, commands_enabled: bool, mode: StringName) -> String:
	if name == &"help":
		return ""
	if not commands_enabled:
		return OFF_MESSAGE
	if CHEATS.has(name) and not ModeRules.allows(mode, ModeRules.CHEATS):
		return SANDBOX_ONLY_MESSAGE
	if name == &"clearbag" and ModeRules.allows(mode, ModeRules.UNLIMITED_BLOCKS):
		return ENDLESS_BAG_MESSAGE
	if name == &"universe" and not UniverseRules.wants_hub(mode):
		return ONE_WORLD_MESSAGE
	return ""


## Whether a child may use `name` in `ctx` ({"mode", "enabled"}; without a mode: everything, for tools).
static func usable(name: StringName, ctx: Dictionary) -> bool:
	if not ctx.has("mode"):
		return true
	return refusal(name, bool(ctx.get("enabled", true)), StringName(ctx.mode)) == ""


## What the buttons and /help need to know about this game: its mode and command switch, the universe's
## weather, the universes open for travel, and the bot friends' names.
static func context(mode: StringName, enabled: bool, universe: int, unlocked: int, bots: Array = []) -> Dictionary:
	var own: Object = UniverseRegistry.descriptor(universe)
	var weather: Variant = own.get("weather") if own else null
	var open: Array[int] = []
	for e: Dictionary in UniverseRegistry.hub_entries(unlocked):
		if e.open:
			open.append(int(e.universe))
	return {"mode": mode, "enabled": enabled, "universes": open, "bots": bots,
		"weather": StringName(weather) if weather is StringName or weather is String else &""}


## The host's check of a command text a player sent over the network. It parses the text itself
## (never trusting a client's parse) and accepts only world-changing commands (a raw request for a
## local one is refused), and only while commands are on.
static func host_check(text: String, commands_enabled: bool, mode: StringName) -> Dictionary:
	if not is_command(text):
		return {"error": "That isn't a command. Try /help"}
	var cmd := parse(text)
	if cmd.has("error"):
		return cmd
	var refused := refusal(cmd.name, commands_enabled, mode)
	if refused != "":
		return {"error": refused}
	if not runs_on_host(cmd.name):
		return {"error": "/%s works on your own device, not on the host." % cmd.name}
	return cmd


## Splits on spaces; "double quotes" keep words together.
static func tokenize(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var word := ""
	var started := false
	var quoted := false
	for ch in text:
		if ch == "\"":
			quoted = not quoted
			started = true
		elif (ch == " " or ch == "\t") and not quoted:
			if started:
				out.append(word)
			word = ""
			started = false
		else:
			word += ch
			started = true
	if started:
		out.append(word)
	return out


## Parses "/name args". Returns {"name": StringName, ...} with the command's typed arguments, or
## {"error": a friendly message}. `here` is the player's position, for "~" in /tp.
##   tp -> "pos": Vector3 or "player": String; time -> "time": float, "choice"; give -> "id": int, "count";
##   summon -> "species": StringName, or "monster": StringName and "level": int; size -> "mode"; jumps -> "count"; style -> "style";
##   help -> "topic": StringName (&"" for all).
## Owner feedback #40: weather -> "weather"; peace, freeze -> "switch" (&"toggle", &"on", &"off"); speed -> "speed"
##   1..3; gravity -> "gravity" (LabRules.Mode); universe -> "universe"; build -> "stamp" (ItemIds); dance, emote ->
##   "emote" (&"" = any dance); bot -> "action" and "personality" or "bot"; music -> "music"; find -> "target".
static func parse(text: String, here: Vector3 = Vector3.ZERO) -> Dictionary:
	var words := tokenize(text.strip_edges().trim_prefix("/"))
	if words.is_empty() or words[0] == "":
		return {"error": "Type a command after the /. Try /help"}
	var name := command_name(words[0])
	if name == &"":
		return {"error": Lang.t("I don't know /%s. Try /help") % words[0]}
	var args := words.slice(1)
	match name:
		&"tp":
			return _parse_tp(args, here)
		&"time":
			return _parse_choice(name, args, TIMES.keys(), func(c: String) -> Dictionary: return {"time": TIMES[c], "choice": c})
		&"size":
			return _parse_choice(name, args, SIZES.keys(), func(c: String) -> Dictionary: return {"mode": SIZES[c]})
		&"jumps":
			return _parse_choice(name, args, JUMPS, func(c: String) -> Dictionary: return {"count": c.to_int()})
		&"style":
			return _parse_choice(name, args, GraphicsPreset.STYLES, func(c: String) -> Dictionary: return {"style": c})
		&"summon":
			return _parse_summon(args)
		&"secret":
			if args.is_empty():
				return {"name": name, "kind": &""}
			return _parse_choice(name, args, SECRET_KINDS, func(c: String) -> Dictionary: return {"kind": StringName(c)})
		&"give":
			return _parse_give(args)
		&"help":
			var topic := command_name(args[0]) if not args.is_empty() else &""
			if not args.is_empty() and topic == &"":
				return {"error": Lang.t("I don't know /%s. Try /help") % args[0].trim_prefix("/")}
			return {"name": name, "topic": topic}
		&"weather":
			return _parse_choice(name, args, WEATHERS, func(c: String) -> Dictionary: return {"weather": StringName(c)})
		&"peace", &"freeze":
			if args.is_empty():
				return {"name": name, "switch": &"toggle"}
			return _parse_choice(name, args, SWITCHES, func(c: String) -> Dictionary: return {"switch": StringName(c)})
		&"speed":
			return _parse_choice(name, args, SPEEDS.keys(), func(c: String) -> Dictionary: return {"speed": SPEEDS[c]})
		&"gravity":
			return _parse_choice(name, args, GRAVITIES.keys(), func(c: String) -> Dictionary:
				return {"gravity": GRAVITIES[c], "choice": c})
		&"universe":
			return _parse_universe(args)
		&"build":
			return _parse_choice(name, args, STAMPS.keys(), func(c: String) -> Dictionary: return {"stamp": STAMPS[c], "choice": c})
		&"dance":
			if args.is_empty():
				return {"name": name, "emote": &""}
			return _parse_choice(name, args, DANCES.keys(), func(c: String) -> Dictionary: return {"emote": DANCES[c]})
		&"emote":
			return _parse_emote(args)
		&"bot":
			return _parse_bot(args)
		&"music":
			return _parse_choice(name, args, MUSIC_CHOICES, func(c: String) -> Dictionary: return {"music": StringName(c)})
		&"find":
			return _parse_choice(name, args, FIND_TARGETS, func(c: String) -> Dictionary: return {"target": StringName(c)})
		&"fill":
			return _parse_fill(args)
	return {"name": name}   # no arguments; extra words are ignored


static func _parse_choice(name: StringName, args: PackedStringArray, choices: Array, make: Callable) -> Dictionary:
	if args.is_empty():
		return {"error": Lang.t("Use it like this: %s") % usage(name)}
	var pick := args[0].to_lower()
	if not choices.has(pick):
		return {"error": Lang.t("Try %s") % usage(name)}
	var result: Dictionary = make.call(pick)
	result["name"] = name
	return result


static func _parse_summon(args: PackedStringArray) -> Dictionary:
	if not args.is_empty() and BOSSES.has(args[0].to_lower()):
		var word := args[0].to_lower()
		return {"name": &"summon", "boss": StringName(BOSS_KINDS.get(word, word))}   # M2 Task 10
	if not args.is_empty() and MONSTERS.has(args[0].to_lower()):
		var level := 1
		if args.size() > 1:
			level = args[1].to_int() if args[1].is_valid_int() else 0
			if level < 1 or level > MonsterRules.MAX_LEVEL:
				return {"error": Lang.t("Monster levels go from 1 to %d. Try /summon goblin 3") % MonsterRules.MAX_LEVEL}
		return {"name": &"summon", "monster": monster_kind(args[0].to_lower()), "level": level}
	return _parse_choice(&"summon", args, ANIMALS, func(c: String) -> Dictionary: return {"species": StringName(c)})


## The monster kind (MonsterRules.KINDS) of a /summon word: "shadowbat" -> &"shadow_bat" (owner #39).
static func monster_kind(word: String) -> StringName:
	return StringName(MONSTER_WORDS.get(word, word))


static func _parse_tp(args: PackedStringArray, here: Vector3) -> Dictionary:
	if args.size() == 1 and _starts_with_letter(args[0]):
		return {"name": &"tp", "player": args[0]}
	if args.size() != 3:
		return {"error": Lang.t("Use it like this: %s") % usage(&"tp")}
	var pos := Vector3()
	for axis in 3:
		var v := coordinate(args[axis], here[axis], axis != 1)
		if is_nan(v):
			return {"error": Lang.t("\"%s\" isn't a number. Try /tp 0 80 0, or ~ for here.") % args[axis]}
		pos[axis] = v
	pos.x = clampf(pos.x, -TP_LIMIT, TP_LIMIT)
	pos.z = clampf(pos.z, -TP_LIMIT, TP_LIMIT)
	pos.y = clampf(pos.y, TP_MIN_Y, TP_MAX_Y)
	return {"name": &"tp", "pos": pos}


## One /tp coordinate: a number, "~" (here) or "~5" (here + 5). A whole number on x or z lands in
## the middle of that block. NAN when it is not a number.
static func coordinate(token: String, here: float, block_centre: bool) -> float:
	if token.begins_with("~"):
		var rest := token.substr(1)
		if rest == "":
			return here
		return here + rest.to_float() if _is_number(rest) else NAN
	if not _is_number(token):
		return NAN
	return token.to_float() + (0.5 if block_centre and token.is_valid_int() else 0.0)


static func _is_number(s: String) -> bool:
	# No exponents ("1e999"): nobody types them for a place, and huge ones overflow.
	return s.is_valid_float() and not s.to_lower().contains("e") and is_finite(s.to_float())


static func _starts_with_letter(s: String) -> bool:
	var c := s.to_lower().unicode_at(0) if s != "" else 0
	return c >= 97 and c <= 122


## /give name, /give name 64 or /give 64 name (owner feedback #40: a count, 1..MAX_GIVE).
static func _parse_give(args: PackedStringArray) -> Dictionary:
	var words := Array(args)
	var count := 1
	if words.size() > 1 and str(words.back()).is_valid_int():
		count = str(words.pop_back()).to_int()
	elif words.size() > 1 and str(words.front()).is_valid_int():
		count = str(words.pop_front()).to_int()
	if words.is_empty():
		return {"error": Lang.t("Use it like this: %s") % usage(&"give")}
	if count < 1 or count > MAX_GIVE:
		return {"error": Lang.t("You can get 1 to %d at a time. Try /give planks 64") % MAX_GIVE}
	var wanted := " ".join(PackedStringArray(words))
	var key := _key(wanted)
	if key == _key(BlockIds.display_name(BlockIds.BEDROCK)):
		return {"error": "Bedrock is the floor of the world. Nobody can have it!"}
	for treasure in TREASURE_ONLY:
		if key == _key(ItemIds.display_name(treasure)):
			return {"error": TREASURE_ONLY_MESSAGE}
	var id := item_for_name(wanted)
	if id < 0:
		return {"error": Lang.t("I don't know \"%s\". Try /give diamond") % wanted}
	return {"name": &"give", "id": id, "count": count}


## Block or item id for a name (case, spaces and underscores ignored), or -1.
static func item_for_name(item_name: String) -> int:
	var key := _key(item_name)
	if _ALIASES.has(key):
		return _ALIASES[key]
	for id in giveable_ids():
		if _key(ItemIds.display_name(id)) == key:
			return id
	return -1


## Everything a hotbar slot can hold and has a name: blocks first, then magic items.
static func giveable_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in range(1, BlockIds.COUNT):   # blocks only: item ids sit among the paged block ids (M3 Task 5)
		if BlockIds.is_valid(id) and ItemIds.display_name(id) != "" and not NEVER_GIVEN.has(id):
			ids.append(id)
	for id in range(_FIRST_ITEM_ID, _LAST_ITEM_ID + 1):
		if ItemIds.is_item(id) and ItemIds.display_name(id) != "" and not NEVER_GIVEN.has(id):
			ids.append(id)
	return ids


static func _key(s: String) -> String:
	return s.to_lower().replace(" ", "").replace("_", "").replace("-", "")


## The player whose name matches (case-insensitive; a unique start of a name also works), or -1.
## names: peer id -> name.
static func find_player(player_name: String, names: Dictionary) -> int:
	var wanted := player_name.to_lower()
	var starts: Array[int] = []
	for id: int in names:
		var n := str(names[id]).to_lower()
		if n == wanted:
			return id
		if n.begins_with(wanted):
			starts.append(id)
	return starts[0] if starts.size() == 1 else -1


## The first words of the argument a command takes, for suggestion buttons. `ctx` (see `context`) narrows
## /weather to what the universe has, /universe to the open ones and lists the bot friends for /bot.
static func choices(name: StringName, players: Array = [], ctx: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	match name:
		&"time":
			out.assign(TIMES.keys())
		&"size":
			out.assign(SIZES.keys())
		&"jumps":
			out.assign(JUMPS)
		&"style":
			out.assign(GraphicsPreset.STYLES)
		&"summon":
			out.assign(ANIMALS + MONSTERS + BOSSES)
		&"secret":
			out.assign(SECRET_KINDS)
		&"give":
			for id in giveable_ids():
				out.append(ItemIds.display_name(id).to_lower())
		&"tp":
			for p: Variant in players:
				out.append(str(p))
		&"help":
			for n: StringName in COMMANDS:
				out.append(String(n))
		&"weather":
			out.assign(weather_choices(StringName(ctx.weather)) if ctx.has("weather") else WEATHERS)
		&"peace", &"freeze":
			out.assign(SWITCHES)
		&"speed":
			out.assign(SPEED_CHOICES)
		&"gravity":
			out.assign(GRAVITIES.keys())
		&"universe":
			for u: int in ctx.get("universes", range(1, UniverseRegistry.size() + 1)):
				out.append(String(UniverseRegistry.ladder_name(u)))
		&"build":
			out.assign(STAMPS.keys())
		&"dance":
			out.assign(DANCES.keys())
		&"emote":
			for e: StringName in EmotePoses.DURATIONS:
				out.append(String(e))
		&"bot":
			for p: StringName in BotRules.PERSONALITIES:
				out.append("add " + String(p))
			for b: Variant in ctx.get("bots", []):
				out.append("remove " + str(b))
		&"music":
			out.assign(MUSIC_CHOICES)
		&"find":
			out.assign(FIND_TARGETS)
	return out


## Completions of what has been typed so far: command names while the name is being typed
## ("/ti" -> "/time"), then that command's choices ("/time n" -> "/time night", "/time noon"). `players` are the
## names for /tp;
## with a mode in `ctx`, only the commands this child may use.
static func suggestions(prefix: String, players: Array = [], ctx: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	var p := prefix.strip_edges(true, false)
	if not p.begins_with("/"):
		return out
	var body := p.substr(1)
	var space := body.find(" ")
	if space == -1:
		var start := body.to_lower()
		for n: StringName in COMMANDS:
			if String(n).begins_with(start) and usable(n, ctx):
				out.append("/" + String(n))
		return out
	var word := body.substr(0, space).to_lower()
	var name := command_name(word)
	if name == &"":
		return out
	var typed := _key(body.substr(space + 1))
	for c in choices(name, players, ctx):
		if _key(c).begins_with(typed):
			out.append("/%s %s" % [String(name), c])
	return out


## What /help shows: the command list (with a mode in `ctx`, only what this child may use), or one
## command's usage.
static func help_lines(topic: StringName, ctx: Dictionary = {}) -> Array[String]:
	if COMMANDS.has(topic):
		return ["%s: %s" % [usage(topic), about(topic)]]
	var names := PackedStringArray()
	for n: StringName in COMMANDS:
		if usable(n, ctx):
			names.append("/" + String(n))
	return ["Commands: " + " ".join(names), "Type / in the chat to tap them. /help tp explains one."]


# --- Owner feedback #40: rules the runner asks ------------------------------------------------------

## The /weather words a universe with weather `universe_weather` (its descriptor's) can take.
static func weather_choices(universe_weather: StringName) -> Array[String]:
	var out: Array[String] = ["clear"]
	if WEATHER_OF.has(universe_weather):
		out.append(WEATHER_OF[universe_weather])
	return out


## Why /weather `choice` can't happen in a universe with `universe_weather` ("" = it can).
static func weather_refusal(choice: StringName, universe_weather: StringName) -> String:
	if weather_choices(universe_weather).has(String(choice)):
		return ""
	match choice:
		&"sandstorm":
			return "No sandstorms here. They blow in the Sandstorm Desert!"
		&"snow":
			return "No snow here. It snows in Frostpeak!"
		&"rain":
			return "No rain here yet. It comes in a later update!"
	return Lang.t("Try %s") % usage(&"weather")


## "Bob called a sandstorm!"
static func weather_words(choice: StringName, who: String) -> String:
	return str(_WEATHER_WORDS.get(String(choice), "%s changed the weather.")) % who


## /peace and /freeze: on, off, or the other way round from `current`.
static func switch_value(switch: StringName, current: bool) -> bool:
	match switch:
		&"on":
			return true
		&"off":
			return false
	return not current


static func give_words(id: int, count: int) -> String:
	return Lang.t("You got %s!") % Lang.t(ItemIds.display_name(id)) if count <= 1 else Lang.t("You got %d %s!") % [count, Lang.t(ItemIds.display_name(id))]


## Where /build's stamp goes: BUILD_AHEAD blocks ahead of the feet, on their level (Blueprints: y = -1 is the
## ground under the stamp).
static func build_anchor(feet: Vector3, forward: Vector3i) -> Vector3i:
	return Vector3i(feet.floor()) + forward * BUILD_AHEAD


static func owns_emote(emote: StringName, owned: Array) -> bool:
	return AvatarUnlocks.is_owned(AvatarCatalog.item_id(AvatarCatalog.EMOTE, emote), owned)


## The dances a child owns (free ones, bought and earned ones), for /dance without a name.
static func owned_dances(owned: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for d: StringName in DANCES.values():
		if owns_emote(d, owned):
			out.append(d)
	return out


## "You don't have the Star Spin yet! …"
static func emote_locked_words(emote: StringName) -> String:
	var id := AvatarCatalog.item_id(AvatarCatalog.EMOTE, emote)
	return Lang.t("You don't have the %s yet! %s") % [Lang.t(AvatarCatalog.display_name(id)), AvatarUnlocks.lock_reason(id)]


## Why /find `target` is not for this child now ("" = it is): Survivor's treasure needs a Treasure Map
## (fair fun §6: treasure is found by playing).
static func find_refusal(target: StringName, mode: StringName, has_map: bool) -> String:
	if target == &"treasure" and not ModeRules.allows(mode, ModeRules.CHEATS) and not has_map:
		return NO_MAP_MESSAGE
	return ""


## When /find sees nothing of `target` here.
static func find_missing(target: StringName, mode: StringName) -> String:
	match target:
		&"tilly":
			return "Tilly's shop is in Survivor worlds." if ModeRules.allows(mode, ModeRules.INFINITE_GOLD) \
				else "I can't see Tilly's shop yet. Look around the start!"
		&"portal":
			return "No portal here yet. Beat the boss to open one!"
		&"treasure":
			return "No treasure left nearby. Go exploring!"
		&"launch":   # owner #98
			return "The Launch Site is in your home worlds, a short walk from the start."
	return "I can't find that here."


## "Tilly is 42 blocks away, on your left." (yaw: where the camera looks; SurpriseRules.compass).
static func find_words(what: String, from: Vector3, to: Vector3, yaw: float) -> String:
	var r := SurpriseRules.compass(from, to, yaw)
	var d: int = r.distance
	var up := to.y - from.y
	var who := Lang.t(what)
	who = who.substr(0, 1).to_upper() + who.substr(1)
	if d <= FIND_HERE and absf(up) < FIND_HIGH:
		return Lang.t("%s is right here!") % who
	var a: float = r.angle
	var way := "straight ahead"
	if absf(a) >= PI * 0.75:
		way = "behind you"
	elif a > PI * 0.25:
		way = "on your right"
	elif a < -PI * 0.25:
		way = "on your left"
	var height := ", up high" if up > FIND_HIGH else (", down below" if up < -FIND_HIGH else "")
	return Lang.t("%s is %d %s away, %s%s.") % [who, d, Lang.t("block" if d == 1 else "blocks"), Lang.t(way),
		Lang.t(height) if height != "" else ""]


static func xp_words(d: ProgressData) -> String:
	var bar := LevelRules.level_progress(d.xp)
	if bar.y <= 0:
		return Lang.t("You have %d XP: the top level!") % d.xp
	return Lang.t("You have %d XP. %d more for level %d!") % [d.xp, bar.y - bar.x, d.level() + 1]


static func level_words(d: ProgressData) -> String:
	var title := LevelRules.title_text(LevelRules.shown_title(d.style_xp, d.title))
	var bar := LevelRules.level_progress(d.xp)
	if bar.y <= 0:
		return Lang.t("Level %d %s: the top level!") % [d.level(), title]
	return Lang.t("Level %d %s. %d XP to level %d.") % [d.level(), title, bar.y - bar.x, d.level() + 1]


static func pets_words(names: Array) -> String:
	if names.is_empty():
		return "You have no pets yet. Tap a dog or a cat 3 times to make a friend!"
	if names.size() == 1:
		return Lang.t("%s is coming!") % names[0]
	var first := PackedStringArray()
	for n: Variant in names.slice(0, names.size() - 1):
		first.append(str(n))
	return Lang.t("%s and %s are coming!") % [", ".join(first), names.back()]


## The second /clearbag (at `now`, seconds) after the first (at `asked_at`) empties the bag.
static func confirmed(asked_at: float, now: float) -> bool:
	return is_finite(asked_at) and now >= asked_at and now - asked_at <= CLEARBAG_SECONDS


## /universe by number or name ("desert", "Frostpeak", "green meadows").
static func _parse_universe(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return {"error": Lang.t("Use it like this: %s") % usage(&"universe")}
	var u := 0
	if args[0].is_valid_int():
		u = args[0].to_int()
		if u < 1 or u > UniverseRegistry.size():
			return {"error": Lang.t("Universes go from 1 to %d. Try /universe 2") % UniverseRegistry.size()}
	else:
		var key := _key(" ".join(args))
		for i in range(1, UniverseRegistry.size() + 1):
			if key == _key(String(UniverseRegistry.ladder_name(i))) or key == _key(UniverseRegistry.LADDER[i - 1].display_name):
				u = i
		if u == 0:
			return {"error": Lang.t("Try %s") % usage(&"universe")}
	return {"name": &"universe", "universe": u}


static func _parse_emote(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return {"error": Lang.t("Use it like this: %s") % usage(&"emote")}
	var key := _key(" ".join(args))
	for e: StringName in EmotePoses.DURATIONS:
		if _key(String(e)) == key:
			return {"name": &"emote", "emote": e}
	if DANCES.has(key):
		return {"name": &"emote", "emote": DANCES[key]}
	return {"error": "I don't know that one. Try /emote wave"}


static func _parse_bot(args: PackedStringArray) -> Dictionary:
	var action := args[0].to_lower() if not args.is_empty() else ""
	if action == "add":
		if args.size() < 2:
			return {"name": &"bot", "action": &"add", "personality": &""}
		var p := StringName(args[1].to_lower())
		if not BotRules.valid_personality(p):
			return {"error": "Bot friends are a builder, an explorer or a fighter. Try /bot add builder"}
		return {"name": &"bot", "action": &"add", "personality": p}
	if action == "remove":
		return {"name": &"bot", "action": &"remove", "bot": " ".join(args.slice(1))}
	return {"error": Lang.t("Use it like this: %s") % usage(&"bot")}

# --- M3 Task 8: /fill ----------------------------------------------------------------------------------

## /fill's default box and the biggest side (16 x 16 x 16 is the FILL tool's 4,096).
const FILL_DEFAULT := 3
const FILL_MAX_SIDE := 16


## /fill block [n | w h d] -> {"name": &"fill", "id", "size": Vector3i}: a block a player may place (not an item,
## not treasure), sides 1-16.
static func _parse_fill(args: PackedStringArray) -> Dictionary:
	var words := Array(args)
	var sides: Array[int] = []
	while not words.is_empty() and str(words.back()).is_valid_int() and sides.size() < 3:
		sides.push_front(str(words.pop_back()).to_int())
	if words.is_empty() or sides.size() == 2:
		return {"error": Lang.t("Use it like this: %s") % usage(&"fill")}
	for n in sides:
		if n < 1 or n > FILL_MAX_SIDE:
			return {"error": Lang.t("A box can be 1 to %d blocks on each side. Try /fill glass 5") % FILL_MAX_SIDE}
	var size := Vector3i(FILL_DEFAULT, FILL_DEFAULT, FILL_DEFAULT)
	if sides.size() == 1:
		size = Vector3i(sides[0], sides[0], sides[0])
	elif sides.size() == 3:
		size = Vector3i(sides[0], sides[1], sides[2])
	var wanted := " ".join(PackedStringArray(words))
	var id := item_for_name(wanted)
	if id < 0 or not BlockIds.is_valid(id) or NEVER_GIVEN.has(id):
		return {"error": "Fill with a block, like /fill glass 5"}
	return {"name": &"fill", "id": id, "size": size}
