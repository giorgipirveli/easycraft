class_name TheaterSession
extends RefCounted
## One visit to the Shorts Theater: which video is on screen, and when "That's the show!" comes
## (spec §5.12, §6, research H6; M3 Task 17; owner #89). The channels are the ones this player may see
## (TheaterRules.channels_for); NEXT and BACK walk through them in order, EasyCraft TV first; a tab picks a
## channel, a card a video of it.
##
## Every video shown counts (NEXT, BACK, a tab, a card). Once TheaterRules.end_card_after(band) have been shown,
## the next move shows the end card instead; so does the end of the list (never an endless feed). From the card
## the player chooses: back to the world, or more shows (the count starts again). Nothing moves by itself, and
## watching never gives anything.

signal changed

const PLAYING := &"playing"
const END_CARD := &"end_card"
const CLOSED := &"closed"
const END_LIMIT := &"limit"      # enough videos for now
const END_LIST := &"list_end"    # the list is over

var band: StringName
var channels: Array[Dictionary] = []
var channel := 0
var index := 0
var shown := 0
var state: StringName = CLOSED
var end_reason: StringName = &""


func _init(list: Dictionary, p_band: StringName) -> void:
	band = p_band
	channels = TheaterRules.channels_for(list, band)
	if not channels.is_empty():
		state = PLAYING
		shown = 1


func is_empty() -> bool:
	return channels.is_empty()


## The video on screen: {channel, channel_id, platform, color, icon, id, title, made_for_kids, from, index, count},
## or {}.
func current() -> Dictionary:
	if state != PLAYING or channels.is_empty():
		return {}
	var c: Dictionary = channels[channel]
	var v: Dictionary = c.videos[index]
	return {"channel": c.title, "channel_id": c.id, "platform": c.platform, "color": c.color, "icon": c.icon,
		"id": v.id, "title": v.title, "made_for_kids": v.made_for_kids, "from": v.get("from", ""), "index": index,
		"count": (c.videos as Array).size()}


## The current channel's videos (the cards under the player).
func videos() -> Array:
	return [] if channels.is_empty() else channels[channel].videos


func can_go_back() -> bool:
	return state == PLAYING and (channel > 0 or index > 0)


func next() -> bool:
	if state != PLAYING:
		return false
	if _limit_reached():
		_end(END_LIMIT)
		return true
	if not _advance():
		_end(END_LIST)
		return true
	_shown()
	return true


func previous() -> bool:
	if not can_go_back():
		return false
	if _limit_reached():
		_end(END_LIMIT)
		return true
	index -= 1
	if index < 0:
		channel -= 1
		index = (channels[channel].videos as Array).size() - 1
	_shown()
	return true


func pick_channel(i: int) -> bool:
	if state != PLAYING or i < 0 or i >= channels.size():
		return false
	if _limit_reached():
		_end(END_LIMIT)
		return true
	channel = i
	index = 0
	_shown()
	return true


## A card under the player: video `i` of the channel on screen.
func pick_video(i: int) -> bool:
	if state != PLAYING or channels.is_empty() or i < 0 or i >= (channels[channel].videos as Array).size():
		return false
	if _limit_reached():
		_end(END_LIMIT)
		return true
	index = i
	_shown()
	return true


## "More shows" on the end card: the count starts again with the next new video (or from the
## start once the list is over).
func more() -> void:
	if state != END_CARD:
		return
	if end_reason == END_LIST or not _advance():
		channel = 0
		index = 0
	state = PLAYING
	shown = 0
	_shown()


func close() -> void:
	state = CLOSED
	changed.emit()


func _limit_reached() -> bool:
	var limit := TheaterRules.end_card_after(band)
	return limit > 0 and shown >= limit


## Moves one video on, into the next channel when this one is over. False (and no move) at the end.
func _advance() -> bool:
	if index + 1 < (channels[channel].videos as Array).size():
		index += 1
		return true
	if channel + 1 < channels.size():
		channel += 1
		index = 0
		return true
	return false


func _shown() -> void:
	shown += 1
	changed.emit()


func _end(reason: StringName) -> void:
	state = END_CARD
	end_reason = reason
	changed.emit()
