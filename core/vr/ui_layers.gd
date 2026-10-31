class_name UiLayers
extends RefCounted
## VR on the Meta Quest (owner #101; the plan's contract): where a CanvasLayer of 2D UI goes. Off VR it is a plain child of
## its owner, exactly as before. In VR it is drawn into Vr.ui_viewport(), the canvas shown on the world-space panels
## (VrUi), and freed when its owner leaves the tree.
##
## Every routed layer is remembered (weakly) with its owner, so one routed before the headset starts (the WebXR route:
## ENTER VR in the main menu; an autoload's toast made at boot) moves into the canvas when it starts and back to its
## owner when it ends. A layer keeps its owner's pause behaviour there (an autoload's toast still runs while the game is
## paused; the canvas itself pauses with the game).
##
## The layers that come here (docs/devlog/parts/vr-ui.md): the world's HUD and panels (scenes/sandbox.gd), the menu's
## two, the loading card, Music's and Session's toasts, the visit's HUD, SETTINGS' MOVE BUTTONS. CanvasLayers made under a
## routed layer's controls (a coin shower, a chat's wheels) are in the canvas already.

## A layer moved into the canvas remembers whether its own process mode was set for the move.
const SET_MODE := &"vr_set_process_mode"

static var _routed: Array[Dictionary] = []   # {layer: WeakRef, owner: WeakRef}
static var _listening := false


## Adds `layer` under `owner` off VR; in VR, into the VR canvas.
static func route(layer: CanvasLayer, owner: Node) -> void:
	_listen()
	_forget_dead()
	var canvas := Vr.ui_viewport() if Vr.active() else null   # made now if this is the session's first layer
	_routed.append({"layer": weakref(layer), "owner": weakref(owner)})
	if canvas == null:
		owner.add_child(layer)
		return
	_into(layer, owner, canvas)


## The layers routed so far that still live (tests, VrUi).
static func routed() -> Array[CanvasLayer]:
	_forget_dead()
	var out: Array[CanvasLayer] = []
	for r in _routed:
		out.append(r.layer.get_ref() as CanvasLayer)
	return out


## VR started: every routed layer into the canvas (Vr.ui_viewport() makes it).
static func move_all_in(canvas: SubViewport) -> void:
	_forget_dead()
	for r in _routed:
		var layer := r.layer.get_ref() as CanvasLayer
		var owner := r.owner.get_ref() as Node
		if layer.get_parent() != canvas and owner != null and owner.is_inside_tree():
			_into(layer, owner, canvas)


## VR ended: every routed layer back to its owner (one whose owner is gone goes too).
static func move_all_out(canvas: SubViewport) -> void:
	_forget_dead()
	for r in _routed:
		var layer := r.layer.get_ref() as CanvasLayer
		var owner := r.owner.get_ref() as Node
		if layer.get_parent() != canvas:
			continue
		canvas.remove_child(layer)
		if layer.has_meta(SET_MODE):
			layer.remove_meta(SET_MODE)
			layer.process_mode = Node.PROCESS_MODE_INHERIT
		var drop: Callable = r.get("drop", Callable())
		if owner != null and drop.is_valid() and owner.tree_exiting.is_connected(drop):
			owner.tree_exiting.disconnect(drop)
		r.erase("drop")
		if owner == null or owner.is_queued_for_deletion():
			layer.queue_free()
			continue
		owner.add_child(layer)


static func _into(layer: CanvasLayer, owner: Node, canvas: SubViewport) -> void:
	if layer.get_parent() != null:
		layer.get_parent().remove_child(layer)
	var mode := effective_mode(owner)
	if layer.process_mode == Node.PROCESS_MODE_INHERIT and mode != canvas.process_mode:
		layer.process_mode = mode
		layer.set_meta(SET_MODE, true)
	canvas.add_child(layer)
	for r in _routed:
		if r.layer.get_ref() == layer and not r.has("drop"):
			var w: WeakRef = weakref(layer)
			r["drop"] = func() -> void: _drop(w)
			owner.tree_exiting.connect(r["drop"])


## The owner leaves the tree: its layer leaves the canvas now (as it would have left with its owner) and is freed.
static func _drop(w: WeakRef) -> void:
	var layer := w.get_ref() as CanvasLayer
	if layer == null or layer.is_queued_for_deletion():
		return
	if layer.get_parent() != null:
		layer.get_parent().remove_child(layer)
	layer.queue_free()


## How `n` behaves while the game is paused (its own mode, else the nearest set one above it; the root's: pausable).
static func effective_mode(n: Node) -> Node.ProcessMode:
	while n != null:
		if n.process_mode != Node.PROCESS_MODE_INHERIT:
			return n.process_mode
		n = n.get_parent()
	return Node.PROCESS_MODE_PAUSABLE


static func _listen() -> void:
	if _listening:
		return
	_listening = true
	Vr.started.connect(func() -> void: Vr.ui_viewport())   # the canvas (VrUi) takes the routed layers in


static func _forget_dead() -> void:
	_routed.assign(_routed.filter(func(r: Dictionary) -> bool: return r.layer.get_ref() != null))
