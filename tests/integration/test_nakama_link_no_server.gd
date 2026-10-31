extends GutTest
## NakamaLink when no server answers (runs everywhere, Docker or not; M4 early spike).


func test_signing_in_to_a_server_that_is_not_there_fails_with_a_reason_and_soon() -> void:
	var link := NakamaLink.new()
	add_child_autofree(link)
	var started := Time.get_ticks_msec()
	var err := await link.sign_in({"scheme": "http", "host": "127.0.0.1", "port": 1}, DeviceId.generate())
	assert_string_contains(err, "sign-in")
	assert_lt(Time.get_ticks_msec() - started, (NakamaLink.TIMEOUT_SEC + 2) * 1000, "gives up in time")
	assert_null(link.peer(), "no match, no peer")


func test_a_bad_device_id_is_refused_before_anything_is_sent() -> void:
	var link := NakamaLink.new()
	add_child_autofree(link)
	assert_ne(await link.sign_in({"scheme": "http", "host": "127.0.0.1", "port": 1}, "tiny"), "")


func test_joining_without_signing_in_fails_with_a_reason() -> void:
	var link := NakamaLink.new()
	add_child_autofree(link)
	assert_ne(await link.join_match("3dcf6dca-ba73-4e08-a89e-8c538234f741."), "")
	assert_ne(await link.join_match("not a match"), "")


func test_the_waiting_peer_is_never_the_host() -> void:
	var p := NakamaLink.waiting_peer()
	assert_eq(p.get_connection_status(), MultiplayerPeer.CONNECTION_CONNECTING)
	assert_ne(p.get_unique_id(), 1)
