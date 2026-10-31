class_name PresentRules
extends RefCounted
## Presents during play (M3 Task 12, spec §5.8, research R4; it replaces a daily login gift): a tamed pet
## near the child brings a small present every 15-25 minutes of active play. The child picks one of three
## fixed gifts. Never paid, never needed, and nothing for time away: only seconds of play count, a frame
## counts at most MAX_STEP, and a waiting present stops the clock (presents never pile up).

## Minutes of play before each present, in turn (a fixed round, no dice: spec §6).
const INTERVALS_MIN: Array[int] = [15, 20, 25, 18, 22, 16, 24]
## One frame counts at most this long: a phone asleep for hours comes back as one long frame.
const MAX_STEP := 1.0
## The longest wait there is (the clock's saved seconds are clamped to it).
const LONGEST_S := 25.0 * 60.0
## No input and no movement for this long: the child is away, the clock stands still.
const IDLE_S := 60.0
## The pet must be this close to bring its present.
const PET_NEAR := 24.0
## The host gives a player a present at most this often (a real one comes every 15 minutes or more).
const CLAIM_GAP_MS := 10 * 60 * 1000

## Survivor: a little gold or a few useful blocks (from the host). Sandbox: stickers (gold is endless).
const SURVIVOR_GIFTS: Array[Dictionary] = [
	{"id": &"gold", "words": "15 gold", "picture": &"coin", "gold": 15, "item": 0, "count": 0, "sticker": ""},
	{"id": &"lanterns", "words": "2 lanterns", "picture": &"lantern", "gold": 0, "item": BlockIds.LANTERN, "count": 2,
		"sticker": ""},
	{"id": &"planks", "words": "10 planks", "picture": &"planks", "gold": 0, "item": BlockIds.PLANKS, "count": 10,
		"sticker": ""},
]
const SANDBOX_GIFTS: Array[Dictionary] = [
	{"id": &"gift_flower", "words": "Flower sticker", "picture": &"flower", "gold": 0, "item": 0, "count": 0,
		"sticker": "gift_flower"},
	{"id": &"gift_heart", "words": "Heart sticker", "picture": &"heart", "gold": 0, "item": 0, "count": 0,
		"sticker": "gift_heart"},
	{"id": &"gift_star", "words": "Star sticker", "picture": &"star", "gold": 0, "item": 0, "count": 0,
		"sticker": "gift_star"},
]
## The gift stickers (the board's stickers are its goals' ids).
const STICKERS: Array[StringName] = [&"gift_flower", &"gift_heart", &"gift_star"]


## Seconds of play before present number n (0 = the first).
static func interval_s(n: int) -> float:
	return INTERVALS_MIN[maxi(n, 0) % INTERVALS_MIN.size()] * 60.0


## Counts `delta` seconds of play (active: the child did something lately; has_pet: their pet is near).
## True when a present has just become ready.
static func tick(d: ProgressData, delta: float, active: bool, has_pet: bool) -> bool:
	if d.present_waiting or not active or not has_pet or not is_finite(delta) or delta <= 0.0:
		return false
	d.present_s = minf(d.present_s + minf(delta, MAX_STEP), LONGEST_S)
	if d.present_s >= interval_s(d.presents):
		d.present_waiting = true
		return true
	return false


static func gifts(survivor: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	for g: Dictionary in (SURVIVOR_GIFTS if survivor else SANDBOX_GIFTS):
		out.append(g.id)
	return out


static func gift(id: StringName, survivor: bool) -> Dictionary:
	for g: Dictionary in (SURVIVOR_GIFTS if survivor else SANDBOX_GIFTS):
		if g.id == id:
			return g
	return {}


## Opens the waiting present with the gift the child picked: the clock starts again and a Sandbox gift's
## sticker goes into the book (a Survivor gift comes from the host). {} when nothing waits or the gift is
## not on this mode's list (the present keeps waiting).
static func open(d: ProgressData, id: StringName, survivor: bool) -> Dictionary:
	var g := gift(id, survivor)
	if not d.present_waiting or g.is_empty():
		return {}
	d.present_waiting = false
	d.present_s = 0.0
	d.presents += 1
	if str(g.sticker) != "":
		d.add_sticker(str(g.sticker))
	return g


## Host: may a player's present be given now (the last at last_ms; -1 = never)?
static func host_allows(last_ms: int, now_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= CLAIM_GAP_MS
