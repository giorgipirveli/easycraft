extends GutTest
## M7 Task 4 (spec §20.3): WebGlue is the only place the game talks to the page's JavaScript (JavaScriptBridge exists
## only in a web build that has it compiled in). Off the web, and in this test run, every call is a quiet no-op. What
## the calls do in a browser is checked there (docs/devlog/parts/m7-web-code.md, the lead's list).


func test_off_the_web_nothing_reaches_javascript() -> void:
	assert_false(OS.has_feature("web"), "this run is not a browser")
	assert_false(WebGlue.coarse_pointer(), "no finger pointer to ask about")
	assert_eq(WebGlue.page_host(), "", "no page")
	assert_false(WebGlue.download(PackedByteArray([1, 2, 3]), "EasyCraft_x.png", "image/png"), "no download")
	assert_false(WebGlue.ask_persistent_storage(), "no browser storage to keep")


## M7 (the shader warm-up): the loading page shows the warm-up's progress (web/shell.html's window.easycraftWarmup).
func test_the_warm_up_s_progress_goes_to_the_page() -> void:
	assert_false(WebGlue.warmup_progress(0.5), "no page off the web")
	assert_eq(WebGlue.warmup_js(0.25), "window.easycraftWarmup && window.easycraftWarmup(0.250)")
	assert_eq(WebGlue.warmup_js(-1.0), "window.easycraftWarmup && window.easycraftWarmup(0.000)", "never below 0")
	assert_eq(WebGlue.warmup_js(3.0), "window.easycraftWarmup && window.easycraftWarmup(1.000)", "never above 1")


func test_the_scripts_ask_before_they_act() -> void:
	assert_string_contains(WebGlue.PERSIST_JS, "persisted()", "asks only when the storage is not kept yet")
	assert_string_contains(WebGlue.PERSIST_JS, "persist()")
	assert_string_contains(WebGlue.PERSIST_JS, "navigator.storage", "browsers without the Storage API are skipped")
	assert_string_contains(WebGlue.COARSE_POINTER_JS, "(pointer: coarse)")


# --- M7 (owner 2026-09-28): the page's offer to add the game to the device (web/shell.html's window.easycraftApp) ---

func test_off_the_web_there_is_nothing_to_add() -> void:
	assert_eq(WebGlue.install_state(), {"can_install": false, "needs_guide": false, "installed": false})
	assert_false(WebGlue.request_install(), "no page to ask")


func test_the_install_state_reads_only_real_answers() -> void:
	assert_eq(WebGlue.parse_install_state('{"can_install":true,"needs_guide":true,"installed":false}'),
		{"can_install": true, "needs_guide": true, "installed": false})
	assert_eq(WebGlue.parse_install_state('{"can_install":false,"needs_guide":false,"installed":true}'),
		{"can_install": false, "needs_guide": false, "installed": true})
	var none := {"can_install": false, "needs_guide": false, "installed": false}
	assert_eq(WebGlue.parse_install_state(""), none, "a page without window.easycraftApp")
	assert_eq(WebGlue.parse_install_state(null), none)
	assert_eq(WebGlue.parse_install_state(true), none)
	assert_eq(WebGlue.parse_install_state("{broken"), none)
	assert_eq(WebGlue.parse_install_state("[1,2]"), none)
	assert_eq(WebGlue.parse_install_state('{"can_install":"yes","installed":1}'), none, "only true is true")


func test_the_install_scripts_ask_the_page_and_survive_a_page_without_it() -> void:
	for js: String in [WebGlue.INSTALL_STATE_JS, WebGlue.INSTALL_JS]:
		assert_string_contains(js, "window.easycraftApp")
		assert_string_contains(js, "if (!app)", "a page without the offer answers nothing")
		assert_string_contains(js, "catch", "a throwing page answers nothing")
	assert_string_contains(WebGlue.INSTALL_STATE_JS, "canInstall()")
	assert_string_contains(WebGlue.INSTALL_STATE_JS, "needsGuide()")
	assert_string_contains(WebGlue.INSTALL_STATE_JS, "isInstalled()")
	assert_string_contains(WebGlue.INSTALL_JS, "install()")


# --- M7 (owner 2026-09-28: the realistic pictures come later too): which pictures this GPU reads ---

func test_the_texture_format_is_the_pages_choice() -> void:
	assert_eq(WebGlue.parse_texture_format("etc2"), "etc2", "a phone: the page took index.mobile.pck")
	assert_eq(WebGlue.parse_texture_format("s3tc"), "s3tc", "a computer: index.pck")
	for odd: Variant in ["", null, "astc", 5, true, "ETC2 "]:
		assert_eq(WebGlue.parse_texture_format(odd), WebContent.DEFAULT_GPU, "the page's default: %s" % [odd])
	assert_eq(WebGlue.texture_format(), WebContent.DEFAULT_GPU, "off the web: no page to ask")


func test_the_page_tells_the_game_which_main_pack_it_took() -> void:
	assert_string_contains(WebGlue.TEXTURE_FORMAT_JS, "window.easycraftGpu")
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "window.easycraftGpu = pick === 'index.mobile.pck' ? 'etc2' : 's3tc';",
		"pickPack() says what it picked")


## Owner #76 (2026-09-29, "screen size on iphone is shown incorectly"): iOS Safari and Chrome (iOS 26 above all) can
## leave the page scrolled or the canvas at a stale size after the keyboard closes (the name), a rotation or the
## toolbars moving. The page is pinned to the screen, and at those moments it scrolls back to the top and makes the
## game read the screen's size again (a few times, as iOS settles).
func test_the_page_stays_the_screens_size_on_an_iphone() -> void:
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "function settleSize()")
	assert_string_contains(shell, "window.dispatchEvent(new Event('resize'));", "the game reads the size again")
	assert_string_contains(shell, "window.scrollTo(0, 0);", "back to the top")
	assert_string_contains(shell, "window.addEventListener('orientationchange', settleSoon);")
	assert_string_contains(shell, "window.visualViewport.addEventListener('resize', settleSoon);", "the toolbars or the keyboard moved")
	assert_string_contains(shell, "document.addEventListener('focusout', settleSoon);", "the keyboard closed")
	assert_string_contains(shell, "position: fixed;\n\tinset: 0;\n\toverscroll-behavior: none;", "the page pinned to the screen")


## Owner #79 (spec §25.2): an invite link (…/play/?invite=BLUE-OTTER-42) carries only a friend's code: the page keeps it
## as window.easycraftInvite (letters, digits, spaces, dashes; 40 at most), the redirect to the server's copy keeps it, and
## the game reads it; the share sheet is the browser's own (navigator.share), off the web nothing is asked.
func test_the_invite_link_s_code_reaches_the_game_and_survives_the_redirect() -> void:
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "window.easycraftInvite = ")
	assert_string_contains(shell, "window.location.replace(HOME + inviteQuery());", "the redirect keeps the code")
	assert_string_contains(WebGlue.INVITE_JS, "window.easycraftInvite")
	assert_eq(WebGlue.invite_code(), "", "off the web: no page")
	assert_false(WebGlue.can_share())
	assert_false(WebGlue.share("hi", "https://x"))


## Owner #95: the browser says whether it is online (navigator.onLine); off the web the game always may try.
func test_off_the_web_the_game_counts_as_online() -> void:
	assert_true(WebGlue.browser_online())
