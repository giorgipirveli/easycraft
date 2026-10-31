class_name LabSupplies
extends RefCounted
## Spec §23.2: a lab bench's supplies are endless in the Sandbox and cost a few ordinary blocks in Survivor, the child's
## own (LabExperiments.supplies: 1-3 blocks an experiment). Taken from the bag all at once, or not at all.


## Takes experiment `e`'s supplies from `inv` (nothing when `unlimited`): "" when the bench may run it, else the words
## of what it needs ("The bench needs 1 Planks and 1 Stone from your bag.").
static func take(inv: Inventory, e: Dictionary, unlimited: bool) -> String:
	if unlimited:
		return ""
	var need := LabExperiments.supplies(e)
	for id: int in need:
		if inv == null or inv.count(id) < int(need[id]):
			return "The bench needs %s from your bag for this one." % LabExperiments.supplies_words(e)
	for id: int in need:
		inv.take(id, int(need[id]))
	return ""
