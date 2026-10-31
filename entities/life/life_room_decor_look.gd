class_name LifeRoomLook
extends RefCounted
## The rooms' look brief (2026-10-17, docs/devlog/parts/rooms-look.md): the rules a practice room's look keeps, as
## geometry a test (or a tool) can ask about any view: signs keep apart from name tags (a person's tag is the Label3D
## named "Name" over them: SuccessCast, the rooms' buddies), a first view frames its people whole and cuts no text, nothing
## crowds the camera across the middle of the view, the dressing (LifeRoom.look_pieces) never sits on a target, across a
## view's line or a VR reach or where the child stands, and what a VR eye sees costs few draws. Pure measuring: nothing
## here changes a room.

## A sign and a tag closer than this (px) on the screen count as touching.
const GAP := 2.0
## The flat HUD's top band (px of the 720-high canvas): the coach's bar and the buttons beside it cover it.
const HUD_TOP := 150.0
## Rays across the middle of the view (a grid of RAYS x RAYS) for the crowding rule.
const RAYS := 6


# --- Labels on the screen ------------------------------------------------------------------------------------------

## A label's size in the world (m): its text in its font at its size, times its pixel size and scale.
static func label_size(l: Label3D) -> Vector2:
	var f: Font = l.font
	if f == null:
		var theme := ThemeDB.get_project_theme()
		f = theme.default_font if theme != null and theme.default_font != null else ThemeDB.fallback_font
	var px := f.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_CENTER, -1, l.font_size)
	px += Vector2(l.outline_size, l.outline_size)
	var s := l.global_transform.basis.get_scale()
	return px * l.pixel_size * Vector2(s.x, s.y)


## The label's rectangle on `cam`'s screen (canvas px); a zero-size rect when it is behind the camera. `partial` (out)
## says some of it is behind.
static func label_rect(l: Label3D, cam: Camera3D) -> Rect2:
	var size := label_size(l)
	var right := cam.global_basis.x
	var up := cam.global_basis.y
	if l.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
		right = l.global_basis.x.normalized()
		up = l.global_basis.y.normalized()
	elif l.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y:
		up = Vector3.UP
	var c := l.global_position + l.offset.x * l.pixel_size * right + l.offset.y * l.pixel_size * up
	if cam.is_position_behind(c):
		return Rect2()
	var r := Rect2()
	var first := true
	for k: Vector2 in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
		var p := c + right * k.x * size.x * 0.5 + up * k.y * size.y * 0.5
		if cam.is_position_behind(p):
			continue
		var s := cam.unproject_position(p)
		if first:
			r = Rect2(s, Vector2.ZERO)
			first = false
		else:
			r = r.expand(s)
	return r


static func _labels(room: Node) -> Array[Label3D]:
	var out: Array[Label3D] = []
	for n: Node in room.find_children("*", "Label3D", true, false):
		var l := n as Label3D
		if l.is_visible_in_tree() and l.text.strip_edges() != "" and l.modulate.a > 0.05:
			out.append(l)
	return out


static func is_tag(l: Label3D) -> bool:
	return l.name == "Name"


## Every sign whose rectangle touches a name tag's on `cam`'s screen: ["SIGN over TAG", ...].
static func signs_over_tags(room: Node, cam: Camera3D, canvas: Vector2) -> Array[String]:
	var screen := Rect2(Vector2.ZERO, canvas)
	var tags: Array[Array] = []
	var signs: Array[Array] = []
	for l in _labels(room):
		var r := label_rect(l, cam)
		if r.size == Vector2.ZERO or not r.intersects(screen):
			continue
		(tags if is_tag(l) else signs).append([l, r])
	var out: Array[String] = []
	for t in tags:
		for s in signs:
			if (s[1] as Rect2).grow(GAP).intersects(t[1] as Rect2):
				out.append("'%s' over the tag '%s'" % [(s[0] as Label3D).text.replace("\n", " "), (t[0] as Label3D).text])
	return out


## Words with a piece of the dressing in front of them or through them: a clock, a frame, a short wall over a sign hides
## some of its words. Words painted flat (a sign that does not turn) are checked as they hang, from every side; a sign
## that turns to the eye as `cam` sees it (the first view). A piece the words are painted on is behind them, not in front;
## a person's name tag is not a sign.
static func words_covered(room: LifeRoom, cam: Camera3D = null) -> Array[String]:
	var out: Array[String] = []
	var into_room := room.global_transform.affine_inverse()
	for n: Node in room.find_children("*", "Label3D", true, false):
		var l := n as Label3D
		if is_tag(l) or l.text.strip_edges() == "":
			continue
		var xf := into_room * l.global_transform
		var right := xf.basis.x.normalized()
		var up := xf.basis.y.normalized()
		var front := xf.basis.z.normalized()
		if l.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			if cam == null or not l.is_visible_in_tree():
				continue
			var shown := label_rect(l, cam)
			if shown.size == Vector2.ZERO or not shown.intersects(cam.get_viewport().get_visible_rect()):
				continue   # not in this view: it turns to whoever sees it
			var eye := into_room.basis * cam.global_basis
			right = eye.x.normalized()
			up = Vector3.UP if l.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y else eye.y.normalized()
			front = eye.z.normalized()
		var size := label_size(l)
		var c := xf.origin + l.offset.x * l.pixel_size * right + l.offset.y * l.pixel_size * up
		for p: Dictionary in room.look_pieces:
			if str(p.kind) != LifeRoomDecor.DECOR and str(p.kind) != LifeRoomDecor.SHELL or not p.has("xf"):
				continue
			var into := (p.xf as Transform3D).affine_inverse()
			var local := (p.local as AABB).abs()
			var hit := false
			for i in 25:   # points over the words, a little in front of them up to a hand's length
				for j in 3:
					for depth: float in [0.008, 0.04, 0.1, 0.25]:
						var at := c + right * (i / 24.0 - 0.5) * size.x * 0.98 + up * (j / 2.0 - 0.5) * size.y * 0.7 + front * depth
						if local.has_point(into * at):
							hit = true
			if hit:
				out.append("%s covers '%s'" % [p.name, l.text.replace("\n", " ")])
	return out


## The part of the canvas the HUD leaves the room (under the coach's bar).
static func free_view(canvas: Vector2) -> Rect2:
	return Rect2(0, HUD_TOP, canvas.x, canvas.y - HUD_TOP)


## Every label cut by the screen's edges or the HUD's top band (some of it in the free view, some off the screen, under
## the band or behind the camera). A label wholly under the band or off the screen is not cut.
static func text_cut(room: Node, cam: Camera3D, canvas: Vector2) -> Array[String]:
	var screen := Rect2(Vector2.ZERO, canvas)
	var free := free_view(canvas)
	var out: Array[String] = []
	var spots: Array[Vector3] = []   # what a step taps: a board's rows read where they are (a target never moves)
	var t: Variant = room.get("targets")
	if t is Dictionary:
		for k: Variant in t:
			var n: Variant = (t[k] as Dictionary).get("node")
			if n is Node3D and is_instance_valid(n):
				spots.append((n as Node3D).global_position)
	for l in _labels(room):
		var size := label_size(l)
		var c := l.global_position
		if cam.is_position_behind(c):
			continue
		var r := label_rect(l, cam)
		if not r.intersects(screen):
			continue
		var corners_behind := false
		for k: Vector2 in [Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]:
			if cam.is_position_behind(c + cam.global_basis.x * k.x * size.x * 0.5 + cam.global_basis.y * k.y * size.y * 0.5):
				corners_behind = true
		if corners_behind or not screen.grow(2.0).encloses(r):
			out.append("'%s' is cut at the edge (%s)" % [l.text.replace("\n", " "), r])
			continue
		# half under the HUD's bar is cut too, but for a target's own words (a board's row: the target stays where it is)
		var by_target := spots.any(func(p: Vector3) -> bool: return p.distance_to(c) < 1.0)
		if r.intersects(free) and not free.grow(2.0).encloses(r) and not by_target:
			out.append("'%s' is half under the HUD's bar (%s)" % [l.text.replace("\n", " "), r])
	return out


# --- People in the first view ------------------------------------------------------------------------------------

## Every person (a buddy, the training dummy) partly on `cam`'s screen whose head is not wholly in the free view (on the
## screen and under the HUD's top band).
static func heads_cut(room: Node, cam: Camera3D, canvas: Vector2) -> Array[String]:
	var out: Array[String] = []
	for n: Node in room.find_children("*", "Node3D", true, false):
		if not (n is LifeBuddy or n is LifeDummy) or not (n as Node3D).is_visible_in_tree():
			continue
		var head_node: Node3D = (n as LifeBuddy).head if n is LifeBuddy else (n as Node3D).get_node_or_null("Head") as Node3D
		if head_node == null:
			continue
		var head := _box_of(head_node, null)
		var body := _box_of(n as Node3D, head_node)
		if head.size == Vector3.ZERO or not _any_on_screen(body, cam, canvas):
			continue
		# a person carrying a step's target (Bobo's marks, Max's chest) stands where the steps need them: their head must
		# be on the screen; anyone else's under the HUD's top bar too
		var carries := _carries_target(room, n)
		if not _all_in(head, cam, Rect2(Vector2.ZERO, canvas) if carries else free_view(canvas)):
			out.append("%s's head is cut (%s)" % [n.name, _screen_box(head, cam)])
	return out


## The global box of the visible meshes under `n` (and `n` itself), leaving out what is under `without`.
static func _box_of(n: Node3D, without: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var all: Array[Node] = [n]
	all.append_array(n.find_children("*", "MeshInstance3D", true, false))
	for m: Node in all:
		if not m is MeshInstance3D or not (m as Node3D).is_visible_in_tree():
			continue
		if without != null and (m == without or without.is_ancestor_of(m)):
			continue
		var g := (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = g if first else box.merge(g)
		first = false
	return box


static func _corners(b: AABB) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in 8:
		out.append(b.get_endpoint(i))
	return out


static func _on_screen(p: Vector3, cam: Camera3D, canvas: Vector2) -> bool:
	return not cam.is_position_behind(p) and Rect2(Vector2.ZERO, canvas).grow(1.0).has_point(cam.unproject_position(p))


static func _any_on_screen(b: AABB, cam: Camera3D, canvas: Vector2) -> bool:
	for p in _corners(b) + [b.get_center()]:
		if _on_screen(p, cam, canvas):
			return true
	return false


static func _all_in(b: AABB, cam: Camera3D, rect: Rect2) -> bool:
	for p in _corners(b):
		if cam.is_position_behind(p) or not rect.grow(1.0).has_point(cam.unproject_position(p)):
			return false
	return true


static func _screen_box(b: AABB, cam: Camera3D) -> String:
	var parts: Array[String] = []
	for p in [b.get_endpoint(0), b.get_endpoint(7)]:
		parts.append("behind" if cam.is_position_behind(p) else str(cam.unproject_position(p).round()))
	return " to ".join(parts)


# --- Crowding the camera --------------------------------------------------------------------------------------------

## Everything nearer than `near` (m) to `cam` along any ray through the middle of the view (the screen's middle half).
static func crowding(room: LifeRoom, cam: Camera3D, canvas: Vector2, near: float) -> Array[String]:
	var out: Array[String] = []
	var rays: Array[Vector3] = []
	for i in RAYS:
		for j in RAYS:
			var s := Vector2(canvas.x * (0.25 + 0.5 * i / (RAYS - 1)), canvas.y * (0.25 + 0.5 * j / (RAYS - 1)))
			rays.append(cam.project_ray_normal(s))
	var from := cam.global_position
	for n: Node in room.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		# a merged mesh is checked by its pieces: the room's (look_pieces) or a moving thing's (its hidden boxes)
		var drawn: bool = m.is_visible_in_tree() or (bool(m.get_meta(LifeRoomPeople.MERGED, false)) and m.get_parent() is Node3D
			and (m.get_parent() as Node3D).is_visible_in_tree())
		if not drawn or _merged(m) or m.mesh == null:
			continue
		var inv := m.global_transform.affine_inverse()
		var local_box := m.get_aabb()
		for d in rays:
			var hit: Variant = local_box.intersects_ray(inv * from, inv.basis * d)
			if local_box.has_point(inv * from):
				hit = inv * from
			if hit != null and (m.global_transform * (hit as Vector3)).distance_to(from) < near:
				out.append("%s is %.2f m from the camera" % [m.name, (m.global_transform * (hit as Vector3)).distance_to(from)])
				break
	for p: Dictionary in room.look_pieces:
		if str(p.kind) == LifeRoomDecor.SKY:
			continue
		var box: AABB = room.global_transform * (p.box as AABB)
		for d in rays:
			var hit: Variant = box.intersects_ray(from, d)
			if box.has_point(from):
				hit = from
			if hit != null and (hit as Vector3).distance_to(from) < near:
				out.append("%s (%s) is %.2f m from the camera" % [p.name, p.kind, (hit as Vector3).distance_to(from)])
				break
	return out


## A merged mesh of the look (its pieces are in look_pieces).
static func _merged(m: MeshInstance3D) -> bool:
	return m.name.begins_with("Decor_") or m.name in ["Sky", "Glass", LifeRoomPeople.PART_LOOK, LifeRoomPeople.HEAD_LOOK, LifeRoomPeople.BODY_LOOK]


# --- In the way -------------------------------------------------------------------------------------------------------

## The dressing in the way of a step at `view`: on a target, across the flat camera's or the VR eye's line to a target,
## where the child stands in VR, or round the camera.
static func in_the_way(room: LifeRoom, step: Dictionary, view: String) -> Array[String]:
	var out: Array[String] = []
	var v := room.view(view)
	var cam: Vector3 = v.cam
	var eye := room.to_local(room.vr_stand(view).origin)
	var feet: Vector3 = v.feet if (v.feet as Vector3).is_finite() else room.view(room.start_view).feet
	var targets: Array[String] = []
	for t in LifeCheck.targets_of(step):
		if room.has_target(t) and room.target_node(t).is_visible_in_tree():
			targets.append(t)
	for p: Dictionary in room.look_pieces:
		var kind := str(p.kind)
		if kind != LifeRoomDecor.DECOR and kind != LifeRoomDecor.SHELL:
			continue
		var box: AABB = p.box
		var name := str(p.name)
		if box.grow(0.05).has_point(cam):
			out.append("the camera is inside %s" % name)
		for t in targets:
			var at := room.to_local(room.target_position(t))
			var r := maxf(room.target_radius(t), 0.05)
			if kind == LifeRoomDecor.DECOR and box.grow(minf(r, 0.08)).has_point(at):
				out.append("%s sits on the target %s" % [name, t])
				continue
			var inner := _shrink(box, 0.01)
			for from: Vector3 in [cam, eye]:
				var d := at - from
				if d.length() <= r + 0.06:
					continue
				var a := from + d.normalized() * 0.05
				var b := at - d.normalized() * r
				if inner.intersects_segment(a, b) != null:
					out.append("%s is across the %s's line to %s" % [name, "camera" if from == cam else "VR eye", t])
		if kind == LifeRoomDecor.DECOR and box.end.y > 0.05 and box.position.y < 1.35:   # over a child's head (flags, a crown) is not in the way
			var foot := Vector2(feet.x, feet.z)
			var r2 := Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z)).grow(0.3)
			if r2.has_point(foot):
				out.append("%s stands where the child stands (%s)" % [name, feet])
	return out


## A box a little smaller on each side (never below a quarter of its size: thin pieces stay boxes).
static func _shrink(box: AABB, by: float) -> AABB:
	var b := box.abs()
	var d := Vector3(minf(by, b.size.x * 0.25), minf(by, b.size.y * 0.25), minf(by, b.size.z * 0.25))
	return AABB(b.position + d, b.size - d * 2.0)


# --- Draws ------------------------------------------------------------------------------------------------------------

## The draws of what `cam` can see of the room (each visible mesh's surfaces and each label inside its frustum: the
## renderer's own culling, without what hides behind what).
static func draws_seen(room: Node, cam: Camera3D, seen: Array = []) -> int:
	var planes := cam.get_frustum()
	var inside := cam.global_position - cam.global_basis.z
	var count := 0
	for n: Node in room.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var box: AABB
		if g is Label3D:
			box = AABB(g.global_position - Vector3.ONE * 0.1, Vector3.ONE * 0.2)
		else:
			box = g.global_transform * g.get_aabb()
		if not _in_frustum(box, planes, inside):
			continue
		if g.visibility_range_end > 0.0 and cam.global_position.distance_to(box.get_center()) > g.visibility_range_end:
			continue   # too far to draw (a visibility range)
		var before := count
		if g is MeshInstance3D:
			count += (g as MeshInstance3D).mesh.get_surface_count() if (g as MeshInstance3D).mesh else 0
		else:
			count += 1
		if count > before:
			seen.append(str(room.get_path_to(g)))   # which ones (a room's draws looked into)
	return count


static func _in_frustum(box: AABB, planes: Array[Plane], inside: Vector3) -> bool:
	for pl in planes:
		var in_sign := signf(pl.distance_to(inside))
		var all_out := true
		for i in 8:
			if signf(pl.distance_to(box.get_endpoint(i))) == in_sign or pl.distance_to(box.get_endpoint(i)) == 0.0:
				all_out = false
				break
		if all_out:
			return false
	return true


## Words split over two lines at the space nearest their middle (a card's words fit on the card).
static func two_lines(text: String) -> String:
	var spaces: Array[int] = []
	for i in text.length():
		if text[i] == " ":
			spaces.append(i)
	if spaces.is_empty():
		return text
	var best := spaces[0]
	for i in spaces:
		if absi(i - text.length() / 2) < absi(best - text.length() / 2):
			best = i
	return text.substr(0, best) + "\n" + text.substr(best + 1)


## Whether a step's target is `n` or under it (a person whose place the steps fix).
static func _carries_target(room: Node, n: Node) -> bool:
	var t: Variant = room.get("targets")
	if not t is Dictionary:
		return false
	for k: Variant in t:
		var node: Variant = (t[k] as Dictionary).get("node")
		if node is Node and is_instance_valid(node) and (node == n or n.is_ancestor_of(node)):
			return true
	return false
