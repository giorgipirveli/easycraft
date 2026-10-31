class_name FlightSounds
extends RefCounted
## The rocket engine's roar (owner #79, spec §25.3): our own sound (tools/make_flight_sounds.py: a second of deep
## rumbling noise that loops without a click, assets/flight/engine_roar.wav, imported as a forward loop). RocketFlight
## plays it louder and higher as the fire grows. (Made at run time on a worker thread before: a task's callable left for
## the engine's shutdown aborted the game at exit.)

const ENGINE := "res://assets/flight/engine_roar.wav"


static func engine() -> AudioStream:
	return load(ENGINE)
