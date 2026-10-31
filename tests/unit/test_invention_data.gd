extends GutTest
## The inventions' part of the profile (owner #78, spec §21e; ProfileData.inventions): what this child invented, in the
## order made, the "try it" moments already paid, and the flying machine picked in Survivor. Account-wide; a broken save
## gives what it can; the server backup's merge never loses an invention or a paid "try it".


func test_it_keeps_what_was_invented_in_order_once() -> void:
	var d := InventionData.new()
	assert_true(d.is_empty())
	assert_true(d.add(InventionLine.KITE))
	assert_false(d.add(InventionLine.KITE), "once")
	assert_false(d.add(&"time_machine"), "only the line's inventions")
	assert_true(d.add(InventionLine.BALLOON))
	assert_true(d.has(InventionLine.KITE))
	assert_false(d.has(InventionLine.JET))
	assert_eq(d.invented, [InventionLine.KITE, InventionLine.BALLOON] as Array[StringName])
	assert_true(d.mark_tried(InventionLine.KITE))
	assert_false(d.mark_tried(InventionLine.KITE), "a try-it pays once")
	assert_true(d.was_tried(InventionLine.KITE))


func test_the_save_keeps_it_and_refuses_junk() -> void:
	var d := InventionData.new()
	d.add(InventionLine.KITE)
	d.add(InventionLine.BALLOON)
	d.mark_tried(InventionLine.BALLOON)
	d.craft = InventionLine.BALLOON
	var back := InventionData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(back.to_dict(), d.to_dict())
	for junk: Variant in [null, 5, "x", [], {"invented": "kite"}, {"invented": [3, "warp_drive"]}, {"craft": 7}]:
		var j := InventionData.from_dict(junk)
		assert_true(j.invented.is_empty(), "junk: %s" % str(junk))
		assert_eq(j.craft, &"")
	assert_eq(InventionData.from_dict({"craft": "jet"}).craft, &"", "a machine not invented is never picked")
	var p := ProfileData.new()
	p.inventions.add(InventionLine.KITE)
	assert_true(ProfileData.from_json(p.to_json()).inventions.has(InventionLine.KITE), "the profile keeps it")


func test_the_backup_s_merge_never_loses_one() -> void:
	var a := InventionData.new()
	a.add(InventionLine.KITE)
	var b := InventionData.new()
	b.add(InventionLine.KITE)
	b.add(InventionLine.BALLOON)
	b.mark_tried(InventionLine.KITE)
	a.merge_from(b)
	assert_true(a.has(InventionLine.BALLOON))
	assert_true(a.was_tried(InventionLine.KITE))
	var local := ProfileData.new()
	local.inventions.add(InventionLine.KITE)
	var server := ProfileData.new()
	server.inventions.add(InventionLine.KITE)
	server.inventions.add(InventionLine.BALLOON)
	local.survivor_gold = 7   # not a new profile: the merge keeps the best of both
	var merged: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(server)).profile
	assert_true(merged.inventions.has(InventionLine.BALLOON), "the server's copy's invention stays")
	var fresh := ProfileData.new()
	fresh.inventions.add(InventionLine.KITE)
	assert_false(ProfileBackup.is_new(fresh), "an invention is progress")
