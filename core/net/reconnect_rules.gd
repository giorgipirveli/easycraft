class_name ReconnectRules
extends RefCounted
## Owner #95 ("offline should save history and get upgraded after getting online"): when the game signs in again by
## itself. Everything a child does offline is kept on the device (the profile, its backup queue, the wallet's marker,
## codes used, invite and learning events) and sign-in sends it all (OnlineService.sign_in); before, only opening the
## main menu tried, once. ReconnectWatch asks these rules: a device that has been online before (the same as the
## menu's autostart), a build with a server, the service offline, and not a friend's world rejoining by itself
## (RejoinRules does that); then it tries, waiting longer after each failure.

## What the child reads when it worked (the HUD's toast, the menu).
const BACK_WORDS := "Back online! What you did offline is saved to your account now."

## Seconds to wait after the n-th failed try (the last one after that).
const WAITS: Array[float] = [20.0, 40.0, 80.0, 160.0, 300.0, 600.0]


static func wait_after(tries: int) -> float:
	return WAITS[clampi(tries - 1, 0, WAITS.size() - 1)]


static func should_try(wanted: bool, status: StringName, has_server: bool, busy: bool) -> bool:
	return wanted and has_server and status == OnlineService.OFFLINE and not busy
