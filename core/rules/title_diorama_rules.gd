class_name TitleDioramaRules
extends RefCounted
## The living title diorama's loop (M5 Task 2, spec §15.2), as plain numbers the diorama reads every frame (floats
## only: nothing is made per frame). The brand's buddy sleeps on its island (shut eyes, a slow breath); at SPARKLE the
## wand's star sparkles; it wakes (its eyes pop open with a blink), hops twice and waves; the dog hops and wags
## harder; then its eyes droop and it dozes off again. The island turns slowly to and fro (the slow camera).

const LOOP := 12.0
const SPARKLE := 4.0
const SHUT := 0.08                # the eyes' height when shut (a line)
const BREATH := 0.03              # the sleeping buddy's breath (of its height)
const HOP := 0.45                 # metres
const DOG_HOP := 0.3
const WAVE_FROM := 6.0
const WAVE_TO := 9.0
const WAVE_ARM := 2.0             # radians: the arm up
const SWAY := 0.3                 # radians the island turns each way

# --- Where it stands (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md) ------------------------------------
# Under the wordmark it hid behind the menu's panels (only the buddy's head showed): it stands beside the wordmark, left
# of it, in the band the wordmark takes, small enough to fit the room there on every screen shape (4:3 to 21:9).

const CANVAS_HEIGHT := 720.0      # the menu's canvas (canvas_items stretch, expand: the width follows the screen)
const FOV := 60.0                 # the menu camera's (vertical) field of view
const LOGO_WIDTH := 492.0         # the wordmark (Menu.LOGO_SIZE), centred at the top
const LOGO_BOTTOM := 128.0        # its bottom edge (8 from the top, 120 high)
const GRASS_Y := 106.0            # the island's grass stands between the wordmark's middle and its bottom
const DEPTH := 10.0               # metres in front of the camera
const HALF_WIDTH := 4.2           # the island's half width (7 blocks), turned and swaying towards the camera
const TOP := 1.9                  # the buddy's star over the grass at its highest hop
const MAX_SCALE := 0.45
const ROOM := 0.8                 # of the free width beside the wordmark it may take


## Where the diorama stands in its camera's space and how big it is ({position, scale}) on a screen `aspect` wide.
static func place(aspect: float) -> Dictionary:
	var width := CANVAS_HEIGHT * maxf(aspect, 1.0)
	var per_metre := CANVAS_HEIGHT * 0.5 / (DEPTH * tan(deg_to_rad(FOV * 0.5)))
	var free := (width - LOGO_WIDTH) * 0.5
	var s := minf(MAX_SCALE, free * ROOM / (2.0 * HALF_WIDTH * per_metre))
	var x := (free * 0.5 - width * 0.5) / per_metre
	var y := (CANVAS_HEIGHT * 0.5 - GRASS_Y) / per_metre
	return {"position": Vector3(x, y, -DEPTH), "scale": s}


static func _k(t: float) -> float:
	return fposmod(t, LOOP)


## How open the buddy's eyes are (SHUT .. 1).
static func eyes(t: float) -> float:
	var k := _k(t)
	if k < 4.25:
		return SHUT
	if k < 4.37:
		return lerpf(SHUT, 1.0, (k - 4.25) / 0.12)
	if k < 4.45:
		return lerpf(1.0, 0.1, (k - 4.37) / 0.08)   # a sleepy blink ...
	if k < 4.55:
		return lerpf(0.1, 1.0, (k - 4.45) / 0.1)    # ... and awake
	if k < 9.6:
		return 1.0
	if k < 10.4:
		return lerpf(1.0, SHUT, smoothstep(9.6, 10.4, k))
	return SHUT


## The buddy's hops of joy (metres up): two, after it wakes.
static func buddy_lift(t: float) -> float:
	var k := _k(t)
	return _hop(k, 4.8, 0.5, HOP) + _hop(k, 5.4, 0.5, HOP * 0.7)


## The dog's hops (metres up): it joins in.
static func dog_lift(t: float) -> float:
	var k := _k(t)
	return _hop(k, 5.0, 0.45, DOG_HOP) + _hop(k, 5.6, 0.4, DOG_HOP * 0.7)


static func _hop(k: float, from: float, length: float, height: float) -> float:
	if k < from or k > from + length:
		return 0.0
	var u := (k - from) / length
	return height * 4.0 * u * (1.0 - u)


## The buddy's waving arm (radians up round its shoulder; 0 at its side).
static func wave(t: float) -> float:
	var k := _k(t)
	if k <= WAVE_FROM or k >= WAVE_TO:
		return 0.0
	var envelope := smoothstep(WAVE_FROM, WAVE_FROM + 0.3, k) * (1.0 - smoothstep(WAVE_TO - 0.3, WAVE_TO, k))
	return envelope * (WAVE_ARM + 0.4 * sin(TAU * (k - WAVE_FROM) * 1.5))


## The buddy's breath (a share of its height, up and down; four breaths a loop).
static func breath(t: float) -> float:
	return BREATH * sin(TAU * _k(t) / 3.0)


## The dog's tail (radians): wagging all the time, harder while the buddy is awake.
static func wag(t: float) -> float:
	var k := _k(t)
	var awake := smoothstep(4.5, 5.0, k) * (1.0 - smoothstep(9.8, 10.4, k))
	return sin(TAU * k * 2.5) * lerpf(0.25, 0.6, awake)


## The island's slow turn (radians about its upright).
static func sway(t: float) -> float:
	return SWAY * sin(TAU * _k(t) / LOOP)


## Whether the star sparkles in (t0, t1] (once a loop, at SPARKLE).
static func sparkles(t0: float, t1: float) -> bool:
	var moment := floorf((t1 - SPARKLE) / LOOP) * LOOP + SPARKLE
	return moment > t0 and moment <= t1
