class_name BuddyRecipes
extends RefCounted
## Secret buddy shapes (M3 Task 20b, spec §14.21, research D1 "Secret buddy shapes"): a small build in one of these
## patterns, woken with the Magic Wand, becomes a special buddy with its own name, look and personality (the jolly
## snowman throws gentle snowflakes, the flower pot grows, the tiny castle sings...). Pure.
##
## A recipe is a few cells, each a block CLASS (any of its blocks will do). Matching is tolerant: the build may be
## turned four ways about the up axis and mirrored, and may have ONE spare block anywhere (a hat, an arm, a tail);
## it is never tipped over. The first recipe that matches wins (the table's order; no two recipes match each
## other's shape: tested). Every recipe block can be woken by the wand (never natural ground: CaptureRules.GROUND).

## Blocks a matching build may have beyond the recipe's own.
const SPARE := 1

# Block classes.
const WHITE := &"white"
const NOSE := &"nose"             # carrot orange (or red)
const METAL := &"metal"
const LAMP := &"lamp"
const POT := &"pot"
const PLANT := &"plant"
const FLOWER := &"flower"
const WALL := &"wall"
const STRIPE := &"stripe"         # a lighthouse's red and white
const SHINY := &"shiny"
const GLASS := &"glass"
const R := &"red"
const Y := &"yellow"
const G := &"green"
const B := &"blue"
const P := &"purple"
const ANY := &"any"               # any block the wand wakes

const CLASSES := {
	WHITE: [BlockIds.PAINTED_WHITE, BlockIds.PACKED_SNOW, BlockIds.SNOW_BRICK, BlockIds.PLASTER],
	NOSE: [BlockIds.PAINTED_ORANGE, BlockIds.EMBER_SCALE, BlockIds.RED, BlockIds.PAINTED_RED],
	METAL: [BlockIds.PAINTED_SILVER, BlockIds.PAINTED_GREY, BlockIds.FURNACE, BlockIds.STONE_BRICK],
	LAMP: [BlockIds.LANTERN, BlockIds.LIGHT, BlockIds.LAMP, BlockIds.LAMP_ON, BlockIds.ICE_LANTERN, BlockIds.DESERT_LAMP,
		BlockIds.CANDY_LAMP, BlockIds.MOON_LAMP, BlockIds.GOLD_LAMP],
	POT: [BlockIds.BRICK, BlockIds.ROOF_TILES, BlockIds.PAINTED_BROWN],
	PLANT: [BlockIds.LEAVES, BlockIds.BUSH, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES, BlockIds.PALM_LEAVES,
		BlockIds.PINE_NEEDLES, BlockIds.GREEN, BlockIds.PAINTED_GREEN, BlockIds.PAINTED_LIME],
	FLOWER: [BlockIds.RED, BlockIds.YELLOW, BlockIds.PURPLE, BlockIds.BLUE, BlockIds.FLOWERS, BlockIds.PAINTED_PINK,
		BlockIds.PAINTED_MAGENTA, BlockIds.PAINTED_RED, BlockIds.PAINTED_YELLOW, BlockIds.PAINTED_PURPLE],
	WALL: [BlockIds.BRICK, BlockIds.STONE_BRICK, BlockIds.MOSSY_BRICK, BlockIds.SNOW_BRICK, BlockIds.FLOATSTONE_BRICK,
		BlockIds.CUT_SANDSTONE, BlockIds.CHISELED_SANDSTONE, BlockIds.PAINTED_GREY],
	STRIPE: [BlockIds.PAINTED_WHITE, BlockIds.RED, BlockIds.PAINTED_RED, BlockIds.PLASTER, BlockIds.PACKED_SNOW,
		BlockIds.SNOW_BRICK],
	SHINY: [BlockIds.CRYSTAL, BlockIds.CRYSTAL_SPIRE, BlockIds.PORTAL_CORE, BlockIds.PAINTED_PINK, BlockIds.PAINTED_MAGENTA],
	GLASS: [BlockIds.GLASS, BlockIds.DESERT_GLASS, BlockIds.FROSTED_GLASS, BlockIds.SUGAR_GLASS, BlockIds.STARGLASS],
	R: [BlockIds.RED, BlockIds.PAINTED_RED],
	Y: [BlockIds.YELLOW, BlockIds.PAINTED_YELLOW],
	G: [BlockIds.GREEN, BlockIds.PAINTED_GREEN, BlockIds.PAINTED_LIME],
	B: [BlockIds.BLUE, BlockIds.PAINTED_BLUE, BlockIds.PAINTED_SKY],
	P: [BlockIds.PURPLE, BlockIds.PAINTED_PURPLE, BlockIds.PAINTED_MAGENTA],
}

# What each special buddy does now and then (Buddy, section "M3 Task 20b").
const SNOW := &"snow"             # gentle snowflakes drift down round it
const BEEP := &"beep"             # a beep and a little robot wiggle; its lamp head glows
const GROW := &"grow"             # it grows a little (up to twice its size) and petals pop
const SING := &"sing"             # a little tune of chimes and music-note sparkles
const BEAM := &"beam"             # a bright light that sweeps round; a horn now and then
const BARK := &"bark"             # a happy bark, and it runs ahead and back (fetch)
const WIGGLE := &"wiggle"         # a wiggle and a rainbow of sparkles
const SPARKLE := &"sparkle"       # it floats and leaves a trail of twinkles
const ACTS: Array[StringName] = [SNOW, BEEP, GROW, SING, BEAM, BARK, WIGGLE, SPARKLE]

## The recipes, in the order they are tried. Cells are [pos, class] with x right, y up and z away from the viewer,
## laid out so the Secret Book's front view (silhouette) reads as the thing. traits: BuddyTraits keys it overrides.
const RECIPES: Array[Dictionary] = [
	{"id": &"snowman", "name": "Frosty", "title": "Jolly Snowman", "act": SNOW, "every": 5.0,
		"color": Color("bfe8ff"), "sound": &"snow_throw", "traits": {"speed": 5.0, "hop": 1.5},
		"hint": "Three white blocks in a stack, and a carrot nose!",
		"cells": [[Vector3i(0, 0, 0), WHITE], [Vector3i(0, 1, 0), WHITE], [Vector3i(0, 2, 0), WHITE],
			[Vector3i(1, 2, 0), NOSE]]},
	{"id": &"robot", "name": "Bolt", "title": "Lantern Robot", "act": BEEP, "every": 6.0,
		"color": Color("9fd8ff"), "sound": &"beep", "traits": {"speed": 4.0, "hop": 0.6, "glow": true, "glow_energy": 1.4},
		"hint": "A grey body with two grey arms, and a lamp for a head.",
		"cells": [[Vector3i(0, 0, 0), METAL], [Vector3i(0, 1, 0), METAL], [Vector3i(-1, 1, 0), METAL],
			[Vector3i(1, 1, 0), METAL], [Vector3i(0, 2, 0), LAMP]]},
	{"id": &"flower_pot", "name": "Petal", "title": "Growing Flower Pot", "act": GROW, "every": 8.0,
		"color": Color("ff9ec8"), "sound": &"sparkle", "traits": {"speed": 3.0, "hop": 0.9},
		"hint": "A pot, some leaves in it, and a flower on top.",
		"cells": [[Vector3i(0, 0, 0), POT], [Vector3i(0, 1, 0), PLANT], [Vector3i(0, 2, 0), FLOWER]]},
	{"id": &"castle", "name": "Melody", "title": "Singing Castle", "act": SING, "every": 9.0,
		"color": Color("ffd23f"), "sound": &"chime", "traits": {"speed": 2.6, "hop": 0.6},
		"hint": "Nine bricks for a floor, and a tower on every corner.",
		"cells": [[Vector3i(0, 0, 0), WALL], [Vector3i(1, 0, 0), WALL], [Vector3i(2, 0, 0), WALL],
			[Vector3i(0, 0, 1), WALL], [Vector3i(1, 0, 1), WALL], [Vector3i(2, 0, 1), WALL],
			[Vector3i(0, 0, 2), WALL], [Vector3i(1, 0, 2), WALL], [Vector3i(2, 0, 2), WALL],
			[Vector3i(0, 1, 0), WALL], [Vector3i(2, 1, 0), WALL], [Vector3i(0, 1, 2), WALL], [Vector3i(2, 1, 2), WALL]]},
	{"id": &"lighthouse", "name": "Beacon", "title": "Lighthouse Buddy", "act": BEAM, "every": 7.0,
		"color": Color("fff2a8"), "sound": &"horn", "traits": {"speed": 3.2, "hop": 0.7, "glow": true, "glow_energy": 2.6},
		"hint": "Red and white, three blocks tall, with a light on top.",
		"cells": [[Vector3i(0, 0, 0), STRIPE], [Vector3i(0, 1, 0), STRIPE], [Vector3i(0, 2, 0), STRIPE],
			[Vector3i(0, 3, 0), LAMP]]},
	{"id": &"caterpillar", "name": "Rainbow", "title": "Rainbow Caterpillar", "act": WIGGLE, "every": 5.0,
		"color": Color("b57bff"), "sound": &"rainbow", "traits": {"speed": 5.5, "hop": 0.4},
		"hint": "Five colours in a row: red, yellow, green, blue, purple.",
		"cells": [[Vector3i(0, 0, 0), R], [Vector3i(1, 0, 0), Y], [Vector3i(2, 0, 0), G], [Vector3i(3, 0, 0), B],
			[Vector3i(4, 0, 0), P]]},
	{"id": &"fairy", "name": "Twinkle", "title": "Crystal Fairy", "act": SPARKLE, "every": 4.0,
		"color": Color("e3a6ff"), "sound": &"wisp_chime", "traits": {"speed": 5.0, "hop": 1.2, "floaty": true},
		"hint": "A crystal body two blocks tall, with glass wings.",
		"cells": [[Vector3i(0, 0, 0), SHINY], [Vector3i(0, 1, 0), SHINY], [Vector3i(-1, 1, 0), GLASS],
			[Vector3i(1, 1, 0), GLASS]]},
	# Any blocks at all: tried last, so a shape made of a class above is never taken for it.
	{"id": &"pup", "name": "Scout", "title": "Puppy Buddy", "act": BARK, "every": 10.0,
		"color": Color("e0a060"), "sound": &"bark", "traits": {"speed": 6.5, "hop": 1.2},
		"hint": "Two legs, a long back and a head up at the front.",
		"cells": [[Vector3i(0, 0, 0), ANY], [Vector3i(2, 0, 0), ANY], [Vector3i(0, 1, 0), ANY], [Vector3i(1, 1, 0), ANY],
			[Vector3i(2, 1, 0), ANY], [Vector3i(0, 2, 0), ANY]]},
]


static func is_recipe(id: StringName) -> bool:
	return not recipe(id).is_empty()


## The recipe called `id`, or {} for none.
static func recipe(id: StringName) -> Dictionary:
	if id == &"":
		return {}
	for r: Dictionary in RECIPES:
		if r.id == id:
			return r
	return {}


## The recipe a build (block offsets -> ids) matches, or &"" for a plain buddy.
static func match_blocks(blocks: Dictionary) -> StringName:
	for r: Dictionary in RECIPES:
		if matches(r, blocks):
			return r.id
	return &""


## Whether `blocks` is recipe `r`: every cell of the recipe (turned 0-3 quarters, maybe mirrored, anywhere) holds a
## block of its class, and at most SPARE blocks are left over.
static func matches(r: Dictionary, blocks: Dictionary) -> bool:
	var cells: Array = r.cells
	var n := cells.size()
	if blocks.size() < n or blocks.size() > n + SPARE:
		return false
	for mirror in [false, true]:
		for k in 4:
			var at: Array[Vector3i] = []
			for c: Array in cells:
				at.append(_turn(c[0], k, mirror))
			for p: Vector3i in blocks:   # the recipe's first cell lands on each block of the build
				var off: Vector3i = p - at[0]
				var ok := true
				for i in n:
					var q: Vector3i = at[i] + off
					if not blocks.has(q) or not in_class(int(blocks[q]), cells[i][1]):
						ok = false
						break
				if ok:
					return true
	return false


static func in_class(id: int, cls: StringName) -> bool:
	if cls == ANY:
		return CaptureRules.is_capturable(id)
	return (CLASSES.get(cls, []) as Array).has(id)


## A cell turned `k` quarters about the up axis after an optional left-right mirror.
static func _turn(p: Vector3i, k: int, mirror: bool) -> Vector3i:
	var q := Vector3i(-p.x, p.y, p.z) if mirror else p
	for i in k:
		q = Vector3i(q.z, q.y, -q.x)
	return q


## The block that shows a class in pictures (its first; ANY shows as planks).
static func block_of(cls: StringName) -> int:
	if cls == ANY:
		return BlockIds.PLANKS
	var ids: Array = CLASSES.get(cls, [])
	return int(ids[0]) if not ids.is_empty() else BlockIds.AIR


## The recipe's front view for the Secret Book: {w, h, cells} with cells row by row from the top left, each the
## class of the front-most cell there (&"" for none).
static func silhouette(id: StringName) -> Dictionary:
	var r := recipe(id)
	if r.is_empty():
		return {"w": 0, "h": 0, "cells": []}
	var lo := Vector3i(1 << 20, 1 << 20, 1 << 20)
	var hi := -lo
	for c: Array in r.cells:
		var p: Vector3i = c[0]
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var w := hi.x - lo.x + 1
	var h := hi.y - lo.y + 1
	var cells: Array = []
	var depth: Array = []
	cells.resize(w * h)
	cells.fill(&"")
	depth.resize(w * h)
	depth.fill(1 << 20)
	for c: Array in r.cells:
		var p: Vector3i = c[0]
		var i := (hi.y - p.y) * w + (p.x - lo.x)
		if p.z < int(depth[i]):
			depth[i] = p.z
			cells[i] = c[1]
	return {"w": w, "h": h, "cells": cells}
