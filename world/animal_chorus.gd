class_name AnimalChorus
extends Node
## The animals' idle calls on this device (owner feedback #50: "a lot chicken sounds only everywhere").
## One per world, on every peer (the sandbox adds it; cosmetic, nothing is sent). When AnimalChorusRules
## says a call is due, it looks at the animals within its RADIUS of this device's listener (the current
## camera, never another player: a LAN guest does not hear the herds round the host) and plays the chosen
## one's call at its place, in its own voice, as loud as its kind and distance say. Animals no longer call on
## their own. Every animal voice this device hears that the chorus did not choose (a hurt cry, a happy
## purr: a child's own action, never blocked) lets that kind rest (AnimalChorusRules.heard).

signal called(animal: Animal, sound: StringName, volume_db: float)

var rules := AnimalChorusRules.new()
var rng := RandomNumberGenerator.new()

var _now := 0.0                   # this chorus's clock (seconds of steps)
var _calling := false
var _voices := {}                 # an animal voice (call, hurt, happy) -> its species


func _ready() -> void:
	rng.randomize()
	for species: StringName in AnimalRules.SPECIES:
		for sound: StringName in [VoiceRules.animal_call(species), VoiceRules.animal_hurt(species),
				VoiceRules.animal_happy(species)]:
			_voices[sound] = species
	_voices.erase(&"splash_small")   # also a player's splash: not an animal's voice
	Audio.sound_played.connect(_on_sound)


func _process(delta: float) -> void:
	step(delta)


## `delta` seconds of the chorus (tests step it directly).
func step(delta: float) -> void:
	_now += delta
	if _now < _due():
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var candidates: Array = []
	var animals: Array[Animal] = []
	if cam:
		var at := cam.global_position
		for n in get_tree().get_nodes_in_group(&"animals"):
			var a := n as Animal
			if a == null or a.is_queued_for_deletion():
				continue
			if a.sitting and not a.is_pet():
				continue                  # owner #41: a wild animal asleep (an owl by day, a herd at night) is quiet
			var d := a.global_position.distance_to(at)
			if d <= AnimalChorusRules.RADIUS:
				candidates.append({"kind": a.species, "dist": d})
				animals.append(a)
	var i := rules.next_call(_now, candidates, rng)
	if i < 0:
		return
	var a := animals[i]
	var sound := VoiceRules.animal_call(a.species)
	var volume := AnimalChorusRules.volume_db(a.species, float(candidates[i].dist))
	_calling = true
	Audio.play(sound, a.global_position, volume, a.voice())
	_calling = false
	called.emit(a, sound, volume)


## When the rules take the next look (the group is walked only then: once a second at most).
func _due() -> float:
	return rules.next_time()


func _on_sound(sound: StringName, at: Vector3, _volume_db: float) -> void:
	if sound == BabbleRules.SOUND:   # M3 Task 21a: a babble voice talks; the animals keep quiet a moment
		rules.heard(sound, _now)
		return
	if _calling or not at.is_finite() or not _voices.has(sound):
		return
	rules.heard(_voices[sound], _now)
