class_name CourseRun
extends RefCounted
## One runner's run on a course (M3 Task 7), kept by the host: armed on START (the clock shows 0.0), running
## once they step off it, where a fall brings them back (START, then the last checkpoint), the coins they
## touched (once each) and their way, recorded at 10 Hz for the course's best run. Times are the host's
## milliseconds.

var start := Vector3i.ZERO
var armed := false
var running := false
var t0 := 0
var spot := Vector3.ZERO
var checkpoint_cell := Vector3i.ZERO
var coins := 0
var path := RecordedRun.new()
var _coins := {}


## Stepped on START (again): a new run, its clock at 0.0 until they step off.
func arm(start_cell: Vector3i, now_ms: int) -> void:
	start = start_cell
	armed = true
	running = false
	t0 = now_ms
	spot = CourseRules.top_of(start_cell)
	checkpoint_cell = start_cell
	coins = 0
	_coins.clear()
	path = RecordedRun.new(spot)


## Stepped off START: the clock runs from now.
func go(now_ms: int) -> void:
	if not armed:
		return
	armed = false
	running = true
	t0 = now_ms
	path = RecordedRun.new(spot)


func is_on() -> bool:
	return armed or running


## Milliseconds on the clock (0 while armed).
func elapsed(now_ms: int) -> int:
	return maxi(now_ms - t0, 0) if running else 0


## A checkpoint touched: a fall comes back here. False when it was the last one already.
func checkpoint(cell: Vector3i) -> bool:
	if not is_on() or cell == checkpoint_cell:
		return false
	checkpoint_cell = cell
	spot = CourseRules.top_of(cell)
	return true


## A coin touched: true the first time in this run.
func coin(cell: Vector3i) -> bool:
	if not is_on() or _coins.has(cell):
		return false
	_coins[cell] = true
	coins += 1
	return true


## FINISH touched: the run's time in ms, or -1 when it never started (or finished already).
func finish(now_ms: int) -> int:
	if not running:
		return -1
	running = false
	armed = false
	return maxi(now_ms - t0, 0)


## The host's 10 Hz sample of where the runner is (while the clock runs).
func record(pos: Vector3) -> void:
	if running:
		path.add(pos)
