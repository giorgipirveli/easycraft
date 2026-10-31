extends RefCounted
## Universe 3, Frostpeak (M3 Task 3, spec §14.1): its descriptor for the universe ladder (M3 Task 5's
## UniverseRegistry loads it by path, world/universes/frost.gd), the desert's sibling: name, display_name,
## index, generator_shape(seed) (a MeadowsShape), generator(seed), monster_kinds, boss_kind, music, sky,
## trader_stock; and the desert's optional fields: secret_rules(seed, shape) (its five kinds of secrets),
## secret_words (what a find says) and weather (&"snowstorm": the desert's storm code in snow).

var name := &"frost"
var display_name := "Frostpeak"
var index := 3
var monster_kinds: Array[StringName] = MonsterRules.FROST_KINDS
var boss_kind := BossRules.FROST_GIANT
## CC0 loops by zesona and écrivain (tools/make_frost_music.py); the boss keeps Green Meadows' boss loop.
var music := {"day": "res://assets/music/frost_day.ogg", "night": "res://assets/music/frost_night.ogg"}
## The daytime colours: a crisp, clear blue overhead, a pale snowy haze at the horizon.
var sky := {
	"sky_top": Color(0.42, 0.66, 0.93),
	"sky_horizon": Color(0.86, 0.92, 0.98),
	"ground_bottom": Color(0.78, 0.83, 0.88),
	"ground_horizon": Color(0.86, 0.92, 0.98),
	"fog": Color(0.88, 0.92, 0.97),
}
## Tilly's local things: gold for one block, in Green Meadows gold (the ladder scales it by 2^(u-1)).
var trader_stock := {
	BlockIds.SNOW: 1, BlockIds.SNOWY_GRASS: 1, BlockIds.PACKED_SNOW: 1, BlockIds.SNOW_BRICK: 1, BlockIds.ICE: 2,
	BlockIds.BLUE_ICE: 3, BlockIds.PINE_LOG: 1, BlockIds.PINE_NEEDLES: 1, BlockIds.FROSTED_GLASS: 2,
	BlockIds.ICE_LANTERN: 5,
}
var weather := &"snowstorm"
## M5 Task 2 (spec §15.2): its own ambience (a cold wind with a soft whistle by day, a quiet snowy pine forest at night)
## and its own classical pieces, played first (Vivaldi's Winter, Debussy's The Snow Is Dancing; MusicPieces "own").
var ambience := {"day": &"snow_wind", "night": &"snow_night"}
var classical: Array[StringName] = [&"winter_largo", &"snow_dancing"]
## Owner #41: its animals (spec §14.19): penguins, a gentle polar bear, arctic foxes and seals.
var animals: Array[StringName] = [&"penguin", &"polar_bear", &"arctic_fox", &"seal"]
## What finding each kind of Frostpeak's secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried treasure!",
	SecretRules.ROOM: "You found a secret room under the igloo!",
	SecretRules.TEMPLE: "You found the ice temple's treasure room!",
	SecretRules.ISLAND: "You found a floating iceberg!",
	SecretRules.GEODE: "You found a crystal geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return FrostShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := FrostGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return FrostSecretRules.new(world_seed, shape)
