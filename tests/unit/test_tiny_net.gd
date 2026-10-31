extends GutTest
## TinyNet (M2 Task 18, owner feedback #24, spec §12.17): the small neural network inside every
## creature's mind — one hidden layer on PackedFloat32Array, a gentle output-layer reward update with
## clamped weights, a deterministic start from a seed, and a small save.


func _inputs(values: Array) -> PackedFloat32Array:
	var x := PackedFloat32Array()
	x.resize(TinyNet.INPUTS)
	for i in values.size():
		x[i] = float(values[i])
	return x


## The same sums written out slowly, as the reference the fast forward pass must match.
func _slow_forward(net: TinyNet, x: PackedFloat32Array) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(TinyNet.HIDDEN)
	for j in TinyNet.HIDDEN:
		var s: float = net.b1[j]
		for i in TinyNet.INPUTS:
			s += net.w1[j * TinyNet.INPUTS + i] * x[i]
		h[j] = maxf(s, 0.0)
	var out := PackedFloat32Array()
	out.resize(net.outputs)
	for a in net.outputs:
		var s: float = net.b2[a]
		for j in TinyNet.HIDDEN:
			s += net.w2[a * TinyNet.HIDDEN + j] * h[j]
		out[a] = s
	return out


func test_the_forward_pass_matches_the_written_out_sums() -> void:
	for outputs in [3, 5, 8]:
		var net := TinyNet.create(outputs, 1234, PackedFloat32Array(), PackedFloat32Array(), 0.8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for k in 5:
			var x := PackedFloat32Array()
			x.resize(TinyNet.INPUTS)
			for i in TinyNet.INPUTS:
				x[i] = rng.randf()
			var fast := net.forward(x)
			var slow := _slow_forward(net, x)
			assert_eq(fast.size(), outputs)
			for a in outputs:
				assert_almost_eq(fast[a], slow[a], 0.0005, "%d outputs, score %d" % [outputs, a])


func test_hand_made_defaults_decide_the_start() -> void:
	# Hidden unit 0 copies input 3; output 1 reads hidden unit 0 strongly: input 3 lifts output 1.
	var hidden := PackedFloat32Array()
	hidden.resize(TinyNet.HIDDEN * (TinyNet.INPUTS + 1))
	hidden[0 * (TinyNet.INPUTS + 1) + 3] = 1.0
	var out := PackedFloat32Array()
	out.resize(2 * (TinyNet.HIDDEN + 1))
	out[1 * (TinyNet.HIDDEN + 1) + 0] = 2.0
	var net := TinyNet.create(2, 7, hidden, out, 0.0)
	var quiet := net.forward(_inputs([]))
	var lifted := net.forward(_inputs([0, 0, 0, 1.0]))
	assert_almost_eq(quiet[1], 0.0, 0.0001)
	assert_almost_eq(lifted[1], 2.0, 0.0001)
	assert_almost_eq(lifted[0], 0.0, 0.0001)


func test_the_same_seed_gives_the_same_net_and_another_seed_a_different_one() -> void:
	var a := TinyNet.create(6, 42)
	var b := TinyNet.create(6, 42)
	var c := TinyNet.create(6, 43)
	assert_eq(a.w1, b.w1)
	assert_eq(a.w2, b.w2)
	assert_ne(a.w1, c.w1)


func test_learning_raises_a_rewarded_action_and_lowers_a_punished_one() -> void:
	var net := TinyNet.create(4, 5, PackedFloat32Array(), PackedFloat32Array(), 0.1)
	var x := _inputs([1, 0.5, 0, 1, 0.2])
	var before := net.forward(x)
	var h := net.last_hidden()
	net.learn(1, 1.0, 0.2, h)
	net.learn(2, -1.0, 0.2, h)
	var after := net.forward(x)
	assert_gt(after[1], before[1], "rewarded: scores higher in the same situation")
	assert_lt(after[2], before[2], "punished: scores lower")
	assert_almost_eq(after[0], before[0], 0.0001, "only the chosen action's weights move")
	assert_almost_eq(after[3], before[3], 0.0001)


## A toy world: in situation A action 2 pays, in situation B action 0 pays, everything else costs a
## little. The hidden layer is hand-made (as in every species: unit 0 notices A, unit 1 notices B);
## a mind that picks by the net's scores (softmax) and learns from the pay finds both.
func test_learning_converges_on_a_toy_reward_and_stays_clamped() -> void:
	var hidden := PackedFloat32Array()
	hidden.resize(TinyNet.HIDDEN * (TinyNet.INPUTS + 1))
	hidden[0 * (TinyNet.INPUTS + 1) + 0] = 1.0
	hidden[1 * (TinyNet.INPUTS + 1) + 1] = 1.0
	var net := TinyNet.create(4, 11, hidden, PackedFloat32Array(), 0.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var sa := _inputs([1, 0])
	var sb := _inputs([0, 1])
	for step in 600:
		var in_a := step % 2 == 0
		var x := sa if in_a else sb
		var scores := net.forward(x)
		var pick := _softmax_pick(scores, rng)
		var good := 2 if in_a else 0
		net.learn(pick, 1.0 if pick == good else -0.3, 0.1, net.last_hidden())
	assert_eq(_best(net.forward(sa)), 2, "situation A: action 2")
	assert_eq(_best(net.forward(sb)), 0, "situation B: action 0")
	# Hammering one action for ever never breaks the net: every learned weight stays within the clamp.
	for i in 5000:
		net.forward(sa)
		net.learn(2, 1.0, 0.5, net.last_hidden())
	for w in net.w2:
		assert_between(w, -TinyNet.MAX_WEIGHT, TinyNet.MAX_WEIGHT)
	for w in net.b2:
		assert_between(w, -TinyNet.MAX_WEIGHT, TinyNet.MAX_WEIGHT)
	for i in net.w2.size():
		assert_lte(absf(net.w2[i] - net.base2[i]), TinyNet.MAX_DELTA + 0.0001, "drifts gently from its defaults")


func _softmax_pick(scores: PackedFloat32Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	var e := PackedFloat32Array()
	for s in scores:
		e.append(exp(s / 0.4))
		total += e[e.size() - 1]
	var r := rng.randf() * total
	for i in e.size():
		r -= e[i]
		if r <= 0.0:
			return i
	return e.size() - 1


func _best(scores: PackedFloat32Array) -> int:
	var best := 0
	for i in scores.size():
		if scores[i] > scores[best]:
			best = i
	return best


func test_only_the_output_layer_learns() -> void:
	var net := TinyNet.create(5, 8)
	var w1 := net.w1.duplicate()
	var b1 := net.b1.duplicate()
	net.forward(_inputs([1, 1, 1, 1]))
	for i in 50:
		net.learn(i % 5, 1.0, 0.3, net.last_hidden())
	assert_eq(net.w1, w1)
	assert_eq(net.b1, b1)


func test_save_and_load_round_trip_in_under_two_kilobytes() -> void:
	var net := TinyNet.create(8, 21)
	var x := _inputs([0.3, 0.9, 0.1, 0.5, 1, 0, 0.2])
	for i in 40:
		net.forward(x)
		net.learn(i % 8, 0.7 if i % 3 == 0 else -0.4, 0.2, net.last_hidden())
	var text := net.to_save()
	assert_lte(text.length(), 2048, "a saved net is small")
	var back := TinyNet.create(8, 21)
	assert_true(back.load_save(text))
	var a := net.forward(x)
	var b := back.forward(x)
	for i in a.size():
		assert_almost_eq(b[i], a[i], 0.05, "score %d comes back" % i)


func test_a_fresh_net_saves_as_nothing_learned() -> void:
	var net := TinyNet.create(8, 21)
	assert_true(net.is_fresh())
	var x := _inputs([1])
	net.forward(x)
	net.learn(0, 1.0, 0.2, net.last_hidden())
	assert_false(net.is_fresh())


func test_broken_saves_are_ignored() -> void:
	var net := TinyNet.create(8, 21)
	var before := net.w2.duplicate()
	for bad in ["", "not base64!!", Marshalls.raw_to_base64(PackedByteArray([1, 2, 3]))]:
		assert_false(net.load_save(bad), "rejects %s" % bad)
	assert_eq(net.w2, before, "and keeps its weights")
