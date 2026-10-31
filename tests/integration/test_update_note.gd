extends GutTest
## Owner #123 (2026-10-17): the owner plays the web game on a phone and on a PC, and the two ran different versions: a
## phone's browser kept starting the copy it had stored. When a new version has downloaded during play, the menu says
## so calmly, with a RESTART button (on the web: the page loads again); nothing shows otherwise, and nothing hurries.

var update_is_ready := false
var restarts := 0


func _note() -> UpdateNote:
	var n := UpdateNote.new(func() -> bool: return update_is_ready, func() -> void: restarts += 1)
	add_child_autofree(n)
	return n


func test_nothing_shows_until_a_new_version_is_ready() -> void:
	var n := _note()
	n.poll()
	assert_false(n.visible)


func test_a_ready_update_shows_calm_words_and_restart() -> void:
	var n := _note()
	update_is_ready = true
	n.poll()
	assert_true(n.visible)
	assert_string_contains(n.words.text, "new EasyCraft is ready")
	n.restart_button.pressed.emit()
	assert_eq(restarts, 1)


func test_it_looks_again_by_itself() -> void:
	var n := _note()
	update_is_ready = true
	await wait_seconds(UpdateNote.POLL_SEC + 0.5)
	assert_true(n.visible, "the note polls on its own while the menu shows")


func test_off_the_web_the_page_answers_never() -> void:
	assert_false(WebGlue.update_ready(), "not the web: no page, no update")
