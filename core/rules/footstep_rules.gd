class_name FootstepRules
extends RefCounted
## Footsteps by the block under the feet (the audio pass, owner feedback #27; spec §15.2): an Audio.SOUNDS
## name for each ground. Wet feet wade whatever the ground (M2 Task 14). The Frostpeak page (ids 80-95,
## M3 Task 3, built in parallel) crunches like snow until it names its blocks here; any other block without
## a sound of its own gets the grass step.

const FROST_FIRST := 80
const FROST_LAST := 95
const SMART_FIRST := 192
const SMART_LAST := 207

const _STEPS := {
	BlockIds.GRASS: &"step", BlockIds.BUSH: &"step", BlockIds.DEAD_BUSH: &"step",
	BlockIds.DIRT: &"step_dirt", BlockIds.TRAP_SAND: &"step_sand",
	BlockIds.SAND: &"step_sand", BlockIds.RED_SAND: &"step_sand",
	BlockIds.STONE: &"step_stone", BlockIds.DEEPSTONE: &"step_stone", BlockIds.BEDROCK: &"step_stone",
	BlockIds.BRICK: &"step_stone", BlockIds.COAL: &"step_stone", BlockIds.IRON: &"step_stone",
	BlockIds.GOLD: &"step_stone", BlockIds.DIAMOND: &"step_stone", BlockIds.FAKE_WALL: &"step_stone",
	BlockIds.PRESSURE_PLATE: &"step_stone", BlockIds.SPIKE_TRAP: &"step_stone", BlockIds.LANTERN: &"step_stone",
	BlockIds.SANDSTONE: &"step_stone", BlockIds.CUT_SANDSTONE: &"step_stone",
	BlockIds.CHISELED_SANDSTONE: &"step_stone", BlockIds.RED_SANDSTONE: &"step_stone",
	BlockIds.FAKE_SANDSTONE: &"step_stone", BlockIds.ARROW_SLIT: &"step_stone", BlockIds.PORTAL_FRAME: &"step_stone",
	BlockIds.JUMP_PAD: &"step_stone", BlockIds.SPEED_PAD: &"step_stone",
	BlockIds.LOG: &"step_wood", BlockIds.PLANKS: &"step_wood", BlockIds.PALM_LOG: &"step_wood",
	BlockIds.DOOR: &"step_wood", BlockIds.DOOR_OPEN: &"step_wood", BlockIds.BED: &"step_cloth",
	BlockIds.BARREL: &"step_wood", BlockIds.CLOSET: &"step_wood", BlockIds.CACTUS: &"step_leaves",
	BlockIds.LEAVES: &"step_leaves", BlockIds.PALM_LEAVES: &"step_leaves",
	BlockIds.GLASS: &"step_glass", BlockIds.CRYSTAL: &"step_glass", BlockIds.DESERT_GLASS: &"step_glass",
	BlockIds.LIGHT: &"step_glass", BlockIds.GOLD_LAMP: &"step_glass", BlockIds.DESERT_LAMP: &"step_glass",
	BlockIds.PYRAMID_GOLD: &"step_stone", BlockIds.TROPHY: &"step_stone", BlockIds.PORTAL_CORE: &"step_glass",
	BlockIds.RED: &"step_cloth", BlockIds.YELLOW: &"step_cloth", BlockIds.GREEN: &"step_cloth",
	BlockIds.BLUE: &"step_cloth", BlockIds.PURPLE: &"step_cloth",
	BlockIds.WATER: &"step_wet",
}


## The step for the block under the feet; wet feet wade.
static func sound(block: int, wet: bool = false) -> StringName:
	if wet:
		return &"step_wet"
	if _STEPS.has(block):
		return _STEPS[block]
	if block >= FROST_FIRST and block <= FROST_LAST:
		return &"step_snow"
	if block >= SMART_FIRST and block <= SMART_LAST:
		return &"step_stone"   # M3 Task 7's smart blocks and Game Blocks: metal plates and plastic
	return &"step"
