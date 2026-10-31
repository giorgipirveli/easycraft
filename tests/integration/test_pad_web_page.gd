extends GutTest
## Owner #90: a browser that cannot run the game (a PlayStation's, an old TV's: no WebGL 2 or no WebAssembly) gets a kind
## page instead of a loading screen that never ends. web/shell.html checks before the engine's script, in words an old
## browser still reads (no const, no arrow functions), and the loading page's main script stands back when it failed or
## when the engine's script never came. In a real headless Chromium: tools/web_kind_page_check.mjs (docs/DEVELOPMENT.md).

var html := ""


func before_all() -> void:
	html = FileAccess.get_file_as_string("res://web/shell.html")


func _check_script() -> String:
	var at := html.find("Owner #90: a browser that cannot run the game")
	var end := html.find("</script>", at)
	return html.substr(at, end - at)


func test_the_kind_words() -> void:
	assert_ne(html, "", "the shell is there")
	assert_string_contains(html, "This browser can\\u2019t run EasyCraft yet.")
	assert_string_contains(html, "Try Chrome, Edge, Firefox or Safari on a computer, tablet or phone.")
	assert_string_contains(html, "A PlayStation or Xbox controller works there too!")


func test_it_checks_webgl2_and_webassembly_before_the_engine_s_script() -> void:
	var check := _check_script()
	assert_string_contains(check, "getContext('webgl2')")
	assert_string_contains(check, "WebAssembly")
	assert_lt(html.find("Owner #90: a browser that cannot run the game"), html.find("<script src=\"$GODOT_URL\">"),
		"before the engine's script (an old browser may not read that one)")
	for modern: String in ["\\bconst\\s", "\\blet\\s", "=>", "`"]:
		var re := RegEx.create_from_string(modern)
		assert_null(re.search(check), "no '%s' in the check (old browsers)" % modern)


func test_the_loading_page_stands_back() -> void:
	assert_string_contains(html, "if (window.EC_CANT_RUN) {")
	assert_string_contains(html, "if (typeof Engine === 'undefined') {")
	assert_string_contains(html, "window.ecCantRun(['a newer browser'])")
