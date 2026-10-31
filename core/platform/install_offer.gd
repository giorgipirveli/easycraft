class_name InstallOffer
extends RefCounted
## M7 (owner 2026-09-28: "when user start playing, they should get shortcut on the app so next time they just click
## and open it"): when the game offers to add itself to the device, as the page's loading screen does
## (web/shell.html's window.easycraftApp, asked through WebGlue.install_state). The main menu's card (InstallCard) comes
## only after some play, at most once a run, 3 days after the last answer, and never again after 3 NOT NOWs; SETTINGS'
## ADD TO THIS DEVICE is there whenever the page can add the game. Pure rules over the platform's features
## (PlatformRules), the page's install state and the profile's settings (install_not_now, install_asked_at).

## After an answer (ADD or NOT NOW) the card waits this long (seconds).
const WAIT_SECONDS := 3 * 24 * 60 * 60
## After this many NOT NOWs only SETTINGS offers it.
const MAX_NOT_NOW := 3
## Owner #59: where only the Home Screen gives full screen (the page's guide: iPhone, iPad, Mac Safari) the card comes
## back after this long and never stops ("remind them from time to time").
const GUIDE_WAIT_SECONDS := 24 * 60 * 60

## This run (a visit of the page): the menu has shown the card.
static var shown_this_run := false


## SETTINGS' ADD TO THIS DEVICE: in a browser whose page can add the game, while it is not added.
static func can_offer(f: Dictionary, state: Dictionary) -> bool:
	return PlatformRules.is_web(f) and state.get("can_install", false) == true and state.get("installed", false) != true


## The main menu's card: `played` = the child came back from a world this run or played before (the profile's
## progress); `shown` = the card was shown this run.
static func card_due(f: Dictionary, state: Dictionary, played: bool, settings: Dictionary, now: int,
		shown: bool) -> bool:
	if not can_offer(f, state) or not played or shown:
		return false
	var guide: bool = state.get("needs_guide", false) == true
	if not guide and int(settings.get("install_not_now", 0)) >= MAX_NOT_NOW:
		return false
	var since := now - int(settings.get("install_asked_at", 0))
	return since < 0 or since >= (GUIDE_WAIT_SECONDS if guide else WAIT_SECONDS)   # a clock set back never locks it away


## NOT NOW: one more, and the card waits.
static func note_not_now(settings: Dictionary, now: int) -> void:
	settings.install_not_now = int(settings.get("install_not_now", 0)) + 1
	settings.install_asked_at = now


## ADD: the card waits too (the browser's prompt may be turned down, Safari's steps not followed), but it is no NOT NOW.
static func note_add(settings: Dictionary, now: int) -> void:
	settings.install_asked_at = now
