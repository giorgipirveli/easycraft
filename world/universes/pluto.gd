extends RefCounted
## World 26, Pluto (cosmos, spec §21b.2): the dwarf planet a spacecraft flew past in 2015, a space world like the Moon,
## Mars, Europa, Io, Titan, Mercury, Venus's cloud city and Saturn's rings (off the universe ladder, reached by a mission
## or by flying up: SpaceRules). Its descriptor for UniverseRegistry (the interface is in universe_registry.gd, the space
## fields in its SPACE table): the heart a walk east of the landing pad (its west half a flat plain of nitrogen ice in
## slowly churning cells with floating hills of water ice on their edges, its east half bright frost), the ice mountains
## on the plain's south-west shore, the red-brown lands to the west (tholins, snowy hilltops, craters), peach-tan uplands
## (SpaceShape PLUTO, PlutoTerrain, SpaceGenerator), the Charon Lookout by the pad, the Balloon Lander and the secrets in
## Pluto's blocks (SpaceSecretRules), its real gravity (0.063 of Earth's: long, floaty jumps), peace, its own sky (a thin
## nitrogen air: black and starry by day, a blue haze along the horizon; the Sun a very bright star; Charon big in the
## west, never moving), soft chimes, calm music, no animals. It says kindly that Pluto is a dwarf planet, and why. Every
## find and every sight says a real fact (checked: docs/devlog/parts/cosmos-pluto.md); no mission names.

var name := &"pluto"
var display_name := "Pluto"
var index := 26
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Pluto's real gravity: 0.62 m/s² against Earth's 9.81, about 6 %: a jump floats ~27 blocks up and lasts ~12 s.
var gravity := 0.063
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## A thin nitrogen air, about 100,000 times thinner than Earth's: a black starry sky overhead by day, a blue haze glowing
## along the horizon (its haze really is blue, in many thin layers); never Earth's photo sky.
var space_sky := 0.55
var photo_sky := false
## Pluto is about 40 times as far from the Sun as Earth: the Sun looks 40 times smaller, a very bright star.
var sun_size := 0.025
## Pluto spins backwards, from east to west, like Venus: the Sun rises in the west (SkyCycle.sun_west).
var sun_rises_west := true
var animals: Array[StringName] = []
## Charon, big and grey with its red cap, low in the west: Pluto and Charon always face each other, so it never moves in
## this sky (SkyCycle.show_planet: `dir`, `cap`); Nix and Hydra tiny points of light; Pluto's, not home's: no moon disc at
## night. (Charon really is about 3.5° across from Pluto, 7 times our Moon's width; the game's sky is not to scale, like
## every world's.)
var sky_planet := {"color": Color("a8a39d"), "land": Color("8f8a84"), "cap": Color("8e4a33"), "size": 64.0,
	"dir": Vector3(-0.95, 0.26, -0.17), "own_moons": true,
	"moons": [
		{"color": Color("f2f0ec"), "land": Color("dcd8d2"), "size": 1.8, "dir": Vector3(-0.3, 0.8, 0.5)},
		{"color": Color("f4f2ee"), "land": Color("e0dcd6"), "size": 1.6, "dir": Vector3(0.45, 0.7, -0.55)},
	]}
var landing_words := "You landed on Pluto! Its heart of ice lies to the east, and Charon hangs still in the west."
## No loops of its own (Green Meadows' play); Vivaldi's Winter far out in the cold by day, the Moonlight Sonata under
## Charon at night.
var music := {}
var classical: Array[StringName] = [&"winter_largo", &"moonlight"]
## Soft icy chimes by day and night (its air is far too thin for wind to be heard; no birds, no crickets).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes most of the sky: `space_sky`): black overhead, a blue haze along the horizon
## and over the far ground.
var sky := {
	"sky_top": Color(0.02, 0.03, 0.08),
	"sky_horizon": Color(0.42, 0.62, 0.98),
	"ground_bottom": Color(0.42, 0.62, 0.98),   # the haze under the horizon, never a dark band over the far ground
	"ground_horizon": Color(0.42, 0.62, 0.98),
	"fog": Color(0.36, 0.5, 0.82),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.NITROGEN_ICE: 1, BlockIds.CELL_EDGE: 1, BlockIds.WATER_ICE: 1, BlockIds.PLUTO_FROST: 1,
	BlockIds.THOLIN_DUST: 1, BlockIds.RED_ICE: 1, BlockIds.METHANE_SNOW: 1, BlockIds.FROST_CRYSTAL: 3,
	BlockIds.DRAG_BALLOON: 2, BlockIds.CHARON_GLOBE: 4, BlockIds.HEART_BEACON: 3, BlockIds.FROST_BRICK: 2,
	BlockIds.TELESCOPE: 4, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Pluto's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Pluto treasure! An 11-year-old girl gave Pluto its name in 1930.",
	SecretRules.ROOM: "You found a hidden ice room! On Pluto, water ice is frozen as hard as rock.",
	SecretRules.TEMPLE: "You found the explorers' treasure! Pluto has five moons: Charon, Nix, Hydra, Kerberos and Styx.",
	SecretRules.ISLAND: "You found the Balloon Lander! Scientists have studied landing on Pluto with a giant balloon.",
	SecretRules.GEODE: "You found a frost crystal geode! At about −230 °C, even the nitrogen of Pluto's air freezes.",
}
## Pluto's sights (SpaceSights): where they are is PlutoTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"lookout": {"name": "Charon Lookout",
		"words": "You found the Charon Lookout! Pluto and Charon always face each other, so Charon never moves in this sky."},
	&"heart": {"name": "Heart Plain",
		"words": "You found Pluto's heart! Its plain of frozen nitrogen slowly churns in giant cells, like a lava lamp."},
	&"hills": {"name": "Floating Hills",
		"words": "You found a floating hill! Water ice is lighter than nitrogen ice, so it floats like an iceberg."},
	&"mountains": {"name": "Ice Mountains",
		"words": "You climbed Pluto's ice mountains! They are named after Tenzing Norgay and Edmund Hillary, who first climbed Everest."},
	&"dark": {"name": "Red-Brown Lands",
		"words": "You found the red-brown lands! Sunlight turns gas high in Pluto's air into this reddish dust: tholins."},
	&"bright": {"name": "Bright Side",
		"words": "You found the heart's bright side! Nitrogen drifts here through the air from the plain and settles as frost."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.PLUTO)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.PLUTO
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
