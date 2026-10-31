extends RefCounted
## A stand-in universe descriptor for tests (M3 Task 5): the interface every
## world/universes/<name>.gd follows (see UniverseRegistry), on flat stone ground at y = HEIGHT.

const HEIGHT := 40


class FlatShape extends MeadowsShape:
	func height_at(_x: int, _z: int) -> int:
		return HEIGHT

	func is_river(_x: int, _z: int) -> bool:
		return false

	func tree_at(_x: int, _z: int) -> bool:
		return false

	func spawn_column() -> Vector2i:
		return Vector2i(3, 5)


var name := &"testland"
var display_name := "Test Land"
var index := 2
var monster_kinds: Array[StringName] = [&"mummy", &"scorpion"]
var boss_kind := &"serpent"
var music := {"day": "res://assets/music/night.ogg"}
var sky := {"sky_top": Color(1.0, 0.6, 0.3), "sky_horizon": Color(1.0, 0.85, 0.6)}
var trader_stock := {BlockIds.COAL: 2}


func generator_shape(world_seed: int) -> MeadowsShape:
	return FlatShape.new(world_seed)


func generator(_world_seed: int) -> VoxelGenerator:
	var g := VoxelGeneratorFlat.new()
	g.channel = VoxelBuffer.CHANNEL_TYPE
	g.voxel_type = BlockIds.STONE
	g.height = HEIGHT
	return g
