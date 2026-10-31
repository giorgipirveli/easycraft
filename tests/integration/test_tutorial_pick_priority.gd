extends GutTest
## M5 Task 3 (the lead's emulator run, 19:35): the first search for Pip's playground took 20.1 s on the emulator while
## the new world streamed in (217 ms when replayed), so "Hi! I'm Pip!" came 20 s late. A phone with 4 cores has one
## low-priority worker slot, shared with resource loading and the other worlds' searches (quest givers, Tilly's cart):
## a low-priority search waits behind them. The search and the plan are high-priority tasks now: busy low-priority
## slots never hold them up.

const SITE := {"origin": Vector3i(10, 40, 10), "dir": 0}
const BLOCKERS := 64               # more than any machine's low-priority slots

var _gate := Semaphore.new()
var _blockers: Array[int] = []


func after_each() -> void:
	_release()


## Fills every low-priority slot of the pool with tasks that wait until released.
func _block_low_priority() -> void:
	for i in BLOCKERS:
		_blockers.append(WorkerThreadPool.add_task(func() -> void: _gate.wait(), false, "test blocker"))


func _release() -> void:
	for i in _blockers.size():
		_gate.post()
	for t in _blockers:
		WorkerThreadPool.wait_for_task_completion(t)
	_blockers.clear()


func test_the_playground_search_is_not_held_up_by_busy_low_priority_workers() -> void:
	var d := TutorialDirector.new()
	d.auto_tick = false
	d.threaded = true
	d.here = false
	d.profile = ProfileData.new()
	d.pick_site = func() -> Dictionary: return SITE
	add_child_autofree(d)
	_block_low_priority()
	d._pick()
	var deadline := Time.get_ticks_msec() + 3000
	while d.site.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		d.tick(0.1)
	var found := d.site
	_release()   # before any assert: a failing run must never leave the pool blocked
	assert_eq(found, SITE, "found while every low-priority worker slot was busy")
