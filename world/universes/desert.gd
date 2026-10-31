extends RefCounted
## Universe 2, the Sandstorm Desert (M3 Task 2, spec §14.1): its descriptor for the universe ladder (M3
## Task 5's UniverseRegistry loads it by path, world/universes/desert.gd). The interface every universe
## file follows: name, display_name, index, generator_shape(seed) (a MeadowsShape), generator(seed),
## monster_kinds, boss_kind, music, sky, trader_stock. The desert adds three optional fields the world
## reads when they are there: secret_rules(seed, shape) (its five kinds of secrets), secret_words (what a
## find says) and weather (&"sandstorm"); `traps` puts the desert's cactus and arrow slits to work.

var name := &"desert"
var display_name := "Sandstorm Desert"
var index := 2
var monster_kinds: Array[StringName] = MonsterRules.DESERT_KINDS
var boss_kind := BossRules.SERPENT
## CC0 loops by iamoneabe (tools/make_desert_music.py); the boss fight keeps Green Meadows' boss loop.
var music := {"day": "res://assets/music/desert_day.ogg", "night": "res://assets/music/desert_night.ogg"}
## The daytime colours: a pale, hot blue overhead and a sandy haze at the horizon.
var sky := {
	"sky_top": Color(0.36, 0.6, 0.92),
	"sky_horizon": Color(1.0, 0.87, 0.64),
	"ground_bottom": Color(0.72, 0.58, 0.38),
	"ground_horizon": Color(1.0, 0.87, 0.64),
	"fog": Color(0.98, 0.86, 0.66),
}
## Tilly's local things: gold for one block, in Green Meadows gold (the ladder scales it by 2^(u-1)).
var trader_stock := {
	BlockIds.SANDSTONE: 1, BlockIds.CUT_SANDSTONE: 1, BlockIds.CHISELED_SANDSTONE: 2, BlockIds.RED_SAND: 1,
	BlockIds.RED_SANDSTONE: 1, BlockIds.CACTUS: 3, BlockIds.DEAD_BUSH: 1, BlockIds.DESERT_GLASS: 2,
	BlockIds.PALM_LOG: 1, BlockIds.PALM_LEAVES: 1, BlockIds.DESERT_LAMP: 5,
}
var weather := &"sandstorm"
## The audio pass: a dry wind over the dunes by day, crickets at night (AmbienceSoundRules).
var ambience := {"day": &"wind", "night": &"crickets"}
var traps := true
## Owner #41: its animals (spec §14.19): camels, lizards and fennec foxes.
var animals: Array[StringName] = [&"camel", &"lizard", &"fennec"]
## What finding each kind of the desert's secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried treasure!",
	SecretRules.ROOM: "You found a hidden room in the rock!",
	SecretRules.TEMPLE: "You found the pyramid's treasure room!",
	SecretRules.ISLAND: "You found a floating rock!",
	SecretRules.GEODE: "You found a crystal geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return DesertShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := DesertGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return DesertSecretRules.new(world_seed, shape)
