class_name GiftStampBook
extends RefCounted
## Friends' builds as stamps on this device (M4 Wave 3, agent I; spec §17.5): an opened blueprint gift,
## or the tiny build from a bottle, sits in a slot of this book and is placed like the M1 stamps
## (Blueprints; one hotbar item id per slot, ItemIds.GIFT_STAMP_FIRST + slot; the palette's GIFTS page).
## The child can delete every one. Also the child's own shelf ("mine"): the last builds picked with the
## wand, to send from PLAY ONLINE later. Kept in user://gifts.json (JsonStore), never in the profile
## backup: friends' builds and names stay on this device; deleting the online account forgets it.

const PATH := "user://gifts.json"
const VERSION := 1
const SLOTS := 20                 # = ItemIds.GIFT_STAMP_SLOTS
const MINE_MAX := 8
const KIND_GIFT := "gift"
const KIND_BOTTLE := "bottle"
const MAX_ID := 64

## {slot, from, from_id, build (BuildCodec text), kind, at (unix seconds)}, in the order received.
var stamps: Array[Dictionary] = []
## The child's own picked builds (BuildCodec texts), oldest first.
var mine: Array[String] = []

var _blocks := {}                 # slot -> decoded blocks (a cache)

static var _current: GiftStampBook
static var _current_path := PATH


## This device's book (read from user://gifts.json the first time).
static func current() -> GiftStampBook:
	if _current == null:
		_current = load_from(_current_path)
	return _current


## Tests (and the online service's forget): this book instead of the device's; null reads the file again.
static func use(book: GiftStampBook, path: String = PATH) -> void:
	_current = book
	_current_path = path


static func item_of(slot: int) -> int:
	return ItemIds.GIFT_STAMP_FIRST + slot


static func slot_of(item: int) -> int:
	return item - ItemIds.GIFT_STAMP_FIRST if ItemIds.is_gift_stamp(item) else -1


## A friend's build into the lowest free slot: the slot, or -1 when the build is broken, too big for
## a gift, the sender's name is not a username, or the book is full.
func add(build: String, from: String, from_id: String, kind: String = KIND_GIFT, at: int = 0) -> int:
	if BuildCodec.decode(build, BuildCodec.GIFT).is_empty() or UsernameRules.validate(from) != "" \
			or from_id == "" or from_id.length() > MAX_ID:
		return -1
	var slot := _free_slot()
	if slot < 0:
		return -1
	stamps.append({"slot": slot, "from": from, "from_id": from_id, "build": build,
		"kind": kind if kind in [KIND_GIFT, KIND_BOTTLE] else KIND_GIFT, "at": maxi(at, 0)})
	return slot


func remove(slot: int) -> bool:
	for s in stamps:
		if s.slot == slot:
			stamps.erase(s)
			_blocks.erase(slot)
			return true
	return false


## Deletes every stamp from one player (a report); how many went.
func remove_from(from_id: String) -> int:
	var n := 0
	for s in stamps.duplicate():
		if s.from_id == from_id and remove(int(s.slot)):
			n += 1
	return n


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
		_blocks[slot] = BuildCodec.decode(str(s.build), BuildCodec.GIFT)
	return _blocks[slot]


## What the palette and hotbar call it.
func name_of(slot: int) -> String:
	var s := stamp(slot)
	return tr("Gift from %s") % s.from if not s.is_empty() else "Gift"


## The child's own picked build, kept to send later (once each, the newest MINE_MAX).
func keep_mine(build: String) -> bool:
	if BuildCodec.decode(build, BuildCodec.GIFT).is_empty():
		return false
	mine.erase(build)
	mine.append(build)
	while mine.size() > MINE_MAX:
		mine.remove_at(0)
	return true


func _free_slot() -> int:
	var used := slots()
	for i in SLOTS:
		if not used.has(i):
			return i
	return -1


# --- On the device ---

static func load_from(path: String = PATH) -> GiftStampBook:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())


## Saves the device's own book (the one current() gives).
static func save_current() -> Error:
	return current().save_to(_current_path)


func to_json() -> String:
	return JSON.stringify({"version": VERSION, "stamps": stamps, "mine": mine}, "\t")


## A stored book, read carefully: only whole stamps (a free slot in range, a username, a gift-sized
## build) and builds; anything else is left out.
static func from_json(text: String) -> GiftStampBook:
	var book := GiftStampBook.new()
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return book
	var d: Dictionary = json.data
	var raw: Variant = d.get("stamps", [])
	if raw is Array:
		for s: Variant in raw:
			if not (s is Dictionary):
				continue
			var slot: Variant = s.get("slot")
			var ok_slot := typeof(slot) in [TYPE_INT, TYPE_FLOAT] and float(slot) == floorf(float(slot)) \
				and int(slot) >= 0 and int(slot) < SLOTS and not book.slots().has(int(slot))
			var at: Variant = s.get("at", 0)
			if not ok_slot or not (s.get("from") is String) or not (s.get("from_id") is String) or not (s.get("build") is String):
				continue
			if UsernameRules.validate(s.from) != "" or s.from_id == "" or str(s.from_id).length() > MAX_ID \
					or BuildCodec.decode(s.build, BuildCodec.GIFT).is_empty():
				continue
			book.stamps.append({"slot": int(slot), "from": s.from, "from_id": s.from_id, "build": s.build,
				"kind": s.get("kind") if s.get("kind") in [KIND_GIFT, KIND_BOTTLE] else KIND_GIFT,
				"at": int(at) if typeof(at) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(at)) and float(at) > 0.0 else 0})
	var shelf: Variant = d.get("mine", [])
	if shelf is Array:
		for b: Variant in shelf:
			if b is String:
				book.keep_mine(b)
	return book
