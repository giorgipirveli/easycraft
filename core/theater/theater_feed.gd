class_name TheaterFeed
extends RefCounted
## Which channel list the Theater plays (owner #89; spec §5.12, §14.12). The owner keeps one on the server (module
## 0.2.17: theater_channels, tools/theater_list.py); a game that is online reads it when a world starts and keeps it
## on the device (CACHE_PATH), so the next start plays it even offline. Before that, and on a device that never
## goes online, the list bundled with the game (TheaterChannels.BUNDLED_PATH). The server's kill-switch
## ("enabled": false) is kept like any list; when the owner clears the server's list, the bundled one comes back.

const RPC := "theater_channels"
const CACHE_PATH := "user://theater_channels.json"


## The list to play now: the server's last one kept here, else the bundled one.
static func load_best(cache_path := CACHE_PATH, bundled_path := TheaterChannels.BUNDLED_PATH) -> Dictionary:
	if FileAccess.file_exists(cache_path):
		var kept := TheaterChannels.parse(FileAccess.get_file_as_string(cache_path))
		if kept.source == TheaterChannels.SOURCE_SERVER:
			return kept
	return TheaterChannels.load_path(bundled_path)


## The server's answer to theater_channels: the list to play from now on ({} = nothing new: keep playing what
## plays). A server list is kept on the device; "no list" deletes the kept one (the bundled list again).
static func keep(reply: Dictionary, cache_path := CACHE_PATH, bundled_path := TheaterChannels.BUNDLED_PATH) -> Dictionary:
	if reply.get("ok") != true or not reply.has("list"):
		return {}
	var list: Variant = reply.list
	if list == null:
		if FileAccess.file_exists(cache_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_path))
		return TheaterChannels.load_path(bundled_path)
	if not list is Dictionary:
		return {}
	var text := JSON.stringify(list)
	var parsed := TheaterChannels.parse(text)
	if parsed.source != TheaterChannels.SOURCE_SERVER:
		return {}
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
	return parsed


## Asks the server through a signed-in OnlineService (its status and backend) and keeps the answer. {} when the
## game is not online or nothing new came.
static func fetch(service: Object, cache_path := CACHE_PATH) -> Dictionary:
	if service == null or service.get("status") != OnlineService.ONLINE or service.get("backend") == null:
		return {}
	var reply: Dictionary = await service.backend.call_rpc(RPC, {})
	return keep(reply, cache_path)
