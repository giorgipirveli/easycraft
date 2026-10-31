class_name SmartPage
extends RefCounted
## Block atlas page 9 (ids 192-207; M3 Task 7): smart blocks and Game Blocks, in both styles. The pixel page is
## drawn by tools/make_smart_page.gd, its realistic twin by tools/make_smart_page.py (CC0 ambientCG textures).
## Registered before every block library is built (BlockLibrary.build), so every world has them. The "on"
## states glow; an open powered door and a coin are walked through (kind &"pass": cut out, no collision).

const PAGE := 9
const FILES := ["res://data/blocks/pages/smart.png", "res://data/blocks/pages/smart_albedo.png",
	"res://data/blocks/pages/smart_normal.png"]
const BASE := Vector2i(1, 3)   # the plain metal base under the smart blocks
## [top, side, bottom, kind]
const TILES := {
	BlockIds.BUTTON: [Vector2i(1, 0), Vector2i(0, 0), BASE],
	BlockIds.BUTTON_ON: [Vector2i(3, 0), Vector2i(2, 0), BASE, &"glow"],
	BlockIds.LEVER: [Vector2i(5, 0), Vector2i(4, 0), BASE],
	BlockIds.LEVER_ON: [Vector2i(7, 0), Vector2i(6, 0), BASE, &"glow"],
	BlockIds.POWERED_DOOR: [BASE, Vector2i(0, 1), BASE],
	BlockIds.POWERED_DOOR_OPEN: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"pass"],
	BlockIds.LAMP: [Vector2i(2, 1), Vector2i(2, 1), BASE],
	BlockIds.LAMP_ON: [Vector2i(3, 1), Vector2i(3, 1), BASE, &"glow"],
	BlockIds.LIGHT_SWITCH: [BASE, Vector2i(4, 1), BASE],
	BlockIds.LIGHT_SWITCH_ON: [BASE, Vector2i(5, 1), BASE, &"glow"],
	BlockIds.TELEPORT_PAD: [Vector2i(6, 1), Vector2i(7, 1), BASE, &"glow"],
	BlockIds.START: [Vector2i(0, 2), Vector2i(1, 2), BASE],
	BlockIds.CHECKPOINT: [Vector2i(2, 2), Vector2i(3, 2), BASE],
	BlockIds.FINISH: [Vector2i(4, 2), Vector2i(5, 2), BASE],
	BlockIds.COIN: [Vector2i(6, 2), Vector2i(6, 2), Vector2i(6, 2), &"pass"],
	BlockIds.BOUNCE: [Vector2i(7, 2), Vector2i(0, 3), BASE],
}
## The palette's SMART tab (M3 Task 7), a row of smart blocks and a row of Game Blocks. Neither is in
## BlockIds.PLACEABLE: the BLOCKS grid keeps its size (the palette fits above the hotbar).
const SMART_ROW: Array[int] = [BlockIds.BUTTON, BlockIds.LEVER, BlockIds.PRESSURE_PLATE, BlockIds.POWERED_DOOR,
	BlockIds.LAMP, BlockIds.LIGHT_SWITCH, BlockIds.TELEPORT_PAD]
const GAME_ROW: Array[int] = [BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH, BlockIds.COIN, BlockIds.BOUNCE]


## Registers page 9 once (again after a test unregistered it).
static func register() -> void:
	if BlockLibrary.tiles_of(BlockIds.START).is_empty():
		BlockLibrary.register_page(PAGE, FILES, TILES)
