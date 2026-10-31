class_name OreRules
extends RefCounted
## Ore veins and crystal spots as pure functions of world position and seed. Each vein lives inside
## one world-aligned 16³ cell, so no chunk ever cuts a vein in half. Ores replace only stone and
## deep stone; crystals grow on stone right above or below a dry cave, deep underground.

const CELL := 16
const MAX_VEIN := 12
## Inclusive y band per ore: coal high up, iron in the middle, gold deep, diamond only below -30.
const DEPTH := {
	BlockIds.COAL: Vector2i(0, 90),
	BlockIds.IRON: Vector2i(-24, 40),
	BlockIds.GOLD: Vector2i(-60, -8),
	BlockIds.DIAMOND: Vector2i(-60, -31),
}
## [ore, vein attempts per cell, min size, max size]
const VEINS := [
	[BlockIds.COAL, 10, 6, 12],
	[BlockIds.IRON, 7, 4, 8],
	[BlockIds.GOLD, 4, 3, 6],
	[BlockIds.DIAMOND, 2, 2, 5],
]
const CRYSTAL_MAX_Y := -20        # crystals only below this
const CRYSTAL_PER_MILLE := 30     # chance for a stone block that touches a cave
const _STEPS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]

var seed: int


func _init(world_seed: int) -> void:
	seed = world_seed


## Veins of cell (world position / 16): [{"ore": id, "blocks": Array[Vector3i]}, ...].
func veins_in_cell(cell: Vector3i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(cell.x, cell.y, cell.z)
	var base := cell * CELL
	var veins: Array = []
	for v: Array in VEINS:
		var ore: int = v[0]
		var band: Vector2i = DEPTH[ore]
		for attempt: int in v[1]:
			# Draw everything first, so the random sequence never depends on the depth checks.
			var p := base + Vector3i(rng.randi_range(0, CELL - 1), rng.randi_range(0, CELL - 1), rng.randi_range(0, CELL - 1))
			var size := rng.randi_range(v[2], v[3])
			var blocks: Array[Vector3i] = []
			for i in size:
				if p.y >= band.x and p.y <= band.y and not blocks.has(p):
					blocks.append(p)
				p = (p + _STEPS[rng.randi_range(0, 5)]).clamp(base, base + Vector3i(CELL - 1, CELL - 1, CELL - 1))
			if not blocks.is_empty():
				veins.append({"ore": ore, "blocks": blocks})
	return veins


## The ore at world position p, or -1 (slow: rebuilds the cell's veins; for references and tools).
func ore_at(p: Vector3i) -> int:
	var cell := Vector3i(floori(p.x / float(CELL)), floori(p.y / float(CELL)), floori(p.z / float(CELL)))
	for vein: Dictionary in veins_in_cell(cell):
		if (vein.blocks as Array).has(p):
			return vein.ore   # the first vein wins: the generator's later veins only replace stone
	return -1


## True where a stone block that touches a dry cave above or below becomes a glowing crystal.
func crystal_chance(p: Vector3i) -> bool:
	return p.y < CRYSTAL_MAX_Y and _mix(p.x * 3 + 1, p.y * 5 - 7, p.z * 7 + 3) % 1000 < CRYSTAL_PER_MILLE


func _mix(x: int, y: int, z: int) -> int:
	var h := x * 73856093 ^ y * 19349663 ^ z * 83492791 ^ seed * 2654435761
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return h & 0x7fffffffffffffff
