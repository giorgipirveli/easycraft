extends GutTest


func test_clearly_under_13() -> void:
	assert_eq(AgeBand.from_birth_year(2018, 2026), AgeBand.UNDER_13)


func test_boundary_is_conservative() -> void:
	assert_eq(AgeBand.from_birth_year(2013, 2026), AgeBand.UNDER_13)


func test_clearly_13_plus() -> void:
	assert_eq(AgeBand.from_birth_year(2012, 2026), AgeBand.TEEN_PLUS)


func test_future_year_is_under_13() -> void:
	assert_eq(AgeBand.from_birth_year(2030, 2026), AgeBand.UNDER_13)


## Owner #57: the first question is "How old are you?" (a number), not the birth year. Only the band is kept.
func test_an_age_gives_the_band() -> void:
	assert_eq(AgeBand.from_age(7), AgeBand.UNDER_13)
	assert_eq(AgeBand.from_age(12), AgeBand.UNDER_13)
	assert_eq(AgeBand.from_age(13), AgeBand.TEEN_PLUS)
	assert_eq(AgeBand.from_age(45), AgeBand.TEEN_PLUS)
	assert_eq(AgeBand.from_age(0), AgeBand.UNDER_13, "nonsense counts as a child (the safe side)")
