class_name IdeaCards
extends RefCounted
## Idea cards (M3 Task 21b; research X5): picture cards with build ideas to flip through when a child doesn't
## know what to build. A card is a few words and one to three pictures: a ProgressPictures name, an animal kind
## (AnimalRules.SPECIES: drawn from its own box model) or a block or item id (its icon). No reward is ever
## attached to a card and nothing is timed (research §1.8: a reward for what children already love makes them
## love it less).

const CARDS: Array[Dictionary] = [
	{"id": &"dog_house", "words": "A house for your dog", "pictures": [&"house", &"dog"]},
	{"id": &"tall_tower", "words": "A tower as tall as a tree", "pictures": [ItemIds.STAMP_TOWER, ItemIds.STAMP_TREE]},
	{"id": &"four_legs", "words": "A buddy with four legs", "pictures": [&"wand", &"cow"]},
	{"id": &"river_bridge", "words": "A bridge over the river", "pictures": [ItemIds.STAMP_BRIDGE, BlockIds.WATER]},
	{"id": &"sky_road", "words": "A rainbow road in the sky", "pictures": [ItemIds.STAMP_RAINBOW, &"island"]},
	{"id": &"castle", "words": "A castle with a secret door", "pictures": [BlockIds.BRICK, &"key"]},
	{"id": &"tree_house", "words": "A tree house with a ladder", "pictures": [ItemIds.STAMP_TREE, &"house"]},
	{"id": &"cat_bed", "words": "A cosy bed for a cat", "pictures": [BlockIds.BED, &"cat"]},
	{"id": &"garden", "words": "A flower garden with a path", "pictures": [&"flower", BlockIds.GRASS]},
	{"id": &"lighthouse", "words": "A lighthouse by the sea", "pictures": [BlockIds.LIGHT, BlockIds.WATER]},
	{"id": &"snowman", "words": "A giant snowman", "pictures": [BlockIds.SNOW]},
	{"id": &"rocket", "words": "A rocket to fly to the stars", "pictures": [BlockIds.RED, &"star"]},
	{"id": &"maze", "words": "A maze for your friends", "pictures": [BlockIds.PLANKS, &"friends"]},
	{"id": &"dragon_buddy", "words": "A dragon buddy with big wings", "pictures": [&"wand", &"dragon"]},
	{"id": &"race_track", "words": "A race track with a finish line", "pictures": [&"flag", BlockIds.START]},
	{"id": &"hideout", "words": "A hideout for your treasure", "pictures": [&"chest", BlockIds.BARREL]},
	{"id": &"farm", "words": "A farm for cows and pigs", "pictures": [BlockIds.PLANKS, &"cow", &"pig"]},
	{"id": &"pool", "words": "A swimming pool with a slide", "pictures": [BlockIds.WATER, BlockIds.GLASS]},
	{"id": &"zoo", "words": "A zoo for all your animals", "pictures": [&"rabbit", &"sheep", &"chicken"]},
	{"id": &"candy_house", "words": "A house made of candy", "pictures": [&"cupcake", &"house"]},
	{"id": &"igloo", "words": "An igloo for a penguin", "pictures": [BlockIds.SNOW, &"penguin"]},
	{"id": &"boat", "words": "A boat to sail away", "pictures": [BlockIds.PLANKS, BlockIds.WATER]},
	{"id": &"statue", "words": "A statue of your best friend", "pictures": [&"friends", BlockIds.STONE]},
	{"id": &"golem_friend", "words": "A friendly stone golem buddy", "pictures": [&"golem", &"wand"]},
	{"id": &"playground", "words": "A playground with jump pads", "pictures": [BlockIds.JUMP_PAD, &"friends"]},
	{"id": &"fish_tank", "words": "A glass tank for fish", "pictures": [BlockIds.GLASS, &"fish"]},
	{"id": &"secret_room", "words": "A secret room behind a wall", "pictures": [&"room", BlockIds.STONE]},
	{"id": &"sky_island", "words": "A little house on a sky island", "pictures": [&"island", &"house"]},
]


static func count() -> int:
	return CARDS.size()


## Card i (any number: it wraps round).
static func card(i: int) -> Dictionary:
	return CARDS[posmod(i, CARDS.size())]


## The card `step` away from card i, round and round.
static func flip(i: int, step: int) -> int:
	return posmod(i + step, CARDS.size())


## Whether a card's picture can be drawn: a ProgressPictures name, an animal kind, or a block or item id.
static func picture_ok(p: Variant) -> bool:
	if p is StringName:
		return ProgressPictures.knows(p) or AnimalRules.SPECIES.has(p)
	if p is int:
		return BlockIds.is_valid(p) or ItemIds.ALL.has(p)
	return false
