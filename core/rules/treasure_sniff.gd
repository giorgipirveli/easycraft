class_name TreasureSniff
extends RefCounted
## A pet dog sniffs out buried treasure (M2 Task 17; the research's "pets help find secrets", spec
## §12.16): now and then it trots a few blocks towards the nearest unopened buried chest — never far
## from its owner — and paws the ground right over it. It points the way; it never digs a block.

const RANGE := 24.0     # a buried treasure this near (flat blocks) gets sniffed
const STEP := 6.0       # blocks the dog leads per trip
const LEAD := 10.0      # never further than this from its owner
const DIG := 1.5        # this near the treasure (flat), it paws the ground there
const EVERY := 20.0     # seconds between trips
const TRIP := 5.0       # seconds a trip lasts before it trots back to its owner


## Where the dog trots from `dog` towards `chest` (INF: nothing near enough), staying within LEAD of
## `owner`; right over the treasure it stays there.
static func target(dog: Vector3, chest: Vector3, owner: Vector3) -> Vector3:
	if not chest.is_finite():
		return Vector3.INF
	var to := Vector2(chest.x - dog.x, chest.z - dog.z)
	if to.length() > RANGE:
		return Vector3.INF
	if to.length() <= DIG:
		return Vector3(chest.x, dog.y, chest.z)
	var t := Vector2(dog.x, dog.z) + to.normalized() * minf(STEP, to.length())
	var from_owner := t - Vector2(owner.x, owner.z)
	if from_owner.length() > LEAD:
		t = Vector2(owner.x, owner.z) + from_owner.normalized() * LEAD
	return Vector3(t.x, dog.y, t.y)


## Whether the dog stands over the treasure (it paws the ground there).
static func digs(dog: Vector3, chest: Vector3) -> bool:
	return chest.is_finite() and Vector2(chest.x - dog.x, chest.z - dog.z).length() <= DIG
