extends RefCounted
## Universe 1, Green Meadows: the world of M1–M2 (M3 Task 5, spec §5.1). Its descriptor for the
## universe ladder (UniverseRegistry has the interface): the Meadows terrain, slimes and goblins, the
## Stone Golem, the M2 music, the default sky, Tilly's usual shop.

var name := &"meadows"
var display_name := "Green Meadows"
var index := 1
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var music := {}          # the M2 day, night and boss loops (Music's own)
var sky := {}            # the default blocky sky (world.tscn, DayCycle)
var trader_stock := {}   # nothing extra: ShopRules' catalog
## Owner #41: its animals (AnimalHomes places the new kinds where they fit; spec §14.19).
var animals: Array[StringName] = AnimalRules.MEADOWS_KINDS
## Owner #41: bees and butterflies flutter over the meadow by day (MeadowInsects).
var insects := true


func generator_shape(world_seed: int) -> MeadowsShape:
	return MeadowsShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := MeadowsGenerator.new()
	g.world_seed = world_seed
	return g


# --- Owner #45b: the wild meadows (terrain version 2, new worlds only) ---

func terrain_shape(world_seed: int, terrain: int) -> MeadowsShape:
	return MeadowsBiomeShape.new(world_seed) if terrain >= MeadowsBiomeShape.TERRAIN else MeadowsShape.new(world_seed)


func terrain_generator(world_seed: int, terrain: int) -> VoxelGenerator:
	if terrain < MeadowsBiomeShape.TERRAIN:
		return generator(world_seed)
	var g := MeadowsBiomeGenerator.new()
	g.world_seed = world_seed
	return g


## The secrets on the world's own terrain (the host's and every guest's: a guest's SecretDirector starts from the
## old meadows' rules until the sandbox hands it these).
func secret_rules(world_seed: int, shape: MeadowsShape) -> SecretRules:
	return SecretRules.new(world_seed, shape)
