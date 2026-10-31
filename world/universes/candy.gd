extends RefCounted
## Universe 4, the Candy Kingdom (M3 Task 4, spec §14.1): its descriptor for the universe ladder (M3 Task 5's
## UniverseRegistry loads it by path, world/universes/candy.gd; the interface is in universe_registry.gd). Like
## the desert's, plus the kingdom's own optional fields: `weather` &"sprinkles" (sprinkles fall at night:
## CandySprinkles), `liquid` &"chocolate" (the water looks like chocolate: its rivers swim like water) and
## `classical` (the classical pieces that fit it, for the audio pass: owner feedback #31).
## Universe 4; since owner #39 the Dragon Realm (5) follows, so its boss opens a portal there (BossDirector); the last
## universe's boss opens the hub (UniverseRules.HUB).

var name := &"candy"
var display_name := "Candy Kingdom"
var index := 4
var monster_kinds: Array[StringName] = MonsterRules.CANDY_KINDS
var boss_kind := BossRules.CAKE
## An original music-box waltz and its lullaby (tools/make_candy_music.py, CC0); the boss fight keeps Green
## Meadows' boss loop.
var music := {"day": "res://assets/music/candy_day.ogg", "night": "res://assets/music/candy_night.ogg"}
## The classical pieces it plays first (MusicPieces ids; M5 Task 2, spec §15.2): The Nutcracker's Waltz of the Flowers
## (the Land of Sweets) and its own Minute Waltz by Chopin. No public-domain recording of the Sugar Plum Fairy exists
## (checked again: only CC BY / BY-SA ones and noisy 1921 discs), so it is not here.
var classical: Array[StringName] = [&"waltz_flowers", &"minute_waltz"]
## M5 Task 2: its own ambience: wind chimes by day, the chocolate river's brook at night.
var ambience := {"day": &"chimes", "night": &"brook"}
## The daytime colours: a candy-pink sky over a pale strawberry-milk horizon.
var sky := {
	"sky_top": Color(0.95, 0.56, 0.8),
	"sky_horizon": Color(1.0, 0.86, 0.93),
	"ground_bottom": Color(0.78, 0.52, 0.66),
	"ground_horizon": Color(1.0, 0.86, 0.93),
	"fog": Color(1.0, 0.86, 0.93),
}
## Tilly's local things: gold for one block, in Green Meadows gold (the ladder scales it by 2^(u-1)).
var trader_stock := {
	BlockIds.FROSTING: 1, BlockIds.CAKE: 1, BlockIds.CHOCOLATE: 1, BlockIds.CANDY_CANE: 2, BlockIds.LOLLIPOP: 2,
	BlockIds.GUMDROP: 2, BlockIds.RED_GUMDROP: 2, BlockIds.CREAM: 1, BlockIds.JAM: 1, BlockIds.SUGAR_GLASS: 2,
	BlockIds.GINGERBREAD: 2, BlockIds.CANDY_LAMP: 5, BlockIds.COTTON_CANDY: 1, BlockIds.SPRINKLES: 2,
}
var weather := &"sprinkles"
var liquid := &"chocolate"
## Owner #41: its animals (spec §14.19): gummy bunnies and candy birds.
var animals: Array[StringName] = [&"gummy_bunny", &"candy_bird"]
## What finding each kind of the kingdom's secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried candy treasure!",
	SecretRules.ROOM: "You found a hidden room in the cake!",
	SecretRules.TEMPLE: "You found the gingerbread house's treasure!",
	SecretRules.ISLAND: "You found a floating cake!",
	SecretRules.GEODE: "You found a rock-candy geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return CandyShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := CandyGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return CandySecretRules.new(world_seed, shape)
