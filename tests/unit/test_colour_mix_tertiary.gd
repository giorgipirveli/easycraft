extends GutTest
## Grade 4 art (research §6.4, "The colour wheel", "Light and shade"): the paint bowl ("mix the colour", ColourMix) also
## makes the six tertiary colours of the painters' wheel, each twice as much of the primary it is named after as of the
## other (red-orange: 2 red and 1 yellow), and the greys of a tone scale (light grey: 2 white and 1 black; dark grey: 1
## white and 2 black). Shares count, not drops, as for every recipe.

const TERTIARY := {"red-orange": {"red": 2, "yellow": 1}, "yellow-orange": {"yellow": 2, "red": 1},
	"yellow-green": {"yellow": 2, "blue": 1}, "blue-green": {"blue": 2, "yellow": 1},
	"blue-purple": {"blue": 2, "red": 1}, "red-purple": {"red": 2, "blue": 1}}
const GREYS := {"light grey": {"white": 2, "black": 1}, "grey": {"white": 1, "black": 1},
	"dark grey": {"white": 1, "black": 2}}


func test_the_tertiary_colours_are_two_of_a_primary_and_one_of_its_neighbour() -> void:
	for target: String in TERTIARY:
		var ex := {"type": "mix", "prompt": "Make %s." % target, "hint": "Which primary is in its name?", "target": target}
		assert_eq(ExerciseCheck.problem(ex), "", target)
		var drops: Dictionary = TERTIARY[target]
		assert_true(ExerciseCheck.is_right(ex, drops), target)
		var twice := {}
		for p: String in drops:
			twice[p] = int(drops[p]) * 2
		assert_true(ExerciseCheck.is_right(ex, twice), "%s: the same shares" % target)
		var even := {}
		for p: String in drops:
			even[p] = 1
		assert_false(ExerciseCheck.is_right(ex, even), "%s: equal drops make the secondary" % target)
		assert_eq(ExerciseCheck.answer_of(ex), drops, target)


func test_a_tertiary_looks_between_its_primary_and_its_secondary() -> void:
	# hue round the RYB wheel: red-orange sits between red and orange, and so on (checked on the bowl's colours)
	var red := ColourMix.colour({"red": 1})
	var orange := ColourMix.colour({"red": 1, "yellow": 1})
	var red_orange := ColourMix.colour(TERTIARY["red-orange"])
	assert_between(red_orange.h, minf(red.h, orange.h), maxf(red.h, orange.h) + 0.001, "red-orange: between red and orange")
	var yellow := ColourMix.colour({"yellow": 1})
	var yellow_orange := ColourMix.colour(TERTIARY["yellow-orange"])
	assert_between(yellow_orange.h, orange.h, yellow.h, "yellow-orange: between orange and yellow")
	var green := ColourMix.colour({"yellow": 1, "blue": 1})
	var blue := ColourMix.colour({"blue": 1})
	assert_between(ColourMix.colour(TERTIARY["yellow-green"]).h, yellow.h, green.h, "yellow-green: between yellow and green")
	assert_between(ColourMix.colour(TERTIARY["blue-green"]).h, green.h, blue.h, "blue-green: between green and blue")


func test_the_greys_of_a_tone_scale_get_darker() -> void:
	var last := 2.0
	for target: String in ["light grey", "grey", "dark grey"]:
		var ex := {"type": "mix", "prompt": "Make %s." % target, "hint": "White and black.", "target": target}
		assert_eq(ExerciseCheck.problem(ex), "", target)
		assert_true(ExerciseCheck.is_right(ex, GREYS[target]), target)
		var lum := ColourMix.colour(GREYS[target]).get_luminance()
		assert_lt(lum, last, "%s is darker than the one before" % target)
		last = lum
	assert_false(ExerciseCheck.is_right({"type": "mix", "prompt": "p", "hint": "h", "target": "light grey"},
		{"white": 1, "black": 1}), "equal drops are grey, not light grey")
	assert_eq(ColourMix.words(GREYS["light grey"]), "2 white and 1 black")
