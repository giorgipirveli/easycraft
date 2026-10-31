class_name BuildToolUser
extends Node
## The local player's building tools (M3 Task 8; spec §14.5), a child of the BlockInteractor (like GadgetUser).
## With a tool in the hand a tap uses it where it points:
##   a PAINT colour paints the tapped block (and its mirror copy in Mirror mode); Sandbox and Survivor;
##   LINE and FILL: the first tap marks one end (the empty cell on the tapped face), the second builds a line or
##   the box between them with the block held last (`material`); Sandbox;
##   COPY: two taps on blocks select a box (at most 16 on a side) and copy it as it faces the child; every tap
##   after that pastes it on the tapped face, turned the way the child looks (TURN adds quarter turns); Sandbox;
##   REWIND: the first tap starts recording around the tapped spot (RewindLog); a tap with a recording opens the
##   time-lapse (rewind_requested); Sandbox and Survivor.
## The host checks every edit (Session section "M3 Task 8"); each is one undo step. Build Rewind records this
## player's edits from the host's undo steps and the undos asked for (the host's answer to an undo it couldn't
## finish is recorded too and cancels it). The wand's Build-and-Wear choice starts here (offer_wear).

signal state_changed
signal said(text: String)
## REWIND tapped while recording: the time-lapse opens (the sandbox shows RewindView).
signal rewind_requested
## The wand tapped a small build: the HAT / BACKPACK / WINGS card opens (the sandbox's WearCard).
signal wear_requested(picked: Dictionary, cell: Vector3i)

const NO_CELL := Vector3i(-1073741824, 0, 0)
const OTHER_END := "Now tap the other end!"
const OTHER_CORNER := "Now tap the other corner!"
const PASTE_HINT := "Tap where it goes!"
const NOTHING_TO_COPY := "Nothing to copy there! Tap two blocks of a build."
const REWIND_STARTED := "Rewind is watching! Build here, then tap with REWIND again to watch."


## What COPY (and /copy) say after copying `n` blocks (M3 Task 19: "1 block", never "1 blocks").
static func copied_words(n: int) -> String:
	return Lang.t("Copied %s! %s") % [Lang.blocks(n), PASTE_HINT]


var interactor: BlockInteractor
## LINE and FILL build with the block the child held last (0: none held yet in this game: the hotbar's first block).
var material := 0
## The first tap of LINE, FILL or COPY (NO_CELL: none yet) and the tool that made it.
var first := NO_CELL
var first_tool := 0
## The copy, in stamp coordinates (PowerTools.to_stamp), and TURN's extra quarter turns.
var clipboard := {}
var turns := 0
## Build Rewind: this player's edits around a spot (the sandbox loads and saves it with the world).
var rewind := RewindLog.new()
## Set by the sandbox when the Build-and-Wear card exists (the wand offers it only then).
var wear_enabled := false
## The glow of the first corner and the box or line being chosen (the sandbox's BuildOutline); may be null.
var outline: BuildOutline

var _shown_to := NO_CELL


func _ready() -> void:
	interactor.selection_changed.connect(_on_selection)
	Session.undo_step_received.connect(_record_step)
	Session.tool_undo_step_received.connect(_record_step)
	interactor.undoing.connect(_record_undo)


func player() -> Player:
	return interactor.player


func handles(id: int) -> bool:
	return PaintRules.is_paint(id) or ItemIds.BUILD_TOOLS.has(id)


## A tap (or a click with a captured mouse) with a tool in the hand; true when it was used.
func use_at_screen(screen_pos: Vector2) -> bool:
	var item := interactor.selected_block()
	var p := player()
	if not p.is_spawned() or p.sleeping or p.knocked_out:
		return false
	var hit := interactor.ray_at(screen_pos)
	if hit == null:
		return false
	if PaintRules.is_paint(item):
		return paint(hit.position, item)
	if item == ItemIds.REWIND:
		return rewind_at(hit.position)
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		_say(Session.TOOLS_SANDBOX_ONLY)
		return true
	if item == ItemIds.COPY_TOOL and not clipboard.is_empty():
		return paste(hit.previous_position)
	return tap(item, hit.position if item == ItemIds.COPY_TOOL else hit.previous_position)

# --- Paint ---------------------------------------------------------------------------------------------------

## Paints `cell` (and its mirror copy) with paint item `item`; the host decides.
func paint(cell: Vector3i, item: int) -> bool:
	var painted := PaintRules.painted_by(item)
	var old := player().world.get_block(cell)
	var code := PaintRules.refusal(old, painted, not Game.allows(ModeRules.UNLIMITED_BLOCKS))
	if code != "":
		_say(PaintRules.message(code, old))
		return true
	var cells: Array = [[cell, painted]]
	if interactor.mirror_enabled:
		var m := MirrorRules.mirror(cell, interactor.mirror_axis, interactor.mirror_plane)
		if m != cell:
			cells.append([m, painted])
	if Session.request_build_tool(Session.TOOL_PAINT, cells):
		var at := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
		Fx.burst(player().world, at, PaintRules.color(PaintRules.tint_of_item(item)), 12, 3.0, 0.1, 0.5, 2.0)
		interactor.melody.place(at, painted)   # M3 Task 21c: one note per paint tap
	return true

# --- LINE, FILL and COPY -------------------------------------------------------------------------------------

## One tap of a two-tap tool at `cell`: the first marks it, the second does the tool's job.
func tap(item: int, cell: Vector3i) -> bool:
	if first == NO_CELL or first_tool != item:
		first = cell
		first_tool = item
		_shown_to = NO_CELL
		_show_choice(cell)
		_say(OTHER_END if item == ItemIds.LINE_TOOL else OTHER_CORNER)
		state_changed.emit()
		return true
	var a := first
	cancel()
	match item:
		ItemIds.LINE_TOOL:   # every cell goes: the host builds only into the empty ones
			return _build(Session.TOOL_LINE, PowerTools.line_refusal(a, cell),
				func() -> Array: return _with_block(PowerTools.line_cells(a, cell)))
		ItemIds.FILL_TOOL:
			return _build(Session.TOOL_FILL, PowerTools.fill_refusal(a, cell),
				func() -> Array: return _with_block(PowerTools.box_cells(a, cell)))
		ItemIds.COPY_TOOL:
			return copy(a, cell)
	return false


## [[cell, the block held last], ...].
func _with_block(cells: Array[Vector3i]) -> Array:
	var id := held_block()
	var out: Array = []
	for c in cells:
		out.append([c, id])
	return out


func _build(kind: StringName, refusal: String, edits_of: Callable) -> bool:
	if refusal != "":
		_say(PowerTools.message(refusal))
		return true
	var edits: Array = edits_of.call()
	if edits.is_empty():
		_say(PowerTools.message(PowerTools.NOTHING))
		return true
	if Session.request_build_tool(kind, edits):
		var at := Vector3(edits[edits.size() / 2][0]) + Vector3(0.5, 0.5, 0.5)
		interactor.melody.place(at, int(edits[0][1]))   # M3 Task 21c: one note per tool step, never one per cell
		Fx.burst(player().world, at, Color("ffd23f"), 20, 5.0, 0.14, 0.8, 4.0)
		interactor.edited.emit(&"stamp")
	return true


## Copies the box between two blocks (one bulk read of the world) as it faces the child.
func copy(a: Vector3i, b: Vector3i) -> bool:
	var refusal := PowerTools.copy_refusal(a, b)
	if refusal != "":
		_say(PowerTools.message(refusal))
		return true
	var blocks := PowerTools.copy_buffer(player().world.copy_box(a.min(b), PowerTools.box_size(a, b)))
	if blocks.is_empty():
		_say(NOTHING_TO_COPY)
		return true
	clipboard = PowerTools.to_stamp(blocks, Blueprints.facing_for_yaw(player().rig.yaw))
	turns = 0
	_say(copied_words(blocks.size()))
	Audio.play(&"chime", Vector3(a))
	state_changed.emit()
	return true


## Pastes the copy on the tapped face (only into empty cells: the host checks each).
func paste(anchor: Vector3i) -> bool:
	var stamp := PowerTools.turned(clipboard, turns)
	var edits := PowerTools.paste_edits(stamp, anchor, Blueprints.facing_for_yaw(player().rig.yaw))
	return _build(Session.TOOL_PASTE, "", func() -> Array: return edits)   # the host builds into the empty cells


## TURN: the copy turns a quarter to the right.
func turn() -> void:
	turns = (turns + 1) % 4
	state_changed.emit()


## NEW COPY: forget the copy; the next two taps copy again.
func new_copy() -> void:
	clipboard = {}
	turns = 0
	cancel()
	state_changed.emit()


## Drops the first tap.
func cancel() -> void:
	var had := first != NO_CELL
	first = NO_CELL
	first_tool = 0
	_shown_to = NO_CELL
	if outline:
		outline.clear()
	if had:
		state_changed.emit()


## The tool bar's words for the tool in the hand ("" = no bar).
func hint() -> String:
	var item := interactor.selected_block()
	if not ItemIds.BUILD_TOOLS.has(item) or item == ItemIds.REWIND:
		return ""
	if item == ItemIds.COPY_TOOL and not clipboard.is_empty():
		return PASTE_HINT
	if first != NO_CELL and first_tool == item:
		return OTHER_END if item == ItemIds.LINE_TOOL else OTHER_CORNER
	match item:
		ItemIds.LINE_TOOL:
			return "LINE: tap two spots"
		ItemIds.FILL_TOOL:
			return "FILL: tap two corners"
	return "COPY: tap two corners of a build"


func _on_selection(_slot: int, id: int) -> void:
	if _is_material(id):
		material = id
	if first != NO_CELL and id != first_tool:
		cancel()
	state_changed.emit()


## The block LINE and FILL build with: the one held last, else the hotbar's first block, else stone.
func held_block() -> int:
	if material != 0:
		return material
	for id in interactor.hotbar:
		if _is_material(id):
			return id
	return BlockIds.STONE


## A block LINE and FILL can build with.
static func _is_material(id: int) -> bool:
	return BlockIds.is_valid(id) and id < BlockIds.COUNT


## While a first tap waits, the glow shows the line or box to the cell under the finger or the crosshair.
func _process(_delta: float) -> void:
	if first == NO_CELL or outline == null or not ItemIds.BUILD_TOOLS.has(interactor.selected_block()):
		return
	var point := interactor.aim_point()
	var hit := interactor.ray_at(point) if point.is_finite() else null
	if hit == null:
		return
	var to := hit.position if first_tool == ItemIds.COPY_TOOL else hit.previous_position
	if to != _shown_to:
		_shown_to = to
		_show_choice(to)


func _show_choice(to: Vector3i) -> void:
	if outline == null:
		return
	if first_tool == ItemIds.LINE_TOOL and PowerTools.line_refusal(first, to) == "":
		var cells := {}
		for c in PowerTools.line_cells(first, to):
			cells[c] = 1
		outline.show_blocks(cells)
	elif first_tool == ItemIds.LINE_TOOL:
		outline.show_blocks({first: 1})
	else:
		outline.show_box(first.min(to), PowerTools.box_size(first, to))

# --- Build Rewind --------------------------------------------------------------------------------------------

## REWIND on `cell`: starts recording there, or opens the time-lapse of the recording.
func rewind_at(cell: Vector3i) -> bool:
	if not rewind.active:
		rewind.start(cell)
		_say(REWIND_STARTED)
		Audio.play(&"chime", Vector3(cell))
		state_changed.emit()
		return true
	rewind_requested.emit()
	return true


## NEW (the time-lapse's button): forget the recording; the next REWIND tap starts one.
func restart_rewind() -> void:
	rewind.clear()
	state_changed.emit()


## The host's undo step for this player's edits: what really changed ([pos, was, is now]).
func _record_step(step: Array) -> void:
	if not rewind.active or not player().is_local:
		return
	for e: Variant in step:
		if e is Array and (e as Array).size() == 3 and e[0] is Vector3i and e[1] is int and e[2] is int:
			rewind.record(e[0], e[1], e[2])


## An undo this player asked for ([pos, becomes, was]).
func _record_undo(changes: Array) -> void:
	if not rewind.active:
		return
	for e: Array in changes:
		rewind.record(e[0], e[2], e[1])

# --- Build-and-Wear (the wand) -------------------------------------------------------------------------------

## The wand on `cell`: a small build (WearRules.MAX_SIDE) opens the HAT / BACKPACK / WINGS card (true); anything
## else is the wand's as before (false).
func offer_wear(cell: Vector3i) -> bool:
	if not wear_enabled:
		return false
	var picked := BuildPicker.pick(cell, player().world.get_block, WearRules.MAX_SIDE, WearRules.MAX_BLOCKS)
	if picked.has("error"):
		return false
	wear_requested.emit(picked, cell)
	return true


## Wears a picked build in `slot` (turned so its side facing the child is its front) and saves the look.
## Returns the words for the child ("" when it can't be worn).
static func wear(profile: ProfileData, picked: Dictionary, slot: StringName, facing: Vector3i) -> String:
	var stamp := PowerTools.to_stamp(picked.get("blocks", {}), facing)
	var code := WearRules.from_blocks(stamp)
	if code == "" or not WearRules.is_slot(slot):
		return WearRules.message(WearRules.refusal(stamp))
	profile.avatar.wear(slot, code)
	return Lang.t("You are wearing your build as %s!") % {WearRules.HAT: "a hat", WearRules.BACK: "a backpack",
		WearRules.WINGS: "wings"}[slot]


func _say(text: String) -> void:
	if text != "":
		said.emit(text)
