extends GutTest
## Owner #89 (spec §5.12, §20): the Theater's player in the browser. The page (web/shell.html) shows YouTube's
## own embedded player (youtube-nocookie.com, the made-for-kids settings) exactly over the Theater's screen, with a
## big CLOSE; the game opens and closes it through WebGlue, and no text from the list reaches the page as code (the
## id is checked, the rest are numbers). Browsers that can't show it inside the game's page (Safari, Firefox: the
## page's thread headers) get a WATCH button that opens the server's player page (server/deploy/site/tv/).
## What the scripts do is checked in a browser (docs/devlog/parts/tv-shows.md); here: what they are made of.

const PLAYER := Rect2i(840, 228, 720, 405)
const CLOSE := Rect2i(1335, 156, 225, 66)


func test_the_show_call_carries_only_a_checked_id_and_numbers() -> void:
	var js := WebGlue.tv_show_js("--xEE7K67Xo", PLAYER, CLOSE, true)
	assert_eq(js, "window.easycraftTv && window.easycraftTv.show('--xEE7K67Xo', 840, 228, 720, 405, 1335, 156, 225, 66, true)")
	assert_string_ends_with(WebGlue.tv_show_js("aqz-KE-bpKQ", PLAYER, CLOSE, false), ", false)")
	for bad: String in ["", "aqz-KE-bpK'", "x');alert(1)//", "aqz-KE-bpKQQ", "aqz KE bpKQ", "<script>ab"]:
		assert_eq(WebGlue.tv_show_js(bad, PLAYER, CLOSE, true), "", "no call for %s" % bad)


func test_the_player_must_be_big_enough() -> void:
	assert_eq(WebGlue.tv_show_js("aqz-KE-bpKQ", Rect2i(0, 0, 199, 300), CLOSE, true), "", "YouTube's 200 x 200 minimum")


func test_the_pages_answers_are_read_strictly() -> void:
	assert_eq(WebGlue.parse_tv_event("ended"), "ended")
	assert_eq(WebGlue.parse_tv_event("closed"), "closed")
	assert_eq(WebGlue.parse_tv_event("failed:150"), "failed:150")
	for junk: Variant in ["", "failed:", "failed:x", "Ended", "<b>", 5, null, "ended ", "failed:1234567"]:
		assert_eq(WebGlue.parse_tv_event(junk), "", "nothing from %s" % [junk])


func test_off_the_web_the_calls_do_nothing() -> void:
	assert_false(WebGlue.tv_available())
	assert_false(WebGlue.tv_show("aqz-KE-bpKQ", PLAYER, CLOSE, true))
	assert_false(WebGlue.tv_hide())
	assert_false(WebGlue.tv_close())
	assert_eq(WebGlue.tv_event(), "")
	assert_null(TheaterWebPlayer.create(), "no browser player off the web")


func _page(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	assert_ne(text, "", path)
	return text


## The page's player block: the privacy-enhanced host, the made-for-kids settings, never a link out.
func _check_player_page(what: String, text: String) -> void:
	assert_string_contains(text, "https://www.youtube-nocookie.com/embed/", "%s: the privacy-enhanced player" % what)
	assert_string_contains(text, "^[A-Za-z0-9_-]{11}$", "%s: the page checks the id again" % what)
	for setting: String in ["rel=0", "playsinline=1", "iv_load_policy=3", "fs=0"]:
		assert_string_contains(text, setting, "%s: %s" % [what, setting])
	var sandbox := RegEx.create_from_string("sandbox[\"']?\\s*[,=:]\\s*['\"]([^'\"]*)['\"]").search(text)
	assert_not_null(sandbox, "%s: the player is sandboxed" % what)
	if sandbox:
		for need: String in ["allow-scripts", "allow-same-origin", "allow-presentation"]:
			assert_string_contains(sandbox.get_string(1), need, what)
		assert_false(sandbox.get_string(1).contains("allow-popups"), "%s: no way out to YouTube's site" % what)
		assert_false(sandbox.get_string(1).contains("allow-top-navigation"), "%s: the game's page stays" % what)
	assert_string_contains(text, "strict-origin-when-cross-origin", "%s: the Referer names the site (YouTube's rule)" % what)
	assert_string_contains(text, "CLOSE", "%s: a big CLOSE" % what)
	assert_false(RegEx.create_from_string("<script[^>]+src=[\"']https?://").search(text) != null,
		"%s: no script from another site" % what)


func test_the_game_page_has_the_player_block() -> void:
	var shell := _page("res://web/shell.html")
	_check_player_page("shell.html", shell)
	assert_string_contains(shell, "window.easycraftTv = {", "the calls WebGlue makes")
	assert_string_contains(shell, "credentialless", "inside a cross-origin-isolated page (Chromium)")
	assert_string_contains(shell, "https://178-104-20-64.sslip.io/tv/", "the server's player page for Safari and Firefox")
	assert_string_contains(shell, "id=\"tv\"")
	assert_string_contains(shell, "id=\"tv-close\"")


func test_the_servers_player_page() -> void:
	var tv := _page("res://server/deploy/site/tv/index.html")
	_check_player_page("site/tv", tv)
	assert_string_contains(tv, "window.close()", "CLOSE goes back to the game")
	var caddy := _page("res://server/deploy/caddy/Caddyfile")
	assert_string_contains(caddy, " /tv /tv/", "Caddy serves it with the other public pages (no thread headers)")
