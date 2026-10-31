extends RefCounted
## World 19, Mars (cosmos, spec §21b.2): the first real planet of the Star Map, a space world like the Moon (off the
## universe ladder, reached by flying up: SpaceRules). Its descriptor for UniverseRegistry (the interface is in
## universe_registry.gd, the space fields in its SPACE table): red dust plains, craters, dry river valleys, a giant
## shield volcano, a long canyon and the polar ice caps (SpaceShape MARS, MarsTerrain, SpaceGenerator), the rover and
## the secrets in Mars's blocks (SpaceSecretRules), real gravity (0.38 of Earth's), peace, a butterscotch sky with blue
## sunsets and its two small moons, a soft dusty wind, no animals (Mars has no life we know of) but the ones living under
## the colony's Great Dome (spec §21c: ColonyLayout, ColonyAnimals). Every find and every sight says a real Mars fact
## (checked: docs/devlog/parts/cosmos-mars.md; the colony's: docs/devlog/parts/colony-domes.md).

var name := &"mars"
var display_name := "Mars"
var index := 19
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
## Mars's real gravity: 3.71 m/s² against Earth's 9.81, 38 %.
var gravity := 0.38
## No life we know of: no animals come (UniverseRegistry.lifeless; the Totem's /summon still works).
var lifeless := true
## Its own butterscotch sky in the realistic style too (the photo sky is Earth's blue with clouds).
var photo_sky := false
## Mars gets under half of Earth's sunlight: its noon light is 0.7 of home's (SkyCycle.sun_light; the visuals brief), so the red
## dust stays red (in Earth's full sun it came out a pale orange-yellow).
var sun_light := 0.7
var animals: Array[StringName] = []
## Phobos, with the smaller Deimos elsewhere in the sky: two small lumpy moons (SkyCycle.show_planet); Mars's own moons,
## so the big round moon of home never shows at night.
var sky_planet := {"color": Color("8a7d72"), "land": Color("6b5f56"), "ring": false, "size": 22.0, "lumpy": true,
	"own_moons": true,
	"moons": [{"color": Color("a39584"), "land": Color("857868"), "size": 11.0, "lumpy": true,
		"dir": Vector3(-0.62, 0.55, -0.4)}]}
var landing_words := "You landed on Mars! Jump: you are lighter here!"
## No loops of its own (Green Meadows' play); calm pieces first.
var music := {}
var classical: Array[StringName] = [&"goldberg_aria", &"air"]
## A soft dusty wind by day and night (no birds, no crickets on Mars).
var ambience := {"day": &"wind", "night": &"wind"}
## The daytime colours: a butterscotch-pink sky, paler at the horizon, a dusty haze; at sunset the glow round the sun
## turns blue (`sunset`: the fine dust scatters blue light forward, as on the real Mars).
var sky := {
	"sky_top": Color(0.8, 0.56, 0.42),
	"sky_horizon": Color(0.93, 0.76, 0.6),
	"ground_bottom": Color(0.84, 0.62, 0.48),   # the haze under the horizon, never a dark band over the far plains
	"ground_horizon": Color(0.93, 0.76, 0.6),
	"fog": Color(0.88, 0.67, 0.52),
	"sunset": Color(0.42, 0.62, 0.95),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space); the colony's blocks too
## (spec §21c: build your own).
var trader_stock := ColonyRules.with_stock({
	BlockIds.MARS_DUST: 1, BlockIds.MARS_REGOLITH: 1, BlockIds.BASALT: 1, BlockIds.DEEP_BASALT: 1,
	BlockIds.MARS_SEDIMENT: 1, BlockIds.POLAR_ICE: 2, BlockIds.DRY_ICE: 2, BlockIds.GYPSUM: 3, BlockIds.ROVER_PANEL: 2,
	BlockIds.ROVER_WHEEL: 2, BlockIds.SOLAR_PANEL: 3, BlockIds.LANDER_FOIL: 2, BlockIds.ROVER_LIGHT: 4,
	BlockIds.LANDING_PAD: 4,
})
## What finding each kind of Mars's secrets says: the find, then a real fact.
var secret_words := {
	SecretRules.TREASURE: "You found buried Mars treasure! Mars is red because its dust has rust in it.",
	SecretRules.ROOM: "You found a hidden room! Mars's dark rock is basalt, made by old lava.",
	SecretRules.TEMPLE: "You found the old lander's treasure! Landers from Earth have visited Mars since the 1970s.",
	SecretRules.ISLAND: "You found the Mars Rover! Real Mars rovers roll on six wheels and get their orders from Earth.",
	SecretRules.GEODE: "You found a gypsum geode! Rovers found gypsum on Mars: it forms in water.",
}
## Mars's sights (SpaceSights): where they are is MarsTerrain's; their names on MY MAP and the real fact each says. The
## colony's parts are sights too (spec §21c: ColonyRules; where they are: ColonyLayout).
var sights := ColonyRules.with_sights(SpaceShape.MARS, {
	&"volcano": {"name": "Giant Volcano",
		"words": "You reached the top of the giant volcano! Mars's Olympus Mons is the tallest volcano in the solar system."},
	&"canyon": {"name": "Great Canyon",
		"words": "You found the great canyon! Mars's Valles Marineris is over 4,000 km long and up to 7 km deep."},
	&"north_cap": {"name": "North Ice Cap",
		"words": "You found the ice cap! Mars's poles hold frozen water and frozen carbon dioxide."},
	&"south_cap": {"name": "South Ice Cap",
		"words": "You found the south ice cap! It is topped with dry ice: frozen carbon dioxide."},
	&"river": {"name": "Dry River Bed",
		"words": "You found a dry river bed! Long ago, water flowed on Mars."},
})


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.MARS)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.MARS
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
