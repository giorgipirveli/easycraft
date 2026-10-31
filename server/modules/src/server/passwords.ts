// Owner #105 (2026-10-15 23:14; module 0.2.20; spec §5.13 "As built (owner #99, #105)"): the account's password, made when
// the name is claimed, and LOG IN with the name and the password on any device: that device is linked to the account
// (as sign_in_with_key does: name, progress, looks and gold come along; worlds stay on each device) and every other
// device of the account is logged out (one device at a time: Keys.signOutOthers unlinks them, ends the account's
// sessions and closes their sockets, so an online one hears it at once and an offline one at its next sign-in, which the
// game makes with create=false: it never makes a new account quietly).
//
// The brake, FROZEN after three reviews (the lead, 2026-10-16): exactly two windows, and nothing else.
// - Every wrong try is counted BEFORE the password is checked, by version, failing closed (a count that can't be written
//   answers "locked"). A correct login clears ONLY its own pair window; nothing else is ever released or decremented.
// - The PAIR window (per target account x asking account): 5 wrong in 15 minutes, then a wait to the window's end. A
//   stranger's tries are counted against the stranger's own asking account, never the child's.
// - The NAME window (per target account): wrong tries from devices NOT known to the account, in a 24-hour window from its first;
//   past 10, each further unknown-device try passes once every 10 minutes. One fixed wait for everyone, no growth/decay.
// - A device KNOWN to the account (its id is LINKED to the account right now) and the grown-up key path are never braked.
//   There is no network window, and no stored list of past devices: "known" is the live link only.
//
//   account/password          (server only) {hash (bcrypt), made_ms}: the game can't read it
//   limits/password_pair:<id> (server only, on the asking account) its tries for the target account id (or name key)
//   limits/password_name      (server only, on the target account) unknown devices' tries for its name (24-hour count)
//   limits/password_change    (server only, on the account) tries of the old password or a key (change, delete)
// Wrong names and wrong passwords get one answer ("wrong_password"), with one bcrypt compare on every path, so neither
// the answer nor its timing ever says whether the name exists.

namespace Passwords {
  export const KEY = "password";
  export const PAIR_PREFIX = "password_pair:";
  export const NAME_TRIES = "password_name";
  export const CHANGE_TRIES = "password_change";
  // The timing-even compare's own hash: made with nk.bcryptHash itself (the server's real cost, the final review: a
  // fixed cost-10 hash answered in 100 ms against a real hash's 740 ms), once per node, kept in the node's cache.
  const PROBE_KEY = "password_probe_hash";
  const PROBE_TEXT = "easycraft-timing-probe";
  const WRITE_TRIES = 3;

  export function probeHash(nk: nkruntime.Nakama): string {
    const cached = nk.localcacheGet(PROBE_KEY);
    if (typeof cached === "string" && cached !== "") {
      return cached;
    }
    const made = nk.bcryptHash(PROBE_TEXT);
    nk.localcachePut(PROBE_KEY, made, 0);
    return made;
  }

  export interface Stored {
    hash: string;
    made_ms: number;
  }

  // One window to count a try in: `key` of `userId`, at most `max` in `windowMs`.
  export interface Counter {
    key: string;
    userId: string;
    max: number;
    windowMs: number;
  }

  // A try counted in a window, and when that window began (a release gives back only in that very window).
  export interface Held {
    counter: Counter;
    since: number;
  }

  export const TRIED_KEY = "password_tried";   // account: {at_ms} the last new device's wrong try the account heard of
  export const NOTE = 112;                     // {"what": "tried"} to the account's devices (persistent)
  // A fixed non-empty probe for the timing-even compare (never an empty string: bcryptCompare("") can throw — N5).
  const DUMMY_PROBE = "x";

  export function stored(nk: nkruntime.Nakama, userId: string): Stored | null {
    const found = Store.read(nk, Store.ACCOUNT, KEY, userId);
    if (!found || typeof found.value.hash !== "string" || found.value.hash === "") {
      return null;
    }
    return { hash: found.value.hash, made_ms: Util.isInt(found.value.made_ms) ? found.value.made_ms : 0 };
  }

  export function matches(nk: nkruntime.Nakama, s: Stored | null, text: unknown): boolean {
    return matchesEvenTiming(nk, s, text);
  }

  // Always spends exactly one bcrypt compare, against a real hash or a dummy, with a non-empty probe and the same
  // try/catch on every path, so neither the answer nor its timing says whether the name exists or has a password (the
  // third review's N5). Returns whether the password is right (false whenever there is no stored hash).
  export function matchesEvenTiming(nk: nkruntime.Nakama, s: Stored | null, text: unknown): boolean {
    const probe = PasswordRules.checkable(text) ? (text as string) : DUMMY_PROBE;
    const hash = s !== null ? s.hash : probeHash(nk);
    let ok = false;
    try {
      ok = nk.bcryptCompare(hash, probe);
    } catch (_e) {
      ok = false;
    }
    return s !== null && PasswordRules.checkable(text) && ok;
  }

  // One more try counted in a hard window (the pair), by version, before anything is checked: {ok, wait, since}. Not ok
  // when the window is full, or when no write landed (fail closed).
  export function reserve(nk: nkruntime.Nakama, c: Counter, nowMs: number): { ok: boolean; wait: number; since: number } {
    for (let attempt = 0; attempt < WRITE_TRIES; attempt++) {
      const found = Store.read(nk, Store.LIMITS, c.key, c.userId);
      const r = PasswordRules.reserve(KeyRules.triesFrom(found ? found.value : undefined), nowMs, c.max, c.windowMs);
      if (!r.ok) {
        return { ok: false, wait: r.wait, since: 0 };
      }
      try {
        Store.write(nk, Store.LIMITS, c.key, c.userId, r.next as unknown as Util.Json, false, found ? found.version : "*");
        return { ok: true, wait: 0, since: r.next.since_ms };
      } catch (_e) {
        // counted by another try meanwhile: read it again and count on top
      }
    }
    return { ok: false, wait: 60, since: 0 };   // no write landed: fail closed (locked)
  }

  // One more unknown-device try in the NAME window (per target account): a 24-hour window from its first wrong try, a
  // fixed wait past the cap, by version, failing closed. {ok, wait, braked (the fixed wait, not a hard lock)}.
  export function reserveName(nk: nkruntime.Nakama, userId: string, nowMs: number): { ok: boolean; wait: number; braked: boolean } {
    for (let attempt = 0; attempt < WRITE_TRIES; attempt++) {
      const found = Store.read(nk, Store.LIMITS, NAME_TRIES, userId);
      const r = PasswordRules.reserveName(PasswordRules.nameFrom(found ? found.value : undefined), nowMs);
      if (!r.ok) {
        return { ok: false, wait: r.wait, braked: true };
      }
      try {
        Store.write(nk, Store.LIMITS, NAME_TRIES, userId, r.next as unknown as Util.Json, false, found ? found.version : "*");
        return { ok: true, wait: 0, braked: false };
      } catch (_e) {
        // counted by another try meanwhile: read again and count on top
      }
    }
    return { ok: false, wait: 60, braked: false };   // no write landed: fail closed (locked)
  }

  // This request's own try taken back in the window it was counted in only, by version, best effort. Used for the pair
  // window alone (the frozen design: nothing else is ever released). The NAME window is never decremented.
  export function release(nk: nkruntime.Nakama, h: Held): void {
    const c = h.counter;
    for (let attempt = 0; attempt < WRITE_TRIES; attempt++) {
      const found = Store.read(nk, Store.LIMITS, c.key, c.userId);
      if (!found) {
        return;
      }
      const next = PasswordRules.release(KeyRules.triesFrom(found.value), c.max, h.since) as unknown as Util.Json | null;
      if (next === null) {
        return;
      }
      try {
        Store.write(nk, Store.LIMITS, c.key, c.userId, next, false, found.version);
        return;
      } catch (_e) {
        // changed meanwhile: again
      }
    }
  }

  export function clear(nk: nkruntime.Nakama, key: string, userId: string): void {
    Store.remove(nk, Store.LIMITS, key, userId);
  }

  export function write(nk: nkruntime.Nakama, userId: string, text: string, nowMs: number): void {
    Store.write(nk, Store.ACCOUNT, KEY, userId, { hash: nk.bcryptHash(text), made_ms: nowMs }, false);
  }

  // A new device's wrong try for the account: its devices hear of it at most once an hour (kept on the account for a
  // device that is offline now, and a persistent note); nothing goes back to the asker.
  export function noteTried(nk: nkruntime.Nakama, userId: string, nowMs: number): void {
    const found = Store.read(nk, Store.ACCOUNT, TRIED_KEY, userId);
    const at = found && Util.isInt(found.value.at_ms) ? found.value.at_ms : 0;
    if (nowMs - at < PasswordRules.NOTE_EVERY_MS) {
      return;
    }
    try {
      Store.write(nk, Store.ACCOUNT, TRIED_KEY, userId, { at_ms: nowMs }, false, found ? found.version : "*");
    } catch (_e) {
      return;   // another try noted it at the same moment
    }
    try {
      nk.notificationSend(userId, "Someone tried to log in", { what: "tried" }, NOTE, null, true);
    } catch (_e) {
      // the account's state says it (password "state": tried_ms)
    }
  }

  export function triedMs(nk: nkruntime.Nakama, userId: string): number {
    const found = Store.read(nk, Store.ACCOUNT, TRIED_KEY, userId);
    return found && Util.isInt(found.value.at_ms) ? found.value.at_ms : 0;
  }

  // Whether `deviceId` is KNOWN to the account: its id is LINKED to the account right now (the frozen design — no stored
  // list of past devices, so a logged-out id is never "known" and never a bearer token).
  export function knows(nk: nkruntime.Nakama, userId: string, deviceId: unknown): boolean {
    return KeyRules.isDeviceId(deviceId) && Keys.deviceIds(nk, userId).indexOf(deviceId as string) >= 0;
  }

  // A proof for a change (the old password, or the account's grown-up key) or for DELETE (the password), counted
  // first in CHANGE_TRIES: "" when proved; else "locked" (+ wait in `out`), "wrong_password", "password_needed".
  export function prove(nk: nkruntime.Nakama, userId: string, text: unknown, typedKey: unknown, nowMs: number,
      out: Util.Json): string {
    const c: Counter = { key: CHANGE_TRIES, userId: userId, max: PasswordRules.CHANGE_MAX_WRONG,
      windowMs: PasswordRules.CHANGE_WINDOW_MS };
    const r = reserve(nk, c, nowMs);
    if (!r.ok) {
      out.wait = r.wait;
      return "locked";
    }
    let ok = matches(nk, stored(nk, userId), text);
    if (!ok && typeof typedKey === "string") {
      const key = KeyRules.normalize(typedKey);
      ok = key !== null && KeyRules.matches(Keys.hasher(nk), Keys.stored(nk, userId), key);
    }
    if (ok) {
      clear(nk, CHANGE_TRIES, userId);
      return "";
    }
    return text !== undefined || typedKey !== undefined ? "wrong_password" : "password_needed";
  }
}

// password {"action": "state"} -> {"ok", "has_password"}; {"action": "set", "password"} (the first one, a claimed account)
// -> {"ok"} | too_short | too_long | bad_chars | is_name | too_common | has_password | not_claimed; {"action": "change",
// "password" (the new one), "old" | "key" (a grown-up's key: FORGOT PASSWORD)} -> {"ok"} | wrong_password | locked +
// wait | the new one's problem.
function rpcPassword(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "password", payload, function (callerId: string, request: Util.Json): Util.Json {
    const now = Server.nowMs();
    const s = Passwords.stored(nk, callerId);
    if (request.action === "state") {
      return { ok: true, has_password: s !== null, tried_ms: Passwords.triedMs(nk, callerId) };
    }
    if (request.action !== "set" && request.action !== "change") {
      return Server.fail("bad_request");
    }
    const loaded = Accounts.load(nk, callerId);
    if (!loaded.state.claimed) {
      return Server.fail("not_claimed");
    }
    if (request.action === "set" && s !== null) {
      return Server.fail("has_password");
    }
    if (request.action === "change" && s !== null) {
      const out: Util.Json = {};
      const why = Passwords.prove(nk, callerId, request.old, request.key, now, out);
      if (why !== "") {
        return Server.fail(why === "password_needed" ? "wrong_password" : why, out);
      }
    }
    const problem = PasswordRules.problem(request.password, loaded.username);
    if (problem !== "") {
      return Server.fail(problem);
    }
    Passwords.write(nk, callerId, request.password as string, now);
    logger.info("password %s by %s", request.action === "set" ? "made" : "changed", callerId);
    return { ok: true };
  });
}

// sign_in_with_password {"username", "password", "device_id" (a NEW random id the asking game made), "known_device" (the
// id this device played as the account with before, if any)} -> {"ok", "user_id", "username", "left": "deleted" | "kept" |
// "same"}: that id is linked to the account and every other device of the account is logged out (unlinked, its sessions
// ended, its sockets closed); the asking account goes when it never claimed a name. wrong_password for a wrong name, a
// wrong password or an account without one (one answer); locked + wait (a window full, PasswordRules); bad_request.
function rpcSignInWithPassword(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "sign_in_with_password", payload, function (callerId: string, request: Util.Json): Util.Json {
    const now = Server.nowMs();
    if (!KeyRules.isDeviceId(request.device_id)) {
      return Server.fail("bad_request");
    }
    const target = Moves.target(nk, request.username);
    // The asking account must be a real one: a brand-new account asking at once is a throwaway's pattern (it waits)
    const created = Number(nk.accountGetId(callerId).user.createTime) || 0;
    const age = now - created * 1000;
    if (created > 0 && age < PasswordRules.ASKER_MIN_AGE_MS) {
      return Server.fail("too_new", { wait: Math.ceil((PasswordRules.ASKER_MIN_AGE_MS - age) / 1000) });
    }
    // A device KNOWN to the account (its id is LINKED right now) is never braked; nor is the key path.
    const known = target !== null && Passwords.knows(nk, target.userId, request.known_device);
    // The PAIR window (this asking account x this target account; a name nobody has: its uniqueness key) is a hard
    // window: a stranger's tries are counted against the stranger's own asking account, never the child's.
    const pair: Passwords.Counter = { key: Passwords.PAIR_PREFIX + (target !== null ? target.userId :
      PasswordRules.nameKey(request.username)), userId: callerId, max: PasswordRules.PAIR_MAX_WRONG,
      windowMs: PasswordRules.PAIR_WINDOW_MS };
    let heldPair: Passwords.Held | null = null;
    if (!known) {
      const p = Passwords.reserve(nk, pair, now);   // counted before the password is checked
      if (!p.ok) {
        return Server.fail("locked", { wait: p.wait });
      }
      heldPair = { counter: pair, since: p.since };
      // The NAME window (per target account), unknown devices only: past the cap, one try every 10 minutes per name.
      if (target !== null) {
        const n = Passwords.reserveName(nk, target.userId, now);
        if (!n.ok) {
          Passwords.release(nk, heldPair);   // this try never happened: give the pair back
          return Server.fail(n.braked ? "slow_down" : "locked", { wait: n.wait });
        }
      }
    }
    // One bcrypt compare on every path (a wrong name, or an account with no password, too), so neither the answer nor
    // its timing tells the asker whether the name exists; a new device's wrong try is always noted.
    if (!Passwords.matchesEvenTiming(nk, target !== null ? Passwords.stored(nk, target.userId) : null, request.password)) {
      if (target !== null) {
        Passwords.noteTried(nk, target.userId, now);
      }
      return Server.fail("wrong_password"); // the try stays counted
    }
    if (target === null) {
      return Server.fail("wrong_password"); // unreachable (matchesEvenTiming is false for a null target), for the type
    }
    if (heldPair !== null) {
      Passwords.clear(nk, pair.key, callerId); // this asker x this account: its window goes (the only thing released)
    }
    if (target.userId === callerId) {
      return { ok: true, user_id: target.userId, username: target.username, left: "same" };
    }
    try {
      nk.linkDevice(target.userId, request.device_id as string);
    } catch (e) {
      logger.warn("sign_in_with_password: device not linked for %s: %s", callerId, Server.errorText(e));
      return Server.fail("bad_request");
    }
    Keys.capLinkedDevices(nk, target.userId, request.device_id as string);   // N7: at most KeyRules linked ids per account
    const out = Keys.signOutOthers(nk, target.userId, request.device_id); // one device at a time (owner #105)
    logger.info("a device logged in to %s with its password; %d other devices logged out", target.userId, out.removed);
    // The asking account stays: it is the device's own credential for asking (old enough for its next LOG IN: a new one
    // waits, ASKER_MIN_AGE_MS); an empty one goes with the retention clean-up after 13 months without a sign-in.
    return { ok: true, user_id: target.userId, username: target.username, left: "kept" };
  });
}

// log_out {"device_id": this device's own} -> {"ok"} | password_needed (a claimed account with no password: the game asks
// for one first, so the player can log back in) | not_claimed | not_allowed (that id is not linked to the caller).
// Owner #105 (the final review's decision): LOG OUT unlinks THIS device from the account (when it is the account's last
// device, a random custom id nobody holds is linked first: Nakama never unlinks an account's last identifier), tombstones
// the id (it never signs in or makes an account again) and ends the account's sessions. The account stays safe on the
// server (its profile backup and gold); LOG IN with the name and the password brings it back on any device.
function rpcLogOut(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "log_out", payload, function (callerId: string, request: Util.Json): Util.Json {
    if (!Accounts.load(nk, callerId).state.claimed) {
      return Server.fail("not_claimed");
    }
    if (Passwords.stored(nk, callerId) === null) {
      return Server.fail("password_needed");
    }
    const ids = Keys.deviceIds(nk, callerId);
    if (!KeyRules.isDeviceId(request.device_id) || ids.indexOf(request.device_id as string) < 0) {
      return Server.fail("not_allowed");
    }
    if (ids.length <= 1) {
      nk.linkCustom(callerId, "logged-out-" + nk.uuidv4());   // a placeholder identifier nobody holds
    }
    nk.unlinkDevice(callerId, request.device_id as string);
    Keys.recordRemoved(nk, request.device_id, Server.nowMs());
    nk.sessionLogout(callerId);
    logger.info("a device logged out of %s", callerId);
    return { ok: true };
  });
}
