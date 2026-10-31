class_name WearRules
extends RefCounted
## Build-and-Wear (M3 Task 8; spec §14.5, §3a): a small build (at most MAX_SIDE on every side, connected blocks
## picked by BuildPicker) tapped with the wand becomes a HAT, a BACKPACK or WINGS. A wearable is kept as its block
## ids and places: BuildCodec's text (the format friends' gifts use), decoded under this file's own limits and
## checked on every load (only blocks a player may place: never an item, bedrock or an id no block owns). The
## avatar look carries one per slot (AvatarLook.builds), so it is saved in the profile and sent to other players
## with the look (Player.look_code). A built hat takes the hat's place while worn, a backpack the cape's and
## built wings the wings'. WearMesh bakes each into one small cached mesh.

const HAT := &"hat"
const BACK := &"back"
const WINGS := &"wings"
const SLOTS: Array[StringName] = [HAT, BACK, WINGS]
const WORDS := {HAT: "HAT", BACK: "BACKPACK", WINGS: "WINGS"}
## The catalogue slot (AvatarLook field) a built wearable replaces while worn.
const REPLACES := {HAT: "hat", BACK: "cape", WINGS: "wings"}

const MAX_SIDE := 5
const MAX_BLOCKS := 125
## The longest text of a 5 x 5 x 5 build (every cell a different block from the last, ids of two LEB128 bytes:
## 4 + 125 x 3 bytes, in base64), so three always fit the look code.
const MAX_TEXT := 520
const LIMITS := {"max_dim": MAX_SIDE, "max_count": MAX_BLOCKS, "max_text": MAX_TEXT}

const TOO_BIG := "too_big"
const EMPTY := "empty"
const NOT_BLOCKS := "not_blocks"


static func word(slot: StringName) -> String:
	return WORDS.get(slot, "")


static func is_slot(slot: Variant) -> bool:
	return (slot is StringName or slot is String) and SLOTS.has(StringName(slot))


## Why these blocks ({pos: id}, any corner) can't be worn ("" = they can).
static func refusal(blocks: Dictionary) -> String:
	if blocks.is_empty():
		return EMPTY
	var lo := Vector3i(1 << 20, 1 << 20, 1 << 20)
	var hi := -lo
	for p: Variant in blocks:
		if not p is Vector3i:
			return NOT_BLOCKS
		var id: Variant = blocks[p]
		if typeof(id) != TYPE_INT or not BlockIds.is_valid(id):
			return NOT_BLOCKS
		lo = lo.min(p)
		hi = hi.max(p)
	var s := hi - lo + Vector3i.ONE
	if maxi(s.x, maxi(s.y, s.z)) > MAX_SIDE or blocks.size() > MAX_BLOCKS:
		return TOO_BIG
	return ""


## The wearable's code ("" when the blocks can't be worn).
static func from_blocks(blocks: Dictionary) -> String:
	if refusal(blocks) != "":
		return ""
	return BuildCodec.encode(blocks)


## A code's blocks from its lowest corner ({} when it is not a wearable: too big, broken, or not only blocks).
static func blocks_of(code: Variant) -> Dictionary:
	if not code is String:
		return {}
	var blocks := BuildCodec.decode(code, LIMITS)
	for p: Vector3i in blocks:
		if not BlockIds.is_valid(blocks[p]):
			return {}
	return blocks


static func valid(code: Variant) -> bool:
	return not blocks_of(code).is_empty()


static func message(code: String) -> String:
	match code:
		TOO_BIG:
			return "Only small builds can be worn: at most 5 x 5 x 5 blocks!"
		EMPTY, NOT_BLOCKS:
			return "Tap a block of your build!"
	return ""
