class_name ChunkDiffer
extends RefCounted
## The host's comparison of a chunk with the generator, on worker threads (M4 Wave 2 A2, spec
## §17.0). A guest generates its terrain from the seed, so for a chunk the edit log does not know
## (edited in the save, or forgotten) the host copies its blocks and generates the chunk again to
## find the cells that differ. That costs 6-9 ms a chunk on the desktop (3-5x on a phone), and the
## copy alone waited up to 200 ms on the voxel threads while the world around was still streaming:
## both run in WorkerThreadPool tasks here, at most MAX_JOBS at once.
## The main thread starts a job, tells it every change to its chunk meanwhile (changed), and takes
## the finished ones (done): the result has those changes replayed over it, against the generated
## block of each cell, so it is right whether the copy saw a change or not.

const MAX_JOBS := 2
const CH := VoxelBuffer.CHANNEL_TYPE


class Job:
	extends RefCounted
	var chunk: Vector3i
	var task := -1
	var cells := {}                  # the worker's diff: cell -> EditLog entry
	var generated := PackedByteArray()   # the generated chunk's ids (16-bit little-endian)
	var changes: Array = []          # [pos, id] made on the main thread while it ran, in order
	var usec := 0


var _generator: VoxelGenerator
var _copy: Callable
var _jobs := {}   # chunk -> Job


## copy(origin: Vector3i, into: VoxelBuffer) reads the host's blocks of the chunk at origin into a
## 16³ buffer; it runs on a worker thread (a VoxelTool's copy locks the voxel data itself).
func _init(generator: VoxelGenerator, copy: Callable) -> void:
	_generator = generator
	_copy = copy


func size() -> int:
	return _jobs.size()


## The chunks being compared.
func chunks() -> Array:
	return _jobs.keys()


func busy(chunk: Vector3i) -> bool:
	return _jobs.has(chunk)


func can_start() -> bool:
	return _jobs.size() < MAX_JOBS


## Starts comparing a chunk; false when it runs already or every worker slot is taken.
func start(chunk: Vector3i) -> bool:
	if _jobs.has(chunk) or not can_start():
		return false
	var job := Job.new()
	job.chunk = chunk
	job.task = WorkerThreadPool.add_task(_run.bind(job), false, "EasyCraft chunk diff")
	_jobs[chunk] = job
	return true


## A block changed on the host (main thread): a job of its chunk replays it over its result.
func changed(pos: Vector3i, id: int) -> void:
	var job: Job = _jobs.get(EditLog.chunk_of(pos))
	if job != null:
		job.changes.append([pos, id])


## The finished jobs: {"chunk", "cells" (cell -> EditLog entry, the changes replayed), "ms" (worker)}.
func done() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for chunk: Vector3i in _jobs.keys():
		var job: Job = _jobs[chunk]
		if not WorkerThreadPool.is_task_completed(job.task):
			continue
		WorkerThreadPool.wait_for_task_completion(job.task)   # (returns at once; frees the task)
		_jobs.erase(chunk)
		out.append({"chunk": chunk, "cells": _replayed(job), "ms": job.usec / 1000.0})
	return out


## Waits for every job and drops the results (the world is going away).
func wait_all() -> void:
	for job: Job in _jobs.values():
		WorkerThreadPool.wait_for_task_completion(job.task)
	_jobs.clear()


# Worker thread: only the job's own fields are written.
func _run(job: Job) -> void:
	var t0 := Time.get_ticks_usec()
	var origin := job.chunk * EditLog.CHUNK
	var current := VoxelBuffer.new()
	current.create(EditLog.CHUNK, EditLog.CHUNK, EditLog.CHUNK)
	_copy.call(origin, current)
	var generated := VoxelBuffer.new()
	generated.create(EditLog.CHUNK, EditLog.CHUNK, EditLog.CHUNK)
	_generator.generate_block(generated, origin, 0)
	job.generated = EditLog.bytes_of(generated)
	job.cells = EditLog.diff_bytes(EditLog.bytes_of(current), job.generated)
	job.usec = Time.get_ticks_usec() - t0


static func _replayed(job: Job) -> Dictionary:
	var cells := job.cells
	for c: Array in job.changes:
		var cell := EditLog.cell_of(c[0])
		var generated := job.generated.decode_u16(cell * 2)
		if int(c[1]) == generated:
			cells.erase(cell)
		else:
			cells[cell] = EditLog.entry(c[1], generated)
	return cells
