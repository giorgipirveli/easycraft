extends GutTest
## Owner #101 (VR on the Meta Quest), the WebXR route (the plan's ruling 1): a separate web export, "Web VR" (preset.16,
## feature tag "webxr": ENTER VR and the multiview shaders, xr/shaders/enabled.webxr), built by tools/export_web_vr.sh
## into build/web_vr/ and served at /vr/, beside /play/ and outside its service worker's scope, with the same thread
## headers. The flat web build stays exactly as it is: no other preset has the tag, the shaders' switch is off for it.

const KIT := "res://server/deploy/"


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	var out := {}
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			var options := {}
			for key in cfg.get_section_keys(section + ".options"):
				options[key] = cfg.get_value(section + ".options", key)
			var p := {"section": section, "options": options}
			for key in cfg.get_section_keys(section):
				p[key] = cfg.get_value(section, key)
			out[str(cfg.get_value(section, "name"))] = p
	return out


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_the_web_vr_preset_is_the_web_game_with_the_webxr_tag() -> void:
	var presets := _presets()
	assert_has(presets, "Web VR")
	if not presets.has("Web VR"):
		return
	var vr: Dictionary = presets["Web VR"]
	var web: Dictionary = presets["Web"]
	assert_eq(vr.section, "preset.16", "after VR-RIG's Quest presets (14, 15)")
	assert_eq(vr.platform, "Web")
	assert_eq(vr.custom_features, "webxr")
	assert_eq(vr.export_path, "build/web_vr/index.html")
	for key: String in ["export_filter", "exclude_filter", "script_export_mode"]:
		assert_eq(vr[key], web[key], "%s as the flat web game's (the media in their own packs)" % key)
	for key: String in ["variant/thread_support", "html/custom_html_shell", "progressive_web_app/enabled",
			"progressive_web_app/ensure_cross_origin_isolation_headers", "threads/emscripten_pool_size"]:
		assert_eq(vr.options[key], web.options[key], key)
	assert_true(vr.options["vram_texture_compression/for_desktop"], "one pack for a PC's browser")
	assert_true(vr.options["vram_texture_compression/for_mobile"], "and the Quest's (ETC2)")
	var head := str(vr.options["html/head_include"])
	assert_string_contains(head, "navigator.xr", "no full screen on the first tap where WebXR is (ENTER VR is the tap)")
	for pname: String in presets:
		if pname != "Web VR":
			assert_false(str(presets[pname].get("custom_features", "")).contains("webxr"), "%s stays flat" % pname)


func test_the_multiview_shaders_are_on_only_for_the_webxr_build() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	assert_true(bool(cfg.get_value("xr", "shaders/enabled.webxr", false)), "the Web VR export draws both eyes")
	assert_false(bool(cfg.get_value("xr", "shaders/enabled", false)), "phones and /play/ compile no stereo variants")
	assert_false(bool(ProjectSettings.get_setting("xr/shaders/enabled", false)), "this run (no webxr tag)")


func test_the_export_script_builds_build_web_vr_from_the_flat_pipeline() -> void:
	var script := _text("res://tools/export_web_vr.sh")
	assert_ne(script, "")
	for word: String in ["build/web_vr", "\"Web VR\"", "tools/export_web.sh", "EasyCraft-vr-files", "/vr/"]:
		assert_string_contains(script, word)
	var deploy := _text("res://tools/deploy_web_vr.sh")
	assert_string_contains(deploy, "build/web_vr")
	assert_string_contains(deploy, "easycraft/server/deploy/vr")


func test_the_server_serves_vr_beside_play_with_the_thread_headers() -> void:
	var caddy := _text(KIT + "caddy/Caddyfile")
	assert_string_contains(caddy, "redir /vr /vr/ 308")
	var at := caddy.find("handle_path /vr/*")
	assert_gt(at, 0, "its own block, not /play/'s")
	var block := caddy.substr(at, caddy.find("file_server", at) - at)
	assert_string_contains(block, "root * /srv/vr")
	for h: String in ["Cross-Origin-Opener-Policy \"same-origin\"", "Cross-Origin-Embedder-Policy \"require-corp\"",
			"Cross-Origin-Resource-Policy \"same-origin\"", "xr-spatial-tracking=(self)"]:
		assert_string_contains(block, h)
	var compose := _text(KIT + "docker-compose.yml")
	assert_string_contains(compose, "./vr:/srv/vr:ro")
