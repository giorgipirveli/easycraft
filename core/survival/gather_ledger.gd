class_name GatherLedger
extends RefCounted
## One edit request's block accounting in Survivor (M2 §12.2), against the requester's Inventory
## (GatherRules decides what each cell change gives and takes). The host (Session) asks `pays`
## before it changes a cell and calls `changed` with what the cell really became. A batch of edits
## first `reserve`s: its placements are paid for whole, or nothing is built. An undo (is_undo) is
## never gated by a pickaxe and never refused whole: each cell it can't pay for waits for later.

var inventory: Inventory
var is_undo: bool
var tier: int
## The first refusal, for the player ("" = nothing was refused).
var message := ""
var _refused := false   # reserve failed: nothing may change


func _init(inv: Inventory, undo: bool = false) -> void:
	inventory = inv
	is_undo = undo
	tier = GatherRules.pickaxe_tier(inv)


## Before a batch of edits: cells = [[old, new], ...], every cell the host would change. False when
## the player hasn't enough for all of its placements (then `pays` refuses every cell). What the
## batch breaks counts towards what it places. Cells the pickaxe can't break are left out (they
## stay). Undo batches are never reserved.
func reserve(cells: Array) -> bool:
	var net := {}
	for c: Array in cells:
		if not is_undo and not GatherRules.can_break(c[0], tier):
			continue
		var delta := GatherRules.change(c[0], c[1], is_undo, tier)
		for id: int in delta:
			net[id] = int(net.get(id, 0)) + int(delta[id])
	for id: int in net:
		if net[id] < 0 and inventory.count(id) < -int(net[id]):
			_refuse(_short_message(id, -int(net[id])))
			_refused = true
			return false
	return true


## May one cell change from `old` to `new` now? An edit needs the pickaxe for `old` (ores) and one
## `new` to place; an undo needs what it puts back.
func pays(old: int, new: int) -> bool:
	if _refused:
		return false
	if old == new:
		return true
	if not is_undo and old != BlockIds.AIR:
		var gate := GatherRules.refusal(old, tier)
		if gate != "":
			_refuse(gate)
			return false
	var delta := GatherRules.change(old, new, is_undo, tier)
	for id: int in delta:
		if delta[id] < 0 and inventory.count(id) < -int(delta[id]):
			_refuse(_short_message(id, -int(delta[id])))
			return false
	return true


## The cell changed from `old` to `new`: takes what it used, gives what it gave (a full count of
## 999 keeps no more).
func changed(old: int, new: int) -> void:
	var delta := GatherRules.change(old, new, is_undo, tier)
	for id: int in delta:
		if delta[id] < 0:
			inventory.take(id, -int(delta[id]))
	for id: int in delta:
		if delta[id] > 0:
			inventory.add(id, delta[id])


## "You have no Stone left!" or "You need 3 more Planks!".
func _short_message(id: int, need: int) -> String:
	var have := inventory.count(id)
	var block_name := ItemIds.display_name(id)
	if have == 0:
		return tr("You have no %s left!") % block_name
	return tr("You need %d more %s!") % [need - have, block_name]


func _refuse(text: String) -> void:
	if message == "":
		message = text
