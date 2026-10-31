// The account on every device (owner #67; spec §5.13, §17.1): the sign-in key (KeyRules) and linking a
// new device to the account it names. A Nakama account is reached by device ids only (no password, no
// e-mail); a key links one more device id to the account, so a new phone or a browser whose storage
// was wiped signs in to the same account and its profile backup, wallet and friends come back.
//
//   account/sign_in_key   (server only; the game can't read it) {hash (bcrypt), made_ms}
//   limits/key_new        (server only) the new-key window
//   wrong keys            the node's local cache (per name, per asking account): nothing is stored
//                         about a name nobody owns, and the counts go with the window

namespace Keys {
  export const STORE_KEY = "sign_in_key";
  export const NEW_LIMIT_KEY = "key_new";
  const NAME_TRIES = "key_tries_name:";
  const CALLER_TRIES = "key_tries_by:";
  const NOTIFICATION_STREAM = 0; // every realtime socket of a user joins its notifications stream
  // Owner #105 (the second review's HIGH): a device id unlinked by a LOG IN elsewhere, SIGN OUT OTHER DEVICES or a
  // DELETE is remembered (only a salted hash, server-only), so beforeAuthenticateDevice never makes a NEW account for
  // it: an old build's phone, or a device that missed the client fix, can't quietly reappear and re-claim a freed name.
  const REMOVED_PREFIX = "removed_device:";
  const DEVICE_SALT_KEY = "device_salt";

  function deviceSalt(nk: nkruntime.Nakama): string {
    let found = Store.read(nk, Store.ACCOUNT, DEVICE_SALT_KEY, Store.SYSTEM_USER);
    if (!found || typeof found.value.salt !== "string" || found.value.salt === "") {
      try {
        Store.write(nk, Store.ACCOUNT, DEVICE_SALT_KEY, Store.SYSTEM_USER, { salt: nk.uuidv4() + nk.uuidv4() }, false, "*");
      } catch (_e) {
        // made by another call meanwhile
      }
      found = Store.read(nk, Store.ACCOUNT, DEVICE_SALT_KEY, Store.SYSTEM_USER);
    }
    return found && typeof found.value.salt === "string" ? found.value.salt : "";
  }

  function removedKey(nk: nkruntime.Nakama, deviceId: string): string {
    return REMOVED_PREFIX + nk.sha256Hash(deviceSalt(nk) + "|" + deviceId).substring(0, 32);
  }

  // Remember that `deviceId` was unlinked from an account (best effort; a lost write just means no tombstone).
  export function recordRemoved(nk: nkruntime.Nakama, deviceId: unknown, nowMs: number): void {
    if (!KeyRules.isDeviceId(deviceId)) {
      return;
    }
    try {
      Store.write(nk, Store.ACCOUNT, removedKey(nk, deviceId as string), Store.SYSTEM_USER, { at_ms: nowMs }, false, "*");
    } catch (_e) {
      // already recorded
    }
  }

  // Whether `deviceId` was unlinked from an account before (so authenticate must not create a new one for it).
  export function wasRemoved(nk: nkruntime.Nakama, deviceId: unknown): boolean {
    if (!KeyRules.isDeviceId(deviceId)) {
      return false;
    }
    return Store.read(nk, Store.ACCOUNT, removedKey(nk, deviceId as string), Store.SYSTEM_USER) !== null;
  }

  // The third review's N7: cap how many device ids an account keeps linked (KeyRules.MAX_LINKED), unlinking the extras
  // (keeping `keepNewest`, the id that just logged in) and tombstoning them, so a client can't link ids without bound.
  export function capLinkedDevices(nk: nkruntime.Nakama, userId: string, keepNewest: string): void {
    const ids = deviceIds(nk, userId);
    let over = ids.length - KeyRules.MAX_LINKED;
    if (over <= 0) {
      return;
    }
    const now = Server.nowMs();
    for (let i = 0; i < ids.length && over > 0; i++) {
      if (ids[i] !== keepNewest) {
        try {
          nk.unlinkDevice(userId, ids[i]);
          recordRemoved(nk, ids[i], now);
          over--;
        } catch (_e) {
          // a last-identifier or race: leave it
        }
      }
    }
  }

  // Keys are kept as bcrypt hashes (KeyRules.Hasher).
  export function hasher(nk: nkruntime.Nakama): KeyRules.Hasher {
    return {
      hash: (text: string) => nk.bcryptHash(text),
      check: (hash: string, text: string) => nk.bcryptCompare(hash, text),
    };
  }

  export function stored(nk: nkruntime.Nakama, userId: string): KeyRules.Stored | null {
    const found = Store.read(nk, Store.ACCOUNT, STORE_KEY, userId);
    return found ? KeyRules.storedFrom(found.value) : null;
  }

  export function deviceIds(nk: nkruntime.Nakama, userId: string): string[] {
    const devices = nk.accountGetId(userId).devices || [];
    const out: string[] = [];
    for (let i = 0; i < devices.length; i++) {
      if (devices[i] && typeof devices[i].id === "string") {
        out.push(devices[i].id);
      }
    }
    return out;
  }

  export function tries(nk: nkruntime.Nakama, cacheKey: string): KeyRules.Tries {
    const cached = nk.localcacheGet(cacheKey);
    if (typeof cached !== "string") {
      return KeyRules.emptyTries();
    }
    try {
      return KeyRules.triesFrom(JSON.parse(cached));
    } catch (_e) {
      return KeyRules.emptyTries();
    }
  }

  export function saveTries(nk: nkruntime.Nakama, cacheKey: string, t: KeyRules.Tries, windowMs: number): void {
    nk.localcachePut(cacheKey, JSON.stringify(t), Math.ceil(windowMs / 1000) * 2);
  }

  export function nameKey(name: string): string {
    return NAME_TRIES + name;
  }

  export function callerKey(userId: string): string {
    return CALLER_TRIES + userId;
  }

  // A new key: shown once to the grown-up, its salted hash kept (the one before stops working).
  export function make(nk: nkruntime.Nakama, userId: string, now: number): Util.Json {
    const found = Store.read(nk, Store.LIMITS, NEW_LIMIT_KEY, userId);
    const window = KeyRules.triesFrom(found ? found.value : undefined);
    const next = KeyRules.wrong(window, now, KeyRules.NEW_MAX + 1, KeyRules.NEW_WINDOW_MS);
    if (KeyRules.wait(window, now) > 0 || next.wrong > KeyRules.NEW_MAX) {
      return Server.fail("rate_limited");
    }
    Store.write(nk, Store.LIMITS, NEW_LIMIT_KEY, userId, next, false);
    const key = KeyRules.fromHex(nk.uuidv4().replace(/-/g, ""));
    Store.write(nk, Store.ACCOUNT, STORE_KEY, userId, KeyRules.store(hasher(nk), key, now), false);
    return {
      ok: true, key: KeyRules.pretty(key), username: Accounts.load(nk, userId).username, made_ms: now,
      devices: deviceIds(nk, userId).length,
    };
  }

  // Every other device of the account stops signing in: it is unlinked, remembered as removed (so it never makes a new
  // account for itself) and dropped from the account's known-devices list (owner #105); its sessions end (sessionLogout)
  // and every open socket of the account closes (the game that asked signs in again). Already-issued session and refresh
  // tokens are invalidated by sessionLogout, so a logged-out device's token answers 401 and cannot be renewed.
  export function signOutOthers(nk: nkruntime.Nakama, userId: string, keep: unknown): Util.Json {
    const ids = deviceIds(nk, userId);
    if (typeof keep !== "string" || ids.indexOf(keep) < 0) {
      return Server.fail("not_allowed");
    }
    const now = Server.nowMs();
    let removed = 0;
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] !== keep) {
        nk.unlinkDevice(userId, ids[i]);
        recordRemoved(nk, ids[i], now);   // owner #105: a logged-out id makes no new account, and is no longer "known"
        removed++;
      }
    }
    nk.sessionLogout(userId);
    const sockets = nk.streamUserList({ mode: NOTIFICATION_STREAM, subject: userId }) || [];
    for (let i = 0; i < sockets.length; i++) {
      nk.sessionDisconnect(sockets[i].sessionId);
    }
    return { ok: true, removed: removed, devices: ids.length - removed };
  }

}

// account_key {"action": "state"} -> {"ok", "has_key", "made_ms", "devices", "username"};
// {"action": "new"} -> {"ok", "key": "XXXX-XXXX", "username", "made_ms", "devices"} (a claimed account; at most
// KeyRules.NEW_MAX an hour: rate_limited); {"action": "sign_out_others", "device_id": this device's} -> {"ok",
// "removed", "devices"} (not_allowed unless that id is the account's). The game asks behind its parent gate.
// The owner, without a session (the runtime HTTP key, or the console's API Explorer with no user id), names the
// account ({"username"} or {"user_id"}) for "state" and "new": a family whose every device lost the account writes in,
// and the owner sends them a new key (docs/hosting.md). not_found; a player naming another account: not_allowed.
function rpcAccountKey(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpcOrAdmin(ctx, logger, "account_key", payload, function (callerId: string, request: Util.Json): Util.Json {
    const now = Server.nowMs();
    const names = Util.has(request, "user_id") || Util.has(request, "username");
    let userId = callerId;
    if (callerId === "") {
      if (!names || request.action === "sign_out_others") {
        return Server.fail("bad_request"); // the owner names the account; signing devices out is the family's step
      }
      const target = Social.find(nk, request);
      if (target === null) {
        return Server.fail("not_found");
      }
      userId = target.userId;
      logger.info("account_key %s by the owner for %s", String(request.action), userId);
    } else if (names) {
      const named = Social.find(nk, request);
      if (named === null || named.userId !== callerId) {
        return Server.fail("not_allowed");
      }
    }
    const loaded = Accounts.load(nk, userId);
    if (request.action === "state") {
      const s = Keys.stored(nk, userId);
      return { ok: true, has_key: s !== null, made_ms: s ? s.made_ms : 0, devices: Keys.deviceIds(nk, userId).length,
        username: loaded.username };
    }
    if (request.action !== "new" && request.action !== "sign_out_others") {
      return Server.fail("bad_request");
    }
    if (!loaded.state.claimed) {
      return Server.fail("not_claimed");
    }
    if (request.action === "new") {
      logger.info("sign-in key made by %s", userId);
      return Keys.make(nk, userId, now);
    }
    const r = Keys.signOutOthers(nk, userId, request.device_id);
    if (r.ok) {
      logger.info("other devices signed out by %s: %d", userId, r.removed);
    }
    return r;
  });
}

// sign_in_with_key {"username", "key", "device_id"}: the asking game (signed in on its own account) names the
// account and its key (a grown-up's, or since 0.2.20 the one-time key an approved move handed to this asking account:
// owner #99, moves.ts), and a NEW device id it made; that id is linked to the named account, so the game signs in
// with it next. {"ok", "user_id", "username", "left": "deleted" | "kept" | "same"}: the asking account is deleted
// when it never claimed a name (a new device's own empty account), kept otherwise. A wrong key, an unknown name, a
// name without a key or a never-claimed one: all "wrong_key"; "locked" (+ "wait" seconds) after too many;
// "bad_request" for an odd device id or one already linked anywhere.
function rpcSignInWithKey(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "sign_in_with_key", payload, function (callerId: string, request: Util.Json): Util.Json {
    const now = Server.nowMs();
    if (!KeyRules.isDeviceId(request.device_id)) {
      return Server.fail("bad_request");
    }
    // The second review's finding 3: wrong keys are counted PER ASKING ACCOUNT only, never per name, so a stranger's
    // wrong keys on a child's name can never keep the grown-up's right key out ("the key always works" under attack).
    const byCaller = Keys.callerKey(callerId);
    const callerTries = Keys.tries(nk, byCaller);
    const name = typeof request.username === "string" ? UsernameRules.uniquenessKey(request.username) : "";
    const wait = KeyRules.wait(callerTries, now);
    if (wait > 0) {
      return Server.fail("locked", { wait: wait });
    }
    const key = KeyRules.normalize(request.key);
    const rows = name !== "" && name.length <= UsernameRules.MAX_LEN ? nk.sqlQuery(Accounts.SQL_USERNAME_OWNER, [name, Store.SYSTEM_USER]) : [];
    const targetId = rows.length > 0 ? String(rows[0].id) : "";
    const target = targetId !== "" ? Accounts.load(nk, targetId) : null;
    const claimed = key !== null && target !== null && target.state.claimed ? target : null;
    // One bcrypt compare on every path (a name nobody has, an account without a key, a bad key too), against the
    // server's probe hash when there is no real one, so the timing never tells (the final review's 5).
    const keyHash = claimed !== null ? Keys.stored(nk, targetId) : null;
    let grownUps = false;
    try {
      const same = nk.bcryptCompare(keyHash !== null ? keyHash.hash : Passwords.probeHash(nk), key !== null ? key : "x");
      grownUps = keyHash !== null && key !== null && same;
    } catch (_e) {
      grownUps = false;
    }
    // Owner #99 (0.2.20): or the one-time key an approved move handed to this very asking account (moves.ts), used up
    // here by version before anything is linked (two uses at once: one finds it used)
    const move = claimed !== null && !grownUps ? Moves.consume(nk, targetId, callerId, key as string, now) : null;
    if (claimed === null || (!grownUps && move === null)) {
      Keys.saveTries(nk, byCaller, KeyRules.wrong(callerTries, now, KeyRules.CALLER_MAX_WRONG, KeyRules.CALLER_WINDOW_MS),
        KeyRules.CALLER_WINDOW_MS);
      return Server.fail("wrong_key");
    }
    if (targetId === callerId) {
      return { ok: true, user_id: targetId, username: claimed.username, left: "same" };
    }
    try {
      nk.linkDevice(targetId, request.device_id as string);
    } catch (e) {
      logger.warn("sign_in_with_key: device not linked for %s: %s", callerId, Server.errorText(e));
      return Server.fail("bad_request");
    }
    logger.info("a device signed in to %s with its key", targetId);
    if (move !== null) {
      Moves.moved(nk, logger, targetId, callerId, move); // the account's devices hear it
    }
    // Owner #105 (the final review's 5): one device at a time with a key too, and at most MAX_LINKED ids per account
    Keys.capLinkedDevices(nk, targetId, request.device_id as string);
    Keys.signOutOthers(nk, targetId, request.device_id);
    let left = "kept";
    if (!Accounts.load(nk, callerId).state.claimed) {
      try {
        Deletion.run(nk, logger, callerId, "a new device's own account, replaced by a key sign-in");
        left = "deleted";
      } catch (e) {
        logger.warn("sign_in_with_key: the asking account stays: %s", Server.errorText(e)); // the retention clean-up
      }
    }
    return { ok: true, user_id: targetId, username: claimed.username, left: left };
  });
}
