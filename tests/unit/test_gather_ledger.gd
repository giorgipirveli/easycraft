extends GutTest
## M2 §12.2: one edit request's block accounting against the requester's inventory (the host asks
## `pays` before it changes a cell and calls `changed` after). Batches of placements are paid for
## whole or not at all; undo never duplicates.

const A := BlockIds.AIR


func _inv(pairs: Array) -> Inventory:
	var inv := Inventory.new()
	for p: Array in pairs:
		inv.add(p[0], p[1])
	return inv


## One edit through the ledger, as the host does it: returns whether the cell changed.
static func _edit(ledger: GatherLedger, old: int, new: int) -> bool:
	if not ledger.pays(old, new):
		return false
	ledger.changed(old, new)
	return true


func test_placing_takes_one() -> void:
	var inv := _inv([[BlockIds.STONE, 2]])
	assert_true(_edit(GatherLedger.new(inv), A, BlockIds.STONE))
	assert_eq(inv.count(BlockIds.STONE), 1)


func test_placing_the_last_one_then_nothing() -> void:
	var inv := _inv([[BlockIds.STONE, 1]])
	assert_true(_edit(GatherLedger.new(inv), A, BlockIds.STONE))
	var ledger := GatherLedger.new(inv)
	assert_false(_edit(ledger, A, BlockIds.STONE), "none left")
	assert_eq(ledger.message, "You have no Stone left!")
	assert_eq(inv.count(BlockIds.STONE), 0)


func test_breaking_gives_the_drop() -> void:
	var inv := Inventory.new()
	var ledger := GatherLedger.new(inv)
	assert_true(_edit(ledger, BlockIds.STONE, A))
	assert_true(_edit(ledger, BlockIds.GRASS, A))
	assert_true(_edit(ledger, BlockIds.LEAVES, A), "leaves break, and give nothing")
	assert_eq(inv.count(BlockIds.STONE), 1)
	assert_eq(inv.count(BlockIds.DIRT), 1)
	assert_eq(inv.count(BlockIds.GRASS), 0)
	assert_eq(inv.count(BlockIds.LEAVES), 0)
	assert_eq(ledger.message, "")


func test_ores_need_their_pickaxe_and_nothing_breaks_without_it() -> void:
	var inv := Inventory.new()
	var ledger := GatherLedger.new(inv)
	assert_false(_edit(ledger, BlockIds.COAL, A))
	assert_eq(ledger.message, "You need a pickaxe for this!")
	inv.add(ItemIds.PICKAXE, 1)
	ledger = GatherLedger.new(inv)
	assert_true(_edit(ledger, BlockIds.COAL, A), "any pickaxe mines coal")
	assert_false(_edit(ledger, BlockIds.DIAMOND, A))
	assert_eq(ledger.message, "You need an iron pickaxe for this!")
	assert_eq(inv.count(BlockIds.COAL), 1)
	assert_eq(inv.count(BlockIds.DIAMOND), 0)


func test_a_break_at_999_still_breaks_and_keeps_999() -> void:
	var inv := _inv([[BlockIds.STONE, Inventory.MAX_COUNT]])
	assert_true(_edit(GatherLedger.new(inv), BlockIds.STONE, A))
	assert_eq(inv.count(BlockIds.STONE), Inventory.MAX_COUNT)


func test_a_batch_of_placements_is_paid_whole_or_not_at_all() -> void:
	var inv := _inv([[BlockIds.PLANKS, 2]])
	var ledger := GatherLedger.new(inv)
	assert_false(ledger.reserve([[A, BlockIds.PLANKS], [A, BlockIds.PLANKS], [A, BlockIds.PLANKS]]))
	assert_eq(ledger.message, "You need 1 more Planks!")
	assert_false(ledger.pays(A, BlockIds.PLANKS), "a refused batch builds nothing")
	assert_eq(inv.count(BlockIds.PLANKS), 2)
	ledger = GatherLedger.new(inv)
	assert_true(ledger.reserve([[A, BlockIds.PLANKS], [A, BlockIds.PLANKS]]))
	assert_true(_edit(ledger, A, BlockIds.PLANKS))
	assert_true(_edit(ledger, A, BlockIds.PLANKS))
	assert_eq(inv.count(BlockIds.PLANKS), 0)


func test_a_batch_with_none_of_a_block_says_so() -> void:
	var ledger := GatherLedger.new(Inventory.new())
	assert_false(ledger.reserve([[A, BlockIds.GLASS]]))
	assert_eq(ledger.message, "You have no Glass left!")


## What the batch breaks counts towards what it places (a stamp carving through planks).
func test_a_batch_counts_what_it_gives_back() -> void:
	var inv := _inv([[BlockIds.PLANKS, 1]])
	var ledger := GatherLedger.new(inv)
	assert_true(ledger.reserve([[BlockIds.PLANKS, A], [A, BlockIds.PLANKS], [A, BlockIds.PLANKS]]))


## A batch that only breaks (tool powers) is never refused whole: gated ore cells stay, the rest break.
func test_a_breaking_batch_skips_only_the_ores_it_may_not_break() -> void:
	var inv := _inv([[ItemIds.PICKAXE, 1]])
	var ledger := GatherLedger.new(inv)
	assert_true(ledger.reserve([[BlockIds.STONE, A], [BlockIds.GOLD, A], [BlockIds.COAL, A]]))
	assert_true(_edit(ledger, BlockIds.STONE, A))
	assert_false(_edit(ledger, BlockIds.GOLD, A))
	assert_true(_edit(ledger, BlockIds.COAL, A))
	assert_eq(ledger.message, "You need an iron pickaxe for this!")
	assert_eq([inv.count(BlockIds.STONE), inv.count(BlockIds.GOLD), inv.count(BlockIds.COAL)], [1, 0, 1])


## Place, undo: the block is back. Break, undo: it is taken back out. Never one more, never one less.
func test_undo_gives_back_and_takes_back_without_duplicating() -> void:
	var inv := _inv([[BlockIds.STONE, 3]])
	assert_true(_edit(GatherLedger.new(inv), A, BlockIds.STONE))
	assert_true(_edit(GatherLedger.new(inv, true), BlockIds.STONE, A))
	assert_eq(inv.count(BlockIds.STONE), 3, "undoing a placement returns the block")
	assert_true(_edit(GatherLedger.new(inv), BlockIds.STONE, A))
	assert_eq(inv.count(BlockIds.STONE), 4)
	assert_true(_edit(GatherLedger.new(inv, true), A, BlockIds.STONE))
	assert_eq(inv.count(BlockIds.STONE), 3, "undoing a break takes it back out")


func test_undoing_a_break_needs_the_block_still_owned() -> void:
	var inv := Inventory.new()
	assert_true(_edit(GatherLedger.new(inv), BlockIds.BRICK, A))
	assert_true(_edit(GatherLedger.new(inv), A, BlockIds.BRICK), "the brick is built somewhere else")
	var undo := GatherLedger.new(inv, true)
	assert_false(_edit(undo, A, BlockIds.BRICK), "no brick to put back: no free brick")
	assert_eq(undo.message, "You have no Brick left!")


func test_undoing_broken_grass_costs_the_dirt_it_gave() -> void:
	var inv := Inventory.new()
	assert_true(_edit(GatherLedger.new(inv), BlockIds.GRASS, A))
	assert_true(_edit(GatherLedger.new(inv, true), A, BlockIds.GRASS))
	assert_eq(inv.ids(), [] as Array[int], "the dirt went back into the grass")


func test_undoing_a_placed_ore_needs_no_pickaxe() -> void:
	var inv := _inv([[BlockIds.GOLD, 1]])
	assert_true(_edit(GatherLedger.new(inv), A, BlockIds.GOLD))
	assert_true(_edit(GatherLedger.new(inv, true), BlockIds.GOLD, A))
	assert_eq(inv.count(BlockIds.GOLD), 1)
