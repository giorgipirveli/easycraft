extends GutTest
## Owner #98, bug 3: one account on a phone and a PC. Each device's gold spends reach the server's wallet and add up
## (WalletSync), so the rocket parts each device bought must add up too when the profile's copies merge
## (ProfileBackup → MissionData.merge_from): before, the merge kept the bigger count, and parts paid for on both
## devices were lost. Each install keeps its own count of what it bought (MissionData.device); a merge keeps the bigger
## count per device and the total is their sum. A copy from before (no counts per device) still merges.

var _device := ""


func before_each() -> void:
	_device = MissionData.device


func after_each() -> void:
	MissionData.device = _device


func test_parts_bought_on_two_devices_add_up_like_their_gold() -> void:
	MissionData.device = "phone-1234"
	var phone := MissionData.new()
	phone.add_part(BlockIds.ROCKET_ENGINE, 8)   # 8 engines bought on the phone, uploaded
	MissionData.device = "pc-5678"
	var pc := MissionData.new()                  # the PC still holds the copy from before the phone's purchase
	pc.add_part(BlockIds.ROCKET_ENGINE, 8)      # and buys 8 more: both spends reach the wallet
	var phone_copy := MissionData.from_dict(JSON.parse_string(JSON.stringify(phone.to_dict())))
	pc.merge_from(phone_copy)
	assert_eq(pc.owned(), {BlockIds.ROCKET_ENGINE: 16}, "paid twice: 16 engines")
	MissionData.device = "phone-1234"
	var pc_copy := MissionData.from_dict(JSON.parse_string(JSON.stringify(pc.to_dict())))
	phone.merge_from(pc_copy)
	assert_eq(phone.owned(), {BlockIds.ROCKET_ENGINE: 16}, "the phone sees the same")
	phone.merge_from(pc_copy)
	assert_eq(phone.owned(), {BlockIds.ROCKET_ENGINE: 16}, "merging again never counts twice")


func test_one_device_merging_its_own_copies_keeps_the_bigger_count() -> void:
	MissionData.device = "phone-1234"
	var a := MissionData.new()
	a.add_part(BlockIds.FUEL_TANK, 3)
	var b := MissionData.from_dict(a.to_dict())
	b.add_part(BlockIds.FUEL_TANK, 2)
	a.merge_from(b)
	assert_eq(a.owned(), {BlockIds.FUEL_TANK: 5}, "the newer copy of the same device")


func test_a_copy_from_before_still_merges() -> void:
	var old := MissionData.from_dict({"parts": {str(BlockIds.FUEL_TANK): 10}, "flown": [16]})
	assert_eq(old.owned(), {BlockIds.FUEL_TANK: 10}, "an old save's parts are kept")
	MissionData.device = "phone-1234"
	old.add_part(BlockIds.FUEL_TANK, 2)
	assert_eq(old.owned(), {BlockIds.FUEL_TANK: 12})
	var back := MissionData.from_dict(JSON.parse_string(JSON.stringify(old.to_dict())))
	assert_eq(back.owned(), {BlockIds.FUEL_TANK: 12}, "saved and loaded")
	assert_eq(int((back.to_dict().parts as Dictionary).get(str(BlockIds.FUEL_TANK))), 12,
		"an older game reads the total")
	# An older game took the total (12) and bought 3 more: its copy has 15 and no counts per device.
	var older := MissionData.from_dict({"parts": {str(BlockIds.FUEL_TANK): 15}})
	back.merge_from(older)
	assert_eq(back.owned(), {BlockIds.FUEL_TANK: 15}, "what the older game added, never counted twice")


func test_this_install_has_a_key_of_its_own() -> void:
	MissionData.device = ""
	var key := MissionData.device_key()
	assert_ne(key, "")
	assert_eq(MissionData.device_key(), key, "the same on every call")
	for bad: Variant in [{"parts": {}, "by": {"x": {"560": -3, "abc": 2}, "": {"560": 1}}, "older": "no"}, {"by": 3}]:
		assert_true(MissionData.from_dict(bad).owned().is_empty(), str(bad))
