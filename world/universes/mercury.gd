extends RefCounted
## World 23, Mercury (cosmos, spec §21b.2): the smallest planet and the closest to the Sun, a space world like the Moon,
## Mars, Europa, Io and Titan (off the universe ladder, reached by flying up: SpaceRules). Its descriptor for
## UniverseRegistry (the interface is in universe_registry.gd, the space fields in its SPACE table): grey dust plains
## with darker patches, craters everywhere (young ones with bright rays, big ones with terraced walls and a central peak),
## long cliffs that rose as the planet cooled and shrank, ice in the shadowed craters near its poles, the explorers'
## thermometer by the landing pad (SpaceShape MERCURY, MercuryTerrain, SpaceGenerator), the Sunshade Lander and the
## secrets in Mercury's blocks (SpaceSecretRules), real gravity (0.38 of Earth's), peace, space's black sky by day
## (almost no air) with the Sun three times as big as at home, Venus, Earth and our Moon as tiny points, soft chimes, no
## animals (no life we know of). Its heat is a fact to learn, never a danger: nothing on Mercury hurts a child. Every
## find and every sight says a real Mercury fact (checked: docs/devlog/parts/cosmos-mercury.md); no mission names, only
## what real missions found, in general words.

var name := &"mercury"
var display_name := "Mercury"
var index := 23
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Mercury's real gravity: 3.70 m/s² against Earth's 9.81, 38 %.
var gravity := 0.38
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Almost no air (a thin exosphere): space's black sky with stars all day; never Earth's photo sky.
var space_sky := 1.0
var photo_sky := false
## Mercury is so close to the Sun that it looks more than three times as big as from home (SkyCycle.sun_size).
var sun_size := 3.0
var animals: Array[StringName] = []
## Venus, the brightest point in Mercury's sky, with Earth and our Moon as two tiny points elsewhere (SkyCycle.show_planet);
## Mercury has no moon of its own: the big round moon disc of home never shows.
var sky_planet := {"color": Color("fbf3dc"), "land": Color("f1e3b8"), "ring": false, "size": 6.0, "own_moons": true,
	"moons": [
		{"color": Color("3f8fe0"), "land": Color("5cb85c"), "size": 5.0, "dir": Vector3(-0.5, 0.62, 0.45)},
		{"color": Color("d8d8d8"), "land": Color("bdbdbd"), "size": 2.5, "dir": Vector3(-0.47, 0.64, 0.44)},
	]}
var landing_words := "You landed on Mercury! The Sun looks three times as big here!"
## No loops of its own (Green Meadows' play); a joyful piece in the big Sun's day, a calm one at night.
var music := {}
var classical: Array[StringName] = [&"ode_to_joy", &"gymnopedie"]
## Soft chimes by day and night (almost no air: no wind, no birds).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes the sky: `space_sky`): a pale grey glow at the horizon, a grey fog far away.
var sky := {
	"sky_top": Color(0.01, 0.01, 0.02),
	"sky_horizon": Color(0.16, 0.16, 0.18),
	"ground_bottom": Color(0.09, 0.09, 0.1),
	"ground_horizon": Color(0.16, 0.16, 0.18),
	"fog": Color(0.18, 0.18, 0.2),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.MERCURY_DUST: 1, BlockIds.MERCURY_ROCK: 1, BlockIds.DARK_DUST: 1, BlockIds.RAY_DUST: 1,
	BlockIds.SHADOW_ICE: 2, BlockIds.ICE_CRYSTAL: 3, BlockIds.SUNSHADE: 2, BlockIds.HEAT_BLANKET: 2,
	BlockIds.MIRROR_PANEL: 3, BlockIds.EXPLORER_LAMP: 4, BlockIds.THERMOMETER: 3, BlockIds.THERMO_BULB: 4,
	BlockIds.EXPLORER_BRICK: 2, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Mercury's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Mercury treasure! A year on Mercury lasts only 88 Earth days.",
	SecretRules.ROOM: "You found a hidden rock room! Mercury's metal core is 85 % as wide as the whole planet.",
	SecretRules.TEMPLE: "You found the explorers' treasure! Mercury has almost no air, so its sky is black by day.",
	SecretRules.ISLAND: "You found the Sunshade Lander! Spacecraft visiting Mercury hide behind big sunshades to keep cool.",
	SecretRules.GEODE: "You found an ice crystal geode! Comets and asteroids probably brought Mercury its water.",
}
## Mercury's sights (SpaceSights): where they are is MercuryTerrain's (the thermometer SpaceShape's); their names on MY MAP
## and the real fact each says.
var sights := {
	&"thermometer": {"name": "Thermometer",
		"words": "You found the thermometer! Mercury's days reach about 430 °C and its nights about −180 °C."},
	&"scarp": {"name": "Long Cliff",
		"words": "You found a long cliff! Mercury shrank as it cooled, and its crust pushed up cliffs like this."},
	&"crater": {"name": "Big Crater",
		"words": "You found a big crater! Mercury's craters are named after famous artists, writers and musicians."},
	&"ice": {"name": "Ice Crater",
		"words": "You found ice! Sunlight never reaches the floors of some craters near Mercury's poles."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.MERCURY)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.MERCURY
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
