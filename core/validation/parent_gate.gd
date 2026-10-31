class_name ParentGate
extends RefCounted
## The parent gate (spec §5.12, §5.14; M3 Task 17, first used by the Shorts Theater's switch): a
## multiplication a grown-up does at a glance, written in words ("What is twenty-three times
## seven?") so a young child can't copy digits from the screen. It is a speed bump, not a lock: an
## older child who can read and multiply gets through (the M4 parental consent is the real one). Three wrong
## answers in a row rest it for a minute (M4 Task 10 review E, below), so guessing is slow.

const MIN_A := 13
const MAX_A := 29
const MIN_B := 6
const MAX_B := 9

const _ONES: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
	"ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const _TENS: Array[String] = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]


## M4 Task 10 review E: MAX_WRONG wrong answers in a row rest every parent gate (the grown-up pages, online play,
## the Theater) for LOCK_MSEC, so guessing is slow; a right answer starts the count again. One count and one rest for
## the whole app run (like the code field's), so closing a gate and opening it again doesn't reset them. Times are
## milliseconds from a steady clock (Time.get_ticks_msec; the gates take theirs from `msec`).
const MAX_WRONG := 3
const LOCK_MSEC := 60_000

static var _wrong := 0
static var _locked_until := 0


## A new question: {a, b, answer, text}.
static func make(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(MIN_A, MAX_A)
	var b := rng.randi_range(MIN_B, MAX_B)
	return {"a": a, "b": b, "answer": a * b, "text": Lang.t("What is %s times %s?") % [words(a), words(b)]}


## 0..99 in English words.
static func words(n: int) -> String:
	n = clampi(n, 0, 99)
	if n < 20:
		return _ONES[n]
	var tens := _TENS[int(n / 10.0)]
	return tens if n % 10 == 0 else "%s-%s" % [tens, _ONES[n % 10]]


static func check(question: Dictionary, typed: String) -> bool:
	var t := typed.strip_edges()
	if not question.has("answer") or not t.is_valid_int() or t.begins_with("-") or t.begins_with("+"):
		return false
	return t.to_int() == int(question.answer)


static func is_locked(now_msec: int) -> bool:
	return now_msec < _locked_until


## Whole seconds of rest left, rounded up (0 when the gate is open).
static func wait_seconds(now_msec: int) -> int:
	return ceili((_locked_until - now_msec) / 1000.0) if is_locked(now_msec) else 0


## A wrong answer; true when it was the one that started the rest.
static func record_wrong(now_msec: int) -> bool:
	_wrong += 1
	if _wrong < MAX_WRONG:
		return false
	_wrong = 0
	_locked_until = now_msec + LOCK_MSEC
	return true


static func record_right() -> void:
	_wrong = 0


## Tests: a fresh count and no rest.
static func reset_tries() -> void:
	_wrong = 0
	_locked_until = 0


## The kind line the gate shows while it rests, to the grown-up, with when to try again.
static func locked_text(seconds: int) -> String:
	return Lang.t("Let's take a short break. A grown-up can try again in %d second%s.") % [seconds, Lang.plural_s(seconds)]
