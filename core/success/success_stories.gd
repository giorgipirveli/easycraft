class_name SuccessStories
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.7; the brief: "twenty short read-aloud stories of real people who built
## things (inventors, nurses, teachers, farmers, engineers, founders; many countries; started small, failed, tried
## again, helped others), every fact checked with its source; no living-people politics, no brands' marketing; 'Which
## skill did they use?' questions"): data/success/stories.json. A story: {id, name, life (their years: people of the
## past only), country, she ("yes" for a woman), job, icon (SuccessIcons), title, skill (SKILLS: what the question
## asks), lines (5-7 short sentences, read aloud one at a time), question {say, choices [{text, icon, why}], answer},
## sources [{fact, url}] (every fact with its source; the stories' notes list them: docs/devlog/parts/success-s2.md)}.
## Reading one is kept in SuccessData.stories (the day first read, the question answered).

const PATH := "res://data/success/stories.json"
const MAX_LINE := 140
const SKILLS: Array[String] = ["kept_going", "try_again", "start_small", "helped", "team", "notice", "checked", "share",
	"courage", "generous", "patience", "improve", "use_what_you_have"]
const SKILL_WORDS := {"kept_going": "kept going", "try_again": "tried again", "start_small": "started small",
	"helped": "helped others", "team": "worked as a team", "notice": "noticed", "checked": "checked carefully",
	"share": "shared what they knew", "courage": "had courage", "generous": "was generous", "patience": "was patient",
	"improve": "made an idea better", "use_what_you_have": "used what they had"}

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {"stories": []}
	return _data


static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Variant in data().get("stories", []):
		if s is Dictionary:
			out.append(s)
	return out


static func story(id: String) -> Dictionary:
	for s in list():
		if str(s.id) == id:
			return s
	return {}


## Every word a child hears or reads in a story (its sources are for grown-ups and the experts' review).
static func texts(s: Dictionary) -> Array[String]:
	var out: Array[String] = [str(s.get("title", "")), str(s.get("name", "")), str(s.get("job", ""))]
	for line: Variant in s.get("lines", []):
		out.append(str(line))
	var q: Dictionary = s.get("question", {})
	out.append(str(q.get("say", "")))
	for c: Variant in q.get("choices", []):
		if c is Dictionary:
			out.append(str((c as Dictionary).get("text", "")))
			out.append(str((c as Dictionary).get("why", "")))
	return out


## The "Which skill did they use?" question as a choose step (LifeCheck's): written right-first, shown mixed.
static func question(s: Dictionary, seed: int = 0) -> Dictionary:
	var q: Dictionary = (s.get("question", {}) as Dictionary).duplicate(true)
	q.kind = "choose"
	q.id = "story_" + str(s.get("id", ""))
	var choices: Array = q.get("choices", [])
	if seed != 0 and choices.size() > 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed, str(s.get("id", ""))])
		var order: Array = range(choices.size())
		GenKit.shuffle(rng, order)
		var mixed: Array = []
		for i: int in order:
			mixed.append(choices[i])
		q.choices = mixed
		q.answer = order.find(int(q.get("answer", 0)))
	return q


## A story read on `day`, its question answered right or not (unknown stories are left out).
static func read(d: SuccessData, id: String, day: int, answered: bool) -> void:
	if not story(id).is_empty():
		d.mark_story(id, day, answered)


static func read_count(d: SuccessData) -> int:
	var n := 0
	for s in list():
		if d.story_read(str(s.id)):
			n += 1
	return n


static func answered_count(d: SuccessData) -> int:
	var n := 0
	for s in list():
		if bool(d.story(str(s.id)).a):
			n += 1
	return n


static func grown_ups_line(d: SuccessData) -> String:
	var n := read_count(d)
	if n == 0:
		return ""
	var a := answered_count(d)
	return "Success Stories: read %d of %d true stories; answered %d \"Which skill did they use?\" question%s." % [n,
		list().size(), a, "" if a == 1 else "s"]


## What is wrong with the stories' data ([] when nothing).
static func problems() -> Array[String]:
	var out: Array[String] = []
	var ids := {}
	for s in list():
		var id := str(s.get("id", ""))
		if not SuccessData.valid_id(id) or ids.has(id):
			out.append("a story's id: %s" % id)
		ids[id] = true
		for key: String in ["name", "life", "country", "job", "icon", "title", "skill"]:
			if str(s.get(key, "")) == "":
				out.append("%s has no %s" % [id, key])
		if not SKILLS.has(str(s.get("skill", ""))):
			out.append("%s: its skill %s is not one of SKILLS" % [id, s.get("skill")])
		var lines: Variant = s.get("lines")
		if not lines is Array or (lines as Array).size() < 5 or (lines as Array).size() > 7:
			out.append("%s needs 5-7 lines" % id)
		var q := question(s)
		if LifeCheck.problem(q) != "":
			out.append("%s: its question: %s" % [id, LifeCheck.problem(q)])
		var sources: Variant = s.get("sources")
		if not sources is Array or (sources as Array).size() < 2:
			out.append("%s needs two sources or more" % id)
	return out
