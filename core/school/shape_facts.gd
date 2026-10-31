class_name ShapeFacts
extends RefCounted
## Owner #68 (grade 4 maths: 4.G.2, 4.G.3, 4.MD.5): the shapes the School draws (SchoolPicture) and asks about
## (G4MathsGen), in one table, so a picture never disagrees with its question. Points are the corners as drawn (x right,
## y down), the facts are those of the drawing: "triangle_acute" is drawn isosceles, the regular polygons regular.

const MANY := -1   # a circle's lines of symmetry
const _R3 := 0.8660254

const SHAPES := {
	"square": {"name": "square", "points": [[0, 0], [1, 0], [1, 1], [0, 1]], "symmetry": 4, "right": 4, "parallel": 2},
	"rectangle": {"name": "rectangle", "points": [[0, 0], [1.6, 0], [1.6, 1], [0, 1]], "symmetry": 2, "right": 4,
		"parallel": 2},
	"rhombus": {"name": "rhombus", "points": [[0.5, 0], [1, 0.8], [0.5, 1.6], [0, 0.8]], "symmetry": 2, "right": 0,
		"parallel": 2},
	"parallelogram": {"name": "parallelogram", "points": [[0.4, 0], [1.6, 0], [1.2, 1], [0, 1]], "symmetry": 0,
		"right": 0, "parallel": 2},
	"trapezium": {"name": "trapezium", "points": [[0.4, 0], [1.2, 0], [1.6, 1], [0, 1]], "symmetry": 1, "right": 0,
		"parallel": 1},
	"kite": {"name": "kite", "points": [[0.5, 0], [1, 0.45], [0.5, 1.6], [0, 0.45]], "symmetry": 1, "right": 0,
		"parallel": 0},
	"triangle_right": {"name": "right-angled triangle", "points": [[0, 0], [0, 1], [1.3, 1]], "symmetry": 0, "right": 1,
		"parallel": 0},
	"triangle_acute": {"name": "acute triangle", "points": [[0.6, 0], [1.2, 1.1], [0, 1.1]], "symmetry": 1, "right": 0,
		"parallel": 0},
	"triangle_obtuse": {"name": "obtuse triangle", "points": [[0.35, 0.55], [1.6, 1], [0, 1]], "symmetry": 0, "right": 0,
		"parallel": 0},
	"triangle_equal": {"name": "equilateral triangle", "points": [[0.5, 0], [1, _R3], [0, _R3]], "symmetry": 3,
		"right": 0, "parallel": 0},
	"pentagon": {"name": "pentagon", "regular": 5, "symmetry": 5, "right": 0, "parallel": 0},
	"hexagon": {"name": "hexagon", "regular": 6, "symmetry": 6, "right": 0, "parallel": 3},
	"octagon": {"name": "octagon", "regular": 8, "symmetry": 8, "right": 0, "parallel": 4},
	"circle": {"name": "circle", "points": [], "symmetry": MANY, "right": 0, "parallel": 0},
}


static func knows(what: String) -> bool:
	return SHAPES.has(what)


## The corners as drawn (a regular polygon's around a circle of radius 0.5, the first corner at the top).
static func points(what: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	var s: Dictionary = SHAPES.get(what, {})
	if s.has("regular"):
		var n := int(s.regular)
		for i in n:
			var a := -PI / 2.0 + TAU * i / n + (PI / n if n % 2 == 0 else 0.0)
			out.append(Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * 0.5)
		return out
	for p: Array in s.get("points", []):
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


static func sides(what: String) -> int:
	return points(what).size()


static func symmetry(what: String) -> int:
	return int(SHAPES.get(what, {}).get("symmetry", 0))


static func right_angles(what: String) -> int:
	return int(SHAPES.get(what, {}).get("right", 0))


static func parallel_pairs(what: String) -> int:
	return int(SHAPES.get(what, {}).get("parallel", 0))


static func name_of(what: String) -> String:
	return str(SHAPES.get(what, {}).get("name", what))


## "acute" (< 90°), "right", "obtuse" (between 90° and 180°), "straight" or "reflex" (> 180°).
static func angle_kind(deg: int) -> String:
	if deg < 90:
		return "acute"
	if deg == 90:
		return "right"
	if deg < 180:
		return "obtuse"
	return "straight" if deg == 180 else "reflex"
