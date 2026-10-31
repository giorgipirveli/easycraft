class_name PlayChoose
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §5.1, Choose by doing and Test it; the weakest bridge, said honestly in the
## notes): the options are things to act with, never buttons on a panel.
## - A choice is given or walked (`costume`): GIVE: each option is a crate on the table (its words or its picture) and the
##   child gives the right one to the buddy who needs it; PATH: each option is a signpost at the start of a path, and the
##   child sends the buddy down one to its gate. The round's seed picks the way (a unit's play block may choose one).
## - True or false is tested at two gates (GATE): TRUE and FALSE; the child opens one.
## The act is ExerciseCheck's response: the option's index for a choice, true or false for a claim.

const GIVE := "give"
const PATH := "path"
const GATE := "gate"
## The buddies who ask (the game's own people: the word problems' Tilly, Zara, Bram and Mimi; Life's Bobo and Lulu).
const BUDDIES: Array[Dictionary] = [
	{"name": "Tilly", "colour": Color("e8735a")}, {"name": "Zara", "colour": Color("8b6fd6")},
	{"name": "Bram", "colour": Color("3f9d5a")}, {"name": "Mimi", "colour": Color("e0a325")},
	{"name": "Bobo", "colour": Color("1fa6a0")}, {"name": "Lulu", "colour": Color("d9437a")}]


static func costume(ex: Dictionary, seed: int, preferred: String = "") -> String:
	if str(ex.get("type", "")) == "truefalse":
		return GATE
	if PlayBlock.COSTUMES.has(preferred):
		return preferred
	return GIVE if posmod(hash([seed, str(ex.get("id", "")), str(ex.get("prompt", ""))]), 2) == 0 else PATH


## The things to act with: {text, picture?} each (a claim's are TRUE and FALSE).
static func options(ex: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if str(ex.get("type", "")) == "truefalse":
		out.append({"text": "TRUE"})
		out.append({"text": "FALSE"})
		return out
	for c: Variant in ex.get("choices", []):
		if c is Dictionary:
			var d := {"text": str((c as Dictionary).get("text", ""))}
			if (c as Dictionary).get("picture") is Dictionary:
				d.picture = (c as Dictionary).picture
			out.append(d)
		else:
			out.append({"text": str(c)})
	return out


## ExerciseCheck's response for acting with option `i`.
static func response(ex: Dictionary, i: int) -> Variant:
	if str(ex.get("type", "")) == "truefalse":
		return i == 0
	return i


static func right_option(ex: Dictionary) -> int:
	if str(ex.get("type", "")) == "truefalse":
		return 0 if bool(ex.get("answer", false)) else 1
	return int(ex.get("answer", 0))


## The buddy who needs it this time: {name, colour}.
static func buddy(seed: int) -> Dictionary:
	return BUDDIES[posmod(seed, BUDDIES.size())]
