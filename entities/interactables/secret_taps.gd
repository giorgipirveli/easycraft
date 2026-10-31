class_name SecretTaps
extends RefCounted
## Taps on secrets (M2 Task 16), checked by BlockInteractor before anything else, whatever is in hand: a
## chest opens (the host decides), a riddle note or the Wanderer shows its riddle, a golden animal is caught
## (the host decides), a fake wall knocks. Things behind a block are out of reach of a tap: a buried chest
## has to be dug out first. Returns true when the tap was used.

const LAYERS := SecretThing.LAYER | Animal.LAYER


static func tap(interactor: BlockInteractor, screen_pos: Vector2) -> bool:
	var player := interactor.player
	if player == null or not player.is_spawned() or player.world == null:
		return false
	var block := interactor.ray_at(screen_pos)
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var hit := interactor.space_ray(PhysicsRayQueryParameters3D.create(from, to, LAYERS))   # VR P5's follow-up (a)
	if not hit.is_empty() and (block == null or block.distance > from.distance_to(hit.position) - 0.05):
		var node := hit.get("collider") as Node
		if node is Animal:
			if not (node as Animal).golden:
				return false          # an ordinary animal: petting, as before
			Session.request_pet(node.name)
			return true
		if node is TreasureChest and (node as TreasureChest).opened and interactor.selected_block() == ItemIds.WAND:
			Session.request_wake_chest(node.name)   # M3 Task 21c: the wand wakes an opened chest (a chest mimic)
			return true
		if node is SecretThing:
			return use(node as SecretThing, interactor.get_tree())
	if block and SecretRules.is_fake_wall(player.world.get_block(block.position)):   # M3 Task 2: fake sandstone too
		Session.request_knock(block.position)
		return true
	return false


## What a tap on a secret thing does.
static func use(thing: SecretThing, tree: SceneTree) -> bool:
	if thing.has_method(&"tapped"):   # M4 I: a friend's bottle opens itself
		return bool(thing.call(&"tapped"))
	if thing is TreasureChest:
		Session.request_open_chest(thing.name)
		return true
	var director := tree.get_first_node_in_group(&"secret_director") as SecretDirector
	var hud: Node = director.hud if director else null
	if hud == null:
		return false
	if thing is RiddleNote:
		hud.call(&"show_note", (thing as RiddleNote).text, (thing as RiddleNote).pictures)
		return true
	if thing is Wanderer:
		var w := thing as Wanderer
		var q := w.question()
		var visitor := String(w.name)
		hud.call(&"show_riddle", q.question, q.choices,
			func(choice: int) -> void: Session.request_wanderer_answer(visitor, choice))
		return true
	if thing.has_method(&"use_tap"):
		return thing.call(&"use_tap", hud)   # owner 42: a ghost's riddle, a wishing well
	return false
