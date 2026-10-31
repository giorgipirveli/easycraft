class_name VrBricks
extends Node3D
## Owner #116 (2026-10-16 15:04: "using vr it should be possible to build a house for example like in real world, take
## brick or stones and put in apropriate place and etc like in real life"; it overrides the research's R5 for the world)
## and owner #110's touchable wrist hotbar (VR-HANDS; docs/devlog/parts/vr-r4-hands.md). Hand building in the world, in
## VR only: a claimer of VrGrabber's (the grip, when no VrGrabbable is near or under the laser).
##
## - **Take a block with the grip:** over the shoulder (the bag: the selected hotbar block; a tool there opens BLOCKS),
##   at the wrist hotbar (the pointing hand on the other wrist's strip: that slot, selected), or out of a wall (the
##   hand in a block or touching its face: the host's own break, Survivor's drop in the bag). It shows brick-sized in
##   the hand (its own texture), and a life-size see-through ghost shows the world cell it goes into (VrBrickRules:
##   flush against the face it touches, only touching a block or the ground, the laser's own checks).
## - **Let go:** on a ghost it is placed (BlockInteractor.place_block: the laser's request, its undo, Survivor's bag, the
##   online path) with a soft click; in the air it goes back to the bag (nothing happens). Higher than the arm: the
##   laser's place, as today.
## - **The wrist hotbar** (the other wrist's strip, VrWrist): the pointing hand's index finger touching a slot picks it.

const TAKE := [0.4, 0.05]
const CLICK := [0.3, 0.03]
const TOUCH := [0.2, 0.02]
const NOPE := [0.15, 0.06]
const GHOST_COLOR := Color(0.55, 0.85, 1.0, 0.32)
## A block taken out of a wall waits this long for the host's break (a guest's round trip); still there: no brick.
const PENDING_SECONDS := 1.0

## VrRules.LEFT / RIGHT -> the block id in that hand (0: none).
var _held := {}
var _brick := {}       # side -> Node3D, the brick's picture
var _ghost := {}       # side -> MeshInstance3D, the life-size ghost
var _cell := {}        # side -> Vector3i, the ghost's cell now (VrBrickRules.NO_CELL: none)
var _from := {}        # side -> Vector3, the brick's last point in the air
var _pending := {}     # side -> [cell, seconds left]: a block out of a wall, waiting for the host
var _touching := -1    # the wrist slot the fingertip is on (a touch picks once)
static var _meshes := {}   # block id -> its one-block mesh (shared)


func _init() -> void:
	name = "VrBricks"
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		_held[side] = 0
		_cell[side] = VrBrickRules.NO_CELL
		_from[side] = Vector3.INF
		var g := MeshInstance3D.new()
		g.name = "Ghost"
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 1.02
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = GHOST_COLOR
		m.disable_receive_shadows = true
		box.material = m
		g.mesh = box
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.top_level = true
		g.visible = false
		add_child(g)
		_ghost[side] = g


## The block in that hand (0: none).
func held(side: StringName) -> int:
	return int(_held.get(side, 0))


## The ghost's cell for that hand now (NO_CELL: none showing).
func ghost_cell(side: StringName) -> Vector3i:
	return _cell.get(side, VrBrickRules.NO_CELL)


func ghost_node(side: StringName) -> MeshInstance3D:
	return _ghost.get(side)


func brick_node(side: StringName) -> Node3D:
	return _brick.get(side)

# --- VrGrabber's claimer ---

func grip_claim(side: StringName) -> bool:
	var interactor := _interactor()
	if interactor == null or not Game.allows(ModeRules.BUILDING):
		return false
	var player := interactor.player
	if side == Vr.pointing_hand():
		var slot := wrist_slot(Vr.hand_grip(side).origin, VrBrickRules.WRIST_GRIP * Vr.world_scale())
		if slot >= 0:
			_pick_slot(interactor, slot, side)
			_from_bag(interactor, side, false)
			return true
	if _over_shoulder(side):
		_from_bag(interactor, side, true)
		return true
	var at := _brick_point(side)
	var cell := VrBrickRules.block_to_take(at, player.world.get_block, VrBrickRules.FACE_REACH * Vr.world_scale())
	if cell == VrBrickRules.NO_CELL or not PlacementRules.in_reach(player.eye_position(), cell):
		return false
	var old := player.world.get_block(cell)
	var survivor := Game.mode == ModeRules.SURVIVOR
	var id := VrBrickRules.brick_id(old, survivor, GatherRules.pickaxe_tier(Session.my_inventory) if survivor else 0)
	if interactor.break_block(cell) and id != BlockIds.AIR:
		_hold(side, id)
		if player.world.get_block(cell) != BlockIds.AIR:
			_pending[side] = [cell, PENDING_SECONDS]   # a guest: the host's answer is on its way
	return true


func grip_release(side: StringName) -> void:
	var id := held(side)
	if id == 0:
		return
	var cell := ghost_cell(side)
	var interactor := _interactor()
	if cell != VrBrickRules.NO_CELL and interactor != null and interactor.place_block(cell, id):
		Vr.haptic(side, float(CLICK[0]), float(CLICK[1]))
	_drop(side)


## The session ends: nothing is placed.
func grip_cancel(side: StringName) -> void:
	_drop(side)

# --- Taking ---

## The selected hotbar item as a brick into the hand (`bag`: from the shoulder; a tool there opens BLOCKS). Survivor:
## only with one in the bag.
func _from_bag(interactor: BlockInteractor, side: StringName, bag: bool) -> void:
	var id := VrBrickRules.bag_brick(interactor.selected_block())
	if id == 0:
		if bag:
			_press_blocks()
		return
	if Game.mode == ModeRules.SURVIVOR and Session.my_inventory.count(id) <= 0:
		Vr.haptic(side, float(NOPE[0]), float(NOPE[1]))   # none left in the bag: the faded slot says so
		return
	_hold(side, id)


func _hold(side: StringName, id: int) -> void:
	_drop(side)
	_held[side] = id
	var b := Node3D.new()
	b.name = "Brick"
	var mi := MeshInstance3D.new()
	mi.mesh = brick_mesh(id)
	mi.position = Vector3(-1.5, -1.5, -1.5)   # the one block sits at (1..2) in its mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(mi)
	b.top_level = true
	add_child(b)
	_brick[side] = b
	_from[side] = Vr.head_transform().origin
	_place_brick(side)
	Vr.haptic(side, float(TAKE[0]), float(TAKE[1]))


func _drop(side: StringName) -> void:
	_held[side] = 0
	_cell[side] = VrBrickRules.NO_CELL
	_pending.erase(side)
	(_ghost[side] as MeshInstance3D).visible = false
	var b := _brick.get(side) as Node3D
	if is_instance_valid(b):
		b.queue_free()
	_brick.erase(side)


## A block's one-block mesh (its real textures), made once.
static func brick_mesh(id: int) -> Mesh:
	if _meshes.has(id):
		return _meshes[id]
	var block := CrystalRules.core_for_item(id) if CrystalRules.is_crystal(id) else id
	var buf := VoxelBuffer.new()
	buf.create(3, 3, 3)
	buf.set_voxel(block, 1, 1, 1, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = WorldService.library()
	var mesh: Mesh = mesher.build_mesh(buf, [], {})
	_meshes[id] = mesh
	return mesh

# --- Every frame ---

## One frame (Vr.step, after the grabber): each brick in its hand and its ghost; a block out of a wall the host did
## not break goes; the fingertip on the wrist hotbar.
func step(delta: float) -> void:
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		if _pending.has(side):
			_wait_for_host(side, delta)
		if held(side) != 0:
			_place_brick(side)
			_place_ghost(side)
	_touch_wrist()


func _wait_for_host(side: StringName, delta: float) -> void:
	var p: Array = _pending[side]
	var interactor := _interactor()
	if interactor == null or interactor.player.world.get_block(p[0]) == BlockIds.AIR:
		_pending.erase(side)
		return
	p[1] = float(p[1]) - delta
	if float(p[1]) <= 0.0:
		_drop(side)   # the host said no (a pickaxe too weak, someone else's land): no brick


## The brick's middle: ahead of the palm.
func _brick_point(side: StringName) -> Vector3:
	return Vr.hand_grip(side) * Vector3(0.0, 0.0, -VrBrickRules.AHEAD * Vr.world_scale())


func _place_brick(side: StringName) -> void:
	var b := _brick.get(side) as Node3D
	if b == null:
		return
	var grip := Vr.hand_grip(side)
	b.global_transform = Transform3D(grip.basis.orthonormalized() * Basis.from_scale(Vector3.ONE * VrBrickRules.BRICK * \
		Vr.world_scale()), _brick_point(side))


func _place_ghost(side: StringName) -> void:
	var g := _ghost[side] as MeshInstance3D
	var interactor := _interactor()
	var cell := VrBrickRules.NO_CELL
	var at := _brick_point(side)
	if interactor != null and interactor.player.world != null:
		var player := interactor.player
		var block_at := player.world.get_block
		cell = VrBrickRules.ghost_cell(at, _from[side], block_at)
		if cell != VrBrickRules.NO_CELL and not VrBrickRules.may_place(cell, held(side), player.eye_position(),
				_bodies(), block_at):
			cell = VrBrickRules.NO_CELL
		if not BlockIds.is_solid(player.world.get_block(Vector3i(at.floor()))):
			_from[side] = at
	_cell[side] = cell
	g.visible = cell != VrBrickRules.NO_CELL
	if g.visible:
		g.global_transform = Transform3D(Basis(), Vector3(cell) + Vector3(0.5, 0.5, 0.5))


## Every spawned player's body (the host's own check: never a block inside a player).
func _bodies() -> Array[AABB]:
	var out: Array[AABB] = []
	for n: Node in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p != null and p.is_spawned():
			out.append(PlacementRules.player_aabb(p.global_position, p.size_scale()))
	return out

# --- The shoulder and the wrist ---

func _over_shoulder(side: StringName) -> bool:
	var inv := Vr.rig.global_transform.affine_inverse()
	var s := 1.0 / maxf(Vr.world_scale(), 0.001)
	var head := inv * Vr.head_transform()
	return VrGrabRules.over_shoulder(Transform3D(head.basis, head.origin * s), (inv * Vr.hand_grip(side).origin) * s)


## The wrist hotbar's slot within `reach` of the world point `at` (the other wrist's strip, VrWrist), or -1; the slot
## past the last block slot is the palette's "+".
func wrist_slot(at: Vector3, reach: float) -> int:
	var hud := _hud()
	var strip := _strip()
	if hud == null or strip == null:
		return -1
	var local := strip.global_transform.affine_inverse() * at
	var size := (strip.mesh as QuadMesh).size
	var margin := reach
	if absf(local.z) > reach or absf(local.x) > size.x * 0.5 + margin or absf(local.y) > size.y * 0.5 + margin:
		return -1
	var m := (strip.mesh as QuadMesh).material as StandardMaterial3D
	var c := Vector2(VrPanelRules.CANVAS)
	var origin := Vector2(m.uv1_offset.x, m.uv1_offset.y) * c
	var span := Vector2(m.uv1_scale.x, m.uv1_scale.y) * c
	var px := origin + Vector2((local.x / size.x + 0.5) * span.x, (0.5 - local.y / size.y) * span.y)
	var rects: Array[Rect2] = []
	for b: Node in hud.hotbar.get_children():
		if b is Control:
			rects.append((b as Control).get_global_rect())
	return VrBrickRules.slot_at(px, rects)


func _pick_slot(interactor: BlockInteractor, slot: int, side: StringName) -> void:
	var hud := _hud()
	if slot >= interactor.hotbar.size():
		if hud:
			hud.hotbar.palette_requested.emit()   # the "+": the palette
	else:
		interactor.tap_slot(slot)
	Vr.haptic(side, float(TOUCH[0]), float(TOUCH[1]))


## The pointing hand's fingertip touching a wrist slot picks it (once a touch).
func _touch_wrist() -> void:
	var interactor := _interactor()
	var point := Vr.pointing_hand()
	var model := Vr.hand_models.get(point) as VrHandModel
	if interactor == null or model == null or held(point) != 0:
		_touching = -1
		return
	var slot := wrist_slot(model.fingertip(), VrBrickRules.WRIST_TOUCH * Vr.world_scale())
	if slot >= 0 and slot != _touching:
		_pick_slot(interactor, slot, point)
	_touching = slot


func _strip() -> MeshInstance3D:
	if VrUi.instance == null or not is_instance_valid(VrUi.instance):
		return null
	var s := VrUi.instance.wrist.part(&"hotbar")
	return s if s.visible and s.is_inside_tree() else null


func _hud() -> Hud:
	return get_tree().get_first_node_in_group(Hud.GROUP) as Hud if is_inside_tree() else null


func _interactor() -> BlockInteractor:
	var p := Vr.local_player()
	if p == null or not p.is_spawned() or p.world == null:
		return null
	return p.get_node_or_null("BlockInteractor") as BlockInteractor


## Times the bag (BLOCKS) was opened over the shoulder (tests).
var bag_opened := 0


## The bag of blocks: BLOCKS, as the Y button does.
func _press_blocks() -> void:
	bag_opened += 1
	for on: bool in [true, false]:
		var e := InputEventAction.new()
		e.action = &"blocks"
		e.pressed = on
		Input.parse_input_event(e)
