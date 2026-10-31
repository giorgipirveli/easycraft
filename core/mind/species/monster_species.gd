class_name MonsterSpecies
extends RefCounted
## The monsters' mind tables (M2 Task 18 part 2, spec §12.17). A monster that sees a child picks a
## tactic — straight at you, zigzag, go round to your side, wait by cover, back off when hurt, call a
## friend — from what it senses; its species' table in the world learns which tactics work (landing a
## hit: good; being hit, shot from far or defeated: bad). Every tactic is fair and signalled: it only
## steers (the same speed, sight, hits and hearts as §12.4/§12.5), the child can see it coming (a
## weave, a curve, a stop, a step back) or hear it (the call). The hidden layer is hand-made features;
## only the output layer learns, and never further than the universe's cap (cap()).

const STRAIGHT := &"straight"
const ZIGZAG := &"zigzag"
const GO_ROUND := &"go_round"
const WAIT := &"wait"
const BACK_OFF := &"back_off"
const CALL := &"call"
const ACTIONS: Array[StringName] = [STRAIGHT, ZIGZAG, GO_ROUND, WAIT, BACK_OFF, CALL]

## What a monster senses (the Mind's slots, with monster meanings).
const S_NEAR := Mind.S_NEAR       # its target: 1 = right here, 0 = 16 blocks or more
const S_FACING := Mind.S_LIKE     # the child looks its way
const S_RANGED := Mind.S_FEAR     # the child holds a bow, a boomerang or a spear
const S_MELEE := Mind.S_RUSH      # ... or a sword, an axe, a hammer, a mace
const S_HEALTH := Mind.S_HEALTH   # its own hearts
const S_KIN := Mind.S_KIN         # other monsters near
const S_THREAT := Mind.S_THREAT   # hit lately
const S_SHOT := Mind.S_NOVEL      # hit from far lately (arrows)

const F_CLOSE := 0
const F_ARCHER := 1               # a far child with a bow
const F_SHOT := 2
const F_FACED := 3                # a child with a sword looking its way
const F_HURT := 4
const F_BOLD := 5
const F_CAUTIOUS := 6
const F_FRIENDS := 7
const F_THREAT := 8
const F_ONE := 11

const NO_WEAPON := 0
const MELEE := 1
const RANGED := 2

# When a tactic can be picked.
const ROUND_FROM := 5.0           # zigzag and go round only when the child is this far or more
const WAIT_FROM := 6.0
const HURT_BELOW := 0.6           # backing off only when its hearts are below this share
const MAX_DRIFT := 0.75           # learning moves a weight at most this far in universe 1 ...
const DRIFT_PER_UNIVERSE := 0.25  # ... and this much more per universe after it (TinyNet.MAX_DELTA at most)

## Being hit up close is part of a fight (a small lesson); an arrow from far is a big one.
const REWARDS := {&"landed": 1.0, &"reached": 0.3, &"answered": 0.2, &"hit": -0.3, &"shot": -1.0,
	&"defeated": -1.0}
## What a species' table learned, told once per world ("<kind>:<tactic>"): short, cheerful, a tip.
const HINTS := {
	"goblin:zigzag": "The goblins remember your bow. They zigzag now!",
	"goblin:go_round": "The goblins learned to come round your side!",
	"goblin:wait": "The goblins wait by cover when you have your bow!",
	"goblin:back_off": "Hurt goblins step back now. Go after them!",
	"goblin:call": "Goblins call their friends now. Listen for the growl!",
	"slime:zigzag": "The slimes remember your bow. They hop side to side!",
	"slime:go_round": "The slimes learned to hop round your side!",
	"slime:wait": "The slimes wait by cover when you have your bow!",
	"slime:back_off": "Hurt slimes hop back now. Go after them!",
	"slime:call": "Slimes call their friends now. Listen for the squish!",
	# M3 Task 2: the Sandstorm Desert's monsters
	"mummy:zigzag": "The mummies remember your bow. They sway side to side!",
	"mummy:go_round": "The mummies learned to shuffle round your side!",
	"mummy:wait": "The mummies wait by cover when you have your bow!",
	"mummy:back_off": "Hurt mummies step back now. Go after them!",
	"mummy:call": "Mummies call their friends now. Listen for the moan!",
	"scorpion:zigzag": "The scorpions remember your bow. They scuttle side to side!",
	"scorpion:go_round": "The scorpions learned to scuttle round your side!",
	"scorpion:wait": "The scorpions wait by cover when you have your bow!",
	"scorpion:back_off": "Hurt scorpions scuttle back now. Go after them!",
	"scorpion:call": "Scorpions call their friends now. Listen for the hiss!",
	# M3 Task 3: Frostpeak's yeti (the ice bat flies its own way: no tactics)
	"yeti:zigzag": "The yetis remember your bow. They stomp side to side!",
	"yeti:go_round": "The yetis learned to come round your side!",
	"yeti:wait": "The yetis wait behind the snow when you have your bow!",
	"yeti:back_off": "Hurt yetis step back now. Go after them!",
	"yeti:call": "Yetis call their friends now. Listen for the roar!",
	# M3 Task 4: the Candy Kingdom's monsters
	"gummy:zigzag": "The gummy bears remember your bow. They bounce side to side!",
	"gummy:go_round": "The gummy bears learned to bounce round your side!",
	"gummy:wait": "The gummy bears wait by cover when you have your bow!",
	"gummy:back_off": "Hurt gummy bears bounce back now. Go after them!",
	"gummy:call": "Gummy bears call their friends now. Listen for the squeak!",
	"sneaker:zigzag": "Candy sneakers remember your bow. They weave side to side!",
	"sneaker:go_round": "The candy sneakers learned to sneak round your side!",
	"sneaker:wait": "The candy sneakers wait by cover when you have your bow!",
	"sneaker:back_off": "Hurt candy sneakers step back now. Go after them!",
	"sneaker:call": "Sneakers call their friends now. Listen for the jingle!",
	# Owner #39: the Dragon Realm's flyers (a tactic only moves where they fly; every attack keeps its signal)
	"shadow_bat:zigzag": "Shadow bats remember your bow. They weave side to side!",
	"shadow_bat:go_round": "Shadow bats learned to swoop in from your side!",
	"shadow_bat:wait": "Shadow bats wait up high when you have your bow!",
	"shadow_bat:back_off": "Hurt shadow bats fly off to rest. Go after them!",
	"shadow_bat:call": "Shadow bats call their friends. Listen for the squeak!",
	"wisp:zigzag": "The wisps remember your bow. They drift side to side!",
	"wisp:go_round": "The wisps learned to float round your side!",
	"wisp:wait": "The wisps wait and watch when you have your bow!",
	"wisp:back_off": "Hurt wisps float away. Go after them!",
	"wisp:call": "Wisps call their friends now. Listen for the chime!",
	"spore_puff:zigzag": "Spore puffs remember your bow. They bob side to side!",   # universe 6
	"spore_puff:go_round": "Spore puffs learned to roll round your side!",
	"spore_puff:wait": "Spore puffs wait in the dark when you have your bow!",
	"spore_puff:back_off": "Hurt spore puffs roll away. Go after them!",
	"spore_puff:call": "Spore puffs call their friends. Listen for the puff!",
	"crawler:zigzag": "Crawlers remember your bow. They scuttle side to side!",
	"crawler:go_round": "Crawlers learned to scuttle round your side!",
	"crawler:wait": "Crawlers wait and listen when you have your bow!",
	"crawler:back_off": "Hurt crawlers scuttle back. Tiptoe after them!",
	"crawler:call": "Crawlers click to their friends. Listen!",
}

static var _tables := {}


static func index(action: StringName) -> int:
	return ACTIONS.find(action)


static func bit(action: StringName) -> int:
	return 1 << index(action)


## The mind table of a monster kind (MonsterRules.KINDS), built once.
static func table(kind: StringName) -> MindSpecies:
	if not _tables.has(kind):
		_tables[kind] = _build(kind)
	return _tables[kind]


static func _build(kind: StringName) -> MindSpecies:
	var t := MindSpecies.new(StringName("monster:%s" % kind), ACTIONS)
	t.feature(F_CLOSE, {S_NEAR: 1.0})
	t.feature(F_ARCHER, {S_RANGED: 1.0, S_NEAR: -1.0})
	t.feature(F_SHOT, {S_SHOT: 1.0})
	t.feature(F_FACED, {S_FACING: 1.0, S_MELEE: 1.0}, -1.0)
	t.feature(F_HURT, {S_HEALTH: -2.0}, 1.2)     # 0 at 60 % of its hearts, 1.2 at none
	t.feature(F_BOLD, {Mind.S_DRIVE_A: 1.0})
	t.feature(F_CAUTIOUS, {Mind.S_DRIVE_B: 1.0})
	t.feature(F_FRIENDS, {S_KIN: 1.0})
	t.feature(F_THREAT, {S_THREAT: 1.0})
	t.feature(F_ONE, {}, 1.0)
	var slime := kind == MonsterRules.SLIME
	t.action_row(STRAIGHT, {F_ONE: 1.0, F_BOLD: 0.5, F_CLOSE: 0.5})
	t.action_row(ZIGZAG, {F_ONE: 0.1, F_SHOT: 0.4, F_ARCHER: 0.2 if not slime else 0.3})
	t.action_row(GO_ROUND, {F_ONE: 0.1, F_FACED: 0.8})
	t.action_row(WAIT, {F_CAUTIOUS: 0.8, F_ARCHER: 0.3, F_BOLD: -0.5}, -0.3)
	t.action_row(BACK_OFF, {F_HURT: 4.0, F_CAUTIOUS: 0.5, F_THREAT: 0.3, F_BOLD: -0.5}, -0.8)
	t.action_row(CALL, {F_FRIENDS: 0.8, F_THREAT: 0.2}, -0.2)
	t.commit = PackedFloat32Array([2.5, 3.0, 3.0, 2.5, 2.5, 0.5])
	# boldness and caution first (the drive senses), then fear, curiosity, company
	t.drive_senses = PackedInt32Array([Mind.BOLDNESS, Mind.CAUTION, Mind.FEAR, Mind.CURIOSITY, Mind.COMPANY])
	t.drive_start = PackedFloat32Array([0.0, 0.0, 0.0, 0.3, 0.3, 0.4 if slime else 0.6, 0.4 if slime else 0.3, 0.0, 0.0])
	t.rewards = REWARDS
	t.learn_rate = 0.15
	t.personality = 0.2
	return t


## Which tactics are possible now (a bit per action): `d` blocks from its target, whether the child
## holds a ranged weapon or faces it, its share of hearts, whether it may call and a quiet friend is near.
static func allowed(d: float, ranged: bool, facing: bool, health: float, called_lately: bool, friend_near: bool) -> int:
	var mask := bit(STRAIGHT)
	if d >= ROUND_FROM:
		mask |= bit(ZIGZAG) | bit(GO_ROUND)
	if d >= WAIT_FROM and (ranged or facing):
		mask |= bit(WAIT)
	if health < HURT_BELOW:
		mask |= bit(BACK_OFF)
	if friend_near and not called_lately:
		mask |= bit(CALL)
	return mask


## The chance of each tactic (by index) now, among `mask` (see Mind.odds).
static func odds(m: Mind, mask: int) -> PackedFloat32Array:
	return m.odds(mask)


## A world's table learns at most MAX_DRIFT per weight in universe 1, a little more in later ones.
static func cap(net: TinyNet, universe: int) -> void:
	net.max_delta = minf(MAX_DRIFT + DRIFT_PER_UNIVERSE * (maxi(universe, 1) - 1), TinyNet.MAX_DELTA)


## What kind of weapon an item is for a monster: none, one for up close, or one that reaches far.
static func weapon_class(item: int) -> int:
	if BlasterRules.is_blaster(item):
		return RANGED                     # M3 Task 14b: a blaster reaches far
	if item == 0 or not WeaponRules.is_weapon(item):
		return NO_WEAPON
	var base := WeaponRules.base_of(item)
	var kind: StringName = WeaponRules.stats(base).get("kind", WeaponRules.MELEE)
	return RANGED if kind == WeaponRules.BOW or kind == WeaponRules.BOOMERANG or base == ItemIds.SPEAR else MELEE


## The situation where a tactic shows it was learned (the net's own scores, no personality): the senses
## for "<tactic>", or an empty array for straight.
static func hint_situation(tactic: StringName) -> PackedFloat32Array:
	var x := PackedFloat32Array()
	x.resize(TinyNet.INPUTS)
	x[S_HEALTH] = 1.0
	x[Mind.S_OUTCOME] = 0.5
	x[Mind.S_DRIVE_A] = 0.5
	x[Mind.S_DRIVE_B] = 0.35
	match tactic:
		ZIGZAG:
			x[S_NEAR] = 0.25
			x[S_RANGED] = 1.0
			x[S_SHOT] = 1.0
		GO_ROUND:
			x[S_NEAR] = 0.6
			x[S_FACING] = 1.0
			x[S_MELEE] = 1.0
		WAIT:
			x[S_NEAR] = 0.25
			x[S_RANGED] = 1.0
		BACK_OFF:
			x[S_NEAR] = 0.8
			x[S_HEALTH] = 0.3
			x[S_THREAT] = 1.0
		CALL:
			x[S_NEAR] = 0.4
			x[S_KIN] = 1.0
		_:
			return PackedFloat32Array()
	return x
