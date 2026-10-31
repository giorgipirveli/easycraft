class_name MindSpecies
extends RefCounted
## A kind of creature's mind table (M2 Task 18, spec §12.17): its actions, the hand-made default
## weights of its TinyNet (hidden units are readable features such as "danger" or "a friend is
## near"; the output rows say how much each feature speaks for each action), what rewards it, how
## long it keeps an action, which picture each action thinks, and how big a personality gets. The
## tables live in core/mind/species/ and are built once.

var id: StringName
var actions: Array[StringName] = []
## TinyNet.HIDDEN rows of TinyNet.INPUTS weights plus a bias.
var hidden_defaults := PackedFloat32Array()
## One row per action of TinyNet.HIDDEN weights plus a bias.
var output_defaults := PackedFloat32Array()
## Which drives fill the drive senses (Mind.S_DRIVE_A .. Mind.S_LONELY), in order.
var drive_senses := PackedInt32Array([0, 1, 2, 3, 4])
## Where a new individual's drives start (Mind.DRIVE_COUNT values; each gets its own wobble).
var drive_start := PackedFloat32Array()
## event -> reward (-1..1): what the creature likes and dislikes.
var rewards := {}
## action index -> Thought id shown when it starts that action.
var thoughts := {}
## Seconds an action is kept (per action) before the mind thinks again, unless something happens.
var commit := PackedFloat32Array()
var learn_rate := 0.05
var temperature := 0.35           # the gentle pick: lower = always the best, higher = livelier
var personality := 0.3            # per-individual offsets on each action's score, up to ±this
var noise := 0.03                 # the seeded wobble on every default weight


func _init(p_id: StringName = &"", p_actions: Array[StringName] = []) -> void:
	id = p_id
	actions = p_actions
	hidden_defaults.resize(TinyNet.HIDDEN * (TinyNet.INPUTS + 1))
	output_defaults.resize(actions.size() * (TinyNet.HIDDEN + 1))
	commit.resize(actions.size())
	commit.fill(3.0)
	drive_start.resize(9)
	drive_start.fill(0.2)


func index(action: StringName) -> int:
	return actions.find(action)


## Hidden unit `h` reads the senses: {sense index: weight}, plus a bias.
func feature(h: int, weights: Dictionary, bias := 0.0) -> void:
	var row := h * (TinyNet.INPUTS + 1)
	for s: int in weights:
		hidden_defaults[row + s] = float(weights[s])
	hidden_defaults[row + TinyNet.INPUTS] = bias


## How much each feature speaks for `action`: {feature index: weight}, plus a bias; all times `scale`.
func action_row(action: StringName, weights: Dictionary, bias := 0.0, scale := 1.0) -> void:
	var row := index(action) * (TinyNet.HIDDEN + 1)
	for f: int in weights:
		output_defaults[row + f] = float(weights[f]) * scale
	output_defaults[row + TinyNet.HIDDEN] = bias * scale


## A fresh net of this species (hand-made defaults plus a seeded wobble).
func make_net(seed: int) -> TinyNet:
	return TinyNet.create(actions.size(), seed, hidden_defaults, output_defaults, noise)


## The bit mask (for Mind.think) of `names`.
func mask(names: Array[StringName]) -> int:
	var m := 0
	for n in names:
		var i := index(n)
		if i >= 0:
			m |= 1 << i
	return m
