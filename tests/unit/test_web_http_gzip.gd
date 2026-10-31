extends GutTest
## M7 (spec §20): in a browser, fetch() already un-gzips a response, and HTTPRequest then tried to un-gzip it again
## (StreamPeerGZIP "err != 0 && err != 1", sign-in failed: "Can't reach the game"). The Nakama adapter must not ask
## for gzip on web. Found live on https://178-104-20-64.sslip.io/play/ on 2026-09-28.

const ADAPTER := "res://addons/com.heroiclabs.nakama/client/NakamaHTTPAdapter.gd"


func test_the_nakama_adapter_turns_gzip_off_in_a_browser() -> void:
	var source := FileAccess.get_file_as_string(ADAPTER)
	assert_string_contains(source, "req.accept_gzip = not OS.has_feature(\"web\")",
		"the browser already decompresses; a second pass fails")


func test_an_http_request_can_turn_gzip_off() -> void:
	var req := HTTPRequest.new()
	req.accept_gzip = false
	assert_false(req.accept_gzip)
	req.free()


## The browser owns the TCP socket under a WebSocket: set_no_delay() is "not supported in Web export" and printed an
## error on every online sign-in (seen live 2026-09-28). NakamaLink only asks for it off web.
func test_the_link_asks_for_no_delay_only_off_the_web() -> void:
	var source := FileAccess.get_file_as_string("res://net/nakama_link.gd")
	assert_string_contains(source, "if not OS.has_feature(\"web\"):\n\t\tws.set_no_delay(true)")
