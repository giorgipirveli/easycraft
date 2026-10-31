class_name LabHeat
extends LabModel
## Melting and freezing (spec §23.1): a beaker of ice on a lab burner and a big thermometer in °C. WARM heats it one
## step, COOL stands it in an ice bath (ice with salt, colder than 0 °C). While the ice melts (and while water freezes)
## the thermometer stays at the melting point for ICE_PARTS taps; at the boiling point more heat makes it boil (steam)
## and it stays there. Done once the child saw it melt, boil and freeze again.

const ICE_PARTS := 2   # taps a whole beaker of ice takes to melt (or water to freeze)

var temp := 0
var ice := ICE_PARTS   # parts still ice: ICE_PARTS all ice, 0 all water
var boiling := false
var warming := false   # the last tap was WARM (the burner's flame shows)
var saw_melt := false
var saw_boil := false
var saw_freeze := false
var melt := 0
var boil := 100
var step := 20
var low := -20


func _init(s: Dictionary = {}) -> void:
	super(s)
	melt = int(s.get("melt", 0))
	boil = int(s.get("boil", 100))
	step = maxi(int(s.get("step", 20)), 1)
	low = int(s.get("low", -20))
	temp = int(s.get("start", low))
	ice = ICE_PARTS if temp <= melt else 0


func warm() -> void:
	warming = true
	if ice > 0:
		if temp < melt:
			temp = mini(temp + step, melt)
			last = "The ice warms up: %s." % degrees(temp) if temp < melt else "The ice has reached %s." % degrees(melt)
		else:
			ice -= 1
			if ice == 0:
				saw_melt = true
				last = "All the ice has melted into water, still at %s." % degrees(melt)
			else:
				last = "The ice is melting! The thermometer stays at %s." % degrees(melt)
	elif temp < boil:
		temp = mini(temp + step, boil)
		boiling = false
		last = "The water warms up: %s." % degrees(temp)
	else:
		boiling = true
		saw_boil = true
		last = "The water is boiling into steam at %s!" % degrees(boil)


func cool() -> void:
	warming = false
	boiling = false
	if ice == 0 and temp > melt:
		temp = maxi(temp - step, melt)
		last = "The water cools down: %s." % degrees(temp)
	elif ice < ICE_PARTS and temp == melt:
		ice += 1
		if ice == ICE_PARTS:
			saw_freeze = saw_freeze or saw_melt
			last = "The water has frozen into ice at %s." % degrees(melt)
		else:
			last = "The water is freezing! The thermometer stays at %s." % degrees(melt)
	else:
		temp = maxi(temp - step, low)
		last = "The ice gets colder: %s." % degrees(temp)


func done() -> bool:
	return saw_melt and saw_boil and saw_freeze


## What is in the beaker, in words.
func state_words() -> String:
	if ice == ICE_PARTS:
		return "Solid ice"
	if ice > 0:
		return "Ice and water"
	return "Water boiling into steam" if boiling else "Liquid water"


## "−20 °C" (the font's minus sign), "100 °C".
static func degrees(t: int) -> String:
	return ("−%d °C" % -t) if t < 0 else "%d °C" % t
