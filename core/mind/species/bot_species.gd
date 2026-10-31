class_name BotSpecies
extends RefCounted
## The bot friends' mind table (M2 Task 18, spec §12.17). A friend's mind learns its child's style:
## a builder picks which small design to build (towers for a tower builder; designs the child keeps
## come back, designs the child breaks less), an explorer learns whether its child follows ores,
## animals or secrets. Every friend owns its net (it learns one child, and is saved with it); its
## BotStyle holds the favourite blocks, shapes, space and guarded side.

## Designs are BotRules' designs by index (Sandbox: 5, Survivor: its first 3).
const DESIGNS: Array[StringName] = [&"design0", &"design1", &"design2", &"design3", &"design4"]
const FIND_ORE := &"find_ore"
const FIND_ANIMAL := &"find_animal"
const FIND_SECRET := &"find_secret"
const FINDS: Array[StringName] = [FIND_ORE, FIND_ANIMAL, FIND_SECRET]
const ACTIONS: Array[StringName] = [&"design0", &"design1", &"design2", &"design3", &"design4",
	FIND_ORE, FIND_ANIMAL, FIND_SECRET]

## Bot senses (the slots animals use for novelty and home).
const S_TALL := Mind.S_NOVEL
const S_WIDE := Mind.S_HOME_FAR

const F_TALL := 0
const F_WIDE := 1
const F_SMALL := 2
const F_ONE := 11

## kept / broken: a build the child keeps or breaks; used / followed / ignored: what the child did
## with something an explorer showed (mined, tamed or opened it / walked over / walked on).
const REWARDS := {&"kept": 1.0, &"broken": -1.0, &"used": 1.0, &"followed": 0.4, &"ignored": -0.4}

static var _table: MindSpecies


static func index(action: StringName) -> int:
	return ACTIONS.find(action)


static func table() -> MindSpecies:
	if _table == null:
		var t := MindSpecies.new(&"bot", ACTIONS)
		t.feature(F_TALL, {S_TALL: 1.0})
		t.feature(F_WIDE, {S_WIDE: 1.0})
		t.feature(F_SMALL, {S_TALL: -1.0, S_WIDE: -1.0}, 1.0)
		t.feature(F_ONE, {}, 1.0)
		# 0 lamp post (3 tall), 1 planter (2 wide), 2 rainbow pillar (5 tall), 3 window pillar (3 tall),
		# 4 little flower (2 tall): BotRules.SANDBOX_DESIGNS.
		t.action_row(&"design0", {F_TALL: 1.0})
		t.action_row(&"design1", {F_WIDE: 1.2})
		t.action_row(&"design2", {F_TALL: 1.3})
		t.action_row(&"design3", {F_TALL: 0.8})
		t.action_row(&"design4", {F_SMALL: 1.0})
		t.action_row(FIND_ORE, {F_ONE: 0.1})
		t.action_row(FIND_ANIMAL, {})
		t.action_row(FIND_SECRET, {F_ONE: 0.2})
		t.commit.fill(0.0)
		t.rewards = REWARDS
		t.learn_rate = 0.3            # one child to learn: a few events matter
		t.personality = 0.2
		t.drive_senses = PackedInt32Array([Mind.HELPFUL, Mind.PLAY, Mind.FEAR, Mind.CURIOSITY, Mind.COMPANY])
		t.drive_start = PackedFloat32Array([0.0, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.7, 0.6])
		_table = t
	return _table


## Which of the first `count` designs to build now (the child's shapes tilt it). The mind remembers
## the choice, so the kept / broken rewards teach the right one.
static func pick_design(m: Mind, style: BotStyle, count: int) -> int:
	_shape_senses(m, style)
	return m.think(_first(count))


## The chance of each design (index) being picked now, for the first `count`.
static func design_odds(m: Mind, style: BotStyle, count: int) -> PackedFloat32Array:
	_shape_senses(m, style)
	return m.odds(_first(count))


## What a friend who knows its child says when it comes back with a saved world: a fixed, friendly
## line with the child's username (never a question, never guilt).
static func greeting(username: String, bot_name: String, personality: StringName) -> String:
	var tail: String = {BotRules.BUILDER: "Let's build something cool!", BotRules.EXPLORER: "Let's go exploring!",
		BotRules.FIGHTER: "I'll keep you safe!"}.get(personality, "Let's play!")
	return Lang.t("Hi %s! It's me, %s! %s") % [username, bot_name, tail]


static func find_mask(kinds: Array[StringName]) -> int:
	return table().mask(kinds)


## What to show the child first among `mask` (FIND_ORE, FIND_ANIMAL, FIND_SECRET).
static func pick_find(m: Mind, mask: int) -> StringName:
	_shape_senses(m, null)
	var a := m.think(mask)
	return ACTIONS[a] if a >= 0 else &""


## The chance of each find kind (by action index) being picked now among `mask`.
static func find_odds(m: Mind, mask: int) -> PackedFloat32Array:
	_shape_senses(m, null)
	return m.odds(mask)


static func _shape_senses(m: Mind, style: BotStyle) -> void:
	var s := style.shape() if style else Vector2.ZERO
	m.senses[S_TALL] = s.x
	m.senses[S_WIDE] = s.y


static func _first(count: int) -> int:
	return (1 << clampi(count, 1, DESIGNS.size())) - 1
