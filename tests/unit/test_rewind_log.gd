extends GutTest
## M3 Task 8 (spec §14.5, §3a): Build Rewind's record. REWIND tapped on a spot starts recording this player's
## edits within 32 blocks of it (a cube), up to 5,000 edits, in order; the replay rebuilds them as a time-lapse of
## at most 20 s. Kept in memory and saved with the world in a compact form (7 bytes an edit: block ids go past 255;
## deflated, base64; a recording saved with 5 bytes an edit still loads); anything broken in a save is dropped, never
## trusted.


func _log(center := Vector3i(100, 20, -50)) -> RewindLog:
	var r := RewindLog.new()
	r.start(center)
	return r


func test_nothing_is_recorded_before_it_starts() -> void:
	var r := RewindLog.new()
	assert_false(r.active)
	assert_false(r.record(Vector3i.ZERO, BlockIds.AIR, BlockIds.STONE))
	assert_eq(r.size(), 0)


func test_it_records_edits_in_order() -> void:
	var r := _log()
	assert_true(r.record(Vector3i(101, 20, -50), BlockIds.AIR, BlockIds.BRICK))
	assert_true(r.record(Vector3i(101, 21, -50), BlockIds.AIR, BlockIds.GLASS))
	assert_true(r.record(Vector3i(101, 20, -50), BlockIds.BRICK, BlockIds.AIR))
	assert_eq(r.size(), 3)
	assert_eq(r.edit(0), {"pos": Vector3i(101, 20, -50), "old": BlockIds.AIR, "new": BlockIds.BRICK})
	assert_eq(r.edit(2), {"pos": Vector3i(101, 20, -50), "old": BlockIds.BRICK, "new": BlockIds.AIR})
	assert_false(r.record(Vector3i(101, 22, -50), BlockIds.STONE, BlockIds.STONE), "no change, nothing to show")


## Within 32 blocks of the spot on every axis; further edits are not this build's.
func test_only_edits_within_32_blocks() -> void:
	var r := _log(Vector3i(0, 50, 0))
	assert_true(r.record(Vector3i(32, 18, -32), BlockIds.AIR, BlockIds.STONE), "the far corner")
	assert_false(r.record(Vector3i(33, 50, 0), BlockIds.AIR, BlockIds.STONE))
	assert_false(r.record(Vector3i(0, 17, 0), BlockIds.AIR, BlockIds.STONE))
	assert_false(r.record(Vector3i(0, 50, -33), BlockIds.AIR, BlockIds.STONE))
	assert_eq(r.size(), 1)
	assert_eq(RewindLog.RADIUS, 32)


func test_at_most_5000_edits() -> void:
	var r := _log(Vector3i.ZERO)
	var kept := 0
	for i in RewindLog.MAX_EDITS:
		if r.record(Vector3i(i % 20, (i / 20) % 20, i / 400), BlockIds.AIR, BlockIds.STONE):
			kept += 1
	assert_eq(kept, 5000)
	assert_eq(r.size(), 5000)
	assert_true(r.is_full())
	assert_false(r.record(Vector3i(1, 1, 1), BlockIds.STONE, BlockIds.AIR), "full: the 5,001st is not kept")
	assert_eq(r.size(), 5000)
	assert_eq(RewindLog.MAX_EDITS, 5000)


func test_starting_again_forgets_the_old_build() -> void:
	var r := _log()
	r.record(Vector3i(100, 20, -50), BlockIds.AIR, BlockIds.STONE)
	r.start(Vector3i(0, 0, 0))
	assert_eq(r.size(), 0)
	assert_eq(r.center, Vector3i.ZERO)


## The replay starts from what each cell held before its first edit and applies the edits in order.
func test_the_replay_rebuilds_in_order() -> void:
	var r := _log(Vector3i.ZERO)
	r.record(Vector3i(0, 0, 0), BlockIds.GRASS, BlockIds.AIR)      # dig
	r.record(Vector3i(0, 0, 0), BlockIds.AIR, BlockIds.BRICK)      # fill it with brick
	r.record(Vector3i(0, 1, 0), BlockIds.AIR, BlockIds.GLASS)
	r.record(Vector3i(0, 1, 0), BlockIds.GLASS, BlockIds.PAINTED_RED)   # painted
	assert_eq(r.blocks_after(0), {Vector3i(0, 0, 0): BlockIds.GRASS}, "the start: grass, and air above")
	assert_eq(r.blocks_after(1), {})
	assert_eq(r.blocks_after(2), {Vector3i(0, 0, 0): BlockIds.BRICK})
	assert_eq(r.blocks_after(4), {Vector3i(0, 0, 0): BlockIds.BRICK, Vector3i(0, 1, 0): BlockIds.PAINTED_RED})
	assert_eq(r.blocks_after(99), r.blocks_after(4))


## At most 20 s whatever the size, a quarter second an edit for small builds; the edits shown by time t.
func test_the_time_lapse_lasts_at_most_20_seconds() -> void:
	var small := _log(Vector3i.ZERO)
	for i in 8:
		small.record(Vector3i(i, 0, 0), BlockIds.AIR, BlockIds.STONE)
	assert_almost_eq(small.step_seconds(), 0.25, 0.001)
	assert_almost_eq(small.duration(), 2.0, 0.001)
	assert_eq(small.shown_at(0.0), 0)
	assert_eq(small.shown_at(0.26), 1)
	assert_eq(small.shown_at(1.0), 4)
	assert_eq(small.shown_at(100.0), 8)
	var big := _log(Vector3i.ZERO)
	for i in 5000:
		big.record(Vector3i(i % 20, (i / 20) % 20, i / 400), BlockIds.AIR, BlockIds.STONE)
	assert_lte(big.duration(), RewindLog.MAX_SECONDS + 0.001)
	assert_eq(big.shown_at(RewindLog.MAX_SECONDS), 5000)
	assert_eq(big.shown_at(10.0), 2500)


func test_saved_in_a_compact_form_and_loaded_again() -> void:
	var r := _log(Vector3i(-7, 33, 12))
	for i in 3000:
		r.record(Vector3i(-7 + i % 30 - 15, 33 + (i / 30) % 30 - 15, 12 + i / 900), BlockIds.AIR, [BlockIds.BRICK, BlockIds.PAINTED_BLUE][i % 2])
	var saved := r.to_save()
	var text := JSON.stringify(saved)
	assert_lt(text.length(), 3000 * 5, "smaller than 5 bytes an edit")
	var back := RewindLog.from_save(JSON.parse_string(text))
	assert_true(back.active)
	assert_eq(back.center, r.center)
	assert_eq(back.size(), 3000)
	for i in [0, 1, 1499, 2999]:
		assert_eq(back.edit(i), r.edit(i), str(i))
	assert_eq(RewindLog.from_save(RewindLog.new().to_save()).active, false, "none recorded: none saved")


func test_a_broken_save_is_dropped() -> void:
	for bad: Variant in [null, 5, "x", {}, {"c": [1, 2]}, {"c": [0, 0, 0], "n": 3, "e": "!!!"},
			{"c": [0, 0, 0], "n": 9999, "e": ""}, {"c": [0, 0, 0], "n": -1, "e": ""},
			{"c": ["a", 0, 0], "n": 0, "e": ""}, {"c": [1e12, 0, 0], "n": 0, "e": ""}]:
		var r := RewindLog.from_save(bad)
		assert_eq(r.size(), 0, str(bad))
	# edits whose bytes don't match their count are dropped
	var good := _log(Vector3i.ZERO)
	good.record(Vector3i(1, 1, 1), BlockIds.AIR, BlockIds.STONE)
	var d := good.to_save()
	d.n = 2
	assert_eq(RewindLog.from_save(d).size(), 0)
	# an id no block owns (239: the Dragon Realm's page's free one; 223 became the Glow Portal Core) is shown as air,
	# never as something strange
	assert_false(BlockIds.is_valid(239))
	var bytes := PackedByteArray([33, 33, 33, BlockIds.AIR, 239, 33, 34, 33, BlockIds.AIR, BlockIds.STONE])
	var raw := {"c": [0, 0, 0], "n": 2, "e": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_DEFLATE))}
	var loaded := RewindLog.from_save(raw)
	assert_eq(loaded.size(), 2)
	assert_eq(loaded.edit(0), {"pos": Vector3i(1, 1, 1), "old": BlockIds.AIR, "new": BlockIds.AIR})
	assert_eq(loaded.edit(1), {"pos": Vector3i(1, 2, 1), "old": BlockIds.AIR, "new": BlockIds.STONE})


## Owner #45b's wild meadows (page 13) and later pages are ids 256-399: a child building with birch or mud sees them in
## the time-lapse too, before and after a save.
func test_blocks_past_255_are_recorded_saved_and_replayed() -> void:
	var r := _log(Vector3i.ZERO)
	assert_true(r.record(Vector3i(1, 0, 0), BlockIds.AIR, BlockIds.BIRCH_LOG))
	assert_true(r.record(Vector3i(2, 0, 0), BlockIds.GRASS, BlockIds.GLOW_MUSHROOM))
	assert_true(r.record(Vector3i(1, 0, 0), BlockIds.BIRCH_LOG, BlockIds.PAINTED_PINK))
	assert_eq(r.edit(0), {"pos": Vector3i(1, 0, 0), "old": BlockIds.AIR, "new": BlockIds.BIRCH_LOG})
	assert_eq(r.edit(1), {"pos": Vector3i(2, 0, 0), "old": BlockIds.GRASS, "new": BlockIds.GLOW_MUSHROOM})
	assert_eq(r.blocks_after(1), {Vector3i(1, 0, 0): BlockIds.BIRCH_LOG, Vector3i(2, 0, 0): BlockIds.GRASS})
	var back := RewindLog.from_save(JSON.parse_string(JSON.stringify(r.to_save())))
	assert_eq(back.size(), 3)
	for i in 3:
		assert_eq(back.edit(i), r.edit(i), str(i))
	assert_false(r.record(Vector3i(3, 0, 0), BlockIds.AIR, BlockIds.COUNT), "an id past the last block is not a block")


## A world saved before the wider ids (5 bytes an edit, no version) keeps its recording.
func test_a_recording_saved_with_five_bytes_an_edit_still_loads() -> void:
	var bytes := PackedByteArray([33, 32, 32, BlockIds.AIR, BlockIds.STONE, 32, 32, 34, BlockIds.DIRT, BlockIds.PAINTED_BLUE])
	var old := {"c": [5, 6, 7], "n": 2, "e": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_DEFLATE))}
	var r := RewindLog.from_save(old)
	assert_eq(r.size(), 2)
	assert_eq(r.edit(0), {"pos": Vector3i(6, 6, 7), "old": BlockIds.AIR, "new": BlockIds.STONE})
	assert_eq(r.edit(1), {"pos": Vector3i(5, 6, 9), "old": BlockIds.DIRT, "new": BlockIds.PAINTED_BLUE})
	assert_true(r.record(Vector3i(5, 6, 8), BlockIds.AIR, BlockIds.MUD), "and it goes on recording, wide ids too")
	assert_eq(RewindLog.from_save(r.to_save()).edit(2).new, BlockIds.MUD)
