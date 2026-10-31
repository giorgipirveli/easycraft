class_name LifeKitchen
extends RefCounted
## Owner #112 (docs/design/life-skills.md §5 #5, The Kitchen: "recipes from many countries"): each track's recipes and
## what a run cuts, pours and weighs, varied by the run's seed (a repeat comes back a little different; the steps stay
## the same). Little cooks without heat (a grown-up near); Middle with the hob and a grown-up; Big with the oven, the
## kettle and a week's meals on a budget. The cup's amounts read as fractions (the School's maths: a quarter, a half,
## three quarters); the scales' in grams.

## track -> [{recipe, from, cut, pour, weigh, grams}]
const RECIPES := {
	"little": [
		{"recipe": "a rainbow fruit salad", "from": "fruit from all over the world", "cut": "a banana",
			"pour": "yoghurt", "weigh": "grapes", "grams": 100},
		{"recipe": "raita", "from": "India", "cut": "a cucumber", "pour": "yoghurt", "weigh": "cucumber", "grams": 150},
		{"recipe": "Bircher muesli", "from": "Switzerland", "cut": "a banana", "pour": "milk", "weigh": "oats",
			"grams": 50},
		{"recipe": "a cucumber and tomato salad", "from": "Georgia", "cut": "a cucumber", "pour": "water",
			"weigh": "tomatoes", "grams": 200},
	],
	"middle": [
		{"recipe": "pancakes", "from": "the UK and France", "cut": "a strawberry", "pour": "milk", "weigh": "flour",
			"grams": 100},
		{"recipe": "an omelette", "from": "France", "cut": "a mushroom", "pour": "milk", "weigh": "cheese", "grams": 50},
		{"recipe": "fried rice", "from": "China", "cut": "a spring onion", "pour": "water", "weigh": "rice",
			"grams": 150},
		{"recipe": "porridge", "from": "Scotland", "cut": "an apple", "pour": "milk", "weigh": "oats", "grams": 50},
	],
	"big": [
		{"recipe": "lentil dal", "from": "India", "cut": "an onion", "pour": "water", "weigh": "red lentils",
			"grams": 200},
		{"recipe": "shakshuka", "from": "Tunisia", "cut": "a pepper", "pour": "water", "weigh": "tomatoes",
			"grams": 400},
		{"recipe": "jollof rice", "from": "West Africa", "cut": "an onion", "pour": "water", "weigh": "rice",
			"grams": 200},
		{"recipe": "pasta with tomato sauce", "from": "Italy", "cut": "an onion", "pour": "water", "weigh": "pasta",
			"grams": 100},
	],
}
## The cup's amounts (a measuring cup's marks).
const CUPS: Array[float] = [0.25, 0.5, 0.75]


static func recipes(track: String) -> Array:
	return RECIPES.get(track, RECIPES.little)


## A run's kitchen words: {recipe, recipe_from, cut_food, pour_what, pour_want, pour_words, weigh_what, weigh_g}.
static func vars(track: String, seed: int) -> Dictionary:
	var list := recipes(track)
	var r: Dictionary = list[posmod(seed, list.size())]
	var want: float = CUPS[posmod(hash([seed, "cup"]), CUPS.size())]
	return {"recipe": r.recipe, "recipe_from": r.from, "cut_food": r.cut, "pour_what": r.pour, "pour_want": want,
		"pour_words": cup_words(want), "weigh_what": r.weigh, "weigh_g": int(r.grams)}


static func cup_words(amount: float) -> String:
	if is_equal_approx(amount, 0.25):
		return "a quarter of a cup (1/4)"
	if is_equal_approx(amount, 0.75):
		return "three quarters of a cup (3/4)"
	if is_equal_approx(amount, 1.0):
		return "a whole cup"
	return "half a cup (1/2)"
