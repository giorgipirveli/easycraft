class_name AlienModels
extends RefCounted
## The friendly aliens and their places, our own designs (owner #86, spec §21f, §3c: bright, round and friendly, never
## scary; no grey skin, no dark almond eyes). Every model faces -Z, stands on y = 0 and is one cached mesh
## (CreatureLook); ground-touching parts reach a block below y = 0 so a camp on ground a block lower never floats.
## - An alien (~1.7 tall): little legs, a round bean body with a pale belly, a big round head with two big shiny eyes,
##   rosy cheeks and a smile, two antennae with glowing tips; an explorer wears a belt with a star badge, a trader an
##   apron with a pocket, a chief a little crown, a villager a scarf. Its right arm waves (arm()).
## - A mini (an alien buddy, MagicPetModels): the same look, tiny (under 1 block).
## - The explorers' camp: a small round ship on three legs with a glass dome, a ring of lights and a ramp; the trader's
##   table with its souvenirs; a telescope pointing at the sky (they keep looking); a lamp post (no campfire: a fire
##   needs air, and these worlds have none to breathe).
## - A village: round homes (Planet Boing's mushroom huts, Rainbow Planet's striped cone huts) and four drum pads.

const EYE_WHITE := Color("ffffff")
const PUPIL := Color("2a2340")
const MOUTH := Color("5b2a44")
const CHEEK := Color("ff9ab8")
const GOLD := Color("ffd23f")
const PEARL := Color("f3f1ea")
const GLASS := Color("bfe9ff")
const LEG_GREY := Color("9aa3ad")
const WOOD := Color("a0703f")
const SHOULDER := Vector3(0.36, 0.72, 0.0)
const PAD_COLORS: Array[Color] = [Color("ff5a5a"), Color("ffd23f"), Color("5ad17a"), Color("4d96ff")]
## The drum pads' size (where they stand: AlienRules.PAD_SPOTS).
const PAD_R := 0.62
const PAD_TOP := 0.2


## Alien `id`'s body (its waving arm is arm()).
static func body(id: StringName) -> ArrayMesh:
	return CreatureLook.mesh("alien_%s" % id, body_parts(id))


static func body_parts(id: StringName, straight: bool = false) -> Array:
	var a := CreatureWords.alien(id)
	var cols: Array = a.get("colors", [Color("8ee6b8"), Color("e3fff0"), Color("f28c28"), Color("ff5c8a")])
	var skin: Color = cols[0]
	var belly: Color = cols[1]
	var suit: Color = cols[2]
	var tip: Color = cols[3]
	var dark := skin.darkened(0.25)
	var face := -0.33
	var parts: Array = [
		[Vector3(-0.13, 0.12, 0), Vector3(0.16, 0.24, 0.18), suit],                 # little legs
		[Vector3(0.13, 0.12, 0), Vector3(0.16, 0.24, 0.18), suit],
		[Vector3(-0.13, 0.04, -0.03), Vector3(0.19, 0.09, 0.25), suit.darkened(0.2)],   # feet
		[Vector3(0.13, 0.04, -0.03), Vector3(0.19, 0.09, 0.25), suit.darkened(0.2)],
		[Vector3(0, 0.5, 0), Vector3(0.58, 0.48, 0.44), skin],                     # a round bean body
		[Vector3(0, 0.5, 0), Vector3(0.48, 0.58, 0.38), skin],
		[Vector3(0, 0.47, -0.225), Vector3(0.32, 0.3, 0.02), belly],               # a pale belly
		[Vector3(-0.36, 0.54, 0), Vector3(0.13, 0.32, 0.15), skin],                 # the left arm
		[Vector3(-0.36, 0.35, 0), Vector3(0.15, 0.11, 0.15), belly],
	]
	parts.append_array([
		[Vector3(0, 1.08, 0), Vector3(0.74, 0.56, 0.6), skin],                      # a big round head
		[Vector3(0, 1.08, 0), Vector3(0.6, 0.68, 0.5), skin],
		[Vector3(0, 1.08, 0), Vector3(0.66, 0.62, 0.66), skin, Basis(Vector3.UP, PI / 4.0)],
		[Vector3(-0.15, 1.13, face), Vector3(0.21, 0.24, 0.02), EYE_WHITE],         # big round eyes
		[Vector3(0.15, 1.13, face), Vector3(0.21, 0.24, 0.02), EYE_WHITE],
		[Vector3(-0.14, 1.11, face - 0.012), Vector3(0.11, 0.13, 0.01), PUPIL],
		[Vector3(0.14, 1.11, face - 0.012), Vector3(0.11, 0.13, 0.01), PUPIL],
		[Vector3(-0.11, 1.15, face - 0.02), Vector3(0.04, 0.04, 0.01), EYE_WHITE],   # the shine in them
		[Vector3(0.17, 1.15, face - 0.02), Vector3(0.04, 0.04, 0.01), EYE_WHITE],
		[Vector3(0, 0.93, face), Vector3(0.18, 0.04, 0.01), MOUTH],                 # a smile
		[Vector3(-0.1, 0.95, face), Vector3(0.04, 0.04, 0.01), MOUTH],
		[Vector3(0.1, 0.95, face), Vector3(0.04, 0.04, 0.01), MOUTH],
		[Vector3(-0.26, 0.98, face + 0.005), Vector3(0.09, 0.05, 0.01), CHEEK],     # rosy cheeks
		[Vector3(0.26, 0.98, face + 0.005), Vector3(0.09, 0.05, 0.01), CHEEK],
	])
	for side: float in [-1.0, 1.0]:   # two antennae with glowing tips
		var lean := Basis.IDENTITY if straight else Basis(Vector3.BACK, -side * 0.28)
		parts.append([Vector3(side * 0.17, 1.52, 0), Vector3(0.05, 0.28, 0.05), dark, lean])
		parts.append([Vector3(side * (0.17 if straight else 0.21), 1.68, 0), Vector3(0.13, 0.13, 0.13), tip])
	match a.get("role", &""):
		&"explorer":
			parts.append([Vector3(0, 0.34, 0), Vector3(0.6, 0.07, 0.46), suit])              # a belt ...
			parts.append([Vector3(0.13, 0.62, -0.235), Vector3(0.1, 0.1, 0.02), GOLD])       # ... a star badge
			parts.append([Vector3(0, 0.46, 0.25), Vector3(0.34, 0.3, 0.14), suit.lightened(0.2)])   # a backpack
		&"trader":
			parts.append([Vector3(0, 0.42, -0.235), Vector3(0.38, 0.36, 0.02), suit])        # an apron ...
			parts.append([Vector3(0, 0.38, -0.25), Vector3(0.16, 0.1, 0.01), GOLD])          # ... with a pocket
		&"chief":
			parts.append([Vector3(0, 1.42, 0), Vector3(0.42, 0.1, 0.42), GOLD])              # a little crown
			for x: float in [-0.15, 0.0, 0.15]:
				parts.append([Vector3(x, 1.5, -0.15), Vector3(0.07, 0.1, 0.05), GOLD])
			parts.append([Vector3(0, 0.34, 0), Vector3(0.6, 0.07, 0.46), suit])
		&"villager":
			parts.append([Vector3(0, 0.76, 0), Vector3(0.52, 0.09, 0.42), suit])             # a scarf
			parts.append([Vector3(0.14, 0.64, -0.2), Vector3(0.1, 0.2, 0.04), suit])
	return parts


## The waving arm of alien `id`: it hangs from its shoulder (SHOULDER); turned round z it waves.
static func arm(id: StringName) -> ArrayMesh:
	var cols: Array = CreatureWords.alien(id).get("colors", [Color("8ee6b8"), Color("e3fff0")])
	return CreatureLook.mesh("alien_arm_%s" % id, [
		[Vector3(0, -0.16, 0), Vector3(0.13, 0.32, 0.15), cols[0]],
		[Vector3(0, -0.35, 0), Vector3(0.15, 0.11, 0.15), cols[1]],
	])


## An alien buddy's tiny look (MagicPetModels: the animals' boxes, no turned ones), under 1 block tall.
static func mini_boxes(id: StringName) -> Array:
	var parts := body_parts(id, true)
	var cols: Array = CreatureWords.alien(id).get("colors", [Color("8ee6b8"), Color("e3fff0")])
	parts.append([SHOULDER + Vector3(0, -0.16, 0), Vector3(0.13, 0.32, 0.15), cols[0]])   # its right arm, resting
	parts.append([SHOULDER + Vector3(0, -0.35, 0), Vector3(0.15, 0.11, 0.15), cols[1]])
	var scale := MagicPetModels.HEIGHT / 1.75
	var out: Array = []
	for p: Array in parts:
		if p.size() > 3:
			continue   # the head's diamond: the pets' boxes are never turned
		out.append([(p[0] as Vector3) * scale, (p[1] as Vector3) * scale, p[2]])
	return out


# --- The explorers' camp --------------------------------------------------------------------------------------------

## The camp of world u (its ship, the trader's table, the telescope, the lamp) round its middle, facing -Z.
static func camp(u: int) -> ArrayMesh:
	return CreatureLook.mesh("alien_camp_%d" % u, camp_parts(u))


## Where the camp's aliens stand, round its middle: the trader behind its table, the explorer by the telescope.
const TRADER_SPOT := Vector3(-2.6, 0, -0.25)
const EXPLORER_SPOT := Vector3(2.0, 0, -1.2)
const TABLE_SPOT := Vector3(-2.6, 0, -1.0)
const SHIP_SPOT := Vector3(0.6, 0, 3.8)
const SHIP_SCALE := 1.4
const TELESCOPE_SPOT := Vector3(3.3, 0, 0.2)
const LAMP_SPOT := Vector3(-0.4, 0, -2.6)


static func camp_parts(u: int) -> Array:
	var c := CreatureWords.camp(u)
	var e: Array = CreatureWords.alien(c.get("explorer", &"")).get("colors", [Color("8ee6b8")])
	var t: Array = CreatureWords.alien(c.get("trader", &"")).get("colors", [Color("ffc59e"), Color("fff0e3"), Color("e05a8a")])
	var parts: Array = CreatureLook.placed(CreatureLook.scaled(ship_parts(e[0], t[0]), SHIP_SCALE), SHIP_SPOT, PI)   # its ramp towards the camp
	parts.append_array(CreatureLook.placed(table_parts(t[2], CreatureWords.alien(c.get("trader", &"")).get("souvenirs", [])),
		TABLE_SPOT, 0.0))
	parts.append_array(CreatureLook.placed(telescope_parts(), TELESCOPE_SPOT, -0.5))
	parts.append_array(CreatureLook.placed(lamp_parts(), LAMP_SPOT, 0.0))
	return parts


## A small round ship on three legs (facing -Z: its door and ramp in front).
static func ship_parts(trim: Color, lights: Color) -> Array:
	var parts: Array = []
	for i in 3:   # three legs, each reaching a block into the ground, with round feet
		var a := PI / 2.0 + TAU * i / 3.0
		var at := Vector3(cos(a) * 1.25, 0, sin(a) * 1.25)
		parts.append([at + Vector3(0, 0.1, 0), Vector3(0.14, 2.2, 0.14), LEG_GREY])
		parts.append([at + Vector3(0, 0.04, 0), Vector3(0.42, 0.08, 0.42), LEG_GREY.darkened(0.2)])
	parts.append_array(CreatureLook.round_box(Vector3(0, 1.0, 0), 1.0, 0.3, trim))       # the belly
	parts.append_array(CreatureLook.round_box(Vector3(0, 1.45, 0), 1.6, 0.66, PEARL))   # the round hull
	parts.append_array(CreatureLook.round_box(Vector3(0, 2.02, 0), 0.75, 0.56, GLASS))  # the glass dome
	parts.append_array(CreatureLook.round_box(Vector3(0, 2.36, 0), 0.4, 0.2, GLASS))
	for i in 8:   # a ring of lights round the hull
		var a := TAU * i / 8.0
		var col := lights if i % 2 == 0 else trim.lightened(0.3)
		parts.append([Vector3(cos(a) * 1.62, 1.45, sin(a) * 1.62), Vector3(0.24, 0.2, 0.24), col])
	parts.append_array([
		[Vector3(0, 2.62, 0), Vector3(0.06, 0.44, 0.06), LEG_GREY],                 # its antenna ...
		[Vector3(0, 2.88, 0), Vector3(0.16, 0.16, 0.16), GOLD],                     # ... with a star light
		[Vector3(0, 1.42, -1.62), Vector3(0.7, 0.62, 0.06), trim.darkened(0.35)],   # the door
		[Vector3(0, 0.62, -2.15), Vector3(0.66, 0.06, 1.35), trim, Basis(Vector3.RIGHT, -0.62)],   # the ramp
		[Vector3(-0.4, 1.6, -1.55), Vector3(0.22, 0.22, 0.04), GLASS],              # two round windows
		[Vector3(0.4, 1.6, -1.55), Vector3(0.22, 0.22, 0.04), GLASS],
	])
	return parts


## The trader's table with a cloth in its colour and its souvenirs on top.
static func table_parts(cloth: Color, souvenirs: Array) -> Array:
	var parts: Array = [
		[Vector3(0, 0.74, 0), Vector3(1.5, 0.08, 0.72), WOOD.lightened(0.15)],
		[Vector3(0, 0.6, -0.365), Vector3(1.52, 0.26, 0.02), cloth],
		[Vector3(-0.72, 0.6, 0), Vector3(0.02, 0.26, 0.72), cloth],
		[Vector3(0.72, 0.6, 0), Vector3(0.02, 0.26, 0.72), cloth],
	]
	for x: float in [-0.66, 0.66]:
		for z: float in [-0.3, 0.3]:
			parts.append([Vector3(x, 0.2, z), Vector3(0.08, 1.4, 0.08), WOOD])   # legs, a block into the ground
	for i in souvenirs.size():
		var col: Color = CreatureWords.souvenir(str(souvenirs[i])).get("color", GOLD)
		parts.append([Vector3(-0.35 + i * 0.7, 0.9, -0.05), Vector3(0.22, 0.24, 0.22), col])
		parts.append([Vector3(-0.35 + i * 0.7, 1.05, -0.05), Vector3(0.12, 0.08, 0.12), col.lightened(0.35)])
	parts.append([Vector3(0, 0.84, 0.15), Vector3(0.14, 0.12, 0.14), GOLD])   # a little pile of gold
	return parts


## A telescope on a tripod, looking up at the sky.
static func telescope_parts() -> Array:
	var parts: Array = []
	for i in 3:
		var a := TAU * i / 3.0
		parts.append([Vector3(cos(a) * 0.22, 0.35, sin(a) * 0.22), Vector3(0.05, 1.7, 0.05), LEG_GREY,
			Basis(Vector3(-sin(a), 0, cos(a)), -0.18)])
	parts.append_array([
		[Vector3(0, 1.22, 0), Vector3(0.14, 0.12, 0.14), LEG_GREY.darkened(0.2)],
		[Vector3(0, 1.5, -0.2), Vector3(0.16, 0.16, 0.95), PEARL, Basis(Vector3.RIGHT, 0.65)],   # the tube, up
		[Vector3(0, 1.81, -0.54), Vector3(0.2, 0.2, 0.08), GOLD, Basis(Vector3.RIGHT, 0.65)],    # its big end
	])
	return parts


## A lamp post with a warm round light.
static func lamp_parts() -> Array:
	var parts: Array = [[Vector3(0, 0.45, 0), Vector3(0.08, 2.1, 0.08), LEG_GREY]]
	parts.append_array(CreatureLook.round_box(Vector3(0, 1.6, 0), 0.17, 0.3, Color("fff3b0")))
	parts.append([Vector3(0, 1.78, 0), Vector3(0.2, 0.05, 0.2), LEG_GREY])
	return parts


# --- A village ------------------------------------------------------------------------------------------------------

## Home `i` of world u's village (its own mesh: it stands on its own ground).
static func home(u: int, i: int) -> ArrayMesh:
	return CreatureLook.mesh("alien_home_%d_%d" % [u, i], home_parts(u, i))


static func home_parts(u: int, i: int) -> Array:
	var v := CreatureWords.village(u)
	var walls: Array = v.get("home_colors", [PEARL])
	var roofs: Array = v.get("roof_colors", [GOLD])
	var wall: Color = walls[i % walls.size()]
	var roof: Color = roofs[i % roofs.size()]
	var parts: Array = []
	if u == SpaceRules.BOING:
		parts = _mushroom_hut(wall, roof)
	else:
		parts = _cone_hut(i)
	parts.append_array([
		[Vector3(0, 0.55, -0.99), Vector3(0.56, 1.1, 0.06), MOUTH.darkened(0.2)],    # a round-topped door
		[Vector3(0, 1.12, -0.99), Vector3(0.36, 0.14, 0.06), MOUTH.darkened(0.2)],
		[Vector3(-0.62, 1.05, -0.8), Vector3(0.3, 0.3, 0.05), Color("fff3b0"), Basis(Vector3.UP, 0.6)],   # a window
	])
	return parts


static func _mushroom_hut(wall: Color, roof: Color) -> Array:
	var parts: Array = CreatureLook.round_box(Vector3(0, 0.45, 0), 1.0, 2.1, wall)   # a block into the ground
	parts.append_array(CreatureLook.round_box(Vector3(0, 1.72, 0), 1.55, 0.5, roof))   # the cap
	parts.append_array(CreatureLook.round_box(Vector3(0, 2.1, 0), 0.9, 0.34, roof))
	for s: Vector3 in [Vector3(0.8, 1.99, 0.3), Vector3(-0.6, 1.99, -0.7), Vector3(-0.3, 2.28, 0.4), Vector3(0.5, 1.99, -0.9)]:
		parts.append([s, Vector3(0.28, 0.06, 0.28), Color("fffdf5")])   # its spots
	return parts


static func _cone_hut(i: int) -> Array:
	var stripes: Array[Color] = [Color("ff6b6b"), Color("ff9e3d"), Color("ffd23f"), Color("6bcb77"), Color("4d96ff"),
		Color("b388ff")]
	var parts: Array = CreatureLook.round_box(Vector3(0, 0.35, 0), 1.0, 1.9, stripes[i % stripes.size()])
	var r := 1.05
	var y := 1.45
	for k in 5:   # a striped cone roof
		parts.append_array(CreatureLook.round_box(Vector3(0, y, 0), r, 0.36, stripes[(i + k + 1) % stripes.size()]))
		r -= 0.2
		y += 0.34
	parts.append([Vector3(0, y + 0.1, 0), Vector3(0.14, 0.3, 0.14), GOLD])
	return parts


## A drum pad of `color` (its own mesh: it lights up and bounces when it plays).
static func pad(i: int) -> ArrayMesh:
	var col := PAD_COLORS[i % PAD_COLORS.size()]
	var parts: Array = CreatureLook.round_box(Vector3(0, 0.02, 0), PAD_R + 0.1, 0.36, Color("fffdf5"))   # the rim
	parts.append_array(CreatureLook.round_box(Vector3(0, 0.12, 0), PAD_R, 0.18, col))
	parts.append_array(CreatureLook.round_box(Vector3(0, 0.215, 0), PAD_R * 0.45, 0.02, col.lightened(0.4)))
	return CreatureLook.mesh("alien_pad_%d" % i, parts)
