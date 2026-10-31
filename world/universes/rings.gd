extends RefCounted
## World 25, Saturn's rings (cosmos, spec §21b.2): billions of chunks of water ice and a little rock, from dust grains to
## chunks as big as a house, in a sheet about 10 metres thick but wider than four Earths, in bands with gaps (NASA). A
## space world like the Moon, Mars, Europa, Io, Titan, Mercury and Venus's cloud city (off the universe ladder, reached by
## a mission or by flying up: SpaceRules). Its descriptor for UniverseRegistry (the interface is in
## universe_registry.gd, the space fields in its SPACE table): the chunks in their real bands (the C ring, the bright B
## ring with the landing chunk, the Cassini Division, the A ring with Pan in the Encke Gap, the braided F ring:
## SpaceShape RINGS, RingsTerrain, SpaceGenerator; the secrets in the rings' blocks and the Ring Explorer:
## SpaceSecretRules), the game's very low gravity (0.05 of Earth's: long, slow jumps from chunk to chunk), peace, space's
## black starry sky with Saturn huge over the northern horizon (its bands, its rings seen edge-on, their shadow on its
## clouds, its shadow on them), the Sun small and far, Titan and other moons, soft chimes, no animals. A child who falls
## between the chunks is carried back by the little jets of its space suit long before the void line (`has_void`,
## `void_y`, `void_words`: DragonRules), never towards Saturn. Every find and every sight says a real fact (checked:
## docs/devlog/parts/cosmos-rings.md); no mission names.

var name := &"rings"
var display_name := "Saturn's Rings"
var index := 25
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## The game's gravity in the rings (spec §21b.2: 0.05 of Earth's): a jump floats ~34 blocks up and lasts ~15 seconds. On
## a real ring chunk a child would weigh almost nothing (a house-sized chunk pulls millions of times less than Earth): one
## hop would float away for ever. The words say so (the notes' ruling).
var gravity := 0.05
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## No air: space's black starry sky all day, never Earth's photo sky.
var space_sky := 1.0
var photo_sky := false
## Saturn is about 9.5 times as far from the Sun as Earth: the Sun looks about ten times smaller (SkyCycle.sun_size).
var sun_size := 0.1
## Between the chunks: fall and the space suit's little jets carry you back to the ice, long before the void line.
var has_void := true
var void_y := RingsTerrain.LIFT_Y
var void_words := "Pfff! Your space suit's little jets flew you back to the ice."
var animals: Array[StringName] = []
## Saturn, huge over the northern horizon (seen from the B ring it is about 70° across), its pale gold zones and tan
## belts, its rings seen edge-on (we stand in them) with their shadow on its clouds and its own shadow on them
## (SkyCycle.show_planet: `dir`, `ring_edge`, `pixels`); Titan, Enceladus and Mimas in the sky, Prometheus and Pandora
## (the F ring's shepherds) low in the south; Saturn's, not home's: no moon disc at night.
var sky_planet := {"color": Color("ead7a4"), "land": Color("c9a46a"), "ring": false, "bands": true, "ring_edge": true,
	"size": 380.0, "pixels": 192, "dir": Vector3(0.0, 0.02, -1.0), "own_moons": true,
	"moons": [
		{"color": Color("e0a44a"), "land": Color("c98a3a"), "size": 7.0, "dir": Vector3(0.62, 0.45, 0.4)},
		{"color": Color("f7fbff"), "land": Color("e6eef8"), "size": 4.0, "dir": Vector3(-0.55, 0.5, 0.25)},
		{"color": Color("cfcbc4"), "land": Color("aaa59c"), "size": 3.5, "dir": Vector3(-0.3, 0.72, -0.2)},
		{"color": Color("bdb6aa"), "land": Color("9f978a"), "size": 2.5, "lumpy": true, "dir": Vector3(0.35, 0.06, 1.0)},
		{"color": Color("c6bfb2"), "land": Color("a39b8e"), "size": 2.5, "lumpy": true, "dir": Vector3(-0.22, 0.07, 1.0)},
	]}
var landing_words := "You landed on Saturn's rings! Jump from chunk to chunk: you are very light here!"
## No loops of its own (Green Meadows' play); a waltz as the ice turns round Saturn by day, a calm piece at night.
var music := {}
var classical: Array[StringName] = [&"waltz_flowers", &"moonlight"]
## Soft icy chimes by day and night (no air: no wind, no birds, no crickets).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours (space's black takes the sky: `space_sky`): a faint golden glow at the horizon, Saturn's light.
var sky := {
	"sky_top": Color(0.02, 0.02, 0.05),
	"sky_horizon": Color(0.16, 0.13, 0.1),
	"ground_bottom": Color(0.03, 0.03, 0.06),
	"ground_horizon": Color(0.12, 0.1, 0.09),
	"fog": Color(0.1, 0.09, 0.11),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space). Never star gold or the fake
## door.
var trader_stock := {
	BlockIds.RING_ICE: 1, BlockIds.RING_FROST: 1, BlockIds.DUSTY_ICE: 1, BlockIds.RING_ROCK: 1, BlockIds.MOONLET_ICE: 2,
	BlockIds.RIDGE_DUST: 1, BlockIds.RING_CRYSTAL: 3, BlockIds.STATION_PANEL: 2, BlockIds.STATION_WINDOW: 2,
	BlockIds.STATION_LAMP: 3, BlockIds.RADIO_DISH: 3, BlockIds.POWER_PACK: 4, BlockIds.TRUSS: 1, BlockIds.RING_BEACON: 3,
	BlockIds.SATURN_BAND: 3, BlockIds.TELESCOPE: 4, BlockIds.LANDING_PAD: 4,
}
## What finding each kind of the rings' secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried ring treasure! The rings are chunks of ice and rock, from dust to house-sized.",
	SecretRules.ROOM: "You found a hidden ice room! The main rings are only about 10 metres thick.",
	SecretRules.TEMPLE: "You found the explorers' treasure! Saturn has more than 270 moons, more than any other planet.",
	SecretRules.ISLAND: "You found the Ring Explorer! In 2017 a spacecraft dived between Saturn and its rings 22 times.",
	SecretRules.GEODE: "You found a ring crystal geode! Bits of the rings slowly rain down into Saturn.",
}
## The rings' sights (SpaceSights): where they are is RingsTerrain's; their names on MY MAP and the real fact each says.
var sights := {
	&"scope": {"name": "Saturn Scope",
		"words": "You found the Saturn scope! Saturn is so big that about 760 Earths could fit inside it."},
	&"station": {"name": "Ring Station",
		"words": "You found the Ring Station! Sunlight takes about 80 minutes to get here, and 8 to reach Earth."},
	&"cassini": {"name": "Cassini Division",
		"words": "You found the Cassini Division! This gap is 4,700 km wide. An astronomer called Cassini saw it in 1675."},
	&"c_ring": {"name": "C Ring",
		"words": "You found the C ring! Its chunks are darker and dustier than the bright B ring's."},
	&"f_ring": {"name": "F Ring",
		"words": "You found the F ring! Two shepherd moons, Prometheus and Pandora, keep it thin and twisted."},
	&"pan": {"name": "Pan",
		"words": "You found Pan! This little moon, shaped like a walnut, sweeps the Encke Gap clean."},
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.RINGS)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.RINGS
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
