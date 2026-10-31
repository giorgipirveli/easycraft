// The Theater's channel list on the server (spec §5.12, §14.12; owner #89, module 0.2.17). One storage object,
// theater/channels, owned by the system user: everyone may read it (permissionRead 2), nobody but the server
// writes it (permissionWrite 0; the storage guard refuses a game's write to any collection but its profile).
//
//   theater_channels      any signed-in game (or the owner): {"ok", "list": the kept list, or null when there is none}
//   theater_set_channels  the owner only (the runtime HTTP key, or the console's API Explorer with no user id):
//                         {"list": {...}} keeps a list after TheaterListRules.check; {"clear": true} deletes it
//
// A game reads the list when it is online and keeps the last one on the device; a game that never went online
// plays the list bundled with it (data/theater/channels.json). tools/theater_list.py checks and sends a list.

namespace Theater {
  export const COLLECTION = "theater";
  export const KEY = "channels";

  export function read(nk: nkruntime.Nakama): Util.Json | null {
    const found = Store.read(nk, COLLECTION, KEY, Store.SYSTEM_USER);
    return found ? found.value : null;
  }

  export function write(nk: nkruntime.Nakama, list: Util.Json): void {
    nk.storageWrite([{
      collection: COLLECTION, key: KEY, userId: Store.SYSTEM_USER, value: list,
      permissionRead: 2, permissionWrite: 0,
    }]);
  }

  // The owner's payload, up to TheaterListRules.MAX_CHARS (a list is ~15 KB; every other RPC takes 4 KiB).
  export function parse(payload: string): Util.Json | null {
    if (payload === undefined || payload === null || payload === "") {
      return {};
    }
    if (typeof payload !== "string" || payload.length > TheaterListRules.MAX_CHARS + 64) {
      return null;
    }
    try {
      const data = JSON.parse(payload);
      return Util.isObject(data) ? data : null;
    } catch (_e) {
      return null;
    }
  }
}

// theater_channels {}: the list the owner keeps on the server, for every game (and the owner).
function rpcTheaterChannels(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpcOrAdmin(ctx, logger, "theater_channels", payload, function (_callerId: string): Util.Json {
    return { ok: true, list: Theater.read(nk) };
  });
}

// theater_set_channels {"list": {...}} or {"clear": true}: the owner only; a game gets not_allowed. A list with a
// mistake is refused whole: {"ok": false, "error": "bad_list", "problems": [...]} (at most 50 named).
function rpcTheaterSetChannels(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  if (ctx.userId) {
    return JSON.stringify(Server.fail("not_allowed"));
  }
  const request = Theater.parse(payload);
  if (request === null) {
    return JSON.stringify(Server.fail(typeof payload === "string" && payload.length > TheaterListRules.MAX_CHARS
      ? "too_big" : "bad_request"));
  }
  try {
    if (request.clear === true) {
      Store.remove(nk, Theater.COLLECTION, Theater.KEY, Store.SYSTEM_USER);
      logger.info("theater: the owner cleared the channel list (games play their bundled list)");
      return JSON.stringify({ ok: true, cleared: true });
    }
    const checked = TheaterListRules.check(request.list, Server.nowMs());
    if (!checked.list) {
      return JSON.stringify(Server.fail("bad_list", { problems: checked.problems.slice(0, 50) }));
    }
    Theater.write(nk, checked.list);
    const n = TheaterListRules.count(checked.list);
    logger.info("theater: the owner kept a channel list (%d channels, %d videos, enabled %s)", n.channels, n.videos,
      String(checked.list.enabled));
    return JSON.stringify({ ok: true, enabled: checked.list.enabled, channels: n.channels, videos: n.videos,
      updated_ms: checked.list.updated_ms });
  } catch (e) {
    logger.error("theater_set_channels failed: %s", Server.errorText(e));
    return JSON.stringify(Server.fail("server_error"));
  }
}
