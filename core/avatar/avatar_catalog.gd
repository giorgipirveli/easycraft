class_name AvatarCatalog
extends RefCounted
## Every avatar item (M3 Task 9; spec §5.9, §13.6, §14.6): our own designs, account-wide. A slot's
## item is a short name (&"crown"); its id is "<slot>.<name>" ("hat.crown"). Colours (skin, hair
## colour, shirt, pants) and hair styles are always free; the rest is free, has a FIXED gold price
## (Survivor gold) or is earned (achievements, bosses, secrets, codes). Nothing is random (§6).

const SKIN := &"skin"
const HAIR_COLOR := &"hair_color"
const SHIRT := &"shirt"
const PANTS := &"pants"
const FACE := &"face"
const HAIR := &"hair"
const HAT := &"hat"
const CAPE := &"cape"
const WINGS := &"wings"
const TRAIL := &"trail"
const OUTFIT := &"outfit"
const EMOTE := &"emote"
const CLOTHES := &"clothes"   # Owner 48: the cut of the clothes (a dress, a hoodie...) in the look's own colours
## The editor's tabs, in order (colour slots first: they are what children change most).
const SLOTS: Array[StringName] = [SKIN, FACE, HAIR, HAT, SHIRT, PANTS, CLOTHES, CAPE, WINGS, TRAIL, OUTFIT, EMOTE]

## How an item is unlocked. There is no random kind, ever (§6, §5.9).
const FREE := &"free"
const GOLD := &"gold"                # a fixed Survivor-gold price
const ACHIEVEMENT := &"achievement"  # earned by doing something (EARN_* below)
const BOSS := &"boss"                # earned by beating a boss
const SECRET := &"secret"            # earned by finding secrets
const CODE := &"code"                # given by a secret code (CodeRules.KIND_COSMETIC)
## Owner 35 (spec §18.4): only in a product a grown-up buys (ShopCatalog; "pack": the product id).
## Never for gold, never earned, never random; nothing earnable is ever sold.
const PACK := &"pack"
## Owner 36 (spec §14.6b): a part that comes only with its costume ("costume": the CostumeRules id), which is
## earned by playing.
const IN_COSTUME := &"in_costume"
const UNLOCK_KINDS: Array[StringName] = [FREE, GOLD, ACHIEVEMENT, BOSS, SECRET, CODE, PACK, IN_COSTUME]
## Owner 36: the costumes themselves are items "costume.<id>" (CostumeRules), not a tab: earning one gives
## everything it wears.
const COSTUME := &"costume"

## Earn events: other systems call AvatarUnlocks.earn(profile, <event>) when they happen.
const EARN_TUTORIAL := &"tutorial"             # M3 Task 15: Pip's lessons finished (§5.10 "a free hat")
const EARN_FIRST_VICTORY := &"first_victory"   # the first won wave or boss (Player.celebrate in Survivor)
const EARN_GOLEM := &"golem"                   # M2 Task 10: the Stone Golem beaten
const EARN_CAKE_MONSTER := &"cake_monster"     # M3 Task 4: the Cake Monster beaten (the cosmic outfit)
const EARN_SECRET_PAGE := &"secret_page"       # M2 Task 16 / M3: a whole Secret Book page found
const EARN_TREASURE_PAGE := &"treasure_page"   # M3 Task 21b: the Secret Book's Treasure Hunt page all found (BookPages)
const EARN_KEEPSAKE_PAGE := &"keepsake_page"   # M3 Task 21b: every quest story's keepsake on the Keepsakes page
const EARN_SERPENT := &"serpent"               # Owner 36: the Sand Serpent beaten (Hercules)
## What a locked item says (short, friendly, never pressure: §6).
const EARN_REASONS := {
	EARN_TUTORIAL: "Finish Pip's lessons to get it!",
	EARN_FIRST_VICTORY: "Win a wave to get it!",
	EARN_GOLEM: "Beat the Stone Golem to get it!",
	EARN_CAKE_MONSTER: "Beat the Cake Monster to get it!",
	EARN_SECRET_PAGE: "Find all secrets on a Secret Book page!",
	EARN_TREASURE_PAGE: "Find every treasure on the Treasure Hunt page!",   # M3 Task 21b
	EARN_KEEPSAKE_PAGE: "Fill the Keepsakes page of your Secret Book!",
	# Owner 36 (spec §14.6b): the Storybook costume pack's ways (CostumeRules)
	EARN_SERPENT: "Beat the Sand Serpent to get it!",
	&"level/3": "Reach level 3 to get it!",
	&"level/6": "Reach level 6 to get it!",
	&"level/10": "Reach level 10 to get it!",
	&"quest/tilly_map": "Help Tilly with her lost map!",
	&"quest/tilly_pets": "Help Tilly find homes for animals!",
	&"quest/tilly_star": "Help Tilly catch a falling star!",
	&"quest/zara_scarab": "Help Zara find the golden scarab!",
	&"quest/zara_oasis": "Help Zara keep the desert paths safe!",
	&"title/explorer": "Find 10 new places to be an Explorer!",
	&"title/hunter": "Find 2 secrets to be a Secret Hunter!",
	&"title/magic": "Wake 3 buddies to be a Buddy Maker!",
	&"title/animals": "Tame 2 animals to be an Animal Friend!",
	&"title/fighter": "Chase away 5 monsters to be a Monster Buster!",
	&"badge/big_builder": "Build with 1,000 blocks to get it!",
	&"secret/cove": "Find a pirate cove to get it!",
	&"secret/sunken": "Find a sunken chest to get it!",
	&"count/buddy_ridden/fly": "Fly on a buddy you built!",
}
const CODE_REASON := "A secret code unlocks this!"

## Rarity colours (§13.2): common grey, uncommon green, rare blue, epic purple, legendary gold.
const COMMON := &"common"
const UNCOMMON := &"uncommon"
const RARE := &"rare"
const EPIC := &"epic"
const LEGENDARY := &"legendary"
const RARITY_COLORS := {COMMON: Color("9e9e9e"), UNCOMMON: Color("4caf50"), RARE: Color("2196f3"),
	EPIC: Color("9c27b0"), LEGENDARY: Color("ffc107")}

const WHEEL_SLOTS := 8

## Clothes patterns (the realistic style's shader; the blocky body adds boxes).
const PATTERN_NONE := 0
const PATTERN_STRIPES := 1
const PATTERN_STARS := 2
const PATTERN_METAL := 3

const SKIN_TONES := {
	&"classic": Color("f5cd30"),   # the blocky avatar's yellow (realistic: the texture's own tone)
	&"light": Color("f6dccb"),
	&"peach": Color("eab48f"),
	&"tan": Color("c98d5e"),
	&"brown": Color("8d5a3b"),
	&"deep": Color("5a3825"),
	&"mint": Color("8fe3b0"),
	&"sky": Color("8cc8ff"),
}
const HAIR_COLORS := {
	&"brown": Color("5a3a22"),
	&"black": Color("241e1b"),
	&"blond": Color("e8c15a"),
	&"red": Color("b8452a"),
	&"white": Color("e6e2da"),
	&"pink": Color("ff8fc8"),
	&"blue": Color("4a8cff"),
	&"green": Color("3fbf5a"),
	&"purple": Color("8e5bd6"),     # Owner 48
	&"platinum": Color("f3e5b5"),   # Owner 48: a light blonde
}
## Shirt and pants colours (16).
const CLOTH := {
	&"blue": Color("0d69ac"),      # the classic torso
	&"jeans": Color("33406b"),     # the classic legs
	&"red": Color("e53935"),
	&"orange": Color("fb8c00"),
	&"yellow": Color("fdd835"),
	&"lime": Color("9ccc65"),
	&"green": Color("2e9d4a"),
	&"teal": Color("00a3a3"),
	&"sky": Color("5ec3ff"),
	&"purple": Color("8e44c9"),
	&"pink": Color("f06bb0"),
	&"white": Color("f2f2f2"),
	&"grey": Color("8a8f98"),
	&"black": Color("26272b"),
	&"brown": Color("7a4e2d"),
	&"gold": Color("e0b43a"),
	&"lilac": Color("b99ae8"),      # Owner 48: colours children like
	&"mint": Color("7fdcc0"),
	&"rose": Color("f9a8c9"),
}

## "<slot>.<name>" -> {name, kind, price (GOLD), earn (ACHIEVEMENT/BOSS/SECRET), dance (emotes)}.
## Prices are fixed and round; wave gold is 10 x N and the Golem pays 300 (§12.7-12.9), so a crown
## is a few good nights. Every slot's &"none" is free and not listed.
const ITEMS := {
	# Faces (the blocky face; the realistic face keeps the texture's, "cool" adds sunglasses)
	"face.smile": {"name": "Smile", "kind": FREE},
	"face.grin": {"name": "Grin", "kind": FREE},
	"face.wink": {"name": "Wink", "kind": FREE},
	"face.wow": {"name": "Wow", "kind": FREE},
	"face.sleepy": {"name": "Sleepy", "kind": FREE},
	"face.cool": {"name": "Cool", "kind": GOLD, "price": 60},
	# Hair styles: always free
	"hair.short": {"name": "Short", "kind": FREE},
	"hair.spiky": {"name": "Spiky", "kind": FREE},
	"hair.long": {"name": "Long", "kind": FREE},
	"hair.bun": {"name": "Bun", "kind": FREE},
	"hair.curly": {"name": "Curly", "kind": FREE},
	# Hats
	"hat.cap": {"name": "Cap", "kind": FREE},
	"hat.beanie": {"name": "Beanie", "kind": FREE},
	"hat.flower": {"name": "Flower", "kind": GOLD, "price": 60},
	"hat.party": {"name": "Party Hat", "kind": GOLD, "price": 80},
	"hat.cowboy": {"name": "Cowboy Hat", "kind": GOLD, "price": 150},
	"hat.top_hat": {"name": "Top Hat", "kind": GOLD, "price": 200},
	"hat.crown": {"name": "Crown", "kind": GOLD, "price": 400},
	"hat.pip_cap": {"name": "Pip's Cap", "kind": ACHIEVEMENT, "earn": EARN_TUTORIAL},
	"hat.golem_helm": {"name": "Rock Helmet", "kind": BOSS, "earn": EARN_GOLEM},
	# Capes
	"cape.hero": {"name": "Hero Cape", "kind": FREE},
	"cape.leaf": {"name": "Leaf Cape", "kind": GOLD, "price": 150},
	"cape.night": {"name": "Night Cape", "kind": GOLD, "price": 250},
	"cape.royal": {"name": "Royal Cape", "kind": GOLD, "price": 400},
	# Wings
	"wings.butterfly": {"name": "Butterfly", "kind": GOLD, "price": 250},
	"wings.bat": {"name": "Bat Wings", "kind": GOLD, "price": 300},
	"wings.angel": {"name": "Angel Wings", "kind": GOLD, "price": 450},
	"wings.dragon": {"name": "Dragon Wings", "kind": GOLD, "price": 600},
	"wings.fairy": {"name": "Fairy Wings", "kind": SECRET, "earn": EARN_SECRET_PAGE},
	# Running trails
	"trail.sparkles": {"name": "Sparkles", "kind": FREE},
	"trail.bubbles": {"name": "Bubbles", "kind": GOLD, "price": 80},
	"trail.hearts": {"name": "Hearts", "kind": GOLD, "price": 80},
	"trail.stars": {"name": "Stars", "kind": GOLD, "price": 150},
	"trail.rainbow": {"name": "Rainbow", "kind": GOLD, "price": 300},
	"trail.confetti": {"name": "Confetti", "kind": CODE},
	# Full outfits (skins) of our own design
	"outfit.candy": {"name": "Candy", "kind": GOLD, "price": 500},
	"outfit.ninja": {"name": "Ninja", "kind": GOLD, "price": 600},
	"outfit.pirate": {"name": "Pirate", "kind": GOLD, "price": 600},
	"outfit.knight": {"name": "Knight", "kind": GOLD, "price": 800},
	"outfit.robot": {"name": "Robot", "kind": GOLD, "price": 800},
	"outfit.dino": {"name": "Dino Suit", "kind": GOLD, "price": 900},
	"outfit.astronaut": {"name": "Astronaut", "kind": GOLD, "price": 1000},
	"outfit.cosmic": {"name": "Cosmic", "kind": BOSS, "earn": EARN_CAKE_MONSTER},
	# Emotes and dances: the free base set fills the whole wheel (§5.9, research X4)
	"emote.wave": {"name": "Wave", "kind": FREE},
	"emote.cheer": {"name": "Cheer", "kind": FREE},
	"emote.laugh": {"name": "Laugh", "kind": FREE},
	"emote.thumbs_up": {"name": "Thumbs Up", "kind": FREE},
	"emote.clap": {"name": "Clap", "kind": FREE},
	"emote.sit": {"name": "Sit", "kind": FREE},
	"emote.dance_hop": {"name": "Bunny Hop", "kind": FREE, "dance": true},
	"emote.dance_robot": {"name": "Robot", "kind": FREE, "dance": true},
	"emote.dance_star": {"name": "Star Spin", "kind": GOLD, "price": 200, "dance": true},
	"emote.bow": {"name": "Take a Bow", "kind": GOLD, "price": 60},   # M3 Task 21a: not the weapon ("Bow") in Georgian
	"emote.victory": {"name": "Victory", "kind": ACHIEVEMENT, "earn": EARN_FIRST_VICTORY, "dance": true},
	"emote.think": {"name": "Think", "kind": FREE},      # owner #94
	"emote.yawn": {"name": "Yawn", "kind": FREE},        # owner #94
	"emote.stretch": {"name": "Stretch", "kind": FREE},  # owner #94
	# --- Owner 35 (spec §18.3-18.4): only in what a grown-up buys (ShopCatalog). EasyCraft Plus's set:
	"outfit.frost_ranger": {"name": "Frost Ranger", "kind": PACK, "pack": "plus"},
	"hat.explorer": {"name": "Explorer Hat", "kind": PACK, "pack": "plus"},
	"cape.aurora": {"name": "Aurora Cape", "kind": PACK, "pack": "plus"},
	"trail.snowflakes": {"name": "Snowflakes", "kind": PACK, "pack": "plus"},
	# The Sky Pack:
	"wings.phoenix": {"name": "Phoenix Wings", "kind": PACK, "pack": "pack_sky"},
	"cape.cloud": {"name": "Cloud Cape", "kind": PACK, "pack": "pack_sky"},
	"trail.feathers": {"name": "Feathers", "kind": PACK, "pack": "pack_sky"},
	"hat.aviator": {"name": "Aviator Cap", "kind": PACK, "pack": "pack_sky"},
	# The Ocean Pack:
	"outfit.diver": {"name": "Deep Diver", "kind": PACK, "pack": "pack_ocean"},
	"cape.wave": {"name": "Wave Cape", "kind": PACK, "pack": "pack_ocean"},
	"trail.little_fish": {"name": "Little Fish", "kind": PACK, "pack": "pack_ocean"},
	"hat.captain": {"name": "Captain's Cap", "kind": PACK, "pack": "pack_ocean"},
	# --- Owner 48 (spec §14.6a): boy and girl looks, all FREE: a child's gender look is never for sale ---
	"face.sweet": {"name": "Sweet", "kind": FREE},
	"face.lovely": {"name": "Lovely", "kind": FREE},
	"face.rosy": {"name": "Rosy", "kind": FREE},
	"hair.bangs": {"name": "Long Bangs", "kind": FREE},
	"hair.ponytail": {"name": "Ponytail", "kind": FREE},
	"hair.pigtails": {"name": "Pigtails", "kind": FREE},
	"hair.braid": {"name": "Braid", "kind": FREE},
	"hair.buns": {"name": "Two Buns", "kind": FREE},
	"hair.bob": {"name": "Curly Bob", "kind": FREE},
	"hat.clips": {"name": "Hair Clips", "kind": FREE},
	"hat.flower_crown": {"name": "Flower Crown", "kind": FREE},
	"hat.bow": {"name": "Hair Bow", "kind": FREE},
	"clothes.dress": {"name": "Dress", "kind": FREE},
	"clothes.gown": {"name": "Princess Gown", "kind": FREE},
	"clothes.skirt": {"name": "Skirt", "kind": FREE},
	"clothes.leggings": {"name": "Leggings", "kind": FREE},
	"clothes.hoodie": {"name": "Hoodie", "kind": FREE},
	"clothes.overalls": {"name": "Overalls", "kind": FREE},
	"clothes.jacket": {"name": "Jacket", "kind": FREE},
	# --- M3 Task 21b: Secret Book page rewards (BookPages; the Fairy Wings above are the first page's) ---
	"hat.treasure_bandana": {"name": "Pirate Bandana", "kind": SECRET, "earn": EARN_TREASURE_PAGE},
	"cape.storybook": {"name": "Storybook Cape", "kind": ACHIEVEMENT, "earn": EARN_KEEPSAKE_PAGE},
	# --- Owner 36 (spec §14.6b): the Storybook costume pack. A costume "costume.<id>" (CostumeRules) is earned by
	# playing in one fixed way, never bought; earning it gives everything it wears. Its own new parts come only
	# with it (IN_COSTUME) and, once earned, mix with anything in their own tabs.
	"costume.alice": {"name": "Alice", "kind": ACHIEVEMENT, "earn": &"level/3"},
	"costume.dorothy": {"name": "Dorothy", "kind": ACHIEVEMENT, "earn": &"quest/tilly_pets"},
	"costume.pinocchio": {"name": "Pinocchio", "kind": ACHIEVEMENT, "earn": &"quest/tilly_map"},
	"costume.robin_hood": {"name": "Robin Hood", "kind": ACHIEVEMENT, "earn": &"title/explorer"},
	"costume.hatter": {"name": "Mad Hatter", "kind": ACHIEVEMENT, "earn": &"level/6"},
	"costume.tin_woodman": {"name": "Tin Woodman", "kind": ACHIEVEMENT, "earn": &"title/animals"},
	"costume.sherlock": {"name": "Sherlock Holmes", "kind": ACHIEVEMENT, "earn": &"title/hunter"},
	"costume.king_arthur": {"name": "King Arthur", "kind": BOSS, "earn": EARN_GOLEM},
	"costume.merlin": {"name": "Merlin", "kind": ACHIEVEMENT, "earn": &"title/magic"},
	"costume.aladdin": {"name": "Aladdin", "kind": ACHIEVEMENT, "earn": &"quest/zara_scarab"},
	"costume.hercules": {"name": "Hercules", "kind": BOSS, "earn": EARN_SERPENT},
	"costume.nemo": {"name": "Captain Nemo", "kind": ACHIEVEMENT, "earn": &"secret/sunken"},
	"costume.fairy": {"name": "Fairy", "kind": SECRET, "earn": EARN_SECRET_PAGE},
	"costume.wizard": {"name": "Little Wizard", "kind": ACHIEVEMENT, "earn": &"quest/tilly_star"},
	"costume.cube_hero": {"name": "Cube Hero", "kind": CODE},
	"costume.pirate": {"name": "Pirate Captain", "kind": ACHIEVEMENT, "earn": &"secret/cove"},
	"costume.knight": {"name": "Knight", "kind": ACHIEVEMENT, "earn": &"quest/zara_oasis"},
	"costume.ninja": {"name": "Ninja", "kind": ACHIEVEMENT, "earn": &"title/fighter"},
	"costume.astronaut": {"name": "Astronaut", "kind": ACHIEVEMENT, "earn": &"level/10"},
	"costume.robot": {"name": "Robot", "kind": ACHIEVEMENT, "earn": &"badge/big_builder"},
	"costume.dragon": {"name": "Dragon Suit", "kind": ACHIEVEMENT, "earn": &"count/buddy_ridden/fly"},
	# The pack's own parts
	"hat.alice_band": {"name": "Alice Band", "kind": IN_COSTUME, "costume": &"alice"},
	"hat.sunbonnet": {"name": "Sunbonnet", "kind": IN_COSTUME, "costume": &"dorothy"},
	"hat.puppet_cap": {"name": "Puppet Cap", "kind": IN_COSTUME, "costume": &"pinocchio"},
	"hat.feather_cap": {"name": "Feather Cap", "kind": IN_COSTUME, "costume": &"robin_hood"},
	"hat.hatter": {"name": "Hatter's Hat", "kind": IN_COSTUME, "costume": &"hatter"},
	"hat.deerstalker": {"name": "Deerstalker", "kind": IN_COSTUME, "costume": &"sherlock"},
	"hat.merlin_hat": {"name": "Merlin's Hat", "kind": IN_COSTUME, "costume": &"merlin"},
	"hat.turban": {"name": "Turban", "kind": IN_COSTUME, "costume": &"aladdin"},
	"hat.lion_hood": {"name": "Lion Hood", "kind": IN_COSTUME, "costume": &"hercules"},
	"hat.nautilus_cap": {"name": "Nautilus Cap", "kind": IN_COSTUME, "costume": &"nemo"},
	"hat.wizard_hat": {"name": "Wizard Hat", "kind": IN_COSTUME, "costume": &"wizard"},
	"hat.tricorn": {"name": "Tricorn", "kind": IN_COSTUME, "costume": &"pirate"},
	"face.long_nose": {"name": "Long Nose", "kind": IN_COSTUME, "costume": &"pinocchio"},
	"face.beard": {"name": "Wizard Beard", "kind": IN_COSTUME, "costume": &"merlin"},
	"clothes.pinafore": {"name": "Pinafore", "kind": IN_COSTUME, "costume": &"alice"},
	"clothes.gingham": {"name": "Gingham Dress", "kind": IN_COSTUME, "costume": &"dorothy"},
	"clothes.paper_suit": {"name": "Paper Suit", "kind": IN_COSTUME, "costume": &"pinocchio"},
	"clothes.archer": {"name": "Archer Tunic", "kind": IN_COSTUME, "costume": &"robin_hood"},
	"clothes.tailcoat": {"name": "Tailcoat", "kind": IN_COSTUME, "costume": &"hatter"},
	"clothes.inverness": {"name": "Detective Coat", "kind": IN_COSTUME, "costume": &"sherlock"},
	"clothes.tabard": {"name": "Royal Tabard", "kind": IN_COSTUME, "costume": &"king_arthur"},
	"clothes.robe": {"name": "Wizard Robe", "kind": IN_COSTUME, "costume": &"wizard"},
	"clothes.kaftan": {"name": "Kaftan", "kind": IN_COSTUME, "costume": &"aladdin"},
	"clothes.chiton": {"name": "Greek Tunic", "kind": IN_COSTUME, "costume": &"hercules"},
	"clothes.captain_coat": {"name": "Captain Coat", "kind": IN_COSTUME, "costume": &"pirate"},
	"clothes.hero_suit": {"name": "Hero Suit", "kind": IN_COSTUME, "costume": &"cube_hero"},
	"clothes.petal_dress": {"name": "Petal Dress", "kind": IN_COSTUME, "costume": &"fairy"},
	"cape.cube": {"name": "Cube Cape", "kind": IN_COSTUME, "costume": &"cube_hero"},
	"cape.parrot": {"name": "Parrot Pal", "kind": IN_COSTUME, "costume": &"pirate"},
	"trail.rocket": {"name": "Rocket", "kind": IN_COSTUME, "costume": &"astronaut"},
	"trail.smoke": {"name": "Smoke Puffs", "kind": IN_COSTUME, "costume": &"ninja"},
	"trail.sparks": {"name": "Sparks", "kind": IN_COSTUME, "costume": &"robot"},
	"outfit.tin_woodman": {"name": "Tin Woodman", "kind": IN_COSTUME, "costume": &"tin_woodman"},
	"outfit.dragon": {"name": "Dragon", "kind": IN_COSTUME, "costume": &"dragon"},
}

## Owner #94: a new wheel has Think where Thumbs Up was (wave, dance, cheer, think from MORE's EMOTE; a saved wheel keeps
## its own, and Thumbs Up is one tap away in the avatar editor).
const DEFAULT_WHEEL: Array[StringName] = [&"wave", &"cheer", &"laugh", &"think", &"clap", &"sit",
	&"dance_hop", &"dance_robot"]

## Full outfits: they set the clothes (colours, shoes, pattern) and the headgear, and add body parts
## (AvatarParts ids). Skin, hair colour, face, cape, wings and trail stay the child's own.
const OUTFITS := {
	&"knight": {"shirt": Color("9aa3ad"), "pants": Color("6b737c"), "shoes": Color("4a5058"), "hat": &"knight_helm",
		"pattern": PATTERN_METAL, "pattern_color": Color("c62828"), "extras": [&"knight_emblem"], "hides_hair": true},
	&"astronaut": {"shirt": Color("f2f4f7"), "pants": Color("e1e5ea"), "shoes": Color("8a93a0"), "hat": &"space_helm",
		"pattern": PATTERN_NONE, "pattern_color": Color("ff7043"), "extras": [&"space_pack", &"space_badge"], "hides_hair": true},
	&"dino": {"shirt": Color("4caf50"), "pants": Color("3d8c40"), "shoes": Color("2f6e32"), "hat": &"dino_hood",
		"pattern": PATTERN_NONE, "pattern_color": Color("ffb74d"), "extras": [&"dino_spikes", &"dino_tail"], "hides_hair": true},
	&"robot": {"shirt": Color("b8c0c8"), "pants": Color("7d8791"), "shoes": Color("55606a"), "hat": &"robot_head",
		"pattern": PATTERN_METAL, "pattern_color": Color("29b6f6"), "extras": [&"robot_panel"], "hides_hair": true},
	&"pirate": {"shirt": Color("f4f1ea"), "pants": Color("3e2c23"), "shoes": Color("1c1512"), "hat": &"pirate_hat",
		"pattern": PATTERN_STRIPES, "pattern_color": Color("c62828"), "extras": [&"pirate_stripes", &"eyepatch"], "hides_hair": false},
	&"ninja": {"shirt": Color("24262b"), "pants": Color("24262b"), "shoes": Color("141518"), "hat": &"ninja_mask",
		"pattern": PATTERN_NONE, "pattern_color": Color("d32f2f"), "extras": [&"ninja_belt"], "hides_hair": true},
	&"candy": {"shirt": Color("ff8fc8"), "pants": Color("7fe0c8"), "shoes": Color("ff5fa2"), "hat": &"candy_crown",
		"pattern": PATTERN_STRIPES, "pattern_color": Color("fff5fb"), "extras": [&"candy_stripes"], "hides_hair": false},
	&"cosmic": {"shirt": Color("2a1b5e"), "pants": Color("1a1240"), "shoes": Color("120c2c"), "hat": &"cosmic_halo",
		"pattern": PATTERN_STARS, "pattern_color": Color("ffe27a"), "extras": [&"cosmic_stars", &"cosmic_cape"], "hides_hair": false},
	# Owner 35: in what a grown-up buys (EasyCraft Plus; the Ocean Pack)
	&"frost_ranger": {"shirt": Color("e3f4ff"), "pants": Color("3f6f9f"), "shoes": Color("2c3e50"), "hat": &"frost_hood",
		"pattern": PATTERN_STRIPES, "pattern_color": Color("7fd3ff"), "extras": [&"frost_scarf"], "hides_hair": true},
	&"diver": {"shirt": Color("8d7b5a"), "pants": Color("6f6047"), "shoes": Color("3a3a3a"), "hat": &"diver_helm",
		"pattern": PATTERN_NONE, "pattern_color": Color("c9a227"), "extras": [&"diver_weights"], "hides_hair": true},
	# Owner 36 (spec §14.6b): the costume pack's own. "sleeves": tin (or scaly) arms, not bare ones.
	&"tin_woodman": {"shirt": Color("b9c1ca"), "pants": Color("a4adb8"), "shoes": Color("6f7a86"), "hat": &"funnel_hat",
		"pattern": PATTERN_METAL, "pattern_color": Color("e6ebf0"), "extras": [&"tin_heart", &"tin_rivets"], "hides_hair": true,
		"sleeves": true},
	&"dragon": {"shirt": Color("e0582a"), "pants": Color("c2441f"), "shoes": Color("7a2a14"), "hat": &"dragon_hood",
		"pattern": PATTERN_NONE, "pattern_color": Color("ffcc80"), "extras": [&"dino_spikes", &"dino_tail", &"dragon_belly"],
		"hides_hair": true, "sleeves": true},
}

# --- Owner 48 (spec §14.6a): boy and girl looks ------------------------------------------------------
# Stylised like a cartoon heroine, never grown-up: no body shaping, no make-up beyond cartoon eyelashes
# and rosy cheeks, clothes children wear to school or a party. Every part below is FREE for everyone.

## Light tights under a skirt.
const TIGHTS := Color("f4ede6")
const JACKET := Color("9a6a3f")      # the adventure jacket's soft brown
const BOOTS := Color("5d3a22")
const PARTY_SHOES := Color("5b3448")  # little strap shoes under a dress
const SNEAKERS := Color("f5f5f5")
## Owner 36: the costume pack's shoes and under-clothes.
const SILVER_SHOES := Color("c3cad4")   # Dorothy's silver shoes (Baum): never ruby slippers
const BLACK_SHOES := Color("2b2b2e")
const CHAINMAIL := Color("8d949c")
const STEEL := Color("5f6770")
const BARK := Color("6d4c2f")           # Pinocchio's shoes of tree bark (Collodi)
const SANDALS := Color("8d5a2b")
const SLIPPERS := Color("e0b43a")
const HERO_BOOTS := Color("f57c00")
const FAIRY_SHOES := Color("c38ad6")
## The CLOTHES slot's cuts, worn in the look's own colours: "top" is its shirt colour, "bottom" its pants
## colour. Keys (all optional): extras (AvatarParts ids without "extra_"), shirt (the torso's own colour
## when it isn't the top: the jacket), legs (the legs' colour when it isn't the bottom: tights), sleeves
## (long sleeves), puff (puffed short sleeves), shoes, boots. An outfit wins over a cut.
const CUTS := {
	&"dress": {"extras": [&"dress_skirt", &"dress_sash"], "puff": true, "shoes": PARTY_SHOES},
	&"gown": {"extras": [&"gown_skirt", &"gown_sash"], "puff": true, "shoes": PARTY_SHOES},
	&"skirt": {"extras": [&"skirt"], "legs": TIGHTS, "shoes": PARTY_SHOES},
	&"leggings": {"extras": [&"tunic"], "shoes": SNEAKERS},
	&"hoodie": {"extras": [&"hood", &"hoodie_pocket"], "sleeves": true, "shoes": SNEAKERS},
	&"overalls": {"extras": [&"overalls_bib"], "shoes": Color("7a4e2d")},
	&"jacket": {"extras": [&"jacket_front"], "shirt": JACKET, "sleeves": true, "shoes": BOOTS, "boots": true},
	# Owner 36 (spec §14.6b): the Storybook costume pack's cuts (they come with their costume: IN_COSTUME)
	&"pinafore": {"extras": [&"dress_skirt", &"pinafore_bib", &"pinafore_apron"], "puff": true, "shoes": BLACK_SHOES},
	&"gingham": {"extras": [&"dress_skirt", &"gingham_checks"], "puff": true, "shoes": SILVER_SHOES},
	&"paper_suit": {"extras": [&"paper_flowers"], "sleeves": true, "shoes": BARK, "boots": true},
	&"archer": {"extras": [&"archer_tunic", &"quiver"], "sleeves": true, "shoes": BOOTS, "boots": true},
	&"tailcoat": {"extras": [&"tailcoat_front", &"tailcoat_tails"], "sleeves": true, "shoes": BLACK_SHOES},
	&"inverness": {"extras": [&"coat_skirt", &"inverness_cape", &"magnifier"], "sleeves": true, "shoes": BLACK_SHOES},
	&"tabard": {"extras": [&"tabard", &"tabard_skirt"], "shirt": CHAINMAIL, "sleeves": true, "shoes": STEEL, "boots": true},
	&"robe": {"extras": [&"robe_skirt", &"robe_crest"], "sleeves": true, "shoes": BLACK_SHOES},
	&"kaftan": {"extras": [&"coat_skirt", &"kaftan_sash", &"lamp"], "sleeves": true, "shoes": SLIPPERS},
	&"chiton": {"extras": [&"chiton", &"chiton_drape"], "shoes": SANDALS},
	&"captain_coat": {"extras": [&"coat_skirt", &"captain_front", &"captain_hem"], "sleeves": true, "shoes": BLACK_SHOES,
		"boots": true},
	&"hero_suit": {"extras": [&"hero_emblem", &"hero_belt"], "sleeves": true, "shoes": HERO_BOOTS, "boots": true},
	&"petal_dress": {"extras": [&"petal_skirt"], "puff": true, "shoes": FAIRY_SHOES},
}
## Faces with cartoon eyelashes and rosy cheeks (the realistic face gets them in its skin shader).
const FACE_STYLES := {
	&"sweet": {"lashes": true, "blush": true},
	&"lovely": {"lashes": true, "blush": true},
	&"rosy": {"blush": true},
}
## Every part Owner 48 added: free, never for gold, never in a pack (tests scan the shop for them).
const GIRL_PARTS: Array[String] = ["face.sweet", "face.lovely", "face.rosy", "hair.bangs", "hair.ponytail",
	"hair.pigtails", "hair.braid", "hair.buns", "hair.bob", "hat.clips", "hat.flower_crown", "hat.bow",
	"clothes.dress", "clothes.gown", "clothes.skirt", "clothes.leggings", "clothes.hoodie", "clothes.overalls",
	"clothes.jacket"]

## The first choice (AvatarLook.base): a starting point, never a lock.
const BOY := &"boy"
const GIRL := &"girl"
const NEUTRAL := &"neutral"   # "Just me": the default look (owner #43's since 2026-09-25; every look saved before keeps its own, AvatarLook.classic())
const BASES: Array[StringName] = [BOY, GIRL, NEUTRAL]
## What each choice puts on (AvatarLook.start); the skin tone and the dance wheel stay the child's.
const STARTS := {
	BOY: {"hair": "short", "hair_color": "brown", "face": "smile", "shirt": "blue", "pants": "jeans"},
	GIRL: {"hair": "pigtails", "hair_color": "brown", "face": "sweet", "hat": "bow", "shirt": "pink",
		"pants": "lilac", "clothes": "skirt"},
	NEUTRAL: {},
}
## Ready-made looks, one tap each in the editor (AvatarLook.preset): free parts only.
const PRESETS := {
	&"adventurer": {"name": "Adventurer", "base": GIRL, "look": {"hair": "ponytail", "hair_color": "red",
		"face": "sweet", "hat": "clips", "shirt": "teal", "pants": "jeans", "clothes": "jacket"}},
	&"princess": {"name": "Princess of the Realms", "base": GIRL, "look": {"hair": "bangs", "hair_color": "blond",
		"face": "lovely", "hat": "flower_crown", "shirt": "rose", "pants": "white", "clothes": "gown"}},
	&"skater": {"name": "Skater", "base": BOY, "look": {"hair": "spiky", "hair_color": "black", "face": "grin",
		"hat": "cap", "shirt": "orange", "pants": "jeans", "clothes": "hoodie"}},
	&"hero": {"name": "Little Hero", "base": BOY, "look": {"hair": "short", "hair_color": "brown", "face": "smile",
		"shirt": "sky", "pants": "jeans", "cape": "hero"}},
}


# --- Owner 36 (spec §14.6b): the Storybook costume pack (CostumeRules has the costumes) ---------------------------

## A boss kind (BossRules) -> the avatar event its win earns in Survivor (the Golem's comes with its portal:
## Session.boss_apply_unlock). Frostpeak's giant has none: nothing is earned only behind a universe that is sold.
const BOSS_EARNS := {&"serpent": EARN_SERPENT, &"cake": EARN_CAKE_MONSTER}


## The presets, the ones of `base` first (every preset stays one tap away).
static func presets_for(base: StringName) -> Array[StringName]:
	var mine: Array[StringName] = []
	var rest: Array[StringName] = []
	for id: StringName in PRESETS:
		if PRESETS[id].base == base:
			mine.append(id)
		else:
			rest.append(id)
	mine.append_array(rest)
	return mine


static func item_id(slot: StringName, item_name: StringName) -> String:
	return "%s.%s" % [slot, item_name]


static func slot_of(id: String) -> StringName:
	return StringName(id.get_slice(".", 0))


static func name_of(id: String) -> StringName:
	return StringName(id.get_slice(".", 1)) if id.contains(".") else &""


## The names a slot can hold, "none" first where a slot can be empty (not the colour slots).
static func items_in(slot: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	match slot:
		SKIN:
			out.assign(SKIN_TONES.keys())
		HAIR_COLOR:
			out.assign(HAIR_COLORS.keys())
		SHIRT, PANTS:
			out.assign(CLOTH.keys())
		_:
			if slot in [HAIR, HAT, CAPE, WINGS, TRAIL, OUTFIT, CLOTHES]:
				out.append(&"none")
			var prefix := String(slot) + "."
			for id: String in ITEMS:
				if id.begins_with(prefix):
					out.append(name_of(id))
	return out


## Whether `item_name` is something `slot` can hold.
static func has_item(slot: StringName, item_name: Variant) -> bool:
	if typeof(item_name) != TYPE_STRING and typeof(item_name) != TYPE_STRING_NAME:
		return false
	return items_in(slot).has(StringName(item_name))


## Whether `id` names a real item (a colour, a hair style, a "none" or an ITEMS entry).
static func is_item(id: String) -> bool:
	if not id.contains("."):
		return false
	var slot := slot_of(id)
	return (SLOTS.has(slot) or slot == HAIR_COLOR or slot == COSTUME) and has_item(slot, name_of(id))   # Owner 36: costumes


## Free: colours, hair styles, every "none", and the free basic set.
static func is_free(id: String) -> bool:
	if not is_item(id):
		return false
	if not ITEMS.has(id):
		return true   # colours, hair colours and "none"
	return ITEMS[id].kind == FREE


## The fixed gold price (0 = not for gold: free or earned).
static func price(id: String) -> int:
	if not ITEMS.has(id) or ITEMS[id].kind != GOLD:
		return 0
	return int(ITEMS[id].get("price", 0))


static func is_dance(emote: StringName) -> bool:
	return bool(ITEMS.get(item_id(EMOTE, emote), {}).get("dance", false))


## §13.2 rarity: earned-by-boss items are legendary (never bought); gold items by price.
static func rarity(id: String) -> StringName:
	var item: Dictionary = ITEMS.get(id, {})
	match item.get("kind", FREE):
		BOSS:
			return LEGENDARY
		ACHIEVEMENT, SECRET, CODE:
			return EPIC
		PACK:
			return RARE   # a grown-up's gift never outranks what is earned (Owner 35)
		IN_COSTUME:
			return rarity(item_id(COSTUME, item.get("costume", &"")))   # Owner 36: as rare as its costume
		GOLD:
			var p := int(item.get("price", 0))
			if p <= 100:
				return UNCOMMON
			return RARE if p <= 400 else EPIC
	return COMMON


## The short name under an item's icon ("Crown"); colours are shown as swatches, named by their id.
static func display_name(id: String) -> String:
	if id == "clothes.none":
		return "Classic"   # Owner 48: no cut is still clothes (the tee and pants)
	if ITEMS.has(id):
		return str(ITEMS[id].name)
	return String(name_of(id)).capitalize()
