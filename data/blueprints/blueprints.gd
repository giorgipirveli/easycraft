class_name Blueprints
extends RefCounted
## Stamp structures, defined in local coordinates: x = right, y = up, z = away from the player.
## The anchor (0, 0, 0) is the empty block on the tapped surface; y = -1 is the ground below it.
## AIR entries carve space (house interiors, bridge headroom) so stamps work inside hills too.

static var _cache := {}


static func local(stamp: int) -> Dictionary:
	if ItemIds.is_gift_stamp(stamp):
		return gift_local(GiftStampBook.current().blocks_of(stamp - ItemIds.GIFT_STAMP_FIRST))   # M4 I
	if ItemIds.is_my_stamp(stamp):
		return gift_local(MyStampBook.current().blocks_of(stamp - ItemIds.MY_STAMP_FIRST))   # M3 Task 20b: My Stamps
	if not _cache.has(stamp):
		var b := {}
		match stamp:
			ItemIds.STAMP_HOUSE:
				_house(b)
			ItemIds.STAMP_TOWER:
				_tower(b)
			ItemIds.STAMP_BRIDGE:
				_bridge(b)
			ItemIds.STAMP_TREE:
				_tree(b)
			ItemIds.STAMP_RAINBOW:
				_rainbow(b)
			ItemIds.BUILD_WALL, ItemIds.BUILD_FLOOR, ItemIds.BUILD_RAMP, ItemIds.BUILD_FORT:
				_quick_build(b, stamp)   # M3 Task 14a: instant builds
		_cache[stamp] = b
	return _cache[stamp]


## Snaps a camera yaw to the closest of the four horizontal directions.
static func facing_for_yaw(yaw: float) -> Vector3i:
	var f := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	if absf(f.x) > absf(f.z):
		return Vector3i(signi(roundi(f.x)), 0, 0)
	return Vector3i(0, 0, signi(roundi(f.z)))


static func to_world(local_pos: Vector3i, anchor: Vector3i, forward: Vector3i) -> Vector3i:
	var right := Vector3i(-forward.z, 0, forward.x)
	return anchor + right * local_pos.x + Vector3i.UP * local_pos.y + forward * local_pos.z


## World edits [[pos, id], ...] for a stamp placed at anchor, facing `forward`.
static func place(stamp: int, anchor: Vector3i, forward: Vector3i) -> Array:
	var out: Array = []
	var blocks := local(stamp)
	for p: Vector3i in blocks:
		out.append([to_world(p, anchor, forward), blocks[p]])
	return out


static func _box(b: Dictionary, from: Vector3i, to: Vector3i, id: int) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			for z in range(from.z, to.z + 1):
				b[Vector3i(x, y, z)] = id


static func _house(b: Dictionary) -> void:
	_box(b, Vector3i(-3, -1, 0), Vector3i(3, -1, 6), BlockIds.PLANKS)        # floor
	_box(b, Vector3i(-3, 0, 0), Vector3i(3, 3, 6), BlockIds.PLANKS)          # walls
	_box(b, Vector3i(-2, 0, 1), Vector3i(2, 3, 5), BlockIds.AIR)             # inside
	for corner in [Vector3i(-3, 0, 0), Vector3i(3, 0, 0), Vector3i(-3, 0, 6), Vector3i(3, 0, 6)]:
		_box(b, corner, corner + Vector3i(0, 3, 0), BlockIds.LOG)
	_box(b, Vector3i(0, 0, 0), Vector3i(0, 1, 0), BlockIds.AIR)               # door
	for w in [Vector3i(-2, 2, 0), Vector3i(2, 2, 0), Vector3i(-3, 1, 3), Vector3i(3, 1, 3), Vector3i(0, 2, 6)]:
		_box(b, w, w + Vector3i(0, 0 if w.z == 0 or w.z == 6 else 1, 0), BlockIds.GLASS)
	for k in 4:                                                              # stepped red roof
		_box(b, Vector3i(-4 + k, 4 + k, -1 + k), Vector3i(4 - k, 4 + k, 7 - k), BlockIds.RED)
	b[Vector3i(0, 3, 3)] = BlockIds.LIGHT                                    # ceiling lamp


static func _tower(b: Dictionary) -> void:
	_box(b, Vector3i(-2, -1, 0), Vector3i(2, 11, 4), BlockIds.STONE)
	_box(b, Vector3i(-1, 0, 1), Vector3i(1, 11, 3), BlockIds.AIR)            # hollow
	for floor_y in [4, 8]:                                                   # floors with a jump hole
		_box(b, Vector3i(-1, floor_y, 1), Vector3i(1, floor_y, 3), BlockIds.PLANKS)
		b[Vector3i(1, floor_y, 3)] = BlockIds.AIR
	_box(b, Vector3i(0, 0, 0), Vector3i(0, 1, 0), BlockIds.AIR)               # door
	for y in [2, 6, 10]:
		b[Vector3i(0, y, 0)] = BlockIds.GLASS
		b[Vector3i(-2, y, 2)] = BlockIds.GLASS
		b[Vector3i(2, y, 2)] = BlockIds.GLASS
	for x in range(-2, 3):                                                   # battlements
		for z in range(0, 5):
			var edge := x == -2 or x == 2 or z == 0 or z == 4
			if edge and (x + z) % 2 == 0:
				b[Vector3i(x, 12, z)] = BlockIds.STONE
	b[Vector3i(0, 11, 2)] = BlockIds.LIGHT


static func _bridge(b: Dictionary) -> void:
	for z in range(0, 16):
		_box(b, Vector3i(-1, 0, z), Vector3i(1, 0, z), BlockIds.PLANKS)
		_box(b, Vector3i(-1, 1, z), Vector3i(1, 3, z), BlockIds.AIR)
		for side in [-2, 2]:
			if z % 4 == 0:
				_box(b, Vector3i(side, 0, z), Vector3i(side, 2, z), BlockIds.LOG)
			else:
				b[Vector3i(side, 1, z)] = BlockIds.PLANKS


static func _tree(b: Dictionary) -> void:
	var trunk_base := Vector3i(0, 0, 3)
	_box(b, trunk_base, trunk_base + Vector3i(1, 7, 1), BlockIds.LOG)
	var c := Vector3(1.0, 9.5, 4.0)
	for x in range(-4, 7):
		for y in range(6, 14):
			for z in range(-1, 10):
				var d := Vector3((x - c.x) / 4.6, (y - c.y) / 3.4, (z - c.z) / 4.6)
				var p := Vector3i(x, y, z)
				if d.length() <= 1.0 and not b.has(p):
					b[p] = BlockIds.LEAVES
	for p in [Vector3i(-3, 8, 4), Vector3i(5, 9, 3), Vector3i(1, 8, -1), Vector3i(2, 8, 8)]:
		b[p] = BlockIds.LIGHT                                                # glowing fruit


static func _rainbow(b: Dictionary) -> void:
	var bands := [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE]
	for x in range(-9, 10):
		for y in range(0, 10):
			var r := Vector2(x, y + 0.5).length()
			var band := int(9.5 - r)
			if r <= 9.5 and band >= 0 and band < bands.size():
				for z in [2, 3]:
					b[Vector3i(x, y, z)] = bands[band]


# --- M4 Wave 3, agent I: gift stamps ---

## A friend's build (from its lowest corner) as stamp coordinates: centred left to right on the tapped
## spot, standing on it, reaching away from the player. Never cached: the book changes.
static func gift_local(blocks: Dictionary) -> Dictionary:
	var width := 0
	for p: Vector3i in blocks:
		width = maxi(width, p.x + 1)
	var out := {}
	for p: Vector3i in blocks:
		out[Vector3i(p.x - floori(width / 2.0), p.y, p.z)] = blocks[p]
	return out

# --- M3 Task 14a: instant builds (GadgetRules): planks, only ever put into empty cells (no AIR carving) ---

static func _quick_build(b: Dictionary, item: int) -> void:
	match item:
		ItemIds.BUILD_WALL:                                                  # 3 wide, 4 high, across the way
			_box(b, Vector3i(-1, 0, 0), Vector3i(1, 3, 0), BlockIds.PLANKS)
		ItemIds.BUILD_FLOOR:                                                 # 3 x 3 at the ground's level
			_box(b, Vector3i(-1, -1, 0), Vector3i(1, -1, 2), BlockIds.PLANKS)
		ItemIds.BUILD_RAMP:                                                  # four steps up, away from you
			for k in 4:
				_box(b, Vector3i(-1, k, k), Vector3i(1, k, k), BlockIds.PLANKS)
		ItemIds.BUILD_FORT:                                                  # a 5 x 5 ring, 3 high, door towards you
			for y in 3:
				for x in range(-2, 3):
					for z in range(0, 5):
						if x == -2 or x == 2 or z == 0 or z == 4:
							b[Vector3i(x, y, z)] = BlockIds.PLANKS
			b.erase(Vector3i(0, 0, 0))
			b.erase(Vector3i(0, 1, 0))
			for x in range(-2, 3):                                           # battlements
				for z in range(0, 5):
					if (x == -2 or x == 2 or z == 0 or z == 4) and (x + z) % 2 == 0:
						b[Vector3i(x, 3, z)] = BlockIds.PLANKS
