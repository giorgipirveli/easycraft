extends GutTest
## Owner #68, grade 5 maths: what grade 5 writes for the eye and a voice must say in words: powers of ten with an
## exponent ("10³": "10 to the power of 3", 5.NBT.2), cubic units for volume ("24 cm³": "24 cubic centimetres",
## 5.MD.4) and points on a grid ("(4, 7)", 5.G.1).


func test_exponents_are_said_as_powers() -> void:
	assert_eq(SchoolSpeech.spoken("10³ = ?"), "10 to the power of 3 equals what?")
	assert_eq(SchoolSpeech.spoken("4 × 10⁵"), "4 times 10 to the power of 5")
	assert_eq(SchoolSpeech.spoken("10¹²"), "10 to the power of 12")


func test_cubic_units() -> void:
	assert_eq(SchoolSpeech.spoken("24 cm³"), "24 cubic centimetres")
	assert_eq(SchoolSpeech.spoken("1 m³"), "1 cubic metre")
	assert_eq(SchoolSpeech.spoken("V = ? cm³"), "V equals what cubic centimetres")


func test_a_point_keeps_its_pair() -> void:
	assert_eq(SchoolSpeech.spoken("Tap the point (4, 7)."), "Tap the point (4, 7).")
