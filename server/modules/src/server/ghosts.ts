// Ghost races on friends' courses (M4; spec §17.5, docs/design T2). A player's best run on a course they
// built travels as a ghost (GhostRules): on their showcase, for friends who visit it, or with a blueprint
// gift. The same guards as showcases (spec §17.2): friends only, the player allowed online (verified
// parental consent for under_13), a child who may not be online is "not_found". The server checks every
// ghost against its course (its START and FINISH are in the showcase or the gift, and the run is one a
// child could make), keeps them small and few, and nobody but friends ever sees a time: no ranking.
// Storage (server only, permissionRead 0: the game reads through these RPCs):
//   ghosts   "showcase": {"ghosts": [{ghost_id, start, finish, ms, path, look, updated_ms}]}, one per
//            course, at most GhostRules.PER_SHOWCASE; a new showcase (or none) takes them down
//   gifts    a gift with a ghost keeps it in its own object ("ghost"); open_gift gives it
//   limits   "ghosts": the share window ({"times"})

namespace Ghosts {
  export const GHOSTS = "ghosts";
  export const KEY = "showcase";
  export const OWN_COLLECTIONS = [GHOSTS]; // Deletion.COLLECTIONS takes it in

  // The showcase's ghosts as stored (well-formed entries only).
  export function listOf(nk: nkruntime.Nakama, userId: string): { ghosts: Util.Json[]; version: string } {
    const found = Store.read(nk, GHOSTS, KEY, userId);
    const out: Util.Json[] = [];
    const raw = found && found.value.ghosts instanceof Array ? found.value.ghosts : [];
    for (let i = 0; i < raw.length; i++) {
      const g = raw[i];
      if (Util.isObject(g) && typeof g.ghost_id === "string" && typeof g.path === "string") {
        out.push(g);
      }
    }
    return { ghosts: out, version: found ? found.version : "*" };
  }

  // Writes the showcase's ghosts (deleted when none are left).
  export function save(nk: nkruntime.Nakama, userId: string, ghosts: Util.Json[], version: string): void {
    if (ghosts.length === 0) {
      if (version !== "*") {
        nk.storageDelete([{ collection: GHOSTS, key: KEY, userId: userId, version: version }]);
      }
      return;
    }
    Store.write(nk, GHOSTS, KEY, userId, { ghosts: ghosts }, false, version);
  }

  // A new showcase is a new area (its cells moved), and no showcase has no ghosts: publish_showcase calls this.
  export function forget(nk: nkruntime.Nakama, userId: string): void {
    Store.remove(nk, GHOSTS, KEY, userId);
  }

  // A ghost as the game reads it.
  export function out(g: Util.Json): Util.Json {
    return { ghost_id: g.ghost_id, start: g.start, finish: g.finish, ms: g.ms, path: g.path, look: g.look,
      updated_ms: g.updated_ms };
  }

  // The server's copy of one showcase ghost of `ownerId` (for a report), or null.
  export function find(nk: nkruntime.Nakama, ownerId: string, ghostId: unknown): Util.Json | null {
    const list = listOf(nk, ownerId).ghosts;
    for (let i = 0; i < list.length; i++) {
      if (list[i].ghost_id === ghostId) {
        return out(list[i]);
      }
    }
    return null;
  }

  // A reporter's copy of a ghost, kept as it came when it has a ghost's shape (sizes capped), else null.
  export function reporterCopy(g: unknown): Util.Json | null {
    if (!Util.isObject(g) || typeof g.path !== "string" || g.path.length > GhostRules.MAX_PATH_TEXT ||
        !GhostRules.isLook(g.look === undefined ? "" : g.look)) {
      return null;
    }
    return { start: g.start, finish: g.finish, ms: g.ms, path: g.path, look: g.look === undefined ? "" : g.look };
  }

  // On the player's own showcase: checked against its build, one per course (a new run of the same course
  // replaces the old), at most PER_SHOWCASE, SHARES_PER_HOUR shares an hour.
  export function onShowcase(nk: nkruntime.Nakama, userId: string, request: Util.Json): Util.Json {
    if (!AccountRules.canPlayOnline(Accounts.load(nk, userId).state)) {
      return Server.fail("not_allowed_online");
    }
    const shown = Store.read(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, userId);
    const area: { build?: BuildRules.Decoded; error?: string } = shown ? BuildRules.decode(shown.value.build, GiftRules.SHOWCASE) : {};
    if (!area.build) {
      return Server.fail("no_showcase");
    }
    const c = GhostRules.check(request.ghost, area.build.size, area.build.cells);
    if (!c.ghost) {
      return Server.fail(c.error || "bad_ghost");
    }
    const g = c.ghost;
    const now = Server.nowMs();
    const current = listOf(nk, userId);
    const kept: Util.Json[] = [];
    for (let i = 0; i < current.ghosts.length; i++) {
      const s = current.ghosts[i].start;
      if (!(s instanceof Array && s[0] === g.start[0] && s[1] === g.start[1] && s[2] === g.start[2])) {
        kept.push(current.ghosts[i]);
      }
    }
    if (kept.length >= GhostRules.PER_SHOWCASE) {
      return Server.fail("too_many_ghosts");
    }
    if (!Gifts.takeSend(nk, userId, GHOSTS, GhostRules.SHARES_PER_HOUR, now)) {
      return Server.fail("too_fast");
    }
    const id = GiftRules.keyFor("h", now, nk.uuidv4());
    kept.push({ ghost_id: id, start: g.start, finish: g.finish, ms: g.ms, path: g.path, look: g.look, updated_ms: now });
    save(nk, userId, kept, current.version);
    return { ok: true, ghost_id: id, ms: g.ms };
  }

  // With a blueprint gift: the gift's own rules (friends, sizes, caps, windows) and the ghost checked
  // against the gift's build.
  export function withGift(nk: nkruntime.Nakama, userId: string, request: Util.Json): Util.Json {
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Gifts.refusal(pair.error, "cannot_gift_self");
    }
    const d = BuildRules.decode(request.build, GiftRules.GIFT);
    if (!d.build) {
      return Server.fail(d.error || "bad_build");
    }
    const c = GhostRules.check(request.ghost, d.build.size, d.build.cells);
    if (!c.ghost) {
      return Server.fail(c.error || "bad_ghost");
    }
    return Gifts.deliver(nk, pair, Gifts.GIFTS, { build: request.build, size: d.build.size, count: d.build.count, ghost: c.ghost });
  }

  export function remove(nk: nkruntime.Nakama, userId: string, ghostId: unknown): Util.Json {
    const current = listOf(nk, userId);
    const kept: Util.Json[] = [];
    for (let i = 0; i < current.ghosts.length; i++) {
      if (current.ghosts[i].ghost_id !== ghostId) {
        kept.push(current.ghosts[i]);
      }
    }
    if (kept.length === current.ghosts.length) {
      return Server.fail("not_found");
    }
    save(nk, userId, kept, current.version);
    return { ok: true, removed: true };
  }
}

// share_ghost: a ghost (GhostRules: {"start", "finish", "ms", "path", "look"}) for friends to race.
//   {"to": "showcase", "ghost"}                          on your showcase: {"ok", "ghost_id", "ms"}
//   {"to": "gift", "user_id" | "username", "build", "ghost"}   with a blueprint gift: {"ok", "gift_id"}
//                                                        (notification 104, like send_gift)
//   {"remove": "<ghost_id>"}                             takes one down (always works): {"ok", "removed"}
// Codes: not_allowed_online, no_showcase, bad_ghost, not_on_course, impossible_run, too_many_ghosts (3 on a
// showcase), too_fast (12 shares an hour; a gift's own window), not_found; a gift's: cannot_gift_self,
// not_friends, bad_build, too_big, empty_build, too_many_gifts, inbox_full. The payload may be 16 KiB.
function rpcShareGhost(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Gifts.rpc(ctx, logger, "share_ghost", payload, GhostRules.PAYLOAD, function (userId: string, request: Util.Json): Util.Json {
    if (Util.has(request, "remove")) {
      return Ghosts.remove(nk, userId, request.remove);
    }
    if (request.to === "showcase") {
      return Ghosts.onShowcase(nk, userId, request);
    }
    if (request.to === "gift") {
      return Ghosts.withGift(nk, userId, request);
    }
    return Server.fail("bad_request");
  });
}

// list_ghosts {"user_id" | "username"}: a friend's showcase ghosts, to race: {"ok", "owner_id",
// "owner_username", "ghosts": [{"ghost_id", "start", "finish", "ms", "path", "look", "updated_ms"}]}
// ([] when none). {} (or yourself): your own. not_allowed_online, not_found, not_friends.
function rpcListGhosts(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "list_ghosts", payload, function (userId: string, request: Util.Json): Util.Json {
    let ownerId = userId;
    let ownerName = "";
    if (Util.has(request, "user_id") || Util.has(request, "username")) {
      const pair = Gifts.friendOf(nk, userId, request);
      if (pair.error !== "" && pair.error !== "self") {
        return Server.fail(pair.error);
      }
      ownerId = (pair.friend as Social.Player).userId;
      ownerName = (pair.friend as Social.Player).username;
    } else {
      const me = Accounts.load(nk, userId);
      if (!AccountRules.canPlayOnline(me.state)) {
        return Server.fail("not_allowed_online");
      }
      ownerName = me.username;
    }
    const ghosts: Util.Json[] = [];
    const list = Ghosts.listOf(nk, ownerId).ghosts;
    for (let i = 0; i < list.length; i++) {
      ghosts.push(Ghosts.out(list[i]));
    }
    return { ok: true, owner_id: ownerId, owner_username: ownerName, ghosts: ghosts };
  });
}
