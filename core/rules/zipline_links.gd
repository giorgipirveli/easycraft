class_name ZiplineLinks
extends RefCounted
## Which zipline posts are linked (M3 Task 14a), a world's own (saved in WorldMeta.ziplines, like the portal
## links). A post a player places links with the nearest post the same player placed that has no line yet,
## GadgetRules.ZIP_MIN_LENGTH to ZIP_MAX_LENGTH (48) blocks away and with a clear line between (can_link, the
## host's world); otherwise it waits for the next one. A broken post frees its partner, which then waits too.
## At most MAX posts per world. Pure (the host's ZiplineDirector keeps one).

const MAX := 64
const _FAR := 100000000.0

var _order: Array[Vector3i] = []
var _owner := {}     # post -> who placed it (a player's name; "" = anyone)
var _partner := {}   # post -> post


func has(post: Vector3i) -> bool:
	return _order.has(post)


## Every post, in placing order.
func posts() -> Array[Vector3i]:
	return _order.duplicate()


func owner_of(post: Vector3i) -> String:
	return str(_owner.get(post, ""))


## The linked post, or null.
func partner_of(post: Vector3i) -> Variant:
	return _partner.get(post)


## A post placed by `owner`: it links with the nearest free post of that owner (can_link(a, b) -> bool:
## the line between them is clear). False when it is known or there are MAX.
func add(post: Vector3i, owner: String, can_link: Callable = Callable()) -> bool:
	if _order.has(post) or _order.size() >= MAX:
		return false
	_order.append(post)
	_owner[post] = owner
	_link(post, can_link)
	return true


## A post broken (or undone): its partner waits for the next post. Returns the freed partner or null.
func remove(post: Vector3i) -> Variant:
	if not _order.has(post):
		return null
	_order.erase(post)
	_owner.erase(post)
	var other: Variant = _partner.get(post)
	_partner.erase(post)
	if other != null:
		_partner.erase(other)
	return other


## Every line once, [[a, b], ...] (a placed before b).
func lines() -> Array:
	var out: Array = []
	for post in _order:
		var other: Variant = _partner.get(post)
		if other != null and _order.find(post) < _order.find(other):
			out.append([post, other])
	return out


func _link(post: Vector3i, can_link: Callable) -> void:
	var best: Variant = null
	var best_d := INF
	for other in _order:
		if other == post or _partner.has(other) or owner_of(other) != owner_of(post):
			continue
		if not GadgetRules.can_link(post, other):
			continue
		var d := Vector3(other - post).length_squared()
		if d < best_d and (not can_link.is_valid() or can_link.call(post, other)):
			best_d = d
			best = other
	if best != null:
		_partner[post] = best
		_partner[best] = post


## [[x, y, z, owner] or [x, y, z, owner, px, py, pz], ...] in placing order.
func to_save() -> Array:
	var out := []
	for post in _order:
		var e: Array = [post.x, post.y, post.z, owner_of(post)]
		var other: Variant = _partner.get(post)
		if other != null:
			e.append_array([other.x, other.y, other.z])
		out.append(e)
	return out


## Never fails: broken entries are dropped, a post counted once, a partner that isn't there, doesn't link
## back or is too far away forgotten (that post waits for the next one).
static func from_save(data: Variant) -> ZiplineLinks:
	var l := ZiplineLinks.new()
	if not data is Array:
		return l
	var wanted := {}
	for entry: Variant in data:
		if not entry is Array or l._order.size() >= MAX:
			continue
		var e: Array = entry
		if (e.size() != 4 and e.size() != 7) or not e[3] is String:
			continue
		var nums := e.slice(0, 3) + (e.slice(4, 7) if e.size() == 7 else [])
		if not nums.all(_finite):
			continue
		var post := Vector3i(int(e[0]), int(e[1]), int(e[2]))
		if l._order.has(post):
			continue
		l._order.append(post)
		l._owner[post] = str(e[3]).left(32)
		if e.size() == 7:
			wanted[post] = Vector3i(int(e[4]), int(e[5]), int(e[6]))
	for post: Vector3i in wanted:
		var other: Vector3i = wanted[post]
		if other != post and l._order.has(other) and wanted.get(other) == post and GadgetRules.can_link(post, other):
			l._partner[post] = other
	return l


static func _finite(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < _FAR
