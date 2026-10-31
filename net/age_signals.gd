class_name AgeSignals
extends RefCounted
## The store's age signal (M4 Wave 2, agent F; spec §17.2 "store age signals (Google Play Age
## Signals) mapped to our bands"). This base class is the no-op used on the desktop, in tests and
## wherever the platform has no signal: request() answers &"" at once. AndroidAgeSignals asks Google
## Play through a plugin when the APK has one. Nothing ever waits for an answer: play never blocks,
## and the band only makes things stricter (AgeSignalsRules.stricter, used by OnlineService).

## The answer to request(): our band, or &"" (no signal).
signal answered(band: StringName)

## The last answer (&"" until one came).
var band: StringName = &""


## The right adapter for this platform.
static func for_platform() -> AgeSignals:
	if OS.get_name() == "Android":
		return AndroidAgeSignals.new(AndroidAgeSignals.find_plugin())
	return AgeSignals.new()


func is_available() -> bool:
	return false


## Asks for the signal; `answered` follows (at once here).
func request() -> void:
	_answer(&"")


func _answer(b: StringName) -> void:
	band = b
	answered.emit(b)
