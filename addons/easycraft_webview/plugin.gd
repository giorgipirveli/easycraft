@tool
extends EditorPlugin
## Adds the EasyCraftWebView Android library (the Shorts Theater's player, M3 Task 17) to Android
## exports. Godot only uses it in presets with "Use Gradle Build" on (the "Android Theater" preset);
## other Android presets export exactly as before, without the player, and the Theater says
## "Coming soon" there. The AARs in bin/ are built from android/plugins/easycraft_webview
## (docs/DEVELOPMENT.md, "Shorts Theater: the Android player plugin").

var _export: EditorExportPlugin


func _enter_tree() -> void:
	_export = EasyCraftWebViewExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class EasyCraftWebViewExport:
	extends EditorExportPlugin

	const NAME := "EasyCraftWebView"

	func _get_name() -> String:
		return NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	## Paths relative to res://addons/. Never in a Quest build (owner #101, #108): an Android View does not show in
	## immersive VR (the TV shows its sign there), so the "quest" presets leave the player out.
	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var preset := get_export_preset()
		if preset != null:
			for feature: String in preset.get_custom_features().split(",", false):
				if feature.strip_edges() == "quest":
					return PackedStringArray()
		if debug:
			return PackedStringArray(["easycraft_webview/bin/debug/%s-debug.aar" % NAME])
		return PackedStringArray(["easycraft_webview/bin/release/%s-release.aar" % NAME])
