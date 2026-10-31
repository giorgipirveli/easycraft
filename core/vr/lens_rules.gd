class_name LensRules
extends RefCounted
## Owner #110 (VR round 4, VR-WONDER, idea 2 "lens tools"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3, ruling R7): the telescope and the magnifier in a headset. Pure: the zoom
## over the trigger, the lens camera's field of view, the steady filter, and the magnifier's close-ups (a picture of our
## own and a short fact for the blocks a child looks at).
##
## **R7: the zoom happens only inside the lens.** The head's view never zooms (a zoomed full view breaks the head's match
## with the world: a known sickness trigger); the lens is a disc world-locked to the hand that shows what its own camera
## sees: the part of the world the disc covers from the eyes, narrowed by the zoom.

const TELESCOPE := &"telescope"
const MAGNIFIER := &"magnifier"
## The trigger (0..1) squeezes the zoom from the first to the second (times).
const TELESCOPE_ZOOM := Vector2(2.0, 8.0)
const MAGNIFIER_ZOOM := Vector2(2.0, 4.0)
## The lens camera's narrowest field (degrees: Camera3D's least is 1) and the eye's least distance counted (m).
const MIN_FOV := 1.0
const MAX_FOV := 60.0
const MIN_EYE := 0.1
## The steady filter: the lens camera turns towards the hand's aim at STEADY_RATE / zoom a second (a zoomed hand tremor
## is magnified by the zoom too, so it is smoothed by as much).
const STEADY_RATE := 32.0
## The magnifier's close-up shows when the block behind the glass is this near it (m); the lens's picture side (pixels).
const CLOSE_RANGE := 0.6
const PIXELS := 512
## A close-up's fact fits two short lines over the lens.
const MAX_FACT := 90
## The School's units the lenses teach with: light and seeing, light travels (a lens bends it); rocks and soils, plant
## parts, materials, states of matter (what the magnifier shows close up).
const UNITS: Array[String] = ["g4.science.light_seeing", "g6.science.light_travels", "g3.science.rocks_soils",
	"g4.science.plant_animal_parts", "g3.science.materials", "g4.science.states_of_matter"]

## The close-ups' pictures (VrLensCloseups draws each: our own work, procedural).
const PICTURES: Array[StringName] = [&"grass", &"soil", &"sand", &"stone", &"rings", &"grain", &"leaf", &"snow", &"ice",
	&"coal", &"iron_ore", &"gold_ore", &"diamond", &"cactus", &"glass", &"brick", &"petal"]

## Block id -> [picture, name, fact]: what the magnifier shows close up. Facts: our own words, checked (the notes).
const CLOSEUPS := {
	BlockIds.GRASS: [&"grass", "Grass", "Each blade of grass makes its own food from sunlight."],
	BlockIds.DIRT: [&"soil", "Soil", "Soil is broken rock mixed with old leaves and tiny living things."],
	BlockIds.MUD: [&"soil", "Mud", "Mud is soil with so much water in it that it turns soft."],
	BlockIds.SAND: [&"sand", "Sand", "Sand is tiny bits of rock and shell, worn down by water and wind."],
	BlockIds.SANDSTONE: [&"sand", "Sandstone", "Sandstone is sand pressed and stuck together over millions of years."],
	BlockIds.STONE: [&"stone", "Stone", "Stone is made of tiny crystals of minerals stuck tightly together."],
	BlockIds.DEEPSTONE: [&"stone", "Deep stone", "Rock deep underground is squeezed hard by all the rock above it."],
	BlockIds.LOG: [&"rings", "Tree trunk", "Each ring in a tree trunk is one year of the tree growing."],
	BlockIds.BIRCH_LOG: [&"rings", "Birch trunk", "Each ring in a tree trunk is one year of the tree growing."],
	BlockIds.PINE_LOG: [&"rings", "Pine trunk", "Each ring in a tree trunk is one year of the tree growing."],
	BlockIds.PLANKS: [&"grain", "Wood", "Wood is made of long fibres. That is why it splits along the grain."],
	BlockIds.LEAVES: [&"leaf", "Leaf", "A leaf's veins carry water in and carry the food it makes out."],
	BlockIds.BIRCH_LEAVES: [&"leaf", "Birch leaf", "A leaf's veins carry water in and carry the food it makes out."],
	BlockIds.PINE_NEEDLES: [&"leaf", "Pine needles", "Pine needles are thin leaves with a waxy coat that keeps water in."],
	BlockIds.SNOW: [&"snow", "Snow", "Every snowflake is a crystal of ice with six sides."],
	BlockIds.SNOWY_GRASS: [&"snow", "Snow", "Every snowflake is a crystal of ice with six sides."],
	BlockIds.ICE: [&"ice", "Ice", "Ice is frozen water. Tiny trapped air bubbles make it look cloudy."],
	BlockIds.COAL: [&"coal", "Coal", "Coal formed from plants that grew millions of years ago."],
	BlockIds.IRON: [&"iron_ore", "Iron ore", "Iron ore is rock with iron in it. People melt it to get iron for steel."],
	BlockIds.GOLD: [&"gold_ore", "Gold ore", "Gold never rusts, so it stays shiny for thousands of years."],
	BlockIds.DIAMOND: [&"diamond", "Diamond", "A diamond is carbon, like coal, packed into a very hard crystal."],
	BlockIds.CACTUS: [&"cactus", "Cactus", "A cactus's spines are its leaves. They lose very little water."],
	BlockIds.GLASS: [&"glass", "Glass", "Glass is made by melting sand until it glows, then cooling it."],
	BlockIds.BRICK: [&"brick", "Brick", "A brick is clay baked hard in a very hot oven called a kiln."],
	BlockIds.FLOWERS: [&"petal", "Flower", "Bees carry tiny grains of pollen from one flower to the next."],
}


## The lens an item is (&"" for none).
static func kind_of(item: int) -> StringName:
	if item == ItemIds.TELESCOPE:
		return TELESCOPE
	if item == ItemIds.MAGNIFIER:
		return MAGNIFIER
	return &""


## The zoom (times) for the trigger's `amount` (0..1).
static func zoom(kind: StringName, amount: float) -> float:
	var r := TELESCOPE_ZOOM if kind == TELESCOPE else MAGNIFIER_ZOOM
	return lerpf(r.x, r.y, clampf(amount, 0.0, 1.0))


## The lens camera's field of view (degrees): what a disc of `lens_radius` (m) covers seen from `eye_distance` (m),
## over the zoom; never under MIN_FOV or over MAX_FOV.
static func fov_degrees(lens_radius: float, eye_distance: float, zoom_times: float) -> float:
	var cover := rad_to_deg(2.0 * atan(lens_radius / maxf(eye_distance, MIN_EYE)))
	return clampf(cover / maxf(zoom_times, 1.0), MIN_FOV, MAX_FOV)


## The lens camera's turn this frame: from `prev` towards `target`, at STEADY_RATE / zoom a second.
static func steady(prev: Basis, target: Basis, delta: float, zoom_times: float) -> Basis:
	var w := 1.0 - exp(-maxf(delta, 0.0) * STEADY_RATE / maxf(zoom_times, 1.0))
	var a := prev.orthonormalized().get_rotation_quaternion()
	var b := target.orthonormalized().get_rotation_quaternion()
	return Basis(a.slerp(b, w))


## The close-up for a block: {picture, name, fact}, or {} for none (air, water, a block with no picture).
static func closeup(block: int) -> Dictionary:
	var c: Array = CLOSEUPS.get(block, [])
	if c.is_empty():
		return {}
	return {"picture": c[0], "name": c[1], "fact": c[2]}


## The block behind the glass is near enough for its close-up (`distance` m from the glass; negative: none).
static func shows_closeup(distance: float) -> bool:
	return distance >= 0.0 and distance <= CLOSE_RANGE
