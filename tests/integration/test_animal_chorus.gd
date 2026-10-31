extends GutTest
## Owner feedback #50 ("please improve sounds, now there is a lot chicken sounds only everywhere"): real
## Animal nodes around this device's listener (a camera), and one AnimalChorus that chooses their idle
## calls (AnimalChorusRules). 20 chickens and 5 other animals make a calm, mixed chorus; the animals never
## call on their own any more; a child's own animal voice (petting, a hit) is never blocked.

const OTHERS := [[&"cow", 5.0], [&"sheep", 8.0], [&"pig", 11.0], [&"dog", 14.0], [&"cat", 17.0]]

var _cam: Camera3D
var _chorus: AnimalChorus
var _calls: Array = []            # [species, sound, volume_db, distance]


func before_each() -> void:
	Audio.stop_all()
	_calls.clear()
	_cam = Camera3D.new()
	add_child_autofree(_cam)
	_cam.global_position = Vector3(0, 41, 0)
	_cam.current = true
	_chorus = AnimalChorus.new()
	add_child_autofree(_chorus)
	_chorus.set_process(false)    # the test steps it: minutes in a moment
	_chorus.rng.seed = 11
	_chorus.called.connect(func(a: Animal, sound: StringName, volume_db: float) -> void:
		_calls.append([a.species, sound, volume_db, a.global_position.distance_to(_cam.global_position)]))


func after_all() -> void:
	Audio.stop_all()


func _animal(species: StringName, dist: float, i: int) -> Animal:
	var a := Animal.new()
	var angle := i * 2.39996   # spread round the listener
	a.setup({"species": species, "id": "c_%s_%d" % [species, i], "pos": Vector3(cos(angle) * dist, 41, sin(angle) * dist),
		"yaw": 0.0, "owner": 0, "name": "", "sitting": false})
	add_child_autofree(a)
	a.set_process(false)          # its own _process (animation, thoughts) is not what is tested here
	return a


## 20 chickens 2-18 blocks away, a cow, a sheep, a pig, a dog and a cat.
func _crowd() -> Array[Animal]:
	var out: Array[Animal] = []
	for i in 20:
		out.append(_animal(&"chicken", 2.0 + i * 0.8, i))
	for k in OTHERS.size():
		out.append(_animal(OTHERS[k][0], OTHERS[k][1], 20 + k))
	return out


func _step(seconds: float, dt: float = 0.2) -> void:
	var t := 0.0
	while t < seconds:
		_chorus.step(dt)
		t += dt


func test_twenty_chickens_and_five_other_animals_make_a_calm_mixed_chorus() -> void:
	_crowd()
	_step(600.0)
	var per_min := _calls.size() / 10.0
	assert_between(per_min, 4.0, 10.0, "idle calls a minute: %.1f (before: every animal its own 8-20 s timer, ~100)" % per_min)
	var count := {}
	for i in _calls.size():
		count[_calls[i][0]] = int(count.get(_calls[i][0], 0)) + 1
		if i > 0:
			assert_ne(_calls[i][0], _calls[i - 1][0], "never the same kind twice in a row")
	var share := float(count.get(&"chicken", 0)) / maxf(_calls.size(), 1)
	assert_lte(share, 0.3, "chickens are 20 of 25 animals but %.0f%% of the calls: %s" % [share * 100.0, count])
	for pair in OTHERS:
		assert_true(count.has(pair[0]), "the %s is heard too: %s" % [pair[0], count])
	gut.p("calls a minute %.1f, by kind %s" % [per_min, count])


func test_a_call_is_heard_through_audio_in_the_animals_own_voice() -> void:
	var cow := _animal(&"cow", 4.0, 0)
	var heard := []
	var on_sound := func(sound: StringName, at: Vector3, volume_db: float) -> void: heard.append([sound, at, volume_db])
	Audio.sound_played.connect(on_sound)
	_step(3.0)
	Audio.sound_played.disconnect(on_sound)
	assert_eq(heard.size(), 1, "one call: %s" % [heard])
	if heard.size() == 1:
		assert_eq(heard[0][0], &"moo")
		assert_eq(heard[0][1], cow.global_position, "at the cow")
		assert_almost_eq(float(heard[0][2]), AnimalChorusRules.volume_db(&"cow", 4.0), 0.001)
		assert_almost_eq(float(Audio.last_voice_pitch), cow.voice(), 0.001, "in its own voice")


func test_every_call_is_as_loud_as_its_kind_and_distance_say() -> void:
	_crowd()
	_step(600.0)
	assert_gt(_calls.size(), 20)
	for c in _calls:
		assert_almost_eq(float(c[2]), AnimalChorusRules.volume_db(c[0], c[3]), 0.01,
			"%s %.1f blocks away: farther is quieter, chickens evened out" % [c[0], c[3]])


func test_the_listener_is_this_devices_camera() -> void:
	_crowd()
	_cam.global_position = Vector3(200, 41, 0)   # another player may stand among them; this device is far
	_step(120.0)
	assert_eq(_calls.size(), 0, "nobody within 20 blocks of this device's camera: quiet")
	_cam.global_position = Vector3(0, 41, 0)
	_step(12.0)
	assert_gt(_calls.size(), 0, "walk up to them: they are heard")


func test_animals_never_call_on_their_own() -> void:
	var hens := _crowd()
	_chorus.queue_free()
	var before: int = Audio.played + Audio.dropped
	for i in 300:   # 30 s of every animal's own _process
		for a in hens:
			a._process(0.1)
	assert_eq(Audio.played + Audio.dropped, before, "only the chorus chooses idle calls")


func test_a_childs_own_animal_voice_is_never_blocked() -> void:
	var hens := _crowd()
	_step(30.0)
	assert_gt(_calls.size(), 0)
	var hen := hens[0]
	var before: int = Audio.played
	hen.cheer()                   # petted: happy, right after the chorus spent its budget
	assert_eq(Audio.played, before + 1, "the petted chicken clucks at once")
	assert_eq(Audio.last_sound, VoiceRules.animal_happy(&"chicken"))
	hen.knockback(Vector3(2, 0, 0))   # hit: it cries out at once
	assert_eq(Audio.played, before + 2)
	assert_eq(Audio.last_sound, VoiceRules.animal_hurt(&"chicken"))
	var n := _calls.size()
	_step(AnimalChorusRules.AFTER_VOICE - 0.4)
	assert_eq(_calls.size(), n, "and the chorus keeps quiet a moment after it")
	_step(40.0)
	assert_gt(_calls.size(), n, "then the chorus goes on")


func test_the_same_take_never_plays_twice_in_a_row() -> void:
	var last := -1
	for i in 60:
		Audio.stop_all()          # no burst cap between these test plays
		Audio.play(&"cluck", Vector3(0, 41, 2))
		assert_ne(Audio.last_take, last, "play %d repeated take %d" % [i, last])
		last = Audio.last_take
