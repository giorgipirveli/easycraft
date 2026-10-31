class_name QrCode
extends RefCounted
## Owner #79 (spec §25.2): the invite link as a QR code the game draws itself (no plugin, no network), so a grown-up
## can point another phone's camera at it. ISO/IEC 18004 in byte mode, error correction level M (about 15% of the
## code may be hidden or smudged), versions 1-10 (up to 213 bytes: every invite link fits in version 4 or 5), the
## mask with the lowest penalty. The layout follows Project Nayuki's reference encoder (MIT); tests compare whole
## matrices with segno's and a decoder read the pictures (docs/devlog/parts/earn-invite.md).
##
## encode(text) -> {"size": n, "version": v, "mask": m, "dark": PackedByteArray (n * n, row by row, 1 = dark)},
## or {} when the text is empty or too long.

const MAX_VERSION := 10
## Level M per version (index = version): error-correction codewords per block and the number of blocks.
const ECC_PER_BLOCK: Array[int] = [0, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26]
const BLOCKS: Array[int] = [0, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5]
const FORMAT_M := 0   # level M's two format bits

var size := 0
var version := 0
var mask := 0
var _dark := PackedByteArray()
var _function := PackedByteArray()


static func encode(text: String, force_mask: int = -1) -> Dictionary:
	var data := text.to_utf8_buffer()
	if data.is_empty():
		return {}
	var v := 1
	while v <= MAX_VERSION and data.size() + (3 if v >= 10 else 2) > data_codewords(v):
		v += 1
	if v > MAX_VERSION:
		return {}
	var q := QrCode.new()
	q._build(data, v, force_mask)
	return {"size": q.size, "version": q.version, "mask": q.mask, "dark": q._dark}


## The data codewords a version holds at level M.
static func data_codewords(v: int) -> int:
	return raw_modules(v) / 8 - ECC_PER_BLOCK[v] * BLOCKS[v]


## Modules left for data and error correction after the function patterns.
static func raw_modules(v: int) -> int:
	var n := (16 * v + 128) * v + 64
	if v >= 2:
		var align := v / 7 + 2
		n -= (25 * align - 10) * align - 55
		if v >= 7:
			n -= 36
	return n


func _build(data: PackedByteArray, v: int, force_mask: int) -> void:
	version = v
	size = v * 4 + 17
	_dark.resize(size * size)
	_dark.fill(0)
	_function.resize(size * size)
	_function.fill(0)
	_draw_function_patterns()
	_draw_codewords(_add_ecc_and_interleave(_data_codewords(data)))
	if force_mask >= 0:
		mask = force_mask
	else:
		var best := -1
		for m in 8:
			_apply_mask(m)
			_draw_format_bits(m)
			var p := _penalty()
			if best < 0 or p < best:
				best = p
				mask = m
			_apply_mask(m)   # a mask applied twice is undone
	_apply_mask(mask)
	_draw_format_bits(mask)


func is_dark(x: int, y: int) -> bool:
	return _dark[y * size + x] == 1


func _put(x: int, y: int, dark: bool) -> void:
	_dark[y * size + x] = 1 if dark else 0
	_function[y * size + x] = 1


# --- The function patterns ------------------------------------------------------------------------------------------

func _draw_function_patterns() -> void:
	for i in size:
		_put(6, i, i % 2 == 0)
		_put(i, 6, i % 2 == 0)
	_draw_finder(3, 3)
	_draw_finder(size - 4, 3)
	_draw_finder(3, size - 4)
	var at := _alignment_positions()
	var n := at.size()
	for i in n:
		for j in n:
			if not ((i == 0 and j == 0) or (i == 0 and j == n - 1) or (i == n - 1 and j == 0)):
				_draw_alignment(at[i], at[j])
	_draw_format_bits(0)   # reserved now, written for real after the mask
	_draw_version()


func _draw_finder(cx: int, cy: int) -> void:
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var d := maxi(absi(dx), absi(dy))
			var x := cx + dx
			var y := cy + dy
			if x >= 0 and x < size and y >= 0 and y < size:
				_put(x, y, d != 2 and d != 4)


func _draw_alignment(cx: int, cy: int) -> void:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			_put(cx + dx, cy + dy, maxi(absi(dx), absi(dy)) != 1)


func _alignment_positions() -> Array[int]:
	var out: Array[int] = []
	if version == 1:
		return out
	var n := version / 7 + 2
	var step := (version * 8 + n * 3 + 5) / (n * 4 - 4) * 2
	for i in n - 1:
		out.push_front(size - 7 - i * step)
	out.push_front(6)
	return out


func _draw_format_bits(m: int) -> void:
	var data := FORMAT_M << 3 | m
	var rem := data
	for i in 10:
		rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	var bits := (data << 10 | rem) ^ 0x5412
	for i in 6:
		_put(8, i, _bit(bits, i))
	_put(8, 7, _bit(bits, 6))
	_put(8, 8, _bit(bits, 7))
	_put(7, 8, _bit(bits, 8))
	for i in range(9, 15):
		_put(14 - i, 8, _bit(bits, i))
	for i in 8:
		_put(size - 1 - i, 8, _bit(bits, i))
	for i in range(8, 15):
		_put(8, size - 15 + i, _bit(bits, i))
	_put(8, size - 8, true)   # the dark module


func _draw_version() -> void:
	if version < 7:
		return
	var rem := version
	for i in 12:
		rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
	var bits := version << 12 | rem
	for i in 18:
		var bit := _bit(bits, i)
		var a := size - 11 + i % 3
		var b := i / 3
		_put(a, b, bit)
		_put(b, a, bit)


static func _bit(x: int, i: int) -> bool:
	return (x >> i) & 1 != 0


# --- Data and error correction --------------------------------------------------------------------------------------

func _data_codewords(data: PackedByteArray) -> PackedByteArray:
	var bits: Array[int] = []
	_append_bits(bits, 0b0100, 4)                       # byte mode
	_append_bits(bits, data.size(), 16 if version >= 10 else 8)
	for b in data:
		_append_bits(bits, b, 8)
	var capacity := data_codewords(version) * 8
	_append_bits(bits, 0, mini(4, capacity - bits.size()))   # the terminator
	_append_bits(bits, 0, (8 - bits.size() % 8) % 8)
	var out := PackedByteArray()
	for i in range(0, bits.size(), 8):
		var byte := 0
		for j in 8:
			byte = byte << 1 | bits[i + j]
		out.append(byte)
	var pad := 0xEC
	while out.size() < data_codewords(version):
		out.append(pad)
		pad = 0x11 if pad == 0xEC else 0xEC
	return out


static func _append_bits(bits: Array[int], value: int, count: int) -> void:
	for i in range(count - 1, -1, -1):
		bits.append((value >> i) & 1)


func _add_ecc_and_interleave(data: PackedByteArray) -> PackedByteArray:
	var blocks_n := BLOCKS[version]
	var ecc_len := ECC_PER_BLOCK[version]
	var raw := raw_modules(version) / 8
	var short_n := blocks_n - raw % blocks_n
	var short_len := raw / blocks_n
	var divisor := _rs_divisor(ecc_len)
	var blocks: Array[PackedByteArray] = []
	var k := 0
	for i in blocks_n:
		var n := short_len - ecc_len + (0 if i < short_n else 1)
		var dat := data.slice(k, k + n)
		k += n
		var ecc := _rs_remainder(dat, divisor)
		if i < short_n:
			dat.append(0)
		dat.append_array(ecc)
		blocks.append(dat)
	var out := PackedByteArray()
	for i in blocks[0].size():
		for j in blocks.size():
			if i != short_len - ecc_len or j >= short_n:
				out.append(blocks[j][i])
	return out


static func _rs_multiply(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z


static func _rs_divisor(degree: int) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(degree)
	result.fill(0)
	result[degree - 1] = 1
	var root := 1
	for i in degree:
		for j in degree:
			result[j] = _rs_multiply(result[j], root)
			if j + 1 < degree:
				result[j] ^= result[j + 1]
		root = _rs_multiply(root, 0x02)
	return result


static func _rs_remainder(data: PackedByteArray, divisor: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(divisor.size())
	result.fill(0)
	for b in data:
		var factor := b ^ result[0]
		result.remove_at(0)
		result.append(0)
		for i in result.size():
			result[i] ^= _rs_multiply(divisor[i], factor)
	return result


func _draw_codewords(data: PackedByteArray) -> void:
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var upward := (right + 1) & 2 == 0
				var y := size - 1 - vert if upward else vert
				if _function[y * size + x] == 0 and i < data.size() * 8:
					_dark[y * size + x] = (data[i >> 3] >> (7 - (i & 7))) & 1
					i += 1
		right -= 2


# --- Masks and their penalty ----------------------------------------------------------------------------------------

func _apply_mask(m: int) -> void:
	for y in size:
		for x in size:
			var invert := false
			match m:
				0: invert = (x + y) % 2 == 0
				1: invert = y % 2 == 0
				2: invert = x % 3 == 0
				3: invert = (x + y) % 3 == 0
				4: invert = (x / 3 + y / 2) % 2 == 0
				5: invert = x * y % 2 + x * y % 3 == 0
				6: invert = (x * y % 2 + x * y % 3) % 2 == 0
				7: invert = ((x + y) % 2 + x * y % 3) % 2 == 0
			if invert and _function[y * size + x] == 0:
				_dark[y * size + x] ^= 1


const N1 := 3
const N2 := 3
const N3 := 40
const N4 := 10


func _penalty() -> int:
	var result := 0
	for pass_ in 2:   # rows, then columns
		for a in size:
			var run_dark := false
			var run := 0
			var history: Array[int] = [0, 0, 0, 0, 0, 0, 0]
			for b in size:
				var dark := is_dark(b, a) if pass_ == 0 else is_dark(a, b)
				if dark == run_dark:
					run += 1
					if run == 5:
						result += N1
					elif run > 5:
						result += 1
				else:
					_add_history(run, history)
					if not run_dark:
						result += _count_finder_like(history) * N3
					run_dark = dark
					run = 1
			result += _terminate_and_count(run_dark, run, history) * N3
	for y in size - 1:
		for x in size - 1:
			var c := is_dark(x, y)
			if c == is_dark(x + 1, y) and c == is_dark(x, y + 1) and c == is_dark(x + 1, y + 1):
				result += N2
	var dark_n := 0
	for d in _dark:
		dark_n += d
	var total := size * size
	var k := ceili(absi(dark_n * 20 - total * 10) / float(total)) - 1
	result += k * N4
	return result


func _add_history(run: int, history: Array[int]) -> void:
	if history[0] == 0:
		run += size   # the light border before the first run
	history.pop_back()
	history.push_front(run)


func _count_finder_like(h: Array[int]) -> int:
	var n := h[1]
	var core := n > 0 and h[2] == n and h[3] == n * 3 and h[4] == n and h[5] == n
	return (1 if core and h[0] >= n * 4 and h[6] >= n else 0) + (1 if core and h[6] >= n * 4 and h[0] >= n else 0)


func _terminate_and_count(run_dark: bool, run: int, history: Array[int]) -> int:
	if run_dark:
		_add_history(run, history)
		run = 0
	run += size   # the light border after the last run
	_add_history(run, history)
	return _count_finder_like(history)
