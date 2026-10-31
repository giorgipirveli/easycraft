extends RefCounted
## Grade 7 computing's text code (the School's own words for the kind of text language schools teach first; spec §22,
## research §6.7 "From blocks to text"): a small interpreter the tests run every program with, so what a lesson or an
## exercise says a program prints, leaves in a variable or stops on is worked out again, never copied. It is the tests'
## own (the game never runs code). Lines are indented 4 spaces a step. It knows:
## - statements: name = expr, name += expr, name -= expr, name[expr] = expr, print(expr, …) (the values joined by a
##   space), name.append(expr), name.remove(expr), if / elif / else, for name in expr (a range, a list or text),
##   while expr, def name(params) with return expr, and # comments;
## - expressions: whole numbers, decimals, "text" or 'text', True, False, [lists], names, a[i] (a[-1] the last), calls
##   of len, range, str, int, max, min, abs, sum and the program's own functions, + - * / // %, == != < > <= >=, in,
##   not in, and, or, not, and brackets, with the usual order;
## - errors: "syntax" (a missing colon, bracket or quote, a wrong step in, = where == is meant), "name" (a name that was
##   never set: a misspelt command), "index" (an item past the end), "zero" (dividing by 0), "type" (text + a number).
## run(lines) -> {out: [text], vars: {name: value}, error: "" or the kind, line: the line (from 1) it stopped on}.
## show(value) writes a value as the programs print it (3.5, 3.0, True, [1, 2], ['a', 'b']).

const MAX_STEPS := 20000
const KEYWORDS: Array[String] = ["if", "elif", "else", "for", "while", "def", "return", "in", "not", "and", "or",
	"True", "False", "None", "print"]
const BUILTINS: Array[String] = ["len", "range", "str", "int", "max", "min", "abs", "sum"]


class Stop:
	var kind := ""
	var line := 0
	var value: Variant = null


static func run(lines: Array) -> Dictionary:
	var st := {"out": [], "vars": {}, "funcs": {}, "steps": 0, "error": "", "line": 0}
	var src: Array[Dictionary] = []   # {depth, text, line}
	for i in lines.size():
		var raw := str(lines[i])
		var text := _strip_comment(raw)
		if text.strip_edges() == "":
			continue
		var lead := text.length() - text.lstrip(" ").length()
		if lead % 4 != 0:
			return _fail(st, "syntax", i + 1)
		src.append({"depth": lead / 4, "text": text.strip_edges(), "line": i + 1})
	var why := _check_syntax(src)
	if why.x > 0:
		return _fail(st, "syntax", why.x)
	st["_src"] = src
	var body: Array[int] = []
	for k in src.size():
		if int(src[k].depth) == 0:
			body.append(k)
	var stop := _block(src, body, st, st.vars)
	if stop != null and stop.kind != "return":
		st.error = stop.kind
		st.line = stop.line
	return _fail(st, st.error, st.line)


static func _fail(st: Dictionary, kind: String, line: int) -> Dictionary:
	st.error = kind
	st.line = line
	for k: String in ["funcs", "steps", "_src"]:
		st.erase(k)
	return st


## A line without its # comment (a # inside quotes stays).
static func _strip_comment(s: String) -> String:
	var quote := ""
	for i in s.length():
		var ch := s[i]
		if quote != "":
			if ch == quote:
				quote = ""
		elif ch == "\"" or ch == "'":
			quote = ch
		elif ch == "#":
			return s.substr(0, i).rstrip(" ")
	return s


## Vector2i(line, 0) of the first syntax mistake, or (0, 0): a block's first line ends with ":" and the next line steps
## in once; no other line ends with ":" or steps in; brackets and quotes close; an if, elif or while tests with ==, not =.
static func _check_syntax(src: Array[Dictionary]) -> Vector2i:
	for k in src.size():
		var t := str(src[k].text)
		var head := _head_word(t)
		var opens := head in ["if", "elif", "else", "for", "while", "def"]
		var next_depth := int(src[k + 1].depth) if k + 1 < src.size() else 0
		if opens != t.ends_with(":"):
			return Vector2i(int(src[k].line), 0)
		if opens and next_depth != int(src[k].depth) + 1:   # the line that should step in (as the error message says)
			return Vector2i(int(src[k + 1].line) if k + 1 < src.size() else int(src[k].line), 0)
		if not opens and next_depth > int(src[k].depth):
			return Vector2i(int(src[k + 1].line), 0)
		if head in ["elif", "else"] and not _follows_if(src, k):
			return Vector2i(int(src[k].line), 0)
		var toks := _tokens(t.trim_suffix(":") if opens else t)
		if toks.is_empty() or str(toks[-1]) == "<bad>":
			return Vector2i(int(src[k].line), 0)
		var depth := 0
		for tok: String in toks:
			if tok in ["(", "["]:
				depth += 1
			elif tok in [")", "]"]:
				depth -= 1
				if depth < 0:
					return Vector2i(int(src[k].line), 0)
		if depth != 0:
			return Vector2i(int(src[k].line), 0)
		if head in ["if", "elif", "while"] and toks.has("="):
			return Vector2i(int(src[k].line), 0)
		if head == "for" and (toks.size() < 4 or not toks.has("in")):
			return Vector2i(int(src[k].line), 0)
	return Vector2i.ZERO


static func _follows_if(src: Array[Dictionary], k: int) -> bool:
	var d := int(src[k].depth)
	for j in range(k - 1, -1, -1):
		if int(src[j].depth) < d:
			return false
		if int(src[j].depth) == d:
			return _head_word(str(src[j].text)) in ["if", "elif"]
	return false


static func _head_word(t: String) -> String:
	var w := ""
	for ch in t:
		if ch == " " or ch == "(" or ch == ":":
			break
		w += ch
	return w


# --- tokens ------------------------------------------------------------------------------------------------------------

## The line's tokens: numbers, "text" (kept with its quotes), names, and operators; a last "<bad>" when a quote does not
## close or a letter is not part of the language.
static func _tokens(s: String) -> Array:
	var out: Array = []
	var i := 0
	while i < s.length():
		var ch := s[i]
		if ch == " ":
			i += 1
		elif ch == "\"" or ch == "'":
			var j := s.find(ch, i + 1)
			if j < 0:
				out.append("<bad>")
				return out
			out.append("\"" + s.substr(i + 1, j - i - 1) + "\"")
			i = j + 1
		elif ch.is_valid_int():
			var j := i
			while j < s.length() and (s[j].is_valid_int() or (s[j] == "." and j + 1 < s.length() and s[j + 1].is_valid_int())):
				j += 1
			out.append(s.substr(i, j - i))
			i = j
		elif ch == "_" or ch.to_lower() != ch.to_upper():
			var j := i
			while j < s.length() and (s[j] == "_" or s[j].is_valid_int() or s[j].to_lower() != s[j].to_upper()):
				j += 1
			out.append(s.substr(i, j - i))
			i = j
		else:
			var two := s.substr(i, 2)
			if two in ["==", "!=", "<=", ">=", "//", "+=", "-="]:
				out.append(two)
				i += 2
			elif ch in ["+", "-", "*", "/", "%", "<", ">", "=", "(", ")", "[", "]", ",", ".", ":"]:
				out.append(ch)
				i += 1
			else:
				out.append("<bad>")
				return out
	return out


# --- statements --------------------------------------------------------------------------------------------------------

static func _inner(src: Array[Dictionary], at: int) -> Array[int]:
	var out: Array[int] = []
	var d := int(src[at].depth)
	for j in range(at + 1, src.size()):
		if int(src[j].depth) <= d:
			break
		if int(src[j].depth) == d + 1:
			out.append(j)
	return out


## Runs the lines `which` of `src` with the variables `vars`; a Stop when it returns or stops on an error.
static func _block(src: Array[Dictionary], which: Array[int], st: Dictionary, vars: Dictionary) -> Stop:
	var k := 0
	while k < which.size():
		st.steps = int(st.steps) + 1
		if int(st.steps) > MAX_STEPS:
			return _stop("loop", int(src[which[k]].line))
		var at := which[k]
		var t := str(src[at].text)
		var line := int(src[at].line)
		var head := _head_word(t)
		var stop: Stop = null
		match head:
			"def":
				var toks := _tokens(t.trim_suffix(":"))
				var params: Array = []
				for tok: String in toks.slice(3, toks.size() - 1):
					if tok != ",":
						params.append(tok)
				st.funcs[str(toks[1])] = {"params": params, "at": at}
			"if":
				var chain: Array[int] = [at]
				while k + 1 < which.size() and _head_word(str(src[which[k + 1]].text)) in ["elif", "else"]:
					k += 1
					chain.append(which[k])
				for c: int in chain:
					var ct := str(src[c].text)
					var ok := true
					if _head_word(ct) != "else":
						var cond: Variant = _eval_text(ct.substr(ct.find(" ") + 1).trim_suffix(":"), st, vars, int(src[c].line))
						if cond is Stop:
							return cond
						ok = _truthy(cond)
					if ok:
						stop = _block(src, _inner(src, c), st, vars)
						break
			"for":
				var toks := _tokens(t.trim_suffix(":"))
				var name := str(toks[1])
				var seq: Variant = _eval_text(t.substr(t.find(" in ") + 4).trim_suffix(":"), st, vars, line)
				if seq is Stop:
					return seq
				var items: Array = []
				if seq is Array:
					items = (seq as Array).duplicate()
				elif seq is String:
					for ch in str(seq):
						items.append(ch)
				else:
					return _stop("type", line)
				for v: Variant in items:
					vars[name] = v
					stop = _block(src, _inner(src, at), st, vars)
					if stop != null:
						break
			"while":
				while stop == null:
					var cond: Variant = _eval_text(t.substr(6).trim_suffix(":"), st, vars, line)
					if cond is Stop:
						return cond
					if not _truthy(cond):
						break
					stop = _block(src, _inner(src, at), st, vars)
					st.steps = int(st.steps) + 1
					if int(st.steps) > MAX_STEPS:
						return _stop("loop", line)
			"return":
				var v: Variant = null if t == "return" else _eval_text(t.substr(7), st, vars, line)
				if v is Stop:
					return v
				stop = _stop("return", line)
				stop.value = v
			"print":
				var toks := _tokens(t)
				if toks.size() < 3 or str(toks[1]) != "(":
					return _stop("syntax", line)
				var p := {"toks": toks, "i": 2, "st": st, "vars": vars, "line": line}
				var v: Variant = _args(p)
				if v is Stop:
					return v
				if int(p.i) != toks.size():
					return _stop("syntax", line)
				var parts: Array[String] = []
				for x: Variant in v:
					parts.append(show(x, false))
				(st.out as Array).append(" ".join(parts))
			_:
				stop = _simple(t, st, vars, line)
		if stop != null:
			return stop
		k += 1
	return null


## An assignment (=, +=, -=, to a name or an item) or a call on its own line (x.append(v), x.remove(v), f(…)).
static func _simple(t: String, st: Dictionary, vars: Dictionary, line: int) -> Stop:
	var toks := _tokens(t)
	var at := -1
	var depth := 0
	for i in toks.size():
		var tok := str(toks[i])
		if tok in ["(", "["]:
			depth += 1
		elif tok in [")", "]"]:
			depth -= 1
		elif depth == 0 and tok in ["=", "+=", "-="]:
			at = i
			break
	if at < 0:
		var v: Variant = _eval_tokens(toks, st, vars, line)
		return v if v is Stop else null
	var value: Variant = _eval_tokens(toks.slice(at + 1), st, vars, line)
	if value is Stop:
		return value
	var target := toks.slice(0, at)
	var op := str(toks[at])
	if target.size() == 1:
		var name := str(target[0])
		if op != "=":
			if not vars.has(name):
				return _stop("name", line)
			value = _arith("+" if op == "+=" else "-", vars[name], value)
			if value is Stop:
				(value as Stop).line = line
				return value
		vars[name] = value
		return null
	if target.size() >= 4 and str(target[1]) == "[" and str(target[-1]) == "]":
		var list: Variant = vars.get(str(target[0]))
		var idx: Variant = _eval_tokens(target.slice(2, target.size() - 1), st, vars, line)
		if idx is Stop:
			return idx
		if not list is Array:
			return _stop("name" if list == null else "type", line)
		var n := (list as Array).size()
		var i := int(idx) + (n if int(idx) < 0 else 0)
		if i < 0 or i >= n:
			return _stop("index", line)
		if op != "=":
			value = _arith("+" if op == "+=" else "-", list[i], value)
			if value is Stop:
				(value as Stop).line = line
				return value
		list[i] = value
		return null
	return _stop("syntax", line)


static func _stop(kind: String, line: int) -> Stop:
	var s := Stop.new()
	s.kind = kind
	s.line = line
	return s


# --- expressions -------------------------------------------------------------------------------------------------------

static func _eval_text(s: String, st: Dictionary, vars: Dictionary, line: int) -> Variant:
	return _eval_tokens(_tokens(s), st, vars, line)


static func _eval_tokens(toks: Array, st: Dictionary, vars: Dictionary, line: int) -> Variant:
	var p := {"toks": toks, "i": 0, "st": st, "vars": vars, "line": line}
	var v: Variant = _or(p)
	if v is Stop:
		return v
	if int(p.i) != toks.size():
		return _stop("syntax", line)
	return v


static func _peek(p: Dictionary) -> String:
	return str(p.toks[p.i]) if int(p.i) < (p.toks as Array).size() else ""


static func _take(p: Dictionary) -> String:
	var t := _peek(p)
	p.i = int(p.i) + 1
	return t


static func _or(p: Dictionary) -> Variant:
	var a: Variant = _and(p)
	while not a is Stop and _peek(p) == "or":
		_take(p)
		var b: Variant = _and(p)
		if b is Stop:
			return b
		a = a if _truthy(a) else b
	return a


static func _and(p: Dictionary) -> Variant:
	var a: Variant = _not(p)
	while not a is Stop and _peek(p) == "and":
		_take(p)
		var b: Variant = _not(p)
		if b is Stop:
			return b
		a = b if _truthy(a) else a
	return a


static func _not(p: Dictionary) -> Variant:
	if _peek(p) == "not":
		_take(p)
		var a: Variant = _not(p)
		return a if a is Stop else not _truthy(a)
	return _compare(p)


static func _compare(p: Dictionary) -> Variant:
	var a: Variant = _sum(p)
	if a is Stop:
		return a
	var op := _peek(p)
	if op == "not" and int(p.i) + 1 < (p.toks as Array).size() and str(p.toks[int(p.i) + 1]) == "in":
		_take(p)
		op = "not in"
	if not op in ["==", "!=", "<", ">", "<=", ">=", "in", "not in"]:
		return a
	_take(p)
	var b: Variant = _sum(p)
	if b is Stop:
		return b
	match op:
		"==":
			return _same(a, b)
		"!=":
			return not _same(a, b)
		"in", "not in":
			var found := false
			if b is Array:
				for x: Variant in b:
					found = found or _same(x, a)
			elif b is String and a is String:
				found = str(b).contains(str(a))
			else:
				return _stop("type", int(p.line))
			return found if op == "in" else not found
	if (a is String) != (b is String) or a is Array or b is Array:
		return _stop("type", int(p.line))
	match op:
		"<":
			return a < b
		">":
			return a > b
		"<=":
			return a <= b
	return a >= b


static func _same(a: Variant, b: Variant) -> bool:
	if _is_num(a) and _is_num(b):
		return float(a) == float(b)
	if typeof(a) != typeof(b):
		return false
	return a == b


static func _is_num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] or v is bool


static func _sum(p: Dictionary) -> Variant:
	var a: Variant = _product(p)
	while not a is Stop and _peek(p) in ["+", "-"]:
		var op := _take(p)
		var b: Variant = _product(p)
		if b is Stop:
			return b
		a = _arith(op, a, b)
		if a is Stop:
			(a as Stop).line = int(p.line)
	return a


static func _product(p: Dictionary) -> Variant:
	var a: Variant = _unary(p)
	while not a is Stop and _peek(p) in ["*", "/", "//", "%"]:
		var op := _take(p)
		var b: Variant = _unary(p)
		if b is Stop:
			return b
		a = _arith(op, a, b)
		if a is Stop:
			(a as Stop).line = int(p.line)
	return a


static func _unary(p: Dictionary) -> Variant:
	if _peek(p) == "-":
		_take(p)
		var a: Variant = _unary(p)
		if a is Stop:
			return a
		return _arith("-", 0, a)
	return _postfix(p)


static func _arith(op: String, a: Variant, b: Variant) -> Variant:
	if op == "+" and a is String and b is String:
		return str(a) + str(b)
	if op == "+" and a is Array and b is Array:
		return (a as Array) + (b as Array)
	if not _is_num(a) or not _is_num(b):
		return _stop("type", 0)
	var both_int := typeof(a) != TYPE_FLOAT and typeof(b) != TYPE_FLOAT
	match op:
		"+":
			return int(a) + int(b) if both_int else float(a) + float(b)
		"-":
			return int(a) - int(b) if both_int else float(a) - float(b)
		"*":
			return int(a) * int(b) if both_int else float(a) * float(b)
		"/":
			if float(b) == 0.0:
				return _stop("zero", 0)
			return float(a) / float(b)
		"//":
			if float(b) == 0.0:
				return _stop("zero", 0)
			var q := floorf(float(a) / float(b))
			return int(q) if both_int else q
	if float(b) == 0.0:
		return _stop("zero", 0)
	var r := float(a) - float(b) * floorf(float(a) / float(b))
	return int(r) if both_int else r


static func _postfix(p: Dictionary) -> Variant:
	var a: Variant = _atom(p)
	while not a is Stop and _peek(p) in ["[", "."]:
		if _take(p) == "[":
			var idx: Variant = _or(p)
			if idx is Stop:
				return idx
			if _take(p) != "]":
				return _stop("syntax", int(p.line))
			if not (a is Array or a is String) or typeof(idx) != TYPE_INT:
				return _stop("type", int(p.line))
			var n: int = (a as Array).size() if a is Array else str(a).length()
			var i := int(idx) + (n if int(idx) < 0 else 0)
			if i < 0 or i >= n:
				return _stop("index", int(p.line))
			a = a[i] if a is Array else str(a)[i]
		else:
			var method := _take(p)
			if _take(p) != "(":
				return _stop("syntax", int(p.line))
			var args: Variant = _args(p)
			if args is Stop:
				return args
			if not a is Array or (args as Array).size() != 1:
				return _stop("type", int(p.line))
			match method:
				"append":
					(a as Array).append(args[0])
				"remove":
					var at := -1
					for j in (a as Array).size():
						if _same(a[j], args[0]):
							at = j
							break
					if at < 0:
						return _stop("index", int(p.line))
					(a as Array).remove_at(at)
				_:
					return _stop("name", int(p.line))
			a = null
	return a


## The arguments after "(" up to ")" (taken).
static func _args(p: Dictionary) -> Variant:
	var out: Array = []
	if _peek(p) == ")":
		_take(p)
		return out
	while true:
		var v: Variant = _or(p)
		if v is Stop:
			return v
		out.append(v)
		var t := _take(p)
		if t == ")":
			return out
		if t != ",":
			return _stop("syntax", int(p.line))
	return out


static func _atom(p: Dictionary) -> Variant:
	var t := _take(p)
	var line := int(p.line)
	if t == "":
		return _stop("syntax", line)
	if t.begins_with("\""):
		return t.substr(1, t.length() - 2)
	if t.is_valid_int():
		return int(t)
	if t.is_valid_float():
		return float(t)
	match t:
		"True":
			return true
		"False":
			return false
		"None":
			return null
		"(":
			var v: Variant = _or(p)
			if v is Stop:
				return v
			return v if _take(p) == ")" else _stop("syntax", line)
		"[":
			var items: Array = []
			if _peek(p) == "]":
				_take(p)
				return items
			while true:
				var v: Variant = _or(p)
				if v is Stop:
					return v
				items.append(v)
				var sep := _take(p)
				if sep == "]":
					return items
				if sep != ",":
					return _stop("syntax", line)
	if t in KEYWORDS or not (t[0] == "_" or t[0].to_lower() != t[0].to_upper()):
		return _stop("syntax", line)
	if _peek(p) == "(":
		_take(p)
		var args: Variant = _args(p)
		if args is Stop:
			return args
		return _call(t, args, p)
	if (p.vars as Dictionary).has(t):
		return p.vars[t]
	if (p.st.vars as Dictionary).has(t):   # a function reads the program's variables too
		return p.st.vars[t]
	return _stop("name", line)


static func _call(name: String, args: Array, p: Dictionary) -> Variant:
	var line := int(p.line)
	var st: Dictionary = p.st
	if (st.funcs as Dictionary).has(name):
		var f: Dictionary = st.funcs[name]
		if (f.params as Array).size() != args.size():
			return _stop("type", line)
		var local := {}
		for i in args.size():
			local[f.params[i]] = args[i]
		return _run_function(f, local, st)
	match name:
		"len":
			if args.size() == 1 and (args[0] is Array or args[0] is String):
				return (args[0] as Array).size() if args[0] is Array else str(args[0]).length()
		"range":
			if args.size() in [1, 2, 3]:
				for a: Variant in args:
					if typeof(a) != TYPE_INT:
						return _stop("type", line)
				var lo: int = 0 if args.size() == 1 else int(args[0])
				var hi: int = int(args[0]) if args.size() == 1 else int(args[1])
				var step: int = int(args[2]) if args.size() == 3 else 1
				if step == 0:
					return _stop("type", line)
				var out: Array = []
				var v := lo
				while (step > 0 and v < hi) or (step < 0 and v > hi):
					out.append(v)
					v += step
				return out
		"str":
			if args.size() == 1:
				return show(args[0], false)
		"int":
			if args.size() == 1 and args[0] is String and str(args[0]).strip_edges().is_valid_int():
				return int(str(args[0]).strip_edges())
			if args.size() == 1 and _is_num(args[0]):
				return int(args[0])
		"abs":
			if args.size() == 1 and _is_num(args[0]):
				return absi(args[0]) if typeof(args[0]) == TYPE_INT else absf(args[0])
		"max", "min", "sum":
			var items: Array = args[0] if args.size() == 1 and args[0] is Array else args
			if items.is_empty() and name != "sum":
				return _stop("type", line)
			var best: Variant = 0 if name == "sum" else items[0]
			for i in range(0 if name == "sum" else 1, items.size()):
				var x: Variant = items[i]
				if name == "sum":
					best = _arith("+", best, x)
					if best is Stop:
						(best as Stop).line = line
						return best
				elif _is_num(x) != _is_num(best):
					return _stop("type", line)
				elif (name == "max" and x > best) or (name == "min" and x < best):
					best = x
			return best
		_:
			return _stop("name", line)
	return _stop("type", line)


static func _run_function(f: Dictionary, local: Dictionary, st: Dictionary) -> Variant:
	var src: Array[Dictionary] = st._src
	var stop := _block(src, _inner(src, int(f.at)), st, local)
	if stop == null:
		return null
	if stop.kind == "return":
		return stop.value
	return stop


static func _truthy(v: Variant) -> bool:
	if v is bool:
		return v
	if v == null:
		return false
	if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
		return float(v) != 0.0
	if v is String:
		return str(v) != ""
	if v is Array:
		return not (v as Array).is_empty()
	return true


## A value as a program prints it: 7, 3.5, 3.0, True, text as it is (inside a list, 'text' in quotes), [1, 2].
static func show(v: Variant, quoted := false) -> String:
	if v == null:
		return "None"
	if v is bool:
		return "True" if v else "False"
	if typeof(v) == TYPE_INT:
		return str(v)
	if typeof(v) == TYPE_FLOAT:
		var f := float(v)
		if f == floorf(f) and absf(f) < 1e15:
			return "%d.0" % int(f)
		var s := str(f)
		return s
	if v is String:
		return "'%s'" % v if quoted else str(v)
	if v is Array:
		var parts: Array[String] = []
		for x: Variant in v:
			parts.append(show(x, true))
		return "[" + ", ".join(parts) + "]"
	return str(v)
