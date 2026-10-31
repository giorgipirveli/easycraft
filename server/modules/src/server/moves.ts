// Owner #99 (module 0.2.20; spec §5.13 "As built (owner #99)", §17.1): the same name on a new device, with proof and
// never by the name alone. The new device asks for the account it names (move_request "start") and shows the 6-digit
// code it gets; the account's devices hear of the ask (notification 110 "asked", or move_approve "list" when they come
// online) and a grown-up types the code from the new device's screen on one of them ("approve", behind the game's
// parent gate). The asking device then gets a one-time key (move_request "status") and signs in with sign_in_with_key
// (keys.ts), exactly as with a grown-up's key: its new device id is linked to the account, its own never-claimed
// account goes, and the old device stays signed in and hears "moved". MoveRules holds the rules.
//
// The lead's security review (2026-10-15):
// - The asking device learns nothing about the account beyond what claim_username's "taken" tells: not whether a
//   device of it is online, not what its devices did (NOT ME, wrong codes: MoveRules.askerView waits until the code's
//   time is over), not that others asked (a name past its limit gets a decoy ask that reaches no device, never
//   "rate_limited"), not the name's own case until the account's device approved.
// - Every count and every use on the way is a read and a write by version, again from the read when another call wrote
//   in between, and it fails closed: the windows (never passed: rate_limited, or the decoy), the wrong codes (each
//   counted on top of the others), the key's hand-outs (at most HANDOUT_MAX, only the newest key's hash kept) and the
//   key's single use (the ask is "done" before the device is linked). A write that never lands answers server_error.
//
//   account/move_asks   (server only) on the account asked for: {asks: [MoveRules.Ask]} (their codes and the newest
//                       one-time key's bcrypt hash: the game can't read it)
//   account/move_asked  (server only) on the asking account: {target ("" for a decoy), id, made_ms}, its newest ask
//   limits/move_name    (server only) on the account asked for: asks for its name in the window (MoveRules.NAME_MAX)
//   limits/move_ask     (server only) on the asking account: asks it made in the window (MoveRules.ASKER_MAX)
// Deleting either account deletes its objects with the rest of `account` and `limits` (DeletionRules.COLLECTIONS).

namespace Moves {
  export const NOTE = 110; // {"what": "asked" | "moved", "kind"} to the account; {"what": "approved"} to the asker
  export const ASKS_KEY = "move_asks";
  export const ASKED_KEY = "move_asked";
  export const NAME_LIMIT_KEY = "move_name";
  export const ASKER_LIMIT_KEY = "move_ask";
  export const WRITE_TRIES = 3;

  // A claimed account by its name (any case), or null.
  export function target(nk: nkruntime.Nakama, typed: unknown): Accounts.Loaded | null {
    const name = typeof typed === "string" ? UsernameRules.uniquenessKey(typed) : "";
    if (name === "" || name.length > UsernameRules.MAX_LEN) {
      return null;
    }
    const rows = nk.sqlQuery(Accounts.SQL_USERNAME_OWNER, [name, Store.SYSTEM_USER]);
    if (rows.length === 0) {
      return null;
    }
    const loaded = Accounts.load(nk, String(rows[0].id));
    return loaded.state.claimed ? loaded : null;
  }

  // A nudge only (the asks and their states are in storage): one that can't be sent (that account went meanwhile)
  // never undoes what was written before it.
  export function note(nk: nkruntime.Nakama, userId: string, content: Util.Json): void {
    try {
      nk.notificationSend(userId, "Your game", content, NOTE, null, false);
    } catch (_e) {
      // the list (move_approve "list") and the status (move_request "status") still say it
    }
  }

  // Reads the account's asks (tidied at nowMs), lets `fn` change the one with `id` (null: no change) and writes the book
  // back over exactly the copy read; when another call wrote in between, all of it again from the read (fn sees the
  // newer ask). The ask as it is now, or null when the book has none with that id. Throws (server_error: fail closed)
  // when no write landed in WRITE_TRIES.
  export function change(nk: nkruntime.Nakama, userId: string, nowMs: number, id: unknown,
      fn: (a: MoveRules.Ask) => MoveRules.Ask | null): MoveRules.Ask | null {
    for (let attempt = 1; ; attempt++) {
      const found = Store.read(nk, Store.ACCOUNT, ASKS_KEY, userId);
      const book = MoveRules.tidy(MoveRules.bookFrom(found ? found.value : undefined), nowMs);
      const a = MoveRules.find(book, id);
      if (a === null) {
        return null;
      }
      const changed = fn(a);
      if (changed === null) {
        return a;
      }
      try {
        Store.write(nk, Store.ACCOUNT, ASKS_KEY, userId, MoveRules.replace(book, changed) as unknown as Util.Json, false,
          found ? found.version : "*");
        return changed;
      } catch (e) {
        if (attempt >= WRITE_TRIES) {
          throw e;
        }
      }
    }
  }

  // A new ask into the account's book (by version, as change does); the asks it ended (OPEN_MAX).
  function add(nk: nkruntime.Nakama, userId: string, nowMs: number, a: MoveRules.Ask): MoveRules.Ask[] {
    for (let attempt = 1; ; attempt++) {
      const found = Store.read(nk, Store.ACCOUNT, ASKS_KEY, userId);
      const r = MoveRules.add(MoveRules.tidy(MoveRules.bookFrom(found ? found.value : undefined), nowMs), a);
      try {
        Store.write(nk, Store.ACCOUNT, ASKS_KEY, userId, r.book as unknown as Util.Json, false, found ? found.version : "*");
        return r.replaced;
      } catch (e) {
        if (attempt >= WRITE_TRIES) {
          throw e;
        }
      }
    }
  }

  // One more ask counted in a window, by version: {ok, wait}. Another call counting at the same moment makes this one
  // read again and count on top of it; when no write lands it is not ok (never passed).
  export function count(nk: nkruntime.Nakama, key: string, userId: string, nowMs: number, max: number,
      windowMs: number): { ok: boolean; wait: number } {
    for (let attempt = 1; attempt <= WRITE_TRIES; attempt++) {
      const found = Store.read(nk, Store.LIMITS, key, userId);
      const r = MoveRules.count(MoveRules.windowFrom(found ? found.value : undefined), nowMs, max, windowMs);
      if (!r.ok) {
        return { ok: false, wait: r.wait };
      }
      try {
        Store.write(nk, Store.LIMITS, key, userId, r.window as unknown as Util.Json, false, found ? found.version : "*");
        return { ok: true, wait: 0 };
      } catch (_e) {
        // counted by another call meanwhile: read the window again
      }
    }
    return { ok: false, wait: 60 };
  }

  function asked(nk: nkruntime.Nakama, callerId: string): { target: string; id: string; made_ms: number } | null {
    const found = Store.read(nk, Store.ACCOUNT, ASKED_KEY, callerId);
    if (!found || typeof found.value.target !== "string" || !MoveRules.isId(found.value.id)) {
      return null;
    }
    return { target: found.value.target, id: found.value.id, made_ms: Util.isInt(found.value.made_ms) ? found.value.made_ms : 0 };
  }

  function open(a: MoveRules.Ask): boolean {
    return a.state === MoveRules.OPEN || a.state === MoveRules.APPROVED;
  }

  // The new device: an ask for the account named. {"ok", "id", "code", "valid_s"}: nothing about the account.
  export function start(nk: nkruntime.Nakama, logger: nkruntime.Logger, callerId: string, request: Util.Json,
      nowMs: number): Util.Json {
    const t = target(nk, request.username);
    if (t === null) {
      return Server.fail("no_such_player"); // claim_username says "taken" for the same names: nothing more is told
    }
    if (t.userId === callerId) {
      return Server.fail("self"); // the asking account itself: it tells nobody anything about another account
    }
    const byAsker = count(nk, ASKER_LIMIT_KEY, callerId, nowMs, MoveRules.ASKER_MAX, MoveRules.ASKER_WINDOW_MS);
    if (!byAsker.ok) {
      return Server.fail("rate_limited", { wait: byAsker.wait }); // only what this account did itself
    }
    const before = asked(nk, callerId);
    if (before !== null && before.target !== "") {
      change(nk, before.target, nowMs, before.id, function (a: MoveRules.Ask): MoveRules.Ask | null {
        return open(a) ? MoveRules.end(a, MoveRules.REPLACED) : null;
      });
    }
    const id = nk.uuidv4();
    const code = MoveRules.codeFromHex(nk.uuidv4().replace(/-/g, "")); // its own randomness: the id is seen by the account
    const byName = count(nk, NAME_LIMIT_KEY, t.userId, nowMs, MoveRules.NAME_MAX, MoveRules.NAME_WINDOW_MS);
    if (!byName.ok) {
      // A decoy: the same answer as a real ask (so nobody learns that others asked for this name), but nothing reaches
      // the account and its code approves nothing; its status waits until the code's time is over.
      Store.write(nk, Store.ACCOUNT, ASKED_KEY, callerId, { target: "", id: id, made_ms: nowMs }, false);
      logger.info("move: an ask for %s's name past its limit (a decoy) by %s", t.userId, callerId);
      return { ok: true, id: id, code: code, valid_s: MoveRules.CODE_MS / 1000 };
    }
    const a: MoveRules.Ask = {
      id: id, from: callerId, kind: MoveRules.kindOf(request.kind), code: code, made_ms: nowMs, state: MoveRules.OPEN,
      wrong: 0, why: "", approved_ms: 0, handed: 0, key_hash: "",
    };
    add(nk, t.userId, nowMs, a); // asks it ended (OPEN_MAX) wait quietly until their time is over (MoveRules.askerView)
    Store.write(nk, Store.ACCOUNT, ASKED_KEY, callerId, { target: t.userId, id: a.id, made_ms: nowMs }, false);
    note(nk, t.userId, { what: "asked", kind: a.kind });
    logger.info("move: %s asks for %s's account", callerId, t.userId);
    return { ok: true, id: a.id, code: a.code, valid_s: MoveRules.CODE_MS / 1000 };
  }

  // The new device: how its ask stands (MoveRules.askerView); once approved, a one-time key: each look hands a new one
  // and keeps only its hash (the one before stops), HANDOUT_MAX at most.
  export function status(nk: nkruntime.Nakama, logger: nkruntime.Logger, callerId: string, request: Util.Json,
      nowMs: number): Util.Json {
    const mine = asked(nk, callerId);
    if (mine === null || mine.id !== request.id) {
      return Server.fail("not_found");
    }
    if (mine.target === "") {
      return withOk(MoveRules.quietView(mine.made_ms, nowMs)); // a decoy
    }
    const seen = { key: "" };
    const a = change(nk, mine.target, nowMs, mine.id, function (x: MoveRules.Ask): MoveRules.Ask | null {
      seen.key = "";
      if (x.state !== MoveRules.APPROVED || x.from !== callerId) {
        return null;
      }
      if (x.handed >= MoveRules.HANDOUT_MAX) {
        return MoveRules.end(x, MoveRules.EXPIRED);
      }
      seen.key = KeyRules.fromHex(nk.uuidv4().replace(/-/g, ""));
      const out = MoveRules.copy(x);
      out.handed = x.handed + 1;
      out.key_hash = nk.bcryptHash(seen.key);
      return out;
    });
    if (a === null) {
      return withOk(MoveRules.quietView(mine.made_ms, nowMs)); // gone from the book (old): its time is over
    }
    const out = withOk(MoveRules.askerView(a, nowMs));
    if (a.state === MoveRules.APPROVED && seen.key !== "") {
      out.key = KeyRules.pretty(seen.key);
      out.username = Accounts.load(nk, mine.target).username;
      logger.info("move: a one-time key for %s to %s's account", callerId, mine.target);
    }
    return out;
  }

  function withOk(view: Util.Json): Util.Json {
    const out: Util.Json = { ok: true };
    for (const k in view) {
      if (Util.has(view, k)) {
        out[k] = view[k];
      }
    }
    return out;
  }

  // The new device: BACK (its ask ends, and an approved one's key with it; the account's card goes).
  export function cancel(nk: nkruntime.Nakama, callerId: string, request: Util.Json, nowMs: number): Util.Json {
    const mine = asked(nk, callerId);
    if (mine === null || mine.id !== request.id) {
      return Server.fail("not_found");
    }
    if (mine.target !== "") {
      change(nk, mine.target, nowMs, mine.id, function (a: MoveRules.Ask): MoveRules.Ask | null {
        return open(a) && a.from === callerId ? MoveRules.end(a, MoveRules.CANCELLED) : null;
      });
    }
    Store.remove(nk, Store.ACCOUNT, ASKED_KEY, callerId);
    return { ok: true };
  }

  // The account's device: its open asks, without their codes. {"ok", "username", "asks": [{"id", "kind", "left_s"}]}.
  export function list(nk: nkruntime.Nakama, callerId: string, nowMs: number): Util.Json {
    const found = Store.read(nk, Store.ACCOUNT, ASKS_KEY, callerId);
    const book = MoveRules.tidy(MoveRules.bookFrom(found ? found.value : undefined), nowMs);
    const asks = MoveRules.open(book);
    const out: Util.Json[] = [];
    for (let i = 0; i < asks.length; i++) {
      out.push(MoveRules.pendingView(asks[i], nowMs));
    }
    return { ok: true, username: Accounts.load(nk, callerId).username, asks: out };
  }

  // The account's device: the code typed from the new device's screen. {"ok"}; "wrong_code" + "tries_left"; "ended" +
  // "why" (the last wrong code, or it ended before); "not_found". Each try is counted by version, on top of any other
  // try at the same moment (MoveRules.check on the ask as it is then).
  export function approve(nk: nkruntime.Nakama, logger: nkruntime.Logger, callerId: string, request: Util.Json,
      nowMs: number): Util.Json {
    const seen = { result: "", tries_left: 0 };
    const a = change(nk, callerId, nowMs, request.id, function (x: MoveRules.Ask): MoveRules.Ask | null {
      const c = MoveRules.check(x, request.code, nowMs);
      seen.result = c.result;
      seen.tries_left = c.tries_left;
      return x.state === MoveRules.OPEN ? c.ask : null;
    });
    if (a === null) {
      return Server.fail("not_found");
    }
    if (seen.result === "approved") {
      note(nk, a.from, { what: "approved" });
      logger.info("move: %s approved an ask for its account", callerId);
      return { ok: true };
    }
    if (seen.result === "wrong") {
      return Server.fail("wrong_code", { tries_left: seen.tries_left });
    }
    return Server.fail("ended", { why: a.why }); // the account's own device hears why (never the asker)
  }

  // The account's device: NOT ME (the ask ends, and an approved one's key with it; the asker is not told).
  export function decline(nk: nkruntime.Nakama, callerId: string, request: Util.Json, nowMs: number): Util.Json {
    const a = change(nk, callerId, nowMs, request.id, function (x: MoveRules.Ask): MoveRules.Ask | null {
      return open(x) ? MoveRules.end(x, MoveRules.DECLINED) : null;
    });
    return a === null ? Server.fail("not_found") : { ok: true };
  }

  // sign_in_with_key: uses up the one-time key an approved ask of `callerId` handed out for this account, by version
  // (two uses at once: one finds it done). The ask, done, or null when `key` is not that key (or its time is over).
  // Before the device is linked: a key is never used twice (a link that fails afterwards needs a new ask).
  export function consume(nk: nkruntime.Nakama, targetId: string, callerId: string, key: string, nowMs: number): MoveRules.Ask | null {
    if (!MoveRules.ENABLED) {
      return null; // the move is off: no one-time key signs anyone in
    }
    const mine = asked(nk, callerId);
    if (mine === null || mine.target !== targetId) {
      return null;
    }
    const seen = { used: false };
    const a = change(nk, targetId, nowMs, mine.id, function (x: MoveRules.Ask): MoveRules.Ask | null {
      seen.used = false;
      if (x.state !== MoveRules.APPROVED || x.from !== callerId || x.key_hash === "" ||
          nowMs - x.approved_ms >= MoveRules.KEY_MS || !nk.bcryptCompare(x.key_hash, key)) {
        return null;
      }
      seen.used = true;
      const out = MoveRules.copy(x);
      out.state = MoveRules.DONE;
      out.key_hash = "";
      return out;
    });
    return seen.used ? a : null;
  }

  // sign_in_with_key linked the asking device with its one-time key: the account's devices hear it ("Your game is on a
  // computer now too.").
  export function moved(nk: nkruntime.Nakama, logger: nkruntime.Logger, targetId: string, callerId: string, a: MoveRules.Ask): void {
    Store.remove(nk, Store.ACCOUNT, ASKED_KEY, callerId);
    note(nk, targetId, { what: "moved", kind: a.kind });
    logger.info("move: %s moved to %s's account", callerId, targetId);
  }
}

// move_request {"action": "start", "username", "kind": "phone" | "tablet" | "computer"} -> {"ok", "id", "code" (6
// digits), "valid_s"}; no_such_player (no claimed account has that name), self, rate_limited + wait (this account's own
// asks). {"action": "status", "id"} -> {"ok", "state": "waiting" (+ "left_s") | "approved" (+ "key", a one-time key for
// sign_in_with_key, and "username") | "ended" (+ "why": expired, or cancelled after its own BACK) | "done"}; not_found
// (not this account's newest ask). {"action": "cancel", "id"} -> {"ok"}.
function rpcMoveRequest(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "move_request", payload, function (callerId: string, request: Util.Json): Util.Json {
    if (!MoveRules.ENABLED) {
      return Server.fail("not_available"); // off for now (MoveRules.ENABLED)
    }
    const now = Server.nowMs();
    if (request.action === "start") {
      return Moves.start(nk, logger, callerId, request, now);
    }
    if (request.action === "status") {
      return Moves.status(nk, logger, callerId, request, now);
    }
    if (request.action === "cancel") {
      return Moves.cancel(nk, callerId, request, now);
    }
    return Server.fail("bad_request");
  });
}

// move_approve, on a device of the account asked for (the game asks behind its parent gate): {"action": "list"} ->
// {"ok", "username", "asks": [{"id", "kind", "left_s"}]}; {"action": "approve", "id", "code"} -> {"ok"} | wrong_code +
// tries_left | ended + why | not_found; {"action": "decline", "id"} -> {"ok"} | not_found.
function rpcMoveApprove(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "move_approve", payload, function (callerId: string, request: Util.Json): Util.Json {
    if (!MoveRules.ENABLED) {
      return Server.fail("not_available"); // off for now (MoveRules.ENABLED)
    }
    const now = Server.nowMs();
    if (request.action === "list") {
      return Moves.list(nk, callerId, now);
    }
    if ((request.action === "approve" || request.action === "decline") && !MoveRules.isId(request.id)) {
      return Server.fail("bad_request");
    }
    if (request.action === "approve") {
      return Moves.approve(nk, logger, callerId, request, now);
    }
    if (request.action === "decline") {
      return Moves.decline(nk, callerId, request, now);
    }
    return Server.fail("bad_request");
  });
}
