extends GutTest
## Owner #93 ("play alone without an internet"), the browser version: after one online visit the page opens without
## the internet. Godot's worker looked the page up as /play/, which it never keeps, so an offline visit failed
## (net::ERR_FAILED); tools/export_web.sh makes it take the page from the network when it can and else this build's
## own index.html when every file of the game is kept. Checked in a browser by tools/web_offline_check.mjs.

const EXPORT := "res://tools/export_web.sh"


func test_the_worker_opens_the_kept_page_without_the_internet() -> void:
	var script := FileAccess.get_file_as_string(EXPORT)
	assert_string_contains(script, "async function ecOfflinePage(cache)")
	assert_string_contains(script, "return await fetchAndCache(event, cache, false);", "online: the newest page")
	assert_string_contains(script, "const page = await ecOfflinePage(cache);", "offline: the kept one")
	assert_string_contains(script, "await cache.match('index.html')")


func test_a_first_visit_cut_short_gets_easycrafts_own_offline_page() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var web := ""
	for section in presets.get_sections():
		if section.ends_with(".options") and presets.get_value(section.trim_suffix(".options"), "name", "") == "Web":
			web = str(presets.get_value(section, "progressive_web_app/offline_page", ""))
	assert_eq(web, "res://web/offline.html")
	var page := FileAccess.get_file_as_string(web)
	for words: String in ["needs the internet once", "without the internet", "Sandbox", "Survivor", "School"]:
		assert_string_contains(page, words)


func test_the_loading_page_says_it_plays_offline() -> void:
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "plays <b>without the internet</b> too")
	assert_string_contains(shell, "navigator.onLine === false")


## Owner #95: an update downloads the whole game for this device before it takes over (so it plays offline too), and
## the page asks for one when the browser is online again.
func test_an_update_is_whole_before_it_takes_over_and_is_asked_for_when_online() -> void:
	var script := FileAccess.get_file_as_string(EXPORT)
	assert_string_contains(script, "async function ecKeepUpdate()")
	assert_string_contains(script, ".then(() => ecKeepUpdate()));")
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "window.addEventListener('online', checkForUpdate);")
	assert_string_contains(shell, "reg.update()")
