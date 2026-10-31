class_name SchoolWords
extends RefCounted
## Owner #68 (spec §22.1, §6, research §1.8): what Professor Hoot says. Praise is for effort and strategy, never for
## talent; a miss is "not yet" with a hint, never "wrong"; nothing rushes, nags or guilts (test_no_guilt_words.gd).

const TEACHER := "Professor Hoot"
const HELLO := "Hoo-hoo! I'm Professor Hoot. Welcome to school!"
const PICK_GRADE := "Which grade are you in?"
## Owner #94: twelve lines, and a round starts at a different one each time (ExercisePanel.praise_from), so the
## praise is not the same six lines in the same order every round.
const RIGHT: Array[String] = ["Yes! You worked it out.", "That's it! Good thinking.", "Right! You checked carefully.",
	"Correct! Nice work.", "You got it!", "Yes! Your plan worked.", "Spot on! You read it carefully.",
	"Yes! You used what you learned.", "Right! You thought it through.", "That's it! Step by step.",
	"Yes! Careful work.", "Correct! You took your time."]
const RIGHT_AFTER_HELP: Array[String] = ["Yes! The hint helped you get there.", "You kept going and got it!",
	"There it is! Trying again paid off.", "Yes! Using the hint was a good plan.", "You got there by thinking again!"]
const NOT_YET: Array[String] = ["Not yet. Here is a hint:", "Almost! Try this:", "Let's think again:"]
const SHOW_HOW := "Let's look at it together:"
## Owner #94: after an answer right on the second try, the worked answer too, so a lucky tap still teaches.
const HERE_IS_WHY := "Here is why:"
const COMING_SOON := "Coming soon"
const REVIEW := "REVIEW"


static func right(i: int) -> String:
	return RIGHT[posmod(i, RIGHT.size())]


static func right_after_help(i: int) -> String:
	return RIGHT_AFTER_HELP[posmod(i, RIGHT_AFTER_HELP.size())]


static func not_yet(i: int) -> String:
	return NOT_YET[posmod(i, NOT_YET.size())]


## "5 of 6 right the first time!"
static func round_score(right_first: int, total: int) -> String:
	var good := MasteryRules.is_mastery(right_first, total)
	return "%d of %d right the first time%s" % [right_first, total, "!" if good else "."]


## The line under the score at a round's end.
static func round_end(right_first: int, total: int, mastered_now: bool) -> String:
	if mastered_now:
		return "You mastered this unit! Well done for working it out."
	if total > 0 and right_first == total:
		return "Every one right the first time. You really know this!"
	if MasteryRules.is_mastery(right_first, total):
		return "Great practice! You know this well."
	return "You finished the round! Every round makes it easier. Practise again for the next star."
