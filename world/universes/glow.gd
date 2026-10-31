extends RefCounted
## Universe 6, the Glow Caves (spec §5.1; brief docs/superpowers/plans/2026-10-01-glow-caves-brief.md): its descriptor
## for the universe ladder (UniverseRegistry loads it by path, world/universes/glow.gd; the interface is in
## universe_registry.gd). Big caverns under a meadow roof (GlowShape, GlowGenerator), lit by their own glow (glow moss,
## giant glowshrooms, glow-worm ceilings, selenite), lakes, daylight shafts with a ramp up to the roof; its secrets
## (GlowSecretRules); its soft blue-violet dark (`cave_mood`: GlowRules). Universe 6 is the last on the ladder: the Spore
## Mother's portal leads to the hub.

var name := &"glow"
var display_name := "Glow Caves"
var index := 6
var monster_kinds: Array[StringName] = MonsterRules.GLOW_KINDS   # spore puffs (see light) and cave crawlers (hear)
var boss_kind := BossRules.SPORE_MOTHER
## No loops of its own (Green Meadows' play); the classical pieces below come first (the audio pass).
var music := {}
## Public-domain pieces already in the game (MusicPieces): Bach's calm Goldberg Aria and Beethoven's Moonlight Sonata
## for the glowing halls, the Flight of the Bumblebee for the Spore Mother's quick, puffing fight.
var classical: Array[StringName] = [&"goldberg_aria", &"moonlight", &"bumblebee"]
## No ambience of its own: the meadow on the roof has the birds and the crickets; under the roof every cavern is deep
## underground (WorldService.sky_height), where the caves' drips play by the existing rule (AmbienceSoundRules).
## The daytime colours seen through a daylight shaft and over the meadow on the roof: a soft clear blue, a lilac
## horizon, lilac-blue fog (the caves' own dark is `cave_mood`).
var sky := {
	"sky_top": Color(0.42, 0.6, 0.95),
	"sky_horizon": Color(0.8, 0.76, 0.98),
	"ground_bottom": Color(0.36, 0.33, 0.56),
	"ground_horizon": Color(0.72, 0.7, 0.92),
	"fog": Color(0.72, 0.72, 0.95),
}
## The free peek while it is locked (UniversePeek, from the hub's card and the Star Map): what is inside, calmly.
var peek: Array[String] = [
	"Giant glowing mushrooms in huge caverns",
	"Crystal halls, glow-worms and blind cave fish",
	"Cave wonders to play: real cave science",
]
## Under the roof: the soft blue-violet dark, never black (GlowRules; Ambience applies it under any ceiling).
var cave_mood: Dictionary = GlowRules.CAVE_MOOD
## Frogs croak by the underground lakes (the blind cave fish are the Blind Fish Lake's own).
var animals: Array[StringName] = [&"frog"]
## Tilly's local things: gold for one block, in Green Meadows gold (the ladder scales it by 2^(u-1)).
var trader_stock := {
	BlockIds.CAVE_STONE: 1, BlockIds.FLOWSTONE: 1, BlockIds.LAKE_STONE: 1, BlockIds.FUNGUS_PLANKS: 1,
	BlockIds.SHROOM_STEM: 1, BlockIds.GLOW_MOSS: 2, BlockIds.BLUE_SHROOM: 2, BlockIds.ROSE_SHROOM: 2,
	BlockIds.SELENITE: 3, BlockIds.STALAGMITE: 2, BlockIds.SPORE_LAMP: 5,
}
## What finding each kind of the caves' secrets says (the SecretDirector's banners).
var secret_words := {
	SecretRules.TREASURE: "You found buried cave treasure!",
	SecretRules.ROOM: "You found a hidden room under the cave floor!",
	SecretRules.TEMPLE: "You found the flowstone temple's treasure!",
	SecretRules.ISLAND: "You found a hidden grotto!",
	SecretRules.GEODE: "You found a selenite geode!",
}


func generator_shape(world_seed: int) -> MeadowsShape:
	return GlowShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := GlowGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return GlowSecretRules.new(world_seed, shape)
