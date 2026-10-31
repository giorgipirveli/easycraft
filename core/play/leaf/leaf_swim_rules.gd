class_name LeafSwimRules
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §2.3, §4.4, ruling 14; the lead's review, question 5): moving
## through the leaf in VR. Swimming, Gorilla Tag's way (the owner's child's game): squeeze a grip and pull, and the body
## moves the other way (the gripping hands' pull, averaged, up to MAX_SPEED); let go and the thick air stops it within
## STOP_TIME (at a cell's size air really is thick: Purcell's low Reynolds number), the most comfortable movement there
## is: you stop when you stop. The laser's grapple glides to a door, a pipe or a cell in GLIDE s, eased in and out
## (PlayHost.GLIDE). Pure: B2's host feeds the hands' velocities (relative to the body) and moves the VR anchor.

const MAX_SPEED := 2.5
## From top speed to under 5 cm/s with no pull (v x e^(-DRAG t)): e^(-16 x 0.25) = 0.018.
const STOP_TIME := 0.25
const DRAG := 16.0
const GLIDE := 0.6


## The body's velocity after `dt`: the gripping hands' pulls (each hand's velocity relative to the body) move it the
## other way; none, and the thick air slows it.
static func step(velocity: Vector3, pulls: Array[Vector3], dt: float) -> Vector3:
	if pulls.is_empty():
		return velocity * exp(-DRAG * dt)
	var sum := Vector3.ZERO
	for p in pulls:
		sum += p
	return (-sum / pulls.size()).limit_length(MAX_SPEED)


## Where the grapple has carried the child `t` s after the trigger, from `from` to `to`.
static func glide(from: Vector3, to: Vector3, t: float) -> Vector3:
	var f := clampf(t / GLIDE, 0.0, 1.0)
	return from.lerp(to, f * f * (3.0 - 2.0 * f))
