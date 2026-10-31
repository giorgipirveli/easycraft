extends RefCounted
## World 21, Io (cosmos, spec §21b.2): Jupiter's volcanic moon, the most volcanic place in the solar system, a space world
## like the Moon, Mars and Europa (off the universe ladder, reached by flying up: SpaceRules). Its descriptor for
## UniverseRegistry (the interface is in universe_registry.gd, the space fields in its SPACE table): yellow and orange
## sulphur plains with white frost, volcanoes whose plumes throw a child up, red sulphur rings, glowing lava lakes (the
## big one's hot lava bounces a child out, never hurts), a big mountain (SpaceShape IO, IoTerrain, SpaceGenerator), the
## Volcano Lander and the secrets in Io's blocks (SpaceSecretRules), real gravity (0.18 of Earth's), peace, space's
## black starry sky (almost no air) with giant banded Jupiter hanging in it and Europa and Ganymede, soft chimes, no
## animals (no life we know of). Every find and every sight says a real Io fact (checked: docs/devlog/parts/cosmos-io.md);
## no mission names, only what real missions found, in general words.

var name := &"io"
var display_name := "Io"
var index := 21
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Io's real gravity: 1.80 m/s² against Earth's 9.81, 18 %.
var gravity := 0.18
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Almost no air (a thin veil of sulphur dioxide): space's black sky with stars all day; never Earth's photo sky.
var space_sky := 1.0
var photo_sky := false
var animals: Array[StringName] = []
## Jupiter, huge and banded, with its Great Red Spot, bigger than over Europa (Io is closer to it): Io always shows it
## the same face, so it hangs still in the sky (SkyCycle.show_planet); Europa (icy white) and Ganymede small elsewhere in
## the sky; Jupiter's moons, not home's: the big round moon disc never shows at night.
var sky_planet := {"color": Color("e3cfa8"), "land": Color("b0714a"), "ring": false, "size": 136.0, "bands": true,
	"spot": true, "own_moons": true,
	"moons": [
		{"color": Color("eae3d2"), "land": Color("a8674a"), "size": 12.0, "dir": Vector3(-0.6, 0.48, -0.42)},
		{"color": Color("a39a8c"), "land": Color("6f6457"), "size": 10.0, "dir": Vector3(0.25, 0.7, 0.55)},
	]}
var landing_words := "You landed on Io! Watch the volcanoes and look up at Jupiter!"
## No loops of its own (Green Meadows' play); a lively piece by day, a calm one at night.
var music := {}
var classical: Array[StringName] = [&"figaro", &"moonlight"]
## Soft chimes by day and night (almost no air: no wind, no birds).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes the sky: `space_sky`): a warm amber glow at the horizon (the volcanoes'
## haze), a warm fog far away.
var sky := {
	"sky_top": Color(0.02, 0.01, 0.03),
	"sky_horizon": Color(0.24, 0.15, 0.07),
	"ground_bottom": Color(0.14, 0.09, 0.05),
	"ground_horizon": Color(0.24, 0.15, 0.07),
	"fog": Color(0.26, 0.18, 0.09),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never hot lava or a vent
## (a moon's own wonders), never star gold or the fake door.
var trader_stock := {
	BlockIds.SULPHUR: 1, BlockIds.ORANGE_SULPHUR: 1, BlockIds.SULPHUR_FROST: 1, BlockIds.RED_SULPHUR: 1,
	BlockIds.IO_ROCK: 1, BlockIds.BLACK_LAVA: 1, BlockIds.LAVA_CRUST: 3, BlockIds.SULPHUR_CRYSTAL: 3,
	BlockIds.SULPHUR_BRICK: 2, BlockIds.HEAT_TILE: 2, BlockIds.LANDER_LEG: 2, BlockIds.HEAT_CAMERA: 4,
	BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Io's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Io treasure! Io is a little bigger than our Moon.",
	SecretRules.ROOM: "You found a hidden warm room! Jupiter's pull squeezes Io and heats up its inside.",
	SecretRules.TEMPLE: "You found the explorers' treasure! A day on Io lasts about 42 hours.",
	SecretRules.ISLAND: "You found the Volcano Lander! A spacecraft first saw a volcano erupting on Io in 1979.",
	SecretRules.GEODE: "You found a sulphur crystal geode! Sulphur paints Io yellow, orange and red.",
}
## Io's sights (SpaceSights): where they are is IoTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"lake": {"name": "Lava Lake",
		"words": "You found a lava lake! Io's biggest is about 200 km across. Its crust sinks in slow waves."},
	&"mountain": {"name": "Tall Mountain",
		"words": "You climbed an Io mountain! The tallest is about twice as high as Mount Everest."},
	&"plume": {"name": "Volcano",
		"words": "You found an erupting volcano! Io's plumes shoot up to about 400 km high."},
	&"ring": {"name": "Red Ring",
		"words": "You found a red ring! Some plumes drop red sulphur in rings over 1,000 km wide."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.IO)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.IO
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
