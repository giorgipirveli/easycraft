class_name DailyData
extends RefCounted
## Owner #85 (brief 2026-09-30 item 1): the Daily Mission's part of the profile (ProfileData.daily), account-wide.
## - days: UTC day (DailyMission.day_of) -> {"s": the answers so far, "1" right the first time, "0" not; "g": the grade}.
##   A child who stops half-way goes on at the next question (the same mission all day). The last KEEP days are kept.
## - total: mission days finished, ever. It never goes down: a missed day is a rest day (the fair-fun rules reject
##   streak loss); week() shows the last 7 days as mission days and rest days, never as "missed".
## - paid: the last day whose stars paid gold (EarnRules.daily_gold: once a day, never back in time).
## merge_from never loses a day, an answer or the count (ProfileBackup).

const KEEP := 60
const MAX_DAY := 10_000_000

var days := {}
var total := 0
var paid := -1


func is_empty() -> bool:
	return days.is_empty() and total == 0 and paid < 0


func stars_of(day: int) -> String:
	var r: Variant = days.get(day)
	return str((r as Dictionary).get("s", "")) if r is Dictionary else ""


func grade_of(day: int) -> int:
	var r: Variant = days.get(day)
	return int((r as Dictionary).get("g", 0)) if r is Dictionary else 0


func is_done(day: int) -> bool:
	return stars_of(day).length() >= DailyMission.SIZE


## One answer of `day`'s mission (true: right the first time). The fifth finishes the day (a mission day more).
func answer(day: int, grade: int, right: bool) -> void:
	if day < 0 or day > MAX_DAY or is_done(day):
		return
	var s := stars_of(day) + ("1" if right else "0")
	days[day] = {"s": s, "g": grade if grade_of(day) == 0 else grade_of(day)}
	if s.length() >= DailyMission.SIZE:
		total += 1
	_trim()


## The last 7 days ending `today`, oldest first: 1 a mission day, 0 a rest day.
func week(today: int) -> Array[int]:
	var out: Array[int] = []
	for i in range(6, -1, -1):
		out.append(1 if is_done(today - i) else 0)
	return out


func _trim() -> void:
	if days.size() <= KEEP:
		return
	var keys: Array = days.keys()
	keys.sort()
	for i in keys.size() - KEEP:
		days.erase(keys[i])


func to_dict() -> Dictionary:
	var d := {}
	for k: int in days:
		d[str(k)] = (days[k] as Dictionary).duplicate()
	return {"days": d, "total": total, "paid": paid}


static func from_dict(v: Variant) -> DailyData:
	var out := DailyData.new()
	if not v is Dictionary:
		return out
	var d: Dictionary = v
	var list: Variant = d.get("days")
	if list is Dictionary:
		for k: Variant in list:
			var r: Variant = list[k]
			if not (str(k).is_valid_int() and r is Dictionary):
				continue
			var day := int(str(k))
			var s: Variant = (r as Dictionary).get("s")
			var g: Variant = (r as Dictionary).get("g", 0)
			if day < 0 or day > MAX_DAY or not s is String or (s as String).length() > DailyMission.SIZE \
					or (s as String).replace("1", "").replace("0", "") != "":
				continue
			out.days[day] = {"s": s, "g": int(g) if typeof(g) in [TYPE_INT, TYPE_FLOAT] and SchoolData.GRADES.has(int(g)) else 0}
	out._trim()
	out.total = _whole(d.get("total"))
	var done := 0
	for k: int in out.days:
		done += 1 if out.is_done(k) else 0
	out.total = maxi(out.total, done)
	var p: Variant = d.get("paid")
	out.paid = int(p) if typeof(p) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(p)) and float(p) >= 0.0 \
		and float(p) <= MAX_DAY else -1
	return out


static func _whole(v: Variant) -> int:
	return clampi(int(v), 0, MAX_DAY) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else 0


## Another copy of the account's profile: each day the further of the two, the higher count, the later day paid.
func merge_from(other: DailyData) -> void:
	for k: int in other.days:
		if other.stars_of(k).length() > stars_of(k).length():
			days[k] = (other.days[k] as Dictionary).duplicate()
	_trim()
	var done := 0
	for k: int in days:
		done += 1 if is_done(k) else 0
	total = maxi(maxi(total, other.total), done)
	paid = maxi(paid, other.paid)
