class_name VrBuildTable
extends Node3D
## Owner #110, VR round 4 idea 5 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "Build with your hands:
## the Build Table", R5): a floating table at hand height with BuildTableRules' 10 cm cells, 16 a side, in VR only (MORE
## → BUILD TABLE). Vr.build_table while it is open; it stays where it was put in the world.
##
## - **Build:** the pointing hand at the table takes the trigger (VrInput: it is the trigger's target here): a ghost
##   cube snaps to the cell where the hand is (standing on the table or touching a block); a tap places the selected
##   hotbar block there with a click (any non-block item: stone); a hold on a block breaks it. MORE → MIRROR mirrors
##   across the table's middle (a glass sheet shows it).
## - **Move it:** a hand on its rim (the grip) slides it and lifts it (its top kept at hand height, HEIGHT_MIN..MAX under
##   the eyes); two hands on the rim twist the build in quarter turns.
## - **Poke** its buttons with a fingertip: SAVE STAMP (My Stamps: then place it in the world like any stamp, one undo),
##   WAKE IT (the build appears in front of the child in the world and wakes as a buddy: the host's own edits and
##   wand), CLEAR, CLOSE.
## - **The School** (its "build the answer" rounds, BuildBoard): while a board shows in the VR canvas the table is that
##   board (a wall up, a farm from above), each block placed or taken is the board's (BuildBoard.paint), so its CHECK
##   reads the table's cells unchanged; it closes with the board.
## Draws while open: the frame (the top, its grid, the buttons and their words: one mesh), the blocks (one or two), the
## ghost while it shows, the mirror's sheet while MIRROR is on.

signal saved(slot: int)
signal woke(cells: int)
signal closed

const BUTTONS: Array[StringName] = [&"save", &"wake", &"clear", &"close"]
const WORDS := {&"save": "SAVE STAMP", &"wake": "WAKE IT", &"clear": "CLEAR", &"close": "CLOSE"}
const BUTTON_COLORS := {&"save": Color("8e5cf0"), &"wake": Color("f5b830"), &"clear": Color("4a90d9"),
	&"close": Color("e05555")}
const BUTTON_SIZE := Vector3(0.2, 0.03, 0.08)
const BUTTON_GAP := 0.03
const TOP_COLOR := Color(0.93, 0.88, 0.76)
const LINE_COLOR := Color(0.62, 0.58, 0.5)
const GHOST_COLOR := Color(0.55, 0.85, 1.0, 0.45)
const BREAK_COLOR := Color(1.0, 0.45, 0.4, 0.55)
const POKE_BUZZ := [0.35, 0.04]
## The hand's building point: this far ahead of the palm (the fingers; never the curling index finger's tip).
const REACH_AHEAD := 0.06
## WAKE IT: the build stands this many blocks ahead of the child's feet.
const WAKE_AHEAD := 2

var cells := {}
var size := BuildTableRules.FREE_SIZE
## The School's board shown on the table (null: the child's own table).
var board: BuildBoard = null
## The table is a School board's (it closes when the board goes).
var school := false
## The ghost's cell and the touched block now (NO_CELL: none), and the build's quarter turns so far (tests).
var ghost := BuildTableRules.NO_CELL
var touched_cell := BuildTableRules.NO_CELL
var presses := {}

var _frame := MeshInstance3D.new()
var _back := MeshInstance3D.new()
var _blocks := MeshInstance3D.new()
var _ghost := MeshInstance3D.new()
var _mirror := MeshInstance3D.new()
var _poked := &""
var _rim := {}          # side -> {at: the hand's start (table space of the start), from: the table's start transform}
var _twist_from := NAN
var _twist_done := 0
var _progress := -1.0


func _init() -> void:
	name = "VrBuildTable"
	top_level = true
	for m: MeshInstance3D in [_frame, _back, _blocks, _ghost, _mirror]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
	_frame.name = "Frame"
	_back.name = "Backboard"
	_blocks.name = "Blocks"
	_blocks.scale = Vector3.ONE * BuildTableRules.CELL
	_ghost.name = "Ghost"
	_mirror.name = "MirrorSheet"
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * BuildTableRules.CELL * 1.02
	cube.material = _unshaded(GHOST_COLOR)
	_ghost.mesh = cube
	_ghost.visible = false


static func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if c.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.albedo_color = c
	m.disable_receive_shadows = true
	return m


## Opens in front of the child's eyes (the head's facing, level), at hand height; `school_board`: that board's table.
func open_before(head: Transform3D, scale_now: float, school_board: BuildBoard = null) -> void:
	board = school_board
	school = school_board != null
	size = BuildTableRules.board_size(board.board) if board != null else BuildTableRules.FREE_SIZE
	cells = {}
	if board != null:
		_read_board()
		if not board.changed.is_connected(_read_board):
			board.changed.connect(_read_board)
	var fwd := -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	# the table's space is the world's for a child facing its -Z: x right, y up, z towards the child; its origin is the
	# top's far-left corner
	var basis := Basis.looking_at(fwd, Vector3.UP)
	var width := size.x * BuildTableRules.CELL * scale_now
	var depth := size.z * BuildTableRules.CELL * scale_now
	var at := head.origin + fwd * (BuildTableRules.AHEAD * scale_now + depth) - basis.x * width * 0.5
	at.y = head.origin.y - BuildTableRules.BELOW * scale_now
	global_transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * scale_now), at)
	_build_frame()
	rebuild()


## The table's top, its grid, the buttons and their words: one mesh, one material (vertex colours): one draw. The
## School's wall gets a see-through backboard of its own.
func _build_frame() -> void:
	var w := size.x * BuildTableRules.CELL
	var d := size.z * BuildTableRules.CELL
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(w * 0.5, -0.01, d * 0.5), Vector3(w + 0.04, 0.02, d + 0.04), TOP_COLOR)
	for i in size.x + 1:
		_add_box(st, Vector3(i * BuildTableRules.CELL, 0.0005, d * 0.5), Vector3(0.003, 0.001, d), LINE_COLOR)
	for k in size.z + 1:
		_add_box(st, Vector3(w * 0.5, 0.0005, k * BuildTableRules.CELL), Vector3(w, 0.001, 0.003), LINE_COLOR)
	if board == null:
		for b: StringName in BUTTONS:
			var at := button_at(b)
			_add_box(st, at, BUTTON_SIZE, BUTTON_COLORS[b])
			var tm := TextMesh.new()
			tm.text = WORDS[b]
			tm.font_size = 48
			tm.pixel_size = 0.0006
			tm.depth = 0.001
			# lying on the button, read from the child's side
			_add_arrays(st, tm.get_mesh_arrays(), Transform3D(Basis(Vector3.RIGHT, -PI * 0.5),
				at + Vector3(0.0, BUTTON_SIZE.y * 0.5 + 0.001, 0.0)), Color.WHITE)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	st.set_material(m)
	_frame.mesh = st.commit()
	var wall := board != null and str(board.board.get("view", "wall")) != "farm"
	_back.visible = wall
	if wall:
		var back := QuadMesh.new()
		back.size = Vector2(w, size.y * BuildTableRules.CELL)
		back.material = _unshaded(Color(1.0, 1.0, 1.0, 0.25))
		(back.material as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		_back.mesh = back   # behind the wall's one row, facing the child
		_back.position = Vector3(w * 0.5, size.y * BuildTableRules.CELL * 0.5, -0.002)


static func _add_box(st: SurfaceTool, at: Vector3, box_size: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = box_size
	_add_arrays(st, box.get_mesh_arrays(), Transform3D(Basis(), at), color)


## A primitive mesh's triangles into `st`, moved by `xf`, in one colour.
static func _add_arrays(st: SurfaceTool, arrays: Array, xf: Transform3D, color: Color) -> void:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
		idx = arrays[Mesh.ARRAY_INDEX]
	var count := idx.size() if not idx.is_empty() else verts.size()
	for n in count:
		var i := idx[n] if not idx.is_empty() else n
		st.set_color(color)
		st.set_normal((xf.basis * normals[i]).normalized())
		st.add_vertex(xf * verts[i])


## A button's middle in the table's space: a row along the near edge, just in front of it.
func button_at(b: StringName) -> Vector3:
	var i := BUTTONS.find(b)
	var row := BUTTONS.size() * BUTTON_SIZE.x + (BUTTONS.size() - 1) * BUTTON_GAP
	var x := size.x * BuildTableRules.CELL * 0.5 - row * 0.5 + BUTTON_SIZE.x * 0.5 + i * (BUTTON_SIZE.x + BUTTON_GAP)
	return Vector3(x, -0.005, size.z * BuildTableRules.CELL + BUTTON_SIZE.z * 0.5 + 0.03)


## The blocks' mesh again (after any change).
func rebuild() -> void:
	if cells.is_empty():
		_blocks.mesh = null
		return
	var buf := VoxelBuffer.new()
	buf.create(size.x + 2, size.y + 2, size.z + 2)
	for c: Vector3i in cells:
		buf.set_voxel(int(cells[c]), c.x + 1, c.y + 1, c.z + 1, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = WorldService.library()
	_blocks.mesh = mesher.build_mesh(buf, [], {})
	_blocks.position = -Vector3.ONE * BuildTableRules.CELL   # mesh coords: a cell's block at (c + 1)


func close() -> void:
	if board != null and is_instance_valid(board) and board.changed.is_connected(_read_board):
		board.changed.disconnect(_read_board)
	board = null
	closed.emit()
	queue_free()

# --- The hands ---

## A hand's building point in the table's space (the child's metres).
func hand_point(side: StringName) -> Vector3:
	var p := Vr.hand_grip(side) * Vector3(0.0, 0.0, -REACH_AHEAD * Vr.world_scale())
	return global_transform.affine_inverse() * p


## The hand is at the table (inside its building space, a little round it): the trigger is the table's then.
func wants_trigger(side: StringName) -> bool:
	if not is_inside_tree():
		return false
	var p := hand_point(side)
	var m := BuildTableRules.MARGIN
	return p.x >= -m and p.z >= -m and p.y >= -0.03 and p.x <= size.x * BuildTableRules.CELL + m \
		and p.z <= size.z * BuildTableRules.CELL + m and p.y <= size.y * BuildTableRules.CELL + m


## One frame (Vr.step): the ghost and the touched block under the pointing hand, the rim's hands, the pokes, the
## mirror's sheet.
func step(_delta: float) -> void:
	if school and not (is_instance_valid(board) and board.is_visible_in_tree()):
		close()   # the School's round ended
		return
	var point := Vr.pointing_hand()
	var p := hand_point(point)
	var at_table := wants_trigger(point)
	touched_cell = BuildTableRules.touched(p, cells, size) if at_table else BuildTableRules.NO_CELL
	ghost = BuildTableRules.ghost_cell(p, cells, size, board == null) if at_table else BuildTableRules.NO_CELL
	if touched_cell != BuildTableRules.NO_CELL and board != null and _given(touched_cell):
		touched_cell = BuildTableRules.NO_CELL   # a board's given blocks stay
	_show_ghost()
	_step_rim()
	_poke()
	var mirror := _mirror_on()
	_mirror.visible = mirror
	if mirror and _mirror.mesh == null:
		var q := QuadMesh.new()
		q.size = Vector2(size.z * BuildTableRules.CELL, size.y * BuildTableRules.CELL * 0.5)
		q.material = _unshaded(Color(0.75, 0.9, 1.0, 0.18))
		(q.material as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		_mirror.mesh = q
		_mirror.position = Vector3(size.x * BuildTableRules.CELL * 0.5, q.size.y * 0.5, size.z * BuildTableRules.CELL * 0.5)
		_mirror.rotation = Vector3(0.0, PI * 0.5, 0.0)


func _show_ghost() -> void:
	var c := touched_cell if touched_cell != BuildTableRules.NO_CELL and _progress >= 0.0 else ghost
	_ghost.visible = c != BuildTableRules.NO_CELL
	if not _ghost.visible:
		return
	_ghost.position = (Vector3(c) + Vector3(0.5, 0.5, 0.5)) * BuildTableRules.CELL
	var breaking := c == touched_cell
	var s := 1.0 - 0.5 * clampf(_progress, 0.0, 1.0) if breaking else 1.0
	_ghost.scale = Vector3.ONE * s
	((_ghost.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = BREAK_COLOR if breaking else GHOST_COLOR


func _mirror_on() -> bool:
	var interactor := _interactor()
	return board == null and interactor != null and interactor.mirror_enabled

# --- The trigger (VrInput's target while the hand is at the table) ---

## A tap: the selected block on the ghost's cell (and its mirror twin).
func place_crosshair() -> bool:
	if ghost == BuildTableRules.NO_CELL:
		return false
	if board != null:   # the School's board decides (a checked board is locked): the table shows what it has
		board.paint(BuildTableRules.board_cell(ghost, board.board), true)
		_read_board()
		if not cells.has(ghost):
			return false
		Audio.play(&"place", global_position)
		return true
	var id := _block_in_hand()
	var put: Array[Vector3i] = [ghost]
	if _mirror_on():
		var twin := BuildTableRules.mirrored(ghost, size)
		if twin != ghost and not cells.has(twin):
			put.append(twin)
	for c in put:
		cells[c] = id
	rebuild()
	Audio.play(&"place", global_position)
	return true


## A hold: the touched block goes (and its mirror twin).
func break_crosshair() -> bool:
	if touched_cell == BuildTableRules.NO_CELL:
		return false
	_progress = -1.0
	if board != null:
		var gone := touched_cell
		board.paint(BuildTableRules.board_cell(gone, board.board), false)
		_read_board()
		if cells.has(gone):
			return false
		Audio.play(&"break", global_position)
		return true
	var take: Array[Vector3i] = [touched_cell]
	if _mirror_on():
		var twin := BuildTableRules.mirrored(touched_cell, size)
		if twin != touched_cell and cells.has(twin):
			take.append(twin)
	for c in take:
		cells.erase(c)
	rebuild()
	Audio.play(&"break", global_position)
	return true


## The hold's progress on the touched block (the ghost shrinks red); a negative progress: none.
func show_break_progress(_hit: Variant, progress: float) -> void:
	_progress = progress


## VrInput reads it for the hold's progress: a stand-in hit while a block is touched.
func ray_at(_pos: Vector2) -> BlockHit:
	return BlockHit.new(touched_cell, touched_cell, 0.0) if touched_cell != BuildTableRules.NO_CELL else null


## The block the hand builds with: the board's, else the selected hotbar block (stone for anything that is no block).
func _block_in_hand() -> int:
	if board != null:
		return int(board.board.get("block", BlockIds.STONE))
	var interactor := _interactor()
	var id := VrBrickRules.bag_brick(interactor.selected_block()) if interactor != null else 0
	if CrystalRules.is_crystal(id):
		id = CrystalRules.core_for_item(id)
	return id if BlockIds.is_valid(id) else BlockIds.STONE

# --- The rim: slide and lift with one hand, a twist with two (a grip claimer, VrGrabber.claimers) ---

func grip_claim(side: StringName) -> bool:
	if not _on_rim(side):
		return false
	_rim[side] = {"at": Vr.hand_grip(side).origin, "from": global_transform}
	if _rim.size() == 2:
		_twist_from = _hands_yaw()
		_twist_done = 0
	Vr.haptic(side, 0.25, 0.03)
	return true


func grip_release(side: StringName) -> void:
	_rim.erase(side)
	_twist_from = NAN
	for other: StringName in _rim.keys():   # the other hand keeps it from here
		_rim[other] = {"at": Vr.hand_grip(other).origin, "from": global_transform}


## The hand is on the table's rim: by the top's height, within RIM of its edge, never over the building space's middle.
func _on_rim(side: StringName) -> bool:
	var p := global_transform.affine_inverse() * Vr.hand_grip(side).origin
	var w := size.x * BuildTableRules.CELL
	var d := size.z * BuildTableRules.CELL
	var r := BuildTableRules.RIM
	if absf(p.y) > r or p.x < -r or p.z < -r or p.x > w + r or p.z > d + r:
		return false
	return p.x < r or p.z < r or p.x > w - r or p.z > d - r


func _step_rim() -> void:
	if _rim.size() == 2 and not is_nan(_twist_from):
		var q := BuildTableRules.twist_quarters(angle_difference(_twist_from, _hands_yaw()))
		if q != _twist_done and board == null:
			cells = BuildTableRules.turned(cells, q - _twist_done, size)
			_twist_done = q
			rebuild()
			for side: StringName in _rim.keys():
				Vr.haptic(side, 0.3, 0.04)
		return
	if _rim.size() != 1:
		return
	var side: StringName = _rim.keys()[0]
	var r: Dictionary = _rim[side]
	var moved: Vector3 = Vr.hand_grip(side).origin - (r.at as Vector3)
	var t: Transform3D = r.from
	var at := t.origin + moved
	var eye := Vr.head_transform().origin.y
	var s := Vr.world_scale()
	at.y = clampf(at.y, eye - BuildTableRules.HEIGHT_MAX * s, eye - BuildTableRules.HEIGHT_MIN * s)
	global_transform = Transform3D(t.basis, at)


func _hands_yaw() -> float:
	var v := Vr.hand_grip(VrRules.RIGHT).origin - Vr.hand_grip(VrRules.LEFT).origin
	return atan2(-v.z, v.x)

# --- The buttons, poked ---

func _poke() -> void:
	if board != null:
		return
	var model := Vr.hand_models.get(Vr.pointing_hand()) as VrHandModel
	if model == null:
		return
	var tip := global_transform.affine_inverse() * model.fingertip()
	var on := &""
	for b: StringName in BUTTONS:
		var d := tip - button_at(b)
		if absf(d.x) <= BUTTON_SIZE.x * 0.5 and absf(d.z) <= BUTTON_SIZE.z * 0.5 and d.y <= BUTTON_SIZE.y * 0.5 + 0.015 \
				and d.y >= -BUTTON_SIZE.y:
			on = b
	if on != &"" and on != _poked:
		press(on)
	_poked = on


## A button pressed (a poke, or a test).
func press(b: StringName) -> void:
	presses[b] = int(presses.get(b, 0)) + 1
	Vr.haptic(Vr.pointing_hand(), float(POKE_BUZZ[0]), float(POKE_BUZZ[1]))
	Audio.play(&"ui_click")
	match b:
		&"save":
			save_stamp()
		&"wake":
			wake()
		&"clear":
			cells.clear()
			rebuild()
		&"close":
			close()


## SAVE STAMP: into this device's My Stamps (the palette's STAMPS page), as the stamp bar saves one. The slot, or -1.
func save_stamp() -> int:
	var book := MyStampBook.current()
	var blocks := BuildTableRules.stamp_blocks(cells)
	var why := MyStampBook.refusal(blocks, book)
	if why != "":
		_say(MyStampBook.message(why))
		return -1
	var slot := book.add(blocks, Vector3i(0, 0, -1), int(Time.get_unix_time_from_system()))
	if slot < 0:
		_say(MyStampBook.message("too_big"))
		return -1
	MyStampBook.save_current()
	Audio.play(&"sparkle")
	_say(tr("Saved as %s! Find it in the palette's STAMPS page.") % MyStampBook.name_of(slot))
	saved.emit(slot)
	return slot


## WAKE IT: the build is put in the world WAKE_AHEAD blocks in front of the child (the host's own edits, Survivor's bag)
## and the host's wand wakes it (Session.request_spark: its reach, the buddy cap). False when there is nothing to wake.
func wake() -> bool:
	var interactor := _interactor()
	if interactor == null or cells.is_empty():
		return false
	var player := interactor.player
	var forward := Blueprints.facing_for_yaw(player.rig.yaw)
	var anchor := Vector3i(player.global_position.floor()) + forward * WAKE_AHEAD
	var edits := PowerTools.paste_edits(BuildTableRules.as_stamp(cells), anchor, forward)
	if not interactor.apply_edits(edits, false):
		return false
	Session.request_spark(edits[0][0])
	woke.emit(cells.size())
	cells.clear()
	rebuild()
	return true


func _read_board() -> void:
	if board == null or not is_instance_valid(board):
		return
	cells.clear()
	var id := int(board.board.get("block", BlockIds.STONE))
	for b: Vector2i in board.cells():
		cells[BuildTableRules.table_cell(b, board.board)] = id
	rebuild()


func _given(c: Vector3i) -> bool:
	return board != null and board.given.has(BuildTableRules.board_cell(c, board.board))


func _say(text: String) -> void:
	var hud := get_tree().get_first_node_in_group(Hud.GROUP) as Hud if is_inside_tree() else null
	if hud:
		hud.toast(text)


func _interactor() -> BlockInteractor:
	var p := Vr.local_player()
	return p.get_node_or_null("BlockInteractor") as BlockInteractor if p != null else null
