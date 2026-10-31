extends Node
## Frame blame (2026-09-28, the browser's freezes): says what a long frame spent its time on, headless, with no change
## to the game. Every node that processes gets its own process (and physics) priority, in tree order (the game sets none,
## so the order stays the same), and a marker node right after it notes the time; a node's cost is the time between the
## marker before it and its own. A frame (between two `process_frame` signals) is split into:
##   physics_scripts  the _physics_process of every node, per node (all the frame's physics ticks),
##   physics_engine   after them: deferred calls from physics, physics timers and tweens, navigation, the Jolt step,
##                    and the next tick's area and body callbacks,
##   process_scripts  _process and internal processing (Timer nodes: their timeouts' calls), per node,
##   post             after them: deferred calls, the scene change (a new scene's _ready), SceneTree timers (await
##                    create_timer), tweens, freeing and the (dummy) drawing.
## The frame's start (before the first node) is split further: coroutines resumed by process_frame, the deferred calls
## queued before the frame, those queued meanwhile. Container sorts and redraws are noted too (a gap before each is
## given to it: a rough guide). Nodes added in a long frame are listed by the panel they belong to (the ancestor right
## under a CanvasLayer, the HUD or the scene) with the time from the previous panel's last node to this panel's last one
## ("built": roughly what building it cost). The report of a long frame is itself counted in the next frame's start
## ("this tool"). Used by tools/frame_probe_steps.gd. Costs about 1 µs per processing node per frame.

## After each window's breakdown: its length (a probe counts frames on this, so both agree on where a frame ends).
signal window(total_ms: float)

const FIRST := -(1 << 30)
const LAST := 1 << 30

## Frames over this many ms are reported (by the caller) and get their breakdown computed.
var threshold_ms := 50

var _nodes: Array[Node] = []   # process: node k has priority 2k, marker k priority 2k + 1
var _markers: Array[Node] = []
var _pnodes: Array[Node] = []
var _pmarkers: Array[Node] = []
var _assigned := {}   # instance id -> true: has its process priority and marker
var _passigned := {}   # instance id -> true: has its physics priority and marker
var _pending: Array[Node] = []
var _later: Array = []   # [WeakRef] nodes with _process or _physics_process (or Timers) not processing yet
var _recheck_at := 0
var _first: Marker
var _last: Marker
var _pfirst: Marker
var _plast: PhysicsMarker

var _s0 := 0   # this window's process_frame
var _prev_s0 := 0
var _phys_first_s0 := 0   # the window's first physics tick (0 = none yet)
var _ticks := 0
var _phys_scripts := 0
var _phys_costs := {}   # node label -> µs, over this window's ticks
var _phys_last_end := 0   # the last tick's last marker
var _phys_engine := 0
var _timeline: Array = []   # [usec, top key] of nodes added in this window
var _gone: Array = []       # [usec, top key] of nodes that left the tree in this window (freed, mostly)
var _ui_events: Array = []   # [usec, top key + draw/sort] in this window
var _tick_s0 := 0
var _t_late := 0
var _self_end := 0   # the end of this tool's own work (and its caller's report) at the frame's start
var _t_flushed := 0

## The last window's breakdown (filled when it was over threshold_ms): total_ms, physics_scripts_ms,
## physics_engine_ms, process_scripts_ms, post_ms, ticks, top_physics, top_process, built, start, deferred, post.
var last := {}


## Notes when its turn came (its priority places it right after one node). Two classes: a script with both
## _process and _physics_process gets both turned on at ready.
class Marker extends Node:
	var t := 0
	var then := Callable()

	func _process(_d: float) -> void:
		t = Time.get_ticks_usec()
		if then.is_valid():
			then.call()


class PhysicsMarker extends Marker:
	func _ready() -> void:
		set_process(false)

	func _physics_process(_d: float) -> void:
		t = Time.get_ticks_usec()
		if then.is_valid():
			then.call()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_first = _marker(false, FIRST)
	_last = _marker(false, LAST)
	_pfirst = _marker(true, FIRST)
	_plast = _marker(true, LAST) as PhysicsMarker
	_plast.then = _tick_end
	_last.then = _process_end
	get_tree().process_frame.connect(_on_process_frame)
	get_tree().physics_frame.connect(_on_physics_frame)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	_scan(get_tree().root)
	_assign_pending()


func _marker(physics: bool, priority: int) -> Marker:
	var m: Marker = PhysicsMarker.new() if physics else Marker.new()
	m.process_mode = Node.PROCESS_MODE_ALWAYS
	if physics:
		m.process_physics_priority = priority
	else:
		m.process_priority = priority
	add_child(m)
	return m


func _scan(n: Node) -> void:
	_pending.append(n)
	for c in n.get_children(true):
		_scan(c)


func _is_ours(n: Node) -> bool:
	return n == self or n.get_parent() == self


func _on_node_added(n: Node) -> void:
	if _is_ours(n):
		return
	_pending.append(n)
	var key := _top_key(n)
	_timeline.append([Time.get_ticks_usec(), key])
	# Deferred work outside any node's turn (layout, redraws: the message queue) shows up by these signals.
	if n is CanvasItem:
		(n as CanvasItem).draw.connect(_ui.bind(key + " draw"))
	if n is Container:
		(n as Container).sort_children.connect(_ui.bind(key + " sort"))


## A node left the tree (2026-09-30, the frame spikes: a long "post" with nothing built was things freed far behind a
## flyer): noted like the nodes added, by panel ("gone").
func _on_node_removed(n: Node) -> void:
	if _is_ours(n) or not is_inside_tree():   # P5: the tree taken down at the quit (no scene to name a panel by)
		return
	_gone.append([Time.get_ticks_usec(), _top_key(n)])


## The start of a frame, split: process_frame's other listeners (coroutines awaiting it) run until _late (connected
## at the end of the previous processing, so after them); the deferred calls queued before the frame run until
## _flushed (queued by _late, so after them); then the calls queued while flushing, until the first node.
func _process_end() -> void:
	get_tree().process_frame.connect(_late, CONNECT_ONE_SHOT)


func _late() -> void:
	_t_late = Time.get_ticks_usec()
	_flushed.call_deferred()


func _flushed() -> void:
	_t_flushed = Time.get_ticks_usec()


func _ui(key: String) -> void:
	_ui_events.append([Time.get_ticks_usec(), key])


## Gaps between the UI events inside [from_t, to_t], each given to the later event's key; the rest to "(other)".
func _deferred(events: Array, from_t: int, to_t: int) -> Dictionary:
	var out := {}
	var prev := from_t
	for e in events:
		var t: int = e[0]
		if t < from_t or t > to_t:
			continue
		out[e[1]] = int(out.get(e[1], 0)) + (t - prev)
		prev = t
	if to_t - prev > 0:
		out["(other deferred work)"] = to_t - prev
	return out


## The panel a node belongs to: its ancestor right under a CanvasLayer, the HUD, a scene's root or the tree's root.
func _top_key(n: Node) -> String:
	var a := n
	var scene := get_tree().current_scene
	while a.get_parent() != null:
		var p := a.get_parent()
		if p is CanvasLayer or p == scene or p == get_tree().root or p is Hud:
			break
		a = p
	var sc: Script = a.get_script()
	return "%s(%s)" % [a.name, sc.resource_path.get_file() if sc and sc.resource_path != "" else a.get_class()]


func _assign_pending() -> void:
	var now := Time.get_ticks_msec()
	if now >= _recheck_at:
		_recheck_at = now + 1000
		for w in _later:
			var n: Node = (w as WeakRef).get_ref()
			if n != null and n.is_inside_tree():
				_pending.append(n)
		_later = []
	var pending := _pending
	_pending = []
	for n in pending:
		if not is_instance_valid(n) or not n.is_inside_tree() or _is_ours(n):
			continue
		var id := n.get_instance_id()
		var wants := false   # may still start processing later: checked again once a second
		if not _assigned.has(id):
			if n.is_processing() or n.is_processing_internal():
				_assigned[id] = true
				n.process_priority = _nodes.size() * 2
				_nodes.append(n)
				_markers.append(_marker(false, _nodes.size() * 2 - 1))
			else:
				wants = n is Timer or n.has_method("_process")
		if not _passigned.has(id):
			if n.is_physics_processing() or n.is_physics_processing_internal():
				_passigned[id] = true
				n.process_physics_priority = _pnodes.size() * 2
				_pnodes.append(n)
				_pmarkers.append(_marker(true, _pnodes.size() * 2 - 1))
			else:
				wants = wants or n is Timer or n.has_method("_physics_process")
		if wants:
			_later.append(weakref(n))


func _label(v: Variant) -> String:
	if not is_instance_valid(v):
		return "(freed)"
	var n: Node = v
	var sc: Script = n.get_script()
	var what := sc.resource_path.get_file() if sc and sc.resource_path != "" else n.get_class()
	var path := str(n.get_path())
	var parts := path.split("/")
	var short := "/".join(parts.slice(maxi(parts.size() - 3, 0)))
	if n is Timer:
		var calls: Array[String] = []
		for c in (n as Timer).timeout.get_connections():
			var cb: Callable = c.callable
			var o := cb.get_object()
			var osc: Script = o.get_script() if o else null
			calls.append("%s.%s" % [osc.resource_path.get_file() if osc else (o.get_class() if o else "?"), cb.get_method()])
		what += "->" + ",".join(calls)
	return "%s %s" % [what, short]


## Per-node costs between markers: first -> node 0's marker -> node 1's marker ... -> last.
func _costs(nodes: Array[Node], markers: Array[Node], first: Marker, start_t: int, end_t: int) -> Dictionary:
	var out := {}
	var prev := first.t
	if prev - start_t > 200:
		out["(frame start: coroutines, deferred calls, this tool)"] = prev - start_t
	for k in nodes.size():
		var t: int = (markers[k] as Marker).t
		if t >= prev and t > 0:
			var d := t - prev
			if d > 200:
				var key := _label(nodes[k])
				out[key] = int(out.get(key, 0)) + d
			prev = t
	if end_t > prev:
		out["(after the last node)"] = end_t - prev
	return out


func _top(costs: Dictionary, count: int) -> Array[String]:
	var keys := costs.keys()
	keys.sort_custom(func(a, b): return costs[a] > costs[b])
	var out: Array[String] = []
	for k in keys.slice(0, count):
		out.append("%s %.1f ms" % [k, costs[k] / 1000.0])
	return out


func _on_physics_frame() -> void:
	var now := Time.get_ticks_usec()
	if _phys_last_end > 0:
		_phys_engine += now - _phys_last_end
	if _phys_first_s0 == 0:
		_phys_first_s0 = now
	_tick_s0 = now


func _on_process_frame() -> void:
	var now := Time.get_ticks_usec()
	_prev_s0 = _s0
	_s0 = now
	if _phys_last_end > 0 and _phys_first_s0 > 0:
		_phys_engine += now - _phys_last_end
	var total := now - _prev_s0
	last = {}
	if _prev_s0 > 0 and total >= threshold_ms * 1000:
		var proc_end := _last.t
		var post_end := _phys_first_s0 if _phys_first_s0 > 0 else now
		var proc := _costs(_nodes, _markers, _first, _prev_s0, proc_end)
		last = {
			"total_ms": total / 1000.0,
			"process_scripts_ms": (proc_end - _prev_s0) / 1000.0,
			"post_ms": (post_end - proc_end) / 1000.0,
			"physics_scripts_ms": _phys_scripts / 1000.0,
			"physics_engine_ms": _phys_engine / 1000.0,
			"ticks": _ticks,
			"top_process": _top(proc, 6),
			"top_physics": _top(_phys_costs, 6),
			"built": _built(_timeline, _prev_s0, now),
			"gone": _built(_gone, _prev_s0, now),
			"start": [(_self_end - _prev_s0) / 1000.0, (_t_late - _self_end) / 1000.0, (_t_flushed - _t_late) / 1000.0,
				(_first.t - _t_flushed) / 1000.0],
			"deferred": _top(_deferred(_ui_events, _prev_s0, _first.t), 6) if _first.t - _prev_s0 > 2000 else [],
			"post": _top(_deferred(_ui_events, proc_end, post_end), 6) if post_end - proc_end > 2000 else [],
		}
	_timeline = []
	_gone = []
	_ui_events = []
	_phys_first_s0 = 0
	_phys_last_end = 0
	_phys_scripts = 0
	_phys_engine = 0
	_ticks = 0
	_phys_costs = {}
	_assign_pending()
	if _prev_s0 > 0:
		window.emit(total / 1000.0)
	_self_end = Time.get_ticks_usec()


## The end of a physics tick (the last physics marker): adds the tick's costs.
func _tick_end() -> void:
	var now := _plast.t
	_ticks += 1
	var dur := now - _tick_s0
	_phys_scripts += dur
	_phys_last_end = now
	if dur > 2000:
		var c := _costs(_pnodes, _pmarkers, _pfirst, _tick_s0, now)
		for k in c:
			_phys_costs[k] = int(_phys_costs.get(k, 0)) + int(c[k])


func _built(timeline: Array, from_t: int, _to_t: int) -> Array[String]:
	var cost := {}
	var count := {}
	var prev_end := from_t
	var i := 0
	while i < timeline.size():
		var key: String = timeline[i][1]
		var j := i
		while j + 1 < timeline.size() and timeline[j + 1][1] == key:
			j += 1
		var end_t: int = timeline[j][0]
		cost[key] = int(cost.get(key, 0)) + maxi(end_t - prev_end, 0)
		count[key] = int(count.get(key, 0)) + (j - i + 1)
		prev_end = end_t
		i = j + 1
	var keys := cost.keys()
	keys.sort_custom(func(a, b): return cost[a] > cost[b])
	var out: Array[String] = []
	for k in keys.slice(0, 10):
		out.append("%s %.1f ms (%d nodes)" % [k, cost[k] / 1000.0, count[k]])
	return out


## One line for the last window (empty when it was under the threshold).
func describe() -> String:
	if last.is_empty():
		return ""
	var s := "physics %d ticks: scripts %.1f ms, engine %.1f ms; process scripts %.1f ms; post %.1f ms (%d/%d nodes timed)" % [
		last.ticks, last.physics_scripts_ms, last.physics_engine_ms, last.process_scripts_ms, last.post_ms, _nodes.size(),
		_pnodes.size()]
	if not (last.top_physics as Array).is_empty():
		s += "\n    physics: " + "; ".join(last.top_physics)
	if not (last.top_process as Array).is_empty():
		s += "\n    process: " + "; ".join(last.top_process)
	if absf(last.start[1]) + absf(last.start[2]) + absf(last.start[3]) > 2.0:
		s += "\n    before the first node: this tool %.1f ms, coroutines on process_frame %.1f ms, deferred calls queued earlier %.1f ms, deferred calls queued meanwhile %.1f ms" % last.start
	if not (last.deferred as Array).is_empty():
		s += "\n    UI events before the first node: " + "; ".join(last.deferred)
	if not (last.post as Array).is_empty():
		s += "\n    post: " + "; ".join(last.post)
	if not (last.built as Array).is_empty():
		s += "\n    built: " + "; ".join(last.built)
	if not (last.gone as Array).is_empty():
		s += "\n    gone: " + "; ".join(last.gone)
	return s
