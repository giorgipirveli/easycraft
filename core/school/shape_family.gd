class_name ShapeFamily
extends RefCounted
## Owner #68, grade 5 maths (5.G.3, 5.G.4): the quadrilaterals' family tree, drawn by SchoolPictureG5 ("family") and asked
## about by G5MeasureGen, in one table so a picture never disagrees with its question. A family's properties belong to
## every family below it: every square is a rectangle and a rhombus, so it has their right angles and equal sides.
## The School's ruling (notes owner-68-school-g5-maths.md): a trapezium has exactly one pair of parallel sides and a kite
## sits beside the parallelograms (as grade 4's ShapeFacts draws them). Books differ on whether a parallelogram is also a
## trapezium, or a rhombus also a kite, so `is_a` says DEPENDS for those and nothing ever asks them.
## Triangles are sorted two ways, by sides and by angles (`triangle_can_be`).

const ALWAYS := 1
const NOT_ALWAYS := 0
const DEPENDS := -1

## Top to bottom, as the tree is drawn.
const NODES: Array[String] = ["quadrilateral", "trapezium", "parallelogram", "kite", "rectangle", "rhombus", "square"]
const PARENTS := {"quadrilateral": [], "trapezium": ["quadrilateral"], "parallelogram": ["quadrilateral"],
	"kite": ["quadrilateral"], "rectangle": ["parallelogram"], "rhombus": ["parallelogram"], "square": ["rectangle", "rhombus"]}
## Each node's level in the drawn tree (0 at the top).
const LEVELS := {"quadrilateral": 0, "trapezium": 1, "parallelogram": 1, "kite": 1, "rectangle": 2, "rhombus": 2, "square": 3}
## A property -> [its words, the families that always have it].
const PROPERTIES := {
	"four_sides": ["4 straight sides", ["quadrilateral", "trapezium", "parallelogram", "kite", "rectangle", "rhombus", "square"]],
	"one_parallel": ["at least 1 pair of parallel sides", ["trapezium", "parallelogram", "rectangle", "rhombus", "square"]],
	"two_parallel": ["2 pairs of parallel sides", ["parallelogram", "rectangle", "rhombus", "square"]],
	"opposite_equal": ["opposite sides of equal length", ["parallelogram", "rectangle", "rhombus", "square"]],
	"right_angles": ["4 right angles", ["rectangle", "square"]],
	"equal_sides": ["4 sides of equal length", ["rhombus", "square"]],
	"adjacent_equal": ["2 pairs of equal sides next to each other", ["kite", "rhombus", "square"]],
}
## A quadrilateral with nothing special: no parallel, equal or right-angled sides (as drawn).
const _ANY_QUAD: Array = [[0, 0.2], [1.2, 0], [1.5, 1.0], [0.4, 0.8]]
const TRIANGLE_SIDES: Array[String] = ["equilateral", "isosceles", "scalene"]
const TRIANGLE_ANGLES: Array[String] = ["acute", "right", "obtuse"]


static func parents(what: String) -> Array:
	return (PARENTS.get(what, []) as Array).duplicate()


## Every family above `what` (its parents, theirs, …).
static func ancestors(what: String) -> Array[String]:
	var out: Array[String] = []
	var todo: Array = parents(what)
	while not todo.is_empty():
		var p := str(todo.pop_front())
		if not out.has(p):
			out.append(p)
			todo.append_array(parents(p))
	return out


## "Every <x> is a <y>": ALWAYS, NOT_ALWAYS, or DEPENDS (on a book's definition; never asked).
static func is_a(x: String, y: String) -> int:
	if x == y or ancestors(x).has(y):
		return ALWAYS
	var parallelograms := ["parallelogram"] + descendants("parallelogram")
	if parallelograms.has(x) and (y == "trapezium" or y == "kite"):
		return DEPENDS
	return NOT_ALWAYS


## Every family below `what`.
static func descendants(what: String) -> Array[String]:
	var out: Array[String] = []
	for n in NODES:
		if ancestors(n).has(what):
			out.append(n)
	return out


## True when every <what> has the property.
static func has(what: String, property: String) -> bool:
	return PROPERTIES.has(property) and (PROPERTIES[property][1] as Array).has(what)


static func property_words(property: String) -> String:
	return str(PROPERTIES.get(property, [property])[0])


## The families that always have the property, in the tree's order.
static func with_property(property: String) -> Array[String]:
	var out: Array[String] = []
	for n in NODES:
		if has(n, property):
			out.append(n)
	return out


static func plural(what: String) -> String:
	return what + ("es" if what.ends_with("s") else "s")


## "a rectangle", "an octagon"
static func with_article(what: String) -> String:
	return ("an " if "aeiou".contains(what.left(1)) else "a ") + what


## The corners as drawn (ShapeFacts' shapes; the general quadrilateral here).
static func points(what: String) -> PackedVector2Array:
	if what == "quadrilateral":
		var out := PackedVector2Array()
		for p: Array in _ANY_QUAD:
			out.append(Vector2(float(p[0]), float(p[1])))
		return out
	return ShapeFacts.points(what)


## Can a triangle be both (by its sides) and (by its angles)? Only an equilateral one is held back: its angles are all
## 60 degrees, so it is always acute.
static func triangle_can_be(by_sides: String, by_angles: String) -> bool:
	return by_sides != "equilateral" or by_angles == "acute"
