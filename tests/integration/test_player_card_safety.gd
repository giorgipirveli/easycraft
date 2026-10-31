extends GutTest
## Spec §17.3 "Safety in the world" (the M4 Task 10 review's finding A, 2026-09-25): a tap on another player's name tag
## opens their card in every world with other players. Online it offers REPORT (the friends page's reasons) and BLOCK
## (asks first), friend or not; the host also gets REMOVE FROM MY WORLD (asks first; offered again after BLOCK). On LAN
## there is no server to report to, but the host can still remove a player. TRADE stays Survivor's.

var card: PlayerCard
var reported: Array = []
var blocked: Array = []
var removed: Array = []


func before_each() -> void:
	reported.clear()
	blocked.clear()
	removed.clear()
	card = PlayerCard.new()
	card.on_report = func(peer: int, reason: String) -> String:
		reported.append([peer, reason])
		return ""
	card.on_block = func(peer: int) -> String:
		blocked.append(peer)
		return ""
	card.on_remove = func(peer: int) -> String:
		removed.append(peer)
		return ""
	add_child_autofree(card)


func _open(online: bool, host: bool, trade := false) -> void:
	card.can_trade = trade
	card.online = online
	card.host = host
	card.open_for(77, "Bob")


func _button(button_name: String) -> Button:
	return card.find_child(button_name, true, false) as Button


func _words() -> String:
	var out := PackedStringArray()
	for l in card.find_children("*", "Label", true, false):
		out.append((l as Label).text)
	return " ".join(out)


func test_an_online_guest_can_report_and_block_but_not_remove() -> void:
	_open(true, false)
	assert_not_null(_button("ReportButton"))
	assert_not_null(_button("BlockButton"))
	assert_null(_button("RemoveButton"), "only the host removes")
	assert_null(_button("TradeButton"), "no trading here")


func test_report_asks_what_happened_and_sends_it() -> void:
	_open(true, false)
	_button("ReportButton").pressed.emit()
	for r: String in OnlineService.REPORT_REASONS:
		assert_not_null(_button("Reason_" + r), r)
	_button("Reason_" + OnlineService.REPORT_MEAN).pressed.emit()
	await wait_process_frames(2)
	assert_eq(reported, [[77, OnlineService.REPORT_MEAN]])
	assert_string_contains(_words(), "Thank you")


func test_block_asks_first() -> void:
	_open(true, false)
	_button("BlockButton").pressed.emit()
	assert_eq(blocked, [], "asks first")
	assert_string_contains(_words(), "Bob")
	_button("YesButton").pressed.emit()
	await wait_process_frames(2)
	assert_eq(blocked, [77])


func test_the_host_removes_a_player_after_asking() -> void:
	_open(true, true)
	_button("RemoveButton").pressed.emit()
	assert_eq(removed, [], "asks first")
	_button("YesButton").pressed.emit()
	await wait_process_frames(2)
	assert_eq(removed, [77])


func test_a_host_who_blocks_is_offered_to_remove_them_too() -> void:
	_open(true, true)
	_button("BlockButton").pressed.emit()
	_button("YesButton").pressed.emit()
	await wait_process_frames(2)
	assert_eq(blocked, [77])
	assert_not_null(_button("RemoveButton"), "remove them from this world too?")


func test_no_is_nothing() -> void:
	_open(true, true)
	_button("RemoveButton").pressed.emit()
	_button("NoButton").pressed.emit()
	await wait_process_frames(2)
	assert_eq(removed, [])
	assert_not_null(_button("ReportButton"), "back to the card")


func test_on_lan_the_host_can_remove_but_there_is_no_server_to_report_to() -> void:
	_open(false, true)
	assert_not_null(_button("RemoveButton"))
	assert_null(_button("ReportButton"))
	assert_null(_button("BlockButton"))


func test_trade_only_where_trading_is() -> void:
	_open(true, false, true)
	assert_not_null(_button("TradeButton"))
