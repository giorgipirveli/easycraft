extends GutTest
## P5 (VR draws): CanvasBatch gathers the HUD's little drawn pictures (polygons, circles, lines, arcs, rects: each its own
## draw call in Godot 4's canvas renderer) into one triangle list with a colour per vertex, so a picture is one draw in
## the headset's HUD canvas instead of up to sixty. The same calls as a CanvasItem's (draw_colored_polygon, draw_circle,
## draw_line, draw_polyline, draw_arc, draw_rect, draw_set_transform).

const RED := Color(1, 0, 0, 1)
const BLUE := Color(0, 0, 1, 0.5)


func _valid(b: CanvasBatch) -> void:
	assert_eq(b.indices.size() % 3, 0, "whole triangles")
	assert_eq(b.colors.size(), b.points.size(), "a colour per vertex")
	for i: int in b.indices:
		assert_true(i >= 0 and i < b.points.size(), "index %d inside" % i)


func test_a_polygon_is_its_points_and_their_triangles() -> void:
	var b := CanvasBatch.new()
	b.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]), RED)
	assert_eq(b.points.size(), 4)
	assert_eq(b.indices.size(), 6, "two triangles")
	for c: Color in b.colors:
		assert_eq(c, RED)
	_valid(b)


func test_a_concave_polygon_is_triangulated_inside_its_outline() -> void:
	var b := CanvasBatch.new()
	var l := PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 5), Vector2(5, 5), Vector2(5, 20), Vector2(0, 20)])
	b.draw_colored_polygon(l, RED)
	assert_eq(b.indices.size(), 12, "an L of six corners: four triangles")
	for t in range(0, b.indices.size(), 3):
		var mid := (b.points[b.indices[t]] + b.points[b.indices[t + 1]] + b.points[b.indices[t + 2]]) / 3.0
		assert_true(Geometry2D.is_point_in_polygon(mid, l), "triangle %d inside the L" % (t / 3))


func test_the_draw_transform_moves_and_scales_what_follows() -> void:
	var b := CanvasBatch.new()
	b.draw_set_transform(Vector2(100, 50), 0.0, Vector2(2, 2))
	b.draw_rect(Rect2(0, 0, 1, 1), RED)
	assert_eq(b.points[0], Vector2(100, 50))
	assert_eq(b.points[2], Vector2(102, 52))
	b.draw_set_transform(Vector2.ZERO)
	b.draw_rect(Rect2(0, 0, 1, 1), RED)
	assert_eq(b.points[4], Vector2.ZERO)


func test_a_circle_is_a_fan_inside_its_radius() -> void:
	var b := CanvasBatch.new()
	b.draw_circle(Vector2(50, 50), 10.0, BLUE)
	assert_gt(b.points.size(), 12, "round enough")
	for p: Vector2 in b.points:
		assert_lte(p.distance_to(Vector2(50, 50)), 10.001)
	assert_almost_eq(b.points[b.points.size() - 1].distance_to(Vector2(50, 50)), 10.0, 0.001, "the rim at the radius")
	_valid(b)


func test_an_antialiased_line_has_a_soft_edge() -> void:
	var b := CanvasBatch.new()
	b.draw_line(Vector2(0, 0), Vector2(100, 0), RED, 4.0, true)
	var ys: Array[float] = []
	for i in b.points.size():
		ys.append(absf(b.points[i].y))
		if absf(absf(b.points[i].y) - 2.0) < 0.001:
			assert_eq(b.colors[i].a, 1.0, "the line's own edge")
		elif absf(b.points[i].y) > 2.5:
			assert_eq(b.colors[i].a, 0.0, "the feather's outer edge: clear")
	assert_almost_eq(ys.max(), 2.0 + CanvasBatch.FEATHER, 0.001, "a pixel of feather")
	_valid(b)
	var hard := CanvasBatch.new()
	hard.draw_line(Vector2(0, 0), Vector2(100, 0), RED, 4.0)
	assert_eq(hard.points.size(), 4, "no feather without antialiasing")


func test_a_closed_polyline_and_an_arc_are_whole_triangles() -> void:
	var b := CanvasBatch.new()
	var ring := PackedVector2Array()
	for k in 9:
		ring.append(Vector2(cos(k * TAU / 8.0), sin(k * TAU / 8.0)) * 20.0)
	b.draw_polyline(ring, RED, 3.0, true)
	b.draw_arc(Vector2(0, 0), 30.0, 0.0, PI, 12, BLUE, 2.0, true)
	_valid(b)
	assert_gt(b.indices.size(), 0)


func test_a_rect_outline_is_four_sides() -> void:
	var b := CanvasBatch.new()
	b.draw_rect(Rect2(0, 0, 10, 10), RED, false, 2.0)
	assert_eq(b.indices.size(), 4 * 6, "four quads")
	_valid(b)


func test_a_flush_hands_the_triangles_over_and_starts_empty() -> void:
	var c := Control.new()
	add_child_autofree(c)
	var b := CanvasBatch.new()
	assert_true(b.is_empty())
	b.draw_circle(Vector2(5, 5), 4.0, RED)
	assert_false(b.is_empty())
	b.flush(c)
	assert_true(b.is_empty())
	assert_eq(b.points.size(), 0)


func test_a_rounded_box_is_its_fill_and_its_border_inside_its_rect() -> void:
	var b := CanvasBatch.new()
	var r := Rect2(10, 10, 60, 40)
	b.draw_rounded_box(r, 10.0, RED, BLUE, 3.0)
	_valid(b)
	var has_red := false
	var has_blue := false
	for i in b.points.size():
		assert_true(r.grow(CanvasBatch.FEATHER + 0.01).has_point(b.points[i]), "inside the box (and its feather)")
		assert_gt(b.points[i].distance_to(r.position), 2.0, "the corner is round")
		has_red = has_red or b.colors[i] == RED
		has_blue = has_blue or b.colors[i] == BLUE
	assert_true(has_red, "the fill")
	assert_true(has_blue, "the border")
