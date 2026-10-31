class_name BedRules
extends RefCounted
## Beds and sleeping, as pure rules: when a player may lie down in a bed, finding the bed next to
## the player (the SLEEP button), when the time skips (every player asleep; players who left never
## block it) and where home is (the bed you last slept in, or the world spawn once it is gone).

const TOP := 0.5625               # the bed block's height: half a block plus a mattress
const REACH := 3.0                # feet to the bed's top: "standing next to it"
const REACH_TOLERANCE := 1.0      # host-side slack for network latency
const NO_BED := Vector3i.MIN
const UNLOADED := -1              # "block id" of a bed cell that is not loaded yet
const SCAN_BELOW := 2             # find_bed looks from this many rows below the feet to one above


## "" if the player may lie down in the bed at `bed`, else why not (see message()).
## bed_id: the block there; feet: the player's position; above_id: the block over the bed;
## taken: somebody else already sleeps in it.
static func check(bed_id: int, bed: Vector3i, feet: Vector3, on_floor: bool, in_water: bool, above_id: int,
		physics_mode: int, taken: bool, reach: float = REACH) -> String:
	if bed_id != BlockIds.BED:
		return "no_bed"
	if feet.distance_to(_top_center(bed)) > reach:
		return "too_far"
	if physics_mode != PhysicsMode.Mode.NORMAL:
		return "flying"
	if in_water:
		return "in_water"
	if not on_floor:
		return "not_on_floor"
	if above_id != BlockIds.AIR:
		return "no_room"
	if taken:
		return "taken"
	return ""


static func message(code: String) -> String:
	match code:
		"no_bed":
			return "Stand next to a bed to sleep."
		"too_far":
			return "Get closer to the bed first!"
		"flying":
			return "Land first, then you can sleep."
		"in_water":
			return "You can't sleep in the water!"
		"not_on_floor":
			return "Stand on the ground to sleep."
		"no_room":
			return "No room on this bed. Take the block off it first!"
		"taken":
			return "Somebody is already sleeping in this bed!"
	return ""


## The nearest bed within REACH of the feet, or NO_BED. get_block: func(pos: Vector3i) -> int.
static func find_bed(feet: Vector3, get_block: Callable) -> Vector3i:
	var base := Vector3i(feet.floor())
	var r := ceili(REACH)
	var best := NO_BED
	var best_distance := INF
	for y in range(base.y - SCAN_BELOW, base.y + 2):
		for z in range(base.z - r, base.z + r + 1):
			for x in range(base.x - r, base.x + r + 1):
				var p := Vector3i(x, y, z)
				if get_block.call(p) != BlockIds.BED:
					continue
				var d := feet.distance_to(_top_center(p))
				if d <= REACH and d < best_distance:
					best = p
					best_distance = d
	return best


## The box [origin, size] of every cell find_bed(feet, ...) reads, for one bulk read of the terrain
## (WorldService.box_reader) instead of a locked read per cell.
static func scan_box(feet: Vector3) -> Array:
	var base := Vector3i(feet.floor())
	var r := ceili(REACH)
	return [Vector3i(base.x - r, base.y - SCAN_BELOW, base.z - r), Vector3i(2 * r + 1, SCAN_BELOW + 2, 2 * r + 1)]


## Where a sleeping player's feet rest: on the mattress, in the middle of the bed.
static func lie_position(bed: Vector3i) -> Vector3:
	return _top_center(bed)


## Where a sleeper stands up: on the bed when two cells above it are free, else beside it on the
## first side with two free cells over solid ground (sleeping needs only one free cell, so a low
## ceiling would put the head inside a block), else on the bed anyway.
static func wake_position(bed: Vector3i, get_block: Callable) -> Vector3:
	if _room_to_stand(bed + Vector3i.UP, get_block):
		return lie_position(bed)
	for side: Vector3i in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		var p := bed + side
		if _room_to_stand(p, get_block) and BlockIds.is_solid(get_block.call(p + Vector3i.DOWN)):
			return Vector3(p.x + 0.5, p.y, p.z + 0.5)
	return lie_position(bed)


static func _room_to_stand(feet: Vector3i, get_block: Callable) -> bool:
	return not BlockIds.is_solid(get_block.call(feet)) and not BlockIds.is_solid(get_block.call(feet + Vector3i.UP))


## Where a player going home appears: just above their bed.
static func home_position(bed: Vector3i) -> Vector3:
	return Vector3(bed.x + 0.5, bed.y + 1.0, bed.z + 0.5)


## True when every player here sleeps. player_ids: the players in the game now (a sleeper who
## left is not one of them, so leaving never blocks the skip); sleepers: {peer_id: bed}.
static func all_asleep(player_ids: Array, sleepers: Dictionary) -> bool:
	return not player_ids.is_empty() and asleep_count(player_ids, sleepers) == player_ids.size()


static func asleep_count(player_ids: Array, sleepers: Dictionary) -> int:
	var n := 0
	for id: Variant in player_ids:
		if sleepers.has(id):
			n += 1
	return n


## The players whose home was the bed at `pos`, when that cell turns into `new_id`.
## homes: {player: bed position}.
static func lost_homes(homes: Dictionary, pos: Vector3i, new_id: int) -> Array:
	var lost := []
	if new_id == BlockIds.BED:
		return lost
	for key: Variant in homes:
		if homes[key] == pos:
			lost.append(key)
	return lost


## Where going home takes a player: just above their bed, beside it when the bed has no room to
## stand (wake_position: a low ceiling put players on top of it, found by the acceptance tour), or
## the world spawn column when they have none or it is gone. bed_id: the block in the bed's cell now
## (UNLOADED when that area is not loaded: go there and check on arrival). get_block reads the loaded
## bed's surroundings. A NAN height means "on the surface there" (Player.spawn_at).
static func home_target(has_home: bool, bed: Vector3i, bed_id: int, spawn_column: Vector2i, get_block: Callable) -> Vector3:
	if has_home and bed_id == BlockIds.BED:
		var spot := wake_position(bed, get_block)
		return home_position(bed) if spot == lie_position(bed) else spot
	if has_home and bed_id == UNLOADED:
		return home_position(bed)
	return Vector3(spawn_column.x + 0.5, NAN, spawn_column.y + 0.5)


static func _top_center(bed: Vector3i) -> Vector3:
	return Vector3(bed.x + 0.5, bed.y + TOP, bed.z + 0.5)
