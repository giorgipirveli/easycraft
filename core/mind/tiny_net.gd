class_name TinyNet
extends RefCounted
## The small neural network inside every creature's mind (M2 Task 18, owner feedback #24, spec
## §12.17): INPUTS senses → HIDDEN rectified units → one score per action. The same idea as a
## language model's (a network picks what comes next from what it sees and learns from what
## happens), sized for a phone: a few hundred weights, and a forward pass of about a microsecond.
##
## The weights live on PackedFloat32Array (w1/b1: the hidden layer, w2/b2: the output layer). The
## forward pass runs on native 4 × 4 blocks (Projection × Vector4) copied from them: the same sums
## written as a GDScript loop cost 18 µs on the desktop, the blocks 0.75 µs (measured, Task 18 notes).
## Only the output layer learns (learn(): a small step for the chosen action, every learned weight
## clamped to ±MAX_WEIGHT and to ±MAX_DELTA of its hand-made default), so a mind drifts gently and
## never breaks. A save holds just those drifts, as one signed byte each.

const INPUTS := 16
const HIDDEN := 12
const MAX_WEIGHT := 5.0
const MAX_DELTA := 2.0

var outputs := 0
var w1 := PackedFloat32Array()     # HIDDEN rows of INPUTS
var b1 := PackedFloat32Array()     # HIDDEN
var w2 := PackedFloat32Array()     # outputs rows of HIDDEN
var b2 := PackedFloat32Array()     # outputs
## The output layer's starting point (w2 then b2): what learning drifts from and a save is relative to.
var base2 := PackedFloat32Array()
## How far learning may move a weight from its default (MAX_DELTA at most; a monster table's is capped
## by the universe, MonsterSpecies.cap).
var max_delta := MAX_DELTA

var _p1: Array[Projection] = []    # hidden layer blocks: [row block * 4 + input block]
var _c1: Array[Vector4] = []       # hidden biases per row block
var _p2: Array[Projection] = []    # output layer blocks: [row block * 3 + hidden block]
var _c2: Array[Vector4] = []
## The hidden activations of the last forward pass, four units each (last_hidden() as one array).
var h0 := Vector4()
var h1 := Vector4()
var h2 := Vector4()
var _scores := PackedFloat32Array()


## A net for `outputs` actions. hidden_defaults: HIDDEN rows of INPUTS weights plus a bias;
## output_defaults: `outputs` rows of HIDDEN weights plus a bias (empty = all zero). Every weight
## gets a small seeded wobble of up to ±noise, so two seeds never make the same net.
static func create(outputs: int, seed: int, hidden_defaults := PackedFloat32Array(),
		output_defaults := PackedFloat32Array(), noise := 0.05) -> TinyNet:
	var net := TinyNet.new()
	net.outputs = clampi(outputs, 1, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	net.w1.resize(HIDDEN * INPUTS)
	net.b1.resize(HIDDEN)
	for j in HIDDEN:
		for i in INPUTS + 1:
			var k := j * (INPUTS + 1) + i
			var v := (hidden_defaults[k] if k < hidden_defaults.size() else 0.0) + rng.randf_range(-noise, noise)
			if i < INPUTS:
				net.w1[j * INPUTS + i] = v
			else:
				net.b1[j] = v
	net.w2.resize(net.outputs * HIDDEN)
	net.b2.resize(net.outputs)
	for a in net.outputs:
		for j in HIDDEN + 1:
			var k := a * (HIDDEN + 1) + j
			var v := (output_defaults[k] if k < output_defaults.size() else 0.0) + rng.randf_range(-noise, noise)
			v = clampf(v, -MAX_WEIGHT, MAX_WEIGHT)
			if j < HIDDEN:
				net.w2[a * HIDDEN + j] = v
			else:
				net.b2[a] = v
	net.base2 = net.w2 + net.b2
	net._build_hidden_blocks()
	net._build_output_blocks()
	return net


func weight_count() -> int:
	return w1.size() + b1.size() + w2.size() + b2.size()


## One score per action for the senses `x` (INPUTS numbers, 0..1). Keeps the hidden activations for
## last_hidden().
func forward(x: PackedFloat32Array) -> PackedFloat32Array:
	var x0 := Vector4(x[0], x[1], x[2], x[3])
	var x1 := Vector4(x[4], x[5], x[6], x[7])
	var x2 := Vector4(x[8], x[9], x[10], x[11])
	var x3 := Vector4(x[12], x[13], x[14], x[15])
	h0 = (_c1[0] + _p1[0] * x0 + _p1[1] * x1 + _p1[2] * x2 + _p1[3] * x3).max(Vector4.ZERO)
	h1 = (_c1[1] + _p1[4] * x0 + _p1[5] * x1 + _p1[6] * x2 + _p1[7] * x3).max(Vector4.ZERO)
	h2 = (_c1[2] + _p1[8] * x0 + _p1[9] * x1 + _p1[10] * x2 + _p1[11] * x3).max(Vector4.ZERO)
	for r in _c2.size():
		var v: Vector4 = _c2[r] + _p2[r * 3] * h0 + _p2[r * 3 + 1] * h1 + _p2[r * 3 + 2] * h2
		for k in mini(4, outputs - r * 4):
			_scores[r * 4 + k] = v[k]
	return _scores.duplicate()


## The hidden activations of the last forward pass (a mind keeps them to learn from later).
func last_hidden() -> PackedFloat32Array:
	return PackedFloat32Array([h0.x, h0.y, h0.z, h0.w, h1.x, h1.y, h1.z, h1.w, h2.x, h2.y, h2.z, h2.w])


## Learns from how an action went: moves the scores of `action` in the situation whose hidden
## activations were `hidden` up (advantage > 0) or down, by `rate`. Output layer only; every weight
## stays within ±MAX_WEIGHT and within ±MAX_DELTA of its default.
func learn(action: int, advantage: float, rate: float, hidden: PackedFloat32Array) -> void:
	if action < 0 or action >= outputs or hidden.size() != HIDDEN or not is_finite(advantage) or not is_finite(rate):
		return
	var step := clampf(advantage, -1.0, 1.0) * clampf(rate, 0.0, 1.0)
	if step == 0.0:
		return
	for j in HIDDEN:
		var k := action * HIDDEN + j
		w2[k] = _clamped(w2[k] + step * hidden[j], base2[k])
	b2[action] = _clamped(b2[action] + step, base2[w2.size() + action])
	_build_output_blocks()


## True while nothing has been learned yet (nothing to save).
func is_fresh() -> bool:
	return (w2 + b2) == base2


## Owner #41: how much it learned (the drifts of its output layer added up), for MindBook's order of saving.
func learned() -> float:
	var now := w2 + b2
	var sum := 0.0
	for i in now.size():
		sum += absf(now[i] - base2[i])
	return sum


## The same from a saved table (to_save's text), in the same units.
static func learned_in(text: String) -> float:
	if not is_base64(text):
		return 0.0
	var sum := 0.0
	for b: int in Marshalls.base64_to_raw(text):
		sum += absf(float(b - 256 if b > 127 else b)) / 127.0 * MAX_DELTA
	return sum


## The learned drifts of the output layer, one signed byte each (base64): about 140 characters
## for 8 actions.
func to_save() -> String:
	var bytes := PackedByteArray()
	var now := w2 + b2
	bytes.resize(now.size())
	for i in now.size():
		var q := clampi(roundi((now[i] - base2[i]) / MAX_DELTA * 127.0), -127, 127)
		bytes[i] = q & 0xff
	return Marshalls.raw_to_base64(bytes)


## Restores the drifts of a save made by a net of the same shape. False (and nothing changes) for
## anything else.
func load_save(text: String) -> bool:
	if not is_base64(text):
		return false
	var bytes := Marshalls.base64_to_raw(text)
	if bytes.size() != outputs * (HIDDEN + 1):
		return false
	for i in bytes.size():
		var q := int(bytes[i])
		if q > 127:
			q -= 256
		var v := _clamped(base2[i] + float(q) / 127.0 * MAX_DELTA, base2[i])
		if i < w2.size():
			w2[i] = v
		else:
			b2[i - w2.size()] = v
	_build_output_blocks()
	return true


## Plain base64 of at most 2 KB (checked first: decoding anything else logs an engine error).
static func is_base64(text: String) -> bool:
	if text == "" or text.length() > 2048 or text.length() % 4 != 0:
		return false
	var pad := 0
	for i in text.length():
		var c := text.unicode_at(i)
		if c == 61:                                     # '=' only at the end
			pad += 1
		elif pad > 0 or not (c >= 65 and c <= 90 or c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 43 or c == 47):
			return false
	return pad <= 2


func _clamped(v: float, base: float) -> float:
	var d := clampf(max_delta, 0.0, MAX_DELTA)
	return clampf(clampf(v, base - d, base + d), -MAX_WEIGHT, MAX_WEIGHT)


func _build_hidden_blocks() -> void:
	_p1.clear()
	_c1.clear()
	for r in 3:
		_c1.append(Vector4(b1[r * 4], b1[r * 4 + 1], b1[r * 4 + 2], b1[r * 4 + 3]))
		for c in 4:
			_p1.append(_block(w1, INPUTS, r * 4, c * 4, HIDDEN))


func _build_output_blocks() -> void:
	_p2.clear()
	_c2.clear()
	var rows := ceili(outputs / 4.0)
	_scores.resize(outputs)
	for r in rows:
		var c := Vector4()
		for k in 4:
			if r * 4 + k < outputs:
				c[k] = b2[r * 4 + k]
		_c2.append(c)
		for h in 3:
			_p2.append(_block(w2, HIDDEN, r * 4, h * 4, outputs))


## The 4 × 4 block of `w` (rows of `width`) at (row, col), as columns for Projection × Vector4.
static func _block(w: PackedFloat32Array, width: int, row: int, col: int, rows: int) -> Projection:
	var cols: Array[Vector4] = []
	for jj in 4:
		var v := Vector4()
		for ii in 4:
			if row + ii < rows:
				v[ii] = w[(row + ii) * width + col + jj]
		cols.append(v)
	return Projection(cols[0], cols[1], cols[2], cols[3])
