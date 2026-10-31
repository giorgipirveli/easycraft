class_name G4ScienceGen
extends RefCounted
## Owner #68 (spec §22.5): grade 4 science generators (NGSS 4-ESS1-1, "Rock layers and fossils"): SchoolGen "g4s.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data`. The rock layers are drawn with the game's own blocks.

const K := preload("res://core/school/gen/gen_kit.gd")
## Stone, deep stone, sandstone, cut sandstone, sand and dirt: layers of a cliff.
const LAYER_BLOCKS: Array[int] = [3, 17, 64, 65, 4, 2]
const FOSSILS: Array[String] = ["shell", "fish", "leaf", "bone", "footprint"]


## "Which fossil is older?" (two fossils in different layers)
static func older_fossil(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var blocks := _layers(rng, level)
	var kinds: Array = FOSSILS.duplicate()
	K.shuffle(rng, kinds)
	var low := rng.randi_range(0, blocks.size() - 2)
	var high := rng.randi_range(low + 1, blocks.size() - 1)
	var older: String = kinds[0]
	var younger: String = kinds[1]
	var ex := K.choice(rng, "Which fossil is older?", "the " + older, ["the " + younger, "They are the same age"],
		"The deeper the layer, the older it is.",
		"The %s is in a lower layer, which formed first, so it is older than the %s." % [older, younger],
		{"kind": "layers", "blocks": blocks, "fossils": {str(low): older, str(high): younger}})
	ex.data = {"low": low, "high": high}
	return ex


## "Each layer took about 1,000 years to form. How many years did all the layers take?"
static func layer_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var blocks := _layers(rng, level)
	var years: int = [[100, 500, 1000], [1000, 2000, 5000], [5000, 10000, 20000]][level - 1][rng.randi_range(0, 2)]
	var n := blocks.size()
	var ex := K.number("Each layer of this cliff took about %s years to form. How many years did all the layers take?" % K.fmt(years),
		n * years, "Count the layers, then multiply by %s." % K.fmt(years),
		"%d layers × %s years = %s years." % [n, K.fmt(years), K.fmt(n * years)], {"kind": "layers", "blocks": blocks})
	ex.data = {"years": years}
	return ex


## "Which layer is the youngest?" / "…the oldest?"
static func layer_age(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var blocks := _layers(rng, level)
	var youngest := rng.randf() < 0.5
	var right := "the top layer" if youngest else "the bottom layer"
	var ex := K.choice(rng, "Which layer of this cliff is the %s?" % ("youngest" if youngest else "oldest"), right,
		["the top layer", "the bottom layer", "the middle layer"].filter(func(x: String) -> bool: return x != right),
		"Layers settle one on top of another. Which came first, and which came last?",
		"The %s layer was laid down %s, so it is the %s." % ["top" if youngest else "bottom", "last" if youngest else "first",
			"youngest" if youngest else "oldest"], {"kind": "layers", "blocks": blocks})
	ex.data = {"youngest": youngest}
	return ex


## 4, 5 or 6 layers (by level), bottom first, no two alike next to each other.
static func _layers(rng: RandomNumberGenerator, level: int) -> Array:
	var out: Array = []
	for i in 3 + level:
		var b: int = LAYER_BLOCKS[rng.randi_range(0, LAYER_BLOCKS.size() - 1)]
		while not out.is_empty() and out.back() == b:
			b = LAYER_BLOCKS[rng.randi_range(0, LAYER_BLOCKS.size() - 1)]
		out.append(b)
	return out
