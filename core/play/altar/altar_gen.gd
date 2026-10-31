class_name AltarGen
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5's rules table, rulings 7 and 29, §4.3; the model's `make`):
## the altars a room offers, new every visit, seeded. The crystal's weight is a whole number the child never sees until
## it is freed; a pan holds at most 16 things in phase B so a child can count them (gems in rows of five; the twin
## forms are phase C's, their ranges set then). The forms and ranges are a countable part of the School's generators' (G6AlgebraGen.solve_one_step: x 1-15, a coefficient 2-12; its "+" and
## "-" forms start at 2, the altar's at 1: a single gem beside the crystal is the gentlest altar; G8AlgebraGen's both
## sides for the twin forms). Pure, no nodes.
##
## Forms ("_R": the pans swapped, the crystal on the right):
## - add_L / add_R: x + a = b (the hall: take);
## - mul_L / mul_R: c x = b (the hall: share);
## - two_L / two_R: c x + a = b (the Great Altar: take, then share);
## - sub_L / sub_R: x - a = b (balloons beside the crystal: the Sky Room);
## - subtwo_L: c x - a = b (the Sky Room's Great Altar);
## - twin_L / twin_R: a x + b = c x + d (crystals on both pans: wing 8, phase C).

const FORMS: Array[String] = ["add_L", "add_R", "mul_L", "mul_R", "two_L", "two_R", "sub_L", "sub_R", "subtwo_L",
	"twin_L", "twin_R"]


static func forms() -> Array[String]:
	return FORMS.duplicate()


## A new altar of `form`, its numbers drawn from `rng` in the model's order.
static func make(form: String, rng: RandomNumberGenerator) -> AltarState:
	var s: AltarState
	match form.trim_suffix("_L").trim_suffix("_R"):
		"add":
			var x := rng.randi_range(1, 8)
			var a := rng.randi_range(1, mini(6, 12 - x))
			s = AltarState.make(1, a, 0, x + a, x)
		"mul":
			var c := rng.randi_range(2, 4)
			var x := rng.randi_range(1, 12 / c)
			s = AltarState.make(c, 0, 0, c * x, x)
		"two":
			var c := rng.randi_range(2, 3)
			var x := rng.randi_range(1, 4)
			var a := rng.randi_range(1, 4)
			s = AltarState.make(c, a, 0, c * x + a, x)
		"sub":
			var a := rng.randi_range(1, 5)
			var b := rng.randi_range(1, 7)
			s = AltarState.make(1, -a, 0, b, a + b)
		"subtwo":
			var c := rng.randi_range(2, 3)
			var x := rng.randi_range(2, 5)
			var a := rng.randi_range(1, mini(4, c * x - 1))
			s = AltarState.make(c, -a, 0, c * x - a, x)
		"twin":
			var c := rng.randi_range(1, 3)
			var a := c + rng.randi_range(1, 3)
			var x := rng.randi_range(1, 5)
			var b := rng.randi_range(0, 5)
			s = AltarState.make(a, b, c, (a - c) * x + b, x)
		_:
			push_error("AltarGen: no form %s" % form)
			return AltarState.make(1, 1, 0, 2, 1)
	if form.ends_with("_R"):
		s = AltarState.make(s.rc, s.rk, s.lc, s.lk, s.x)
	return s


## A taught altar's fixed pans ([left crystals, left gems, right crystals, right gems]) and weight: the same every
## visit, so its lines ("Two crystals weighed six. So one weighs three!") stay true.
static func fixed(pans: Array, weight: int) -> AltarState:
	return AltarState.make(int(pans[0]), int(pans[1]), int(pans[2]), int(pans[3]), weight)
