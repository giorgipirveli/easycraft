extends GutTest
## M3 Task 7 (spec §14.4): teleport pads link in pairs. A new pad links with the nearest pad that has no
## partner yet; a broken pad's partner links again with the nearest free one. The pairs are saved with the
## world and checked when loaded (broken entries are dropped, one-sided pairs forgotten, free pads pair up).

const A := Vector3i(0, 10, 0)
const B := Vector3i(40, 10, 0)
const C := Vector3i(8, 10, 0)
const D := Vector3i(100, 12, 5)


func test_a_lone_pad_waits_and_the_next_one_links_with_it() -> void:
	var l := TeleportLinks.new()
	assert_true(l.add(A))
	assert_eq(l.partner_of(A), null, "a pad alone waits")
	assert_true(l.add(B))
	assert_eq(l.partner_of(A), B)
	assert_eq(l.partner_of(B), A)
	assert_false(l.add(A), "known already")


func test_a_new_pad_links_with_the_nearest_free_pad() -> void:
	var l := TeleportLinks.new()
	l.add(A)
	l.add(B)          # A-B
	l.add(D)          # waits
	l.add(C)          # nearest free pad is D (A and B are taken)
	assert_eq(l.partner_of(C), D)
	var m := TeleportLinks.new()
	m.add(D)
	m.add(A)          # D-A
	m.add(B)          # waits
	m.add(C)          # free: B only
	assert_eq(m.partner_of(C), B)
	var n := TeleportLinks.new()
	n.add(B)
	n.add(D)          # B-D
	n.remove(B)       # D waits
	n.add(A)          # D-A
	n.add(C)
	n.add(B)          # C and B are free: the nearest to B... C is at 32, it links with C
	assert_eq(n.partner_of(B), C)


func test_the_two_nearest_free_pads_pair_when_two_wait() -> void:
	var l := TeleportLinks.new()
	l.add(A)
	l.add(D)          # A-D
	l.add(B)          # waits
	l.remove(A)       # D is free again: D and B are the only free pads
	assert_eq(l.partner_of(D), B, "the free ones pair up")
	assert_false(l.has(A))


func test_a_broken_pads_partner_links_with_the_nearest_free_pad() -> void:
	var l := TeleportLinks.new()
	l.add(A)
	l.add(B)          # A-B
	l.add(D)          # waits
	l.add(C)          # C-D
	l.remove(B)
	assert_eq(l.partner_of(A), null, "no free pad left: A waits")
	l.remove(D)
	assert_eq(l.partner_of(A), C, "C came free: the two free pads pair")
	assert_eq(l.partner_of(C), A)


func test_at_most_max_pads() -> void:
	var l := TeleportLinks.new()
	for i in TeleportLinks.MAX:
		assert_true(l.add(Vector3i(i * 3, 10, 0)))
	assert_false(l.add(Vector3i(0, 50, 0)), "a world keeps at most MAX pads")
	assert_eq(l.pads().size(), TeleportLinks.MAX)


func test_pairs_are_saved_and_loaded() -> void:
	var l := TeleportLinks.new()
	l.add(A)
	l.add(B)
	l.add(D)
	var saved := l.to_save()
	var json: Variant = JSON.parse_string(JSON.stringify(saved))
	var back := TeleportLinks.from_save(json)
	assert_eq(back.partner_of(A), B)
	assert_eq(back.partner_of(B), A)
	assert_true(back.has(D))
	assert_eq(back.partner_of(D), null)


func test_loading_never_fails_and_drops_what_is_broken() -> void:
	for bad: Variant in [null, 3, "x", {}, [[1, 2]], [["a", 1, 2]], [[1.5, INF, 2]]]:
		assert_eq(TeleportLinks.from_save(bad).pads().size(), 0, str(bad))
	var one_sided := [[0, 10, 0, 40, 10, 0], [40, 10, 0, 8, 10, 0], [8, 10, 0]]
	var l := TeleportLinks.from_save(one_sided)
	assert_eq(l.pads().size(), 3)
	for p in l.pads():
		var other: Variant = l.partner_of(p)
		if other != null:
			assert_eq(l.partner_of(other), p, "pairs are mutual")
	var repeats := [[0, 10, 0], [0, 10, 0], [40, 10, 0]]
	var r := TeleportLinks.from_save(repeats)
	assert_eq(r.pads().size(), 2, "a pad counted once")
	assert_eq(r.partner_of(A), B, "free pads pair up when loaded")
	var many := []
	for i in TeleportLinks.MAX + 10:
		many.append([i * 2, 10, 0])
	assert_eq(TeleportLinks.from_save(many).pads().size(), TeleportLinks.MAX)


## Several free pads (a save from before its pairs were written): each pairs with the nearest free one.
func test_free_pads_in_a_save_pair_nearest_first() -> void:
	var l := TeleportLinks.from_save([[0, 10, 0], [40, 10, 0], [8, 10, 0], [44, 10, 0]])
	assert_eq(l.partner_of(A), C, "A's nearest free pad is C, not B (placed before it)")
	assert_eq(l.partner_of(B), Vector3i(44, 10, 0))
