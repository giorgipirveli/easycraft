class_name MonsterChorus
extends Node
## The monsters' idle voices on this device (M5 Task 2, spec §15.2; like owner #50's AnimalChorus). One per world,
## on every peer (the sandbox adds it; cosmetic, nothing is sent). When MonsterChorusRules says a voice is due, it
## looks at the monsters within its RADIUS of this device's listener (the current camera) and plays the chosen
## one's idle voice (VoiceRules.monster_idle: a grunt, a squish, a moan...) at its place. Monsters no longer speak
## on their own timers. A cry when a hit lands, or the growl of a monster spotting a child, is never held back:
## hearing one lets that kind rest (MonsterChorusRules.heard). A bat asleep under a ceiling is quiet.

signal called(monster: Monster, sound: StringName, volume_db: float)

var rules := MonsterChorusRules.new()
var rng := RandomNumberGenerator.new()

var _now := 0.0
var _calling := false
var _voices := {}                 # a cry or a spotting growl -> its kind


func _ready() -> void:
	rng.randomize()
	for kind: StringName in MonsterRules.KINDS:
		var hurt := VoiceRules.monster_hurt(kind)
		if hurt != &"hit":            # the weapons' own hit is no voice
			_voices[hurt] = kind
		if MonsterRules.behaviour(kind) != MonsterRules.JUMPER:   # a jumper's squish is also every hop's sound
			_voices[StringName(MonsterRules.KIND[kind].sound)] = kind
	Audio.sound_played.connect(_on_sound)


func _process(delta: float) -> void:
	step(delta)


## This chorus's clock (seconds of steps).
func now() -> float:
	return _now


## `delta` seconds of the chorus (tests step it directly). The monsters are looked at only when a voice is due.
func step(delta: float) -> void:
	_now += delta
	if _now < rules.next_time():
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var candidates: Array = []
	var near: Array[Monster] = []
	if cam:
		var at := cam.global_position
		for m in Monster.all_monsters():
			if m.is_queued_for_deletion() or m.perched or m.hp <= 0:
				continue
			var d := m.global_position.distance_to(at)
			if d <= MonsterChorusRules.RADIUS:
				candidates.append({"kind": m.kind, "dist": d})
				near.append(m)
	var i := rules.next_call(_now, candidates, rng)
	if i < 0:
		return
	var m := near[i]
	var sound := VoiceRules.monster_idle(m.kind)
	var volume := MonsterChorusRules.volume_db(m.kind, float(candidates[i].dist))
	_calling = true
	Audio.play(sound, m.global_position, volume)
	_calling = false
	called.emit(m, sound, volume)


func _on_sound(sound: StringName, at: Vector3, _volume_db: float) -> void:
	if _calling or not at.is_finite() or not _voices.has(sound):
		return
	rules.heard(_voices[sound], _now)
