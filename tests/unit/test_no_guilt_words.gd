extends GutTest
## M2 Task 17 (owner feedback #21, spec §6 and §16): no on-screen text makes a child feel guilty,
## rushed or small. Every string literal in the game's code (comments are skipped) is checked against
## the words the research rejects (docs/design/engagement-and-child-psychology.md: no guilt lines, no
## timers that pressure, no shaming difficulty words).

const DIRS: Array[String] = ["res://autoloads", "res://core", "res://entities", "res://scenes", "res://ui", "res://world"]
## Word filters list the words they block; they are never shown to a child.
const FILTER_DIRS: Array[String] = ["res://core/validation/"]

## Whole words or phrases, matched case-insensitively.
const BANNED: Array[String] = ["miss you", "misses you", "missed you", "don't go", "dont go", "don't leave",
	"dont leave", "lonely", "is sad", "feels sad", "last chance", "hurry", "only today", "limited time",
	"you'll lose", "youll lose", "come back tomorrow", "before it's gone", "don't miss", "buy now",
	"you failed", "failure", "loser", "for babies", "baby mode", "noob", "are you sure you want to leave",
	"streak"]

var _literal := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"")


func _files(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_files(dir.path_join(d), out)


## The string literals of one line of code, stopping at a comment outside any string.
func _strings(line: String) -> Array[String]:
	var out: Array[String] = []
	var pos := 0
	for m in _literal.search_all(line):
		var hash := line.find("#", pos)
		if hash != -1 and hash < m.get_start():
			break
		out.append(m.get_string().substr(1, m.get_string().length() - 2))
		pos = m.get_end()
	return out


func _banned_in(text: String) -> String:
	var lower := text.to_lower()
	for phrase in BANNED:
		var re := RegEx.create_from_string("\\b" + phrase + "\\b")
		if re.search(lower):
			return phrase
	return ""


func test_the_checker_finds_banned_words_and_skips_comments() -> void:
	assert_eq(_strings("\tlabel.text = \"Hurry up!\"   # \"loser\" in a comment"), ["Hurry up!"] as Array[String])
	assert_eq(_banned_in("Hurry up!"), "hurry")
	assert_eq(_banned_in("Your pets are happy"), "")
	assert_eq(_banned_in("Streaks are gone"), "", "whole words only: 'streaks' is not 'streak'")


func test_no_game_text_uses_guilt_pressure_or_shaming_words() -> void:
	var files: Array[String] = []
	for d in DIRS:
		_files(d, files)
	assert_gt(files.size(), 50, "the game's code was found")
	var found: Array[String] = []
	for path in files:
		if FILTER_DIRS.any(func(d: String) -> bool: return path.begins_with(d)):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			if lines[i].strip_edges().begins_with("#"):
				continue
			for s in _strings(lines[i]):
				var hit := _banned_in(s)
				if hit != "":
					found.append("%s:%d \"%s\" (%s)" % [path, i + 1, s, hit])
	assert_eq(found, [] as Array[String], "\n".join(found))
