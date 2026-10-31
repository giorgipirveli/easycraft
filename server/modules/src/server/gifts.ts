// Friends when they are not online together (M4 Wave 3, agent I; spec §17.5, docs/design T3, T4,
// D5): blueprint gifts, showcase visits with guestbook stickers, bottle mail, and a report about a
// build. Everything is friends only and needs the player to be allowed online (verified parental
// consent for under_13, spec §17.2); a child who may not be online is "not_found", like nobody.
// Storage (server only, permissionRead 0: the game reads through these RPCs):
//   gifts      one object per unopened gift, owned by the friend it is for ("g<ms>_<hex>")
//   bottles    one object per unopened bottle, owned by the friend it is for ("b<ms>_<hex>")
//   showcases  "showcase": the player's one read-only build area (and maybe a waving buddy)
//   guestbook  "guestbook": the stickers visitors left on it (GiftRules.Book)
//   limits     "gifts", "bottles", "showcase": send windows ({"times"})
// Notifications (not persistent: the lists are the mailbox, a note only nudges an open game):
// 104 a gift, 105 a bottle ({"from_username", "from_user_id", "kind"}), 106 a sticker
// ({"from_username", "from_user_id", "sticker"}).

namespace Gifts {
  export const GIFTS = "gifts";
  export const BOTTLES = "bottles";
  export const SHOWCASES = "showcases";
  export const GUESTBOOK = "guestbook";
  // The player's own objects of this wave (Deletion.COLLECTIONS takes them in).
  export const OWN_COLLECTIONS = [GIFTS, BOTTLES, SHOWCASES, GUESTBOOK];
  export const SHOWCASE_KEY = "showcase";
  export const GUESTBOOK_KEY = "guestbook";
  export const NOTE_GIFT = 104;
  export const NOTE_BOTTLE = 105;
  export const NOTE_STICKER = 106;
  export const WHAT: string[] = ["showcase", "gift", "bottle", "ghost"];   // M4 ghosts: "ghost"
  const PAGE = 100;

  // What deleted players sent or left (Deletion.run) and what the retention clean-up removes.
  export const SQL_SENT_BY = "DELETE FROM storage WHERE collection IN ('gifts', 'bottles') AND value ->> 'from_id' = $1";
  export const SQL_BOOKS_WITH = "SELECT user_id::text AS id FROM storage WHERE collection = 'guestbook' AND key = 'guestbook' " +
    "AND value -> 'entries' @> $1::jsonb";
  export const SQL_EXPIRED = "DELETE FROM storage WHERE (collection, key, user_id) IN (SELECT collection, key, user_id " +
    "FROM storage WHERE collection IN ('gifts', 'bottles') AND (value ->> 'created_ms')::bigint <= $1::bigint LIMIT $2::bigint)";
  export const SQL_ORPHANS = "DELETE FROM storage s WHERE s.collection IN ('gifts', 'bottles') " +
    "AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id::text = s.value ->> 'from_id')";
  export const SQL_OLD_BOOKS = "SELECT user_id::text AS id FROM storage WHERE collection = 'guestbook' AND key = 'guestbook' " +
    "AND (value ->> 'oldest_ms')::bigint <= $1::bigint LIMIT $2::bigint";
  export const SQL_ORPHAN_BOOKS = "SELECT DISTINCT s.user_id::text AS id FROM storage s, jsonb_array_elements(s.value -> 'entries') e " +
    "WHERE s.collection = 'guestbook' AND s.key = 'guestbook' AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id::text = e ->> 'from_id') " +
    "LIMIT $1::bigint";
  export const EXPIRED_PER_RUN = 5000;
  export const BOOKS_PER_RUN = 500;

  // An RPC like Server.rpc, with this RPC's own payload cap.
  export function rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, name: string, payload: string, max: number,
      body: (userId: string, request: Util.Json) => Util.Json): string {
    let request: Util.Json | null = null;
    if (payload === undefined || payload === null || payload === "") {
      request = {};
    } else if (typeof payload === "string" && payload.length <= max) {
      try {
        const data = JSON.parse(payload);
        request = Util.isObject(data) ? data : null;
      } catch (_e) {
        request = null;
      }
    }
    if (request === null) {
      return JSON.stringify(Server.fail(payload && payload.length > max ? "too_big" : "bad_request"));
    }
    if (!ctx.userId) {
      return JSON.stringify(Server.fail("not_signed_in"));
    }
    try {
      return JSON.stringify(body(ctx.userId, request));
    } catch (e) {
      logger.error("%s failed for %s: %s", name, ctx.userId, Server.errorText(e));
      return JSON.stringify(Server.fail("server_error"));
    }
  }

  export interface Pair {
    caller: Accounts.Loaded;
    friend: Social.Player | null;
    error: string;
  }

  // The caller (allowed online) and the friend the request names (allowed online, a mutual friend).
  // error: "" or not_allowed_online, not_found, self, not_friends.
  export function friendOf(nk: nkruntime.Nakama, userId: string, request: Util.Json): Pair {
    const caller = Accounts.load(nk, userId);
    if (!AccountRules.canPlayOnline(caller.state)) {
      return { caller: caller, friend: null, error: "not_allowed_online" };
    }
    const friend = Social.find(nk, request);
    if (friend === null || !AccountRules.canPlayOnline(friend.state)) {
      return { caller: caller, friend: null, error: "not_found" };
    }
    if (friend.userId === userId) {
      return { caller: caller, friend: friend, error: "self" };
    }
    if (!Social.areFriends(nk, userId, friend.userId)) {
      return { caller: caller, friend: friend, error: "not_friends" };
    }
    return { caller: caller, friend: friend, error: "" };
  }

  // The player's mutual friends (Nakama state 0).
  export function friendIds(nk: nkruntime.Nakama, userId: string): string[] {
    const out: string[] = [];
    let cursor: string | undefined = undefined;
    for (let page = 0; page < 10; page++) {
      const list = nk.friendsList(userId, PAGE, 0, cursor);
      const friends = list.friends || [];
      for (let i = 0; i < friends.length; i++) {
        if (friends[i].user && friends[i].state === 0) {
          out.push(friends[i].user!.userId);
        }
      }
      if (!list.cursor) {
        break;
      }
      cursor = list.cursor;
    }
    return out;
  }

  // Every object of a collection the player owns (an inbox holds at most GIFT_INBOX_MAX).
  export function inbox(nk: nkruntime.Nakama, userId: string, collection: string): nkruntime.StorageObject[] {
    const out: nkruntime.StorageObject[] = [];
    let cursor: string | undefined = undefined;
    for (let page = 0; page < 10; page++) {
      const list = nk.storageList(userId, collection, PAGE, cursor);
      const objects = list && list.objects ? list.objects : [];
      for (let i = 0; i < objects.length; i++) {
        out.push(objects[i]);
      }
      if (!list || !list.cursor) {
        break;
      }
      cursor = list.cursor;
    }
    return out;
  }

  // One more send in the player's window `key` (limits), or false when it is full.
  export function takeSend(nk: nkruntime.Nakama, userId: string, key: string, max: number, nowMs: number): boolean {
    const found = Store.read(nk, Store.LIMITS, key, userId);
    const step = GiftRules.allow(GiftRules.timesFrom(found ? found.value : undefined), nowMs, max, GiftRules.HOUR_MS);
    if (!step.ok) {
      return false;
    }
    Store.write(nk, Store.LIMITS, key, userId, { times: step.times }, false);
    return true;
  }

  // Unopened things in the friend's inbox: {from this sender, all}.
  function counts(objects: nkruntime.StorageObject[], fromId: string): { mine: number; all: number } {
    let mine = 0;
    for (let i = 0; i < objects.length; i++) {
      if (Util.isObject(objects[i].value) && objects[i].value.from_id === fromId) {
        mine++;
      }
    }
    return { mine: mine, all: objects.length };
  }

  // A gift or a bottle into a friend's inbox (the caps checked), with its nudge. {ok, id} or a fail.
  export function deliver(nk: nkruntime.Nakama, pair: Pair, collection: string, value: Util.Json): Util.Json {
    const bottle = collection === BOTTLES;
    const friend = pair.friend as Social.Player;
    const c = counts(inbox(nk, friend.userId, collection), pair.caller.userId);
    if (c.mine >= (bottle ? GiftRules.BOTTLES_PER_FRIEND : GiftRules.GIFTS_PER_FRIEND)) {
      return Server.fail(bottle ? "too_many_bottles" : "too_many_gifts");
    }
    if (c.all >= (bottle ? GiftRules.BOTTLE_INBOX_MAX : GiftRules.GIFT_INBOX_MAX)) {
      return Server.fail("inbox_full");
    }
    const now = Server.nowMs();
    if (!takeSend(nk, pair.caller.userId, collection, GiftRules.SENDS_PER_HOUR, now)) {
      return Server.fail("too_fast");
    }
    const key = GiftRules.keyFor(bottle ? "b" : "g", now, nk.uuidv4());
    value.from_id = pair.caller.userId;
    value.from_username = pair.caller.username;
    value.created_ms = now;
    Store.write(nk, collection, key, friend.userId, value, false, "*");
    nk.notificationSend(friend.userId, pair.caller.username + (bottle ? " sent you a bottle!" : " sent you a present!"), {
      from_username: pair.caller.username, from_user_id: pair.caller.userId, kind: bottle ? "bottle" : "gift",
    }, bottle ? NOTE_BOTTLE : NOTE_GIFT, pair.caller.userId, false);
    const out: Util.Json = { ok: true };
    out[bottle ? "bottle_id" : "gift_id"] = key;
    return out;
  }

  // The player's inbox as the game lists it: things from mutual friends only (the others are
  // deleted: an unfriended or blocked player's gifts go away), oldest first.
  export function listed(nk: nkruntime.Nakama, userId: string, collection: string): nkruntime.StorageObject[] {
    const friends = friendIds(nk, userId);
    const kept: nkruntime.StorageObject[] = [];
    const objects = inbox(nk, userId, collection);
    for (let i = 0; i < objects.length; i++) {
      const v = objects[i].value;
      if (Util.isObject(v) && typeof v.from_id === "string" && friends.indexOf(v.from_id) >= 0) {
        kept.push(objects[i]);
      } else {
        nk.storageDelete([{ collection: collection, key: objects[i].key, userId: userId }]);
      }
    }
    kept.sort(function (a: nkruntime.StorageObject, b: nkruntime.StorageObject): number {
      const ta = Util.isInt(a.value.created_ms) ? a.value.created_ms : 0;
      const tb = Util.isInt(b.value.created_ms) ? b.value.created_ms : 0;
      return ta !== tb ? ta - tb : (a.key < b.key ? -1 : 1);
    });
    return kept;
  }

  // Opens (or with discard deletes) one thing of the player's inbox; the server forgets it then.
  export function open(nk: nkruntime.Nakama, userId: string, collection: string, idKey: string, request: Util.Json,
      shape: (key: string, value: Util.Json) => Util.Json): Util.Json {
    const key = request[idKey];
    if (typeof key !== "string" || key === "" || key.length > 64) {
      return Server.fail("not_found");
    }
    const found = Store.read(nk, collection, key, userId);
    if (found === null) {
      return Server.fail("not_found");
    }
    // M4 Task 10 review: like the lists, nothing opens while the player may not be online (a grown-up's
    // switch, consent gone); it stays for later. Deleting it unopened always works.
    if (request.discard !== true && !AccountRules.canPlayOnline(Accounts.load(nk, userId).state)) {
      return Server.fail("not_allowed_online");
    }
    Store.remove(nk, collection, key, userId);
    if (request.discard === true) {
      return { ok: true, discarded: true };
    }
    if (typeof found.value.from_id !== "string" || !Social.areFriends(nk, userId, found.value.from_id)) {
      return Server.fail("not_found"); // no longer a friend: it goes away unopened
    }
    const out: Util.Json = { ok: true };
    out[collection === BOTTLES ? "bottle" : "gift"] = shape(key, found.value);
    return out;
  }

  export function book(nk: nkruntime.Nakama, ownerId: string, nowMs: number): { book: GiftRules.Book; version: string } {
    const found = Store.read(nk, GUESTBOOK, GUESTBOOK_KEY, ownerId);
    return { book: GiftRules.bookFrom(found ? found.value : undefined, nowMs), version: found ? found.version : "*" };
  }

  // Writes a guestbook (deleted when empty). version: from book(), so two visitors never overwrite each other.
  export function saveBook(nk: nkruntime.Nakama, ownerId: string, b: GiftRules.Book, version: string): void {
    if (b.entries.length === 0) {
      if (version !== "*") {
        nk.storageDelete([{ collection: GUESTBOOK, key: GUESTBOOK_KEY, userId: ownerId, version: version }]);
      }
      return;
    }
    Store.write(nk, GUESTBOOK, GUESTBOOK_KEY, ownerId, { entries: b.entries, oldest_ms: b.oldest_ms }, false, version);
  }

  // A guestbook's entries as the owner's game reads them.
  export function entriesOut(b: GiftRules.Book): Util.Json[] {
    const out: Util.Json[] = [];
    for (let i = 0; i < b.entries.length; i++) {
      const e = b.entries[i];
      out.push({ entry_id: e.entry_id, from_user_id: e.from_id, from_username: e.from_username, sticker: e.sticker, at_ms: e.at_ms });
    }
    return out;
  }

  // Rewrites one guestbook through `change` (read, change, write by version; three tries).
  export function rewriteBook(nk: nkruntime.Nakama, ownerId: string, nowMs: number,
      change: (b: GiftRules.Book) => GiftRules.Book | null): number {
    for (let attempt = 0; attempt < 3; attempt++) {
      const found = Store.read(nk, GUESTBOOK, GUESTBOOK_KEY, ownerId);
      if (found === null) {
        return 0;
      }
      const before = GiftRules.bookFrom(found.value, nowMs);
      const raw = found.value.entries instanceof Array ? found.value.entries.length : 0;
      const after = change(before) || before;
      try {
        saveBook(nk, ownerId, after, found.version);
        return raw - after.entries.length;
      } catch (e) {
        if (!Social.isVersionClash(e)) {
          throw e;
        }
      }
    }
    return 0;
  }

  // Deletion.run: the gifts and bottles this player sent (in friends' inboxes) and the stickers it left.
  export function forgetSent(nk: nkruntime.Nakama, userId: string): number {
    return nk.sqlExec(SQL_SENT_BY, [userId]).rowsAffected;
  }

  export function forgetStickers(nk: nkruntime.Nakama, userId: string): number {
    const rows = nk.sqlQuery(SQL_BOOKS_WITH, [JSON.stringify([{ from_id: userId }])]);
    let removed = 0;
    const now = Server.nowMs();
    for (let i = 0; i < rows.length; i++) {
      removed += rewriteBook(nk, String(rows[i].id), now, function (b: GiftRules.Book): GiftRules.Book {
        return GiftRules.without(b, [userId]);
      });
    }
    return removed;
  }

  // The retention clean-up's part (Retention.run): unopened gifts and bottles after KEEP_DAYS, what
  // players deleted in the console sent, and old or orphaned stickers.
  export function retention(nk: nkruntime.Nakama, nowMs: number, result: Util.Json): void {
    result.gifts_expired = nk.sqlExec(SQL_EXPIRED, [GiftRules.cutoffMs(nowMs), EXPIRED_PER_RUN]).rowsAffected;
    if (result.gifts_expired >= EXPIRED_PER_RUN) {
      result.more = true;
    }
    result.gifts_orphaned = nk.sqlExec(SQL_ORPHANS, []).rowsAffected;
    let old = 0;
    const books = nk.sqlQuery(SQL_OLD_BOOKS, [GiftRules.cutoffMs(nowMs), BOOKS_PER_RUN]);
    for (let i = 0; i < books.length; i++) {
      old += rewriteBook(nk, String(books[i].id), nowMs, function (b: GiftRules.Book): GiftRules.Book { return b; });
    }
    result.stickers_expired = old;
    let orphaned = 0;
    const orphanBooks = nk.sqlQuery(SQL_ORPHAN_BOOKS, [BOOKS_PER_RUN]);
    for (let i = 0; i < orphanBooks.length; i++) {
      orphaned += rewriteBook(nk, String(orphanBooks[i].id), nowMs, function (b: GiftRules.Book): GiftRules.Book {
        const ids: string[] = [];
        for (let k = 0; k < b.entries.length; k++) {
          if (ids.indexOf(b.entries[k].from_id) < 0) {
            ids.push(b.entries[k].from_id);
          }
        }
        const living = ids.length > 0 ? nk.usersGetId(ids) : [];
        const gone: string[] = [];
        for (let k = 0; k < ids.length; k++) {
          let found = false;
          for (let u = 0; u < living.length; u++) {
            found = found || living[u].userId === ids[k];
          }
          if (!found) {
            gone.push(ids[k]);
          }
        }
        return GiftRules.without(b, gone);
      });
    }
    result.stickers_orphaned = orphaned;
    if (books.length >= BOOKS_PER_RUN || orphanBooks.length >= BOOKS_PER_RUN) {
      result.more = true;
    }
  }

  // A gift's or bottle's build as the game reads it: {build, size, count}.
  function buildOut(value: Util.Json, out: Util.Json): Util.Json {
    if (typeof value.build === "string") {
      out.build = value.build;
      out.size = value.size;
      out.count = value.count;
    }
    return out;
  }

  export function giftOut(key: string, v: Util.Json): Util.Json {
    const out = buildOut(v, { gift_id: key, from_user_id: v.from_id, from_username: v.from_username, created_ms: v.created_ms });
    if (Util.isObject(v.ghost)) {
      out.ghost = v.ghost;   // M4 ghosts: a gift shared with the sender's ghost (share_ghost to a gift)
    }
    return out;
  }

  export function bottleOut(key: string, v: Util.Json): Util.Json {
    return buildOut(v, { bottle_id: key, from_user_id: v.from_id, from_username: v.from_username, phrase: v.phrase,
      created_ms: v.created_ms });
  }

  export function refusal(pairError: string, self: string): Util.Json {
    return Server.fail(pairError === "self" ? self : pairError);
  }

  // M4 ghosts: a report covers ghosts too. "ghost": the server's copy of that showcase ghost (ghost_id),
  // else the reporter's (source "reporter"), else null; "showcase": its ghosts as the server keeps them;
  // a gift's ghost as the reporter's game has it.
  export function reportGhosts(nk: nkruntime.Nakama, targetId: string, request: Util.Json, report: Util.Json): void {
    if (request.what === "showcase") {
      const list = Ghosts.listOf(nk, targetId).ghosts;
      if (list.length > 0) {
        report.ghosts = list.map(Ghosts.out);
      }
      return;
    }
    let ghost: Util.Json | null = request.what === "ghost" ? Ghosts.find(nk, targetId, request.ghost_id) : null;
    if (ghost !== null) {
      ghost.source = ReportRules.SERVER;
    } else if (request.ghost !== undefined) {
      ghost = Ghosts.reporterCopy(request.ghost);
      if (ghost !== null) {
        ghost.source = ReportRules.REPORTER;
      }
    }
    if (request.what === "ghost" || ghost !== null) {
      report.ghost = ghost;
    }
  }
}

// send_gift {"user_id" | "username", "build"}: a build (GiftRules.GIFT: 8 x 8 x 8, 512 blocks) for a
// friend's stamps. {"ok", "gift_id"}; not_allowed_online, not_found, cannot_gift_self, not_friends,
// bad_build, too_big, empty_build, too_many_gifts (10 unopened from you), inbox_full, too_fast (30 an hour).
function rpcSendGift(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "send_gift", payload, function (userId: string, request: Util.Json): Util.Json {
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Gifts.refusal(pair.error, "cannot_gift_self");
    }
    const d = BuildRules.decode(request.build, GiftRules.GIFT);
    if (!d.build) {
      return Server.fail(d.error || "bad_build");
    }
    return Gifts.deliver(nk, pair, Gifts.GIFTS, { build: request.build, size: d.build.size, count: d.build.count });
  });
}

// list_gifts {}: {"ok", "gifts": [{"gift_id", "from_user_id", "from_username", "count", "size", "created_ms"}]}
// from friends only, oldest first (no builds: open_gift gives one).
function rpcListGifts(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "list_gifts", payload, function (userId: string): Util.Json {
    if (!AccountRules.canPlayOnline(Accounts.load(nk, userId).state)) {
      return Server.fail("not_allowed_online");
    }
    const out: Util.Json[] = [];
    const objects = Gifts.listed(nk, userId, Gifts.GIFTS);
    for (let i = 0; i < objects.length; i++) {
      const v = objects[i].value;
      out.push({ gift_id: objects[i].key, from_user_id: v.from_id, from_username: v.from_username, count: v.count,
        size: v.size, created_ms: v.created_ms });
      if (Util.isObject(v.ghost)) {
        out[out.length - 1].ghost = true;   // M4 ghosts: the sender's ghost comes with it
      }
    }
    return { ok: true, gifts: out };
  });
}

// open_gift {"gift_id", "discard"?}: {"ok", "gift": {"gift_id", "from_user_id", "from_username", "build",
// "size", "count", "created_ms"}} (the server forgets it), or {"ok", "discarded": true}; not_found.
function rpcOpenGift(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "open_gift", payload, function (userId: string, request: Util.Json): Util.Json {
    return Gifts.open(nk, userId, Gifts.GIFTS, "gift_id", request, Gifts.giftOut);
  });
}

// publish_showcase {"build", "buddy"?: {"build", "at": [x, y, z]}} or {"remove": true}: the player's
// one showcase (GiftRules.SHOWCASE: 32 x 32 x 32, 48 KiB of text; a buddy of GiftRules.BUDDY standing
// inside it). {"ok", "count", "size", "updated_ms"} or {"ok", "removed": true} (the guestbook goes
// too; it always works, even for a player who may not be online now); not_allowed_online, bad_build,
// too_big, empty_build, bad_buddy, too_fast (12 an hour).
function rpcPublishShowcase(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Gifts.rpc(ctx, logger, "publish_showcase", payload, GiftRules.SHOWCASE_PAYLOAD, function (userId: string, request: Util.Json): Util.Json {
    if (request.remove === true) {   // taking one's own showcase down always works
      Store.remove(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, userId);
      Store.remove(nk, Gifts.GUESTBOOK, Gifts.GUESTBOOK_KEY, userId);
      Ghosts.forget(nk, userId);   // M4 ghosts: no showcase, no ghosts on it
      return { ok: true, removed: true };
    }
    if (!AccountRules.canPlayOnline(Accounts.load(nk, userId).state)) {
      return Server.fail("not_allowed_online");
    }
    const d = BuildRules.decode(request.build, GiftRules.SHOWCASE);
    if (!d.build) {
      return Server.fail(d.error || "bad_build");
    }
    const value: Util.Json = { build: request.build, size: d.build.size, count: d.build.count };
    if (request.buddy !== undefined && request.buddy !== null) {
      const b = Util.isObject(request.buddy) ? request.buddy : {};
      const bd = BuildRules.decode(b.build, GiftRules.BUDDY);
      const at = b.at;
      const inside = at instanceof Array && at.length === 3 && Util.isInt(at[0]) && Util.isInt(at[1]) && Util.isInt(at[2]) &&
        at[0] >= 0 && at[1] >= 0 && at[2] >= 0 && at[0] < d.build.size[0] && at[1] < d.build.size[1] && at[2] < d.build.size[2];
      if (!bd.build || !inside) {
        return Server.fail("bad_buddy");
      }
      value.buddy = { build: b.build, at: [at[0], at[1], at[2]] };
    }
    const now = Server.nowMs();
    if (!Gifts.takeSend(nk, userId, "showcase", GiftRules.PUBLISHES_PER_HOUR, now)) {
      return Server.fail("too_fast");
    }
    value.updated_ms = now;
    Store.write(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, userId, value, false);
    Ghosts.forget(nk, userId);   // M4 ghosts: a new area (its cells moved); the game shares its ghosts again
    return { ok: true, count: d.build.count, size: d.build.size, updated_ms: now };
  });
}

// get_showcase {"user_id" | "username"}: a friend's showcase, even while they are away: {"ok",
// "owner_id", "owner_username", "build", "size", "buddy"?, "updated_ms"}. With no one named (or
// yourself): your own, with "guestbook" [{"entry_id", "from_user_id", "from_username", "sticker",
// "at_ms"}]. not_allowed_online, not_found, not_friends, no_showcase.
function rpcGetShowcase(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "get_showcase", payload, function (userId: string, request: Util.Json): Util.Json {
    const named = Util.has(request, "user_id") || Util.has(request, "username");
    let ownerId = userId;
    let ownerName = "";
    if (named) {
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
    const found = Store.read(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, ownerId);
    if (found === null || typeof found.value.build !== "string") {
      return Server.fail("no_showcase");
    }
    const out: Util.Json = { ok: true, owner_id: ownerId, owner_username: ownerName, build: found.value.build,
      size: found.value.size, updated_ms: found.value.updated_ms };
    if (Util.isObject(found.value.buddy)) {
      out.buddy = found.value.buddy;
    }
    if (ownerId === userId) {
      out.guestbook = Gifts.entriesOut(Gifts.book(nk, userId, Server.nowMs()).book);
    }
    return out;
  });
}

// sign_guestbook {"user_id" | "username", "sticker"}: a visitor's preset sticker in a friend's
// guestbook (the newest 30 of 60 days; one every 10 minutes per visitor); notification 106.
// {"ok"}; not_allowed_online, not_found, cannot_sign_own, not_friends, bad_sticker, no_showcase, too_fast.
function rpcSignGuestbook(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "sign_guestbook", payload, function (userId: string, request: Util.Json): Util.Json {
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Gifts.refusal(pair.error, "cannot_sign_own");
    }
    if (!GiftRules.isSticker(request.sticker)) {
      return Server.fail("bad_sticker");
    }
    const owner = pair.friend as Social.Player;
    if (Store.read(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, owner.userId) === null) {
      return Server.fail("no_showcase");
    }
    const now = Server.nowMs();
    const entry: GiftRules.Entry = { entry_id: nk.uuidv4().replace(/-/g, "").substring(0, 12), from_id: userId,
      from_username: pair.caller.username, sticker: request.sticker, at_ms: now };
    for (let attempt = 0; attempt < 3; attempt++) {
      const current = Gifts.book(nk, owner.userId, now);
      const step = GiftRules.sign(current.book, entry, now);
      if (!step.book) {
        return Server.fail(step.error || "too_fast");
      }
      try {
        Gifts.saveBook(nk, owner.userId, step.book, current.version);
      } catch (e) {
        if (Social.isVersionClash(e)) {
          continue; // another visitor at the same moment: read again
        }
        throw e;
      }
      nk.notificationSend(owner.userId, pair.caller.username + " left you a sticker!", {
        from_username: pair.caller.username, from_user_id: userId, sticker: request.sticker,
      }, Gifts.NOTE_STICKER, userId, false);
      return { ok: true };
    }
    return Server.fail("busy");
  });
}

// remove_sticker {"entry_id"}: the owner deletes one sticker of their own guestbook. {"ok",
// "guestbook"}; not_found.
function rpcRemoveSticker(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "remove_sticker", payload, function (userId: string, request: Util.Json): Util.Json {
    let found = false;
    Gifts.rewriteBook(nk, userId, Server.nowMs(), function (b: GiftRules.Book): GiftRules.Book | null {
      const after = GiftRules.remove(b, request.entry_id);
      found = after !== null;
      return after;
    });
    if (!found) {
      return Server.fail("not_found");
    }
    return { ok: true, guestbook: Gifts.entriesOut(Gifts.book(nk, userId, Server.nowMs()).book) };
  });
}

// send_bottle {"user_id" | "username", "phrase", "build"?}: a quick-chat phrase (ChatRules.QUICK_PHRASES)
// and maybe a tiny build (GiftRules.BOTTLE: 4 x 4 x 4) for a friend; notification 105. {"ok",
// "bottle_id"}; not_allowed_online, not_found, cannot_gift_self, not_friends, bad_phrase, bad_build,
// too_big, empty_build, too_many_bottles (5 unopened from you), inbox_full, too_fast.
function rpcSendBottle(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "send_bottle", payload, function (userId: string, request: Util.Json): Util.Json {
    const pair = Gifts.friendOf(nk, userId, request);
    if (pair.error !== "") {
      return Gifts.refusal(pair.error, "cannot_gift_self");
    }
    if (typeof request.phrase !== "string" || !ChatRules.isQuickPhrase(request.phrase)) {
      return Server.fail("bad_phrase");
    }
    const value: Util.Json = { phrase: request.phrase };
    if (request.build !== undefined && request.build !== null) {
      const d = BuildRules.decode(request.build, GiftRules.BOTTLE);
      if (!d.build) {
        return Server.fail(d.error || "bad_build");
      }
      value.build = request.build;
      value.size = d.build.size;
      value.count = d.build.count;
    }
    return Gifts.deliver(nk, pair, Gifts.BOTTLES, value);
  });
}

// list_bottles {}: {"ok", "bottles": [{"bottle_id", "from_user_id", "from_username", "created_ms"}]}
// from friends only, oldest first (what is inside shows when one is opened).
function rpcListBottles(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "list_bottles", payload, function (userId: string): Util.Json {
    if (!AccountRules.canPlayOnline(Accounts.load(nk, userId).state)) {
      return Server.fail("not_allowed_online");
    }
    const out: Util.Json[] = [];
    const objects = Gifts.listed(nk, userId, Gifts.BOTTLES);
    for (let i = 0; i < objects.length; i++) {
      const v = objects[i].value;
      out.push({ bottle_id: objects[i].key, from_user_id: v.from_id, from_username: v.from_username, created_ms: v.created_ms });
    }
    return { ok: true, bottles: out };
  });
}

// open_bottle {"bottle_id", "discard"?}: {"ok", "bottle": {"bottle_id", "from_user_id",
// "from_username", "phrase", "build"?, "size"?, "count"?, "created_ms"}} (the server forgets it), or
// {"ok", "discarded": true}; not_found.
function rpcOpenBottle(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "open_bottle", payload, function (userId: string, request: Util.Json): Util.Json {
    return Gifts.open(nk, userId, Gifts.BOTTLES, "bottle_id", request, Gifts.bottleOut);
  });
}

// report_build {"user_id" | "username", "what": "showcase" | "gift" | "bottle", "build"?, "reason"?}:
// a report about a build for a person to review (collection "reports", like report_user, with its
// limits): "build" keeps the server's copy of the showcase ({"build", "size", "source": "server"}),
// else the build as the reporter's game had it ("source": "reporter"), else null. The reason defaults
// to "bad_build". {"ok"}; not_found, cannot_report_self, too_many, bad_request.
function rpcReportBuild(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Gifts.rpc(ctx, logger, "report_build", payload, GiftRules.SHOWCASE_PAYLOAD, function (userId: string, request: Util.Json): Util.Json {
    if (Gifts.WHAT.indexOf(request.what) < 0) {
      return Server.fail("bad_request");
    }
    const target = Social.findReported(nk, request);
    if (target === null) {
      return Server.fail("not_found");
    }
    if (target.userId === userId) {
      return Server.fail("cannot_report_self");
    }
    const now = Server.nowMs();
    const found = Store.read(nk, Store.LIMITS, "report", userId);
    const step = ReportRules.accept(ReportRules.windowFrom(found ? found.value : undefined), target.userId, now);
    if (step.error) {
      return Server.fail(step.error);
    }
    if (step.store) {
      let snapshot: Util.Json | null = null;
      if (request.what === "showcase") {
        const shown = Store.read(nk, Gifts.SHOWCASES, Gifts.SHOWCASE_KEY, target.userId);
        if (shown !== null && typeof shown.value.build === "string") {
          snapshot = { build: shown.value.build, size: shown.value.size, source: ReportRules.SERVER };
        }
      }
      if (snapshot === null && request.build !== undefined) {
        const d = BuildRules.decode(request.build, GiftRules.SHOWCASE);
        if (d.build) {
          snapshot = { build: request.build, size: d.build.size, source: ReportRules.REPORTER };
        }
      }
      const me = Accounts.load(nk, userId);
      const report: Util.Json = {
        reporter_id: userId, reporter_username: me.username,
        reported_id: target.userId, reported_username: target.username,
        reason: request.reason === undefined ? "bad_build" : ReportRules.reason(request.reason),
        what: request.what, build: snapshot,
        match_id: "", channel_id: "", message_id: "",
        created_ms: now, status: "new",
      };
      Gifts.reportGhosts(nk, target.userId, request, report);   // M4 ghosts
      Store.write(nk, Store.REPORTS, now + "_" + userId + "_build", Store.SYSTEM_USER, report, false);
      Store.write(nk, Store.LIMITS, "report", userId, step.window, false);
      logger.info("build report stored: %s reported %s", userId, target.userId);
    }
    return { ok: true };
  });
}
