class_name MagicPetModels
extends RefCounted
## The looks of buddy magic's pets (M3 Task 20b): a befriended monster (BefriendRules.SPECIES) is its monster
## kind's level-1 model (MonsterModels' boxes) without its weapon, shrunk to pet size; a boss's mini-buddy
## (MiniRules.SPECIES) is a small box model of its boss (the Pebble Golem, the mini Sand Serpent, the little Frost
## Giant, the Cupcake Monster) in the boss's own colours. Each is ONE mesh built once per kind and shared, in
## BlockyAnimal's vertex-colour material (the animals' and monsters' shader: nothing new to compile). Models face
## -Z and stand on y = 0 (a flyer's floats a little over it).

const HEIGHT := 0.8               # a friend is shrunk to fit this tall ...
const WIDTH := 0.75               # ... and this wide
const HOVER := 0.25               # a flying monster's friend floats this high
const BLUSH := Color("ff8fb0")

static var _meshes := {}


static func has(species: StringName) -> bool:
	return species == BefriendRules.SPECIES or species == MiniRules.SPECIES


## The shared mesh of `species` (a has() species) with `variant` (a monster or boss kind; an unknown one: a slime
## or the Pebble Golem).
static func mesh_for(species: StringName, variant: StringName) -> ArrayMesh:
	var key := "%s/%s" % [species, variant]
	if not _meshes.has(key):
		_meshes[key] = BlockyAnimal._build(boxes(species, variant))
	return _meshes[key]


## [center, size, colour] boxes of the model.
static func boxes(species: StringName, variant: StringName) -> Array:
	if species == MiniRules.SPECIES:
		return mini_boxes(variant)
	return friend_boxes(variant)


## A monster's level-1 boxes without its club or bow (and the yeti's snowball), fitted to pet size, with pink
## cheeks under its eyes.
static func friend_boxes(kind: StringName) -> Array:
	var k := kind if MonsterRules.KINDS.has(kind) else MonsterRules.SLIME
	var kept: Array = []
	var armed := k == MonsterRules.GOBLIN or k == MonsterRules.ARCHER
	var arm_seen := false
	for b: Array in MonsterModels.boxes(k, 1):
		if b[3] == MonsterModels.BALL:
			continue
		if b[3] == MonsterModels.ARM and armed:
			if arm_seen:
				continue                  # the club or bow: a friend carries none (its arm stays)
			arm_seen = true
		kept.append([b[0], b[1], b[2]])
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for b: Array in kept:
		var h: Vector3 = (b[1] as Vector3) * 0.5
		lo = lo.min((b[0] as Vector3) - h)
		hi = hi.max((b[0] as Vector3) + h)
	var size := hi - lo
	var s := minf(1.0, minf(HEIGHT / maxf(size.y, 0.01), WIDTH / maxf(maxf(size.x, size.z), 0.01)))
	var lift := HOVER if MonsterRules.KIND[k].behaviour == MonsterRules.FLYER else 0.0
	var shift := Vector3(-(lo.x + hi.x) * 0.5, -lo.y, -(lo.z + hi.z) * 0.5)
	var out: Array = []
	for b: Array in kept:
		out.append([((b[0] as Vector3) + shift) * s + Vector3(0, lift, 0), (b[1] as Vector3) * s, b[2]])
	var front := (lo.z + shift.z) * s - 0.005
	var cheek_y := (lo.y + shift.y + size.y * 0.55) * s + lift
	for side in [-1.0, 1.0]:
		out.append([Vector3(side * size.x * s * 0.28, cheek_y, front), Vector3(0.07, 0.035, 0.01), BLUSH])
	return out


## Where a pet's collar (a band) sits on its model: [center, size].
static func collar_for(species: StringName, variant: StringName) -> Array:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for b: Array in boxes(species, variant):
		var h: Vector3 = (b[1] as Vector3) * 0.5
		lo = lo.min((b[0] as Vector3) - h)
		hi = hi.max((b[0] as Vector3) + h)
	var y := lo.y + (hi.y - lo.y) * 0.5
	return [Vector3((lo.x + hi.x) * 0.5, y, (lo.z + hi.z) * 0.5),
		Vector3((hi.x - lo.x) * 0.7 + 0.04, 0.05, (hi.z - lo.z) * 0.7 + 0.04)]


## A boss's mini-buddy: a small box model in the boss's colours.
static func mini_boxes(boss: StringName) -> Array:
	if AlienRules.is_alien_kind(boss):   # owner #86 (spec §21f): an alien friend
		return AlienModels.mini_boxes(AlienRules.alien_of_kind(boss))
	match boss:
		BossRules.SERPENT:
			var sc := SerpentModels.SCALES
			var dark := SerpentModels.SCALES_DARK
			return [
				[Vector3(0, 0.09, 0.05), Vector3(0.6, 0.18, 0.6), dark],            # its coils
				[Vector3(0, 0.25, 0.08), Vector3(0.44, 0.14, 0.44), sc],
				[Vector3(0, 0.48, -0.04), Vector3(0.18, 0.32, 0.18), sc],           # the neck
				[Vector3(0, 0.48, -0.135), Vector3(0.12, 0.28, 0.02), SerpentModels.BELLY],
				[Vector3(0, 0.68, -0.13), Vector3(0.3, 0.18, 0.34), sc],            # the head
				[Vector3(0, 0.79, -0.08), Vector3(0.06, 0.06, 0.22), dark],         # its crest
				[Vector3(-0.09, 0.73, -0.305), Vector3(0.07, 0.05, 0.02), SerpentModels.EYES],
				[Vector3(0.09, 0.73, -0.305), Vector3(0.07, 0.05, 0.02), SerpentModels.EYES],
				[Vector3(-0.05, 0.61, -0.305), Vector3(0.03, 0.05, 0.02), SerpentModels.FANG],
				[Vector3(0.05, 0.61, -0.305), Vector3(0.03, 0.05, 0.02), SerpentModels.FANG],
				[Vector3(0.24, 0.05, 0.3), Vector3(0.1, 0.1, 0.16), dark],          # the tip of its tail
			]
		BossRules.FROST_GIANT:
			var skin := GiantModels.SKIN
			return [
				[Vector3(-0.12, 0.1, 0), Vector3(0.16, 0.2, 0.2), GiantModels.SKIN_DARK],   # legs
				[Vector3(0.12, 0.1, 0), Vector3(0.16, 0.2, 0.2), GiantModels.SKIN_DARK],
				[Vector3(0, 0.37, 0), Vector3(0.46, 0.34, 0.32), skin],             # the chest
				[Vector3(0, 0.22, 0), Vector3(0.48, 0.05, 0.34), GiantModels.BELT],
				[Vector3(0, 0.55, 0), Vector3(0.52, 0.07, 0.36), GiantModels.FUR],  # the fur mantle
				[Vector3(-0.3, 0.38, 0), Vector3(0.12, 0.3, 0.16), skin],           # arms
				[Vector3(0.3, 0.38, 0), Vector3(0.12, 0.3, 0.16), skin],
				[Vector3(0, 0.71, -0.02), Vector3(0.32, 0.26, 0.3), skin],          # the head
				[Vector3(0, 0.61, -0.175), Vector3(0.26, 0.14, 0.04), GiantModels.FUR],   # its icicle beard
				[Vector3(-0.07, 0.75, -0.175), Vector3(0.06, 0.05, 0.02), GiantModels.MOUTH],
				[Vector3(0.07, 0.75, -0.175), Vector3(0.06, 0.05, 0.02), GiantModels.MOUTH],
				[Vector3(0, 0.87, 0), Vector3(0.28, 0.07, 0.26), GiantModels.ICE],  # a crown of ice
				[Vector3(-0.1, 0.93, 0), Vector3(0.05, 0.06, 0.05), GiantModels.ICE],
				[Vector3(0.1, 0.93, 0), Vector3(0.05, 0.06, 0.05), GiantModels.ICE],
			]
		BossRules.CAKE:
			var out: Array = [
				[Vector3(0, 0.18, 0), Vector3(0.6, 0.36, 0.6), CakeModels.SPONGE],  # the bottom tier, with the face
				[Vector3(0, 0.37, 0), Vector3(0.62, 0.04, 0.62), CakeModels.CREAM],
				[Vector3(0, 0.5, 0), Vector3(0.42, 0.24, 0.42), CakeModels.PINK],   # the top tier
				[Vector3(0, 0.67, 0), Vector3(0.12, 0.12, 0.12), CakeModels.CHERRY],
				[Vector3(0.02, 0.76, 0), Vector3(0.02, 0.07, 0.02), CakeModels.STEM],
				[Vector3(-0.12, 0.22, -0.305), Vector3(0.12, 0.12, 0.02), CakeModels.EYE_WHITE],
				[Vector3(0.12, 0.22, -0.305), Vector3(0.12, 0.12, 0.02), CakeModels.EYE_WHITE],
				[Vector3(-0.12, 0.21, -0.315), Vector3(0.06, 0.06, 0.02), CakeModels.PUPIL],
				[Vector3(0.12, 0.21, -0.315), Vector3(0.06, 0.06, 0.02), CakeModels.PUPIL],
				[Vector3(0, 0.1, -0.305), Vector3(0.16, 0.04, 0.02), CakeModels.MOUTH],
			]
			for i in CakeModels.SPRINKLES.size():   # sprinkles on the top tier
				var a := TAU * i / CakeModels.SPRINKLES.size()
				out.append([Vector3(cos(a) * 0.14, 0.625, sin(a) * 0.14), Vector3(0.04, 0.02, 0.04), CakeModels.SPRINKLES[i]])
			return out
	var stone := GolemModels.STONE   # the Pebble Golem
	var dark := GolemModels.STONE_DARK
	return [
		[Vector3(-0.14, 0.09, 0), Vector3(0.18, 0.18, 0.22), dark],               # legs
		[Vector3(0.14, 0.09, 0), Vector3(0.18, 0.18, 0.22), dark],
		[Vector3(0, 0.38, 0), Vector3(0.56, 0.42, 0.42), stone],                  # a round stone body
		[Vector3(0, 0.6, 0), Vector3(0.58, 0.05, 0.44), GolemModels.MOSS],        # moss on its shoulders
		[Vector3(-0.36, 0.33, 0), Vector3(0.14, 0.34, 0.18), dark],               # arms
		[Vector3(0.36, 0.33, 0), Vector3(0.14, 0.34, 0.18), dark],
		[Vector3(0, 0.4, -0.215), Vector3(0.1, 0.1, 0.02), GolemModels.RUNE],     # the rune on its chest
		[Vector3(0, 0.72, -0.02), Vector3(0.36, 0.26, 0.32), GolemModels.STONE_LIGHT],   # the head
		[Vector3(0, 0.8, -0.18), Vector3(0.38, 0.06, 0.06), dark],                # a heavy brow
		[Vector3(-0.08, 0.72, -0.185), Vector3(0.07, 0.05, 0.02), GolemModels.EYES],
		[Vector3(0.08, 0.72, -0.185), Vector3(0.07, 0.05, 0.02), GolemModels.EYES],
	]
