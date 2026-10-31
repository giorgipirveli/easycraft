extends GutTest
## Owner #68 (grade 4 maths, 4.G.2, 4.G.3, 4.MD.5): the shapes the School draws and asks about, with the facts the
## questions use; the drawn corners agree with the facts (right angles really are right, the lines of symmetry really
## mirror the shape).


func test_every_shape_has_points_and_facts() -> void:
	for what: String in ShapeFacts.SHAPES:
		if what != "circle":
			assert_gte(ShapeFacts.points(what).size(), 3, what)
		assert_eq(ShapeFacts.points(what).size(), ShapeFacts.sides(what), "%s: a corner per side" % what)


func test_right_angles_match_the_drawing() -> void:
	for what: String in ShapeFacts.SHAPES:
		var pts := ShapeFacts.points(what)
		var right := 0
		for i in pts.size():
			var a := pts[i - 1] - pts[i]
			var b := pts[(i + 1) % pts.size()] - pts[i]
			if absf(a.normalized().dot(b.normalized())) < 0.01:
				right += 1
		assert_eq(right, ShapeFacts.right_angles(what), what)


func test_parallel_pairs_match_the_drawing() -> void:
	for what: String in ShapeFacts.SHAPES:
		var pts := ShapeFacts.points(what)
		var n := pts.size()
		var pairs := 0
		for i in n:
			for j in range(i + 1, n):
				var a := (pts[(i + 1) % n] - pts[i]).normalized()
				var b := (pts[(j + 1) % n] - pts[j]).normalized()
				if absf(a.cross(b)) < 0.01:
					pairs += 1
		assert_eq(pairs, ShapeFacts.parallel_pairs(what), what)


func test_lines_of_symmetry() -> void:
	assert_eq(ShapeFacts.symmetry("square"), 4)
	assert_eq(ShapeFacts.symmetry("rectangle"), 2)
	assert_eq(ShapeFacts.symmetry("triangle_equal"), 3)
	assert_eq(ShapeFacts.symmetry("parallelogram"), 0)
	assert_eq(ShapeFacts.symmetry("hexagon"), 6)
	assert_eq(ShapeFacts.symmetry("circle"), ShapeFacts.MANY)


func test_angle_kinds() -> void:
	assert_eq(ShapeFacts.angle_kind(35), "acute")
	assert_eq(ShapeFacts.angle_kind(90), "right")
	assert_eq(ShapeFacts.angle_kind(120), "obtuse")
	assert_eq(ShapeFacts.angle_kind(180), "straight")
	assert_eq(ShapeFacts.angle_kind(270), "reflex")


func test_names() -> void:
	assert_eq(ShapeFacts.name_of("triangle_right"), "right-angled triangle")
	assert_eq(ShapeFacts.name_of("trapezium"), "trapezium")
