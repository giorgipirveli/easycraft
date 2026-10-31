class_name AndroidAgeSignals
extends AgeSignals
## Google Play Age Signals on Android (M4 Wave 2, agent F; spec §17.2) through an Android plugin,
## when the APK has one; otherwise a no-op like the base class.
##
## TODO (ruling 9 in docs/devlog/parts/m4-f.md): the plugin is not built yet. The API is a Play
## library (com.google.android.play:age-signals, a Task-based call on AgeSignalsManager) that only a
## Gradle build can add, and the game's main presets are not Gradle builds. The plugin's contract,
## ready for it: an Android v2 plugin registered as the Engine singleton PLUGIN_NAME with a method
## requestAgeSignals() that calls AgeSignalsManagerFactory.create(context).checkAgeSignals(...) and
## emits the signal age_signals_result(json: String), where json is
## {"age_lower": int|null, "age_upper": int|null, "source": "TIER_A"...|null} or "" on an error or
## when the store has no signal (AgeSignalsRules.band_from_json maps it).

const PLUGIN_NAME := "EasyCraftAgeSignals"
const PLUGIN_SIGNAL := "age_signals_result"
const PLUGIN_METHOD := "requestAgeSignals"

var _plugin: Object


## The plugin's singleton, or null when this APK has none.
static func find_plugin() -> Object:
	return Engine.get_singleton(PLUGIN_NAME) if Engine.has_singleton(PLUGIN_NAME) else null


func _init(plugin: Object) -> void:
	_plugin = plugin
	if is_available() and not _plugin.is_connected(PLUGIN_SIGNAL, _on_result):
		_plugin.connect(PLUGIN_SIGNAL, _on_result)


func is_available() -> bool:
	return _plugin != null and _plugin.has_method(PLUGIN_METHOD) and _plugin.has_signal(PLUGIN_SIGNAL)


func request() -> void:
	if not is_available():
		_answer(&"")
		return
	_plugin.call(PLUGIN_METHOD)


func _on_result(json: String) -> void:
	_answer(AgeSignalsRules.band_from_json(json))
