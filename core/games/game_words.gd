class_name GameWords
extends RefCounted
## What the co-op games say (M4 Wave 3, agent H; spec §6, §17.5): short, kind words; a round's clock is
## shown, never a "hurry"; nobody loses — the end of every round is a good game and a sticker for all.
## Bot friends' lines go to the chat marked as a bot (Session.bot_say).

const SEEK_START := "Ready or not, here we come!"
const YOU_SEEK := "You are the seeker! Count to 30."
const HINT := "A sparkle! Someone is hiding near it."
const STORM_START := "Storm Run! Grab the stars inside the circle!"
const PUSHED := "Back inside the circle!"
const AREA := "Hide a little closer to the start!"
const PHOTO_OFFER := "Team photo! Tap TEAM PHOTO."
const PHOTO_BUTTON := "TEAM PHOTO"
const SAY_CHEESE := "Say cheese!"
const WAVE_WAITS := "A game is on! The Totem waits for it."
const BOT_COUNTING := "I'm counting to 30! No peeking."
const BOT_SEEK := "Ready or not, here I come!"
const BOT_FOUND_ME := "You found me! Now I seek too."
const BOT_STAR := "Got a star for the team!"
const NOBODY := "Nobody is hiding in there."
const CLOSER := "Get closer to look inside!"
const REFUSALS := {
	&"running": "A game is on already!",
	&"wave": "Finish the wave first!",
	&"boss": "Beat the boss first!",
	&"alone": "Hide-and-seek needs a friend. Add a bot friend!",
}


## A round's clock: "2:41" (whole seconds, rounded up).
static func clock(seconds: float) -> String:
	var s := maxi(ceili(seconds), 0)
	return "%d:%02d" % [s / 60, s % 60]


static func refusal(key: StringName) -> String:
	return str(REFUSALS.get(key, ""))


## The HUD's round line for the player with `key` in a hide-and-seek round.
static func hide_line(r: HideSeekRound, key: String) -> String:
	var left := r.time_left()
	match r.phase:
		HideSeekRound.Phase.COUNTING:
			if r.is_seeker(key):
				return Lang.t("Counting... %d") % maxi(ceili(left), 0)
			return Lang.t("Hide! %s") % clock(left)
		HideSeekRound.Phase.SEEKING:
			if r.is_seeker(key):
				return Lang.t("Find them! %d of %d found · %s") % [r.found.size(), r.hiders.size(), clock(left)]
			if r.is_hiding(key):
				return Lang.t("Stay hidden! %s") % clock(left)
			return Lang.t("Hide-and-seek · %s") % clock(left)
		HideSeekRound.Phase.OVER:
			return "Great game!"
	return ""


## The HUD's round line in Storm Run: the team's stars, the clock and the world's best.
static func storm_line(s: StormRun) -> String:
	var line := Lang.t("Stars: %d · %s") % [s.score, clock(s.time_left() if s.running() else 0.0)]
	return line + (Lang.t(" · Best %d") % s.best if s.best > 0 else "")


static func seeker_is(seeker_name: String) -> String:
	return Lang.t("%s is the seeker! Hide!") % seeker_name


static func found(seeker_name: String, hider_name: String) -> String:
	return Lang.t("%s found %s!") % [seeker_name, hider_name]


static func found_you(seeker_name: String) -> String:
	return Lang.t("%s found you! Now you seek too.") % seeker_name


static func you_found(hider_name: String) -> String:
	return Lang.t("You found %s!") % hider_name


static func end_hide(result: StringName) -> String:
	match result:
		HideSeekRound.ALL_FOUND:
			return "Everyone was found! Great game!"
		HideSeekRound.TIME_UP:
			return "Time's up! Great hiding!"
	return "The game is over. Great game!"


static func end_storm(score: int, new_best: bool) -> String:
	var best := " A new best!" if new_best else ""
	if score == 1:   # M3 Task 19: never "1 stars"
		return Lang.t("Your team got 1 star!%s") % best
	return Lang.t("Your team got %d stars!%s") % [score, best]


static func sticker(kind: StringName, count: int) -> String:
	return Lang.t("Everyone gets a %s sticker! You have %d.") % [str(GameRules.STICKERS.get(String(kind), "game")), count]


static func bot_found(player_name: String) -> String:
	return Lang.t("Found you, %s!") % player_name
