class_name TreasureRules
extends RefCounted
## The treasure pack while playing (owner feedback #42, spec §12.16b), as pure rules: when a rainbow comes and
## where its pot of gold lands, the wishing well's once-a-day gift, the vault's levers, the friendly ghosts'
## riddles; and the pack's words and pictures (names, what a find says, the Secret Book's picture riddles,
## what explorer bots say, which pets sniff out treasure). Everything is decided from the world seed and a
## count (the n-th dawn) or a fixed table, so a world plays the same way every time and the host can check it.

# Pictures: tiles of the pack's own atlas, data/secrets/treasure_pictures.png (8 x 3, drawn by
# tools/make_treasure_pictures.gd); ids go on after the M2 atlas's 32 tiles (Pictures picks the atlas).
const FIRST_PICTURE := 32
const PICTURE_COUNT := 24
const COLUMNS := 8
const SHIPWRECK_PICTURE := 32
const SUNKEN_PICTURE := 33
const MINESHAFT_PICTURE := 34
const VAULT_PICTURE := 35
const WATERFALL_PICTURE := 36
const HOLLOW_PICTURE := 37
const RAINBOW_PICTURE := 38
const WELL_PICTURE := 39
const COVE_PICTURE := 40
const RUINS_PICTURE := 41
const HAUNTED_PICTURE := 42
const CAMP_PICTURE := 43
const ANCHOR := 44
const CROWN := 45
const GEM := 46
const COIN := 47
const PICKAXE := 48
const LEVER := 49
const WAVES := 50
const FIRE := 51
const GHOST := 52
const DROP := 53

## The short word under a picture answer (Riddles.word looks here for the pack's pictures).
const WORDS := {
	ANCHOR: "anchor", CROWN: "crown", GEM: "gem", COIN: "coin", PICKAXE: "pickaxe", LEVER: "lever",
	WAVES: "waves", FIRE: "fire", GHOST: "ghost", DROP: "water", RAINBOW_PICTURE: "rainbow",
	SHIPWRECK_PICTURE: "ship", WELL_PICTURE: "well", CAMP_PICTURE: "tent",
}

const NAMES := {
	TreasurePlaces.SHIPWRECK: "Shipwreck", TreasurePlaces.SUNKEN: "Sunken Chest",
	TreasurePlaces.MINESHAFT: "Mineshaft", TreasurePlaces.VAULT: "Dungeon Vault",
	TreasurePlaces.WATERFALL: "Waterfall Cave", TreasurePlaces.HOLLOW: "Hollow Tree",
	TreasurePlaces.RAINBOW: "Pot of Gold", TreasurePlaces.WELL: "Wishing Well", TreasurePlaces.COVE: "Pirate Cove",
	TreasurePlaces.RUINS: "Ancient Ruins", TreasurePlaces.HAUNTED: "Haunted House", TreasurePlaces.CAMP: "Campsite",
}
const FOUND_TEXT := {
	TreasurePlaces.SHIPWRECK: "You found a shipwreck!", TreasurePlaces.SUNKEN: "You found a sunken chest!",
	TreasurePlaces.MINESHAFT: "You found an old mineshaft!", TreasurePlaces.VAULT: "You opened a dungeon vault!",
	TreasurePlaces.WATERFALL: "You found a cave behind a waterfall!",
	TreasurePlaces.HOLLOW: "You found a hollow tree!", TreasurePlaces.RAINBOW: "You found the pot of gold!",
	TreasurePlaces.WELL: "You found a wishing well!", TreasurePlaces.COVE: "You found a pirate cove!",
	TreasurePlaces.RUINS: "You found ancient ruins!", TreasurePlaces.HAUNTED: "You found a friendly haunted house!",
	TreasurePlaces.CAMP: "You found a campsite!",
}
const PICTURES := {
	TreasurePlaces.SHIPWRECK: SHIPWRECK_PICTURE, TreasurePlaces.SUNKEN: SUNKEN_PICTURE,
	TreasurePlaces.MINESHAFT: MINESHAFT_PICTURE, TreasurePlaces.VAULT: VAULT_PICTURE,
	TreasurePlaces.WATERFALL: WATERFALL_PICTURE, TreasurePlaces.HOLLOW: HOLLOW_PICTURE,
	TreasurePlaces.RAINBOW: RAINBOW_PICTURE, TreasurePlaces.WELL: WELL_PICTURE, TreasurePlaces.COVE: COVE_PICTURE,
	TreasurePlaces.RUINS: RUINS_PICTURE, TreasurePlaces.HAUNTED: HAUNTED_PICTURE, TreasurePlaces.CAMP: CAMP_PICTURE,
}
## The Secret Book's picture riddles: until a kind is found its slot shows where to look (a picture and a
## few words), never the kind's own picture.
const BOOK_RIDDLES := {
	TreasurePlaces.SHIPWRECK: {"text": "Where waves meet sand, a boat sleeps.", "picture": WAVES},
	TreasurePlaces.SUNKEN: {"text": "Swim down deep. Something shines!", "picture": Riddles.FISH},
	TreasurePlaces.MINESHAFT: {"text": "Follow the rails under the hill.", "picture": PICKAXE},
	TreasurePlaces.VAULT: {"text": "Deep down, three levers wait.", "picture": LEVER},
	TreasurePlaces.WATERFALL: {"text": "Look behind the falling water.", "picture": DROP},
	TreasurePlaces.HOLLOW: {"text": "Some big trees have a door.", "picture": Riddles.TREE},
	TreasurePlaces.RAINBOW: {"text": "Find where the rainbow ends.", "picture": Riddles.CLOUD},
	TreasurePlaces.WELL: {"text": "Toss a coin and make a wish.", "picture": COIN},
	TreasurePlaces.COVE: {"text": "Pirates hid gold by the sea.", "picture": ANCHOR},
	TreasurePlaces.RUINS: {"text": "Old kings left their stones.", "picture": CROWN},
	TreasurePlaces.HAUNTED: {"text": "Friendly ghosts love riddles.", "picture": GHOST},
	TreasurePlaces.CAMP: {"text": "Campers left their supplies.", "picture": FIRE},
}
## What an explorer bot says when it points at one (BotDirector.notice).
const NOTICE := {
	TreasurePlaces.SHIPWRECK: "Look! An old ship!", TreasurePlaces.SUNKEN: "Look! Something shiny under the water!",
	TreasurePlaces.MINESHAFT: "Look! An old mine!", TreasurePlaces.VAULT: "Look! Stairs going down deep!",
	TreasurePlaces.WATERFALL: "Look! A waterfall!", TreasurePlaces.HOLLOW: "Look! A giant old tree!",
	TreasurePlaces.RAINBOW: "Look! A rainbow!", TreasurePlaces.WELL: "Look! A wishing well!",
	TreasurePlaces.COVE: "Look! A pirate cave!", TreasurePlaces.RUINS: "Look! Old ruins!",
	TreasurePlaces.HAUNTED: "Look! A spooky little house!", TreasurePlaces.CAMP: "Look! A campsite!",
}
const NOTICE_DEFAULT := "Look! Something secret over here!"
## /secret's names for the pack's kinds.
const HINT_NAMES := {
	TreasurePlaces.SHIPWRECK: "shipwreck", TreasurePlaces.SUNKEN: "sunken chest", TreasurePlaces.MINESHAFT: "mineshaft",
	TreasurePlaces.VAULT: "dungeon vault", TreasurePlaces.WATERFALL: "waterfall cave",
	TreasurePlaces.HOLLOW: "hollow tree", TreasurePlaces.WELL: "wishing well", TreasurePlaces.COVE: "pirate cove",
	TreasurePlaces.RUINS: "ancient ruins", TreasurePlaces.HAUNTED: "haunted house", TreasurePlaces.CAMP: "campsite",
}

## The vault's levers: painted with a key, a crown and a gem; its note draws them in the order to flip them.
const VAULT_SYMBOLS: Array[int] = [Riddles.KEY, CROWN, GEM]
const VAULT_TEXT := "Flip them in this order!"
const LOCK_TEXT := {&"vault": "Locked! Flip the levers in the right order.",
	&"haunted": "Locked! Answer the ghost's riddle."}
const LOCK_DEFAULT := "Locked! Step on the plates in the right order."

## The ghosts' riddles: a short question and three picture answers; `answer` is the right one's index.
const GHOST_RIDDLES: Array[Dictionary] = [
	{"question": "Hee hee! I shine at the rainbow's end.", "choices": [COIN, Riddles.FISH, Riddles.CAT], "answer": 0},
	{"question": "Boo! I tick and tock all night.", "choices": [Riddles.TREE, Riddles.CLOCK, Riddles.APPLE], "answer": 1},
	{"question": "Hee hee! I float and say boo!", "choices": [Riddles.SUN, Riddles.KEY, GHOST], "answer": 2},
	{"question": "Boo! I hold a ship still at sea.", "choices": [ANCHOR, Riddles.BALL, Riddles.FLOWER], "answer": 0},
	{"question": "Hee hee! I sparkle deep in caves.", "choices": [Riddles.HOUSE, GEM, Riddles.CLOUD], "answer": 1},
	{"question": "Boo! Kings wear me on their heads.", "choices": [Riddles.FISH, Riddles.MOON, CROWN], "answer": 2},
	{"question": "Hee hee! I purr when you pet me.", "choices": [Riddles.CAT, Riddles.HEART, Riddles.STAR], "answer": 0},
	{"question": "Boo! I keep campers warm at night.", "choices": [Riddles.KEY, FIRE, Riddles.FISH], "answer": 1},
]
const GHOST_RIGHT := "Hee hee! You got it! The chest is open!"
const GHOST_WRONG := "Hee hee! Not quite. Try again!"

## Pets that sniff out treasure: dogs, foxes (owner #41's foxes, whatever their species names) and parrots.
const SNIFFERS: Array[StringName] = [&"dog", &"fox", &"parrot"]
## The kinds whose chests a pet leads to: every chest that isn't locked.
const SNIFF_KINDS: Array[StringName] = [&"treasure", &"room", TreasurePlaces.SHIPWRECK,
	TreasurePlaces.SUNKEN, TreasurePlaces.MINESHAFT, TreasurePlaces.WATERFALL, TreasurePlaces.HOLLOW,
	TreasurePlaces.COVE, TreasurePlaces.RUINS, TreasurePlaces.CAMP]

# The rainbow's end.
const RAINBOW_EVERY := 2          # about one dawn in 2 (the first dawn always)
const RAINBOW_STAY := 180.0       # seconds a rainbow stays
const RAINBOW_SPAN := 40.0        # blocks from the pot to the rainbow's other foot
const POT_MIN := 16.0             # the pot lands this far from a player ...
const POT_MAX := 28.0             # ... at most this far
const POT_REACH := 2.5            # a player this close (sideways) has reached it
const POT_HEIGHT := 3.0           # ... with their feet this close up or down
const POT_GOLD := 50              # Survivor gold, x 2^(u-1), once per rainbow for each player
const POT_BLOCKS := 4             # of each rainbow colour

## The well's gifts, one per day of the week (fixed; never gold).
const WISH_GIFTS: Array = [
	[[ItemIds.POTION_JUMP, 1]],
	[[ItemIds.TREASURE_MAP, 1]],
	[[BlockIds.LANTERN, 2]],
	[[ItemIds.POTION_SPEED, 1]],
	[[BlockIds.RED, 4], [BlockIds.YELLOW, 4], [BlockIds.BLUE, 4]],
	[[BlockIds.GLASS, 6]],
	[[ItemIds.POTION_INVIS, 1]],
	[[BlockIds.GREEN, 4], [BlockIds.PURPLE, 4]],
]
const WISH_TEXT := "Your wish came true!"
const WISH_DONE := "The well already gave you a gift today."


static func word(picture: int) -> String:
	return WORDS.get(picture, "")


static func notice_text(kind: StringName) -> String:
	return NOTICE.get(kind, NOTICE_DEFAULT)


static func lock_text(chest_kind: StringName) -> String:
	return LOCK_TEXT.get(chest_kind, LOCK_DEFAULT)


static func sniffs(species: StringName) -> bool:
	return SNIFFERS.has(species) or String(species).ends_with("fox") or String(species).ends_with("parrot")


static func ghost_riddle(index: int) -> Dictionary:
	return GHOST_RIDDLES[posmod(index, GHOST_RIDDLES.size())]


static func is_right_ghost_answer(riddle: int, choice: int) -> bool:
	return choice >= 0 and choice < 3 and choice == int(ghost_riddle(riddle).answer)


## Which of three levers stay on for the progress so far (the right ones flipped in order).
static func levers_on(progress: Array, count: int) -> Array[bool]:
	var out: Array[bool] = []
	for i in count:
		out.append(progress.has(i))
	return out


# --- The rainbow ---

## Is there a rainbow on the world's n-th dawn (counted from 1)?
static func rainbow_at_dawn(world_seed: int, dawn: int) -> bool:
	return dawn >= 1 and (dawn == 1 or _mix(world_seed, dawn, 21) % RAINBOW_EVERY == 0)


## Rainbows show in daylight: from the start of the day to the start of dusk.
static func rainbow_may_show(time_of_day: float) -> bool:
	return DayCycle.phase(time_of_day) == DayCycle.Phase.DAY


## Where the n-th rainbow's pot of gold lands near a player at `near`: {"pot": the first air cell above dry
## ground, "yaw": the way the arch runs (across the player's view)}, or {} when every try is water.
## height_at(x, z) -> the ground height there.
static func rainbow_spot(world_seed: int, n: int, near: Vector3, height_at: Callable) -> Dictionary:
	var a0 := (_mix(world_seed, n, 22) % 3600) / 3600.0 * TAU
	var d := lerpf(POT_MIN, POT_MAX, (_mix(world_seed, n, 23) % 1000) / 1000.0)
	for i in 8:
		var a := a0 + i * TAU / 8.0
		var x := floori(near.x + cos(a) * d)
		var z := floori(near.z + sin(a) * d)
		var h: int = height_at.call(x, z)
		if h > MeadowsShape.SEA_LEVEL + 1:
			return {"pot": Vector3i(x, h, z), "yaw": -a - PI / 2.0}   # the arch runs across the view
	return {}


## Has a player with feet at `feet` reached the pot at `pot`?
static func at_pot(feet: Vector3, pot: Vector3i) -> bool:
	return Vector2(feet.x - pot.x - 0.5, feet.z - pot.z - 0.5).length() <= POT_REACH and absf(feet.y - pot.y) <= POT_HEIGHT


## The pot of gold: a fixed pile of Survivor gold (x 2^(u-1)) and a few blocks of each rainbow colour.
static func pot_reward(universe: int, survivor: bool) -> Dictionary:
	var items: Array = []
	for id: int in [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE]:
		items.append([id, POT_BLOCKS])
	var gold := POT_GOLD * (1 << clampi(SpaceRules.scaling(universe) - 1, 0, 20)) if survivor else 0
	return {"gold": gold, "items": items, "rarity": ItemRarity.LEGENDARY}


# --- The wishing well ---

## May player `who` wish on day `day` (a world's day: its dawns seen)? Once a day each.
static func may_wish(wishes: Dictionary, who: String, day: int) -> bool:
	return int(wishes.get(who, -1)) != day


static func wish(wishes: Dictionary, who: String, day: int) -> void:
	wishes[who] = day


## The day's gift: {"gold": 0, "items": [[id, count], ...], "rarity"}.
static func wish_gift(day: int) -> Dictionary:
	var items: Array = (WISH_GIFTS[posmod(day, WISH_GIFTS.size())] as Array).duplicate(true)
	return {"gold": 0, "items": items, "rarity": LootRules.best_rarity(items)}


static func _mix(world_seed: int, n: int, salt: int) -> int:
	return SurpriseRules._mix(world_seed, n, salt)
