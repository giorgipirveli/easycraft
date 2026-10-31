extends RefCounted
## World 20, Europa (cosmos, spec §21b.2): Jupiter's icy moon, a space world like the Moon and Mars (off the universe
## ladder, reached by flying up: SpaceRules). Its descriptor for UniverseRegistry (the interface is in
## universe_registry.gd, the space fields in its SPACE table): a smooth white crust of ice crossed by long reddish cracks,
## the ice cliffs, water plumes that throw a child up, the ocean under the ice at the bottom of a deep well (SpaceShape
## EUROPA, EuropaTerrain, SpaceGenerator), the Ice Lander and the secrets in Europa's blocks (SpaceSecretRules), real
## gravity (0.13 of Earth's), peace, space's black starry sky (almost no air) with giant banded Jupiter hanging in it and
## Io and Ganymede, soft icy chimes, no animals (no life we know of). Every find and every sight says a real Europa fact
## (checked: docs/devlog/parts/cosmos-europa.md); no mission names, only what real missions found, in general words.

var name := &"europa"
var display_name := "Europa"
var index := 20
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Europa's real gravity: 1.31 m/s² against Earth's 9.81, 13 %.
var gravity := 0.13
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Almost no air: space's black sky with stars all day, like the Moon's; never Earth's photo sky when realistic.
var space_sky := 1.0
var photo_sky := false
var animals: Array[StringName] = []
## Jupiter, huge and banded, with its Great Red Spot: Europa always shows it the same face, so it hangs still in the
## sky (SkyCycle.show_planet); Io (sulphur-yellow) and Ganymede (the biggest moon of all) small elsewhere in the sky;
## Jupiter's moons, not home's: the big round moon disc never shows at night.
var sky_planet := {"color": Color("e3cfa8"), "land": Color("b0714a"), "ring": false, "size": 104.0, "bands": true,
	"spot": true, "own_moons": true,
	"moons": [
		{"color": Color("e8d04a"), "land": Color("d9772b"), "size": 13.0, "dir": Vector3(-0.58, 0.5, -0.45)},
		{"color": Color("a39a8c"), "land": Color("6f6457"), "size": 11.0, "dir": Vector3(0.2, 0.72, 0.55)},
	]}
var landing_words := "You landed on Europa! Jump high and look up at Jupiter!"
## No loops of its own (Green Meadows' play); calm icy pieces first.
var music := {}
var classical: Array[StringName] = [&"snow_dancing", &"gymnopedie"]
## Soft icy chimes by day and night (no air: no wind, no birds).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes the sky: `space_sky`): a deep blue glow at the horizon, like the Moon's.
var sky := {
	"sky_top": Color(0.01, 0.01, 0.05),
	"sky_horizon": Color(0.08, 0.12, 0.26),
	"ground_bottom": Color(0.05, 0.06, 0.12),
	"ground_horizon": Color(0.08, 0.12, 0.26),
	"fog": Color(0.1, 0.13, 0.24),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space).
var trader_stock := {
	BlockIds.EUROPA_ICE: 1, BlockIds.LINEA_ICE: 1, BlockIds.BAND_ICE: 1, BlockIds.DEEP_ICE: 1, BlockIds.EUROPA_ROCK: 1,
	BlockIds.GLOW_ICE: 3, BlockIds.SALT: 3, BlockIds.ICE_BRICK: 2, BlockIds.PROBE_PANEL: 2, BlockIds.MELT_PROBE: 2,
	BlockIds.PROBE_LIGHT: 4, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Europa's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Europa treasure! Europa is a little smaller than our Moon.",
	SecretRules.ROOM: "You found a hidden ice room! Europa's ice is about −160 °C, colder than any freezer.",
	SecretRules.TEMPLE: "You found the ice station's treasure! A day on Europa lasts about 3.5 Earth days.",
	SecretRules.ISLAND: "You found the Ice Lander! Scientists design probes to melt through the ice to the ocean.",
	SecretRules.GEODE: "You found a salt crystal geode! A space telescope found table salt on Europa's ice.",
}
## Europa's sights (SpaceSights): where they are is EuropaTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"ocean": {"name": "Ocean Under the Ice",
		"words": "You reached the ocean under the ice! It may hold twice as much water as all of Earth's oceans."},
	&"cliffs": {"name": "Ice Cliffs",
		"words": "You climbed the ice cliffs! Europa's shell of ice is about 15 to 25 km thick."},
	&"plume": {"name": "Water Plume",
		"words": "You found a water plume! A space telescope saw one shoot about 100 km up from Europa."},
	&"linea": {"name": "Reddish Crack",
		"words": "You found a long crack! Its reddish colour may come from salts and sulphur in the ice."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.EUROPA)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.EUROPA
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
