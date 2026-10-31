class_name SchoolClock
extends RefCounted
## Owner #68 (spec §22.2): the School counts whole days of the device's own calendar, only to suggest reviews and to show
## grown-ups the day a unit was last practised. Nothing expires or is lost by a day passing (MasteryRules).


## Today's day number (days since 1970-01-01 of the local calendar).
static func today() -> int:
	return day_of(Time.get_date_dict_from_system())


static func day_of(date: Dictionary) -> int:
	var d := {"year": int(date.get("year", 1970)), "month": int(date.get("month", 1)), "day": int(date.get("day", 1)),
		"hour": 12, "minute": 0, "second": 0}
	return int(floor(Time.get_unix_time_from_datetime_dict(d) / 86400.0))


## "28 Sep" (for grown-ups), "" for day 0 (never).
static func short_date(day: int) -> String:
	if day <= 0:
		return ""
	var d := Time.get_date_dict_from_unix_time(day * 86400 + 43200)
	var months: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s" % [int(d.day), months[clampi(int(d.month) - 1, 0, 11)]]
