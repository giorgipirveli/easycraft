class_name SpaceTrip
extends RefCounted
## The saves of a trip to space (owner feedback #55, spec §21.3), shared by the sandbox (section "Owner #55: space")
## and the tests. Landing: the space world's save is written first (made the first time; like universe travel, a crash
## in between may copy the bag, never lose it); then the world left behind is saved by the caller and marked with
## SpaceRules.take_off (the column the child took off from, walking). Coming home is owner #39's way home
## (sandbox.travel_through_gate: the portal by the landing pad, or HOME in the picker); the home world then lands the
## child on that column (SpaceRules.landing_spot).


## The space world `to` a child of `key` lands on from the world of `here` (played in `mode`), saved in `slot`: on its
## landing pad, its home remembered (here's, or here's own home when here is a space world). Survivor: the live bag and
## hotbar come along (UniverseRules.carry: what does not fit stays in `here`); Sandbox: the hotbar. Returns the saved
## meta.
static func arrival(here: WorldMeta, to: int, mode: StringName, slot: String, key: String, bag: Array,
		hotbar: Array[int], selected: int) -> WorldMeta:
	var home := SpaceRules.home_for(here.universe, here.space_home)
	var existing := WorldSaves.load_meta(slot) if WorldSaves.exists(slot) else null
	var m := SpaceRules.arrival_meta(existing, to, mode, here.difficulty, home)
	if ModeRules.valid(mode) == ModeRules.SURVIVOR:
		UniverseRules.carry(here, m, key, bag, hotbar, selected)
	else:
		m.hotbar = hotbar.duplicate()
		m.selected_slot = clampi(selected, 0, WorldMeta.HOTBAR_SIZE - 1)
	WorldSaves.save_meta(slot, m)
	return m
