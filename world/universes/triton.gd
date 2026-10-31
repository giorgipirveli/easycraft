extends RefCounted
## World 27, Triton (cosmos, spec §21b.2): Neptune's biggest moon, which a spacecraft flew past in 1989, a space world like
## the Moon, Mars, Europa, Io, Titan, Mercury, Venus's cloud city, Saturn's rings and Pluto (off the universe ladder,
## reached by a mission or by flying up: SpaceRules). Its descriptor for UniverseRegistry (the interface is in
## universe_registry.gd, the space fields in its SPACE table): the landing pad on a bright band of fresh nitrogen frost,
## the pink south polar cap a walk south with its geysers (a gentle puff carries a child up, the thin wind drifts it
## north-east: PadRules, SpaceGeysers) and their dark streaks, the cantaloupe terrain to the north-west, a frozen lake of
## ice lava in a walled plain to the north-east, one of its few craters to the east (SpaceShape TRITON, TritonTerrain,
## SpaceGenerator), the Neptune Lookout by the pad, the Hopper Lander and the secrets in Triton's blocks
## (SpaceSecretRules), its real gravity (0.079 of Earth's: long, floaty jumps), peace, its own sky (a very thin nitrogen
## air: black and starry by day, a faint haze low down; the Sun a very bright star; Neptune huge and deep blue in the
## north-east, never moving), soft chimes, calm music, no animals. It says that Triton goes round Neptune backwards (the
## only big moon that does: probably caught from the Kuiper Belt, Pluto's cousin). Every find and every sight says a
## real fact (checked: docs/devlog/parts/cosmos-triton.md); no mission names.

var name := &"triton"
var display_name := "Triton"
var index := 27
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Triton's real gravity: 0.779 m/s² against Earth's 9.81, about 8 %: a jump floats ~21 blocks up and lasts ~10 s.
var gravity := 0.079
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## A very thin nitrogen air, about 70,000 times thinner than Earth's: a black starry sky by day, a faint cold haze low
## down; never Earth's photo sky.
var space_sky := 0.8
var photo_sky := false
## Triton goes round the Sun with Neptune, about 30 times as far out as Earth: the Sun looks 30 times smaller, a very
## bright star.
var sun_size := 0.033
var animals: Array[StringName] = []
## Neptune, huge and deep blue with faint cloud bands and a great dark spot (a storm seen in 1989), in the north-east:
## Triton always shows Neptune the same face, so it never moves in this sky (SkyCycle.show_planet: `dir`, `bands`, `spot`,
## `spot_color`); two of its small moons as points; Neptune's, not home's: no moon disc at night. (Neptune really is
## about 8° across from Triton, 16 times our Moon's width; the game's sky is not to scale, like every world's.)
var sky_planet := {"color": Color("3f63e0"), "land": Color("5b7ff0"), "size": 100.0, "bands": true, "spot": true,
	"spot_color": Color("1d2a6e"), "dir": Vector3(0.66, 0.22, -0.66), "own_moons": true,
	"moons": [
		{"color": Color("d8d4cf"), "land": Color("b9b4ad"), "size": 1.8, "dir": Vector3(-0.4, 0.75, 0.52)},
		{"color": Color("e2ded8"), "land": Color("c4bfb8"), "size": 1.4, "dir": Vector3(0.35, 0.82, 0.45)},
	]}
var landing_words := "You landed on Triton! Neptune hangs big and blue in the sky, and geysers puff to the south."
## No loops of its own (Green Meadows' play); Debussy's snow by day far out in the cold, the Moonlight Sonata under
## Neptune at night.
var music := {}
var classical: Array[StringName] = [&"snow_dancing", &"moonlight"]
## Soft icy chimes by day and night (its air is far too thin for wind to be heard; no birds, no crickets).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes most of the sky: `space_sky`): black overhead, a faint cold haze low down and
## over the far ground (never a dark band under the horizon).
var sky := {
	"sky_top": Color(0.01, 0.015, 0.05),
	"sky_horizon": Color(0.26, 0.32, 0.5),
	"ground_bottom": Color(0.26, 0.32, 0.5),
	"ground_horizon": Color(0.26, 0.32, 0.5),
	"fog": Color(0.22, 0.27, 0.42),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold, the fake
## door or a geyser (Triton's geysers stay on Triton).
var trader_stock := {
	BlockIds.TRITON_FROST: 1, BlockIds.PINK_ICE: 1, BlockIds.MOTTLED_ICE: 1, BlockIds.GEYSER_DUST: 1,
	BlockIds.CANTALOUPE_ICE: 1, BlockIds.RIDGE_ICE: 1, BlockIds.ICE_LAVA: 1, BlockIds.NITROGEN_ICE: 1,
	BlockIds.WATER_ICE: 1, BlockIds.NITROGEN_CRYSTAL: 3, BlockIds.NITROGEN_TANK: 2, BlockIds.NEPTUNE_GLOBE: 4,
	BlockIds.BLUE_BEACON: 3, BlockIds.CAP_BRICK: 2, BlockIds.TELESCOPE: 4, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of Triton's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Triton treasure! Triton was found in 1846, just 17 days after Neptune.",
	SecretRules.ROOM: "You found a hidden ice room! Triton's ice reflects about 70 % of the sunlight that reaches it.",
	SecretRules.TEMPLE: "You found the explorers' treasure! Triton is Neptune's biggest moon, a little bigger than Pluto.",
	SecretRules.ISLAND: "You found the Hopper Lander! Scientists have planned a lander that hops, using Triton's ice as rocket fuel.",
	SecretRules.GEODE: "You found a nitrogen crystal geode! At about −235 °C, Triton is one of the coldest places known.",
}
## Triton's sights (SpaceSights): where they are is TritonTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"lookout": {"name": "Neptune Lookout",
		"words": "You found the Neptune Lookout! Triton always shows Neptune the same face, so Neptune never moves here."},
	&"geyser": {"name": "Geyser",
		"words": "You found a geyser! It blows nitrogen gas and dark dust about 8 km high. Step on it for a ride!"},
	&"trail": {"name": "Dark Streaks",
		"words": "You found a trail of geyser dust! The thin wind blew it as far as 150 km across the ice."},
	&"cap": {"name": "Pink Polar Cap",
		"words": "You reached the south polar cap! Sunlight turns a little methane in its nitrogen ice pink."},
	&"melon": {"name": "Cantaloupe Terrain",
		"words": "You found the cantaloupe terrain! Its dimples and ridges look like the skin of a melon."},
	&"lake": {"name": "Frozen Lake",
		"words": "You found a frozen lake! Icy lava of water probably flooded this plain, then froze flat."},
	&"crater": {"name": "Lone Crater",
		"words": "You found one of Triton's few craters! Its ground is young: new ice keeps covering old craters."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.TRITON)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.TRITON
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
