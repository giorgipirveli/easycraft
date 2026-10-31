class_name VoidWatch
extends Node
## The Dragon Realm's void on the host (owner feedback #39, spec §14.2a): a few times a second, every monster below
## DragonRules.RESCUE_Y puffs away (MonsterDirector.puff: no gold, a little cloud), and every animal, pet, bot friend
## and living buddy down there comes back next to its child (or next to the world spawn when it has none, or its
## child is not standing safely) with its fall stopped: never lost. Players carry themselves back (Player.carry_back).
## World access is injected, so tests use stubs.

const EVERY := 0.25

## The world's line (DragonRules.rescue_y: the Dragon Realm's RESCUE_Y, Venus's far over its clouds).
var line := DragonRules.RESCUE_Y
var monsters: Callable     # () -> Array: the monsters (Node3D)
var puff: Callable         # (monster: Node3D) -> void
var friends: Callable      # () -> Array: animals, bot friends and buddies (Node3D, with `velocity`)
var child_of: Callable     # (body: Node3D) -> Vector3: its child's feet while standing safely, else Vector3.INF
var spawn_feet: Callable   # () -> Vector3: the feet on the world spawn's ground

var _t := 0.0
var _returned := 0          # each one back gets the next spot of the ring round its child


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = EVERY
	check()


## One look: how many bodies below the line were puffed away or brought back.
func check() -> int:
	var n := 0
	for m: Variant in monsters.call():
		var monster := m as Node3D
		if is_instance_valid(monster) and not monster.is_queued_for_deletion() \
				and DragonRules.fell_into_void(monster.global_position.y, line):
			puff.call(monster)
			n += 1
	for f: Variant in friends.call():
		var body := f as Node3D
		if not is_instance_valid(body) or body.is_queued_for_deletion() \
				or not DragonRules.fell_into_void(body.global_position.y, line):
			continue
		var child: Vector3 = child_of.call(body)
		body.global_position = DragonRules.return_spot(child, child.is_finite(), spawn_feet.call(), _returned)
		_returned += 1
		if "velocity" in body:
			body.set("velocity", Vector3.ZERO)
		n += 1
	return n
