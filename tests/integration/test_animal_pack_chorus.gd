extends GutTest
## Owner feedback #41's animals join owner #50's chorus (one idle-call budget per device, kinds in turn, the nearest
## first): every kind has a measured level; a crowd of the new flock animals (ducks, candy birds, penguins, gummy
## bunnies) never brings back "a lot of chicken sounds only everywhere"; and a wild animal asleep (an owl by day, a
## herd at night) never calls.

var _cam: Camera3D
var _chorus: AnimalChorus
var _calls: Array = []            # [species, sound]


func before_each() -> void:
	Audio.stop_all()
	_calls.clear()
	_cam = Camera3D.new()
	add_child_autofree(_cam)
	_cam.global_position = Vector3(0, 41, 0)
	_cam.current = true
	_chorus = AnimalChorus.new()
	add_child_autofree(_chorus)
	_chorus.set_process(false)
	_chorus.rng.seed = 41
	_chorus.called.connect(func(a: Animal, sound: StringName, _v: float) -> void: _calls.append([a.species, sound]))


func after_all() -> void:
	Audio.stop_all()


func _animal(species: StringName, dist: float, i: int, sitting := false) -> Animal:
	var a := Animal.new()
	var angle := i * 2.39996
	a.setup({"species": species, "id": "k_%s_%d" % [species, i], "pos": Vector3(cos(angle) * dist, 41, sin(angle) * dist),
		"yaw": 0.0, "owner": 0, "name": "", "sitting": sitting})
	add_child_autofree(a)
	a.set_process(false)
	return a


func _step(seconds: float, dt: float = 0.2) -> void:
	var t := 0.0
	while t < seconds:
		_chorus.step(dt)
		t += dt


func test_every_animal_kind_joins_the_chorus_with_a_measured_level() -> void:
	for sp: StringName in AnimalRules.SPECIES:
		assert_true(VoiceRules.CALL_GAIN_DB.has(sp), "%s has a measured level (VoiceRules.CALL_GAIN_DB)" % sp)
		assert_between(VoiceRules.call_gain_db(sp), -12.0, 3.0, "%s: boosts capped at +3 dB" % sp)
	assert_lt(VoiceRules.call_gain_db(&"candy_bird"), -3.0, "candy birds are as loud as the hens: softened like them")


func test_a_crowd_of_the_new_flocks_is_a_calm_mixed_chorus() -> void:
	var i := 0
	for pair: Array in [[&"duck", 8], [&"candy_bird", 6], [&"penguin", 5], [&"gummy_bunny", 4]]:
		for k in int(pair[1]):
			_animal(pair[0], 2.0 + k * 1.5, i)
			i += 1
	_animal(&"horse", 12.0, i)
	_animal(&"goat", 15.0, i + 1)
	_step(600.0)
	var per_min := _calls.size() / 10.0
	assert_between(per_min, 4.0, 10.0, "idle calls a minute: %.1f" % per_min)
	var count := {}
	for c in _calls:
		count[c[0]] = int(count.get(c[0], 0)) + 1
	for kind: StringName in count:
		assert_lte(float(count[kind]) / _calls.size(), 0.3, "no kind takes over: %s" % [count])
	for kind: StringName in [&"duck", &"candy_bird", &"penguin", &"gummy_bunny", &"horse", &"goat"]:
		assert_true(count.has(kind), "the %s is heard: %s" % [kind, count])
	gut.p("calls a minute %.1f, by kind %s" % [per_min, count])


func test_a_wild_animal_asleep_never_calls() -> void:
	_animal(&"owl", 4.0, 0, true)       # asleep in the daytime
	_animal(&"horse", 14.0, 1)
	_step(300.0)
	var kinds := {}
	for c in _calls:
		kinds[c[0]] = true
	assert_false(kinds.has(&"owl"), "the sleeping owl is quiet")
	assert_true(kinds.has(&"horse"), "the horse still calls")


func test_the_new_kinds_call_in_their_own_real_voices() -> void:
	var files: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for sp: StringName in [&"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle", &"squirrel", &"owl",
			&"hedgehog", &"camel", &"lizard", &"fennec", &"penguin", &"polar_bear", &"arctic_fox", &"seal", &"gummy_bunny",
			&"candy_bird", &"fox", &"parrot"]:
		var takes: Array = files.get(VoiceRules.animal_call(sp), [])
		assert_gte(takes.size(), 2, "%s: two or three takes so it never repeats" % sp)
		for path: String in takes:
			assert_true(path.ends_with(".ogg"), "%s: a recording" % path)
		assert_ne(VoiceRules.animal_hurt(sp), VoiceRules.animal_call(sp), "%s cries out in its own hurt voice" % sp)
	assert_false((files[&"yip"] as Array).has("res://assets/audio/sfx/dog_2.ogg"), "the fox no longer barks like a dog")
	assert_false((files[&"squawk"] as Array).has("res://assets/audio/sfx/chicken_3.ogg"), "nor the parrot clucks")
