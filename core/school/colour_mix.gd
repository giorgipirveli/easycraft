class_name ColourMix
extends RefCounted
## The research's "mix the colour" (docs/design/school-curriculum-research.md §5.3; art: colour mixing). Paint as
## children mix it: the painters' primaries red, yellow and blue, and white and black. A colour is made when the drops'
## shares match its recipe (2 red + 2 yellow is orange like 1 + 1). The bowl's look: the drops mixed in the RYB colour
## cube (Gossett and Chen's corners), then lightened by the white's share and darkened by the black's.

const PAINTS: Array[String] = ["red", "yellow", "blue", "white", "black"]
const PAINT_COLOURS := {"red": Color("d8262e"), "yellow": Color("f7d117"), "blue": Color("2a5fc4"),
	"white": Color("f7f5ef"), "black": Color("22211f")}
const MAX_DROPS := 12
## Every colour an exercise may ask for, and its recipe (the fewest drops).
const RECIPES := {
	"red": {"red": 1}, "yellow": {"yellow": 1}, "blue": {"blue": 1},
	"orange": {"red": 1, "yellow": 1}, "green": {"yellow": 1, "blue": 1}, "purple": {"red": 1, "blue": 1},
	"brown": {"red": 1, "yellow": 1, "blue": 1},
	"pink": {"red": 1, "white": 1}, "light blue": {"blue": 1, "white": 1}, "light green": {"yellow": 1, "blue": 1, "white": 1},
	"lilac": {"red": 1, "blue": 1, "white": 1}, "cream": {"yellow": 1, "white": 1},
	"dark red": {"red": 1, "black": 1}, "dark blue": {"blue": 1, "black": 1},
	"dark green": {"yellow": 1, "blue": 1, "black": 1}, "grey": {"white": 1, "black": 1},
	# grade 4 art (the colour wheel): the tertiary colours, twice as much of the primary they are named after
	"red-orange": {"red": 2, "yellow": 1}, "yellow-orange": {"yellow": 2, "red": 1},
	"yellow-green": {"yellow": 2, "blue": 1}, "blue-green": {"blue": 2, "yellow": 1},
	"blue-purple": {"blue": 2, "red": 1}, "red-purple": {"red": 2, "blue": 1},
	# grade 4 art (light and shade): the greys of a tone scale
	"light grey": {"white": 2, "black": 1}, "dark grey": {"white": 1, "black": 2},
}
## The RYB cube's corners (r, y, b each 0 or 1) as screen colours.
const _CORNERS := {
	Vector3i(0, 0, 0): Color(1, 1, 1), Vector3i(1, 0, 0): Color(1, 0, 0), Vector3i(0, 1, 0): Color(1, 1, 0),
	Vector3i(0, 0, 1): Color(0.163, 0.373, 0.6), Vector3i(1, 1, 0): Color(1, 0.5, 0), Vector3i(1, 0, 1): Color(0.5, 0, 0.5),
	Vector3i(0, 1, 1): Color(0, 0.66, 0.2), Vector3i(1, 1, 1): Color(0.2, 0.094, 0),
}


## Drops (paint -> count) with only the paints used, or {} when something is odd.
static func clean(drops: Variant) -> Dictionary:
	if not drops is Dictionary:
		return {}
	var out := {}
	for k: Variant in drops:
		var n: Variant = drops[k]
		if not PAINTS.has(str(k)) or typeof(n) not in [TYPE_INT, TYPE_FLOAT] or float(n) != floorf(float(n)) or int(n) < 0:
			return {}
		if int(n) > 0:
			out[str(k)] = int(n)
	return out


## The drops make `target`: the same paints, in the recipe's shares.
static func matches(target: String, drops: Variant) -> bool:
	var recipe: Dictionary = RECIPES.get(target, {})
	var d := clean(drops)
	if recipe.is_empty() or d.is_empty() or d.size() != recipe.size():
		return false
	var times := -1.0
	for k: String in recipe:
		if not d.has(k):
			return false
		var t := float(d[k]) / float(recipe[k])
		if times < 0.0:
			times = t
		elif not is_equal_approx(t, times):
			return false
	return true


## How the bowl looks.
static func colour(drops: Variant) -> Color:
	var d := clean(drops)
	var total := 0
	for k: String in d:
		total += int(d[k])
	if total == 0:
		return Color(0.93, 0.93, 0.9)
	var ryb := Vector3(d.get("red", 0), d.get("yellow", 0), d.get("blue", 0))
	var top := maxf(ryb.x, maxf(ryb.y, ryb.z))
	var c := Color(1, 1, 1)
	if top > 0.0:
		c = _ryb(ryb / top)
	var white := float(d.get("white", 0)) / total
	var black := float(d.get("black", 0)) / total
	if top == 0.0:   # only white and black: a grey
		return Color(1, 1, 1).lerp(Color(0.13, 0.13, 0.12), black / maxf(white + black, 0.001))
	return c.lerp(Color(1, 1, 1), white).lerp(Color(0.13, 0.13, 0.12), black)


static func _ryb(v: Vector3) -> Color:
	var out := Color(0, 0, 0, 1)
	for corner: Vector3i in _CORNERS:
		var w := (v.x if corner.x == 1 else 1.0 - v.x) * (v.y if corner.y == 1 else 1.0 - v.y) \
			* (v.z if corner.z == 1 else 1.0 - v.z)
		var col: Color = _CORNERS[corner]
		out.r += col.r * w
		out.g += col.g * w
		out.b += col.b * w
	return out


## "1 red and 1 yellow".
static func words(drops: Dictionary) -> String:
	var parts: Array[String] = []
	for p in PAINTS:
		if int(drops.get(p, 0)) > 0:
			parts.append("%d %s" % [int(drops[p]), p])
	if parts.size() <= 1:
		return "".join(parts)
	return ", ".join(parts.slice(0, parts.size() - 1)) + " and " + parts.back()
