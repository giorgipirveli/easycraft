class_name LabColours
extends LabModel
## Mixing colours (spec §23.1): PAINT drops red, yellow and blue into a bowl (the School's ColourMix: its recipes name a
## mix, its RYB colours paint the bowl) and LIGHT shines red, green and blue torches on a dark wall, where light adds
## (red + green = yellow, all three = white). Done once the scene's paint goals (orange, green, brown) and light goals
## (yellow, white) were all made.

## The light primaries as screen colours (additive: a sum, each channel at most 1).
const LIGHTS := {"red": Color(1, 0, 0), "green": Color(0, 1, 0), "blue": Color(0, 0, 1)}
## Names of the light mixes (the lit torches' names, sorted, joined by "+").
const LIGHT_NAMES := {"green+red": "yellow", "blue+red": "magenta", "blue+green": "cyan", "blue+green+red": "white"}

var paints: Array[String] = []
var light_list: Array[String] = []
var drops := {}                 # paint -> drops in the bowl
var lights: Array[bool] = []    # which torches are on (light_list's order)
var found_paint := {}           # mixes of two or more paints made (a ColourMix recipe name) -> true
var found_light := {}           # mixes of two or more lights made -> true


func _init(s: Dictionary = {}) -> void:
	super(s)
	for p: Variant in s.get("paints", []):
		paints.append(str(p))
	for l: Variant in s.get("lights", []):
		light_list.append(str(l))
		lights.append(false)


## One more drop of paint `p` (the bowl holds ColourMix.MAX_DROPS).
func add_paint(p: String) -> void:
	if not paints.has(p):
		return
	var total := 0
	for k: String in drops:
		total += int(drops[k])
	if total >= ColourMix.MAX_DROPS:
		last = "The bowl is full: tap CLEAN to start again."
		return
	drops[p] = int(drops.get(p, 0)) + 1
	var name := paint_name()
	if name != "" and drops.size() >= 2:
		found_paint[name] = true
		last = "%s make %s!" % [LabModel.sentence(_and(drops.keys())), name]
	elif name != "":
		last = "%s paint in the bowl." % LabModel.sentence(name)
	else:
		last = "A new colour! Tap CLEAN to try another mix."


func clean() -> void:
	drops.clear()
	last = "The bowl is clean."


## The mix's name when the drops match a recipe the scene's paints make ("orange"), else "".
func paint_name() -> String:
	if drops.is_empty():
		return ""
	for name: String in ColourMix.RECIPES:
		if ColourMix.matches(name, drops):
			return name
	return ""


func toggle_light(i: int) -> void:
	if i < 0 or i >= lights.size():
		return
	lights[i] = not lights[i]
	var on := lit_names()
	if on.size() >= 2:
		var name := light_name(on)
		found_light[name] = true
		last = "%s light make %s!" % [LabModel.sentence(_and(on)), name]
	elif on.size() == 1:
		last = "%s light on the wall." % LabModel.sentence(on[0])
	else:
		last = "The torches are off."


## The torches that are on, in the scene's order.
func lit_names() -> Array[String]:
	var out: Array[String] = []
	for i in lights.size():
		if lights[i]:
			out.append(light_list[i])
	return out


func done() -> bool:
	for g: Variant in scene.get("paint_goals", []):
		if not found_paint.has(str(g)):
			return false
	for g: Variant in scene.get("light_goals", []):
		if not found_light.has(str(g)):
			return false
	return true


## What lights `names` make together: a primary's own name, or a mix's ("yellow", "white").
static func light_name(names: Array) -> String:
	var sorted: Array[String] = []
	for n: Variant in names:
		if not sorted.has(str(n)):
			sorted.append(str(n))
	sorted.sort()
	if sorted.size() == 1:
		return sorted[0]
	return str(LIGHT_NAMES.get("+".join(sorted), ""))


## The colour where lights `names` overlap: their sum, each channel at most 1.
static func light_colour(names: Array) -> Color:
	var c := Color(0, 0, 0)
	for n: Variant in names:
		var l: Color = LIGHTS.get(str(n), Color(0, 0, 0))
		c = Color(minf(c.r + l.r, 1.0), minf(c.g + l.g, 1.0), minf(c.b + l.b, 1.0))
	return c


## "red and yellow", "red, yellow and blue".
static func _and(words: Array) -> String:
	var list: Array[String] = []
	for w: Variant in words:
		list.append(str(w))
	if list.size() <= 1:
		return "".join(list)
	return ", ".join(list.slice(0, list.size() - 1)) + " and " + list.back()
