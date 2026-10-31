// Accounts (spec §17.1-17.2, plan M4 Wave 1): claim_username, get_account_state,
// set_parent_settings, consent_start, consent_status, and the username filter on Nakama's own
// sign-in and account update, so a modified game can't skip it.

namespace Accounts {
  // Survivor gold lives in the Nakama wallet under this key (spec §7.4: the wallet ledger).
  export const GOLD = "survivor_gold";
  // Case-insensitive uniqueness: Nakama's own check is exact-case. The index (made at start, main.ts)
  // makes the database refuse a second "hopper_7" even if two claims race past the query.
  export const SQL_USERNAME_OWNER = "SELECT id::text AS id FROM users WHERE lower(username) = $1 AND id <> $2::uuid LIMIT 1";
  export const SQL_USERNAME_INDEX = "CREATE UNIQUE INDEX IF NOT EXISTS easycraft_users_username_lower ON users (lower(username))";
  export const HISTORY_MAX = 20;

  export interface Loaded {
    userId: string;
    username: string;
    state: AccountRules.Read;
    gold: number;
  }

  export function load(nk: nkruntime.Nakama, userId: string): Loaded {
    const account = nk.accountGetId(userId);
    const wallet: Util.Json = Util.isObject(account.wallet) ? account.wallet : {};
    return {
      userId: userId,
      username: account.user.username,
      state: AccountRules.fromMetadata(account.user.metadata),
      gold: Util.isInt(wallet[GOLD]) ? wallet[GOLD] : 0,
    };
  }

  export function saveState(nk: nkruntime.Nakama, userId: string, state: AccountRules.State): void {
    nk.accountUpdateId(userId, null, null, null, null, null, null, AccountRules.toMetadata(state));
  }

  // Many accounts' states at once (friends, match players).
  export function states(nk: nkruntime.Nakama, userIds: string[]): { [userId: string]: AccountRules.Read } {
    const out: { [userId: string]: AccountRules.Read } = {};
    if (userIds.length === 0) {
      return out;
    }
    const users = nk.usersGetId(userIds);
    for (let i = 0; i < users.length; i++) {
      out[users[i].userId] = AccountRules.fromMetadata(users[i].metadata);
    }
    return out;
  }

  export function nameTakenByOther(nk: nkruntime.Nakama, name: string, userId: string): boolean {
    const rows = nk.sqlQuery(SQL_USERNAME_OWNER, [UsernameRules.uniquenessKey(name), userId || Store.SYSTEM_USER]);
    return rows.length > 0;
  }

  export function consentRecord(nk: nkruntime.Nakama, userId: string): Consent.Record {
    const found = Store.read(nk, Store.PARENT, "consent", userId);
    return Consent.recordFrom(found ? found.value : undefined);
  }

  // What the game needs to know about this account (every account RPC answers with it).
  export function stateReply(nk: nkruntime.Nakama, ctx: nkruntime.Context, userId: string): Util.Json {
    const a = load(nk, userId);
    return {
      ok: true,
      user_id: userId,
      username: a.username,
      claimed: a.state.claimed,
      age_band: a.state.age_band,
      consent: a.state.consent,
      online_allowed: a.state.online_allowed,
      chat: a.state.chat,
      can_play_online: AccountRules.canPlayOnline(a.state),
      chat_level: AccountRules.chatLevel(a.state),
      consent_available: Consent.providerFor(ctx.env) !== null,
      consent_request: consentRecord(nk, userId).status,
      gold: a.gold,
      // 0.2.19: the last match the server saw this player in and the host's last word on its gold there ({"match_id",
      // "seq"} or null): a game back from an online world waits for it before it trusts the wallet (gold-double.md).
      hosted: Economy.hostedReply(nk, userId),
      server_time_ms: Server.nowMs(),
    };
  }

  // The username checks shared by claim_username and the hooks: "" or an error code.
  export function usernameProblem(nk: nkruntime.Nakama, name: unknown, userId: string): string {
    const code = UsernameRules.validate(name);
    if (code !== "") {
      return code;
    }
    return nameTakenByOther(nk, name as string, userId) ? "taken" : "";
  }
}

// claim_username {"username", "age_band"}: the name becomes this account's Nakama username (unique
// whatever the case); the first claim also sets the age band's defaults.
function rpcClaimUsername(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "claim_username", payload, function (userId: string, request: Util.Json): Util.Json {
    const name = typeof request.username === "string" ? UsernameRules.normalize(request.username) : "";
    const code = UsernameRules.validate(name);
    if (code !== "") {
      return Server.fail(code);
    }
    const loaded = Accounts.load(nk, userId);
    const claim = AccountRules.onClaim(loaded.state, request.age_band);
    if (!claim.state) {
      return Server.fail(claim.error || "bad_age_band");
    }
    if (Accounts.nameTakenByOther(nk, name, userId)) {
      return Server.fail("taken");
    }
    try {
      nk.accountUpdateId(userId, name, null, null, null, null, null, AccountRules.toMetadata(claim.state));
    } catch (e) {
      if (/already in use|unique/i.test(Server.errorText(e))) {
        return Server.fail("taken");
      }
      throw e;
    }
    logger.info("username claimed by %s", userId);
    return Accounts.stateReply(nk, ctx, userId);
  });
}

// get_account_state {}: the account's band, consent, parent switches, what it may do, its gold.
function rpcGetAccountState(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "get_account_state", payload, function (userId: string): Util.Json {
    return Accounts.stateReply(nk, ctx, userId);
  });
}

// set_parent_settings {"online_allowed"?, "chat"?, "age_band"?}: the game calls it only after its
// parent gate. Stored in the account metadata and in parent/settings with a short history.
function rpcSetParentSettings(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "set_parent_settings", payload, function (userId: string, request: Util.Json): Util.Json {
    const loaded = Accounts.load(nk, userId);
    const result = AccountRules.applyParentSettings(loaded.state, request);
    if (!result.state) {
      return Server.fail(result.error || "bad_request");
    }
    Accounts.saveState(nk, userId, result.state);
    const now = Server.nowMs();
    const found = Store.read(nk, Store.PARENT, "settings", userId);
    const history: Util.Json[] = found && found.value.history instanceof Array ? found.value.history : [];
    const change: Util.Json = { at_ms: now };
    const keys = ["age_band", "online_allowed", "chat"];
    for (let i = 0; i < keys.length; i++) {
      if (Util.has(request, keys[i])) {
        change[keys[i]] = request[keys[i]];
      }
    }
    history.push(change);
    Store.write(nk, Store.PARENT, "settings", userId, {
      age_band: result.state.age_band,
      online_allowed: result.state.online_allowed,
      chat: result.state.chat,
      updated_ms: now,
      history: history.slice(-Accounts.HISTORY_MAX),
    }, true);
    return Accounts.stateReply(nk, ctx, userId);
  });
}

// consent_start {"parent_contact"?}: asks the provider to reach the parent (under_13 only). The
// contact is passed to the provider and never stored.
function rpcConsentStart(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "consent_start", payload, function (userId: string, request: Util.Json): Util.Json {
    const loaded = Accounts.load(nk, userId);
    const step = Consent.start(loaded.state, Accounts.consentRecord(nk, userId), Consent.providerFor(ctx.env),
      userId, request, Server.nowMs());
    if (step.error) {
      return Server.fail(step.error);
    }
    if (step.changed) {
      Accounts.saveState(nk, userId, step.state);
      Store.write(nk, Store.PARENT, "consent", userId, step.record, true);
    }
    return Accounts.stateReply(nk, ctx, userId);
  });
}

// consent_status {}: asks the provider about the pending request; a yes turns online play on and
// sends notification 103 ("a parent approved something").
function rpcConsentStatus(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  return Server.rpc(ctx, logger, "consent_status", payload, function (userId: string): Util.Json {
    const loaded = Accounts.load(nk, userId);
    const step = Consent.check(loaded.state, Accounts.consentRecord(nk, userId), Consent.providerFor(ctx.env), Server.nowMs());
    if (step.changed) {
      Accounts.saveState(nk, userId, step.state);
      Store.write(nk, Store.PARENT, "consent", userId, step.record, true);
      if (step.approved) {
        nk.notificationSend(userId, "A grown-up said yes! You can play online with friends.", { what: "consent" },
          Notes.PARENT_APPROVED, null, true);
      }
    }
    return Accounts.stateReply(nk, ctx, userId);
  });
}

// Nakama's own account update: the username filter and uniqueness, and no free-text fields that
// could carry personal info (display name, avatar link, location, time zone).
function beforeUpdateAccount(ctx: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama,
    data: nkruntime.UserUpdateAccount): nkruntime.UserUpdateAccount {
  const d = data as Util.Json;
  const personal = ["displayName", "avatarUrl", "location", "timezone"];
  for (let i = 0; i < personal.length; i++) {
    if (typeof d[personal[i]] === "string" && d[personal[i]] !== "") {
      Server.refuse("field_not_allowed", Server.INVALID_ARGUMENT);
    }
  }
  if (typeof d.username === "string" && d.username !== "") {
    const problem = Accounts.usernameProblem(nk, d.username, ctx.userId || "");
    if (problem === "taken") {
      Server.refuse(problem, Server.ALREADY_EXISTS);
    }
    if (problem !== "") {
      Server.refuse(problem, Server.INVALID_ARGUMENT);
    }
  }
  return data;
}

// A username sent with a sign-in (Nakama makes a new account with it) passes the same filter. The
// hook can't tell a new device from a known one (Nakama ignores the name for a known one), so the
// case-insensitive check is left to the database index here; claim_username is the game's way.
function beforeAuthenticateUsername<T extends { username?: string }>(_ctx: nkruntime.Context, _logger: nkruntime.Logger,
    _nk: nkruntime.Nakama, data: T): T {
  if (typeof data.username === "string" && data.username !== "") {
    const code = UsernameRules.validate(data.username);
    if (code !== "") {
      Server.refuse(code, Server.INVALID_ARGUMENT);
    }
  }
  return data;
}

// The message a tombstoned device's sign-in is refused with (the game maps it to its logged-out words).
const DEVICE_LOGGED_OUT = "device_logged_out";

// Owner #105 (the second review's HIGH; the third review's D): the username check, plus: a device id that was unlinked
// from a CLAIMED account (a LOG IN elsewhere, SIGN OUT OTHER DEVICES, a DELETE; tombstones are made for claimed accounts
// only) never signs in or makes a NEW account again: it is refused with its own code (PERMISSION_DENIED,
// "device_logged_out"), which the game shows as the logged-out words whatever its prefs say. Covers old builds too
// (they get an error, never a fresh empty account). A never-claimed account that went (the clean-up) has no tombstone,
// so its device gets a plain 404 and starts anew.
function beforeAuthenticateDevice(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
    data: nkruntime.AuthenticateDeviceRequest): nkruntime.AuthenticateDeviceRequest {
  beforeAuthenticateUsername(ctx, logger, nk, data);
  if (data.account && Keys.wasRemoved(nk, data.account.id)) {
    Server.refuse(DEVICE_LOGGED_OUT, Server.PERMISSION_DENIED);
  }
  return data;
}
