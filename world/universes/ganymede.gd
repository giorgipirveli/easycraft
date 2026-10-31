extends RefCounted
## World 28, Ganymede (cosmos, spec §21b.2): Jupiter's biggest moon, the biggest moon of all (bigger than the planet
## Mercury) and the only one with its own magnetic field, a space world like the Moon, Mars, Europa, Io, Titan, Mercury,
## Venus's cloud city, Saturn's rings, Pluto and Triton (off the universe ladder, reached by a mission or by flying up:
## SpaceRules). Its descriptor for UniverseRegistry (the interface is in universe_registry.gd, the space fields in its
## SPACE table): the landing pad on a smooth plain of bright ice, the bright grooved terrain round it (long parallel ridges
## and grooves), the old dark terrain to the west (furrows, old craters), a young bright ray crater with a pit to the east,
## frost at the poles (SpaceShape GANYMEDE, GanymedeTerrain, SpaceGenerator), the Jupiter Lookout by the pad, the Aurora
## Watch on the northern frost and the ocean drill (GanymedeTerrain.place_parts), the Solar Wing Lander and the secrets in
## Ganymede's blocks (SpaceSecretRules), its real gravity (0.146 of Earth's: long, floaty jumps), peace, space's black
## starry sky (almost no air) with Jupiter big and banded in the east, never moving, Io and Europa swinging past it as
## bright dots, the Sun small (5 times as far as from Earth), and its auroras: glowing belts over the poles at night
## (GanymedeSky), soft chimes, calm music, no animals. Every find and every sight says a real fact (checked:
## docs/devlog/parts/cosmos-ganymede.md); no mission names.

var name := &"ganymede"
var display_name := "Ganymede"
var index := 28
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Ganymede's real gravity: 1.428 m/s² against Earth's 9.81, about 15 %: a jump floats ~11 blocks up and lasts ~5 s.
var gravity := 0.146
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Almost no air (a very thin breath of oxygen): space's black sky with stars all day, like Europa's; never Earth's photo
## sky.
var space_sky := 1.0
var photo_sky := false
## Ganymede goes round the Sun with Jupiter, about 5.2 times as far out as Earth: the Sun looks about 5 times smaller.
var sun_size := 0.19
var animals: Array[StringName] = []
## Jupiter, big and banded with its Great Red Spot, up in the east: Ganymede always shows Jupiter the same face, so it
## never moves in this sky (SkyCycle.show_planet: `dir`, `bands`, `spot`; smaller than from Europa and Io, which are
## nearer to it); Io (sulphur-yellow) and Europa (icy white) as bright dots, which GanymedeSky swings back and forth past
## Jupiter as they go round it inside Ganymede's orbit; Jupiter's moons, not home's: no moon disc at night. (Jupiter really
## is about 7.6° across from Ganymede, 15 times our Moon's width; the game's sky is not to scale, like every world's.)
var sky_planet := {"color": Color("e3cfa8"), "land": Color("b0714a"), "ring": false, "size": 80.0, "bands": true,
	"spot": true, "dir": Vector3(0.9, 0.33, -0.2), "own_moons": true,
	"moons": [
		{"color": Color("e8d04a"), "land": Color("d9772b"), "size": 4.0, "dir": Vector3(0.97, 0.2, -0.15)},
		{"color": Color("eae3d2"), "land": Color("c9a98a"), "size": 5.0, "dir": Vector3(0.66, 0.68, -0.25)},
	]}
var landing_words := "You landed on Ganymede, the biggest moon of all! Jupiter hangs big in the sky to the east."
## No loops of its own (Green Meadows' play); Mozart by day under Jupiter, Bach's Air for the auroras at night.
var music := {}
var classical: Array[StringName] = [&"nachtmusik", &"air"]
## Soft icy chimes by day and night (almost no air: no wind, no birds).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes the sky: `space_sky`): a deep blue glow at the horizon, like Europa's.
var sky := {
	"sky_top": Color(0.01, 0.01, 0.05),
	"sky_horizon": Color(0.08, 0.12, 0.26),
	"ground_bottom": Color(0.05, 0.06, 0.12),
	"ground_horizon": Color(0.08, 0.12, 0.26),
	"fog": Color(0.1, 0.13, 0.24),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.GROOVED_ICE: 1, BlockIds.TROUGH_ICE: 1, BlockIds.DARK_ICE: 1, BlockIds.OLD_ICE: 1, BlockIds.RAY_ICE: 1,
	BlockIds.POLAR_FROST: 1, BlockIds.WATER_ICE: 1, BlockIds.AURORA_CRYSTAL: 3, BlockIds.JUPITER_GLOBE: 4,
	BlockIds.AURORA_LAMP: 3, BlockIds.MAGNETOMETER: 3, BlockIds.GROOVE_BRICK: 2, BlockIds.TELESCOPE: 4,
	BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Ganymede's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Ganymede treasure! Galileo Galilei discovered Ganymede on 7 January 1610.",
	SecretRules.ROOM: "You found a hidden ice room! Ganymede is bigger than Mercury, but only about half as heavy.",
	SecretRules.TEMPLE: "You found the explorers' treasure! While Ganymede circles Jupiter once, Europa goes twice and Io 4 times.",
	SecretRules.ISLAND: "You found the Solar Wing Lander! Sunlight here is about 25 times weaker than on Earth: big wings help.",
	SecretRules.GEODE: "You found an aurora crystal geode! Ganymede's ice is about −160 °C, far colder than any freezer.",
}
## Ganymede's sights (SpaceSights): where they are is GanymedeTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"lookout": {"name": "Jupiter Lookout",
		"words": "You found the Jupiter Lookout! Ganymede always shows Jupiter the same face, so Jupiter never moves here."},
	&"grooves": {"name": "Grooved Terrain",
		"words": "You found the grooved terrain! Its long ridges, some 700 m high, formed as the icy crust stretched."},
	&"dark": {"name": "Dark Terrain",
		"words": "You reached the dark terrain! It is about 4 billion years old and full of old craters."},
	&"crater": {"name": "Bright Ray Crater",
		"words": "You found a bright ray crater! A crash threw fresh ice out across the ground in long, bright rays."},
	&"frost": {"name": "Polar Frost",
		"words": "You reached the polar frost! Ganymede's magnetic field steers Jupiter's particles here: they brighten the ice."},
	&"aurora": {"name": "Aurora Watch",
		"words": "You found the Aurora Watch! Ganymede's magnetic field makes auroras: look up at night for glowing belts!"},
	&"ocean": {"name": "Ocean Drill",
		"words": "You found the ocean drill! Ganymede's salty ocean lies about 150 km down: deeper than any drill."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.GANYMEDE)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.GANYMEDE
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
