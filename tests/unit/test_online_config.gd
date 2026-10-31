extends GutTest
## Online play settings (M4 spike): the Nakama server's address, relayed match ids, and the
## developer args --online-host / --online-join=<id> / --online-server=<address>.

const RELAYED := "3dcf6dca-ba73-4e08-a89e-8c538234f741."   # as Nakama 3.41 names a relayed match
const AUTHORITATIVE := "3dcf6dca-ba73-4e08-a89e-8c538234f741.easycraft-dev"


func test_no_address_means_the_development_server_on_this_pc() -> void:
	assert_eq(OnlineConfig.parse_server(""), {"scheme": "http", "host": "127.0.0.1", "port": 7350})
	assert_eq(OnlineConfig.parse_server("   "), {"scheme": "http", "host": "127.0.0.1", "port": 7350})


func test_a_host_alone_keeps_nakamas_port() -> void:
	assert_eq(OnlineConfig.parse_server("10.0.2.2"), {"scheme": "http", "host": "10.0.2.2", "port": 7350},
		"the Android emulator's name for this PC")
	assert_eq(OnlineConfig.parse_server("  localhost  "), {"scheme": "http", "host": "localhost", "port": 7350})


func test_a_host_and_port() -> void:
	assert_eq(OnlineConfig.parse_server("192.168.1.20:7450"), {"scheme": "http", "host": "192.168.1.20", "port": 7450})


func test_urls_with_a_scheme() -> void:
	assert_eq(OnlineConfig.parse_server("https://play.example.com"), {"scheme": "https", "host": "play.example.com", "port": 443},
		"https without a port is 443 (a TLS proxy in front of Nakama)")
	assert_eq(OnlineConfig.parse_server("http://localhost:7350/"), {"scheme": "http", "host": "localhost", "port": 7350})
	assert_eq(OnlineConfig.parse_server("HTTPS://Play.Example.com:8443"), {"scheme": "https", "host": "Play.Example.com", "port": 8443})


func test_an_ipv6_host_needs_brackets() -> void:
	assert_eq(OnlineConfig.parse_server("[::1]:7350"), {"scheme": "http", "host": "::1", "port": 7350})
	assert_eq(OnlineConfig.parse_server("[::1]"), {"scheme": "http", "host": "::1", "port": 7350})
	assert_true(OnlineConfig.parse_server("::1").has("error"), "a bare IPv6 address is ambiguous")


func test_bad_addresses_are_refused_with_a_reason() -> void:
	for bad: String in ["ftp://example.com", "ws://example.com", "host:0", "host:65536", "host:abc", "host:",
			":7350", "host/path", "http://host:7350/v2", "a b", "http://", "[::1", "[::1]x", "host:7350:1"]:
		var result := OnlineConfig.parse_server(bad)
		assert_true(result.has("error"), "refused: %s" % bad)
		if result.has("error"):
			assert_ne(str(result.error), "", "says why: %s" % bad)


func test_match_ids_of_relayed_and_authoritative_matches() -> void:
	assert_eq(OnlineConfig.normalize_match_id(RELAYED), RELAYED)
	assert_eq(OnlineConfig.normalize_match_id(AUTHORITATIVE), AUTHORITATIVE)
	assert_true(OnlineConfig.is_match_id(RELAYED))


func test_a_match_id_is_trimmed_and_its_uuid_lowercased() -> void:
	assert_eq(OnlineConfig.normalize_match_id("  3DCF6DCA-BA73-4E08-A89E-8C538234F741.  "), RELAYED)
	assert_eq(OnlineConfig.normalize_match_id("3DCF6DCA-BA73-4E08-A89E-8C538234F741.EasyCraft-Dev"),
		"3dcf6dca-ba73-4e08-a89e-8c538234f741.EasyCraft-Dev", "the node name is kept as it is")


func test_things_that_are_not_match_ids() -> void:
	for bad: String in ["", "hello", "3dcf6dca-ba73-4e08-a89e-8c538234f741", "3dcf6dca-ba73-4e08-a89e-8c538234f74.",
			"zzzzzzzz-ba73-4e08-a89e-8c538234f741.", "3dcf6dca-ba73-4e08-a89e-8c538234f741. x",
			"3dcf6dca-ba73-4e08-a89e-8c538234f741.no/de", "3dcf6dcaba734e08a89e8c538234f741.",
			"3dcf6dca-ba73-4e08-a89e-8c538234f741." + "n".repeat(65)]:
		assert_eq(OnlineConfig.normalize_match_id(bad), "", "not a match id: %s" % bad)
		assert_false(OnlineConfig.is_match_id(bad), "not a match id: %s" % bad)


func test_no_online_args_means_not_online() -> void:
	assert_eq(OnlineConfig.from_args([]), {})
	assert_eq(OnlineConfig.from_args(["--lan-test", "--auto-host"]), {})
	assert_eq(OnlineConfig.from_args(["--online-server=10.0.2.2"]), {}, "a server alone does not start online play")


func test_online_host() -> void:
	assert_eq(OnlineConfig.from_args(["--online-host"]),
		{"role": OnlineConfig.HOST, "match_id": "", "server": OnlineConfig.parse_server("")})


func test_online_join_by_match_id() -> void:
	assert_eq(OnlineConfig.from_args(["--net-test", "--online-join=" + RELAYED.to_upper()]),
		{"role": OnlineConfig.JOIN, "match_id": RELAYED, "server": OnlineConfig.parse_server("")})


func test_online_server_arg() -> void:
	var cfg := OnlineConfig.from_args(["--online-host", "--online-server=10.0.2.2:7450"])
	assert_eq(cfg.get("server"), {"scheme": "http", "host": "10.0.2.2", "port": 7450})


func test_bad_online_args_are_refused_with_a_reason() -> void:
	for args: Array in [["--online-join=nope"], ["--online-join="], ["--online-host", "--online-join=" + RELAYED],
			["--online-host", "--online-server=ftp://x"]]:
		var cfg := OnlineConfig.from_args(args)
		assert_true(cfg.has("error"), "refused: %s" % [args])
		assert_false(cfg.has("role"), "no role when refused: %s" % [args])


# --- M4 D: the release server (server/deploy, docs/hosting.md) ---------------------------------

const RELEASE_ADDRESS := "https://play.example.com"


func test_developer_builds_keep_this_pcs_server() -> void:
	assert_eq(OnlineConfig.server_for_build(false, false, RELEASE_ADDRESS), OnlineConfig.parse_server(""),
		"a desktop developer build talks to server/dev.sh on 127.0.0.1:7350")
	assert_eq(OnlineConfig.server_for_build(false, true, RELEASE_ADDRESS), {"scheme": "http", "host": "10.0.2.2", "port": 7350},
		"a developer build on the Android emulator reaches this PC as 10.0.2.2")


func test_release_builds_use_the_release_server_over_tls() -> void:
	var expected := {"scheme": "https", "host": "play.example.com", "port": 443}
	assert_eq(OnlineConfig.server_for_build(true, true, RELEASE_ADDRESS), expected, "a phone")
	assert_eq(OnlineConfig.server_for_build(true, false, RELEASE_ADDRESS), expected, "a desktop release build too")
	assert_eq(OnlineConfig.release_server("play.example.com"), expected, "https is assumed when no scheme is given")
	assert_eq(OnlineConfig.release_server("https://play.example.com:8443"),
		{"scheme": "https", "host": "play.example.com", "port": 8443})


## M7 (spec §20.3): the web build is served from the game server's own host (/play/), so a web release build signs in
## to RELEASE_SERVER like the phones (same site: no CORS); a developer web build to the server on the machine that
## served the page (this PC's Chrome: 127.0.0.1; the emulator's Chrome: 10.0.2.2), whatever the device.
func test_a_web_release_build_uses_the_release_server() -> void:
	var expected := {"scheme": "https", "host": "play.example.com", "port": 443}
	assert_eq(OnlineConfig.server_for_build(true, false, RELEASE_ADDRESS, "play.example.com"), expected)
	assert_eq(OnlineConfig.server_for_build(true, false, RELEASE_ADDRESS, "mirror.example.org"), expected,
		"even from a page served elsewhere")


func test_a_developer_web_build_uses_the_server_where_the_page_came_from() -> void:
	assert_eq(OnlineConfig.server_for_build(false, false, RELEASE_ADDRESS, "10.0.2.2"),
		{"scheme": "http", "host": "10.0.2.2", "port": 7350}, "the emulator's Chrome")
	assert_eq(OnlineConfig.server_for_build(false, false, RELEASE_ADDRESS, "localhost"),
		{"scheme": "http", "host": "localhost", "port": 7350}, "this PC's Chrome")
	assert_eq(OnlineConfig.server_for_build(false, false, RELEASE_ADDRESS, ""), OnlineConfig.parse_server(""),
		"no page: this PC, as before")
	assert_eq(OnlineConfig.server_for_build(false, false, RELEASE_ADDRESS, "bad host!"), OnlineConfig.parse_server(""),
		"a page host that is no host name: this PC")


func test_a_release_server_without_tls_is_refused() -> void:
	for bad: String in ["http://play.example.com", "http://203.0.113.10:7350", "HTTP://play.example.com:443"]:
		var result := OnlineConfig.release_server(bad)
		assert_true(result.has("error"), "children's accounts never cross the internet unencrypted: %s" % bad)
		assert_false(result.has("host"), "no server when refused: %s" % bad)
	assert_true(OnlineConfig.release_server("https://").has("error"), "a bad address is refused as well")


func test_no_release_server_yet_means_no_online_play_in_release_builds() -> void:
	var result := OnlineConfig.server_for_build(true, true, "")
	assert_true(result.has("error"), "until the owner has a server, a release build has none")
	assert_false(result.has("host"))
	assert_eq(OnlineConfig.server_for_build(false, false, ""), OnlineConfig.parse_server(""),
		"developer builds don't need a release server")


func test_the_release_server_in_the_game_is_empty_or_secure() -> void:
	if OnlineConfig.RELEASE_SERVER == "":
		pass_test("no release server yet (docs/hosting.md, step 8)")
		return
	var server := OnlineConfig.release_server(OnlineConfig.RELEASE_SERVER)
	assert_false(server.has("error"), "RELEASE_SERVER must be a valid https address: %s" % server.get("error", ""))
	assert_eq(server.get("scheme"), "https")


func test_this_build_is_a_developer_build_when_tests_run() -> void:
	assert_false(OnlineConfig.is_release_build(), "tests run in the editor binary, a debug build")
	assert_eq(OnlineConfig.default_server(),
		OnlineConfig.server_for_build(false, OS.has_feature("android"), OnlineConfig.RELEASE_SERVER))


func test_each_server_gets_its_own_key() -> void:
	assert_eq(OnlineConfig.key_for(OnlineConfig.parse_server(""), RELEASE_ADDRESS), OnlineConfig.SERVER_KEY,
		"the development server keeps server/nakama/local.yml's key")
	assert_eq(OnlineConfig.key_for(OnlineConfig.parse_server("10.0.2.2"), RELEASE_ADDRESS), OnlineConfig.SERVER_KEY)
	assert_eq(OnlineConfig.key_for(OnlineConfig.release_server(RELEASE_ADDRESS), RELEASE_ADDRESS),
		OnlineConfig.RELEASE_SERVER_KEY, "the release server has the hosting kit's key")
	assert_eq(OnlineConfig.key_for(OnlineConfig.parse_server("https://other.example.com"), RELEASE_ADDRESS),
		OnlineConfig.SERVER_KEY, "another server is not the release server")
	assert_eq(OnlineConfig.key_for(OnlineConfig.release_server(RELEASE_ADDRESS), ""), OnlineConfig.SERVER_KEY,
		"no release server yet: every server is a development one")


func test_the_release_key_is_not_nakamas_default() -> void:
	assert_ne(OnlineConfig.RELEASE_SERVER_KEY, OnlineConfig.SERVER_KEY)
	assert_ne(OnlineConfig.RELEASE_SERVER_KEY, "defaultkey", "Nakama warns about its default key in production")
	assert_gte(OnlineConfig.RELEASE_SERVER_KEY.length(), 16)
	assert_not_null(RegEx.create_from_string("^[A-Za-z0-9._~-]+$").search(OnlineConfig.RELEASE_SERVER_KEY),
		"letters, digits and . _ ~ - only (the kit's start check allows only these)")


func test_online_server_release_arg() -> void:
	var cfg := OnlineConfig.from_args(["--online-host", "--online-server=release"])
	if OnlineConfig.RELEASE_SERVER == "":
		assert_true(cfg.has("error"), "no release server yet")
		assert_false(cfg.has("role"))
	else:
		assert_eq(cfg.get("server"), OnlineConfig.release_server(OnlineConfig.RELEASE_SERVER),
			"a developer build can try the release server")


func test_without_a_server_arg_the_builds_own_server_is_used() -> void:
	assert_eq(OnlineConfig.from_args(["--online-host"]).get("server"), OnlineConfig.default_server())
