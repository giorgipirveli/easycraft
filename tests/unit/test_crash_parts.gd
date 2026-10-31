extends GutTest
## Owner #106: in the Sandbox the parts a crash broke are gone from what the child owns (MissionData.parts), and stay
## gone through the server backup's merge (each device counts what it lost, like what it bought: owner #98's counts per
## install, merged by the bigger count), so a rebuild costs gold again.

var _device := ""


func before_each() -> void:
	_device = MissionData.device
	MissionData.device = "test-a"


func after_each() -> void:
	MissionData.device = _device


func test_broken_parts_are_gone_from_what_the_child_owns() -> void:
	var m := MissionData.new()
	m.add_part(BlockIds.ROCKET_ENGINE, 10)
	m.add_part(BlockIds.FUEL_TANK, 4)
	m.lose_parts({BlockIds.ROCKET_ENGINE: 3, BlockIds.FUEL_TANK: 1})
	assert_eq(m.owned(), {BlockIds.ROCKET_ENGINE: 7, BlockIds.FUEL_TANK: 3})
	m.add_part(BlockIds.ROCKET_ENGINE, 3)
	assert_eq(int(m.owned()[BlockIds.ROCKET_ENGINE]), 10, "bought again")


func test_never_more_than_the_child_has_and_never_a_non_part() -> void:
	var m := MissionData.new()
	m.add_part(BlockIds.FUEL_TANK, 2)
	m.lose_parts({BlockIds.FUEL_TANK: 5, BlockIds.STONE: 3, BlockIds.ROCKET_ENGINE: 2})
	assert_eq(m.owned(), {}, "two tanks gone, nothing below zero")
	m.add_part(BlockIds.FUEL_TANK, 1)
	assert_eq(m.owned(), {BlockIds.FUEL_TANK: 1}, "a loss never eats a part bought later")


func test_the_loss_survives_the_save_and_the_backups_merge() -> void:
	var m := MissionData.new()
	m.add_part(BlockIds.ROCKET_ENGINE, 10)
	var backup := MissionData.from_dict(m.to_dict())   # the server's copy before the crash
	m.lose_parts({BlockIds.ROCKET_ENGINE: 4})
	var saved := MissionData.from_dict(m.to_dict())
	assert_eq(saved.owned(), {BlockIds.ROCKET_ENGINE: 6}, "the save keeps the loss")
	saved.merge_from(backup)
	assert_eq(saved.owned(), {BlockIds.ROCKET_ENGINE: 6}, "the older backup does not bring the broken parts back")
	backup.merge_from(MissionData.from_dict(m.to_dict()))
	assert_eq(backup.owned(), {BlockIds.ROCKET_ENGINE: 6}, "and the backup learns of the loss")


func test_two_devices_purchases_and_losses_add_up() -> void:
	var a := MissionData.new()
	a.add_part(BlockIds.ROCKET_ENGINE, 5)
	MissionData.device = "test-b"
	var b := MissionData.from_dict(a.to_dict())
	b.add_part(BlockIds.ROCKET_ENGINE, 5)
	b.lose_parts({BlockIds.ROCKET_ENGINE: 2})
	MissionData.device = "test-a"
	a.merge_from(b)
	assert_eq(a.owned(), {BlockIds.ROCKET_ENGINE: 8}, "5 + 5 bought, 2 broke")
