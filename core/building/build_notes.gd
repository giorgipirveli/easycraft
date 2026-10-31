class_name BuildNotes
extends RefCounted
## Building sounds (M3 Task 21c, spec §16 "building sounds"): every block kind has a soft note of its own, in one of
## two voices (a wooden marimba, or a bell for glass, crystal, ice and lights), and blocks placed one after another in
## a row climb a little melody. Every note is on the major pentatonic scale, whose notes never clash, so building
## always sounds nice. Pure: the notes, their pitches (exact: a note is never wobbled out of tune), the melody's rule
## and the budget that keeps the notes from flooding the mix. BuildMelody (entities/player/) plays them: one note per
## tap or tool step, never one per cell of a LINE or a FILL.

## Major pentatonic (C D E G A): semitones above the sample's own C.
const SCALE: Array[int] = [0, 2, 4, 7, 9]
## A block kind's own note is one of the first START_TOP + 1 degrees (C4 up to D5) ...
const START_TOP := 6
## ... and a row climbs PHRASE notes from its first one, then starts that phrase again.
const PHRASE := 6
## The highest degree anything reaches (about 4.5 times the sample's pitch: bright, never shrill).
const TOP := START_TOP + PHRASE - 1
## The next block within this long ...
const ROW_GAP_MS := 1500
## ... and this close to the last one (blocks, each way) goes on up the melody.
const ROW_REACH := 2
## The budget: at most one note this often (ms) ...
const MIN_GAP_MS := 70
## ... and this many in any second.
const PER_SECOND := 8

const WOOD := &"wood"
const BELL := &"bell"

## Families of blocks share a note: low stone, earth, bricks and red things, wood, green and yellow things, blue and
## precious things, and high glass and lights. Other blocks get a note from their id.
const _NOTE := {
	BlockIds.STONE: 0, BlockIds.DEEPSTONE: 0, BlockIds.COAL: 0, BlockIds.IRON: 0, BlockIds.SANDSTONE: 0,
	BlockIds.CUT_SANDSTONE: 0, BlockIds.STONE_BRICK: 0, BlockIds.MOSSY_BRICK: 0, BlockIds.FLOATSTONE: 0,
	BlockIds.DIRT: 1, BlockIds.GRASS: 1, BlockIds.SAND: 1, BlockIds.MUD: 1, BlockIds.PATH: 1, BlockIds.SNOW: 1,
	BlockIds.PACKED_SNOW: 1, BlockIds.RED_SAND: 1, BlockIds.HAY: 1,
	BlockIds.BRICK: 2, BlockIds.RED: 2, BlockIds.PLASTER: 2, BlockIds.ROOF_TILES: 2, BlockIds.SNOW_BRICK: 2,
	BlockIds.PUMPKIN: 2, BlockIds.JACK_O_LANTERN: 2,
	BlockIds.LOG: 3, BlockIds.PLANKS: 3, BlockIds.DOOR: 3, BlockIds.BARREL: 3, BlockIds.CLOSET: 3, BlockIds.BED: 3,
	BlockIds.PINE_LOG: 3, BlockIds.PALM_LOG: 3, BlockIds.BIRCH_LOG: 3, BlockIds.DARK_LOG: 3,
	BlockIds.CRAFTING_TABLE: 3,
	BlockIds.LEAVES: 4, BlockIds.BUSH: 4, BlockIds.GREEN: 4, BlockIds.YELLOW: 4, BlockIds.PINE_NEEDLES: 4,
	BlockIds.BIRCH_LEAVES: 4, BlockIds.DARK_LEAVES: 4, BlockIds.FLOWERS: 4, BlockIds.CHEESE: 4,
	BlockIds.BLUE: 5, BlockIds.PURPLE: 5, BlockIds.WATER: 5, BlockIds.GOLD: 5, BlockIds.DIAMOND: 5,
	BlockIds.SNOWMAN_HEAD: 5,
	BlockIds.GLASS: 6, BlockIds.CRYSTAL: 6, BlockIds.LIGHT: 6, BlockIds.LANTERN: 6, BlockIds.ICE: 6,
	BlockIds.BLUE_ICE: 6, BlockIds.FROSTED_GLASS: 6, BlockIds.DESERT_GLASS: 6, BlockIds.ICE_LANTERN: 6,
	BlockIds.SUGAR_GLASS: 6, BlockIds.STARGLASS: 6,
}
## Blocks that ring like a bell.
const _BELLS: Array[int] = [BlockIds.GLASS, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.LANTERN, BlockIds.ICE,
	BlockIds.BLUE_ICE, BlockIds.FROSTED_GLASS, BlockIds.DESERT_GLASS, BlockIds.ICE_LANTERN, BlockIds.SUGAR_GLASS,
	BlockIds.STARGLASS, BlockIds.DIAMOND, BlockIds.GOLD, BlockIds.CRYSTAL_SPIRE, BlockIds.MOON_LAMP,
	BlockIds.CANDY_LAMP, BlockIds.DESERT_LAMP, BlockIds.JACK_O_LANTERN]


## The note (a degree of the scale, 0..START_TOP) block or item `id` sings when it is placed.
static func base_degree(id: int) -> int:
	return int(_NOTE.get(id, posmod(id * 5, START_TOP + 1)))


## The voice of `id`: BELL or WOOD.
static func voice(id: int) -> StringName:
	return BELL if _BELLS.has(id) else WOOD


## The pitch scale that plays degree `d` from a sample of the scale's first note (degree 0).
static func pitch(d: int) -> float:
	var n := maxi(d, 0)
	var semis := SCALE[n % SCALE.size()] + 12 * (n / SCALE.size())
	return pow(2.0, semis / 12.0)


## One child's melody while building: which note comes next, and whether the budget lets it play.
class Melody:
	extends RefCounted
	var _start := -1                  # the row's first note (-1: no row yet)
	var _step := 0                    # how far up the phrase the row is
	var _last_cell := Vector3i.ZERO
	var _last_ms := -1
	var _played: Array[int] = []      # when the notes of the last second played (ms)

	## The degree of the note for block `id` placed at `cell` at time `now_ms`.
	func next(id: int, cell: Vector3i, now_ms: int) -> int:
		var d := (cell - _last_cell).abs()
		var in_row := _start >= 0 and now_ms - _last_ms <= ROW_GAP_MS and maxi(d.x, maxi(d.y, d.z)) <= ROW_REACH
		if in_row:
			_step = (_step + 1) % PHRASE
		else:
			_start = BuildNotes.base_degree(id)
			_step = 0
		_last_cell = cell
		_last_ms = now_ms
		return mini(_start + _step, TOP)

	## True (and counted) when a note may play at `now_ms`: MIN_GAP_MS after the last one, and fewer than
	## PER_SECOND in the second before.
	func may_play(now_ms: int) -> bool:
		while not _played.is_empty() and now_ms - _played[0] >= 1000:
			_played.pop_front()
		if not _played.is_empty() and (now_ms - _played[_played.size() - 1] < MIN_GAP_MS or _played.size() >= PER_SECOND):
			return false
		_played.append(now_ms)
		return true
