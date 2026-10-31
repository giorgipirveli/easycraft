class_name LabPlants
extends LabModel
## A fair test: what do plants need? (spec §23.1). Three pots on the bench's shelf, the same soil: light and water, in
## the dark, no water. A tap plants a pot's seed; the test starts when every seed is in (`planted_at`, unix seconds, kept
## in the Lab Book so the pots grow while the child plays anywhere or is away). A game day is one turn of the sun
## (DayCycle.LENGTH). With water a seed sprouts on day 1 and is grown on day 2: green in the light, a pale thin shoot in
## the dark (it lives on the seed's own food); with no water it never sprouts. Done after the scene's days.

const DAY := DayCycle.LENGTH   # seconds of one game day
## What a pot shows.
const EMPTY := &"empty"
const SEED := &"seed"
const SPROUT := &"sprout"
const PLANT := &"plant"
const PALE_SPROUT := &"pale_sprout"
const PALE_SHOOT := &"pale_shoot"

var pots: Array[Dictionary] = []
var planted: Array[bool] = []
var planted_at := 0   # unix seconds when the last seed went in (0: not started)
## Unix seconds now (tests set their own).
var now: Callable = func() -> int: return int(Time.get_unix_time_from_system())


func _init(s: Dictionary = {}, clock: Callable = Callable()) -> void:
	super(s)
	if clock.is_valid():
		now = clock
	for p: Variant in s.get("pots", []):
		if p is Dictionary:
			pots.append(p)
			planted.append(false)


func plant(i: int) -> void:
	if i < 0 or i >= pots.size() or planted[i]:
		return
	planted[i] = true
	if planted.has(false):
		last = "A seed goes into the pot: %s." % str(pots[i].name).to_lower()
	else:
		planted_at = int(now.call())
		last = "Every seed is planted! Come back after %d game days to see what grew." % days_needed()


## The pots as they were planted at `at` (a Lab Book's planting coming back).
func restore(at: int) -> void:
	if at <= 0:
		return
	planted_at = at
	for i in planted.size():
		planted[i] = true


func days_needed() -> int:
	return int(scene.get("days", 2))


## Whole game days since every seed went in (0 before).
func days() -> int:
	if planted_at <= 0:
		return 0
	return maxi(0, floori((int(now.call()) - planted_at) / DAY))


func look(i: int) -> StringName:
	if i < 0 or i >= pots.size() or not planted[i]:
		return EMPTY
	var pot := pots[i]
	var stage := mini(days(), 2) if bool(pot.get("water", false)) else 0
	if stage == 0:
		return SEED
	if bool(pot.get("light", false)):
		return SPROUT if stage == 1 else PLANT
	return PALE_SPROUT if stage == 1 else PALE_SHOOT


func done() -> bool:
	return planted_at > 0 and days() >= days_needed()


## "Day 1 of 2" while it grows ("" before it starts).
func day_words() -> String:
	if planted_at <= 0:
		return ""
	return "Day %d of %d" % [mini(days(), days_needed()), days_needed()]
