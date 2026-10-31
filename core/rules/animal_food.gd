class_name AnimalFood
extends RefCounted
## What each kind of animal eats (owner feedback #41, spec §14.19), as a pure table. A tap on an animal while
## holding its food feeds it: it likes that child more (M2 Task 18's mind learns it). Blocks are fed from the
## hand and never used up (as M2 Task 18's grass and leaves); treats (items 430-434) go through the pets' path
## (PetDirector: Survivor pays one; two tame a fox, a horse, a camel, a donkey, a fennec or an arctic fox).
## M1b's and M3 Task 11's animals keep grass and leaves (every animal liked plants before).

const PLANTS: Array[int] = [BlockIds.GRASS, BlockIds.LEAVES]

const FOOD := {
	&"dog": PLANTS, &"cat": PLANTS, &"pig": PLANTS, &"cow": PLANTS, &"sheep": PLANTS, &"chicken": PLANTS,
	&"rabbit": PLANTS, &"fox": [BlockIds.GRASS, BlockIds.LEAVES, ItemIds.TREAT_BERRIES],
	&"parrot": [BlockIds.GRASS, BlockIds.LEAVES, ItemIds.TREAT_SEEDS],
	&"fish": [ItemIds.TREAT_SEEDS], &"pip": [ItemIds.TREAT_BOLT],
	&"dragon": [ItemIds.TREAT_FISH],   # owner #39: the pet dragon's fish snack (PetRules' favourite)
	# owner #41: Green Meadows
	&"horse": [BlockIds.GRASS, BlockIds.LEAVES, ItemIds.TREAT_BERRIES, ItemIds.TREAT_SEEDS],
	&"donkey": [BlockIds.GRASS, BlockIds.LEAVES, ItemIds.TREAT_BERRIES, ItemIds.TREAT_SEEDS],
	&"goat": [BlockIds.GRASS, BlockIds.LEAVES, BlockIds.BUSH],
	&"deer": [BlockIds.GRASS, BlockIds.LEAVES, ItemIds.TREAT_BERRIES],
	&"duck": [BlockIds.GRASS, ItemIds.TREAT_SEEDS],
	&"frog": [ItemIds.TREAT_SEEDS],
	&"turtle": [BlockIds.LEAVES, ItemIds.TREAT_BERRIES],
	&"squirrel": [ItemIds.TREAT_SEEDS, ItemIds.TREAT_BERRIES],
	&"owl": [ItemIds.TREAT_SEEDS],
	&"hedgehog": [ItemIds.TREAT_BERRIES, BlockIds.LEAVES],
	# the Sandstorm Desert: camels eat the thorny plants
	&"camel": [BlockIds.DEAD_BUSH, BlockIds.CACTUS, BlockIds.PALM_LEAVES, BlockIds.GRASS, ItemIds.TREAT_SEEDS,
		ItemIds.TREAT_BERRIES],
	&"lizard": [ItemIds.TREAT_SEEDS],
	&"fennec": [ItemIds.TREAT_BERRIES, ItemIds.TREAT_SEEDS],
	# Frostpeak: the sea animals love fish
	&"penguin": [ItemIds.TREAT_FISH],
	&"seal": [ItemIds.TREAT_FISH],
	&"polar_bear": [ItemIds.TREAT_FISH, ItemIds.TREAT_BERRIES],
	&"arctic_fox": [ItemIds.TREAT_BERRIES, ItemIds.TREAT_FISH],
	# the Candy Kingdom
	&"gummy_bunny": [BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.COTTON_CANDY],
	&"candy_bird": [BlockIds.SPRINKLES, ItemIds.TREAT_SEEDS],
	&"moon_bunny": [BlockIds.MOON_CHEESE, BlockIds.MOON_CRYSTAL, ItemIds.TREAT_SEEDS],   # owner #55: cheese!
	# M3 Task 20b: a befriended monster likes berries best, a boss's mini-buddy a shiny bolt (like Pip)
	&"monster_friend": [ItemIds.TREAT_BERRIES, ItemIds.TREAT_SEEDS],
	&"mini_boss": [ItemIds.TREAT_BOLT],
}


static func foods(species: StringName) -> Array:
	return FOOD.get(species, [])


static func eats(species: StringName, item: int) -> bool:
	return foods(species).has(item)


## A block the child holds that feeds this animal from the hand (not a treat item).
static func is_block_food(species: StringName, item: int) -> bool:
	return eats(species, item) and not PetRules.is_treat(item)
