extends GutTest
## M3 Task 7: a recorded run is where a runner was, 10 times a second (positions only), at most 3 minutes.
## A bot friend replays the best one as its "own" run (M4's ghost races can reuse it). Saved compact: 16-bit
## decimetres from the START, base64; checked when loaded.

const ORIGIN := Vector3(0.5, 11.0, 0.5)


func _line(n: int) -> RecordedRun:
	var r := RecordedRun.new(ORIGIN)
	for i in n:
		r.add(ORIGIN + Vector3(i * 0.6, 0.0, 0.0))
	return r


func test_it_keeps_ten_samples_a_second() -> void:
	assert_eq(RecordedRun.DT, 0.1)
	var r := _line(11)
	assert_eq(r.size(), 11)
	assert_almost_eq(r.duration(), 1.0, 0.0001)


func test_it_stops_at_three_minutes() -> void:
	var r := RecordedRun.new(ORIGIN)
	var added := 0
	for i in 2000:
		if r.add(ORIGIN + Vector3(i * 0.01, 0, 0)):
			added += 1
	assert_eq(RecordedRun.MAX_SAMPLES, 1800, "3 minutes at 10 Hz")
	assert_eq(added, RecordedRun.MAX_SAMPLES)
	assert_eq(r.size(), RecordedRun.MAX_SAMPLES)
	assert_true(r.full, "a longer run is not kept whole")
	var text := JSON.stringify(r.to_save())
	assert_lt(text.length(), 15000, "3 minutes fit in about 14 KB")


func test_replay_goes_between_the_samples() -> void:
	var r := _line(3)
	assert_eq(r.sample_at(0.0), ORIGIN)
	assert_almost_eq(r.sample_at(0.05), ORIGIN + Vector3(0.3, 0, 0), Vector3.ONE * 0.001)
	assert_almost_eq(r.sample_at(0.2), ORIGIN + Vector3(1.2, 0, 0), Vector3.ONE * 0.001)
	assert_eq(r.sample_at(5.0), r.sample_at(r.duration()), "after the end: the last place")
	assert_eq(r.sample_at(-1.0), ORIGIN)
	assert_almost_eq(r.facing_at(0.1), Vector3(1, 0, 0), Vector3.ONE * 0.001, "facing the way it goes")
	assert_eq(RecordedRun.new(ORIGIN).sample_at(1.0), ORIGIN, "an empty run stays at its start")


func test_save_and_load_round_trip() -> void:
	var r := RecordedRun.new(ORIGIN)
	for i in 40:
		r.add(ORIGIN + Vector3(i * 0.37, sin(i * 0.3) * 2.0, -i * 0.21))
	var back := RecordedRun.from_save(JSON.parse_string(JSON.stringify(r.to_save())))
	assert_not_null(back)
	assert_eq(back.size(), 40)
	assert_eq(back.origin, ORIGIN)
	for t in [0.0, 1.05, 2.2, 3.9]:
		assert_almost_eq(back.sample_at(t), r.sample_at(t), Vector3.ONE * 0.06, "within 5 cm at %s s" % t)


func test_loading_checks_everything() -> void:
	var good := _line(5).to_save()
	for bad: Variant in [null, 5, "p", [], {}, {"o": [0, 0], "p": good.p}, {"o": [0, INF, 0], "p": good.p},
			{"o": [0, 0, 0]}, {"o": [0, 0, 0], "p": 7}, {"o": [0, 0, 0], "p": "not base64 !"},
			{"o": [0, 0, 0], "p": Marshalls.raw_to_base64(PackedByteArray([1, 2, 3, 4, 5]))},
			{"o": [0, 0, 0], "p": Marshalls.raw_to_base64(PackedByteArray([1, 2, 3, 4, 5, 6]))}]:
		assert_null(RecordedRun.from_save(bad), "refused: %s" % str(bad))
	var too_long := PackedByteArray()
	too_long.resize((RecordedRun.MAX_SAMPLES + 1) * 6)
	assert_null(RecordedRun.from_save({"o": [0, 0, 0], "p": Marshalls.raw_to_base64(too_long)}), "over 3 minutes")
	assert_not_null(RecordedRun.from_save(good))


func test_far_away_samples_are_clamped_not_wrapped() -> void:
	var r := RecordedRun.new(ORIGIN)
	r.add(ORIGIN)
	r.add(ORIGIN + Vector3(5000, 0, 0))
	var back := RecordedRun.from_save(r.to_save())
	assert_gt(back.sample_at(0.1).x, 3000.0, "clamped at the edge, never wrapped round to the other side")
