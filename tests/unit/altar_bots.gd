extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.9, §4.6; the phase A model's players,
## docs/design/games/balance-altar/model/altar_rules.py): children with and without the knowledge, as bots that play a
## whole room through the production rules (AltarRun, so AltarMoves' waiting batches, the help policy, the ghost and
## AltarBeats' judging are what is tested). A bot decides a twin move (or a misconception's act) as the model's players
## do; the driver turns it into what the hands do: a take is a long press and its twin (or lift by lift), an add the gem
## bag's gems pair by pair, a share the bowls, "one pan" a lift and then the crystal tapped, "across" a thing carried
## over, "weigh" the crystal lifted and then the other pan's gems. The random tapper taps things one at a time, as the
## model's play_taps does.

const RULE := "knows the rule"
const SLIPS := "knows it, slips 4 %"
const GREEDY := "keeps balance, greedy"
const NO_PLAN := "keeps balance, no plan"
const GUESS := "guesses which move"
const TAKE_ONLY := "habit: always take away"
const SHARE_ONLY := "habit: divide by the number"
const HABIT := "the hall's habit"
const RANDOM_MOVES := "random moves"
const RANDOM_TAPS := "random taps"
const ONE_PAN := "one pan only"
const ACROSS := "carries across"
const WEIGH := "weighs (chained beam)"
const SLIP := 0.04

const GEM := AltarState.GEM
const BALLOON := AltarState.BALLOON
const CRYSTAL := AltarState.CRYSTAL


## One visit: the room played by `bot` from `seed` (the room's numbers and the bot's choices both seeded): {masters,
## right_first, total, breaks, kinds (the judged altars' event kinds)}.
static func play(room: String, bot: String, seed: int) -> Dictionary:
	var run := AltarRun.make(room, seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 13
	run.start()
	var breaks := 0
	while not run.is_done():
		var guard := 0
		while not run.freed():
			guard += 1
			assert(guard < 400, "the ghost frees every altar within AltarRun.CAP acts")
			if bot == RANDOM_TAPS:
				_tap(run, rng)
			else:
				_act(run, decide(bot, run.moves.state, run.tools, rng))
		breaks += run.moves.breaks
		run.take_cues()
		run.next_altar()
	var kinds := run.beats.judged().map(func(r: Dictionary) -> String: return str(r.kind))
	return {"masters": run.beats.masters(), "right_first": run.beats.right_first(), "total": run.beats.total(),
		"breaks": breaks, "kinds": kinds}


# --- The players' decisions (the model's) -----------------------------------------------------------------------------

static func decide(bot: String, s: AltarState, tools: Array[String], rng: RandomNumberGenerator) -> Dictionary:
	match bot:
		RULE:
			return rule(s, tools)
		SLIPS:
			return {"verb": "one_pan"} if rng.randf() < SLIP else rule(s, tools)
		GREEDY:
			return _greedy(s, tools, rng)
		NO_PLAN:
			return _no_plan(s, tools, rng)
		GUESS:
			return _guess(s, rng)
		TAKE_ONLY:
			return _take_only(s)
		SHARE_ONLY:
			return _share_only(s)
		HABIT:
			return _habit(s)
		RANDOM_MOVES:
			return _random_move(rng)
		ONE_PAN:
			return {"verb": "one_pan"}
		ACROSS:
			return {"verb": "across"}
		WEIGH:
			return {"verb": "weigh"}
	return {"verb": "one_pan"}


## Knows it: the same to both pans; gather the crystals on one pan; undo what is beside the crystal (take its gems; a
## balloon is undone by a gem), then share by the crystal count.
static func rule(s: AltarState, tools: Array[String]) -> Dictionary:
	var side := s.crystal_pan()
	var c := s.crystals(side)
	var k := s.gems(side)
	var oc := s.crystals(1 - side)
	var ok := s.gems(1 - side)
	if c > 0 and oc > 0:
		return AltarMoves.take(CRYSTAL, mini(c, oc))
	if k > 0:
		if ok >= k:
			return AltarMoves.take(GEM, k)
		return AltarMoves.add(BALLOON, k) if tools.has(AltarMoves.PUMP) else AltarMoves.take(GEM, k)
	if k < 0:
		return AltarMoves.add(GEM, -k)
	if c > 1:
		return AltarMoves.share(c)
	return AltarMoves.take(GEM, 1)


## Keeps the balance (only twin moves) and always does the move that leaves the crystal most alone.
static func _greedy(s: AltarState, tools: Array[String], rng: RandomNumberGenerator) -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	for op: Dictionary in AltarMoves.legal_ops(s, tools):
		var score := float(AltarMoves.apply(s, op).clutter()) + rng.randf() * 0.5
		if score < best_score:
			best_score = score
			best = op
	return best


## Keeps the balance with no plan: a random twin move (a kind of move first, then its size).
static func _no_plan(s: AltarState, tools: Array[String], rng: RandomNumberGenerator) -> Dictionary:
	var groups := {}
	for op: Dictionary in AltarMoves.legal_ops(s, tools, 3):
		var t := AltarMoves.tag(op)
		if not groups.has(t):
			groups[t] = []
		(groups[t] as Array).append(op)
	var keys := groups.keys()
	keys.sort()
	var group: Array = groups[keys[rng.randi_range(0, keys.size() - 1)]]
	return group[rng.randi_range(0, group.size() - 1)]


## Knows the moves and the twin rule but not which move undoes what: guesses take, add or share each time.
static func _guess(s: AltarState, rng: RandomNumberGenerator) -> Dictionary:
	var side := s.crystal_pan()
	var c := s.crystals(side)
	var k := s.gems(side)
	var kind := GEM if k > 0 else (BALLOON if k < 0 else CRYSTAL)
	var n := absi(k) if k != 0 else maxi(c, 1)
	match rng.randi_range(0, 2):
		0:
			return AltarMoves.take(kind, n)
		1:
			return AltarMoves.add(GEM, n)
	return AltarMoves.share(rng.randi_range(2, 6))


## The habit "take away": takes what is beside the crystal off both pans; never shares, never adds.
static func _take_only(s: AltarState) -> Dictionary:
	var side := s.crystal_pan()
	var k := s.gems(side)
	if k > 0:
		return AltarMoves.take(GEM, k)
	if k < 0:
		return AltarMoves.take(BALLOON, -k)
	return AltarMoves.take(CRYSTAL, maxi(s.crystals(side) - 1, 1))


## The habit "divide by the number you see": shares by the number beside the crystal.
static func _share_only(s: AltarState) -> Dictionary:
	var side := s.crystal_pan()
	var c := s.crystals(side)
	var k := s.gems(side)
	var n := c if c > 1 else (absi(k) if k != 0 else 2)
	return AltarMoves.share(maxi(n, 2))


## The hall's routine as a recipe (the Sky Room's habit; Knuth's "unwind"): take away what is beside the crystal, then
## share by the crystal count. Never adds.
static func _habit(s: AltarState) -> Dictionary:
	var side := s.crystal_pan()
	var c := s.crystals(side)
	var k := s.gems(side)
	if k > 0:
		return AltarMoves.take(GEM, k)
	if k < 0:
		return AltarMoves.take(BALLOON, -k)
	if c > 1:
		return AltarMoves.share(c)
	return AltarMoves.take(GEM, 1)


## Random moves of every kind, fair or not.
static func _random_move(rng: RandomNumberGenerator) -> Dictionary:
	match rng.randi_range(0, 5):
		0:
			return {"verb": "one_pan"}
		1:
			return {"verb": "across"}
		2:
			return AltarMoves.take([GEM, BALLOON, CRYSTAL][rng.randi_range(0, 2)], rng.randi_range(1, 4))
		3:
			return AltarMoves.add([GEM, BALLOON][rng.randi_range(0, 1)], rng.randi_range(1, 4))
	return AltarMoves.share(rng.randi_range(2, 6))


# --- The hands ------------------------------------------------------------------------------------------------------

## A decision done with the hands, act by act, stopping once the crystal is free.
static func _act(run: AltarRun, op: Dictionary) -> void:
	var s := run.moves.state
	var side := s.crystal_pan()
	var other := 1 - side
	match str(op.get("verb", "")):
		AltarMoves.TAKE:
			var kind := str(op.kind)
			var n := int(op.n)
			if n == s.amount(side, kind) and n > 0:
				run.handful(side, kind)
				if not run.freed():
					run.handful(other, kind)
				return
			for i in n:
				run.lift(side, kind)
			for i in n:
				if run.freed():
					return
				run.lift(other, kind)
		AltarMoves.ADD:
			for i in int(op.n):
				run.place(side, str(op.kind))
			for i in int(op.n):
				if run.freed():
					return
				run.place(other, str(op.kind))
		AltarMoves.SHARE:
			run.share_by(int(op.n))
		"one_pan":
			run.lift(side, _some_kind(s, side))
			run.tap_crystal()
		"across":
			run.carry_across(side, _some_kind(s, side))
		"weigh":
			run.lift(side, CRYSTAL)
			run.lift(other, _some_kind(s, other))


## A kind the pan holds (its gems, balloons, else a crystal).
static func _some_kind(s: AltarState, pan: int) -> String:
	for kind: String in [GEM, BALLOON, CRYSTAL]:
		if s.amount(pan, kind) > 0:
			return kind
	return CRYSTAL


## The random tapper (the model's play_taps): lift something, put something from a supply on a pan, share, put back,
## carry across, or tap the crystal.
static func _tap(run: AltarRun, rng: RandomNumberGenerator) -> void:
	var s := run.moves.state
	var r := rng.randf()
	var side := rng.randi_range(0, 1)
	var supply: Array[String] = []
	if run.tools.has(AltarMoves.GEM_BAG):
		supply.append(GEM)
	if run.tools.has(AltarMoves.PUMP):
		supply.append(BALLOON)
	if r < 0.45:
		var kinds: Array[String] = []
		for kind: String in [GEM, BALLOON, CRYSTAL]:
			if s.amount(side, kind) > 0:
				kinds.append(kind)
		run.lift(side, kinds[rng.randi_range(0, kinds.size() - 1)] if not kinds.is_empty() else GEM)
	elif r < 0.65 and not supply.is_empty():
		run.place(side, supply[rng.randi_range(0, supply.size() - 1)])
	elif r < 0.78:
		run.share_by(rng.randi_range(2, 6))
	elif r < 0.86:
		run.put_back()
	elif r < 0.94:
		run.carry_across(side, _some_kind(s, side))
	else:
		run.tap_crystal()
