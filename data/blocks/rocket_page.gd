class_name RocketPage
extends RefCounted
## The rocket parts and the launch pad on block atlas page 32 (spec §21d.2; ids 560-573 in BlockIds, 574-575 free; past
## the items' ids 400-511 and page 31, kept for the colony domes). The pixel page is drawn by tools/make_rocket_page.gd,
## its realistic twin by tools/make_rocket_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout.
## BlockLibrary registers the page when it loads, so every library, icon and break particle has it. Engines, the nose
## cone, the capsule, the legs and the fins are cut out (their shapes); the rest are solid cubes. Never painted
## (PaintRules.JOB_PAGES).

const PAGE := 32
const FILES := ["res://data/blocks/pages/rockets.png", "res://data/blocks/pages/rockets_albedo.png",
	"res://data/blocks/pages/rockets_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.ROCKET_ENGINE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"cutout"],
	BlockIds.SPACE_ENGINE: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), &"cutout"],
	BlockIds.FUEL_TANK: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.NOSE_CONE: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(2, 1), &"cutout"],
	BlockIds.CREW_CAPSULE: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(5, 1), &"cutout"],
	BlockIds.SERVICE_MODULE: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.HEAT_SHIELD: [Vector2i(1, 2), Vector2i(0, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.LANDING_LEGS: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"cutout"],
	BlockIds.ROCKET_FINS: [Vector2i(5, 2), Vector2i(4, 2), Vector2i(5, 2), &"cutout"],
	BlockIds.STAGE_SEPARATOR: [Vector2i(7, 2), Vector2i(6, 2), Vector2i(7, 2), &"opaque"],
	BlockIds.SOLAR_ARRAY: [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 3), &"opaque"],
	BlockIds.PARACHUTE_PACK: [Vector2i(3, 3), Vector2i(2, 3), Vector2i(7, 1), &"opaque"],
	BlockIds.PAD_CONCRETE: [Vector2i(4, 3), Vector2i(7, 3), Vector2i(7, 3), &"opaque"],
	BlockIds.PAD_STRIPE: [Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), &"opaque"],
}

## The Sandbox palette's SPACE row (the SMART page): every part, in the shop's order.
const SPACE_ROW: Array[int] = [BlockIds.ROCKET_ENGINE, BlockIds.SPACE_ENGINE, BlockIds.FUEL_TANK, BlockIds.NOSE_CONE,
	BlockIds.CREW_CAPSULE, BlockIds.SERVICE_MODULE, BlockIds.HEAT_SHIELD, BlockIds.LANDING_LEGS, BlockIds.ROCKET_FINS,
	BlockIds.STAGE_SEPARATOR, BlockIds.SOLAR_ARRAY, BlockIds.PARACHUTE_PACK]


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
