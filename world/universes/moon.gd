extends RefCounted
## World 16, the Moon (owner feedback #55, spec §21): a space world, off the universe ladder, reached by flying up
## (SpaceRules). Its descriptor for UniverseRegistry (the interface is in universe_registry.gd, the space fields in its
## SPACE table): silvery dust, craters and moon crystals (SpaceShape, SpaceGenerator), the Moon Base and the secrets in
## moon blocks (SpaceSecretRules), low gravity (0.35: big floaty jumps), peace (no night monsters; the Sandbox Totem and
## /summon still work), a black starry sky with the home planet hanging in it, moon bunnies; the colony under domes a
## short walk from the landing pad (spec §21c: ColonyLayout; its animals live under the Great Dome, ColonyAnimals).

var name := &"moon"
var display_name := "The Moon"
var index := 16
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
var gravity := 0.35
var space_sky := 1.0
## The home planet in the Moon's sky: blue seas and green land (SkyCycle.show_planet).
var sky_planet := {"color": Color("3f8fe0"), "land": Color("5cb85c"), "ring": false, "size": 70.0}
var landing_words := "You landed on the Moon! Jump: you float!"
## No loops of its own (Green Meadows' play); the dreamy pieces come first.
var music := {}
var classical: Array[StringName] = [&"moonlight", &"gymnopedie"]
## Soft wind chimes by day and night (no birds, no crickets on the Moon).
var ambience := {"day": &"chimes", "night": &"chimes"}
## The daytime colours: space's black overhead, a deep blue glow at the horizon (the sun still shines bright).
var sky := {
	"sky_top": Color(0.01, 0.01, 0.05),
	"sky_horizon": Color(0.08, 0.1, 0.24),
	"ground_bottom": Color(0.05, 0.05, 0.1),
	"ground_horizon": Color(0.08, 0.1, 0.24),
	"fog": Color(0.1, 0.11, 0.2),
}
## Tilly's local things: gold for one block, in Green Meadows gold (never scaled in space); the colony's blocks too
## (spec §21c: build your own).
var trader_stock := ColonyRules.with_stock({
	BlockIds.MOON_DUST: 1, BlockIds.MOON_ROCK: 1, BlockIds.DEEP_MOON_ROCK: 1, BlockIds.MOON_CRYSTAL: 3,
	BlockIds.MOON_CHEESE: 2, BlockIds.BASE_PANEL: 2, BlockIds.PORTHOLE: 3, BlockIds.BASE_LIGHT: 4, BlockIds.LANDING_PAD: 4,
})
## The colony's parts (spec §21c: ColonyRules; where they are: ColonyLayout): each says a real fact when a child walks in.
var sights := ColonyRules.sights(SpaceShape.MOON)
var animals: Array[StringName] = [&"moon_bunny"]
## What finding each kind of the Moon's secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried moon treasure!",
	SecretRules.ROOM: "You found a hidden cheese room!",
	SecretRules.TEMPLE: "You found the star temple's treasure!",
	SecretRules.ISLAND: "You found the Moon Base!",
	SecretRules.GEODE: "You found a moon crystal geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return SpaceShape.new(world_seed, SpaceShape.MOON)


func generator(world_seed: int) -> VoxelGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.MOON
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return SpaceSecretRules.new(world_seed, shape if shape is SpaceShape else generator_shape(world_seed))
