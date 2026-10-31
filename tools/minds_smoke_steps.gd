extends Node
## The steps of tools/minds_smoke.gd (M2 Task 18), in a new Sandbox world on real terrain: animals near
## the player have minds and act; a treat through the host's request makes one like the player (and a
## heart shows over it); at night the herds lie down, in the morning they get up; the world saves what the
## species learned. Prints what the animals were doing.

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _fed: Animal
var _actions := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
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


func _minded(sandbox: Node, p: Player) -> Array[Animal]:
	var out: Array[Animal] = []
	for n in (sandbox.get("_animals") as Node).get_children():
		var a := n as Animal
		if a and a.mind and not a.is_pet() and a.global_position.distance_to(p.global_position) < 32.0:
			out.append(a)
	return out


func _run_step(sandbox: Node, p: Player) -> void:
	var animals := _minded(sandbox, p)
	match _step:
		0:   # animals around, thinking
			var acting := animals.filter(func(a: Animal) -> bool: return a.mind_action() != &"")
			if acting.size() >= 3 or (_step_t > 60.0 and not acting.is_empty()):
				for a: Animal in acting:
					_actions[a.mind_action()] = int(_actions.get(a.mind_action(), 0)) + 1
				_check(true, "%d animals near the player have minds and act: %s" % [acting.size(), _actions])
				_next()
			elif _step_t > 60.0:
				_check(false, "no animal with a mind near the player after 60 s (%d near)" % animals.size())
				_finish()
		1:   # walk up to the nearest one and give it a treat through the host's request
			animals.sort_custom(func(a: Animal, b: Animal) -> bool:
				return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
			_fed = animals[0]
			var to := _fed.global_position - p.global_position
			to.y = 0.0
			p.global_position = _fed.global_position - to.normalized() * 2.0 + Vector3(0, 0.3, 0)
			p.velocity = Vector3.ZERO
			_next()
		2:
			if _step_t < 0.3:
				return
			Session.mind_request_treat(_fed.name)
			var who := Animal.mind_name(p)
			_check(_fed.mind.memory.like(who) >= 0.5, "%s likes %s after a treat (%.2f)" % [_fed.animal_id, who, _fed.mind.memory.like(who)])
			_next()
		3:
			if _fed.thought == Thought.HEART and _fed.get_node_or_null("Thought") != null:
				_check(true, "a heart shows over %s (a bubble node on it)" % _fed.animal_id)
				_next()
			elif _step_t > 8.0:   # a reaction waits Mind.REACTION_GAP after its last thought; the mind ticks slower under load
				_check(false, "no heart over %s (thought %d)" % [_fed.animal_id, _fed.thought])
				_next()
		4:   # night: herds lie down
			sandbox.call(&"set_time_of_day", 0.95)
			_next()
		5:
			var asleep := animals.filter(func(a: Animal) -> bool: return a.sitting and a.mind_action() == AnimalSpecies.SLEEP)
			if animals.size() > 0 and asleep.size() * 2 >= animals.size():
				_check(true, "at night %d of %d animals near the player sleep (%.0f s)" % [asleep.size(), animals.size(), _step_t])
				_next()
			elif _step_t > 45.0:
				_check(false, "at night only %d of %d animals sleep after 45 s" % [asleep.size(), animals.size()])
				_next()
		6:   # morning: up they get
			sandbox.call(&"set_time_of_day", 0.3)
			_next()
		7:
			if _step_t < 2.0:
				return
			var still := animals.filter(func(a: Animal) -> bool: return a.sitting)
			_check(still.is_empty(), "in the morning nobody still lies down (%d do)" % still.size())
			_next()
		8:   # the world saves what the species learned
			sandbox.call(&"save_world")
			var meta: WorldMeta = sandbox.get("meta")
			var key := "animal:%s" % _fed.species
			_check(meta.minds.has(key), "the world saved the %s table (%s)" % [_fed.species, meta.minds.keys()])
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MINDS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MINDS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	get_tree().quit(0 if _fails.is_empty() else 1)
