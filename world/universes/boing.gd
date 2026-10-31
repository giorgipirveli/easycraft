extends RefCounted
## World 17, Planet Boing (owner feedback #55, spec §21): a space world, off the universe ladder, reached by flying up
## (SpaceRules). Its descriptor for UniverseRegistry (interface in universe_registry.gd, the space fields in its SPACE
## table): rolling lime moss hills with pink jelly pools and spring mushrooms (SpaceShape, SpaceGenerator) — moss, jelly
## and spring caps bounce a landing child (CandyRules.is_gumdrop) —, the Boing Tower and the secrets in its blocks
## (SpaceSecretRules), gravity 0.6, peace, a violet sky with a ringed planet in it, frogs and goats.

var name := &"boing"
var display_name := "Planet Boing"
var index := 17
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
var gravity := 0.6
## A ringed planet, golden-orange, hanging in the violet sky (SkyCycle.show_planet).
var sky_planet := {"color": Color("ffb347"), "land": Color("ffd98a"), "ring": true, "size": 64.0}
var landing_words := "You landed on Planet Boing! Everything bounces!"
var music := {}
var classical: Array[StringName] = [&"nachtmusik", &"spring"]
## A babbling brook by day (the jelly pools), crickets at night.
var ambience := {"day": &"brook", "night": &"crickets"}
## The daytime colours: a violet sky over a pink horizon.
## Its own sky in the realistic style too (the photo sky is Earth's blue with clouds).
var photo_sky := false
var sky := {
	"sky_top": Color(0.48, 0.31, 0.84),
	"sky_horizon": Color(0.9, 0.72, 1.0),
	"ground_bottom": Color(0.78, 0.64, 0.95),   # the haze under the horizon, never a dark band
	"ground_horizon": Color(0.9, 0.72, 1.0),
	"fog": Color(0.86, 0.72, 0.98),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space).
var trader_stock := {
	BlockIds.BOING_MOSS: 1, BlockIds.BOING_SOIL: 1, BlockIds.BOING_ROCK: 1, BlockIds.JELLY: 2, BlockIds.SPRING_STEM: 1,
	BlockIds.SPRING_CAP: 2, BlockIds.BOING_GLOW: 4, BlockIds.BOING_BRICK: 2, BlockIds.LANDING_PAD: 4,
}
var animals: Array[StringName] = [&"frog", &"goat"]
var secret_words := {
	SecretRules.TREASURE: "You found buried bouncy treasure!",
	SecretRules.ROOM: "You found a hidden room!",
	SecretRules.TEMPLE: "You found the jelly temple's treasure!",
	SecretRules.ISLAND: "You reached the top of the Boing Tower!",
	SecretRules.GEODE: "You found a glowing geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.BOING)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.BOING
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
