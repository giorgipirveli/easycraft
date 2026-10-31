extends GutTest
## M2 Task 7 (lead's child-psychology note): gold is shown with short numbers everywhere ("1.2K",
## "3.4M"), never rounded up, so a child never thinks they have more than they do.


func test_small_amounts_are_shown_as_they_are() -> void:
	assert_eq(GoldFormat.short(0), "0")
	assert_eq(GoldFormat.short(7), "7")
	assert_eq(GoldFormat.short(999), "999")


func test_thousands_and_millions_are_short() -> void:
	assert_eq(GoldFormat.short(1000), "1K")
	assert_eq(GoldFormat.short(1200), "1.2K")
	assert_eq(GoldFormat.short(9950), "9.9K")
	assert_eq(GoldFormat.short(12345), "12K")
	assert_eq(GoldFormat.short(340000), "340K")
	assert_eq(GoldFormat.short(3_400_000), "3.4M")
	assert_eq(GoldFormat.short(Wallet.MAX_GOLD), "999M")


func test_never_rounded_up() -> void:
	assert_eq(GoldFormat.short(1199), "1.1K", "1199 is not yet 1.2K: the 1.2K sword would look affordable")
	assert_eq(GoldFormat.short(999_999), "999K")
	assert_eq(GoldFormat.short(1_999_999), "1.9M")


func test_changes_have_a_sign() -> void:
	assert_eq(GoldFormat.change(12), "+12")
	assert_eq(GoldFormat.change(-30), "-30")
	assert_eq(GoldFormat.change(-1200), "-1.2K")
	assert_eq(GoldFormat.change(2500), "+2.5K")


func test_have_and_need() -> void:
	assert_eq(GoldFormat.have_need(340, 1200), "340 / 1.2K")
