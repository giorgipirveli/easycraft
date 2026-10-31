extends GutTest
## The game's words are English only (owner feedback #52, 2026-09-25; M3 Task 21a's Georgian and its LANGUAGE setting
## were removed). Lang keeps the English helpers M3 Task 21a's code calls.

var _locale := ""


func before_each() -> void:
	_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_locale)


func test_the_game_speaks_english() -> void:
	TranslationServer.set_locale("ka")
	Lang.apply()
	assert_eq(TranslationServer.get_locale().left(2), "en")
	assert_eq(Lang.current(), "en")


func test_words_come_back_as_they_are() -> void:
	assert_eq(Lang.t("Hello, friend!"), "Hello, friend!")
	assert_eq(Lang.t("%s can't be painted!") % "Stones", "Stones can't be painted!")


func test_a_new_profile_has_no_language_setting_and_an_old_one_drops_it() -> void:
	assert_false(ProfileData.new().settings.has("language"))
	var q := ProfileData.from_json('{"version":1,"username":"Hop","settings":{"language":"ka"}}')
	assert_false(q.settings.has("language"), "a profile saved with M3 Task 21a's LANGUAGE loads without it")


func test_english_articles_and_plurals() -> void:
	assert_eq(Lang.article("owl"), "an")
	assert_eq(Lang.article("horse"), "a")
	assert_eq(Lang.plural_s(1), "")
	assert_eq(Lang.plural_s(3), "s")
