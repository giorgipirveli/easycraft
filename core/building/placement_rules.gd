class_name PlacementRules
extends RefCounted
## Rules for editing blocks: reach, valid ids, and never placing a block inside a player.
## The host runs validate_edit on every request, including its own.

const REACH := 10.0
const REACH_TOLERANCE := 2.0   # host-side slack for network latency
const BATCH_REACH := 32.0      # mirror copies and stamps reach further than a single tap
const PLAYER_RADIUS := 0.3
const PLAYER_HEIGHT := 1.8


## How far a tap ray must reach: from the (possibly far-away, e.g. Giant) camera to the eye,
## plus the building reach.
static func ray_length(camera_pos: Vector3, eye: Vector3) -> float:
	return camera_pos.distance_to(eye) + REACH + 1.0


static func player_aabb(feet: Vector3, scale: float = 1.0) -> AABB:
	var r := PLAYER_RADIUS * scale
	return AABB(feet - Vector3(r, 0.0, r), Vector3(r * 2.0, PLAYER_HEIGHT * scale, r * 2.0))


## True if block `id` may be placed at block_pos without overlapping any player body.
static func can_place(block_pos: Vector3i, player_aabbs: Array[AABB], id: int) -> bool:
	if not BlockIds.is_valid(id):
		return false
	var block := AABB(Vector3(block_pos), Vector3.ONE)
	for body in player_aabbs:
		if body.intersects(block):
			return false
	return true


static func in_reach(eye: Vector3, block_pos: Vector3i, reach: float = REACH) -> bool:
	return eye.distance_to(Vector3(block_pos) + Vector3(0.5, 0.5, 0.5)) <= reach


const BEDROCK_MESSAGE := "Bedrock can't be broken!"
const TOO_FAR_MESSAGE := "That's too far away!"
const BODY_MESSAGE := "Someone is standing there!"
const INVALID_MESSAGE := "You can't place that."


## Host-side check for a set-block request. id == AIR means "break". current_id is the block in
## the cell now (world.get_block): unbreakable blocks (bedrock) can be neither broken nor replaced.
## It has no default on purpose: a caller that forgets it fails to compile instead of passing
## the cell as air and editing bedrock (review M1).
static func validate_edit(block_pos: Vector3i, id: int, current_id: int, requester_eye: Vector3,
		player_aabbs: Array[AABB], reach: float = REACH + REACH_TOLERANCE) -> bool:
	return refusal(block_pos, id, current_id, requester_eye, player_aabbs, reach) == ""


## Why an edit is refused, as a short friendly message for the player ("" = allowed).
static func refusal(block_pos: Vector3i, id: int, current_id: int, requester_eye: Vector3,
		player_aabbs: Array[AABB], reach: float = REACH + REACH_TOLERANCE) -> String:
	if not BlockIds.is_breakable(current_id):
		return BEDROCK_MESSAGE
	if not in_reach(requester_eye, block_pos, reach):
		return TOO_FAR_MESSAGE
	if id == BlockIds.AIR:
		return ""
	if not BlockIds.is_valid(id):
		return INVALID_MESSAGE
	return "" if can_place(block_pos, player_aabbs, id) else BODY_MESSAGE
