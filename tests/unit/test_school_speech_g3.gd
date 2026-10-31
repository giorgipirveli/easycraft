extends GutTest
## Owner #70, grade 3 science and English: what grade 3 writes for the eye and a voice must say in words. Weather
## tables and climates write temperatures as "21 °C" and "−30 °C": said "21 degrees Celsius", "minus 30 degrees
## Celsius" (not "degreesC"); an angle keeps "degrees".
## And grade 3 maths: what grade 3 writes for the eye and a voice must say in words: line plots of lengths in
## halves and quarters ("2½ cm": "2 and a half centimetres", 3.MD.4), the units after them, and 24-hour times as they are.


func test_temperatures_are_said_in_degrees_celsius() -> void:
	assert_eq(SchoolSpeech.spoken("Tuesday was 21 °C, the warmest."), "Tuesday was 21 degrees Celsius, the warmest.")
	assert_eq(SchoolSpeech.spoken("It is −30 °C."), "It is minus 30 degrees Celsius.")
	assert_eq(SchoolSpeech.spoken("a thermometer, in degrees Celsius (°C)"),
		"a thermometer, in degrees Celsius (degrees Celsius)")


func test_an_angle_keeps_its_degrees() -> void:
	assert_eq(SchoolSpeech.spoken("a 90° angle"), "a 90 degrees angle")


func test_halves_and_quarters_after_a_whole_number() -> void:
	assert_eq(SchoolSpeech.spoken("How many leaves are 2½ cm long?"), "How many leaves are 2 and a half centimetres long?")
	assert_eq(SchoolSpeech.spoken("3¼ cm"), "3 and a quarter centimetres")
	assert_eq(SchoolSpeech.spoken("1¾ m"), "1 and 3 quarters metres")


func test_a_half_or_a_quarter_alone() -> void:
	assert_eq(SchoolSpeech.spoken("½ cm"), "a half centimetres")
	assert_eq(SchoolSpeech.spoken("¼, ½ and ¾ of a centimetre"), "a quarter, a half and 3 quarters of a centimetre")


func test_what_grade_4_writes_is_said_as_before() -> void:
	assert_eq(SchoolSpeech.spoken("3/4 + 1/4 = ?"), "3 quarters plus 1 quarter equals what?")
	assert_eq(SchoolSpeech.spoken("5 km = ? m"), "5 kilometres equals what metres")
