extends GutTest
## Owner #95 ("offline should save history and get upgraded after getting online"): the game signs in again by itself
## when the internet comes back (before, only opening the main menu tried, once), so what was played offline goes up.


func test_it_tries_again_later_each_time_up_to_ten_minutes() -> void:
	assert_eq(ReconnectRules.wait_after(1), 20.0)
	assert_eq(ReconnectRules.wait_after(2), 40.0)
	assert_eq(ReconnectRules.wait_after(3), 80.0)
	assert_eq(ReconnectRules.wait_after(20), 600.0, "never longer than ten minutes")
	assert_eq(ReconnectRules.wait_after(0), 20.0)


func test_only_a_device_that_has_been_online_with_a_server_and_is_offline_tries() -> void:
	assert_true(ReconnectRules.should_try(true, OnlineService.OFFLINE, true, false))
	assert_false(ReconnectRules.should_try(false, OnlineService.OFFLINE, true, false), "never online before: never")
	assert_false(ReconnectRules.should_try(true, OnlineService.ONLINE, true, false), "online already")
	assert_false(ReconnectRules.should_try(true, OnlineService.CONNECTING, true, false), "trying already")
	assert_false(ReconnectRules.should_try(true, OnlineService.OFFLINE, false, false), "a build without a server")
	assert_false(ReconnectRules.should_try(true, OnlineService.OFFLINE, true, true), "a friend's world rejoining itself")
