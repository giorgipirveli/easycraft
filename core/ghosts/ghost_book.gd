class_name GhostBook
extends RefCounted
## Friends' ghosts on this device (M4 ghost races; spec §17.5): they race offline once downloaded. A friend's
## showcase ghosts are kept with that showcase's build, so the visit (and its races) works without the server;
## a gift's ghost belongs to its stamp's slot (GiftStampBook) and to the places it was stamped in this player's
## own worlds; the child's best against each ghost. Also this player's own showcase: which world, where, and
## the ghosts shared on it (so a new best can replace its ghost). Kept in user://ghosts.json (JsonStore), never
## in the profile backup: friends' runs and names stay on this device; deleting the online account forgets it
## (OnlineService.online_files); a report forgets everything of that player. Read carefully; capped.

const PATH := "user://ghosts.json"
const VERSION := 1
const MAX_GHOSTS := 12
const MAX_SHOWCASES := 6
const MAX_PLACED := 32
const KIND_SHOWCASE := "showcase"
const KIND_GIFT := "gift"
const MAX_ID := 64

## [{"key", "kind", "owner_id", "owner", "slot" (a gift's; -1), "ghost": RaceGhost, "best" (ms; 0 not raced),
## "at" (kept, unix s), "raced" (last raced, unix s)}], least lately raced first.
var ghosts: Array[Dictionary] = []
## Friends' showcases whose ghosts are kept: owner id -> {"owner", "build", "at"}.
var showcases := {}
## Where gifts' ghosts were stamped: [{"key", "world", "start": Vector3i, "forward": Vector3i}], oldest first.
var placed: Array[Dictionary] = []
## This player's own showcase: {"world", "origin": Vector3i, "size": Vector3i, "shared": {"x,y,z" (a START in
## the world) -> {"id", "ms"}}}, or {}.
var mine := {}
## Whether names show on ghosts (GhostRaceRules.shows_names at the last sign-in; offline it is the last known).
var names_ok := false

static var _current: GhostBook
static var _current_path := PATH


static func current() -> GhostBook:
	if _current == null:
		_current = load_from(_current_path)
	return _current


## Tests (and forgetting the online account): this book instead of the device's.
static func use(book: GhostBook, path: String = PATH) -> void:
	_current = book
	_current_path = path


static func save_current() -> Error:
	return current().save_to(_current_path)


static func showcase_key(ghost_id: String) -> String:
	return "s:" + ghost_id


static func gift_key(slot: int) -> String:
	return "g%d" % slot


# --- Friends' showcases ---

## What a visit to `owner_id`'s showcase brought: its ghosts (a showcase without any is not kept) and the build.
## A ghost kept already keeps the child's best against it.
func keep_showcase(owner_id: String, owner: String, build: String, list: Array[RaceGhost], now: int) -> void:
	var old := {}
	for e in ghosts.duplicate():
		if e.kind == KIND_SHOWCASE and e.owner_id == owner_id:
			old[e.key] = e
			ghosts.erase(e)
	if list.is_empty() or not _ok_owner(owner_id, owner) or BuildCodec.decode(build, BuildCodec.SHOWCASE).is_empty():
		showcases.erase(owner_id)
		return
	showcases[owner_id] = {"owner": owner, "build": build, "at": now}
	for g in list.slice(0, GhostRaceRules.PER_SHOWCASE):
		var key := showcase_key(g.id)
		var was: Dictionary = old.get(key, {})
		g.owner_id = owner_id
		g.owner = owner
		ghosts.append({"key": key, "kind": KIND_SHOWCASE, "owner_id": owner_id, "owner": owner, "slot": -1, "ghost": g,
			"best": int(was.get("best", 0)), "at": now, "raced": int(was.get("raced", now))})
	_trim()


## A friend's showcase as a visit reads it (GiftRules.showcase's keys, "ghosts" and "offline"), or {}.
func showcase_for(owner_id: String) -> Dictionary:
	if not showcases.has(owner_id):
		return {}
	var s: Dictionary = showcases[owner_id]
	var list: Array[RaceGhost] = []
	for e in ghosts:
		if e.kind == KIND_SHOWCASE and e.owner_id == owner_id:
			list.append(e.ghost)
	return {"owner_id": owner_id, "owner": s.owner, "build": s.build, "size": BuildCodec.size_of(s.build), "buddy": {},
		"guestbook": [], "ghosts": list, "offline": true}


## The friends whose showcase races are kept: [{"owner_id", "owner", "entries": [...]}], newest first.
func showcase_owners() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids := showcases.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return int(showcases[a].at) > int(showcases[b].at))
	for id: String in ids:
		out.append({"owner_id": id, "owner": showcases[id].owner,
			"entries": ghosts.filter(func(e: Dictionary) -> bool: return e.kind == KIND_SHOWCASE and e.owner_id == id)})
	return out


# --- Gifts ---

## A gift's ghost, for the stamp in `slot` (a new gift in a slot replaces what was there, and its places).
func keep_gift(slot: int, owner_id: String, owner: String, g: RaceGhost, now: int) -> void:
	forget_slot(slot)
	if g == null or slot < 0 or slot >= GiftStampBook.SLOTS or not _ok_owner(owner_id, owner):
		return
	g.owner_id = owner_id
	g.owner = owner
	ghosts.append({"key": gift_key(slot), "kind": KIND_GIFT, "owner_id": owner_id, "owner": owner, "slot": slot,
		"ghost": g, "best": 0, "at": now, "raced": now})
	_trim()


func gift_entry(slot: int) -> Dictionary:
	return entry(gift_key(slot))


## The stamp in `slot` was deleted (or reported): its ghost goes, and where it was stamped.
func forget_slot(slot: int) -> void:
	_drop(gift_key(slot))


## A gift's stamp with a ghost was stamped in this player's world `world` with its START at `start`, facing
## `forward` (Blueprints): racing that START races the ghost.
func place(key: String, world: String, start: Vector3i, forward: Vector3i) -> void:
	if entry(key).is_empty():
		return
	for p in placed.duplicate():
		if p.world == world and p.start == start:
			placed.erase(p)
	placed.append({"key": key, "world": world, "start": start, "forward": forward})
	while placed.size() > MAX_PLACED:
		placed.pop_front()


## The ghosts stamped in `world`: [{"key", "start", "forward", "ghost", "owner"}].
func placed_in(world: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in placed:
		var e := entry(p.key)
		if p.world == world and not e.is_empty():
			out.append({"key": p.key, "start": p.start, "forward": p.forward, "ghost": e.ghost, "owner": e.owner})
	return out


# --- Every ghost ---

func entry(key: String) -> Dictionary:
	for e in ghosts:
		if e.key == key:
			return e
	return {}


## The child finished a race against the ghost `key` in `ms`: true for a new best against it.
func note_result(key: String, ms: int, now: int) -> bool:
	var e := entry(key)
	if e.is_empty():
		return false
	e.raced = now
	ghosts.erase(e)
	ghosts.append(e)                     # raced lately
	var best := int(e.best) <= 0 or ms < int(e.best)
	if best:
		e.best = ms
	return best


## A report (or a block): every ghost, showcase copy and place of that player goes. How many ghosts went.
func remove_owner(owner_id: String) -> int:
	var n := 0
	for e in ghosts.duplicate():
		if e.owner_id == owner_id:
			_drop(e.key)
			n += 1
	showcases.erase(owner_id)
	return n


func _drop(key: String) -> void:
	for e in ghosts.duplicate():
		if e.key == key:
			ghosts.erase(e)
	for p in placed.duplicate():
		if p.key == key:
			placed.erase(p)


## At most MAX_SHOWCASES friends' showcases (the oldest go with their ghosts) and MAX_GHOSTS ghosts (the least
## lately raced go).
func _trim() -> void:
	while showcases.size() > MAX_SHOWCASES:
		var oldest := ""
		for id: String in showcases:
			if oldest == "" or int(showcases[id].at) < int(showcases[oldest].at):
				oldest = id
		for e in ghosts.duplicate():
			if e.kind == KIND_SHOWCASE and e.owner_id == oldest:
				_drop(e.key)
		showcases.erase(oldest)
	ghosts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.raced) < int(b.raced))
	while ghosts.size() > MAX_GHOSTS:
		_drop(ghosts[0].key)
	for id: String in showcases.keys():
		if not ghosts.any(func(e: Dictionary) -> bool: return e.kind == KIND_SHOWCASE and e.owner_id == id):
			showcases.erase(id)


static func _ok_owner(owner_id: Variant, owner: Variant) -> bool:
	return owner_id is String and owner_id != "" and (owner_id as String).length() <= MAX_ID and owner is String \
		and UsernameRules.validate(owner) == ""


# --- This player's own showcase ---

## A new showcase went up in `world` (Game.slot and the seed), its area at `origin` of `size`: nothing is shared
## on it yet (the server took the old area's ghosts down).
func set_mine(world: String, origin: Vector3i, size: Vector3i) -> void:
	mine = {"world": world, "origin": origin, "size": size, "shared": {}}


func clear_mine() -> void:
	mine = {}


## Whether `cell` of `world` is inside this player's showcase area.
func in_my_showcase(world: String, cell: Vector3i) -> bool:
	if mine.is_empty() or mine.world != world:
		return false
	var l: Vector3i = cell - (mine.origin as Vector3i)
	var s: Vector3i = mine.size
	return l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x < s.x and l.y < s.y and l.z < s.z


func note_shared(world: String, start: Vector3i, ghost_id: String, ms: int) -> void:
	if not mine.is_empty() and mine.world == world:
		mine.shared[_cell_key(start)] = {"id": ghost_id, "ms": ms}


## The ghost shared for the course whose START is `start` in `world`: {"id", "ms"} or {}.
func shared_at(world: String, start: Vector3i) -> Dictionary:
	if mine.is_empty() or mine.world != world:
		return {}
	return mine.shared.get(_cell_key(start), {})


func unshare(ghost_id: String) -> void:
	if mine.is_empty():
		return
	for k: String in (mine.shared as Dictionary).keys():
		if mine.shared[k].id == ghost_id:
			mine.shared.erase(k)


static func _cell_key(c: Vector3i) -> String:
	return "%d,%d,%d" % [c.x, c.y, c.z]


# --- On the device ---

static func load_from(path: String = PATH) -> GhostBook:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())


func to_json() -> String:
	var list := []
	for e in ghosts:
		var g: RaceGhost = e.ghost
		var w := g.to_wire()
		if g.id != "":
			w.ghost_id = g.id
		list.append({"key": e.key, "kind": e.kind, "owner_id": e.owner_id, "owner": e.owner, "slot": e.slot, "ghost": w,
			"best": e.best, "at": e.at, "raced": e.raced})
	var places := []
	for p in placed:
		places.append({"key": p.key, "world": p.world, "start": _arr(p.start), "forward": _arr(p.forward)})
	var own := {}
	if not mine.is_empty():
		own = {"world": mine.world, "origin": _arr(mine.origin), "size": _arr(mine.size), "shared": mine.shared}
	return JSON.stringify({"version": VERSION, "ghosts": list, "showcases": showcases, "placed": places, "mine": own,
		"names_ok": names_ok}, "\t")


static func _arr(v: Vector3i) -> Array:
	return [v.x, v.y, v.z]


## A stored book, read carefully: whole ghosts of friends with a username, a showcase ghost only with its
## showcase's build, a gift's only in a stamp's slot, places only of kept ghosts; anything else is left out.
static func from_json(text: String) -> GhostBook:
	var book := GhostBook.new()
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or not json.data is Dictionary:
		return book
	var d: Dictionary = json.data
	book.names_ok = d.get("names_ok") is bool and bool(d.names_ok)
	var cases: Variant = d.get("showcases", {})
	if cases is Dictionary:
		for id: Variant in cases:
			var s: Variant = cases[id]
			if s is Dictionary and _ok_owner(id, s.get("owner")) and s.get("build") is String \
					and not BuildCodec.decode(s.build, BuildCodec.SHOWCASE).is_empty():
				book.showcases[id] = {"owner": s.owner, "build": s.build, "at": _num(s.get("at"))}
	var raw: Variant = d.get("ghosts", [])
	if raw is Array:
		for e: Variant in raw:
			if not e is Dictionary or not _ok_owner(e.get("owner_id"), e.get("owner")):
				continue
			var g := RaceGhost.from_wire(e.get("ghost"))
			if g == null:
				continue
			var kind: Variant = e.get("kind")
			var key := ""
			var slot := -1
			if kind == KIND_SHOWCASE and g.id != "" and book.showcases.has(e.owner_id):
				key = showcase_key(g.id)
			elif kind == KIND_GIFT and _num(e.get("slot"), -1) >= 0 and _num(e.get("slot"), -1) < GiftStampBook.SLOTS:
				slot = _num(e.get("slot"), -1)
				key = gift_key(slot)
			if key == "" or not book.entry(key).is_empty():
				continue
			g.owner_id = e.owner_id
			g.owner = e.owner
			book.ghosts.append({"key": key, "kind": kind, "owner_id": e.owner_id, "owner": e.owner, "slot": slot,
				"ghost": g, "best": _num(e.get("best")), "at": _num(e.get("at")), "raced": _num(e.get("raced"))})
	var places: Variant = d.get("placed", [])
	if places is Array:
		for p: Variant in places:
			if p is Dictionary and p.get("key") is String and p.get("world") is String and _cell(p.get("start")) != null \
					and _cell(p.get("forward")) != null:
				book.place(p.key, p.world, _cell(p.start), _cell(p.forward))
	var own: Variant = d.get("mine", {})
	if own is Dictionary and own.get("world") is String and _cell(own.get("origin")) != null and _cell(own.get("size")) != null:
		book.set_mine(own.world, _cell(own.origin), _cell(own.size))
		var shared: Variant = own.get("shared", {})
		if shared is Dictionary:
			for k: Variant in shared:
				var v: Variant = shared[k]
				if k is String and v is Dictionary and v.get("id") is String and (v.id as String).length() <= MAX_ID:
					book.mine.shared[k] = {"id": v.id, "ms": _num(v.get("ms"))}
	book._trim()
	return book


static func _num(v: Variant, fallback: int = 0) -> int:
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else fallback


static func _cell(v: Variant) -> Variant:
	if not v is Array or (v as Array).size() != 3:
		return null
	for x: Variant in v:
		if not typeof(x) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(x)) or absf(float(x)) > 100000000.0:
			return null
	return Vector3i(int(v[0]), int(v[1]), int(v[2]))
