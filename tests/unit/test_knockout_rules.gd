extends GutTest
## Knock-outs and pickup bags as pure rules (M2 Task 2, spec §12.3, §12.15).


func _kit() -> Inventory:
	var inv := Inventory.new()
	inv.add(ItemIds.SWORD, 1)
	inv.add(BlockIds.PLANKS, 16)
	inv.add(ItemIds.PICKAXE, 1)
	inv.add(BlockIds.DIRT, 8)
	inv.add(BlockIds.CRYSTAL, 3)
	inv.add(ItemIds.BOW, 1)
	return inv


func test_health_protection_can_be_held_but_never_shortened() -> void:
	var h := Health.new()
	h.protect(2.0)
	assert_true(h.is_protected())
	assert_false(h.damage(5))
	h.protect(0.5)
	h.tick(1.9)
	assert_true(h.is_protected(), "a shorter hold never cuts it")
	h.tick(0.2)
	assert_false(h.is_protected())
	h.protect(NAN)
	assert_false(h.is_protected(), "a broken hold is no hold")
	h.damage(5)
	assert_eq(h.hp, Health.MAX_HP - 5, "hurts again")


func test_survivor_respawns_at_home_and_sandbox_pops_up_keeping_everything() -> void:
	assert_true(KnockoutRules.respawns_at_home(ModeRules.SURVIVOR))
	assert_false(KnockoutRules.respawns_at_home(ModeRules.SANDBOX), "Sandbox pops back up on the spot (§12.15)")


## The lead (child-psychology research, docs/design/): Cozy / Normal / Brave per Survivor world. The
## knock-out part: Cozy drops no bag; Normal and Brave do. Sandbox never does.
func test_cozy_survivor_worlds_drop_no_bag() -> void:
	assert_true(KnockoutRules.drops_bag(ModeRules.SURVIVOR, KnockoutRules.NORMAL))
	assert_true(KnockoutRules.drops_bag(ModeRules.SURVIVOR, KnockoutRules.BRAVE))
	assert_true(KnockoutRules.drops_bag(ModeRules.SURVIVOR), "Normal by default")
	assert_false(KnockoutRules.drops_bag(ModeRules.SURVIVOR, KnockoutRules.COZY))
	assert_true(KnockoutRules.drops_bag(ModeRules.SURVIVOR, &"banana"), "unknown: Normal")
	for d: StringName in KnockoutRules.DIFFICULTIES:
		assert_false(KnockoutRules.drops_bag(ModeRules.SANDBOX, d))
	assert_eq(KnockoutRules.DIFFICULTIES, [KnockoutRules.COZY, KnockoutRules.NORMAL, KnockoutRules.BRAVE] as Array[StringName])
	assert_eq(KnockoutRules.valid_difficulty(&"brave"), KnockoutRules.BRAVE)
	assert_eq(KnockoutRules.valid_difficulty(&"banana"), KnockoutRules.NORMAL)


## The lead: after a knock-out, one picture tip from a small list, never blaming words.
func test_without_a_bed_the_tip_is_the_bed() -> void:
	var t := KnockoutRules.tip(0, true, false)
	assert_eq(t.icon, BlockIds.BED)
	assert_eq(t.text, "Sleep in a bed to wake up there next time.")
	assert_eq(KnockoutRules.tip(5, true, false).icon, BlockIds.BED, "every time until they have one")


func test_otherwise_the_tips_take_turns() -> void:
	var seen := []
	for n in KnockoutRules.TIPS.size() - 1:
		var t := KnockoutRules.tip(n, true, true)
		assert_ne(t.icon, BlockIds.BED, "they have a bed already")
		assert_false(seen.has(t.text), "a new tip each time")
		seen.append(t.text)
		assert_ne(KnockoutRules.tip(n + 1, true, true).text, t.text, "never the same twice in a row")
	assert_eq(KnockoutRules.tip(0, true, true), KnockoutRules.tip(KnockoutRules.TIPS.size() - 1, true, true), "round again")
	for n in 8:
		assert_ne(KnockoutRules.tip(n, false, false).icon, BlockIds.BED, "Sandbox gets up on the spot: no bed tip")


func test_every_tip_has_a_picture_and_kind_words() -> void:
	for t: Dictionary in KnockoutRules.TIPS:
		assert_not_null(BlockIcons.icon(t.icon), "an icon for %s" % t.text)
		var words := str(t.text).to_lower()
		for bad: String in ["fault", "fail", "bad", "died", "dead", "careless", "should have", "lose", "lost", "wrong", "stupid"]:
			assert_false(words.contains(bad), "'%s' blames: %s" % [bad, t.text])
		assert_lt(str(t.text).length(), 60, "short: %s" % t.text)
	assert_between(KnockoutRules.TIPS.size(), 4, 8, "a small list")


func test_only_blocks_drop_never_tools_weapons_potions_or_shields() -> void:
	for id: int in [BlockIds.DIRT, BlockIds.PLANKS, BlockIds.CRYSTAL, BlockIds.BED, BlockIds.LANTERN]:
		assert_true(KnockoutRules.drops(id), "block %d drops" % id)
	for id: int in [ItemIds.SWORD, ItemIds.PICKAXE, ItemIds.BOW, ItemIds.WAND, ItemIds.DUMMY, ItemIds.POTION_JUMP,
			ItemIds.POTION_INVIS, ItemIds.SHIELD_IRON, ItemIds.SWORD_COSMIC, BlockIds.AIR, BlockIds.BEDROCK, -1, 9999]:
		assert_false(KnockoutRules.drops(id), "%d is kept" % id)


func test_taking_the_blocks_leaves_the_items() -> void:
	var inv := _kit()
	var bag := KnockoutRules.take_blocks(inv)
	assert_eq(bag, [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8], [BlockIds.CRYSTAL, 3]], "every block, in order")
	assert_eq(inv.ids(), [ItemIds.SWORD, ItemIds.PICKAXE, ItemIds.BOW] as Array[int], "tools and weapons stay")
	assert_eq(KnockoutRules.take_blocks(inv), [], "nothing left to drop")


func test_putting_the_bag_back_restores_exactly() -> void:
	var inv := _kit()
	var before := inv.to_save()
	var bag := KnockoutRules.take_blocks(inv)
	var left := KnockoutRules.put_back(bag, inv)
	assert_eq(left, [], "everything fit")
	for e: Array in before:
		assert_eq(inv.count(e[0]), e[1], "id %d" % e[0])
	assert_eq(inv.ids().size(), before.size())


func test_what_does_not_fit_stays_in_the_bag() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.DIRT, Inventory.MAX_COUNT - 5)
	var left := KnockoutRules.put_back([[BlockIds.DIRT, 8], [BlockIds.STONE, 2]], inv)
	assert_eq(inv.count(BlockIds.DIRT), Inventory.MAX_COUNT)
	assert_eq(inv.count(BlockIds.STONE), 2)
	assert_eq(left, [[BlockIds.DIRT, 3]], "never lost: the rest waits in the bag")


func test_merging_bags_adds_counts() -> void:
	var merged := KnockoutRules.merge_items([[BlockIds.DIRT, 8], [BlockIds.STONE, 2]], [[BlockIds.STONE, 5], [BlockIds.SAND, 1]])
	assert_eq(merged, [[BlockIds.DIRT, 8], [BlockIds.STONE, 7], [BlockIds.SAND, 1]])


func test_clean_items_keeps_only_real_blocks() -> void:
	var dirty: Variant = [[BlockIds.DIRT, 8.0], [ItemIds.SWORD, 1], [BlockIds.BEDROCK, 3], [BlockIds.STONE, 0],
		[BlockIds.STONE, -4], "junk", [BlockIds.SAND], [BlockIds.SAND, NAN], [BlockIds.SAND, INF], ["2", 5],
		[BlockIds.DIRT, 2], [BlockIds.GLASS, 1e12]]
	assert_eq(KnockoutRules.clean_items(dirty),
		[[BlockIds.DIRT, 10], [BlockIds.GLASS, KnockoutRules.MAX_COUNT]], "duplicates merge, silly counts cap")
	assert_eq(KnockoutRules.clean_items("nope"), [])
	assert_eq(KnockoutRules.clean_items(null), [])


## Ruling (docs/devlog/parts/m2-task-2.md): a bag is its owner's for 5 minutes, then anyone's.
func test_a_bag_is_its_owners_for_five_minutes_then_anyones() -> void:
	assert_true(KnockoutRules.can_take("Mia", "Mia", 0.0), "the owner, right away")
	assert_true(KnockoutRules.can_take("Mia", "Mia", 9999.0))
	assert_false(KnockoutRules.can_take("Mia", "Leo", 0.0))
	assert_false(KnockoutRules.can_take("Mia", "Leo", KnockoutRules.OWNER_ONLY_TIME - 0.1))
	assert_true(KnockoutRules.can_take("Mia", "Leo", KnockoutRules.OWNER_ONLY_TIME), "then anyone")
	assert_true(KnockoutRules.can_take("", "Leo", 0.0), "a bag without an owner is anyone's")
	assert_eq(KnockoutRules.OWNER_ONLY_TIME, 300.0)


func test_the_refusal_says_whose_bag_and_how_long() -> void:
	assert_eq(KnockoutRules.refusal("Mia", "Mia", 0.0), "")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 0.0), "This is Mia's bag. You can take it in 5 minutes.")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 230.0), "This is Mia's bag. You can take it in 2 minutes.")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 240.0), "This is Mia's bag. You can take it in 1 minute.")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 250.0), "This is Mia's bag. You can take it in 50 seconds.")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 290.0), "This is Mia's bag. You can take it in 10 seconds.")
	assert_eq(KnockoutRules.refusal("Mia", "Leo", 299.5), "This is Mia's bag. You can take it in 1 second.")


func test_reach_is_the_building_reach_with_the_hosts_slack() -> void:
	var eye := Vector3(0, 1.6, 0)
	assert_true(KnockoutRules.in_reach(eye, eye + Vector3(0, 0, PlacementRules.REACH)))
	assert_true(KnockoutRules.in_reach(eye, eye + Vector3(PlacementRules.REACH + PlacementRules.REACH_TOLERANCE, 0, 0)))
	assert_false(KnockoutRules.in_reach(eye, eye + Vector3(PlacementRules.REACH + PlacementRules.REACH_TOLERANCE + 0.1, 0, 0)))
	assert_false(KnockoutRules.in_reach(eye, Vector3(NAN, 0, 0)))


## A world of air with a floor at y = 9 (solid for y <= 9) and one stone at (0, 12, 0).
func _floor(cell: Vector3i) -> bool:
	return cell.y <= 9 or cell == Vector3i(0, 12, 0)


func test_the_bag_falls_to_the_ground_below() -> void:
	assert_eq(KnockoutRules.bag_spot(Vector3(3.2, 17.9, -4.7), _floor), Vector3(3.5, 10.0, -4.5))
	assert_eq(KnockoutRules.bag_spot(Vector3(3.2, 10.0, -4.7), _floor), Vector3(3.5, 10.0, -4.5), "already on the ground")
	assert_eq(KnockoutRules.bag_spot(Vector3(0.5, 15.0, 0.5), _floor), Vector3(0.5, 13.0, 0.5), "lands on the stone")


func test_a_bag_inside_blocks_rises_to_the_first_free_cell() -> void:
	assert_eq(KnockoutRules.bag_spot(Vector3(2.5, 7.5, 2.5), _floor), Vector3(2.5, 10.0, 2.5))


func test_with_no_ground_in_sight_the_bag_stays_where_they_fell() -> void:
	var air := func(_cell: Vector3i) -> bool: return false
	assert_eq(KnockoutRules.bag_spot(Vector3(1.2, 40.3, 1.7), air), Vector3(1.5, 40.0, 1.5))
	assert_eq(KnockoutRules.bag_spot(Vector3(NAN, 1, 1), air), Vector3.INF, "a broken position drops no bag in the void")


func test_a_new_drop_goes_into_the_owners_bag_nearby() -> void:
	var bags := [{"owner": "Leo", "pos": Vector3(0, 10, 0), "age": 5.0},
		{"owner": "Mia", "pos": Vector3(20, 10, 0), "age": 50.0},
		{"owner": "Mia", "pos": Vector3(1, 10, 1), "age": 10.0}]
	assert_eq(KnockoutRules.merge_index(bags, "Mia", Vector3(1.5, 10, 0.5)), 2, "Mia's bag right there")
	assert_eq(KnockoutRules.merge_index(bags, "Mia", Vector3(10, 10, 0)), -1, "a new bag far from hers")
	assert_eq(KnockoutRules.merge_index(bags, "Ava", Vector3(0, 10, 0)), -1, "never into someone else's bag")


func test_too_many_bags_fill_the_owners_oldest() -> void:
	var bags := []
	for i in KnockoutRules.MAX_BAGS_PER_PLAYER:
		bags.append({"owner": "Mia", "pos": Vector3(i * 10, 10, 0), "age": 100.0 - i})
	bags.append({"owner": "Leo", "pos": Vector3(0, 10, 50), "age": 999.0})
	assert_eq(KnockoutRules.merge_index(bags, "Mia", Vector3(500, 10, 0)), 0, "her oldest")
	assert_eq(KnockoutRules.merge_index(bags, "Leo", Vector3(500, 10, 0)), -1, "Leo has room")


func test_a_full_world_fills_the_oldest_bag() -> void:
	var bags := []
	for i in KnockoutRules.MAX_BAGS:
		bags.append({"owner": "P%d" % (i % 40), "pos": Vector3(i * 10, 10, 0), "age": 100.0 + (7 if i == 13 else 0)})
	assert_eq(KnockoutRules.merge_index(bags, "Zed", Vector3(-500, 10, 0)), 13, "never more than MAX_BAGS, never a loss")
