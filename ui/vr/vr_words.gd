class_name VrWords
extends RefCounted
## VR on the Meta Quest (owner #101), the panel side: the words the VR screens say (English only, owner #52).

## The Theater's TV (YouTube in an Android WebView, or the browser page's player) is not drawn in a headset's view: its
## sign (the plan's ruling 7); EasyCraft Shorts are the game's own and play.
const TV_SIGN := "The TV plays on a phone or tablet."
const TV_SHORTS := "EasyCraft Shorts play here!"
const WATCH_SHORTS := "WATCH SHORTS"

## The VR COMFORT page (SETTINGS, only in a headset).
const PAGE := "VR COMFORT"
const TURNING := "Turning"
const TURN_WORDS := {"snap45": "SNAP 45°", "snap30": "SNAP 30°", "smooth": "SMOOTH"}
const VIGNETTE := "Comfort view"
const VIGNETTE_WORDS := {"strong": "STRONG", "light": "LIGHT", "off": "OFF"}
const TEXT := "Text size"
const TEXT_WORDS := {"normal": "NORMAL", "big": "BIG"}
const WALKING := "Walking"
const WALK_WORDS := {"head": "WHERE I LOOK", "hand": "WHERE I POINT"}
const HEIGHT := "Height"
const HEIGHT_WORDS := {"game": "GAME", "real": "MY OWN"}
const TELEPORT := "Teleport"
const TELEPORT_WORDS := {true: "ON", false: "OFF"}
const BREAK := "Break"
const BREAK_WORDS := {30: "30 MIN", 60: "60 MIN", 0: "NEVER"}
const RECENTER := "RECENTER"
const ABOUT := "SNAP turns in small jumps: kind to tummies."

## The break card (VrBreakCard).
const BREAK_TITLE := "Time for a break!"
const BREAK_SAY := "You have been in VR for %d minutes. Take the headset off and rest your eyes for a while: the game " \
	+ "waits for you."
const BREAK_BACK := "I'M BACK"
