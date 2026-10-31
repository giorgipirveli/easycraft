extends GutTest
## The lead (2026-10-17, after grade 8's humanities): the grown-ups' list cut every unit title longer than its column
## ("8. Volume of cylinders, cones and spheres" lost its end). Every grade's every subject now shows each title whole:
## on one line in a smaller size when it needs it, on two lines when even that is too long, and the page still fits
## the School's frame.

const MIN_FONT := 13

var profile: ProfileData
var screen: SchoolScreen


func before_each() -> void:
	ParentGate.reset_tries()
	Curriculum.clear_cache()
	profile = ProfileData.new()


func after_each() -> void:
	Curriculum.clear_cache()


func _page() -> SchoolGrownUpsPage:
	profile.school.grade = SchoolData.GRADES[0]
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	screen.today = func() -> int: return 20_000
	screen.next_seed = func() -> int: return 7
	add_child_autofree(screen)
	await wait_process_frames(2)
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	return screen.find_children("*", "SchoolGrownUpsPage", true, false)[0]


func test_every_units_title_shows_whole_in_every_grade_and_subject() -> void:
	var page := await _page()
	for g: int in SchoolData.GRADES:
		page.set_grade(g)
		for sub: Dictionary in Curriculum.subjects(g):
			page.show_subject(str(sub.id))
			var units := Curriculum.units(g, str(sub.id))
			for i in page.rows.size():
				var title := page.rows[i].get_child(0) as Label
				var u: Dictionary = units[i]
				assert_string_contains(title.text, str(u.title))
				var fs := title.get_theme_font_size("font_size")
				assert_gte(fs, MIN_FONT, "%s is readable" % u.title)
				var w := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var whole := w <= title.custom_minimum_size.x or (title.autowrap_mode != TextServer.AUTOWRAP_OFF and not title.clip_text)
				assert_true(whole, "grade %d %s: \"%s\" is %d wide in a %d column at %d" % [g, sub.id, title.text, w,
						title.custom_minimum_size.x, fs])


func test_the_grown_ups_page_fits_the_frame_in_every_grade_and_subject() -> void:
	var page := await _page()
	for g: int in SchoolData.GRADES:
		page.set_grade(g)
		for sub: Dictionary in Curriculum.subjects(g):
			page.show_subject(str(sub.id))
			await wait_process_frames(1)
			var size := screen.get_combined_minimum_size()
			assert_lte(size.x, SchoolUi.FRAME.x, "grade %d %s is %s" % [g, sub.id, size])
			assert_lte(size.y, SchoolUi.FRAME.y, "grade %d %s is %s" % [g, sub.id, size])
