// Owner #67 (spec §5.13, §17.1): the account on every device. account_key makes a sign-in key (a
// grown-up, on a device where the child plays), tells whether one exists and signs other devices out;
// sign_in_with_key links a new device id to the account named with the right key, so that device signs
// in to it (its own new, never-claimed account goes). The game writes its profile backup itself, and
// the server cleans every write (ProfileRules) before Nakama keeps it.
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { server } from "./harness.ts";
import { FakeNakama, FakeLogger, ctx } from "./fake_nakama.ts";

const S = server();
const A = S.AccountRules;
const K = S.KeyRules;
const TEEN = A.defaults("13_plus");
const KID = { ...A.defaults("under_13"), consent: "verified", online_allowed: true };
const UNCLAIMED = {};
const NEW_DEVICE = "0b8f6a8e-3c1d-4a8e-9f00-1234567890ab";
const OTHER_DEVICE = "5d7e2c1a-9b8f-4e6d-8c7b-0a1b2c3d4e5f";

let nk: FakeNakama;
let log: FakeLogger;
let now = 1_790_000_000_000;

beforeEach(() => {
  nk = new FakeNakama();
  log = new FakeLogger();
  now = 1_790_000_000_000;
  nk.clock = () => now;
  S.Server.nowMs = () => now;
});

function key(userId: string, payload: object): any {
  return JSON.parse(S.rpcAccountKey(ctx(userId), log, nk, JSON.stringify(payload)));
}

function signIn(callerId: string, payload: object): any {
  return JSON.parse(S.rpcSignInWithKey(ctx(callerId), log, nk, JSON.stringify(payload)));
}

// A child's account with a phone, and a new device's own fresh account asking.
function family(meta: object = KID): { child: string; phone: string; asker: string; key: string } {
  const child = nk.addUser("Sasa_7", meta);
  nk.linkDevice(child, "phone-device-0001");
  const asker = nk.addUser("x9Rq2w", UNCLAIMED);
  nk.linkDevice(asker, "browser-device-01");
  const made = key(child, { action: "new" });
  assert.equal(made.ok, true, JSON.stringify(made));
  return { child, phone: "phone-device-0001", asker, key: made.key };
}

test("a claimed account makes a key: shown once, only its salted hash kept, the owner's game can't read it", () => {
  const child = nk.addUser("Sasa_7", KID);
  nk.linkDevice(child, "phone-device-0001");
  const r = key(child, { action: "new" });
  assert.equal(r.ok, true);
  assert.match(r.key, /^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
  assert.equal(r.username, "Sasa_7");
  assert.equal(r.made_ms, now);
  assert.equal(r.devices, 1);
  const o = nk.object("account", "sign_in_key", child)!;
  assert.equal(o.permissionRead, 0, "the game can't read it back");
  assert.equal(o.permissionWrite, 0);
  assert.ok(!JSON.stringify(o.value).includes(r.key.replace("-", "")), "never the key itself");
  assert.equal(K.matches({ hash: (t) => nk.bcryptHash(t), check: (h, t) => nk.bcryptCompare(h, t) }, K.storedFrom(o.value),
    K.normalize(r.key)), true);
});

test("the state: whether a key exists, when it was made, how many devices", () => {
  const child = nk.addUser("Sasa_7", TEEN);
  nk.linkDevice(child, "phone-device-0001");
  assert.deepEqual(key(child, { action: "state" }), { ok: true, has_key: false, made_ms: 0, devices: 1, username: "Sasa_7" });
  key(child, { action: "new" });
  assert.deepEqual(key(child, { action: "state" }), { ok: true, has_key: true, made_ms: now, devices: 1, username: "Sasa_7" });
});

test("no key before a name is claimed", () => {
  const fresh = nk.addUser("x9Rq2w", UNCLAIMED);
  assert.deepEqual(key(fresh, { action: "new" }), { ok: false, error: "not_claimed" });
  assert.equal(key(fresh, { action: "what" }).error, "bad_request");
});

test("a few new keys an hour at most", () => {
  const child = nk.addUser("Sasa_7", TEEN);
  for (let i = 0; i < K.NEW_MAX; i++) {
    assert.equal(key(child, { action: "new" }).ok, true);
  }
  assert.equal(key(child, { action: "new" }).error, "rate_limited");
  now += K.NEW_WINDOW_MS + 1;
  assert.equal(key(child, { action: "new" }).ok, true);
});

test("the name (any case) and the key (as typed) sign a new device in to the account; its own fresh account goes", () => {
  const f = family();
  const typed = f.key.toLowerCase().replace("-", " ");
  const r = signIn(f.asker, { username: "sasa_7", key: typed, device_id: NEW_DEVICE });
  assert.deepEqual(r, { ok: true, user_id: f.child, username: "Sasa_7", left: "deleted" });
  assert.equal(nk.deviceOwner(NEW_DEVICE), f.child, "the new device signs in to the child's account now");
  assert.equal(nk.deviceOwner(f.phone), undefined, "one device at a time: the phone is logged out (owner #105)");
  assert.equal(S.Keys.wasRemoved(nk, f.phone), true, "and its id is tombstoned");
  assert.equal(nk.users.has(f.asker), false, "the asking device's own fresh account is gone");
  assert.equal(nk.deviceOwner("browser-device-01"), undefined);
});

test("an asking account that claimed a name of its own is kept", () => {
  const f = family();
  const sibling = nk.addUser("Bro_9", TEEN);
  const r = signIn(sibling, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE });
  assert.equal(r.left, "kept");
  assert.equal(nk.users.has(sibling), true);
});

test("already this account: nothing to link", () => {
  const f = family();
  assert.deepEqual(signIn(f.child, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE }),
    { ok: true, user_id: f.child, username: "Sasa_7", left: "same" });
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("a wrong key, an unknown name, a name without a key, a never-claimed name: all the same answer", () => {
  const f = family();
  nk.addUser("NoKey_1", TEEN);
  const other = nk.addUser("Other_1", TEEN);
  key(other, { action: "new" });
  const cases = [
    { username: "Sasa_7", key: "0000-0000" },
    { username: "Nobody_1", key: f.key },
    { username: "NoKey_1", key: f.key },
    { username: "Other_1", key: f.key },
  ];
  for (const c of cases) {
    assert.deepEqual(signIn(f.asker, { ...c, device_id: NEW_DEVICE }), { ok: false, error: "wrong_key" }, JSON.stringify(c));
  }
  assert.equal(nk.users.has(f.asker), true, "nothing happened to the asking account");
  assert.equal(nk.deviceOwner(NEW_DEVICE), undefined);
});

test("one bcrypt compare on every key path (a name nobody has, an account with no key, a wrong key): no timing tell", () => {
  family();
  nk.addUser("NoKey_1", KID);   // a claimed account without a key
  let compared = 0;
  const compare = nk.bcryptCompare.bind(nk);
  nk.bcryptCompare = (h: string, t: string) => {
    compared++;
    return compare(h, t);
  };
  for (const username of ["Nobody_9", "NoKey_1", "Sasa_7"]) {
    const before = compared;
    const asker = nk.addUser("asker" + username, UNCLAIMED);
    assert.equal(signIn(asker, { username, key: "0000-0000", device_id: NEW_DEVICE }).error, "wrong_key", username);
    assert.equal(compared - before, 1, username + ": exactly one compare");
  }
});

test("wrong keys are counted per asking account only, never per name: a stranger can't keep the grown-up's key out", () => {
  // The second review's finding 3b: strangers typing wrong keys for Sasa's name never lock the right key out.
  const f = family();
  for (let i = 0; i < K.CALLER_MAX_WRONG + 5; i++) {
    const other = nk.addUser("Tryer_" + i, UNCLAIMED);   // a different asking account each time
    nk.linkDevice(other, "tryer-device-" + i + "-0000");
    assert.equal(signIn(other, { username: "Sasa_7", key: "0000-0000", device_id: NEW_DEVICE }).error, "wrong_key");
  }
  assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE }).ok, true,
    "the grown-up's own asking account was never touched by the strangers' tries");
});

test("one asking account's wrong keys lock that account for a while (never the name)", () => {
  const f = family();
  for (let i = 0; i < K.CALLER_MAX_WRONG; i++) {
    assert.equal(signIn(f.asker, { username: "Nobody_" + i, key: "0000-0000", device_id: NEW_DEVICE }).error, "wrong_key");
  }
  const locked = signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE });
  assert.equal(locked.error, "locked");
  assert.equal(locked.wait, K.CALLER_WINDOW_MS / 1000);
  // another asking account (a different grown-up device) is not locked by this one's tries
  const other = nk.addUser("x8Qw2z", UNCLAIMED);
  nk.linkDevice(other, "other-browser-0001");
  assert.equal(signIn(other, { username: "Sasa_7", key: f.key, device_id: OTHER_DEVICE }).ok, true);
});

test("one asking account can't guess across many names", () => {
  const f = family();
  for (let i = 0; i < K.CALLER_MAX_WRONG; i++) {
    signIn(f.asker, { username: "Name_" + i, key: "0000-0000", device_id: NEW_DEVICE });
  }
  assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE }).error, "locked");
});

test("a new key stops the old one", () => {
  const f = family();
  key(f.child, { action: "new" });
  assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE }).error, "wrong_key");
});

test("a device id that is odd or already someone's is refused", () => {
  const f = family();
  for (const device_id of ["short", "has spaces in it", 123456789012, undefined]) {
    assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id }).error, "bad_request", String(device_id));
  }
  assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: "browser-device-01" }).error, "bad_request",
    "the asking device's own id: the game makes a new one");
  assert.equal(nk.users.has(f.asker), true);
  assert.equal(signIn(f.asker, { username: 5, key: f.key, device_id: NEW_DEVICE }).error, "wrong_key");
});

test("sign out other devices: every other device of the account goes and their sessions end", () => {
  const f = family();
  signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: NEW_DEVICE });
  nk.linkDevice(f.child, "tablet-device-001");
  const phoneSocket = nk.presence(f.child);
  const tabletSocket = nk.presence(f.child);
  nk.streams.set("0|" + f.child + "|", [phoneSocket, tabletSocket]); // their notification streams: open sockets
  const r = key(f.child, { action: "sign_out_others", device_id: NEW_DEVICE });
  assert.deepEqual(r, { ok: true, removed: 1, devices: 1 }, "the key sign-in logged the phone out already");
  assert.equal(nk.deviceOwner(NEW_DEVICE), f.child);
  assert.equal(nk.deviceOwner(f.phone), undefined, "the lost phone can't sign in any more");
  assert.equal(nk.deviceOwner("tablet-device-001"), undefined);
  assert.deepEqual(nk.loggedOut, [f.child, f.child], "no refresh (the key sign-in, then this)");
  assert.deepEqual(nk.disconnected, [phoneSocket.sessionId, tabletSocket.sessionId], "every open socket closes");
  assert.equal(key(f.child, { action: "sign_out_others", device_id: f.phone }).error, "not_allowed", "not one of its devices");
  assert.equal(key(f.child, { action: "sign_out_others" }).error, "not_allowed");
});

test("the owner (no session: the console or the HTTP key) makes a key for a family whose every device lost the account", () => {
  const f = family();
  const admin = (payload: object) => JSON.parse(S.rpcAccountKey(ctx(""), log, nk, JSON.stringify(payload)));
  assert.deepEqual(admin({ action: "state", username: "sasa_7" }),
    { ok: true, has_key: true, made_ms: now, devices: 1, username: "Sasa_7" });
  const made = admin({ action: "new", username: "Sasa_7" });
  assert.equal(made.ok, true);
  assert.equal(made.username, "Sasa_7");
  const asker = nk.addUser("z1Rq2w", UNCLAIMED);
  assert.equal(signIn(asker, { username: "Sasa_7", key: made.key, device_id: NEW_DEVICE }).user_id, f.child);
  assert.equal(signIn(f.asker, { username: "Sasa_7", key: f.key, device_id: "other-device-0001" }).error, "wrong_key",
    "the family's old key stopped");
  assert.equal(admin({ action: "new" }).error, "bad_request", "the owner names the account");
  assert.equal(admin({ action: "new", username: "Nobody_1" }).error, "not_found");
  assert.equal(admin({ action: "sign_out_others", username: "Sasa_7", device_id: NEW_DEVICE }).error, "bad_request",
    "signing devices out is the family's own step");
  assert.equal(key(f.child, { action: "state", username: "Other_1" }).error, "not_allowed", "a player names only itself");
});

test("deleting the account deletes its key", () => {
  const f = family();
  const first = JSON.parse(S.rpcDeleteAccount(ctx(f.child), log, nk, "{}"));
  JSON.parse(S.rpcDeleteAccount(ctx(f.child), log, nk, JSON.stringify({ confirm: first.confirm })));
  assert.equal(nk.object("account", "sign_in_key", f.child), undefined);
  assert.ok(S.Deletion.COLLECTIONS.includes("account"));
});

// --- the profile backup the game writes itself (guards.ts + ProfileRules) ---

function write(userId: string, objects: object[]): any {
  return S.beforeWriteStorageObjects(ctx(userId), log, nk, { objects });
}

test("a profile write is cleaned: no gold, the account's own name and band", () => {
  const child = nk.addUser("Sasa_7", KID);
  const value = JSON.stringify({ version: 1, backup: 2, username: "Other_1", age_band: "13_plus", survivor_gold: 999999,
    settings: { volume: 0.4, graphics: "high" }, universe_unlocked: 3 });
  const out = write(child, [{ collection: "profiles", key: "profile", value, version: "", permissionRead: 1, permissionWrite: 1 }]);
  const kept = JSON.parse(out.objects[0].value);
  assert.deepEqual(kept, { version: 1, backup: 2, username: "Sasa_7", age_band: "under_13", settings: { volume: 0.4 },
    universe_unlocked: 3 });
  assert.equal(out.objects[0].version, "", "the game's version check is kept");
});

test("the module is 0.2.12 and registers account_key and sign_in_with_key", () => {
  const registered: string[] = [];
  const init = new Proxy({}, { get: (_t, k) => (k === "registerRpc" ? (id: string) => registered.push(id) : () => {}) });
  S.InitModule(ctx("", {}), log, nk, init);
  for (const id of ["account_key", "sign_in_with_key"]) {
    assert.ok(registered.includes(id), id);
  }
  assert.equal(JSON.parse(S.rpcHealthcheck(ctx("u"), log, nk, "")).version, "0.2.20");
});

test("only the one profile object; a broken profile is refused", () => {
  const child = nk.addUser("Sasa_7", KID);
  assert.throws(() => write(child, [{ collection: "profiles", key: "other", value: '{"version":1}' }]),
    (e: any) => e.message === "not_allowed" && e.code === 7);
  assert.throws(() => write(child, [{ collection: "profiles", key: "profile", value: "[1,2]" }]),
    (e: any) => e.message === "bad_profile" && e.code === 3);
  assert.throws(() => write(child, [{ collection: "profiles", key: "profile", value: "{" + " ".repeat(S.ProfileRules.MAX_CHARS) + "}" }]),
    (e: any) => e.message === "too_big" && e.code === 3);
});
