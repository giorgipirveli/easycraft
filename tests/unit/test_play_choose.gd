extends GutTest
## Owner #122 (docs/design/learning-is-play.md §5.1, the weakest bridge): Choose by doing (a choice) and Test it (true or
## false) are acts, never buttons on a panel: give the right thing to the buddy who needs it, or take the path to the
## right gate; a claim is tested at the TRUE gate or the FALSE gate. The act makes ExerciseCheck's response.

const CHOICE := {"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 1,
	"hint": "No hundreds."}
const TF := {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": false, "hint": "Tens place."}


func test_a_choice_is_given_or_walked() -> void:
	var seen := {}
	for seed in 20:
		seen[PlayChoose.costume(CHOICE, seed)] = true
	assert_eq(seen.keys().size(), 2, "both ways, by the round's seed")
	assert_true(seen.has("give") and seen.has("path"))
	assert_eq(PlayChoose.costume(CHOICE, 3, "path"), "path", "a unit's play block may choose")
	assert_eq(PlayChoose.costume(TF, 3), "gate")


func test_the_things_to_act_with_are_the_choices() -> void:
	assert_eq(PlayChoose.options(CHOICE).size(), 3)
	assert_eq(str(PlayChoose.options(CHOICE)[0].text), "3,025")
	assert_eq(str(PlayChoose.options(TF)[0].text), "TRUE")
	assert_eq(str(PlayChoose.options(TF)[1].text), "FALSE")


func test_the_act_is_the_response() -> void:
	assert_true(ExerciseCheck.is_right(CHOICE, PlayChoose.response(CHOICE, PlayChoose.right_option(CHOICE))))
	assert_false(ExerciseCheck.is_right(CHOICE, PlayChoose.response(CHOICE, 0)))
	assert_eq(PlayChoose.right_option(TF), 1, "FALSE is the right gate")
	assert_true(ExerciseCheck.is_right(TF, PlayChoose.response(TF, 1)))
	assert_false(ExerciseCheck.is_right(TF, PlayChoose.response(TF, 0)))


func test_the_buddy_who_needs_it_changes_with_the_seed() -> void:
	var names := {}
	for seed in 30:
		names[str(PlayChoose.buddy(seed).name)] = true
	assert_gt(names.size(), 2)
