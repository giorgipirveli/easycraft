class_name MusicRules
extends RefCounted
## Which music plays when (M2 spec §12.10), as pure rules: a calm day loop, a tense night loop and a
## boss theme. The night music starts when the sun sets and ends when it rises (DayCycle.is_night),
## the same moments night monsters may come and go, so the music tells a child to get ready.
## A boss fight wins over both. The menu plays the day track. MusicMix does the cross-fades.

const DAY := &"day"
const NIGHT := &"night"
const BOSS := &"boss"
const TRACKS: Array[StringName] = [DAY, NIGHT, BOSS]
const MENU := DAY
const CROSSFADE := 2.5            # seconds from one track to the next (dusk, dawn, a boss fight)


static func track_for(time_of_day: float, boss: bool) -> StringName:
	if boss:
		return BOSS
	return NIGHT if DayCycle.is_night(time_of_day) else DAY
