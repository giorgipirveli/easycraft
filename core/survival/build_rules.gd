class_name BuildRules
extends RefCounted
## Build to Survive's clock and words (spec §12.18). A new world starts in the morning (START_TIME) and
## the first sunset comes 3:00 later: while the sun is up the clock runs DAY_SPEED × DayCycle's (sunrise to
## sunset in 3:30), while it is down NIGHT_SPEED × (sunset to sunrise in 3:00). The night clock on the HUD
## counts to the next sunset by day and to the next sunrise at night. It is game time only.

const START_TIME := 0.25
const DAY_SPEED := 4.0
const NIGHT_SPEED := 2.0


## How many times faster than DayCycle's the clock runs at time of day t.
static func speed(t: float) -> float:
	return NIGHT_SPEED if DayCycle.is_night(t) else DAY_SPEED


## Seconds of play from time of day t until time of day `target` comes next (0 when it is now).
static func seconds_until(t: float, target: float) -> float:
	var u := DayCycle.wrap_time(t)
	var left := fposmod(DayCycle.wrap_time(target) - u, 1.0)
	var seconds := 0.0
	while left > 1e-9:
		var edge := DayCycle.SUNRISE if u < DayCycle.SUNRISE else (DayCycle.SUNSET if u < DayCycle.SUNSET else DayCycle.SUNRISE + 1.0)
		var span := minf(edge - u, left)
		seconds += span * DayCycle.LENGTH / speed(u)
		u = DayCycle.wrap_time(u + span)
		left -= span
	return seconds


## Seconds until the sun sets (by day), or 0 at night.
static func seconds_to_night(t: float) -> float:
	return 0.0 if DayCycle.is_night(t) else seconds_until(t, DayCycle.SUNSET)


## Seconds until the sun rises (at night), or 0 by day.
static func seconds_to_morning(t: float) -> float:
	return seconds_until(t, DayCycle.SUNRISE) if DayCycle.is_night(t) else 0.0


## The clock counts to the morning (a sun) at night, to the night (a moon) by day.
static func clock_is_night(t: float) -> bool:
	return DayCycle.is_night(t)


## "Night in 1:20" by day, "Morning in 0:45" at night.
static func clock_line(t: float) -> String:
	if clock_is_night(t):
		return Lang.t("Morning in %s") % mm_ss(seconds_to_morning(t))
	return Lang.t("Night in %s") % mm_ss(seconds_to_night(t))


## "1:20" (seconds rounded up, so 0:00 shows only at the moment itself).
static func mm_ss(seconds: float) -> String:
	var s := maxi(ceili(seconds - 0.0001), 0)
	return "%d:%02d" % [s / 60, s % 60]


## The small line under the clock.
static func score_line(nights: int, best: int) -> String:
	return Lang.t("Nights %d · Best %d") % [nights, best]


## The morning's words for a player who got through the night outside a knock-out.
static func morning_line(nights: int, new_best: bool) -> String:
	var line := Lang.t("You made it through night %d!") % nights
	return line + " A new best!" if new_best else line
