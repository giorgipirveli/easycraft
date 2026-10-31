extends GutTest
## Owner #68, grade 5 maths (5.G.3, 5.G.4): the quadrilaterals' family tree (ShapeFamily). A family's properties belong
## to everyone below it; "every X is a Y" is true when Y is above X in the tree, false when it is not, and never asked
## when its answer depends on how a book defines a trapezium or a kite (the School's ruling). The shapes drawn for the
## tree have exactly the properties the tree gives them (a drawn parallelogram has no right angle), and triangles are
## sorted by sides and by angles.


func _drawn(what: String) -> Dictionary:
	var pts := ShapeFamily.points(what)
	var n := pts.size()
	var sides: Array[float] = []
	var right := 0
	var dirs: Array[Vector2] = []
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		sides.append(a.distance_to(b))
		dirs.append((b - a).normalized())
		var back := (pts[i - 1] - a).normalized()
		if absf(back.dot((b - a).normalized())) < 0.001:
			right += 1
	var parallel := 0
	for i in 2:
		if absf(dirs[i].cross(dirs[i + 2])) < 0.001:
			parallel += 1
	var eq := func(x: float, y: float) -> bool: return absf(x - y) < 0.001
	return {
		"four_sides": n == 4,
		"one_parallel": parallel >= 1,
		"two_parallel": parallel == 2,
		"right_angles": right == 4,
		"equal_sides": eq.call(sides[0], sides[1]) and eq.call(sides[1], sides[2]) and eq.call(sides[2], sides[3]),
		"opposite_equal": eq.call(sides[0], sides[2]) and eq.call(sides[1], sides[3]),
		"adjacent_equal": (eq.call(sides[0], sides[1]) and eq.call(sides[2], sides[3]))
			or (eq.call(sides[1], sides[2]) and eq.call(sides[3], sides[0])),
	}


func test_the_tree() -> void:
	assert_eq(ShapeFamily.NODES.size(), 7)
	assert_eq(ShapeFamily.parents("square"), ["rectangle", "rhombus"])
	assert_eq(ShapeFamily.parents("quadrilateral"), [])
	assert_true(ShapeFamily.ancestors("square").has("parallelogram"))
	assert_true(ShapeFamily.ancestors("square").has("quadrilateral"))
	assert_false(ShapeFamily.ancestors("rectangle").has("rhombus"))


func test_every_x_is_a_y() -> void:
	assert_eq(ShapeFamily.is_a("square", "rectangle"), ShapeFamily.ALWAYS)
	assert_eq(ShapeFamily.is_a("square", "rhombus"), ShapeFamily.ALWAYS)
	assert_eq(ShapeFamily.is_a("rectangle", "parallelogram"), ShapeFamily.ALWAYS)
	assert_eq(ShapeFamily.is_a("kite", "quadrilateral"), ShapeFamily.ALWAYS)
	assert_eq(ShapeFamily.is_a("rectangle", "square"), ShapeFamily.NOT_ALWAYS)
	assert_eq(ShapeFamily.is_a("parallelogram", "rhombus"), ShapeFamily.NOT_ALWAYS)
	assert_eq(ShapeFamily.is_a("trapezium", "parallelogram"), ShapeFamily.NOT_ALWAYS)
	assert_eq(ShapeFamily.is_a("rhombus", "rectangle"), ShapeFamily.NOT_ALWAYS)
	assert_eq(ShapeFamily.is_a("square", "kite"), ShapeFamily.DEPENDS, "some books call a square a kite")
	assert_eq(ShapeFamily.is_a("parallelogram", "trapezium"), ShapeFamily.DEPENDS, "some books call it a trapezium")


func test_a_familys_properties_belong_to_everyone_below_it() -> void:
	for p: String in ShapeFamily.PROPERTIES:
		for node: String in ShapeFamily.NODES:
			if ShapeFamily.has(node, p):
				for other: String in ShapeFamily.NODES:
					if ShapeFamily.ancestors(other).has(node):
						assert_true(ShapeFamily.has(other, p), "%s has %s like every %s" % [other, p, node])


func test_the_drawn_shapes_have_exactly_their_properties() -> void:
	for node: String in ShapeFamily.NODES:
		var seen := _drawn(node)
		for p: String in ShapeFamily.PROPERTIES:
			assert_eq(seen[p], ShapeFamily.has(node, p), "the drawn %s: %s" % [node, p])


func test_a_property_names_the_families_that_always_have_it() -> void:
	assert_eq(ShapeFamily.with_property("right_angles"), ["rectangle", "square"])
	assert_eq(ShapeFamily.with_property("equal_sides"), ["rhombus", "square"])


func test_names_and_plurals() -> void:
	assert_eq(ShapeFamily.plural("rhombus"), "rhombuses")
	assert_eq(ShapeFamily.plural("trapezium"), "trapeziums")
	assert_eq(ShapeFamily.plural("square"), "squares")


func test_triangles_by_sides_and_angles() -> void:
	assert_false(ShapeFamily.triangle_can_be("equilateral", "right"))
	assert_false(ShapeFamily.triangle_can_be("equilateral", "obtuse"))
	assert_true(ShapeFamily.triangle_can_be("equilateral", "acute"))
	assert_true(ShapeFamily.triangle_can_be("isosceles", "right"))
	assert_true(ShapeFamily.triangle_can_be("scalene", "obtuse"))
