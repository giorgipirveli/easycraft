extends RefCounted
## World 41, Wonders of the World (owner #78, spec §24): Earth's own first world (EarthRules 41-60, off the universe
## ladder), reached from the Star Map's Earth card ("Wonders of the World: LAND"; by plane once flight is invented,
## spec §21e). A friendly Earth world, free for everyone, peaceful, with Earth's gravity, sky and animals, where the
## first tour stands round the landing spot, the Seven Wonders of the Ancient World, the second round its own square
## at the end of the Wonders Road to the west, the New Seven Wonders, and the third round its square at the end of the
## Nature Trail to the south, the Seven Natural Wonders (WonderTour where, WonderBuilds, WonderBuildsNew and
## WonderBuildsNature what, WondersShape, NewSevenGround and NatureGround the ground, WondersGenerator the terrain,
## WondersSecretRules a secret at each, NatureSky the northern lights and the falls' rainbow).
## Each wonder is a sight (WonderSights): reaching it says its real fact, stamps the Wonders Passport and ticks the
## explorer's guide; its plaque opens its card and fact quiz (WondersDirector). Every fact is checked
## (docs/devlog/parts/wonders-ancient.md, wonders-new-seven.md, wonders-nature.md).

var name := &"wonders"
var display_name := "Wonders of the World"
var index := EarthRules.WONDERS
## Only for the Sandbox Totem and /summon (no monster comes by itself: `peaceful`).
var monster_kinds: Array[StringName] = [MonsterRules.SLIME, MonsterRules.GOBLIN]
var boss_kind := &"golem"
var peaceful := true
var landing_words := "Welcome to the Wonders of the World! Follow the red arrow: the Seven Ancient Wonders are " \
	+ "here, the New Seven along the Wonders Road, nature's seven along the Nature Trail."
## Green Meadows' loops; calm, bright pieces first.
var music := {}
var classical: Array[StringName] = [&"spring", &"morning_mood", &"air"]
## Tilly's local things: what the wonders were built of, in Green Meadows gold (never scaled: an Earth world).
var trader_stock := {
	BlockIds.LIMESTONE: 1, BlockIds.CASING_STONE: 2, BlockIds.GRANITE: 2, BlockIds.MARBLE: 2,
	BlockIds.MARBLE_COLUMN: 3, BlockIds.CAPITAL: 3, BlockIds.FRIEZE: 3, BlockIds.BRONZE: 4, BlockIds.IVORY: 4,
	BlockIds.GOLD_LEAF: 5, BlockIds.EBONY: 3, BlockIds.BABYLON_BRICK: 1, BlockIds.GLAZED_BRICK: 2,
	BlockIds.WHITE_BRICK: 1, BlockIds.PAVING: 1, BlockIds.SCREW_PUMP: 3, BlockIds.OLIVE_LEAVES: 1,
	BlockIds.BEACON_FIRE: 4,
	# the New Seven's (owner #78's second tour)
	BlockIds.WALL_BRICK: 1, BlockIds.ROSE_ROCK: 1, BlockIds.ROSE_STONE: 2, BlockIds.ROSE_COLUMN: 3,
	BlockIds.TRAVERTINE: 1, BlockIds.MAYA_STONE: 1, BlockIds.MAYA_CARVING: 3, BlockIds.SERPENT_HEAD: 4,
	BlockIds.JAGUAR_THRONE: 5, BlockIds.INCA_STONE: 2, BlockIds.SOAPSTONE: 2, BlockIds.INLAID_MARBLE: 4,
	BlockIds.MUGHAL_RED: 2,
	# nature's (owner #78's third tour)
	BlockIds.KAIBAB_LIMESTONE: 1, BlockIds.COCONINO_SANDSTONE: 1, BlockIds.SUPAI_REDBED: 1,
	BlockIds.REDWALL_LIMESTONE: 1, BlockIds.CANYON_SHALE: 1, BlockIds.VISHNU_SCHIST: 2, BlockIds.SEA_FOSSIL: 4,
	BlockIds.BRAIN_CORAL: 2, BlockIds.STAGHORN_CORAL: 2, BlockIds.SEA_FAN: 2, BlockIds.CINDER: 1, BlockIds.CORN: 1,
	BlockIds.PRAYER_FLAGS: 2, BlockIds.SPRAY: 2,
}
## The wonders as sights (WonderSights): their names on MY MAP and the real fact each says on arrival.
var sights := _sights()


static func _sights() -> Dictionary:
	var out := {}
	for id: StringName in WonderFacts.ORDER:
		var w := WonderFacts.of(id)
		out[id] = {"name": str(w.name), "words": str(w.sight)}
	return out


func generator_shape(world_seed: int) -> MeadowsShape:
	return WondersShape.new(world_seed)


func generator(world_seed: int) -> VoxelGenerator:
	var g := WondersGenerator.new()
	g.world_seed = world_seed
	return g


func secret_rules(world_seed: int, shape: MeadowsShape = null) -> SecretRules:
	return WondersSecretRules.new(world_seed, shape if shape is WondersShape else generator_shape(world_seed))
