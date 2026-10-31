class_name LifeRoomPeople
extends RefCounted
## The rooms' look brief (2026-10-17, docs/devlog/parts/rooms-look.md): the practice rooms' people and dogs drawn in few
## meshes (the Quest's ≤ 100 draws a frame: a buddy is eleven boxes and more with a hat, a village has twelve of them).
## Nothing about a buddy changes but how its boxes are drawn: its head's boxes (the face, a hat, the eyes and the mouth)
## become one mesh under the head (it still nods), its body's become one mesh per moving part (`merge_person`), or one
## mesh for the whole body of a buddy who never changes pose again in its room (`rigid`). The boxes stay as hidden nodes,
## so LifeBuddy's own code (face, pose, nod, the marks, the ouch spots) works as before; a room that changes a merged
## buddy's face calls `feel` (LifeBuddy.face, then the head drawn again), and after recolouring one, `redraw`.
## Every mesh draws with LifeRoomDecor's lit vertex-colour material (already warmed up).

const HEAD_LOOK := "HeadLook"
const BODY_LOOK := "BodyLook"
const PART_LOOK := "Look"
const MERGED := &"look_merged"


## Draws `b` in few meshes: its head in one, its body in one per moving part (arms and legs still swing), or in one
## (`rigid`: for a buddy whose pose never changes again; nods and faces still show).
static func merge_person(b: LifeBuddy, rigid: bool = false) -> void:
	b.set_meta(&"look_rigid", rigid)
	redraw(b)


## LifeBuddy.face(feeling) for a merged buddy: the face changes and is drawn again.
static func feel(b: LifeBuddy, feeling: String) -> void:
	b.face(feeling)
	if b.has_meta(&"look_rigid"):
		_head(b)


## Draws a merged buddy again (after its boxes were recoloured or moved by the room).
static func redraw(b: LifeBuddy) -> void:
	_head(b)
	if bool(b.get_meta(&"look_rigid", false)):
		_together(b, b, [b.head], BODY_LOOK)
	else:
		for pivot: Node3D in [b.hips, b.arm_near, b.arm_far, b.leg_near, b.leg_far]:
			_together(pivot, pivot, [b.head] + _pivots_under(b, pivot), PART_LOOK)


## The other moving parts under `pivot` (they draw themselves).
static func _pivots_under(b: LifeBuddy, pivot: Node3D) -> Array:
	var out: Array = []
	for p: Node3D in [b.hips, b.head, b.arm_near, b.arm_far, b.leg_near, b.leg_far]:
		if p != pivot and pivot.is_ancestor_of(p):
			out.append(p)
	return out


## The head: its own boxes (the face block, a hat, glasses) always, and the face's parts as LifeBuddy.face left them:
## the eyes (squashed or not), the first smile until a feeling was shown, then the feeling's mouth, its corners when
## shown, and the brows.
static func _head(b: LifeBuddy) -> void:
	var face_parts := {}
	var fp: Variant = b.get("_face_parts")
	if fp is Dictionary:
		for k: Variant in fp:
			face_parts[fp[k]] = str(k)
	var smile := b.head.get_node_or_null("Smile")
	var d := LifeRoomDecor.new()
	for n: Node in b.head.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.name == HEAD_LOOK or m.is_queued_for_deletion() or not (m.get_meta(MERGED, false) or LifeRoomDecor._plain_lit(m) and _shown_under(m, b.head)):
			continue
		var draw := true
		if m == smile:
			draw = b.feeling == ""
		elif face_parts.has(m):
			draw = not str(face_parts[m]).begins_with("corner") or m.visible
		if draw:
			LifeRoomDecor._merge(m, b.head, d)
		m.set_meta(MERGED, true)
		m.visible = false
	_replace(b.head, HEAD_LOOK, d)


## Every plain lit box under `root` (but under the parts in `skip`) drawn in one mesh named `look` under `into`.
static func _together(root: Node3D, into: Node3D, skip: Array, look: String) -> void:
	var d := LifeRoomDecor.new()
	var count := 0
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.name == look or m.name == HEAD_LOOK or m.name == BODY_LOOK or m.name == PART_LOOK:
			continue
		var skipped := false
		for s: Node in skip:
			if s == m or (s as Node).is_ancestor_of(m):
				skipped = true
		if skipped or m.is_queued_for_deletion() or not (m.get_meta(MERGED, false) or LifeRoomDecor._plain_lit(m) and _shown_under(m, root)):
			continue
		LifeRoomDecor._merge(m, into, d)
		m.set_meta(MERGED, true)
		m.visible = false
		count += 1
	if count < 2 and into.get_node_or_null(look) == null:
		# one box alone already draws once: leave it as it was
		for n: Node in root.find_children("*", "MeshInstance3D", true, false):
			if (n as Node).get_meta(MERGED, false) and not _skipped(n, skip):
				(n as MeshInstance3D).visible = true
				n.remove_meta(MERGED)
		return
	_replace(into, look, d)


static func _skipped(n: Node, skip: Array) -> bool:
	for s: Node in skip:
		if s == n or s.is_ancestor_of(n):
			return true
	return false


## Whether `m` shows when `root` does (its own and its parents' visibility up to root).
static func _shown_under(m: Node3D, root: Node) -> bool:
	var at: Node = m
	while at != null and at != root:
		if at is Node3D and not (at as Node3D).visible:
			return false
		at = at.get_parent()
	return true


static func _replace(into: Node3D, look: String, d: LifeRoomDecor) -> void:
	var old := into.get_node_or_null(look)
	if old != null:
		into.remove_child(old)
		old.free()
	if d._parts[LifeRoomDecor.LIT].empty():
		return
	d.commit(into, "")
	var made := into.get_node_or_null("Decor_Lit")
	if made != null:
		made.name = look


# --- Dogs --------------------------------------------------------------------------------------------------------------

## A dog in few meshes: each of its moving parts' own boxes (the body, the head with its face, each ear, the tail, each
## leg) in one, the warning signs (the brow, the lips) left as they are: the room shows and hides them. A dog whose mood
## never changes again in its room (`still`: it neither runs, wags, sleeps nor wakes) is one mesh as its mood left it.
static func merge_dog(dog: LifeDog, still: bool = false) -> void:
	if still:
		_together(dog, dog, [], PART_LOOK)
		return
	var parts: Array = [dog.body, dog.head, dog.tail] + dog.ears + dog.legs
	for p: Node3D in parts:
		var skip: Array = []
		for q: Node3D in parts:
			if q != p and p.is_ancestor_of(q):
				skip.append(q)
		if dog.brow != null:
			skip.append(dog.brow)
		if dog.lips != null:
			skip.append(dog.lips)
		for e: Node in dog.head.get_children():   # the eyes close when it sleeps (set_mood scales them)
			if e is MeshInstance3D and _dog_eye(e as MeshInstance3D):
				skip.append(e)
		_direct(p, skip)


static func _dog_eye(m: MeshInstance3D) -> bool:
	var box := m.mesh as BoxMesh
	var mat := m.material_override as StandardMaterial3D
	return m.name.begins_with("Eye") or (box != null and mat != null and mat.albedo_color == LifeDog.EYES
		and is_equal_approx(box.size.y, 0.025))


## The plain lit boxes right under `p` (not under its moving children) in one mesh.
static func _direct(p: Node3D, skip: Array) -> void:
	var d := LifeRoomDecor.new()
	var count := 0
	for c: Node in p.get_children():
		if not c is MeshInstance3D or c.name == PART_LOOK or _skipped(c, skip):
			continue
		var m := c as MeshInstance3D
		if not LifeRoomDecor._plain_lit(m) or not m.visible or m.get_child_count() > 0:
			continue
		LifeRoomDecor._merge(m, p, d)
		m.set_meta(MERGED, true)
		m.visible = false
		count += 1
	if count < 2:
		for c: Node in p.get_children():
			if c.get_meta(MERGED, false):
				(c as MeshInstance3D).visible = true
				c.remove_meta(MERGED)
		return
	_replace(p, PART_LOOK, d)


# --- Moving things ------------------------------------------------------------------------------------------------------

## A moving or hidden-and-shown thing's own boxes (a float's eight bits, a pole and its hook) drawn in one mesh under it:
## the thing still moves, shows and hides as one. Boxes the room holds or taps (a property, a target) stay themselves.
static func merge_parts(room: Node, node: Node3D) -> void:
	var keep := {}
	for p: Dictionary in room.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			LifeRoomDecor._refs(room.get(p.name), keep, 0)
	var t: Variant = room.get("targets")
	if t is Dictionary:
		for k: Variant in t:
			var n: Variant = (t[k] as Dictionary).get("node")
			if n is Node:
				keep[n] = true
	keep.erase(node)
	# only what the room holds under the thing stays itself (the thing's own holder, a dictionary of bottles, never does)
	_direct(node, keep.keys().filter(func(k: Variant) -> bool: return k is Node and node.is_ancestor_of(k as Node)))


## A thing that never comes apart (a bottle with its warning sign) drawn in one mesh under it, all its plain boxes however
## deep, but under the parts in `skip`. A target inside it keeps its place: the room taps and glows at the node itself.
static func merge_whole(node: Node3D, skip: Array = []) -> void:
	_together(node, node, skip, PART_LOOK)
