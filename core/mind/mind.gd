class_name Mind
extends RefCounted
## A creature's small learned mind (M2 Task 18, owner feedback #24, spec §12.17): "like a small
## LLM" in idea — a tiny network picks what to do next from what the creature senses and remembers,
## and learns from what happens — sized for a phone (not a text model: ruling in §12.17).
##
## senses (TinyNet.INPUTS numbers, 0..1; the creature fills the world facts, the mind its drives
## and how the last action went) → the species' TinyNet → one score per action, plus this
## individual's personality offset (from its id: no two sheep are the same) → a gentle softmax pick
## among the actions that are possible now. An action is kept for a while (the species' commit
## time) unless something happens (interrupt()). reward() after an outcome teaches the net's last
## layer. Drives rise and fall like needs; the memory knows players and places. A wild creature
## shares its species' net (MindBook: what one sheep learns, every sheep of that world learns); pets
## and friends that learn alone own theirs. Pure: no scene tree.

# Senses (TinyNet.INPUTS slots, 0..1). The creature fills the world facts before think().
const S_NEAR := 0         # the nearest player: 1 = right here, 0 = far
const S_LIKE := 1         # how much it likes that player
const S_FEAR := 2         # how much it fears that player
const S_RUSH := 3         # that player rushing at it
const S_HEALTH := 4       # its own hearts
const S_DRIVE_A := 5      # the species' drive_senses fill 5..9 (animals: hunger, sleepiness, fear, curiosity, company)
const S_DRIVE_B := 6
const S_AFRAID := 7
const S_CURIOUS := 8
const S_LONELY := 9
const S_NIGHT := 10       # 1 at night
const S_KIN := 11         # friends of its kind near
const S_THREAT := 12      # hit lately
const S_NOVEL := 13       # something new near (a block, a face)
const S_HOME_FAR := 14    # how far from its den or favourite place
const S_OUTCOME := 15     # how the last action went (0.5 = nothing happened)

# Drives (0..1).
const HUNGER := 0
const SLEEPY := 1
const FEAR := 2
const CURIOSITY := 3
const COMPANY := 4
const BOLDNESS := 5       # monsters
const CAUTION := 6        # monsters
const HELPFUL := 7        # bot friends
const PLAY := 8           # bot friends
const DRIVE_COUNT := 9

const BUBBLE_GAP := 8.0   # seconds between two thoughts of one creature (not spammy)
const REPEAT_GAP := 3.0   # the same picture again waits this many gaps (a sleeping herd isn't a zzz storm)
const REACTION_GAP := 2.0 # an answer to what a child just did waits only this long
const FORGET_EVERY := 1.0

## Cost check (tools/minds_bench.gd): while on, creatures count their mind steps (and the wall-clock
## microseconds they took) and minds count their picks.
static var profiling := false
static var spent_us := 0
static var steps := 0
static var thinks := 0

var species: MindSpecies
var net: TinyNet
var owns_net := true      # saved with the creature (pets, friends); false = the species' shared net
var memory := MindMemory.new()
var drives := PackedFloat32Array()
var personality := PackedFloat32Array()
var senses := PackedFloat32Array()
var action := -1
var clock := 0.0          # its own time (s), advanced by tick()
## 1 = learns normally, 0 = never learns (Cozy monsters), in between = slower (Sandbox monsters).
var learning := 1.0
var raw := PackedFloat32Array()      # the net's scores at the last think
var scores := PackedFloat32Array()   # plus personality: what the pick used
var lessons := 0                     # rewards that taught it something

var _h0 := Vector4()                # the hidden activations of the last pick (to learn from later)
var _h1 := Vector4()
var _h2 := Vector4()
var _picked := false
var _weights := PackedFloat32Array()
var _next_think := 0.0
var _urgent := true
var _baseline := 0.0
var _outcome := 0.5
var _rng := RandomNumberGenerator.new()
var _thought := Thought.NONE
var _last_thought := -INF
var _last_picture := Thought.NONE
var _reaction := false
var _forget_t := 0.0


## The mind of individual `id` of `species`. shared: the species' net for this world (MindBook);
## without it the mind gets a fresh net of its own.
static func create(p_species: MindSpecies, id: String, shared: TinyNet = null) -> Mind:
	var m := Mind.new()
	m.species = p_species
	m.owns_net = shared == null
	m.net = shared if shared else p_species.make_net(hash(String(p_species.id)))
	m._rng.seed = hash(String(p_species.id) + ":" + id)
	var n := p_species.actions.size()
	m.personality.resize(n)
	for a in n:
		m.personality[a] = m._rng.randf_range(-p_species.personality, p_species.personality)
	m.drives.resize(DRIVE_COUNT)
	for d in DRIVE_COUNT:
		m.drives[d] = clampf(p_species.drive_start[d] + m._rng.randf_range(-0.15, 0.15), 0.0, 1.0)
	m.senses.resize(TinyNet.INPUTS)
	m.senses[S_HEALTH] = 1.0
	m.senses[S_OUTCOME] = 0.5
	m.scores.resize(n)
	m._weights.resize(n)
	return m


## One mind step of a creature took `us` microseconds (only while profiling).
static func note_cost(us: int) -> void:
	spent_us += us
	steps += 1


## Lets `dt` seconds pass: its clock runs and its memory slowly forgets.
func tick(dt: float) -> void:
	clock += dt
	_forget_t += dt
	if _forget_t >= FORGET_EVERY:
		memory.forget(clock, _forget_t)
		_forget_t = 0.0


func drive(d: int) -> float:
	return drives[d]


## Moves drive `d` towards `target` at `rate` per second.
func nudge(d: int, target: float, rate: float, dt: float) -> void:
	drives[d] = clampf(move_toward(drives[d], target, rate * dt), 0.0, 1.0)


func set_drive(d: int, value: float) -> void:
	drives[d] = clampf(value, 0.0, 1.0) if is_finite(value) else drives[d]


## Time to pick again: the current action has run its course, or something happened.
func due() -> bool:
	return _urgent or clock >= _next_think


## Something happened (a hit, a treat, night fell): think again at the next chance.
func interrupt() -> void:
	_urgent = true


## Picks the next action among `allowed` (a bit per action index; -1 = any) from the current senses.
## Returns the action index (the current one when nothing is allowed).
func think(allowed: int = -1) -> int:
	if profiling:
		thinks += 1
	for k in species.drive_senses.size():
		senses[S_DRIVE_A + k] = drives[species.drive_senses[k]]
	senses[S_OUTCOME] = _outcome
	raw = net.forward(senses)
	_h0 = net.h0
	_h1 = net.h1
	_h2 = net.h2
	_picked = true
	var n := raw.size()
	var best := -INF
	for a in n:
		var s: float = raw[a] + personality[a]
		scores[a] = s
		if allowed & (1 << a) and s > best:
			best = s
	_urgent = false
	if best == -INF:
		return action
	var total := 0.0
	for a in n:
		var w := exp((scores[a] - best) / species.temperature) if allowed & (1 << a) else 0.0
		_weights[a] = w
		total += w
	var r := _rng.randf() * total
	var pick := -1
	for a in n:
		if _weights[a] <= 0.0:
			continue
		pick = a
		r -= _weights[a]
		if r <= 0.0:
			break
	action = pick
	_next_think = clock + species.commit[pick] * _rng.randf_range(0.7, 1.3)
	var picture := int(species.thoughts.get(pick, Thought.NONE))
	if picture != Thought.NONE:
		show_thought(picture)
	return pick


## Takes up `a` as if it had picked it (its commit time starts); for scripted moments and tests.
func hold(a: int) -> void:
	if a < 0 or a >= species.actions.size():
		return
	action = a
	_urgent = false
	_next_think = clock + species.commit[a]


## The chance of each action (by index) being picked now among `allowed`, without picking.
func odds(allowed: int = -1) -> PackedFloat32Array:
	for k in species.drive_senses.size():
		senses[S_DRIVE_A + k] = drives[species.drive_senses[k]]
	senses[S_OUTCOME] = _outcome
	var r := net.forward(senses)
	var out := PackedFloat32Array()
	out.resize(r.size())
	var best := -INF
	for a in r.size():
		if allowed & (1 << a):
			best = maxf(best, r[a] + personality[a])
	if best == -INF:
		return out
	var total := 0.0
	for a in r.size():
		if allowed & (1 << a):
			out[a] = exp((r[a] + personality[a] - best) / species.temperature)
			total += out[a]
	for a in r.size():
		out[a] /= total
	return out


## How the current action went, -1..1: teaches the net (unless learning is off) and becomes the
## "last outcome" sense. Returns the amount.
func reward(amount: float) -> float:
	return credit(action, last_hidden(), amount)


## How an earlier pick went (its action and the hidden activations it was picked with, from
## last_hidden()): for outcomes that come long after the pick, like a build the child keeps.
func credit(p_action: int, hidden: PackedFloat32Array, amount: float) -> float:
	if not is_finite(amount):
		return 0.0
	amount = clampf(amount, -1.0, 1.0)
	_outcome = clampf(0.5 + amount * 0.5, 0.0, 1.0)
	if p_action < 0 or hidden.is_empty() or learning <= 0.0 or amount == 0.0:
		return amount
	var advantage := amount - _baseline
	_baseline = lerpf(_baseline, amount, 0.2)
	net.learn(p_action, advantage, species.learn_rate * clampf(learning, 0.0, 1.0), hidden)
	lessons += 1
	return amount


## The hidden activations of the last pick (keep them to credit() that pick later).
func last_hidden() -> PackedFloat32Array:
	if not _picked:
		return PackedFloat32Array()
	return PackedFloat32Array([_h0.x, _h0.y, _h0.z, _h0.w, _h1.x, _h1.y, _h1.z, _h1.w, _h2.x, _h2.y, _h2.z, _h2.w])


## An event from the species' reward table (&"fed", &"hit", ...). Returns its reward.
func feel(event: StringName) -> float:
	return reward(float(species.rewards.get(event, 0.0)))


## A thought to show when the next bubble may come.
## reaction: an answer to something a child just did (fed, petted, hit it) comes after only REACTION_GAP.
func show_thought(picture: int, reaction := false) -> void:
	if Thought.valid(picture):
		_thought = picture
		_reaction = reaction


## The thought to show now (once), or Thought.NONE: at most one every BUBBLE_GAP seconds.
func take_thought() -> int:
	if _thought == Thought.NONE or clock - _last_thought < (REACTION_GAP if _reaction else BUBBLE_GAP):
		return Thought.NONE
	var t := _thought
	_thought = Thought.NONE
	if not _reaction and t == _last_picture and clock - _last_thought < BUBBLE_GAP * REPEAT_GAP:
		return Thought.NONE              # the same picture again so soon: once is enough
	_last_thought = clock
	_last_picture = t
	return t


## A random number from this mind's own generator (deterministic per individual).
func roll() -> float:
	return _rng.randf()


## For the world save (pets, bot friends): memory, drives and, for a net of its own, its learning.
func to_save() -> Dictionary:
	var d := {"m": memory.to_save(), "d": Array(drives).map(func(v: float) -> float: return snappedf(v, 0.01))}
	if owns_net and not net.is_fresh():
		d.n = net.to_save()
	return d


## Restores a save made by to_save(); anything broken is ignored.
func load_save(d: Variant) -> void:
	if not d is Dictionary:
		return
	var s: Dictionary = d
	memory = MindMemory.from_save(s.get("m"))
	var saved: Variant = s.get("d")
	if saved is Array and (saved as Array).size() == DRIVE_COUNT:
		for i in DRIVE_COUNT:
			var v: Variant = saved[i]
			if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
				drives[i] = clampf(float(v), 0.0, 1.0)
	if owns_net and s.get("n") is String:
		net.load_save(str(s.n))
