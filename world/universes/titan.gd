extends RefCounted
## World 22, Titan (cosmos, spec §21b.2): Saturn's biggest moon, the only moon with thick air, a space world like the
## Moon, Mars, Europa and Io (off the universe ladder, reached by flying up: SpaceRules). Its descriptor for
## UniverseRegistry (the interface is in universe_registry.gd, the space fields in its SPACE table): orange-brown soil
## plains with ice pebbles, the methane sea to the north and small methane lakes (the game's WATER shown as liquid
## methane: `liquid`; a swimmer leaps out of it, TitanRules), long dunes of dark grains to the south, the icy mountains
## (SpaceShape TITAN, TitanTerrain, SpaceGenerator), the Landing Probe with its parachute and the secrets in Titan's
## blocks (SpaceSecretRules), real gravity (0.14 of Earth's), peace, its own sky (an orange haze by day: thick nitrogen
## air, never space's black) with Saturn and its rings hanging in it, a soft wind, calm music, no animals (no life we know
## of). Every find and every sight says a real Titan fact (checked: docs/devlog/parts/cosmos-titan.md); no mission names,
## only what real missions found, in general words.

var name := &"titan"
var display_name := "Titan"
var index := 22
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Titan's real gravity: 1.35 m/s² against Earth's 9.81, 14 %.
var gravity := 0.14
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Thick air (mostly nitrogen, about one and a half times the pressure of Earth's): its own orange haze by day, never
## space's black sky, never Earth's photo sky.
var space_sky := 0.0
var photo_sky := false
var animals: Array[StringName] = []
## Its lakes and sea are liquid methane: the game's water, shown amber and glassy (BlockLibrary.set_liquid), very floaty
## (TitanRules: JUMP at the surface leaps out), never harmful.
var liquid := TitanRules.METHANE
## Saturn, big, pale and banded, with its rings: Titan always shows it the same face, so it hangs still in the sky
## (SkyCycle.show_planet); the haze hides Saturn's other moons; Saturn's, not home's: no moon disc at night. (The real haze
## is so thick that Saturn is hard to see from the ground; the game shows it softly: ruling in the notes.)
var sky_planet := {"color": Color("ecd3a1"), "land": Color("cfa86a"), "ring": true, "bands": true, "size": 84.0,
	"own_moons": true}
var landing_words := "You landed on Titan! Look up at Saturn through the orange haze!"
## No loops of its own (Green Meadows' play); a morning piece under the orange haze, a calm one at night.
var music := {}
var classical: Array[StringName] = [&"morning_mood", &"air"]
## A soft wind by day and night (thick air: gentle breezes; no birds, no crickets on Titan).
var ambience := {"day": &"wind", "night": &"wind"}
## The daytime colours: an orange haze overhead, paler and golden at the horizon, an orange fog far away; bright and
## friendly (spec §3c), though noon on the real Titan is much dimmer than on Earth.
var sky := {
	"sky_top": Color(0.86, 0.55, 0.26),
	"sky_horizon": Color(0.97, 0.78, 0.46),
	"ground_bottom": Color(0.88, 0.62, 0.34),   # the haze under the horizon, never a dark band over the far plains
	"ground_horizon": Color(0.97, 0.78, 0.46),
	"fog": Color(0.93, 0.7, 0.42),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.TITAN_SOIL: 1, BlockIds.ICE_PEBBLES: 1, BlockIds.DUNE_SAND: 1, BlockIds.WET_SHORE: 1, BlockIds.ICY_ROCK: 1,
	BlockIds.SHORE_CRYSTAL: 3, BlockIds.TITAN_BRICK: 2, BlockIds.PROBE_SHELL: 2, BlockIds.PARACHUTE: 2,
	BlockIds.PROBE_LAMP: 4, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Titan's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Titan treasure! Titan is bigger than the planet Mercury.",
	SecretRules.ROOM: "You found a hidden ice room! Titan's rocks are water ice, frozen as hard as stone.",
	SecretRules.TEMPLE: "You found the explorers' treasure! A day on Titan lasts about 16 Earth days.",
	SecretRules.ISLAND: "You found the Landing Probe! A probe landed on Titan in 2005: the farthest landing ever.",
	SecretRules.GEODE: "You found a shore crystal geode! Drying lakes on Titan leave bright rings, like a bathtub.",
}
## Titan's sights (SpaceSights): where they are is TitanTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"sea": {"name": "Methane Sea",
		"words": "You found a sea of liquid methane! Titan's biggest seas lie near its north pole."},
	&"lake": {"name": "Methane Lake",
		"words": "You found a methane lake! Titan's rain is methane too: it fills its lakes and rivers."},
	&"dunes": {"name": "Dark Dunes",
		"words": "You found Titan's dunes! Scientists think their dark grains fell from the orange haze."},
	&"mountain": {"name": "Icy Mountains",
		"words": "You climbed Titan's icy mountains! Its tallest peak is about 3.3 km high."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.TITAN)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.TITAN
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
