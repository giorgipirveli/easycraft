extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §4.4 "VR", ruling 23; Cook, Mitchell & Goldin-Meadow's two-hand
## gesture [C7]): in VR the twin move is two hands, one a pan: which pan a hand is over, how many a scoop takes, both
## hands' lifts as one twin, a held gem let go over its own pan (back) or over the other (carried across: refused), and
## one-handed play (a trigger on a gem lifts it, a trigger on its twin completes it).

const PANS: Array[Vector3] = [Vector3(-0.35, 0.78, 0), Vector3(0.35, 0.78, 0)]


func test_the_pan_under_a_hand() -> void:
	assert_eq(AltarTwinRules.pan_under(Vector3(-0.33, 0.86, 0.04), PANS), 0)
	assert_eq(AltarTwinRules.pan_under(Vector3(0.38, 0.82, -0.05), PANS), 1)
	assert_eq(AltarTwinRules.pan_under(Vector3(0, 0.86, 0), PANS), -1, "over the fulcrum: neither")
	assert_eq(AltarTwinRules.pan_under(Vector3(-0.35, 1.3, 0), PANS), -1, "too high above it")
	assert_eq(AltarTwinRules.pan_under(Vector3(-0.35, 0.6, 0), PANS), -1, "under the pan")


func test_a_scoop_takes_the_things_under_the_open_hand() -> void:
	var gems: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0.06, 0, 0), Vector3(0.12, 0, 0), Vector3(0.3, 0, 0)]
	assert_eq(AltarTwinRules.scoop(Vector3(0.06, 0.04, 0), gems), 3)
	assert_eq(AltarTwinRules.scoop(Vector3(0.3, 0.03, 0), gems), 1)
	assert_eq(AltarTwinRules.scoop(Vector3(1.0, 0, 0), gems), 0)


func test_two_hands_two_pans_one_twin() -> void:
	var left := {"pan": 0, "kind": AltarState.GEM, "n": 1, "t": 2.0}
	var right := {"pan": 1, "kind": AltarState.GEM, "n": 1, "t": 2.4}
	assert_eq(AltarMoves.name_of(AltarTwinRules.pair(left, right)), "take gem 1", "both lift together: one twin move")
	var handfuls := {"pan": 1, "kind": AltarState.GEM, "n": 3, "t": 2.2}
	assert_eq(AltarTwinRules.pair({"pan": 0, "kind": AltarState.GEM, "n": 3, "t": 2.0}, handfuls).n, 3, "two scoops")
	assert_eq(AltarTwinRules.pair(left, {"pan": 0, "kind": AltarState.GEM, "n": 1, "t": 2.1}), {}, "one pan twice")
	assert_eq(AltarTwinRules.pair(left, {"pan": 1, "kind": AltarState.CRYSTAL, "n": 1, "t": 2.1}), {}, "another kind")
	assert_eq(AltarTwinRules.pair(left, {"pan": 1, "kind": AltarState.GEM, "n": 2, "t": 2.1}), {}, "not the same number")
	assert_eq(AltarTwinRules.pair(left, {"pan": 1, "kind": AltarState.GEM, "n": 1, "t": 9.0}), {},
		"too far apart in time: the first lift waits alone, as with one hand")


func test_a_held_thing_let_go() -> void:
	assert_eq(AltarTwinRules.release(PANS[0] + Vector3(0, 0.1, 0), PANS, 0), AltarTwinRules.BACK, "over its own pan")
	assert_eq(AltarTwinRules.release(PANS[1] + Vector3(0, 0.1, 0), PANS, 0), AltarTwinRules.ACROSS,
		"over the other pan: carried across, refused")
	assert_eq(AltarTwinRules.release(Vector3(0, 1.5, 0.4), PANS, 1), AltarTwinRules.BACK, "anywhere else: back")


func test_one_handed_play_is_the_altar_s_own_waiting_batch() -> void:
	var m := AltarMoves.start(AltarState.make(1, 2, 0, 6, 4), ["bowls", "gem_bag"] as Array[String])
	for t: Dictionary in [{"pan": 0, "kind": AltarState.GEM}, {"pan": 1, "kind": AltarState.GEM},
			{"pan": 0, "kind": AltarState.GEM}, {"pan": 1, "kind": AltarState.GEM}]:
		AltarTwinRules.trigger(m, int(t.pan), str(t.kind))
	assert_true(m.freed(), "a trigger on a gem lifts it, a trigger on its twin completes it")
	assert_eq(m.ops, 1)
