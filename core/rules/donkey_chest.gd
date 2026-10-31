class_name DonkeyChest
extends RefCounted
## A tamed donkey's chest (owner feedback #41, spec §14.19), as pure rules: SLOTS slots, each one kind of block or
## item, up to SLOT_MAX of it. Kept flat for the network and the save: [id0, count0, id1, count1, ...] (an empty
## slot is 0, 0). The host's PetDirector moves things between a child's bag and their donkey's chest; only real,
## ownable things go in (Inventory.ownable), so nothing can be made from nothing.

const SLOTS := 9
const SLOT_MAX := 99


## A clean chest from anything (a save, a sync): SLOTS × [id, count], bad entries emptied.
static func clean(v: Variant) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(SLOTS * 2)
	out.fill(0)
	if not (v is Array or v is PackedInt32Array):
		return out
	var a: Array = Array(v)
	for i in mini(a.size() / 2, SLOTS):
		var id: Variant = a[i * 2]
		var n: Variant = a[i * 2 + 1]
		if typeof(id) in [TYPE_INT, TYPE_FLOAT] and typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(id)) \
				and is_finite(float(n)) and int(n) > 0 and Inventory.ownable(int(id)):
			out[i * 2] = int(id)
			out[i * 2 + 1] = mini(int(n), SLOT_MAX)
	return out


static func is_empty(chest: PackedInt32Array) -> bool:
	for i in range(1, chest.size(), 2):
		if chest[i] > 0:
			return false
	return true


static func slot(chest: PackedInt32Array, i: int) -> Vector2i:
	if i < 0 or i >= SLOTS or chest.size() < SLOTS * 2 or chest[i * 2 + 1] <= 0:
		return Vector2i.ZERO
	return Vector2i(chest[i * 2], chest[i * 2 + 1])


## How many of `id` fit (slots of that kind with room, then empty slots).
static func room_for(chest: PackedInt32Array, id: int) -> int:
	var room := 0
	for i in SLOTS:
		var s := slot(chest, i)
		if s.y == 0:
			room += SLOT_MAX
		elif s.x == id:
			room += SLOT_MAX - s.y
	return room


## Puts up to `n` of `id` in (topping up that kind's slots first). Returns {"chest", "moved"}.
static func put(chest: PackedInt32Array, id: int, n: int) -> Dictionary:
	var out := clean(chest)
	var left := n if Inventory.ownable(id) else 0
	for pass_empty: bool in [false, true]:
		for i in SLOTS:
			if left <= 0:
				break
			var s := slot(out, i)
			if (not pass_empty and s.x == id and s.y > 0) or (pass_empty and s.y == 0):
				var add := mini(left, SLOT_MAX - s.y)
				out[i * 2] = id
				out[i * 2 + 1] = s.y + add
				left -= add
	return {"chest": out, "moved": n - left if Inventory.ownable(id) else 0}


## Takes slot `i` out whole. Returns {"chest", "id", "count"} (count 0: the slot was empty).
static func take(chest: PackedInt32Array, i: int) -> Dictionary:
	var out := clean(chest)
	var s := slot(out, i)
	if s.y > 0:
		out[i * 2] = 0
		out[i * 2 + 1] = 0
	return {"chest": out, "id": s.x, "count": s.y}
