class_name VrGrabbable
extends Node3D
## Owner #110, VR round 4's frozen contract (docs/superpowers/plans/2026-10-16-vr-round4.md): a hand can take what holds
## one of these as a child (a planet, a lens, a mallet, a block; Life's coins, cloths and extinguishers later). The names,
## the exports and the signals never change; VR-HANDS' grabber (entities/vr/vr_grabber.gd, VrGrabRules) drives them, and
## the thing's own script listens. Off VR nothing grabs (the phone keeps its taps).

## A hand points at it (the outline) or not.
signal hovered(side: StringName, on: bool)
## A hand took it (`side`: &"left" or &"right"; the second hand of a &"two_hand" thing grabs too).
signal grabbed(side: StringName)
## A hand let go; `velocity` is the throw (VrGrabRules.throw_velocity), ZERO for a drop.
signal released(side: StringName, velocity: Vector3)
## The trigger while held, 0..1 (a &"tool": the lens's zoom, the extinguisher's squeeze, a mallet's strike).
signal used(side: StringName, amount: float)

## &"hold" (one hand), &"two_hand" (both: stretch or aim), &"tool" (held and used with the trigger).
@export var kind: StringName = &"hold"
## Released moving, it flies (VrGrabRules' throw); else it drops.
@export var throwable := true
## The laser's far pull reaches it (VrGrabRules.FAR_RANGE, PULL_HOLD).
@export var far_pull := true
## How it sits in the hand (from the hand's grip pose).
@export var hold_offset := Transform3D.IDENTITY

## Who holds it now (the grabber sets it): &"", &"left", &"right" or &"both".
var holder: StringName = &""

# --- VR-HANDS' body (owner #110; docs/devlog/parts/vr-r4-hands.md): plain fields, set in code by the thing's script ---

## Every grabbable in the tree (VrGrabber looks here).
const GROUP := &"vr_grabbable"
## The thing's own size round this node (m, the world's): the near reach counts from its surface, the far pick's cone
## widens for it, the glow fits it. 0: a point.
var radius := 0.0
## The grabber moves the thing (this node's parent) with the hand while held, and flies it in on a far pull. False: the
## thing's script moves itself (the Build Table's edge, the model's turn) and only hears the signals.
var follows_hand := true
## False: no hand may take it now (a placed piece, a planet in its slot).
var enabled := true
## Two hands on a &"two_hand" thing: their stretch now (VrGrabRules.stretch; 1 with one hand), for the thing's script.
var stretch := 1.0


func _enter_tree() -> void:
	add_to_group(GROUP)


## Who holds it: &"" (nobody), &"left", &"right", &"both".
func held_by() -> StringName:
	return holder


## The thing a hand takes: this node's parent.
func thing() -> Node3D:
	return get_parent() as Node3D


## A hand may take it now: in the tree, enabled, its thing shown.
func takeable() -> bool:
	var t := thing()
	return enabled and is_inside_tree() and not is_queued_for_deletion() and t != null and t.is_visible_in_tree() \
		and not t.is_queued_for_deletion()
