class_name TrophyRules
extends RefCounted
## The trophy shelf (M3 Task 21b; research C3): block 217, an open wooden cabinet with two shelves. Every shelf
## block near a game's player shows the world owner's badges (AchievementRules) as small 3D trophies, PER_SHELF
## on each, filled in the order the badges came, the top row of shelves first, then left to right: more shelves
## show more. Pure: the order, the layout and each shelf's boxes (TrophyShelves bakes them into one cached mesh
## per shelf content, so a shelf is one draw call).

const PER_SHELF := 4
## Trophies are shown on shelves this close to this game's player, at most this many shelves.
const SHOW_RADIUS := 16.0   # 27 chunks to index, not 64 (a trophy is a few pixels farther away)
const MAX_SHELVES := 16

const CUP := &"cup"
const STAR := &"star"
const GEM := &"gem"
const BLOCK := &"block"
const SHAPES: Array[StringName] = [CUP, STAR, GEM, BLOCK]

const GOLD := Color("ffd23f")
const WOOD := Color("8d6e63")
const DARK_WOOD := Color("5d4037")
## The look of a badge's trophy: by its family (AchievementRules kinds), a few by their own id.
const FAMILY_LOOKS := {
	&"buddy_woken": [CUP, Color("b388ff")], &"animal_tamed": [CUP, Color("ffab40")],
	&"secret_found": [CUP, Color("4dd0e1")], &"monster_defeated": [CUP, Color("81c784")],
	&"wave_won": [CUP, Color("ef7a5a")], &"boss_beaten": [BLOCK, Color("a0a0a0")],
	&"block_placed": [BLOCK, Color("d0643b")], &"photo_taken": [CUP, Color("64b5f6")],
	&"area_explored": [CUP, Color("9ccc65")], &"friend_played": [CUP, Color("f48fb1")],
	&"race_finished": [CUP, Color("eceff1")], &"goal_done": [STAR, Color("ffcc80")],
	AchievementRules.LEVEL: [STAR, GOLD],
}
const ID_LOOKS := {&"crystal_cave": [GEM, Color("ce93d8")], &"star_catcher": [STAR, Color("fff59d")],
	&"treasure_digger": [CUP, GOLD], &"golden_catch": [CUP, GOLD]}

## A trophy's slots: the upper shelf's left and right, then the lower shelf's; feet heights of the two shelves.
const SLOTS: Array[Vector3] = [Vector3(0.3, 0.54, 0.5), Vector3(0.7, 0.54, 0.5), Vector3(0.3, 0.1, 0.5),
	Vector3(0.7, 0.1, 0.5)]


## The shelves in filling order: the top row first, then along x, then along z (the same on every game).
static func order(cells: Array[Vector3i]) -> Array[Vector3i]:
	var out := cells.duplicate()
	out.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		if a.y != b.y:
			return a.y > b.y
		if a.x != b.x:
			return a.x < b.x
		return a.z < b.z)
	return out


## Shelf cell -> the badges on it (PER_SHELF at most; [] for an empty shelf). Unknown badges are left out.
static func layout(cells: Array[Vector3i], badges: Array[String]) -> Dictionary:
	var known: Array[String] = []
	for id in badges:
		if not AchievementRules.badge(StringName(id)).is_empty() and not known.has(id):
			known.append(id)
	var out := {}
	var i := 0
	for cell in order(cells):
		var on: Array = []
		while on.size() < PER_SHELF and i < known.size():
			on.append(known[i])
			i += 1
		out[cell] = on
	return out


## {shape, color} of a badge's trophy.
static func look_of(id: String) -> Dictionary:
	var pick: Array = ID_LOOKS.get(StringName(id), [])
	if pick.is_empty():
		var b := AchievementRules.badge(StringName(id))
		pick = FAMILY_LOOKS.get(LevelRules.family(b.get("kind", &"")), [CUP, GOLD])
	return {"shape": pick[0], "color": pick[1]}


## One shelf's content: the two wooden shelves and a trophy per badge, [centre, size, colour] inside the block
## (0..1 on every axis).
static func boxes(badges: Array[String]) -> Array:
	var out: Array = [[Vector3(0.5, 0.08, 0.5), Vector3(0.92, 0.04, 0.92), WOOD],
		[Vector3(0.5, 0.52, 0.5), Vector3(0.92, 0.04, 0.92), WOOD]]
	for i in mini(badges.size(), PER_SHELF):
		_trophy(out, SLOTS[i], look_of(badges[i]))
	return out


static func _trophy(out: Array, foot: Vector3, look: Dictionary) -> void:
	var c: Color = look.color
	var x := foot.x
	var y := foot.y
	var z := foot.z
	out.append([Vector3(x, y + 0.025, z), Vector3(0.2, 0.05, 0.2), DARK_WOOD])
	match look.shape:
		STAR:
			out.append([Vector3(x, y + 0.09, z), Vector3(0.04, 0.08, 0.04), c.darkened(0.25)])
			out.append([Vector3(x, y + 0.21, z), Vector3(0.2, 0.05, 0.05), c])
			out.append([Vector3(x, y + 0.21, z), Vector3(0.05, 0.2, 0.05), c])
			out.append([Vector3(x, y + 0.21, z), Vector3(0.1, 0.1, 0.06), c.lightened(0.35)])
		GEM:
			out.append([Vector3(x, y + 0.075, z), Vector3(0.08, 0.05, 0.08), c.darkened(0.3)])
			out.append([Vector3(x, y + 0.14, z), Vector3(0.15, 0.08, 0.15), c])
			out.append([Vector3(x, y + 0.21, z), Vector3(0.11, 0.06, 0.11), c.lightened(0.25)])
			out.append([Vector3(x, y + 0.26, z), Vector3(0.05, 0.04, 0.05), c.lightened(0.5)])
		BLOCK:
			out.append([Vector3(x, y + 0.12, z), Vector3(0.14, 0.14, 0.14), c])
			out.append([Vector3(x, y + 0.21, z), Vector3(0.07, 0.04, 0.07), GOLD])
		_:   # CUP
			out.append([Vector3(x, y + 0.09, z), Vector3(0.05, 0.08, 0.05), c.darkened(0.25)])
			out.append([Vector3(x, y + 0.19, z), Vector3(0.16, 0.12, 0.16), c])
			out.append([Vector3(x, y + 0.26, z), Vector3(0.18, 0.02, 0.18), c.lightened(0.3)])
			out.append([Vector3(x - 0.1, y + 0.19, z), Vector3(0.03, 0.07, 0.03), c.darkened(0.15)])
			out.append([Vector3(x + 0.1, y + 0.19, z), Vector3(0.03, 0.07, 0.03), c.darkened(0.15)])


## A shelf's content key: shelves showing the same badges share one mesh.
static func key(badges: Array[String]) -> String:
	return ",".join(PackedStringArray(badges))
