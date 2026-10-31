class_name ReviveRules
extends RefCounted
## Helping a knocked-out teammate up (M4 Wave 2, Agent E; spec §17.5, §12.3), as pure rules. A
## knocked-out player with a teammate up nearby (CALL_DISTANCE) stays down a little longer
## (WAIT_TIME instead of KnockoutRules.KO_TIME, with GET UP to go at once). A teammate who holds HELP
## UP within REACH of them for HOLD_TIME helps them up right there, with full hearts; both cheer.
## Only a teammate who is still down can be helped (not one already getting up, who is protected),
## and only by a player who is up. The host decides all of it (KnockoutDirector) with its own
## positions; a game only asks. Sandbox and Survivor alike.

const HOLD_TIME := 3.0
const REACH := 3.0            # helper's feet to the friend's, in blocks (a giant reaches further)
const WAIT_TIME := 10.0       # down this long when a teammate could come and help
const CALL_DISTANCE := 24.0   # a teammate this close (and up) could come and help

## Why a help can't go on (&"" = it can).
const SELF := &"self"
const NOT_DOWN := &"not_down"
const PROTECTED := &"protected"
const HELPER_DOWN := &"helper_down"
const TOO_FAR := &"too_far"

const HELP_BUTTON := "HELP UP"
const GET_UP_BUTTON := "GET UP"
const WAITING := "A friend can help you up!"


## How long a knocked-out player stays down: as before when alone, a little longer when
## `teammates_near` could come and help.
static func down_time(teammates_near: int) -> float:
	return WAIT_TIME if teammates_near > 0 else KnockoutRules.KO_TIME


## Whether a teammate at `teammate` could come and help someone down at `down_at`.
static func calls_for_help(down_at: Vector3, teammate: Vector3) -> bool:
	return down_at.is_finite() and teammate.is_finite() and down_at.distance_to(teammate) <= CALL_DISTANCE


## The helper's feet near enough to the friend's (scaled for a giant helper, never below normal).
static func in_reach(helper: Vector3, friend: Vector3, helper_scale: float = 1.0) -> bool:
	if not helper.is_finite() or not friend.is_finite():
		return false
	return helper.distance_to(friend) <= REACH * maxf(helper_scale, 1.0)


static func refusal(helper: int, friend: int, friend_down: bool, friend_protected: bool, helper_down: bool,
		near: bool) -> StringName:
	if helper == friend:
		return SELF
	if not friend_down:
		return NOT_DOWN
	if friend_protected:
		return PROTECTED
	if helper_down:
		return HELPER_DOWN
	if not near:
		return TOO_FAR
	return &""


static func progress(held: float) -> float:
	return clampf(held / HOLD_TIME, 0.0, 1.0)


static func done(held: float) -> bool:
	return held >= HOLD_TIME - 0.0001


## What the helper hears when the host says no ("" when there is nothing to say).
static func refusal_message(why: StringName) -> String:
	match why:
		TOO_FAR:
			return "Get closer to help your friend up!"
		HELPER_DOWN:
			return "Get up first, then help!"
	return ""


static func helping_you(helper: String) -> String:
	return Lang.t("%s is helping you up!") % helper


static func helped_you(helper: String) -> String:
	return Lang.t("%s helped you up!") % helper


static func you_helped(friend: String) -> String:
	return Lang.t("You helped %s up!") % friend


static func someone_helped(helper: String, friend: String) -> String:
	return Lang.t("%s helped %s up!") % [helper, friend]
