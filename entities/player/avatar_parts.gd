class_name AvatarParts
extends RefCounted
## Box-built avatar parts (M3 Task 9): hair, faces, hats and helmets, capes, wings and outfit pieces,
## all our own designs, worn by both avatar styles (the realistic person wears them on its bones, at
## its own head and back scale). A part's boxes are merged into one mesh (one draw call) made once per
## part and colours and shared, drawn with one of two part materials (vertex colours; unshaded for
## glowing boxes). The blocky body's own boxes share one material per colour. All of it is kept for
## the whole game (DEVELOPMENT.md §8), so dressing up never makes a material.
##
## A part is built in its anchor's space:
##   HEAD: the head's centre; the blocky head is a 0.5 cube (top y 0.25, face at z -0.25, forward -Z).
##   FACE: the same frame on the blocky body; on the realistic person it sits lower, at its eyes.
##   BACK: between the shoulders on the back (blocky: the torso's top back edge); +Z is away from it.
##   HIP: the lower back, at hip height. BODY: the torso's centre (blocky only: the realistic shirt
##   shows patterns through its shader instead).
##   WAIST (Owner 48): where a skirt hangs: the blocky torso's centre (like BODY); on the realistic person
##   its hips, in metres (skirts there are its own "_real" recipes).
## A box is [size, position, colour, rotation in degrees (optional), glows (optional), shape (optional)].
## A colour is a Color or one of the look's colours: "hair", "skin", "shirt", "pants", "shoes", and (Owner
## 48) "top" and "bottom", the look's own shirt and pants colours (a skirt, a jacket's tee). Boxes of a
## "glow" part shine. "mirror" parts (wings) build their boxes on the right (+X) under "R" and mirrored under
## "L". "cover" parts wrap the whole head (helmets, the ninja mask): a body with a bigger head fits them
## (AvatarModel._fit_cover).
## Owner 48: a box's shape (or the part's "shape") can be BALL (a sphere in the box), CONE (a skirt's
## frustum: the top is 0.6 of the bottom) or TUBE (a cylinder): the realistic person's hair and skirts are
## round. A part "<id>_real" is what the realistic person wears instead of "<id>" (AvatarModel._dress).

const HEAD := &"head"
const FACE := &"face"      # the face: the head on the blocky body, a little lower on the realistic one
const BACK := &"back"
const HIP := &"hip"
const BODY := &"body"
const WAIST := &"waist"    # Owner 48

const BOX := &"box"
const BALL := &"ball"
const CONE := &"cone"
const TUBE := &"tube"
const CONE_TOP := 0.6      # a cone's top radius over its bottom radius

const TIE := Color("ff6fa8")       # hair ties and scrunchies
const PETAL := Color("ff9ecb")
const BLUSH := Color("ff9eb0")

const FACE_INK := Color("1b1b1b")
## Owner 36: how much lower (and further back) a hat sits on the realistic head, whose top is below the blocky
## head's (a part's "real_offset", in head units; M3 Task 9's hats keep their place).
const REAL_HAT_DROP := Vector3(0, -0.07, 0.02)
const WHITE := Color("fafafa")
const BLACK := Color("1f1f1f")
const GOLD := Color("ffd23f")

const PARTS := {
	# --- Hair (blocky; the realistic hair is painted on its skin) ---
	"hair_short": {"anchor": HEAD, "blocky_only": true, "boxes": [
		[Vector3(0.54, 0.1, 0.54), Vector3(0, 0.27, 0), "hair"],
		[Vector3(0.54, 0.36, 0.08), Vector3(0, 0.1, 0.26), "hair"],
		[Vector3(0.06, 0.16, 0.5), Vector3(-0.27, 0.17, 0.01), "hair"],
		[Vector3(0.06, 0.16, 0.5), Vector3(0.27, 0.17, 0.01), "hair"],
		[Vector3(0.54, 0.07, 0.06), Vector3(0, 0.2, -0.255), "hair"]]},
	"hair_spiky": {"anchor": HEAD, "blocky_only": true, "base": "hair_short", "boxes": [
		[Vector3(0.12, 0.16, 0.12), Vector3(-0.15, 0.36, -0.08), "hair", Vector3(20, 0, 25)],
		[Vector3(0.13, 0.2, 0.13), Vector3(0, 0.38, 0.02), "hair", Vector3(-15, 45, 0)],
		[Vector3(0.12, 0.16, 0.12), Vector3(0.15, 0.36, -0.08), "hair", Vector3(20, 0, -25)],
		[Vector3(0.12, 0.15, 0.12), Vector3(0, 0.34, 0.18), "hair", Vector3(-30, 0, 0)]]},
	"hair_long": {"anchor": HEAD, "blocky_only": true, "base": "hair_short", "boxes": [
		[Vector3(0.54, 0.62, 0.08), Vector3(0, -0.06, 0.27), "hair"],
		[Vector3(0.07, 0.5, 0.2), Vector3(-0.28, -0.02, 0.1), "hair"],
		[Vector3(0.07, 0.5, 0.2), Vector3(0.28, -0.02, 0.1), "hair"]]},
	"hair_bun": {"anchor": HEAD, "blocky_only": true, "base": "hair_short", "boxes": [
		[Vector3(0.22, 0.2, 0.22), Vector3(0, 0.4, 0.12), "hair"]]},
	"hair_curly": {"anchor": HEAD, "blocky_only": true, "boxes": [
		[Vector3(0.58, 0.14, 0.58), Vector3(0, 0.28, 0), "hair"],
		[Vector3(0.58, 0.4, 0.1), Vector3(0, 0.08, 0.26), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.24, 0.2, -0.12), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.24, 0.2, -0.12), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.26, 0.14, 0.14), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.26, 0.14, 0.14), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.12, 0.37, 0.0), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.12, 0.37, 0.08), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0, 0.35, -0.14), "hair"]]},
	# --- Faces (blocky; on the realistic person only "cool" adds sunglasses: extra_sunglasses) ---
	"face_smile": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.07, 0.1, 0.01), Vector3(-0.1, 0.05, -0.251), FACE_INK],
		[Vector3(0.07, 0.1, 0.01), Vector3(0.1, 0.05, -0.251), FACE_INK],
		[Vector3(0.22, 0.04, 0.01), Vector3(0, -0.09, -0.251), FACE_INK],
		[Vector3(0.04, 0.05, 0.01), Vector3(-0.11, -0.06, -0.251), FACE_INK],
		[Vector3(0.04, 0.05, 0.01), Vector3(0.11, -0.06, -0.251), FACE_INK]]},
	"face_grin": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.07, 0.1, 0.01), Vector3(-0.1, 0.05, -0.251), FACE_INK],
		[Vector3(0.07, 0.1, 0.01), Vector3(0.1, 0.05, -0.251), FACE_INK],
		[Vector3(0.26, 0.1, 0.01), Vector3(0, -0.1, -0.251), Color("5a1f1f")],
		[Vector3(0.22, 0.03, 0.012), Vector3(0, -0.07, -0.252), WHITE]]},
	"face_wink": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.09, 0.025, 0.01), Vector3(-0.1, 0.04, -0.251), FACE_INK],
		[Vector3(0.07, 0.1, 0.01), Vector3(0.1, 0.05, -0.251), FACE_INK],
		[Vector3(0.22, 0.04, 0.01), Vector3(0, -0.09, -0.251), FACE_INK],
		[Vector3(0.04, 0.05, 0.01), Vector3(-0.11, -0.06, -0.251), FACE_INK],
		[Vector3(0.04, 0.05, 0.01), Vector3(0.11, -0.06, -0.251), FACE_INK]]},
	"face_wow": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.08, 0.12, 0.01), Vector3(-0.1, 0.06, -0.251), FACE_INK],
		[Vector3(0.08, 0.12, 0.01), Vector3(0.1, 0.06, -0.251), FACE_INK],
		[Vector3(0.09, 0.1, 0.01), Vector3(0, -0.1, -0.251), Color("5a1f1f")]]},
	"face_sleepy": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.09, 0.025, 0.01), Vector3(-0.1, 0.03, -0.251), FACE_INK],
		[Vector3(0.09, 0.025, 0.01), Vector3(0.1, 0.03, -0.251), FACE_INK],
		[Vector3(0.1, 0.03, 0.01), Vector3(0, -0.09, -0.251), FACE_INK]]},
	"face_cool": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.46, 0.1, 0.03), Vector3(0, 0.05, -0.265), BLACK],
		[Vector3(0.06, 0.03, 0.005), Vector3(-0.13, 0.07, -0.281), Color("8a8f98")],
		[Vector3(0.06, 0.03, 0.005), Vector3(0.09, 0.07, -0.281), Color("8a8f98")],
		[Vector3(0.16, 0.04, 0.01), Vector3(0.03, -0.09, -0.251), FACE_INK],
		[Vector3(0.04, 0.05, 0.01), Vector3(0.11, -0.06, -0.251), FACE_INK]]},
	# --- Hats ---
	"hat_cap": {"anchor": HEAD, "boxes": [
		[Vector3(0.54, 0.14, 0.54), Vector3(0, 0.31, 0), Color("e53935")],
		[Vector3(0.46, 0.04, 0.24), Vector3(0, 0.26, -0.36), Color("b71c1c")],
		[Vector3(0.08, 0.04, 0.08), Vector3(0, 0.4, 0), Color("b71c1c")]]},
	"hat_beanie": {"anchor": HEAD, "boxes": [
		[Vector3(0.56, 0.2, 0.56), Vector3(0, 0.33, 0), Color("3a7be8")],
		[Vector3(0.58, 0.08, 0.58), Vector3(0, 0.25, 0), Color("2a5cb0")],
		[Vector3(0.14, 0.14, 0.14), Vector3(0, 0.48, 0), WHITE]]},
	"hat_flower": {"anchor": HEAD, "boxes": [
		[Vector3(0.09, 0.09, 0.06), Vector3(0.15, 0.3, -0.16), Color("ffd54f")],
		[Vector3(0.08, 0.08, 0.05), Vector3(0.07, 0.3, -0.16), Color("f48fb1")],
		[Vector3(0.08, 0.08, 0.05), Vector3(0.23, 0.3, -0.16), Color("f48fb1")],
		[Vector3(0.08, 0.08, 0.05), Vector3(0.15, 0.38, -0.16), Color("f48fb1")],
		[Vector3(0.08, 0.08, 0.05), Vector3(0.15, 0.22, -0.16), Color("f48fb1")],
		[Vector3(0.12, 0.04, 0.05), Vector3(0.03, 0.25, -0.17), Color("66bb6a"), Vector3(0, 0, 20)]]},
	"hat_party": {"anchor": HEAD, "boxes": [
		[Vector3(0.32, 0.12, 0.32), Vector3(0, 0.31, 0), Color("ab47bc")],
		[Vector3(0.24, 0.12, 0.24), Vector3(0, 0.43, 0), Color("ffca28")],
		[Vector3(0.16, 0.12, 0.16), Vector3(0, 0.55, 0), Color("ab47bc")],
		[Vector3(0.08, 0.1, 0.08), Vector3(0, 0.66, 0), Color("ffca28")],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.74, 0), Color("ef5350")]]},
	"hat_cowboy": {"anchor": HEAD, "boxes": [
		[Vector3(0.7, 0.04, 0.8), Vector3(0, 0.27, 0), Color("8d5a2b")],
		[Vector3(0.1, 0.04, 0.8), Vector3(-0.38, 0.3, 0), Color("8d5a2b"), Vector3(0, 0, -25)],
		[Vector3(0.1, 0.04, 0.8), Vector3(0.38, 0.3, 0), Color("8d5a2b"), Vector3(0, 0, 25)],
		[Vector3(0.46, 0.22, 0.44), Vector3(0, 0.39, 0), Color("8d5a2b")],
		[Vector3(0.48, 0.05, 0.46), Vector3(0, 0.31, 0), Color("4e2c12")]]},
	"hat_top_hat": {"anchor": HEAD, "boxes": [
		[Vector3(0.68, 0.04, 0.68), Vector3(0, 0.27, 0), Color("212121")],
		[Vector3(0.42, 0.44, 0.42), Vector3(0, 0.51, 0), Color("212121")],
		[Vector3(0.44, 0.07, 0.44), Vector3(0, 0.33, 0), Color("c62828")]]},
	"hat_crown": {"anchor": HEAD, "boxes": [
		[Vector3(0.52, 0.12, 0.04), Vector3(0, 0.31, -0.24), GOLD],
		[Vector3(0.52, 0.12, 0.04), Vector3(0, 0.31, 0.24), GOLD],
		[Vector3(0.04, 0.12, 0.52), Vector3(-0.24, 0.31, 0), GOLD],
		[Vector3(0.04, 0.12, 0.52), Vector3(0.24, 0.31, 0), GOLD],
		[Vector3(0.07, 0.1, 0.07), Vector3(-0.24, 0.41, -0.24), GOLD],
		[Vector3(0.07, 0.1, 0.07), Vector3(0.24, 0.41, -0.24), GOLD],
		[Vector3(0.07, 0.1, 0.07), Vector3(-0.24, 0.41, 0.24), GOLD],
		[Vector3(0.07, 0.1, 0.07), Vector3(0.24, 0.41, 0.24), GOLD],
		[Vector3(0.07, 0.12, 0.04), Vector3(0, 0.42, -0.24), GOLD],
		[Vector3(0.08, 0.06, 0.02), Vector3(0, 0.31, -0.265), Color("e53935")],
		[Vector3(0.06, 0.05, 0.02), Vector3(-0.15, 0.31, -0.265), Color("42a5f5")],
		[Vector3(0.06, 0.05, 0.02), Vector3(0.15, 0.31, -0.265), Color("42a5f5")]]},
	"hat_pip_cap": {"anchor": HEAD, "boxes": [
		[Vector3(0.54, 0.14, 0.54), Vector3(0, 0.31, 0), Color("26a69a")],
		[Vector3(0.46, 0.04, 0.24), Vector3(0, 0.26, -0.36), Color("00796b")],
		[Vector3(0.03, 0.16, 0.03), Vector3(0, 0.46, 0), Color("b0bec5")],
		[Vector3(0.08, 0.08, 0.08), Vector3(0, 0.56, 0), Color("ff9800")]]},
	"hat_golem_helm": {"anchor": HEAD, "boxes": [
		[Vector3(0.6, 0.2, 0.6), Vector3(0, 0.3, 0), Color("8d8d8d")],
		[Vector3(0.6, 0.08, 0.1), Vector3(0, 0.22, -0.28), Color("616161")],
		[Vector3(0.12, 0.18, 0.12), Vector3(-0.22, 0.46, 0), Color("616161"), Vector3(0, 0, 15)],
		[Vector3(0.12, 0.18, 0.12), Vector3(0.22, 0.46, 0), Color("616161"), Vector3(0, 0, -15)],
		[Vector3(0.3, 0.03, 0.3), Vector3(0.05, 0.415, 0.05), Color("7cb342")]]},
	# --- Outfit headgear ---
	"hat_knight_helm": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.58, 0.58, 0.58), Vector3(0, 0.02, 0), Color("b0b8c0")],
		[Vector3(0.44, 0.05, 0.02), Vector3(0, 0.06, -0.295), BLACK],
		[Vector3(0.03, 0.03, 0.02), Vector3(-0.08, -0.08, -0.295), BLACK],
		[Vector3(0.03, 0.03, 0.02), Vector3(0, -0.08, -0.295), BLACK],
		[Vector3(0.03, 0.03, 0.02), Vector3(0.08, -0.08, -0.295), BLACK],
		[Vector3(0.06, 0.06, 0.58), Vector3(0, 0.33, 0), Color("8f98a2")],
		[Vector3(0.08, 0.2, 0.34), Vector3(0, 0.43, 0.04), Color("d32f2f")]]},
	"hat_space_helm": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.64, 0.64, 0.64), Vector3(0, 0.02, 0), Color("f5f5f5")],
		[Vector3(0.5, 0.34, 0.02), Vector3(0, 0.04, -0.325), Color("26415f")],
		[Vector3(0.1, 0.06, 0.022), Vector3(-0.14, 0.13, -0.327), Color("7fb2e5")],
		[Vector3(0.08, 0.06, 0.06), Vector3(0.24, 0.3, -0.2), Color("ff7043"), Vector3.ZERO, true]]},
	"hat_dino_hood": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.6, 0.12, 0.62), Vector3(0, 0.3, 0), Color("43a047")],
		[Vector3(0.6, 0.56, 0.1), Vector3(0, 0.04, 0.29), Color("43a047")],
		[Vector3(0.07, 0.44, 0.6), Vector3(-0.29, 0.1, 0), Color("43a047")],
		[Vector3(0.07, 0.44, 0.6), Vector3(0.29, 0.1, 0), Color("43a047")],
		[Vector3(0.52, 0.12, 0.18), Vector3(0, 0.22, -0.36), Color("388e3c")],
		[Vector3(0.06, 0.05, 0.04), Vector3(-0.18, 0.14, -0.42), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(-0.06, 0.14, -0.42), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(0.06, 0.14, -0.42), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(0.18, 0.14, -0.42), WHITE],
		[Vector3(0.1, 0.1, 0.06), Vector3(-0.15, 0.4, -0.18), WHITE],
		[Vector3(0.1, 0.1, 0.06), Vector3(0.15, 0.4, -0.18), WHITE],
		[Vector3(0.05, 0.05, 0.02), Vector3(-0.15, 0.4, -0.215), BLACK],
		[Vector3(0.05, 0.05, 0.02), Vector3(0.15, 0.4, -0.215), BLACK],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.38, 0.08), Color("ffa726"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.3, 0.3), Color("ffa726"), Vector3(45, 0, 0)]]},
	"hat_robot_head": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.56, 0.56, 0.56), Vector3.ZERO, Color("b8c0c8")],
		[Vector3(0.13, 0.08, 0.02), Vector3(-0.12, 0.06, -0.285), Color("29b6f6"), Vector3.ZERO, true],
		[Vector3(0.13, 0.08, 0.02), Vector3(0.12, 0.06, -0.285), Color("29b6f6"), Vector3.ZERO, true],
		[Vector3(0.3, 0.05, 0.02), Vector3(0, -0.12, -0.285), Color("37474f")],
		[Vector3(0.05, 0.12, 0.12), Vector3(-0.3, 0, 0), Color("37474f")],
		[Vector3(0.05, 0.12, 0.12), Vector3(0.3, 0, 0), Color("37474f")],
		[Vector3(0.03, 0.16, 0.03), Vector3(0, 0.36, 0), Color("37474f")],
		[Vector3(0.08, 0.08, 0.08), Vector3(0, 0.46, 0), Color("ef5350"), Vector3.ZERO, true]]},
	"hat_pirate_hat": {"anchor": HEAD, "boxes": [
		[Vector3(0.72, 0.05, 0.52), Vector3(0, 0.28, 0), BLACK],
		[Vector3(0.48, 0.18, 0.42), Vector3(0, 0.39, 0.02), BLACK],
		[Vector3(0.72, 0.1, 0.04), Vector3(0, 0.34, -0.25), BLACK, Vector3(-20, 0, 0)],
		[Vector3(0.74, 0.02, 0.02), Vector3(0, 0.39, -0.27), Color("ffca28"), Vector3(-20, 0, 0)],
		[Vector3(0.08, 0.08, 0.02), Vector3(0, 0.36, -0.285), WHITE, Vector3(-20, 0, 0)]]},
	"hat_ninja_mask": {"anchor": FACE, "cover": true, "boxes": [
		[Vector3(0.54, 0.19, 0.54), Vector3(0, 0.17, 0), Color("1f2023")],
		[Vector3(0.54, 0.2, 0.54), Vector3(0, -0.16, 0), Color("1f2023")],
		[Vector3(0.54, 0.14, 0.2), Vector3(0, 0.0, 0.17), Color("1f2023")],
		[Vector3(0.56, 0.05, 0.1), Vector3(0, 0.12, 0.23), Color("d32f2f")],
		[Vector3(0.06, 0.05, 0.26), Vector3(0.06, 0.1, 0.38), Color("d32f2f"), Vector3(0, 15, 0)],
		[Vector3(0.06, 0.05, 0.22), Vector3(-0.04, 0.06, 0.36), Color("d32f2f"), Vector3(0, -10, 0)]]},
	"hat_candy_crown": {"anchor": HEAD, "boxes": [
		[Vector3(0.5, 0.08, 0.5), Vector3(0, 0.29, 0), Color("ff80ab")],
		[Vector3(0.13, 0.13, 0.13), Vector3(-0.15, 0.39, 0), Color("7fe0c8")],
		[Vector3(0.13, 0.13, 0.13), Vector3(0, 0.42, 0), Color("fff176")],
		[Vector3(0.13, 0.13, 0.13), Vector3(0.15, 0.39, 0), Color("ff80ab")],
		[Vector3(0.03, 0.16, 0.03), Vector3(0.2, 0.4, 0.12), WHITE],
		[Vector3(0.16, 0.16, 0.04), Vector3(0.2, 0.54, 0.12), Color("ff5fa2")],
		[Vector3(0.1, 0.04, 0.045), Vector3(0.2, 0.54, 0.12), WHITE, Vector3(0, 0, 45)]]},
	"hat_cosmic_halo": {"anchor": HEAD, "glow": true, "boxes": [
		[Vector3(0.5, 0.03, 0.05), Vector3(0, 0.45, -0.22), Color("ffe27a")],
		[Vector3(0.5, 0.03, 0.05), Vector3(0, 0.45, 0.22), Color("ffe27a")],
		[Vector3(0.05, 0.03, 0.5), Vector3(-0.22, 0.45, 0), Color("ffe27a")],
		[Vector3(0.05, 0.03, 0.5), Vector3(0.22, 0.45, 0), Color("ffe27a")],
		[Vector3(0.1, 0.1, 0.03), Vector3(0, 0.58, 0), Color("fff3c4"), Vector3(0, 0, 45)]]},
	# --- Capes (they hang from the shoulders and flutter back as the body runs) ---
	"cape_hero": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("d32f2f")],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), GOLD]]},
	"cape_leaf": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("558b2f")],
		[Vector3(0.03, 0.8, 0.045), Vector3(0, -0.45, 0.03), Color("33691e")],
		[Vector3(0.25, 0.03, 0.045), Vector3(-0.12, -0.35, 0.03), Color("33691e"), Vector3(0, 0, -30)],
		[Vector3(0.25, 0.03, 0.045), Vector3(0.12, -0.35, 0.03), Color("33691e"), Vector3(0, 0, 30)],
		[Vector3(0.25, 0.03, 0.045), Vector3(-0.12, -0.65, 0.03), Color("33691e"), Vector3(0, 0, -30)],
		[Vector3(0.25, 0.03, 0.045), Vector3(0.12, -0.65, 0.03), Color("33691e"), Vector3(0, 0, 30)]]},
	"cape_night": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("1a237e")],
		[Vector3(0.05, 0.05, 0.045), Vector3(-0.15, -0.2, 0.03), Color("ffee58"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(0.12, -0.35, 0.03), Color("ffee58"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(-0.05, -0.55, 0.03), Color("ffee58"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(0.18, -0.7, 0.03), Color("ffee58"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(-0.18, -0.82, 0.03), Color("ffee58"), Vector3.ZERO, true]]},
	"cape_royal": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("6a1b9a")],
		[Vector3(0.04, 0.95, 0.05), Vector3(-0.29, -0.48, 0.03), Color("ffc107")],
		[Vector3(0.04, 0.95, 0.05), Vector3(0.29, -0.48, 0.03), Color("ffc107")],
		[Vector3(0.58, 0.05, 0.05), Vector3(0, -0.95, 0.03), Color("ffc107")],
		[Vector3(0.64, 0.1, 0.1), Vector3(0, 0.0, 0.0), WHITE],
		[Vector3(0.03, 0.04, 0.02), Vector3(-0.15, 0.0, 0.055), BLACK],
		[Vector3(0.03, 0.04, 0.02), Vector3(0.15, 0.0, 0.055), BLACK]]},
	# --- Wings (built on the right, mirrored; they flap, faster in the air) ---
	"wings_butterfly": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.36, 0.32, 0.03), Vector3(0.2, 0.1, 0), Color("ff9800")],
		[Vector3(0.26, 0.24, 0.03), Vector3(0.15, -0.2, 0), Color("ffca28")],
		[Vector3(0.08, 0.08, 0.035), Vector3(0.26, 0.14, 0), BLACK],
		[Vector3(0.06, 0.06, 0.035), Vector3(0.16, -0.2, 0), BLACK],
		[Vector3(0.04, 0.32, 0.035), Vector3(0.37, 0.1, 0), Color("5d4037")]]},
	"wings_bat": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.46, 0.22, 0.03), Vector3(0.25, 0.02, 0), Color("3e2a4f")],
		[Vector3(0.14, 0.1, 0.03), Vector3(0.1, -0.12, 0), Color("3e2a4f")],
		[Vector3(0.14, 0.1, 0.03), Vector3(0.25, -0.13, 0), Color("3e2a4f")],
		[Vector3(0.14, 0.1, 0.03), Vector3(0.4, -0.12, 0), Color("3e2a4f")],
		[Vector3(0.48, 0.03, 0.035), Vector3(0.25, 0.13, 0), BLACK],
		[Vector3(0.04, 0.06, 0.035), Vector3(0.49, 0.15, 0), BLACK]]},
	"wings_angel": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.42, 0.12, 0.04), Vector3(0.22, 0.16, 0), WHITE, Vector3(0, 0, 18)],
		[Vector3(0.36, 0.1, 0.04), Vector3(0.2, 0.04, 0.01), Color("e0e0e0"), Vector3(0, 0, 12)],
		[Vector3(0.28, 0.1, 0.04), Vector3(0.16, -0.08, 0.02), WHITE, Vector3(0, 0, 6)],
		[Vector3(0.2, 0.08, 0.04), Vector3(0.12, -0.18, 0.03), Color("e0e0e0")]]},
	"wings_dragon": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.56, 0.28, 0.03), Vector3(0.3, 0.02, 0), Color("c62828")],
		[Vector3(0.16, 0.12, 0.03), Vector3(0.12, -0.16, 0), Color("c62828")],
		[Vector3(0.16, 0.12, 0.03), Vector3(0.3, -0.17, 0), Color("c62828")],
		[Vector3(0.16, 0.12, 0.03), Vector3(0.48, -0.16, 0), Color("c62828")],
		[Vector3(0.6, 0.04, 0.04), Vector3(0.3, 0.17, 0), Color("4e342e")],
		[Vector3(0.03, 0.3, 0.035), Vector3(0.2, 0.02, 0), Color("4e342e")],
		[Vector3(0.03, 0.3, 0.035), Vector3(0.4, 0.02, 0), Color("4e342e")],
		[Vector3(0.05, 0.08, 0.04), Vector3(0.6, 0.2, 0), Color("fafafa")]]},
	"wings_fairy": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.3, 0.36, 0.02), Vector3(0.17, 0.14, 0), Color("b2ebf2"), Vector3(0, 0, 20)],
		[Vector3(0.22, 0.22, 0.02), Vector3(0.13, -0.16, 0), Color("f8bbd0"), Vector3(0, 0, -15)],
		[Vector3(0.04, 0.04, 0.03), Vector3(0.28, 0.27, 0), WHITE, Vector3.ZERO, true],
		[Vector3(0.03, 0.03, 0.03), Vector3(0.2, -0.24, 0), WHITE, Vector3.ZERO, true]]},
	# --- Outfit pieces ---
	"extra_sunglasses": {"anchor": FACE, "boxes": [
		[Vector3(0.46, 0.1, 0.03), Vector3(0, 0.05, -0.265), BLACK],
		[Vector3(0.06, 0.03, 0.005), Vector3(-0.13, 0.07, -0.281), Color("8a8f98")],
		[Vector3(0.06, 0.03, 0.005), Vector3(0.09, 0.07, -0.281), Color("8a8f98")]]},
	"extra_eyepatch": {"anchor": FACE, "boxes": [
		[Vector3(0.11, 0.11, 0.02), Vector3(-0.1, 0.05, -0.262), BLACK],
		[Vector3(0.56, 0.025, 0.012), Vector3(0, 0.1, -0.258), BLACK, Vector3(0, 0, -12)]]},
	"extra_knight_emblem": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.3, 0.07, 0.02), Vector3(0, 0.08, -0.17), Color("c62828")],
		[Vector3(0.07, 0.34, 0.02), Vector3(0, 0.06, -0.17), Color("c62828")],
		[Vector3(0.63, 0.06, 0.33), Vector3(0, -0.3, 0), Color("4e342e")]]},
	"extra_space_pack": {"anchor": BACK, "boxes": [
		[Vector3(0.4, 0.46, 0.16), Vector3(0, -0.3, 0.09), Color("eceff1")],
		[Vector3(0.1, 0.34, 0.1), Vector3(-0.12, -0.3, 0.2), Color("90a4ae")],
		[Vector3(0.1, 0.34, 0.1), Vector3(0.12, -0.3, 0.2), Color("90a4ae")],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.1, -0.12, 0.18), Color("ff7043"), Vector3.ZERO, true]]},
	"extra_space_badge": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.12, 0.08, 0.02), Vector3(0.15, 0.15, -0.17), Color("1e88e5")],
		[Vector3(0.05, 0.03, 0.022), Vector3(0.13, 0.16, -0.172), Color("e53935")]]},
	"extra_dino_spikes": {"anchor": BACK, "boxes": [
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.0, 0.05), Color("ffa726"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, -0.18, 0.05), Color("ffa726"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, -0.36, 0.05), Color("ffa726"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, -0.54, 0.05), Color("ffa726"), Vector3(45, 0, 0)]]},
	"extra_dino_tail": {"anchor": HIP, "boxes": [
		[Vector3(0.26, 0.22, 0.3), Vector3(0, 0.0, 0.16), "shirt"],
		[Vector3(0.2, 0.17, 0.3), Vector3(0, -0.1, 0.42), "shirt"],
		[Vector3(0.13, 0.12, 0.26), Vector3(0, -0.18, 0.66), "shirt"],
		[Vector3(0.08, 0.08, 0.08), Vector3(0, 0.12, 0.3), Color("ffa726"), Vector3(45, 0, 0)],
		[Vector3(0.06, 0.06, 0.06), Vector3(0, 0.0, 0.55), Color("ffa726"), Vector3(45, 0, 0)]]},
	"extra_robot_panel": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.3, 0.22, 0.02), Vector3(0, 0.08, -0.17), Color("37474f")],
		[Vector3(0.05, 0.05, 0.02), Vector3(-0.08, 0.12, -0.182), Color("ef5350"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.02), Vector3(0, 0.12, -0.182), Color("66bb6a"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.02), Vector3(0.08, 0.12, -0.182), Color("ffee58"), Vector3.ZERO, true],
		[Vector3(0.2, 0.03, 0.02), Vector3(0, 0.02, -0.182), Color("90a4ae")]]},
	"extra_pirate_stripes": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.63, 0.06, 0.33), Vector3(0, 0.22, 0), Color("c62828")],
		[Vector3(0.63, 0.06, 0.33), Vector3(0, 0.08, 0), Color("c62828")],
		[Vector3(0.63, 0.06, 0.33), Vector3(0, -0.06, 0), Color("c62828")],
		[Vector3(0.63, 0.06, 0.33), Vector3(0, -0.2, 0), Color("c62828")],
		[Vector3(0.63, 0.05, 0.33), Vector3(0, -0.32, 0), Color("4e342e")],
		[Vector3(0.08, 0.07, 0.02), Vector3(0, -0.32, -0.172), Color("ffca28")]]},
	"extra_ninja_belt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.63, 0.07, 0.33), Vector3(0, -0.28, 0), Color("d32f2f")],
		[Vector3(0.08, 0.12, 0.03), Vector3(0.12, -0.34, -0.17), Color("d32f2f")]]},
	"extra_candy_stripes": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.63, 0.05, 0.33), Vector3(0, 0.22, 0), Color("fff5fb")],
		[Vector3(0.63, 0.05, 0.33), Vector3(0, 0.08, 0), Color("fff5fb")],
		[Vector3(0.63, 0.05, 0.33), Vector3(0, -0.06, 0), Color("fff5fb")],
		[Vector3(0.63, 0.05, 0.33), Vector3(0, -0.2, 0), Color("fff5fb")],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.2, 0.15, -0.17), Color("64b5f6")],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.18, 0.0, -0.17), Color("fff176")],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.05, -0.13, -0.17), Color("81c784")]]},
	"extra_cosmic_stars": {"anchor": BODY, "blocky_only": true, "glow": true, "boxes": [
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.2, 0.2, -0.17), Color("ffe27a")],
		[Vector3(0.05, 0.05, 0.02), Vector3(0.12, 0.25, -0.17), Color("ffe27a")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0.22, 0.05, -0.17), Color("ffe27a")],
		[Vector3(0.05, 0.05, 0.02), Vector3(-0.1, 0.0, -0.17), Color("ffe27a")],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.05, -0.18, -0.17), Color("ffe27a")],
		[Vector3(0.03, 0.03, 0.02), Vector3(-0.22, -0.26, -0.17), Color("ffe27a")]]},
	"extra_cosmic_cape": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("4527a0")],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), Color("ffe27a"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(-0.16, -0.25, 0.03), Color("ffe27a"), Vector3.ZERO, true],
		[Vector3(0.04, 0.04, 0.045), Vector3(0.14, -0.4, 0.03), Color("ffe27a"), Vector3.ZERO, true],
		[Vector3(0.05, 0.05, 0.045), Vector3(-0.04, -0.62, 0.03), Color("ffe27a"), Vector3.ZERO, true],
		[Vector3(0.04, 0.04, 0.045), Vector3(0.2, -0.78, 0.03), Color("ffe27a"), Vector3.ZERO, true]]},
	# --- Owner 35 (spec §18): the looks in what a grown-up buys (our own designs) ---
	# EasyCraft Plus's set
	"hat_frost_hood": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.6, 0.14, 0.6), Vector3(0, 0.3, 0.01), Color("dfeefa")],
		[Vector3(0.6, 0.56, 0.1), Vector3(0, 0.04, 0.28), Color("dfeefa")],
		[Vector3(0.08, 0.5, 0.58), Vector3(-0.29, 0.06, 0.01), Color("dfeefa")],
		[Vector3(0.08, 0.5, 0.58), Vector3(0.29, 0.06, 0.01), Color("dfeefa")],
		[Vector3(0.64, 0.1, 0.08), Vector3(0, 0.26, -0.28), WHITE],
		[Vector3(0.08, 0.46, 0.08), Vector3(-0.3, 0.02, -0.28), WHITE],
		[Vector3(0.08, 0.46, 0.08), Vector3(0.3, 0.02, -0.28), WHITE],
		[Vector3(0.6, 0.05, 0.62), Vector3(0, 0.39, 0.01), Color("7fd3ff")]]},
	"extra_frost_scarf": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.66, 0.08, 0.36), Vector3(0, 0.3, 0), Color("4fc3f7")],
		[Vector3(0.1, 0.26, 0.03), Vector3(-0.14, 0.16, -0.18), Color("4fc3f7")],
		[Vector3(0.1, 0.03, 0.035), Vector3(-0.14, 0.06, -0.18), WHITE]]},
	"hat_explorer": {"anchor": HEAD, "boxes": [
		[Vector3(0.72, 0.04, 0.72), Vector3(0, 0.26, 0), Color("c8b27a")],
		[Vector3(0.5, 0.16, 0.5), Vector3(0, 0.36, 0), Color("d9c48d")],
		[Vector3(0.36, 0.08, 0.36), Vector3(0, 0.47, 0), Color("d9c48d")],
		[Vector3(0.52, 0.05, 0.52), Vector3(0, 0.3, 0), Color("6d4c2f")],
		[Vector3(0.08, 0.05, 0.02), Vector3(0.14, 0.3, -0.265), Color("ffca28")]]},
	"cape_aurora": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("1b2a4e")],
		[Vector3(0.58, 0.1, 0.045), Vector3(0, -0.22, 0.03), Color("4dd0a8"), Vector3.ZERO, true],
		[Vector3(0.58, 0.08, 0.045), Vector3(0, -0.4, 0.03), Color("26c6da"), Vector3.ZERO, true],
		[Vector3(0.58, 0.1, 0.045), Vector3(0, -0.58, 0.03), Color("9575cd"), Vector3.ZERO, true],
		[Vector3(0.58, 0.06, 0.045), Vector3(0, -0.75, 0.03), Color("4dd0a8"), Vector3.ZERO, true],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), Color("b0bec5")]]},
	# The Sky Pack
	"wings_phoenix": {"anchor": BACK, "sway": &"wings", "mirror": true, "boxes": [
		[Vector3(0.5, 0.14, 0.04), Vector3(0.27, 0.16, 0), Color("e53935"), Vector3(0, 0, 20)],
		[Vector3(0.44, 0.12, 0.04), Vector3(0.24, 0.03, 0.01), Color("fb8c00"), Vector3(0, 0, 12)],
		[Vector3(0.36, 0.11, 0.04), Vector3(0.2, -0.09, 0.02), Color("fdd835"), Vector3(0, 0, 5)],
		[Vector3(0.26, 0.09, 0.04), Vector3(0.15, -0.2, 0.03), Color("fb8c00")],
		[Vector3(0.06, 0.08, 0.045), Vector3(0.5, 0.26, 0), Color("fff176"), Vector3(0, 0, 20), true]]},
	"cape_cloud": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.9, 0.04), Vector3(0, -0.45, 0.03), Color("90caf9")],
		[Vector3(0.22, 0.14, 0.05), Vector3(-0.17, -0.86, 0.03), WHITE],
		[Vector3(0.24, 0.16, 0.05), Vector3(0.05, -0.88, 0.03), WHITE],
		[Vector3(0.2, 0.13, 0.05), Vector3(0.2, -0.85, 0.03), WHITE],
		[Vector3(0.18, 0.1, 0.045), Vector3(-0.1, -0.35, 0.03), Color("e3f2fd")],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), WHITE]]},
	"hat_aviator": {"anchor": HEAD, "boxes": [
		[Vector3(0.56, 0.14, 0.56), Vector3(0, 0.3, 0.01), Color("795548")],
		[Vector3(0.1, 0.3, 0.3), Vector3(-0.28, 0.12, 0.04), Color("795548")],
		[Vector3(0.1, 0.3, 0.3), Vector3(0.28, 0.12, 0.04), Color("795548")],
		[Vector3(0.58, 0.05, 0.05), Vector3(0, 0.3, -0.27), Color("4e342e")],
		[Vector3(0.14, 0.1, 0.04), Vector3(-0.1, 0.32, -0.29), Color("80deea")],
		[Vector3(0.14, 0.1, 0.04), Vector3(0.1, 0.32, -0.29), Color("80deea")]]},
	# The Ocean Pack
	"hat_diver_helm": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.66, 0.62, 0.66), Vector3(0, 0.02, 0), Color("c9a227")],
		[Vector3(0.34, 0.3, 0.03), Vector3(0, 0.04, -0.335), Color("4fc3f7")],
		[Vector3(0.4, 0.05, 0.035), Vector3(0, 0.21, -0.335), Color("8d6e1f")],
		[Vector3(0.4, 0.05, 0.035), Vector3(0, -0.13, -0.335), Color("8d6e1f")],
		[Vector3(0.08, 0.08, 0.08), Vector3(0, 0.37, 0), Color("8d6e1f")],
		[Vector3(0.7, 0.1, 0.7), Vector3(0, -0.3, 0), Color("8d6e1f")]]},
	"extra_diver_weights": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.63, 0.08, 0.33), Vector3(0, -0.28, 0), Color("4e342e")],
		[Vector3(0.1, 0.1, 0.04), Vector3(-0.16, -0.28, -0.18), Color("78909c")],
		[Vector3(0.1, 0.1, 0.04), Vector3(0.16, -0.28, -0.18), Color("78909c")]]},
	"cape_wave": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("1565c0")],
		[Vector3(0.58, 0.07, 0.045), Vector3(0, -0.3, 0.03), Color("4fc3f7")],
		[Vector3(0.58, 0.07, 0.045), Vector3(0, -0.55, 0.03), Color("4fc3f7")],
		[Vector3(0.58, 0.09, 0.045), Vector3(0, -0.88, 0.03), WHITE],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), Color("0d47a1")]]},
	"hat_captain": {"anchor": HEAD, "boxes": [
		[Vector3(0.58, 0.12, 0.58), Vector3(0, 0.34, 0), WHITE],
		[Vector3(0.54, 0.06, 0.54), Vector3(0, 0.26, 0), BLACK],
		[Vector3(0.46, 0.03, 0.2), Vector3(0, 0.24, -0.34), BLACK],
		[Vector3(0.12, 0.08, 0.02), Vector3(0, 0.3, -0.275), Color("ffca28")]]},
	# --- Owner 48 (spec §14.6a): boy and girl looks, all free. Cute like a cartoon heroine: no body
	# shaping, only cartoon lashes and rosy cheeks on the faces, clothes children wear. ---
	# Faces (blocky; the realistic face gets its lashes and cheeks from AvatarSkin's shader)
	"face_sweet": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.07, 0.1, 0.01), Vector3(-0.1, 0.04, -0.251), FACE_INK],
		[Vector3(0.07, 0.1, 0.01), Vector3(0.1, 0.04, -0.251), FACE_INK],
		[Vector3(0.025, 0.025, 0.012), Vector3(-0.085, 0.065, -0.252), WHITE],
		[Vector3(0.025, 0.025, 0.012), Vector3(0.115, 0.065, -0.252), WHITE],
		[Vector3(0.035, 0.016, 0.012), Vector3(-0.145, 0.095, -0.252), FACE_INK, Vector3(0, 0, -30)],
		[Vector3(0.035, 0.016, 0.012), Vector3(0.145, 0.095, -0.252), FACE_INK, Vector3(0, 0, 30)],
		[Vector3(0.03, 0.014, 0.012), Vector3(-0.14, 0.115, -0.252), FACE_INK, Vector3(0, 0, -60)],
		[Vector3(0.03, 0.014, 0.012), Vector3(0.14, 0.115, -0.252), FACE_INK, Vector3(0, 0, 60)],
		[Vector3(0.1, 0.03, 0.01), Vector3(0, -0.1, -0.251), FACE_INK],
		[Vector3(0.03, 0.04, 0.01), Vector3(-0.06, -0.08, -0.251), FACE_INK],
		[Vector3(0.03, 0.04, 0.01), Vector3(0.06, -0.08, -0.251), FACE_INK],
		[Vector3(0.075, 0.04, 0.008), Vector3(-0.16, -0.045, -0.2505), BLUSH],
		[Vector3(0.075, 0.04, 0.008), Vector3(0.16, -0.045, -0.2505), BLUSH]]},
	"face_lovely": {"anchor": FACE, "blocky_only": true, "boxes": [
		[Vector3(0.08, 0.12, 0.01), Vector3(-0.1, 0.04, -0.251), FACE_INK],
		[Vector3(0.08, 0.12, 0.01), Vector3(0.1, 0.04, -0.251), FACE_INK],
		[Vector3(0.03, 0.03, 0.012), Vector3(-0.083, 0.07, -0.252), WHITE],
		[Vector3(0.03, 0.03, 0.012), Vector3(0.117, 0.07, -0.252), WHITE],
		[Vector3(0.015, 0.015, 0.012), Vector3(-0.115, 0.01, -0.252), WHITE],
		[Vector3(0.015, 0.015, 0.012), Vector3(0.085, 0.01, -0.252), WHITE],
		[Vector3(0.09, 0.02, 0.012), Vector3(-0.1, 0.11, -0.252), FACE_INK],
		[Vector3(0.09, 0.02, 0.012), Vector3(0.1, 0.11, -0.252), FACE_INK],
		[Vector3(0.04, 0.016, 0.012), Vector3(-0.155, 0.125, -0.252), FACE_INK, Vector3(0, 0, -40)],
		[Vector3(0.04, 0.016, 0.012), Vector3(0.155, 0.125, -0.252), FACE_INK, Vector3(0, 0, 40)],
		[Vector3(0.034, 0.016, 0.012), Vector3(-0.14, 0.14, -0.252), FACE_INK, Vector3(0, 0, -70)],
		[Vector3(0.034, 0.016, 0.012), Vector3(0.14, 0.14, -0.252), FACE_INK, Vector3(0, 0, 70)],
		[Vector3(0.12, 0.05, 0.01), Vector3(0, -0.1, -0.251), Color("7a2a35")],
		[Vector3(0.06, 0.02, 0.012), Vector3(0, -0.115, -0.252), Color("ff8a9a")],
		[Vector3(0.075, 0.04, 0.008), Vector3(-0.16, -0.045, -0.2505), BLUSH],
		[Vector3(0.075, 0.04, 0.008), Vector3(0.16, -0.045, -0.2505), BLUSH]]},
	"face_rosy": {"anchor": FACE, "blocky_only": true, "base": "face_smile", "boxes": [
		[Vector3(0.075, 0.04, 0.008), Vector3(-0.17, -0.03, -0.2505), BLUSH],
		[Vector3(0.075, 0.04, 0.008), Vector3(0.17, -0.03, -0.2505), BLUSH]]},
	# Hair (blocky): a soft cap with full bangs under every girl style
	"hair_girl": {"anchor": HEAD, "blocky_only": true, "boxes": [
		[Vector3(0.56, 0.1, 0.56), Vector3(0, 0.27, 0), "hair"],
		[Vector3(0.56, 0.42, 0.08), Vector3(0, 0.06, 0.27), "hair"],
		[Vector3(0.06, 0.3, 0.52), Vector3(-0.28, 0.1, 0.0), "hair"],
		[Vector3(0.06, 0.3, 0.52), Vector3(0.28, 0.1, 0.0), "hair"],
		[Vector3(0.56, 0.08, 0.06), Vector3(0, 0.205, -0.265), "hair"],
		[Vector3(0.16, 0.05, 0.06), Vector3(-0.17, 0.19, -0.265), "hair"],     # side-swept, clear of the lashes
		[Vector3(0.1, 0.04, 0.06), Vector3(0.2, 0.19, -0.265), "hair"]]},
	"hair_bangs": {"anchor": HEAD, "blocky_only": true, "base": "hair_girl", "boxes": [
		[Vector3(0.58, 0.62, 0.09), Vector3(0, -0.2, 0.285), "hair"],
		[Vector3(0.07, 0.5, 0.22), Vector3(-0.29, -0.12, 0.08), "hair"],
		[Vector3(0.07, 0.5, 0.22), Vector3(0.29, -0.12, 0.08), "hair"]]},
	"hair_ponytail": {"anchor": HEAD, "blocky_only": true, "base": "hair_girl", "boxes": [
		[Vector3(0.15, 0.13, 0.07), Vector3(0, 0.17, 0.33), TIE],
		[Vector3(0.18, 0.18, 0.16), Vector3(0, 0.14, 0.42), "hair"],
		[Vector3(0.16, 0.3, 0.14), Vector3(0, -0.07, 0.46), "hair", Vector3(-8, 0, 0)],
		[Vector3(0.12, 0.2, 0.12), Vector3(0, -0.3, 0.44), "hair"]]},
	"hair_pigtails": {"anchor": HEAD, "blocky_only": true, "base": "hair_girl", "boxes": [
		[Vector3(0.07, 0.1, 0.1), Vector3(-0.32, 0.12, 0.06), TIE],
		[Vector3(0.07, 0.1, 0.1), Vector3(0.32, 0.12, 0.06), TIE],
		[Vector3(0.16, 0.28, 0.16), Vector3(-0.39, 0.0, 0.07), "hair", Vector3(0, 0, -15)],
		[Vector3(0.16, 0.28, 0.16), Vector3(0.39, 0.0, 0.07), "hair", Vector3(0, 0, 15)],
		[Vector3(0.1, 0.14, 0.1), Vector3(-0.44, -0.18, 0.07), "hair", Vector3(0, 0, -25)],
		[Vector3(0.1, 0.14, 0.1), Vector3(0.44, -0.18, 0.07), "hair", Vector3(0, 0, 25)]]},
	"hair_braid": {"anchor": HEAD, "blocky_only": true, "base": "hair_girl", "boxes": [
		[Vector3(0.14, 0.12, 0.1), Vector3(0, -0.02, 0.33), "hair", Vector3(0, 0, 30)],
		[Vector3(0.14, 0.12, 0.1), Vector3(0, -0.13, 0.33), "hair", Vector3(0, 0, -30)],
		[Vector3(0.13, 0.11, 0.1), Vector3(0, -0.24, 0.3), "hair", Vector3(0, 0, 30)],
		[Vector3(0.12, 0.11, 0.09), Vector3(0, -0.35, 0.25), "hair", Vector3(0, 0, -30)],
		[Vector3(0.11, 0.1, 0.09), Vector3(0, -0.46, 0.22), "hair", Vector3(0, 0, 30)],
		[Vector3(0.09, 0.05, 0.09), Vector3(0, -0.53, 0.22), TIE],
		[Vector3(0.1, 0.1, 0.08), Vector3(0, -0.6, 0.22), "hair"]]},
	"hair_buns": {"anchor": HEAD, "blocky_only": true, "base": "hair_girl", "boxes": [
		[Vector3(0.2, 0.2, 0.2), Vector3(-0.19, 0.38, 0.04), "hair"],
		[Vector3(0.2, 0.2, 0.2), Vector3(0.19, 0.38, 0.04), "hair"],
		[Vector3(0.21, 0.04, 0.21), Vector3(-0.19, 0.3, 0.04), TIE],
		[Vector3(0.21, 0.04, 0.21), Vector3(0.19, 0.3, 0.04), TIE]]},
	"hair_bob": {"anchor": HEAD, "blocky_only": true, "boxes": [
		[Vector3(0.58, 0.12, 0.58), Vector3(0, 0.28, 0), "hair"],
		[Vector3(0.58, 0.44, 0.1), Vector3(0, 0.04, 0.28), "hair"],
		[Vector3(0.08, 0.36, 0.54), Vector3(-0.29, 0.06, 0.01), "hair"],
		[Vector3(0.08, 0.36, 0.54), Vector3(0.29, 0.06, 0.01), "hair"],
		[Vector3(0.58, 0.1, 0.06), Vector3(0, 0.2, -0.27), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(-0.3, -0.14, -0.14), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(0.3, -0.14, -0.14), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(-0.31, -0.15, 0.08), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(0.31, -0.15, 0.08), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(-0.17, -0.15, 0.3), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(0.17, -0.15, 0.3), "hair"],
		[Vector3(0.15, 0.15, 0.15), Vector3(0, -0.16, 0.32), "hair"]]},
	# Hair on the realistic person: round shapes over its painted hair, at head scale (HEAD units)
	"hair_long_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.56, 0.74, 0.16), Vector3(0, -0.26, 0.24), "hair"],
		[Vector3(0.11, 0.46, 0.16), Vector3(-0.24, -0.2, 0.07), "hair"],
		[Vector3(0.11, 0.46, 0.16), Vector3(0.24, -0.2, 0.07), "hair"]]},
	"hair_bangs_real": {"anchor": HEAD, "shape": BALL, "base": "hair_long_real", "boxes": [   # the fringe is painted
		[Vector3(0.12, 0.3, 0.14), Vector3(-0.22, 0.02, -0.06), "hair"],
		[Vector3(0.12, 0.3, 0.14), Vector3(0.22, 0.02, -0.06), "hair"]]},
	"hair_ponytail_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.12, 0.12, 0.12), Vector3(0, 0.14, 0.31), TIE],
		[Vector3(0.2, 0.18, 0.18), Vector3(0, 0.16, 0.36), "hair"],
		[Vector3(0.18, 0.46, 0.17), Vector3(0, -0.1, 0.4), "hair", Vector3(-10, 0, 0)],
		[Vector3(0.12, 0.2, 0.12), Vector3(0, -0.36, 0.37), "hair"]]},
	"hair_pigtails_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.1, 0.1, 0.1), Vector3(-0.27, 0.1, 0.08), TIE],
		[Vector3(0.1, 0.1, 0.1), Vector3(0.27, 0.1, 0.08), TIE],
		[Vector3(0.16, 0.34, 0.16), Vector3(-0.34, -0.08, 0.1), "hair", Vector3(0, 0, -12)],
		[Vector3(0.16, 0.34, 0.16), Vector3(0.34, -0.08, 0.1), "hair", Vector3(0, 0, 12)],
		[Vector3(0.1, 0.16, 0.1), Vector3(-0.38, -0.3, 0.1), "hair"],
		[Vector3(0.1, 0.16, 0.1), Vector3(0.38, -0.3, 0.1), "hair"]]},
	"hair_braid_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.15, 0.14, 0.13), Vector3(0, 0.0, 0.3), "hair"],
		[Vector3(0.14, 0.13, 0.12), Vector3(0, -0.12, 0.3), "hair"],
		[Vector3(0.13, 0.13, 0.12), Vector3(0, -0.24, 0.27), "hair"],
		[Vector3(0.12, 0.12, 0.11), Vector3(0, -0.36, 0.22), "hair"],
		[Vector3(0.11, 0.12, 0.1), Vector3(0, -0.48, 0.19), "hair"],
		[Vector3(0.1, 0.11, 0.1), Vector3(0, -0.6, 0.18), "hair"],
		[Vector3(0.08, 0.05, 0.08), Vector3(0, -0.68, 0.18), TIE],
		[Vector3(0.09, 0.12, 0.08), Vector3(0, -0.76, 0.18), "hair"]]},
	"hair_bun_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.27, 0.25, 0.27), Vector3(0, 0.25, 0.18), "hair"],
		[Vector3(0.2, 0.06, 0.2), Vector3(0, 0.14, 0.2), TIE]]},
	"hair_buns_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.2, 0.2, 0.2), Vector3(-0.17, 0.28, 0.06), "hair"],
		[Vector3(0.2, 0.2, 0.2), Vector3(0.17, 0.28, 0.06), "hair"]]},
	"hair_bob_real": {"anchor": HEAD, "shape": BALL, "boxes": [
		[Vector3(0.16, 0.34, 0.34), Vector3(-0.23, 0.02, 0.06), "hair"],
		[Vector3(0.16, 0.34, 0.34), Vector3(0.23, 0.02, 0.06), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.25, -0.14, -0.08), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.25, -0.14, -0.08), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.26, -0.15, 0.12), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.26, -0.15, 0.12), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(-0.15, -0.15, 0.27), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.15, -0.15, 0.27), "hair"],
		[Vector3(0.16, 0.16, 0.16), Vector3(0, -0.14, 0.3), "hair"]]},
	"hair_curly_real": {"anchor": HEAD, "shape": BALL, "base": "hair_bob_real", "boxes": [
		[Vector3(0.18, 0.18, 0.18), Vector3(-0.16, 0.26, -0.06), "hair"],
		[Vector3(0.18, 0.18, 0.18), Vector3(0.16, 0.26, -0.06), "hair"],
		[Vector3(0.18, 0.18, 0.18), Vector3(-0.18, 0.24, 0.14), "hair"],
		[Vector3(0.18, 0.18, 0.18), Vector3(0.18, 0.24, 0.14), "hair"],
		[Vector3(0.18, 0.18, 0.18), Vector3(0, 0.29, 0.04), "hair"]]},
	# Hats
	"hat_clips": {"anchor": HEAD, "boxes": [
		[Vector3(0.03, 0.055, 0.055), Vector3(-0.32, 0.175, -0.125), TIE],
		[Vector3(0.03, 0.055, 0.055), Vector3(-0.32, 0.175, -0.075), TIE],
		[Vector3(0.03, 0.06, 0.06), Vector3(-0.32, 0.145, -0.1), TIE, Vector3(45, 0, 0)],
		[Vector3(0.03, 0.1, 0.03), Vector3(0.32, 0.16, -0.1), Color("ffd54f")],
		[Vector3(0.03, 0.03, 0.1), Vector3(0.32, 0.16, -0.1), Color("ffd54f")],
		[Vector3(0.03, 0.06, 0.06), Vector3(0.32, 0.16, -0.1), Color("ffd54f"), Vector3(45, 0, 0)]]},
	"hat_clips_real": {"anchor": HEAD, "boxes": [
		[Vector3(0.03, 0.055, 0.055), Vector3(-0.26, 0.135, -0.115), TIE],
		[Vector3(0.03, 0.055, 0.055), Vector3(-0.26, 0.135, -0.065), TIE],
		[Vector3(0.03, 0.06, 0.06), Vector3(-0.26, 0.105, -0.09), TIE, Vector3(45, 0, 0)],
		[Vector3(0.03, 0.1, 0.03), Vector3(0.26, 0.12, -0.09), Color("ffd54f")],
		[Vector3(0.03, 0.03, 0.1), Vector3(0.26, 0.12, -0.09), Color("ffd54f")],
		[Vector3(0.03, 0.06, 0.06), Vector3(0.26, 0.12, -0.09), Color("ffd54f"), Vector3(45, 0, 0)]]},
	"hat_flower_crown": {"anchor": HEAD, "boxes": [
		[Vector3(0.54, 0.035, 0.035), Vector3(0, 0.27, -0.26), Color("66bb6a")],
		[Vector3(0.54, 0.035, 0.035), Vector3(0, 0.27, 0.26), Color("66bb6a")],
		[Vector3(0.035, 0.035, 0.54), Vector3(-0.26, 0.27, 0), Color("66bb6a")],
		[Vector3(0.035, 0.035, 0.54), Vector3(0.26, 0.27, 0), Color("66bb6a")],
		[Vector3(0.09, 0.09, 0.035), Vector3(-0.17, 0.29, -0.28), PETAL],
		[Vector3(0.09, 0.09, 0.035), Vector3(-0.17, 0.29, -0.28), PETAL, Vector3(0, 0, 45)],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.17, 0.29, -0.3), Color("ffd54f")],
		[Vector3(0.1, 0.1, 0.035), Vector3(0, 0.3, -0.28), WHITE],
		[Vector3(0.1, 0.1, 0.035), Vector3(0, 0.3, -0.28), WHITE, Vector3(0, 0, 45)],
		[Vector3(0.045, 0.045, 0.02), Vector3(0, 0.3, -0.3), Color("ffd54f")],
		[Vector3(0.09, 0.09, 0.035), Vector3(0.17, 0.29, -0.28), Color("c7a4f0")],
		[Vector3(0.09, 0.09, 0.035), Vector3(0.17, 0.29, -0.28), Color("c7a4f0"), Vector3(0, 0, 45)],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.17, 0.29, -0.3), Color("ffd54f")],
		[Vector3(0.035, 0.09, 0.09), Vector3(-0.28, 0.29, 0.02), PETAL],
		[Vector3(0.035, 0.09, 0.09), Vector3(-0.28, 0.29, 0.02), PETAL, Vector3(45, 0, 0)],
		[Vector3(0.035, 0.09, 0.09), Vector3(0.28, 0.29, 0.02), PETAL],
		[Vector3(0.035, 0.09, 0.09), Vector3(0.28, 0.29, 0.02), PETAL, Vector3(45, 0, 0)],
		[Vector3(0.09, 0.09, 0.035), Vector3(0, 0.29, 0.28), Color("fff176")],
		[Vector3(0.09, 0.09, 0.035), Vector3(0, 0.29, 0.28), Color("fff176"), Vector3(0, 0, 45)]]},
	"hat_bow": {"anchor": HEAD, "boxes": [
		[Vector3(0.07, 0.07, 0.06), Vector3(0.13, 0.36, -0.02), Color("e8336f")],
		[Vector3(0.13, 0.11, 0.05), Vector3(0.05, 0.38, -0.02), Color("ff4f8b"), Vector3(0, 0, 20)],
		[Vector3(0.13, 0.11, 0.05), Vector3(0.21, 0.38, -0.02), Color("ff4f8b"), Vector3(0, 0, -20)],
		[Vector3(0.04, 0.1, 0.035), Vector3(0.1, 0.3, -0.02), Color("ff4f8b"), Vector3(0, 0, -15)],
		[Vector3(0.04, 0.1, 0.035), Vector3(0.16, 0.3, -0.02), Color("ff4f8b"), Vector3(0, 0, 15)]]},
	"hat_bow_real": {"anchor": HEAD, "boxes": [
		[Vector3(0.07, 0.07, 0.06), Vector3(0.13, 0.29, 0.0), Color("e8336f")],
		[Vector3(0.13, 0.11, 0.05), Vector3(0.05, 0.31, 0.0), Color("ff4f8b"), Vector3(0, 0, 20)],
		[Vector3(0.13, 0.11, 0.05), Vector3(0.21, 0.31, 0.0), Color("ff4f8b"), Vector3(0, 0, -20)],
		[Vector3(0.04, 0.1, 0.035), Vector3(0.1, 0.23, 0.0), Color("ff4f8b"), Vector3(0, 0, -15)],
		[Vector3(0.04, 0.1, 0.035), Vector3(0.16, 0.23, 0.0), Color("ff4f8b"), Vector3(0, 0, 15)]]},
	# Clothes (blocky: BODY is the torso's centre; the legs start 0.36 below it and the knees at 0.68)
	"extra_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.66, 0.08, 0.36), Vector3(0, -0.34, 0), "bottom"],
		[Vector3(0.72, 0.14, 0.42), Vector3(0, -0.44, 0), "bottom"],
		[Vector3(0.8, 0.14, 0.5), Vector3(0, -0.56, 0), "bottom"]]},
	"extra_dress_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.66, 0.08, 0.36), Vector3(0, -0.34, 0), "top"],
		[Vector3(0.72, 0.14, 0.42), Vector3(0, -0.44, 0), "top"],
		[Vector3(0.8, 0.14, 0.5), Vector3(0, -0.56, 0), "top"],
		[Vector3(0.86, 0.1, 0.56), Vector3(0, -0.67, 0), "top"],
		[Vector3(0.88, 0.03, 0.58), Vector3(0, -0.715, 0), WHITE]]},
	"extra_dress_sash": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.06, 0.34), Vector3(0, -0.26, 0), WHITE],
		[Vector3(0.16, 0.1, 0.04), Vector3(0, -0.26, 0.19), WHITE]]},
	"extra_gown_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.7, 0.14, 0.4), Vector3(0, -0.42, 0), "top"],
		[Vector3(0.8, 0.18, 0.5), Vector3(0, -0.57, 0), "top"],
		[Vector3(0.9, 0.18, 0.6), Vector3(0, -0.74, 0), "top"],
		[Vector3(0.98, 0.16, 0.68), Vector3(0, -0.9, 0), "top"],
		[Vector3(1.0, 0.04, 0.7), Vector3(0, -0.96, 0), Color("ffe082")],
		[Vector3(0.82, 0.03, 0.52), Vector3(0, -0.495, 0), Color("ffe082")]]},
	"extra_gown_sash": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.07, 0.34), Vector3(0, -0.28, 0), Color("ffd54f")],
		[Vector3(0.06, 0.06, 0.02), Vector3(0, -0.28, -0.176), Color("ff6fa8")],
		[Vector3(0.66, 0.05, 0.035), Vector3(0, 0.33, -0.16), Color("ffe082")]]},
	"extra_tunic": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.66, 0.2, 0.36), Vector3(0, -0.44, 0), "top"],
		[Vector3(0.68, 0.03, 0.38), Vector3(0, -0.535, 0), WHITE]]},
	"extra_hood": {"anchor": BACK, "boxes": [
		[Vector3(0.46, 0.2, 0.12), Vector3(0, -0.02, 0.05), "top"],
		[Vector3(0.5, 0.06, 0.14), Vector3(0, 0.08, 0.05), "top"]]},
	"extra_hoodie_pocket": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.36, 0.14, 0.03), Vector3(0, -0.2, -0.175), "top"],
		[Vector3(0.025, 0.14, 0.02), Vector3(-0.07, 0.26, -0.17), WHITE],
		[Vector3(0.025, 0.14, 0.02), Vector3(0.07, 0.26, -0.17), WHITE]]},
	"extra_overalls_bib": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.14, 0.34), Vector3(0, -0.29, 0), "bottom"],
		[Vector3(0.34, 0.28, 0.02), Vector3(0, -0.08, -0.17), "bottom"],
		[Vector3(0.07, 0.36, 0.02), Vector3(-0.13, 0.17, -0.17), "bottom"],
		[Vector3(0.07, 0.36, 0.02), Vector3(0.13, 0.17, -0.17), "bottom"],
		[Vector3(0.07, 0.6, 0.02), Vector3(-0.13, 0.05, 0.17), "bottom"],
		[Vector3(0.07, 0.6, 0.02), Vector3(0.13, 0.05, 0.17), "bottom"],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.13, 0.02, -0.182), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.13, 0.02, -0.182), GOLD]]},
	"extra_jacket_front": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.22, 0.62, 0.02), Vector3(0, -0.03, -0.165), "top"],
		[Vector3(0.08, 0.22, 0.025), Vector3(-0.13, 0.24, -0.168), Color("6e4a2a"), Vector3(0, 0, -18)],
		[Vector3(0.08, 0.22, 0.025), Vector3(0.13, 0.24, -0.168), Color("6e4a2a"), Vector3(0, 0, 18)],
		[Vector3(0.64, 0.05, 0.34), Vector3(0, -0.33, 0), Color("6e4a2a")]]},
	# Clothes on the realistic person, in metres: WAIST is its hips (the waist at y 0), BODY its chest
	"extra_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.54, 0.36, 0.44), Vector3(0, -0.18, 0), "bottom", Vector3.ZERO, false, CONE],
		[Vector3(0.34, 0.05, 0.28), Vector3(0, -0.005, 0), "bottom", Vector3.ZERO, false, TUBE]]},
	"extra_dress_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.58, 0.42, 0.48), Vector3(0, -0.21, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.6, 0.025, 0.5), Vector3(0, -0.41, 0), WHITE, Vector3.ZERO, false, TUBE]]},
	"extra_dress_sash_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.34, 0.05, 0.28), Vector3(0, 0.0, 0), WHITE, Vector3.ZERO, false, TUBE],
		[Vector3(0.08, 0.06, 0.04), Vector3(-0.04, 0.0, 0.14), WHITE, Vector3.ZERO, false, BALL],
		[Vector3(0.08, 0.06, 0.04), Vector3(0.04, 0.0, 0.14), WHITE, Vector3.ZERO, false, BALL]]},
	"extra_gown_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.46, 0.3, 0.4), Vector3(0, -0.15, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.8, 0.44, 0.7), Vector3(0, -0.5, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.82, 0.03, 0.72), Vector3(0, -0.705, 0), Color("ffe082"), Vector3.ZERO, false, TUBE]]},
	"extra_gown_sash_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.34, 0.05, 0.28), Vector3(0, 0.0, 0), Color("ffd54f"), Vector3.ZERO, false, TUBE],
		[Vector3(0.05, 0.05, 0.03), Vector3(0, 0.0, -0.14), Color("ff6fa8"), Vector3.ZERO, false, BALL]]},
	"extra_tunic_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.44, 0.22, 0.36), Vector3(0, -0.09, 0), "top", Vector3.ZERO, false, CONE]]},
	"extra_hoodie_pocket_real": {"anchor": BODY, "boxes": [
		[Vector3(0.2, 0.09, 0.02), Vector3(0, -0.12, -0.13), "top"],
		[Vector3(0.012, 0.1, 0.012), Vector3(-0.035, 0.13, -0.118), WHITE],
		[Vector3(0.012, 0.1, 0.012), Vector3(0.035, 0.13, -0.118), WHITE]]},
	"extra_overalls_bib_real": {"anchor": BODY, "boxes": [
		[Vector3(0.2, 0.17, 0.02), Vector3(0, -0.08, -0.13), "bottom"],
		[Vector3(0.04, 0.2, 0.02), Vector3(-0.075, 0.09, -0.122), "bottom"],
		[Vector3(0.04, 0.2, 0.02), Vector3(0.075, 0.09, -0.122), "bottom"],
		[Vector3(0.025, 0.025, 0.015), Vector3(-0.075, 0.0, -0.134), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.025, 0.025, 0.015), Vector3(0.075, 0.0, -0.134), GOLD, Vector3.ZERO, false, BALL]]},
	"extra_jacket_front_real": {"anchor": BODY, "boxes": [
		[Vector3(0.1, 0.32, 0.02), Vector3(0, -0.02, -0.125), "top"],
		[Vector3(0.04, 0.13, 0.02), Vector3(-0.065, 0.1, -0.12), Color("6e4a2a"), Vector3(0, 0, -15)],
		[Vector3(0.04, 0.13, 0.02), Vector3(0.065, 0.1, -0.12), Color("6e4a2a"), Vector3(0, 0, 15)]]},
	# --- M3 Task 21b: Secret Book page rewards ---
	# The Pirate Bandana: a red bandana with white dots, knotted at the back, two tails and a gold coin.
	"hat_treasure_bandana": {"anchor": HEAD, "boxes": [
		[Vector3(0.56, 0.12, 0.56), Vector3(0, 0.27, 0), Color("d32f2f")],
		[Vector3(0.56, 0.08, 0.04), Vector3(0, 0.2, -0.27), Color("c62828")],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.16, 0.24, -0.29), WHITE],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.14, 0.26, -0.29), WHITE],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.02, 0.3, -0.29), WHITE],
		[Vector3(0.05, 0.05, 0.05), Vector3(-0.12, 0.34, 0.1), WHITE],
		[Vector3(0.05, 0.05, 0.05), Vector3(0.14, 0.34, -0.06), WHITE],
		[Vector3(0.12, 0.1, 0.08), Vector3(0, 0.22, 0.3), Color("b71c1c")],
		[Vector3(0.08, 0.2, 0.03), Vector3(-0.06, 0.1, 0.33), Color("c62828"), Vector3(0, 0, 18)],
		[Vector3(0.08, 0.18, 0.03), Vector3(0.06, 0.1, 0.33), Color("c62828"), Vector3(0, 0, -14)],
		[Vector3(0.09, 0.09, 0.03), Vector3(0.23, 0.24, -0.25), GOLD, Vector3.ZERO, true, BALL]]},
	# The Storybook Cape: a deep blue cape like a book's cover, gold corners and a big star, a ribbon clasp.
	"cape_storybook": {"anchor": BACK, "sway": &"cape", "boxes": [
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("283593")],
		[Vector3(0.12, 0.12, 0.045), Vector3(-0.23, -0.9, 0.03), GOLD],
		[Vector3(0.12, 0.12, 0.045), Vector3(0.23, -0.9, 0.03), GOLD],
		[Vector3(0.5, 0.03, 0.045), Vector3(0, -0.12, 0.03), Color("ffe082")],
		[Vector3(0.16, 0.16, 0.05), Vector3(0, -0.5, 0.03), Color("ffd23f"), Vector3(0, 0, 45), true],
		[Vector3(0.08, 0.08, 0.055), Vector3(0, -0.5, 0.03), Color("fff8e1"), Vector3.ZERO, true],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), Color("c62828")]]},
	# --- Owner 36 (spec §14.6b): the Storybook costume pack. Drawn our own way from the books (never a film's look)
	# and our own genre costumes. Every part is worn by both bodies: blocky boxes, and "_real" recipes (in metres on
	# the realistic chest and hips) where the realistic person needs its own. ---
	# Hats
	"hat_alice_band": {"anchor": HEAD, "boxes": [   # Tenniel's Alice band (Through the Looking-Glass, 1871), in blue
		[Vector3(0.6, 0.05, 0.09), Vector3(0, 0.335, -0.06), Color("2f6fd0")],
		[Vector3(0.05, 0.2, 0.09), Vector3(-0.31, 0.24, -0.06), Color("2f6fd0")],
		[Vector3(0.05, 0.2, 0.09), Vector3(0.31, 0.24, -0.06), Color("2f6fd0")],
		[Vector3(0.06, 0.06, 0.05), Vector3(0.17, 0.37, -0.09), Color("1f55ad")],
		[Vector3(0.11, 0.08, 0.04), Vector3(0.1, 0.38, -0.09), Color("2f6fd0"), Vector3(0, 0, 20)],
		[Vector3(0.11, 0.08, 0.04), Vector3(0.24, 0.38, -0.09), Color("2f6fd0"), Vector3(0, 0, -20)]]},
	"hat_alice_band_real": {"anchor": HEAD, "boxes": [
		[Vector3(0.5, 0.05, 0.09), Vector3(0, 0.27, -0.05), Color("2f6fd0")],
		[Vector3(0.05, 0.18, 0.09), Vector3(-0.255, 0.18, -0.05), Color("2f6fd0")],
		[Vector3(0.05, 0.18, 0.09), Vector3(0.255, 0.18, -0.05), Color("2f6fd0")],
		[Vector3(0.06, 0.06, 0.05), Vector3(0.15, 0.3, -0.08), Color("1f55ad")],
		[Vector3(0.11, 0.08, 0.04), Vector3(0.08, 0.31, -0.08), Color("2f6fd0"), Vector3(0, 0, 20)],
		[Vector3(0.11, 0.08, 0.04), Vector3(0.22, 0.31, -0.08), Color("2f6fd0"), Vector3(0, 0, -20)]]},
	"hat_sunbonnet": {"anchor": HEAD, "cover": true, "boxes": [   # Dorothy's pink sunbonnet (Baum, 1900)
		[Vector3(0.6, 0.1, 0.56), Vector3(0, 0.3, 0.03), Color("f48fb1")],
		[Vector3(0.6, 0.48, 0.08), Vector3(0, 0.08, 0.3), Color("f48fb1")],
		[Vector3(0.07, 0.36, 0.5), Vector3(-0.31, 0.14, 0.04), Color("f48fb1")],
		[Vector3(0.07, 0.36, 0.5), Vector3(0.31, 0.14, 0.04), Color("f48fb1")],
		[Vector3(0.72, 0.12, 0.14), Vector3(0, 0.36, -0.28), Color("f06a9b"), Vector3(-15, 0, 0)],
		[Vector3(0.1, 0.4, 0.14), Vector3(-0.36, 0.14, -0.27), Color("f06a9b")],
		[Vector3(0.1, 0.4, 0.14), Vector3(0.36, 0.14, -0.27), Color("f06a9b")],
		[Vector3(0.04, 0.2, 0.03), Vector3(-0.16, -0.3, -0.24), Color("f06a9b"), Vector3(0, 0, -25)],
		[Vector3(0.04, 0.2, 0.03), Vector3(0.16, -0.3, -0.24), Color("f06a9b"), Vector3(0, 0, 25)],
		[Vector3(0.1, 0.06, 0.04), Vector3(-0.05, -0.38, -0.25), Color("f48fb1"), Vector3(0, 0, 20)],
		[Vector3(0.1, 0.06, 0.04), Vector3(0.05, -0.38, -0.25), Color("f48fb1"), Vector3(0, 0, -20)]]},
	"hat_puppet_cap": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # Pinocchio's little cap of bread (Collodi; Mazzanti's 1883 drawings)
		[Vector3(0.54, 0.05, 0.54), Vector3(0, 0.265, 0), Color("d9b77a")],
		[Vector3(0.5, 0.12, 0.5), Vector3(0, 0.34, 0), Color("f0dfb4")],
		[Vector3(0.38, 0.12, 0.38), Vector3(0, 0.46, 0.02), Color("f0dfb4")],
		[Vector3(0.26, 0.12, 0.26), Vector3(0, 0.58, 0.05), Color("f0dfb4")],
		[Vector3(0.15, 0.12, 0.15), Vector3(0, 0.7, 0.09), Color("f0dfb4")],
		[Vector3(0.08, 0.1, 0.08), Vector3(0, 0.8, 0.14), Color("f0dfb4")],
		[Vector3(0.08, 0.08, 0.08), Vector3(0, 0.86, 0.19), Color("e57373")]]},
	"hat_feather_cap": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # Robin Hood's cap (Howard Pyle, 1883)
		[Vector3(0.56, 0.05, 0.56), Vector3(0, 0.265, 0), Color("6d4a2a")],
		[Vector3(0.54, 0.12, 0.54), Vector3(0, 0.33, 0), Color("4f8a2e")],
		[Vector3(0.3, 0.1, 0.46), Vector3(0, 0.43, 0.02), Color("4f8a2e")],
		[Vector3(0.22, 0.06, 0.22), Vector3(0, 0.3, -0.33), Color("3f7424"), Vector3(0, 45, 0)],
		[Vector3(0.04, 0.03, 0.42), Vector3(0.28, 0.44, 0.1), Color("d84330"), Vector3(-25, 0, 0)],
		[Vector3(0.03, 0.03, 0.16), Vector3(0.28, 0.55, 0.32), Color("d84330"), Vector3(-45, 0, 0)],
		[Vector3(0.05, 0.02, 0.3), Vector3(0.28, 0.43, 0.12), Color("ef8a6a"), Vector3(-25, 0, 0)]]},
	"hat_hatter": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # the Hatter's hat with its "10/6" price card (Tenniel, 1865)
		[Vector3(0.7, 0.04, 0.7), Vector3(0, 0.27, 0), Color("4a4e57")],
		[Vector3(0.44, 0.3, 0.44), Vector3(0, 0.44, 0), Color("4a4e57")],
		[Vector3(0.5, 0.2, 0.5), Vector3(0, 0.69, 0), Color("4a4e57")],
		[Vector3(0.52, 0.03, 0.52), Vector3(0, 0.795, 0), Color("3a3d45")],
		[Vector3(0.46, 0.08, 0.46), Vector3(0, 0.34, 0), Color("e8dcc0")],
		[Vector3(0.14, 0.1, 0.02), Vector3(0.1, 0.42, -0.235), WHITE],
		[Vector3(0.012, 0.05, 0.005), Vector3(0.155, 0.42, -0.247), FACE_INK],
		[Vector3(0.01, 0.05, 0.005), Vector3(0.135, 0.42, -0.247), FACE_INK],
		[Vector3(0.01, 0.05, 0.005), Vector3(0.115, 0.42, -0.247), FACE_INK],
		[Vector3(0.03, 0.01, 0.005), Vector3(0.125, 0.445, -0.247), FACE_INK],
		[Vector3(0.03, 0.01, 0.005), Vector3(0.125, 0.395, -0.247), FACE_INK],
		[Vector3(0.01, 0.055, 0.005), Vector3(0.095, 0.42, -0.247), FACE_INK, Vector3(0, 0, 25)],
		[Vector3(0.01, 0.05, 0.005), Vector3(0.07, 0.42, -0.247), FACE_INK],
		[Vector3(0.03, 0.01, 0.005), Vector3(0.06, 0.395, -0.247), FACE_INK],
		[Vector3(0.03, 0.01, 0.005), Vector3(0.06, 0.42, -0.247), FACE_INK],
		[Vector3(0.025, 0.01, 0.005), Vector3(0.06, 0.445, -0.247), FACE_INK],
		[Vector3(0.01, 0.025, 0.005), Vector3(0.05, 0.407, -0.247), FACE_INK]]},
	"hat_deerstalker": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # the travelling cap of Sidney Paget's drawings (1891)
		[Vector3(0.56, 0.14, 0.56), Vector3(0, 0.31, 0), Color("8a7456")],
		[Vector3(0.44, 0.06, 0.44), Vector3(0, 0.4, 0), Color("8a7456")],
		[Vector3(0.44, 0.04, 0.2), Vector3(0, 0.26, -0.35), Color("7a6448")],
		[Vector3(0.44, 0.04, 0.2), Vector3(0, 0.26, 0.35), Color("7a6448")],
		[Vector3(0.57, 0.015, 0.57), Vector3(0, 0.29, 0), Color("5e4d38")],
		[Vector3(0.57, 0.015, 0.57), Vector3(0, 0.35, 0), Color("5e4d38")],
		[Vector3(0.015, 0.14, 0.57), Vector3(-0.1, 0.31, 0), Color("5e4d38")],
		[Vector3(0.015, 0.14, 0.57), Vector3(0.1, 0.31, 0), Color("5e4d38")],
		[Vector3(0.57, 0.14, 0.015), Vector3(0, 0.31, -0.1), Color("5e4d38")],
		[Vector3(0.57, 0.14, 0.015), Vector3(0, 0.31, 0.1), Color("5e4d38")],
		[Vector3(0.06, 0.16, 0.24), Vector3(-0.27, 0.38, 0), Color("7a6448"), Vector3(0, 0, -30)],
		[Vector3(0.06, 0.16, 0.24), Vector3(0.27, 0.38, 0), Color("7a6448"), Vector3(0, 0, 30)],
		[Vector3(0.12, 0.04, 0.06), Vector3(0, 0.45, 0), Color("5e4d38")]]},
	"hat_merlin_hat": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # a tall forest-green hat with a gold band, no stars and no brim
		[Vector3(0.56, 0.1, 0.56), Vector3(0, 0.3, 0), Color("2e6b3f")],
		[Vector3(0.58, 0.05, 0.58), Vector3(0, 0.28, 0), Color("e0b43a")],
		[Vector3(0.46, 0.16, 0.46), Vector3(0, 0.43, 0.01), Color("2e6b3f")],
		[Vector3(0.36, 0.16, 0.36), Vector3(0, 0.59, 0.03), Color("2e6b3f")],
		[Vector3(0.26, 0.16, 0.26), Vector3(0, 0.75, 0.06), Color("2e6b3f")],
		[Vector3(0.16, 0.14, 0.16), Vector3(0, 0.9, 0.1), Color("2e6b3f")],
		[Vector3(0.08, 0.1, 0.08), Vector3(0, 1.0, 0.15), Color("2e6b3f")],
		[Vector3(0.07, 0.07, 0.02), Vector3(0, 0.28, -0.295), Color("7cb342"), Vector3(0, 0, 45)]]},
	"hat_turban": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # One Thousand and One Nights: our own saffron turban
		[Vector3(0.6, 0.12, 0.6), Vector3(0, 0.28, 0), Color("f2a33a")],
		[Vector3(0.58, 0.1, 0.58), Vector3(0, 0.38, 0), Color("f7b955")],
		[Vector3(0.48, 0.1, 0.48), Vector3(0, 0.47, 0), Color("f2a33a")],
		[Vector3(0.32, 0.08, 0.32), Vector3(0, 0.54, 0), Color("f7b955")],
		[Vector3(0.62, 0.05, 0.1), Vector3(0, 0.33, -0.28), Color("d98524"), Vector3(0, 0, 18)],
		[Vector3(0.08, 0.08, 0.03), Vector3(0, 0.36, -0.315), Color("2e7dd6"), Vector3(0, 0, 45)],
		[Vector3(0.04, 0.22, 0.03), Vector3(0.02, 0.5, -0.3), WHITE, Vector3(0, 0, -10)]]},
	"hat_lion_hood": {"anchor": HEAD, "cover": true, "boxes": [   # the Nemean lion's skin (Greek myth)
		[Vector3(0.6, 0.12, 0.62), Vector3(0, 0.3, 0), Color("d9a441")],
		[Vector3(0.6, 0.56, 0.1), Vector3(0, 0.04, 0.29), Color("d9a441")],
		[Vector3(0.07, 0.44, 0.6), Vector3(-0.29, 0.1, 0), Color("d9a441")],
		[Vector3(0.07, 0.44, 0.6), Vector3(0.29, 0.1, 0), Color("d9a441")],
		[Vector3(0.56, 0.42, 0.06), Vector3(0, -0.42, 0.3), Color("d9a441")],
		[Vector3(0.74, 0.14, 0.14), Vector3(0, 0.36, -0.22), Color("b5762a")],
		[Vector3(0.14, 0.5, 0.16), Vector3(-0.35, 0.06, -0.18), Color("b5762a")],
		[Vector3(0.14, 0.5, 0.16), Vector3(0.35, 0.06, -0.18), Color("b5762a")],
		[Vector3(0.3, 0.12, 0.16), Vector3(0, 0.3, -0.37), Color("e6b85c")],
		[Vector3(0.1, 0.06, 0.04), Vector3(0, 0.34, -0.46), Color("4a2c1a")],
		[Vector3(0.07, 0.06, 0.03), Vector3(-0.1, 0.42, -0.3), WHITE],
		[Vector3(0.07, 0.06, 0.03), Vector3(0.1, 0.42, -0.3), WHITE],
		[Vector3(0.035, 0.04, 0.02), Vector3(-0.1, 0.42, -0.317), BLACK],
		[Vector3(0.035, 0.04, 0.02), Vector3(0.1, 0.42, -0.317), BLACK],
		[Vector3(0.1, 0.1, 0.06), Vector3(-0.2, 0.44, -0.06), Color("b5762a")],
		[Vector3(0.1, 0.1, 0.06), Vector3(0.2, 0.44, -0.06), Color("b5762a")]]},
	"hat_nautilus_cap": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # Verne's Nautilus flag: a golden N on dark blue
		[Vector3(0.58, 0.1, 0.58), Vector3(0, 0.35, 0), Color("1f2a44")],
		[Vector3(0.54, 0.08, 0.54), Vector3(0, 0.27, 0), Color("15151a")],
		[Vector3(0.46, 0.03, 0.2), Vector3(0, 0.24, -0.34), Color("15151a")],
		[Vector3(0.56, 0.02, 0.02), Vector3(0, 0.305, -0.28), GOLD],
		[Vector3(0.018, 0.07, 0.01), Vector3(-0.03, 0.35, -0.294), GOLD],
		[Vector3(0.018, 0.07, 0.01), Vector3(0.03, 0.35, -0.294), GOLD],
		[Vector3(0.018, 0.085, 0.01), Vector3(0, 0.35, -0.294), GOLD, Vector3(0, 0, -38)]]},
	"hat_wizard_hat": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # our wizard school's hat: purple, a gold band, a star on top
		[Vector3(0.72, 0.04, 0.72), Vector3(0, 0.27, 0), Color("6a3fb5")],
		[Vector3(0.48, 0.14, 0.48), Vector3(0, 0.36, 0), Color("6a3fb5")],
		[Vector3(0.5, 0.05, 0.5), Vector3(0, 0.32, 0), GOLD],
		[Vector3(0.36, 0.14, 0.36), Vector3(0, 0.5, 0.01), Color("6a3fb5")],
		[Vector3(0.24, 0.14, 0.24), Vector3(0, 0.64, 0.03), Color("6a3fb5")],
		[Vector3(0.13, 0.12, 0.13), Vector3(0, 0.77, 0.06), Color("6a3fb5")],
		[Vector3(0.1, 0.1, 0.03), Vector3(0, 0.87, 0.06), Color("ffe27a"), Vector3(0, 0, 45), true],
		[Vector3(0.1, 0.1, 0.03), Vector3(0, 0.87, 0.06), Color("ffe27a"), Vector3.ZERO, true]]},
	"hat_tricorn": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [   # our own captain's tricorn with gold trim (no feather, no skull)
		[Vector3(0.72, 0.05, 0.52), Vector3(0, 0.28, 0), Color("2b2320")],
		[Vector3(0.48, 0.18, 0.42), Vector3(0, 0.39, 0.02), Color("2b2320")],
		[Vector3(0.72, 0.1, 0.04), Vector3(0, 0.34, -0.25), Color("2b2320"), Vector3(-20, 0, 0)],
		[Vector3(0.04, 0.1, 0.5), Vector3(-0.35, 0.34, 0.02), Color("2b2320"), Vector3(0, 0, 20)],
		[Vector3(0.04, 0.1, 0.5), Vector3(0.35, 0.34, 0.02), Color("2b2320"), Vector3(0, 0, -20)],
		[Vector3(0.74, 0.025, 0.025), Vector3(0, 0.39, -0.27), GOLD, Vector3(-20, 0, 0)],
		[Vector3(0.025, 0.025, 0.5), Vector3(-0.38, 0.39, 0.02), GOLD, Vector3(0, 0, 20)],
		[Vector3(0.025, 0.025, 0.5), Vector3(0.38, 0.39, 0.02), GOLD, Vector3(0, 0, -20)],
		[Vector3(0.08, 0.08, 0.03), Vector3(0.18, 0.35, -0.28), GOLD, Vector3(-20, 0, 45)]]},
	# Faces (blocky; the realistic face is painted, and wears only these add-ons)
	"face_long_nose": {"anchor": FACE, "blocky_only": true, "base": "face_smile", "boxes": [   # Pinocchio (Collodi, 1883)
		[Vector3(0.06, 0.06, 0.24), Vector3(0, -0.01, -0.37), Color("c8955a")],
		[Vector3(0.05, 0.05, 0.03), Vector3(0, -0.01, -0.49), Color("b8844d")],
		[Vector3(0.07, 0.05, 0.008), Vector3(-0.16, -0.06, -0.2505), Color("ef6b6b")],
		[Vector3(0.07, 0.05, 0.008), Vector3(0.16, -0.06, -0.2505), Color("ef6b6b")]]},
	"face_long_nose_real": {"anchor": FACE, "boxes": [
		[Vector3(0.06, 0.06, 0.3), Vector3(0, 0.0, -0.38), Color("c8955a"), Vector3.ZERO, false, BALL]]},
	"face_beard": {"anchor": FACE, "blocky_only": true, "base": "face_smile", "boxes": [   # Merlin's long beard, in the hair colour
		[Vector3(0.26, 0.05, 0.03), Vector3(0, -0.06, -0.265), "hair"],
		[Vector3(0.06, 0.04, 0.03), Vector3(-0.14, -0.08, -0.265), "hair", Vector3(0, 0, 20)],
		[Vector3(0.06, 0.04, 0.03), Vector3(0.14, -0.08, -0.265), "hair", Vector3(0, 0, -20)],
		[Vector3(0.05, 0.2, 0.1), Vector3(-0.25, -0.1, -0.21), "hair"],
		[Vector3(0.05, 0.2, 0.1), Vector3(0.25, -0.1, -0.21), "hair"],
		[Vector3(0.46, 0.2, 0.05), Vector3(0, -0.18, -0.255), "hair"],
		[Vector3(0.36, 0.22, 0.05), Vector3(0, -0.38, -0.23), "hair"],
		[Vector3(0.2, 0.14, 0.05), Vector3(0, -0.55, -0.22), "hair"]]},
	"face_beard_real": {"anchor": FACE, "boxes": [
		[Vector3(0.22, 0.05, 0.06), Vector3(0, -0.11, -0.25), "hair", Vector3.ZERO, false, BALL],
		[Vector3(0.34, 0.46, 0.14), Vector3(0, -0.33, -0.2), "hair", Vector3.ZERO, false, BALL]]},
	# Capes and back pieces
	"cape_cube": {"anchor": BACK, "sway": &"cape", "boxes": [   # our own Cube Hero: a golden block, not anyone's emblem
		[Vector3(0.58, 0.95, 0.04), Vector3(0, -0.48, 0.03), Color("f57c00")],
		[Vector3(0.62, 0.06, 0.06), Vector3(0, 0.0, 0.02), Color("ffd23f")],
		[Vector3(0.24, 0.24, 0.045), Vector3(0, -0.38, 0.035), Color("ffd23f")],
		[Vector3(0.085, 0.085, 0.05), Vector3(-0.05, -0.33, 0.035), Color("fff176")],
		[Vector3(0.085, 0.085, 0.05), Vector3(0.05, -0.33, 0.035), Color("ffb300")],
		[Vector3(0.085, 0.085, 0.05), Vector3(-0.05, -0.43, 0.035), Color("ffb300")],
		[Vector3(0.085, 0.085, 0.05), Vector3(0.05, -0.43, 0.035), Color("fff176")]]},
	"cape_parrot": {"anchor": BACK, "boxes": [   # a parrot on the right shoulder (Treasure Island's Captain Flint, 1883)
		[Vector3(0.12, 0.16, 0.13), Vector3(0.42, 0.1, -0.16), Color("e53935")],
		[Vector3(0.11, 0.11, 0.11), Vector3(0.42, 0.23, -0.19), Color("e53935")],
		[Vector3(0.05, 0.06, 0.05), Vector3(0.42, 0.21, -0.26), Color("ffd54f")],
		[Vector3(0.03, 0.03, 0.03), Vector3(0.42, 0.19, -0.28), Color("3e2723")],
		[Vector3(0.02, 0.035, 0.035), Vector3(0.365, 0.25, -0.2), WHITE],
		[Vector3(0.02, 0.035, 0.035), Vector3(0.475, 0.25, -0.2), WHITE],
		[Vector3(0.022, 0.018, 0.018), Vector3(0.36, 0.25, -0.205), BLACK],
		[Vector3(0.022, 0.018, 0.018), Vector3(0.48, 0.25, -0.205), BLACK],
		[Vector3(0.03, 0.14, 0.11), Vector3(0.355, 0.1, -0.15), Color("1e88e5")],
		[Vector3(0.03, 0.14, 0.11), Vector3(0.485, 0.1, -0.15), Color("1e88e5")],
		[Vector3(0.08, 0.2, 0.04), Vector3(0.42, -0.02, -0.08), Color("1e88e5"), Vector3(-35, 0, 0)],
		[Vector3(0.06, 0.06, 0.042), Vector3(0.42, -0.1, -0.02), Color("ffd54f"), Vector3(-35, 0, 0)],
		[Vector3(0.08, 0.02, 0.06), Vector3(0.42, 0.01, -0.17), Color("5d4037")]]},
	"extra_quiver": {"anchor": BACK, "boxes": [   # Robin Hood's arrows
		[Vector3(0.14, 0.46, 0.12), Vector3(0.08, -0.3, 0.08), Color("8d5a2b"), Vector3(0, 0, -22)],
		[Vector3(0.16, 0.04, 0.14), Vector3(0.166, -0.087, 0.08), Color("5d3a1a"), Vector3(0, 0, -22)],
		[Vector3(0.02, 0.14, 0.02), Vector3(0.19, -0.02, 0.07), Color("d7b98c"), Vector3(0, 0, -22)],
		[Vector3(0.02, 0.14, 0.02), Vector3(0.16, 0.0, 0.1), Color("d7b98c"), Vector3(0, 0, -22)],
		[Vector3(0.05, 0.07, 0.02), Vector3(0.215, 0.05, 0.07), Color("d84330"), Vector3(0, 0, -22)],
		[Vector3(0.05, 0.07, 0.02), Vector3(0.19, 0.07, 0.1), WHITE, Vector3(0, 0, -22)],
		[Vector3(0.05, 0.07, 0.02), Vector3(0.235, 0.03, 0.05), Color("d84330"), Vector3(0, 0, -22)]]},
	# Clothes (blocky: BODY is the torso's centre; the legs start 0.36 below it and the knees at 0.68)
	"extra_pinafore_bib": {"anchor": BODY, "blocky_only": true, "boxes": [   # Alice's white pinafore (Tenniel)
		[Vector3(0.36, 0.34, 0.02), Vector3(0, 0.06, -0.17), WHITE],
		[Vector3(0.07, 0.14, 0.02), Vector3(-0.145, 0.29, -0.17), WHITE],
		[Vector3(0.07, 0.14, 0.02), Vector3(0.145, 0.29, -0.17), WHITE],
		[Vector3(0.07, 0.02, 0.34), Vector3(-0.145, 0.37, 0), WHITE],
		[Vector3(0.07, 0.02, 0.34), Vector3(0.145, 0.37, 0), WHITE],
		[Vector3(0.07, 0.62, 0.02), Vector3(-0.145, 0.05, 0.17), WHITE],
		[Vector3(0.07, 0.62, 0.02), Vector3(0.145, 0.05, 0.17), WHITE]]},
	"extra_pinafore_apron": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.05, 0.34), Vector3(0, -0.3, 0), WHITE],
		[Vector3(0.44, 0.08, 0.02), Vector3(0, -0.34, -0.19), WHITE],
		[Vector3(0.5, 0.14, 0.02), Vector3(0, -0.44, -0.22), WHITE],
		[Vector3(0.56, 0.14, 0.02), Vector3(0, -0.56, -0.26), WHITE],
		[Vector3(0.6, 0.1, 0.02), Vector3(0, -0.665, -0.29), WHITE],
		[Vector3(0.08, 0.07, 0.04), Vector3(0, -0.3, 0.19), WHITE],
		[Vector3(0.12, 0.09, 0.03), Vector3(-0.09, -0.29, 0.19), WHITE, Vector3(0, 0, 20)],
		[Vector3(0.12, 0.09, 0.03), Vector3(0.09, -0.29, 0.19), WHITE, Vector3(0, 0, -20)],
		[Vector3(0.05, 0.18, 0.02), Vector3(-0.05, -0.42, 0.2), WHITE, Vector3(0, 0, -10)],
		[Vector3(0.05, 0.18, 0.02), Vector3(0.05, -0.42, 0.2), WHITE, Vector3(0, 0, 10)]]},
	"extra_tailcoat_front": {"anchor": BODY, "blocky_only": true, "boxes": [   # the Hatter's coat, waistcoat and bow tie
		[Vector3(0.26, 0.46, 0.02), Vector3(0, -0.06, -0.168), Color("e8c547")],
		[Vector3(0.26, 0.015, 0.022), Vector3(0, 0.04, -0.169), Color("c9a227")],
		[Vector3(0.26, 0.015, 0.022), Vector3(0, -0.12, -0.169), Color("c9a227")],
		[Vector3(0.015, 0.46, 0.022), Vector3(-0.06, -0.06, -0.169), Color("c9a227")],
		[Vector3(0.015, 0.46, 0.022), Vector3(0.06, -0.06, -0.169), Color("c9a227")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0, 0.08, -0.18), Color("8d6e1f")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0, -0.02, -0.18), Color("8d6e1f")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0, -0.12, -0.18), Color("8d6e1f")],
		[Vector3(0.09, 0.26, 0.025), Vector3(-0.15, 0.2, -0.172), "top", Vector3(0, 0, 18)],
		[Vector3(0.09, 0.26, 0.025), Vector3(0.15, 0.2, -0.172), "top", Vector3(0, 0, -18)],
		[Vector3(0.2, 0.06, 0.025), Vector3(0, 0.33, -0.17), WHITE],
		[Vector3(0.1, 0.08, 0.03), Vector3(-0.06, 0.3, -0.185), Color("d32f2f"), Vector3(0, 0, 15)],
		[Vector3(0.1, 0.08, 0.03), Vector3(0.06, 0.3, -0.185), Color("d32f2f"), Vector3(0, 0, -15)],
		[Vector3(0.05, 0.05, 0.035), Vector3(0, 0.3, -0.19), Color("b71c1c")],
		[Vector3(0.02, 0.02, 0.032), Vector3(-0.07, 0.31, -0.19), WHITE],
		[Vector3(0.02, 0.02, 0.032), Vector3(0.07, 0.29, -0.19), WHITE]]},
	"extra_tailcoat_tails": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.05, 0.34), Vector3(0, -0.33, 0), "top"],
		[Vector3(0.2, 0.5, 0.03), Vector3(-0.11, -0.56, 0.17), "top", Vector3(0, 0, 4)],
		[Vector3(0.2, 0.5, 0.03), Vector3(0.11, -0.56, 0.17), "top", Vector3(0, 0, -4)]]},
	"extra_paper_flowers": {"anchor": BODY, "blocky_only": true, "boxes": [   # Pinocchio's suit of flowered paper
		[Vector3(0.12, 0.07, 0.025), Vector3(-0.08, 0.32, -0.17), WHITE, Vector3(0, 0, 25)],
		[Vector3(0.12, 0.07, 0.025), Vector3(0.08, 0.32, -0.17), WHITE, Vector3(0, 0, -25)],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.2, 0.2, -0.168), Color("e53935"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.12, 0.2, -0.168), Color("1e88e5"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.05, 0.05, -0.168), Color("fdd835"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.2, 0.0, -0.168), Color("e53935"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.18, -0.14, -0.168), Color("1e88e5"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.06, -0.2, -0.168), Color("fdd835"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.15, 0.15, 0.168), Color("fdd835"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(0.15, -0.05, 0.168), Color("e53935"), Vector3(0, 0, 45)],
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.05, -0.22, 0.168), Color("1e88e5"), Vector3(0, 0, 45)]]},
	"extra_archer_tunic": {"anchor": BODY, "blocky_only": true, "boxes": [   # Robin Hood's belted tunic (Pyle)
		[Vector3(0.66, 0.2, 0.36), Vector3(0, -0.45, 0), "top"],
		[Vector3(0.09, 0.09, 0.37), Vector3(-0.24, -0.55, 0), "top", Vector3(0, 0, 45)],
		[Vector3(0.09, 0.09, 0.37), Vector3(-0.08, -0.55, 0), "top", Vector3(0, 0, 45)],
		[Vector3(0.09, 0.09, 0.37), Vector3(0.08, -0.55, 0), "top", Vector3(0, 0, 45)],
		[Vector3(0.09, 0.09, 0.37), Vector3(0.24, -0.55, 0), "top", Vector3(0, 0, 45)],
		[Vector3(0.64, 0.06, 0.34), Vector3(0, -0.32, 0), Color("5d3a1a")],
		[Vector3(0.08, 0.07, 0.02), Vector3(0, -0.32, -0.175), GOLD],
		[Vector3(0.05, 0.84, 0.02), Vector3(0, 0.0, -0.168), Color("6d4a2a"), Vector3(0, 0, -38)],
		[Vector3(0.05, 0.84, 0.02), Vector3(0, 0.0, 0.168), Color("6d4a2a"), Vector3(0, 0, -38)]]},
	"extra_tabard": {"anchor": BODY, "blocky_only": true, "boxes": [   # King Arthur's arms: three gold crowns on blue
		[Vector3(0.44, 0.72, 0.02), Vector3(0, 0.0, -0.17), "top"],
		[Vector3(0.44, 0.72, 0.02), Vector3(0, 0.0, 0.17), "top"],
		[Vector3(0.44, 0.02, 0.34), Vector3(0, 0.37, 0), "top"],
		[Vector3(0.09, 0.035, 0.01), Vector3(-0.09, 0.17, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(-0.126, 0.2, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(-0.09, 0.2, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(-0.054, 0.2, -0.182), GOLD],
		[Vector3(0.09, 0.035, 0.01), Vector3(0.09, 0.17, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(0.054, 0.2, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(0.09, 0.2, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(0.126, 0.2, -0.182), GOLD],
		[Vector3(0.09, 0.035, 0.01), Vector3(0, 0.02, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(-0.036, 0.05, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(0, 0.05, -0.182), GOLD],
		[Vector3(0.018, 0.03, 0.01), Vector3(0.036, 0.05, -0.182), GOLD]]},
	"extra_tabard_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.44, 0.3, 0.02), Vector3(0, -0.49, -0.17), "top"],
		[Vector3(0.44, 0.3, 0.02), Vector3(0, -0.49, 0.17), "top"],
		[Vector3(0.45, 0.03, 0.025), Vector3(0, -0.63, -0.172), GOLD],
		[Vector3(0.45, 0.03, 0.025), Vector3(0, -0.63, 0.172), GOLD],
		[Vector3(0.64, 0.06, 0.35), Vector3(0, -0.33, 0), Color("4e342e")],
		[Vector3(0.08, 0.07, 0.02), Vector3(0, -0.33, -0.18), GOLD]]},
	"extra_robe_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [   # a wizard's robe to the floor
		[Vector3(0.68, 0.2, 0.38), Vector3(0, -0.44, 0), "top"],
		[Vector3(0.72, 0.2, 0.42), Vector3(0, -0.63, 0), "top"],
		[Vector3(0.76, 0.24, 0.46), Vector3(0, -0.84, 0), "top"],
		[Vector3(0.78, 0.03, 0.48), Vector3(0, -0.945, 0), GOLD],
		[Vector3(0.05, 0.2, 0.02), Vector3(0, -0.44, -0.2), GOLD],
		[Vector3(0.05, 0.2, 0.02), Vector3(0, -0.63, -0.22), GOLD],
		[Vector3(0.05, 0.24, 0.02), Vector3(0, -0.84, -0.24), GOLD],
		[Vector3(0.64, 0.04, 0.34), Vector3(0, -0.32, 0), GOLD],
		[Vector3(0.04, 0.14, 0.03), Vector3(0.12, -0.4, -0.19), GOLD]]},
	"extra_robe_crest": {"anchor": BODY, "blocky_only": true, "boxes": [   # our own crest: a gold shield with a star
		[Vector3(0.05, 0.72, 0.02), Vector3(0, 0.0, -0.168), GOLD],
		[Vector3(0.13, 0.1, 0.02), Vector3(0.14, 0.15, -0.17), GOLD],
		[Vector3(0.09, 0.09, 0.02), Vector3(0.14, 0.1, -0.17), GOLD, Vector3(0, 0, 45)],
		[Vector3(0.09, 0.07, 0.022), Vector3(0.14, 0.15, -0.172), "top"],
		[Vector3(0.035, 0.035, 0.024), Vector3(0.14, 0.145, -0.174), WHITE, Vector3(0, 0, 45), true],
		[Vector3(0.035, 0.035, 0.024), Vector3(0.14, 0.145, -0.174), WHITE, Vector3.ZERO, true]]},
	"extra_coat_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [   # a coat to the knees
		[Vector3(0.68, 0.16, 0.38), Vector3(0, -0.44, 0), "top"],
		[Vector3(0.72, 0.16, 0.42), Vector3(0, -0.6, 0), "top"],
		[Vector3(0.015, 0.16, 0.01), Vector3(0, -0.44, -0.195), Color("2b2b2e")],
		[Vector3(0.015, 0.16, 0.01), Vector3(0, -0.6, -0.215), Color("2b2b2e")]]},
	"extra_inverness_cape": {"anchor": BODY, "blocky_only": true, "boxes": [   # the shoulder cape of Paget's Holmes
		[Vector3(0.86, 0.24, 0.42), Vector3(0, 0.25, 0), "top"],
		[Vector3(0.87, 0.015, 0.43), Vector3(0, 0.2, 0), Color("5b5f66")],
		[Vector3(0.87, 0.015, 0.43), Vector3(0, 0.29, 0), Color("5b5f66")],
		[Vector3(0.015, 0.24, 0.43), Vector3(-0.2, 0.25, 0), Color("5b5f66")],
		[Vector3(0.015, 0.24, 0.43), Vector3(0.2, 0.25, 0), Color("5b5f66")],
		[Vector3(0.035, 0.035, 0.02), Vector3(0.05, 0.05, -0.172), BLACK],
		[Vector3(0.035, 0.035, 0.02), Vector3(0.05, -0.07, -0.172), BLACK],
		[Vector3(0.035, 0.035, 0.02), Vector3(0.05, -0.19, -0.172), BLACK]]},
	"extra_magnifier": {"anchor": BODY, "blocky_only": true, "boxes": [   # "a large round magnifying glass" (1887)
		[Vector3(0.03, 0.12, 0.03), Vector3(0.23, -0.33, -0.2), Color("6d4c2f"), Vector3(0, 0, -20)],
		[Vector3(0.11, 0.11, 0.02), Vector3(0.26, -0.22, -0.2), GOLD],
		[Vector3(0.08, 0.08, 0.024), Vector3(0.26, -0.22, -0.2), Color("b3e5fc")]]},
	"extra_gingham_checks": {"anchor": BODY, "blocky_only": true, "boxes": [   # "checks of white and blue" (Baum)
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.2325, 0.29, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.2325, 0.29, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.0775, 0.29, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.0775, 0.29, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.0775, 0.135, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.0775, 0.135, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.2325, 0.135, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.2325, 0.135, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.2325, -0.02, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.2325, -0.02, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.0775, -0.02, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.0775, -0.02, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.0775, -0.175, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.0775, -0.175, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.2325, -0.175, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.2325, -0.175, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.2325, -0.33, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.2325, -0.33, 0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(0.0775, -0.33, -0.163), WHITE],
		[Vector3(0.155, 0.155, 0.01), Vector3(-0.0775, -0.33, 0.163), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(-0.288, -0.44, -0.213), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(0.288, -0.44, 0.213), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(0, -0.44, -0.213), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(-0, -0.44, 0.213), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(0.288, -0.44, -0.213), WHITE],
		[Vector3(0.144, 0.13, 0.01), Vector3(-0.288, -0.44, 0.213), WHITE],
		[Vector3(0.16, 0.13, 0.01), Vector3(-0.16, -0.56, -0.253), WHITE],
		[Vector3(0.16, 0.13, 0.01), Vector3(0.16, -0.56, 0.253), WHITE],
		[Vector3(0.16, 0.13, 0.01), Vector3(0.16, -0.56, -0.253), WHITE],
		[Vector3(0.16, 0.13, 0.01), Vector3(-0.16, -0.56, 0.253), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(-0.344, -0.67, -0.283), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(0.344, -0.67, 0.283), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(-0, -0.67, -0.283), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(0, -0.67, 0.283), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(0.344, -0.67, -0.283), WHITE],
		[Vector3(0.172, 0.09, 0.01), Vector3(-0.344, -0.67, 0.283), WHITE]]},
	"extra_kaftan_sash": {"anchor": BODY, "blocky_only": true, "boxes": [   # Aladdin's kaftan and golden sash
		[Vector3(0.64, 0.08, 0.35), Vector3(0, -0.3, 0), GOLD],
		[Vector3(0.08, 0.08, 0.03), Vector3(-0.16, -0.3, -0.18), Color("d9a520")],
		[Vector3(0.06, 0.2, 0.02), Vector3(-0.15, -0.44, -0.2), GOLD, Vector3(0, 0, 8)],
		[Vector3(0.06, 0.16, 0.02), Vector3(-0.2, -0.42, -0.2), GOLD, Vector3(0, 0, -10)],
		[Vector3(0.035, 0.5, 0.02), Vector3(-0.06, 0.08, -0.168), GOLD, Vector3(0, 0, -18)],
		[Vector3(0.3, 0.05, 0.025), Vector3(0, 0.33, -0.168), GOLD]]},
	"extra_lamp": {"anchor": BODY, "blocky_only": true, "boxes": [   # the wonderful lamp at the sash
		[Vector3(0.09, 0.06, 0.13), Vector3(0.2, -0.4, -0.24), Color("f5c542")],
		[Vector3(0.05, 0.04, 0.05), Vector3(0.2, -0.355, -0.23), Color("e0a81e")],
		[Vector3(0.03, 0.03, 0.1), Vector3(0.2, -0.385, -0.33), Color("f5c542"), Vector3(-20, 0, 0)],
		[Vector3(0.02, 0.06, 0.04), Vector3(0.2, -0.39, -0.16), Color("e0a81e")]]},
	"extra_chiton": {"anchor": BODY, "blocky_only": true, "boxes": [   # a Greek tunic with a gold belt
		[Vector3(0.66, 0.22, 0.36), Vector3(0, -0.45, 0), "top"],
		[Vector3(0.015, 0.22, 0.01), Vector3(-0.24, -0.45, -0.182), Color("d9d4c7")],
		[Vector3(0.015, 0.22, 0.01), Vector3(-0.12, -0.45, -0.182), Color("d9d4c7")],
		[Vector3(0.015, 0.22, 0.01), Vector3(0, -0.45, -0.182), Color("d9d4c7")],
		[Vector3(0.015, 0.22, 0.01), Vector3(0.12, -0.45, -0.182), Color("d9d4c7")],
		[Vector3(0.015, 0.22, 0.01), Vector3(0.24, -0.45, -0.182), Color("d9d4c7")],
		[Vector3(0.64, 0.05, 0.35), Vector3(0, -0.32, 0), GOLD],
		[Vector3(0.67, 0.025, 0.37), Vector3(0, -0.555, 0), GOLD]]},
	"extra_chiton_drape": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.12, 0.9, 0.025), Vector3(0, 0.02, -0.17), Color("e6e1d6"), Vector3(0, 0, 31)],
		[Vector3(0.12, 0.9, 0.025), Vector3(0, 0.02, 0.17), Color("e6e1d6"), Vector3(0, 0, 31)],
		[Vector3(0.07, 0.07, 0.03), Vector3(-0.2, 0.3, -0.18), GOLD, Vector3(0, 0, 45)]]},
	"extra_captain_front": {"anchor": BODY, "blocky_only": true, "boxes": [   # a captain's coat: gold buttons, epaulettes
		[Vector3(0.1, 0.3, 0.025), Vector3(-0.13, 0.2, -0.17), "top", Vector3(0, 0, 18)],
		[Vector3(0.1, 0.3, 0.025), Vector3(0.13, 0.2, -0.17), "top", Vector3(0, 0, -18)],
		[Vector3(0.02, 0.3, 0.027), Vector3(-0.09, 0.19, -0.171), GOLD, Vector3(0, 0, 18)],
		[Vector3(0.02, 0.3, 0.027), Vector3(0.09, 0.19, -0.171), GOLD, Vector3(0, 0, -18)],
		[Vector3(0.1, 0.12, 0.02), Vector3(0, 0.27, -0.168), WHITE],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.1, 0.05, -0.172), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.1, 0.05, -0.172), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.1, -0.08, -0.172), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.1, -0.08, -0.172), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(-0.1, -0.21, -0.172), GOLD],
		[Vector3(0.04, 0.04, 0.02), Vector3(0.1, -0.21, -0.172), GOLD],
		[Vector3(0.18, 0.05, 0.24), Vector3(-0.34, 0.385, 0), GOLD],
		[Vector3(0.18, 0.05, 0.24), Vector3(0.34, 0.385, 0), GOLD],
		[Vector3(0.2, 0.03, 0.26), Vector3(-0.34, 0.35, 0), Color("c9a227")],
		[Vector3(0.2, 0.03, 0.26), Vector3(0.34, 0.35, 0), Color("c9a227")]]},
	"extra_captain_hem": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.73, 0.03, 0.43), Vector3(0, -0.665, 0), GOLD]]},
	"extra_hero_emblem": {"anchor": BODY, "blocky_only": true, "boxes": [   # our own emblem: a golden block
		[Vector3(0.22, 0.22, 0.02), Vector3(0, 0.12, -0.168), Color("f57c00")],
		[Vector3(0.075, 0.075, 0.022), Vector3(-0.045, 0.165, -0.17), Color("ffd23f")],
		[Vector3(0.075, 0.075, 0.022), Vector3(0.045, 0.165, -0.17), Color("fff176")],
		[Vector3(0.075, 0.075, 0.022), Vector3(-0.045, 0.075, -0.17), Color("fff176")],
		[Vector3(0.075, 0.075, 0.022), Vector3(0.045, 0.075, -0.17), Color("ffd23f")]]},
	"extra_hero_belt": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.64, 0.07, 0.35), Vector3(0, -0.32, 0), Color("ffd23f")],
		[Vector3(0.1, 0.09, 0.02), Vector3(0, -0.32, -0.18), Color("f57c00")],
		[Vector3(0.05, 0.05, 0.022), Vector3(0, -0.32, -0.182), Color("ffd23f")]]},
	"extra_petal_skirt": {"anchor": BODY, "blocky_only": true, "boxes": [   # our fairy's petal dress
		[Vector3(0.64, 0.06, 0.34), Vector3(0, -0.33, 0), "top"],
		[Vector3(0.26, 0.3, 0.03), Vector3(-0, -0.48, -0.2), "top", Vector3(15, 0, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(-0, -0.6249, -0.2388), "top", Vector3(15, 0, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(0.2333, -0.48, -0.1414), "top", Vector3(15, -45, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(0.2608, -0.6249, -0.1689), "top", Vector3(15, -45, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(0.33, -0.48, -0), "top", Vector3(15, -90, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(0.3688, -0.6249, -0), "top", Vector3(15, -90, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(0.2333, -0.48, 0.1414), "top", Vector3(15, -135, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(0.2608, -0.6249, 0.1689), "top", Vector3(15, -135, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(0, -0.48, 0.2), "top", Vector3(15, -180, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(0, -0.6249, 0.2388), "top", Vector3(15, -180, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(-0.2333, -0.48, 0.1414), "top", Vector3(15, -225, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(-0.2608, -0.6249, 0.1689), "top", Vector3(15, -225, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(-0.33, -0.48, 0), "top", Vector3(15, -270, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(-0.3688, -0.6249, 0), "top", Vector3(15, -270, 45)],
		[Vector3(0.26, 0.3, 0.03), Vector3(-0.2333, -0.48, -0.1414), "top", Vector3(15, -315, 0)],
		[Vector3(0.13, 0.13, 0.03), Vector3(-0.2608, -0.6249, -0.1689), "top", Vector3(15, -315, 45)],
		[Vector3(0.03, 0.03, 0.03), Vector3(-0.12, -0.45, -0.215), WHITE, Vector3.ZERO, true],
		[Vector3(0.03, 0.03, 0.03), Vector3(0.18, -0.52, -0.18), WHITE, Vector3.ZERO, true],
		[Vector3(0.03, 0.03, 0.03), Vector3(0.3, -0.42, 0.05), WHITE, Vector3.ZERO, true],
		[Vector3(0.03, 0.03, 0.03), Vector3(-0.2, -0.5, 0.16), WHITE, Vector3.ZERO, true]]},
	# The pack's outfits: the Tin Woodman (Baum; W. W. Denslow's drawings, 1900) and our own dragon suit
	"hat_funnel_hat": {"anchor": HEAD, "real_offset": REAL_HAT_DROP, "boxes": [
		[Vector3(0.56, 0.12, 0.56), Vector3(0, 0.3, 0), Color("c9d0d8")],
		[Vector3(0.58, 0.03, 0.58), Vector3(0, 0.245, 0), Color("8a939e")],
		[Vector3(0.46, 0.08, 0.46), Vector3(0, 0.39, 0), Color("b0b8c2")],
		[Vector3(0.34, 0.08, 0.34), Vector3(0, 0.47, 0), Color("b0b8c2")],
		[Vector3(0.22, 0.08, 0.22), Vector3(0, 0.55, 0), Color("b0b8c2")],
		[Vector3(0.07, 0.2, 0.07), Vector3(0, 0.69, 0), Color("98a1ac")],
		[Vector3(0.05, 0.22, 0.22), Vector3(-0.27, 0.02, 0.02), Color("c9d0d8")],
		[Vector3(0.05, 0.22, 0.22), Vector3(0.27, 0.02, 0.02), Color("c9d0d8")],
		[Vector3(0.02, 0.03, 0.03), Vector3(-0.3, 0.02, -0.05), Color("8a939e")],
		[Vector3(0.02, 0.03, 0.03), Vector3(0.3, 0.02, -0.05), Color("8a939e")]]},
	"extra_tin_heart": {"anchor": BODY, "blocky_only": true, "boxes": [   # the heart the Wizard gave him
		[Vector3(0.07, 0.07, 0.02), Vector3(-0.035, 0.17, -0.172), Color("e53935")],
		[Vector3(0.07, 0.07, 0.02), Vector3(0.035, 0.17, -0.172), Color("e53935")],
		[Vector3(0.085, 0.085, 0.02), Vector3(0, 0.13, -0.172), Color("e53935"), Vector3(0, 0, 45)]]},
	"extra_tin_rivets": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.44, 0.05, 0.34), Vector3(0, 0.36, 0), Color("8a939e")],
		[Vector3(0.63, 0.03, 0.33), Vector3(0, -0.02, 0), Color("8a939e")],
		[Vector3(0.03, 0.03, 0.02), Vector3(-0.26, 0.28, -0.17), Color("8a939e")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0.26, 0.28, -0.17), Color("8a939e")],
		[Vector3(0.03, 0.03, 0.02), Vector3(-0.26, -0.3, -0.17), Color("8a939e")],
		[Vector3(0.03, 0.03, 0.02), Vector3(0.26, -0.3, -0.17), Color("8a939e")]]},
	"hat_dragon_hood": {"anchor": HEAD, "cover": true, "boxes": [
		[Vector3(0.6, 0.12, 0.62), Vector3(0, 0.3, 0), Color("d84315")],
		[Vector3(0.6, 0.56, 0.1), Vector3(0, 0.04, 0.29), Color("d84315")],
		[Vector3(0.07, 0.44, 0.6), Vector3(-0.29, 0.1, 0), Color("d84315")],
		[Vector3(0.07, 0.44, 0.6), Vector3(0.29, 0.1, 0), Color("d84315")],
		[Vector3(0.52, 0.12, 0.2), Vector3(0, 0.22, -0.37), Color("bf360c")],
		[Vector3(0.05, 0.03, 0.02), Vector3(-0.1, 0.25, -0.475), Color("4e1a0a")],
		[Vector3(0.05, 0.03, 0.02), Vector3(0.1, 0.25, -0.475), Color("4e1a0a")],
		[Vector3(0.06, 0.05, 0.04), Vector3(-0.18, 0.14, -0.43), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(-0.06, 0.14, -0.43), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(0.06, 0.14, -0.43), WHITE],
		[Vector3(0.06, 0.05, 0.04), Vector3(0.18, 0.14, -0.43), WHITE],
		[Vector3(0.1, 0.1, 0.06), Vector3(-0.15, 0.4, -0.18), Color("ffd54f")],
		[Vector3(0.1, 0.1, 0.06), Vector3(0.15, 0.4, -0.18), Color("ffd54f")],
		[Vector3(0.025, 0.07, 0.02), Vector3(-0.15, 0.4, -0.215), BLACK],
		[Vector3(0.025, 0.07, 0.02), Vector3(0.15, 0.4, -0.215), BLACK],
		[Vector3(0.06, 0.2, 0.06), Vector3(-0.2, 0.46, 0.08), Color("ffe0b2"), Vector3(25, 0, 0)],
		[Vector3(0.06, 0.2, 0.06), Vector3(0.2, 0.46, 0.08), Color("ffe0b2"), Vector3(25, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.38, 0.1), Color("ffb300"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.22, 0.34), Color("ffb300"), Vector3(45, 0, 0)],
		[Vector3(0.1, 0.1, 0.1), Vector3(0, 0.02, 0.36), Color("ffb300"), Vector3(45, 0, 0)]]},
	"extra_dragon_belly": {"anchor": BODY, "blocky_only": true, "boxes": [
		[Vector3(0.34, 0.08, 0.02), Vector3(0, 0.22, -0.17), Color("ffcc80")],
		[Vector3(0.34, 0.08, 0.02), Vector3(0, 0.1, -0.17), Color("ffcc80")],
		[Vector3(0.34, 0.08, 0.02), Vector3(0, -0.02, -0.17), Color("ffcc80")],
		[Vector3(0.34, 0.08, 0.02), Vector3(0, -0.14, -0.17), Color("ffcc80")],
		[Vector3(0.34, 0.08, 0.02), Vector3(0, -0.26, -0.17), Color("ffcc80")]]},
	# The same clothes on the realistic person, in metres: WAIST is its hips (the waist at y 0), BODY its chest
	"extra_pinafore_bib_real": {"anchor": BODY, "boxes": [
		[Vector3(0.17, 0.15, 0.015), Vector3(0, -0.06, -0.132), WHITE],
		[Vector3(0.03, 0.16, 0.015), Vector3(-0.06, 0.08, -0.125), WHITE],
		[Vector3(0.03, 0.16, 0.015), Vector3(0.06, 0.08, -0.125), WHITE]]},
	"extra_pinafore_apron_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.3, 0.38, 0.015), Vector3(0, -0.21, -0.205), WHITE, Vector3(15, 0, 0)],
		[Vector3(0.36, 0.04, 0.3), Vector3(0, 0.0, 0), WHITE, Vector3.ZERO, false, TUBE],
		[Vector3(0.08, 0.06, 0.04), Vector3(-0.04, 0.0, 0.15), WHITE, Vector3.ZERO, false, BALL],
		[Vector3(0.08, 0.06, 0.04), Vector3(0.04, 0.0, 0.15), WHITE, Vector3.ZERO, false, BALL]]},
	"extra_tailcoat_front_real": {"anchor": BODY, "boxes": [
		[Vector3(0.12, 0.22, 0.015), Vector3(0, -0.05, -0.13), Color("e8c547")],
		[Vector3(0.018, 0.018, 0.012), Vector3(0, 0.02, -0.14), Color("8d6e1f"), Vector3.ZERO, false, BALL],
		[Vector3(0.018, 0.018, 0.012), Vector3(0, -0.05, -0.14), Color("8d6e1f"), Vector3.ZERO, false, BALL],
		[Vector3(0.018, 0.018, 0.012), Vector3(0, -0.12, -0.14), Color("8d6e1f"), Vector3.ZERO, false, BALL],
		[Vector3(0.05, 0.035, 0.03), Vector3(-0.028, 0.15, -0.125), Color("d32f2f"), Vector3.ZERO, false, BALL],
		[Vector3(0.05, 0.035, 0.03), Vector3(0.028, 0.15, -0.125), Color("d32f2f"), Vector3.ZERO, false, BALL],
		[Vector3(0.025, 0.025, 0.03), Vector3(0, 0.15, -0.13), Color("b71c1c"), Vector3.ZERO, false, BALL]]},
	"extra_tailcoat_tails_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.1, 0.34, 0.02), Vector3(-0.055, -0.17, 0.13), "top", Vector3(-8, 0, 0)],
		[Vector3(0.1, 0.34, 0.02), Vector3(0.055, -0.17, 0.13), "top", Vector3(-8, 0, 0)]]},
	"extra_paper_flowers_real": {"anchor": BODY, "boxes": [
		[Vector3(0.03, 0.03, 0.015), Vector3(-0.09, 0.1, -0.13), Color("e53935"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.03, 0.015), Vector3(0.06, 0.12, -0.13), Color("1e88e5"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.03, 0.015), Vector3(-0.03, 0.02, -0.135), Color("fdd835"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.03, 0.015), Vector3(0.1, 0.0, -0.128), Color("e53935"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.03, 0.015), Vector3(-0.08, -0.08, -0.13), Color("1e88e5"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.03, 0.015), Vector3(0.03, -0.11, -0.132), Color("fdd835"), Vector3.ZERO, false, BALL]]},
	"extra_archer_tunic_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.44, 0.26, 0.36), Vector3(0, -0.11, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.35, 0.045, 0.29), Vector3(0, 0.0, 0), Color("5d3a1a"), Vector3.ZERO, false, TUBE],
		[Vector3(0.04, 0.035, 0.02), Vector3(0, 0.0, -0.148), GOLD]]},
	"extra_tabard_real": {"anchor": BODY, "boxes": [
		[Vector3(0.2, 0.34, 0.015), Vector3(0, 0.0, -0.13), "top"],
		[Vector3(0.2, 0.34, 0.015), Vector3(0, 0.0, 0.11), "top"],
		[Vector3(0.045, 0.018, 0.008), Vector3(-0.045, 0.08, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(-0.063, 0.095, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(-0.045, 0.095, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(-0.027, 0.095, -0.139), GOLD],
		[Vector3(0.045, 0.018, 0.008), Vector3(0.045, 0.08, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(0.027, 0.095, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(0.045, 0.095, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(0.063, 0.095, -0.139), GOLD],
		[Vector3(0.045, 0.018, 0.008), Vector3(0, 0.01, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(-0.018, 0.025, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(0, 0.025, -0.139), GOLD],
		[Vector3(0.009, 0.015, 0.008), Vector3(0.018, 0.025, -0.139), GOLD]]},
	"extra_tabard_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.22, 0.3, 0.015), Vector3(0, -0.15, -0.15), "top", Vector3(8, 0, 0)],
		[Vector3(0.22, 0.3, 0.015), Vector3(0, -0.15, 0.14), "top", Vector3(-8, 0, 0)],
		[Vector3(0.36, 0.05, 0.3), Vector3(0, 0.0, 0), Color("4e342e"), Vector3.ZERO, false, TUBE],
		[Vector3(0.04, 0.035, 0.02), Vector3(0, 0.0, -0.152), GOLD]]},
	"extra_robe_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.36, 0.12, 0.3), Vector3(0, -0.02, 0), "top", Vector3.ZERO, false, TUBE],
		[Vector3(0.52, 0.66, 0.46), Vector3(0, -0.41, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.53, 0.03, 0.47), Vector3(0, -0.735, 0), GOLD, Vector3.ZERO, false, TUBE],
		[Vector3(0.37, 0.03, 0.31), Vector3(0, 0.02, 0), GOLD, Vector3.ZERO, false, TUBE],
		[Vector3(0.03, 0.64, 0.01), Vector3(0, -0.41, -0.189), GOLD, Vector3(8, 0, 0)]]},
	"extra_robe_crest_real": {"anchor": BODY, "boxes": [
		[Vector3(0.06, 0.05, 0.012), Vector3(0.06, 0.07, -0.13), GOLD],
		[Vector3(0.042, 0.042, 0.012), Vector3(0.06, 0.045, -0.13), GOLD, Vector3(0, 0, 45)],
		[Vector3(0.02, 0.02, 0.014), Vector3(0.06, 0.065, -0.137), WHITE, Vector3.ZERO, true, BALL]]},
	"extra_coat_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.36, 0.06, 0.3), Vector3(0, 0.0, 0), "top", Vector3.ZERO, false, TUBE],
		[Vector3(0.48, 0.46, 0.42), Vector3(0, -0.21, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.012, 0.44, 0.01), Vector3(0, -0.21, -0.18), Color("2b2b2e"), Vector3(8, 0, 0)]]},
	"extra_inverness_cape_real": {"anchor": BODY, "boxes": [
		[Vector3(0.56, 0.22, 0.46), Vector3(0, 0.12, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.565, 0.012, 0.465), Vector3(0, 0.02, 0), Color("5b5f66"), Vector3.ZERO, false, TUBE]]},
	"extra_magnifier_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.015, 0.07, 0.015), Vector3(0.13, -0.06, -0.16), Color("6d4c2f"), Vector3(0, 0, -20)],
		[Vector3(0.07, 0.012, 0.07), Vector3(0.14, 0.0, -0.165), GOLD, Vector3(90, 0, 0), false, TUBE],
		[Vector3(0.055, 0.014, 0.055), Vector3(0.14, 0.0, -0.165), Color("b3e5fc"), Vector3(90, 0, 0), false, TUBE]]},
	"extra_gingham_checks_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.4112, 0.035, 0.3417), Vector3(0, -0.1, 0), WHITE, Vector3.ZERO, false, TUBE],
		[Vector3(0.4886, 0.035, 0.4057), Vector3(0, -0.24, 0), WHITE, Vector3.ZERO, false, TUBE],
		[Vector3(0.5604, 0.035, 0.4651), Vector3(0, -0.37, 0), WHITE, Vector3.ZERO, false, TUBE],
		[Vector3(0.03, 0.42, 0.012), Vector3(-0.1, -0.21, -0.198), WHITE, Vector3(12.875, 0, 0)],
		[Vector3(0.03, 0.42, 0.012), Vector3(-0.1, -0.21, 0.198), WHITE, Vector3(-12.875, 0, 0)],
		[Vector3(0.03, 0.42, 0.012), Vector3(0.1, -0.21, -0.198), WHITE, Vector3(12.875, 0, 0)],
		[Vector3(0.03, 0.42, 0.012), Vector3(0.1, -0.21, 0.198), WHITE, Vector3(-12.875, 0, 0)],
		[Vector3(0.012, 0.42, 0.03), Vector3(-0.238, -0.21, 0), WHITE, Vector3(0, 0, -15.4396)],
		[Vector3(0.012, 0.42, 0.03), Vector3(0.238, -0.21, 0), WHITE, Vector3(0, 0, 15.4396)]]},
	"extra_kaftan_sash_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.36, 0.06, 0.3), Vector3(0, 0.01, 0), GOLD, Vector3.ZERO, false, TUBE],
		[Vector3(0.05, 0.05, 0.04), Vector3(-0.08, 0.0, -0.14), Color("d9a520"), Vector3.ZERO, false, BALL],
		[Vector3(0.03, 0.12, 0.012), Vector3(-0.08, -0.08, -0.15), GOLD]]},
	"extra_lamp_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.06, 0.035, 0.08), Vector3(0.12, -0.04, -0.16), Color("f5c542"), Vector3.ZERO, false, BALL],
		[Vector3(0.025, 0.02, 0.025), Vector3(0.12, -0.02, -0.16), Color("e0a81e"), Vector3.ZERO, false, BALL],
		[Vector3(0.015, 0.015, 0.05), Vector3(0.12, -0.035, -0.21), Color("f5c542"), Vector3(-20, 0, 0)]]},
	"extra_chiton_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.44, 0.28, 0.36), Vector3(0, -0.12, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.35, 0.04, 0.29), Vector3(0, 0.0, 0), GOLD, Vector3.ZERO, false, TUBE],
		[Vector3(0.45, 0.02, 0.37), Vector3(0, -0.255, 0), GOLD, Vector3.ZERO, false, TUBE]]},
	"extra_chiton_drape_real": {"anchor": BODY, "boxes": [
		[Vector3(0.05, 0.36, 0.015), Vector3(0, 0.02, -0.13), Color("e6e1d6"), Vector3(0, 0, 35)],
		[Vector3(0.035, 0.035, 0.02), Vector3(-0.09, 0.14, -0.12), GOLD, Vector3.ZERO, false, BALL]]},
	"extra_captain_front_real": {"anchor": BODY, "boxes": [
		[Vector3(0.05, 0.07, 0.015), Vector3(0, 0.12, -0.125), WHITE],
		[Vector3(0.02, 0.02, 0.012), Vector3(-0.045, 0.05, -0.135), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(0.045, 0.05, -0.135), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(-0.045, -0.02, -0.137), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(0.045, -0.02, -0.137), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(-0.045, -0.09, -0.135), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(0.045, -0.09, -0.135), GOLD, Vector3.ZERO, false, BALL],
		[Vector3(0.1, 0.025, 0.1), Vector3(-0.17, 0.21, 0), GOLD],
		[Vector3(0.1, 0.025, 0.1), Vector3(0.17, 0.21, 0), GOLD]]},
	"extra_captain_hem_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.485, 0.025, 0.425), Vector3(0, -0.43, 0), GOLD, Vector3.ZERO, false, TUBE]]},
	"extra_hero_emblem_real": {"anchor": BODY, "boxes": [
		[Vector3(0.11, 0.11, 0.015), Vector3(0, 0.05, -0.132), Color("f57c00")],
		[Vector3(0.037, 0.037, 0.017), Vector3(-0.022, 0.072, -0.134), Color("ffd23f")],
		[Vector3(0.037, 0.037, 0.017), Vector3(0.022, 0.072, -0.134), Color("fff176")],
		[Vector3(0.037, 0.037, 0.017), Vector3(-0.022, 0.028, -0.134), Color("fff176")],
		[Vector3(0.037, 0.037, 0.017), Vector3(0.022, 0.028, -0.134), Color("ffd23f")]]},
	"extra_hero_belt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.36, 0.05, 0.3), Vector3(0, 0.01, 0), Color("ffd23f"), Vector3.ZERO, false, TUBE],
		[Vector3(0.05, 0.045, 0.015), Vector3(0, 0.01, -0.152), Color("f57c00")]]},
	"extra_petal_skirt_real": {"anchor": WAIST, "boxes": [
		[Vector3(0.46, 0.28, 0.4), Vector3(0, -0.13, 0), "top", Vector3.ZERO, false, CONE],
		[Vector3(0.35, 0.04, 0.29), Vector3(0, 0.0, 0), "top", Vector3.ZERO, false, TUBE],
		[Vector3(0.15, 0.1, 0.07), Vector3(0, -0.27, -0.195), "top", Vector3(0, 0, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(0.1591, -0.27, -0.1379), "top", Vector3(0, -45, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(0.225, -0.27, -0), "top", Vector3(0, -90, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(0.1591, -0.27, 0.1379), "top", Vector3(0, -135, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(0, -0.27, 0.195), "top", Vector3(0, -180, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(-0.1591, -0.27, 0.1379), "top", Vector3(0, -225, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(-0.225, -0.27, 0), "top", Vector3(0, -270, 0), false, BALL],
		[Vector3(0.15, 0.1, 0.07), Vector3(-0.1591, -0.27, -0.1379), "top", Vector3(0, -315, 0), false, BALL],
		[Vector3(0.02, 0.02, 0.02), Vector3(-0.08, -0.12, -0.19), WHITE, Vector3.ZERO, true, BALL],
		[Vector3(0.02, 0.02, 0.02), Vector3(0.12, -0.2, -0.16), WHITE, Vector3.ZERO, true, BALL],
		[Vector3(0.02, 0.02, 0.02), Vector3(0.17, -0.1, 0.1), WHITE, Vector3.ZERO, true, BALL]]},
	"extra_tin_heart_real": {"anchor": BODY, "boxes": [
		[Vector3(0.04, 0.04, 0.015), Vector3(-0.018, 0.085, -0.135), Color("e53935"), Vector3.ZERO, false, BALL],
		[Vector3(0.04, 0.04, 0.015), Vector3(0.018, 0.085, -0.135), Color("e53935"), Vector3.ZERO, false, BALL],
		[Vector3(0.042, 0.042, 0.015), Vector3(0, 0.065, -0.135), Color("e53935"), Vector3(0, 0, 45)]]},
	"extra_tin_rivets_real": {"anchor": BODY, "boxes": [
		[Vector3(0.02, 0.02, 0.012), Vector3(-0.1, 0.13, -0.125), Color("8a939e"), Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(0.1, 0.13, -0.125), Color("8a939e"), Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(-0.1, -0.12, -0.125), Color("8a939e"), Vector3.ZERO, false, BALL],
		[Vector3(0.02, 0.02, 0.012), Vector3(0.1, -0.12, -0.125), Color("8a939e"), Vector3.ZERO, false, BALL]]},
	"extra_dragon_belly_real": {"anchor": BODY, "boxes": [
		[Vector3(0.14, 0.035, 0.015), Vector3(0, 0.1, -0.13), Color("ffcc80")],
		[Vector3(0.15, 0.035, 0.015), Vector3(0, 0.05, -0.132), Color("ffcc80")],
		[Vector3(0.15, 0.035, 0.015), Vector3(0, 0.0, -0.133), Color("ffcc80")],
		[Vector3(0.14, 0.035, 0.015), Vector3(0, -0.05, -0.132), Color("ffcc80")],
		[Vector3(0.13, 0.035, 0.015), Vector3(0, -0.1, -0.13), Color("ffcc80")]]},
}

static var _materials := {}   # Color.to_html() (+ ":glow") -> StandardMaterial3D (the blocky body's boxes)
static var _meshes := {}      # size -> BoxMesh (the blocky body's boxes)
static var _part_meshes := {} # part id | mirrored | colours -> merged ArrayMesh
static var _part_material: StandardMaterial3D
static var _part_glow: StandardMaterial3D
static var _unit_box: Array = []
static var _unit_shapes := {} # Owner 48: shape -> unit mesh arrays
## The look's colours a box can name (AvatarModel._dress fills them).
const COLOR_KEYS: Array[String] = ["hair", "skin", "shirt", "pants", "shoes", "top", "bottom"]


static func has_part(id: String) -> bool:
	return PARTS.has(id)


static func anchor_of(id: String) -> StringName:
	return PARTS.get(id, {}).get("anchor", HEAD)


static func blocky_only(id: String) -> bool:
	return bool(PARTS.get(id, {}).get("blocky_only", false))


static func covers(id: String) -> bool:
	return bool(PARTS.get(id, {}).get("cover", false))


## Owner 36: where the realistic person wears the part, from where the blocky body does (a hat sits lower).
static func real_offset(id: String) -> Vector3:
	return PARTS.get(id, {}).get("real_offset", Vector3.ZERO)


static func sway_of(id: String) -> StringName:
	return PARTS.get(id, {}).get("sway", &"")


## Builds part `id` (named `id`) with the look's colours (keys "hair", "skin", "shirt", "pants",
## "shoes"); null for an unknown part. Its boxes are one merged mesh (one draw call; wings: one per
## wing, so they can flap), shared by every avatar wearing the part in the same colours.
static func build(id: String, colors: Dictionary) -> Node3D:
	if not PARTS.has(id):
		return null
	var root := Node3D.new()
	root.name = id
	if PARTS[id].get("mirror", false):
		for side: String in ["R", "L"]:
			var wing := Node3D.new()
			wing.name = side
			root.add_child(wing)
			wing.add_child(_mesh_instance(part_mesh(id, colors, side == "L")))
	else:
		root.add_child(_mesh_instance(part_mesh(id, colors, false)))
	return root


static func _mesh_instance(mesh: ArrayMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # small pieces: no extra shadow pass
	return mi


## The merged mesh of a part in the look's colours (made once, then shared). Boxes take their colour
## from vertex colours; glowing boxes go into a second surface with the unshaded material.
static func part_mesh(id: String, colors: Dictionary, mirrored: bool) -> ArrayMesh:
	var key := "%s|%s|%s" % [id, mirrored, ",".join(COLOR_KEYS.map(
		func(k: String) -> String: return (colors.get(k, Color.BLACK) as Color).to_html()))]
	if _part_meshes.has(key):
		return _part_meshes[key]
	var spec: Dictionary = PARTS[id]
	var boxes: Array = []
	if spec.has("base"):
		boxes.append_array(PARTS[spec.base].boxes)
	boxes.append_array(spec.boxes)
	var surfaces := [_new_surface(), _new_surface()]   # lit, glowing
	for box: Array in boxes:
		var c: Variant = box[2]
		var color: Color = colors.get(c, Color.MAGENTA) if typeof(c) == TYPE_STRING else c
		var shines := bool(spec.get("glow", false)) or (box.size() > 4 and bool(box[4]))
		var pos: Vector3 = box[1]
		var rot: Vector3 = box[3] if box.size() > 3 else Vector3.ZERO
		var shape: StringName = box[5] if box.size() > 5 else spec.get("shape", BOX)
		if mirrored:
			pos.x = -pos.x
			rot = Vector3(rot.x, -rot.y, -rot.z)
		_append_box(surfaces[1 if shines else 0], box[0], pos, rot, Color(color, 1.0), shape)
	var mesh := ArrayMesh.new()
	for i in 2:
		var s: Dictionary = surfaces[i]
		if (s.v as Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(s.v)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(s.n)
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(s.c)
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(s.i)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, part_glow_material() if i == 1 else part_material())
	_part_meshes[key] = mesh
	return mesh


## A surface being gathered: plain Arrays (packed arrays are values: appending to one read out of a
## Dictionary would append to a copy), packed once at the end.
static func _new_surface() -> Dictionary:
	return {"v": [], "n": [], "c": [], "i": []}


## Appends one box (a BoxMesh's unit cube, scaled, turned and moved) with a colour; Owner 48: or a
## ball, cone or tube of that size (normals follow the stretch, so a long ball still shades round).
static func _append_box(s: Dictionary, size: Vector3, pos: Vector3, rot_degrees: Vector3, color: Color,
		shape: StringName = BOX) -> void:
	var unit := _unit_shape(shape)
	var turn := Basis.from_euler(rot_degrees * (PI / 180.0))
	var xform := Transform3D(turn * Basis.from_scale(size), pos)
	var verts: PackedVector3Array = unit[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = unit[Mesh.ARRAY_NORMAL]
	var v: Array = s.v
	var n: Array = s.n
	var c: Array = s.c
	var idx: Array = s.i
	var base := v.size()
	for k in verts.size():
		v.append(xform * verts[k])
		n.append((turn * (normals[k] / size)).normalized())
		c.append(color)
	for index: int in unit[Mesh.ARRAY_INDEX]:
		idx.append(base + index)


## A shape's unit mesh arrays (1 across, centred), made once. Few sides: small parts on phones.
static func _unit_shape(shape: StringName) -> Array:
	if shape == BOX or not shape in [BALL, CONE, TUBE]:
		if _unit_box.is_empty():
			_unit_box = BoxMesh.new().get_mesh_arrays()
		return _unit_box
	if not _unit_shapes.has(shape):
		var mesh: PrimitiveMesh
		if shape == BALL:
			var ball := SphereMesh.new()
			ball.radius = 0.5
			ball.height = 1.0
			ball.radial_segments = 12
			ball.rings = 6
			mesh = ball
		else:
			var cyl := CylinderMesh.new()
			cyl.bottom_radius = 0.5
			cyl.top_radius = 0.5 * CONE_TOP if shape == CONE else 0.5
			cyl.height = 1.0
			cyl.radial_segments = 16
			cyl.rings = 1
			mesh = cyl
		_unit_shapes[shape] = mesh.get_mesh_arrays()
	return _unit_shapes[shape]


## The one material of every part's ordinary boxes (their colours are vertex colours).
static func part_material() -> StandardMaterial3D:
	if _part_material == null:
		_part_material = StandardMaterial3D.new()
		_part_material.vertex_color_use_as_albedo = true
		_part_material.vertex_color_is_srgb = true   # the same look as albedo_color
		_part_material.roughness = 0.45
		_part_material.metallic_specular = 0.6
	return _part_material


## The one material of glowing boxes (stars, lamps, robot eyes, the cosmic halo): unshaded, so they
## stay bright in the dark.
static func part_glow_material() -> StandardMaterial3D:
	if _part_glow == null:
		_part_glow = StandardMaterial3D.new()
		_part_glow.vertex_color_use_as_albedo = true
		_part_glow.vertex_color_is_srgb = true
		_part_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _part_glow


static func mesh_count() -> int:
	return _part_meshes.size()


## The shared material for a colour: the blocky body's boxes (a look recolours them by swapping these).
static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.45
		mat.metallic_specular = 0.6
		_materials[key] = mat
	return _materials[key]


## The shared box mesh of a size (the blocky body; the material is set on each MeshInstance3D).
static func box_mesh(size: Vector3) -> BoxMesh:
	if not _meshes.has(size):
		var mesh := BoxMesh.new()
		mesh.size = size
		_meshes[size] = mesh
	return _meshes[size]


static func material_count() -> int:
	return _materials.size()
