extends RefCounted
## World 18, Rainbow Planet (owner feedback #55, spec §21): a space world, off the universe ladder, reached by flying up
## (SpaceRules). Its descriptor for UniverseRegistry (interface in universe_registry.gd, the space fields in its SPACE
## table): terraced hills striped in the rainbow's six colours with prism grass on top and glowing prism crystal spires
## (SpaceShape, SpaceGenerator), the Rainbow Arch and the secrets in its blocks (SpaceSecretRules), gravity 0.8, peace,
## a lilac sky with a pink planet in it, candy birds and horses.

var name := &"rainbow"
var display_name := "Rainbow Planet"
var index := 18
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
var gravity := 0.8
## A soft pink planet in the lilac sky (SkyCycle.show_planet).
var sky_planet := {"color": Color("ff9fcf"), "land": Color("fff0f8"), "ring": false, "size": 54.0}
var landing_words := "You landed on Rainbow Planet! Find the Rainbow Arch!"
var music := {}
var classical: Array[StringName] = [&"waltz_flowers", &"morning_mood"]
## Wind chimes by day, crickets at night.
var ambience := {"day": &"chimes", "night": &"crickets"}
## The daytime colours: lilac overhead, a pale pink horizon.
## Its own sky in the realistic style too (the photo sky is Earth's blue with clouds).
var photo_sky := false
var sky := {
	"sky_top": Color(0.73, 0.64, 0.96),
	"sky_horizon": Color(1.0, 0.88, 0.96),
	"ground_bottom": Color(0.8, 0.72, 0.95),
	"ground_horizon": Color(1.0, 0.88, 0.96),
	"fog": Color(0.98, 0.88, 0.97),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space).
var trader_stock := {
	BlockIds.PRISM_GRASS: 1, BlockIds.RAINBOW_RED: 1, BlockIds.RAINBOW_ORANGE: 1, BlockIds.RAINBOW_YELLOW: 1,
	BlockIds.RAINBOW_GREEN: 1, BlockIds.RAINBOW_BLUE: 1, BlockIds.RAINBOW_VIOLET: 1, BlockIds.PRISM_CRYSTAL: 3,
	BlockIds.PRISM_BRICK: 2, BlockIds.PRISM_LAMP: 4, BlockIds.LANDING_PAD: 4,
}
var animals: Array[StringName] = [&"candy_bird", &"horse"]
var secret_words := {
	SecretRules.TREASURE: "You found buried rainbow treasure!",
	SecretRules.ROOM: "You found a hidden room in the stripes!",
	SecretRules.TEMPLE: "You found the prism temple's treasure!",
	SecretRules.ISLAND: "You reached the top of the Rainbow Arch!",
	SecretRules.GEODE: "You found a prism geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.RAINBOW)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.RAINBOW
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
