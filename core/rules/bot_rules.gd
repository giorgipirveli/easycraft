class_name BotRules
extends RefCounted
## Bot friends as pure rules (M2 §12.14, owner feedback #18): up to three host-simulated friends
## with a made-up name, their own look and a personality (builder, explorer, fighter). They follow
## the player at a comfortable distance and pop up next to them when left far behind, rest when no
## player is near, pick which monsters to fight and what to do by personality, say at most one
## short chat line every 20 s, and builders plan small builds that only ever fill empty cells.

const MAX_BOTS := 3
const BUILDER := &"builder"
const EXPLORER := &"explorer"
const FIGHTER := &"fighter"
const PERSONALITIES: Array[StringName] = [BUILDER, EXPLORER, FIGHTER]

## What a bot is doing (its state; the host decides it AI_INTERVAL apart).
const IDLE := &"idle"
const FOLLOW := &"follow"
const WANDER := &"wander"
const FIGHT := &"fight"
const BUILD := &"build"
const POINT := &"point"          # an explorer showing the player something it found

const AI_INTERVAL := 0.1         # decisions ten times a second, like animals
const ACTIVE_DISTANCE := 32.0    # simulated only this close (sideways) to a player
const FOLLOW_NEAR := 2.5         # walking back stops this close to the player
## The comfortable distance: farther than this from the player, a bot walks back to them.
const FOLLOW_FAR := {BUILDER: 7.0, EXPLORER: 15.0, FIGHTER: 5.0}
const WANDER_MIN := 2.0
const WANDER_RADIUS := {BUILDER: 5.0, EXPLORER: 12.0, FIGHTER: 4.0}
const CATCH_UP := 24.0           # farther than this (sideways): pops up next to the player
const CATCH_UP_DROP := 12.0      # or this far above or below a player standing on the ground
## Monsters this close to the player are fought; fighters guard a wider circle.
const FIGHT_RADIUS := {BUILDER: 6.0, EXPLORER: 8.0, FIGHTER: 14.0}
const DEFEND_RADIUS := 3.0       # a monster this close to the bot itself is always fought
const WEAPON := ItemIds.SWORD    # every bot fights with the wooden sword (the host's weapon table)
const ATTACK_EVERY := 0.8        # seconds between a bot's swings: helpful, never the whole show
const KNOCKOUT_TIME := 10.0      # knocked out: back next to the player after this
const CHAT_GAP := 20.0           # at most one chat line per bot this often
const NOTICE_RADIUS := 24.0      # an explorer points at things this close to the player

const BUILD_FIRST := 15.0        # a builder's first build after joining
const BUILD_EVERY := 40.0        # and then
const BUILD_RETRY := 10.0        # nothing to build next to (or no room): looks again after this
const BUILD_NEAR := 12.0         # the player's blocks this close to the player count as their build
const BUILD_GAP := 2             # a build starts this far (at least) from the player's block
const MAX_BUILD_BLOCKS := 5
const BUILD_TRIES := 16          # spots tried per plan (of the 72 around the block)
const SPOT_STRIDE := 29          # coprime with 72: the tries go all around the block, not one side
## The ground a build may stand on: natural ground, never a player's planks, bricks or toys.
const GROUND: Array[int] = [BlockIds.GRASS, BlockIds.DIRT, BlockIds.STONE, BlockIds.SAND, BlockIds.DEEPSTONE,
	BlockIds.SANDSTONE, BlockIds.RED_SAND, BlockIds.RED_SANDSTONE,   # + BlockIds.DESERT_GROUND
	BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.ICE,   # + BlockIds.FROST_GROUND (M3 Task 3)
	BlockIds.FROSTING, BlockIds.CAKE, BlockIds.CHOCOLATE, BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.CREAM,
	BlockIds.JAM, BlockIds.SPRINKLES,   # + BlockIds.CANDY_GROUND (M3 Task 4)
	BlockIds.SKY_GRASS, BlockIds.FLOATSTONE, BlockIds.DEEP_FLOATSTONE,   # + BlockIds.DRAGON_GROUND (owner 39)
	BlockIds.MUD,   # owner #45b: a swamp
	BlockIds.MOON_DUST, BlockIds.MOON_ROCK, BlockIds.DEEP_MOON_ROCK,   # + BlockIds.SPACE_GROUND (owner #55)
	BlockIds.BOING_MOSS, BlockIds.BOING_SOIL, BlockIds.BOING_ROCK, BlockIds.JELLY, BlockIds.PRISM_GRASS, BlockIds.RAINBOW_RED,
	BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW, BlockIds.RAINBOW_GREEN, BlockIds.RAINBOW_BLUE, BlockIds.RAINBOW_VIOLET,
	BlockIds.MARS_DUST, BlockIds.MARS_REGOLITH, BlockIds.BASALT, BlockIds.DEEP_BASALT, BlockIds.MARS_SEDIMENT,   # cosmos: Mars
	BlockIds.POLAR_ICE, BlockIds.DRY_ICE,
	BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.BAND_ICE, BlockIds.DEEP_ICE, BlockIds.EUROPA_ROCK,   # cosmos: Europa
	BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR, BlockIds.IO_ROCK,   # cosmos: Io
	BlockIds.BLACK_LAVA,
	BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE, BlockIds.ICY_ROCK,   # cosmos: Titan
	BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST, BlockIds.SHADOW_ICE,   # Mercury
	BlockIds.VENUS_CLOUD, BlockIds.DEEP_CLOUD, BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL, BlockIds.SKY_TURF,   # Venus's city
	BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK, BlockIds.MOONLET_ICE,   # Saturn's rings
	BlockIds.RIDGE_DUST,
	BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.THOLIN_DUST,   # Pluto
	BlockIds.RED_ICE, BlockIds.METHANE_SNOW,
	BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST, BlockIds.CANTALOUPE_ICE,   # Triton
	BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA,
	BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE, BlockIds.RAY_ICE,   # Ganymede
	BlockIds.POLAR_FROST,
	BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.LAKE_STONE, BlockIds.FLOWSTONE]   # + BlockIds.GLOW_GROUND (universe 6)
## What a build may lean on: the world's own blocks (a hillside, a tree, water), never a player's
## planks, bricks, glass or toys.
const NATURAL: Array[int] = [BlockIds.GRASS, BlockIds.DIRT, BlockIds.STONE, BlockIds.SAND, BlockIds.DEEPSTONE,
	BlockIds.LOG, BlockIds.LEAVES, BlockIds.WATER, BlockIds.BEDROCK, BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD,
	BlockIds.DIAMOND, BlockIds.CRYSTAL, BlockIds.SANDSTONE, BlockIds.RED_SAND, BlockIds.RED_SANDSTONE,
	BlockIds.CACTUS, BlockIds.DEAD_BUSH, BlockIds.PALM_LOG, BlockIds.PALM_LEAVES,   # + the desert's own
	BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.ICE, BlockIds.PINE_LOG, BlockIds.PINE_NEEDLES,
	BlockIds.FROZEN_ORE,   # + Frostpeak's own (M3 Task 3)
	BlockIds.FROSTING, BlockIds.CAKE, BlockIds.CHOCOLATE, BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.CREAM,
	BlockIds.JAM, BlockIds.SPRINKLES, BlockIds.CANDY_CANE, BlockIds.LOLLIPOP, BlockIds.COTTON_CANDY,   # + the Candy Kingdom's (M3 Task 4)
	BlockIds.SKY_GRASS, BlockIds.FLOATSTONE, BlockIds.DEEP_FLOATSTONE, BlockIds.MUSHROOM_STEM, BlockIds.GLOW_CAP,
	BlockIds.CRYSTAL_SPIRE, BlockIds.CLOUD,   # + the Dragon Realm's (owner 39)
	BlockIds.MUD, BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG, BlockIds.DARK_LEAVES, BlockIds.FLOWERS,
	BlockIds.LILY_PAD, BlockIds.GLOW_MUSHROOM,   # + the wild meadows' (owner #45b)
	BlockIds.GOLD_QUARTZ, BlockIds.GOLD_GRAVEL, BlockIds.COPPER_ORE, BlockIds.MALACHITE, BlockIds.BANDED_IRON,
	BlockIds.RUSTY_ROCK, BlockIds.FERN_SHALE, BlockIds.OIL_SEEP, BlockIds.ROCK_SALT, BlockIds.SALT_CRUST,   # + spec §26's riches
	BlockIds.ICY_REGOLITH, BlockIds.MARE_DUST, BlockIds.ILMENITE, BlockIds.KREEP_ROCK, BlockIds.IRON_METEORITE,
	BlockIds.GROUND_ICE, BlockIds.BLUEBERRY_SOIL, BlockIds.HEMATITE, BlockIds.DARK_SAND, BlockIds.MARS_SALT,   # + §26.5's
	BlockIds.MOON_DUST, BlockIds.MOON_ROCK, BlockIds.DEEP_MOON_ROCK, BlockIds.MOON_CRYSTAL,   # + space's (owner #55)
	BlockIds.BOING_MOSS, BlockIds.BOING_SOIL, BlockIds.BOING_ROCK, BlockIds.JELLY, BlockIds.SPRING_STEM, BlockIds.SPRING_CAP,
	BlockIds.PRISM_GRASS, BlockIds.RAINBOW_RED, BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW, BlockIds.RAINBOW_GREEN,
	BlockIds.RAINBOW_BLUE, BlockIds.RAINBOW_VIOLET, BlockIds.PRISM_CRYSTAL,
	BlockIds.MARS_DUST, BlockIds.MARS_REGOLITH, BlockIds.BASALT, BlockIds.DEEP_BASALT, BlockIds.MARS_SEDIMENT,   # cosmos: Mars
	BlockIds.POLAR_ICE, BlockIds.DRY_ICE, BlockIds.GYPSUM,
	BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.BAND_ICE, BlockIds.DEEP_ICE, BlockIds.EUROPA_ROCK,   # cosmos: Europa
	BlockIds.GLOW_ICE, BlockIds.SALT, BlockIds.GEYSER_VENT,
	BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR, BlockIds.IO_ROCK,   # cosmos: Io
	BlockIds.BLACK_LAVA, BlockIds.LAVA_CRUST, BlockIds.HOT_LAVA, BlockIds.VOLCANO_VENT, BlockIds.SULPHUR_CRYSTAL,
	BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE, BlockIds.ICY_ROCK,   # cosmos: Titan
	BlockIds.SHORE_CRYSTAL,
	BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST, BlockIds.SHADOW_ICE,   # Mercury
	BlockIds.ICE_CRYSTAL,
	BlockIds.VENUS_CLOUD, BlockIds.DEEP_CLOUD, BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL, BlockIds.SKY_TURF,   # Venus's city
	BlockIds.CLOUD_CRYSTAL,
	BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK, BlockIds.MOONLET_ICE,   # Saturn's rings
	BlockIds.RIDGE_DUST, BlockIds.RING_CRYSTAL,
	BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.THOLIN_DUST,   # Pluto
	BlockIds.RED_ICE, BlockIds.METHANE_SNOW, BlockIds.FROST_CRYSTAL,
	BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST, BlockIds.CANTALOUPE_ICE,   # Triton
	BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA, BlockIds.NITROGEN_CRYSTAL, BlockIds.NITROGEN_GEYSER,
	BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE, BlockIds.RAY_ICE,   # Ganymede
	BlockIds.POLAR_FROST, BlockIds.AURORA_CRYSTAL,
	BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.LAKE_STONE, BlockIds.FLOWSTONE,   # universe 6: the Glow Caves
	BlockIds.SHROOM_STEM, BlockIds.BLUE_SHROOM, BlockIds.ROSE_SHROOM, BlockIds.GLOW_WORMS, BlockIds.SELENITE,
	BlockIds.STALACTITE, BlockIds.STALAGMITE]
## Small builds: [offset from the base cell, block id]; the base (0, 0, 0) first.
const SANDBOX_DESIGNS: Array = [
	[[Vector3i(0, 0, 0), BlockIds.PLANKS], [Vector3i(0, 1, 0), BlockIds.PLANKS], [Vector3i(0, 2, 0), BlockIds.LIGHT]],
	[[Vector3i(0, 0, 0), BlockIds.BRICK], [Vector3i(1, 0, 0), BlockIds.BRICK], [Vector3i(0, 1, 0), BlockIds.LEAVES],
		[Vector3i(1, 1, 0), BlockIds.LEAVES]],
	[[Vector3i(0, 0, 0), BlockIds.RED], [Vector3i(0, 1, 0), BlockIds.YELLOW], [Vector3i(0, 2, 0), BlockIds.GREEN],
		[Vector3i(0, 3, 0), BlockIds.BLUE], [Vector3i(0, 4, 0), BlockIds.PURPLE]],
	[[Vector3i(0, 0, 0), BlockIds.BRICK], [Vector3i(0, 1, 0), BlockIds.GLASS], [Vector3i(0, 2, 0), BlockIds.BRICK]],
	[[Vector3i(0, 0, 0), BlockIds.GREEN], [Vector3i(0, 1, 0), BlockIds.YELLOW]],
]
## Survivor (ruling): friends never use the player's counted blocks; they plant leaves, which give
## nothing when broken (§12.2), so a friend's build is never a free source of blocks or gold.
const SURVIVOR_DESIGNS: Array = [
	[[Vector3i(0, 0, 0), BlockIds.LEAVES], [Vector3i(1, 0, 0), BlockIds.LEAVES], [Vector3i(0, 1, 0), BlockIds.LEAVES]],
	[[Vector3i(0, 0, 0), BlockIds.LEAVES], [Vector3i(0, 1, 0), BlockIds.LEAVES], [Vector3i(0, 2, 0), BlockIds.LEAVES]],
	[[Vector3i(0, 0, 0), BlockIds.LEAVES], [Vector3i(1, 0, 0), BlockIds.LEAVES]],
]

## Shiny things an explorer points at (when it can see them).
const SHINY: Array[int] = [BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]
const NO_CELL := Vector3i(-2147483648, -2147483648, -2147483648)
const _SIDES: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1)]

## Made-up friendly names (never a real person's), all passing the username filter.
const NAMES: Array[String] = ["Pip", "Bolt", "Zuzu", "Sprout", "Nimbus", "Pebble", "Tinker", "Comet",
	"Mossy", "Widget", "Bloop", "Fizz", "Doodle", "Sparky", "Wobble", "Gizmo"]
## Each bot's look: blocky colours (torso, legs, skin) and, in the REALISTIC style, which body
## (0 = humanMaleA, 1 = humanFemaleA) wears a shirt of the torso colour (tools/make_bot_skins.py).
## Owner 48: "avatar" is the rest of the look (AvatarLook fields, free parts only), worn in the bot's own
## colours; "girl" looks wear girl hair, faces and clothes (and the long-haired realistic body, base 1).
## Dark hair: the realistic bodies keep their painted hair colour (tools/make_bot_skins.py).
const LOOKS: Array[Dictionary] = [
	{"torso": Color("3cbf5a"), "legs": Color("5a3d2b"), "skin": Color("f5cd30"), "base": 0,
		"avatar": {"hair": "spiky", "hair_color": "brown", "face": "grin"}},
	{"torso": Color("e8413c"), "legs": Color("2b3a67"), "skin": Color("f2c9a0"), "base": 1, "girl": true,
		"avatar": {"hair": "ponytail", "hair_color": "brown", "face": "sweet", "hat": "clips", "clothes": "skirt"}},
	{"torso": Color("a05be0"), "legs": Color("3b3b44"), "skin": Color("c68e5d"), "base": 0,
		"avatar": {"hair": "short", "hair_color": "black", "face": "smile", "clothes": "hoodie"}},
	{"torso": Color("f08a2c"), "legs": Color("1f6f78"), "skin": Color("f5cd30"), "base": 1, "girl": true,
		"avatar": {"hair": "pigtails", "hair_color": "brown", "face": "lovely", "clothes": "dress"}},
	{"torso": Color("34c6c9"), "legs": Color("44304f"), "skin": Color("8d5a3b"), "base": 0,
		"avatar": {"hair": "curly", "hair_color": "black", "face": "smile", "clothes": "overalls"}},
	{"torso": Color("e05ba8"), "legs": Color("2f2f2f"), "skin": Color("f2c9a0"), "base": 1, "girl": true,
		"avatar": {"hair": "braid", "hair_color": "black", "face": "sweet", "hat": "bow", "clothes": "leggings"}},
]
## Owner 48: which look a new friend gets first: a girl, then a boy, and so on (never an all-boy team).
const PICK_ORDER: Array[int] = [1, 0, 3, 2, 5, 4]

const LINE_KINDS: Array[StringName] = [&"hello", &"fight", &"win", &"knocked_out", &"back", &"build",
	&"shiny", &"animal", &"bye", &"idle"]
const HELLO := {BUILDER: "Hi, I'm %s! Let's build something cool!",
	EXPLORER: "Hi, I'm %s! Let's go exploring!", FIGHTER: "Hi, I'm %s! I'll keep you safe!"}
const IDLE_LINES := {
	BUILDER: ["I love your builds!", "Wow, you build so well!", "Want a lamp? I can make one!",
		"Building with you is the best!"],
	EXPLORER: ["What's over that hill?", "I wonder what's in that cave!", "This world is so big!"],
	FIGHTER: ["I'm right here with you!", "No monster gets past me!", "Stay close, OK?"],
}
const LINES := {
	&"fight": ["I've got this one!", "Watch out, a monster!", "Stay behind me!"],
	&"win": ["Got it!", "Poof! Gone!", "We make a great team!"],
	&"knocked_out": ["Oof! I'll be right back!", "Whoa! Back in a moment!"],
	&"back": ["I'm back!", "Ready to play again!"],
	&"build": ["I made something for you!", "Look, a little build next to yours!", "Ta-da! Do you like it?"],
	&"shiny": ["Look! Something shiny over here!"],
	&"animal": ["Look! A little friend over here! Pet it three times!"],
	&"bye": ["Bye! See you soon!"],
}


static func valid_personality(p: StringName) -> bool:
	return PERSONALITIES.has(p)


static func valid_look(look: int) -> bool:
	return look >= 0 and look < LOOKS.size()


# --- Following ---

static func follow_far(personality: StringName) -> float:
	return float(FOLLOW_FAR.get(personality, FOLLOW_FAR[FIGHTER]))


## Should the bot walk back to the player, `dist` away? Farther than the comfortable distance
## starts it; once walking (`following`), it keeps going until FOLLOW_NEAR.
static func wants_follow(dist: float, following: bool, personality: StringName) -> bool:
	return dist > FOLLOW_NEAR if following else dist > follow_far(personality)


## Too far behind to walk: pop up next to the player. A player flying high is waited for below.
static func needs_catch_up(bot: Vector3, leader: Vector3, leader_grounded: bool) -> bool:
	if bot.y < SpawnRules.FALL_LIMIT_Y:
		return true
	if Vector2(bot.x - leader.x, bot.z - leader.z).length() > CATCH_UP:
		return true
	return leader_grounded and absf(bot.y - leader.y) > CATCH_UP_DROP


## Simulated only near a player (measured sideways, like animals); otherwise it rests.
static func is_active(pos: Vector3, players: Array[Vector3]) -> bool:
	for p in players:
		if Vector2(p.x - pos.x, p.z - pos.z).length_squared() <= ACTIVE_DISTANCE * ACTIVE_DISTANCE:
			return true
	return false


## A spot to wander to near the player: `angle` (radians) and `t` (0..1, how far) are the rolls.
static func wander_spot(personality: StringName, leader: Vector3, angle: float, t: float) -> Vector3:
	var d := lerpf(WANDER_MIN, float(WANDER_RADIUS.get(personality, WANDER_MIN)), clampf(t, 0.0, 1.0))
	return Vector3(leader.x + cos(angle) * d, leader.y, leader.z + sin(angle) * d)


# --- Fighting and behaviours ---

## Which monster to fight (index into `monsters`), or -1: the nearest (to the bot) of those within
## the personality's FIGHT_RADIUS of the player, or within DEFEND_RADIUS of the bot itself.
static func choose_target(personality: StringName, bot: Vector3, leader: Vector3, monsters: Array[Vector3],
		guard_radius: float = -1.0) -> int:
	var guard := guard_radius if guard_radius >= 0.0 else float(FIGHT_RADIUS.get(personality, FIGHT_RADIUS[BUILDER]))
	var best := -1
	var best_d := INF
	for i in monsters.size():
		var m := monsters[i]
		var d := bot.distance_to(m)
		if (leader.distance_to(m) <= guard or d <= DEFEND_RADIUS) and d < best_d:
			best = i
			best_d = d
	return best


## The behaviour for this moment. facts: target (a monster to fight), far (wants_follow), sight
## (an explorer has something to show), build_ready (a builder has a planned build), wander_due;
## owner 38: order (what the child asked for: STAY, GUIDE, HIDE, DANCE) and asked_build (the child
## asked this friend to build, builder or not).
## A monster comes first (not while running and hiding); then what the child asked for; explorers
## point and builders build before walking back (their spot is near the player); then follow, wander,
## or stand and watch.
static func choose_behaviour(personality: StringName, facts: Dictionary) -> StringName:
	var order: StringName = facts.get("order", &"")
	if facts.get("target", false) and order != HIDE:
		return FIGHT
	if TALK_BEHAVIOURS.has(order):
		return order
	if personality == EXPLORER and facts.get("sight", false):
		return POINT
	if (personality == BUILDER or facts.get("asked_build", false)) and facts.get("build_ready", false):
		return BUILD
	if facts.get("far", false):
		return FOLLOW
	if facts.get("wander_due", false):
		return WANDER
	return IDLE


## What the bot holds: the sword in a fight; otherwise fighters keep it, builders carry a hammer.
static func held_item(personality: StringName, behaviour: StringName) -> int:
	if behaviour == FIGHT or personality == FIGHTER:
		return WEAPON
	return ItemIds.HAMMER if personality == BUILDER else 0


# --- Chat ---

## May a bot that last spoke at `last` (seconds; -INF = never) speak at `now`?
static func can_say(last: float, now: float) -> bool:
	return now - last >= CHAT_GAP


## A line of `kind` (LINE_KINDS) for a bot; pick varies it. "" for an unknown kind.
static func line(kind: StringName, personality: StringName, pick: int, bot_name: String) -> String:
	if kind == &"hello":
		return str(HELLO.get(personality, HELLO[FIGHTER])) % bot_name
	var list: Array = IDLE_LINES.get(personality, IDLE_LINES[FIGHTER]) if kind == &"idle" else LINES.get(kind, [])
	return "" if list.is_empty() else str(list[posmod(pick, list.size())])


## How a bot appears in the chat, so nobody mistakes it for a real person.
static func chat_name(bot_name: String) -> String:
	return Lang.t("%s (bot)") % bot_name


# --- Names and looks ---

## A name not in `taken` (pick varies it); when every name is taken, any name.
static func pick_name(taken: Array[String], pick: int) -> String:
	var free: Array[String] = []
	for n in NAMES:
		if not taken.has(n):
			free.append(n)
	if free.is_empty():
		return NAMES[posmod(pick, NAMES.size())]
	return free[posmod(pick, free.size())]


## The first look nobody wears yet, in PICK_ORDER (girls and boys in turn).
static func pick_look(taken: Array[int]) -> int:
	for i in PICK_ORDER:
		if not taken.has(i):
			return i
	return PICK_ORDER[0]


## Owner 48: whether look `look` is a girl's.
static func is_girl(look: int) -> bool:
	return valid_look(look) and bool(LOOKS[look].get("girl", false))


## Owner 48: the avatar look a bot of look `look` wears (hair, face, hat and clothes; its colours are the bot's).
static func avatar_look(look: int) -> AvatarLook:
	var a := AvatarLook.from_dict(LOOKS[posmod(look, LOOKS.size())].get("avatar", {}))
	a.base = AvatarCatalog.GIRL if is_girl(look) else AvatarCatalog.BOY
	return a


# --- Builders ---

static func build_design(mode: StringName, pick: int) -> Array:
	var designs: Array = SURVIVOR_DESIGNS if ModeRules.valid(mode) == ModeRules.SURVIVOR else SANDBOX_DESIGNS
	return designs[posmod(pick, designs.size())]


## Where a small `design` goes next to the player's block `anchor`: [[cell, id], ...] or [] when
## there is no room. The base stands on natural ground (GROUND) 2-4 blocks from the anchor, every
## cell of the build is empty, and the cells around it at the same heights are empty or natural
## (NATURAL): a build never replaces, touches or sits on the player's blocks. start: which spot
## around the anchor to try first (varies between builds); BUILD_TRIES spots are tried, so a plan
## costs little. block_at(cell) -> id. bodies: players and friends (never build where someone stands).
static func plan_build(anchor: Vector3i, design: Array, block_at: Callable, start: int,
		bodies: Array[AABB] = []) -> Array:
	var spots := _ring(BUILD_GAP, BUILD_GAP + 2)
	for i in mini(spots.size(), BUILD_TRIES):
		var side: Vector2i = spots[posmod(start + i * SPOT_STRIDE, spots.size())]   # spread all around
		var base := _base_at(anchor + Vector3i(side.x, 0, side.y), block_at)
		if base == NO_CELL:
			continue
		var plan: Array = []
		for cell: Array in design:
			plan.append([base + (cell[0] as Vector3i), int(cell[1])])
		if plan_fits(plan, block_at, bodies):
			return plan
	return []


## Does a planned build still fit: every cell empty with empty cells around it, nobody standing
## in it? (Checked again right before it goes up; the player may have built there meanwhile.)
static func plan_fits(plan: Array, block_at: Callable, bodies: Array[AABB]) -> bool:
	if plan.is_empty():
		return false
	for cell: Array in plan:
		var box := AABB(Vector3(cell[0] as Vector3i), Vector3.ONE)
		for body in bodies:
			if body.intersects(box):
				return false
	return _has_room(plan, block_at)


## Columns (dx, dz) from `inner` to `outer` blocks away (the larger of |dx| and |dz|), nearest first.
static func _ring(inner: int, outer: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r in range(inner, outer + 1):
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) == r:
					out.append(Vector2i(dx, dz))
	return out


## The empty cell standing on natural ground in the column of `at`, from 2 above to 4 below it.
static func _base_at(at: Vector3i, block_at: Callable) -> Vector3i:
	for dy in range(2, -5, -1):
		var cell := at + Vector3i(0, dy, 0)
		if block_at.call(cell) == BlockIds.AIR and GROUND.has(block_at.call(cell + Vector3i.DOWN)):
			return cell
	return NO_CELL


static func _has_room(plan: Array, block_at: Callable) -> bool:
	var mine := {}
	for cell: Array in plan:
		mine[cell[0]] = true
	for cell: Array in plan:
		var pos: Vector3i = cell[0]
		if block_at.call(pos) != BlockIds.AIR:
			return false
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var n := pos + Vector3i(dx, 0, dz)
				if mine.has(n):
					continue
				var id: int = block_at.call(n)
				if id != BlockIds.AIR and not NATURAL.has(id):
					return false
	return true


# --- Explorers ---

static func is_shiny(id: int) -> bool:
	return SHINY.has(id)


## The nearest shiny block in the box center ± half that the player could see (a side open to air
## or water) and that is not in `seen`, or NO_CELL.
static func find_shiny(center: Vector3i, block_at: Callable, half: Vector3i, seen: Dictionary) -> Vector3i:
	var best := NO_CELL
	var best_d := INF
	for y in range(center.y - half.y, center.y + half.y + 1):
		for z in range(center.z - half.z, center.z + half.z + 1):
			for x in range(center.x - half.x, center.x + half.x + 1):
				var cell := Vector3i(x, y, z)
				if not is_shiny(block_at.call(cell)) or seen.has(cell) or not _open(cell, block_at):
					continue
				var d := Vector3(cell - center).length_squared()
				if d < best_d:
					best_d = d
					best = cell
	return best


## The cells holding one of `ids` in a copied box (`buf`, the type channel; its corner at `origin`),
## found by a native search of the box's bytes instead of a script loop over every cell (a 9 x 7 x 9
## look cost 4.5 ms that way on the desktop). Voxel Tools keeps cells y-first: index = y + sy * (x + sx * z).
static func find_in_buffer(buf: VoxelBuffer, origin: Vector3i, ids: Array[int]) -> Array[Vector3i]:
	buf.decompress_channel(VoxelBuffer.CHANNEL_TYPE)      # a box of one block is stored as one value
	var bytes := buf.get_channel_as_byte_array(VoxelBuffer.CHANNEL_TYPE)
	var wide := buf.get_channel_depth(VoxelBuffer.CHANNEL_TYPE) == VoxelBuffer.DEPTH_16_BIT
	var width := 2 if wide else 1
	var size := buf.get_size()
	var out: Array[Vector3i] = []
	for id in ids:
		if id < 0 or id >= (1 << (8 * width)):
			continue   # an id this box can't hold
		var low := id & 0xFF   # M3 Task 19: ids past 255 (owner #45b's blocks) are two bytes
		var i := bytes.find(low)
		while i >= 0:
			if i % width == 0 and (not wide or bytes[i + 1] == id >> 8):   # 16 bits, little-endian
				var v := i / width
				var rest := v / size.y
				out.append(origin + Vector3i(rest % size.x, v % size.y, rest / size.x))
			i = bytes.find(low, i + 1)
	return out


## The nearest of `cells` that is open to air or water and not in `seen`, or NO_CELL.
static func nearest_open(center: Vector3i, cells: Array[Vector3i], block_at: Callable, seen: Dictionary) -> Vector3i:
	var best := NO_CELL
	var best_d := INF
	for cell in cells:
		var d := Vector3(cell - center).length_squared()
		if d < best_d and not seen.has(cell) and _open(cell, block_at):
			best_d = d
			best = cell
	return best


static func _open(cell: Vector3i, block_at: Callable) -> bool:
	for s in _SIDES:
		var id: int = block_at.call(cell + s)
		if id == BlockIds.AIR or id == BlockIds.WATER:
			return true
	return false


# --- Boss fights ---

## Players and bot friends together: bots count for the Stone Golem's health like players (§12.9).
static func team_size(players: int, bots: int) -> int:
	return players + bots


# --- M4 E: bot friends fill the empty seats of an online world (§17.5) ---

## What a friend says when a player joins a full world and it makes room (it comes back later).
const MAKE_ROOM_LINE := "I'll make room for your friend!"


## How many bot friends may play in an online world with `players` in it: the seats the players
## leave (four in all, OnlineRules.MAX_PLAYERS), never more than MAX_BOTS.
static func seats_for_bots(players: int, max_players: int = OnlineRules.MAX_PLAYERS) -> int:
	return clampi(max_players - players, 0, MAX_BOTS)


# --- Owner 38: what the child asks for (BotIntents, spec §12.14a) -------------------------------------

## Behaviours the child's words switch on (BotFriend's talk orders).
const STAY := &"stay"            # waits where the child said (or at the child's home)
const GUIDE := &"guide"          # leads the child to a place: a secret nobody found, Tilly's stall
const HIDE := &"hide"            # runs from monsters, or hides quietly behind the child
const DANCE := &"dance"          # dances (or does a trick) where it stands
const TALK_BEHAVIOURS: Array[StringName] = [STAY, GUIDE, HIDE, DANCE]

const CLOSE_FOLLOW := 3.0        # "follow me": walks back from this far, for CLOSE_TIME
const CLOSE_TIME := 60.0
const GUARD_RADIUS := 16.0       # "guard me": monsters this close to the child are fought, for GUARD_TIME
const GUARD_TIME := 120.0
const HELP_TIME := 30.0          # "help!": close and guarding this long
const STAY_TIME := 180.0         # waits this long (at home: until called)
const STAY_LEASH := 96.0         # a waiting friend comes after a child farther away than this
const SPACE_TIME := 20.0         # "give me space": stays back this long
const SPACE_MORE := 2            # and keeps this many more blocks of space (BotStyle.walked_away)
const HIDE_TIME := 20.0
const RUN_TIME := 10.0
const RUN_FROM_MONSTERS := 16.0  # "run away" with monsters this close to the child: run
const RUN_DISTANCE := 8.0
const DANCE_TIME := 6.0
const TRICK_TIME := 3.0
const GUIDE_TIME := 240.0
const GUIDE_MAX := 250.0         # farther places are told, not led to
const GUIDE_AHEAD := 9.0         # a guide waits when the child is farther behind than this
const HOME_POP := 16.0           # home farther than this: it pops over (a poof) instead of walking
const LOOK_TIME := 15.0          # "look!": comes close this long
const BUILD_STEP := 0.35         # a requested build places MAX_BUILD_BLOCKS blocks this often
const DANCES: Array[StringName] = [&"dance_hop", &"dance_robot", &"dance_star"]
const TRICK := &"victory"


## A build the child asked for (BotIntents.HOUSE / TOWER / WALL; &"" for a small design of its own):
## [[offset from the base cell, id], ...], base (0, 0, 0) first. `block` builds it all when >= 0
## (the child's blocks, or leaves in Survivor); else a house has plank walls and a brick roof, a
## tower is brick with a lamp on top, a wall is brick.
static func request_design(what: StringName, block: int = -1) -> Array:
	var out: Array = []
	match what:
		BotIntents.HOUSE:              # a 3 x 3 hut: walls 2 high with a doorway, a flat roof
			for y in 2:
				for z in 3:
					for x in 3:
						if (x == 1 and z == 1) or (x == 1 and z == 0):
							continue       # inside, and the doorway
						out.append([Vector3i(x, y, z), block if block >= 0 else BlockIds.PLANKS])
			for z in 3:
				for x in 3:
					out.append([Vector3i(x, 2, z), block if block >= 0 else BlockIds.BRICK])
		BotIntents.TOWER:
			for y in 6:
				out.append([Vector3i(0, y, 0), block if block >= 0 else BlockIds.BRICK])
			if block < 0:
				out.append([Vector3i(0, 6, 0), BlockIds.LIGHT])
		BotIntents.WALL:
			for x in 5:
				for y in 2:
					out.append([Vector3i(x, y, 0), block if block >= 0 else BlockIds.BRICK])
	return out
