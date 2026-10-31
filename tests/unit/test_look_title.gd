extends GutTest
## The first impression (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md): the living title diorama (the
## buddy on its island, the dog, the wand's star) stands beside the wordmark, whole and on the screen, on every screen
## shape the game runs on: under the wordmark it hid behind the menu's panels (only the buddy's head showed).

const R := preload("res://core/rules/title_diorama_rules.gd")
const ASPECTS: Array[float] = [4.0 / 3.0, 16.0 / 10.0, 16.0 / 9.0, 2.0, 20.0 / 9.0, 21.0 / 9.0]


## Canvas units (the menu's 720-high canvas, canvas_items stretch) per metre at `depth` in front of the 60° camera.
func _units_per_metre(depth: float) -> float:
	return R.CANVAS_HEIGHT * 0.5 / (depth * tan(deg_to_rad(R.FOV * 0.5)))


func test_it_stands_left_of_the_wordmark_on_every_screen_shape() -> void:
	for aspect in ASPECTS:
		var p := R.place(aspect)
		var at: Vector3 = p.position
		var s: float = p.scale
		var u := _units_per_metre(-at.z)
		var width := R.CANVAS_HEIGHT * aspect
		var left := width * 0.5 + (at.x - R.HALF_WIDTH * s) * u
		var right := width * 0.5 + (at.x + R.HALF_WIDTH * s) * u
		assert_gt(left, 0.0, "on the screen at %.2f" % aspect)
		assert_lt(right, (width - R.LOGO_WIDTH) * 0.5, "clear of the wordmark at %.2f" % aspect)
		var top := R.CANVAS_HEIGHT * 0.5 - (at.y + R.TOP * s) * u
		var grass := R.CANVAS_HEIGHT * 0.5 - at.y * u
		assert_gt(top, 0.0, "the buddy's head on the screen at %.2f" % aspect)
		assert_lt(grass, R.LOGO_BOTTOM, "the island's grass beside the wordmark, above the panels, at %.2f" % aspect)
		assert_between(s, 0.3, 0.6, "a small island at %.2f" % aspect)


func test_it_stays_in_front_of_the_camera_and_above_the_middle() -> void:
	for aspect in ASPECTS:
		var at: Vector3 = R.place(aspect).position
		assert_lt(at.z, -3.0)
		assert_gt(at.y / -at.z, 0.15)
		assert_lt(at.x, 0.0, "the left side (the child's name is on the right)")
