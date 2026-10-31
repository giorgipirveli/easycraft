extends GutTest
## Grade 3 design and technology, "Boxes and nets" (research §6.3): CubeNet decides whether squares joined edge to edge
## fold into a cube, and which face each square becomes; BuildCheck's "cube_net" goal ("build a net of a cube on the
## block board") uses it. Checked against a known fact worked out here from scratch: of the 35 free hexominoes, exactly 11
## are nets of a cube.

const CROSS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(1, 2)]


func _cells(rows: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows.size():
		for x in str(rows[y]).length():
			if str(rows[y])[x] != ".":
				out.append(Vector2i(x, y))
	return out


func test_the_cross_and_other_nets_fold() -> void:
	assert_true(CubeNet.folds(CROSS), "the cross")
	for rows: Array in [["#...", "####", "#..."], ["##..", ".###", "..#."], ["###..", "..###"], ["##..", ".##.", "..##"],
			["..#.", "####", ".#.."], ["#...", "###.", "..##"]]:
		assert_true(CubeNet.folds(_cells(rows)), str(rows))


func test_shapes_that_do_not_fold() -> void:
	# a row of 6, a block of 2 × 3, two flaps on the same side, a row of 5, two squares round a corner overlapping
	for rows: Array in [["######"], ["###", "###"], ["##..", "####"], ["####.", "...##"], ["#..#", "####"],
			["#####", "#...."], ["##.", "##.", ".##"], ["#...", "####", "...."], [".#..", "####"]]:
		assert_false(CubeNet.folds(_cells(rows)), str(rows))
	assert_false(CubeNet.folds(_cells(["##", "##"])), "four squares")
	assert_false(CubeNet.folds(_cells(["#....#", "####.."])), "not joined")
	assert_false(CubeNet.folds(_cells(["#...", "####", ".#.", "..#"])), "seven squares")


func test_eleven_of_the_35_hexominoes_fold() -> void:
	var free := {}
	var folding := {}
	for shape in _hexominoes():
		var key := _free_key(shape)
		free[key] = true
		if CubeNet.folds(shape):
			folding[key] = true
	assert_eq(free.size(), 35, "the free hexominoes")
	assert_eq(folding.size(), 11, "the nets of a cube")
	for key: String in folding:   # a net folds whichever way it is turned or flipped
		for shape in _forms(_from_key(key)):
			assert_true(CubeNet.folds(shape), key)


func test_every_face_is_different_and_opposites_are_three_apart() -> void:
	var faces := CubeNet.faces(CROSS)
	assert_eq(faces.size(), 6)
	var seen := {}
	for c: Vector2i in faces:
		seen[faces[c]] = true
	assert_eq(seen.size(), 6, "six different faces")
	# the cross's middle row: squares two apart are opposite faces
	assert_true(CubeNet.opposite(CROSS, Vector2i(0, 1), Vector2i(2, 1)))
	assert_true(CubeNet.opposite(CROSS, Vector2i(1, 1), Vector2i(3, 1)))
	assert_true(CubeNet.opposite(CROSS, Vector2i(1, 0), Vector2i(1, 2)))
	assert_false(CubeNet.opposite(CROSS, Vector2i(0, 1), Vector2i(1, 1)))
	assert_eq(CubeNet.faces(_cells(["###", "###"])), {}, "no faces for a shape that does not fold")


func test_the_build_board_goal() -> void:
	var board := {"cols": 6, "rows": 4, "block": 1, "given": [], "view": "farm"}
	var goal := {"kind": "cube_net"}
	assert_eq(BuildCheck.problem(goal, board), "")
	assert_true(BuildCheck.check(goal, board, CROSS))
	assert_false(BuildCheck.check(goal, board, _cells(["######"])))
	assert_false(BuildCheck.check(goal, board, CROSS + [Vector2i(4, 1)] as Array[Vector2i]), "seven squares")
	var ex := BuildCheck.example(goal, board)
	assert_eq(ex.size(), 6)
	assert_true(BuildCheck.check(goal, board, ex))
	assert_ne(BuildCheck.problem(goal, {"cols": 3, "rows": 3, "block": 1}), "", "no net fits a 3 × 3 board")


func test_the_goal_keeps_the_given_squares() -> void:
	var board := {"cols": 6, "rows": 4, "block": 1, "given": [[1, 1], [2, 1], [3, 1], [4, 1]], "view": "farm"}
	var goal := {"kind": "cube_net"}
	assert_eq(BuildCheck.problem(goal, board), "")
	var ex := BuildCheck.example(goal, board)
	for g in BuildCheck.given(board):
		assert_true(ex.has(g), "keeps %s" % g)
	assert_true(BuildCheck.check(goal, board, ex))
	# both extra squares on the same side of the row: not a net
	assert_false(BuildCheck.check(goal, board, BuildCheck.given(board) + [Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i]))
	assert_true(BuildCheck.check(goal, board, BuildCheck.given(board) + [Vector2i(1, 0), Vector2i(4, 2)] as Array[Vector2i]))
	assert_ne(BuildCheck.problem(goal, {"cols": 6, "rows": 4, "block": 1, "given": [[0, 0], [1, 1], [2, 0], [3, 1], [4, 0],
		[5, 1], [0, 2]]}), "", "seven given squares")


# --- Hexominoes, worked out here -----------------------------------------------------------------------------------

## Every fixed hexomino (216), grown square by square from one.
func _hexominoes() -> Array:
	var level := {_key([Vector2i.ZERO]): [Vector2i.ZERO]}
	for n in range(2, 7):
		var next := {}
		for k: String in level:
			var shape: Array = level[k]
			for c: Vector2i in shape:
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var p: Vector2i = c + d
					if shape.has(p):
						continue
					var grown: Array = shape.duplicate()
					grown.append(p)
					var norm := _normal(grown)
					next[_key(norm)] = norm
		level = next
	assert_eq(level.size(), 216, "fixed hexominoes")
	var out: Array = []
	for k: String in level:
		var typed: Array[Vector2i] = []
		typed.assign(level[k])
		out.append(typed)
	return out


func _normal(shape: Array) -> Array:
	var lo := Vector2i(1 << 20, 1 << 20)
	for c: Vector2i in shape:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var out: Array = []
	for c: Vector2i in shape:
		out.append(c - lo)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


func _key(shape: Array) -> String:
	return ";".join(shape.map(func(c: Vector2i) -> String: return "%d,%d" % [c.x, c.y]))


func _from_key(key: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for part in key.split(";"):
		var xy := part.split(",")
		out.append(Vector2i(int(xy[0]), int(xy[1])))
	return out


## The 8 ways a shape can be turned and flipped.
func _forms(shape: Array[Vector2i]) -> Array:
	var out: Array = []
	for flip in [false, true]:
		for turn in 4:
			var t: Array = []
			for c in shape:
				var p := Vector2i(-c.x, c.y) if flip else c
				for _i in turn:
					p = Vector2i(-p.y, p.x)
				t.append(p)
			var typed: Array[Vector2i] = []
			typed.assign(_normal(t))
			out.append(typed)
	return out


func _free_key(shape: Array[Vector2i]) -> String:
	var keys: Array[String] = []
	for f: Array in _forms(shape):
		keys.append(_key(f))
	keys.sort()
	return keys[0]
