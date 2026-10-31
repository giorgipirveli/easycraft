class_name ArenaShape
extends MeadowsShape
## Monster Wave's arena (owner feedback #44, spec §12.20), pure: a flat world of the universe's ground (palette)
## at FLOOR, packed layers down to a bedrock floor DEPTH below, and low cover on a grid of CELL blocks — in two of
## three cells a 2 × 2 pillar of the universe's stone or a 3-long wall of its wood, COVER_HIGH tall — never within
## CLEAR blocks of the middle, where the Monster Totem stands (totem_cell); the players start START_Z blocks from
## it. Every rule is a function of (x, y, z) and the seed, so chunks meet without seams (ArenaGenerator writes it).

const FLOOR := 32
const DEPTH := 6
const CELL := 12
const CLEAR := 12
const COVER_HIGH := 2
const START_Z := 6

## Each universe's ground: top, fill (3 under the top), stone, cover (pillars), wood (walls). A universe without
## its own entry uses Green Meadows'.
const PALETTES := {
	1: {"top": BlockIds.GRASS, "fill": BlockIds.DIRT, "stone": BlockIds.STONE, "cover": BlockIds.STONE, "wood": BlockIds.LOG},
	2: {"top": BlockIds.SAND, "fill": BlockIds.SANDSTONE, "stone": BlockIds.SANDSTONE, "cover": BlockIds.RED_SANDSTONE,
		"wood": BlockIds.PALM_LOG},
	3: {"top": BlockIds.SNOW, "fill": BlockIds.PACKED_SNOW, "stone": BlockIds.STONE, "cover": BlockIds.PACKED_SNOW,
		"wood": BlockIds.PINE_LOG},
	5: {"top": BlockIds.SKY_GRASS, "fill": BlockIds.FLOATSTONE, "stone": BlockIds.DEEP_FLOATSTONE,   # owner 39: the Dragon
		"cover": BlockIds.CRYSTAL_SPIRE, "wood": BlockIds.MUSHROOM_STEM},                            # Realm (no void here)
	6: {"top": BlockIds.CAVE_STONE, "fill": BlockIds.CAVE_STONE, "stone": BlockIds.CAVE_STONE,   # universe 6: the Glow
		"cover": BlockIds.SELENITE, "wood": BlockIds.SHROOM_STEM},                                  # Caves (glowing cover)
}

var universe := 1
var palette: Dictionary


func _init(world_seed: int, u: int = 1) -> void:
	super(world_seed)
	universe = u
	palette = PALETTES.get(u, PALETTES[1])


## The column the Monster Totem stands in (the middle).
static func totem_cell() -> Vector2i:
	return Vector2i.ZERO


func height_at(_x: int, _z: int) -> int:
	return FLOOR


func is_river(_x: int, _z: int) -> bool:
	return false


func tree_at(_x: int, _z: int) -> bool:
	return false


func tree_height(_x: int, _z: int) -> int:
	return 0


func spawn_column() -> Vector2i:
	return Vector2i(0, START_Z)


func bedrock_top(_x: int, _z: int) -> int:
	return FLOOR - DEPTH


## The ground: the palette's top, fill and stone on bedrock; air above (no water anywhere).
func column_block(y: int, height: int, bed_top: int = WORLD_BOTTOM) -> int:
	if y >= height:
		return BlockIds.AIR
	if y <= bed_top:
		return BlockIds.BEDROCK if y == bed_top else BlockIds.STONE
	if y == height - 1:
		return palette.top
	if y >= height - 4:
		return palette.fill
	return palette.stone


## The cover standing in column (x, z) (AIR where there is none).
func cover_at(x: int, z: int) -> int:
	var cx := floori(float(x) / CELL)
	var cz := floori(float(z) / CELL)
	var h := absi(_hash(cx * 7919 + 13, cz * 104729 - 7))
	if h % 3 == 0:
		return BlockIds.AIR
	var c := Vector2i(cx * CELL + CELL / 2, cz * CELL + CELL / 2)
	if Vector2(c).length() < CLEAR + 4:
		return BlockIds.AIR
	var d := Vector2i(x, z) - c
	if (h / 3) % 2 == 0:
		return palette.cover if d.x >= 0 and d.x <= 1 and d.y >= 0 and d.y <= 1 else BlockIds.AIR   # a pillar
	var along_x := (h / 6) % 2 == 0
	var on := (absi(d.x) <= 1 and d.y == 0) if along_x else (absi(d.y) <= 1 and d.x == 0)       # a short wall
	return palette.wood if on else BlockIds.AIR


## The block at p (the reference the generator must match).
func block_at(p: Vector3i) -> int:
	if p.y >= FLOOR:
		return cover_at(p.x, p.z) if p.y < FLOOR + COVER_HIGH else BlockIds.AIR
	return column_block(p.y, FLOOR, bedrock_top(p.x, p.z))
