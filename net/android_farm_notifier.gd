class_name AndroidFarmNotifier
extends FarmNotifier
## "Your farm is full!" on Android (M3 Task 10) through an Android plugin, when the APK has one; otherwise a
## no-op like the base class.
##
## TODO (M5; ruling in docs/devlog/parts/m3-task-10.md): the plugin is not built yet. A note that rings while
## the game is closed needs a BroadcastReceiver (or a WorkManager worker) declared in the APK's manifest, the
## POST_NOTIFICATIONS permission (Android 13+) asked at the moment the switch is turned on, and a Gradle
## build, which the game's main presets are not (only the Theater check preset is). The plugin's contract,
## ready for it: an Android v2 plugin registered as the Engine singleton PLUGIN_NAME with
## scheduleNote(id: int, at_unix: int, title: String, text: String) (an inexact AlarmManager alarm whose
## receiver posts the note on the game's own channel; re-armed after a reboot) and cancelNote(id: int).

const PLUGIN_NAME := "EasyCraftNotes"
const NOTE_ID := 1001             # the farm's one note (a new schedule replaces it)

var _plugin: Object


## The plugin's singleton, or null when this APK has none.
static func find_plugin() -> Object:
	return Engine.get_singleton(PLUGIN_NAME) if Engine.has_singleton(PLUGIN_NAME) else null


func _init(plugin: Object) -> void:
	_plugin = plugin


func is_available() -> bool:
	return _plugin != null and _plugin.has_method("scheduleNote") and _plugin.has_method("cancelNote")


func _schedule(at_unix: int, title: String, text: String) -> void:
	if is_available():
		_plugin.call("scheduleNote", NOTE_ID, at_unix, title, text)


func _cancel() -> void:
	if is_available():
		_plugin.call("cancelNote", NOTE_ID)
