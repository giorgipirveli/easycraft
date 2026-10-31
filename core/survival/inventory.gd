class_name Inventory
extends RefCounted
## Survivor's counted blocks and items (M2 §12.2): id -> count, in the order they were first got.
## Only real blocks and items count (no air, bedrock or unknown ids); counts cap at MAX_COUNT.

const MAX_COUNT := 999

## Something was added or taken (Session sends the owner a snapshot, M2 Task 3). Every method that
## changes the counts emits it.
signal changed

var _counts := {}   # id -> count (> 0), insertion ordered


func count(id: int) -> int:
	return _counts.get(id, 0)


func has(id: int) -> bool:
	return _counts.has(id)


## Adds up to n of id; returns how many fit (0 for things that cannot be owned).
func add(id: int, n: int) -> int:
	if n <= 0 or not ownable(id):
		return 0
	var room := MAX_COUNT - count(id)
	var added := mini(n, room)
	if added > 0:
		_counts[id] = count(id) + added
		changed.emit()
	return added


## Takes n of id only if there are that many.
func take(id: int, n: int) -> bool:
	if n <= 0 or count(id) < n:
		return false
	var left := count(id) - n
	if left == 0:
		_counts.erase(id)
	else:
		_counts[id] = left
	changed.emit()
	return true


func ids() -> Array[int]:
	var list: Array[int] = []
	for id: int in _counts:
		list.append(id)
	return list


## [[id, count], ...] for WorldMeta.
func to_save() -> Array:
	var out := []
	for id: int in _counts:
		out.append([id, _counts[id]])
	return out


## Never fails: broken entries are skipped.
static func from_save(data: Variant) -> Inventory:
	var inv := Inventory.new()
	if not data is Array:
		return inv
	for e: Variant in data:
		if e is Array and (e as Array).size() == 2 and typeof(e[0]) in [TYPE_INT, TYPE_FLOAT] \
				and typeof(e[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(e[0])) and is_finite(float(e[1])):
			inv.add(int(e[0]), int(e[1]))
	return inv


## A new Survivor world's kit (§12.1).
static func starter_kit() -> Inventory:
	var inv := Inventory.new()
	inv.add(ItemIds.SWORD, 1)
	inv.add(ItemIds.PICKAXE, 1)
	inv.add(BlockIds.PLANKS, 16)
	inv.add(BlockIds.DIRT, 8)
	return inv


static func ownable(id: int) -> bool:
	return (BlockIds.is_valid(id) and BlockIds.is_breakable(id)) or ItemIds.is_item(id)
