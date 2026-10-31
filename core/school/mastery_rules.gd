class_name MasteryRules
extends RefCounted
## Owner #68 (spec §22.2, rulings 7-8): what a finished round does to a unit's progress (SchoolData's short keys).
## - Stars, never lost: ★ a round finished; ★★ a round with MASTER_RIGHT of ROUND_SIZE right the first time (mastered:
##   its reward, once); ★★★ mastered again on a later day than it was first mastered (remembered).
## - Spaced practice: once mastered, a review is suggested REVIEW_DAYS[step] days later; a good round on or after that
##   day moves to the next step, a harder one brings the next review to tomorrow. Nothing is lost or expires, a review
##   is never required, and a day going backwards (the clock changed) changes nothing earned.
## - Reading a lesson earns nothing by itself (no reward for opening lessons or for time).

const ROUND_SIZE := 6
const MASTER_RIGHT := 5
const REVIEW_DAYS: Array[int] = [1, 3, 7, 21, 60]
const MASTERED := 2
const REMEMBERED := 3
## The Survivor gold a unit gives, once, when it is first mastered (spec §22.2, ruling 8).
const UNIT_GOLD := 100


static func stars(p: Dictionary) -> int:
	return int(p.get("s", 0))


## True when right_first of total is as good as MASTER_RIGHT of ROUND_SIZE.
static func is_mastery(right_first: int, total: int) -> bool:
	return total > 0 and right_first * ROUND_SIZE >= MASTER_RIGHT * total


## A review is suggested (the stop's leaf, PRACTICE says REVIEW).
static func review_due(p: Dictionary, today: int) -> bool:
	return stars(p) >= MASTERED and today >= int(p.get("d", 0))


static func lesson_read(p: Dictionary) -> Dictionary:
	var out := p.duplicate()
	out.l = true
	return out


## A round of `total` exercises with `right_first` right the first time, finished on `today`:
## {progress, stars_before, stars, mastered_now, remembered_now, pay (the unit's gold is due now, once)}.
static func after_round(p: Dictionary, right_first: int, total: int, today: int) -> Dictionary:
	var out := {"progress": p, "stars_before": stars(p), "stars": stars(p), "mastered_now": false,
		"remembered_now": false, "pay": false}
	if total <= 0:
		return out
	right_first = clampi(right_first, 0, total)
	var q := p.duplicate()
	q.r = int(q.get("r", 0)) + 1
	q.a = int(q.get("a", 0)) + total
	q.f = int(q.get("f", 0)) + right_first
	q.b = maxi(int(q.get("b", 0)), roundi(100.0 * right_first / total))
	q.t = maxi(int(q.get("t", 0)), today)
	q.s = maxi(stars(q), 1)
	var good := is_mastery(right_first, total)
	var due := int(q.get("d", 0))
	if good and stars(q) < MASTERED:
		q.s = MASTERED
		q.m = today
		q.x = 0
		q.d = today + REVIEW_DAYS[0]
		out.mastered_now = true
	elif good:
		if stars(q) == MASTERED and today > int(q.get("m", 0)):
			q.s = REMEMBERED
			out.remembered_now = true
		if today >= due:
			q.x = mini(int(q.get("x", 0)) + 1, REVIEW_DAYS.size() - 1)
			q.d = today + REVIEW_DAYS[int(q.x)]
	elif stars(q) >= MASTERED and today >= due:
		q.x = 0
		q.d = today + REVIEW_DAYS[0]
	if out.mastered_now and not bool(q.get("p", false)):
		q.p = true
		out.pay = true
	out.progress = q
	out.stars = stars(q)
	return out


## A subject's certificate: every written unit (`unit_ids`) mastered; never for a subject with nothing written yet.
static func all_mastered(school: SchoolData, unit_ids: Array[String]) -> bool:
	if unit_ids.is_empty():
		return false
	for id in unit_ids:
		if stars(school.progress(id)) < MASTERED:
			return false
	return true
