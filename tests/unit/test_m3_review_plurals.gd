extends GutTest
## M3 Task 19 (the whole-branch review): counts a child can make 1 said "1 stars" and "1 blocks": Storm Run's end
## ("Your team got 1 stars!"), the GAMES page's best, and COPY / /copy of a single block ("Copied 1 blocks!").


func test_one_star_is_a_star() -> void:
	assert_eq(GameWords.end_storm(1, false), "Your team got 1 star!")
	assert_eq(GameWords.end_storm(1, true), "Your team got 1 star! A new best!")
	assert_eq(GameWords.end_storm(9, true), "Your team got 9 stars! A new best!", "unchanged for more")


func test_the_games_page_best_of_one_star() -> void:
	assert_eq(GamesPanel.best_words(1), "Best: 1 star")
	assert_eq(GamesPanel.best_words(17), "Best: 17 stars")
	assert_eq(GamesPanel.best_words(0), "No best yet")


func test_copying_one_block() -> void:
	assert_eq(BuildToolUser.copied_words(1), "Copied 1 block! " + BuildToolUser.PASTE_HINT)
	assert_eq(BuildToolUser.copied_words(12), "Copied 12 blocks! " + BuildToolUser.PASTE_HINT)


## The review's "few rare 1 blocks lines" (a gift, a shelf build or a capture of one block, a secret 1 block away)
## say their count through Lang.blocks: "1 block", "2 blocks".
func test_a_count_of_blocks_says_one_block() -> void:
	assert_eq(Lang.blocks(1), "1 block")
	assert_eq(Lang.blocks(0), "0 blocks")
	assert_eq(Lang.blocks(12), "12 blocks")


func test_no_game_line_counts_blocks_without_lang_blocks() -> void:
	var bad := RegEx.create_from_string("(tr|Lang\\.t)\\(\"[^\"]*%d blocks")
	var allowed := RegEx.create_from_string("(max|At most|at most|1 to|in) %d")   # limits, never 1
	var found: Array[String] = []
	for dir in ["res://core", "res://ui", "res://scenes", "res://world", "res://entities", "res://autoloads"]:
		_scan(dir, bad, allowed, found)
	assert_eq(found, [] as Array[String], "\n".join(found))


func _scan(dir: String, bad: RegEx, allowed: RegEx, found: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), bad, allowed, found)
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".gd"):
			continue
		var lines := FileAccess.get_file_as_string(dir.path_join(f)).split("\n")
		for i in lines.size():
			if bad.search(lines[i]) != null and allowed.search(lines[i]) == null:
				found.append("%s:%d" % [dir.path_join(f), i + 1])
