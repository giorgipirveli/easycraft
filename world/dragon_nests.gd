class_name DragonNests
extends Node
## Dragon eggs in the Dragon Realm's nests (owner feedback #39, spec §14.2a). A nest is the realm's sky-island secret
## with an `egg` cell (DragonSecretRules); the SecretDirector brings the egg (a DragonEgg secret thing) near players
## while its nest's egg has not hatched. The sandbox adds this node on every game, always named "DragonNests".
## Host: a tap on an egg (Session.egg_hatch_requested) within reach hatches it once per world (SecretState.opened
## keeps "egg_<secret id>"): every game sees it crack, the egg goes, and a baby dragon comes out as the tapper's pet
## (saved with the world's pets, id "dragon_<secret id>"). Nothing here changes a block.

const REACH := PlacementRules.REACH + PlacementRules.REACH_TOLERANCE
const TOO_FAR := "Come closer to the egg!"
const HATCHED := "A baby dragon hatched! %s is your pet now. It flies with you!"

## Host: (egg_name) -> DragonEgg (the SecretDirector's thing), null when it isn't here.
var eggs: Callable = func(_egg_name: String) -> DragonEgg: return null
## Host: (data) -> Animal: the sandbox's animal spawner.
var spawn: Callable = func(_data: Dictionary) -> Animal: return null
## Host: tell(peer, text).
var tell: Callable = func(peer_id: int, text: String) -> void: Session.send_feedback(peer_id, text)
## Host: the world's secret state (the SecretDirector's).
var state := SecretState.new()


## Is there an egg in this nest (a secret with an egg cell whose egg has not hatched)?
static func has_egg(secret: Dictionary, secret_state: SecretState) -> bool:
	return secret.has("egg") and not secret_state.opened.has(key_of(str(secret.get("id", ""))))


static func key_of(secret_id: String) -> String:
	return "egg_" + secret_id


## Host: `peer` tapped the egg `egg_name`.
func hatch(peer: int, egg_name: String) -> void:
	var egg: DragonEgg = eggs.call(egg_name)
	var p := Session._player_for_peer(peer)
	if egg == null or p == null or not is_instance_valid(egg) or egg.is_queued_for_deletion():
		return
	var key := key_of(egg.secret_id)
	if state.opened.has(key):
		return
	if not PlacementRules.in_reach(p.eye_position(), egg.cell(), REACH):
		tell.call(peer, TOO_FAR)
		return
	state.opened[key] = true
	if egg.is_inside_tree() and multiplayer.has_multiplayer_peer():
		egg.hatch_fx.rpc()
	var pet_name := PetRules.first_name(PetRules.DRAGON, "dragon_" + egg.secret_id)
	spawn.call({"species": PetRules.DRAGON, "id": "dragon_" + egg.secret_id, "pos": egg.global_position + Vector3(0, 0.3, 0),
		"yaw": egg.rotation.y, "owner": peer, "name": pet_name, "sitting": false, "collar": PetRules.OWNER_COLOUR,
		"happiness": PetRules.HAPPY_START})
	egg.queue_free()
	tell.call(peer, tr(HATCHED) % pet_name)
	Session.progress_tell(peer, StringName("%s/%s" % [LevelRules.TAMED, PetRules.DRAGON]))   # M3 Task 12
