class_name MyStampBook
extends RefCounted
## My Stamps (M3 Task 20b, spec §14.21, research C2 "a collection of my own creations"): the child saves a small
## build of theirs (picked with BuildPicker: the connected non-natural blocks under a tap) as a stamp, and places
## it again like the preset stamps (Blueprints; one edit, so one undo). At most MAX_SIDE blocks a side and
## EditBatch.MAX_BATCH blocks (a stamp is never cut into two edits). SLOTS stamps, one hotbar item id each
## (ItemIds.MY_STAMP_FIRST + slot); the palette's STAMPS page. Kept on this device in user://my_stamps.json
## (JsonStore), like friends' gift stamps, never in the profile: the profile's server backup is capped at 60 KB,
## and five 16-a-side stamps could be 80 KB.

const PATH := "user://my_stamps.json"
const VERSION := 1
const SLOTS := 5                  # = ItemIds.MY_STAMP_SLOTS (item ids 495-499)
const MAX_SIDE := 16
const MAX_BLOCKS := EditBatch.MAX_BATCH
## BuildCodec's limits for a stamp (16 a side; every cell a different run at worst: ~17 KB of text).
const LIMITS := {"max_dim": MAX_SIDE, "max_count": MAX_BLOCKS, "max_text": 17000}

const _WORDS := {
	"too_big": "That build is too big for a stamp. Pick one that fits in 16 x 16 x 16 blocks!",
	"too_many": "That build has too many blocks for a stamp (at most 1600).",
	"empty": "Tap a block of your build!",
	"full": "Your stamp book is full! Delete a stamp to make room.",
}

## {slot, build (BuildCodec text), at (unix seconds)}, in the order saved.
var stamps: Array[Dictionary] = []

var _blocks := {}                 # slot -> decoded blocks (a cache)

static var _current: MyStampBook
static var _current_path := PATH


## This device's book (read from user://my_stamps.json the first time).
static func current() -> MyStampBook:
	if _current == null:
		_current = load_from(_current_path)
	return _current


## Tests: this book instead of the device's; null reads the file again.
static func use(book: MyStampBook, path: String = PATH) -> void:
	_current = book
	_current_path = path


static func item_of(slot: int) -> int:
	return ItemIds.MY_STAMP_FIRST + slot


static func slot_of(item: int) -> int:
	return item - ItemIds.MY_STAMP_FIRST if ItemIds.is_my_stamp(item) else -1


## Why `blocks` (world or any offsets -> ids) can't be a stamp ("" = it can): too big, too many, none, or the book
## (when given) is full.
static func refusal(blocks: Dictionary, book: MyStampBook = null) -> String:
	if blocks.is_empty():
		return "empty"
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := -lo
	for p: Vector3i in blocks:
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var side := hi - lo + Vector3i.ONE
	if maxi(side.x, maxi(side.y, side.z)) > MAX_SIDE:
		return "too_big"
	if blocks.size() > MAX_BLOCKS:
		return "too_many"
	if book != null and book.is_full():
		return "full"
	return ""


static func message(code: String) -> String:
	return _WORDS.get(code, "")


## Saves `blocks` (world positions -> ids, as BuildPicker picks them) as a stamp, turned so the side facing the
## child (facing: Blueprints.facing_for_yaw) is its front: the slot, or -1 (refusal says why).
func add(blocks: Dictionary, facing := Vector3i(0, 0, -1), at: int = 0) -> int:
	if refusal(blocks, self) != "":
		return -1
	var text := BuildCodec.encode(PowerTools.to_stamp(blocks, facing))
	if BuildCodec.decode(text, LIMITS).is_empty():
		return -1
	var slot := _free_slot()
	stamps.append({"slot": slot, "build": text, "at": maxi(at, 0)})
	return slot


func remove(slot: int) -> bool:
	for s in stamps:
		if s.slot == slot:
			stamps.erase(s)
			_blocks.erase(slot)
			return true
	return false


func stamp(slot: int) -> Dictionary:
	for s in stamps:
		if s.slot == slot:
			return s
	return {}


func slots() -> Array[int]:
	var out: Array[int] = []
	for s in stamps:
		out.append(int(s.slot))
	return out


func is_full() -> bool:
	return _free_slot() < 0


## A stamp's blocks from its lowest corner ({} for an empty slot).
func blocks_of(slot: int) -> Dictionary:
	if not _blocks.has(slot):
		var s := stamp(slot)
		if s.is_empty():
			return {}
		_blocks[slot] = BuildCodec.decode(str(s.build), LIMITS)
	return _blocks[slot]


## What the palette and hotbar call it.
static func name_of(slot: int) -> String:
	return Lang.t("My Stamp %d") % (slot + 1)


func _free_slot() -> int:
	var used := slots()
	for i in SLOTS:
		if not used.has(i):
			return i
	return -1

# --- On the device ---

static func load_from(path: String = PATH) -> MyStampBook:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())


## Saves the device's own book (the one current() gives).
static func save_current() -> Error:
	return current().save_to(_current_path)


func to_json() -> String:
	return JSON.stringify({"version": VERSION, "stamps": stamps}, "\t")


## A stored book, read carefully: only whole stamps (a free slot in range, a stamp-sized build).
static func from_json(text: String) -> MyStampBook:
	var book := MyStampBook.new()
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return book
	var raw: Variant = (json.data as Dictionary).get("stamps", [])
	if not raw is Array:
		return book
	for s: Variant in raw:
		if not s is Dictionary:
			continue
		var slot: Variant = s.get("slot")
		var ok := typeof(slot) in [TYPE_INT, TYPE_FLOAT] and float(slot) == floorf(float(slot)) and int(slot) >= 0 \
			and int(slot) < SLOTS and not book.slots().has(int(slot))
		if not ok or not s.get("build") is String or BuildCodec.decode(s.build, LIMITS).is_empty():
			continue
		var at: Variant = s.get("at", 0)
		book.stamps.append({"slot": int(slot), "build": s.build,
			"at": int(at) if typeof(at) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(at)) and float(at) > 0.0 else 0})
	return book
