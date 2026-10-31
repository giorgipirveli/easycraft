class_name HudLayout
extends RefCounted
## Where every HUD control sits (M2 Task 17), in one table for the 1280 × 720 design space: an anchor
## (a corner or the middle of an edge, as a fraction of the screen), the offset of the control's
## top-left corner from it, and its size (ZERO: the control's own size). Wider phones only add room
## between the corners (stretch "expand"). M5 Task 1 (spec §15.1a): the table at three button sizes (BIG and BIGGER
## grow the thumb controls and have their own spots), in a mirror for the left hand, with the controls a child
## moved (`configure`; the Hud calls it from the profile and places everything again).
##
## Sizes (spec §5.15, research A4): JUMP about 2 cm on a phone, ATTACK a little less, every other
## button at least 135 (about 1.2 cm). The hotbar's slots are a strip of items, not buttons, and keep
## their size (ruling in docs/devlog/parts/m2-task-17-hud.md). Buttons used now and then live in the
## MORE panel (MorePanel), which lays them out itself.

const JUMP := 225.0
const ATTACK := 200.0
const BUTTON := 135.0
## The smallest JUMP and ATTACK may be (the layout test's bar), and every other button.
const MAIN_MIN := 200.0
const BUTTON_MIN := 135.0

const HEARTS_POS := Vector2(165, 26)
## M3 Task 7: where the toasts sit while the race clock shows (under it).
const TOAST_RACING_Y := 156.0
const STEALTH_POS := Vector2(165, 62)

## name -> [anchor, offset, size]
const SPOTS := {
	# Top left: pause, CHAT under it and the Secret Book beside CHAT; the hearts, the eye and the Brave
	# badge right of pause (the open chat bar covers them). The joystick's area below, down to the corner.
	&"pause": [Vector2(0, 0), Vector2(16, 16), Vector2(135, 135)],
	&"chat": [Vector2(0, 0), Vector2(16, 161), Vector2(135, 135)],
	&"book": [Vector2(0, 0), Vector2(161, 161), Vector2(135, 135)],
	&"hearts": [Vector2(0, 0), HEARTS_POS, Vector2.ZERO],
	&"stealth": [Vector2(0, 0), STEALTH_POS, Vector2.ZERO],
	&"brave": [Vector2(0, 0), Vector2(280, 58), Vector2(120, 36)],
	&"joystick": [Vector2(0, 1), Vector2(0, -400), Vector2(400, 400)],
	# Top middle: the wave line and the boss bar share a spot (the Totem starts no wave while the boss
	# fights); the toasts under them; the potion chips under the hearts, left of the middle.
	&"wave": [Vector2(0.5, 0), Vector2(-132, 16), Vector2(264, 64)],
	&"boss": [Vector2(0.5, 0), Vector2(-135, 8), Vector2(270, 76)],
	# M4 H: a co-op game's round line shares the wave line's place (no wave or boss during a round).
	&"game_line": [Vector2(0.5, 0), Vector2(-158, 16), Vector2(316, 56)],
	&"toast": [Vector2(0.5, 0), Vector2(0, 96), Vector2.ZERO],
	# M3 Task 7: the race clock (a label, never a button) under the wave line and the boss bar, right of the
	# potion chips and left of the FPS; the toasts step down under it while it shows (TOAST_RACING_Y).
	&"race": [Vector2(0.5, 0), Vector2(-95, 90), Vector2(250, 58)],
	&"potions": [Vector2(0.5, 0), Vector2(-400, 100), Vector2(300, 48)],
	# Survivor games (spec §12.18): the game clock (a label, never a button) centred under the potion chips and
	# M3 Task 7's race clock, clear of the Secret Book and of M3 Task 20a's RIDE beside it on small screens.
	&"game_clock": [Vector2(0.5, 0), Vector2(-150, 156), Vector2(300, 60)],
	&"crosshair": [Vector2(0.5, 0.5), Vector2(-20, -26), Vector2(40, 52)],
	# Top right: the name (the online dot beside it), gold, FPS; under them the treasure compass,
	# WALK/FLY and MORE. The MORE panel's top-right corner is left of MORE; it grows left and down.
	&"username": [Vector2(1, 0), Vector2(-440, 16), Vector2(420, 44)],
	&"online_dot": [Vector2(1, 0), Vector2(-48, 24), Vector2(28, 28)],
	&"gold": [Vector2(1, 0), Vector2(-350, 62), Vector2(220, 48)],
	&"fps": [Vector2(1, 0), Vector2(-470, 68), Vector2(110, 36)],
	&"compass": [Vector2(1, 0), Vector2(-410, 118), Vector2(104, 128)],
	&"physics": [Vector2(1, 0), Vector2(-296, 118), Vector2(135, 135)],
	&"more": [Vector2(1, 0), Vector2(-151, 118), Vector2(135, 135)],
	&"more_panel": [Vector2(1, 0), Vector2(-161, 118), Vector2.ZERO],
	# Bottom right, for the right thumb: JUMP (UP) in the corner, ATTACK above it, CROUCH (DOWN) left
	# of it, clear of the hotbar.
	&"attack": [Vector2(1, 1), Vector2(-216, -457), Vector2(200, 200)],
	&"jump": [Vector2(1, 1), Vector2(-241, -241), Vector2(225, 225)],
	&"crouch": [Vector2(1, 1), Vector2(-396, -223), Vector2(135, 135)],
	# M3 Task 14a: GLIDE (a context button: only in the air with a glider, or while gliding: DROP) left of
	# ATTACK and above CROUCH.
	&"glide": [Vector2(1, 1), Vector2(-396, -380), Vector2(135, 135)],
	# Bottom middle: the hotbar; SLEEP above it (asleep: WAKE UP and STOP FOR TODAY side by side);
	# HELP UP / GET UP above those, the ring that fills left of them.
	&"hotbar": [Vector2(0.5, 1), Vector2(-337, -78), Vector2(674, 62)],
	&"sleep": [Vector2(0.5, 1), Vector2(-110, -223), Vector2(220, 135)],
	&"wake": [Vector2(0.5, 1), Vector2(-230, -223), Vector2(220, 135)],
	&"stop": [Vector2(0.5, 1), Vector2(10, -223), Vector2(220, 135)],
	&"help": [Vector2(0.5, 1), Vector2(-120, -368), Vector2(240, 135)],
	&"help_ring": [Vector2(0.5, 1), Vector2(-224, -368), Vector2(88, 88)],
	# M4 H: TEAM PHOTO, for 20 s after a boss is beaten, right of HELP UP.
	&"team_photo": [Vector2(0.5, 1), Vector2(140, -368), Vector2(240, 135)],
	# M3 Task 20a: RIDE (HOP OFF while riding), a context button right of BOOK, above the joystick's area.
	&"ride": [Vector2(0, 0), Vector2(306, 161), Vector2(135, 135)],
	# Owner #109: in a car, HORN and (a flying car's driver) FLY / LAND over the hotbar, left of the middle: where SLEEP,
	# WAKE UP and STOP FOR TODAY go, which never show in a car (no bed from a seat; a sleeper is out of the car).
	&"horn": [Vector2(0.5, 1), Vector2(-230, -223), Vector2(135, 135)],
	&"car_fly": [Vector2(0.5, 1), Vector2(-85, -223), Vector2(135, 135)],
}


## Puts `c` on its spot; `own_size` for spots without a size of their own. M5 Task 1: the spot at the chosen button
## size, moved if the child moved it, in a mirror for the left hand; `c` remembers it (Hud.relayout places it again).
static func place(c: Control, spot_name: StringName, own_size := Vector2.ZERO) -> void:
	var s := _shown(spot_name, own_size)
	apply(c, s[0], s[1], s[2])
	c.set_meta(PLACED, [spot_name, own_size])


static func apply(c: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y


## The spot's rectangle on a screen of this size (in canvas units), as placed now (M5 Task 1: size, moves, hand).
static func rect(spot_name: StringName, screen: Vector2, own_size := Vector2.ZERO) -> Rect2:
	var s := _shown(spot_name, own_size)
	return Rect2((s[0] as Vector2) * screen + (s[1] as Vector2), s[2])


## Left-handed (M5): the spot seen in a mirror.
static func mirrored(spot: Array) -> Array:
	var anchor: Vector2 = spot[0]
	var offset: Vector2 = spot[1]
	var size: Vector2 = spot[2]
	return [Vector2(1.0 - anchor.x, anchor.y), Vector2(-offset.x - size.x, offset.y), size]


## Bigger buttons (M5): the spot grows away from its anchor, keeping its share of the margin.
static func scaled(spot: Array, factor: float) -> Array:
	return [spot[0], (spot[1] as Vector2) * factor, (spot[2] as Vector2) * factor]

# --- M5 Task 1: button sizes, the left hand, moved controls (spec §15.1a) ---------------------------------------

const NORMAL := &"normal"
const BIG := &"big"
const BIGGER := &"bigger"
const STEPS: Array[StringName] = [NORMAL, BIG, BIGGER]
## How much the thumb controls (the stick, JUMP, ATTACK, CROUCH, GLIDE) grow. ×1.2 is the most: at ×1.25 JUMP in
## the corner meets the hotbar on a 16:9 phone.
const FACTORS := {NORMAL: 1.0, BIG: 1.1, BIGGER: 1.2}
## The stick's picture at NORMAL (it grows with the thumb controls).
const STICK := 190.0
const STICK_TIP := 80.0
## BIG and BIGGER: there is no room for a bigger thumb cluster in NORMAL's shape on a 16:9 phone (JUMP, ATTACK and
## MORE fill the right edge from top to bottom), so CROUCH goes above JUMP, ATTACK left of JUMP (above the hotbar),
## GLIDE above ATTACK (left of the compass, under the game clock), the stick's area is lower (400 × 260), and the
## middle word buttons move left: SLEEP / WAKE UP over STOP FOR TODAY / HELP UP, the help ring above HELP UP, TEAM
## PHOTO under CHAT. Checked like the table (test_hud_layout_config.gd, test_hud_layout.gd).
const _MIDDLE := {
	&"joystick": [Vector2(0, 1), Vector2(0, -260), Vector2(400, 260)],
	&"sleep": [Vector2(0.5, 1), Vector2(-230, -223), Vector2(220, 135)],
	&"wake": [Vector2(0.5, 1), Vector2(-230, -223), Vector2(220, 135)],
	&"stop": [Vector2(0.5, 1), Vector2(-230, -368), Vector2(220, 135)],
	&"help": [Vector2(0.5, 1), Vector2(-230, -368), Vector2(240, 135)],
	&"help_ring": [Vector2(0.5, 1), Vector2(-140, -466), Vector2(88, 88)],
	&"team_photo": [Vector2(0, 0), Vector2(16, 306), Vector2(240, 135)],
}
const BIG_SPOTS := {   # JUMP 248, ATTACK 220, CROUCH and GLIDE 149
	&"jump": [Vector2(1, 1), Vector2(-264, -264), Vector2(248, 248)],
	&"crouch": [Vector2(1, 1), Vector2(-165, -423), Vector2(149, 149)],
	&"attack": [Vector2(1, 1), Vector2(-494, -308), Vector2(220, 220)],
	&"glide": [Vector2(1, 1), Vector2(-569, -467), Vector2(149, 149)],
}
const BIGGER_SPOTS := {   # JUMP 270, ATTACK 240, CROUCH and GLIDE 162
	&"jump": [Vector2(1, 1), Vector2(-286, -286), Vector2(270, 270)],
	&"crouch": [Vector2(1, 1), Vector2(-178, -458), Vector2(162, 162)],
	&"attack": [Vector2(1, 1), Vector2(-536, -328), Vector2(240, 240)],
	&"glide": [Vector2(1, 1), Vector2(-582, -500), Vector2(162, 162)],
}
## What a child can drag in MOVE BUTTONS (DOWN shares CROUCH's spot and moves with it).
const MOVABLE: Array[StringName] = [&"jump", &"attack", &"crouch", &"joystick"]
## Pairs of spots that never show at the same time (they may share a place): asleep or awake, the wave line, the boss
## bar and a round's line, the hotbar over the stick's area's corner, the dot inside the name's line. And GLIDE (in the
## air) and TEAM PHOTO (20 s after a boss) at NORMAL on a 16:9 phone since M3 Task 14a: both at once is rare, and a
## child in the air can't pose for the photo (ruling in docs/devlog/parts/m5-task-1.md).
const APART := [[&"sleep", &"wake"], [&"sleep", &"stop"], [&"help", &"wake"], [&"help", &"stop"],
	[&"help_ring", &"wake"], [&"help_ring", &"stop"], [&"wave", &"boss"], [&"wave", &"game_line"],
	[&"boss", &"game_line"], [&"hotbar", &"joystick"], [&"username", &"online_dot"], [&"glide", &"team_photo"],
	[&"horn", &"sleep"], [&"horn", &"wake"], [&"horn", &"stop"], [&"car_fly", &"sleep"], [&"car_fly", &"wake"],   # owner #109
	[&"car_fly", &"stop"]]
## Overlays and passing things, never in the way: the toasts, the MORE panel (it takes every touch while open), the
## aiming cross.
const OVERLAYS: Array[StringName] = [&"toast", &"more_panel", &"crosshair"]
## A move farther than this is not a move (bad data).
const MAX_MOVE := 2000.0
## The meta a placed control keeps: [its spot, its own size].
const PLACED := &"hud_spot"

## The button size in use, and the left hand's mirror.
static var step: StringName = NORMAL
static var left_handed := false
## The display's safe area (canvas units; a notch or rounded corners), set by the Hud; moved controls stay inside.
static var safe_area := Rect2(-1e6, -1e6, 2e6, 2e6)
## The moves the last configure() ignored (they covered something or left the screen).
static var rejected: Array[StringName] = []
static var _table := {}   # spot -> [anchor, offset, size] in the right hand's frame (empty: SPOTS)


## Back to NORMAL, right-handed, nothing moved (tests).
static func reset() -> void:
	step = NORMAL
	left_handed = false
	safe_area = Rect2(-1e6, -1e6, 2e6, 2e6)
	rejected = []
	_table = {}


## The layout for a button size, a hand and moves ({spot: offset from its own place, in the right hand's frame}) on
## a screen of this size: a move stays only if its control covers nothing that may show with it and keeps inside
## the screen and its safe area (else `rejected` lists it).
static func configure(size_step: StringName, left: bool, moves: Dictionary, screen: Vector2) -> void:
	step = size_step if FACTORS.has(size_step) else NORMAL
	left_handed = left
	rejected = []
	_table = SPOTS.duplicate()
	if step != NORMAL:
		_table.merge(_MIDDLE, true)
		_table.merge(BIG_SPOTS if step == BIG else BIGGER_SPOTS, true)
	for spot_name: StringName in MOVABLE:
		var d: Variant = moves.get(spot_name, Vector2.ZERO)
		if not d is Vector2 or d == Vector2.ZERO:
			continue
		var s: Array = _table[spot_name]
		var moved := [s[0], (s[1] as Vector2) + (d as Vector2), s[2]]
		if fits(spot_name, moved, screen):
			_table[spot_name] = moved
		else:
			rejected.append(spot_name)


## From the profile: its button size, hand and this size's moves.
static func configure_from(profile: ProfileData, screen: Vector2) -> void:
	var s := StringName(str(profile.settings.get("button_size", "normal")))
	configure(s, bool(profile.settings.get("left_handed", false)), moves_for(profile.hud_moves, s), screen)


## How much the thumb controls grow at the button size in use.
static func factor() -> float:
	return float(FACTORS[step])


## The spot in use (the right hand's frame: before the mirror).
static func spot(spot_name: StringName) -> Array:
	return _table.get(spot_name, SPOTS[spot_name])


## True when `s` (a spot for `spot_name`, the right hand's frame) is on the screen, in the safe area, and clear of
## every other spot that may show with it.
static func fits(spot_name: StringName, s: Array, screen: Vector2) -> bool:
	var r := Rect2((s[0] as Vector2) * screen + (s[1] as Vector2), s[2])
	var view := Rect2(Vector2.ZERO, screen).intersection(_right_frame(safe_area, screen))
	if not view.encloses(r):
		return false
	for other: StringName in SPOTS:
		if other == spot_name or OVERLAYS.has(other) or _apart(spot_name, other):
			continue
		if r.intersects(_frame_rect(other, screen)):
			return false
	return true


## Every pair of spots that may show together and overlap on this screen, as words (a test's list; empty is right).
static func clashes(screen: Vector2) -> Array[String]:
	var out: Array[String] = []
	var names: Array = SPOTS.keys().filter(func(n: StringName) -> bool: return not OVERLAYS.has(n))
	for i in names.size():
		var a: StringName = names[i]
		var ra := rect(a, screen, spot_own_size(a))
		if not Rect2(Vector2.ZERO, screen).encloses(ra):
			out.append("%s off the screen %s" % [a, ra])
		for j in range(i + 1, names.size()):
			var b: StringName = names[j]
			if not _apart(a, b) and ra.intersects(rect(b, screen, spot_own_size(b))):
				out.append("%s over %s" % [a, b])
	return out


## This size's moves from the profile's `hud_moves` ({size: {spot: [x, y]}}), as {spot: Vector2}.
static func moves_for(all: Dictionary, size_step: StringName) -> Dictionary:
	var out := {}
	var mine: Variant = all.get(String(size_step), {})
	if mine is Dictionary:
		for spot_name: Variant in mine:
			var d: Variant = mine[spot_name]
			if d is Array and (d as Array).size() == 2:
				out[StringName(str(spot_name))] = Vector2(float(d[0]), float(d[1]))
	return out


## The profile's moves, cleaned: known sizes and movable spots, two finite numbers each, none farther than MAX_MOVE.
static func sanitize_moves(v: Variant) -> Dictionary:
	var out := {}
	if not v is Dictionary:
		return out
	for size_key: Variant in v:
		if not FACTORS.has(StringName(str(size_key))) or not v[size_key] is Dictionary:
			continue
		var clean := {}
		var mine: Dictionary = v[size_key]
		for spot_name: Variant in mine:
			var d: Variant = mine[spot_name]
			if not MOVABLE.has(StringName(str(spot_name))) or not d is Array or (d as Array).size() != 2:
				continue
			if not typeof(d[0]) in [TYPE_INT, TYPE_FLOAT] or not typeof(d[1]) in [TYPE_INT, TYPE_FLOAT]:
				continue
			var x := float(d[0])
			var y := float(d[1])
			if is_finite(x) and is_finite(y) and absf(x) <= MAX_MOVE and absf(y) <= MAX_MOVE:
				clean[str(spot_name)] = [x, y]
		if not clean.is_empty():
			out[str(size_key)] = clean
	return out


## The spot as shown: in use, its own size filled in, mirrored for the left hand.
static func _shown(spot_name: StringName, own_size: Vector2) -> Array:
	var s := spot(spot_name)
	if (s[2] as Vector2) == Vector2.ZERO:
		s = [s[0], s[1], own_size]
	return mirrored(s) if left_handed else s


## The spot's rectangle in the right hand's frame (for checking moves; a mirror changes nothing about overlaps).
static func _frame_rect(spot_name: StringName, screen: Vector2) -> Rect2:
	var s := spot(spot_name)
	var size: Vector2 = s[2]
	return Rect2((s[0] as Vector2) * screen + (s[1] as Vector2), size if size != Vector2.ZERO else spot_own_size(spot_name))


## The safe area in the right hand's frame.
static func _right_frame(r: Rect2, screen: Vector2) -> Rect2:
	return Rect2(screen.x - r.end.x, r.position.y, r.size.x, r.size.y) if left_handed else r


static func _apart(a: StringName, b: StringName) -> bool:
	for pair: Array in APART:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


## The size of a spot that takes its control's own size (the hearts, the eye), for checks.
static func spot_own_size(spot_name: StringName) -> Vector2:
	match spot_name:
		&"hearts":
			return Vector2(HeartsBar.HEARTS * HeartsBar.HEART_SIZE + (HeartsBar.HEARTS - 1) * HeartsBar.GAP,
				HeartsBar.HEART_SIZE)
		&"stealth":
			return Vector2(StealthMeter.EYE_BOX.x + 12.0 + 3.0 * StealthMeter.BAR_W + 2.0 * StealthMeter.BAR_GAP + 10.0,
				StealthMeter.EYE_BOX.y + 4.0)
	return Vector2.ZERO
