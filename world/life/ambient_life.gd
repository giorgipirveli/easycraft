class_name AmbientLife
extends Node3D
## Owner #94 (the animations brief §2): the meadow's sky life round this game's player (MeadowInsects' pattern, one of
## each per screen): fireflies at night over the grass (Fireflies), a flock of birds circling high by day (Birds).
## LifeRules says when, four times a second; every frame only follows the player (and moves the flying birds). The
## sandbox adds it where bees and butterflies fly (a universe with "insects"). Nothing is sent over the network.

const CHECK_EVERY := 0.25

## This game's player (the life follows it).
var player: Node3D
## () -> float: the time of day (DayCycle).
var time_of_day: Callable = func() -> float: return DayCycle.NOON
## () -> float: how far underground this game's player is, 0..1 (Ambience.underground).
var underground: Callable = func() -> float: return 0.0
## () -> int: the block under this game's player's feet.
var ground: Callable = func() -> int: return BlockIds.GRASS

var fireflies := Fireflies.new()
var birds := Birds.new()
var _check_t := 0.0


func _ready() -> void:
	add_child(fireflies)
	add_child(birds)


func _process(delta: float) -> void:
	tick(delta)


## Every frame: follow the player and fly; four times a second: is it their time and place?
func tick(delta: float) -> void:
	if not is_instance_valid(player):
		fireflies.set_on(false)
		birds.set_on(false)
		return
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = CHECK_EVERY
		var t := float(time_of_day.call())
		var under := float(underground.call())
		fireflies.set_on(LifeRules.fireflies_on(t, under, int(ground.call())))
		birds.set_on(LifeRules.birds_on(t, under))
	var feet := player.global_position
	fireflies.follow(feet)
	birds.step(delta, feet)
