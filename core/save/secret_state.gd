class_name SecretState
extends RefCounted
## One world's secrets (M2 Task 16), saved in WorldMeta.secrets: the secrets found here, the chests opened
## (a chest opens once), the temples solved, the secrets that already chimed, the areas explored (with how
## many secrets each holds: the Secret Book's found / total), the golden animals caught, the fallen stars
## nobody has reached yet, and the dusks and nights counted (the Wanderer's and the stars' schedule).
## from_save never fails: anything broken is dropped.

const MAX_IDS := 4096
const MAX_AREAS := 4096
const MAX_STARS := 8

var found := {}                   # secret id -> true
var opened := {}                  # chest id (its secret's id) -> true
var solved := {}                  # temple id -> true
var chimed := {}                  # secret id -> true
var explored := {}                # Vector2i area -> how many secrets it holds
var caught := {}                  # golden animal id -> true
var stars: Array[Vector3i] = []   # fallen stars (their ground cell) nobody has reached yet
var dusks := 0                    # dusks seen in this world (the Wanderer's schedule)
var nights := 0                   # nights seen (the shooting stars' schedule)
var wanderer_rewarded := 0        # the dusk whose Wanderer already gave his reward
var more := TreasureState.new()   # owner 42: the treasure pack's rainbows, pots and wishes


## Marks an area explored; true the first time.
func explore(area: Vector2i, secrets_in_it: int) -> bool:
	if explored.has(area) or explored.size() >= MAX_AREAS:
		return false
	explored[area] = maxi(secrets_in_it, 0)
	return true


## (found, total): the secrets found in the explored areas, and how many those areas hold.
func counts() -> Vector2i:
	var total := 0
	for n: int in explored.values():
		total += n
	var got := 0
	for id: String in found:
		var parts := id.split("_")
		if parts.size() == 4 and parts[1].is_valid_int() and parts[2].is_valid_int() \
				and explored.has(Vector2i(int(parts[1]), int(parts[2]))):
			got += 1
	return Vector2i(mini(got, total), total)


func to_save() -> Dictionary:
	var areas: Array = []
	for a: Vector2i in explored:
		areas.append([a.x, a.y, explored[a]])
	var star_list: Array = []
	for s in stars:
		star_list.append([s.x, s.y, s.z])
	return {"found": found.keys(), "opened": opened.keys(), "solved": solved.keys(), "chimed": chimed.keys(),
		"explored": areas, "caught": caught.keys(), "stars": star_list, "dusks": dusks, "nights": nights,
		"wanderer_rewarded": wanderer_rewarded, "more": more.to_save()}


static func from_save(data: Variant) -> SecretState:
	var s := SecretState.new()
	if not data is Dictionary:
		return s
	var d: Dictionary = data
	s.found = _ids(d.get("found"))
	s.opened = _ids(d.get("opened"))
	s.solved = _ids(d.get("solved"))
	s.chimed = _ids(d.get("chimed"))
	s.caught = _ids(d.get("caught"))
	var areas: Variant = d.get("explored")
	if areas is Array:
		for e: Variant in areas:
			if _ints(e, 3):
				s.explore(Vector2i(int(e[0]), int(e[1])), int(e[2]))
	var star_list: Variant = d.get("stars")
	if star_list is Array:
		for e: Variant in star_list:
			if _ints(e, 3) and s.stars.size() < MAX_STARS:
				s.stars.append(Vector3i(int(e[0]), int(e[1]), int(e[2])))
	s.dusks = _count(d.get("dusks"))
	s.nights = _count(d.get("nights"))
	s.wanderer_rewarded = _count(d.get("wanderer_rewarded"))
	s.more = TreasureState.from_save(d.get("more"))
	return s


static func _ids(v: Variant) -> Dictionary:
	var out := {}
	if v is Array:
		for e: Variant in v:
			if e is String and e != "" and out.size() < MAX_IDS:
				out[e] = true
	return out


static func _ints(v: Variant, n: int) -> bool:
	if not v is Array or (v as Array).size() != n:
		return false
	for e: Variant in v:
		if not typeof(e) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(e)) or absf(float(e)) > 1.0e9:
			return false
	return true


static func _count(v: Variant) -> int:
	return maxi(int(v), 0) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < 1.0e9 else 0
