class_name BlockInteractor
extends Node
## Placing, breaking and undoing blocks for the local player. Targets come from a screen point
## (touch) or the screen centre (crosshair). Every edit goes through Session.request_set_block.

signal selection_changed(slot: int, block_id: int)
signal edited(kind: StringName)   # &"place", &"break", &"undo"
signal mirror_changed(enabled: bool)
## M3 Task 11: this player tapped one of their own pets (the sandbox opens its picture card).
signal pet_tapped(animal: Animal)

const UNDO_DEPTH := 20

var hotbar: Array[int] = WorldMeta._default_hotbar()
var selected_slot := 0
var crosshair_mode := false   # true with a captured mouse or in first person
var mirror_enabled := false
var mirror_axis: int = MirrorRules.Axis.X
var mirror_plane := 0

var _undo := UndoStack.new(UNDO_DEPTH)
var _preview_point := Vector2.INF

@onready var player: Player = get_parent()
@onready var highlight: TargetHighlight = $TargetHighlight
@onready var mirror_wall: MirrorWall = $MirrorWall


func _ready() -> void:
	Session.undo_step_received.connect(_on_undo_step)
	Session.tool_undo_step_received.connect(_on_tool_undo_step)   # M3 Task 8
	ShaderWarmup.at_spawn(player.spawned, prewarm_feedback)   # M2 Task 3: the ring's and pop's shader (M7: at_spawn)


func selected_block() -> int:
	return hotbar[selected_slot]


func select_slot(slot: int) -> void:
	selected_slot = clampi(slot, 0, hotbar.size() - 1)
	selection_changed.emit(selected_slot, selected_block())


func set_slot_block(slot: int, id: int) -> void:
	if ItemIds.is_hotbar_valid(id):
		hotbar[slot] = id
		select_slot(slot)


## Tap action: places the selected block, stamps the selected stamp, or casts the wand.
func place_at_screen(screen_pos: Vector2) -> bool:
	if _come_out():   # M2 Task 5: inside a barrel or closet, any tap comes out
		return true
	if tap_override.is_valid():   # M4 I: SHARE is picking a build (the tap picks, nothing else)
		return tap_override.call(screen_pos)
	if discovery_tap.is_valid() and discovery_tap.call(screen_pos):
		return true   # owner #132 (W1): a discovery crystal or its gems, whatever is in the hand
	if _take_bag_at(screen_pos):   # a pickup bag comes first, whatever is in the hand (M2 Task 2)
		return true
	if _tap_trader(screen_pos):
		return true   # Tilly's shop, whatever is in the hand (M2 Task 7)
	if _tap_quest_giver(screen_pos):
		return true   # owner #45a: a quest giver's card, whatever is in the hand
	if _tap_space_creature(screen_pos):
		return true   # owner #86: a robot or an alien on a space world, whatever is in the hand
	if name_tag_tap.is_valid() and name_tag_tap.call(screen_pos):
		return true   # owner #37: another player's card (TRADE), whatever is in the hand
	if music_tap.is_valid() and music_tap.call(screen_pos):
		return true   # owner #110: a music block's bar or skin plays, whatever is in the hand
	if vehicle_tap.is_valid() and vehicle_tap.call(screen_pos):
		return true   # owner #109: a car: get in (a pickup's bed: load or unload it)
	if SecretTaps.tap(self, screen_pos):   # chests, notes, the Wanderer, golden animals, fake walls (M2 Task 16)
		return true
	if _tap_totem(screen_pos):
		return true   # the Monster Totem's panel, whatever is in the hand (M2 Task 9)
	if _tap_farm(screen_pos):
		return true   # M3 Task 10: the Gold Farm's panel, whatever is in the hand
	if GameTaps.tap(self, screen_pos):
		return true   # M4 H: a seeker looks into a barrel, closet or bush
	if _tap_hiding_spot(screen_pos):
		return true   # M2 Task 5: into a barrel or closet close by, whatever is in the hand
	if _tap_door(screen_pos):
		return true   # a door opens or closes, whatever is in the hand (M2 Task 8)
	if _tap_smart(screen_pos):
		return true   # M3 Task 7: a switch flips, START and FINISH show their course, whatever is in the hand
	if _tap_zipline(screen_pos):
		return true   # M3 Task 14a: a tap on a zipline post rides its line, whatever is in the hand
	if _tap_bookshelf(screen_pos):
		return true   # M3 Task 21b: a bookshelf opens the books, whatever is in the hand
	if _tap_lab_bench(screen_pos):
		return true   # spec §23: a lab bench opens the Science Lab, whatever is in the hand
	if _tap_plaque(screen_pos):
		return true   # owner #78: a wonder's plaque opens its card and quiz, whatever is in the hand
	if tools.handles(selected_block()):
		return tools.use_at_screen(screen_pos)   # M3 Task 8: paint, LINE, FILL, COPY, REWIND
	if gadgets.handles(selected_block()):
		return gadgets.use_at_screen(screen_pos)   # M3 Task 14a: the hook, an orb, a quick build, the glider
	if weapons.handles(selected_block()):
		return weapons.use_at_screen(screen_pos)   # a weapon hits (animals too, owner feedback #26; pets are only pushed)
	if selected_block() == ItemIds.WAND and _t20b_befriend(screen_pos):
		return true   # M3 Task 20b: the wand on a monster asks to befriend it
	var animal := _animal_at(screen_pos)
	if animal and _tap_pet(animal):   # M3 Task 11: a treat, or a pat on your own pet
		return true
	if animal:
		Session.request_pet(animal.name)
		if AnimalFood.is_block_food(animal.species, selected_block()):
			Session.mind_request_treat(animal.name)   # M2 Task 18: its food in hand is a treat (owner #41: by kind)
			animal_fed.emit(animal.species)   # M3 Task 21b: the Animal Book's FED mark
		animal.cheer()
		return true
	var buddy := _buddy_at(screen_pos)
	if buddy:
		if selected_block() == ItemIds.WAND:
			Session.request_sleep(buddy.name)
		else:
			buddy.cheer()
		return true
	var hit := _ray(screen_pos)
	if hit == null:
		return false
	var item := selected_block()
	if item == ItemIds.FARM:
		return _place_farm(hit)   # M3 Task 10: placed like a stamp; the host decides
	if ItemIds.is_stamp(item):
		return _stamp(item, hit.previous_position)
	if item == ItemIds.WAND:
		return _cast_wand(hit.position)
	return place_block(hit.previous_position, item)


## Places the block `item` at `pos` through the host (the same undo, Survivor's bag and online path), with its note and
## pop: a tap's and the laser's place, and owner #116's brick laid by hand in VR (VrBricks). False when nothing was asked.
func place_block(pos: Vector3i, item: int) -> bool:
	if PetRules.is_treat(item):
		return false   # M3 Task 11: a treat is for a pet, never a block
	if ItemIds.is_lens(item):
		return false   # owner #110 (VR-WONDER): a lens is a tool in the hand (VrLens), never a block
	var id := CrystalRules.core_for_item(item) if CrystalRules.is_crystal(item) else item   # owner 39: a crystal is its universe's core
	if not _apply_edits([[pos, id]]):
		return false
	edited.emit(&"place")
	melody.place(Vector3(pos) + Vector3(0.5, 0.5, 0.5), id)   # M3 Task 21c: its note (or the plain pop)
	place_pop.pop(pos)   # M2 Task 3: the new block pops in
	return true


func break_at_screen(screen_pos: Vector2) -> bool:
	if _come_out():   # M2 Task 5
		return true
	if discovery_tap.is_valid() and discovery_tap.call(screen_pos):
		return true   # owner #132 (W1): a crystal's gem (a PC's left click too), never a block broken behind it
	if _take_bag_at(screen_pos):
		return true
	var target := hittable_at(screen_pos, PlacementRules.REACH) as PracticeTarget
	if target:
		Session.request_remove_target(target.name)
		return true
	var hit := _ray(screen_pos)
	if hit == null:
		return false
	return break_block(hit.position)


## Breaks the block at `pos` through the host, with its sound and bits: a hold's and the laser's break, and owner #116's
## block taken out of a wall by hand in VR (VrBricks). False when there was nothing to break.
func break_block(pos: Vector3i) -> bool:
	var old := player.world.get_block(pos)
	if old == BlockIds.AIR or not _apply_edits([[pos, BlockIds.AIR]]):
		return false
	edited.emit(&"break")
	Audio.play(&"break", Vector3(pos) + Vector3(0.5, 0.5, 0.5))
	Fx.break_block(player.world, pos, old)
	return true


func _stamp(stamp: int, anchor: Vector3i) -> bool:
	var forward := Blueprints.facing_for_yaw(player.rig.yaw)
	if not _apply_edits(Blueprints.place(stamp, anchor, forward)):
		return false
	edited.emit(&"stamp")
	stamped.emit(stamp, anchor, forward)   # M4 ghost races: a gift's race comes with its stamp
	melody.place(Vector3(anchor), stamp)   # M3 Task 21c: one note for the whole stamp
	Fx.burst(player.world, Vector3(anchor) + Vector3(0.5, 2.0, 0.5), Color("ffd23f"), 28, 6.0, 0.16, 0.9, 6.0)
	return true


## Magic Wand: asks the host to bring the tapped build to life.
func _cast_wand(block_pos: Vector3i) -> bool:
	Fx.burst(player.world, Vector3(block_pos) + Vector3(0.5, 0.5, 0.5), Color("ffd23f"), 18, 4.0, 0.12, 0.7, 3.0)
	Audio.play(&"air_jump", Vector3(block_pos))
	if tools.offer_wear(block_pos):
		return true   # M3 Task 8: a small build: WAKE UP, or wear it as a HAT, BACKPACK or WINGS
	Session.request_spark(block_pos)
	return true


## The animal under a screen point, if any (physics ray against the animal layer).
func _animal_at(screen_pos: Vector2) -> Animal:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var query := PhysicsRayQueryParameters3D.create(from, to, Animal.LAYER)
	var hit := space_ray(query)
	return hit.get("collider") as Animal if not hit.is_empty() else null


## The buddy under a screen point, if any (physics ray against the buddy layer).
func _buddy_at(screen_pos: Vector2) -> Buddy:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var query := PhysicsRayQueryParameters3D.create(from, to, Buddy.LAYER)
	var hit := space_ray(query)
	return hit.get("collider") as Buddy if not hit.is_empty() else null


## Applies edits [[pos, id], ...] (plus their mirror copies in Mirror mode, unless mirrored is
## false) through the host. The host answers with one undo step of what it really changed.
func _apply_edits(edits: Array, mirrored: bool = true) -> bool:
	var all: Array = edits.duplicate()
	if mirror_enabled and mirrored:
		for e: Array in edits:
			var m := MirrorRules.mirror(e[0], mirror_axis, mirror_plane)
			if m != e[0]:
				all.append([m, e[1]])
	return Session.request_set_block(all[0][0], all[0][1]) if all.size() == 1 else Session.request_set_blocks(all)


## The host's answer to this player's edits: one undo step of [pos, id to put back, id now]
## entries (for an undo, the cells it could not restore yet). Malformed entries are skipped.
func _on_undo_step(step: Array) -> void:
	if not player.is_local:
		return
	var entries: Array = []
	for e: Variant in step:
		if e is Array and (e as Array).size() == 3 and e[0] is Vector3i and e[1] is int and e[2] is int:
			entries.append({"pos": e[0], "old_id": e[1], "new_id": e[2]})
	if entries.size() == 1:
		_undo.push(entries[0].pos, entries[0].old_id, entries[0].new_id)
	elif entries.size() > 1:
		_undo.push_batch(entries)


func place_crosshair() -> bool:
	return place_at_screen(_screen_center())


func break_crosshair() -> bool:
	return break_at_screen(_screen_center())


## Reverts the last edit (a whole batch at once). The host sends back, as a new undo step, the
## cells it could not restore yet (a player standing there), so they are kept for later.
func undo() -> bool:
	var entry := _undo.pop()
	if entry.is_empty():
		return false
	undoing.emit(_undo_cells(entry))   # M3 Task 8: Build Rewind records what an undo asks for
	var ok := false
	if entry.get("via", &"") == &"tool":
		ok = _undo_tool(entry)   # M3 Task 8: a building tool's step goes back through the host's tool log
	elif entry.has("batch"):
		var changes: Array = []
		for c: Dictionary in entry.batch:
			changes.append([c.pos, c.old_id])
		ok = Session.request_set_blocks(changes, true)
	else:
		ok = Session.request_set_block(entry.pos, entry.old_id, true)
	if ok:
		edited.emit(&"undo")
		Audio.play(&"undo")
	return ok


## Mirror mode on/off. The mirror runs through the player's position, splitting left from right
## as the camera currently sees it.
func toggle_mirror() -> void:
	mirror_enabled = not mirror_enabled
	if mirror_enabled:
		mirror_axis = MirrorRules.axis_for_yaw(player.rig.yaw)
		var p := player.global_position
		mirror_plane = floori(p.x) if mirror_axis == MirrorRules.Axis.X else floori(p.z)
		mirror_wall.show_at(mirror_axis, mirror_plane, p)
	else:
		mirror_wall.visible = false
	mirror_changed.emit(mirror_enabled)


func undo_size() -> int:
	return _undo.size()


## Shows the target highlight under a finger that is resting on the screen.
func preview_at_screen(screen_pos: Vector2) -> void:
	_preview_point = screen_pos


func clear_preview() -> void:
	_preview_point = Vector2.INF


func _process(_delta: float) -> void:
	if not player.is_spawned():
		highlight.visible = false
		return
	var point := _screen_center() if crosshair_mode else _preview_point
	var hit := _ray(point) if point.is_finite() else null
	highlight.show_block(hit.position if hit else null)


func _unhandled_input(event: InputEvent) -> void:
	if not space_readable():   # VR P5's follow-up (a): a key's or a button's tap in the physics step
		_later.append([func() -> bool: _handle_input(event); return true, Callable()])
		return
	_handle_input(event)


func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"undo"):
		undo()
	if event.is_action_pressed(&"mirror"):
		toggle_mirror()
	for i in hotbar.size():
		if event.is_action_pressed(StringName("hotbar_%d" % (i + 1))):
			tap_slot(i)
	if weapons.handle_input(event, crosshair_mode, _screen_center()):
		return
	if not crosshair_mode:
		return
	if event.is_action_pressed(&"break"):
		break_crosshair()
	elif event.is_action_pressed(&"place"):
		place_crosshair()


func _ray(screen_pos: Vector2) -> BlockHit:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var max_dist := PlacementRules.ray_length(ray[0], player.eye_position())
	var hit := player.world.raycast(ray[0], ray[1], max_dist)
	if hit and PlacementRules.in_reach(player.eye_position(), hit.position):
		return hit
	return null


func _screen_center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


# --- Weapons, tools and practice targets (M1b Task 11) ---

## Physics layers a weapon tap looks for (besides the world, which blocks the view): players (2),
## buddies, animals (8) and practice targets.
const HITTABLE_LAYERS := 2 | Buddy.LAYER | 8 | PracticeTarget.LAYER

@onready var weapons: WeaponUser = _add_weapon_user()


func _add_weapon_user() -> WeaponUser:
	var w := WeaponUser.new()
	w.name = "Weapons"
	w.interactor = self
	add_child(w)
	return w


## The block a screen point targets within building reach, or null.
func ray_at(screen_pos: Vector2) -> BlockHit:
	return _ray(screen_pos)


func apply_edits(edits: Array, mirrored: bool = true) -> bool:
	return _apply_edits(edits, mirrored)


## The player, buddy, animal, monster (M2 Task 4; on the animals' layer) or practice target under a
## screen point, up to max_dist from the player's eye; never one hidden behind blocks, never yourself.
func hittable_at(screen_pos: Vector2, max_dist: float) -> Node3D:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * (from.distance_to(player.eye_position()) + max_dist)
	var query := PhysicsRayQueryParameters3D.create(from, to, HITTABLE_LAYERS | Player.WORLD_COLLISION_MASK, [player.get_rid()])
	var hit := space_ray(query)
	var node := hit.get("collider") as Node3D if not hit.is_empty() else null
	if node is PracticeTarget or node is Buddy or node is Player or (node and (node.is_in_group(&"animals") or node.is_in_group(&"monsters"))):
		return node
	return null


# --- Build feedback: the break ring and the place pop (M2 Task 3, the lead's child-friendly feedback) ---

@onready var break_ring: BreakRing = _add_feedback(BreakRing.new(), &"BreakRing") as BreakRing
@onready var place_pop: PlacePop = _add_feedback(PlacePop.new(), &"PlacePop") as PlacePop


func _add_feedback(node: Node3D, node_name: StringName) -> Node3D:
	node.name = node_name
	add_child(node)
	return node


## The break ring on the block a held finger is breaking, `progress` (0..1) filled; a null hit or a
## negative progress hides it.
func show_break_progress(hit: BlockHit, progress: float) -> void:
	if hit == null or progress < 0.0:
		if break_ring.visible:
			break_ring.show_on(null, 0.0)
		return
	break_ring.show_on(hit, progress)


## Compiles the ring's and the pop's shader as the world appears (this game's own player only).
func prewarm_feedback() -> void:
	if player.is_local:
		break_ring.prewarm(player.camera())
		place_pop.prewarm(player.camera())

# --- Pickup bags (M2 Task 2) ---

## A tap (or a hold) on a pickup bag asks the host for it; the host checks reach and whose it is.
func _take_bag_at(screen_pos: Vector2) -> bool:
	var bag := _bag_at(screen_pos)
	if bag == null:
		return false
	Session.request_take_bag(bag.name)
	return true


## The pickup bag under a screen point within building reach, never one behind blocks.
func _bag_at(screen_pos: Vector2) -> PickupBag:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var query := PhysicsRayQueryParameters3D.create(from, to, PickupBag.LAYER | Player.WORLD_COLLISION_MASK, [player.get_rid()])
	var hit := space_ray(query)
	return hit.get("collider") as PickupBag if not hit.is_empty() else null

# --- M2 Task 7: Tilly the trader ----------------------------------------------------------------

## The local player tapped Tilly within reach: the HUD opens her shop.
signal trader_tapped(trader: Trader)


func _tap_trader(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var blocked := func(from: Vector3, dir: Vector3, dist: float) -> bool: return player.world.raycast(from, dir, dist) != null
	var t := Trader.find(get_tree(), ray[0], ray[1], player.eye_position(), blocked)
	if t and stall_quest_tap.is_valid() and stall_quest_tap.call():
		return true   # owner #45a: Tilly has a story to tell (her card has SHOP)
	if t:
		trader_tapped.emit(t)
	return t != null

# --- Owner #45a: quest givers ---

## The local player tapped a quest giver within reach: its card (QuestDirector).
signal quest_giver_tapped(giver: QuestGiver)
## () -> bool: a tap on Tilly's stall opened her quest card instead of the shop (QuestDirector sets it).
var stall_quest_tap: Callable


func _tap_quest_giver(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var blocked := func(from: Vector3, dir: Vector3, dist: float) -> bool: return player.world.raycast(from, dir, dist) != null
	var g := QuestGiver.find(get_tree(), ray[0], ray[1], player.eye_position(), blocked)
	if g:
		quest_giver_tapped.emit(g)
	return g != null

# --- Owner #86: the planets' robots and aliens (spec §21f) ---

## A robot or an alien on a space world under the tap (SpaceCreature.find): it hears the tap (its card, a dig...).
func _tap_space_creature(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var blocked := func(from: Vector3, dir: Vector3, dist: float) -> bool: return player.world.raycast(from, dir, dist) != null
	var c := SpaceCreature.find(get_tree(), ray[0], ray[1],
		player.eye_position(), blocked)
	return c != null and c.tapped()

# --- Potions (M2 Task 6) ---

## A tap on a hotbar slot (or its number key): selects it, and drinks a potion held there (the host
## decides; Session.request_drink). Picking a potion from the palette only puts it in the slot.
func tap_slot(slot: int) -> void:
	select_slot(slot)
	if PotionRules.is_potion(selected_block()):
		Session.request_drink(selected_block())

# --- M2 Task 9: the Monster Totem ----------------------------------------------------------------

## The local player tapped the Monster Totem within reach (never during its wave): the HUD opens its panel.
signal totem_tapped(totem: Totem)


func _tap_totem(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var blocked := func(from: Vector3, dir: Vector3, dist: float) -> bool: return player.world.raycast(from, dir, dist) != null
	var t := Totem.find(get_tree(), ray[0], ray[1], player.eye_position(), blocked)
	if t:
		totem_tapped.emit(t)
	return t != null


# --- M2 Task 5: hiding in barrels and closets -----------------------------------------------------

## Inside a hiding spot, any tap (or hold) asks the host to come out.
func _come_out() -> bool:
	if not player.is_hiding():
		return false
	Session.stealth_request_unhide()
	return true


## A tap on a barrel or closet within building reach asks the host to hide inside (it checks that it
## is close enough, and says so when it is not). No block is placed on it.
func _tap_hiding_spot(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or not StealthRules.is_hiding_block(player.world.get_block(hit.position)):
		return false
	Session.stealth_request_hide(hit.position)
	return true


# --- M2 Task 8: doors -------------------------------------------------------------------------------

## A tap on a door within reach asks the host to open or close its doorway, whatever is in the hand (a
## hold still breaks it). Something standing in front of the door (a monster, an animal, a friend)
## takes the tap instead, so a sword still hits the goblin at the door.
func _tap_door(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or not DefenseRules.is_door(player.world.get_block(hit.position)):
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	Session.request_door(hit.position)
	return true

# --- M3 Task 7: smart blocks and Game Blocks -------------------------------------------------------------

## A tap on a START or FINISH block (the HUD shows its course's goals panel).
signal course_tapped(cell: Vector3i)


## A tap on a button, lever or light switch within reach asks the host to flip it; a tap on START or FINISH
## shows its course; whatever is in the hand (a hold still breaks them). Something standing in front of the
## block (a monster, an animal, a friend) takes the tap instead, like doors.
func _tap_smart(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null:
		return false
	var id := player.world.get_block(hit.position)
	if not PowerRules.is_switch(id) and id != BlockIds.START and id != BlockIds.FINISH:
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	if PowerRules.is_switch(id):
		Session.request_smart_tap(hit.position)
	else:
		course_tapped.emit(hit.position)
	return true

# --- M4 Wave 3, agent I: picking a build ---

## While set, a tap on the world goes here instead (SharePanel picks a build with it); returns true.
var tap_override := Callable()
## Owner #132 (W1): (screen_pos) -> bool: a tap on a discovery crystal or, while its play runs, any tap (its gems; never
## a block placed or broken behind them). DiscoveryDirector.tap through the sandbox; false leaves the tap to the world.
var discovery_tap := Callable()

# --- M3 Task 14a: gadgets and ziplines -----------------------------------------------------------------------

@onready var gadgets: GadgetUser = _add_gadget_user()


func _add_gadget_user() -> GadgetUser:
	var g := GadgetUser.new()
	g.name = "Gadgets"
	g.interactor = self
	add_child(g)
	return g


## A tap on a zipline post within reach asks the host to ride its line (a hold still breaks it). Something
## standing in front of the post takes the tap instead, like doors.
func _tap_zipline(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or player.world.get_block(hit.position) != BlockIds.ZIPLINE_POST:
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	Session.request_zipline(hit.position)
	return true

# --- M3 Task 11: pets with perks ---

## A tap on an animal holding a treat feeds it (the host decides: it tames a fox or a parrot, raises a pet's
## heart; a wild dog or cat also counts it as a pet); a tap on your own pet pats it and opens its card (SIT
## lives on the card now). True when the tap was used here.
func _tap_pet(animal: Animal) -> bool:
	var item := selected_block()
	if item == AnimalRideRules.SADDLE and AnimalRideRules.takes_saddle(animal.species):
		Session.pet_request_saddle(animal.name)   # owner #41: a saddle for a tamed horse or camel (never placed)
		animal.cheer()
		return true
	if PetRules.is_treat(item):
		Session.pet_request_treat(animal.name, item)
		if not animal.is_pet() and PetRules.tames_by_petting(animal.species):
			Session.request_pet(animal.name)   # three pets tame a dog or cat: a treat is one of them
		animal.cheer()
		return true
	if animal.is_pet() and animal.owner_peer == player.peer_id:
		Session.pet_request_pat(animal.name)
		animal.cheer()
		pet_tapped.emit(animal)
		return true
	return false

# --- M3 Task 10: the Gold Farm ------------------------------------------------------------------------------

## The local player tapped the farm's barn within reach: the HUD opens its panel.
signal farm_tapped(building: FarmBuilding)


## A tap on the barn (not through blocks); something standing in front of it (a monster, an animal, a
## friend) takes the tap instead, like doors.
func _tap_farm(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var dir: Vector3 = ray[1]
	var blocked := func(f: Vector3, d: Vector3, dist: float) -> bool: return player.world.raycast(f, d, dist) != null
	var b := FarmBuilding.find(get_tree(), from, dir, player.eye_position(), blocked)
	if b == null:
		return false
	var other := hittable_at(screen_pos, FarmBuilding.TAP_REACH)
	if other != null and from.distance_to(other.global_position) < b.ray_hit(from, dir):
		return false
	farm_tapped.emit(b)
	return true


## The FARM item in the hand: the tapped cell is the middle of the farm's front row, its door facing the
## child; the host checks the ground and says why not.
func _place_farm(hit: BlockHit) -> bool:
	Session.request_farm_place(hit.previous_position, FarmSite.facing_for_forward(Blueprints.facing_for_yaw(player.rig.yaw)))
	return true

# --- M3 Task 8: building tools (paint, LINE, FILL, COPY, REWIND) ---------------------------------------------

## This player is undoing these cells ([pos, id it becomes, id it was], as asked: Build Rewind records them).
signal undoing(changes: Array)

@onready var tools: BuildToolUser = _add_build_tool_user()


func _add_build_tool_user() -> BuildToolUser:
	var t := BuildToolUser.new()
	t.name = "BuildTools"
	t.interactor = self
	add_child(t)
	return t


## The host's answer to this player's tool edits: one undo step, undone through the host's tool log.
func _on_tool_undo_step(step: Array) -> void:
	if not player.is_local:
		return
	var entries: Array = []
	for e: Variant in step:
		if e is Array and (e as Array).size() == 3 and e[0] is Vector3i and e[1] is int and e[2] is int:
			entries.append({"pos": e[0], "old_id": e[1], "new_id": e[2]})
	_undo.push_batch(entries, &"tool")


func _undo_tool(entry: Dictionary) -> bool:
	var changes: Array = []
	for c: Dictionary in entry.batch:
		changes.append([c.pos, c.old_id])
	return Session.request_build_tool(Session.TOOL_UNDO, changes)


## Where the child aims: the screen centre with a crosshair, else the finger resting on the screen (INF: none).
func aim_point() -> Vector2:
	return _screen_center() if crosshair_mode else _preview_point


## An undo entry's cells as [pos, id it becomes, id it was].
static func _undo_cells(entry: Dictionary) -> Array:
	var out: Array = []
	for c: Dictionary in (entry.batch if entry.has("batch") else [entry]):
		out.append([c.pos, c.old_id, c.new_id])
	return out

# --- M3 Task 21b: books and memories ---------------------------------------------------------------------------

## The local player tapped a bookshelf within reach: the HUD opens the books.
signal bookshelf_tapped(cell: Vector3i)
## The local player gave an animal its food from the hand (the Animal Book's FED mark).
signal animal_fed(species: StringName)


## A tap on a bookshelf within reach opens the books, whatever is in the hand (a hold still breaks it); something
## standing in front of it (a monster, an animal, a friend) takes the tap instead, like doors.
func _tap_bookshelf(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or player.world.get_block(hit.position) != BlockIds.BOOKSHELF:
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	bookshelf_tapped.emit(hit.position)
	return true

# --- Spec §23: the Science Lab ---------------------------------------------------------------------------------

## The local player tapped a lab bench within reach: the sandbox opens the Lab.
signal lab_bench_tapped(cell: Vector3i)


## A tap on a lab bench within reach opens the Lab, whatever is in the hand (a hold still breaks it); something standing
## in front of it takes the tap instead, like a bookshelf.
func _tap_lab_bench(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or player.world.get_block(hit.position) != BlockIds.LAB_BENCH:
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	lab_bench_tapped.emit(hit.position)
	return true

# --- Owner #78 (spec §24): the world's wonders ----------------------------------------------------------------------

## The local player tapped a wonder plaque within reach: the sandbox opens the wonder's card (WondersDirector).
signal plaque_tapped(cell: Vector3i)


## A tap on a wonder plaque within reach opens its card, whatever is in the hand (a hold still breaks it); something
## standing in front of it takes the tap instead, like a bookshelf.
func _tap_plaque(screen_pos: Vector2) -> bool:
	var hit := _ray(screen_pos)
	if hit == null or player.world.get_block(hit.position) != BlockIds.WONDER_PLAQUE:
		return false
	if hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false
	plaque_tapped.emit(hit.position)
	return true

# --- M3 Task 21c: building sounds and melody -------------------------------------------------------------------

## Every tap or tool step that places blocks sings one note (BuildMelody; the plain pop with block music off).
@onready var melody: BuildMelody = _add_melody()


func _add_melody() -> BuildMelody:
	var m := BuildMelody.new()
	m.name = "BuildMelody"
	add_child(m)
	return m

# --- M4 ghost races ---

## A stamp was placed at `anchor` facing `forward` (Blueprints): a gift's stamp may bring its sender's race.
signal stamped(stamp: int, anchor: Vector3i, forward: Vector3i)


# --- M3 Task 20b: befriend a monster with the wand ---

## The wand's tap on a monster: the host is asked to befriend it (BuddyMagicDirector decides); a boss is too big
## (this game says so). False when no monster is the first thing under the tap: the ground, a buddy (the wand puts it
## to sleep) or an animal in front is that tap's own.
func _t20b_befriend(screen_pos: Vector2) -> bool:
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var mask := 1 | Buddy.LAYER | Monster.LAYER   # the world's collision, buddies, animals and monsters
	var hit := space_ray(PhysicsRayQueryParameters3D.create(from, to, mask))
	var body := hit.get("collider") as Node3D if not hit.is_empty() else null
	if body == null or not body.is_in_group(&"monsters"):
		return false
	Fx.burst(player.world, hit.position, Color("ff9ec8"), 14, 3.0, 0.1, 0.7, 2.0)
	if body is Monster:
		Session.request_befriend(String(body.name))
	else:
		Session.magic_feedback.emit(BefriendRules.message(BefriendRules.BOSS))
	return true


# --- Owner #37: trading ---

## (screen_pos) -> bool: a tap on another player's name tag opened their card (the TradeDirector sets it; Survivor).
var name_tag_tap: Callable
## Owner #109: (screen_pos) -> bool: a tap on a car got in or loaded it (VehicleDirector.tap_at_screen sets it).
var vehicle_tap: Callable
## Owner #110 (VR round 4, idea 7): (screen_pos) -> bool: a tap on a music block played it (MusicDirector.tap_at_screen
## sets it). Its own hook, before the cars', so the order the directors start in never matters (VR-SOUND's ruling S1).
var music_tap: Callable


# --- VR P5's follow-up (a), owner #101/#110: the physics space read only in the physics step ---------------------------

## Tests: 1 makes this game act as if the physics ran on its own thread (the Quest APK's lever,
## `physics/3d/run_on_separate_thread.quest`, docs/devlog/parts/vr-perf.md), 0 as if not; -1 reads the project setting.
static var physics_thread := -1
## Ray queries made through space_ray (tests), and those asked where the engine would have refused them.
var space_reads := 0
var unreadable_queries := 0


## The physics runs on its own thread (the project setting, or a test's physics_thread).
static func physics_threaded() -> bool:
	if physics_thread >= 0:
		return physics_thread == 1
	return bool(ProjectSettings.get_setting("physics/3d/run_on_separate_thread", false))


## The world's physics space can be read now: always while the physics runs on the main thread (phones, the web, the
## desktop); on its own thread only inside the physics step.
func space_readable() -> bool:
	return _in_step or not physics_threaded() or Engine.is_in_physics_frame()


## Every ray this interactor and SecretTaps ask of the physics space ({} where it can't be read now: never the engine's
## error).
func space_ray(query: PhysicsRayQueryParameters3D) -> Dictionary:
	if not space_readable():
		unreadable_queries += 1
		return {}
	space_reads += 1
	return player.get_world_3d().direct_space_state.intersect_ray(query)


## A tap that may read the physics space (`tap` () -> bool): now when the space can be read, else in the next physics
## step, in the order asked; `done(ok)` hears how it went, at once or then. True when it ran now and was used.
func in_space(tap: Callable, done := Callable()) -> bool:
	if not space_readable():
		_later.append([tap, done])
		return false
	var ok := bool(tap.call())
	if done.is_valid():
		done.call(ok)
	return ok


## Taps waiting for the physics step.
func waiting() -> int:
	return _later.size()


var _later: Array = []
var _in_step := false


func _physics_process(_delta: float) -> void:
	if _later.is_empty():
		return
	var todo := _later
	_later = []
	_in_step = true
	for t: Array in todo:
		var ok := bool((t[0] as Callable).call())
		if (t[1] as Callable).is_valid():
			(t[1] as Callable).call(ok)
	_in_step = false
