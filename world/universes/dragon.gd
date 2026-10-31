extends RefCounted
## Universe 5, the Dragon Realm (owner feedback #39, spec §14.2a): its descriptor for the universe ladder (M3 Task 5's
## UniverseRegistry loads it by path, world/universes/dragon.gd; the interface is in universe_registry.gd). Floating
## islands over a starry purple void (DragonShape, DragonGenerator), dragon nests and the other secrets
## (DragonSecretRules), and the realm's own field `has_void` (fall off and the wind carries you back: DragonRules; named
## so because `void` is a GDScript keyword). Universe 5 is the last on the ladder: its boss opens a portal to the hub.

var name := &"dragon"
var display_name := "Dragon Realm"
var index := 5
var monster_kinds: Array[StringName] = MonsterRules.DRAGON_KINDS   # owner 39: shadow bats and wisp spirits
var boss_kind := BossRules.SKY_DRAGON   # owner 39: Monster Wave's raid boss here
## No loops of its own (Green Meadows' play); the classical pieces below come first (the audio pass).
var music := {}
## Public-domain pieces already in the game (MusicPieces): Satie's dreamy Gymnopédie for the floating islands, Grieg's
## In the Hall of the Mountain King for the dragon's fights.
var classical: Array[StringName] = [&"gymnopedie", &"mountain_king"]
## A windy sky by day (the islands are high up), crickets at night.
var ambience := {"day": &"wind", "night": &"crickets"}
## The daytime colours (owner #43, spec §3c: a sunrise, never black and purple): a clear morning blue overhead, a
## golden peach horizon, warm peach fog, and below the islands a bright sea of clouds.
var sky := {
	"sky_top": Color(0.46, 0.66, 0.95),
	"sky_horizon": Color(1.0, 0.84, 0.62),
	"ground_bottom": Color(0.98, 0.91, 0.9),
	"ground_horizon": Color(1.0, 0.88, 0.78),
	"fog": Color(1.0, 0.87, 0.76),
}
## Tilly's local things: gold for one block, in Green Meadows gold (the ladder scales it by 2^(u-1)).
var trader_stock := {
	BlockIds.SKY_GRASS: 1, BlockIds.FLOATSTONE: 1, BlockIds.DEEP_FLOATSTONE: 1, BlockIds.FLOATSTONE_BRICK: 1,
	BlockIds.CRYSTAL_SPIRE: 3, BlockIds.MUSHROOM_STEM: 1, BlockIds.GLOW_CAP: 2, BlockIds.DRAGON_SCALE: 2,
	BlockIds.EMBER_SCALE: 2, BlockIds.STARGLASS: 2, BlockIds.MOON_LAMP: 5, BlockIds.CLOUD: 1, BlockIds.NEST: 2,
}
## Floating islands over a void: falling off carries you back (DragonRules).
var has_void := true
## What finding each kind of the realm's secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried dragon treasure!",
	SecretRules.ROOM: "You found a hidden room in the island!",
	SecretRules.TEMPLE: "You found the sky shrine's treasure!",
	SecretRules.ISLAND: "You found a dragon nest!",
	SecretRules.GEODE: "You found a sun crystal geode!",   # owner #43: the realm's crystals are golden
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return DragonShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := DragonGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return DragonSecretRules.new(world_seed, shape)
