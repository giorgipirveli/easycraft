class_name ProgressData
extends RefCounted
## The player's progress (M3 Task 12, spec §5.8): XP, how often each kind of thing was done, the
## adventure board, badges, stickers and the pet's present clock. Kept in the profile (account-wide),
## parsed field by field: a bad field falls back on its own. Nothing here has a date: no clock can make
## anything expire (research R4).

## The XP of the top level (LevelRules.xp_to_reach(MAX_LEVEL)); nobody needs more.
const MAX_XP := 247450
const MAX_COUNT := 1_000_000_000
const MAX_KINDS := 256
const MAX_STICKER := 9999

var xp := 0
## Kind (a family, or "family/detail") -> how many. An event counts its detail and its family.
var counts := {}
## Play style (LevelRules.STYLES) -> the XP earned in it: the titles.
var style_xp := {}
## The title the child chose to show (&"" = the style played most).
var title: StringName = &""
## The adventure board: BoardRules.SLOTS entries {"goal": id, "start": the count when picked, "done"}.
var board: Array = BoardRules.clean_board([])
## The starter goals went up once (BoardRules.ensure_board).
var board_set := false
## Badges unlocked (AchievementRules ids), in the order they came.
var achievements: Array[String] = []
## Sticker id (a board goal's id or a gift's) -> how many.
var stickers := {}
## Active play seconds toward the pet's next present (PresentRules), how many were opened, and whether
## one waits to be opened.
var present_s := 0.0
var presents := 0
var present_waiting := false
## Owner #45a (spec §14.17): the counts per universe ("<u>" -> {kind: n}), next to the account-wide ones,
## for the goals and quest steps of one universe; and the quests (QuestData: the chain followed, waiting
## chains, stories done, places).
var u_counts := {}
var quests := QuestData.new()

## The counts per universe stay small (the server backup takes 60 KB of profile): at most this many
## universes and kinds in each (a child's real play has about 40 kinds in a universe).
const MAX_UNIVERSES := 8
const MAX_U_KINDS := 64


func level() -> int:
	return LevelRules.level_for(xp)


func count(kind: StringName) -> int:
	return int(counts.get(String(kind), 0))


## How many of `kind` happened in universe `universe` (0: anywhere, the account-wide count).
func count_in(kind: StringName, universe: int) -> int:
	if universe <= 0:
		return count(kind)
	var per: Variant = u_counts.get(str(universe))
	return int((per as Dictionary).get(String(kind), 0)) if per is Dictionary else 0


## Counts one event (amount of it) and returns the XP it gave (0 for an unknown kind). `universe` (1…):
## where it happened, also counted per universe (owner #45a); 0 when unknown.
func record(kind: StringName, amount: int = 1, universe: int = 0) -> int:
	if not LevelRules.is_kind(kind) or amount <= 0:
		return 0
	var n := mini(amount, LevelRules.MAX_AMOUNT)
	_add_count(String(kind), n)
	var f := LevelRules.family(kind)
	if f != kind:
		_add_count(String(f), n)
	if universe >= 1 and universe <= MAX_UNIVERSES:
		_add_u_count(universe, String(kind), n)
		if f != kind:
			_add_u_count(universe, String(f), n)
	var gained := LevelRules.xp_for(kind, n)
	xp = mini(xp + gained, MAX_XP)
	var style := LevelRules.style_of(kind)
	if style != &"":
		style_xp[String(style)] = mini(int(style_xp.get(String(style), 0)) + gained, MAX_XP)
	return gained


func _add_count(key: String, n: int) -> void:
	if not counts.has(key) and counts.size() >= MAX_KINDS:
		return
	counts[key] = mini(int(counts.get(key, 0)) + n, MAX_COUNT)


func _add_u_count(universe: int, key: String, n: int) -> void:
	var u := str(universe)
	if not u_counts.has(u):
		u_counts[u] = {}
	var per: Dictionary = u_counts[u]
	if not per.has(key) and per.size() >= MAX_U_KINDS:
		return
	per[key] = mini(int(per.get(key, 0)) + n, MAX_COUNT)


func add_sticker(id: String) -> void:
	if ProgressData.is_sticker(id):
		stickers[id] = mini(int(stickers.get(id, 0)) + 1, MAX_STICKER)


## A board goal's id or a gift's sticker (M3 Task 21b: or a Secret Book page's, BookPages).
static func is_sticker(id: String) -> bool:
	return not BoardRules.goal(StringName(id)).is_empty() or PresentRules.STICKERS.has(StringName(id)) \
		or BookPages.stickers().has(id)


## Nothing done yet (a new profile).
func is_empty() -> bool:
	return xp == 0 and counts.is_empty() and achievements.is_empty() and stickers.is_empty() and presents == 0 \
		and quests.is_empty()


func to_dict() -> Dictionary:
	return {"xp": xp, "counts": counts, "style_xp": style_xp, "title": String(title), "board": board,
		"board_set": board_set, "achievements": achievements, "stickers": stickers, "present_s": present_s,
		"presents": presents, "present_waiting": present_waiting, "u_counts": u_counts, "quests": quests.to_dict()}


static func from_dict(v: Variant) -> ProgressData:
	var d := ProgressData.new()
	if not v is Dictionary:
		return d
	var src: Dictionary = v
	d.xp = clampi(_int(src.get("xp"), 0), 0, MAX_XP)
	var c: Variant = src.get("counts")
	if c is Dictionary:
		for key: Variant in c:
			var n := _int(c[key], 0)
			if key is String and LevelRules.is_kind(StringName(key)) and n > 0 and d.counts.size() < MAX_KINDS:
				d.counts[key] = mini(n, MAX_COUNT)
	var s: Variant = src.get("style_xp")
	if s is Dictionary:
		for key: Variant in s:
			var n := _int(s[key], 0)
			if key is String and LevelRules.STYLES.has(StringName(key)) and n > 0:
				d.style_xp[key] = mini(n, MAX_XP)
	var t: Variant = src.get("title")
	d.title = StringName(t) if t is String and LevelRules.is_title(StringName(t)) else &""
	d.board = BoardRules.clean_board(src.get("board"))
	d.board_set = _bool(src.get("board_set"))
	var a: Variant = src.get("achievements")
	if a is Array:
		for id: Variant in a:
			if id is String and not AchievementRules.badge(StringName(id)).is_empty() and not d.achievements.has(id):
				d.achievements.append(id)
	var st: Variant = src.get("stickers")
	if st is Dictionary:
		for key: Variant in st:
			var n := _int(st[key], 0)
			if key is String and is_sticker(key) and n > 0:
				d.stickers[key] = mini(n, MAX_STICKER)
	var ps: Variant = src.get("present_s")
	if typeof(ps) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(ps)):
		d.present_s = clampf(float(ps), 0.0, PresentRules.LONGEST_S)
	d.presents = maxi(_int(src.get("presents"), 0), 0)
	d.present_waiting = _bool(src.get("present_waiting"))
	var uc: Variant = src.get("u_counts")
	if uc is Dictionary:
		for u: Variant in uc:
			var per: Variant = uc[u]
			if not (u is String and (u as String).is_valid_int() and per is Dictionary):
				continue
			var n_u := (u as String).to_int()
			if n_u < 1 or n_u > MAX_UNIVERSES:
				continue
			for key: Variant in per:
				var n := _int(per[key], 0)
				if key is String and LevelRules.is_kind(StringName(key)) and n > 0:
					d._add_u_count(n_u, key, n)
	d.quests = QuestData.from_dict(src.get("quests"))
	if QuestRules.is_title(d.title) and not QuestRules.titles(d).has(d.title):
		d.title = &""   # a quest title only once its story is done
	return d


## true only for a saved true (a string or a number is not).
static func _bool(v: Variant) -> bool:
	return v is bool and v


## A whole number from JSON (which gives floats), or `default` for anything else.
static func _int(v: Variant, default: int) -> int:
	if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
		return int(clampf(float(v), -MAX_COUNT, MAX_COUNT))
	return default


## Keeps the best of both copies (the server backup's merge, ProfileBackup): each count, each style's
## XP, every badge and sticker. The XP is at least both styles' best plus the goals'; the board, the
## title and the present clock stay this copy's.
func merge_from(other: ProgressData) -> void:
	for key: String in other.counts:
		counts[key] = maxi(int(counts.get(key, 0)), int(other.counts[key]))
	for key: String in other.style_xp:
		style_xp[key] = maxi(int(style_xp.get(key, 0)), int(other.style_xp[key]))
	for id in other.achievements:
		if not achievements.has(id):
			achievements.append(id)
	for key: String in other.stickers:
		stickers[key] = maxi(int(stickers.get(key, 0)), int(other.stickers[key]))
	var from_styles := count(LevelRules.GOAL) * int(LevelRules.XP[LevelRules.GOAL])
	for key: String in style_xp:
		from_styles += int(style_xp[key])
	xp = mini(maxi(maxi(xp, other.xp), from_styles), MAX_XP)
	presents = maxi(presents, other.presents)
	for u: String in other.u_counts:
		var per: Dictionary = other.u_counts[u]
		for key: String in per:
			var have := count_in(StringName(key), u.to_int())
			if int(per[key]) > have:
				_add_u_count(u.to_int(), key, int(per[key]) - have)
	quests.merge_from(other.quests)
