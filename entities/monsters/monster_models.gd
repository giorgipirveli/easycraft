class_name MonsterModels
extends RefCounted
## Box-built monster models (M2 Task 4), one mesh per kind and level, built once and shared by every
## monster of that kind and level. They use BlockyAnimal's vertex-colour material, so animals,
## monsters, coins and health bars all draw with one shader (a new shader would compile on the first
## monster: a 100+ ms frame on the emulator, DEVELOPMENT.md §8).
## Level looks (spec §12.4): the model grows (MonsterRules.size_scale), wears its level colour
## (Okabe-Ito, safe for colour blindness) and carries one spike (slime) or horn (goblin) per level.
## Models face -Z and stand on y = 0. A goblin's club arm is a second mesh that turns around its
## shoulder (ARM_PIVOT) for the wind-up.

const SPIKE := &"spike"
const ARM := &"arm"
const BONE := Color("f4ebd0")
const BLACK := Color("1c1c20")
const WHITE := Color("fbfbfb")
const SLIME_BLUSH := Color("ff8fa3")   # owner #43: the jelly drop's cheeks
const GOBLIN_SKIN := Color("8fa85a")
const GOBLIN_EYES := Color("ffd23f")
const WOOD := Color("7a5230")
const WOOD_DARK := Color("4e3320")
const ARM_PIVOT := Vector3(-0.3, 0.84, 0.0)   # the goblin's right shoulder (unscaled)
const BAR_WIDTH := 0.9
const BAR_HEIGHT := 0.1

static var _meshes := {}
static var _arms := {}
static var _coin: ArrayMesh
static var _bar_back: ArrayMesh
static var _bar_fill: ArrayMesh


## The body (everything but the arm that winds up: a goblin's club, a mummy's arms, a scorpion's tail).
## A mummy's half (M3 Task 2) is the part of its boxes above or below the waist.
static func mesh_for(kind: StringName, level: int, half: int = 0) -> ArrayMesh:
	var key := "%s%d_%d" % [kind, MonsterRules.level_of(level), half]
	if not _meshes.has(key):
		_meshes[key] = BlockyAnimal._build(boxes(kind, level, half).filter(func(b: Array) -> bool: return b[3] != ARM and b[3] != BALL))
	return _meshes[key]


## The arm that winds up, around arm_pivot_for; null for slimes and a mummy's legs. `lit`: the scorpion's
## tail glowing while it winds up (brighter vertex colours: the same material, a second shared mesh); M3
## Task 3: the yeti's arms holding a snowball up, the ice bat's wings glowing icy before a dive. `frame`: an
## ice bat's wings up (0) or down (1): it flaps by swapping two shared meshes.
static func arm_mesh_for(kind: StringName, level: int, half: int = 0, lit: bool = false, frame: int = 0) -> ArrayMesh:
	if kind == MonsterRules.SLIME or kind == MonsterRules.GUMMY or half == MonsterRules.HALF_LEGS:   # M3 Task 4: no weapon
		return null
	var key := "%s%d_%d_%s_%d" % [kind, MonsterRules.level_of(level), half, lit, frame]
	if not _arms.has(key):
		var pivot := arm_pivot_for(kind, level, half)
		var arm: Array = []
		var glow: Color = GLOWS.get(kind, TAIL_GLOW)   # owner #39: the shadow bat's lilac flare, the wisp's light
		for b: Array in boxes(kind, level, half, frame):
			if b[3] == ARM or (b[3] == BALL and lit):
				var c: Color = b[2]
				var tint: bool = lit and b[3] == ARM and kind != MonsterRules.YETI and kind != MonsterRules.ARCHER
				var col := c.lerp(glow, 0.6) if tint else c
				if lit and c == SHADOW_EYES:
					col = SHADOW_EYES_LIT   # owner #39: a shadow bat's eyes light up before its swoop
				arm.append([(b[0] as Vector3) - pivot, b[1], col])
		_arms[key] = BlockyAnimal._build(arm)
	return _arms[key]


## Kinds whose arm mesh changes while they wind up (the scorpion's glowing tail, the yeti's snowball, the
## ice bat's icy wings).
static func lights_up(kind: StringName) -> bool:
	return kind == MonsterRules.SCORPION or kind == MonsterRules.YETI or kind == MonsterRules.ICE_BAT \
		or kind == MonsterRules.ARCHER \
		or kind == MonsterRules.SHADOW_BAT or kind == MonsterRules.WISP \
		or kind == MonsterRules.SPORE_PUFF or kind == MonsterRules.CRAWLER   # 14b: the archer; owner #39; universe 6


static func arm_pivot(level: int) -> Vector3:
	return ARM_PIVOT * MonsterRules.size_scale(level)


## Where the arm turns: a goblin's right shoulder, a mummy's shoulders, a scorpion's tail root.
static func arm_pivot_for(kind: StringName, level: int, half: int = 0) -> Vector3:
	var s := MonsterRules.size_scale(level)
	match kind:
		MonsterRules.MUMMY:
			return (MUMMY_SHOULDERS - (Vector3(0, TOP_DROP, 0) if half == MonsterRules.HALF_TOP else Vector3.ZERO)) * s
		MonsterRules.SCORPION:
			return TAIL_ROOT * s
		MonsterRules.YETI:
			return YETI_SHOULDERS * s
		MonsterRules.ICE_BAT, MonsterRules.SHADOW_BAT:
			return BAT_SHOULDERS * s
		MonsterRules.WISP:
			return WISP_CORE * s          # owner #39: its ring grows round the orb
		MonsterRules.SPORE_PUFF:
			return PUFF_HINGE * s         # universe 6: its cap lifts at the back
		MonsterRules.CRAWLER:
			return FEELER_ROOT * s        # universe 6: its feelers rise from its head
	return ARM_PIVOT * s


## How far the arm turns for the wind-up (radians around x): the club over the head, the mummy's arms up,
## the scorpion's tail cocked forward over its back.
static func windup_angle(kind: StringName) -> float:
	match kind:
		MonsterRules.MUMMY:
			return 1.1
		MonsterRules.SCORPION:
			return -0.75
		MonsterRules.YETI:
			return 2.8
		MonsterRules.ICE_BAT, MonsterRules.SHADOW_BAT, MonsterRules.WISP:
			return 0.0          # its wings flap instead (frames); a wisp's ring grows (owner #39)
		MonsterRules.ARCHER:
			return ARCHER_AIM   # M3 Task 14b: the bow comes up level, aimed
		MonsterRules.SPORE_PUFF:
			return -0.45        # universe 6: its cap lifts as it swells
		MonsterRules.CRAWLER:
			return -0.8         # universe 6: its feelers go up
	return 2.6


## How many spikes or horns the model carries (its level).
static func spike_count(kind: StringName, level: int) -> int:
	return boxes(kind, level).filter(func(b: Array) -> bool: return b[3] == SPIKE).size()


static func colors_of(kind: StringName, level: int) -> Array[Color]:
	var out: Array[Color] = []
	for b: Array in boxes(kind, level):
		out.append(b[2])
	return out


## [center, size, colour, tag] boxes, scaled for the level. tag: &"" (body), SPIKE, ARM or BALL (the yeti's
## snowball, shown only in its arms' wind-up mesh). frame: the ice bat's wings up or down.
static func boxes(kind: StringName, level: int, half: int = 0, frame: int = 0) -> Array:
	var l := MonsterRules.level_of(level)
	var s := MonsterRules.size_scale(l)
	var raw: Array
	match kind:
		MonsterRules.GOBLIN:
			raw = _goblin(l)
		MonsterRules.MUMMY:
			raw = _mummy_half(_mummy(l), half)
		MonsterRules.SCORPION:
			raw = _scorpion(l)
		MonsterRules.YETI:
			raw = _yeti(l)
		MonsterRules.ICE_BAT:
			raw = _bat(l, frame)
		MonsterRules.GUMMY:
			raw = _gummy(l)       # M3 Task 4
		MonsterRules.SNEAKER:
			raw = _sneaker(l)
		MonsterRules.ARCHER:
			raw = _archer(l)    # M3 Task 14b
		MonsterRules.SHADOW_BAT:
			raw = _shadow_bat(l, frame)   # owner #39
		MonsterRules.WISP:
			raw = _wisp(l)
		MonsterRules.SPORE_PUFF:
			raw = _spore_puff(l)   # universe 6
		MonsterRules.CRAWLER:
			raw = _crawler(l)
		_:
			raw = _slime(l)
	var out: Array = []
	for b: Array in raw:
		out.append([(b[0] as Vector3) * s, (b[1] as Vector3) * s, b[2], b[3] if b.size() > 3 else &""])
	return out


## A jelly drop (owner #43: a stepped dome, never a cube): a wide soft foot, layers that narrow to a round top with a
## little curl, a glossy spot, big eyes, pink cheeks and a smile; l spikes in a row on top.
static func _slime(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(0, 0.05, 0), Vector3(0.8, 0.1, 0.8), c.darkened(0.25)],          # the foot
		[Vector3(0, 0.23, 0), Vector3(0.76, 0.26, 0.76), c],                      # the body, narrowing up
		[Vector3(0, 0.42, 0), Vector3(0.62, 0.12, 0.62), c],
		[Vector3(0, 0.52, 0), Vector3(0.44, 0.08, 0.44), c.lightened(0.12)],
		[Vector3(0, 0.595, 0), Vector3(0.14, 0.07, 0.14), c.lightened(0.2)],      # the curl on top
		[Vector3(-0.14, 0.49, -0.14), Vector3(0.12, 0.03, 0.1), c.lightened(0.55)],   # a glossy spot
		[Vector3(-0.14, 0.26, -0.38), Vector3(0.16, 0.16, 0.02), WHITE],          # eyes
		[Vector3(0.14, 0.26, -0.38), Vector3(0.16, 0.16, 0.02), WHITE],
		[Vector3(-0.12, 0.27, -0.395), Vector3(0.08, 0.1, 0.02), BLACK],
		[Vector3(0.16, 0.27, -0.395), Vector3(0.08, 0.1, 0.02), BLACK],
		[Vector3(-0.27, 0.19, -0.385), Vector3(0.08, 0.04, 0.02), SLIME_BLUSH],   # cheeks
		[Vector3(0.27, 0.19, -0.385), Vector3(0.08, 0.04, 0.02), SLIME_BLUSH],
		[Vector3(0, 0.15, -0.385), Vector3(0.16, 0.04, 0.02), c.darkened(0.55)],  # a smile
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.08
		out.append([Vector3(x, 0.66, 0.0), Vector3(0.06, 0.12, 0.06), BONE, SPIKE])
	return out


## A small goblin in a tunic of its level colour, with pointy ears, yellow eyes, l horns and a club.
static func _goblin(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var skin := GOBLIN_SKIN
	var out: Array = [
		[Vector3(-0.11, 0.2, 0), Vector3(0.14, 0.4, 0.16), WOOD_DARK],            # legs
		[Vector3(0.11, 0.2, 0), Vector3(0.14, 0.4, 0.16), WOOD_DARK],
		[Vector3(0, 0.63, 0), Vector3(0.46, 0.46, 0.28), c],                      # tunic
		[Vector3(0, 0.43, 0), Vector3(0.48, 0.06, 0.3), WOOD],                    # belt
		[Vector3(0, 1.04, -0.02), Vector3(0.4, 0.36, 0.36), skin],                # head
		[Vector3(-0.27, 1.08, 0), Vector3(0.14, 0.08, 0.06), skin],               # ears
		[Vector3(0.27, 1.08, 0), Vector3(0.14, 0.08, 0.06), skin],
		[Vector3(-0.09, 1.1, -0.205), Vector3(0.09, 0.07, 0.02), GOBLIN_EYES],    # eyes
		[Vector3(0.09, 1.1, -0.205), Vector3(0.09, 0.07, 0.02), GOBLIN_EYES],
		[Vector3(-0.09, 1.1, -0.215), Vector3(0.04, 0.05, 0.02), BLACK],
		[Vector3(0.09, 1.1, -0.215), Vector3(0.04, 0.05, 0.02), BLACK],
		[Vector3(0, 1.0, -0.23), Vector3(0.08, 0.1, 0.06), skin.darkened(0.15)],  # nose
		[Vector3(0, 0.92, -0.205), Vector3(0.16, 0.03, 0.02), BLACK],             # grin
		[Vector3(0.3, 0.66, 0), Vector3(0.1, 0.36, 0.12), skin],                  # left arm
		[Vector3(-0.3, 0.66, 0), Vector3(0.1, 0.36, 0.12), skin, ARM],            # right arm and club
		[Vector3(-0.3, 0.5, -0.14), Vector3(0.07, 0.07, 0.24), WOOD, ARM],
		[Vector3(-0.3, 0.5, -0.32), Vector3(0.14, 0.14, 0.18), WOOD_DARK, ARM],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.085
		out.append([Vector3(x, 1.28, 0.0), Vector3(0.05, 0.12, 0.05), BONE, SPIKE])
	return out


## A blocky gold coin, standing upright (faces ±Z).
static func coin_mesh() -> ArrayMesh:
	if _coin == null:
		_coin = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.32, 0.32, 0.06), Color("f2b632")],
			[Vector3.ZERO, Vector3(0.2, 0.2, 0.08), Color("ffe27a")],
			[Vector3.ZERO, Vector3(0.06, 0.14, 0.09), Color("f2b632")],
		])
	return _coin


## The health bar: a dark back and a green fill (BAR_WIDTH wide, centred, facing +Z).
static func bar_back_mesh() -> ArrayMesh:
	if _bar_back == null:
		_bar_back = BlockyAnimal._build([[Vector3.ZERO, Vector3(BAR_WIDTH + 0.06, BAR_HEIGHT + 0.06, 0.02), Color("26222b")]])
	return _bar_back


static func bar_fill_mesh() -> ArrayMesh:
	if _bar_fill == null:
		_bar_fill = BlockyAnimal._build([[Vector3.ZERO, Vector3(BAR_WIDTH, BAR_HEIGHT, 0.02), Color("5ee05e")]])
	return _bar_fill


# --- M3 Task 2: the Sandstorm Desert's mummy and scorpion ---------------------------------------------

const BANDAGE := Color("e8dcc0")
const BANDAGE_DARK := Color("b9ab8a")
const MUMMY_EYES := Color("7cf0ff")
const MUMMY_SHOULDERS := Vector3(0.0, 1.12, 0.0)   # both arms turn here (unscaled)
const WAIST := 0.72               # a mummy unwraps here: boxes above are its top half, below its legs
const TOP_DROP := 0.62            # the top half crawls: its boxes come this far down
const SHELL_DARK := Color("3b2a1e")
const STINGER := Color("f2e7c9")
const TAIL_GLOW := Color("b8ff5a")   # the poison glow of a scorpion winding up (its lit tail)
const TAIL_ROOT := Vector3(0.0, 0.3, 0.42)
const GLOB := Color("8fdc3c")


## A bandaged mummy: arms held out in front (they rise for the grab), glowing eyes, a sash of its level
## colour, l loose bandage ends on its head.
static func _mummy(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(-0.13, 0.36, 0), Vector3(0.18, 0.72, 0.2), BANDAGE_DARK],       # legs
		[Vector3(0.13, 0.36, 0), Vector3(0.18, 0.72, 0.2), BANDAGE],
		[Vector3(0, 0.95, 0), Vector3(0.52, 0.5, 0.3), BANDAGE],                 # body
		[Vector3(0, 0.85, 0), Vector3(0.54, 0.06, 0.32), BANDAGE_DARK],          # a bandage stripe
		[Vector3(0, 1.06, -0.005), Vector3(0.54, 0.08, 0.31), c],                # the sash (level colour)
		[Vector3(0, 1.36, -0.02), Vector3(0.4, 0.34, 0.34), BANDAGE],            # head
		[Vector3(0, 1.3, -0.02), Vector3(0.42, 0.05, 0.36), BANDAGE_DARK],
		[Vector3(-0.09, 1.4, -0.195), Vector3(0.08, 0.06, 0.02), MUMMY_EYES],    # eyes
		[Vector3(0.09, 1.4, -0.195), Vector3(0.08, 0.06, 0.02), MUMMY_EYES],
		[Vector3(-0.33, 1.12, -0.22), Vector3(0.13, 0.13, 0.5), BANDAGE, ARM],   # arms held out
		[Vector3(0.33, 1.12, -0.22), Vector3(0.13, 0.13, 0.5), BANDAGE_DARK, ARM],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.09
		out.append([Vector3(x, 1.6, 0.05), Vector3(0.05, 0.14, 0.05), BANDAGE_DARK, SPIKE])
	return out


## A mummy's half: its top (moved down: it crawls) or its legs. The spikes (its level) stay on the top.
static func _mummy_half(raw: Array, half: int) -> Array:
	if half == MonsterRules.WHOLE:
		return raw
	var out: Array = []
	for b: Array in raw:
		var top := (b[0] as Vector3).y > WAIST
		if half == MonsterRules.HALF_TOP and top:
			var moved := b.duplicate()
			moved[0] = (b[0] as Vector3) - Vector3(0, TOP_DROP, 0)
			out.append(moved)
		elif half == MonsterRules.HALF_LEGS and not top:
			out.append(b)
	if half == MonsterRules.HALF_LEGS:   # a bandaged stump on top, so the legs are not just two sticks
		out.append([Vector3(0, 0.76, 0), Vector3(0.46, 0.1, 0.24), BANDAGE_DARK])
		out.append([Vector3(0, 0.84, 0), Vector3(0.05, 0.1, 0.05), BANDAGE, SPIKE])
	return out


## A scorpion: a shell of its level colour, pincers, six legs, and a curled tail with a stinger (the arm
## that winds up); l spikes along its back.
static func _scorpion(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var d := c.darkened(0.3)
	var out: Array = [
		[Vector3(0, 0.2, 0.05), Vector3(0.5, 0.2, 0.62), c],                     # body
		[Vector3(0, 0.22, -0.32), Vector3(0.36, 0.16, 0.2), d],                  # head
		[Vector3(-0.08, 0.3, -0.42), Vector3(0.06, 0.06, 0.02), BLACK],          # eyes
		[Vector3(0.08, 0.3, -0.42), Vector3(0.06, 0.06, 0.02), BLACK],
		[Vector3(-0.28, 0.18, -0.46), Vector3(0.1, 0.08, 0.22), d],              # pincer arms
		[Vector3(0.28, 0.18, -0.46), Vector3(0.1, 0.08, 0.22), d],
		[Vector3(-0.3, 0.18, -0.62), Vector3(0.16, 0.12, 0.14), c],              # claws
		[Vector3(0.3, 0.18, -0.62), Vector3(0.16, 0.12, 0.14), c],
		[Vector3(0, 0.33, 0.42), Vector3(0.14, 0.12, 0.14), d, ARM],             # tail: up and over
		[Vector3(0, 0.47, 0.46), Vector3(0.13, 0.18, 0.12), c, ARM],
		[Vector3(0, 0.63, 0.4), Vector3(0.12, 0.16, 0.12), d, ARM],
		[Vector3(0, 0.74, 0.3), Vector3(0.11, 0.1, 0.14), c, ARM],
		[Vector3(0, 0.72, 0.19), Vector3(0.06, 0.08, 0.1), STINGER, ARM],        # the stinger
	]
	for side in [-1.0, 1.0]:
		for k in 3:
			out.append([Vector3(side * 0.31, 0.08, -0.12 + k * 0.18), Vector3(0.14, 0.05, 0.05), SHELL_DARK])
	for i in l:
		var z := (i - (l - 1) * 0.5) * 0.11
		out.append([Vector3(0, 0.34, 0.05 + z), Vector3(0.06, 0.08, 0.06), BONE, SPIKE])
	return out


static var _glob: ArrayMesh


## The scorpion's poison glob: a green blob (shared, vertex colours).
static func glob_mesh() -> ArrayMesh:
	if _glob == null:
		_glob = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.26, 0.26, 0.26), GLOB],
			[Vector3(0.05, 0.06, -0.05), Vector3(0.12, 0.12, 0.12), GLOB.lightened(0.4)],
		])
	return _glob


# --- M3 Task 3: Frostpeak's yeti and ice bat -------------------------------------------------------------

const BALL := &"ball"
const FUR := Color("eef3f8")
const FUR_SHADE := Color("c9d6e3")
const YETI_FACE := Color("7f95b0")
const ICICLE := Color("bfeaff")
const SNOWBALL := Color("fbfdff")
const YETI_SHOULDERS := Vector3(0.0, 1.3, 0.0)   # both arms turn here (unscaled)
const BAT_FUR := Color("5d7290")
const BAT_WING := Color("3f4f68")
const BAT_EYES := Color("8ff4ff")
const ICE_GLOW := Color("c8f8ff")    # a bat's wings as it signals its dive
const BAT_SHOULDERS := Vector3(0.0, 0.2, 0.0)


## A big white yeti: a scarf of its level colour, a blue-grey face with little fangs, l icicle spikes on its
## head, and long arms that lift a snowball over its head (the snowball shows only while it winds up).
static func _yeti(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(-0.2, 0.3, 0), Vector3(0.3, 0.6, 0.35), FUR_SHADE],             # legs
		[Vector3(0.2, 0.3, 0), Vector3(0.3, 0.6, 0.35), FUR_SHADE],
		[Vector3(-0.2, 0.04, -0.06), Vector3(0.32, 0.08, 0.45), YETI_FACE],     # big feet
		[Vector3(0.2, 0.04, -0.06), Vector3(0.32, 0.08, 0.45), YETI_FACE],
		[Vector3(0, 0.95, 0), Vector3(0.8, 0.8, 0.55), FUR],                    # body
		[Vector3(0, 0.88, -0.28), Vector3(0.5, 0.52, 0.02), FUR_SHADE],         # belly
		[Vector3(0, 1.33, 0), Vector3(0.84, 0.1, 0.58), c],                     # the scarf (level colour)
		[Vector3(0.3, 1.2, -0.3), Vector3(0.14, 0.26, 0.04), c],                # its end
		[Vector3(0, 1.6, -0.02), Vector3(0.56, 0.46, 0.5), FUR],                # head
		[Vector3(0, 1.57, -0.28), Vector3(0.4, 0.3, 0.02), YETI_FACE],          # face
		[Vector3(-0.09, 1.63, -0.295), Vector3(0.07, 0.07, 0.02), BLACK],       # eyes
		[Vector3(0.09, 1.63, -0.295), Vector3(0.07, 0.07, 0.02), BLACK],
		[Vector3(0, 1.49, -0.295), Vector3(0.16, 0.04, 0.02), BLACK],           # mouth
		[Vector3(-0.05, 1.46, -0.3), Vector3(0.03, 0.04, 0.02), WHITE],         # fangs
		[Vector3(0.05, 1.46, -0.3), Vector3(0.03, 0.04, 0.02), WHITE],
		[Vector3(-0.52, 0.95, 0), Vector3(0.24, 0.7, 0.28), FUR, ARM],          # long arms
		[Vector3(0.52, 0.95, 0), Vector3(0.24, 0.7, 0.28), FUR, ARM],
		[Vector3(-0.52, 0.55, -0.04), Vector3(0.26, 0.14, 0.3), YETI_FACE, ARM],   # hands
		[Vector3(0.52, 0.55, -0.04), Vector3(0.26, 0.14, 0.3), YETI_FACE, ARM],
		[Vector3(0, 0.6, -0.3), Vector3(0.5, 0.5, 0.5), SNOWBALL, BALL],        # the snowball between its hands
		[Vector3(0.08, 0.66, -0.52), Vector3(0.2, 0.16, 0.06), FUR_SHADE, BALL],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.1
		out.append([Vector3(x, 1.9, 0.0), Vector3(0.06, 0.14, 0.06), ICICLE, SPIKE])
	return out


## A small ice bat: a blue-grey body, glowing icy eyes, ears of its level colour, l icicle spikes on its back,
## and two wings (the arm) drawn up (frame 0) or down (frame 1).
static func _bat(l: int, frame: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(0, 0.18, 0), Vector3(0.26, 0.24, 0.3), BAT_FUR],               # body
		[Vector3(0, 0.12, -0.13), Vector3(0.18, 0.08, 0.06), c],                # a belly patch (level colour)
		[Vector3(0, 0.24, -0.2), Vector3(0.22, 0.2, 0.18), BAT_FUR],            # head
		[Vector3(-0.07, 0.38, -0.2), Vector3(0.06, 0.1, 0.04), c],              # ears
		[Vector3(0.07, 0.38, -0.2), Vector3(0.06, 0.1, 0.04), c],
		[Vector3(-0.05, 0.27, -0.295), Vector3(0.05, 0.05, 0.02), BAT_EYES],    # glowing eyes
		[Vector3(0.05, 0.27, -0.295), Vector3(0.05, 0.05, 0.02), BAT_EYES],
		[Vector3(-0.03, 0.17, -0.295), Vector3(0.02, 0.04, 0.02), WHITE],       # fangs
		[Vector3(0.03, 0.17, -0.295), Vector3(0.02, 0.04, 0.02), WHITE],
		[Vector3(0, 0.05, 0.1), Vector3(0.08, 0.06, 0.06), BAT_WING],          # little feet
	]
	var lift := [0.04, 0.1, 0.16] if frame == 0 else [-0.04, -0.1, -0.16]
	for side in [-1.0, 1.0]:
		out.append([Vector3(side * 0.2, 0.2 + lift[0], 0), Vector3(0.16, 0.03, 0.3), BAT_WING, ARM])
		out.append([Vector3(side * 0.34, 0.2 + lift[1], 0.01), Vector3(0.14, 0.03, 0.26), BAT_WING, ARM])
		out.append([Vector3(side * 0.46, 0.2 + lift[2], 0.03), Vector3(0.12, 0.03, 0.18), BAT_WING.lightened(0.15), ARM])
	for i in l:
		var z := (i - (l - 1) * 0.5) * 0.06
		out.append([Vector3(0, 0.33, 0.02 + z), Vector3(0.04, 0.08, 0.04), ICICLE, SPIKE])
	return out


static var _snowball: ArrayMesh


## The yeti's thrown snowball (shared, vertex colours).
static func snowball_mesh() -> ArrayMesh:
	if _snowball == null:
		_snowball = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.42, 0.42, 0.42), SNOWBALL],
			[Vector3(0.08, 0.1, -0.08), Vector3(0.2, 0.2, 0.2), FUR_SHADE.lightened(0.3)],
		])
	return _snowball

# --- M3 Task 4: the Candy Kingdom's gummy bear and candy sneaker -------------------------------------------

const GUMMY_EYES := Color("fbfbfb")
const LICORICE := Color("3a2346")
const LICORICE_DARK := Color("24142e")
const WRAPPER := Color("9b6bc7")
const SNEAKER_EYES := Color("ff7ad9")
const LOLLIPOP_PINK := Color("ff5ca8")
const SPARKLES: Array[Color] = [Color("ffffff"), Color("ffd6f2"), Color("fff3a0"), Color("c9b6ff")]

static var _shimmers := {}


## A gummy bear in its level colour: see-through-looking jelly (a lighter top and belly), round ears, a
## snout, and l sugar crystals on its head.
static func _gummy(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var light := c.lightened(0.35)
	var out: Array = [
		[Vector3(-0.13, 0.1, 0), Vector3(0.16, 0.2, 0.18), c.darkened(0.15)],     # legs
		[Vector3(0.13, 0.1, 0), Vector3(0.16, 0.2, 0.18), c.darkened(0.15)],
		[Vector3(0, 0.38, 0), Vector3(0.46, 0.38, 0.36), c],                      # body
		[Vector3(0, 0.36, -0.185), Vector3(0.26, 0.24, 0.02), light],             # belly
		[Vector3(-0.29, 0.42, -0.02), Vector3(0.12, 0.26, 0.14), c],              # arms
		[Vector3(0.29, 0.42, -0.02), Vector3(0.12, 0.26, 0.14), c],
		[Vector3(0, 0.72, 0), Vector3(0.4, 0.32, 0.34), c],                       # head
		[Vector3(0, 0.87, 0), Vector3(0.36, 0.03, 0.3), light],                   # a shiny top
		[Vector3(-0.15, 0.92, 0), Vector3(0.12, 0.12, 0.1), c],                   # ears
		[Vector3(0.15, 0.92, 0), Vector3(0.12, 0.12, 0.1), c],
		[Vector3(0, 0.66, -0.2), Vector3(0.16, 0.1, 0.06), light],                # snout
		[Vector3(0, 0.69, -0.235), Vector3(0.06, 0.04, 0.02), BLACK],             # nose
		[Vector3(-0.09, 0.76, -0.175), Vector3(0.08, 0.08, 0.02), GUMMY_EYES],    # eyes
		[Vector3(0.09, 0.76, -0.175), Vector3(0.08, 0.08, 0.02), GUMMY_EYES],
		[Vector3(-0.09, 0.75, -0.185), Vector3(0.04, 0.05, 0.02), BLACK],
		[Vector3(0.09, 0.75, -0.185), Vector3(0.04, 0.05, 0.02), BLACK],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.045
		out.append([Vector3(x, 0.92, 0.05), Vector3(0.04, 0.08, 0.04), BONE, SPIKE])
	return out


## A candy sneaker: a wrapped licorice sweet on thin legs, the wrapper twisted out at its sides, a sash of its
## level colour, glowing pink eyes, l wrapper spikes on its head and a lollipop (the arm that winds up).
static func _sneaker(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(-0.12, 0.19, 0), Vector3(0.12, 0.38, 0.14), LICORICE_DARK],      # legs
		[Vector3(0.12, 0.19, 0), Vector3(0.12, 0.38, 0.14), LICORICE_DARK],
		[Vector3(0, 0.62, 0), Vector3(0.46, 0.5, 0.36), LICORICE],                # the wrapped body
		[Vector3(0, 0.62, -0.005), Vector3(0.48, 0.08, 0.37), c],                 # the sash (level colour)
		[Vector3(-0.3, 0.62, 0), Vector3(0.14, 0.2, 0.1), WRAPPER],               # wrapper twists
		[Vector3(0.3, 0.62, 0), Vector3(0.14, 0.2, 0.1), WRAPPER],
		[Vector3(-0.4, 0.62, 0), Vector3(0.06, 0.3, 0.08), WRAPPER.lightened(0.2)],
		[Vector3(0.4, 0.62, 0), Vector3(0.06, 0.3, 0.08), WRAPPER.lightened(0.2)],
		[Vector3(0, 1.02, 0), Vector3(0.36, 0.3, 0.32), LICORICE],                # head
		[Vector3(-0.08, 1.06, -0.165), Vector3(0.08, 0.05, 0.02), SNEAKER_EYES],  # eyes
		[Vector3(0.08, 1.06, -0.165), Vector3(0.08, 0.05, 0.02), SNEAKER_EYES],
		[Vector3(0, 0.95, -0.165), Vector3(0.12, 0.03, 0.02), LICORICE_DARK],     # a sly grin
		[Vector3(0.3, 0.66, 0), Vector3(0.1, 0.34, 0.12), LICORICE_DARK],         # left arm
		[Vector3(-0.3, 0.66, 0), Vector3(0.1, 0.34, 0.12), LICORICE_DARK, ARM],   # right arm and its lollipop
		[Vector3(-0.3, 0.5, -0.16), Vector3(0.05, 0.05, 0.28), BONE, ARM],
		[Vector3(-0.3, 0.5, -0.36), Vector3(0.26, 0.26, 0.05), LOLLIPOP_PINK, ARM],
		[Vector3(-0.3, 0.5, -0.39), Vector3(0.12, 0.12, 0.02), WHITE, ARM],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.07
		out.append([Vector3(x, 1.22, 0.02), Vector3(0.04, 0.12, 0.04), WRAPPER.lightened(0.3), SPIKE])
	return out


## What shows of a candy sneaker in the dark near a player (and while it winds up): its glowing eyes and
## sparkles round its shape (shared per level, vertex colours). Universe 6: a spore puff's own (its glowing spots
## and tufts, its eyes): puff_shimmer.
static func shimmer_mesh(level: int, kind: StringName = MonsterRules.SNEAKER) -> ArrayMesh:
	if kind == MonsterRules.SPORE_PUFF:
		return puff_shimmer(level)
	var l := MonsterRules.level_of(level)
	if not _shimmers.has(l):
		var s := MonsterRules.size_scale(l)
		var boxes: Array = [
			[Vector3(-0.08, 1.06, -0.17) * s, Vector3(0.09, 0.06, 0.02) * s, SNEAKER_EYES],
			[Vector3(0.08, 1.06, -0.17) * s, Vector3(0.09, 0.06, 0.02) * s, SNEAKER_EYES],
		]
		var spots: Array[Vector3] = [Vector3(-0.26, 0.9, 0.0), Vector3(0.26, 0.85, 0.05), Vector3(-0.2, 0.4, -0.1),
			Vector3(0.22, 0.35, 0.1), Vector3(0.0, 1.25, 0.0), Vector3(-0.42, 0.62, 0.0), Vector3(0.42, 0.6, 0.0),
			Vector3(0.1, 0.1, -0.1), Vector3(-0.12, 0.08, 0.1), Vector3(0.0, 0.7, 0.22), Vector3(0.18, 1.12, 0.1),
			Vector3(-0.18, 1.1, -0.1), Vector3(0.0, 0.55, -0.22), Vector3(-0.3, 0.2, 0.0)]
		for i in spots.size():
			boxes.append([spots[i] * s, Vector3.ONE * 0.06 * s, SPARKLES[i % SPARKLES.size()]])
		_shimmers[l] = BlockyAnimal._build(boxes)
	return _shimmers[l]

# --- M3 Task 14b: the goblin archer ---------------------------------------------------------------------

const ARCHER_AIM := 1.5           # the bow arm comes up level (radians)
const HOOD := Color("4e5d2e")
const ARROW_GLOW := Color("fff6b0")
const FLETCH := Color("ff3b30")


## A goblin archer: the goblin (tunic of its level colour, l horns) in a green hood, a quiver on its back,
## and a bow in its right hand (the arm that winds up: level when it aims). The nocked arrow with its glowing
## tip shows only while it aims (BALL, like the yeti's snowball): the child sees it coming a second early.
static func _archer(l: int) -> Array:
	var out: Array = []
	for b: Array in _goblin(l):
		if b.size() > 3 and b[3] == ARM:
			continue                                                                  # no club
		out.append(b)
	var skin := GOBLIN_SKIN
	out.append_array([
		[Vector3(0, 1.21, 0.03), Vector3(0.44, 0.1, 0.4), HOOD],                        # hood
		[Vector3(0, 1.06, 0.2), Vector3(0.42, 0.3, 0.04), HOOD],
		[Vector3(0.1, 0.72, 0.2), Vector3(0.12, 0.36, 0.1), WOOD],                     # quiver
		[Vector3(0.1, 0.93, 0.2), Vector3(0.1, 0.06, 0.08), FLETCH],
		[Vector3(-0.3, 0.66, 0), Vector3(0.1, 0.36, 0.12), skin, ARM],                 # the bow arm
		[Vector3(-0.3, 0.47, -0.17), Vector3(0.04, 0.05, 0.26), WOOD_DARK, ARM],       # bow limbs (along z at rest)
		[Vector3(-0.3, 0.47, 0.17), Vector3(0.04, 0.05, 0.26), WOOD_DARK, ARM],
		[Vector3(-0.3, 0.5, -0.31), Vector3(0.04, 0.08, 0.04), WOOD, ARM],             # tips curving back
		[Vector3(-0.3, 0.5, 0.31), Vector3(0.04, 0.08, 0.04), WOOD, ARM],
		[Vector3(-0.3, 0.53, 0), Vector3(0.012, 0.012, 0.6), WHITE, ARM],              # the string
		[Vector3(-0.3, 0.42, 0), Vector3(0.035, 0.24, 0.035), WOOD, BALL],             # the nocked arrow ...
		[Vector3(-0.3, 0.29, 0), Vector3(0.08, 0.07, 0.08), ARROW_GLOW, BALL],         # ... its glowing tip
		[Vector3(-0.3, 0.54, 0), Vector3(0.1, 0.04, 0.02), FLETCH, BALL],
	])
	return out

# --- Owner #39: the Dragon Realm's shadow bat and wisp spirit ---------------------------------------------------
# Glowing is bright vertex colour on the one shared material (a new or emissive material would compile a shader:
# DEVELOPMENT.md §8). A shadow bat's signal is its wing flare and lit eyes (its lit arm mesh, like the ice bat's);
# a wisp's is a lit body (a second shared body mesh) and a ring that grows round the orb (BALL boxes of its arm).

const SHADOW_FUR := Color("3a2856")      # dark violet: hard to make out at night ...
const SHADOW_WING := Color("2b1d42")
const SHADOW_WING_EDGE := Color("4a3570")
const SHADOW_EYES := Color("e2b8ff")     # ... but its eyes always glow lilac
const SHADOW_EYES_LIT := Color("fff4ff")  # brighter still as it signals a swoop
const SHADOW_FLARE := Color("c9a2ff")    # its wings flare lilac as it signals
const WISP_CORE := Vector3(0.0, 0.3, 0.0)   # the orb's middle (unscaled): the ring grows round it
const WISP_LIGHT := Color("fffbe8")      # a wisp's light as it winds up (its ring, its trail)
const WISP_FACE := Color("4a3a6a")
const WISP_BLUSH := Color("ffb3c8")
## The colour a lit arm glows towards (the ice bat's icy wings, the scorpion's tail by default).
const GLOWS := {MonsterRules.ICE_BAT: ICE_GLOW, MonsterRules.SHADOW_BAT: SHADOW_FLARE, MonsterRules.WISP: WISP_LIGHT,
	MonsterRules.SPORE_PUFF: SPORE_GLOW, MonsterRules.CRAWLER: SPORE_GLOW}

static var _wisp_lit := {}
static var _spark: ArrayMesh


## A small shadow bat: a dark-violet body and round head, lilac glowing eyes (in the arm mesh, so they light up with
## its wings as it signals), ear tips and a belly patch of its level colour, l soft tufts on its back, and two soft
## wings (the arm) up (frame 0) or down (frame 1).
static func _shadow_bat(l: int, frame: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(0, 0.18, 0), Vector3(0.26, 0.24, 0.3), SHADOW_FUR],              # body
		[Vector3(0, 0.12, -0.14), Vector3(0.16, 0.08, 0.04), c],                  # a belly patch (level colour)
		[Vector3(0, 0.25, -0.19), Vector3(0.24, 0.19, 0.18), SHADOW_FUR],         # a round head
		[Vector3(0, 0.25, -0.19), Vector3(0.19, 0.24, 0.15), SHADOW_FUR],
		[Vector3(-0.08, 0.39, -0.19), Vector3(0.07, 0.1, 0.04), SHADOW_FUR],      # ears ...
		[Vector3(0.08, 0.39, -0.19), Vector3(0.07, 0.1, 0.04), SHADOW_FUR],
		[Vector3(-0.08, 0.45, -0.19), Vector3(0.05, 0.03, 0.04), c],              # ... with tips of its level colour
		[Vector3(0.08, 0.45, -0.19), Vector3(0.05, 0.03, 0.04), c],
		[Vector3(-0.055, 0.275, -0.3), Vector3(0.025, 0.035, 0.02), BLACK],       # pupils (over the glowing eyes)
		[Vector3(0.055, 0.275, -0.3), Vector3(0.025, 0.035, 0.02), BLACK],
		[Vector3(0, 0.2, -0.285), Vector3(0.07, 0.02, 0.02), SHADOW_WING_EDGE],   # a little smile
		[Vector3(0, 0.05, 0.1), Vector3(0.08, 0.06, 0.06), SHADOW_WING],          # little feet
		[Vector3(-0.055, 0.28, -0.29), Vector3(0.07, 0.07, 0.02), SHADOW_EYES, ARM],   # glowing eyes
		[Vector3(0.055, 0.28, -0.29), Vector3(0.07, 0.07, 0.02), SHADOW_EYES, ARM],
	]
	var lift := [0.04, 0.1, 0.15] if frame == 0 else [-0.04, -0.1, -0.15]
	for side in [-1.0, 1.0]:
		out.append([Vector3(side * 0.2, 0.2 + lift[0], 0), Vector3(0.16, 0.03, 0.3), SHADOW_WING, ARM])
		out.append([Vector3(side * 0.34, 0.2 + lift[1], 0.01), Vector3(0.14, 0.03, 0.28), SHADOW_WING, ARM])
		out.append([Vector3(side * 0.46, 0.2 + lift[2], 0.03), Vector3(0.12, 0.03, 0.2), SHADOW_WING, ARM])
		out.append([Vector3(side * 0.36, 0.2 + lift[1], 0.16), Vector3(0.26, 0.025, 0.05), SHADOW_WING_EDGE, ARM])   # a soft edge
	for i in l:
		var z := (i - (l - 1) * 0.5) * 0.06
		out.append([Vector3(0, 0.33, 0.02 + z), Vector3(0.04, 0.07, 0.04), SHADOW_WING, SPIKE])
	return out


## A wisp spirit: a glowing orb of its level colour's pastel with a tiny face (eyes, a smile, blushing cheeks), a
## glowing band of its level colour, l little flames on top and a soft trail behind (the arm); while it winds up
## the arm also shows a ring round the orb (BALL) that grows.
static func _wisp(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var pastel := c.lerp(WHITE, 0.55)
	var out: Array = [
		[Vector3(0, 0.3, 0), Vector3(0.36, 0.36, 0.36), pastel],                 # the orb, rounded by three boxes
		[Vector3(0, 0.3, 0), Vector3(0.42, 0.26, 0.26), pastel],
		[Vector3(0, 0.3, 0), Vector3(0.26, 0.42, 0.26), pastel],
		[Vector3(0, 0.3, 0), Vector3(0.26, 0.26, 0.42), pastel],
		[Vector3(0, 0.19, 0), Vector3(0.4, 0.05, 0.4), c],                       # a glowing band (level colour)
		[Vector3(-0.07, 0.34, -0.215), Vector3(0.05, 0.06, 0.02), WISP_FACE],    # eyes
		[Vector3(0.07, 0.34, -0.215), Vector3(0.05, 0.06, 0.02), WISP_FACE],
		[Vector3(0, 0.26, -0.215), Vector3(0.08, 0.02, 0.02), WISP_FACE],        # a smile
		[Vector3(-0.13, 0.28, -0.213), Vector3(0.04, 0.03, 0.02), WISP_BLUSH],   # cheeks
		[Vector3(0.13, 0.28, -0.213), Vector3(0.04, 0.03, 0.02), WISP_BLUSH],
		[Vector3(0, 0.27, 0.26), Vector3(0.2, 0.2, 0.12), pastel.lerp(WHITE, 0.3), ARM],    # the trail
		[Vector3(0, 0.23, 0.38), Vector3(0.14, 0.14, 0.12), pastel.lerp(WHITE, 0.5), ARM],
		[Vector3(0, 0.2, 0.49), Vector3(0.09, 0.09, 0.1), pastel.lerp(WHITE, 0.7), ARM],
		[Vector3(0, 0.18, 0.58), Vector3(0.05, 0.05, 0.08), WHITE, ARM],
	]
	for i in 12:                                                                      # the ring (winding up only)
		var a := i * TAU / 12.0
		out.append([Vector3(cos(a) * 0.4, 0.3 + sin(a) * 0.4, -0.04), Vector3(0.09, 0.09, 0.04), WISP_LIGHT, BALL])
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.07
		out.append([Vector3(x, 0.53, 0), Vector3(0.05, 0.1, 0.05), pastel.lerp(WHITE, 0.6), SPIKE])
	return out


## A wisp's body, calm or lit (as it winds up: its pastel brighter), one shared mesh each per level.
static func wisp_body(level: int, lit: bool) -> ArrayMesh:
	if not lit:
		return mesh_for(MonsterRules.WISP, level)
	var l := MonsterRules.level_of(level)
	if not _wisp_lit.has(l):
		var body: Array = []
		for b: Array in boxes(MonsterRules.WISP, l):
			if b[3] != ARM and b[3] != BALL:
				var col: Color = b[2]
				body.append([b[0], b[1], col if col == WISP_FACE or col == WISP_BLUSH else col.lerp(WISP_LIGHT, 0.5)])
		_wisp_lit[l] = BlockyAnimal._build(body)
	return _wisp_lit[l]


## A wisp's spark (shared, vertex colours): a small bright core in a soft glow.
static func spark_mesh() -> ArrayMesh:
	if _spark == null:
		_spark = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.22, 0.22, 0.22), Color("ffe9a8")],
			[Vector3.ZERO, Vector3(0.12, 0.3, 0.12), WISP_LIGHT],
			[Vector3.ZERO, Vector3(0.3, 0.12, 0.12), WISP_LIGHT],
		])
	return _spark

# --- Universe 6: the Glow Caves' spore puff and cave crawler ------------------------------------------------------

const PUFF_SKIN := Color("e3d8f6")       # a pale lilac puffball
const PUFF_LIGHT := Color("f6f0ff")
const PUFF_STALK := Color("d4c6e6")
const SPORE_GLOW := Color("7dffd6")      # glowing spores and spots (teal): what shows in the dark
const PUFF_BLUSH := Color("ff9fc2")
const PUFF_HINGE := Vector3(0.0, 0.46, 0.24)    # the back of its cap: it lifts there as it swells (unscaled)
const CRAWLER_SHELL := Color("3f5d86")   # a blue cave beetle
const CRAWLER_SHELL_LIGHT := Color("6f8fbd")
const CRAWLER_HEAD := Color("5876a3")
const CRAWLER_LEGS := Color("2c3f5c")
const FEELER_ROOT := Vector3(0.0, 0.28, -0.5)   # where its feelers leave its head (unscaled)

static var _puff_shimmers := {}


## A spore puff: a round puffball on a short stalk (a stepped dome, never a cube), a band of its level colour round its
## middle, big friendly eyes, pink cheeks and a smile, glowing teal spots, l glowing spore tufts on top; its cap's top
## (the arm) lifts at the back as it swells, its spots glowing brighter (the lit arm).
static func _spore_puff(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(0, 0.07, 0), Vector3(0.34, 0.14, 0.34), PUFF_STALK],              # its short stalk
		[Vector3(0, 0.3, 0), Vector3(0.66, 0.32, 0.62), PUFF_SKIN],                # the puffball
		[Vector3(0, 0.3, 0), Vector3(0.68, 0.07, 0.64), c],                        # a band of its level colour
		[Vector3(-0.11, 0.36, -0.315), Vector3(0.12, 0.13, 0.02), WHITE],          # eyes
		[Vector3(0.11, 0.36, -0.315), Vector3(0.12, 0.13, 0.02), WHITE],
		[Vector3(-0.1, 0.35, -0.327), Vector3(0.06, 0.08, 0.02), BLACK],
		[Vector3(0.1, 0.35, -0.327), Vector3(0.06, 0.08, 0.02), BLACK],
		[Vector3(-0.08, 0.385, -0.335), Vector3(0.025, 0.025, 0.01), WHITE],       # a glint in each eye
		[Vector3(0.12, 0.385, -0.335), Vector3(0.025, 0.025, 0.01), WHITE],
		[Vector3(0, 0.22, -0.315), Vector3(0.1, 0.03, 0.02), BLACK],               # a smile
		[Vector3(-0.22, 0.25, -0.313), Vector3(0.07, 0.04, 0.02), PUFF_BLUSH],     # cheeks
		[Vector3(0.22, 0.25, -0.313), Vector3(0.07, 0.04, 0.02), PUFF_BLUSH],
		[Vector3(-0.3, 0.28, 0.12), Vector3(0.04, 0.06, 0.06), SPORE_GLOW],        # glowing spots on its sides
		[Vector3(0.3, 0.32, -0.1), Vector3(0.04, 0.06, 0.06), SPORE_GLOW],
		[Vector3(0.2, 0.22, 0.31), Vector3(0.06, 0.06, 0.02), SPORE_GLOW],
		[Vector3(0, 0.52, 0), Vector3(0.52, 0.14, 0.5), PUFF_SKIN, ARM],          # the cap's top (lifts as it swells)
		[Vector3(0, 0.62, 0), Vector3(0.32, 0.08, 0.3), PUFF_LIGHT, ARM],
		[Vector3(-0.16, 0.58, -0.16), Vector3(0.06, 0.04, 0.06), SPORE_GLOW, ARM],
		[Vector3(0.17, 0.57, 0.12), Vector3(0.06, 0.04, 0.06), SPORE_GLOW, ARM],
	]
	for i in l:
		var x := (i - (l - 1) * 0.5) * 0.08
		out.append([Vector3(x, 0.7, 0.0), Vector3(0.05, 0.09, 0.05), SPORE_GLOW, SPIKE])
	return out


## What shows of a spore puff in the dark a little way off (and while it swells): its glowing spots and tufts, and the
## whites of its eyes (shared per level).
static func puff_shimmer(level: int) -> ArrayMesh:
	var l := MonsterRules.level_of(level)
	if not _puff_shimmers.has(l):
		var s := MonsterRules.size_scale(l)
		var out: Array = []
		for b: Array in boxes(MonsterRules.SPORE_PUFF, l):
			if b[2] == SPORE_GLOW or b[2] == WHITE:
				out.append([b[0], b[1], b[2]])
		for p: Vector3 in [Vector3(-0.36, 0.45, 0.0), Vector3(0.36, 0.4, 0.05), Vector3(0.0, 0.8, 0.05),
				Vector3(-0.2, 0.62, 0.22), Vector3(0.24, 0.12, -0.2)]:
			out.append([p * s, Vector3.ONE * 0.05 * s, SPORE_GLOW.lightened(0.3)])
		_puff_shimmers[l] = BlockyAnimal._build(out)
	return _puff_shimmers[l]


## A cave crawler: a blind blue cave beetle (no eyes: real cave beetles are often blind) with a rounded shell, a stripe
## of its level colour down its back, six little legs, a smiling head with pink cheeks, l pale nubs along its shell, and
## two long feelers with glowing tips (the arm: they go up as it signals, glowing brighter).
static func _crawler(l: int) -> Array:
	var c := MonsterRules.level_color(l)
	var out: Array = [
		[Vector3(0, 0.24, 0.06), Vector3(0.62, 0.24, 0.76), CRAWLER_SHELL],        # the shell
		[Vector3(0, 0.38, 0.08), Vector3(0.44, 0.06, 0.6), CRAWLER_SHELL_LIGHT],   # its rounded top
		[Vector3(0, 0.415, 0.08), Vector3(0.1, 0.02, 0.62), c],                    # a stripe of its level colour
		[Vector3(0, 0.2, -0.41), Vector3(0.36, 0.22, 0.2), CRAWLER_HEAD],          # the head (no eyes: blind)
		[Vector3(0, 0.15, -0.513), Vector3(0.12, 0.025, 0.02), BLACK],             # a smile
		[Vector3(-0.12, 0.21, -0.512), Vector3(0.06, 0.04, 0.02), PUFF_BLUSH],     # cheeks
		[Vector3(0.12, 0.21, -0.512), Vector3(0.06, 0.04, 0.02), PUFF_BLUSH],
		[Vector3(-0.08, 0.31, -0.62), Vector3(0.03, 0.03, 0.26), CRAWLER_LEGS, ARM],   # its feelers
		[Vector3(0.08, 0.31, -0.62), Vector3(0.03, 0.03, 0.26), CRAWLER_LEGS, ARM],
		[Vector3(-0.08, 0.31, -0.77), Vector3(0.07, 0.07, 0.07), SPORE_GLOW, ARM],     # their glowing tips
		[Vector3(0.08, 0.31, -0.77), Vector3(0.07, 0.07, 0.07), SPORE_GLOW, ARM],
	]
	for z: float in [-0.2, 0.06, 0.32]:                                          # six little legs
		out.append([Vector3(-0.36, 0.07, z), Vector3(0.14, 0.06, 0.06), CRAWLER_LEGS])
		out.append([Vector3(0.36, 0.07, z), Vector3(0.14, 0.06, 0.06), CRAWLER_LEGS])
	for i in l:
		var z := (i - (l - 1) * 0.5) * 0.12 + 0.08
		out.append([Vector3(0.0, 0.45, z), Vector3(0.06, 0.06, 0.06), BONE, SPIKE])
	return out
