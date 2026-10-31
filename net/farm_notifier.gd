class_name FarmNotifier
extends RefCounted
## The Gold Farm's "Your farm is full!" note on the phone (M3 Task 10; spec §5.6). Godot has no local
## notifications of its own: this base class is the no-op used on the desktop, in tests and in an APK
## without the plugin (it only remembers what it was asked). AndroidFarmNotifier rings through an Android
## plugin when the APK has one (M5: ruling in docs/devlog/parts/m3-task-10.md). When and whether a note
## rings is FarmNotifyRules'; this only schedules and cancels the one note.

## The time of the note asked for (unix seconds; 0 = none).
var scheduled_at := 0


## The right notifier for this platform.
static func for_platform() -> FarmNotifier:
	if OS.get_name() == "Android":
		return AndroidFarmNotifier.new(AndroidFarmNotifier.find_plugin())
	return FarmNotifier.new()


func is_available() -> bool:
	return false


## Asks for the note at `at_unix` (replacing one that waits).
func schedule(at_unix: int, title: String, text: String) -> void:
	scheduled_at = at_unix
	_schedule(at_unix, title, text)


## Takes back the note that waits, if any.
func cancel() -> void:
	scheduled_at = 0
	_cancel()


func _schedule(_at_unix: int, _title: String, _text: String) -> void:
	pass


func _cancel() -> void:
	pass
