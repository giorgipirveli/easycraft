extends Node
## The steps of tools/pets_smoke.gd (M3 Task 11), in a new Sandbox world on real terrain, through the same
## requests a child's taps send: three pets tame a dog; two treats tame a fox and a parrot; Pip comes from the
## profile; a name from the list and a collar colour; a treat raises the heart; a summoned monster makes the dog
## bark; a coin near the dog flies to the child; the parrot repeats the child's own line (and points at a secret
## if one is near); at night one light sits on Pip; the world saves the pets (never Pip) and the profile keeps Pip.

const TIMEOUT := 120.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _dog: Animal
var _fox: Animal
var _parrot: Animal
var _coin: Coin
var _heart := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Profile.data.pip = {}
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _summon(sandbox: Node, species: StringName, p: Player) -> Animal:
	var before := {}
	for a: Animal in sandbox.call(&"_animal_nodes"):
		before[a] = true
	var said: String = sandbox.call(&"summon_animal", species, p.global_position)
	for a: Animal in sandbox.call(&"_animal_nodes"):
		if not before.has(a) and a.species == species:
			return a
	_check(false, "no %s came (%s)" % [species, said])
	return null


func _run_step(sandbox: Node, p: Player) -> void:
	var pets: PetDirector = sandbox.get("pets")
	match _step:
		0:   # three quick pets tame a dog
			if _step_t < 1.0:
				return
			_dog = _summon(sandbox, &"dog", p)
			if _dog == null:
				_finish()
				return
			for i in 3:
				Session.request_pet(_dog.name)
			_check(_dog.owner_peer == p.peer_id, "three pets tamed the dog: %s" % _dog.pet_name)
			_next()
		1:   # two treats tame a fox and a parrot
			_fox = _summon(sandbox, &"fox", p)
			_parrot = _summon(sandbox, &"parrot", p)
			for a: Animal in [_fox, _parrot]:
				if a == null:
					continue
				var treat := PetRules.favourite(a.species)
				Session.pet_request_treat(a.name, treat)
				var one := a.is_pet()
				Session.pet_request_treat(a.name, treat)
				_check(not one and a.owner_peer == p.peer_id, "two treats tamed the %s: %s" % [a.species, a.pet_name])
			_next()
		2:   # Pip comes from the profile
			PetRules.give_pip(Profile.data)
			sandbox.call(&"bring_pip")
			_next()
		3:
			var pip := pets.pip_of(p.peer_id)
			if pip:
				_check(pip.pet_name == "Pip" and pip.global_position.distance_to(p.global_position) < 6.0,
					"Pip came to the child (%.1f blocks)" % pip.global_position.distance_to(p.global_position))
				_next()
			elif _step_t > 3.0:
				_check(false, "no Pip")
				_next()
		4:   # a name and a collar through the host's checks
			Session.pet_request_name(_dog.name, "Mochi")
			Session.pet_request_collar(_dog.name, 4)
			_dog._process(0.016)
			var band := _dog.find_child("Collar", true, false) as MeshInstance3D
			_check(_dog.pet_name == "Mochi", "the dog is called %s" % _dog.pet_name)
			_check(_dog.collar == 4 and band and (band.material_override as StandardMaterial3D).albedo_color == PetRules.COLLARS[4],
				"its collar is colour 4")
			_heart = _dog.happiness
			Session.pet_request_treat(_dog.name, ItemIds.TREAT_BISCUIT)
			_check(_dog.happiness > _heart, "a biscuit raised its heart %.2f -> %.2f" % [_heart, _dog.happiness])
			_next()
		5:   # a monster comes: the dog barks
			var said: String = sandbox.call(&"summon_monster", &"slime", 1, p.global_position)
			_check(said == "", "a slime came (%s)" % said)
			_next()
		6:
			if _dog.mark_shown():
				_check(true, "the dog barked, a '!' over it (%.1f s)" % _step_t)
				_next()
			elif _step_t > 3.0:
				_check(false, "the dog did not bark")
				_next()
		7:   # a coin near the dog flies to the child
			(sandbox.get("_monsters") as MonsterDirector).puff_all()
			var away := _dog.global_position - p.global_position
			away.y = 0.0
			var at := _dog.global_position + (away.normalized() if away.length() > 0.1 else Vector3.RIGHT) * 3.0 + Vector3(0, 1, 0)
			var list: Array[Coin] = (sandbox.get("_monsters") as MonsterDirector).spawn_coins(at, 1)
			_coin = list[0] if not list.is_empty() else null
			_next()
		8:
			if _coin == null or not is_instance_valid(_coin) or _coin.collector == p.peer_id:
				_check(true, "a coin near the dog flew to the child (%.1f s)" % _step_t)
				_next()
			elif _step_t > 4.0:
				_check(false, "the coin stayed (landed %s, %.1f blocks from the dog)" % [_coin.is_landed(),
					_coin.global_position.distance_to(_dog.global_position)])
				_next()
		9:   # the parrot repeats the child's own words (this game only)
			var hud: Hud = sandbox.get("hud")
			hud.chat.own_line_sent.emit("Hello!")
			_next()
		10:
			if _parrot and _parrot.bubble_text() == "Squawk! Hello!":
				_check(true, "the parrot said: %s" % _parrot.bubble_text())
				_next()
			elif _step_t > 3.0:
				_check(false, "the parrot said nothing (%s)" % (_parrot.bubble_text() if _parrot else "no parrot"))
				_next()
		11:   # a secret near? the parrot points at it
			var secrets: Array[Vector3] = sandbox.call(&"_unfound_secrets", _parrot.global_position, PetPerks.POINT_RANGE)
			if secrets.is_empty():
				print("PETS_SMOKE skip no secret within %d blocks of the parrot" % PetPerks.POINT_RANGE)
				_step += 2
				_step_t = 0.0
				return
			_parrot.point_t = 0.05
			_next()
		12:
			if _parrot.pointing():
				_check(true, "the parrot points at a secret")
				_next()
			elif _step_t > 2.0:
				_check(false, "the parrot did not point")
				_next()
		13:   # night: one light on the glowing pet nearest the child (Pip)
			sandbox.call(&"set_time_of_day", 0.95)
			_next()
		14:
			if _step_t < 1.0:
				return
			var target := pets.glow_target()
			var seen: Array = []
			for a: Animal in pets.all_pets():
				seen.append("%s %.1f" % [a.species, a.global_position.distance_to(p.global_position)])
			_check(target != null and target.species == PetRules.PIP and pets.glow.visible,
				"at night one light sits on %s (night %s, underground %.2f, pets %s)" % [target.species if target else "nothing",
				pets.is_night.call(), pets.underground.call(), seen])
			_check(sandbox.find_children("*", "OmniLight3D", true, false).filter(func(n: Node) -> bool: return n.name == "PetGlow").size() == 1,
				"one pet light in the whole world")
			_next()
		15:   # saves: the world keeps its pets (not Pip), the profile keeps Pip
			sandbox.call(&"save_world")
			var meta: WorldMeta = sandbox.get("meta")
			var kinds: Array = []
			for e: Dictionary in meta.pets:
				kinds.append(e.species)
			_check(kinds.has("dog") and kinds.has("fox") and kinds.has("parrot") and not kinds.has("pip"),
				"the world saved %s" % [kinds])
			for e: Dictionary in meta.pets:
				if e.species == "dog":
					_check(int(e.collar) == 4 and e.name == "Mochi", "with the dog's name and collar")
			_check(not Profile.data.pip.is_empty(), "the profile keeps Pip: %s" % [Profile.data.pip])
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("PETS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PETS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	get_tree().quit(0 if _fails.is_empty() else 1)
