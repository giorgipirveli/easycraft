class_name WondersBlocks
extends RefCounted
## The world's wonders' blocks (owner #78, spec §24) on block atlas pages 33 and 34 (ids in BlockIds 576-597; 598-607
## free for the next tours): what the Seven Wonders of the Ancient World were built of, drawn in the game's own look
## (§3c: our blocks, no copied art). Page 33: the pyramid's limestone, its white casing and the King's Chamber's pink
## granite; the Greek marble, a fluted column, its scrolled top and a carved band; the Colossus's bronze; Zeus's ivory,
## gold and ebony; Babylon's baked and blue glazed bricks; and three fake stones for the hidden rooms. Page 34: the
## Lighthouse's fire and white stone, the tour's paving, the wonder plaque (a tap: the wonder's card and quiz), the
## gardens' water screw and Olympia's olive leaves. The pixel pages are drawn by tools/make_wonders_page.gd, their
## realistic twins by tools/make_wonders_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout.
## BlockLibrary registers both pages when it loads, so every library, icon and break particle has them (a child can
## carry the blocks anywhere). Reused from other pages where they fit: the desert's palms and lamps, the wild meadows'
## flowers and roof tiles, page 0's grass, leaves, water and glass.

const PAGE := 33
const PAGE_MORE := 34
const FILES := ["res://data/blocks/pages/wonders.png", "res://data/blocks/pages/wonders_albedo.png",
	"res://data/blocks/pages/wonders_normal.png"]
const FILES_MORE := ["res://data/blocks/pages/wonders2.png", "res://data/blocks/pages/wonders2_albedo.png",
	"res://data/blocks/pages/wonders2_normal.png"]

## Page 33: id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.LIMESTONE: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.CASING_STONE: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.GRANITE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.FAKE_LIMESTONE: [Vector2i(1, 0), Vector2i(4, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.MARBLE: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.MARBLE_COLUMN: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.CAPITAL: [Vector2i(5, 0), Vector2i(0, 1), Vector2i(7, 0), &"opaque"],
	BlockIds.FRIEZE: [Vector2i(5, 0), Vector2i(1, 1), Vector2i(5, 0), &"opaque"],
	BlockIds.FAKE_MARBLE: [Vector2i(5, 0), Vector2i(2, 1), Vector2i(5, 0), &"opaque"],
	BlockIds.BRONZE: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.IVORY: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.GOLD_LEAF: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.EBONY: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.BABYLON_BRICK: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"opaque"],
	BlockIds.GLAZED_BRICK: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.FAKE_BABYLON_BRICK: [Vector2i(0, 2), Vector2i(3, 2), Vector2i(0, 2), &"opaque"],
}

## Page 34.
const TILES_MORE := {
	BlockIds.BEACON_FIRE: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"glow"],
	BlockIds.WHITE_BRICK: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.PAVING: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.WONDER_PLAQUE: [Vector2i(6, 0), Vector2i(5, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.SCREW_PUMP: [Vector2i(0, 1), Vector2i(7, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.OLIVE_LEAVES: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"cutout", {"transparency": 1, "sway": true}],
}

## The fake stones a knock opens (SecretRules.is_fake_wall), each with the stone it looks like and drops.
const FAKES := {BlockIds.FAKE_LIMESTONE: BlockIds.LIMESTONE, BlockIds.FAKE_MARBLE: BlockIds.MARBLE,
	BlockIds.FAKE_BABYLON_BRICK: BlockIds.BABYLON_BRICK}

# --- The second tour: the New Seven Wonders (pages 36 and 37, ids 624-641; 642-655 are the third tour's) ---
## What the New Seven were built of, drawn by tools/make_wonders_new_page.gd (pixel) and
## tools/make_wonders_new_realistic.py (CC0 ambientCG textures), in the same 8 x 8 layout. Page 36: the Great Wall's
## grey bricks (their tops the walkway), Petra's rose rock with its bands, its carved stone and a column, the Colosseum's
## travertine, Chichen Itza's Maya stone, its carved band, the serpent's head, the red jaguar throne with jade spots,
## Machu Picchu's Inca stone, Christ the Redeemer's soapstone tiles, the Taj Mahal's inlaid marble; four fakes. Page
## 37: the Taj Mahal's gate of red sandstone with marble lines, and a fake white stone (the pedestal's door) drawn like
## page 34's white stone. Reused where they fit: the ancient tour's marble, white stone, gold leaf, paving, the beacon
## fire and the plaque; the game's sand, grass, hay (thatch), leaves, water and bricks.
const PAGE_NEW := 36
const PAGE_NEW_MORE := 37
const FILES_NEW := ["res://data/blocks/pages/wonders3.png", "res://data/blocks/pages/wonders3_albedo.png",
	"res://data/blocks/pages/wonders3_normal.png"]
const FILES_NEW_MORE := ["res://data/blocks/pages/wonders4.png", "res://data/blocks/pages/wonders4_albedo.png",
	"res://data/blocks/pages/wonders4_normal.png"]

## Page 36: id -> [top, side, bottom, kind].
const TILES_NEW := {
	BlockIds.WALL_BRICK: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.FAKE_WALL_BRICK: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.ROSE_ROCK: [Vector2i(4, 0), Vector2i(3, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.ROSE_STONE: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.ROSE_COLUMN: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.TRAVERTINE: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.FAKE_TRAVERTINE: [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.MAYA_STONE: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.MAYA_CARVING: [Vector2i(4, 1), Vector2i(5, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.FAKE_MAYA_STONE: [Vector2i(4, 1), Vector2i(6, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.SERPENT_HEAD: [Vector2i(4, 1), Vector2i(7, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.JAGUAR_THRONE: [Vector2i(1, 2), Vector2i(0, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.INCA_STONE: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.FAKE_INCA_STONE: [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.SOAPSTONE: [Vector2i(5, 2), Vector2i(5, 2), Vector2i(5, 2), &"opaque"],
	BlockIds.INLAID_MARBLE: [Vector2i(7, 2), Vector2i(6, 2), Vector2i(7, 2), &"opaque"],
}

## Page 37.
const TILES_NEW_MORE := {
	BlockIds.MUGHAL_RED: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.FAKE_WHITE_BRICK: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 0), &"opaque"],
}

## The second tour's fake stones, each with the stone it looks like and drops.
const FAKES_NEW := {BlockIds.FAKE_WALL_BRICK: BlockIds.WALL_BRICK, BlockIds.FAKE_TRAVERTINE: BlockIds.TRAVERTINE,
	BlockIds.FAKE_MAYA_STONE: BlockIds.MAYA_STONE, BlockIds.FAKE_INCA_STONE: BlockIds.INCA_STONE,
	BlockIds.FAKE_WHITE_BRICK: BlockIds.WHITE_BRICK}

# --- The third tour: the Seven Natural Wonders (page 37's rows 1-3, ids 642-655) ---
## What nature made them of, drawn by tools/make_wonders_nature_page.gd (pixel) and tools/make_wonders_nature_realistic.py
## (CC0 ambientCG textures) into page 37 under the New Seven's row: the Grand Canyon's rock layers (the pale Kaibab
## limestone of the rim, the Coconino sandstone's slanting dune lines, the Supai's red beds, the Redwall's red-stained
## grey limestone, the green-grey shale, the dark Vishnu schist with pink granite veins), a sea fossil (a trilobite in grey
## limestone), the reef's brain coral, staghorn coral and sea fan, Parícutin's cinders and its corn, Everest's prayer
## flags and the falls' spray. Reused where they fit: the frost world's snow, ice and pines, Io's black lava rock and hot
## lava (the game's lava never hurts), the game's grass, dirt, sand, stone, water, glass, leaves, logs and planks.
const TILES_NATURE := {
	BlockIds.KAIBAB_LIMESTONE: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.COCONINO_SANDSTONE: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.SUPAI_REDBED: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.REDWALL_LIMESTONE: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.CANYON_SHALE: [Vector2i(1, 2), Vector2i(0, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.VISHNU_SCHIST: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.SEA_FOSSIL: [Vector2i(6, 3), Vector2i(4, 2), Vector2i(6, 3), &"opaque"],
	BlockIds.BRAIN_CORAL: [Vector2i(6, 2), Vector2i(5, 2), Vector2i(6, 2), &"opaque"],
	BlockIds.STAGHORN_CORAL: [Vector2i(7, 2), Vector2i(7, 2), Vector2i(7, 2), &"opaque"],
	BlockIds.SEA_FAN: [Vector2i(0, 3), Vector2i(0, 3), Vector2i(0, 3), &"opaque"],
	BlockIds.CINDER: [Vector2i(2, 3), Vector2i(1, 3), Vector2i(2, 3), &"opaque"],
	BlockIds.CORN: [Vector2i(3, 3), Vector2i(3, 3), Vector2i(3, 3), &"pass", {"cross": true}],
	BlockIds.PRAYER_FLAGS: [Vector2i(7, 3), Vector2i(4, 3), Vector2i(7, 3), &"pass", {"culls": true}],
	BlockIds.SPRAY: [Vector2i(5, 3), Vector2i(5, 3), Vector2i(5, 3), &"pass", {"culls": true}],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
	BlockLibrary.register_page(PAGE_MORE, FILES_MORE, TILES_MORE)
	BlockLibrary.register_page(PAGE_NEW, FILES_NEW, TILES_NEW)
	BlockLibrary.register_page(PAGE_NEW_MORE, FILES_NEW_MORE, page_37_tiles())


## Page 37's blocks: the New Seven's row and nature's rows.
static func page_37_tiles() -> Dictionary:
	return TILES_NEW_MORE.merged(TILES_NATURE)
