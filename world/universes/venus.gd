extends RefCounted
## World 24, Venus's cloud city (cosmos, spec §21b.2): Venus's ground is hotter than an oven (about 465 °C) and crushed
## by its thick air, but about 50 km up the air presses like Earth's and a balloon full of the air we breathe floats:
## scientists have imagined airships and floating cities there. A space world like the Moon, Mars, Europa, Io, Titan and
## Mercury (off the universe ladder, reached by a mission or by flying up: SpaceRules). Its descriptor for
## UniverseRegistry (the interface is in universe_registry.gd, the space fields in its SPACE table): round platforms
## joined by bridges over the yellow clouds, gardens and homes on them, the airship dock with the Research Blimp moored
## at it, the cloud scope and the west lookout (SpaceShape VENUS, VenusTerrain, SpaceGenerator; the secrets in its
## blocks: SpaceSecretRules), real gravity (0.9 of Earth's), peace, a hazy golden sky of its own with the Sun a little
## bigger than at home and rising in the west (Venus spins backwards: SkyCycle.sun_west), Earth and our Moon as tiny
## points, soft lightning far below in the clouds (VenusLightning), a gentle wind, no animals (no life we know of). A
## child who falls off a deck is lifted back to the city by a warm breeze long before the clouds (`has_void`,
## `void_y`, `void_words`: DragonRules): the acid clouds and the heat far below are facts to learn, never a danger.
## Every find and every sight says a real Venus fact (checked: docs/devlog/parts/cosmos-venus.md); no mission names.

var name := &"venus"
var display_name := "Venus"
var index := 24
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Venus's real gravity: 8.87 m/s² against Earth's 9.81, 90 %.
var gravity := 0.9
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Thick air: a sky of its own, all day; never space's black, never Earth's photo sky.
var space_sky := 0.0
var photo_sky := false
## Venus is closer to the Sun (0.72 of Earth's distance): the Sun looks about 1.4 times as big (SkyCycle.sun_size).
var sun_size := 1.4
## Under a glaring cloud deck the white clouds and the city washed out: its noon light is 0.8 of home's (SkyCycle.sun_light;
## the visuals brief).
var sun_light := 0.8
## Venus spins backwards: its Sun rises in the west and sets in the east (SkyCycle.sun_west).
var sun_rises_west := true
## The city floats over the clouds: fall off and a warm breeze lifts you back, long before the clouds (DragonRules).
var has_void := true
var void_y := VenusTerrain.LIFT_Y
var void_words := "Whoosh! A warm breeze lifted you back up to the city."
var animals: Array[StringName] = []
## Earth and our Moon as two tiny points (SkyCycle.show_planet); Venus has no moon: home's moon disc never shows.
var sky_planet := {"color": Color("3f8fe0"), "land": Color("5cb85c"), "ring": false, "size": 5.0, "own_moons": true,
	"moons": [
		{"color": Color("d8d8d8"), "land": Color("bdbdbd"), "size": 2.5, "dir": Vector3(0.58, 0.44, -0.69)},
	]}
var landing_words := "You landed on Venus's cloud city! Far below, the clouds hide ground hotter than an oven."
## No loops of its own (Green Meadows' play); a gentle piece by day, a calm one at night.
var music := {}
var classical: Array[StringName] = [&"fur_elise", &"air"]
## A gentle wind by day (the city rides Venus's winds), soft chimes at night.
var ambience := {"day": &"wind", "night": &"chimes"}
## The daytime colours: a hazy golden sky over pale yellow clouds, a warm haze far away, a peach glow at sunrise and
## sunset (FlightLooks.SKY keeps the flight's picture of it the same).
var sky := {
	"sky_top": Color(0.92, 0.78, 0.45),
	"sky_horizon": Color(1.0, 0.92, 0.7),
	"ground_bottom": Color(0.86, 0.7, 0.38),
	"ground_horizon": Color(1.0, 0.9, 0.62),
	"fog": Color(0.98, 0.87, 0.6),
	"sunset": Color(1.0, 0.74, 0.5),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.CLOUD_DECK: 1, BlockIds.FLOAT_HULL: 1, BlockIds.SKY_TURF: 1, BlockIds.SKY_BRIDGE: 1, BlockIds.CLOUD_LAMP: 3,
	BlockIds.SKY_FRAME: 1, BlockIds.HOME_PANEL: 2, BlockIds.BLIMP_SKIN: 2, BlockIds.BLIMP_STRIPE: 2, BlockIds.GONDOLA: 3,
	BlockIds.SOLAR_FILM: 3, BlockIds.CLOUD_CRYSTAL: 3, BlockIds.TELESCOPE: 4, BlockIds.VENUS_CLOUD: 1,
	BlockIds.DEEP_CLOUD: 1, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Venus's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Venus treasure! Venus is almost as big as Earth: it is called Earth's twin.",
	SecretRules.ROOM: "You found a hidden room! Far below the clouds, Venus's ground is about 465 °C, hotter than an oven.",
	SecretRules.TEMPLE: "You found the explorers' treasure! Venus is the hottest planet, though Mercury is closer to the Sun.",
	SecretRules.ISLAND: "You found the Research Blimp! In 1985 two robot balloons floated in Venus's clouds for two days.",
	SecretRules.GEODE: "You found a cloud crystal geode! Venus's cloud tops race round the planet in about 4 Earth days.",
}
## Venus's sights (SpaceSights): where they are is VenusTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"scope": {"name": "Cloud Scope",
		"words": "You found the cloud scope! The yellow clouds far below are made of tiny drops of sulfuric acid."},
	&"dock": {"name": "Airship Dock",
		"words": "You found the airship dock! Here a balloon full of the air we breathe floats: Venus's air is heavier."},
	&"garden": {"name": "Sky Garden",
		"words": "You found the sky garden! About 50 km up, Venus's air presses as gently as the air at home."},
	&"homes": {"name": "Cloud Homes",
		"words": "You found the cloud homes! A day on Venus lasts longer than its year: 243 Earth days, not 225."},
	&"lookout": {"name": "West Lookout",
		"words": "You found the west lookout! Venus spins backwards, so here the Sun rises in the west."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.VENUS)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.VENUS
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
