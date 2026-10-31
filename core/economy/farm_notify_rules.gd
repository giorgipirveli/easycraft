class_name FarmNotifyRules
extends RefCounted
## When the opt-in "Your farm is full!" note may ring (spec §5.6, §6; M3 Task 10). Off by default (the
## setting "farm_note"; for an under-13 child only a grown-up turns it on, behind the parent gate). It rings
## when the barn is full, never between 20:00 and 08:00 on the phone's own clock (it waits for 08:00), and at
## most once a day. Times are unix seconds; `bias` is the phone's time zone in minutes east of UTC
## (Time.get_time_zone_from_system().bias). Its words carry no guilt.

const TITLE := "Your farm is full!"
const TEXT := "The barn holds all the gold it can."
const NIGHT_FROM := 20        # local hours: no note from 20:00 ...
const MORNING := 8            # ... until 08:00
const DAY := 86400
const HOUR := 3600


## Did the player turn the note on? (Settings are checked by type: only a real switch counts.)
static func wanted(settings: Dictionary) -> bool:
	var v: Variant = settings.get("farm_note", false)
	return v is bool and v


## The phone's day number of a moment.
static func local_day(unix: int, bias: int) -> int:
	return floori(float(unix + bias * 60) / DAY)


## When the note for a barn full at `full_at` rings: then, or the next 08:00 when that is night or when a
## note already rang that day (`last_day`, local_day of it; -1 for none).
static func fire_at(full_at: int, bias: int, last_day: int) -> int:
	var shift := bias * 60
	var local := full_at + shift
	var day := floori(float(local) / DAY)
	var hour := floori(float(local - day * DAY) / HOUR)
	if hour >= NIGHT_FROM:
		local = (day + 1) * DAY + MORNING * HOUR
	elif hour < MORNING:
		local = day * DAY + MORNING * HOUR
	if floori(float(local) / DAY) == last_day:
		local = (last_day + 1) * DAY + MORNING * HOUR
	return local - shift


## The day the last note rang: `at` is the last note asked for (0 = none); one still waiting has not rung.
static func last_rang_day(at: int, now: int, bias: int) -> int:
	if at <= 0 or at > now:
		return -1
	return local_day(at, bias)
